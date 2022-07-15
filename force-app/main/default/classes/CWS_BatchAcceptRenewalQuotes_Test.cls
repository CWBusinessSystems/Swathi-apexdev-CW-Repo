/* Class Name   : CWS_BatchAcceptRenewalQuotes_Test
 * Description  : Test Class for CWS_BatchAcceptRenewalQuotes Class
 * Created By   : Megha Shetty
 * Created On   : 8/13/2020
 * Modification Log
*------------------------------------------------------------------------------------------
*Developer                          Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_BatchAcceptRenewalQuotes_Test {
@testSetup
    static void createTestData(){
    
    CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','SBQQ__QuoteDocument__c'});
        
        // Create Account
        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'CWS_Payment_Terms__c'=>'Due Upon Receipt',
            'currencyIsoCode'=>'USD',
            'CWS_Account_Restriction_Status__c'=>'No Restriction'
            };
        Account account1=CWS_UTLDataFactory.createAccount('TestAccount', accountFieldValues,true);
        
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>true
           
            };
        Contact primaryContact = CWS_UTLDataFactory.createContact('Mark', 'Anthony', account1.Id, contactFieldValues, true);
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
                'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'StageName'=>'Prospecting',
                'Type'=>'New',
                'CWS_Master__c' => true,
                'CWS_Ramp_Options__c'=>'Minimum Commit Ramp',
                'CWS_Bill_To_Account__c'=> account1.Id,
                'CWS_Period_of_Fixed_Usage_Commit_Ramp__c'=>3,
                'Amount'=>30000,
                'Probability'=>50,
                'CurrencyIsoCode'=>'USD',
                'CWS_Legal_Entity__c'=>'CW-US',
                'CWS_Disti_Deal_Phase__c'=>''
        };
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',account1.Id,opportunityFields,true);
        
		Map<String, Object> productFields1=new Map<String, Object>{
              'CWS_Category__c'=>'Other', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>1,
              'CWS_Charge_Model__c'=>'Per Unit Pricing', 
              'CWS_License_Type__c'=>'Other', 
              'CWS_Route_to_Market__c'=>'Direct', 
              'CWS_SKU_Type__c'=>'Fee', 
              'CWS_UOM__c'=>'Each', 
              'CWS_Sub_Category__c'=>'Other', 
              'CWS_Currencies__c'=>'USD;CAD;AUD;EUR;GBP', 
              'CWS_Status__c'=>'Active', 
              'CWS_Billing_Term__c'=>'Monthly', 
              'CWS_Product_Family__c'=>'Other', 
              'CW_Product_Type__c'=>'Product', 
              'CWS_ChargeType__c'=>'Usage', 
              'CWS_Item_Revenue_Category__c'=>'	Other-Billing', 
              'CWS_Renewal_Type__c'=>'Opt-out', 
              'CWS_Product_Line__c'=>'None' ,
           	  'SBQQ__BillingType__c'=>'	Arrears',
              'SBQQ__PricingMethod__c'=>'List',
              'Description'=>'Test',
              'CWS_Description__c'=>'Minimum Commitment Charge',
              'CWS_Base_SKU__c'=>'900901'
              
        };
        Product2 product2=CWS_UTLDataFactory.createProduct('Minimum Commitment Charge', 'CU-OTHERSAAS900901',productFields1,false);
        product2.SBQQ__SubscriptionType__c='Renewable';
        product2.SBQQ__SubscriptionBase__c='List';
        insert product2;
      	PricebookEntry pbe2=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product2.Id,1,'USD', true);
         
         Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'SBQQ__Primary__c' => true,
            'CWS_Quote_Type__c'=>'Renewal',
            'SBQQ__ExpirationDate__c' => Date.today(),
            'CWS_Route_to_Market__c'=>'Direct',
            'CWS_Bill_To_Account__c'=> account1.Id,
            'CWS_Ship_To_Account__c'=> account1.Id,
            'CWS_Bill_To_Contact__c'=>primaryContact.id,
            'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
            'SBQQ__SubscriptionTerm__c'=> 12,
            'CWS_Renewal_Category__c' => 'Opt-Out'
        };
        SBQQ__Quote__c quote1=CWS_UTLDataFactory.createQuote(account1.Id, opty.Id, quoteFields, true); 
	}
    
     @isTest
    static void testQuote(){
        Test.startTest();
        List<SBQQ__Quote__c> quote = [SELECT id,SBQQ__Primary__c,SBQQ__Type__c from SBQQ__Quote__c];
        quote[0].SBQQ__Primary__c = false;
        quote[0].SBQQ__Type__c = 'Renewal';
        update quote;
        
        Set<Id> quoteIds = New Set<Id>();
        quoteIds.add(quote[0].Id);
        CWS_BatchAcceptRenewalQuotes bARQ = new CWS_BatchAcceptRenewalQuotes();
        CWS_BatchAcceptRenewalQuotes bARQ1 = new CWS_BatchAcceptRenewalQuotes(quoteIds);
        Id batchId = Database.executeBatch(bARQ1);
        
        //Covering the CWS_ScheduleAcceptRenewalQuotes Class       
        CWS_ScheduleAcceptRenewalQuotes sh1 = new CWS_ScheduleAcceptRenewalQuotes();
        String sch = '0 0 2 * * ?'; 
        system.schedule('Test Schedulable', sch, sh1);  
		
		CWS_ScheduleAccpetAndCreateOrdBatch sh2 = new CWS_ScheduleAccpetAndCreateOrdBatch();
        String sche = '0 0 3 * * ?'; 
        system.schedule('Test Schedulable1', sche, sh2);
        
        
        Test.stopTest(); 
    }
    
    
    @isTest
    static void testTriggerContext(){
        Test.startTest();
        List<SBQQ__Quote__c> quote = [SELECT id from SBQQ__Quote__c];
        
        Set<Id> quoteIds = New Set<Id>();
        quoteIds.add(quote[0].Id);
        CWS_BatchAcceptRenewalQuotes bARQ1 = new CWS_BatchAcceptRenewalQuotes(quoteIds);
        Id batchId = Database.executeBatch(bARQ1);
        
        CWS_BatchAcceptQuoteAndCreateOrder ordBatch = new CWS_BatchAcceptQuoteAndCreateOrder(quoteIds);
        id bId = Database.executeBatch(ordBatch);
        Test.stopTest(); 
    }
    
    @isTest
    static void testBatchContext(){
        List<SBQQ__Quote__c> quoteList = [SELECT id, SBQQ__Opportunity2__c,SBQQ__Account__c, 
                                          CWS_Bill_to_Account__c, SBQQ__PrimaryContact__c, 
                                          CWS_Legal_Entity__c, CWS_Route_to_Market__c,
                                          CWS_Renewal_Type__c, SBQQ__Pricebook__c, 
                                          SBQQ__StartDate__c, SBQQ__SubscriptionTerm__c from SBQQ__Quote__c];
        //quoteList[0].CWS_Renewal_Category__c='Opt-Out';
        //quoteList[0].CWS_Quote_Type__c = 'Renewal';
        
        Map<String, Object> mapContractFields =new Map<String, Object>{'SBQQ__Quote__c'=> quoteList[0].Id,
            'SBQQ__Opportunity__c'=> quoteList[0].SBQQ__Opportunity2__c, 'AccountId'=>quoteList[0].SBQQ__Account__c,
            'CWS_Bill_to_Account__c'=> quoteList[0].CWS_Bill_to_Account__c, 'CWS_Sold_to_Contact__c'=> quoteList[0].SBQQ__PrimaryContact__c,
            'CWS_Legal_Entity__c'=>quoteList[0].CWS_Legal_Entity__c, 'CWS_Route_to_Market__c'=> quoteList[0].CWS_Route_to_Market__c,
            'CWS_Renewal_Type__c'=> quoteList[0].CWS_Renewal_Type__c, 'Pricebook2Id'=> quoteList[0].SBQQ__Pricebook__c,
            'StartDate'=>Date.today().addYears(-1), 'ContractTerm'=>12,
            'CurrencyIsoCode'=>'EUR' };
        Contract contract=CWS_UTLDataFactory.createSalesContract(mapContractFields , true);
        //List<SBQQ__Subscription__c> subsList=CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(quoteList[0].SBQQ__Account__c, contract.Id, quoteList[0].Id, true);        
        Test.startTest();
        CWS_BatchAcceptRenewalQuotes bARQ1 = new CWS_BatchAcceptRenewalQuotes();
        Id batchId = Database.executeBatch(bARQ1);
        Test.stopTest(); 
    }
    @isTest
    static void testTriggerContext1(){
        Test.startTest();
		Set<Id> quoteIds = new Set<Id>();
        List<Opportunity> optyLst = [Select Id from Opportunity];
        List<SBQQ__Quote__c> quotes = [Select Id,CWS_Renewal_Category__c,SBQQ__Primary__c,SBQQ__Opportunity2__c from SBQQ__Quote__c];
        quotes[0].SBQQ__Primary__c = true;
        quotes[0].SBQQ__Opportunity2__c = optyLst[0].Id;
        update quotes;
        
        CWS_BatchAcceptRenewalQuotes bARQ1 = new CWS_BatchAcceptRenewalQuotes(quoteIds);
        bARQ1.execute(null,quotes);
        Id batchId = Database.executeBatch(bARQ1);
        
        Test.stopTest(); 
    }
}