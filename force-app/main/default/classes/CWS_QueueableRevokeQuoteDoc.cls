/*Class Name: CWS_QueueableRevokeQuoteDoc
*Description: Callout for revoking docusign documents
*Created By: Khayam
*Created On: 5/20/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                 5/20/2020       BED-8645            Account Restriction - Delinquency 
*/
global with sharing class CWS_QueueableRevokeQuoteDoc implements Queueable, Database.AllowsCallouts { 

    global List<SBQQ__QuoteDocument__c> qdocList;
    
    global CWS_QueueableRevokeQuoteDoc(){
        qdocList = new List<SBQQ__QuoteDocument__c>();
    }

    global CWS_QueueableRevokeQuoteDoc(List<SBQQ__QuoteDocument__c> docs){
        qdocList = docs;
    }

    global void execute(QueueableContext context) {
        SBQQDS.DocuSignPlugin plugin = new SBQQDS.DocuSignPlugin();
        List<SBQQ__QuoteDocument__c> docs = new List<SBQQ__QuoteDocument__c>();
        for (SBQQ__QuoteDocument__c doc : qdocList) {
            if (doc.SBQQDS__VoidedReason__c != NULL) {
                docs.add(doc);
            }
        }
        if (!docs.isEmpty()) {
            plugin.revoke(docs);   
        }
    }
}