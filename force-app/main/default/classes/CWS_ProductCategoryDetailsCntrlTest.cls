/*Class Name: CWS_ProductCategoryDetailsCntrlTest
*Description: Test Class for CWS_ProductCategoryDetailsCntrlTest
*Created By: Indra Ganesan
*Created On: 19-08-2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            Description
*------------------------------------------------------------------------------------------
*Indra Ganesan         03-08-2020       Test Class for CWS_ProductCategoryDetailsCntrlTest           
    */
@isTest(SeeAllData=false)
public with sharing class CWS_ProductCategoryDetailsCntrlTest {
    
    @TestSetup
    static void init(){
        
        // Insert Trigger Switch
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','OpportunityLineItem'}); 
       
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'USD',
            'CWS_Purchase_Order_Required__c'=>'Yes'
            };
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        //create Contact
        Contact contact = CWS_UTLDataFactory.createContact('tst01 FName', 'tst01 lName', soldtoaccount.id,new Map<String, Object> {}, true);

        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'USD','CWS_Is_Partner__c'=>true,'CWS_Is_Distributor__c'=>true};
        Account distiAccounts =CWS_UTLDataFactory.createAccount('TestDistiAccount', distributorAccountFieldValues,true);
         // Create Products
        Map<String, Object> productFields=new Map<String, Object>{
              'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12,
              'CWS_Charge_Model__c'=>'Per Unit Pricing', 
              'CWS_License_Type__c'=>'SaaS', 
              'CWS_Route_to_Market__c'=>'Direct', 
              'CWS_SKU_Type__c'=>'Package', 
              'CWS_UOM__c'=>'Each', 
              'CWS_Sub_Category__c'=>'License', 
              'CWS_Currencies__c'=>'USD', 
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
         //Create product
        List<Product2> lstProducts = new List<Product2>();
        Product2 p=CWS_UTLDataFactory.createProduct('Testp', 'SKU123',productFields,false);
        p.SBQQ__SubscriptionType__c='Renewable';
        p.SBQQ__SubscriptionBase__c='List';
        p.CWS_Avg_Number_of_Days__c=10;
        p.CWS_ChargeType__c='One-Time';
        p.CWS_Provisioning_Eligibility__c='Immediate';
        
        lstProducts.add(p); 
        insert lstProducts;
        
         
         // Create Pricebook Entry       
        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id=Test.getStandardPricebookId(), Product2Id = p.Id, UnitPrice = 1000, IsActive = true);
        insert standardPBE;        
        Pricebook2 pbCW = CWS_UTLDataFactory.createCustomPB('ConnectWise Standard PriceBook', true);             
        PricebookEntry pbe = CWS_UTLDataFactory.createPBEwithPricebookId(pbCW.Id,p.id,1000.00,'USD', true);        
             
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
              'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> distiaccounts.Id,
              'Type'=>'Commission Only',
                'CurrencyIsoCode'=>'USD',
                'CWS_Distributor__c'=>distiaccounts.Id,
                    'CWS_Legal_Entity__c'=>'CW-US',
                  'Pricebook2Id'=>pbCW.id,
                  'RecordTypeId'=>CWS_ConstantClass.Opportunity_CommissionOnly
        }; 
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);     
                     
        system.debug(' @@@ Opty Currency ISO CODE'+ opty.CurrencyISOCode);    
        system.debug(' @@@ pbe Currency ISO CODE'+ pbe.CurrencyISOCode);
        //Create Opp line item
        OpportunityLineItem oliObj = new OpportunityLineItem();
        oliObj.OpportunityId = opty.id;
        oliObj.Product2Id = p.id;
        oliObj.Quantity = 1;
        //oliObj.TotalPrice = 2000;
        oliObj.CWS_Commission_Only__c = true;
        oliObj.UnitPrice = 500;
        oliObj.PricebookEntryId = pbe.Id;
        insert oliObj;
        
        //Create Quote        
        Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__ExpirationDate__c'=>system.today()+20,'SBQQ__PrimaryContact__c'=>contact.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Quote_Type__c'=>'New Business','CWS_Bill_To_Account__c'=>soldtoaccount.id, 'CWS_Master__c'=>false,'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2019,7,7), 'CWS_Route_to_Market__c'=>'Direct'
        };        
        
        SBQQ__Quote__c quote1 = CWS_UTLDataFactory.createQuote(soldtoaccount.id,opty.id,addFields,true);
        //SBQQ__Quote__c quote2 = CWS_UTLDataFactory.createQuote(soldtoaccount.id,opty.id,addFields,true);
                
        
        
    }
    
     @isTest
    Public static void  testProductCategoryDetailsCntlr(){
        
        Test.startTest();
        Account acc = [Select id from Account LIMIT 1];
        
        Opportunity opty = [Select id,StageName from Opportunity];
        List<OpportunityLineItem> lstOli = [select id from OpportunityLineItem where OpportunityId=: opty.id];

        List<SBQQ__Quote__c> lstQuotes = [SELECT id,SBQQ__Status__c  from SBQQ__Quote__c];
        for(SBQQ__Quote__c q: lstQuotes){
          q.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG;         
        }
        if(lstQuotes != null)       
            update lstQuotes;
         
        CWS_ProductCategoryDetailsCntrl ctrl = new CWS_ProductCategoryDetailsCntrl();
        ctrl.accid = acc.id;
        ctrl.Oppid = opty.id;
        ctrl.lstQuotes = lstQuotes;
        system.assertEquals(acc.id, ctrl.accid);
        system.assertEquals(opty.id, ctrl.Oppid);        
        system.assertEquals('Automate',ctrl.getopptylines());
        system.assertEquals(lstQuotes.size(), ctrl.lstQuotes.size());
        
        Test.stopTest();
        
    }
}