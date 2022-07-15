/*Class Name: CWS_OpportunityACVAlertSchedulerTest
*Description: test class of Schedular for CWS_OpportunityACVAlertBatch Batch Class 
*Created By: Nida
*Created On: 07/22/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nida	               07/22/2020      BED-5096              test class of Schedular for CWS_OpportunityACVAlertBatch Batch Class 
*/

@isTest(SeeAllData=false)
public class CWS_OpportunityACVAlertSchedulerTest {
	public static testMethod void testschedule() {
		Test.StartTest();
		CWS_OpportunityACVAlertScheduler testsche = new CWS_OpportunityACVAlertScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}