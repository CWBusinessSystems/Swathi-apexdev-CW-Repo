/*Class Name: CWS_BatchAcceptQuoteAndCreateOrder
*Description: Batch class to accept Quote and create order
*Created By: 
*Created On: 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Pooja Dhiman          02/09/2021         OBD-1532            Renewal with change Opportunities
*Updates
*Pooja Dhiman		   07/03/2022         OBD-4134		      Added filter in Query: Status!=Inactive
*/
Public class CWS_BatchAcceptQuoteAndCreateOrder implements Database.Batchable<sObject>, Database.stateful{
    private String queryString {get;set;}
    public Set<Id> quoteIds;
    private Map<Id,String> mapOfOppWithQuoteStatus = new Map<Id,String>();
    
	public CWS_BatchAcceptQuoteAndCreateOrder(){
    }
        
    public CWS_BatchAcceptQuoteAndCreateOrder(Set<Id> tquoteIds){
        quoteIds=tquoteIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
    
        queryString='Select Id, Name, SBQQ__Status__c, CWS_Route_to_Market__c, SBQQ__Primary__c,CWS_Renewal_Category__c, '+
            ' SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.type, CWS_Quote_Type__c from SBQQ__Quote__c '+
            ' where (CWS_Quote_Type__c=\''+CWS_ConstantClass.Quote_Type_Renewal+'\' '+
            ' AND SBQQ__Status__c != \''+CWS_ConstantClass.QUOTE_STATUS_ACCEPTED +
            '\' AND SBQQ__Status__c != \''+CWS_ConstantClass.QUOTE_STATUS_INACTIVE + '\' AND '+
            ' (NOT SBQQ__Opportunity2__r.StageName in (\''+CWS_ConstantClass.OpportunityClosedWon_Stage +
            '\', \''+ CWS_ConstantClass.OpportunityClosedLose_Stage +'\')) AND '+
            ' SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate=TODAY AND '+
            ' CWS_On_Hold__c=FALSE AND SBQQ__Opportunity2__r.CWS_Do_Not_Renew_Existing_Contract__c = FALSE and SBQQ__Uncalculated__c = FALSE AND SBQQ__Primary__c = TRUE) OR CWS_acceptThisQuote__c = TRUE';
        if(quoteIds!=null && !quoteIds.isEmpty()){
            queryString='Select Id, Name, CWS_Route_to_Market__c, SBQQ__Opportunity2__c, '+
                    ' SBQQ__Status__c, SBQQ__Primary__c,CWS_Renewal_Category__c from SBQQ__Quote__c where id in :quoteIds';
        }
        queryString = queryString + ' LIMIT ' +Label.CWS_BatchAcceptQuoteAndCreateOrder_LIMIT;
        system.debug(queryString);
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)scope;
        
		CWS_QuoteReader reader = new CWS_QuoteReader();
        CWS_QuoteModel quoteMod;
        
        String idStr = '';
        if(quoteList.size() > 0 && quoteList[0].CWS_Renewal_Category__c == CWS_ConstantClass.Renewal_Type_OptOut){
            idStr = quoteList[0].id;
        }
        
        if(String.isNotBlank(idStr)){
            quoteMod = reader.read(idStr);
        }
        
        if(quoteMod != null){
            quoteMod.record.SBQQ__Status__c=CWS_ConstantClass.Quote_Status_Accepted;
            quoteMod.record.CWS_acceptThisQuote__c = FALSE;
            CWS_QuoteCalculator calculator = new CWS_QuoteCalculator();
            calculator.calculate(quoteMod, 'CWS_QuoteCallbackOnAcceptance');
            //Pooja added the logic
            if((quoteMod.record.SBQQ__Opportunity2__r.type != quoteMod.record.CWS_Quote_Type__c)){
                mapOfOppWithQuoteStatus.put(quoteMod.record.SBQQ__Opportunity2__c,quoteMod.record.CWS_Quote_Type__c);
            }
            List<Opportunity> opportunityToUpdate = new List<Opportunity>();
            for(Opportunity opp : [SELECT id, Type FROM Opportunity WHERE Id In: mapOfOppWithQuoteStatus.keyset()]){
                    opp.Type = mapOfOppWithQuoteStatus.get(opp.ID);
                	opportunityToUpdate.add(opp); 
            }
            List<Database.SaveResult> results = Database.Update(opportunityToUpdate);
             CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_BatchAcceptQuoteAndCreateOrder' , 
             'execute','Opportunity', null , null );
        }
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    

}