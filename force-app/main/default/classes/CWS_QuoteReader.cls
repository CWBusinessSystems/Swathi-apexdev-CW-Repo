public with sharing class CWS_QuoteReader {
    
    public CWS_QuoteModel read(String quoteId) {
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
        return (CWS_QuoteModel) JSON.deserialize(quoteJSON, CWS_QuoteModel.class);
    }
}