/*Class Name: CWS_MinCommitAccountStartSchedular
*Description: Batch Class to Calculate Min Commit amount for specific month
*Created By: Sudhir Moturu
*Created On: 08/06/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               08/06/2020      BED-13015               Calculate Min Commit amount for specific month
*/
public with sharing class CWS_MinCommitAccountStartSchedular implements schedulable{
    public void execute(SchedulableContext sc) {
        Id batchInstanceId = Database.executeBatch(new CWS_MinCommitAccountStartBatch()); 
    }
}