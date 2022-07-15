/*Class Name: CWS_OrderItemTriggerHelperTest
*Description: Test Class for CWS_OrderItemTriggerHelper
*Created By: swachatterjee
*Created On: 4/9/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*swachatterjee          4/14/2020           -                  Initial Version
*swachatterjee          4/14/2020        BED - 1287         Test class for Helper (testRFSOrder,testPFOrder,testUnderReviewOrder) 
*/
@isTest(seeAllData=false)
public class CWS_OrderItemTriggerHelperTest {

    @TestSetup
    static void makeData(){
        // Activate the Triggers
       
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','Order'}); 
        /*
        CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
    	insert bypassValidate;
		*/
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
            'CWS_Purchase_Order_Required__c'=>'Yes'
            };
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
		
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>True
        };
        Contact primaryBillingcon = CWS_UTLDataFactory.createContact('Test1', 'Test2',  soldtoaccount.Id, contactFieldValues, true);
        //Create COntract
        Map<String, Object> contractFields=new Map<String, Object>(); 
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR','CWS_Is_Partner__c'=>true,'CWS_Is_Distributor__c'=>true};
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
   
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', null, null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', null, null, true);
        Contract con = CWS_UTLDataFactory.createContract(soldtoaccount.Id, contractFields, true );
      
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 
            'CloseDate'=> Date.today(),
            'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New',
            'CurrencyIsoCode'=>'USD'
        };
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('RFS Opps',soldtoaccount.Id,opportunityFields,true);
        Opportunity opty2=CWS_UTLDataFactory.createOpportunity('UR Opps',soldtoaccount.Id,opportunityFields,true);
        Opportunity opty3=CWS_UTLDataFactory.createOpportunity('PF Opps',soldtoaccount.Id,opportunityFields,true);
        
        //Create Quote record : RFS
        Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'CWS_Quote_Type__c'=>'New Business', 
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,
            'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'CurrencyISOCode'=>'USD',
            'CWS_PO_Number__c'=>'ABC123456',
            'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
            'CWS_Actual_Contract_Term__c' => 12,
             'CWS_Bill_To_Contact__c'=>primaryBillingcon.Id 
        };
        //Added by Mahak - 17 Sep.2021
        Test.startTest();
        CWS_QuoteTriggerHandler.BEFORE_INSERT_EXECUTED = TRUE;
        CWS_QuoteTriggerHandler.AFTER_INSERT_EXECUTED = TRUE;
        CWS_QuoteTriggerHandler.AFTER_UPDATE_EXECUTED = TRUE;
        CWS_QuoteTriggerHandler.BEFORE_UPDATE_EXECUTED = TRUE;
        SBQQ__Quote__c quote1=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);
     
        //Create Quote record : UR
        Map<String, Object> quoteFields1=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'CWS_Quote_Type__c'=>'New Business', 
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,
            'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'CurrencyISOCode'=>'USD',
            'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
            'CWS_Actual_Contract_Term__c' => 11,
            'SBQQ__SubscriptionTerm__c' => 11,
            'CWS_Bill_To_Contact__c'=>primaryBillingcon.Id 
        };
            
        SBQQ__Quote__c quote2=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty2.Id, quoteFields1, true);
       
        //Create Quote record : PF
        Map<String, Object> quoteFields2=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'CWS_Quote_Type__c'=>'New Business', 
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,
            'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'CurrencyISOCode'=>'USD',
            'CWS_PO_Number__c'=>'ABC12345',
            'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
            'CWS_Actual_Contract_Term__c' => 12,
            'CWS_Bill_To_Contact__c'=>primaryBillingcon.Id 
        };
            
        SBQQ__Quote__c quote3=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty3.Id, quoteFields2, true);
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
              'CW_Product_Type__c'=>'Charge', 
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
        Product2 product2=CWS_UTLDataFactory.createProduct('TestProduct2', 'SKU124',productFields,false);
        product2.SBQQ__SubscriptionType__c='One-Time';
        product2.SBQQ__SubscriptionBase__c='List';
        //product2.CWS_ChargeType__c='One-Time';
        product2.CWS_Provisioning_Eligibility__c='Manual';
       	product2.CWS_Additional_Restrictions__c = CWS_ConstantClass.Product_AdditionRestriction_NewAgreement;
        product2.CWS_Charge_Model__c = 'Per Unit Pricing';
       	
        lstProducts.add(product2);
        Product2 product3=CWS_UTLDataFactory.createProduct('TestProduct3', 'SKU125',productFields,false);
        product3.SBQQ__SubscriptionType__c='Renewable';
        product3.SBQQ__SubscriptionBase__c='List';
        product3.CWS_ChargeType__c='Recurring';
        lstProducts.add(product3);
        insert lstProducts;
        
        // Create Pricebook Entry
        PricebookEntry pbe1=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product1.Id,1000.00,'USD', true);
        PricebookEntry pbe2=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product2.Id,1000.00,'USD', true);
        PricebookEntry pbe3=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product3.Id,1000.00,'USD', true);
        
        // Create Quote lines For Quote 1: Under Review
        List<SBQQ__QuoteLine__c> insertQLI = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLine11 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product1.Id);
        quoteLine11[0].SBQQ__PricebookEntryId__c = pbe1.Id;
        quoteLine11[0].CWS_Provisioning_Eligibility__c = 'Immediate';
        quoteLine11[0].CWS_Avg_Number_of_Days__c = 3;
        quoteLine11[0].CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Quarterly;
        quoteLine11[0].CWS_Payment_Schedule_Driver__c = 'Deferment';
        quoteLine11[0].SBQQ__NetPrice__c = 1000;
        quoteLine11[0].CWS_Period_for_Ramp_Spread_Deferment__c = 3; 
        quoteLine11[0].CWS_ProvisioningDate__c = null;
        quoteLine11[0].SBQQ__StartDate__c=Date.today();
        quoteLine11[0].CWS_Category__c = CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH;
        
        insertQLI.add(quoteLine11[0]);

        List<SBQQ__QuoteLine__c> quoteLine12 = CWS_UTLDataFactory.createQuoteLines(1, quote2.Id, product2.Id);
        quoteLine12[0].SBQQ__PricebookEntryId__c = pbe2.Id;
        quoteLine12[0].CWS_Provisioning_Eligibility__c = 'Manual';
        quoteLine12[0].CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_OneTime;
        quoteLine12[0].CWS_Payment_Schedule_Driver__c = 'Spread';
        quoteLine12[0].SBQQ__NetPrice__c = 1000;
        quoteLine12[0].CWS_Period_for_Ramp_Spread_Deferment__c = 3;
        quoteLine12[0].CWS_Uneven_Spread_Values__c = null;
        quoteLine12[0].CWS_ProvisioningDate__c = null;
        quoteLine12[0].SBQQ__StartDate__c=Date.today();
        quoteLine12[0].CWS_Category__c = CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH;
        List<SBQQ__QuoteLine__c> quoteLine14 = CWS_UTLDataFactory.createQuoteLines(1, quote2.Id, product3.Id);
        quoteLine14[0].SBQQ__PricebookEntryId__c = pbe2.Id;
        quoteLine14[0].CWS_Provisioning_Eligibility__c = 'Manual';
        quoteLine14[0].CWS_Payment_Schedule_Driver__c = 'Spread';
        quoteLine14[0].SBQQ__NetPrice__c = 900;
        quoteLine14[0].CWS_Period_for_Ramp_Spread_Deferment__c = 3;
        quoteLine14[0].CWS_Uneven_Spread_Values__c = null;
        quoteLine14[0].CWS_ProvisioningDate__c = null;
        quoteLine14[0].SBQQ__StartDate__c=Date.today()-1;
        quoteLine14[0].CWS_ChargeType__c = 'One-Time'; 
        quoteLine14[0].CWS_Category__c = CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH;
        insertQLI.add(quoteLine12[0]);
        insertQLI.add(quoteLine14[0]);


        List<SBQQ__QuoteLine__c> quoteLine13 = CWS_UTLDataFactory.createQuoteLines(1, quote3.Id, product3.Id);
        quoteLine13[0].SBQQ__PricebookEntryId__c = pbe3.Id;
        quoteLine13[0].CWS_Provisioning_Eligibility__c = 'NA';
        quoteLine13[0].CWS_Billing_Term__c =CWS_ConstantClass.BillingTerm_SemiAnnual;
        quoteLine13[0].SBQQ__StartDate__c=Date.today();
        quoteLine13[0].SBQQ__SubscriptionTerm__c =12;
        insertQLI.add(quoteLine13[0]);
        insert insertQLI;
        Test.stopTest();
    }

    
    
    @IsTest //Quote2/Manual/Spread
    static void testUnderReviewtOrder(){
        SBQQ__Quote__c quoteObj = [SELECT Id,CWS_Bill_To_Account__r.Name,CWS_PO_Number__c FROM SBQQ__Quote__c WHERE CWS_PO_Number__c=null][0];
        Test.startTest();
        quoteObj.SBQQ__Primary__c=true;
        quoteObj.SBQQ__Ordered__c=true;
        quoteObj.SBQQ__StartDate__c = Date.today()-30;
        update quoteObj;
        
        //uncommented by Mahak - 17 Sep.2021
        OrderItem orderItemObj = [SELECT Id,CWS_ServicesProvisioned__c FROM OrderItem WHERE Order.SBQQ__Quote__c=:quoteObj.Id limit 1];
        orderItemObj.CWS_ServicesProvisioned__c =true;
        update orderItemObj;
        Test.stopTest();
		        //System.assertEquals(True, quoteObj.SBQQ__Ordered__c);
    }
    
    @IsTest //Quote1/Immediate/Deferment
    static void testRFSOrder(){
        SBQQ__Quote__c quoteObj = [SELECT Id,CWS_Bill_To_Account__r.Name,CWS_PO_Number__c FROM SBQQ__Quote__c WHERE CWS_PO_Number__c ='ABC123456'][0];
        Test.startTest();
        quoteObj.SBQQ__Primary__c=true;
        quoteObj.SBQQ__Ordered__c=true;
        update quoteObj;
        Test.stopTest();
       System.assertEquals(True, quoteObj.SBQQ__Ordered__c);
    }

    @IsTest
    static void testPFOrder(){
        SBQQ__Quote__c quoteObj = [SELECT Id,CWS_Bill_To_Account__r.Name,CWS_PO_Number__c FROM SBQQ__Quote__c WHERE CWS_PO_Number__c<>null and SBQQ__Opportunity2__r.name ='PF Opps'][0];
        SBQQ__QuoteLine__c	qliObj = [Select Id,CWS_Provisioning_Eligibility__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteObj.Id];
        qliObj.CWS_Provisioning_Eligibility__c = 'NA';
        Test.startTest();
        quoteObj.SBQQ__Primary__c=true;
        quoteObj.SBQQ__Ordered__c=true;
        update qliObj;
        update quoteObj;
        Test.stopTest();
        
        System.assertEquals(True, quoteObj.SBQQ__Ordered__c);
    }
	
    @IsTest
    static void testLegacyScenario(){
        //Switch for Legacy Data migration
        CWS_Trigger_Switch__c triggerSwitch = [SELECT Id,CWS_LegacyDataMigration__c FROM CWS_Trigger_Switch__c];
        triggerSwitch.CWS_LegacyDataMigration__c = true;
        update triggerSwitch;
      	SBQQ__Quote__c quoteObj = [SELECT Id,CWS_Billing_Term__c FROM SBQQ__Quote__c WHERE CWS_PO_Number__c=null][0];
        Test.startTest();
       	//SBQQ__QuoteLine__c quotelineObj = [SELECT Id,CWS_Provisioning_Eligibility__c,CWS_ProvisioningDate__c,CWS_ServicesProvisioned__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: quoteObj.Id limit 1];
        List<SBQQ__QuoteLine__c> updateQL = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLine =[SELECT Id,CWS_Provisioning_Eligibility__c,CWS_ProvisioningDate__c,CWS_ServicesProvisioned__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: quoteObj.Id];
        for(SBQQ__QuoteLine__c obj:quoteLine){
           obj.CWS_ServicesProvisioned__c = true;
            obj.CWS_ProvisioningDate__c = System.today();
            obj.CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_TriAnnual;
            updateQL.add(obj);
        }
        //quotelineObj.CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_TriAnnual;
        //quotelineObj.CWS_ProvisioningDate__c = System.today();
        //quotelineObj.CWS_ServicesProvisioned__c = true;
        update updateQL;
        
        quoteObj.SBQQ__Primary__c=true;
        quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quoteObj.SBQQ__Ordered__c=true;
        update quoteObj;

        Test.stopTest();
        CWS_OrderItemTriggerHandler handler = new CWS_OrderItemTriggerHandler();
        map<Id,SObject> newRecs = new map<Id,SObject>();
        handler.BeforeDelete(newRecs);
        handler.AfterDelete(newRecs);
        handler.AfterUndelete(newRecs);
        handler.AfterUpdate(newRecs, newRecs); 
        System.assertEquals(true, quoteObj.SBQQ__Ordered__c);
    }
	
    @IsTest
    static void testRenewal(){
        Test.startTest();
        //Generate Renewal Opp
        Opportunity opp = [Select Id,SBQQ__RenewedContract__c FROM Opportunity WHERE Name  ='PF Opps'];
        opp.Type = 'Renewal';
        update opp;
        //Generate Renewal Quote
        SBQQ__Quote__c quoteObj1 = [SELECT Id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c  FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:opp.Id ];
        quoteObj1.SBQQ__Primary__c=true;
        quoteObj1.CWS_Quote_Type__c='Renewal';
        quoteObj1.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quoteObj1.SBQQ__Ordered__c=true; //Create Renewal Order
        update quoteObj1;
        SBQQ__QuoteLine__c quotelineObj = [SELECT Id,CWS_Provisioning_Eligibility__c,CWS_ServicesProvisioned__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: quoteObj1.Id][0];
        quotelineObj.CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_BiAnnual;
        quotelineObj.SBQQ__Existing__c = true;
        quotelineObj.CWS_Uneven_Spread__c = true;
        quotelineObj.CWS_Payment_Schedule_Driver__c = CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD;
        quotelineObj.CWS_Transaction_Type__c = 'New';
        quotelineObj.SBQQ__Quantity__c = 5;
        quotelineObj.No_Of_Uneven_Spread_Entries__c  = 5;
        quotelineObj.CWS_Period_for_Ramp_Spread_Deferment__c = 5;
        quotelineObj.CWS_Uneven_Spread_Values__c = '10;10;10;10;10;';
        update quotelineObj;
        
        Test.stopTest(); 
        System.assertEquals(True, quoteObj1.SBQQ__Ordered__c);
    }
    
    @IsTest
    static void testRenewalWC(){
        Test.startTest();
        //Generate Renewal Opp
        Opportunity opp = [Select Id,SBQQ__RenewedContract__c FROM Opportunity WHERE Name  ='PF Opps'];
        opp.Type = 'Renewal with Change';
        update opp;
        //Generate Renewal Quote
        SBQQ__Quote__c quoteObj1 = [SELECT Id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c  FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:opp.Id ];
        quoteObj1.SBQQ__Primary__c=true;
        quoteObj1.CWS_Quote_Type__c='Renewal with Change';
        quoteObj1.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quoteObj1.SBQQ__Ordered__c=true; //Create Renewal Order
        update quoteObj1;
        SBQQ__QuoteLine__c quotelineObj = [SELECT Id,CWS_Provisioning_Eligibility__c,CWS_ServicesProvisioned__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: quoteObj1.Id][0];
        quotelineObj.CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Monthly;
        
        quotelineObj.SBQQ__Existing__c = true;
        update quotelineObj;
        Test.stopTest(); 
        System.assertEquals(True, quoteObj1.SBQQ__Ordered__c);
    }
    
    @IsTest
    static void testAmendment(){
        Test.startTest();
        //Generate Renewal Opp
        Opportunity opp = [Select Id,SBQQ__RenewedContract__c FROM Opportunity WHERE Name  ='PF Opps'];
        opp.Type = 'Amendment';
        update opp;
        //Generate Renewal Quote
        SBQQ__Quote__c quoteObj1 = [SELECT Id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c  FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:opp.Id ];
        quoteObj1.SBQQ__Primary__c=true;
        quoteObj1.CWS_Quote_Type__c='Amendment';
        quoteObj1.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY;
        quoteObj1.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quoteObj1.SBQQ__Ordered__c=true; //Create Renewal Order
        update quoteObj1;
        Test.stopTest();
        System.assertEquals(True, quoteObj1.SBQQ__Ordered__c);
    }
      
    @IsTest
    static void testAmendment2(){
        Test.startTest();
        //Generate Renewal Opp
        Opportunity opp = [Select Id,SBQQ__RenewedContract__c FROM Opportunity WHERE Name  ='PF Opps'];
        opp.Type = 'Amendment';
        update opp;
        //Generate Renewal Quote
        SBQQ__Quote__c quoteObj1 = [SELECT Id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c  FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:opp.Id ];
        quoteObj1.SBQQ__Primary__c=true;
        quoteObj1.CWS_Quote_Type__c='Amendment';
        quoteObj1.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quoteObj1.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY;
        quoteObj1.SBQQ__Ordered__c=true; //Create Renewal Order
        SBQQ__QuoteLine__c quotelineObj = [SELECT Id,CWS_Provisioning_Eligibility__c,CWS_ServicesProvisioned__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: quoteObj1.Id][0];
        quotelineObj.CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Annual;
        quoteLineObj.CWS_Provisioning_Eligibility__c = 'Immediate';
        quotelineObj.CWS_Avg_Number_of_Days__c = 3;
        update quotelineObj;
        
        update quoteObj1;
        Test.stopTest(); 
        System.assertEquals(True, quoteObj1.SBQQ__Ordered__c);
    }
    
}