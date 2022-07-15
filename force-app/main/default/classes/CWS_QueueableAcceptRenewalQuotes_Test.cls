/*Class Name: CWS_QueueableAcceptRenewalQuotes_Test
*Description: Test Class for CWS_QueueableAcceptRenewalQuotes
*Created By: Manoj
*Created On: 4/7/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Manoj                 24/08/2020        BED-3696              Quote Cloning
*/
@istest(seealldata = false)
public class CWS_QueueableAcceptRenewalQuotes_Test {
		
    	@testsetup
        static void createTestData(){
      //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','Quote','SBQQ__QuoteDocument__c','CWS_Approval_Trigger__c'});   
            CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'SBQQ__QuoteDocument__c;SBQQ__Quote__c;';
        insert bypassValidate;         
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
             'CWS_Is_Distributor__c'=>true,
             'CWS_BA_Agreement__c'=>'TestBA',
             'CWS_BA_Agreement_Status__c'=>'Request',
             'CWS_MSA_Agreement__c'=>'TestMSA',
             'CWS_MSA_Agreement_Status__c'=>'Request',
             'CWS_NDA_Agreement__c'=>'NDAStatus',
             'CWS_NDA_Agreement_Status__c' =>'Request',
              'CWS_Need_Recurring__c'=>true
                };
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        Map<String, Object> contAdditionalFieldValues = new Map<String, Object>{
          'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL,
         'CWS_Quote_SubType__c' => 'Credit',
          'CWS_OF_Signed_Date__c'=>System.today(),
           'StartDate' => System.today()
          //'EndDate' =>System.today()+ 2
        };
        Contract cont = CWS_UTLDataFactory.createContract(soldtoaccount.id, contAdditionalFieldValues, true);
 
        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
             'CWS_Is_Partner__c'=>true,
             'CWS_Is_Distributor__c'=>true,
             'CWS_Need_Recurring__c'=>true
              };
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,3,true);        
              
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, CWS_ConstantClass.DISTRIBUTOR_TYPE,'Deal Reg', null, null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Fulfillment', null, null, true);
        //CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[2].Id, CWS_ConstantClass.RESELLER_TYPE,'Deal Reg', null, null, true);
        
        // Create Opportunity1
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD', 'StageName' =>'Prospecting'
        };
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);
        
       
        //Create Quote record
        Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 'CWS_Quote_Type__c'=>'Renewal', 
            'CWS_Bill_to_Account__c'=> distiaccounts[0].Id,
            'CWS_Agreement_Numbers__c'=> 'ABC123456',
            'CWS_Route_to_Market__c'=>'IIT',
            'CWS_Reseller_Account__c'=>distiaccounts[2].Id
        };
        SBQQ__Quote__c quote=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);
        List<SBQQ__Quote__c> quotes  = [SELECT ID,SBQQ__Primary__c from SBQQ__Quote__c ];
            system.debug('quote--'+quotes);
        }
        
    @istest static void renewalQuotes(){
        
        Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>( [SELECT ID,SBQQ__Primary__c from SBQQ__Quote__c ]);
		List<SBQQ__Quote__c> quotelist = new List<SBQQ__Quote__c>();
        quotelist.addAll(quoteMap.values());
        quotelist[0].SBQQ__Primary__c = true;
        update  quotelist[0];
        List<SBQQ__Quote__c> quotes =[select id, SBQQ__Primary__c from SBQQ__Quote__c];
        system.debug('quotes--'+quotes);
        if(quoteMap != null){
            System.enqueueJob( new CWS_QueueableAcceptRenewalQuotes(quoteMap.keyset()));
        }
        
        
    } 
    

}