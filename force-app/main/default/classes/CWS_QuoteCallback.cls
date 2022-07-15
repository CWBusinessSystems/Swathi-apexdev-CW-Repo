global with sharing class CWS_QuoteCallback implements SBQQ.CalculateCallback {
    global void callback(String quoteJSON){
      try {

        CWS_QuoteModel qModel = (CWS_QuoteModel) JSON.deserialize(quoteJSON, CWS_QuoteModel.class);
        SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(qModel));
        if (qModel.record.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && qModel.record.SBQQ__Status__c==CWS_ConstantClass.QUOTE_STATUS_ACCEPTED && !qModel.record.SBQQ__Ordered__c) {
          SBQQ__Quote__c quote = new SBQQ__Quote__c(id=qModel.record.id);
          //quote.SBQQ__Ordered__c = TRUE;
		  List<CWS_Create_Order_Switch__c> lstorderswitch = CWS_Create_Order_Switch__c.getall().values();
            for(CWS_Create_Order_Switch__c ord :  lstorderswitch){
                if(ord.CWS_Create_Order_When_Quote_Is_Accepted__c == TRUE && ord.name == 'create Order'){
                     quote.SBQQ__Ordered__c = TRUE;
                }
            }
          if (quote!=null) {
            update quote;
          }
        }
        
      } catch (Exception e) {
        CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_QuoteCallback', 'callback' , '', null, null , 'callback' , null);
      }
    }
  }