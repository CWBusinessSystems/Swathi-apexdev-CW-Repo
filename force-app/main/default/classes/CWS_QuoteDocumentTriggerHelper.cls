/** Class Name: CWS_QuoteDocumentTriggerHelpher
* @description: Helper Class for CWS_QuoteDocumentTriggerHandler
*Created By: Khayam
*Created On: 4/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                 4/6/2020        BED-5213            Quote Stage sync with Quote Documents
*Khayam                 6/8/2020        BED-8869            Co-terming Sales Contract - Amendment & Renewal
*Aakash                 6/16/2020       BED-7862            Sub-Stage Changes
*Ankit                  7/6/2020        RENEWALCAT_CHANGE_REQ - Changing the Renewal Type Reference to Renewal Category
*Carl Shahan            01/27/2021      #14154761           Broke out the syncQuoteDocumentQuoteStage() method into a seperate class CWS_QuoteDocumentSyncQuoteStage 
*/
public with sharing class CWS_QuoteDocumentTriggerHelper {
    /** 
    * Method name  : beforeInsert
    * @description  BED-8798 : Before Insert operation(Update Document Naming)
    * @param  newList
    * @return void
    * Developer    : Khayam
    */
    public static void beforeInsert(List<SObject> newList){ 
        List<SBQQ__QuoteDocument__c> qDocList = (List<SBQQ__QuoteDocument__c>) newList;
        Set<Id> quoteIds = new set<Id>();
        List<Document> docList = new List<Document>();
        Map<id,SBQQ__QuoteDocument__c> docMap = new map<id,SBQQ__QuoteDocument__c>();
        Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>(); 

        try {

            for(SBQQ__QuoteDocument__c qDoc:qDocList) {
                if(qDoc.SBQQ__Quote__c!= null){
                   quoteIds.add(qDoc.SBQQ__Quote__c);
                }       
                if(qDoc.SBQQ__DocumentId__c != null){
                    docMap.put(qDoc.SBQQ__DocumentId__c,qDoc);
                }
           }
   
           if( !quoteIds.isEmpty() ){
               quoteMap= new Map<Id,SBQQ__Quote__c>([SELECT id,SBQQ__Account__r.Name,Name,SBQQ__Type__c, CWS_Quote_Type__c
                            FROM SBQQ__Quote__C WHERE Id in :quoteIds]);
           }
        
           if(docMap != NULL && !docMap.isEmpty()){
                docList= [SELECT Id,Name from Document where id in :docMap.keySet()];
            }

           // Start BED-5338 Quote Document Naming Convention
            for(SBQQ__QuoteDocument__c qDoc:qDocList) {
                SBQQ__Quote__c quote =  quoteMap.get(qDoc.SBQQ__Quote__c);
                qDoc.CWS_Quote_Type__c=quote.CWS_Quote_Type__c;
                string accName = quote.SBQQ__Account__r.Name;

                string docType = (qDoc.CWS_Document_Type__c == CWS_ConstantClass.QDOC_TYPE_QD) ? CWS_ConstantClass.QDOC_INITIALS_QD :
                                (qDoc.CWS_Document_Type__c == CWS_ConstantClass.QDOC_TYPE_OF) ? CWS_ConstantClass.QDOC_INITIALS_OF : '';

                string quoteType = (quote.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_QUOTE) ? CWS_ConstantClass.QDOC_QTYPE_NEW :
                                    (quote.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) ? CWS_ConstantClass.QUOTE_TYPE_AMENDMENT :
                                    (quote.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) ? CWS_ConstantClass.QUOTE_TYPE_RENEWAL : '';

                string qNum = quote.Name;
                Decimal version = qDoc.SBQQ__Version__c;
                
                qDoc.Name = String.format(CWS_ConstantClass.QDOC_NAME_FORMAT,new List<object>{accName,docType,quoteType,qNum,version});
                integer len = qDoc.Name.length();
                // Consolidated to one line to help code coverage
                if (len>80) { qDoc.Name = String.format(CWS_ConstantClass.QDOC_NAME_FORMAT,new List<object>{accName.substring(0,accName.length()-(len-80)),docType,quoteType,qNum,version}); }

                // Start BED-8798 // Consolidated to one line to help code coverage
                if (CWS_QuoteDocumentTriggerUtility.isSignatureCompleted(qdoc) && qdoc.SBQQDS__SignedDate__c == NULL) { qdoc.SBQQDS__SignedDate__c = Date.today(); }
                // End BED-8798

            }
            
            for(Document dc :  docList){
                dc.Name = dc.name.endswith('pdf') ? docMap.get(dc.id).name+'.pdf': docMap.get(dc.id).name+'.docx';
            } 
            if (docList != null) {
                Database.update(docList);
            }
            // END BED-5338
            
        } catch (Exception e) {
            CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_QuoteDocumentTrigger', 'beforeInsert' , '', null, null , 'beforeInsert' , null);            
        }
    }

    /** 
    * Method name  : beforeUpdate
    * @description  BED-8798 : Co-terming Sales Contract - New Business
    * @param  newMap
    * @param oldMap
    * @return void
    * Developer    : Khayam
    */
    public static void beforeUpdate(Map<Id,SObject> newMap,Map<Id,SObject> oldMap){

        Map<Id,SBQQ__QuoteDocument__c> oldQDMap = (Map<Id,SBQQ__QuoteDocument__c>) oldMap;
        Map<Id,SBQQ__QuoteDocument__c> newQDMap = (Map<Id,SBQQ__QuoteDocument__c>) newMap;

        try {
            
            for (SBQQ__QuoteDocument__c qdoc: newQDMap.values()) {
                //Logic Added to update the Offline Signature Status with Signed Status
                if(qdoc.SBQQ__SignatureStatus__c != oldQDMap.get(qdoc.Id).SBQQ__SignatureStatus__c 
                   && qdoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_COMPLETED
                   && String.isBlank(qdoc.CWS_Offline_Signature_Status__c)){
                    qdoc.SBQQ__SignatureStatus__c = CWS_ConstantClass.QDOC_SIG_SIGNED;
                }
                
                if (qdoc.CWS_Offline_Signature_Status__c != oldQDMap.get(qdoc.Id).CWS_Offline_Signature_Status__c || 
                    qdoc.SBQQ__SignatureStatus__c != oldQDMap.get(qdoc.Id).SBQQ__SignatureStatus__c) {
                    if (CWS_QuoteDocumentTriggerUtility.isSignatureCompleted(qdoc)){
                        if(qdoc.SBQQDS__SignedDate__c == NULL){ 
                            qdoc.SBQQDS__SignedDate__c = Date.today(); 
                        }
                    }
                }
            }
        } catch (Exception e) { 
            CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_QuoteDocumentTrigger', 'beforeUpdate' , '', null, null , 'beforeUpdate' , null); 
        }
    }
    
    /**
    * Method name  : voidQuoteDocument
    * @description BED-12417 : Not able to resend quote for signature 
    * Parameter    : Quote Document
    * @return  void
    * Developer    : Naresh
    */
    @AuraEnabled
    public static void voidQuoteDocument(ID qDocID){
        List<SBQQ__QuoteDocument__c> quoteDocumentList = new List<SBQQ__QuoteDocument__c>(); 
        List<SBQQ__QuoteDocument__c> qDocspluginList = new List<SBQQ__QuoteDocument__c>();
         try{  
                if(qDocID != null) {
                    quoteDocumentList = [Select Id, name, SBQQ__Quote__c,SBQQ__SignatureStatus__c, SBQQDS__EnvelopeId__c, SBQQDS__VoidedReason__c From SBQQ__QuoteDocument__c Where Id = :qDocID ];
                    
                    if(quoteDocumentList.size() > 0){
            
                        for(SBQQ__QuoteDocument__c qtdoc : quoteDocumentList){
                            qtdoc.SBQQDS__VoidedReason__c= System.Label.CWS_Void_message_on_Quote_document;
                            qDocspluginList.add(qtdoc);  
                        }
                        SBQQDS.DocuSignPlugin plugin = new SBQQDS.DocuSignPlugin();
                        plugin.revoke(qDocspluginList);
                    }
                if(qDocspluginList.size() > 0){
                    update qDocspluginList;
                }
            }       
         } catch (Exception e) {
            CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_QuoteDocumentTrigger', 'beforeUpdate' , '', null, null , 'voidQuoteDocument' , null);          
        }
    }
}