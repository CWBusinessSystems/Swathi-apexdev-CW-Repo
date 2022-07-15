/*Class Name: CWS_AccountMRRSchedularTest
*Description: test class for Scheduler class of CWS_AccountMRRCalculationBatch
*Created By: Nida
*Created On: 07/22/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nida               	07/22/2020      BED-5141              Calculate MRR based on Contract ACV
*/
@isTest(SeeAllData=false)
public class CWS_AccountMRRSchedularTest {
	public static testMethod void testschedule() {
		Test.StartTest();
		CWS_AccountMRRSchedular testsche = new CWS_AccountMRRSchedular();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}