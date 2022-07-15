/*Class Name: CWS_legacyQuoteOrderCreationBatchTest
*Description: Test Class for legacy Quote and Order creation batch
*Created By: Aditya
*Created On: 8/3/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aditya             8/3/2020                       
*/
@isTest
public class CWS_legacyQuoteOrderCreationBatchTest {
	 @TestSetup
    static void makeData(){
        // Activate the Triggers
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','Order'}); 
       
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
            'CWS_Purchase_Order_Required__c'=>'Yes'
            };
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);

        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR','CWS_Is_Partner__c'=>true,'CWS_Is_Distributor__c'=>true};
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
   
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', null, null, true);
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
              'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
              'Type'=>'New',
                'CurrencyIsoCode'=>'USD',
                'CWS_Distributor__c'=>distiaccounts[0].Id,
                 'CWS_Route_to_Market__c'=>'Channel',
                    'CWS_Legal_Entity__c'=>'CW-US'
        }; 
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);
                
        //Create New business Quote record
        Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'CWS_Quote_Type__c'=>'New Business', 
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,
            'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'CWS_Ship_To_Account__c'=>soldtoaccount.Id
        };
        SBQQ__Quote__c quote1=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);

    }
    @istest
    static void testBatch(){
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        
        SBQQ__Quote__c quoteObj = [Select id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c, CWS_LegacyKey__c from SBQQ__Quote__c limit 1];
            quoteObj.SBQQ__Primary__c=true;
            quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
			quoteObj.SBQQ__Status__c='Accepted';
        	quoteObj.CWS_LegacyKey__c='test1245';
        	quoteObj.SBQQ__ExpirationDate__c = System.today();
        
        	quoteObj.SBQQ__LastCalculatedOn__c = System.Today();
        quoteObj.CWS_Recalculation_DateTime__c = System.Today() - 1;
        quoteList.add(quoteObj);
        update quoteList;
        Test.startTest();
        CWS_LegacyOrderCreationBatch batch = new CWS_LegacyOrderCreationBatch();
        Database.QueryLocator ql = batch.start(null);
		batch.execute(null,quoteList);
		batch.Finish(null);
        //Database.executeBatch(batch);
        Test.stopTest();
    } 
	    
    @istest
    static void testBatch2(){
        List<Id> quoteList = new List<Id>();
        List<SBQQ__Quote__c> quote = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteObj = [Select id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c, CWS_LegacyKey__c from SBQQ__Quote__c limit 1];
            quoteObj.SBQQ__Primary__c=true;
            quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
			quoteObj.SBQQ__Status__c='Accepted';
        	quoteObj.CWS_LegacyKey__c='test1245';
        	quoteObj.SBQQ__ExpirationDate__c = System.today();
        	quoteObj.SBQQ__LastCalculatedOn__c = System.Today();
        quoteObj.CWS_Recalculation_DateTime__c = System.Today() - 1;
        update quoteObj;
      	quoteList.add(quoteObj.id);
        quote.add(quoteObj);
        Test.startTest();
        CWS_LegacyOrderCreationBatch batch = new CWS_LegacyOrderCreationBatch(quoteList);
        Database.QueryLocator ql = batch.start(null);
		batch.execute(null,quote);
		batch.Finish(null);
        //Database.executeBatch(batch);
        Test.stopTest();
    }
     @istest
    static void testBatch3(){
        List<Id> quoteList = new List<Id>();
        List<SBQQ__Quote__c> quote = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteObj = [Select id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c, CWS_LegacyKey__c from SBQQ__Quote__c limit 1];
            quoteObj.SBQQ__Primary__c=true;
            quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
			quoteObj.SBQQ__Status__c='Accepted';
        	quoteObj.CWS_LegacyKey__c='test1245';
        	quoteObj.SBQQ__ExpirationDate__c = System.today();
        update quoteObj;
      	quoteList.add(quoteObj.id);
        quote.add(quoteObj);
        Test.startTest();
        CWS_LegacyQuoteSync batch = new CWS_LegacyQuoteSync();
        Database.QueryLocator ql = batch.start(null);
		batch.execute(null,quote);
		batch.Finish(null);
        //Database.executeBatch(batch);
        Test.stopTest();
    }
    
    
     @istest
    static void testBatch4(){
        List<Id> quoteList = new List<Id>();
        List<SBQQ__Quote__c> quote = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteObj = [Select id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c, CWS_LegacyKey__c from SBQQ__Quote__c limit 1];
            quoteObj.SBQQ__Primary__c=true;
            quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
			quoteObj.SBQQ__Status__c='Accepted';
        	quoteObj.CWS_LegacyKey__c='test1245';
        	quoteObj.SBQQ__ExpirationDate__c = System.today();
        update quoteObj;
      	quoteList.add(quoteObj.id);
        quote.add(quoteObj);
        Test.startTest();
        CWS_LegacyQuoteSync batch = new CWS_LegacyQuoteSync(quoteList);
        Database.QueryLocator ql = batch.start(null);
		batch.execute(null,quote);
		batch.Finish(null);
        //Database.executeBatch(batch);
        Test.stopTest();
    }
}