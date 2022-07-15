/*Class Name: CWS_SubmitOrderBatch
*Description: batch Class for making integration callouts
*Created By: swachatterjee
*Created On: 5/4/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*swachatterjee		    5/4/2020		 BED-1350		           Initial Version
*/
public class CWS_SubmitOrderBatch implements Database.Batchable<Order>, Database.AllowsCallouts {
    
    // Declare instance variables
    private List<Order> lstOrders {get; set;}
    /**
     * @Description: Parameterized Constructor
     *               Argument: list of orders to be submitted
     * @Developer: swachatterjee
     * @Requirement/issue: BED-1350
     */
    public CWS_SubmitOrderBatch(List<Order> lstOrders){
        this.lstOrders = lstOrders;
    }

    /**
     * @Description: start method implementation: Mandatory Batchable method
     *               return the list of orders passed in the argument
     * @Developer: swachatterjee
     * @Requirement/issue: BED-1350
     */
    public List<Order> start (Database.BatchableContext bContext){
        return lstOrders;
    }
    /**
     * @Description: execute method implementation: Mandatory Batchable method
     *               Batch frequency : 1 according to design
     *               Use the Operation name = CWS_SubmitOrder and invoke callout by
     *               converting the sObject from list to JSON (Serialize)
     * @Developer: swachatterjee
     * @Requirement/issue: BED-1350
     */
    public void execute (Database.BatchableContext bContext, List<Order> scope){
        try {
            CWS_OrderRequest requestBody = null;
            if(!scope.isEmpty()){
                requestBody = prepareRequestBody(scope);
            }
            if(requestBody<>null){
                // serialize the order sobject to JSON String
                String strJSONBody = JSON.serializePretty(requestBody);
                // Capture the HTTP Response from the callout
                HttpResponse response = CWS_CallloutService.invokeCallout(CWS_ConstantClass.CALLOUT_SUBMIT_ORDER, strJSONBody);
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'CWS_SubmitOrderBatch' , 'CWS_SubmitOrderBatch','execute' ,'', null, null ,'execute' , null);
        }
    }

    /**
     * @Description: finish method: Mandatory definition: No Logic
     * @Developer: swachatterjee
     * @Requirement/issue: BED-1350
     */
    public void finish(Database.BatchableContext bContext){
        // No logic implemented for finish method
    }
	
    /***************************Additional Wrapper & Utility for processing the request *******************/
    public class CWS_OrderRequest {
        String Id {get;set;}
        String OrderNumber {get; set;}
    }

    public CWS_OrderRequest prepareRequestBody (List<Order> lstOrders){
        CWS_OrderRequest request = new CWS_OrderRequest();
        try {
            if(!lstOrders.isEmpty()){
                for(Order sObjOrder: lstOrders){
                    request.Id = request.Id<>null? request.Id+';'+sObjOrder.Id:sObjOrder.Id;
                    request.OrderNumber = request.OrderNumber<>null? request.OrderNumber+';'+sObjOrder.OrderNumber:sObjOrder.OrderNumber;
                    
                }
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'CWS_SubmitOrderBatch' , 'CWS_SubmitOrderBatch','prepareRequestBody' ,'', null, null ,'prepareRequestBody' , null);
        }
        return request;
    }

}