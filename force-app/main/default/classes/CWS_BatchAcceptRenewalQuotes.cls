Public class CWS_BatchAcceptRenewalQuotes implements Database.Batchable<sObject>, Database.stateful{
    private String queryString {get;set;}
    public Set<Id> quoteIds;
    private boolean calledFromTrigger = false;
    

    public CWS_BatchAcceptRenewalQuotes(){
    }
        
    public CWS_BatchAcceptRenewalQuotes(Set<Id> tquoteIds){
        quoteIds=tquoteIds;
    }

    
    public Database.QueryLocator start(Database.BatchableContext bc){
    
        queryString='Select Id, Name, SBQQ__Status__c, CWS_Route_to_Market__c, SBQQ__Primary__c,CWS_Renewal_Category__c, '+
            ' SBQQ__Opportunity2__c from SBQQ__Quote__c '+
            ' where CWS_Quote_Type__c=\''+CWS_ConstantClass.Quote_Type_Renewal+'\' '+
            ' AND SBQQ__Status__c != \''+CWS_ConstantClass.QUOTE_STATUS_ACCEPTED +'\' AND '+
            ' (NOT SBQQ__Opportunity2__r.StageName in (\''+CWS_ConstantClass.OpportunityClosedWon_Stage +
            '\', \''+ CWS_ConstantClass.OpportunityClosedLose_Stage +'\')) AND '+
            ' SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate=TODAY AND '+
            ' CWS_On_Hold__c=FALSE AND SBQQ__Opportunity2__r.CWS_Do_Not_Renew_Existing_Contract__c = FALSE';
        if(quoteIds!=null && !quoteIds.isEmpty()){
            calledFromTrigger = true;
            queryString='Select Id, Name, CWS_Route_to_Market__c, SBQQ__Opportunity2__c, '+
                    ' SBQQ__Status__c, SBQQ__Primary__c,CWS_Renewal_Category__c from SBQQ__Quote__c where id in :quoteIds';
        }
        system.debug(queryString);
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)scope;
        set<id> optyIds = new set<id>();
        list<SBQQ__Quote__c> quoteToUpdate = new list<SBQQ__Quote__c>();
        
        for(SBQQ__Quote__c quote: quoteList){
            if(quote.CWS_Renewal_Category__c == CWS_ConstantClass.Renewal_Type_OptOut){
                if(calledFromTrigger && !quote.SBQQ__Primary__c){
                    quote.SBQQ__Primary__c = TRUE;
                    quote.CWS_acceptThisQuote__c = TRUE;
                    quoteToUpdate.add(quote);
                }else{
                    optyIds.add(quote.SBQQ__Opportunity2__c);
                }
            }
        }
        
        if(!calledFromTrigger){
            for(SBQQ__Quote__c quote: [Select Id, SBQQ__Primary__c,CWS_acceptThisQuote__c, SBQQ__Opportunity2__c, SBQQ__Status__c,CWS_Quote_Type__c
                                              from SBQQ__Quote__c where 
                                              SBQQ__Opportunity2__c in :optyIds and 
                                              SBQQ__Opportunity2__r.StageName!=:CWS_ConstantClass.OpportunityClosedWon_Stage and
                                              SBQQ__Opportunity2__r.StageName!=:CWS_ConstantClass.OpportunityClosedLose_Stage order by createdDate DESC]){
                
                if(quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL){
                    if(quote.SBQQ__Primary__c == TRUE){
                        //Renewal code is already marked as primary no need to process in this batch
                        break;
                    }else{
                        quote.SBQQ__Primary__c = TRUE;
                        quoteToUpdate.add(quote);
                        break;
                    }
                 }
             }
         }
        
         if(quoteToUpdate!=null && !quoteToUpdate.isEmpty()){
             List<Database.SaveResult> results = Database.Update(quoteToUpdate);
             CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_BatchAcceptRenewalQuotes' , 
             'execute','SBQQ__Quote__c', null , null );         
         }
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    

}