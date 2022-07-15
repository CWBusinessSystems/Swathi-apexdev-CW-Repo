/*Class Name: CWS_RenewalBatch_Test
*Description: Test Class for CWS_RenewalBatch_Test
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Pooja Dhiman		  12/4/2022	       Fixed too many SOQL Queries
*/
@isTest(SeeAllData=false)
public class CWS_RenewalBatch_Test{
    @testSetup
    static void createTestData(){
        
        
       //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','SBQQ__Quote__c', 'CWS_RenewalJobStatusCheck__c'});           
        //Create Sold To Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR'};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
             'CWS_Is_Distributor__c' => true   };
        Account[] distiAccounts = CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
              
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', 'Automate;Sell', null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', 'Perch', null, true);
        
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
        	    'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS ,
                     'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Direct',
            'SBQQ__Distributor__c'=>distiAccounts[0].Id, 'CWS_Renewal_Type__c'=> 'Non-Renewable',
            'SBQQ__StartDate__c'=>Date.today()-345, 'SBQQ__SubscriptionTerm__c'=>12,
            'CWS_Renewal_CAP__c'=>10, 'CWS_Renewal_Uplift_Applicable__c'=>2
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

        PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product.Id,1000.00,'EUR', true);
        SBQQ__Quote__c quote2=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields2, false); 
        quote2.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quote2.CWS_Bill_To_Account__c = soldtoaccount.Id;
        quote2.CurrencyIsoCode='EUR';
        if(quote2!=null){
        insert quote2;
        }
 		Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLineItem = CWS_UTLDataFactory.createQuoteLines(1, quote2.Id, product.Id);
        quoteLineItem[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem[0].SBQQ__SubscriptionTerm__c=12;
        if(quoteLineItem!=null){
        insert quoteLineItem;
        }
        system.debug(quoteLineItem[0].CWS_ACVLine__c);
        List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)Database.query('Select Id, Name,CWS_Renewal_Type__c,SBQQ__StartDate__c, SBQQ__EndDate__c,SBQQ__Ordered__c,SBQQ__PricebookId__c,SBQQ__PriceBook__c,CWS_Quote_ACV__c from SBQQ__Quote__c');
        quoteList[0].SBQQ__Ordered__c=true;
        if(quoteList!=null){
        update quoteList;
        }
        Test.stopTest();
    }
    //BED-3402
    @isTest
    static void testRenewalbatch1(){
          
        Account acc = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        Test.StartTest();
        Map<String, Object> contAdditionalFieldValues = new Map<String, Object>{
          'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL,
         'CWS_Quote_SubType__c' => 'Credit',
          'CWS_OF_Signed_Date__c'=>System.today(),
           'StartDate' => System.today(),
              //'EndDate' =>Date.today().addMonths(3),
              'SBQQ__RenewalForecast__c' => FALSE,
              'CWS_Renewal_Opportunity_Schedule__c' => Date.today().adddays(-2),
              'ContractTerm' => 2,
              'CWS_Renewal_Category__c' => 'Opt-In',
              'CWS_Renewable_Products__c' => 2
        };
        Contract cont = CWS_UTLDataFactory.createContract(acc.id, contAdditionalFieldValues, true);
        
        List<SBQQ__RecordJob__c> recordJobList=new List<SBQQ__RecordJob__c>();
        SBQQ__RecordJob__c recordJob1=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Failed', SBQQ__RecordId__c=cont.Id+'::RenewContract',
                                            SBQQ__JobDetails__c='UNABLE_TO_LOCK_ROW');
        if(recordJob1!=null){
        insert recordJob1;
        }
        
        List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status from Contract LIMIT 2];
        System.assertEquals(FALSE, lstContracts.isEmpty());
        //System.assertEquals(CWS_ConstantClass.Renewal_Type_NonRenewable,lstContracts [0].CWS_Renewal_Type__c);
        

        
        
            Database.executeBatch(new CWS_RenewalBatch(acc.id),1);
        Test.stopTest();
        
    }
    
    @isTest
    static void testRenewalbatch2(){
        Account acc = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        Test.StartTest();
        Map<String, Object> contAdditionalFieldValues = new Map<String, Object>{
          'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL,
         'CWS_Quote_SubType__c' => 'Credit',
          'CWS_OF_Signed_Date__c'=>System.today(),
           'StartDate' => System.today(),
              //'EndDate' =>Date.today().addMonths(3),
              'SBQQ__RenewalForecast__c' => FALSE,
              'CWS_Renewal_Opportunity_Schedule__c' => Date.today().adddays(-2),
              'ContractTerm' => 2,
              'CWS_Renewal_Category__c' => 'Opt-In',
              'CWS_Renewable_Products__c' => 2
        };
        Contract cont = CWS_UTLDataFactory.createContract(acc.id, contAdditionalFieldValues, true);
        
        List<SBQQ__RecordJob__c> recordJobList=new List<SBQQ__RecordJob__c>();
        SBQQ__RecordJob__c recordJob1=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Queued', SBQQ__RecordId__c=cont.Id+'::RenewContract',
                                            SBQQ__JobDetails__c='');
        if(recordJob1!=null){
        insert recordJob1;
        }
           
        
        Map<Id,Contract> mapContracts = new map<Id,Contract>([SELECT Id,CWS_Renewal_Type__c, status from Contract]);
        System.assertEquals(FALSE, mapContracts.isEmpty());
        //System.assertEquals(CWS_ConstantClass.Renewal_Type_NonRenewable,lstContracts [0].CWS_Renewal_Type__c);
        List<Id> contractids = new List<Id>();
        contractids.addAll(mapContracts.keySet());
        Database.executeBatch(new CWS_RenewalBatch(contractids),1);
        Test.stopTest();
        
        List<Contract> lstContracts2 =[SELECT Id,CWS_Renewal_Type__c, SBQQ__RenewalForecast__c,SBQQ__RenewalQuoted__c, SBQQ__RenewalOpportunity__c,
                    SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c, status, ContractTerm, StartDate,EndDate, CWS_Renewal_Batch_Failed__c,
                    CWS_Renewal_CAP__c, CWS_Renewal_Uplift_Applicable__c from Contract];  
    }
    //BED-3402

    @isTest
    static void testSchedule(){
        Test.startTest();
        //CWS_RenewalEmailBatchScheduler sh1 = new CWS_RenewalEmailBatchScheduler();
        CWS_RenewalEmailBatchScheduler.run();
        /*CWS_RenewalEmailBatchScheduler sh1 = new CWS_RenewalEmailBatchScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, sh1); */
        Test.stopTest(); 
    }
    
    @isTest
    static void renewalSchedule(){
        Test.startTest();
		SchedulableContext sc = null;
        CWS_RenewalSchedule sh1 = new CWS_RenewalSchedule();
        sh1.execute(sc);          
        Test.stopTest(); 
    }
/*    @isTest
    static void testRenewalatch(){
        List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status from Contract];
        System.assertEquals(FALSE, lstContracts.isEmpty());
        System.assertEquals(CWS_ConstantClass.Renewal_Type_OptIn,lstContracts [0].CWS_Renewal_Type__c);
        
        lstContracts[0].status='Activated';
        lstContracts[0].StartDate=Date.today()-345;
        lstContracts[0].ContractTerm=12;
        lstContracts[0].CWS_Renewal_Opportunity_Schedule__c=Date.today()-110;
        lstContracts[0].CWS_Renewal_Quote_Schedule__c=Date.today()-20;        
        if(lstContracts!=null){
        update lstContracts[0];
        }
        
        List<Contract> lstContracts1 =[SELECT Id,CWS_Renewal_Type__c, status, ContractTerm, StartDate,EndDate, CWS_Renewal_Batch_Failed__c from Contract];
        system.debug(lstContracts1);
        
        Test.StartTest();
            Database.executeBatch(new CWS_RenewalBatch(),1);
        Test.stopTest();
        
        List<Contract> lstContracts2 =[SELECT Id,CWS_Renewal_Type__c, SBQQ__RenewalForecast__c,SBQQ__RenewalQuoted__c, SBQQ__RenewalOpportunity__c,
                    status, ContractTerm, StartDate,EndDate, CWS_Renewal_Batch_Failed__c from Contract]; 
        system.debug(lstContracts2);
        System.assertNotEquals(null,lstContracts2[0].SBQQ__RenewalOpportunity__c);
        
    }
    
    @isTest
    static void testRenewalBatchFailedRecords(){
        List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status from Contract];
        System.assertEquals(FALSE, lstContracts.isEmpty());
        System.assertEquals(CWS_ConstantClass.Renewal_Type_OptIn,lstContracts [0].CWS_Renewal_Type__c);
        
        lstContracts[0].status='Activated';
        lstContracts[0].StartDate=Date.today()-345;
        lstContracts[0].ContractTerm=12;
        lstContracts[0].CWS_Renewal_Opportunity_Schedule__c=Date.today()-110;
        lstContracts[0].CWS_Renewal_Quote_Schedule__c=Date.today()-20;        
        if(lstContracts!=null){
        update lstContracts[0];
        }
        
        List<Contract> lstContracts1 =[SELECT Id,CWS_Renewal_Type__c, status, ContractTerm, StartDate,EndDate, CWS_Renewal_Batch_Failed__c from Contract];
        system.debug(lstContracts1);
        List<SBQQ__RecordJob__c> recordJobList=new List<SBQQ__RecordJob__c>();
        SBQQ__RecordJob__c recordJob1=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Failed', SBQQ__RecordId__c=lstContracts1[0].Id+'::RenewContract',
                                            SBQQ__JobDetails__c='UNABLE_TO_LOCK_ROW');
        if(recordJob1!=null){
        insert recordJob1;
        }
                
        Test.StartTest();
            Database.executeBatch(new CWS_RenewalBatch(),1);
        Test.stopTest();
        List<Contract> contractList2=[Select Id, CWS_Renewal_Type__c, CWS_Renewal_Batch_Failed__c,
             SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c from Contract];
        system.assertEquals(false,contractList2[0].CWS_Renewal_Batch_Failed__c);
        system.assertEquals(false,contractList2[0].SBQQ__RenewalForecast__c);
        system.assertEquals(false,contractList2[0].SBQQ__RenewalQuoted__c);        
    }    
    
     @isTest
    static void testRenewalBatchQueuedRecords(){
        List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status from Contract];
        
        lstContracts[0].status='Activated';
        lstContracts[0].StartDate=Date.today()-345;
        lstContracts[0].ContractTerm=12;
        lstContracts[0].CWS_Renewal_Opportunity_Schedule__c=Date.today()-110;
        lstContracts[0].CWS_Renewal_Quote_Schedule__c=Date.today()-20;        
        if(lstContracts!=null){
        update lstContracts[0];
        }
        List<SBQQ__RecordJob__c> recordJobList=new List<SBQQ__RecordJob__c>();
        SBQQ__RecordJob__c recordJob1=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Queued', SBQQ__RecordId__c=lstContracts[0].Id+'::RenewContract',
                                            SBQQ__JobDetails__c='');
        if(recordJob1!=null){
        insert recordJob1;
        }
                
        Test.StartTest();
            Database.executeBatch(new CWS_RenewalBatch(),1);        
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;        
            String sch0 = '0 0 * * * ?'; System.schedule('Renew Contracts 0'+uniqueName ,sch0  , new CWS_RenewalSchedule() );
        Test.stopTest();
        List<CWS_Renewal_Batch_Status__c> lstRenewalStatus=[Select Id, Name from CWS_Renewal_Batch_Status__c where CWS_Processed__c=False Limit 10];
        system.assertEquals(false,lstRenewalStatus.isEmpty());
    }
    
    @isTest
    static void testRenewalBatchwithAccountId(){
        List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status, AccountId from Contract];
        
        lstContracts[0].status='Activated';
        lstContracts[0].StartDate=Date.today()-345;
        lstContracts[0].ContractTerm=12;
        lstContracts[0].CWS_Renewal_Opportunity_Schedule__c=Date.today()-110;
        lstContracts[0].CWS_Renewal_Quote_Schedule__c=Date.today()-20;        
        if(lstContracts!=null){
        update lstContracts[0];
        }
        
        List<SBQQ__RecordJob__c> recordJobList=new List<SBQQ__RecordJob__c>();
        SBQQ__RecordJob__c recordJob1=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Queued', SBQQ__RecordId__c=lstContracts[0].Id+'::RenewContract',
                                            SBQQ__JobDetails__c='');
        if(recordJob1!=null){
        insert recordJob1;
        }
                
        Test.StartTest();
            Database.executeBatch(new CWS_RenewalBatch(lstContracts[0].AccountId),1);
        Test.stopTest();
        List<Contract> contractList=[Select Id, Name, SBQQ__RenewalOpportunity__c, SBQQ__RenewalQUoted__c from Contract LIMIT 1];
        System.assertNotEquals(true,contractList.isEmpty());
        system.assertNotEquals(null, contractList[0].SBQQ__RenewalOpportunity__c);        
    }    
    @isTest
    static void testRenewalBatchwithContractId(){
        List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status, AccountId from Contract];
        
        lstContracts[0].status='Activated';
        lstContracts[0].StartDate=Date.today()-345;
        lstContracts[0].ContractTerm=12;
        lstContracts[0].CWS_Renewal_Opportunity_Schedule__c=Date.today()-110;
        lstContracts[0].CWS_Renewal_Quote_Schedule__c=Date.today()-20;        
        if(lstContracts!=null){
        update lstContracts[0];
        }
        List<SBQQ__RecordJob__c> recordJobList=new List<SBQQ__RecordJob__c>();
        SBQQ__RecordJob__c recordJob1=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Queued', SBQQ__RecordId__c=lstContracts[0].Id+'::RenewContract',
                                            SBQQ__JobDetails__c='');
        if(recordJob1!=null){
        insert recordJob1;
        }
                
        Test.StartTest();
            Database.executeBatch(new CWS_RenewalBatch(new List<Id> {lstContracts[0].Id}),1);
        Test.stopTest();
        List<Contract> contractList=[Select Id, Name, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,
                                        SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.CWS_Renewal_Type__c, SBQQ__RenewalQUoted__c from Contract];
        List<SBQQ__Quote__c> quoteList=[Select Id, Name, CWS_Renewal_Type__c from SBQQ__Quote__c where CWS_Quote_Type__c=:CWS_ConstantClass.QUOTE_TYPE_RENEWAL
            and CWS_Quote_Type__c!=null LIMIT 1];
        System.assertNotEquals(true,contractList.isEmpty());
        system.assertNotEquals(null, contractList[0].SBQQ__RenewalOpportunity__c);
        
    }
    
    @isTest
    static  void testScheduleRenewalBatch(){
        List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status from Contract];
        
        lstContracts[0].status='Activated';
        lstContracts[0].StartDate=Date.today()-345;
        lstContracts[0].ContractTerm=12;
        lstContracts[0].CWS_Renewal_Opportunity_Schedule__c=Date.today()-110;
        lstContracts[0].CWS_Renewal_Quote_Schedule__c=Date.today()-20;
        if(lstContracts!=null){
        update lstContracts[0];
        }
        List<SBQQ__RecordJob__c> recordJobList=new List<SBQQ__RecordJob__c>();
        SBQQ__RecordJob__c recordJob1=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Queued', SBQQ__RecordId__c=lstContracts[0].Id+'::RenewContract',
                                            SBQQ__JobDetails__c='');
        if(recordJob1!=null){
        insert recordJob1;
        }
                
        Test.StartTest();
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;        
            String sch0 = '0 0 * * * ?'; System.schedule('Renew Contracts 0'+uniqueName ,sch0  , new CWS_RenewalSchedule() );
        Test.stopTest();

        List<AsyncApexJob> batchApex = [select Id from AsyncApexJob where JobType = 'BatchApex' and JobType !=null Limit 1];
        System.assertEquals(1, batchApex.size());
    }
    
    @isTest
    static void testRenewalQuoteValues(){
        List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status, AccountId from Contract];
        
        lstContracts[0].status='Activated';
        lstContracts[0].StartDate=Date.today()-345;
        lstContracts[0].ContractTerm=12;
        lstContracts[0].CWS_Renewal_Opportunity_Schedule__c=Date.today()-110;
        lstContracts[0].CWS_Renewal_Quote_Schedule__c=Date.today()-20;       
        if(lstContracts!=null){ 
        update lstContracts[0];
        }
        
        Test.StartTest();
            Database.executeBatch(new CWS_RenewalBatch(new List<Id> {lstContracts[0].Id}),1);
        Test.stopTest();
        
        List<Contract> contractList=[Select Id, Name, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,
                                        SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.CWS_Renewal_Type__c, SBQQ__RenewalQUoted__c from Contract];
        List<SBQQ__Quote__c> quoteList=[Select Id, Name, CWS_Renewal_Type__c, CWS_Quote_Type__c,RecordTypeId, SBQQ__Status__c
                             from SBQQ__Quote__c where CWS_Quote_Type__c=:CWS_ConstantClass.QUOTE_TYPE_RENEWAL and CWS_Quote_Type__c!=null LIMIT 1];
        system.assertNotEquals(true,contractList.isEmpty());
        system.assertNotEquals(null, contractList[0].SBQQ__RenewalOpportunity__c);
        system.assertNotEquals(null, contractList[0].SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c);
        system.assertEquals(false,quoteList.isEmpty());
        system.assertEquals(CWS_ConstantClass.QUOTE_TYPE_RENEWAL,quoteList[0].CWS_Quote_Type__c);
        system.assertEquals(CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_RONLY, quoteList[0].RecordTypeId);
        quoteList[0].SBQQ__Status__c=CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN;
        if(quoteList!=null){
        update quoteList[0];
        }
        List<SBQQ__Quote__c> quoteupdated=[Select Id, Name, CWS_Renewal_Type__c, RecordTypeId, SBQQ__Status__c
                             from SBQQ__Quote__c where CWS_Quote_Type__c=:CWS_ConstantClass.QUOTE_TYPE_RENEWAL and CWS_Quote_Type__c!=null  LIMIT 1];
        system.assertEquals(CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_APPROVED_RONLY ,quoteupdated[0].RecordTypeId);
        
    }    */
}