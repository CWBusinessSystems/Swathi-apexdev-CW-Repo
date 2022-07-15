public class CWS_LegacyQuoteSync  implements Database.Batchable<SObject>{
   
    // Instance variable to hold the list of quote Id passed if 
    // Parameterized Constructor is used
    private List<Id> lstQuoteIds {get; set;}

    // Definition for a no-arg constructor for general usage
    public CWS_LegacyQuoteSync (){
        // Default operation : No additional logic
		lstQuoteIds = new List<Id>();
    }
    // Parameterized Constructor for passing a list of Quote Ids
    public CWS_LegacyQuoteSync(List<Id> lstQuoteIds) {
        // Instance variable : Copy the values
        this.lstQuoteIds = lstQuoteIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = null;
        String strQuoteStatusAccepted = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
        try {
            strQuery ='select Id from SBQQ__Quote__c where CWS_LegacyKey__c <> null and SBQQ__Status__c = :strQuoteStatusAccepted and CWS_Recalculation_DateTime__c=null and SBQQ__Ordered__c = false';
            if(!lstQuoteIds.isEmpty()){
                strQuery = 'SELECT Id from SBQQ__Quote__c where SBQQ__Status__c = :strQuoteStatusAccepted AND SBQQ__Ordered__c = false AND CWS_LegacyKey__c <> NULL and Id in:lstQuoteIds';    
            }
            
       } catch (Exception e) {
        CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_LegacyQuoteSync','start' ,'', null, null ,'Legacy Quote Sync' , null);
       }
       return Database.getQueryLocator(strQuery);
    }
    public void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> scope){
        try {
            // Iterate through the Quote instances from the scope
            for(SBQQ__Quote__c sObjQuote: scope){
                // Check the ordered Checkbox
                sObjQuote.CWS_Recalculation_DateTime__c = System.now();
            }
            // Create the save result instance
            List<Database.SaveResult> saveResults = null;
            if(!scope.isEmpty()){
                // Invoke  DML
                saveResults = Database.update(scope,true);
                // Log the save results for faulty orders
                CWS_ExceptionHandler.logDMLSaveResults(saveResults,'CWS_LegacyQuoteSync','execute','legacy Order creation: DML','','CWS_LegacyQuoteSync');
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_LegacyQuoteSync','execute' ,'', null, null ,'Legacy Quote Sync' , null);
        }
    }    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    

}