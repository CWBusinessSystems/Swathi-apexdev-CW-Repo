/* Component Name   : CWS_BatchGenerateQuoteDocument_Test 
 * Description      : Test Class For CWS_BatchGenerateQuoteDocument
 * Created By       : Manoj
 * Created On       : 14-08-2020  
 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                            Modification ID              Description 
 * ----------------------------------------------------------------------------------------------------------------------------------------
 * Manoj                 14-08-2020     
 * Indra Ganesan         23-08-2020
 */
@istest(Seealldata = false)
public class CWS_BatchGenerateQuoteDocument_Test {
 // Test data setup 
    @testSetup
    static void init(){
       //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','Quote'});           
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'USD','CWS_Distributor_Logic_Exclusion__c'=>false, 'CWS_Additional_Emails_for_Invoice__c'=>'testUsr@cw.com,tst@cw.com'};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccountConWise', soldtoaccountFieldValues,true);
        Account accChannel = CWS_UTLDataFactory.createAccount('ConnectWise Channel Test Account', new Map<String, Object>{'CWS_Is_Distributor__c'=> true,'CWS_Additional_Emails_for_Invoice__c'=>'testUsr@cw.com,tst@cw.com','Industry'=>'MSP','CWS_Distributor_Logic_Exclusion__c'=>true}, true);
        
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
            'Type'=>'New','CurrencyIsoCode'=>'USD','accountID'=>soldtoaccount.id,'CWS_Bill_To_Contact__c'=>contact.id, 'CWS_Master__c'=>true
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
            'Type'=>'Renewal','CurrencyIsoCode'=>'USD','accountID'=>soldtoaccount.id,'CWS_Bill_To_Contact__c'=>contact.id,'CWS_Master__c'=>true
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
                'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2025,7,7),'CWS_Master__c'=>true,'SBQQ__PrimaryContact__c'=>contact.id
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
           'SBQQ__PrimaryContact__c'=>contact.id,'SBQQ__Account__c'=>soldtoaccount.Id ,'SBQQ__opportunity2__c'=> lstOpportunities[4].Id, 'CWS_Bill_To_Account__c'=>soldtoaccount.Id,'CWS_Bill_To_Contact__c'=>contact.id,'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_RENEWAL,  
                'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Direct,'CWS_Master__c'=>true,'CWS_Renewal_Category__c'=> CWS_ConstantClass.Renewal_Type_OptOut
                
        };
		 List<Product2> productList=new List<Product2>();
        Map<String,Object> additionalFields1 = new Map<String, Object>{'CWS_ChargeType__c'=>CWS_ConstantClass.ChargeType_Recurring, 'isActive'=>true, 'CWS_Category__c'=> 'Automate', 'CWS_Description__c'=>'This is a Demo Product Created For Marketing Purposes.Not For Sale'};
        
        
        Product2 prod1 = CWS_UTLDataFactory.createProduct('TestProductRecurring', 'RecurringProduct', additionalFields1, false);
        
        Map<String,Object> additionalFields2 = new Map<String, Object>{'CWS_ChargeType__c'=>CWS_ConstantClass.ChargeType_OneTime, 'isActive'=>true, 'CWS_Category__c'=> 'Automate'};
        Product2 prod2 = CWS_UTLDataFactory.createProduct('TestProductOneTime', 'OneTimeProduct', additionalFields2, false);
        
        
        productList.add(prod1);
        productList.add(prod2);
		
		// New Product
		
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
        productList.add(product2);
        insert productList;	
		
		
		
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
         
    @istest static void renewalQuotes(){   
        List<SBQQ__Quote__c> lstQuotes = [SELECT ID,SBQQ__Primary__c,CWS_Master__c from SBQQ__Quote__c where CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Direct LIMIT 1];
        lstQuotes[0].CWS_Master__c  = false;
        update lstQuotes;
        set<Id> qID = new set<Id>();
        for(SBQQ__Quote__c q:lstQuotes){
           qID.add(q.id);        
        }
        Id jobid;
        if(!lstQuotes .isEmpty()){
            test.startTest();
            CWS_BatchGenerateQuoteDocument bgqd = new CWS_BatchGenerateQuoteDocument(qID);             
            jobid = database.executeBatch(bgqd);
            test.stopTest();                       
        }
        system.assertEquals(true, jobid !=null);  
    } 
    
    @istest static void renewalCatOptOut(){   
        List<SBQQ__Quote__c> lstQuotes = [SELECT ID,SBQQ__Primary__c,CWS_Master__c,CWS_Renewal_Category__c from SBQQ__Quote__c where CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Direct AND CWS_Master__c=: true  LIMIT 1];
        lstQuotes[0].CWS_Renewal_Category__c=CWS_ConstantClass.Renewal_Type_OptOut;
        update lstQuotes[0];
        
        set<Id> qID = new set<Id>();
        for(SBQQ__Quote__c q:lstQuotes){
           qID.add(q.id);        
        }
        system.debug('++Master' +lstQuotes[0].CWS_Master__c);
        update lstQuotes;
        Id jobid;
        if(!lstQuotes .isEmpty()){
            test.startTest();
            CWS_BatchGenerateQuoteDocument bgqd = new CWS_BatchGenerateQuoteDocument(qID);             
            jobid = database.executeBatch(bgqd);
            test.stopTest();                       
        }
        system.assertEquals(true, jobid !=null);  
    } 
    
     @istest static void renewalCatOptOut2(){   
       List<Account> lstAccs = [select id, CWS_Additional_Emails_for_Invoice__c from Account where Name IN ('TestAccountConWise','ConnectWise Channel Test Account')];
        lstAccs[0].CWS_Additional_Emails_for_Invoice__c = 'test.acc@cq.com';
        lstAccs[1].CWS_Additional_Emails_for_Invoice__c = 'test.acc@cq.com';
        update lstAccs;
        List<SBQQ__Quote__c> lstQuotes = [SELECT ID,SBQQ__Primary__c,CWS_Master__c,CWS_Renewal_Category__c from SBQQ__Quote__c where CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Direct AND CWS_Master__c=: true LIMIT 1];
        lstQuotes[0].CWS_Renewal_Category__c=CWS_ConstantClass.Renewal_Type_OptOut;
        update lstQuotes[0];
        
        set<Id> qID = new set<Id>();
        for(SBQQ__Quote__c q:lstQuotes){
           qID.add(q.id);        
        }
        system.debug('++Master' +lstQuotes[0].CWS_Master__c);
        update lstQuotes;
        Id jobid;
        if(!lstQuotes .isEmpty()){
            test.startTest();
            CWS_BatchGenerateQuoteDocument bgqd = new CWS_BatchGenerateQuoteDocument(qID);             
            jobid = database.executeBatch(bgqd);
            test.stopTest();                       
        }
        system.assertEquals(true, jobid !=null);  
    } 
    
      @isTest
    static void testRTMChannel(){
        
        List<SBQQ__Quote__c> lstQuotes = [SELECT ID,SBQQ__Primary__c,CWS_Master__c,CWS_Renewal_Category__c from SBQQ__Quote__c where CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Channel AND CWS_Master__c=: false];
       // lstQuotes.add(quote);
        set<Id> qID = new set<Id>();
        for(SBQQ__Quote__c q:lstQuotes){
           qID.add(q.id);        
        }        
        Id jobid;
        if(lstQuotes != null){
            test.startTest();
            CWS_BatchGenerateQuoteDocument bgqd = new CWS_BatchGenerateQuoteDocument(qID);             
            jobid = database.executeBatch(bgqd);
            test.stopTest();                       
        }
        system.assertEquals(true, jobid !=null);  
    }
    
    
      @isTest
    static void testRTMDirect(){
        
        List<SBQQ__Quote__c> lstQuotes = [SELECT ID,CWS_Quote_Type__c,SBQQ__PrimaryContact__c,CWS_Bill_To_Account__c,SBQQ__Primary__c,CWS_Master__c,CWS_Renewal_Category__c,SBQQ__opportunity2__c from SBQQ__Quote__c where CWS_Route_to_Market__c =: CWS_ConstantClass.RTM_Value_Direct AND CWS_Quote_Type__c=:CWS_ConstantClass.QUOTE_TYPE_Renewal AND CWS_Master__c=: true LIMIT 1];
        system.debug('Master in test data = '+  lstQuotes[0].CWS_Master__c);
        system.debug('Quote type in test data ='+lstQuotes[0].CWS_Quote_Type__c);
        system.debug('Primary Quote in test data ='+lstQuotes[0].SBQQ__PrimaryContact__c);

        //update lstQuotes; 
        Account accs = [select id from Account where Name=: 'TestAccountConWise'];
       // lstQuotes.add(quote);
        Opportunity opp = [select id,SBQQ__RenewedContract__c from Opportunity where Name=: 'OpptRWCDirect'];
        set<Id> qID = new set<Id>();
        for(SBQQ__Quote__c q:lstQuotes){
           qID.add(q.id);        
        }        
        Id jobid;
        Contract con = new Contract(Account = accs, ContractTerm=12, Status='Draft',AccountId = accs.id);
        insert con;
        if(con!=null){
            con.Status = 'Activated';
            con.CWS_Renewal_Category__c = 'Opt-Out';
            con.CWS_Renewable_Products__c  = 1;
            con.CWS_Master__c = true;
            update con;
        }
        system.debug('$$Contract Id  ='+con.id);
        opp.SBQQ__RenewedContract__c = con.id;
        update opp;
        system.debug('$$Contract Master ='+ con.CWS_Master__c);
        system.debug('$$Opp Query '+[select id,SBQQ__RenewedContract__r.CWS_Master__c from Opportunity where id=:opp.id]);
        if(lstQuotes != null){
            test.startTest();
            CWS_BatchGenerateQuoteDocument bgq = new CWS_BatchGenerateQuoteDocument();      
            CWS_BatchGenerateQuoteDocument bgqd = new CWS_BatchGenerateQuoteDocument(qID);             
            jobid = database.executeBatch(bgqd);
            test.stopTest();                       
        }
        system.assertEquals(true, jobid !=null);  
    }
}