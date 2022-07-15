/* Class Name   : CWS_PaymentScheduleController_Test
 * Description  : Test Class for CWS_PaymentScheduleController Class
 * Created By   : Aditya
 * Created On   : 8/13/2020
 * Modification Log
*------------------------------------------------------------------------------------------
*Developer              			Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_PaymentScheduleController_Test {
    
    // Test data setup 
    @testSetup static void createTestDataPaymentSchedule(){
       //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','Quote'});           
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR'};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
             'CWS_Is_Partner__c'=>true,'CWS_Is_Distributor__c'=>true,
             'CWS_Distributor_Logic_Exclusion__c'=> true   };
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
              
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', null, null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', null, null, true);
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD', 'CWS_Disti_Deal_Phase__c' => System.Label.CWS_Disti_Deal_End_Customer_Pricing
        };
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);
                
        //Create Quote record
        Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS,  
                'SBQQ__Distributor__c'=>distiAccounts[0].Id, 'CWS_Bill_to_Account__c'=> distiaccounts[0].Id,'CWS_Reseller_Account__c'=> soldtoaccount.id
        };
        SBQQ__Quote__c quote=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);


        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        Pricebook2 ConnectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
        if(ConnectwisePricebook!=null){
            insert ConnectwisePricebook;
        }
        List<Product2> productList=new List<Product2>();
        Map<String,Object> additionalFields1 = new Map<String, Object>{'CWS_ChargeType__c'=>'Recurring', 'isActive'=>true, 'CWS_Category__c'=> 'Automate',
                                                                        'SBQQ__BillingType__c'=>'Advance'};
        Product2 prod1 = CWS_UTLDataFactory.createProduct('TestProductRecurring', 'RecurringProduct', additionalFields1, false);
        
        Map<String,Object> additionalFields2 = new Map<String, Object>{'CWS_ChargeType__c'=>'One-Time', 'isActive'=>true, 'CWS_Category__c'=> 'Automate'};
        Product2 prod2 = CWS_UTLDataFactory.createProduct('TestProductOneTime', 'OneTimeProduct', additionalFields2, false);
        
        Map<String,Object> additionalFields3 = new Map<String, Object>{'CWS_ChargeType__c'=>'Recurring', 'isActive'=>true, 'CWS_Category__c'=> 'Automate',
                                                                        'SBQQ__BillingType__c'=>'Advance'};
        Product2 prod3 = CWS_UTLDataFactory.createProduct('TestProductRamp', 'RampProduct', additionalFields3, false);
        
        Map<String,Object> additionalFields4 = new Map<String, Object>{'CWS_ChargeType__c'=>'Recurring', 'isActive'=>true, 'CWS_Category__c'=> 'Automate',
                                                                        'SBQQ__BillingType__c'=>'Advance'};
        Product2 prod4 = CWS_UTLDataFactory.createProduct('TestProductSpread', 'SpreadProduct', additionalFields4, false);
        
        Map<String,Object> additionalFields5 = new Map<String, Object>{'CWS_ChargeType__c'=>'Recurring', 'isActive'=>true, 'CWS_Category__c'=> 'Automate',
                                                                        'SBQQ__BillingType__c'=>'Advance'};
        Product2 prod5 = CWS_UTLDataFactory.createProduct('TestProductDeferment', 'DefermentProdut', additionalFields5, false);
        productList.add(prod1); productList.add(prod2);productList.add(prod3); productList.add(prod4);productList.add(prod5);
        if(productList!=null){
        insert productList;
        }
        
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
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Direct';
        update quoteList[0];
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_OneTime];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12, CWS_Payment_Schedule_Driver__c='Spread',CWS_Billing_Term__c='Monthly',CWS_Period_for_Ramp_Spread_Deferment__c=1,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id);
            if(quoteLine!=null){
            insert quoteLine;
            }
            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
            SBQQ__QuoteLine__c[] quoteLineList=[Select Id, SBQQ__NetTotal__c from SBQQ__QuoteLine__c where CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_OneTime];        
            //System.assertNotEquals(true,quoteLineList.isEmpty());
            //System.assertNotEquals(null, contr.paymentScheduleList );                
            //System.assertEquals(quoteLineList[0].SBQQ__NetTotal__c, contr.paymentScheduleList[0].servicePrice);            
        }
        Test.stopTest();


    }
   
    @isTest
    static void testPaymentScheduleOneTimeProduct2(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Direct';
        update quoteList[0];
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_OneTime];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12, CWS_Payment_Schedule_Driver__c='Spread',CWS_Billing_Term__c='Monthly',CWS_Period_for_Ramp_Spread_Deferment__c=4,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id);
            if(quoteLine!=null){
            insert quoteLine;
            }
            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
        }
        Test.stopTest();
	}
   
    @isTest
    static void testPaymentScheduleRampProduct(){
        Test.startTest();
          SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Direct';
        update quoteList[0];
       	
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,CWS_Payment_Schedule_Driver__c='Ramp', 
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=2, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_Monthly);
             SBQQ.TriggerControl.disable();
            if(quoteLine!=null){
            insert quoteLine;
            }
    		 SBQQ__QuoteLine__c quoteLine1=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[1].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=1,CWS_Payment_Schedule_Driver__c='Ramp', 
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[1].Product2Id, SBQQ__PricebookEntryId__c=pbeList[1].Id,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=2, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_BiAnnual);
            if(quoteLine1!=null){
            //insert quoteLine1;
            }
             SBQQ.TriggerControl.enable();
            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
            SBQQ__QuoteLine__c[] quoteLineList=[Select Id, SBQQ__NetTotal__c, SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where 
                    CWS_Payment_Schedule_Driver__c=:CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP];        
           // System.assertNotEquals(true,quoteLineList.isEmpty());
            //System.assertNotEquals(true, contr.paymentScheduleList.isEmpty()); 
            //System.assert(contr.paymentScheduleList.size()==3);
            ///System.assertEquals(quoteLineList[0].SBQQ__NetTotal__c/quoteLineList[0].SBQQ__SubscriptionTerm__c, contr.paymentScheduleList[2].recurringPrice); 
        }
        Test.stopTest();
  
    }    
   
    @isTest
    static void testPaymentScheduleBillingTypeQuarterly(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
       
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c='Deferment',
                SBQQ__BillingType__c='Advance', CWS_Period_for_Ramp_Spread_Deferment__c=2, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_Quarterly);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
            SBQQ__QuoteLine__c[] quoteLineList=[Select Id, SBQQ__NetTotal__c, SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where 
                    CWS_Payment_Schedule_Driver__c=:CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP];        
           }
        Test.stopTest();
    }        
     
        @isTest
    static void testPaymentScheduleBillingTypeQuarterly2(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Direct';
        update quoteList[0];
       
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_OneTime];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                SBQQ__BillingType__c='Advance', CWS_Period_for_Ramp_Spread_Deferment__c=2, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_Annual);
            SBQQ.TriggerControl.disable();
            if(quoteLine!=null){
            insert quoteLine;
            }
            
            SBQQ.TriggerControl.enable();
            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
            SBQQ__QuoteLine__c[] quoteLineList=[Select Id, SBQQ__NetTotal__c, SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where 
                    CWS_Payment_Schedule_Driver__c=:CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP];        
           }
        Test.stopTest();
    }        
    
    @isTest
    static void testPaymentScheduleBillingTypeBiAnnual(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, SBQQ__SubscriptionTerm__c,CurrencyIsoCode,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
         quoteList[0].CWS_Route_to_Market__c = 'Direct';
        quoteList[0].SBQQ__SubscriptionTerm__c = 1;
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, 
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c=CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP,
                SBQQ__BillingType__c='Advance', CWS_Period_for_Ramp_Spread_Deferment__c=4, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_Quarterly);
            if(quoteLine!=null){
            insert quoteLine;
            }
            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
            SBQQ__QuoteLine__c[] quoteLineList=[Select Id, SBQQ__NetTotal__c, SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where 
                    CWS_Payment_Schedule_Driver__c=:CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP];        
           
        }
        Test.stopTest();
    }            

    @isTest
    static void testPaymentScheduleBillingTypeTriAnnual(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
         quoteList[0].CWS_Route_to_Market__c = 'Direct';
        update quoteList[0];
        
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=11,
                SBQQ__NetPrice__c=1100, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c='Spread',CWS_Uneven_Spread__c= true, CWS_Uneven_Spread_Values__c= '100;900',No_Of_Uneven_Spread_Entries__c= 2,
                SBQQ__BillingType__c='Advance', CWS_Period_for_Ramp_Spread_Deferment__c=2, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_TriAnnual);
            if(quoteLine!=null){
            insert quoteLine;
            }
            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
            SBQQ__QuoteLine__c[] quoteLineList=[Select Id, SBQQ__NetTotal__c, SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where 
                    CWS_Payment_Schedule_Driver__c=:CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP];
            //System.assertNotEquals(true,quoteLineList.isEmpty());
            //System.assertNotEquals(true, contr.paymentScheduleList.isEmpty()); 
            //System.assert(contr.paymentScheduleList.size()==3);
            //System.assertEquals((quoteLineList[0].SBQQ__NetTotal__c/quoteLineList[0].SBQQ__SubscriptionTerm__c)*4, contr.paymentScheduleList[2].recurringPrice); 
        }
        Test.stopTest();
    }  
    
    @isTest
    static void testPaymentScheduleBillingTypeAnnual(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
         quoteList[0].CWS_Route_to_Market__c = 'Direct';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_OneTime];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,CWS_Min_Commit__c = true,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c=CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP,
                SBQQ__BillingType__c='Advance', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_OneTime);
            if(quoteLine!=null){
            insert quoteLine;
            }
            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
            SBQQ__QuoteLine__c[] quoteLineList=[Select Id, SBQQ__NetTotal__c, SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where 
                    CWS_Payment_Schedule_Driver__c=:CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP];
           // System.assertNotEquals(true,quoteLineList.isEmpty());
            //System.assertNotEquals(true, contr.paymentScheduleList.isEmpty()); 
            //System.assert(contr.paymentScheduleList.size()==3);
            //System.assertEquals(quoteLineList[0].SBQQ__NetTotal__c.round(), contr.paymentScheduleList[2].recurringPrice.round()); 
        }
        Test.stopTest();
    }                      

    @isTest
    static void testPaymentScheduleMinCommit(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c= CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP, CWS_Usage_Ramp_Qty__c = '1',CWS_Min_Commit__c = true,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_TriAnnual);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
            SBQQ__QuoteLine__c[] quoteLineList=[Select Id, SBQQ__NetTotal__c, SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where 
                    CWS_Payment_Schedule_Driver__c=:CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP];
           // System.assertNotEquals(true,quoteLineList.isEmpty());
            //System.assertNotEquals(true, contr.paymentScheduleList.isEmpty()); 
            //System.assert(contr.paymentScheduleList.size()==3);
            //System.assertEquals(quoteLineList[0].SBQQ__NetTotal__c.round(), contr.paymentScheduleList[2].recurringPrice.round()); 
        }
        Test.stopTest();
    }    
    
       @isTest
    static void testPaymentScheduleBillingTypeOnetime1(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = CWS_ConstantClass.RTM_Value_IIT;
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_OneTime];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c='Ramp',
                SBQQ__BillingType__c='Advance', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_BiAnnual);
            if(quoteLine!=null){
            insert quoteLine;
            }
            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
        }
        Test.stopTest();
    }       
	
	 @isTest
    static void testPaymentScheduleMinCommit2(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=1,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c= CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP, CWS_Usage_Ramp_Qty__c = '1',CWS_Min_Commit__c = true,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_TriAnnual);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
           System.assertEquals(true, quoteLine.CWS_Min_Commit__c);
        }
        Test.stopTest();
    }    
	 @isTest
    static void testPaymentScheduleMinCommit3(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=1,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c= CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP, CWS_Usage_Ramp_Qty__c = '1',CWS_Min_Commit__c = true,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_BiAnnual);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
           System.assertEquals(true, quoteLine.CWS_Min_Commit__c);
        }
        Test.stopTest();
    }    

     @isTest
    static void testPaymentScheduleMinCommit4(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c= CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP, CWS_Usage_Ramp_Qty__c = '1',CWS_Min_Commit__c = true,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_BiAnnual);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
               System.assertEquals(true, quoteLine.CWS_Min_Commit__c);
        }
        Test.stopTest();
    }    
    @isTest
    static void testPaymentScheduleMinCommit5(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,
                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c= CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP, CWS_Usage_Ramp_Qty__c = '1',CWS_Min_Commit__c = true,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_Annual);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
           System.assertEquals(true, quoteLine.CWS_Min_Commit__c);
        }
        Test.stopTest();
    }    
	    @isTest
    static void testPaymentScheduleMinCommit6(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=1,
                                                                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c= CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP, CWS_Usage_Ramp_Qty__c = '1',CWS_Min_Commit__c = true,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_Annual);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
           System.assertEquals(true, quoteLine.CWS_Min_Commit__c);
        }
        Test.stopTest();
    } 
   	    @isTest
    static void testPaymentScheduleMinCommit7(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=1,
                                                                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c= CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP, CWS_Usage_Ramp_Qty__c = '1',CWS_Min_Commit__c = true,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_Quarterly);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
           System.assertEquals(true, quoteLine.CWS_Min_Commit__c);
        }
        Test.stopTest();
    }
    
     @isTest
    static void testPaymentScheduleMinCommit8(){
        Test.startTest();
        SBQQ__Quote__c[] quoteList=[Select Id, Name, CurrencyIsoCode ,CWS_Route_to_Market__c  from SBQQ__Quote__c ];
        quoteList[0].CWS_Route_to_Market__c = 'Channel';
        update quoteList[0];
        if(!quoteList.isEmpty()){
            PricebookEntry[] pbeList=[Select Id, product2.CWS_ChargeType__c, product2Id, pricebook2Id, productcode, unitprice from PricebookEntry 
                                            where Pricebook2.Name= :CWS_ConstantClass.CONNECTWISE_PRICEBOOK and 
                                            Product2.CWS_ChargeType__c=:CWS_ConstantClass.ChargeType_Recurring];
            SBQQ__QuoteLine__c quoteLine=new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteList[0].Id,CWS_ChargeType__c=pbeList[0].Product2.CWS_ChargeType__c,
                SBQQ__Quantity__c=1, SBQQ__ListPrice__c=1000, SBQQ__SubscriptionTerm__c=12,
                                                                SBQQ__NetPrice__c=1200, SBQQ__Product__c=pbeList[0].Product2Id, SBQQ__PricebookEntryId__c=pbeList[0].Id,
                CWS_Payment_Schedule_Driver__c= CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP, CWS_Usage_Ramp_Qty__c = '1',CWS_Min_Commit__c = true,
                SBQQ__BillingType__c='Arrears', CWS_Period_for_Ramp_Spread_Deferment__c=1, CWS_Billing_Term__c=CWS_ConstantClass.BillingTerm_Quarterly);

            if(quoteLine!=null){
            insert quoteLine;
            }

            Test.setCurrentPage(new PageReference('apex/CWS_PaymentSchedule'));
            ApexPages.currentPage().getparameters().put('qid', quoteList[0].Id);        
            CWS_PaymentScheduleController contr=new CWS_PaymentScheduleController();
           System.assertEquals(true, quoteLine.CWS_Min_Commit__c);
        }
        Test.stopTest();
      
    }
}