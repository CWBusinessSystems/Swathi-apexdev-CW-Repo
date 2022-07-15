/*Class Name: CWS_SingleDitributorStampingBatch_Test
*Description: test Class for CWS_SingleDitributorStampingBatch
*Created By: Nida
*Created On: 08/06/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nida               08/06/2020     BED-8383              
*/
@isTest(SeeAllData=false)
public class CWS_SingleDitributorStampingBatch_Test {
    
   @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'CWS_Distributor_Reseller__c','Quote','SBQQ__QuoteDocument__c'});    
        
        //Create Account
        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'CWS_Is_Distributor__c' =>True,
             //   'CWS_Is_IIT_Reseller__c' =>True,
            'currencyIsoCode'=>'EUR'};
        List<Account> acctLst = CWS_UTLDataFactory.createBulkAccounts('Test Account',accountFieldValues , 4, true);
        
        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',acctLst[0].Id, new Map<String, Object>{'StageName'=>'Analysis','Type' => 'Amendment' ,'CloseDate'=>System.today()+1,'CWS_Bill_To_Account__c'=>acctLst[0].Id,'CWS_Route_to_Market__c'=>'Direct','CWS_Store_Bill_To_Id__c' => acctLst[0].Id,'CWS_Master__c' => false}, true);
          
       Map<String, Object> QuoteFields=new Map<String, Object>{
            'CWS_Bill_To_Account__c' => acctLst[0].id,
            'SBQQ__Opportunity2__c' => opp.id,
            'CWS_Master__c' => false,
            'SBQQ__Primary__c' => True,
            'SBQQ__Status__c' => 'Accepted',
            'CWS_First_Quote__c' => True,
            'CWS_Sub_Stage__c' => 'Accepted'
        };
            
        SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acctLst[0].id,opp.id,QuoteFields, true);
    }

    @isTest static void DistyStamping(){
     Test.starttest();
        
        list<Account> accObj = [Select id from Account limit 4];
                   
        List<Id> qIds = new List<Id>();       
        Id qId =[Select id from SBQQ__Quote__c limit 1].Id;
        qIds.add(qId);
        
        //testing parameterised constructor
        CWS_SingleDitributorStampingBatch Disty1 = new CWS_SingleDitributorStampingBatch(qIds);
        
        //testing constructor
         CWS_SingleDitributorStampingBatch Disty2 = new CWS_SingleDitributorStampingBatch();
    
        list<SBQQ__Quote__c> Qlist = [Select id, SBQQ__Account__c, SBQQ__Account__r.CWS_Established_Disti_Reseller__c from SBQQ__Quote__c limit 1];
       
        Qlist[0].CWS_Share_with_Bill_To_Account__c = accObj[2].id;
        Qlist[0].SBQQ__ExpirationDate__c = system.today() +1;
        
        update Qlist;
             
        Id batchId = Database.executeBatch(new CWS_SingleDitributorStampingBatch(qIds),50);
    
        Test.stopTest();
    }
}