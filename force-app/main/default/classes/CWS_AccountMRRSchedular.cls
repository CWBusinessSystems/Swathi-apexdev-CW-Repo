/*Class Name: CWS_AccountMRRSchedular
*Description: Batch Class to Calculate MRR based on Contract ACV
*Created By: Abhishek
*Created On: 06/24/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               06/25/2020      BED-5141              Calculate MRR based on Contract ACV
*/
public class CWS_AccountMRRSchedular implements schedulable{
    public void execute(SchedulableContext sc) {
        Id batchInstanceId = Database.executeBatch(new CWS_AccountMRRCalculationBatch()); 
    }
}