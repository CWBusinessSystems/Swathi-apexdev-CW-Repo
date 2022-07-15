/*Class Name: CWS_QuoteTermsCtrl_Test
*Description: Test Class for CWS_QuoteTermsCtrl
*Created By: Manoj
*Created On: 08/9/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Manoj					08/09/2020							  
*/
@isTest(SeeAllData=false)
public class CWS_QuoteTermsCtrl_Test {
    
    @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','Order'});  
        
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                'currencyIsoCode'=>'EUR',
                'CWS_Purchase_Order_Required__c'=>'Yes',
                'CWS_Is_Distributor__c' => true,
                'CWS_Distributor_Logic_Exclusion__c' => true
                };
                    Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>True
                };
        Contact primaryBillingcon = CWS_UTLDataFactory.createContact('Test1', 'Test2',  soldtoaccount.id, contactFieldValues, true);
        
        //Create Contract
        Map<String, Object> contractFields=new Map<String, Object>(); 
        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                'currencyIsoCode'=>'EUR','CWS_Is_Partner__c'=>true,'CWS_Is_Distributor__c'=>true};
                    Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
        Test.startTest();
        
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
        Opportunity opty = CWS_UTLDataFactory.createOpportunity('RFS Opps',soldtoaccount.Id,opportunityFields,true);
        
        //Creating Product
        Map<String, Object> productFields=new Map<String, Object>{
            'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12,
                'CWS_Charge_Model__c'=>'Per Unit Pricing', 
                'CWS_License_Type__c'=>'Perpetual', 
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
         //Creating Another product with Maintenance subcategory                       
        Map<String, Object> productFields2 = new Map<String, Object>(productFields);
        productFields2.remove('CWS_Sub_Category__c');
        productFields2.put('CWS_Sub_Category__c', CWS_ConstantClass.Maintenance_sub_Category);
        
        Product2 product1 = CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,true);
        Product2 product11 = CWS_UTLDataFactory.createProduct('TestProduct2', 'CU-OTHERSAAS900901',productFields2,true);
        
        // Create Pricebook Entry
        PricebookEntry pbe1=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product1.Id,1000.00,'USD', true);
              
        Test.stopTest();
    }
    
    @IsTest //Quote2/Manual/Spread
    static void testMethod1(){
        
        List<String> testProducts = new list<String>{'TestProduct1','TestProduct2'};
        List<Account> accsList = [SELECT ID,Name,(SELECT ID FROM Contacts WHERE CWS_Primary_Contact__c = true LIMIT 1) FROM Account];
        List<Product2> products = [SELECT ID,Name,CWS_Sub_Category__c FROM Product2 WHERE Name in: testProducts];        
        PricebookEntry pbe1 = [SELECT ID FROM PricebookEntry  LIMIT 1];
        
        Account soldtoaccount;
        List<Account> distiAccounts = new List<Account>();
        Contact primaryBillingcon;
        for(Account acc: accsList){
            if(acc.name == 'TestAccount'){
                soldtoaccount = acc;
                if(!acc.Contacts.Isempty()){
                    primaryBillingcon = acc.Contacts[0];
                }
            }
            else{
                distiAccounts.add(acc);
            }
        }
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> soldtoaccount.Id,//
                'Type'=>CWS_ConstantClass.QUOTE_TYPE_AMEND,
                'CurrencyIsoCode'=>'USD'
                };                    
                    
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('RFS Opps',soldtoaccount.Id,opportunityFields,true);
        
        
        Map<String, Object> quoteFields5=new Map<String,Object>{
            'SBQQ__Primary__c'=>true,
                'SBQQ__Type__c'=>'Amendment',
                'CWS_Quote_Type__c'=>'Amendment',
                'CWS_Add_Terms_Manually__c'=>'Test123456',
                'SBQQ__ExpirationDate__c'=> System.today(),
                'CWS_Bill_to_Account__c'=> soldtoaccount.Id,
                'CWS_Reference_Expiry_Date__c' =>null,
                'CWS_IsCloned__c' => false,
                'RecordTypeId'=>CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY,
                'SBQQ__WatermarkShown__c'=>false,
                'CWS_Route_to_Market__c'=>'Channel'
                };
        SBQQ__Quote__c quote5 = CWS_UTLDataFactory.createQuote(soldtoaccount.id,opty.Id, quoteFields5, true);
        Map<String,Product2> prodMap = new Map<String,Product2>();
        for(Product2 prod: products){
            if(prod.name == 'TestProduct1'){
                prodMap.put('TestProduct1',prod);
            }
            else if (prod.name == 'TestProduct2'){
                prodMap.put('TestProduct2',prod);
            }
        }
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        List<SBQQ__QuoteLine__c> quoteLine11 = CWS_UTLDataFactory.createQuoteLines(1, quote5.Id, prodMap.get('TestProduct2').Id);
        quoteLine11[0].SBQQ__PricebookEntryId__c = pbe1.id;
        quoteLine11[0].CWS_Provisioning_Eligibility__c = 'Immediate';
        quoteLine11[0].CWS_Avg_Number_of_Days__c = 3;
        quoteLine11[0].CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Quarterly;
        quoteLine11[0].CWS_Payment_Schedule_Driver__c = 'Deferment';
        quoteLine11[0].SBQQ__NetPrice__c = 1000;
        quoteLine11[0].CWS_Period_for_Ramp_Spread_Deferment__c = 1; 
        quoteLine11[0].CWS_ProvisioningDate__c = null;
        quoteLine11[0].SBQQ__StartDate__c=Date.today();
        quoteLine11[0].CWS_Category__c = CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH;
        quoteLine11[0].CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE;        
        quoteLines.add(quoteLine11[0]);
        if(!quoteLines.isEmpty()){
            Insert quoteLines;
        }       
        ApexPages.StandardController sc = new ApexPages.StandardController(quote5);          
        PageReference pageRef = Page.CWS_QuoteTerms; 
        pageRef.getParameters().put('qid', String.valueOf(quote5.Id));
        Test.setCurrentPage(pageRef);
        CWS_QuoteTermsCtrl qtctrl = new CWS_QuoteTermsCtrl();
        PageReference pr = qtctrl.fetchData();
    }
    
    @IsTest 
    static void testMethod2(){
        List<Account> accsList = [SELECT ID,Name,(SELECT ID FROM Contacts WHERE CWS_Primary_Contact__c = true LIMIT 1) FROM Account];
        Product2 product1 = [SELECT ID,name FROM Product2 WHERE Name = 'TestProduct1' LIMIT 1];
        PricebookEntry pbe1 = [SELECT ID FROM PricebookEntry  LIMIT 1];
        Account soldtoaccount;
        List<Account> distiAccounts = new List<Account>();
        Contact primaryBillingcon;
        for(Account acc: accsList){
            if(acc.name == 'TestAccount'){
                soldtoaccount = acc;
                if(!acc.Contacts.Isempty()){
                    primaryBillingcon = acc.Contacts[0];
                }
            }
            else{
                distiAccounts.add(acc);
            }
        }
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> soldtoaccount.Id,//
                'Type'=>CWS_ConstantClass.QUOTE_TYPE_AMEND,
                'CurrencyIsoCode'=>'USD'
                };
                    Test.startTest();
        
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('RFS Opps',soldtoaccount.Id,opportunityFields,true);
        
        //Create Quote record : RFS
        Map<String, Object> quoteFields = new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
                'CWS_Quote_Type__c'=> 'Renewal', 
                'SBQQ__Distributor__c'=>distiAccounts[0].Id, //
                'CWS_Bill_To_Account__c'=> soldtoaccount.Id,//
                'CurrencyISOCode'=>'USD',
                'CWS_PO_Number__c'=>'ABC123456',
                'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
                'CWS_Actual_Contract_Term__c' => 12,
                'CWS_Bill_To_Contact__c'=>primaryBillingcon.id, //
                'SBQQ__PaymentTerms__c' => 'Net 30',
                'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Direct
                };       
        
        SBQQ__Quote__c quote1 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);
        Test.stopTest();
        
        // Create Quote lines For Quote 1: Under Review
        List<SBQQ__QuoteLine__c> insertQLI = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLine11 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product1.Id);
        quoteLine11[0].SBQQ__PricebookEntryId__c = pbe1.id;
        quoteLine11[0].CWS_Provisioning_Eligibility__c = 'Immediate';
        quoteLine11[0].CWS_Avg_Number_of_Days__c = 3;
        quoteLine11[0].CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Quarterly;        
        quoteLine11[0].SBQQ__NetPrice__c = 1000;
        quoteLine11[0].CWS_Period_for_Ramp_Spread_Deferment__c = 1; 
        quoteLine11[0].CWS_ProvisioningDate__c = null;
        quoteLine11[0].SBQQ__StartDate__c=Date.today();
        quoteLine11[0].CWS_Category__c = CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH;
        quoteLine11[0].CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE;
        quoteLine11[0].SBQQ__ChargeType__c =CWS_ConstantClass.ChargeType_OneTime;        
        List<SBQQ__QuoteLine__c> quoteLine12 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product1.Id);
        quoteLine12[0].SBQQ__PricebookEntryId__c = pbe1.id;
        quoteLine12[0].CWS_Provisioning_Eligibility__c = 'Immediate';
        quoteLine12[0].CWS_Avg_Number_of_Days__c = 3;
        quoteLine12[0].CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Quarterly;
        quoteLine12[0].CWS_Payment_Schedule_Driver__c = 'Deferment';
        quoteLine12[0].SBQQ__NetPrice__c = 1000;
        quoteLine12[0].CWS_Period_for_Ramp_Spread_Deferment__c = 1; 
        quoteLine12[0].CWS_ProvisioningDate__c = null;
        quoteLine12[0].SBQQ__StartDate__c= Date.today().adddays(1) ;
        quoteLine12[0].CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT;       
        quoteLine12[0].CWS_Uneven_Spread__c = true;
        quoteLine12[0].CWS_Uneven_Spread_Values__c = '1';
        quoteLine12[0].No_Of_Uneven_Spread_Entries__c = 1;        
        quoteLine12[0].SBQQ__PriorQuantity__c = 1;  
        List<SBQQ__QuoteLine__c> quoteLine13 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product1.Id);
        quoteLine13[0].CWS_Swapped_For__c = product1.Id ;
        quoteLine13[0].CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN;
        quoteLine13[0].CWS_Period_for_Ramp_Spread_Deferment__c =1;        
        quoteLine13[0].SBQQ__StartDate__c = date.today() ;        
        quoteLine13[0].SBQQ__ChargeType__c = CWS_ConstantClass.ChargeType_Recurring;
        quoteLine13[0].CWS_Min_Commit__c = true;
        quoteLine13[0].CWS_Category__c = 'Automate';        
        quoteLine13[0].CWS_Future_Contracted_Price__c = 1000;        
        quoteLine13[0].CWS_Future_pricing_Blocks__c = 2;
        
        insertQLI.add(quoteLine11[0]);
        insertQLI.add(quoteLine12[0]);
        insertQLI.add(quoteLine13[0]);        
        insert insertQLI;       
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quote1);                
        PageReference pageRef = Page.CWS_QuoteTerms;
        pageRef.getParameters().put('qid', String.valueOf(quote1.Id));
        Test.setCurrentPage(pageRef);
        CWS_QuoteTermsCtrl qtctrl = new CWS_QuoteTermsCtrl();
        PageReference pr = qtctrl.fetchData();
    }
    /*
    @IsTest
    static void testMethod3(){
        List<Account> accsList = [SELECT ID,Name,(SELECT ID FROM Contacts WHERE CWS_Primary_Contact__c = true LIMIT 1) FROM Account];
        Product2 product1 = [SELECT ID,name FROM Product2 WHERE Name = 'TestProduct1' LIMIT 1];
        PricebookEntry pbe1 = [SELECT ID FROM PricebookEntry  LIMIT 1];
        Account soldtoaccount;
        List<Account> distiAccounts = new List<Account>();
        Contact primaryBillingcon;
        for(Account acc: accsList){
            if(acc.name == 'TestAccount'){
                soldtoaccount = acc;
            }
            else{
                distiAccounts.add(acc);
            }
        }
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>True
                };
        Test.startTest();
        primaryBillingcon = CWS_UTLDataFactory.createContact('Testcontact', 'Dummy',  distiAccounts[0].Id, contactFieldValues, true);
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> distiAccounts[0].Id,
                'Type'=>CWS_ConstantClass.QUOTE_TYPE_AMEND,
                'CurrencyIsoCode'=>'USD'
                };
                    
        system.debug('before oppty--');
        Opportunity opty = CWS_UTLDataFactory.createOpportunity('RFS Opps',soldtoaccount.Id,opportunityFields,true);

        Map<String, Object> quoteFields = new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
                'CWS_Quote_Type__c'=> 'Renewal', 
                'SBQQ__Distributor__c'=>distiAccounts[0].Id, 
                'CWS_Bill_To_Account__c'=> distiAccounts[0].Id,
                'CurrencyISOCode'=>'USD',
                'CWS_PO_Number__c'=>'ABC123456',
                'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
                'CWS_Actual_Contract_Term__c' => 12,
                'CWS_Bill_To_Contact__c'=> primaryBillingcon.id, 
                'SBQQ__PaymentTerms__c' => 'Net 30',
                'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Channel
                };
        
        SBQQ__Quote__c quote1 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);
        Test.stopTest();
        
        // Create Quote lines For Quote 1: Under Review
        List<SBQQ__QuoteLine__c> insertQLI = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLine11 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product1.Id);
        quoteLine11[0].SBQQ__PricebookEntryId__c = pbe1.id;
        quoteLine11[0].CWS_Provisioning_Eligibility__c = 'Immediate';
        quoteLine11[0].CWS_Avg_Number_of_Days__c = 3;
        quoteLine11[0].CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Quarterly;
        quoteLine11[0].SBQQ__NetPrice__c = 1000;
        quoteLine11[0].CWS_Period_for_Ramp_Spread_Deferment__c = 1; 
        quoteLine11[0].CWS_ProvisioningDate__c = null;
        quoteLine11[0].SBQQ__StartDate__c=Date.today();
        quoteLine11[0].CWS_Category__c = CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH;
        quoteLine11[0].CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN;
        quoteLine11[0].SBQQ__ChargeType__c =CWS_ConstantClass.ChargeType_OneTime;
        quoteLine11[0].CWS_Swapped_For__c = product1.Id;    
        
        insertQLI.add(quoteLine11[0]); 
        insert insertQLI;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quote1);
        PageReference pageRef = Page.CWS_QuoteTerms; 
        pageRef.getParameters().put('qid', String.valueOf(quote1.Id));
        Test.setCurrentPage(pageRef);
        CWS_QuoteTermsCtrl qtctrl = new CWS_QuoteTermsCtrl();
        PageReference pr = qtctrl.fetchData();
    }*/
    @IsTest
    static void testMethod4(){
        
        List<Account> accsList = [SELECT ID,Name,(SELECT ID FROM Contacts WHERE CWS_Primary_Contact__c = true LIMIT 1) FROM Account];
        Product2 product1 = [SELECT ID,name FROM Product2 WHERE Name = 'TestProduct1' LIMIT 1];
        PricebookEntry pbe1 = [SELECT ID FROM PricebookEntry  LIMIT 1];
        Account soldtoaccount;
        List<Account> distiAccounts = new List<Account>();
        Contact primaryBillingcon;
        for(Account acc: accsList){
            if(acc.name == 'TestAccount'){
                soldtoaccount = acc;
                if(!acc.Contacts.Isempty()){
                    primaryBillingcon = acc.Contacts[0];
                }
            }
            else{
                distiAccounts.add(acc);
            }
        }
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> soldtoaccount.Id,//
                'Type'=>CWS_ConstantClass.QUOTE_TYPE_AMEND,
                'CurrencyIsoCode'=>'USD'
                };
                    Test.startTest();
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('RFS Opps',soldtoaccount.Id,opportunityFields,true);
        
        //Create Quote record : RFS
        Map<String, Object> quoteFields = new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
                'CWS_Quote_Type__c'=> 'Renewal', 
                'SBQQ__Distributor__c'=>distiAccounts[0].Id, 
                'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
                'CurrencyISOCode'=>'USD',
                'CWS_PO_Number__c'=>'ABC123456',
                'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
                'CWS_Actual_Contract_Term__c' => 12,
                'CWS_Bill_To_Contact__c'=>primaryBillingcon.id, 
                'SBQQ__PaymentTerms__c' => 'Net 30',
                'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_IIT
                };
        
        SBQQ__Quote__c quote1 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);
        Test.stopTest();
        
        // Create Quote lines For Quote 1: Under Review
        List<SBQQ__QuoteLine__c> insertQLI = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLine11 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product1.Id);
        quoteLine11[0].SBQQ__PricebookEntryId__c = pbe1.id;
        quoteLine11[0].CWS_Provisioning_Eligibility__c = 'Immediate';
        quoteLine11[0].CWS_Avg_Number_of_Days__c = 3;
        quoteLine11[0].CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Quarterly;
        quoteLine11[0].SBQQ__NetPrice__c = 1000;
        quoteLine11[0].CWS_Period_for_Ramp_Spread_Deferment__c = 1; 
        quoteLine11[0].CWS_ProvisioningDate__c = null;
        quoteLine11[0].SBQQ__StartDate__c=Date.today();
        quoteLine11[0].CWS_Category__c = CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH;
        quoteLine11[0].CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN;
        quoteLine11[0].SBQQ__ChargeType__c =CWS_ConstantClass.ChargeType_Recurring ;
        quoteLine11[0].CWS_Swapped_For__c = product1.Id;
        
        
        insertQLI.add(quoteLine11[0]); 
        insert insertQLI;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quote1);
        PageReference pageRef = Page.CWS_QuoteTerms; // Add your VF page Name here
        pageRef.getParameters().put('qid', String.valueOf(quote1.Id));
        Test.setCurrentPage(pageRef);
        CWS_QuoteTermsCtrl qtctrl = new CWS_QuoteTermsCtrl();
        PageReference pr = qtctrl.fetchData();
        
        //Filling below for test covergae.
        CWS_QuoteTermsCtrl.futurePricingQLI  fpQl = new CWS_QuoteTermsCtrl.futurePricingQLI();
        CWS_QuoteTermsCtrl.implementationSpreadQLI  impQl = new CWS_QuoteTermsCtrl.implementationSpreadQLI();
        fpQl.billingTerm = '3';
        fpQl.futurePriceEndDate = Date.today();
        fpQl.thirdPatyProduct = 'Test';
        impQl.spreadPrices = new list<string>();       
    }
}