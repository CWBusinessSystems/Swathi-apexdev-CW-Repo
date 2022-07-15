/*Class Name: CWS_CommonUtilityTest
*Description: Test Class for CWS_CommonUtilityTest
*Created By: Indra Ganesan
*Created On: 03-08-2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            Description
*------------------------------------------------------------------------------------------
*Indra Ganesan         03-08-2020       Test Class for CWS_DiscountTierTriggerHelper             
    */
    @isTest(SeeAllData=false)
    public with sharing class CWS_CommonUtilityTest {

    @TestSetup
    static void init(){
        
        /* Map<String, Object> addFieldsA   mendOpp=new Map<String, Object>{
                'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
                'Type'=>'Renewal',
                'CurrencyIsoCode'=>'USD',
                'CWS_Distributor__c'=>distiaccounts[0].Id,
                'CWS_Route_to_Market__c'=>'Channel',
                'CWS_Legal_Entity__c'=>'CW-US'
        };*/   
         /**USer  **/
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        //Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString;
        
       // User tstUserFTQ = CWS_UTLDataFactory.createUser('TUserFTQ', uniqueName+'@Connectwise'+orgId+'.org', 'FTQUserLastName', 'System Administrator', 'CEO', uniqueName+'FTQ' +'@Connectwise'+orgId+'.org', new Map<String, Object>{}, true);       
       // User tstUserCA = CWS_UTLDataFactory.createUser('TUserCA', uniqueName+'@Connectwise'+orgId+'.org', 'CAUserLastName', 'System Administrator', 'CEO', uniqueName+'CA'+'@Connectwise'+orgId+'.org', new Map<String, Object>{}, true);        
       
       
        Account acc = CWS_UTLDataFactory.createAccount('ConnectWise Test Account', new Map<String, Object>{'CWS_Is_Distributor__c'=> true,'Industry'=>'MSP'}, true);
       
      
        //Contact contact = CWS_UTLDataFactory.createContact('tst01 FName', 'tst01 lName', acc.id,new Map<String, Object> {}, true);
		Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => false,
            'CWS_Primary_Contact__c' => true,
            'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
            'Email'=>'test@test1.com'
        };
        Contact contact = CWS_UTLDataFactory.createContact('TestFirstName','TestLastName', acc.Id,mapConFieldValues,true);
		
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty',acc.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>acc.id,'type'=> 'Amendment'}, true);      
        
       
        Product2 p = CWS_UTLDataFactory.createProduct('Test Product','SKU001',new Map<String, Object>{}, true);
       
        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id=Test.getStandardPricebookId(), Product2Id = p.Id, UnitPrice = 1000, IsActive = true);
        insert standardPBE;
        
        Pricebook2 pbCW = CWS_UTLDataFactory.createCustomPB('ConnectWise Standard PriceBook', true);     
        
        PricebookEntry pbe = CWS_UTLDataFactory.createPBEwithPricebookId(pbCW.Id,p.id,1000.00,'USD', true);  
       
        /**Block Price**/
        SBQQ__BlockPrice__c blkPrice = new SBQQ__BlockPrice__c(Name = 'Tst Block Price', SBQQ__Product__c=p.id, SBQQ__Price__c = 546);
        insert blkprice;                
        
      
        /**Quote 01**/
         
        Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__PrimaryContact__c'=>contact.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Quote_Type__c'=>'New Business','CWS_Bill_To_Account__c'=>acc.id, 'SBQQ__Primary__c'=> true,'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2019,7,7), 'CWS_Route_to_Market__c'=>'Direct','SBQQ__Status__c'=>'Approved'
        };  
        
        
        SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acc.id,opp.id,addFields,true);
        quote.SBQQ__Status__c = 'Approved'; 
        
        //quote.SBQQ__PricebookId__c=Test.getStandardPricebookId();    
        update quote;
       /**Quote 01**/       
        
        /** Quote Lines for Quote 01**/
        List<SBQQ__QuoteLine__c> tstQL = CWS_UTLDataFactory.createQuoteLines(1,quote.id, p.Id);
        tstQL[0].CWS_Manage_Special_Product__c = true;
        tstQL[0].CWS_Manage_Product__c = true;
        tstQL[0].SBQQ__PricebookEntryId__c = pbe.id;
        if(tstQL[0].id != null){
            insert tstQL[0];
        }
        system.debug('tstql id:'+tstQL[0].id);
        List<SBQQ__QuoteLine__c> tstQL01 = CWS_UTLDataFactory.createQuoteLinesWithBlkPrice(1,quote.id, p.Id, blkPrice.id,pbe.id);
        insert tstQL01;
         system.debug('tstql01 id:'+tstQL01[0].id);
        /** Quote Lines for Quote 01**/
       
        quote.SBQQ__Primary__c=true;      
        update quote;     
       
        /**Quote 2**/
         
        Map<String, Object> addFields01 = new Map<String,Object>{
            'CWS_Quote_Type__c'=>'New Business','CWS_Bill_To_Account__c'=>acc.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2019,7,7), 'CWS_Route_to_Market__c'=>'Direct'
        };  
        SBQQ__Quote__c quote02 = CWS_UTLDataFactory.createQuote(acc.id,opp.id,addFields01,true);
        quote.CWS_Quote_Type__c = CWS_ConstantClass.QUOTE_TYPE_RENEWALWC;
        if(quote02 != null){
            update quote02;
        }
        /**Quote 2**/
        
        /** Quote Line for Quote 02**/
        List<SBQQ__QuoteLine__c> tstQL02 = CWS_UTLDataFactory.createQuoteLines(1,quote02.id, p.Id);
        tstQL02[0].CWS_Manage_Special_Product__c = true;
        tstQL02[0].CWS_Manage_Product__c = true;
         tstQL02[0].CWS_NetTotal__c = 88979;
          tstQL02[0].SBQQ__SubscriptionTerm__c = 12;    
        if(tstQL02[0].id != null){
        
            update tstQL02[0];
        }
        /** Quote Line for Quote 02**/      
        
        /** Quote with REGION =APAC **/
        Map<String, Object> addFieldsAPAC = new Map<String,Object>{
            'SBQQ__PrimaryContact__c'=>contact.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Quote_Type__c'=>'New Business','CWS_Bill_To_Account__c'=>acc.id, 'CWS_Master__c'=>true, 'CWS_Route_to_Market__c'=>'Direct','CWS_Region__c'=> 'APAC' 
        };          
        SBQQ__Quote__c quoteRegionAPAC = CWS_UTLDataFactory.createQuote(acc.id,opp.id,addFieldsAPAC,true);  
        /** Quote with REGION =APAC **/
        
        
        /** Quote with REGION =APAC **/
        Map<String, Object> addFieldsEMEA = new Map<String,Object>{
            'SBQQ__PrimaryContact__c'=>contact.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Quote_Type__c'=>'New Business','CWS_Bill_To_Account__c'=>acc.id, 'CWS_Master__c'=>true, 'CWS_Route_to_Market__c'=>'Direct','CWS_Region__c'=> 'EMEA/ROW' 
        };          
        SBQQ__Quote__c quoteRegionEMEAROW = CWS_UTLDataFactory.createQuote(acc.id,opp.id,addFieldsEMEA,true);
        /** Quote with REGION =APAC **/

        
       
        /** Quote Document**/
        SBQQ__QuoteDocument__c qDoc= CWS_UTLDataFactory.createQuoteDocument(quote.id, new Map<String, Object> {}, true); 
       
        List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
        lstQuotes.add(quote);
        lstQuotes.add(quote02);         
     
    }    
   
    @isTest
    Public static void  testCAUserCheckRenewalCap(){
        
        /**Quote 01**/
         
       /* Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__PrimaryContact__c'=>contact.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Quote_Type__c'=>'New Business','CWS_Bill_To_Account__c'=>acc.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2019,7,7), 'CWS_Route_to_Market__c'=>'Direct'
        }; */ 
        CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'SBQQ__Quote__c';
        insert bypassValidate;
        
        
        SBQQ__Quote__c quoteObjectOne =new SBQQ__Quote__c (CurrencyISOCode = 'USD',CWS_Master__c=true,CWS_Quote_Type__c='New Business');
        if(quoteObjectOne !=null){
            insert quoteObjectOne;
        }
       
        test.startTest();
            List<String> getErr = new List<String>();
            getErr = CWS_CommonUtility.fieldsChk(quoteObjectOne.id,false);
            SBQQ__Quote__c quoteObjectOnes = [SELECT id, CWS_Quote_ACV__c from SBQQ__Quote__c where id =:quoteObjectOne.id];
            system.debug('Quote ACV :'+quoteObjectOnes.CWS_Quote_ACV__c);
            system.assertEquals(0, quoteObjectOnes.CWS_Quote_ACV__c);
            System.assertEquals(true, getErr.size()!=null); 
        test.stopTest();
        
    }
    

    
    @isTest
    Public static void  testCAUserCheckNoOppQL(){
        
        /**Quote 01**/
         
       /* Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__PrimaryContact__c'=>contact.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Quote_Type__c'=>'New Business','CWS_Bill_To_Account__c'=>acc.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2019,7,7), 'CWS_Route_to_Market__c'=>'Direct'
        }; */ 
        CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'SBQQ__Quote__c';
        insert bypassValidate;
        
        
        SBQQ__Quote__c quoteObjectOne =new SBQQ__Quote__c (CurrencyISOCode = 'USD',CWS_Master__c=true,CWS_Quote_Type__c='New Business');
        if(quoteObjectOne !=null){
            insert quoteObjectOne;
        }
        quoteObjectOne.SBQQ__PaymentTerms__c = null;
        update quoteObjectOne;
        test.startTest();
            List<String> getErr = new List<String>();
            getErr = CWS_CommonUtility.fieldsChk(quoteObjectOne.id,true);
            System.assertEquals(true, getErr.size()!=null); 

        test.stopTest();
        
    }
    
    @isTest
    Public static void testValidateMinCommit(){
     
        Account acc = [Select id from Account limit 1];
        
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id];
        Contact contact = [select id from Contact limit 1];
        Opportunity tstOpps = CWS_UTLDataFactory.createOpportunity('ConnectWise01 Test Oppty',acc.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>acc.id,'CWS_Master__c'=>true}, true);     
        Map<String, Object> addFields = new Map<String,Object>{
        'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 'SBQQ__EndDate__c'=>Date.newInstance(2019,7,7),'CWS_Master__c'=>true,'SBQQ__PrimaryContact__c'=>contact.id, 'CWS_Ship_To_Contact__c'=>contact.id,'CWS_Bill_To_Contact__c'=>contact.id,'CWS_Ship_To_Account__c'=>acc.id,'SBQQ__PricebookId__c'=> pbCW.id,'CWS_Bill_To_Account__c'=>acc.id, 'CWS_Route_to_Market__c'=>'Direct'
        };
        SBQQ__Quote__c tstQuote = CWS_UTLDataFactory.createQuote(acc.id,tstOpps.id,addFields,true);        
        system.debug('Quote id: '+ tstQuote.id);
         system.debug('Quote id: '+ tstQuote.id);
        system.debug('tstOpps id: '+ tstOpps.id);
        CWS_Minimum_Commit__c minCommit = CWS_UTLDataFactory.createMinimumCommit(tstOpps.id, acc.Id,true);       
        Test.startTest();
        List<String> getErrors = new List<String>();
        getErrors = CWS_CommonUtility.validateMinCommit(tstQuote);
                system.debug('getErrors'+getErrors);

       // System.assertEquals('Please populate monthly minimum commit object with delta values before submitting for approval.',getErrors[0]=System.Label.CWS_QuoteErrorMinCommitment);
        Test.stopTest();
     
    }
    
    @isTest
    Public static void testquoteCalcHelper(){
        Test.startTest();
        SBQQ__Quote__c tstQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Pricebook2 pb = [SELECT Id, Name , isActive from Pricebook2 where name='ConnectWise Standard PriceBook'];
        CWS_CommonUtility.quoteCalcHelper(tstQuote.id);
        System.assertEquals(true, tstQuote.id!=null);
        System.assertEquals(true, pb.id!=null); 
        Test.stopTest();
    }
    
    @isTest
    Public static void testNBQuoteDefaults(){
        Test.startTest();
        CWS_CommonUtility.NBQuoteDefaults();
        Test.stopTest();
    
    }
    
    @isTest
    Public static void testGetGroupMemberRegion(){
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        //Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString;
        User tstUser = CWS_UTLDataFactory.createUser('TUser01', uniqueName+'@Connectwise'+orgId+'.org', 'TestUserLastName', 'System Administrator', 'CEO', uniqueName+'@Connectwise'+orgId+'.org', new Map<String, Object>{}, true);
        Group tstGroup = CWS_UTLDataFactory.createGroup('Public_Group','Regular', true);
        GroupMember tstGroupMem = CWS_UTLDataFactory.createGroupMember(tstUser.id,tstGroup.id,true);    
        User newUser = [SELECT id FROM User LIMIT 1];
        Group newGroup = [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName =: 'Public_Group'];
        GroupMember newGrpMem = [SELECT GroupId,UserOrGroupId FROM GroupMember WHERE  Group.DeveloperName ='Public_Group' and UserOrGroupId =:tstUser.id];
        List<CWS_RegionGroupMapping__mdt> RegionGroup = [Select id,CWS_Region__c,CWS_GroupName__c from CWS_RegionGroupMapping__mdt Limit : Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit)];
        List<Id> lstUsers = new List<Id>();
        lstUsers.add(newUser.id);
        Test.startTest();
        Map<Id, Set<String>> mapUserWthRegion = CWS_CommonUtility.getGroupMemberRegion(lstUsers);
        System.assertEquals(true, lstUsers != null); 
        Test.stopTest();
    
    }
    
    @isTest
    Public static void testRefreshPriceOnQuotePrice(){
        Boolean setError = false;
        Product2 p = [Select Id from Product2 LIMIT 1];
        Pricebook2 pbCW = [SELECT Id, Name , isActive from Pricebook2 where name=:'ConnectWise Standard PriceBook'];
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id];        
        SBQQ__Quote__c tstQuote = [SELECT Id,CWS_Quote_Type__c,SBQQ__Status__c,SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];    
        SBQQ__BlockPrice__c  blockPrice = [Select Id, SBQQ__Price__c from SBQQ__BlockPrice__c limit 1]; 
       /* List<SBQQ__QuoteLine__c> QLine =  [SELECT id, SBQQ__ListPrice__c, SBQQ__PricebookEntryId__c, SBQQ__BlockPrice__c, SBQQ__PricingMethod__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :tstQuote.id ];*/
        SBQQ__BlockPrice__c blkPrice = [select id, SBQQ__Price__c from SBQQ__BlockPrice__c limit 1];
       
       List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(1, tstQuote.Id, p.Id);
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;        
        quoteLineItem2[0].SBQQ__Quantity__c = 4;
        quoteLineItem2[0].CWS_Renewal_Type__c = 'Opt-out';
        quoteLineItem2[0].CWS_NetTotal__c = 3439;

       
        if(quoteLineItem2!=null){
        insert quoteLineItem2;
        } 
        
        system.debug('Quote line===>'+[select id, SBQQ__PricingMethod__c from SBQQ__QuoteLine__c where id =:quoteLineItem2[0].id]);

        List<SBQQ__QuoteLine__c> tstQLs02 = CWS_UTLDataFactory.createQuoteLinesWithBlkPrice(1,tstQuote.id, p.Id, blkPrice.id,pbCW.id);
        tstQLs02[0].CWS_Manage_Special_Product__c = true;
        tstQLs02[0].CWS_Manage_Product__c = true;
        tstQLs02[0].SBQQ__PricebookEntryId__c = pbe.id;
        if(tstQLs02[0].id != null){
            insert tstQLs02[0];
        }
                system.debug('Quote line===>'+[select id, SBQQ__PricingMethod__c from SBQQ__QuoteLine__c where id =: quoteLineItem2[0].id]);

        Test.startTest();
        setError = CWS_CommonUtility.refreshPriceOnQuote(tstQuote.id);       
        System.assertEquals(true, tstQuote.id!=null); 
        Test.stopTest();
        
    }
    
  /*   @isTest
    Public static void testCAUserCheckRefreshPrice(){
        Pricebook2 pb = [SELECT Id, Name , isActive from Pricebook2 where name='ConnectWise Standard PriceBook'];
        List<PricebookEntry> lstPriceBookEntry = [Select Id from PricebookEntry WHERE Pricebook2.Name = 'System.Label.CWS_ConnectwisePricebook' limit 1];
        Contact c = [select id from Contact LIMIT 1];
        Account account = [SELECT id from Account limit 1];
        account.CWS_MSA_Agreement__c = 'MSA agreement';
        update account;
        SBQQ__Quote__c tstQuote = [SELECT Id,CWS_Quote_Type__c,SBQQ__Status__c,CWS_Master__c FROM SBQQ__Quote__c LIMIT 1];    
        tstQuote.SBQQ__Status__c = 'Draft';
        tstQuote.SBQQ__Primary__c = true;
        tstQuote.CWS_Master__c = false;
        tstQuote.CWS_Bill_To_Contact__c = c.id;
        tstQuote.CWS_Ship_To_Account__c = account.id;
        tstQuote.SBQQ__Account__c = account.id;
        tstQuote.SBQQ__PrimaryContact__c = c.id;
        tstQuote.SBQQ__PaymentTerms__c = 'Net30';
        tstQuote.CWS_Legal_Entity__c = 'CW-US';
        update tstQuote;
        SBQQ__BlockPrice__c  blockPrice = [Select Id, SBQQ__Price__c from SBQQ__BlockPrice__c limit 1]; 
        List<SBQQ__QuoteLine__c> QLine =  [SELECT id,SBQQ__SubscriptionTerm__c,CWS_NetTotal__c,SBQQ__ChargeType__c,CWS_Calculated_Subscription_Term__c, SBQQ__ListPrice__c, SBQQ__PricebookEntryId__c, SBQQ__BlockPrice__c, SBQQ__PricingMethod__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :tstQuote.id ];
        QLine[0].SBQQ__SubscriptionTerm__c = 12;
        QLine[0].CWS_NetTotal__c = 34234;
        update QLine[0];
        Test.startTest();
        String err='Price of the products has been updated, use Refresh Price button to refresh the Price.';
        List<String> setErrors = CWS_CommonUtility.fieldsChk(tstQuote.id, true);       
        System.assertEquals(err, setErrors[0]); 
        Test.stopTest();
        
    }*/
    
     @isTest
    Public static void testupdateRenewalWCQuoteOwner(){
        
        SBQQ__Quote__c tstQuote = [SELECT Id,CWS_Quote_Type__c,SBQQ__Status__c,OwnerId FROM SBQQ__Quote__c LIMIT 1];   
        tstQuote.CWS_Quote_Type__c = CWS_ConstantClass.QUOTE_TYPE_RENEWALWC;
        update tstQuote;
        Opportunity tstOpp = [SELECT id,CWS_Master__c,OwnerId from Opportunity limit 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString;
       
        
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
            User tstUser = CWS_UTLDataFactory.createUser('TUser01', uniqueName+'@Connectwise'+orgId+'.org', 'TestUserLastName', 'System Administrator', 'CEO', uniqueName+'@Connectwise'+orgId+'.org', new Map<String, Object>{}, true);
            
            System.runAs(tstUser)
            {
                tstOpp.ownerId = tstUser.id;
                update tstOpp ;
            }
        Test.startTest();
            CWS_CommonUtility.updateRenewalWCQuoteOwner(new set<ID>{tstQuote.id});
            System.assertNotEquals(tstOpp.ownerId, tstQuote.ownerId); 

        Test.stopTest();    
        
    }
    
    @isTest
    Public static void testsendEmail(){
        
        String subject = 'Tst Subject';
        String htmlBody = 'Yes Body';
        List<String> toAddresses = new list<String>{'iganesan@deloitte.com'};
        Test.startTest();
        CWS_CommonUtility.sendEmail(subject, htmlBody, toAddresses);
        Test.stopTest();
    }
    
   /*  @isTest
    Public static void testQuoteID(){
        id qid;
        list<id> qidLst;
       // qid.add(null);
        List<string> setError = new List<String>();
        SBQQ__Quote__c objQuote = null;
        Test.startTest();
       // setError = ;
        CWS_CommonUtility.updateRenewalWCQuoteOwner(new set<ID>{qid});         
        System.assertEquals(false,CWS_CommonUtility.refreshPriceOnQuote(qid));
        //System.assertEquals(null,CWS_CommonUtility.getGroupMemberRegion(qidLst));
        CWS_CommonUtility.quoteCalcHelper(qid);
        System.assertNotEquals(new List<String>{System.Label.CWS_QuoteErrorMinCommitment}, CWS_CommonUtility.validateMinCommit(objQuote));
        Test.stopTest();
    }   */
    
    @isTest
    Public static void testsendOFCancellationEmail(){
        
        SBQQ__Quote__c quote = [select id, ownerid from SBQQ__Quote__c limit 1];
        EmailTemplate et = [SELECT Id,Subject, Body FROM EmailTemplate WHERE DeveloperName =: CWS_ConstantClass.QUOTE_OF_NOTIF_TEMPLATE];
        List<SBQQ__QuoteDocument__c> lstQDoc = [SELECT id,SBQQ__Quote__c,SBQQ__PrimaryContactId__c,SBQQ__Quote__r.OwnerId FROM SBQQ__QuoteDocument__c LIMIT 1];
        Test.startTest();
        CWS_CommonUtility.sendOFCancellationEmail(lstQDoc);
        System.assertEquals(true,lstQDoc.size()>0);
        Test.stopTest();
        
    }
    
     @isTest 
    Public static void  testCAUserCheckRenewalQT(){
       
        CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
        insert bypassValidate;
        
        Account accs = CWS_UTLDataFactory.createAccount('ConnectWise012ACC', new Map<String, Object>{'CWS_Is_Distributor__c'=> true,'Industry'=>'MSP'}, true);
        //Contact contact = CWS_UTLDataFactory.createContact('CName111', 'lName11', accs.id,new Map<String, Object> {}, true);
             Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
            'CWS_Primary_Contact__c' => false,
            'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
            'Email'=>'test123@test1.com'
        };
        Contact contact = CWS_UTLDataFactory.createContact('TestFirstName1','TestLastName1', accs.Id,mapConFieldValues,true);
		Contract con = new Contract(Account = accs, ContractTerm=12, Status='Draft',AccountId = accs.id);
        insert con;
        if(con!=null){
            con.Status = 'Activated';
            con.CWS_Renewal_Category__c = 'Opt-Out';
            con.CWS_Renewable_Products__c  = 1;
            update con;
        }
        system.debug('Contract id :'+ con.id);
       Test.Starttest();
        Opportunity opps = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty667676',accs.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>accs.id,'type'=> 'Renewal with Change'}, true);  
        Product2 p = CWS_UTLDataFactory.createProduct('Test Product001','SKU002',new Map<String, Object>{}, true);
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id];        
         system.debug('Opps id :'+opps.id);
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Amendment_Read_Only' AND sObjectType = 'SBQQ__Quote__c'].Id;
        
        Map<String, Object> addFields = new Map<String,Object>{
            'CWS_Vendor_Approval_Received__c'=>false,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.today(), 'SBQQ__EndDate__c'=>Date.today()+10, 'CWS_Route_to_Market__c'=>'Direct','RecordTypeId'=>recordTypeId 
        }; 
         SBQQ__Quote__c quotes = CWS_UTLDataFactory.createQuote(accs.id,opps.id,addFields,true);
         quotes.CWS_Quote_Type__c = 'Renewal with Change';
        
         quotes.CWS_Sub_Type__c ='Credit';
        // quotes.SBQQ__Type__c='Amendment';
        
         SYSTEM.debug([SELECT ID,CWS_Quote_Type__c from SBQQ__Quote__c where SBQQ__opportunity2__c =:opps.id]); 
         
        SYSTEM.debug([SELECT ID from SBQQ__QuoteLine__c where SBQQ__Quote__c=:quotes.id]);
        
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(1, quotes.Id, p.Id);
        quoteLineItem2[0].CWS_SKU_Type__c= 'Dedicated Tech';
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem2[0].CWS_Manage_Special_Product__c = true;
        quoteLineItem2[0].CWS_Manage_Product__c = true;
        quoteLineItem2[0].SBQQ__Quantity__c = 2;
        quoteLineItem2[0].CWS_NetTotal__c = 3439;
        
        if(quoteLineItem2!=null){
            insert quoteLineItem2;
        } 
        List<SBQQ__Subscription__c> sub = CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(accs.id,con.Id,quotes.Id, true);
         sub[0].SBQQ__Quantity__c=1;
         update sub[0];
        quoteLineItem2[0].SBQQ__UpgradedSubscription__c = sub[0].id;
        update quoteLineItem2[0];
        //quotes.SBQQ__Status__c = 'Approved'; 
        quotes.SBQQ__Primary__c=true;
        quotes.SBQQ__Ordered__c=true;
        update quotes;
        
        System.assert([SELECT ID from Order where SBQQ__Quote__c=:quotes.id].size()!=0,'No order is created');  
        SYSTEM.debug([SELECT ID,ORDERNumber,account.name from Order where SBQQ__Quote__c=:quotes.id]);       

        Order orderObjs = [select Id from Order where SBQQ__Quote__c=:quotes.Id];
        OrderItem oliObjs = [Select id,SBQQ__OrderedQuantity__c, Product2.CWS_Manage_Special_Product__c, Product2.CWS_Manage_Product__c  from OrderItem where OrderId =: orderObjs.id];
        
        
       // SBQQ__Quote__c errQuote = new SBQQ__Quote__c (CurrencyIsoCode='USD');
       // insert errQuote; 
          List<String> getErr = new List<String>();
          getErr = CWS_CommonUtility.fieldsChk(quotes.id,true);
          System.assertEquals(true, getErr.size()!=null);
        Test.StopTest();        
    
    
    }   
    
      @isTest
    Public static void testfieldsChk(){
         CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
      insert bypassValidate;
        Product2 p = [SELECT id from Product2 limit 1];
       
       // Opportunity opp = [SELECT id,type,SBQQ__PrimaryQuote__c FROM Opportunity LIMIT 1];
        
        Account accs = CWS_UTLDataFactory.createAccount('My New Test Accounts01', new Map<String, Object>{'CWS_Is_Distributor__c'=> true}, true);

        
      /*  List<SBQQ__Quote__c> quoteObj=[select id,SBQQ__Ordered__c,CWS_isFastTrack__c,CWS_Renewal_CAP__c,CWS_Prior_Renewal_CAP__c,CWS_Quote_Type__c,CWS_Bill_To_Account__c,CWS_Bill_To_Contact__c,   CWS_Sub_Stage__c,CWS_Master__c,SBQQ__StartDate__c, SBQQ__EndDate__c,CWS_Addendum_Number__c,                                      
        CWS_Ship_To_Account__c,CWS_Ship_To_Contact__c,CWS_Renewal_Type__c,CWS_Quote_ACV__c,SBQQ__Account__c, CWS_Transaction_Reason__c, 
        SBQQ__PrimaryContact__c,SBQQ__PaymentTerms__c,CWS_Legal_Entity__c,SBQQ__Opportunity2__c,SBQQ__LineItemCount__c, 
        SBQQ__Primary__c,SBQQ__Status__c, CWS_Vendor_Approval_Received__c,
        CWS_OF_Signed_Override_Date__c, CWS_Master_Dedicated_Tech__c,SBQQ__PrimaryContact__r.CWS_Primary_Billing_Contact__c,SBQQ__PrimaryContact__r.CWS_Primary_Contact__c from SBQQ__Quote__c LIMIT 2];*/
      
      //  List<SBQQ__QuoteLine__c> quoteLine = [Select Id,CWS_Subscription_Quantity__c,SBQQ__PriorQuantity__c,SBQQ__Quantity__c,CWS_Manage_Special_Product__c,CWS_Manage_Product__c, CWS_Cost_Price__c, CWS_Original_Cost_Price__c from SBQQ__QuoteLine__c where SBQQ__Quote__c IN :quoteObj];
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id];
        Contact contactTst = [select id from contact limit 1];
        Test.StartTest();
        Contract con = new Contract(Account = accs, ContractTerm=12, Status='Draft',AccountId = accs.id);
        insert con;
        if(con!=null){
            con.Status = 'Activated';
            con.CWS_Renewal_Category__c = 'Opt-Out';
            con.CWS_Renewable_Products__c  = 1;
            update con;
        }
        system.debug('Contract id :'+ con.id);
       
        Opportunity opps = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty',accs.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>accs.id,'type'=> 'Amendment'}, true);       
        opps.SBQQ__AmendedContract__c = con.id;
        update opps;
        
        system.debug('Opps id :'+opps.id);
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Amendment_Read_Only' AND sObjectType = 'SBQQ__Quote__c'].Id;
        
        Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.today(), 'SBQQ__EndDate__c'=>Date.today()+10, 'CWS_Route_to_Market__c'=>'Direct','RecordTypeId'=>recordTypeId,'SBQQ__Status__c'=>'Draft'
        }; 
       
       /* Map<String, Object> addFields = new Map<String,Object>{
            'CWS_Ship_To_Contact__c'=>contactTst.id,'CWS_Bill_To_Contact__c'=>contactTst.id,'CWS_Ship_To_Account__c'=>accs.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Route_to_Market__c'=>'Direct','RecordTypeId'=>recordTypeId 
        };*/
        SBQQ__Quote__c quotes = CWS_UTLDataFactory.createQuote(accs.id,opps.id,addFields,true);
         quotes.CWS_Quote_Type__c = 'Amendment';
         quotes.CWS_Sub_Type__c ='Credit';
         quotes.SBQQ__Type__c='Amendment';
         SYSTEM.debug([SELECT ID,CWS_Quote_Type__c from SBQQ__Quote__c where SBQQ__opportunity2__c =:opps.id]); 
        
       /* SBQQ__BlockPrice__c blkPrice = [select id, SBQQ__Price__c from SBQQ__BlockPrice__c limit 1];
         List<SBQQ__QuoteLine__c> tstQLs = CWS_UTLDataFactory.createQuoteLinesWithBlkPrice(1,quotes.id, p.Id, blkPrice.id,pbCW.id);
        tstQLs[0].CWS_Manage_Special_Product__c = true;
        tstQLs[0].CWS_Manage_Product__c = true;
         tstQLs[0].SBQQ__PricebookEntryId__c = pbCW.id;
        if(tstQLs[0].id != null){
            insert tstQLs[0];
        }*/
        
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(1, quotes.Id, p.Id);
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem2[0].CWS_Manage_Special_Product__c = true;
        quoteLineItem2[0].CWS_Manage_Product__c = true;
        quoteLineItem2[0].SBQQ__Quantity__c = 4;
        if(quoteLineItem2!=null){
        insert quoteLineItem2;
        } 
        
        SYSTEM.debug([SELECT ID from SBQQ__QuoteLine__c where SBQQ__Quote__c=:quotes.id]);
        //quotes.SBQQ__Status__c = 'Draft'; 
        quotes.SBQQ__Primary__c=true;
        quotes.SBQQ__Ordered__c=true;
        update quotes;
        
        System.assert([SELECT ID from Order where SBQQ__Quote__c=:quotes.id].size()!=0,'No order is created');  
        SYSTEM.debug([SELECT ID,ORDERNumber,account.name from Order where SBQQ__Quote__c=:quotes.id]);       

        Order orderObjs = [select Id from Order where SBQQ__Quote__c=:quotes.Id];
        OrderItem oliObjs = [Select id,SBQQ__OrderedQuantity__c, Product2.CWS_Manage_Special_Product__c, Product2.CWS_Manage_Product__c  from OrderItem where OrderId =: orderObjs.id];
        
        List<String> getErr = new List<String>();
        getErr = CWS_CommonUtility.fieldsChk(quotes.id,true);
        System.assertEquals(true, getErr.size()!=null);
        Test.StopTest();        
    }
    
     @isTest
    Public static void testfieldsChkRegionAPAC(){
            
        Group tstGroupnameFTQ = [SELECT Id, name, DeveloperName FROM Group where DeveloperName =: CWS_ConstantClass.GroupnameFTQ];
        Group tstGroupnameCA = [SELECT Id, name, DeveloperName FROM Group where DeveloperName =: CWS_ConstantClass.GroupnameCA];
        
        GroupMember tstGroupMemFTQ = CWS_UTLDataFactory.createGroupMember(UserInfo.getUserId(),tstGroupnameFTQ.id,true);  
        GroupMember tstGroupMemCA = CWS_UTLDataFactory.createGroupMember(UserInfo.getUserId(),tstGroupnameCA.id,true);
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                'CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
              
        SBQQ__Quote__c tstQuoteAPAC = [SELECT Id FROM SBQQ__Quote__c WHERE CWS_Region__c =:'APAC'];
        
       
        System.runas(admin){
            Test.StartTest();    
                
                CWS_CommonUtility.CAUserCheck(tstQuoteAPAC.id);
            Test.StopTest();
        }
        System.assertEquals(true, tstQuoteAPAC!=null);
    }
    
    
    
         @isTest
    Public static void testfieldsChkRegionEMEA(){
            
        Group tstGroupnameFTQ = [SELECT Id, name, DeveloperName FROM Group where DeveloperName =: CWS_ConstantClass.GroupnameFTQ];
        Group tstGroupnameCA = [SELECT Id, name, DeveloperName FROM Group where DeveloperName =: CWS_ConstantClass.GroupnameCA];
        
        GroupMember tstGroupMemFTQ = CWS_UTLDataFactory.createGroupMember(UserInfo.getUserId(),tstGroupnameFTQ.id,true);  
        GroupMember tstGroupMemCA = CWS_UTLDataFactory.createGroupMember(UserInfo.getUserId(),tstGroupnameCA.id,true);
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                'CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
              
        SBQQ__Quote__c tstQuoteEMEA = [SELECT Id FROM SBQQ__Quote__c WHERE CWS_Region__c =:'EMEA/ROW'];
        
       
        System.runas(admin){
            Test.StartTest();    
                
                CWS_CommonUtility.CAUserCheck(tstQuoteEMEA.id);
            Test.StopTest();
        }
        System.assertEquals(true, tstQuoteEMEA.id !=null);
    }
    
       @isTest
    Public static void testfieldsChk03(){
        Account accs = CWS_UTLDataFactory.createAccount('My New Test Accounts02', new Map<String, Object>{'CWS_Is_Distributor__c'=> true}, true);
        
        Product2 p = [SELECT id,CWS_Base_SKU__c from Product2 limit 1];
        p.CWS_Base_SKU__c = CWS_ConstantClass.MINCOM_BASESKU_900901;
        update p;
        
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id];
        
        Contact contactTst = [select id from contact limit 1];
        
        Opportunity opps = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty03',accs.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>accs.id,'type'=> 'New Business'}, true);      
        
        Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.today(), 'SBQQ__EndDate__c'=>Date.today()+10, 'CWS_Route_to_Market__c'=>'Direct','CWS_Region__c'=>'NA'
        }; 

        SBQQ__Quote__c quoteObj = CWS_UTLDataFactory.createQuote(accs.id,opps.id,addFields,true);
       
        
        SYSTEM.debug([SELECT ID,CWS_Quote_Type__c from SBQQ__Quote__c where SBQQ__opportunity2__c =:opps.id]); 
        
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(1, quoteObj.Id, p.Id);
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;        
        quoteLineItem2[0].SBQQ__Quantity__c = 4;
        quoteLineItem2[0].CWS_Renewal_Type__c = 'Opt-out';
        quoteLineItem2[0].CWS_Transaction_Type__c ='Cancel' ;
        if(quoteLineItem2!=null){
        insert quoteLineItem2;
        } 
        
        Test.StartTest();                 
            CWS_CommonUtility.CAUserCheck(quoteObj.id);         
        Test.StopTest();
        
    }
    
      @isTest
    Public static void testfieldsChk04(){
        Account accs = CWS_UTLDataFactory.createAccount('My New Test Accounts02', new Map<String, Object>{'CWS_Is_Distributor__c'=> true}, true);
        
        Product2 p = [SELECT id,CWS_Base_SKU__c from Product2 limit 1];
        p.CWS_Base_SKU__c = CWS_ConstantClass.MINCOM_BASESKU_900901;
        update p;
        
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id];
        
        Contact contactTst = [select id from contact limit 1];
        
        Opportunity opps = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty03',accs.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>accs.id,'type'=> 'New Business'}, true);      
        
        Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.today(), 'SBQQ__EndDate__c'=>Date.today()+10, 'CWS_Route_to_Market__c'=>'Direct','CWS_Region__c'=>'NA','CWS_Transaction_Reason__c'=>CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT
        }; 

        SBQQ__Quote__c quoteObj = CWS_UTLDataFactory.createQuote(accs.id,opps.id,addFields,true);
       
        
        SYSTEM.debug([SELECT ID,CWS_Quote_Type__c from SBQQ__Quote__c where SBQQ__opportunity2__c =:opps.id]); 
        
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(1, quoteObj.Id, p.Id);
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;        
        quoteLineItem2[0].SBQQ__Quantity__c = 4;
        quoteLineItem2[0].CWS_Renewal_Type__c = 'Opt-out';
        quoteLineItem2[0].CWS_Transaction_Type__c ='Cancel' ;
        
        if(quoteLineItem2!=null){
        insert quoteLineItem2;
        } 
        
        Test.StartTest();                 
            CWS_CommonUtility.CAUserCheck(quoteObj.id);         
        Test.StopTest();
        
    }
    
       @isTest
    Public static void testqueryCWPriceBook(){
        test.startTest();
        CWS_CommonUtility.queryCWPriceBook();
        test.stopTest();
    }
     
}