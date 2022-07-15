/*Class Name: CWS_ManageIntegrationCallout
*Description:  Class for handling Contact/Account Manage Integraion
*Created By: Abhishek
*Created On: 08/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*abhishek		        08/05/2020	    BED-9925	            Initial Version
*Sudhir Moturu          10/27/2020                              Changed class from Future to Queueable
*Carl Shahan            10/03/2021      OBD-244                 Added debug statement for Boomi response troubleshooting
*/
public  class CWS_ManageIntegrationCallout implements Queueable,Database.AllowsCallouts{
   
    private List<Id> lstIds;
    private String manageContact;
    public  CWS_ManageIntegrationCallout() {}
    public  CWS_ManageIntegrationCallout(list<Id> Ids,string manageCnt) {
        this.lstIds = Ids;
        this.manageContact = manageCnt;
    }
    public void execute(QueueableContext context) {
        try {
            CWS_ManageIntegrationRequest requestBody = null;
            if(!lstIds.isEmpty()){
                requestBody = prepareRequestBody(lstIds);
            }
            if(requestBody<>null){
                // serialize the order sobject to JSON String
                String strJSONBody = JSON.serializePretty(requestBody);
                System.debug('@@@@ strJSONBody'+strJSONBody);
                // Capture the HTTP Response from the callout
                HttpResponse response = CWS_CallloutService.invokeCallout(manageContact, strJSONBody);
                System.debug('@@@@ Contact callout service response: ' + response.getStatusCode() + ' ' + response.getBody());
            } 
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'CWS_ManageIntegrationCallout' , 'CWS_ManageIntegrationCallout','Method' ,'', null, null ,'Method' , null);
        }
    }

    /***************************Additional Wrapper & Utility for processing the request *******************/
     public class CWS_ManageIntegrationRequest {
        String Id {get;set;}
    }

    public  static CWS_ManageIntegrationRequest prepareRequestBody (List<Id> ids){
        CWS_ManageIntegrationRequest request = new CWS_ManageIntegrationRequest();
        system.debug('@@@ids'+Ids);
        try {
            if(!ids.isEmpty()){
                for(Id recId: Ids){
                    request.Id = recId;
                }
                System.debug(request);
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'CWS_ManageIntegrationCallout' , 'CWS_ManageIntegrationCallout','prepareRequestBody' ,'', null, null ,'prepareRequestBody' , null);
        }
        return request;
    }
}