/*Class Name: CWS_MinCommitSchedular_Test
*Description: test class for CWS_MinCommitSchedular
*Created By: Nida
*Created On: 08/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nida	               08/05/2020      BED-5581              Calculate Min Commit amount for specific month
*/
@isTest(SeeAllData=false)
public class CWS_MinCommitAcStartSchedular_Test {
	public static testMethod void testschedule() {
		Test.StartTest();
		CWS_MinCommitAccountStartSchedular testsche = new CWS_MinCommitAccountStartSchedular();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}