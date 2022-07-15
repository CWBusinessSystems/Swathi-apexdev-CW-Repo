/*Class Name: CWS_AmendContractControllerTest
*Description: Test Class for CWS_AmendContractController
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_AmendContractControllerTest{
    /* @testSetup
   static void createTestData(){
       //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','SBQQ__Quote__c'});           
        //Create Sold To Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR','CWS_Region__c'=>'NA'};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD'
        };
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,false);
        opty.CurrencyIsoCode='EUR';
        if(opty!=null){
        insert opty;
        }

        Map<String, Object> quoteFields2=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New', 'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Channel'
        };
        
        Map<String, Object> productFields=new Map<String, Object>{
            'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12   
        };
        Product2 product=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,false);
        product.SBQQ__SubscriptionType__c='Renewable';
        product.SBQQ__SubscriptionBase__c='List';
        if(product!=null){
        insert product;
        }

       // PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithStdPricebook(Test.getStandardPricebookId(),product.Id,1000.00,'EUR');
        SBQQ__Quote__c quote2=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields2, false); 
        quote2.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quote2.CurrencyIsoCode='EUR';
        if(quote2!=null){
        insert quote2;
        }

        List<SBQQ__QuoteLine__c> quoteLineItem = CWS_UTLDataFactory.createQuoteLines(1, quote2.Id, product.Id);
       // quoteLineItem[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem[0].SBQQ__SubscriptionTerm__c=12;
        if(quoteLineItem!=null){
        insert quoteLineItem;
        }
                    
        List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)Database.query('Select Id, Name,SBQQ__Ordered__c,SBQQ__PricebookId__c,SBQQ__PriceBook__c,CWS_Quote_ACV__c from SBQQ__Quote__c');
        quoteList[0].SBQQ__Ordered__c=true;
        if(quoteList.size()>0){
        update quoteList;
        }

        List<order> orderList=(List<order>)Database.query('Select Id,SBQQ__Contracted__c from order ');
        orderList[0].Pricebook2Id=Test.getStandardPricebookId();
        orderList[0].Status='Activated';
        if(orderList.size()>0){
        update  orderList;
        }
        
        list<OrderItem> lstOLI =(List<OrderItem>)Database.query('select id,SBQQ__Activated__c from OrderItem');
        lstOLI[0].SBQQ__Activated__c = true;
        if(lstOLI.size()>0){
        update lstOLI;
        }
        
         orderList[0].SBQQ__Contracted__c=true;
         if(orderList.size()>0){
         update orderList;
         }      

    }*/
    
     @TestSetup
    static void init(){
         Account acc = CWS_UTLDataFactory.createAccount('ConnectWise Test Account', new Map<String, Object>{'CWS_Region__c'=>'NA','CWS_Is_Distributor__c'=> true,'Industry'=>'MSP'}, true);
       
      
        Contact contact = CWS_UTLDataFactory.createContact('tst01 FName', 'tst01 lName', acc.id,new Map<String, Object> {}, true);

        Opportunity opp = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty',acc.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>acc.id,'type'=> 'Amendment'}, true);      
        
       
        Product2 p = CWS_UTLDataFactory.createProduct('Test Product','SKU001',new Map<String, Object>{}, true);
       
        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id=Test.getStandardPricebookId(), Product2Id = p.Id, UnitPrice = 1000, IsActive = true);
        insert standardPBE;
        
        Pricebook2 pbCW = CWS_UTLDataFactory.createCustomPB('ConnectWise Standard PriceBook', true);     
        
        PricebookEntry pbe = CWS_UTLDataFactory.createPBEwithPricebookId(pbCW.Id,p.id,1000.00,'USD', true);  
        
        
        
        
        Contract con = new Contract(Account = acc, ContractTerm=12, Status='Draft',AccountId = acc.id);
        insert con;
        
        
    }
   
        @isTest
        static void TestAMUserCheck(){
            Test.startTest();
            list<Contract> lstContract=[select id,Account.CWS_Region__c from Contract];
            String errMsg =CWS_AmendContractController.AMUserCheck(lstContract[0].id);
            system.assertEquals('true','true');
            Test.StopTest();  
        }
        
        
        @isTest
        static void TestUserCheckAM(){
            Test.startTest();
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            //Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString;
            User tstUser = CWS_UTLDataFactory.createUser('TUser01', uniqueName+'@Connectwise'+orgId+'.org', 'TestUserLastName', 'System Administrator', 'CEO', uniqueName+'@Connectwise'+orgId+'.org', new Map<String, Object>{}, true);        
            
            boolean booVal = CWS_AmendContractController.UserCheckAM('NA',tstUser);
            system.assertEquals(true,booVal);
            Test.StopTest();  
        }
        
        
        @isTest
        static void testUpdateRecord(){
            Test.startTest();
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            //Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString;
            User tstUser = CWS_UTLDataFactory.createUser('TUser01', uniqueName+'@Connectwise'+orgId+'.org', 'TestUserLastName', 'System Administrator', 'CEO', uniqueName+'@Connectwise'+orgId+'.org', new Map<String, Object>{}, true);        
            String dummyString = 'Dummy String';
            list<Contract> lstContract=[select id,Account.CWS_Region__c from Contract];
            boolean booVal = CWS_AmendContractController.updateRecord('New','','Pending','', lstContract[0].id);
            system.assertEquals(true,booVal);
            Test.StopTest();  
        }

        @isTest
        static void testdecimalToBinary() {
            Test.startTest();
            String s = CWS_AmendContractController.decimalToBinary(327);
            system.debug('%s' + s);
            system.assertEquals(s,s);
            Test.stopTest();
        }
        
        @isTest
        static void testbase64ToBits() {
            Test.startTest();
            String s = CWS_AmendContractController.base64ToBits('Dummy');
            system.debug('%s' + s);
            system.assertEquals(s,s);
            Test.stopTest();
        }
        @isTest
        static void testSetters(){
            Test.startTest();
            CWS_AmendContractController.PicklistEntryWrapper obj = new CWS_AmendContractController.PicklistEntryWrapper();
            obj.active = 'true';
            obj.defaultValue = 'Dummy';
            obj.label = 'DummyLabel';
            obj.value = 'Dummy  Value';
            obj.validFor = 'Dummy Valid For';
            system.assertEquals('true',obj.active);
            system.assertEquals('Dummy',obj.defaultValue);
            system.assertEquals('DummyLabel',obj.label);
            system.assertEquals('Dummy  Value',obj.value);
            system.assertEquals('Dummy Valid For',obj.validFor);
            Test.stopTest();
        }
        @isTest
        static void testPickListEntry(){
            Test.startTest();
            list<Contract> lstContract=[select id,Account.CWS_Region__c, CWS_TransactionReason__c, CWS_ConversionType__c from Contract];
            Map<String, List<String>> getMappedFields = CWS_AmendContractController.getDependentMap(lstContract[0], 'CWS_TransactionReason__c','CWS_ConversionType__c');
            system.assertEquals(true,getMappedFields!=null);
            Test.stopTest();
        }
        /* @isTest
        static void testPickListEntryNull(){
            Test.startTest();
            list<Contract> lstContract=[select id,Account.CWS_Region__c, CWS_TransactionReason__c, CWS_ConversionType__c from Contract];
            Map<String, List<String>> getMappedFields = CWS_AmendContractController.getDependentMap(null, 'CWS_TransactionReason__c','CWS_ConversionType__c');
            system.assertEquals(true,getMappedFields!=null);
            Test.stopTest();        
        }*/
        
        
        
    }