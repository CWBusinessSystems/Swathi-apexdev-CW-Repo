/*Class Name: CWS_DocusignEnvelopHelper
*Description: Helper Class for CWS_DocusignEnvelopHandler
*Created By: Akhila
*Created On: 15/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                  15/05/2020        BED-2916     Populate agreement status based on envelope status
*/

public class CWS_DocusignEnvelopHelper {
    
    public static void afterUpdate(Map<Id, Apttus_DocuApi__DocuSignEnvelope__c> newItems, Map<Id, Apttus_DocuApi__DocuSignEnvelope__c> oldItems){
        try{
            Map<Id,Apttus__APTS_Agreement__c> agreementMap;
            Set<Id> agrmntIds = new Set<Id>();
            List<Apttus__APTS_Agreement__c> agrmntList = new List<Apttus__APTS_Agreement__c>();
            for(Apttus_DocuApi__DocuSignEnvelope__c docEnvelop: newItems.values()){
                agrmntIds.add(docEnvelop.Apttus_CMDSign__Agreement__c);
            }
            if(agrmntIds != null){
                agreementMap = new Map<Id,Apttus__APTS_Agreement__c>([Select Id,Name,Apttus__Status__c,Apttus__Status_Category__c from Apttus__APTS_Agreement__c where Id IN : agrmntIds]);
            }
            System.debug('Agreement map'+ agreementMap);
            for(Apttus_DocuApi__DocuSignEnvelope__c newEnvelop : newItems.values()){
                Apttus_DocuApi__DocuSignEnvelope__c oldEnvelop = oldItems.get(newEnvelop.Id);
                Apttus__APTS_Agreement__c agreementRec;
                if(agreementMap.containsKey(newEnvelop.Apttus_CMDSign__Agreement__c)){
                    agreementRec = agreementMap.get(newEnvelop.Apttus_CMDSign__Agreement__c);
                }
            	System.debug('Agreement Record'+ agreementRec.Name);
                if(newEnvelop.Apttus_DocuApi__Status__c != oldEnvelop.Apttus_DocuApi__Status__c){
                    agreementRec.Apttus__Status_Category__c = CWS_ConstantClass.In_Signature_Status;
                    
                    if(newEnvelop.Apttus_DocuApi__Status__c == CWS_ConstantClass.Envelope_Status_Completed){
                        agreementRec.Apttus__Status__c = CWS_ConstantClass.Agreement_Status_Fully_Signed;
                    }
                    else if(newEnvelop.Apttus_DocuApi__Status__c == CWS_ConstantClass.Envelope_Status_Sent){
                        agreementRec.Apttus__Status__c = CWS_ConstantClass.AGREEMENT_STATUS_Other_party_Signatures;
                    }
                    else if(newEnvelop.Apttus_DocuApi__Status__c == CWS_ConstantClass.Envelope_Status_Declined){
                        agreementRec.Apttus__Status__c = CWS_ConstantClass.AGREEMENT_STATUS_Signature_Declined;
                    }
                    else if(newEnvelop.Apttus_DocuApi__Status__c == CWS_ConstantClass.Envelope_Status_Voided){
                        agreementRec.Apttus__Status__c = CWS_ConstantClass.Ready_for_signature_Status;
                    }
                }
                agrmntList.add(agreementRec);
            }
            if(agrmntList != null && !agrmntList.isEmpty()){
                update agrmntList;
            }
            
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Docusign Envelope' , 'CWS_DocusignEnvelopHelper', 'afterUpdateMethod' , '', null, null , 'Afterupdate' , null);
        }
    }
}