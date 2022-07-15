/*Class Name: CWS_RenewalFlexQueueSchedulableTest
*Description: Test class
*Created By: mahak bansal
*Created On:  12/2/2021 
*Ticket no :- 14276942 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*mahak bansal          12/2/2021            -                  Initial Version
*mahak bansal          24/2/2021            -                  Updated
*/
@isTest
public class CWS_RenewalFlexQueueSchedulableTest {
	
    @testsetup
    public static void setup(){
         Account accObj = new Account(Name = 'Continuum');
        insert accObj;
      // System.debug('Account object'+accObj);
       
        Order order = new Order();
        order.status ='DRAFT';
        order.Type='Renewal';
        order.AccountId = accObj.Id;
		order.EffectiveDate=Date.newInstance(2021, 09, 01);
        insert order;
       // System.debug('order object'+order);
        
        CWS_Error_Log__c errorRec = new CWS_Error_Log__c();
        errorRec.CWS_Error_Message__c ='TEXT___EEE'+'exceeded the limit of 100 jobs in the flex queue for org';
        errorRec.CWS_Class_Name__c='CWS_OrderTriggerHelper';
        errorRec.CWS_Error_Type__c='System.AsyncException';
        errorRec.CWS_Record_Id__c = order.Id;
        insert errorRec;
    }
    
    @isTest
    public static void testBatchCLass(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2022';
  
        String jobId = System.schedule('testScheduledApex',CRON_EXP,new CWS_RenewalFlexQueueSchedulable());
        
        // Get the information from the CronTrigger API object
      	CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                                 NextFireTime
                                 FROM CronTrigger WHERE id = :jobId];
 
      // Verify the expressions are the same
     	 System.assertEquals(CRON_EXP, ct.CronExpression);                            
     //  System.schedule(new CWS_RenewalFlexQueueSchedulable())
      //   Database.executeBatch(new CWS_ProcessFlexQueueExcRecords(), 100);
        Test.stopTest();    
    }
    
}