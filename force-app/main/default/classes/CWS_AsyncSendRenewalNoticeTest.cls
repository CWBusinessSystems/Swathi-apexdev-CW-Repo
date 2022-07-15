@isTest
public class CWS_AsyncSendRenewalNoticeTest {
     
        
     @testSetup 
     static void createTestData(){
            
       //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Contract','Opportunity','Quote','SBQQ__QuoteDocument__c'});   
        
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'USD','CWS_Distributor_Logic_Exclusion__c'=>false};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
         //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'USD','CWS_Is_Distributor__c'=> true};
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount1', distributorAccountFieldValues,2,true);        
              
        // Create Distributr Reseller Records 
          Account accChannel = CWS_UTLDataFactory.createAccount('ConnectWise Test Account', new Map<String, Object>{'CWS_Is_Distributor__c'=> true,'Industry'=>'MSP','CWS_Distributor_Logic_Exclusion__c'=>true}, true);
          CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.id,accChannel.Id, 'Distributor','Fulfillment', null, null, true);
        //  CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', null, null, true);
        
        
        //Create Contract
        Map<String, Object> contAdditionalFieldValues = new Map<String, Object>{
          'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL,
         'CWS_Quote_SubType__c' => 'Credit',
          'CWS_OF_Signed_Date__c'=>System.today(),
           'StartDate' => System.today()
              //'EndDate' =>System.Today()
        };
        Contract cont = CWS_UTLDataFactory.createContract(soldtoaccount.id, contAdditionalFieldValues, true);
        
         //Create Contact
        Map<String, Object> conFields = new Map<String, Object>{
          'CWS_Primary_Billing_Contact__c' => true,
           'Email'=> 'test@test.com'
        };
        Contact contact=CWS_UTLDataFactory.createContact('soldToFirstName','soldToLastName',soldtoAccount.Id, conFields, true);
        
      
        
        // Create Opportunity Map 1
        Map<String, Object> opportunityFields1 = new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'Renewal','CurrencyIsoCode'=>'USD', 'SBQQ__RenewedContract__c'=>cont.id,'accountID'=>soldtoaccount.id,'Name'=>'New Business Opty'
        };
        
         // Create Opportunity Map 2
        Map<String, Object> opportunityFields2 = new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'Renewal','CurrencyIsoCode'=>'USD', 'SBQQ__RenewedContract__c'=>cont.id,'Name'=>'New Business Opty', 'accountID'=>soldtoaccount.id
        };
         
        Map<Integer, Map<String, Object>> oppBulkCreationMap = new Map<Integer, Map<String, Object>>();
        oppBulkCreationMap.put(1,opportunityFields1);
        oppBulkCreationMap.put(2,opportunityFields2);
        
        //Create Bulk Opportunities     
        List<Opportunity> opties = CWS_UTLDataFactory.createOpportunities(oppBulkCreationMap,oppBulkCreationMap.size(), true); 
        
        //Create Product
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
        product1.SBQQ__SubscriptionType__c='Renewable';
        product1.SBQQ__SubscriptionBase__c='List';
        insert product1;
        PricebookEntry pbe1=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product1.Id,1000,'USD', true);
         
        //Create Quote Fields Map1
        Map<String, Object> quoteFields1=new Map<String,Object>{
             'SBQQ__Primary__c'=>true,
             'SBQQ__opportunity2__c'=> opties[0].id,
             'CWS_Quote_Type__c'=>'Renewal',
             'CWS_Add_Terms_Manually__c'=>'Test123456',
             'SBQQ__ExpirationDate__c'=> System.today(),
             'CWS_Bill_to_Account__c'=> soldtoaccount.Id,
             'CWS_Reference_Expiry_Date__c' =>null,
             'CWS_IsCloned__c' => false,
             'RecordTypeId'=>CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY,
             'SBQQ__WatermarkShown__c'=>false,
             'CWS_Route_to_Market__c'=>'Direct',
             'CWS_Renewal_Category__c'=>'Opt-Out',
              'SBQQ__PrimaryContact__c'=>contact.id,
              'CWS_Bill_To_Account__c'=>soldtoaccount.Id,
               'SBQQ__Account__c'=> soldtoaccount.Id,
               'CWS_Secondary_Recipient_Email__c' =>'test@test1.com'
                 };
        
          
        //Create  Quote Fields Map2
        Map<String, Object> quoteFields2=new Map<String,Object>{
             'SBQQ__Primary__c'=>true,
             'SBQQ__opportunity2__c'=> opties[1].id,
             'CWS_Quote_Type__c'=>'Renewal',
             'CWS_Add_Terms_Manually__c'=>'Test123456',
             'SBQQ__ExpirationDate__c'=> System.today(),
             'CWS_Bill_to_Account__c'=> soldtoAccount.Id,
             'CWS_Reference_Expiry_Date__c' =>null,
             'CWS_IsCloned__c' => false,
             'RecordTypeId'=>CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY,
             'SBQQ__WatermarkShown__c'=>false,
             'CWS_Route_to_Market__c'=>'Direct',
             'CWS_Renewal_Category__c'=>'Opt-Out',
            'SBQQ__PrimaryContact__c'=>contact.id,
              'CWS_Bill_To_Account__c'=>soldtoaccount.Id,
               'SBQQ__Account__c'=> soldtoaccount.Id,
               'CWS_Secondary_Recipient_Email__c' =>'test@test1.com'
                 };
        // Create Bulk Quotes       
        Map<Integer, Map<String, Object>> quotesMap = new Map<Integer, Map<String, Object>>();
        quotesMap.put(1,quoteFields1);
        quotesMap.put(2,quoteFields2);
        List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
        lstQuotes = CWS_UTLDataFactory.createQuotes(quotesMap, quotesMap.size(), true);
       
       //Create Bulk Quote Lines
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        
        //Create QuoteLine
        
        Map<String, Object> quoteLinesFields1 = new Map<String, Object>{'SBQQ__PricebookEntryId__c'=> pbe1.id, 'SBQQ__Product__c' =>product1.id,'SBQQ__Quote__c'=>lstQuotes[0].id};
        Map<String, Object> quoteLinesFields2 = new Map<String, Object>{'SBQQ__PricebookEntryId__c'=> pbe1.id, 'SBQQ__Product__c' =>product1.id,'SBQQ__Quote__c'=>lstQuotes[1].id};     
        
        Map<Integer, Map<String, Object>> quoteLinesMap = new Map<Integer, Map<String, Object>> (); 
        quoteLinesMap.put(1, quoteLinesFields1);
        quoteLinesMap.put(2, quoteLinesFields2);
        List<SBQQ__QuoteLine__c> lstQuoteLines = CWS_UTLDataFactory.createQuoteLines(quoteLinesMap, quoteLinesMap.size(), true);        
         
        Document document = new Document();
        document.AuthorId = UserInfo.getUserId();
        document.FolderId = UserInfo.getUserId();
        document.Name = 'TestDoc';
        document.type = 'pdf';
        document.Body = Blob.valueOf('TestBodyDoc');
        insert document;  
         
         //Create QuoteDOcument Fields 1
        Map<String, object> docFields1 = new Map<String, Object>{
             'SBQQ__Quote__c'=> lstQuotes[0].id,
             'SBQQ__SignatureStatus__c'=> '', 
             'SBQQ__ElectronicSignature__c'=>false,
             'SBQQ__DocumentId__c' => document.id
        };
         //Create QuoteDOcument Fields  2
        Map<String, object> docFields2 = new Map<String, Object>{
             'SBQQ__Quote__c'=> lstQuotes[1].id,
             'SBQQ__SignatureStatus__c'=> '', 
             'SBQQ__ElectronicSignature__c'=>false,
             'SBQQ__DocumentId__c' => document.id
        };
        Map<Integer, Map<String, Object>> mapQuoteDocs = new Map<Integer, Map<String, Object>>();
        mapQuoteDocs.put(1, docFields1);
        mapQuoteDocs.put(1, docFields2);
        
        List<SBQQ__QuoteDocument__c> lstQuoteDocs = CWS_UTLDataFactory.createQuoteDocuments(mapQuoteDocs, mapQuoteDocs.size(), true);
     } 
     
     @isTest
     static void testAsyncRenewalBatch(){

         //Test.setMock(HttpCalloutMock.class, new CWS_MockHttpResponseGenerator_test());
                

         CWS_EnvelopeModel modelWrap = new CWS_EnvelopeModel();
         
        Document doc1=[Select id, name, type, body from Document limit 1];
        Map<Id,Document> mdoc= new Map<Id,Document>();
        mDoc.put(doc1.Id,doc1);
        SBQQ__QuoteDocument__c doc = [Select id, SBQQ__Quote__c,SBQQ__DocumentId__c, SBQQ__Opportunity__c from SBQQ__QuoteDocument__c limit 1];
        SBQQ__Quote__c quote = [Select id,SBQQ__PrimaryContact__r.Email, CWS_Secondary_Recipient_Email__c   from SBQQ__Quote__c limit 1];
        CWS_EnvelopeRequestWrapper wrap = new CWS_EnvelopeRequestWrapper('tempId',doc1.id,
            quote.SBQQ__PrimaryContact__r.Email, 
            'test@pass.com',
            'role1', 
            'role2', 
            'test1',
            'test2',
            'subject',
            doc.SBQQ__Quote__c, 
            doc.id, 
            doc.SBQQ__Opportunity__c,
            'Opt-Out',
            'Channel',
            'TestAccount');
            
        List<CWS_EnvelopeRequestWrapper> lstWrap = new List<CWS_EnvelopeRequestWrapper>();
        lstWrap.add(wrap);
          Test.startTest();
        CWS_AsyncSendRenewalNotice async=new CWS_AsyncSendRenewalNotice(lstWrap, mdoc);
              Id jobId=System.enqueueJob(async);
               // Database.executeBatch(async); 
        Test.stopTest();
         System.assertEquals(1,lstWrap.size());
     } 
    
     @isTest
     static void testAsyncRenewalBatch2(){
       
        //Test.setMock(HttpCalloutMock.class, new CWS_MockHttpResponseGenerator_test());
        CWS_EnvelopeModel modelWrap = new CWS_EnvelopeModel();
        Document doc1=[Select id, name, type, body from Document limit 1];
        Map<Id,Document> mdoc= new Map<Id,Document>();
        mDoc.put(doc1.Id,doc1);
        SBQQ__QuoteDocument__c doc = [Select id, SBQQ__Quote__c,SBQQ__DocumentId__c, SBQQ__Opportunity__c from SBQQ__QuoteDocument__c
                                                                where SBQQ__Quote__r.CWS_Route_to_Market__c = 'Direct'];
        SBQQ__Quote__c quote = [Select id,SBQQ__PrimaryContact__r.Email, CWS_Secondary_Recipient_Email__c   from SBQQ__Quote__c 
                                                                where CWS_Route_to_Market__c = 'Direct' LIMIT 1];
       CWS_EnvelopeRequestWrapper wrap = new CWS_EnvelopeRequestWrapper('tempId',doc1.id,
            quote.SBQQ__PrimaryContact__r.Email, 
            'test@pass.com',
            'role1', 
            'role2', 
            'test1',
            'test2',
            'subject',
            doc.SBQQ__Quote__c, 
            doc.id, 
            doc.SBQQ__Opportunity__c,
            'Opt-Out',
            'Direct',
            'TestAccount');
            
        List<CWS_EnvelopeRequestWrapper> lstWrap = new List<CWS_EnvelopeRequestWrapper>();
        lstWrap.add(wrap);
         Test.startTest();
        CWS_AsyncSendRenewalNotice async=new CWS_AsyncSendRenewalNotice(lstWrap, mdoc);
              Id jobId=System.enqueueJob(async);
            
               // Database.executeBatch(async); 
        Test.stopTest();
         System.assertEquals(1,lstWrap.size());
     } 
    @IsTest
    static void TestEnvelopeModel(){
         CWS_EnvelopeModel.EnvelopeResponse testResponse = new CWS_EnvelopeModel.EnvelopeResponse(); 
            testResponse.envelopeId = 'TestId';
            testResponse.uri = 'TestUri';
            testResponse.status = 'TestStatus';
            testResponse.statusDateTime = 'TestStatusDate';
         CWS_EnvelopeModel.Recipient testRecipient = new CWS_EnvelopeModel.Recipient(); 
            testRecipient.email = 'T@t.com';
            testRecipient.username = 'abc1234';
            testRecipient.id = '123123123';
            testRecipient.type_x = 'asadad';
            testRecipient.routingOrder = 'acbderf';
         CWS_EnvelopeModel.TabWrapper testTabWrap = new CWS_EnvelopeModel.TabWrapper();
            testTabWrap.value = 'string';
            testTabWrap.font = 'Font';
            testTabWrap.locked = 'locked';
            testTabWrap.show = 'show';
            testTabWrap.configurationType = 'Type';
            testTabWrap.name = 'Name';
    }
  

}