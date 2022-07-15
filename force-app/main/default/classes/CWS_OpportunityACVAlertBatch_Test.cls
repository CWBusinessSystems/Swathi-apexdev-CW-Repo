/*Class Name: CWS_OpportunityACVAlertBatch_Test
*Description: Test class for CWS_OpportunityACVAlertBatch 
*Created By: Nida
*Created On: 25/07/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Nida					25/7/2020	 	BED-5096    		    Test Class for CWS_OpportunityACVAlertBatch
*Ad Victoriam Solutions 02/14/2022      N/A                     Updated test class to reflect query change in main.
*/

@isTest(SeeAllData=false)
public class CWS_OpportunityACVAlertBatch_Test {
    @testSetup static void setupTestData(){
        
        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'EUR'};
                List<Account> acctLst = CWS_UTLDataFactory.createBulkAccounts('Test Account',accountFieldValues , 1, true);
        
        date check = system.TODAY();
        check = check.addDays(1);
        //Creating Manager user
        Map<String, Object> userExtraFields1=new Map<String, Object>{
            'isActive'=>true,                
                'Email' => 'test@gmail.com'               
                };
                    //UserRole portalRole = [Select Id,name From UserRole Limit 1];
        User userObj1 = CWS_UTLDataFactory.createUser('Admin','disty@test1.com','Dist','System Administrator','CEO',
                                                      'disty@test.com.Admin.cw',userExtraFields1,true);
        User managerUser = [SELECT ID,EMAIL FROM User WHERE Profile.Name ='System Administrator' AND ID!=: UserInfo.getUserId() LIMIT 1];        
        User currentUser = [SELECT ID,ManagerId FROM User WHERE ID=:UserInfo.getUserId() LIMIT 1];
        if( managerUser!=null && currentUser.ManagerId ==null ){
            currentUser.ManagerId = managerUser.Id;            
            Update currentUser;
        }
        Map<String, Object> OppFieldValues=new Map<String, Object>{'StageName'=>'Qualification',
            'CloseDate'=>check,
            'CWS_Bill_To_Account__c'=>acctLst[0].Id,
            'CWS_Route_to_Market__c'=>'Direct',
            'CWS_Store_Bill_To_Id__c' => acctLst[0].Id,'CWS_Master__c' => true,
            'CWS_Min_Commit_QR__c' => 30000
            };
                //  List<Opportunity> OppLst = CWS_UTLDataFactory.createBulkOpps(OppFieldValues, 5,true);
                Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',acctLst[0].Id,OppFieldValues ,true);
    }
    testMethod static void ACVAlert(){
        Test.startTest();
        Account acctRec = [Select Id,SBQQ__DefaultOpportunity__c from Account];
        
        //Testing Parameterised constructor      
        List<Id> oppIds = new List<Id>();       
        Id oppId =[Select id from opportunity limit 1].Id;
        oppIds.add(oppId);
        CWS_OpportunityACVAlertBatch Acc1 = new CWS_OpportunityACVAlertBatch(oppIds);
        
        //Testing Constructor
        CWS_OpportunityACVAlertBatch Acc2 = new CWS_OpportunityACVAlertBatch();
        
        //Testing QueryLocator
        List<Opportunity> OppLst = [Select id,Amount,CWS_Total_ACV__c,closeDate,owner.Name,Owner.Manager.Name,Owner.email,Owner.Manager.email,CWS_Bill_To_Contact__c,ownerId,Owner.Manager.Id,CWS_Bill_To_Account__c  from opportunity];
        date check = system.TODAY();
        OppLst[0].closeDate = check.addDays(1);
        update OppLst;
        
        Id batchId = Database.executeBatch(Acc1, 50);
        
        Test.stopTest();
    }
}