/**
 * @description       : 
 * @author            : DPC Advictoriam Solutions
 * @group             : 
 * @last modified on  : 06-18-2021
 * @last modified by  : DPC Advictoriam Solutions
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   06-18-2021   DPC Advictoriam Solutions   Initial Version
**/
@isTest
public class CWS_DisplayRelatedTaskDetails_Test {
    @isTest
    private static void testGetTaskList(){
        task newTask = new Task();
        newTask.Subject = 'Testing Original Task';
        newTask.ActivityDate = system.today();
        newTask.Status = 'Open';
        insert newTask;
        task followupTask = new Task();
        followupTask.Subject = 'Testing Original Task';
        followupTask.ActivityDate = system.today();
        followupTask.Status = 'Open';
        followupTask.CWS_Original_Activity_ID__c = newTask.Id;
        insert followupTask;
        test.startTest();
        List<Task> taskList = CWS_DisplayRelatedTaskDetails.taskList(newTask.Id,followupTask.Id);
        system.assertEquals(taskList.size(),1);
        test.stopTest();
    } 
    @isTest
    private static void testNull(){
        List<Task> taskList = CWS_DisplayRelatedTaskDetails.taskList(null,null);
        system.assertEquals(taskList,null);
    }
}