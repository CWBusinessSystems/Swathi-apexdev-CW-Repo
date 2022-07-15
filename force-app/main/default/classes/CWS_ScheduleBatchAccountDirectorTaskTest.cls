/*Class Name: CWS_ScheduleBatchAccountDirectorTaskTest
*@description: Test class
*Created By: mahak b
*Created On:  2/4/2021 
*Ticket no :- 14528272 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*mahak bansal          24/3/2021            -                  Initial Version
*mahak bansal          5/4/2021             -                  updated 
*/
@isTest
public class CWS_ScheduleBatchAccountDirectorTaskTest {
 	/**
    * @description This method creates dummy data for testing
    */
    @testsetup
    public static void setup(){
        List<Account> accListforAD=new List<Account>();
         
        for(Integer i =0;i<100;i++){
            Account acc = new Account(Name = ' AccDirector '+i);
            accListforAD.add(acc);
        }
		                
        insert accListforAD;
        
        CWS_Org_Defaults__c customSettings= new CWS_Org_Defaults__c();
        customSettings.CWS_Account_Task_Notification_Email__c='test@test.com';
        customSettings.CWS_Renewal_QuoteFlexQueue_email__c='test@test.com';
        insert customSettings;
    }
    
    /**
    * @description This method test the schedule job with assertions
    */
    @isTest
    public static void testBatchAccountDirectorCLass(){
        List<Accountteammember> acMemberList= new List<Accountteammember>();
        List<Account> accList =[SELECT ID FROM Account WHERE NAME LIKE '%AccDirector%'];
        
		for(Account acc:accList){
            Accountteammember  acctmem=new Accountteammember();
            acctmem.AccountId=acc.id;
            acctmem.UserId= Userinfo.getUserId();
            acctmem.TeamMemberRole='Account Director';
            acMemberList.add(acctmem);
        }
        insert acMemberList;

        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2021';
  
        String jobId = System.schedule('testScheduledApex',CRON_EXP,new CWS_ScheduleBatchAccountDirectorTask());
        
        // Get the information from the CronTrigger API object
      	CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                                 NextFireTime
                                 FROM CronTrigger WHERE id = :jobId];
      // Verify the expressions are the same
     	 System.assertEquals(CRON_EXP, ct.CronExpression);  
        Test.stopTest();  
    }
	
}