/*Class Name: CWS_SingleDistyStampingSchedular_Test
*Description: test class for CWS_SingleDistyStampingSchedular
*Created By: Nida
*Created On: 08/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nida 	             08/05/2020        BED-5267                 Initial version created 
*/
@isTest(SeeAllData=false)
public class CWS_SingleDistyStampingSchedular_Test {
	public static testMethod void testschedule() {
		Test.StartTest();
		CWS_SingleDistyStampingSchedular testsche = new CWS_SingleDistyStampingSchedular();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}