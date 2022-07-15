/*Class Name: CWS_AgreementTriggerHelper
*Description: Helper Class for CWS_AgreementTriggerHandler
*Created By: Akhila
*Created On: 30/04/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                  30/04/2020        BED-3087     Populate MSA/NDA/BAA agreement fields on Account
*Akhila					 05/05/2020		   BED-2880		Update status to In authoring on document generation
*/

public class CWS_AgreementTriggerHelper {
    
	public static void beforeInsert(List<Apttus__APTS_Agreement__c> NewSObjectRecs){
        try{
            //BED-5644 populate original agreement execution date when amended agreement is created
            for(Apttus__APTS_Agreement__c agg : NewSObjectRecs){
                if(agg.Apttus__Status__c == CWS_ConstantClass.AGREEMENT_STATUS_In_Amendment && agg.Apttus__Other_Party_Signed_Date__c != null){
                    agg.CWS_Original_Agreement_Execution_Date__c = agg.Apttus__Other_Party_Signed_Date__c;
                    agg.Apttus_Approval__Approval_Status__c = CWS_ConstantClass.Approval_Not_Submitted;
                }
            }
            //END BED-5644
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Agreement' , 'CWS_AgreementTriggerHelper', 'beforeInsertMethod' , '', null, null , 'Beforeinsert' , null);
        }
    }
    public static void afterInsert(Map<Id, SObject> NewSObjectRecs){    
        try{
            list<Apttus__APTS_Agreement__c> NewRecs = new list<Apttus__APTS_Agreement__c>();
            if(NewSObjectRecs != null){
                NewRecs = NewSObjectRecs.values();
            }
            Set<Id> acctIds = new Set<Id>();
            List<Account> acctLst = new List<Account>();
            Map<Id,Account> acctMap;
            
            for(Apttus__APTS_Agreement__c agreementRec : NewRecs){
                acctIds.add(agreementRec.Apttus__Account__c);
            }
            if(acctIds != null){
                acctMap = new Map<Id, Account>([SELECT Id,CWS_BA_Agreement__c,CWS_BA_Agreement_Status__c,CWS_MSA_Agreement_Status__c,CWS_NDA_Agreement_Status__c,CWS_MSA_Agreement__c,CWS_NDA_Agreement__c FROM Account WHERE Id IN :acctIds]);
            }
            for(Apttus__APTS_Agreement__c agrmnt : NewRecs){
                Account accRec;
                if(acctMap.containsKey(agrmnt.Apttus__Account__c)){
                    accRec = acctMap.get(agrmnt.Apttus__Account__c);
                }
                if(agrmnt.RecordTypeId == CWS_ConstantClass.NDA_Agreement_RT){
                    accRec.CWS_NDA_Agreement__c = agrmnt.Apttus__Contract_Number__c;
                    accRec.CWS_NDA_Agreement_Status__c = agrmnt.Apttus__Status_Category__c;
                }
                if(agrmnt.RecordTypeId == CWS_ConstantClass.MSA_Agreement_RT){
                    accRec.CWS_MSA_Agreement__c = agrmnt.Apttus__Contract_Number__c;
                    accRec.CWS_MSA_Agreement_Status__c = agrmnt.Apttus__Status_Category__c;
                }
                if(agrmnt.RecordTypeId == CWS_ConstantClass.BAA_Agreement_RT){
                    accRec.CWS_BA_Agreement__c = agrmnt.Apttus__Contract_Number__c;
                    accRec.CWS_BA_Agreement_Status__c = agrmnt.Apttus__Status_Category__c;
                }
                acctLst.add(accRec);
            }
			if(acctLst != null && !acctLst.isEmpty()){
				update acctLst;
            }      
			List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipientList = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
            for(Apttus__APTS_Agreement__c agrmnt : NewRecs){
                if(agrmnt.Apttus__Other_Party_Signed_By__c != null){
                    Apttus_DocuApi__DocuSignDefaultRecipient2__c recipient = new Apttus_DocuApi__DocuSignDefaultRecipient2__c();
                    recipient.Apttus_DocuApi__ContactId__c = agrmnt.Apttus__Other_Party_Signed_By__c;
                    recipient.Apttus_CMDSign__AgreementId__c = agrmnt.Id;
                    recipient.Apttus_DocuApi__SigningOrder__c = 1;
                    recipient.Apttus_DocuApi__RoleName__c = 'Signer 1';
                    recipientList.add(recipient);
                }
                if(agrmnt.CWS_Secondary_Recipient__c != null){
                    Apttus_DocuApi__DocuSignDefaultRecipient2__c recipient = new Apttus_DocuApi__DocuSignDefaultRecipient2__c();
                    recipient.Apttus_DocuApi__ContactId__c = agrmnt.CWS_Secondary_Recipient__c;
                    recipient.Apttus_CMDSign__AgreementId__c = agrmnt.Id;
                    recipient.Apttus_DocuApi__SigningOrder__c = 2;
                    recipient.Apttus_DocuApi__RoleName__c = 'Signer 2';
                    recipientList.add(recipient);
                }
            }
            if(recipientList != null && !recipientList.isEmpty()){
                insert recipientList;
            }
			
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Agreement' , 'CWS_AgreementTriggerHelper', 'afterInsertMethod' , '', null, null , 'Afterinsert' , null);
        }
    }
    
    public static void beforeUpdate(Map<Id, Apttus__APTS_Agreement__c> NewSObjectRecs, map<id,Apttus__APTS_Agreement__c> mapOfOldSObjectRecs){    
        try{            
            for(Apttus__APTS_Agreement__c agreementRec : NewSObjectRecs.values()){
                Apttus__APTS_Agreement__c oldAgrmnt = mapOfOldSObjectRecs.get(agreementRec.Id);
                if(oldAgrmnt.Apttus__Status_Category__c == CWS_ConstantClass.Request_Status && (oldAgrmnt.Apttus__Status__c == CWS_ConstantClass.Request_Status || oldAgrmnt.Apttus__Status__c == CWS_ConstantClass.AGREEMENT_STATUS_In_Amendment) && oldAgrmnt.Apttus__Workflow_Trigger_Viewed_Final__c == false && agreementRec.Apttus__Workflow_Trigger_Viewed_Final__c == true){
                       agreementRec.Apttus__Status_Category__c = CWS_ConstantClass.In_Authoring_Status;
                       agreementRec.Apttus__Status__c = CWS_ConstantClass.In_Authoring_Status;
                   }
			 //BED-9187 START
                //Update start date, other party signed date based on signed date
                if(agreementRec.Apttus__Status__c != oldAgrmnt.Apttus__Status__c && agreementRec.Apttus__Status__c == CWS_ConstantClass.Agreement_Status_Fully_Signed
                   && oldAgrmnt.Apttus__Status__c == CWS_ConstantClass.AGREEMENT_STATUS_Other_party_Signatures){
                       if(agreementRec.RecordTypeId != CWS_ConstantClass.Distributor_Agreement_RT){
                           agreementRec.Apttus__Contract_Start_Date__c = System.today();
                       }
                       agreementRec.Apttus__Other_Party_Signed_Date__c = System.today();
                       agreementRec.CWS_EnvelopeStatus__c = CWS_ConstantClass.Envelope_Status_Completed;
                   }    
                //BED-9187 Update envelope sent date for wet signatures based on the status change to Other party signatures
                if(agreementRec.Apttus__Status__c != oldAgrmnt.Apttus__Status__c && agreementRec.Apttus__Status__c == CWS_ConstantClass.AGREEMENT_STATUS_Other_party_Signatures
                   && oldAgrmnt.Apttus__Status__c == CWS_ConstantClass.Ready_for_signature_Status){
                       agreementRec.CWS_Envelope_SentDate__c = System.today();
                       agreementRec.CWS_EnvelopeStatus__c = CWS_ConstantClass.Envelope_Status_Sent;
                   }
                if(agreementRec.Apttus__Status__c != oldAgrmnt.Apttus__Status__c && agreementRec.Apttus__Status__c == CWS_ConstantClass.AGREEMENT_STATUS_Signature_Declined){
                    agreementRec.CWS_EnvelopeStatus__c = CWS_ConstantClass.Envelope_Status_Declined;
                }
                if(agreementRec.Apttus__Status_Category__c != oldAgrmnt.Apttus__Status_Category__c && agreementRec.Apttus__Status_Category__c == CWS_ConstantClass.AGREEMENT_STATUS_Cancelled ){
                    agreementRec.CWS_Cancellation_Date__c = System.today();
                }
                //BED-9187 END
				//BED- 2979 Populate Termination date when Agreement is terminated
                if(agreementRec.Apttus__Status_Category__c != oldAgrmnt.Apttus__Status_Category__c && agreementRec.Apttus__Status_Category__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED ){
                    agreementRec.Apttus__Termination_Date__c = System.today();
                    agreementRec.Apttus__Contract_End_Date__c = System.today();
                }
            }
            
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Agreement' , 'CWS_AgreementTriggerHelper', 'afterInsertMethod' , '', null, null , 'Afterinsert' , null);
        }
    }
    public static void afterUpdate(Map<Id, Apttus__APTS_Agreement__c> NewSObjectRecs, map<id,Apttus__APTS_Agreement__c> mapOfOldSObjectRecs){    
        try{
            Set<Id> acctIds = new Set<Id>();
            List<Account> acctLst = new List<Account>();
            Map<Id,Account> acctMap;
            Set<Id> otherPartyIds = new Set<Id>();
            Set<Id> secRecipientIds = new Set<Id>();
            List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipientList = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
            
            for(Apttus__APTS_Agreement__c agreementRec : NewSObjectRecs.values()){
                acctIds.add(agreementRec.Apttus__Account__c);
				if(agreementRec.Apttus__Other_Party_Signed_By__c != null){
                    otherPartyIds.add(agreementRec.Apttus__Other_Party_Signed_By__c);
                }
                if(agreementRec.CWS_Secondary_Recipient__c != null){
                    secRecipientIds.add(agreementRec.CWS_Secondary_Recipient__c);
                }
            }
            if(acctIds != null){
                acctMap = new Map<Id,Account>([SELECT Id,CWS_BA_Agreement__c,CWS_BA_Agreement_Status__c,CWS_MSA_Agreement_Status__c,CWS_NDA_Agreement_Status__c,CWS_MSA_Agreement__c,CWS_NDA_Agreement__c FROM Account WHERE Id IN :acctIds]);
            }
            for(Apttus__APTS_Agreement__c agrmnt : NewSObjectRecs.values()){
                
                Apttus__APTS_Agreement__c oldAgrmnt = mapOfOldSObjectRecs.get(agrmnt.Id);
                Account accRec;
                if(acctMap.containsKey(agrmnt.Apttus__Account__c)){
                    accRec = acctMap.get(agrmnt.Apttus__Account__c);
                }
                if(agrmnt.Apttus__Status_Category__c != oldAgrmnt.Apttus__Status_Category__c){
                    if(agrmnt.RecordTypeId == CWS_ConstantClass.NDA_Agreement_RT){
                        accRec.CWS_NDA_Agreement_Status__c = agrmnt.Apttus__Status_Category__c;
                    }
                    if(agrmnt.RecordTypeId == CWS_ConstantClass.MSA_Agreement_RT){
                        accRec.CWS_MSA_Agreement_Status__c = agrmnt.Apttus__Status_Category__c;
                    }
                    if(agrmnt.RecordTypeId == CWS_ConstantClass.BAA_Agreement_RT){
                        accRec.CWS_BA_Agreement_Status__c = agrmnt.Apttus__Status_Category__c;
                    }
                }
                acctLst.add(accRec);
            }
            if(acctLst != null && !acctLst.isEmpty()){
                update acctLst;
            }
            Boolean otherPartyContact = False;
            Boolean secondaryContact = False;
            //BED-2619 Start
            //Creating Docusign Recipient records if Other Party Signed by/Secondary Recipient fields are populated
            List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipientLst= [Select Id,Apttus_CMDSign__AgreementId__c,Apttus_DocuApi__ContactId__c from Apttus_DocuApi__DocuSignDefaultRecipient2__c where Apttus_CMDSign__AgreementId__c IN: NewSObjectRecs.keySet() AND (Apttus_DocuApi__ContactId__c IN: secRecipientIds OR Apttus_DocuApi__ContactId__c IN: otherPartyIds)];
            for(Apttus_DocuApi__DocuSignDefaultRecipient2__c recipient : recipientLst){
                if(otherPartyIds.contains(recipient.Apttus_DocuApi__ContactId__c)){
                    otherPartyContact = true;
                }
                if(secRecipientIds.contains(recipient.Apttus_DocuApi__ContactId__c)){
                    secondaryContact = true;
                }
            }
            for(Apttus__APTS_Agreement__c agrmnt : NewSObjectRecs.values()){
                Apttus__APTS_Agreement__c oldAgrmnt = mapOfOldSObjectRecs.get(agrmnt.Id);
                if(otherPartyContact != true){
                    if((oldAgrmnt.Apttus__Other_Party_Signed_By__c == null && agrmnt.Apttus__Other_Party_Signed_By__c != null) || (oldAgrmnt.Apttus__Other_Party_Signed_By__c != agrmnt.Apttus__Other_Party_Signed_By__c)){
                        Apttus_DocuApi__DocuSignDefaultRecipient2__c recipient = new Apttus_DocuApi__DocuSignDefaultRecipient2__c();
                        recipient.Apttus_DocuApi__ContactId__c = agrmnt.Apttus__Other_Party_Signed_By__c;
                        recipient.Apttus_CMDSign__AgreementId__c = agrmnt.Id;
                        recipientList.add(recipient);
                    }
                }
                if(secondaryContact != true){
                    if((oldAgrmnt.CWS_Secondary_Recipient__c == null && agrmnt.CWS_Secondary_Recipient__c != null) || (oldAgrmnt.CWS_Secondary_Recipient__c != agrmnt.CWS_Secondary_Recipient__c)){
                        Apttus_DocuApi__DocuSignDefaultRecipient2__c recipient = new Apttus_DocuApi__DocuSignDefaultRecipient2__c();
                        recipient.Apttus_DocuApi__ContactId__c = agrmnt.CWS_Secondary_Recipient__c;
                        recipient.Apttus_CMDSign__AgreementId__c = agrmnt.Id;
                        recipientList.add(recipient);
                    }
                }
            }
            if(recipientList != null && !recipientList.isEmpty()){
                insert recipientList;
            }
            // BED-2916 End
            
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Agreement' , 'CWS_AgreementTriggerHelper', 'afterInsertMethod' , '', null, null , 'Afterinsert' , null);
        }
    }
    
}