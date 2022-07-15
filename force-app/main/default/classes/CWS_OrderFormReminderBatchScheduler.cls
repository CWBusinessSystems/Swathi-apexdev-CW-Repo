/*Class Name: CWS_OrderFormReminderBatchScheduler
*Description: Scheduler class to schedule the batch tp send email notification to Sales Rep until the form is viewed by the customer 
*Created By: Indra Ganesan
*Created On: 18/05/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Indra Ganesan      18/5/2020           BED-3767           Initial version created
*
*/
global without sharing class CWS_OrderFormReminderBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        Id batchInstanceId = Database.executeBatch(new CWS_OrderFormSignatureReminderBatch(), 50); 
    }
     global Static void run(){
        String sch = '0 0 0,3,6,9,12 ? * *';
        system.schedule('Renewal Email Notification', sch, new CWS_OrderFormReminderBatchScheduler());
    }
}