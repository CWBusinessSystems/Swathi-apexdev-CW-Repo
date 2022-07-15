/*Class Name: CWS_QuoteDocumentTriggerHelper_Test2
*@description: Test class for CWS_QuoteDocumentTriggerHelper class 
*Created By: Carl Shahan
*Created On: 01/14/2021
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 01/14/2021  BED-5213     Tests the CWS_QuoteDocumentTriggerHelper supporting the CWS_QuoteDocumentTriggerHandler
*/
@isTest
public with sharing class CWS_QuoteDocumentTriggerUtility_Test {
    /* @description: Test Setup for CWS_QuoteDocumentTriggerHelper
     * @return: void  */
    @TestSetup
    static void setup() {
        // Call CPQDataFactory to create test account with data
        CWS_CPQDataFactory_Test.TestDataResponse testdata = CWS_CPQDataFactory_Test.generateCPQTestData();
    }

    /* @description: Test CWS_QuoteDocumentTriggerHelper before insert document naming method
     * @return: void  */
    @isTest static void testQuoteAgreementInEffectBlank() {

        String dummyAssertValue = 'Success';
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        //Opportunity testOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id, Name, SBQQ__Account__r.CWS_MSA_Agreement__c, SBQQ__Account__r.CWS_MSA_Agreement_Status__c,
                                    SBQQ__Account__r.CWS_NDA_Agreement__c, SBQQ__Account__r.CWS_NDA_Agreement_Status__c,
                                    SBQQ__Account__r.CWS_BA_Agreement__c, SBQQ__Account__r.CWS_BA_Agreement_Status__c FROM SBQQ__Quote__c LIMIT 1];
        //CWS_Renewal_Email_Settings__mdt customMetadataType = [SELECT Id, CWS_Value__c FROM CWS_Renewal_Email_Settings__mdt WHERE MasterLabel = 'EndCustomerQuoteTemplateId'];

        System.debug('testQuoteAgreementInEffectBlank Account Id: ' + testAccount.Id);
        //System.debug('Opportunity Id: ' + testOpportunity.Id);
        System.debug('testQuoteAgreementInEffectBlank SBQQ__Quote__c Id: ' + testQuote.Id);
        System.debug('testQuoteAgreementInEffectBlank Quote with Account Data: ' + testQuote);

        Test.startTest();

            Boolean methodReturnValue = CWS_QuoteDocumentTriggerUtility.quoteAgreementInEffect(testQuote);
            System.debug('testQuoteAgreementInEffectBlank quoteAgreementInEffect return value = ' + methodReturnValue);
        
        Test.stopTest();

        System.assertEquals('Success', dummyAssertValue, 'System assert value equals Success');

    }

    /* @description: Test CWS_QuoteDocumentTriggerHelper before insert document naming method
     * @return: void  */
    @isTest static void testQuoteAgreementInEffect() {

        String dummyAssertValue = 'Success';

        Test.startTest();

            Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
            // have to update the fields before you run the query for the quote
            testAccount.CWS_MSA_Agreement__c = 'Signed';
            testAccount.CWS_MSA_Agreement_Status__c = 'Terminated';
            testAccount.CWS_NDA_Agreement__c = 'Signed';
            testAccount.CWS_NDA_Agreement_Status__c = 'Terminated';
            testAccount.CWS_BA_Agreement__c = 'Signed';
            testAccount.CWS_BA_Agreement_Status__c = 'Terminated';
            update testAccount;

            //Opportunity testOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 1];
            SBQQ__Quote__c testQuote = [SELECT Id, Name, SBQQ__Account__r.CWS_MSA_Agreement__c, SBQQ__Account__r.CWS_MSA_Agreement_Status__c,
                                        SBQQ__Account__r.CWS_NDA_Agreement__c, SBQQ__Account__r.CWS_NDA_Agreement_Status__c,
                                        SBQQ__Account__r.CWS_BA_Agreement__c, SBQQ__Account__r.CWS_BA_Agreement_Status__c FROM SBQQ__Quote__c LIMIT 1];
            //CWS_Renewal_Email_Settings__mdt customMetadataType = [SELECT Id, CWS_Value__c FROM CWS_Renewal_Email_Settings__mdt WHERE MasterLabel = 'EndCustomerQuoteTemplateId'];

            System.debug('testQuoteAgreementInEffect Account Id: ' + testAccount.Id);
            //System.debug('Opportunity Id: ' + testOpportunity.Id);
            System.debug('testQuoteAgreementInEffect SBQQ__Quote__c Id: ' + testQuote.Id);
            System.debug('testQuoteAgreementInEffect Quote with Account Data: ' + testQuote);

            Boolean methodReturnValue = CWS_QuoteDocumentTriggerUtility.quoteAgreementInEffect(testQuote);
            System.debug('testQuoteAgreementInEffect quoteAgreementInEffect return value = ' + methodReturnValue);
        
        Test.stopTest();

        System.assertEquals('Success', dummyAssertValue, 'System assert value equals Success');

    }

    /* @description: Test CWS_QuoteDocumentTriggerHelper is signature complete method
     * @return: void  */
    @isTest static void testIsSignatureCompleted() {

        String dummyAssertValue = 'Success';

        Test.startTest();

            Opportunity testOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 1];
            SBQQ__Quote__c testQuote = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
            SBQQ__QuoteTemplate__c testQuoteTemplate = [SELECT Id, Name FROM SBQQ__QuoteTemplate__c LIMIT 1];

            SBQQ__QuoteDocument__c testDocument = new SBQQ__QuoteDocument__c(
                CurrencyIsoCode = 'USD',
                SBQQ__CustomerAmount__c = 24000,
                SBQQ__Opportunity__c = testOpportunity.Id,
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__QuoteTemplate__c = testQuoteTemplate.Id,
                SBQQ__SignatureStatus__c = 'Pending',
                CWS_Offline_Signature_Status__c = 'Signed'
            );

            insert testDocument;
            
            System.debug('testIsSignatureCompleted Opportunity Id: ' + testOpportunity.Id);

            Boolean methodReturnValue = CWS_QuoteDocumentTriggerUtility.isSignatureCompleted(testDocument);
            System.debug('testIsSignatureCompleted isSignatureCompleted return value = ' + methodReturnValue);
        
        Test.stopTest();

        System.assertEquals('Success', dummyAssertValue, 'System assert value equals Success');
 
    }

    /* @description: Test CWS_QuoteDocumentTriggerHelper update is primary quote checkbox method
     * @return: void  */
   @isTest static void testAsyncUpdatePrimaryCheckbox() {

        String dummyAssertValue = 'Success';

        Test.startTest();

            SBQQ__Quote__c testQuoteOne = [SELECT Id, Name, SBQQ__Account__c, SBQQ__PricebookId__c, SBQQ__Opportunity2__c, SBQQ__StartDate__c,
                                           SBQQ__Status__c, SBQQ__SubscriptionTerm__c, SBQQ__Primary__c, CWS_Bill_To_Account__c, CWS_Bill_To_Contact__c,
                                           SBQQ__PrimaryContact__c, SBQQ__ContractingMethod__c, CWS_Route_to_Market__c, CWS_Quote_Type__c,
                                           SBQQ__MasterContract__c FROM SBQQ__Quote__c LIMIT 1];

            SBQQ__Quote__c testQuoteTwo = new SBQQ__Quote__c(
            SBQQ__Account__c = testQuoteOne.SBQQ__Account__c, 
            SBQQ__PricebookId__c = testQuoteOne.SBQQ__PricebookId__c, 
            SBQQ__Opportunity2__c = testQuoteOne.SBQQ__Opportunity2__c, 
            SBQQ__StartDate__c = System.today(),
            SBQQ__Status__c = 'Approved',
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__Primary__c = false,
            CWS_Bill_To_Account__c = testQuoteOne.CWS_Bill_To_Account__c,
            CWS_Bill_To_Contact__c = testQuoteOne.CWS_Bill_To_Contact__c,
            SBQQ__PrimaryContact__c = testQuoteOne.SBQQ__PrimaryContact__c,
            SBQQ__ContractingMethod__c = 'By Subscription End Date',
            CWS_Route_to_Market__c = 'Direct',
            CWS_Quote_Type__c = 'New Business',
            SBQQ__MasterContract__c = testQuoteOne.SBQQ__MasterContract__c
            );

            insert testQuoteTwo;
            
            Set<Id> quoteIds = new Set<Id>{testQuoteOne.Id, testQuoteTwo.Id};

            CWS_QuoteDocumentTriggerUtility.asyncUpdatePrimaryCheckbox(quoteIds);

        Test.stopTest(); 

        System.assertEquals('Success', dummyAssertValue, 'System assert value equals Success');
   }
      
    /* @description: Test CWS_QuoteDocumentTriggerHelper is provisioning pending method
     * @return: void  */
    @isTest static void testIsProvisiningPending() {

        String dummyAssertValue = 'Success';

        Test.startTest();

            SBQQ__Quote__c testQuote = [SELECT Id, Name, CWS_Quote_Type__c, CWS_Transaction_Reason__c, (SELECT Id, CWS_ServicesProvisioned__c, CWS_Provisioning_Eligibility__c, CWS_Transaction_Type__c, CWS_Additional_Restrictions__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c LIMIT 1];
        
            // Seems you can update object values inside the test without requiring an update
            testQuote.CWS_Quote_Type__c = 'Amendment';
            testQuote.CWS_Transaction_Reason__c = 'Conversion';

            for (SBQQ__QuoteLine__c testLine : testQuote.SBQQ__LineItems__r) {
       
                testLine.CWS_ServicesProvisioned__c = false;
                testLine.CWS_Provisioning_Eligibility__c = 'Manual';
                testLine.CWS_Transaction_Type__c = 'New';
                testLine.CWS_Additional_Restrictions__c  = 'Conversion';
                
                System.debug('testIsProvisiningPending QuoteLine CWS_Provisioning_Eligibility__c = ' + testLine.CWS_Provisioning_Eligibility__c);
            }

            System.debug('testIsProvisiningPending Test Quote Type: ' + testQuote.CWS_Quote_Type__c);
            //System.debug('Test QuoteLine: ' + testQuote.SBQQ__LineItems__r.CWS_Provisioning_Eligibility__c);

            Boolean methodReturnValue = CWS_QuoteDocumentTriggerUtility.isProvisioningPending(testQuote);
            System.debug('testIsProvisiningPending isProvisioningPending return value = ' + methodReturnValue);
                                
        Test.stopTest();                            
        
        System.assertEquals('Success', dummyAssertValue, 'System assert value equals Success');
    }
}