/*Class Name: CWS_MinCommitSchedular
*Description: Batch Class to Calculate Min Commit amount for specific month
*Created By: Abhishek
*Created On: 06/12/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               06/12/2020      BED-5581              Calculate Min Commit amount for specific month
*/
public class CWS_MinCommitSchedular implements schedulable{
    public void execute(SchedulableContext sc) {
        Id batchInstanceId = Database.executeBatch(new CWS_MinCommitAccountBatch()); 
    }
}