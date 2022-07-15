/*Class Name: CWS_QuoteDocumentSyncQuoteStage
*@description: Quote document sync quote class for CWS_QuoteDocumentTriggerHelper class 
*Created By: Carl Shahan
*Created On: 01/14/2021
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story      Description
*------------------------------------------------------------------------------------------
*Carl Shahan 01/14/2021  #14154761      Created this class to augment the functionality in the CWS_QuoteDocumentTriggerHelper class
*/
public with sharing class CWS_QuoteDocumentSyncQuoteStage { 
        
    /* @description:  BED-5213 : Quote Stage sync with Quote Documents
     * @return; void */
    public static void syncQuoteDocumentQuoteStage(Map<Id,SObject> newMap,Map<Id,SObject> oldMap) {

        Map<Id,SBQQ__QuoteDocument__c> oldQDMap = (Map<Id,SBQQ__QuoteDocument__c>) oldMap;
        Map<Id,SBQQ__QuoteDocument__c> newQDMap = (Map<Id,SBQQ__QuoteDocument__c>) newMap;        
        Map<Id,SBQQ__Quote__c> ofgQuotes = new Map<Id,SBQQ__Quote__c>();
        Map<Id,SBQQ__Quote__c> awtSigQuotes = new Map<Id,SBQQ__Quote__c>();
        Map<Id,SBQQ__Quote__c> accQuotes = new Map<Id,SBQQ__Quote__c>();
        Map<Id,SBQQ__Quote__c> subStageQuotes = new Map<Id,SBQQ__Quote__c>();
        Map<Id,SBQQ__Quote__c> allQuotes = new Map<Id,SBQQ__Quote__c>();
        Map<Id,SBQQ__QuoteDocument__c> quoteDocMap = new Map<Id,SBQQ__QuoteDocument__c>();
        Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>(); 
        Set<Id> quoteIds = new set<Id>();
        List<Id> lstContIds = new List<Id>();
        List<Contract> lstContractUpdate=new List<Contract>();
                
        //BED-10977
        List<Messaging.SingleEmailMessage> msgList=new List<Messaging.SingleEmailMessage>();
        Set<Id> renOFgeneratedQuotes=new Set<Id>();
        Map<String, String> mapConstants=new Map<String, String>();
        for(CWS_Renewal_Email_Settings__mdt ren:[SELECT  MasterLabel, DeveloperName, CWS_Value__c FROM CWS_Renewal_Email_Settings__mdt LIMIT 100]){
            mapConstants.put(ren.MasterLabel,ren.CWS_Value__c);
        }

        Set<Id> renNoticeSentQuotes=new Set<Id>();        
        List<CWS_EnvelopeRequestWrapper> envelopeRequestWrapperList=new List<CWS_EnvelopeRequestWrapper>();        
        Set<Id> renDocumentIds=new Set<Id>();
        Map<Id, Document> mapDocument=new Map<Id, Document>();
        //END BED_10977
        
        try {

            for(SBQQ__QuoteDocument__c qDoc:newQDMap.values()) {
                if(qDoc != null && qDoc.SBQQ__Quote__c!= null){
                    quoteIds.add(qDoc.SBQQ__Quote__c);
                    quoteDocMap.put(qDoc.SBQQ__Quote__c,qDoc);
                }
                if(qDoc.CWS_Quote_Type__c==CWS_ConstantClass.Quote_Type_Renewal ){
                    renDocumentIds.add(qDoc.SBQQ__DocumentId__c);
                }
            }
            if(!renDocumentIds.isEmpty()){
                mapDocument=new Map<Id, Document>([Select Id, type, contentType, name, body, developerName from Document
                                                where id in:renDocumentIds]);
            }
            // BED-5930
            if(!quoteIds.isEmpty()){ 
                quoteMap= new Map<Id,SBQQ__Quote__c>([SELECT id,Name, SBQQ__Account__r.CWS_BA_Agreement__c, SBQQ__Account__r.CWS_BA_Agreement_Status__c,
                SBQQ__Account__r.CWS_MSA_Agreement__c, SBQQ__Account__r.CWS_MSA_Agreement_Status__c, SBQQ__Account__r.CWS_NDA_Agreement__c,
                SBQQ__Account__r.CWS_NDA_Agreement_Status__c, CWS_Quote_Type__c, CWS_Route_to_Market__c, SBQQ__Opportunity2__c,
                SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c, SBQQ__Status__c, CWS_Renewal_Type__c, SBQQ__Primary__c, SBQQ__PrimaryContact__c,
                SBQQ__PrimaryContact__r.Email, SBQQ__PrimaryContact__r.Name, CWS_Bill_to_Contact__r.Email, CWS_Bill_to_Contact__r.Name,
                CWS_Secondary_Recipient_Email__c, CWS_Secondary_Recipient_Name__c, CWS_Bill_to_Contact__c, CWS_Renewal_Notice_Sent_Date__c,
                SBQQ__Opportunity2__r.SBQQ__RenewedContract__c, SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate,
                SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_30_Days_Sent__c, SBQQ__Opportunity2__r.StageName,
                SBQQ__Opportunity2__r.Account.CWS_Additional_Emails_for_Invoice__c, CWS_Renewal_Document_Generated_Date__c, CWS_Sold_To_Account_Text__c,
                SBQQ__StartDate__c, CWS_Master__c, CWS_On_Hold__c, CWS_Transaction_Reason__c, CWS_Renewal_Category__c,
                (SELECT id,CWS_Additional_Restrictions__c,SBQQ__StartDate__c,CWS_Transaction_Type__c,CWS_ServicesProvisioned__c,CWS_Provisioning_Eligibility__c,CWS_ProvisioningDate__c from SBQQ__LineItems__r limit :Limits.getLimitQueryRows())
                FROM SBQQ__Quote__C WHERE Id in :quoteIds]);
            }
            Id templateId;
            List<User> lstUser;
            if(oldMap==null && UserInfo.getUserId()!=null){
                lstUser=[Select Id, CWS_Renewal_Batch_User__c from User where id =:UserInfo.getUserId()];
            }
            /* All quotes must have the following attibutes: CWS_Quote_Type__c = Renewal, CWS_On_Hold__c = false, CWS_Master__c = false
             * Contract must have EndDate > Today  
             * Must be run using an account with User account CWS_Renewal_Batch_User__c= true */
            for (SBQQ__QuoteDocument__c qDoc : newQDMap.values()) {
                SBQQ__Quote__c quote =  quoteMap.get(qDoc.SBQQ__Quote__c);
                
                System.debug('** SBQQ__RenewedContract__r.EndDate = ' + quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate);
                System.debug('** CWS_Renewal_Document_Generated_Date__c = ' + quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Renewal_Document_Generated_Date__c);

                if( oldMap==null && lstUser!=null && !lstUser.isEmpty() && lstUser[0].CWS_Renewal_Batch_User__c==TRUE && 
                    qDoc.SBQQ__Quote__c!=null && quoteMap!=null && quoteMap.containsKey(qDoc.SBQQ__Quote__c) &&
                    quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Quote_Type__c==CWS_ConstantClass.Quote_Type_Renewal && 
                    (quoteMap.get(qDoc.SBQQ__Quote__c).CWS_On_Hold__c==false ||  quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Master__c==TRUE) &&    
                    quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__c!=null && 
                    quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c!=null && 
                    !quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_30_Days_Sent__c && 
                    quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate!=null &&
                    quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate>=Date.today() && 
                    quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate-30<=Date.today() &&
                    quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Renewal_Document_Generated_Date__c==null && 
                    ((Label.CWS_Renewal_Email_Batch_Switch30Days == CWS_ConstantClass.RENEWAL_BATCH_ON) || Test.isRunningTest())){
                    
                    renOFgeneratedQuotes.add(qDoc.SBQQ__Quote__c);
                    
                    System.debug('** Quote name = ' + quote.Name);
                    
                    //RENEWALCAT_CHANGE_REQ - Changing the Renewal Type Reference to Renewal Category            
                    if(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Renewal_Category__c==CWS_ConstantClass.Renewal_Type_OptOut) {                   
                        //BED-12735 Start. Checking for Additional emails on sold to account.                        
                        List<String> additionalEmailsList = new List<String>();
                        if(quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.Account.CWS_Additional_Emails_for_Invoice__c != null) {
                            String addEmailContent = quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.Account.CWS_Additional_Emails_for_Invoice__c;

                            if(addEmailContent.contains(',')) {
                                additionalEmailsList = addEmailContent.split(',');
                            }
                            else{ additionalEmailsList.add(addEmailContent); }
                        }                        
                        //BED-12735 End
                        
                        if(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Route_to_Market__c==CWS_ConstantClass.RTM_Value_Direct && 
                            mapConstants!=null && mapConstants.get('EndCustomerQuoteTemplateId')!=null && 
                            qDoc.SBQQ__QuoteTemplate__c==mapConstants.get('EndCustomerQuoteTemplateId')) {
                            
                            if(quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__PrimaryContact__c!=null) {
                            templateId=mapConstants.get('RNOptOutEmailTemplate');
                            Messaging.SingleEmailMessage message1 = new Messaging.SingleEmailMessage();
                            message1.setTargetObjectId(quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__PrimaryContact__c);
                            message1.setSaveAsActivity(true);
                            message1.setTemplateID(templateId);
                            message1.setWhatId(qDoc.SBQQ__Opportunity__c);
                            message1.setEntityAttachments(new List<Id>{qDoc.SBQQ__DocumentId__c});
                                //BED-12735 Start
                                if (!additionalEmailsList.isEmpty()) { 
                                    message1.setCcAddresses(additionalEmailsList);
                                }
                            
                            msgList.add(message1);
                            renNoticeSentQuotes.add(qDoc.SBQQ__Quote__c);
                            lstContIds.add(quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);

                            }
                        }
                        else if(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Route_to_Market__c!=CWS_ConstantClass.RTM_Value_Direct && 
                            mapConstants!=null && mapConstants.get('DistiQuoteTemplateId')!=null && 
                            qDoc.SBQQ__QuoteTemplate__c==mapConstants.get('DistiQuoteTemplateId') && 
                            mapConstants.get('RNOptOutDistiEmailTemplate')!=null) {
                                
                            if(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Bill_to_Contact__c!=null) {
                                templateId=mapConstants.get('RNOptOutDistiEmailTemplate');                     
                                renOFgeneratedQuotes.add(qDoc.SBQQ__Quote__c);
                                Messaging.SingleEmailMessage message1 = new Messaging.SingleEmailMessage();
                                message1.setTargetObjectId(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Bill_to_Contact__c);
                                message1.setSaveAsActivity(true);
                                message1.setTemplateID(templateId);
                                message1.setEntityAttachments(new List<Id>{qDoc.SBQQ__DocumentId__c});
                                message1.setWhatId(qDoc.SBQQ__Opportunity__c);
                                if(!additionalEmailsList.isEmpty()){ //BED-12735 Start
                                    message1.setCcAddresses(additionalEmailsList);
                                }//BED-12735 END
                                
                                msgList.add(message1);     
                                renNoticeSentQuotes.add(qDoc.SBQQ__Quote__c);   
                                lstContIds.add(quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);                               
                            }
                        }
                    }
                    //RENEWALCAT_CHANGE_REQ - Changing the Renewal Type Reference to Renewal Category
                    else if(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Renewal_Category__c==CWS_ConstantClass.Renewal_Type_OptIn) {
                        if(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Route_to_Market__c==CWS_ConstantClass.RTM_Value_Direct){ 
                            if(quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__PrimaryContact__c!=null){
                               envelopeRequestWrapperList.add(new CWS_EnvelopeRequestWrapper
                                   (mapConstants.get('EndCustomerDSTemplateId'), 
                               qDoc.SBQQ__DocumentId__c, 
                                quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__PrimaryContact__r.Email,
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Secondary_Recipient_Email__c,
                                'Signer','Signer',
                                quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__PrimaryContact__r.Name,
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Secondary_Recipient_Name__c,
                                'Contract Renewal Notification',
                                qDoc.SBQQ__Quote__c,
                                qDoc.Id,
                                qDoc.SBQQ__Opportunity__c,
                                //RENEWALCAT_CHANGE_REQ - Changing the Renewal Type Reference to Renewal Category
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Renewal_Category__c,
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Route_to_Market__c,
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Sold_To_Account_Text__c
                                ));
                            }
                        }
                        else if(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Route_to_Market__c!=CWS_ConstantClass.RTM_Value_Direct){
                            if(quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Bill_To_Contact__c!=null){
                               envelopeRequestWrapperList.add(new CWS_EnvelopeRequestWrapper(mapConstants.get('DistiDSTemplateId'), 
                               qDoc.SBQQ__DocumentId__c, 
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Bill_to_Contact__r.Email,
                                null,
                                'Signer',null,
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Bill_to_Contact__r.Name,
                                null,
                                'Contract Renewal Notification',
                                qDoc.SBQQ__Quote__c,
                                qDoc.Id,
                                qDoc.SBQQ__Opportunity__c,
                                //RENEWALCAT_CHANGE_REQ - Changing the Renewal Type Reference to Renewal Category
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Renewal_Category__c,
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Route_to_Market__c,
                                quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Sold_To_Account_Text__c
                                ));
                            } 
                        }
                    }
                }
                // moving Quote to Order Form Generated - After Insert
                if (oldMap == null && qDoc.CWS_Document_Type__c != CWS_ConstantClass.QDOC_TYPE_QD 
                     && (quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c != CWS_ConstantClass.DistiEndCustomer || 
                    (quoteMap.get(qDoc.SBQQ__Quote__c).CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL)) &&
                    qDoc.SBQQ__SignatureStatus__c != CWS_ConstantClass.QDOC_SIG_SENT &&
                    qDoc.CWS_Offline_Signature_Status__c != CWS_ConstantClass.QDOC_SIG_SENT &&
                    qDoc.SBQQ__SignatureStatus__c != CWS_ConstantClass.QDOC_SIG_SIGNED &&
                    qDoc.SBQQ__SignatureStatus__c != CWS_ConstantClass.QDOC_SIG_COMPLETED &&
                    qDoc.CWS_Offline_Signature_Status__c != CWS_ConstantClass.QDOC_SIG_SIGNED) {
                        ofgQuotes.put(qDoc.SBQQ__Quote__c,new SBQQ__Quote__c(id=qDoc.SBQQ__Quote__c));
                }
    
                // moving Quote to Awaiting Signature - After Insert
                if (oldMap == null && qDoc.CWS_Document_Type__c != CWS_ConstantClass.QDOC_TYPE_QD &&
                    qDoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_SENT &&
                    qDoc.CWS_Offline_Signature_Status__c == CWS_ConstantClass.QDOC_SIG_SENT && quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c != CWS_ConstantClass.DistiEndCustomer) {
                        awtSigQuotes.put(qDoc.SBQQ__Quote__c,new SBQQ__Quote__c(id=qDoc.SBQQ__Quote__c));
                }
    
                // moving Quote to Accepted - After Insert
                if (oldMap == null && qDoc.CWS_Document_Type__c != CWS_ConstantClass.QDOC_TYPE_QD && CWS_QuoteDocumentTriggerUtility.isSignatureCompleted(qDoc) && quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c != CWS_ConstantClass.DistiEndCustomer) {
                        accQuotes.put(qDoc.SBQQ__Quote__c,new SBQQ__Quote__c(id=qDoc.SBQQ__Quote__c));
                }
    
                // After Update
                if (oldQDMap != null && qDoc.CWS_Document_Type__c != CWS_ConstantClass.QDOC_TYPE_QD && 
                    (qDoc.SBQQ__SignatureStatus__c != oldQDMap.get(qDoc.id).SBQQ__SignatureStatus__c || 
                    qDoc.CWS_Offline_Signature_Status__c != oldQDMap.get(qDoc.id).CWS_Offline_Signature_Status__c)) {
    
                        // moving Quote to Order Form Generated - After Update
                        if (qDoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_DECLINED ||
                            qDoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_Voided ||
                            qDoc.CWS_Offline_Signature_Status__c == CWS_ConstantClass.QDOC_SIG_DECLINED) {
                            ofgQuotes.put(qDoc.SBQQ__Quote__c,new SBQQ__Quote__c(id=qDoc.SBQQ__Quote__c));
                        }

                        // moving Quote to Awaiting Signature - After Update
                         if ((((qDoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_SENT && qDoc.CWS_Offline_Signature_Status__c != CWS_ConstantClass.QDOC_SIG_SIGNED) 
                            || qDoc.CWS_Offline_Signature_Status__c == CWS_ConstantClass.QDOC_SIG_SENT)) 
                            && quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c != CWS_ConstantClass.DistiEndCustomer) {
                                awtSigQuotes.put(qDoc.SBQQ__Quote__c,new SBQQ__Quote__c(id=qDoc.SBQQ__Quote__c));
                        }
    
                        // moving Quote to Accepted - After Update
                        boolean agrmntsInEffect = CWS_QuoteDocumentTriggerUtility.quoteAgreementInEffect(quote);
                        
                        if (!CWS_QuoteDocumentTriggerUtility.isProvisioningPending(quote) && agrmntsInEffect  && CWS_QuoteDocumentTriggerUtility.isSignatureCompleted(qDoc) && quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c != CWS_ConstantClass.DistiEndCustomer) {
                            accQuotes.put(qDoc.SBQQ__Quote__c,new SBQQ__Quote__c(id=qDoc.SBQQ__Quote__c));
                        }
                        //BED-7862
                        if(quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG && CWS_QuoteDocumentTriggerUtility.isSignatureCompleted(qDoc) && !agrmntsInEffect && quoteMap.get(qDoc.SBQQ__Quote__c).SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c != CWS_ConstantClass.DistiEndCustomer){
                            subStageQuotes.put(quote.Id,new SBQQ__Quote__c(id=quote.Id, CWS_Sub_Stage__c=CWS_ConstantClass.Sub_Stage));
                        }
                        //BED-7862

                       //BED-8869 starts
                        //BED-13052
                        //if (isProvisioningPending(quote) && quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG) {
                        if ((CWS_QuoteDocumentTriggerUtility.isProvisioningPending(quote) || (quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS )) && CWS_QuoteDocumentTriggerUtility.isSignatureCompleted(qDoc) && quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG) {
                            SBQQ__Quote__c qTemp = subStageQuotes.get(quote.Id);
                            if (qTemp!=null) {
                                qTemp.CWS_Sub_Stage__c = CWS_ConstantClass.ORDER_STATUS_PENDING_FULFILLMENT;
                            } else {
                                subStageQuotes.put(quote.Id,new SBQQ__Quote__c(id=quote.Id, CWS_Sub_Stage__c=CWS_ConstantClass.ORDER_STATUS_PENDING_FULFILLMENT));
                            }
                        }
                        //BED-13052
                        //BED-8869 ends
                    
                }              
            }        
            
            if(mapDocument!=null && !mapDocument.keySet().isEmpty() && envelopeRequestWrapperList!=null &&
                !envelopeRequestWrapperList.isEmpty()){
                CWS_AsyncSendRenewalNotice async=new CWS_AsyncSendRenewalNotice(envelopeRequestWrapperList, mapDocument);
                Id jobId=System.enqueueJob(async);
                
            }
            
            if (!ofgQuotes.isEmpty() || !awtSigQuotes.isEmpty() || !accQuotes.isEmpty() || !renOFgeneratedQuotes.isEmpty() || !subStageQuotes.isEmpty()) {
                Set<Id> quoteIdsPrimary=new Set<Id>();  
                for (SBQQ__Quote__c quote : ofgQuotes.values()) {
                    quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN;
                    quote.CWS_Document_Version__c = quoteDocMap.get(quote.id) != null ? quoteDocMap.get(quote.id).SBQQ__Version__c+1 : 1 ;
                    if(quoteMap!=null && quoteMap.get(quote.Id)!=null && 
                        quoteMap.get(quote.Id).CWS_Quote_Type__c==CWS_ConstantClass.Quote_Type_Renewal &&
                        quoteMap.get(quote.Id).SBQQ__Primary__c==FALSE){
                        quoteIdsPrimary.add(quote.Id);
                    }
                }
          
                for (SBQQ__Quote__c quote : awtSigQuotes.values()) {
                    quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG;
                    quote.CWS_Sub_Stage__c= CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG;
                    if(quoteMap!=null && quoteMap.get(quote.Id)!=null && 
                        quoteMap.get(quote.Id).CWS_Quote_Type__c==CWS_ConstantClass.Quote_Type_Renewal && 
                        quoteMap.get(quote.Id).SBQQ__Primary__c==FALSE){
                        quoteIdsPrimary.add(quote.Id);
                    }
                }
                
                Set<Id> quoteIdsToAccept=new Set<Id>();
                for (SBQQ__Quote__c quote : accQuotes.values()) {
                    quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
                    quote.CWS_Sub_Stage__c = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
                    if(quoteMap!=null && quoteMap.get(quote.Id)!=null && 
                       (quoteMap.get(quote.Id).CWS_Quote_Type__c==CWS_ConstantClass.Quote_Type_Renewal ||
                       quoteMap.get(quote.Id).CWS_Quote_Type__c==CWS_ConstantClass.QUOTE_TYPE_RENEWALWC ) &&  
                       quoteMap.get(quote.Id).SBQQ__Opportunity2__c!=null &&
                       quoteMap.get(quote.Id).SBQQ__Opportunity2__r.StageName!=CWS_ConstantClass.OpportunityClosedWon_Stage &&
                       quoteMap.get(quote.Id).SBQQ__Opportunity2__r.StageName!=CWS_ConstantClass.OpportunityClosedLose_Stage &&
                       quoteMap.get(quote.Id).SBQQ__Status__c==CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG && 
                       quoteMap.get(quote.Id).SBQQ__Primary__c==FALSE){ quoteIdsToAccept.add(quote.Id);
                    }
                    else{
                        allQuotes.put(quote.Id, quote);
                    }
                }
                if(quoteIdsToAccept!=null && !quoteIdsToAccept.isEmpty()) { Database.executeBatch(new CWS_BatchAcceptRenewalQuotes(quoteIdsToAccept),1); }

                if(quoteIdsPrimary!=null && !quoteIdsPrimary.isEmpty()) { CWS_QuoteDocumentTriggerUtility.asyncUpdatePrimaryCheckbox(quoteIdsPrimary); }
                    
                allQuotes.putAll(ofgQuotes);
                allQuotes.putAll(awtSigQuotes);
                allQuotes.putAll(subStageQuotes);
                
                if(!msgList.isEmpty()){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(msgList);
                }       
                SBQQ__Quote__c tempQuote;
                if(renOFgeneratedQuotes!=null && !renOFgeneratedQuotes.isEmpty() && allQuotes!=null){
                    for(Id quoteId:renOFgeneratedQuotes){
                        
                        if(allQuotes.containsKey(quoteId) && allQuotes.get(quoteId)!=null){
                            allQuotes.get(quoteId).CWS_Renewal_Document_Generated_Date__c=Date.today();
                            if(renNoticeSentQuotes.contains(quoteId)){
                                allQuotes.get(quoteId).CWS_Renewal_Notice_Sent_Date__c=Date.today();
                            }
                        }
                        else{
                            tempQuote=new SBQQ__Quote__c();
                            tempQuote.Id=quoteId;
                            tempQuote.CWS_Renewal_Document_Generated_Date__c=Date.today();
                            if(renNoticeSentQuotes.contains(quoteId)){
                                tempQuote.CWS_Renewal_Notice_Sent_Date__c=Date.today();
                            }
                            allQuotes.put(quoteId, tempQuote);
                        }
                    }
                }
                if (!allQuotes.isEmpty()) {
                    Database.SaveResult []results = Database.update(allQuotes.values(),FALSE);
                    CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_QuoteDocumentTriggerHelper', 'afterUpdate','SBQQ__QuoteDocument__c' , null, null );
                    
                    String msgBody = '';
                    String subject = 'Failed to update Quote Stage';
                    for (integer i=0;i<results.size();i++) {
                        if(!results[i].isSuccess()){ String recordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + allQuotes.values()[i].id; msgBody += '<br />'+JSON.serialize(results[i].getErrors())+' '+'<a href="'+recordURL+'">Link</a>'; }
                        
                    }
                    if (msgBody.length() > 0){ CWS_CommonUtility.sendEmail(subject, msgBody, new String[]{UserInfo.getUserEmail()}); }
                }
    
            }
            //BED-11397
            if(!lstContIds.isEmpty()){
                for(id contId:lstContIds){
                    contract Con = new Contract(id=contId,CWS_30_Days_Sent__c=true);
                    if(!lstContractUpdate.contains(Con)){
                        lstContractUpdate.add(Con);
                    }
                }
            }
            if(!lstContractUpdate.isEmpty()){
                Database.SaveResult []results = Database.update(lstContractUpdate,FALSE);
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_QuoteDocumentTriggerHelper', 'afterUpdate','SBQQ__QuoteDocument__c' , null, null );
            }
            //BED-11397

        } catch(Exception e){ CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_QuoteDocumentTrigger', 'afterUpdate' , '', null, null , 'afterUpdate' , null); }
    }
}