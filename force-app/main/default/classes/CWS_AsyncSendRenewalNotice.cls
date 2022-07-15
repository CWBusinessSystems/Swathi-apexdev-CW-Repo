public class CWS_AsyncSendRenewalNotice implements Queueable, Database.AllowsCallouts {
    List<CWS_EnvelopeRequestWrapper> lstWrapper;
    Map<Id, Document> mapDocument;
   
    public CWS_AsyncSendRenewalNotice(List<CWS_EnvelopeRequestWrapper> tlstWrapper, Map<Id, Document> tmapDocument){
        lstWrapper=tlstWrapper;
        mapDocument=tMapDocument;
    }
    public void execute(QueueableContext context) {
		try{
        List<SBQQ__Quote__c> quotesToUpdate=new List<SBQQ__Quote__c>();
        List<SBQQ__QuoteDocument__c> quoteDocumentsToUpdate=new List<SBQQ__QuoteDocument__c>();
        Set<Id> quoteIds=new Set<Id>();
        Map<Id, Set<String>> mapQuoteProductCategory=new Map<Id, Set<String>>();
        Map<Id, String> mapContractEndDate=new Map<Id, String>();
        for(CWS_EnvelopeRequestWrapper wr:lstWrapper){
            quoteIds.add(wr.quoteId);
        }
        if(!quoteIds.isEmpty()){
            Set<String> categories;
            String endDateString;
            for(SBQQ__QuoteLine__c quoteLine:[Select Id,SBQQ__Quote__c, SBQQ__Product__c,SBQQ__Product__r.CWS_Category__c ,
                            SBQQ__Quote__r.SBQQ__Opportunity2__c,
                            SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,
                            SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.endDate from SBQQ__QuoteLine__c 
                            where SBQQ__Quote__c in : quoteIds]){
                if(quoteLine.SBQQ__Product__c!=null && quoteLine.SBQQ__Product__r.CWS_Category__c !=null){
                    if(mapQuoteProductCategory.containsKey(quoteLine.SBQQ__Quote__c) ){
                        mapQuoteProductCategory.get(quoteLine.SBQQ__Quote__c).add(quoteLine.SBQQ__Product__r.CWS_Category__c);
                    }
                    else{
                        mapQuoteProductCategory.put(quoteLine.SBQQ__Quote__c,new Set<String> {quoteLine.SBQQ__Product__r.CWS_Category__c} );
                    }
                }
                if(quoteLine.SBQQ__Quote__c!=null && quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c!=null &&
                    quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c!=null){
                     if(!mapContractEndDate.containsKey(quoteLine.SBQQ__Quote__c)){
                         endDateString=quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate!=null?
                             quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate.format():'';
                         mapContractEndDate.put(quoteLine.SBQQ__Quote__c,endDateString);
                            
                     }
                }
            }
        } 
        List<String> lstProductCategory;  
        Set<String> productCategorySet;
        String productCategoryString;
        for(CWS_EnvelopeRequestWrapper req:lstWrapper){
          productCategoryString='';
          
          productCategorySet=mapQuoteProductCategory.get(req.quoteId);

          if(productCategorySet!=null && productCategorySet.size()>0){
              lstProductCategory=new List<String>();
              lstProductCategory.addAll(productCategorySet);
              productCategoryString=String.join(lstProductCategory,', ');
          }
          HttpResponse response=CWS_DSEnvelopeUtil.sendRequest(req.dsTemplateId, req.documentId,mapDocument,
              req.email1, req.email2, req.roleName1, req.roleName2,
              req.name1, req.name2 , req.subject,mapContractEndDate.get(req.quoteId), 
              productCategoryString, req.renewalType, req.routeToMarket,
              req.soldToAccountName);
            system.debug(response.getStatus());
            system.debug(response.getStatusCode());
            system.debug(response.getBody());
            system.debug(response);               
            if( response.getStatusCode()==201){
                CWS_EnvelopeModel.EnvelopeResponse resp=
                (CWS_EnvelopeModel.EnvelopeResponse)JSON.deserialize(response.getBody(), CWS_EnvelopeModel.EnvelopeResponse.class);          
                system.debug(resp);                
                if(resp.status=='sent'){
                    quotesToUpdate.add(new SBQQ__Quote__c(id=req.quoteId, CWS_Renewal_Notice_Sent_Date__c=Date.today()));
                    quoteDocumentsToUpdate.add(new SBQQ__QuoteDocument__c(id=req.quoteDocumentId, SBQQDS__EnvelopeId__c=resp.envelopeId,
                    SBQQ__SignatureStatus__c='Sent'));
                }
            }
        }
        if(quotesToUpdate!=null && !quotesToUpdate.isEmpty()){
            update quotesToUpdate;
        }
        if(quoteDocumentsToUpdate!=null && !quoteDocumentsToUpdate.isEmpty()){
            update quoteDocumentsToUpdate;
        }
		}catch(Exception exp){
			CWS_ExceptionHandler.logException( exp,'CWS_AsyncSendRenewalNotice' , 'CWS_AsyncSendRenewalNotice', 'execute' , '', null, null , '' , null);
		}
    }
}