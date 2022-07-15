/*Class Name: CWS_ContentDocumentHelper
*Description: Helper for CWS_ContentDocumentTrigger
*Created By: Akhila
*Created On: 23/07/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                 23/07/2020        BED-3096     			Update Agreement when signed document is deleted
*/

public class CWS_ContentDocumentHelper {
    
	public static void beforeDelete(Map<Id,ContentDocument> contentDocMap){
        
        try{
            Set<Id> agrmntIds = new Set<Id>();
            Set<Id> cdIds = new Set<Id>();
            List<ContentDocumentLink> cDLinkList;
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            for(ContentDocument cdObj: contentDocMap.values()){                 
                cdIds.add(cdObj.Id);
            }
            if(cdIds != null){
                cDLinkList = new List<ContentDocumentLink>([Select Id,LinkedEntityId,ContentDocument.Title from ContentDocumentLink where ContentDocumentId IN: cdIds]);
            }
            for(ContentDocumentLink cdlObj: cDLinkList ){  
                Apttus__APTS_Agreement__c agreementRec = new Apttus__APTS_Agreement__c();
                if((cdlObj.LinkedEntityId).getSObjectType().getDescribe().getName() == 'Apttus__APTS_Agreement__c' && cdlObj.ContentDocument.Title.toLowerCase().containsIgnoreCase(CWS_ConstantClass.signed_Document_Name.toLowerCase())){ 
                    agreementRec.Id = cdlObj.LinkedEntityId;
                    agreementRec.CWS_No_of_Signed_Docs__c = 0;
                    agreementList.add(agreementRec);
                }                          
            }
            if(agreementList.size() > 0){
                update agreementList;
            }
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Content Document' , 'CWS_ContentDocumentHelper', 'afterDeleteMethod' , '', null, null , 'AfterDelete' , null);
        }   
    }
}