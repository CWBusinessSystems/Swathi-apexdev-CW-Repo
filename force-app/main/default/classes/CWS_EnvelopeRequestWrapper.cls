Public class CWS_EnvelopeRequestWrapper{   
    public string dsTemplateId {get;set;}
    public string documentId {get;set;}
    public String email1 {get;set;}
    public String email2 {get;set;}
    public string roleName1 {get;set;}
    public string roleName2 {get;set;}
    public String name1 {get;set;}
    public String name2 {get;set;}
    public String subject {get;set;}
    public Id quoteId {get;set;}
    public Id quoteDocumentId {get;set;}
    public Id opportunityId {get;set;}
    public String renewalType {get;set;}
    public String routeToMarket {get;set;}
    public String soldToAccountName {get;set;}
    public CWS_EnvelopeRequestWrapper(String tdsTemplateId, String tdocumentId,
                String temail1, String temail2,
               String troleName1,String troleName2,String tname1,String tname2,
               String tsubject, Id tquoteId, Id tquoteDocumentId, Id topportunityId,
               String trenewalType, String trouteToMarket, String tsoldToAccountName ){
        dsTemplateId=tdsTemplateId;
        documentId=tdocumentId;
        email1=temail1;
        email2=temail2;
        roleName1=troleName1;
        roleName2=troleName2;
        name1=tname1;
        name2=tname2;
        subject=tsubject;
        quoteId=tQuoteId;
        quoteDocumentId=tQuoteDocumentId;
        opportunityId=tOpportunityId;
        renewalType=trenewalType;
        routeToMarket=trouteToMarket;
        soldToAccountName =tsoldToAccountName; 
    }
}