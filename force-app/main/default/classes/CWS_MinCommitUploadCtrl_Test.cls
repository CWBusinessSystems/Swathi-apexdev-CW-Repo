/*Class Name: CWS_MinCommitUploadCtrl_Test
*Description: Test Class for CWS_MinCommitUploadCtrl
*Created By: Ankit
*Created On: 6/24/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                 06/24/2020        BED-8615            Initial Version
*/

@isTest(SeeAllData=false)
public class CWS_MinCommitUploadCtrl_Test{

   @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'CWS_Distributor_Reseller__c','Quote','SBQQ__QuoteDocument__c'});    
        
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR'};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',soldtoaccount.Id, new Map<String, Object>{'CloseDate'=>System.today(),'CWS_Bill_To_Account__c'=>soldtoaccount.Id,'CWS_Route_to_Market__c'=>'Direct','CWS_Store_Bill_To_Id__c' => soldtoaccount.Id,'CWS_Master__c' => true}, true);
        
   }
   
    @isTest static void testMethod1(){

        Test.starttest();
        
        list<Opportunity> oppObj = [Select id from opportunity limit 1];
        list<Account> accObj = [Select id from Account limit 1];
        
        CWS_Minimum_Commit__c minCom = new CWS_Minimum_Commit__c();
        minCom.CWS_Account__c = accObj[0].id;
        minCom.CWS_Opportunity__c = oppObj[0].id;
        minCom.CWS_Monthly_Minimum_Commit__c = 10000;
        minCom.CWS_Month_Year__c = 'Jan-20';
        
        CWS_MinCommitUploadCtrl.insertMinCommits(new list<CWS_Minimum_Commit__c>{minCom});
        CWS_Minimum_Commit__c minComObj = [Select id,CWS_Month_Year__c from CWS_Minimum_Commit__c limit 1];
        system.assertEquals('Jan-20',minComObj.CWS_Month_Year__c);
        
        CWS_Minimum_Commit__c minCom1 = new CWS_Minimum_Commit__c();
        minCom1.CWS_Account__c = accObj[0].id;
        minCom1.CWS_Opportunity__c = oppObj[0].id;
        minCom1.CWS_Monthly_Minimum_Commit__c = 10000;
        minCom1.CWS_Month_Year__c = 'Jan-20';
        
        try{
            CWS_MinCommitUploadCtrl.insertMinCommits(new list<CWS_Minimum_Commit__c>{minCom1});
        }Catch(Exception e){
            list<CWS_Minimum_Commit__c> minComObjList = [Select id,CWS_Month_Year__c from CWS_Minimum_Commit__c where CWS_Month_Year__c = 'Jan-20'];
            system.assertEquals(1,minComObjList.size());
        }
        
        
        Test.stopTest();
    }
}