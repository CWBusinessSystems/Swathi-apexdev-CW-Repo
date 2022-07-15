/*Class Name: CWS_BatchRetryRevokeQuoteDocTest
*Description: Callout for revoking failed docusign documents
*Created By: Khayam
*Created On: 05/26/2020 

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date               Description
*--------------------------------------------------------------------------------------------------
*Indra Ganesan       14/08/2020            Test Class for CWS_BatchRetryRevokeQuoteDoc
*Harsha              08/09/2020            CWS_BatchRetryRevokeQuoteDoc
*/
@isTest(SeeAllData=false)

public with sharing class CWS_BatchRetryRevokeQuoteDocTest {

    @testSetup
    static void init(){
        Account acc = CWS_UTLDataFactory.createAccount('ConnectWise Test Account', new Map<String, Object>{'CWS_Is_Distributor__c'=> true,'Industry'=>'MSP'}, true);
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty',acc.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>acc.id,'type'=> 'Amendment'}, true); 
        Map<String, Object> addFields01 = new Map<String,Object>{
            'CWS_Quote_Type__c'=>'New Business','CWS_Bill_To_Account__c'=>acc.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2019,7,7), 'CWS_Route_to_Market__c'=>'Direct'
        };  
        SBQQ__Quote__c quoteObj = CWS_UTLDataFactory.createQuote(acc.id,opp.id,addFields01,true);
        
        Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__Quote__c'=>quoteObj.id, 'SBQQDS__EnvelopeId__c'=>'ENV89797987', 'SBQQDS__ErrorMessage__c'=> System.Label.CWS_DocuSign_Revoke_Errors,  'SBQQDS__VoidedReason__c'=> 'NA'
        };
         /** Quote Document**/
        List<SBQQ__QuoteDocument__c> qDocLst = CWS_UTLDynamicApex.createBulkRecords('SBQQ__QuoteDocument__c', addFields, 20, true);
        
    }
    
   /*  @isTest
    Public static void  testBatch(){
        List<SBQQ__QuoteDocument__c> getquoteDocLst = [select id, SBQQDS__EnvelopeId__c, SBQQDS__ErrorMessage__c, SBQQDS__VoidedReason__c from SBQQ__QuoteDocument__c];
        Test.startTest();
        CWS_BatchRetryRevokeQuoteDoc revokeQuote = new CWS_BatchRetryRevokeQuoteDoc();
        Database.executeBatch(revokeQuote);
        Test.stopTest();
    }*/
    @isTest
    Public static void  testBatch(){
        //List<SBQQ__QuoteDocument__c> getquoteDocLst = [select id, SBQQDS__EnvelopeId__c, SBQQDS__ErrorMessage__c, SBQQDS__VoidedReason__c from SBQQ__QuoteDocument__c];
        Test.startTest();
        //CWS_BatchRetryRevokeQuoteDoc.runNow();
		System.scheduleBatch(new CWS_BatchRetryRevokeQuoteDoc(), 'CWS_DOCREVOKE_Test_1', 0);
        Test.stopTest();
    }
    
    
}