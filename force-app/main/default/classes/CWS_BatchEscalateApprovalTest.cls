/*Class Name: CWS_BatchEscalateApprovalTest
*Description: Test Class for CWS_BatchEscalateApproval
*Created By: Aditya
*Created On: 8/17/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aditya         8/17/2020        -                  Initial Version
*/

@isTest
public class CWS_BatchEscalateApprovalTest {

     @TestSetup
     static void init(){
     	 CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'SBQQ__Quote__c','Account', 'Opportunity', 'Order','Contract'});
           Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
             'CWS_Is_Distributor__c'=>true,
             'Industry'=>'MSP',
             'CWS_Sub_Industry__c'=>'N/A',
              'CWS_Additional_Emails_for_Invoice__c'=>'test@add.com'
                };
        Account acc = CWS_UTLDataFactory.createAccount('accountName', soldtoaccountFieldValues, true);
        
           //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
             'CWS_Is_Partner__c'=>true,
             'CWS_Is_Distributor__c'=>true,
             'CWS_Need_Recurring__c'=>true,
             'Industry'=>'MSP',
             'CWS_Sub_Industry__c'=>'N/A'
              };
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,3,true);        
        
      
              
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(acc.Id,distiaccounts[0].Id, CWS_ConstantClass.DISTRIBUTOR_TYPE,'Deal Reg', null, null, true);
        
        //Create Opportunity
         Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD'
        }; 
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',acc.id, opportunityFields, true); 
  
        
        //Create New Business Quote
        Map<String, Object> quoteFields=new Map<String,Object>{
             'SBQQ__Primary__c'=>true,
             'CWS_Quote_Type__c'=>'New Business',
             'CWS_Bill_to_Account__c'=> distiaccounts[0].Id,
             'CWS_Route_to_Market__c'=>'Direct',
             'CWS_Renewal_Category__c'=> CWS_ConstantClass.Renewal_Type_OptIn,
             'SBQQ__StartDate__c'=> Date.today(),
             'SBQQ__SubscriptionTerm__c'=>12,
              'CWS_Approval_Requested_Date__c'=> System.today(),
              'SBQQ__Status__c' =>'In Review'
                 }; 
        SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acc.id, opp.id, quoteFields, true);  
         
         //Create Approval Rule
         sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c();
         rule.name ='Test';
         rule.sbaa__Active__c = true;
         rule.CWS_Notify_Higher_level_after_3_days__c = true;
         rule.sbaa__TargetObject__c = 'SBQQ__Quote__c';
         insert rule;
         
         //Create approval record
         sbaa__Approval__c app = new sbaa__Approval__c();
         app.CWS_Quote__c = quote.id;
         app.sbaa__Status__c = 'Requested';
         app.sbaa__Rule__c = rule.id;
         app.sbaa__RecordField__c = 'CWS_Quote__c';
         app.sbaa__ApprovalStep__c = 1;
         insert app;
     } 
    @isTest
    static void testMethod1(){
      Test.startTest();
        CWS_BatchEscalateApprovalRequest batch = new CWS_BatchEscalateApprovalRequest();
        Database.executeBatch(batch);
      Test.stopTest();
        List<sbaa__Approval__c> lstApp = [Select id from sbaa__Approval__c];
        System.assertEquals(1, lstApp.size());
    }
}