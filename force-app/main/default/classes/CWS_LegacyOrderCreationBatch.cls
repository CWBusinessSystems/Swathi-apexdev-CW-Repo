/*Class Name: CWS_LegacyOrderCreationBatch
*Description: Batch Class for creating legacy orders
*Created By: swachatterjee
*Created On: 6/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*swachatterjee          6/13/2020            -                  Initial Version                                                                                  
*/
public class CWS_LegacyOrderCreationBatch implements Database.Batchable<SObject> {
    // Instance variable to hold the list of quote Id passed if 
    // Parameterized Constructor is used
    private List<Id> lstQuoteIds {get; set;}

    // Definition for a no-arg constructor for general usage
    public CWS_LegacyOrderCreationBatch (){
        // Default operation : No additional logic
		lstQuoteIds = new List<Id>();
    }
    // Parameterized Constructor for passing a list of Quote Ids
    public CWS_LegacyOrderCreationBatch(List<Id> lstQuoteIds) {
        // Instance variable : Copy the values
        this.lstQuoteIds = lstQuoteIds;
    }

    /**
     * @Developer: swachatterjee
     * @Description: start Method of the batch class
     * If a list of quote id is passed through constructor then do additional validation and pass on to execute
     * If no-arg constructor is used then : 
     * Query all accepted legacy quotes and pass it on for execution
     */
    public Database.QueryLocator start (Database.BatchableContext bContext){
        // Initialize the return variable
        String strQuery = null;
        // Constant String : Quote Status : Accepted
        String strAcceptedStatus = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
        try {
            strQuery = 'SELECT Id,CWS_Recalculation_DateTime__c,SBQQ__LastCalculatedOn__c from SBQQ__Quote__c where SBQQ__Status__c = :strAcceptedStatus AND SBQQ__Ordered__c = false AND CWS_LegacyKey__c <> NULL';
			// If the list of quote ids is empty: No arg constructor is used
            if(!lstQuoteIds.isEmpty()){
                strQuery = 'SELECT Id,CWS_Recalculation_DateTime__c,SBQQ__LastCalculatedOn__c from SBQQ__Quote__c where SBQQ__Status__c = :strAcceptedStatus AND Id in: lstQuoteIds AND SBQQ__Ordered__c = false AND CWS_LegacyKey__c <> NULL';
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_LegacyOrderCreationBatch','start' ,'', null, null ,'Legacy Order Creation' , null);
        }
        // Return the quotes 
        return Database.getQueryLocator(strQuery);
    }	

    /**
     * @Developer: swachatterjee
     * @Description: Batch Job: go through each Quote in the scope and check the ordered checkbox
     */
    public void execute (Database.BatchableContext bContext, List<SBQQ__Quote__c> scope){
        try {
            // Iterate through the Quote instances from the scope
            for(SBQQ__Quote__c sObjQuote: scope){
                // Check the ordered Checkbox
                if(sObjQuote.SBQQ__LastCalculatedOn__c>sObjQuote.CWS_Recalculation_DateTime__c){
                    sObjQuote.SBQQ__Ordered__c = true;
                }
            }
            // Create the save result instance
            List<Database.SaveResult> saveResults = null;
            if(!scope.isEmpty()){
                // Invoke  DML
                saveResults = Database.update(scope,true);
                // Log the save results for faulty orders
                CWS_ExceptionHandler.logDMLSaveResults(saveResults,'CWS_LegacyOrderCreationBatch','execute','legacy Order creation: DML','','CWS_LegacyOrderCreationBatch');
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_LegacyOrderCreationBatch','execute' ,'', null, null ,'Legacy Order Creation' , null);
        }
    }

    public void finish(Database.BatchableContext bContext){
        // Finish method logic : No Additional Logic
    }
}