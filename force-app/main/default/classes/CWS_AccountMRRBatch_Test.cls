/*Class Name: CWS_AccountMRRBatch_Test
*Description: Batch Class to Calculate MRR
*Created By: Abhishek
*Created On: 06/29/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               06/25/2020      BED-5141              Calculate MRR
*/
@isTest(SeeAllData=false)
public class CWS_AccountMRRBatch_Test {
    
   @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'CWS_Distributor_Reseller__c','Quote','SBQQ__QuoteDocument__c'});    
        
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
            'CWS_Is_Partner__c'=>TRUE};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',soldtoaccount.Id, new Map<String, Object>{'StageName'=>'Closed Won','CloseDate'=>System.today(),'CWS_Bill_To_Account__c'=>soldtoaccount.Id,'CWS_Route_to_Market__c'=>'Direct','CWS_Store_Bill_To_Id__c' => soldtoaccount.Id,'CWS_Master__c' => true}, true);
    
       Map<String, Object> contractFieldsDefaultValues = new Map<String, Object>{
            'StartDate' => date.today() - 1,
            'ContractTerm' => 12,
            'CurrencyIsoCode' => 'USD',
            'status' => 'Draft'};
       Contract Cntr = CWS_UTLDataFactory.createContract(soldtoaccount.Id,contractFieldsDefaultValues, true);
       
    }

    @isTest static void MRRCalculation(){

        Test.starttest();
        
        list<Opportunity> oppObj = [Select id from opportunity limit 1];
        list<Account> accObj = [Select id from Account limit 1];
        List<id> accids = new List<id>();
        accids.add(accObj[0].ID);
       // system.debug('test1--');
        List<Contract> Cntr = [SELECT Id, currencyISOCode,CWS_Cancelled__c,CWS_Status__c,StartDate,AccountId,SBQQ__Opportunity__c,EndDate,CWS_Contract_ACV__c from Contract]; 
         
        Cntr[0].AccountId = accObj[0].id;
        Cntr[0].SBQQ__Opportunity__c = oppObj[0].id;
        Cntr[0].CWS_Contract_ACV__c = 1000;
        Cntr[0].CWS_Cancelled__c = FALSE;
        //system.debug('test3--' + Cntr[0].CWS_Status__c+' '+Cntr[0].StartDate+' __ '+Cntr[0].CWS_Cancelled__c+ ' __ '+Cntr[0].EndDate);
        
        update Cntr;
        //system.debug('test2--');
        
        Id batchId = Database.executeBatch(new CWS_AccountMRRCalculationBatch(accids), 50);
        Id batchId2 = Database.executeBatch(new CWS_AccountMRRCalculationBatch(), 50);
    
        Test.stopTest();
    }
}