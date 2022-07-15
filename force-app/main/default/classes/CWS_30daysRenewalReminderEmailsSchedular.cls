global class CWS_30daysRenewalReminderEmailsSchedular implements System.Schedulable {
	global void execute(System.SchedulableContext sc) {
        CWS_30daysRenewalReminderEmailsBatch b = new CWS_30daysRenewalReminderEmailsBatch(); 
        database.executebatch(b,150);
    }
}