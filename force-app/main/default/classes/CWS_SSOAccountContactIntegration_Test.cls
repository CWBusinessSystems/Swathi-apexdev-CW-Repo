/*Class Name: CWS_SSOAccountContactIntegration_Test
*Description: Test class for SSO Integration to provide Account and Contract data
*Created By: Carl Shahan
*Created On: 10/03/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 10/03/2020 CWH-996       Test class for SSO Integration to provide Account and Contract data
*/
@isTest
public with sharing class CWS_SSOAccountContactIntegration_Test {
    private static Account createAccountWithContact() {

        Account account = new Account(

            Name = 'AIOITS Test Account',
            Phone = '727 777 3625',
            BillingStreet = '8800 Bay Pines Boulevard',
            BillingCity = 'St. Petersburg',
            BillingCountry = 'United States',
            BillingState = 'Florida',
            BillingPostalCode = '33715',
            CWS_Account_Restriction_Status__c = 'No Restriction',
            CWS_Products_Owned__c = 'Automate',
            CWS_Is_Partner__c = true,
            CWS_SSO_GUID__c = '5f6d07a5e6426900017a3ad5'
        );

        insert account;

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(
            AccountId = account.Id,
            CWS_Active__c = true,
            CWS_Primary_Contact__c = true,
            FirstName = 'Roger',
            LastName = 'Rabbit',
            Phone = '727 777 3625',
            Email = 'roger.rabbit@aioits.com.invalid',
            CWS_SSO_User_ID__c = '5f6d07a5ba60dafc65b47f92',
            CWS_CW_Login_Email__c = 'lskywalker@bb8fptecc.com.invalid'
        ));

        insert contactList;

        return account;
    }

    @isTest static void getAccountFoundTest() {

        // Create the Account and Contact needed for the SOQL query 
        Account account = createAccountWithContact();

        System.debug('Account Id ' + account.Id);

        Test.startTest();

            RestRequest getRequest = new RestRequest();
            getRequest.requestURI = '/services/apexrest/sso/account/' + account.Id;
            getRequest.httpMethod = 'GET';
            RestContext.request = getRequest;
            Account record = CWS_SSOAccountContactIntegration.getAccountContact();
 
        Test.stopTest();

        System.debug('>>>>>>>>> getAccountFoundTest record = ' + record);

        System.assertEquals(account.Id, record.Id);
    }
}