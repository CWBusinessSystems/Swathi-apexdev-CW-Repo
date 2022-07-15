/* Class Name   : CWS_ScheduleBatchEscalateApprovalReqTest
 * Description  : Test Class for CWS_ScheduleBatchEscalateApprovalRequest Class
 * Created By   : Megha Shetty
 * Created On   : 8/14/2020
 * Modification Log
*------------------------------------------------------------------------------------------
*Developer                    Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_ScheduleBatchEscalateApprovalReqTest {

  @isTest
      static void testschedule() {
    Test.StartTest();
    CWS_ScheduleBatchEscalateApprovalRequest sh1 = new CWS_ScheduleBatchEscalateApprovalRequest();
        String sch = '0 0 2 * * ?'; 
        system.schedule('Test Schedulable', sch, sh1);  
    Test.stopTest();
}
}