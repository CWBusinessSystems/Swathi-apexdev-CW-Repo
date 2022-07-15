/**Class Name: CWS_InAppIntegration_Test 
* @description: Test class for In App Purchasing to provide Account, Contract, Quote, and Product data to In App Purchasing
* @author Created By: Carl Shahan
* @date 08/27/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 09/28/2020 CWH-996       Test class for In App Purchasing
*Carl Shahan 02/11/2022 OBD-3769      Modified to instantiate the QuoteData class as a seperate class and not part of the In App code  
*/
@isTest
/** @description In App test class */
private with sharing class CWS_InAppIntegration_Test {
    
    /** @description  setup method runs dml in seperate context to avoind too many dml queries */
    @TestSetup
    static void setup() {
        
        Boolean testDataCreated = CWS_CPQDataFactory_Test.generateCPQTestData();      
    }
    /** @description tests the get account and contract rest api */
    @isTest static void getAccountContractsTest() {
        
        Account testAccount = [SELECT Id FROM Account WHERE Name='BB8 Test Account' LIMIT 1];
        
        System.debug('Account Id ' + testAccount.Id);

        RestRequest getRequest = new RestRequest();
        getRequest.requestURI = '/services/apexrest/inapp/contracts/' + testAccount.Id;
        getRequest.httpMethod = 'GET';
        RestContext.request = getRequest;

        System.debug('RestContext.request getRequest = ' + getRequest);

        Test.startTest();
            CWS_InAppIntegration.Records records = CWS_InAppIntegration.getAccountContracts(); 
        Test.stopTest();

        System.debug('TEST Record data returned: ' + records);

        System.assertEquals(testAccount.Id, records.accountId, 'TEST assertEquals completed');

    }
    /** @description tests the standard pricing rest api */
    @isTest static void postStandardPricingTest() {

        Account testAccount = [SELECT Id FROM Account WHERE Name='BB8 Test Account' LIMIT 1];
        Contract testContract = [SELECT Id, AccountId FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];        
        Product2 testProduct = [SELECT Id, Name FROM Product2 WHERE Name='Automate Standard' LIMIT 1];
        SBQQ__Subscription__c testSubscription = [SELECT Id, SBQQ__ProductName__c FROM SBQQ__Subscription__c WHERE SBQQ__ProductName__c = 'Automate Standard' LIMIT 1];

        CWS_InAppQuoteData quoteData = new CWS_InAppQuoteData();

        quoteData.contractId = testContract.Id;
        quoteData.quotedPrice = 2.95;
        quoteData.quotedQuantity = 10;
        quoteData.subscriptionId =  testSubscription.Id;
        quoteData.productId =  testProduct.Id;
        quoteData.productCode =  'AUT-LIC-SAASPKSNDSAS';
        quoteData.productName =  'Automate Standard';
        quoteData.purchaserFirstName = 'Luke';
        quoteData.purchaserLastName = 'Skywalker';
        quoteData.purchaserEmail = 'luke.skywalker@bb8fptecc.com';

        String postData = (String)JSON.serialize(quoteData);

        Test.startTest();   

            RestResponse postResponse = new RestResponse();
            RestRequest postRequest = new RestRequest();
            postRequest.requestURI = '/services/apexrest/inapp/contracts';
            postRequest.httpMethod = 'POST';
            postRequest.requestBody = Blob.valueOf(postData);
            RestContext.request = postRequest;
            RestContext.response = postResponse;
 
            CWS_InAppIntegration.createQuote();
        
        Test.stopTest();

        System.debug('TEST postStandardPricingTest response status: ' + postResponse.statusCode);
        System.debug('TEST postStandardPricingTest response: ' + postResponse.responseBody.toString());

        System.assertEquals(200, postResponse.statusCode, 'TEST assertEquals completed');
    }
    /** @description tests the future pricing rest api */
    @isTest static void postFuturePricingTest() {

        Account testAccount = [SELECT Id FROM Account WHERE Name='BB8 Test Account' LIMIT 1];
        Contract testContract = [SELECT Id, AccountId FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];        
        Product2 testProduct = [SELECT Id, Name FROM Product2 WHERE Name='Automate Standard' LIMIT 1];
        SBQQ__Subscription__c testSubscription = [SELECT Id, SBQQ__ProductName__c FROM SBQQ__Subscription__c WHERE SBQQ__ProductName__c = 'Automate Standard' LIMIT 1];


        CWS_InAppQuoteData quoteData = new CWS_InAppQuoteData();

        quoteData.contractId = testContract.Id;
        quoteData.quotedPrice = 2.75;
        quoteData.quotedQuantity = 10;
        quoteData.subscriptionId =  testSubscription.Id;
        quoteData.productId =  testProduct.Id;
        quoteData.productCode =  'AUT-LIC-SAASPKSNDSAS';
        quoteData.productName =  'Automate Standard';
        quoteData.purchaserFirstName = 'Luke';
        quoteData.purchaserLastName = 'Skywalker';
        quoteData.purchaserEmail = 'luke.skywalker@bb8fptecc.com';

        String postData = (String)JSON.serialize(quoteData);

        Test.startTest();   

            RestResponse postResponse = new RestResponse();
            RestRequest postRequest = new RestRequest();
            postRequest.requestURI = '/services/apexrest/inapp/contracts';
            postRequest.httpMethod = 'POST';
            postRequest.requestBody = Blob.valueOf(postData);
            RestContext.request = postRequest;
            RestContext.response = postResponse;

            CWS_InAppIntegration.ResponseMessage responseMessage = new CWS_InAppIntegration.ResponseMessage();
            
            CWS_InAppIntegration.createQuote();
        
        Test.stopTest();

        System.debug('TEST postFuturePricingTest response status: ' + postResponse.statusCode);
        System.debug('TEST postFuturePricingTest response: ' + postResponse.responseBody.toString());

        System.assertEquals(200, postResponse.statusCode, 'TEST assertEquals completed');

    }
}