/*Class Name: CWS_BatchRetryRevokeQuoteDoc
*Description: Callout for revoking failed docusign documents
*Created By: Khayam
*Created On: 05/26/2020 

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Khayam                 05/26/2020          BED-8645             Delinquency and Termination Process
*/
public with sharing class CWS_BatchRetryRevokeQuoteDoc implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext BC) {

            String query = 'SELECT SBQQDS__EnvelopeId__c, SBQQDS__ErrorMessage__c, SBQQ__ElectronicSignature__c, SBQQDS__VoidedReason__c, ' +
            'SBQQ__SignatureStatus__c FROM SBQQ__QuoteDocument__c ' + 
            'Where SBQQDS__EnvelopeId__c <> null AND SBQQDS__VoidedReason__c <> null AND ' +
            'SBQQ__SignatureStatus__c <> \''+CWS_ConstantClass.QDOC_SIG_Voided+'\' ';

            return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SBQQ__QuoteDocument__c> qdocList) {

        try {
            
            SBQQDS.DocuSignPlugin plugin = new SBQQDS.DocuSignPlugin();
            List<SBQQ__QuoteDocument__c> docs = new List<SBQQ__QuoteDocument__c>();
            for (SBQQ__QuoteDocument__c doc : qdocList) {
                if (doc.SBQQDS__VoidedReason__c != NULL && System.Label.CWS_DocuSign_Revoke_Errors.containsIgnoreCase(doc.SBQQDS__ErrorMessage__c)) {
                    doc.SBQQDS__ErrorMessage__c=null;
                    docs.add(doc);
                }
            }
            if (!docs.isEmpty()) {
                plugin.revoke(docs);   
            }

        } catch (Exception e) {
            CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_BatchRetryRevokeQuoteDoc', 'CWS_BatchRetryRevokeQuoteDoc' , '', null, null , 'CWS_BatchRetryRevokeQuoteDoc' , null);
        }
    }

    public void finish(Database.BatchableContext bc) {
        
        try {
            
            AsyncApexJob a = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email 
                                FROM AsyncApexJob WHERE Id =:bc.getJobId()];

            if (a.NumberOfErrors > 0) {
                CWS_ExceptionHandler.logErrors('CWS_BatchRetryRevokeQuoteDoc', 'finish::'+a.id, 'CWS_BatchRetryRevokeQuoteDoc::finish',a.ExtendedStatus,'',null,null);            
            }
            System.scheduleBatch(new CWS_BatchRetryRevokeQuoteDoc(), 'CWS_BatchRetryRevokeQuoteDoc', 1);

        } catch (Exception e) {
            CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_BatchRetryRevokeQuoteDoc', 'CWS_BatchRetryRevokeQuoteDoc::finish' , '', null, null , 'CWS_BatchRetryRevokeQuoteDoc' , null);            
        }

    }

    public static void runNow(){
        System.scheduleBatch(new CWS_BatchRetryRevokeQuoteDoc(), 'CWS_BatchRetryRevokeQuoteDoc', 0);
    }

}