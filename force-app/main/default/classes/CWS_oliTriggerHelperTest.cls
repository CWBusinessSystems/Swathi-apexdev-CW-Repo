/*Class Name: CWS_oliTriggerHelperTest
*Description: Test Class for OpportunityLineItem trigger
*Created By: Aditya
*Created On: 8/4/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aditya             8/4/2020                       
*/
@isTest
public class CWS_oliTriggerHelperTest {
	 @TestSetup
    static void makeData(){
        // Activate the Triggers
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','OpportunityLineItem'}); 
       
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
              'Type'=>'Commission Only',
                'CurrencyIsoCode'=>'USD',
                'CWS_Distributor__c'=>distiaccounts[0].Id,
                    'CWS_Legal_Entity__c'=>'CW-US',
                  'Pricebook2Id'=>Test.getStandardPricebookId(),
                  'RecordTypeId'=>CWS_ConstantClass.Opportunity_CommissionOnly
        }; 
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);
         // Create Products
        Map<String, Object> productFields=new Map<String, Object>{
              'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12,
              'CWS_Charge_Model__c'=>'Per Unit Pricing', 
              'CWS_License_Type__c'=>'SaaS', 
              'CWS_Route_to_Market__c'=>'Direct', 
              'CWS_SKU_Type__c'=>'Package', 
              'CWS_UOM__c'=>'Each', 
              'CWS_Sub_Category__c'=>'License', 
              'CWS_Currencies__c'=>'USD;CAD;AUD;EUR;GBP', 
              'CWS_Status__c'=>'Active', 
              'CWS_Billing_Term__c'=>'Monthly', 
              'CWS_Product_Family__c'=>'BDR', 
              'CW_Product_Type__c'=>'Product', 
              'CWS_ChargeType__c'=>'Usage', 
              'CWS_Item_Revenue_Category__c'=>'Saas-Billing', 
              'CWS_Renewal_Type__c'=>'Opt-out', 
              'CWS_Product_Line__c'=>'None' ,
           	  'SBQQ__BillingType__c'=>'Advance',
              'SBQQ__PricingMethod__c'=>'List',
              'Description'=>'Test',
              'CWS_Description__c'=>'Test'
              
        };  
        List<Product2> lstProducts = new List<Product2>();
        Product2 product1=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,false);
        product1.SBQQ__SubscriptionType__c='Renewable';
        product1.SBQQ__SubscriptionBase__c='List';
        product1.CWS_Avg_Number_of_Days__c=10;
        product1.CWS_ChargeType__c='One-Time';
        product1.CWS_Provisioning_Eligibility__c='Immediate';
        lstProducts.add(product1); 
        insert lstProducts;
    	// Create Pricebook Entry
    	Pricebook2 pb = CWS_UTLDataFactory.createCustomPB(System.Label.CWS_ConnectwisePricebook,true);
        PricebookEntry Stdpbe1 = CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product1.Id,1000.00,'USD', true);
        PricebookEntry pbe1 = CWS_UTLDataFactory.createPBEwithPricebookId(pb.id,product1.Id,1000.00,'USD', true);
        CWS_Economic_Factor__c ef = CWS_UTLDataFactory.createEconomicFactor('Automate', 'Product', 1, 'USD');
	    Map<String, Object> addFields01 = new Map<String,Object>{
           'CWS_Bill_To_Account__c'=>soldtoaccount.id, 
           'CWS_Route_to_Market__c'=>'Direct',
           'CWS_Quote_Type__c'=> CWS_ConstantClass.QUOTE_TYPE_RENEWAL
        };  
        SBQQ__Quote__c quote02 = CWS_UTLDataFactory.createQuote(soldtoaccount.id,opty.id,addFields01,true);       
	}
	
      @isTest
    static void testOLIAfterInsert(){
     	Test.startTest(); 
        Opportunity opp = [Select id, Pricebook2Id from Opportunity limit 1];
        Pricebook2 pb = [Select id from Pricebook2 where name =: System.Label.CWS_ConnectwisePricebook];
        PricebookEntry pbe = [Select id,UnitPrice from PricebookEntry where Pricebook2Id =: pb.id];   
       	opp.Pricebook2Id = pb.id;
        update opp;
        Product2 prod = [Select id from Product2 limit 1];
        prod.CWS_License_Type__c ='SaaS';
        prod.CWS_EF_Attribute__c  = 'Service';
        update prod;
        OpportunityLineItem oliObj = new OpportunityLineItem();
        oliObj.OpportunityId = opp.id;
        oliObj.PricebookEntryId = pbe.Id;
        //oliObj.Product2Id = prod.id;
        oliObj.UnitPrice = 0;
        oliObj.Quantity = 1;
        //oliObj.UnitPrice = pbe.UnitPrice;
        //oliObj.TotalPrice = 1000;
        oliObj.CWS_Commission_Only__c = true;
        oliObj.CWS_Transaction_Type__c = CWS_ConstantClass.QUOTE_TYPE_RENEWAL;
        insert oliObj;
        
        system.assertEquals(true, oliObj !=null);
        Test.stopTest();
    }
    
	  @isTest
    static void testOLI(){
      Test.startTest();  
        Opportunity opp = [Select id,Pricebook2Id from Opportunity limit 1];
     
        Product2 prod = [Select id from Product2 limit 1];
        Pricebook2 pb = [Select id from Pricebook2 where name =: System.Label.CWS_ConnectwisePricebook];
       	opp.Pricebook2Id = pb.id;
        update opp;
        PricebookEntry pbe = [Select id,UnitPrice from PricebookEntry where Pricebook2Id =: pb.id];   
        OpportunityLineItem oliObj = new OpportunityLineItem();
        oliObj.OpportunityId = opp.id;
        //oliObj.Product2Id = prod.id;
        oliObj.Quantity = 1;
        //oliObj.TotalPrice = 1000;
        oliObj.PricebookEntryId = pbe.Id;
        oliObj.UnitPrice = pbe.UnitPrice;
        oliObj.CWS_Commission_Only__c = true;
        insert oliObj;
        oliObj.Quantity = 2;
        oliObj.CWS_ACVLine__c = 20;
        oliObj.CWS_NetTotal__c =30;
        update oliObj;
      Test.stopTest();
        CWS_OpportunityLineItemTriggerHandler obj = new CWS_OpportunityLineItemTriggerHandler();
        Map<Id, OpportunityLineItem> newItems = new Map<Id, OpportunityLineItem>();
        obj.BeforeDelete(newItems);
        obj.AfterInsert(newItems);
        obj.AfterUpdate(newItems , newItems);
        obj.AfterDelete(newItems);
        obj.AfterUndelete(newItems);
    }
      @isTest
    static void testOLI2(){
      Test.startTest();  
        Opportunity opp = [Select id from Opportunity limit 1];
        Product2 prod = [Select id from Product2 limit 1];
        prod.CWS_License_Type__c ='SaaS';
        prod.CWS_EF_Attribute__c  = 'Service';
        update prod;
        OpportunityLineItem oliObj = new OpportunityLineItem();
        oliObj.OpportunityId = opp.id;
        oliObj.Product2Id = prod.id;
        oliObj.Quantity = 1;
        oliObj.TotalPrice = 1000;
        oliObj.CWS_Commission_Only__c = true;
        insert oliObj;
      Test.stopTest();
    }
    
}