/*Class Name: CWS_AgreementSignReminderBatchScheduler
*Description: Scheduler class for CWS_AgreementSignReminderBatch
*Created By: Akhila
*Created On: 20/05/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Akhila      			20/5/2020       BED-2970           Scheduler class for CWS_AgreementSignReminderBatch
*
*/

global class CWS_AgreementSignReminderBatchScheduler implements Schedulable{
	global void execute(SchedulableContext sc) {
        Id batchInstanceId = Database.executeBatch(new CWS_AgreementSignReminderBatch(), 50); 
    }
     global Static void run(){
        String sch = '0 0 0,3,6,9,12 ? * *';
        system.schedule('jobName', sch, new CWS_AgreementSignReminderBatchScheduler());
    }
}