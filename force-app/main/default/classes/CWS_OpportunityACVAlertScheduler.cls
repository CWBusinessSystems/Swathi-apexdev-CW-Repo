/*Class Name: CWS_OpportunityACVAlertScheduler
*Description: Schedular for CWS_OpportunityACVAlertBatch Batch Class 
*Created By: Abhishek
*Created On: 07/02/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               07/02/2020      BED-5096              Schedular for CWS_OpportunityACVAlertBatch Batch Class 
*/
public class CWS_OpportunityACVAlertScheduler implements schedulable{
    public void execute(SchedulableContext sc) {
        Id batchInstanceId = Database.executeBatch(new CWS_OpportunityACVAlertBatch()); 
    }
}