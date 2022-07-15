/* Class Name   : CWS_AgreementSignReminderBatchSch_Test
 * Description  : Test Class for CWS_AgreementSignReminderBatchScheduler Class
 * Created By   : Megha Shetty
 * Created On   : 8/14/2020
 * Modification Log
*------------------------------------------------------------------------------------------
*Developer              			Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_AgreementSignReminderBatchSch_Test {
@isTest
    	static void testschedule() {
		Test.StartTest();
		CWS_AgreementSignReminderBatchScheduler sh1 = new CWS_AgreementSignReminderBatchScheduler();
        String sch = '0 0 2 * * ?'; 
        system.schedule('Test Schedulable', sch, sh1); 
        CWS_AgreementSignReminderBatchScheduler.run();
		Test.stopTest();
}
}