/*Class Name: CWS_SubsTriggerHelperTest
*Description: Test Class for CWS_SubsTriggerHelper
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Mahak Bansal       11 Feb 2022         OBD-3379              Test coverage updated, 
*/
@isTest(SeeAllData=false)
public class CWS_SubsTriggerHelperTest{
    @testSetup
    static void createTestData(){
        
        System.debug('---SOQL Queries fired 01 -'+Limits.getQueries());
       //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','SBQQ__Quote__c'});           
        //Create Sold To Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR'};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        System.debug('SOQL Queries fired 02 -'+Limits.getQueries());
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
            'CWS_Is_Partner__c'=>true,
            'CWS_Is_Distributor__c'=>true};
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
              
        System.debug('SOQL Queries fired 03 -'+Limits.getQueries());
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', 'Automate;Sell', null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', 'Perch', null, true);
        Pricebook2 connectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
        insert connectwisePricebook;
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'EUR', 'Pricebook2Id'=>ConnectwisePricebook.Id
        };
            
        System.debug('SOQL Queries fired 04 -'+Limits.getQueries());
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);
        //opty.CurrencyIsoCode='EUR';
        //insert opty;
        
        Map<String, Object> quoteFields2=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 'CWS_Quote_Type__c'=>'New Business', 'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Channel',
            'SBQQ__Distributor__c'=>distiAccounts[0].Id, 'SBQQ__Pricebook__c'=>connectwisePricebook.Id, 'SBQQ__StartDate__c'=> Date.today(),
            'SBQQ__SubscriptionTerm__c'=>12, 'CurrencyIsoCode'=>'EUR', 'CWS_Bill_to_Account__c'=> distiaccounts[0].Id
                
        };
        
        Map<String, Object> productFields=new Map<String, Object>{
            'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12  ,
            'SBQQ__SubscriptionType__c' =>'Renewable', 'SBQQ__SubscriptionBase__c'=>'List', 'SBQQ__ChargeType__c'=>CWS_ConstantClass.ChargeType_Recurring,
            'SBQQ__BillingType__c'=>'Advance'
        };

        Product2 productA=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123', productFields, true);
        product2 productB=CWS_UTLDataFactory.createProduct('TestProduct2', 'SKU456', productFields, true);
        PricebookEntry stdpbeA=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),productA.Id,1000.00,'EUR', true);
        PricebookEntry stdpbeB=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),productB.Id,1000.00,'EUR', true);        
        PricebookEntry pbeA=CWS_UTLDataFactory.createPBEwithPricebookId(connectwisePricebook.Id,productA.Id,1000.00,'EUR', true);
        PricebookEntry pbeB=CWS_UTLDataFactory.createPBEwithPricebookId(connectwisePricebook.Id,productB.Id,1000.00,'EUR', true);        
        SBQQ__Quote__c quote2=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields2, true); 
        //quote2.SBQQ__PricebookId__c=ConnectwisePricebook.Id;
        //quote2.CurrencyIsoCode='EUR';
        //insert quote2;
        
        System.debug('SOQL Queries fired 05 -'+Limits.getQueries());
        Map<String, Object> mapQuoteLineFields=new Map<String, Object>{'SBQQ__Quote__c'=>quote2.Id, 'SBQQ__Product__c'=> productA.Id, 
                'SBQQ__PricebookEntryId__c'=> pbeA.Id,'SBQQ__Quantity__c'=>1,'SBQQ__ListPrice__c'=>1000.00, 'SBQQ__CustomerPrice__c'=>1000.00,
                'SBQQ__RegularPrice__c'=>1000, 'SBQQ__SpecialPrice__c'=>1000, 'SBQQ__NetPrice__c'=>1000,
                'SBQQ__SubscriptionTerm__c' =>12,'SBQQ__StartDate__c'=>(Date)Date.today(), 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 
                'SBQQ__ChargeType__c'=>CWS_ConstantClass.ChargeType_Recurring, 'SBQQ__BillingType__c'=>'Advance', 'CWS_Transaction_Type__c'=>'New', 
                'SBQQ__PricebookEntryId__c' => pbeA.Id, 'CWS_Category__c'=>'Automate',  'CWS_Margin__c'=>1,
            	'SBQQ__AdditionalDiscountAmount__c'=>20, 'CWS_Distributor_Net_Price__c'=>500};
        SBQQ__QuoteLine__c quoteLineItemA = CWS_UTLDataFactory.createQuoteLine(mapQuoteLineFields,true);
        mapQuoteLineFields.put('SBQQ__Product__c', productB.Id);
        mapQuoteLineFields.put('SBQQ__PricebookEntryId__c',pbeB.Id);
        mapQuoteLineFields.put('SBQQ__Discount__c',1);
        mapQuoteLineFields.put('SBQQ__AdditionalDiscountAmount__c',null);
        mapQuoteLineFields.put('CWS_Reseller_Net_Price__c',500);
        SBQQ__QuoteLine__c quoteLineItemB = CWS_UTLDataFactory.createQuoteLine(mapQuoteLineFields,true);
		
	    System.debug('SOQL Queries fired 06 -'+Limits.getQueries());	
}
 
    //BED-1251
    @isTest
    static void testSubsCreation(){
            Test.startTest();//Added by Mahak
        	System.debug('SOQL Queries fired 1 -'+Limits.getQueries());
        	String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;
            Map<String, Object> userFields = new Map<String, Object>{
              'CWS_Renewal_Batch_User__c' => true
            };
                
        	System.debug('SOQL Queries fired 2 -'+Limits.getQueries());
            User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                    'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        
            System.debug('SOQL Queries fired 3 -'+Limits.getQueries());   
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CWS_Integration_User_permission'];
        
        	System.debug('SOQL Queries fired 4 -'+Limits.getQueries());
            
			insert new PermissionSetAssignment(AssigneeId = admin.id, PermissionSetId = ps.Id);
       	 	System.runas(admin){
            List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)Database.query('Select Id, Name,SBQQ__Ordered__c,SBQQ__PricebookId__c,SBQQ__PriceBook__c,CWS_Quote_ACV__c from SBQQ__Quote__c');
            quoteList[0].SBQQ__Ordered__c=true;
          //   Test.startTest();   
            update quoteList;
            
            List<Pricebook2> pricebookList=[Select Id, Name from Pricebook2 where name=:CWS_ConstantClass.CONNECTWISE_PRICEBOOK Limit 1];
            List<order> orderList=(List<order>)Database.query('Select Id,SBQQ__Contracted__c from order ');
            System.debug(orderList);
            if(pricebookList!=null && !pricebookList.isEMpty()){
            orderList[0].Pricebook2Id=pricebookList[0].Id;
            }
        	
            orderList[0].Status='Activated';
            update  orderList;

            list<OrderItem> lstOLI =(List<OrderItem>)Database.query('select id,SBQQ__Activated__c from OrderItem');
            System.debug(lstOLI);
            lstOLI[0].SBQQ__Activated__c = true;
            update lstOLI;

           
            orderList[0].SBQQ__Contracted__c=true;
            update orderList;
            Test.StopTest();
			system.assertEquals(False,orderList.isEmpty());
         }
        
    }
    
     // BED-5671
    //Method Name: CWS_SubsTriggerHelper.beforeInsertHelper
    @isTest
    static void testBeforeInsertHelper(){
        Test.startTest();
        System.debug('SOQL Queries fired 1 -'+Limits.getQueries());
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
        'CWS_Renewal_Batch_User__c' => true
        };
        //Added by Mahak To avoid recursion of the Trigger
        CWS_SubscriptionHandler.AFTER_INSERT_EXECUTED = TRUE;
        CWS_SubscriptionHandler.AFTER_UPDATE_EXECUTED = TRUE;
        CWS_SubscriptionHandler.BEFORE_UPDATE_EXECUTED = TRUE;
        
        System.debug('SOQL Queries fired 2 -'+Limits.getQueries());
        User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                    'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CWS_Integration_User_permission'];
        insert new PermissionSetAssignment(AssigneeId = admin.id, PermissionSetId = ps.Id);
        
        System.debug('SOQL Queries fired 3 -'+Limits.getQueries());
        System.runas(admin){
            List<SBQQ__Quote__c> quoteList=[Select Id, Name,SBQQ__Ordered__c, SBQQ__Account__c from SBQQ__Quote__c];
            if(!quoteList.isEmpty() && quoteList[0].SBQQ__Account__c!=null){
                Account account=new Account(Id=quoteList[0].SBQQ__Account__c, CWS_Region__c='NA');
                update account;
                System.debug('SOQL Queries fired 4 -'+Limits.getQueries());
                quoteList[0].SBQQ__Ordered__c=true;
                update quoteList[0];
                List<Pricebook2> pricebookList=[Select Id, Name from Pricebook2 where name=:CWS_ConstantClass.CONNECTWISE_PRICEBOOK Limit 1];            
                List<Order> orderList=[Select Id, Name,  SBQQ__Contracted__c, Pricebook2Id, Status from Order];
                if(pricebookList!=null && !pricebookList.isEMpty()){
                    orderList[0].Pricebook2Id=pricebookList[0].Id;
                }
                
                System.debug('SOQL Queries fired 5 -'+Limits.getQueries());
                orderList[0].status='Activated';
                update orderList[0];
                
                List<OrderItem> orderItemList=[Select Id, SBQQ__Activated__c from OrderItem];
                orderItemList[0].SBQQ__Activated__c=true;
                update orderItemList;
            
                System.debug('SOQL Queries fired 6 -'+Limits.getQueries());
                orderList[0].SBQQ__Contracted__c=true;
                update orderList[0];
                Test.stopTest();
                List<SBQQ__Subscription__c> subs=[Select Id, SBQQ__TerminatedDate__c, CWS_Region__c from SBQQ__Subscription__c];
                List<SBQQ__Subscription__c> subsList = new List<SBQQ__Subscription__c>();
            // System.assertEquals('NA',subs[0].CWS_Region__c);
                system.assertEquals(False,subs.isEmpty());
                System.debug('SOQL Queries fired 7 -'+Limits.getQueries());
                //System.assertEquals('NA',subs[0].CWS_Region__c);
                for(SBQQ__Subscription__c subscription : subs){
                    subscription.SBQQ__TerminatedDate__c =  System.today();
                    subsList.add(subscription);
                }
                update subsList;
                System.debug('SOQL Queries fired 8 -'+Limits.getQueries());
                CWS_SubscriptionHandler hand = new CWS_SubscriptionHandler();
                hand.AfterDelete(new Map<Id, SObject>());
                hand.AfterUndelete(new Map<Id, SObject>());
                //delete sub test
                if(!subs.isEmpty()){
                    delete subs;
                }            
            }
        }	
    }
    
    	@isTest
    	static void testAmendCancel(){
            Test.startTest();//Added by Mahak -OBD-3379
          	String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;
            Map<String, Object> userFields = new Map<String, Object>{
              'CWS_Renewal_Batch_User__c' => true
            };
              User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                    'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CWS_Integration_User_permission'];
            
			insert new PermissionSetAssignment(AssigneeId = admin.id, PermissionSetId = ps.Id);
       	 	System.runas(admin){
            List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)Database.query('Select Id, Name,SBQQ__Ordered__c,SBQQ__PricebookId__c,SBQQ__PriceBook__c,CWS_Quote_ACV__c from SBQQ__Quote__c');
            //SBQQ__CustomerDiscount__c =null;
            quoteList[0].SBQQ__Ordered__c=true;
            
            List<SBQQ__QuoteLine__c> quoteLines=[Select id, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__Product__c
                             from SBQQ__QuoteLine__c where SBQQ__Quote__c=:quoteList[0].Id];
            for(SBQQ__QuoteLine__c quoteLine: quoteLines){
                //quoteLine.SBQQ__Quantity__c=0;
                //quoteLine.SBQQ__PricebookEntryId__c=mapPricebookEntryId.get(quoteLine.SBQQ__Product__c);
                quoteLine.CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_CANCEL;
            }
            update quoteLines;
            update quoteList;
            
            List<Pricebook2> pricebookList=[Select Id, Name from Pricebook2 where name=:CWS_ConstantClass.CONNECTWISE_PRICEBOOK Limit 1];
            List<order> orderList=(List<order>)Database.query('Select Id,SBQQ__Contracted__c from order ');
            System.debug(orderList);
            if(pricebookList!=null && !pricebookList.isEMpty()){
            orderList[0].Pricebook2Id=pricebookList[0].Id;
            }
        	
            orderList[0].Status='Activated';
            update  orderList;

            list<OrderItem> lstOLI =(List<OrderItem>)Database.query('select id,SBQQ__Activated__c from OrderItem');
            System.debug(lstOLI);
            lstOLI[0].SBQQ__Activated__c = true;
            update lstOLI;
			orderList[0].SBQQ__Contracted__c=true;
            update orderList;
              system.assertEquals(False,orderList.isEmpty());   
            Test.StopTest();
            

         }
        
    }
    
    /*
     *  @isTest 
    static void testAmendmentFullCancellation(){
        List<Pricebook2> pricebookList=[Select Id, Name from Pricebook2 where name=:CWS_ConstantClass.CONNECTWISE_PRICEBOOK Limit 1]; 
        Map<Id, Id> mapPricebookEntryId=new Map<Id, Id>();
        for(PricebookEntry pricebookEntry:[Select Id,  CurrencyIsoCode, product2Id from PricebookEntry where Pricebook2.Name=:CWS_ConstantClass.CONNECTWISE_PRICEBOOK
                                 and currencyIsoCode='EUR']){
            mapPricebookEntryId.put(pricebookEntry.Product2Id, pricebookEntry.Id);
        }
        List<SBQQ__Quote__c> quoteList=[Select Id, Name, SBQQ__Account__c, SBQQ__StartDate__c, SBQQ__SubscriptionTerm__c, 
                    SBQQ__EndDate__c, SBQQ__PrimaryContact__c, CurrencyIsoCode, SBQQ__Pricebook__c,CWS_Bill_to_Account__c,
                    SBQQ__Opportunity2__c, CWS_Legal_Entity__c, CWS_Route_to_Market__c, 
                    CWS_Renewal_Type__c
                    from SBQQ__Quote__c limit 1];
        if(quoteList!=null && !quoteList.isEmpty()){
            Map<String, Object> mapContractFields =new Map<String, Object>{'SBQQ__Quote__c'=> quoteList[0].Id,
                'SBQQ__Opportunity__c'=> quoteList[0].SBQQ__Opportunity2__c, 'AccountId'=>quoteList[0].SBQQ__Account__c,
                'CWS_Bill_to_Account__c'=> quoteList[0].CWS_Bill_to_Account__c, 'CWS_Sold_to_Contact__c'=> quoteList[0].SBQQ__PrimaryContact__c,
                'CWS_Legal_Entity__c'=>quoteList[0].CWS_Legal_Entity__c, 'CWS_Route_to_Market__c'=> quoteList[0].CWS_Route_to_Market__c,
                'CWS_Renewal_Type__c'=> quoteList[0].CWS_Renewal_Type__c, 'Pricebook2Id'=> quoteList[0].SBQQ__Pricebook__c,
                'StartDate'=>quoteList[0].SBQQ__StartDate__c, 'ContractTerm'=>(Integer)quoteList[0].SBQQ__SubscriptionTerm__c,
                'CurrencyIsoCode'=>'EUR'};
            Contract contract=CWS_UTLDataFactory.createSalesContract(mapContractFields , true);
            List<SBQQ__Subscription__c> subsList=CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(quoteList[0].SBQQ__Account__c, contract.Id, quoteList[0].Id, true);

            String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contract.Id, null);
            //QuoteModel quotemodel= (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
            SBQQ__Quote__c[] amendmentQuotes=[Select Id, SBQQ__Ordered__c from SBQQ__Quote__c where SBQQ__Type__c='Amendment'];
            //:CWS_ConstantClass.Quote_Type_Amendment];
            System.assertNotEquals(true,amendmentQuotes.isEMpty());
            List<SBQQ__QuoteLine__c> quoteLines=[Select id, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__Product__c
                             from SBQQ__QuoteLine__c where SBQQ__Quote__c=:amendmentQuotes[0].Id];
            for(SBQQ__QuoteLine__c quoteLine: quoteLines){
                quoteLine.SBQQ__Quantity__c=0;
                quoteLine.SBQQ__PricebookEntryId__c=mapPricebookEntryId.get(quoteLine.SBQQ__Product__c);
            }
            update quoteLines;
            Test.startTest();
            amendmentQuotes[0].SBQQ__Pricebook__c=pricebookList[0].Id;
            amendmentQuotes[0].SBQQ__Ordered__c=true;
            update amendmentQuotes[0];
            
           
            List<Order> orderList=[Select Id, Name,  SBQQ__Contracted__c, Pricebook2Id, Status from Order];
            if(pricebookList!=null && !pricebookList.isEMpty()){
            orderList[0].Pricebook2Id=pricebookList[0].Id;
            }
            orderList[0].status='Activated';
            update orderList[0];
            
            List<OrderItem> orderItemList=[Select Id, SBQQ__Activated__c from OrderItem];
            orderItemList[0].SBQQ__Activated__c=true;
            update orderItemList;
            Test.stopTest();
            
            Contract[] updatedContract=[Select Id, Name, CWS_Cancelled__c from Contract where Id = :contract.Id Limit 1];
            System.assertNotEquals(true, updatedContract.isEmpty());
            system.assertEquals(true,updatedContract[0].CWS_Cancelled__c);
        }
    }
    
    
    @isTest 
    static void testAmendmentPartialCancellation(){
        List<Pricebook2> pricebookList=[Select Id, Name from Pricebook2 where name=:CWS_ConstantClass.CONNECTWISE_PRICEBOOK Limit 1]; 
        Map<Id, Id> mapPricebookEntryId=new Map<Id, Id>();
        for(PricebookEntry pricebookEntry:[Select Id,  CurrencyIsoCode, product2Id from PricebookEntry where Pricebook2.Name=:CWS_ConstantClass.CONNECTWISE_PRICEBOOK
                                 and currencyIsoCode='EUR']){
            mapPricebookEntryId.put(pricebookEntry.Product2Id, pricebookEntry.Id);
        }
        List<SBQQ__Quote__c> quoteList=[Select Id, Name, SBQQ__Account__c, SBQQ__StartDate__c, SBQQ__SubscriptionTerm__c, 
                    SBQQ__EndDate__c, SBQQ__PrimaryContact__c, CurrencyIsoCode, SBQQ__Pricebook__c,CWS_Bill_to_Account__c,
                    SBQQ__Opportunity2__c, CWS_Legal_Entity__c, CWS_Route_to_Market__c, 
                    CWS_Renewal_Type__c
                    from SBQQ__Quote__c limit 1];
        if(quoteList!=null && !quoteList.isEmpty()){
            Map<String, Object> mapContractFields =new Map<String, Object>{'SBQQ__Quote__c'=> quoteList[0].Id,
                'SBQQ__Opportunity__c'=> quoteList[0].SBQQ__Opportunity2__c, 'AccountId'=>quoteList[0].SBQQ__Account__c,
                'CWS_Bill_to_Account__c'=> quoteList[0].CWS_Bill_to_Account__c, 'CWS_Sold_to_Contact__c'=> quoteList[0].SBQQ__PrimaryContact__c,
                'CWS_Legal_Entity__c'=>quoteList[0].CWS_Legal_Entity__c, 'CWS_Route_to_Market__c'=> quoteList[0].CWS_Route_to_Market__c,
                'CWS_Renewal_Type__c'=> quoteList[0].CWS_Renewal_Type__c, 'Pricebook2Id'=> quoteList[0].SBQQ__Pricebook__c,
                'StartDate'=>quoteList[0].SBQQ__StartDate__c, 'ContractTerm'=>(Integer)quoteList[0].SBQQ__SubscriptionTerm__c,
                'CurrencyIsoCode'=>'EUR'};
            Contract contract=CWS_UTLDataFactory.createSalesContract(mapContractFields , true);
            List<SBQQ__Subscription__c> subsList=CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(quoteList[0].SBQQ__Account__c, contract.Id, quoteList[0].Id, true);

            String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contract.Id, null);
            //QuoteModel quotemodel= (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
            SBQQ__Quote__c[] amendmentQuotes=[Select Id, SBQQ__Ordered__c from SBQQ__Quote__c where SBQQ__Type__c='Amendment'];
            //:CWS_ConstantClass.Quote_Type_Amendment];
            System.assertNotEquals(true,amendmentQuotes.isEmpty());
            List<SBQQ__QuoteLine__c> quoteLines=[Select id, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__Product__c
                             from SBQQ__QuoteLine__c where SBQQ__Quote__c=:amendmentQuotes[0].Id];
            quoteLines[0].SBQQ__Quantity__c=0;
            quoteLines[0].SBQQ__PricebookEntryId__c=mapPricebookEntryId.get(quoteLines[0].SBQQ__Product__c);
            update quoteLines[0];
            
            Test.startTest();
            amendmentQuotes[0].SBQQ__Pricebook__c=pricebookList[0].Id;
            amendmentQuotes[0].SBQQ__Ordered__c=true;
            update amendmentQuotes[0];
            
           
            List<Order> orderList=[Select Id, Name,  SBQQ__Contracted__c, Pricebook2Id, Status from Order];
            if(pricebookList!=null && !pricebookList.isEMpty()){
            orderList[0].Pricebook2Id=pricebookList[0].Id;
            }
            orderList[0].status='Activated';
            update orderList[0];
            
            List<OrderItem> orderItemList=[Select Id, SBQQ__Activated__c from OrderItem];
            orderItemList[0].SBQQ__Activated__c=true;
            update orderItemList;
            Test.stopTest();
            
            Contract[] updatedContract=[Select Id, Name, CWS_Cancelled__c from Contract where Id = :contract.Id Limit 1];
            System.assertNotEquals(true, updatedContract.isEmpty());
            system.assertEquals(false,updatedContract[0].CWS_Cancelled__c);
        }
    }     
     */
	 
       public class QuoteModel {
        public SBQQ__Quote__c record;
        public QuoteLineModel[] lineItems;
        public QuoteLineGroupModel[] lineItemGroups;
        public Integer nextKey;
        public Boolean applyAdditionalDiscountLast;
        public Boolean applyPartnerDiscountFirst;
        public Boolean channelDiscountsOffList;
        public Decimal customerTotal;
        public Decimal netTotal;
        public Decimal netNonSegmentTotal;
    } 
    
    public class QuoteLineGroupModel {
        public SBQQ__QuoteLineGroup__c record;
        public Decimal netNonSegmentTotal;
        public Integer key;
    }    
    
    public class QuoteLineModel {
        public SBQQ__QuoteLine__c record;
        public Boolean amountDiscountProrated;
        public Integer parentGroupKey;
        public Integer parentItemKey;
        public Integer key;
        public Boolean upliftable;
        public String configurationType;
        public String configurationEvent;
        public Boolean reconfigurationDisabled;
        public Boolean descriptionLocked;
        public Boolean productQuantityEditable;
        public Decimal productQuantityScale;
        public String dimensionType;
        public Boolean productHasDimensions;
        public Decimal targetCustomerAmount;
        public Decimal targetCustomerTotal;
    }    
}