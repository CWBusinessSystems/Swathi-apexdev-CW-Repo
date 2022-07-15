/*Class Name: CWS_SSOUpdatedAccountContacts_Test
*Description: Apex test class to test CW Home SSO account provisioning
*Created By: Carl Shahan
*Created On: 08/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 09/13/2020 CWH-996       Apex test class to test CW Home SSO account provisioning
*/

@isTest
private class CWS_SSOUpdatedAccountContacts_Test {

    private class SuccessfulResponse implements HttpCalloutMock {
        /**
        * @description mock http response that returns successful message and status code
        * @param request
        * @return HttpResponse response 
        */
        public HTTPResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"partnerId":"5f515856bab09f000172e5cc","userId":"5f515856c8192caeb31b6065"}');
            response.setStatusCode(200);
            return response;
        }
    }

    private class ErrorResponse implements HttpCalloutMock {
        /**
        * @description mock http response that returns error message and status code
        * @param request
        * @return HttpResponse response 
        */
        public HTTPResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"code":"InvalidObject","message":"PartnerProvisioningRequest object is invalid","errors":[{"code":"InvalidField","message":"Partner 60c25cbd08ddf80001c0cace already exists and is linked to a Salesforce account.","resource":"PartnerProvisioningRequest","field":null}]}');
            response.setStatusCode(400);
            return response;
        }
    }
       
    private static Account createAccountWithContact() {

        CWS_SSO_Endpoints__c customSettings = new CWS_SSO_Endpoints__c();

        customSettings.CWS_SSO_Client_Secret__c = '12345678910zWcVuxdyOfVoXuPxJiyxo';
        customSettings.CWS_SSO_Error_Notification_Email__c = 'cshahan@connectwise.com';
        customSettings.CWS_SSO_Integration_Active__c = true;
        customSettings.CWS_SSO_SF_Gateway__c = 'https://dev-na-latest.sf-gateway.connectwisedev.com/v1/connectwise/partners/provision';
        customSettings.CWS_SSO_Token_Endpoint__c = 'https://sts.connectwisedev.com/connect/token';
        customSettings.CWS_SSO_Token_Redirect__c = 'https://connectwise20--csdev.lightning.force.com/apex/oauthv2';

        insert customSettings;
           
        Account account = new Account(

            Name = 'AIOITS Test Account',
            Phone = '727 777 3625',
            BillingCountry = 'United States',
            BillingState = 'Florida',
            BillingPostalCode = '33715',
            CWS_SSO_GUID__c = null,
            CWS_Is_Partner__c = true,
            CWS_Access_to_CW_University__c = false
        );

        insert account;

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(
            AccountId = account.Id,
            CWS_Active__c = true,
            CWS_Primary_Contact__c = true,
            FirstName = 'Roger',
            LastName = 'Rogers',
            Phone = '727 777 3625',
            Email = 'roger.rogers@aioitssystems.com.invalid'
        ));

        insert contactList;

        return account;
    }

    @isTest static void postAccountContactData() {
        
        // Create the Account and Contact needed for the SOQL query 
        Account account = createAccountWithContact();
        Integer statusCode = 404;
        
        Test.setMock(HttpCalloutMock.class, new SuccessfulResponse());

        Test.startTest();
            CWS_SSOUpdatedAccountContacts.postContactData(account.Id);
            statusCode = 200;
        Test.stopTest();

        System.assertEquals(200, statusCode);
    }
    
    @isTest static void postAccountContactDataError() {
        
        // Create the Account and Contact needed for the SOQL query 
        Account account = createAccountWithContact();
        Integer statusCode = 404;

        Test.setMock(HttpCalloutMock.class, new ErrorResponse());

        Test.startTest();
            CWS_SSOUpdatedAccountContacts.postContactData(account.Id);
            statusCode = 400;
        Test.stopTest();

        System.assertEquals(400, statusCode);
    }
}