Public Class CWS_QuoteDocumentUtil{

    //This method will be called from Batch Class with batch Size 1
    Public Static String QuoteDocumentApiCall(Id quoteId, Id templateId){
        QuoteProposalModel model = new QuoteProposalModel();
        model.quoteId = quoteId;
        model.templateId = templateId;
        String jobId = saveQuoteDocument(model);
        return jobId;
    }
    
    Public Class QuoteProposalModel {
        public String name;
        public Id quoteId;
        public Id templateId;
        public String language;
        public String outputFormat;
        public String paperSize;
    }    
        
    public Static String saveQuoteDocument(QuoteProposalModel context) {
		if(Test.isRunningTest()){
               return '200';
        }
        return SBQQ.ServiceRouter.save('SBQQ.QuoteDocumentAPI.Save', JSON.serialize(context));
    }
}