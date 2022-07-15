@isTest
public  class CWS_SplitContractTest {
     @TestSetup
     static void init(){
     	 CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'SBQQ__Quote__c','Account', 'Opportunity', 'Order','Contract'});
           Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
             'CWS_Is_Distributor__c'=>true,
             'Industry'=>'MSP',
             'CWS_Sub_Industry__c'=>'N/A',
              'CWS_Additional_Emails_for_Invoice__c'=>'test@add.com'
                };
        Account acc = CWS_UTLDataFactory.createAccount('accountName', soldtoaccountFieldValues, true);
        
           //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
             'CWS_Is_Partner__c'=>true,
             'CWS_Is_Distributor__c'=>true,
             'CWS_Need_Recurring__c'=>true,
             'Industry'=>'MSP',
             'CWS_Sub_Industry__c'=>'N/A'
              };
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,3,true);        
        
      
              
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(acc.Id,distiaccounts[0].Id, CWS_ConstantClass.DISTRIBUTOR_TYPE,'Deal Reg', null, null, true);
        
        //Create Opportunity
         Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD'
        }; 
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',acc.id, opportunityFields, true); 
        
    	 //Create Amendment Opportunity
         Map<String, Object> opportunityFields2=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
            'Type'=>'New Business','CurrencyIsoCode'=>'USD'
        }; 
        Opportunity opp2 = CWS_UTLDataFactory.createOpportunity('optyName2',acc.id, opportunityFields2, true);   
        
        //Create New Business Quote
        Map<String, Object> quoteFields=new Map<String,Object>{
             'SBQQ__Primary__c'=>true,
             'CWS_Quote_Type__c'=>'New Business',
             'CWS_Bill_to_Account__c'=> distiaccounts[0].Id,
             'CWS_Route_to_Market__c'=>'Direct',
             'CWS_Renewal_Category__c'=> CWS_ConstantClass.Renewal_Type_OptIn,
             'SBQQ__StartDate__c'=> Date.today(),
             'SBQQ__SubscriptionTerm__c'=>12
                 }; 
        SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acc.id, opp.id, quoteFields, true);  
         
          Map<String, Object> quoteFields2=new Map<String,Object>{
             'SBQQ__Primary__c'=>true,
             'CWS_Quote_Type__c'=>'New Business',
             'CWS_Bill_to_Account__c'=> distiaccounts[0].Id,
             'CWS_Route_to_Market__c'=>'Direct',
             'CWS_Renewal_Category__c'=> CWS_ConstantClass.Renewal_Type_OptIn,
             'SBQQ__StartDate__c'=> Date.today(),
             'SBQQ__SubscriptionTerm__c'=>12
                 }; 
        SBQQ__Quote__c quote2 = CWS_UTLDataFactory.createQuote(acc.id, opp2.id, quoteFields2, true);  
        
           //Create Contract
        Map<String, Object> contAdditionalFieldValues = new Map<String, Object>{
          'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL,
          'CWS_Quote_SubType__c' => 'Credit',
           'CWS_OF_Signed_Date__c'=>System.today(),
           'StartDate' => System.today()
          
            };
        Contract cont = CWS_UTLDataFactory.createContract(acc.id, contAdditionalFieldValues, true);
        //Create Products
        List<Product2> prodList = new List<Product2>();
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
              'CWS_Description__c'=>'Test',
              'CWS_Base_SKU__c'=>'900901'
              
        };
        Product2 product1=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,false);
        prodList.add(product1);
        Product2 product2=CWS_UTLDataFactory.createProduct('TestProduct2', 'SKU124',productFields,false);
        product2.CWS_Renewal_Type__c ='Opt-in';
        prodList.add(product2);
        Product2 product3=CWS_UTLDataFactory.createProduct('TestProduct3', 'SKU125',productFields,false);
        //product3.CWS_Renewal_Type__c = null;
       	prodList.add(product3); 
     	insert prodList;
     	PricebookEntry pbe1=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product1.Id,1000,'USD', true);
      	PricebookEntry pbe2=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product2.Id,1000,'USD', true);
      	PricebookEntry pbe3=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product3.Id,1000,'USD', true);
        
         
          Map<String, Object> quoteLineFields = new Map<String, Object>{
            'SBQQ__Quote__c'=>quote.id,
             'SBQQ__Quantity__c'=>1
            }; 
        //Insert QUote Lines for New Business
       List<SBQQ__QuoteLine__c> quoteLineInsert = new List<SBQQ__QuoteLine__c>();
       SBQQ.TriggerControl.disable();
        SBQQ__QuoteLine__c quoteLine11 = CWS_UTLDataFactory.createQuoteLine(quoteLineFields,false);
        quoteLine11.SBQQ__PricebookEntryId__c = pbe1.id;
       	quoteLine11.SBQQ__Product__c = product1.id; 
        quoteLine11.SBQQ__SubscriptionType__c ='Renewable'; 
        quoteLine11.SBQQ__ProductSubscriptionType__c ='Renewable'; 
        quoteLine11.CWS_Margin__c = 1;
        quoteLine11.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_REASON_NEW;
        quoteLineInsert.add(quoteLine11);
		
        SBQQ__QuoteLine__c quoteLine12 = CWS_UTLDataFactory.createQuoteLine(quoteLineFields,false);
        quoteLine12.SBQQ__PricebookEntryId__c = pbe2.id;
       	quoteLine12.SBQQ__Product__c = product2.id; 
        quoteLine12.SBQQ__SubscriptionType__c ='Renewable'; 
        quoteLine12.SBQQ__ProductSubscriptionType__c ='Renewable'; 
       	quoteLine12.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_REASON_NEW;
        quoteLine12.CWS_NetTotal__c=1000;
        quoteLine12.SBQQ__SubscriptionTerm__c=12; 
        quoteLineInsert.add(quoteLine12);
        //insert quoteLine12;
        SBQQ__QuoteLine__c quoteLine13 = CWS_UTLDataFactory.createQuoteLine(quoteLineFields,false);
        quoteLine13.SBQQ__PricebookEntryId__c = pbe3.id;
       	quoteLine13.SBQQ__Product__c = product3.id; 
        quoteLine13.SBQQ__SubscriptionType__c ='Renewable'; 
        quoteLine13.SBQQ__ProductSubscriptionType__c ='Renewable'; 
       	quoteLine13.SBQQ__Quantity__c =  0;
       	quoteLine13.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_CANCEL;
        quoteLineInsert.add(quoteLine13);
         
        SBQQ__QuoteLine__c quoteLine14 = CWS_UTLDataFactory.createQuoteLine(quoteLineFields,false);
        quoteLine14.SBQQ__Quote__c = quote2.id;
        quoteLine14.SBQQ__PricebookEntryId__c = pbe1.id;
       	quoteLine14.SBQQ__Product__c = product1.id; 
        quoteLine14.SBQQ__SubscriptionType__c ='Renewable'; 
        quoteLine14.SBQQ__ProductSubscriptionType__c ='Renewable'; 
       	quoteLine14.SBQQ__Quantity__c =  0;
        quoteLine14.CWS_NetTotal__c=1000;
        quoteLine14.SBQQ__SubscriptionTerm__c=12; 
       	quoteLine14.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_REASON_NEW;
        quoteLineInsert.add(quoteLine14);
        insert quoteLineInsert; 
         SBQQ.TriggerControl.enable();
     
                 
        //CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(acc.id,cont.id, quote.Id,  true);
     }
     
     @IsTest
     static void testMethod1(){
   
		Test.startTest();	       
     	Opportunity opp = [Select id from Opportunity where name = 'optyName'];
         
     	SBQQ__Quote__c quote = [Select id,SBQQ__Account__c, SBQQ__Ordered__c, SBQQ__PricebookId__c from SBQQ__Quote__c where SBQQ__Opportunity2__c =:opp.id];
     	Contract con = [Select id from Contract limit 1];
        CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(quote.SBQQ__Account__c,con.id, quote.Id,  true);
        List<id> conId = new List<Id>();
            con.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Category_SplitPending;
            update con;
        conId.add(con.id);
        CWS_SplitContract obj = new CWS_SplitContract(conId);
         CWS_SplitContract obj1 = new CWS_SplitContract();
            Database.executeBatch(obj,1);
     
     	Test.stopTest();
           	//System.assertEquals(True, con.size()>0); 
     }
    
     @IsTest
     static void testMethod2(){
   
		Test.startTest();	       
     	Opportunity opp = [Select id from Opportunity where name = 'optyName2'];
         
     	SBQQ__Quote__c quote = [Select id,SBQQ__Account__c, SBQQ__Ordered__c, SBQQ__PricebookId__c from SBQQ__Quote__c where SBQQ__Opportunity2__c =:opp.id];
     	Contract con = [Select id from Contract limit 1];
        CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(quote.SBQQ__Account__c,con.id, quote.Id,  true);
        List<id> conId = new List<Id>();
            con.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Category_SplitPending;
            update con;
        conId.add(con.id);
        CWS_SplitContract obj = new CWS_SplitContract(conId);
        CWS_SplitContract obj1 = new CWS_SplitContract(quote.SBQQ__Account__c);
            Database.executeBatch(obj1,1);
     
     	Test.stopTest();
           	//System.assertEquals(True, con.size()>0); 
     }

     @IsTest
     static void testMethod3(){
   
		Test.startTest();	       
     	//Opportunity opp = [Select id from Opportunity where name = 'optyName2'];
         //Product2 prod = [Select id from Product2 where name = 'TestProduct2'];
        PricebookEntry pbe = [Select id, Product2Id from PricebookEntry where Product2.name = 'TestProduct2'];
     	SBQQ__Quote__c quote = [Select id,SBQQ__Account__c, SBQQ__Ordered__c, SBQQ__PricebookId__c from SBQQ__Quote__c where SBQQ__Opportunity2__r.name ='optyName2'];
        SBQQ__QuoteLine__c quoteLine = [Select id,SBQQ__Product__c, SBQQ__PricebookEntryId__c  from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quote.id]; 
        quoteLine.SBQQ__Product__c = pbe.Product2Id; 
        quoteLine.SBQQ__PricebookEntryId__c = pbe.id;
       	quoteLine.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_CANCEL;
        update quoteLine;
     	Contract con = [Select id, CWS_Renewable_Products__c from Contract limit 1];
         con.CWS_Renewable_Products__c = 1;
         update con;
        CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(quote.SBQQ__Account__c,con.id, quote.Id,  true);
        List<id> conId = new List<Id>();
            con.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Category_SplitPending;
            update con;
        conId.add(con.id);
        CWS_SplitContract obj = new CWS_SplitContract(conId);
        CWS_SplitContract obj1 = new CWS_SplitContract(quote.SBQQ__Account__c);
            Database.executeBatch(obj1,1);
     
     	Test.stopTest();
           	//System.assertEquals(True, con.size()>0); 
     }
    @IsTest
     static void testMethod4(){
   
		Test.startTest();	       
     	//Opportunity opp = [Select id from Opportunity where name = 'optyName2'];
         //Product2 prod = [Select id from Product2 where name = 'TestProduct2'];
        PricebookEntry pbe = [Select id, Product2Id from PricebookEntry where Product2.name = 'TestProduct1'];
     	SBQQ__Quote__c quote = [Select id,SBQQ__Account__c, SBQQ__Ordered__c, SBQQ__PricebookId__c from SBQQ__Quote__c where SBQQ__Opportunity2__r.name ='optyName2'];
        SBQQ__QuoteLine__c quoteLine = [Select id,SBQQ__Product__c, SBQQ__PricebookEntryId__c  from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quote.id]; 
        quoteLine.SBQQ__Product__c = pbe.Product2Id; 
        quoteLine.SBQQ__PricebookEntryId__c = pbe.id;
       	quoteLine.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_CANCEL;
        SBQQ__QuoteLine__c quoteLine1 = quoteLine.clone();
        quoteLine1.SBQQ__Quote__c = quote.id;
        quoteLine1.SBQQ__PricebookEntryId__c = pbe.id;
       	quoteLine1.SBQQ__Product__c = pbe.Product2Id; 
        quoteLine1.SBQQ__SubscriptionType__c ='Renewable'; 
        quoteLine1.SBQQ__ProductSubscriptionType__c ='Renewable'; 
       	quoteLine1.SBQQ__Quantity__c =  0;
        quoteLine1.CWS_NetTotal__c=1000;
        quoteLine1.SBQQ__SubscriptionTerm__c=12; 
       	quoteLine1.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_CANCEL;
		SBQQ.TriggerControl.disable();
        //insert quoteLine1;
        
        update quoteLine;
        SBQQ.TriggerControl.enable();
     	Contract con = [Select id, CWS_Renewable_Products__c from Contract limit 1];
         con.CWS_Renewable_Products__c = 1;
         update con;
        CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(quote.SBQQ__Account__c,con.id, quote.Id,  true);
        List<id> conId = new List<Id>();
            con.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Category_SplitPending;
            update con;
        conId.add(con.id);
        CWS_SplitContract obj = new CWS_SplitContract(conId);
        CWS_SplitContract obj1 = new CWS_SplitContract(quote.SBQQ__Account__c);
            Database.executeBatch(obj1,1);
     
     	Test.stopTest();
           	//System.assertEquals(True, con.size()>0); 
     }
      @IsTest
     static void testMethod5(){
   
		Test.startTest();	       
     	//Opportunity opp = [Select id from Opportunity where name = 'optyName2'];
         //Product2 prod = [Select id from Product2 where name = 'TestProduct2'];
        PricebookEntry pbe = [Select id, Product2Id from PricebookEntry where Product2.name = 'TestProduct2'];
     	SBQQ__Quote__c quote = [Select id,SBQQ__Account__c, SBQQ__Ordered__c, SBQQ__PricebookId__c from SBQQ__Quote__c where SBQQ__Opportunity2__r.name ='optyName2'];
        SBQQ__QuoteLine__c quoteLine = [Select id,SBQQ__Product__c, SBQQ__PricebookEntryId__c  from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quote.id]; 
        quoteLine.SBQQ__Product__c = pbe.Product2Id; 
        quoteLine.SBQQ__PricebookEntryId__c = pbe.id;
        quoteLine.CWS_Margin__c = 1;
       	quoteLine.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_REASON_NEW;
        SBQQ__QuoteLine__c quoteLine1 = quoteLine.clone();
        quoteLine1.SBQQ__Quote__c = quote.id;
        quoteLine1.SBQQ__PricebookEntryId__c = pbe.id;
       	quoteLine1.SBQQ__Product__c = pbe.Product2Id; 
        quoteLine1.SBQQ__SubscriptionType__c ='Renewable'; 
        quoteLine1.SBQQ__ProductSubscriptionType__c ='Renewable'; 
       	quoteLine1.SBQQ__Quantity__c =  1;
        quoteLine1.CWS_NetTotal__c=1000;
        quoteLine1.SBQQ__SubscriptionTerm__c=12; 
       	quoteLine1.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_REASON_NEW;
		SBQQ.TriggerControl.disable();
        //insert quoteLine1;
        
        update quoteLine;
        SBQQ.TriggerControl.enable();
     	Contract con = [Select id, CWS_Renewable_Products__c from Contract limit 1];
         con.CWS_Renewable_Products__c = 1;
            con.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Category_SplitPending;
         update con;
        CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(quote.SBQQ__Account__c,con.id, quote.Id,  true);
        List<id> conId = new List<Id>();
        conId.add(con.id);
        CWS_SplitContract obj = new CWS_SplitContract(conId);
        CWS_SplitContract obj1 = new CWS_SplitContract(quote.SBQQ__Account__c);
            Database.executeBatch(obj1,1);
     	CWS_SplitContractSchedule sch = new CWS_SplitContractSchedule();
         String sch1 = '0 0 2 * * ?'; 
         system.schedule('Test', sch1, sch); 
     	Test.stopTest();
           	//System.assertEquals(True, con.size()>0); 
     }
    
}