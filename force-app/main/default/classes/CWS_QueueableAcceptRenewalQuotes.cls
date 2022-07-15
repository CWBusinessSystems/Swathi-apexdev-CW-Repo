public class CWS_QueueableAcceptRenewalQuotes implements Queueable {
    Set<Id> quoteIds;
    public CWS_QueueableAcceptRenewalQuotes(Set<Id> recordIds) {
        this.quoteIds = recordIds;
    }
    public void execute(QueueableContext context) {
        if(quoteIds!=null){
            List<SBQQ__Quote__c> quotesToUpdate=[Select Id, SBQQ__Status__c from SBQQ__Quote__c where 
                                                    id in :quoteIds and SBQQ__Primary__c=true];
            for(SBQQ__Quote__c quote: quotesToUpdate){
                quote.SBQQ__Status__c=CWS_ConstantClass.Quote_Status_Accepted;
                quote.SBQQ__Ordered__c=TRUE;
            }
            
            if(quotesToUpdate!=null && !quotesToUpdate.isEmpty()){
                 List<Database.SaveResult> results = Database.Update(quotesToUpdate);
                 CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_QueueableAcceptRenewalQuotes' , 
                     'execute','SBQQ__Quote__c', null , null );
            }
            for(SBQQ__Quote__c quote: quotesToUpdate){   
                CWS_QuoteReader reader = new CWS_QuoteReader();
                CWS_QuoteModel quoteModel = reader.read(quote.Id);
                CWS_QuoteSaver saver = new CWS_QuoteSaver();
                CWS_QuoteModel savedQuote = saver.save(quoteModel);
            }
        }
    }
}