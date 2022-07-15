/* Class Name   : CWS_RenewalEmailBatchScheduler
* Description  : Scheduler will be used to send renewal notifications   
* Created By   : Apurva Makuluri
* Created On   : 08-May-2020

* Modification Log:  
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description 
* ---------------------------------------------------------------------------------------------------------------------------------------
* Apurva Makuluri     08-May-2020                  BED-6407                 Initial version
*/ 
global class CWS_RenewalEmailBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        CWS_RenewalEmailBatch b = new CWS_RenewalEmailBatch(); 
        database.executebatch(b,1);
    }
    global Static void run(){
        String sch = '0 15 * * * ?';//CRON for scheduler to run 
        system.schedule('Renewal Email Notification', sch, new CWS_RenewalEmailBatchScheduler());
    }
}