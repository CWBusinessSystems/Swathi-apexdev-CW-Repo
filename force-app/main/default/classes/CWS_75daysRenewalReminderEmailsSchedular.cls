global class CWS_75daysRenewalReminderEmailsSchedular implements System.Schedulable {
	global void execute(System.SchedulableContext sc) {
        CWS_75daysRenewalReminderEmailsBatch b = new CWS_75daysRenewalReminderEmailsBatch(); 
        database.executebatch(b,150);
    }
}