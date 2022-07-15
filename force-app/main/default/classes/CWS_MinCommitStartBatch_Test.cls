/*Class Name: CWS_MinCommitStartBatch_Test
*Description: Batch Class to Calculate Min Commit amount for specific month
*Created By: Nida
*Created On: 06/12/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nida               06/25/2020      BED-5581              Calculate Min Commit amount for specific month
*/
@isTest(SeeAllData=false)
public class CWS_MinCommitStartBatch_Test {
    
   @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'CWS_Distributor_Reseller__c','Quote','SBQQ__QuoteDocument__c'});    
        
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
                'CWS_Minimum_Commit_Amount__c' => 1000
                };
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',soldtoaccount.Id, new Map<String, Object>{'StageName'=>'Closed Won','CloseDate'=>System.today(),'CWS_Bill_To_Account__c'=>soldtoaccount.Id,'CWS_Route_to_Market__c'=>'Direct','CWS_Store_Bill_To_Id__c' => soldtoaccount.Id,'CWS_Master__c' => true}, true);
    
    }

    @isTest static void MinCommitTest(){

        Test.starttest();
        
        list<Opportunity> oppObj = [Select id from opportunity limit 1];
        list<Account> accObj = [Select id,CWS_Minimum_Commit_Amount__c from Account where CWS_Minimum_Commit_Amount__c != null AND CWS_Minimum_Commit_Amount__c != 0 limit 1];
        
        CWS_MinCommitAccountStartBatch constru = new CWS_MinCommitAccountStartBatch();
              
        List<id> accids1 = new List<id>();
        accids1.add(accObj[0].ID);
        Id batchId = Database.executeBatch(new CWS_MinCommitAccountStartBatch(accids1), 50);
       
        
        Test.stopTest();
    }
}