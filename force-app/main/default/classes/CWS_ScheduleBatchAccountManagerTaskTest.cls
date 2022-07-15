/*Class Name: CWS_ScheduleBatchAccountManagerTaskTest
* @description: Test class
*Created By: mahak bansal
*Created On:  2/4/2021 
*Ticket no :- 14528272 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*mahak bansal          24/3/2021            -                  Initial Version
*mahak bansal         52/4/2021             -                  updated 
*/
@isTest
public class CWS_ScheduleBatchAccountManagerTaskTest {
	/**
    * @description This method creates dummy data for testing
    */
    @testsetup
    public static void setup(){
		List<Account> accListforAMgr=new List<Account>();
        List<Account> accListforAD=new List<Account>();
            
        for(Integer i =0;i<100;i++){
            Account acct13 = new Account(Name = ' AccManager '+i);
            accListforAMgr.add(acct13);
        }		                
        insert accListforAMgr;
        
        CWS_Org_Defaults__c customSettings= new CWS_Org_Defaults__c();
        customSettings.CWS_Account_Task_Notification_Email__c='test@test.com';
        customSettings.CWS_Renewal_QuoteFlexQueue_email__c='test@test.com';
        insert customSettings;
    }
    
    /**
    * @description This method test the schedule job with assertions
    */
    @isTest
    public static void testBatchAccountManagerCLass(){
        List<Accountteammember> acMemberList= new List<Accountteammember>();
        List<Account> accList =[SELECT ID FROM Account WHERE NAME LIKE '%AccManager%'];
        for(Account acc:accList){
            Accountteammember acctMem=new Accountteammember();
            acctMem.AccountId=acc.id;
            acctMem.UserId= Userinfo.getUserId();
            acctMem.TeamMemberRole='Account Manager';
            acMemberList.add(acctMem);                
        }
        
        insert acMemberList;
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2021';
  
        String jobId = System.schedule('testScheduledApex',CRON_EXP,new CWS_ScheduleBatchAccountManagerTask());
        
        // Get the information from the CronTrigger API object
      	CronTrigger cTriggger = [SELECT Id, CronExpression, TimesTriggered, 
                                 NextFireTime
                                 FROM CronTrigger WHERE id = :jobId];
       // Verify the expressions are the same
     	System.assertEquals(CRON_EXP, cTriggger.CronExpression);  
        Test.stopTest();  
    }        
   
   
}