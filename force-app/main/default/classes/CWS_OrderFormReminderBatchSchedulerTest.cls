/*Class Name:CWS_OrderFormReminderBatchSchedulerTest
*Description: test class for CWS_OrderFormReminderBatchSchedulerTest
*Created By: Indra Ganesan
*Created On: 14/08/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date               Description
*------------------------------------------------------------------------------------------
*Indra Ganesan         14/08/2020          Initial version created 
*/
@isTest(SeeAllData=false)
public class CWS_OrderFormReminderBatchSchedulerTest {

 /* public static testMethod void testOFschedule() {
    Test.startTest();
    CWS_OrderFormReminderBatchScheduler testOFSchedule = new CWS_OrderFormReminderBatchScheduler();
    String sch = '0 0 0,3,6,9,12 ? * *';
    system.schedule('OrderForm Email Notification', sch, new CWS_OrderFormReminderBatchScheduler());   
    Test.stopTest();
  }*/
    
    public static testMethod void testRun() {
    Test.startTest();
    CWS_OrderFormReminderBatchScheduler.run();
    Test.stopTest();
  }
}