/*Class Name: CWS_AttachmentTriggerHelper
*Description: Handler Class for CWS_AttachmentTrigger
*Created By: Naresh
*Created On: 05/30/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Naresh                05/30/2020           BED-6236          
*Harsha                 07/15/2020         BED-12480   
*Indra Ganesan           16/7/2020         BED-1431
*/
public class CWS_AttachmentTriggerHelper {
    
	public static void createAdditionalDocument(Map<Id, SObject> newItems){
	
		List<ID> lstQuoteId = new List<ID>();
		string documentName;
		Set<Id> contentDocumentIdSet =new Set<ID>();
		List<ContentDocumentLink> cd = new List <ContentDocumentLink>();
		Map<Id,ContentVersion> newMap=(Map<Id,ContentVersion>)newItems; 
		list<SBQQ__RelatedContent__c> lsttoInsert = new list<SBQQ__RelatedContent__c>();
		
		for(ContentVersion att: newMap.values()){
			If(att.ContentDocumentId != null){
				contentDocumentIdSet.add(att.ContentDocumentId);
				documentName = att.Title;
			}
		}
		cd = [SELECT ContentDocumentId,  LinkedEntityId , ShareType FROM ContentDocumentLink WHERE ContentDocumentId IN:contentDocumentIdSet ];
		for(ContentDocumentLink cdl : cd){
			system.debug('cdl.ShareType == '+cdl.ShareType );
			if(cdl != null && cdl.ShareType == 'V'){
				ID s = string.valueof(cdl.LinkedEntityId);
				string objname =s.getSObjectType().getDescribe().getName();
				system.debug('objname ==='+objname);
				if(objname == 'SBQQ__Quote__c'){
					System.debug('Entered attachement trigger');					
					SBQQ__RelatedContent__c nw = new SBQQ__RelatedContent__c(Name=documentName,SBQQ__ExternalId__c=cdl.ContentDocumentId,SBQQ__Quote__c=cdl.LinkedEntityId);
					if(documentName.containsIgnoreCase(CWS_ConstantClass.CUSTOM) && documentName.containsIgnoreCase(CWS_ConstantClass.SOW)){
						lstQuoteId.add(cdl.LinkedEntityId);
					}
						lsttoInsert.add(nw);
				} 
				if(objname == 'Product2'){
					System.debug('Entered attachement trigger for product');
					SBQQ__RelatedContent__c nw = new SBQQ__RelatedContent__c(Name=documentName,SBQQ__ExternalId__c=cdl.ContentDocumentId,SBQQ__Product__c=cdl.LinkedEntityId);
					lsttoInsert.add(nw);
				} 
			}
		}
		List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
		List<SBQQ__Quote__c> lstQuoteUpdated = new List<SBQQ__Quote__c>();
		if(!lstQuoteId.isEmpty()){
			lstQuote = [SELECT Id,CWS_File_Attached__c FROM SBQQ__Quote__c WHERE Id IN: lstQuoteId];
			for(SBQQ__Quote__c q : lstQuote){
				q.CWS_File_Attached__c = true;
				lstQuoteUpdated.add(q);   
			}    
		}			
		if(!lsttoInsert.isEmpty() ){
			try{
				insert lsttoInsert;
				if(!lstQuoteUpdated.isEmpty()){
					update lstQuoteUpdated;
				}
			}catch(Exception e ){
				CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_AttachmentTriggerHelper', 'CWS_AttachmentTriggerHelper:createAdditionalDocuments' , '', null, null , 'BeforeInsert' , null);

			}
		}
	}
}