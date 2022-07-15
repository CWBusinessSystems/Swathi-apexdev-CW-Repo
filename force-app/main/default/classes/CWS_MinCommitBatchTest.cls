/*Class Name: CWS_MinCommitBatchTest
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
public class CWS_MinCommitBatchTest {
    
   @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'CWS_Distributor_Reseller__c','Quote','SBQQ__QuoteDocument__c'});    
        
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR'
                };
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',soldtoaccount.Id, new Map<String, Object>{'StageName'=>'Closed Won','CloseDate'=>System.today(),'CWS_Bill_To_Account__c'=>soldtoaccount.Id,'CWS_Route_to_Market__c'=>'Direct','CWS_Store_Bill_To_Id__c' => soldtoaccount.Id,'CWS_Master__c' => true}, true);
    
          
       
       Map<String,Object> mincommitFields1 = new Map<String,Object>{
            'CWS_Account__c' => soldtoaccount.Id,
            'CWS_Month_Year__c'=> DateTime.now().format('MMM-YY'),
            'CWS_Monthly_Minimum_Commit__c'=> 5690
        };
       	CWS_Minimum_Commit__c minCommit1 = CWS_UTLDataFactory.createMinCommit( opp.Id, mincommitFields1, true);
       
    }

    @isTest static void MinCommitTest(){

        Test.starttest();
        
        list<Opportunity> oppObj = [Select id from opportunity limit 1];
        list<Account> accObj = [Select id from Account limit 1];
        
        CWS_MinCommitAccountBatch constru = new CWS_MinCommitAccountBatch();
        
              
        List<id> accids1 = new List<id>();
        accids1.add(accObj[0].ID);
       
        String monthYear = DateTime.now().format('MMM-YY');
        String closedWon = CWS_ConstantClass.OpportunityClosedWon_Stage;
        String closedWonLegacy = CWS_ConstantClass.OPPORTUNITY_STAGE_CLOSEDWONLEGACY;
        
        list<CWS_Minimum_Commit__c> miComObj = [Select id,CWS_Account__c,CWS_Account__r.CWS_Minimum_Commit_Amount__c,
                                                CWS_Monthly_Minimum_Commit__c,CurrencyIsoCode,CWS_Account__r.currencyIsoCode
                        from CWS_Minimum_Commit__c where CWS_Month_Year__c =: monthYear AND CWS_Opportunity__r.StageName IN (:closedWon,:closedWonLegacy) limit 1];
        Id batchId = Database.executeBatch(new CWS_MinCommitAccountBatch(accids1), 50);
                
        Test.stopTest();
    }
}