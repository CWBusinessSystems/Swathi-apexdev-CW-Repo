/*Class Name:CWS_ProductSyncPbeSchedulerTest
*Description: test class for CCWS_ProductSyncPbeScheduler
*Created By: Indra Ganesan
*Created On: 14/08/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            Description
*------------------------------------------------------------------------------------------
*Nida                14/08/2020       Initial version created 
*/
@isTest(SeeAllData=false)
public class CWS_ProductSyncPbeSchedulerTest {
  public static testMethod void testOFschedule() {
    Test.StartTest();
    CWS_ProductSyncPbeScheduler testpbeSchedule = new CWS_ProductSyncPbeScheduler();
    String sch = '0 0 0,3,6,9,12 ? * *';
    system.schedule('ProductSyncPbeSchedulerTest', sch, new CWS_ProductSyncPbeScheduler());   
    Test.stopTest();
  }
}