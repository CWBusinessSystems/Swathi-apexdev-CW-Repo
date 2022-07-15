/*Class Name: CWS_QuoteTemplateLineItemsCtrlTest
*Description: Test Class for CWS_QuoteTemplateLineItemsCtrl
*Created By: 
*Created On: 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                 05/06/2020        BED-5114               Generating XSLFO
*/
@isTest(SeeAllData=false)
public with sharing class CWS_QuoteTemplateLineItemsCtrlTest {

    public static Profile objSaleRepProfile = [SELECT Id FROM Profile WHERE Name = 'CWS_Sales_Rep'];
    
    // Test data setup 
    @testSetup
    static void init(){
       //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','Quote'});           
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'USD','CWS_Distributor_Logic_Exclusion__c'=>false};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        Account accChannel = CWS_UTLDataFactory.createAccount('ConnectWise Test Account', new Map<String, Object>{'CWS_Is_Distributor__c'=> true,'Industry'=>'MSP','CWS_Distributor_Logic_Exclusion__c'=>true}, true);
        
        Contact contact = CWS_UTLDataFactory.createContact('tst01 FName', 'tst01 lName', soldtoaccount.id,new Map<String, Object> { 'CWS_Primary_Billing_Contact__c'=>true,'CWS_Primary_Contact__c'=>true}, true);
        Contact contactChannel = CWS_UTLDataFactory.createContact('tst01Channel', 'tst01Channel', accChannel.id,new Map<String, Object> {'CWS_Primary_Billing_Contact__c'=>true, 'CWS_Primary_Contact__c'=>true}, true);


        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'USD','CWS_Is_Distributor__c'=> true};
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount1', distributorAccountFieldValues,2,true);        
              
        // Create Distributr Reseller Records 
          CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.id,accChannel.Id, 'Distributor','Fulfillment', null, null, true);
        //  CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', null, null, true);
        
        
        
        
        
        /** Bulk Opp Creation*****************************************************************************************************************************************************/
        Map<String, Object> opptyFieldsNBDirect = new Map<String, Object>{
           'Name'=>'OpptyNBDirect','CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD','accountID'=>soldtoaccount.id,'CWS_Bill_To_Contact__c'=>contact.id
        };                
        Map<String, Object> oppFieldsAmendDirect = new Map<String, Object>{
            'Name'=> 'OpptyAmendDirect','CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD','accountID'=>soldtoaccount.id,'CWS_Bill_To_Contact__c'=>contact.id,'CWS_Disti_Deal_Phase__c'=>System.Label.CWS_Disti_Deal_End_Customer_Pricing
        }; 
        Map<String, Object> oppFieldsNBChannel = new Map<String, Object>{
            'CWS_Disti_Deal_Phase__c'=>System.Label.CWS_Disti_Deal_End_Customer_Pricing ,'Name'=> 'OpptyNBChannel','CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> accChannel.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD','CWS_Disti_Deal_Phase__c'=> System.Label.CWS_Disti_Deal_End_Customer_Pricing,'accountID'=>accChannel.id,'CWS_Bill_To_Contact__c'=>contactChannel.id
        };        
        Map<String, Object> oppFieldsNBIIT = new Map<String, Object>{
            'Name'=> 'OpptyNBIIT','CWS_Route_to_Market__c'=>CWS_ConstantClass.RTM_Value_IIT, 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD','accountID'=>soldtoaccount.id,'CWS_Bill_To_Contact__c'=>contact.id
        };        
        Map<String, Object> oppFieldsRWCDirect = new Map<String, Object>{
            'Name'=> 'OpptRWCDirect','CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'Renewal with Change','CurrencyIsoCode'=>'USD','accountID'=>soldtoaccount.id,'CWS_Bill_To_Contact__c'=>contact.id
        };  
        
        Map<Integer, Map<String, Object>> createOppsMap = new Map<Integer, Map<String, Object>>();
        createOppsMap.put(1, opptyFieldsNBDirect);
        createOppsMap.put(2, oppFieldsAmendDirect);
        createOppsMap.put(3, oppFieldsNBChannel);
        createOppsMap.put(4, oppFieldsNBIIT);
        createOppsMap.put(5, oppFieldsRWCDirect);    
        
        List<Opportunity> lstOpportunities = CWS_UTLDataFactory.createOpportunities(createOppsMap, createOppsMap.size(), true);
        for(Opportunity p :lstOpportunities){
            system.debug('####Opp id = '+ p.id);
        }

        /*************************************************************************************************************************************************************************/
                
        /** Bullk Quote Creation**************************************************************************************************************************************************/
        Map<String, Object> quoteFieldsNBDirect = new Map<String,Object>{
            'SBQQ__Account__c'=>soldtoaccount.Id,'SBQQ__opportunity2__c'=>lstOpportunities[0].Id,'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS,  'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Direct,
                'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CWS_Bill_To_Contact__c'=>contact.id,'CWS_Bill_To_Account__c'=>soldtoaccount.Id,
                'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2025,7,7)
        };
                
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Amendment_Read_Only' AND sObjectType = 'SBQQ__Quote__c'].Id;

        Map<String, Object> quoteFieldsAmendDirect =new Map<String,Object>{
            'SBQQ__Account__c'=> soldtoaccount.Id,'SBQQ__opportunity2__c'=>lstOpportunities[1].Id ,'CWS_Bill_To_Account__c'=>soldtoaccount.Id,'CWS_Bill_To_Contact__c'=>contact.id,'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_AMENDMENT,  
                'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_ADDENDUM,'RecordTypeId'=>recordTypeId 
        };        
              
        Map<String, Object> quoteFieldsNBChannel =new Map<String,Object>{
            'SBQQ__Account__c'=>soldtoaccount.Id,'SBQQ__opportunity2__c'=> lstOpportunities[2].Id ,'CWS_Bill_To_Account__c'=>accChannel.Id,'CWS_Bill_To_Contact__c'=>contactChannel.id,'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS,  
                'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Channel
        };
               
        Map<String, Object> quoteFieldsNBIIT = new Map<String,Object>{
            'SBQQ__Account__c'=>soldtoaccount.Id ,'SBQQ__opportunity2__c'=> lstOpportunities[3].Id,'CWS_Bill_To_Account__c'=>soldtoaccount.Id,'CWS_Bill_To_Contact__c'=>contact.id,'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS,  
                'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_IIT
        };
        
        Map<String, Object> quoteFieldsRWCDirect = new Map<String,Object>{
           'SBQQ__Account__c'=>soldtoaccount.Id ,'SBQQ__opportunity2__c'=> lstOpportunities[4].Id, 'CWS_Bill_To_Account__c'=>soldtoaccount.Id,'CWS_Bill_To_Contact__c'=>contact.id,'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_RENEWALWC,  
                'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Direct,
                'CWS_Transaction_Reason__c'=> CWS_ConstantClass.TRANSACTION_REASON_RENEWALWC
        };
        Map<Integer, Map<String, Object>> quotesMap = new Map<Integer, Map<String, Object>>();
        quotesMap.put(1,quoteFieldsNBDirect);
        quotesMap.put(2,quoteFieldsAmendDirect);
        quotesMap.put(3,quoteFieldsNBChannel);
        quotesMap.put(4,quoteFieldsNBIIT);
        quotesMap.put(5,quoteFieldsRWCDirect);
        
        List<SBQQ__Quote__c> lstQuotes = CWS_UTLDataFactory.createquotes(quotesMap, quotesMap.size(), true);

        /************************************************************************************************************************************************************************/
        
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        Pricebook2 ConnectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
        if(ConnectwisePricebook!=null){
            insert ConnectwisePricebook;
        }
        List<Product2> productList=new List<Product2>();
        Map<String,Object> additionalFields1 = new Map<String, Object>{'CWS_ChargeType__c'=>CWS_ConstantClass.ChargeType_Recurring, 'isActive'=>true, 'CWS_Category__c'=> 'Automate', 'CWS_Description__c'=>'This is a Demo Product Created For Marketing Purposes.Not For Sale'};
        
        
        Product2 prod1 = CWS_UTLDataFactory.createProduct('TestProductRecurring', 'RecurringProduct', additionalFields1, false);
        
        Map<String,Object> additionalFields2 = new Map<String, Object>{'CWS_ChargeType__c'=>CWS_ConstantClass.ChargeType_OneTime, 'isActive'=>true, 'CWS_Category__c'=> 'Automate'};
        Product2 prod2 = CWS_UTLDataFactory.createProduct('TestProductOneTime', 'OneTimeProduct', additionalFields2, false);
        
        
        productList.add(prod1);
        productList.add(prod2);
        insert productList;
        
        // Insert Standard PricebookEntries.
        List<PriceBookEntry> pbeListStd=new List<PricebookEntry>();
        for(product2 product:productList){
            Pricebookentry pbe2=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(), product.Id, 1000,'USD', false); 
            pbeListStd.add(pbe2);
        }
        upsert pbeListStd;

        // Insert PricebookEntries.
        List<PriceBookEntry> pbeList=new List<PricebookEntry>();
        for(product2 product:productList){
            Pricebookentry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(ConnectwisePricebook.Id, product.Id, 1000,'USD', false);          
            pbeList.add(pbe);
        }
        upsert pbeList;    


    }

    @isTest
    static void testPaymentScheduleOneTimeProduct(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode  from SBQQ__Quote__c ];
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c =:CWS_ConstantClass.ChargeType_OneTime];
            
            for (PricebookEntry entry : pbList) {
                SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c(
                SBQQ__Quote__c=quoteList[0].Id,
                CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1,               
                SBQQ__Product__c=entry.Product2Id,
				CWS_Transaction_Type__c = 'Rebill',    
                SBQQ__ListPrice__c=1000, 
                SBQQ__SubscriptionTerm__c=12,
                SBQQ__NetPrice__c=1200, 
                SBQQ__CustomerPrice__c = 3400,  
                SBQQ__RegularPrice__c = 3400,
                CWS_Disti_Regular_Price__c=3400,
                CWS_MM_ListPrice__c=2345,            
                SBQQ__PricebookEntryId__c=entry.Id);
               
                if(line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_OneTime){
                    line.CWS_Billing_Term__c=CWS_ConstantClass.ChargeType_OneTime;                
                }
                
                system.debug('&&& charge type = '+ line.CWS_ChargeType__c);
                lines.add(line);
            }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ.TriggerControl.enable();
            
            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(true, ctrl.oneTimeProductsAvailable);
            System.assertEquals(CWS_ConstantClass.ChargeType_OneTime, ctrl.wrap.bTypes[0]);
        }
        Test.stopTest();


    }
	
	     
   /* @isTest
    static void testQLNoBillingTem(){
        Test.startTest();
        Product2 p = [Select id, CWS_Description__c FROM Product2 limit 1];      
        SBQQ__Quote__c quoteList=[Select Id, Name, CurrencyIsoCode,CWS_Quote_Type__c  from SBQQ__Quote__c LIMIT 1];
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(quoteList!=null){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            for (PricebookEntry entry : pbList) {
                SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList.Id,CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=entry.Product2Id, SBQQ__PricebookEntryId__c=entry.Id);
                if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                    line.SBQQ__BillingType__c='Advance';
                }
                lines.add(line);
            }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList.Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertNotEquals(0, ctrl.wrap.oneTimeLines.size());
            System.assertNotEquals(0, ctrl.wrap.recurrLinesMap.size());
        }
        Test.stopTest();
    }
    */
      @isTest
    static void testRTMDirect(){
    
        Test.startTest();
        Boolean isEffectQtyset = false;
        
        List<SBQQ__Quote__c> quoteList = [Select Id, Name, CurrencyIsoCode, CWS_Quote_Type__c,SBQQ__opportunity2__c  from SBQQ__Quote__c Where CWS_Quote_Type__c =: CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS AND CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Direct];
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            
                for (PricebookEntry entry : pbList) {
                    
                    
                        SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                        (SBQQ__Quote__c=quoteList[0].Id,
                        CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                        SBQQ__Quantity__c=1, 
                        SBQQ__ListPrice__c=1000, 
                        SBQQ__SubscriptionTerm__c=12,
                        SBQQ__NetPrice__c=1200, 
                        SBQQ__Product__c=entry.Product2Id, 
                        SBQQ__PricebookEntryId__c=entry.Id,
                        SBQQ__CustomerPrice__c = 3400,
                        CWS_Billing_Term__c = 'Monthly',
                        //SBQQ__EffectiveQuantity__c = 4,
                        SBQQ__PricingMethod__c = CWS_ConstantClass.PRICINGMETHOD_BLOCK,  
                        CWS_Period_for_Ramp_Spread_Deferment__c = 1,
                        CWS_Payment_Schedule_Driver__c = 'Spread',
                         SBQQ__RegularPrice__c = 9000,
                        CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                        if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                            line.SBQQ__BillingType__c='Advance';
                        }
                        
                        lines.add(line);
                    
                }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(ql.SBQQ__Quantity__c, ql.SBQQ__EffectiveQuantity__c);
			System.assertEquals(true,ctrl.wrap.hasRecurrLines);
        }       
        Test.stopTest();        
    }
    
      @isTest
    static void testRTMIIT(){
    
        Test.startTest();
        Boolean isEffectQtyset = false;
        
        List<SBQQ__Quote__c> quoteList = [Select Id, Name, CurrencyIsoCode, CWS_Quote_Type__c,SBQQ__opportunity2__c  from SBQQ__Quote__c Where CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_IIT];
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            
                for (PricebookEntry entry : pbList) {
                    
                    
                        SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                        (SBQQ__Quote__c=quoteList[0].Id,
                        CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                        SBQQ__Quantity__c=1, 
                        SBQQ__ListPrice__c=1000, 
                        SBQQ__SubscriptionTerm__c=12,
                        SBQQ__NetPrice__c=1200, 
                        SBQQ__Product__c=entry.Product2Id, 
                        SBQQ__PricebookEntryId__c=entry.Id,
                        SBQQ__CustomerPrice__c = 3400,
                        CWS_Billing_Term__c =  CWS_ConstantClass.BillingTerm_TriAnnual,
                        CWS_Reseller_Net_Price__c = 90909,
                        //SBQQ__EffectiveQuantity__c = 4,
                        CWS_Period_for_Ramp_Spread_Deferment__c = 4,
                        CWS_Payment_Schedule_Driver__c = 'Spread',
                        CWS_MM_ListPrice__c = 4566,
                         SBQQ__RegularPrice__c = 9000,
                        CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                        if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                            line.SBQQ__BillingType__c='Advance';
                        }
                        
                        lines.add(line);
                    
                }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(ql.SBQQ__Quantity__c, ql.SBQQ__EffectiveQuantity__c);
			system.assertEquals(CWS_ConstantClass.BillingTerm_TriAnnual,ctrl.wrap.bTypes[0]);

        }       
        Test.stopTest();        
    }
    
	
      @isTest
    static void testRTMIIT2(){
    
        Test.startTest();
        Boolean isEffectQtyset = false;
        
        List<SBQQ__Quote__c> quoteList = [Select Id, Name, CWS_Bill_To_Account__c, CurrencyIsoCode, CWS_Quote_Type__c,SBQQ__opportunity2__c  from SBQQ__Quote__c Where CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_IIT];
        
			
		Opportunity opp = [Select id, CWS_Disti_Deal_Phase__c from Opportunity where id = : quoteList[0].SBQQ__opportunity2__c];
		opp.CWS_Disti_Deal_Phase__c = System.Label.CWS_Disti_Deal_End_Customer_Pricing;
		update opp;
		
		
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            
                for (PricebookEntry entry : pbList) {
                    
                    
                        SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                        (SBQQ__Quote__c=quoteList[0].Id,
                        CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                        SBQQ__Quantity__c=1, 
                        SBQQ__ListPrice__c=1000, 
                        SBQQ__SubscriptionTerm__c=12,
                        SBQQ__NetPrice__c=1200, 
                        SBQQ__Product__c=entry.Product2Id, 
                        SBQQ__PricebookEntryId__c=entry.Id,
                        SBQQ__CustomerPrice__c = 3400,
                        CWS_Billing_Term__c =  CWS_ConstantClass.BillingTerm_TriAnnual,
                        CWS_Reseller_Net_Price__c = 90909,
                        //SBQQ__EffectiveQuantity__c = 4,
                        CWS_Period_for_Ramp_Spread_Deferment__c = 4,
                        CWS_Payment_Schedule_Driver__c = 'Spread',
                        CWS_MM_ListPrice__c = 4566,
                         SBQQ__RegularPrice__c = 9000,
                        CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                        if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                            line.SBQQ__BillingType__c='Advance';
                        }
                        
                        lines.add(line);
                    
                }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(ql.SBQQ__Quantity__c, ql.SBQQ__EffectiveQuantity__c);
			system.assertEquals(CWS_ConstantClass.BillingTerm_TriAnnual,ctrl.wrap.bTypes[0]);

        }       
        Test.stopTest();        
    }
    
	
     @isTest
    static void testRTMIITBTQuarterly(){
    
        Test.startTest();
        Boolean isEffectQtyset = false;
        
        List<SBQQ__Quote__c> quoteList = [Select Id, Name, CurrencyIsoCode, CWS_Quote_Type__c,SBQQ__opportunity2__c  from SBQQ__Quote__c Where CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_IIT];
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            
                for (PricebookEntry entry : pbList) {
                    
                    
                        SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                        (SBQQ__Quote__c=quoteList[0].Id,
                        CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                        SBQQ__Quantity__c=1, 
                        SBQQ__ListPrice__c=1000, 
                        SBQQ__SubscriptionTerm__c=12,
                        SBQQ__NetPrice__c=1200, 
                        SBQQ__Product__c=entry.Product2Id, 
                        SBQQ__PricebookEntryId__c=entry.Id,
                        SBQQ__CustomerPrice__c = 3400,
                        CWS_Billing_Term__c =  CWS_ConstantClass.BillingTerm_Quarterly,
                        CWS_Reseller_Net_Price__c = 90909,
                        //SBQQ__EffectiveQuantity__c = 4,                       
                        CWS_MM_ListPrice__c = 4566,
                         SBQQ__RegularPrice__c = 9000,
                        CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                        if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                            line.SBQQ__BillingType__c='Advance';
                        }
                        
                        lines.add(line);
                    
                }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(ql.SBQQ__Quantity__c, ql.SBQQ__EffectiveQuantity__c);
			system.assertEquals(CWS_ConstantClass.BillingTerm_Quarterly,ctrl.wrap.bTypes[0]);
			system.assertEquals(true,ctrl.wrap.hasRecurrDisc);

			

        }       
        Test.stopTest();        
    }
    
    
     @isTest
    static void testRTMChannel(){
    
        Test.startTest();
        Boolean isEffectQtyset = false;
        
        List<SBQQ__Quote__c> quoteList = [Select Id, Name, CurrencyIsoCode, CWS_Quote_Type__c,SBQQ__opportunity2__c  from SBQQ__Quote__c Where CWS_Quote_Type__c =: CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS AND CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Channel];
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            
                for (PricebookEntry entry : pbList) {
                    
                    
                        SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                        (SBQQ__Quote__c=quoteList[0].Id,
                        CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                        SBQQ__Quantity__c=1, 
                        SBQQ__ListPrice__c=1000, 
                        SBQQ__SubscriptionTerm__c=12,
                        SBQQ__NetPrice__c=1200, 
                        SBQQ__Product__c=entry.Product2Id, 
                        SBQQ__PricebookEntryId__c=entry.Id,
                        SBQQ__CustomerPrice__c = 3400,
                         SBQQ__RegularPrice__c = 9000,
                         CWS_Disti_Regular_Price__c=9000,
                        CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_BiAnnual,
                        //SBQQ__EffectiveQuantity__c = 4,
                        CWS_Period_for_Ramp_Spread_Deferment__c = 4,
                        CWS_Payment_Schedule_Driver__c = 'Spread',                  
                        CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                        if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                            line.SBQQ__BillingType__c='Advance';
                        }
                        
                        lines.add(line);
                    
                }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(ql.SBQQ__Quantity__c, ql.SBQQ__EffectiveQuantity__c);
			system.assertEquals(CWS_ConstantClass.BillingTerm_BiAnnual,ctrl.wrap.bTypes[0]);

        }       
        Test.stopTest();        
    }
    
     @isTest
    static void testRTMChannelRemoveDisti(){
    
        Test.startTest();
        Boolean isEffectQtyset = false;
        
        List<SBQQ__Quote__c> quoteList = [Select Id, Name, CurrencyIsoCode, CWS_Quote_Type__c,SBQQ__opportunity2__c  from SBQQ__Quote__c Where CWS_Quote_Type__c =: CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS AND CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Channel];
        
        Opportunity opp = [select id, CWS_Disti_Deal_Phase__c from Opportunity where id =: quoteList[0].SBQQ__opportunity2__c];
        opp.CWS_Disti_Deal_Phase__c = CWS_ConstantClass.Disti_Pricing;
        update opp;
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            
                for (PricebookEntry entry : pbList) {
                    
                    
                        SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                        (SBQQ__Quote__c=quoteList[0].Id,
                        CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                        SBQQ__Quantity__c=1, 
                        CWS_Disti_Regular_Price__c = 9000,
                        SBQQ__ListPrice__c=1000, 
                        SBQQ__SubscriptionTerm__c=12,
                        SBQQ__NetPrice__c=1200, 
                        SBQQ__Product__c=entry.Product2Id, 
                        SBQQ__PricebookEntryId__c=entry.Id,
                        SBQQ__CustomerPrice__c = 3400,
                         SBQQ__RegularPrice__c = 9000,
                        CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Annual,
                        //SBQQ__EffectiveQuantity__c = 4,
                                        
                        CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                        if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                            line.SBQQ__BillingType__c='Advance';
                        }
                        
                        lines.add(line);
                    
                }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(ql.SBQQ__Quantity__c, ql.SBQQ__EffectiveQuantity__c);
			system.assertEquals(CWS_ConstantClass.BillingTerm_Annual,ctrl.wrap.bTypes[0]);

        }       
        Test.stopTest();        
    }
    
     @isTest
    static void testRTMChannelRemDistiLogic(){
    
        Test.startTest();
        Boolean isEffectQtyset = false;
        
        List<SBQQ__Quote__c> quoteList = [Select Id, Name,CWS_Bill_To_Account__c, CurrencyIsoCode, CWS_Quote_Type__c,SBQQ__opportunity2__c  from SBQQ__Quote__c Where CWS_Quote_Type__c =: CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS AND CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Channel];
        
        Account acc = [select id, CWS_Distributor_Logic_Exclusion__c from account where id =: quoteList[0].CWS_Bill_To_Account__c];
        acc.CWS_Distributor_Logic_Exclusion__c = false;
        update acc;
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            
                for (PricebookEntry entry : pbList) {
                    
                    
                        SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                        (SBQQ__Quote__c=quoteList[0].Id,
                        CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                        SBQQ__Quantity__c=1, 
                        SBQQ__ListPrice__c=1000, 
                        SBQQ__SubscriptionTerm__c=12,
                        SBQQ__NetPrice__c=1200, 
                        SBQQ__Product__c=entry.Product2Id, 
                        SBQQ__PricebookEntryId__c=entry.Id,
                        SBQQ__CustomerPrice__c = 3400,
                         SBQQ__RegularPrice__c = 9000,
                         CWS_Disti_Regular_Price__c = 9000,
                        CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_SemiAnnual,
                        //SBQQ__EffectiveQuantity__c = 4,
                        CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                        if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                            line.SBQQ__BillingType__c='Advance';
                        }
                        
                        lines.add(line);
                    
                }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(ql.SBQQ__Quantity__c, ql.SBQQ__EffectiveQuantity__c);
			system.assertEquals(CWS_ConstantClass.BillingTerm_SemiAnnual,ctrl.wrap.bTypes[0]);

        }       
        Test.stopTest();        
    }
    
    @isTest
    static void testMakeDefaultsAmend(){
    
        Test.startTest();
        Boolean isEffectQtyset = false;
        List<SBQQ__Quote__c> quoteList = [Select Id, Name, CurrencyIsoCode, CWS_Quote_Type__c  from SBQQ__Quote__c Where CWS_Quote_Type__c =: CWS_ConstantClass.QUOTE_TYPE_AMENDMENT];
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c in (:CWS_ConstantClass.ChargeType_OneTime,:CWS_ConstantClass.ChargeType_Recurring)];
            
                for (PricebookEntry entry : pbList) {
                    
                    if(quoteList[0].CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT){
                    
                        SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                        (SBQQ__Quote__c=quoteList[0].Id,
                        CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                        SBQQ__Quantity__c=1, 
                        SBQQ__RegularPrice__c = 9000,
                        SBQQ__ListPrice__c=1000, 
                        SBQQ__SubscriptionTerm__c=12,
                        SBQQ__NetPrice__c=1200, 
                        SBQQ__Product__c=entry.Product2Id, 
                        SBQQ__PricebookEntryId__c=entry.Id,
                        SBQQ__CustomerPrice__c = 3400,
                        CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Quarterly,
                        CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                        if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                            line.SBQQ__BillingType__c='Advance';
                        }
                        lines.add(line);
                    }
                }
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();

            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
            System.assertEquals(ql.SBQQ__Quantity__c, ql.SBQQ__EffectiveQuantity__c);
		    //system.assertEquals(CWS_ConstantClass.BillingTerm_Quarterly,ctrl.wrap.bTypes[0]);

        }       
        Test.stopTest();        
    }
    
    @isTest
    static void testMakeDefaultsRWC(){
    
        Test.startTest();
        Account billTo = [SELECT id, CWS_Distributor_Logic_Exclusion__c from Account LIMIT 1];
        Opportunity tstOpp = [SELECT id from Opportunity limit 1];
        SBQQ__Quote__c quoteList = [Select Id, Name, CurrencyIsoCode,CWS_Transaction_Reason__c, CWS_Quote_Type__c,SBQQ__Opportunity2__c  from SBQQ__Quote__c Where CWS_Quote_Type__c =: CWS_ConstantClass.QUOTE_TYPE_RENEWALWC LIMIT 1];
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        
        if(quoteList!=null){
            PricebookEntry[] pbList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2Id!= :Test.getStandardPricebookId() and 
                                            Product2.CWS_ChargeType__c =:CWS_ConstantClass.ChargeType_Recurring];            
            
            for (PricebookEntry entry : pbList) {
                
                if(quotelist.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC){
                        
                    SBQQ__QuoteLine__c line=new SBQQ__QuoteLine__c
                    (SBQQ__Quote__c=quotelist.Id,
                    SBQQ__RegularPrice__c = 9000,
                    CWS_ChargeType__c=entry.Product2.CWS_ChargeType__c,
                    SBQQ__Quantity__c=5, 
                    SBQQ__ListPrice__c=10000, 
                    SBQQ__SubscriptionTerm__c=12,
                    SBQQ__NetPrice__c=1200, 
                    SBQQ__Product__c=entry.Product2Id, 
                    SBQQ__PricebookEntryId__c=entry.Id,
                    SBQQ__CustomerPrice__c = 3400,
                    CWS_Billing_Term__c = 'Monthly',
                   // SBQQ__EffectiveQuantity__c = 4,
                    CWS_Transaction_Quantity__c = 1,
                    SBQQ__PricingMethod__c = 'Cost',
                   // SBQQ__ProductName__c = 'Cloud Access SPQ',
                   // SBQQ__ProductCode__c = 'CASP9077',
                    //SBQQ__Product__r.CWS_Description__c = 'This is a Demo Product Created For Marketing Purposes.Not For Sale',
                    CWS_Minimum_Commit_Eligibility__c = true,
                    CWS_Min_Commit__c = true,
                    SBQQ__DiscountScheduleType__c = CWS_ConstantClass.DISCOUNTSCH_SLAB,
                   // CWS_Usage_Ramp_Qty__c = '2',
                    CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE);
                    if (line.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring) {
                        line.SBQQ__BillingType__c='Advance';
                    }
                    lines.add(line);                            
                    
                }
            }
            
            SBQQ.TriggerControl.disable();
            insert lines;
            SBQQ__QuoteLine__c ql = [select id, SBQQ__Quantity__c, SBQQ__EffectiveQuantity__c from SBQQ__QuoteLine__c Limit 1];
            SBQQ.TriggerControl.enable();
            //Decimal finalQty = ql.SBQQ__Quantity__c - ql.CWS_Transaction_Quantity__c;
            Test.setCurrentPage(new PageReference('/apex/CWS_Quote_Template_LineItems'));
            ApexPages.currentPage().getparameters().put('qid', quoteList.Id);        
            CWS_QuoteTemplateLineItemsCtrl ctrl = new CWS_QuoteTemplateLineItemsCtrl();
            ctrl.fetchData();
             system.assertEquals(true,ctrl.wrap.hasMinCommLines);
             system.assertEquals(true,ctrl.wrap.hasMinCommDisc);
             system.assertEquals(CWS_ConstantClass.BillingTerm_Monthly,ctrl.wrap.bTypes[0]);
                         
        }
        Test.stopTest();
    }
   
}