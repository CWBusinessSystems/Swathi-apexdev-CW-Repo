/** Class Name: CWS_SSOUpdatedAccountContacts
* @description: Callout to send updated Account and Contact data to CW Home to create an SSO account
* @author Created By: Carl Shahan
* @date 08/27/2020
* Modification Log
* ------------------------------------------------------------------------------------------
* Developer   Date       User Story    Description
* ------------------------------------------------------------------------------------------
* Carl Shahan 08/27/2020 CWH-996       Callout to send updated Account and Contact data to CW Home to create an SSO account
* Carl Shahan 09/14/2021 OBD-244       Updated to include customSettings CWS_SSO_Endpoints__c to remove hardcoded endpoints
*/

/**
 * @description REST API class for calling the SSO provisioning endpont 
 */ 
public with sharing class CWS_SSOUpdatedAccountContacts {
    
    public static Boolean recursion = true;
    public static Http http = new Http();
    public static HTTPResponse response;
    public static HttpRequest request;
    public static Integer  responseCode = 0;
    public static String responseValue = '';
    public static String htmlEmailBody = '';

    // access_token is the json object returned from the api call so cannot change this
    private class DeserializeResponse {
        private String access_token {get; set;}
    }

    private class SuccessfulResponse {
        private String partnerId {get; set;}
        private String userId {get; set;}
    }
 
    private class AccountWrapper {
        private String accountName {get; set;}
        private String accountGuid {get; set;}
        private String manageAccountId {get; set;}
        private String accountSSOUserId {get; set;}
        private String contactGuid {get; set;}
        private String email {get; set;}
        private String firstName {get; set;}
        private String lastName {get; set;}
        private String country {get; set;}
        private String state {get; set;}
        private String zip {get; set;}
        private String phoneNumber {get; set;}
    }

    private class ProvisioningError {
        private String code {get; set;}
        private String message {get; set;}
        private String resource {get; set;}
        private String field {get; set;}
    }

    private class ErrorResponse {
        private String code {get; set;}
        private String message {get; set;}
        private List<ProvisioningError> errors {get; set;}
    }

    private class UpdateRecordParameters {
        private String accountId {get; set;}
        private String contactId {get; set;}
        private String emailAddress {get; set;}
        private String partnerId {get; set;}
        private String userId {get; set;}
    }

    private class SendEmailParameters {
        private String emailAddress {get; set;}
        private String accountUrl {get; set;}
        private String partnerId {get; set;}
        private String error {get; set;}
        private String message {get; set;}
    }

    /**
     * @description Constructor for setting the custom settings for REST methods 
     */ 
    private static CWS_SSO_Endpoints__c customSettings = CWS_SSO_Endpoints__c.getInstance();

    /**
     * @description untility method for sending emails
     * @param parameters
     */
    private static void sendMail(SendEmailParameters parameters) {
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { parameters.emailAddress };
        String subject = 'Error linking Salesforce and SSO Accounts';
        String htmlBody = '<p>There was an error attempting to link this Salesforce with an SSO account:</p>' +
                          '<p>SF Account: ' + parameters.accountUrl + '</p>' +
                          '<p>SSO Partner Id: ' + parameters.partnerId + '</p>' +
                          '<p>Error: ' + parameters.error + '</p>' +
                          '<p>Note: ' + parameters.message + '</p>';
        
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        // Pass this email message to the built-in sendEmail method of the Messaging class
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        for (Messaging.SendEmailResult res : results) {
            if (res.isSuccess()) {
                System.debug('Email successfully sent to: ' + parameters.emailAddress);
            }
            else {
                System.debug('The following errors occurred: ' + res.getErrors());                 
            }
        }
    }

    /**
     * @description Method for getting the sts token from the sts server
     * @return String access_token
     */
    private static String getSTSAccessToken() {
       
        Http http = new http();
        Httprequest request = new HttpRequest();
        request.setendpoint(customSettings.CWS_SSO_Token_Endpoint__c);
        request.setMethod('POST');
        System.debug('Requesting access token');
        request.setBody('client_secret=' + customSettings.CWS_SSO_Client_Secret__c + '&client_id=sfapi&grant_type=client_credentials&redirect_uri=' + customSettings.CWS_SSO_Token_Redirect__c);
        Httpresponse response = http.send(request);

        DeserializeResponse responseToken = (DeserializeResponse)JSON.deserialize(response.getbody(),DeserializeResponse.class);

        return responseToken.access_token;
    }

    /**
     * @description Entry method for consturucting the payload for the SSO API endpoint
     * @param accountId
     */
    @future(callout=true)
    public static void postContactData(Id accountId) {
        
        Account accountData = new Account();
        List<Contact> contactData = new List<Contact>();
       
        // Had to add the try catch because there are so many contacts referencing merged or deleted Accounts 
        try {
            accountData = [SELECT Id, Name, Phone, BillingCountry, BillingState, BillingPostalCode, CWS_SSO_GUID__c, CWS_Is_Partner__c,
                        CWS_Access_to_CW_University__c, CWS_Manage_Company_Rec_Id__c, (SELECT Id, FirstName, LastName, Phone, Email,
                        CWS_SSO_User_ID__c, CWS_SSO_Login_Email__c FROM Contacts WHERE CWS_Primary_Contact__c = true) FROM Account
                        WHERE Id = :accountId]; //WITH SECURITY_ENFORCED Keeps throwing insuficient permission errors
        
            contactData = accountData.Contacts;
        }
        catch (QueryException qex) {

            System.debug('CWS_SSOUpdatedAccountContacts query Account data error: ' + qex.getMessage());
        }
        catch (Exception ex) {
            
            System.debug('CWS_SSOUpdatedAccountContacts query Account general exception error: ' + ex.getMessage());
        }
        finally {

            System.debug('CWS_SSOUpdatedAccountContacts future method was called with Account Id: ' + accountId);
        }

        if (contactData.size() > 0 && customSettings.CWS_SSO_Integration_Active__c) {
            
            if ((accountData.CWS_SSO_GUID__c == null || accountData.CWS_SSO_GUID__c.length() < 24) && (accountData.CWS_Is_Partner__c == true || accountData.CWS_Access_to_CW_University__c == true)) {
                
                    System.debug('CWS_SSOUpdatedAccountContacts class conditional parameters met, ready to send data to endpoint');

                    AccountWrapper wrapper = new AccountWrapper();
                    
                    for (Contact contact : contactData) {

                        wrapper.accountGuid = accountData.Id;
                        wrapper.accountName = accountData.Name;
                        wrapper.manageAccountId =  accountData.CWS_Manage_Company_Rec_Id__c;
                        wrapper.accountSSOUserId = accountData.CWS_SSO_GUID__c;
                        wrapper.contactGuid = contact.Id;
                        wrapper.country = accountData.BillingCountry;
                        wrapper.email = contact.Email;
                        wrapper.firstName = contact.FirstName;
                        wrapper.lastName = contact.LastName;
                        wrapper.phoneNumber = contact.Phone;
                        wrapper.state = accountData.BillingState;
                        wrapper.zip = accountData.BillingPostalCode;
                    }

                    System.debug('Account wrapper: ' + JSON.serialize(wrapper));

                    makeApiCall(wrapper, accountData.Id); 
            }
            else {

                System.debug('CWS_SSOUpdatedAccountContacts class CWS_SSO_GUID__c is not null or referenced Account is not a partner -- end process');
            }
        }
        else {

            System.debug('CWS_SSOUpdatedAccountContacts class contactData = null or Custom Setting SSO Endpoints CWS_SSO_Integration_Active__c is false or method was called with invalid Account Id.');
        }
    }

    /**
     * @description Method that actually makes the API call to the SSO provisioning endpoint
     * @param wrapper Account data wrapper
     * @param accountDataId Account Id
     */
    private static void makeApiCall(AccountWrapper wrapper, String accountDataId) {

        String partnerIdMessageValue = 'Not available';
        String emailMessage = 'No additional details about the error are available.';
        String accessToken = getSTSAccessToken();
                

        // OAUTH 2.0 not fully supported on end point so named credentials not an option 
        request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(customSettings.CWS_SSO_SF_Gateway__c);
        request.setHeader('Authorization','Bearer ' + accessToken);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('accept', 'application/json');
        request.setBody(JSON.serialize(wrapper));

        response = http.send(request);

        String rawResponse = response.getBody();
        System.debug('Json raw response: ' + rawResponse);

        if (response.getStatusCode() == 200) {

            System.debug('CWS_SSOUpdatedAccountContacts response status code = 200');

            // A successful json response: {"partnerId":"5f515856bab09f000172e5cc","userId":"5f515856c8192caeb31b6065"}
            SuccessfulResponse returnData = (SuccessfulResponse)JSON.deserialize(response.getbody(), SuccessfulResponse.class);

            UpdateRecordParameters recordParameters = new UpdateRecordParameters();

            recordParameters.accountId = wrapper.accountGuid;
            recordParameters.contactId = wrapper.contactGuid;
            recordParameters.emailAddress = wrapper.email;
            recordParameters.partnerId = returnData.partnerId;
            recordParameters.userId = returnData.userId;

            // Call helper method to update Account and Contact records from response 
            updateAccountAndContact(recordParameters);
        }
        else {

            System.debug('CWS_SSOUpdatedAccountContacts response status code = ' + response.getStatusCode());
            
            String orgDomainUrl = Url.getOrgDomainUrl().getHost();
            String dynamicUrl = 'https://' + orgDomainUrl + '/lightning/r/Account/' + accountDataId + '/view';
            
            // A unsuccessful json response: {"code":"InvalidObject","message":"PartnerProvisioningRequest object is invalid","errors":[{"code":"InvalidField","message":"Partner 608c5d2ab7de540001115014 already exists and is linked to a Salesforce account.","resource":"PartnerProvisioningRequest","field":null}]}                   
            ErrorResponse errorResponse = (ErrorResponse)JSON.deserialize(response.getBody(), ErrorResponse.class);
            System.debug('CWS_SSOUpdatedAccountContacts provisioning service error: ' + errorResponse);
            
            if (errorResponse.errors[0].message.indexOf('Partner') == 0) {

                String[] messageArray = errorResponse.errors[0].message.split(' ');
                partnerIdMessageValue =  messageArray[1];
                emailMessage = 'Updated account with the Partner Id that already exists.';

                updateAccountOnly(wrapper.accountGuid, partnerIdMessageValue);

                /* Temporarily commenting out until all the missing data is updated

                SendEmailParameters emailParameters = new SendEmailParameters();
            
                emailParameters.emailAddress = customSettings.CWS_SSO_Error_Notification_Email__c; //connectwisehome@gmail.com
                emailParameters.accountUrl = dynamicUrl;
                emailParameters.partnerId = partnerIdMessageValue;
                emailParameters.error = errorResponse.errors[0].message;
                emailParameters.message = emailMessage;

                sendMail(emailParameters); */
            }
        }
    }

    /**
     * @description Helper method to update the target Account and Contact with the returned SSO data
     * @param accountId the account that is missing the Partner Id
     * @param partnerId the partner is that is missing from the account
     */
    private static void updateAccountOnly(Id accountId, String partnerId) {
    
        Account account = [SELECT Id, CWS_SSO_GUID__c FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED];
        // CWS_SSO_GUID__c is going to be null or have a value less than 24 before makeApiCall() fires.
        if (account.CWS_SSO_GUID__c == null || account.CWS_SSO_GUID__c.length() < 24) {

            account.CWS_SSO_GUID__c = partnerId;
        }

        // Make sure we can update the database before even trying
        if (Schema.sObjectType.Account.isUpdateable()) {
        
            update account;
        }
    }

    /**
     * @description Helper method to update the target Account and Contact with the returned SSO data
     * @param parameters custom class for all the updates for the Account and Contact records
     */
    private static void updateAccountAndContact(UpdateRecordParameters parameters) {
          
        Account account = [SELECT Id, CWS_SSO_GUID__c FROM Account WHERE Id = :parameters.accountId WITH SECURITY_ENFORCED];
        Contact contact = [SELECT Id, CWS_CW_Login_Email__c, CWS_SSO_User_ID__c FROM Contact WHERE Id = :parameters.contactId WITH SECURITY_ENFORCED];
        // this can be an array of comma delimited values
        account.CWS_SSO_GUID__c = parameters.partnerId;
        
        // Make sure we can update the database before even trying
        if (Schema.sObjectType.Account.isUpdateable()) {
        
            update account;
        }

        contact.CWS_CW_Login_Email__c = parameters.emailAddress;
        contact.CWS_SSO_User_ID__c = parameters.userId;
        
        // Make sure we can update the database before even trying
        if (Schema.sObjectType.Contact.isUpdateable()) {
        
            update contact;
        }
    }
}