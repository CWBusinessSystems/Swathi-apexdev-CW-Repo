/* Class Name   : CWS_ScheduleGenerateQuoteDocument_Test
 * Description  : Test Class for CWS_ScheduleGenerateQuoteDocument Class
 * Created By   : Megha Shetty
 * Created On   : 8/14/2020
 * Modification Log
*------------------------------------------------------------------------------------------
*Developer              			Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_ScheduleGenerateQuoteDocument_Test {

	@isTest
    	static void testschedule() {
		Test.StartTest();
		CWS_ScheduleGenerateQuoteDocument sh1 = new CWS_ScheduleGenerateQuoteDocument();
        String sch = '0 0 2 * * ?'; 
        system.schedule('Test Schedulable', sch, sh1);  
		Test.stopTest();
}
}