/*Class Name: CWS_InAppAccountInterface_Test
*Description: Test class to provide Account, Contract, Quote, and Product data to In App Purchasing
*Created By: Carl Shahan
*Created On: 10/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 10/05/2020 CWH-996       In App Purchasing get account data test class
*/
@isTest
public with sharing class CWS_InAppAccountInterface_Test { 

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
            getRequest.requestURI = '/services/apexrest/inapp/account/' + account.Id;
            getRequest.httpMethod = 'GET';
            RestContext.request = getRequest;
            Account record = CWS_InAppAccountInterface.getAccounts();
 
        Test.stopTest();

        System.debug('>>>>>>>>> getAccountFoundTest account = ' + record);

        System.assertEquals(account.Id, record.Id);
    }

    @isTest static void getAccountFailedTest() {

        // Create the Account and Contact needed for the SOQL query 
        Account account = createAccountWithContact();

        Test.startTest();

            RestRequest getRequest = new RestRequest();
            getRequest.requestURI = '/services/apexrest/inapp/account/0016C00000NXiQQQ';
            getRequest.httpMethod = 'GET';
            RestContext.request = getRequest;
            Account record = CWS_InAppAccountInterface.getAccounts();
 
        Test.stopTest();

        Account emptyAccount = new Account();

        System.debug('>>>>>>>>> getAccountFailedTest account = ' + record);

        System.assertEquals(emptyAccount, record);
    }
}