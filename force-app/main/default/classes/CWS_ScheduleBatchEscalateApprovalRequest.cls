/*Class Name: CWS_ScheduleBatchEscalateApprovalRequest
*Description: Schedule class for CWS_BatchEscalateApprovalRequest
*Created By:Naresh
*Created On: 05/07/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Naresh              05/07/2020        BED-3438                 Initial version created 
*/

global without sharing class CWS_ScheduleBatchEscalateApprovalRequest implements Schedulable { 
   global void execute(SchedulableContext sc) {
      Id batchInstanceId = Database.executeBatch(new CWS_BatchEscalateApprovalRequest(), 50); 
      
      
   }
}