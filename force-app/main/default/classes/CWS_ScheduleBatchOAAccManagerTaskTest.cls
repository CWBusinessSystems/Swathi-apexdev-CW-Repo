/*Class Name: CWS_ScheduleBatchOAAccManagerTaskTest
*@description: Test class
*Created By: mahak bansal
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
public class CWS_ScheduleBatchOAAccManagerTaskTest {
	/**
    * @description This method creates dummy data for testing
    */
    @testsetup
    public static void setup(){
        List<Account> accList=new List<Account>();
                 
        for(Integer i =0;i<50;i++){
            Account acct13 = new Account(Name = ' OAAccManager '+i);
            accList.add(acct13);
        }
		                
        insert accList;        
        
        CWS_Org_Defaults__c customSettings= new CWS_Org_Defaults__c();
        customSettings.CWS_Account_Task_Notification_Email__c='test@test.com';
        customSettings.CWS_Renewal_QuoteFlexQueue_email__c='test@test.com';
        insert customSettings;
    }
    
    /**
    * @description This method test the schedule job with assertions
    */
    @isTest
    public static void testBatchOAAccManagerCLass(){
        List<Accountteammember> acMemberList= new List<Accountteammember>();
        List<Account> accList =[SELECT ID FROM Account WHERE NAME LIKE '%OAAccManager%'];
        
		for(Account acc:accList){
            Accountteammember acctMem=new Accountteammember();
            acctMem.AccountId=acc.id;
            acctMem.UserId= Userinfo.getUserId();
            acctMem.TeamMemberRole='Outbound Associate Account Manager';
            acMemberList.add(acctMem);            
        }

        Test.startTest();
        insert acMemberList;
        String CRON_EXP = '0 0 0 3 9 ? 2021';
        
        String jobId = System.schedule('testScheduledApex',CRON_EXP,new CWS_ScheduleBatchOAAccManagerTask());

        // Get the information from the CronTrigger API object
     	CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                                 NextFireTime
                                 FROM CronTrigger WHERE id = :jobId];
      // Verify the expressions are the same
     	 System.assertEquals(CRON_EXP, ct.CronExpression);  
        Test.stopTest();  
    }

}