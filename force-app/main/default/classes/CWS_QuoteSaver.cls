public with sharing class CWS_QuoteSaver {
    public CWS_QuoteModel save(CWS_QuoteModel quote) {
        String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
        return (CWS_QuoteModel) JSON.deserialize(quoteJSON, CWS_QuoteModel.class);
    }
}