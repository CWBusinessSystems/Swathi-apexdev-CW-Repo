/**
* Description  : Renewal Notification Batch : 75 days 
* User Story   : Service Ticket #14292767 
**/ 
@isTest
public class CWS_75daysRenewalReminderEmailsBatchTest {
	@testSetup
    static void createTestData(){
        //Create Sold To Account
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
        list<CWS_Currency_Legal_Entity_Mapping__mdt> lstCLEMapping=[Select label,DeveloperName,CWS_Legal_Entity__c from CWS_Currency_Legal_Entity_Mapping__mdt];
        //Run as Admin
        System.runas(admin){          
            //create custom setting data
            // CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','SBQQ__Quote__c', 'CWS_RenewalJobStatusCheck__c'});
            Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
                'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                    'currencyIsoCode'=>'EUR',
                    'CWS_Additional_Emails_for_Invoice__c'=>'test@gmail.com,test2@gmail.com',
                    'CWS_Is_Distributor__c' => true,
                    'CWS_Additional_Emails_for_Invoice__c' => 'test@gmail.com,testnew@gmail.com'};
                        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
            
            //Creating Contact for the Account
            Map<String, Object> mapConFieldValues = new Map<String, Object>{
                'CWS_Primary_Billing_Contact__c' => true,
                    'CWS_Primary_Contact__c' => true,
                    'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                    'Email'=>'test@test.com'
                    };
                        Contact objCon = CWS_UTLDataFactory.createContact('TestFirstName','TestLastName',soldtoaccount.Id,mapConFieldValues,true);  
            
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
                'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
                    'Type'=>'New','CurrencyIsoCode'=>'EUR'
                    };
                        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,false);
            opty.CurrencyIsoCode='EUR';
            if(opty!=null){
                insert opty;
            }
            
            Map<String, Object> quoteFields2=new Map<String,Object>{
                'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS ,
                    'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Channel',
                    'SBQQ__Distributor__c'=>distiAccounts[0].Id, 'CWS_Bill_to_Account__c'=> distiAccounts[0].Id,
                    'CWS_Renewal_Type__c'=> 'Non-Renewable',
                    'SBQQ__StartDate__c'=>Date.today()-260, 'SBQQ__SubscriptionTerm__c'=>12,
                    'CWS_Renewal_CAP__c'=>10, 'CWS_Renewal_Uplift_Applicable__c'=>2
                    };
                        
                        Map<String, Object> productFields=new Map<String, Object>{
                            'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12, 'CWS_Source__c' =>'CMS'
                                };
            Product2 product=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,false);
            product.SBQQ__SubscriptionType__c='Renewable';
            product.SBQQ__SubscriptionBase__c='List';
            product.CWS_Renewal_Uplift__c=5;
            if(product!=null){
                insert product;
            }
            Test.startTest();
                PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product.Id,1000.00,'EUR', true);
                SBQQ__Quote__c quote2=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields2, false); 
                quote2.SBQQ__PricebookId__c=Test.getStandardPricebookId();
                quote2.CurrencyIsoCode='EUR';
                if(quote2!=null){
                    insert quote2;
                }
                
                List<SBQQ__QuoteLine__c> quoteLineItem = CWS_UTLDataFactory.createQuoteLines(1, quote2.Id, product.Id);
                quoteLineItem[0].SBQQ__PricebookEntryId__c = pbe.id;
                quoteLineItem[0].SBQQ__StartDate__c=Date.today();
                quoteLineItem[0].SBQQ__SubscriptionPricing__c='Fixed Price';
                quoteLineItem[0].SBQQ__SubscriptionTerm__c= 1;
                if(quoteLineItem!=null){
                    insert quoteLineItem;
                }
                system.debug(quoteLineItem[0].CWS_ACVLine__c);
                List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)Database.query('Select Id, Name,CWS_Renewal_Type__c,SBQQ__StartDate__c, SBQQ__EndDate__c,SBQQ__Ordered__c,SBQQ__PricebookId__c,SBQQ__PriceBook__c,CWS_Quote_ACV__c from SBQQ__Quote__c');
                quoteList[0].SBQQ__Ordered__c=true;
                if(quoteList!=null){
                    update quoteList;
                }
                system.debug(quoteList[0]);      
                List<order> orderList=(List<order>)Database.query('Select Id,SBQQ__Contracted__c from order');
                System.debug(orderList);
                orderList[0].Pricebook2Id=Test.getStandardPricebookId();
                orderList[0].CWS_ServicesProvisioned__c = true;
                orderList[0].Status ='Activated';
                orderList[0].SBQQ__Contracted__c = true;
                orderList[0].CWS_ZuoraSubscriptionNumber__c = 'abc1234';        
                if(orderList!=null){
                    update  orderList;
                }
                
                list<OrderItem> lstOLI =(List<OrderItem>)Database.query('select id,SBQQ__Activated__c from OrderItem');
                System.debug(lstOLI);
                lstOLI[0].SBQQ__Activated__c = true;
                lstOLI[0].CWS_ProvisioningDate__c=Date.Today();
                if(lstOLI!=null){
                    update lstOLI;
                }
                
                
                orderList[0].SBQQ__Contracted__c=true;
                if(orderList!=null){
                    update orderList;
                }
            Test.StopTest();
        }
    }
    //BED-3402
    
    @isTest
    static void testRenewalbatch_CMS_OptOut(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Additional_Emails_for_Invoice__c from Account where Name ='TestAccount' Limit 1];
        
        Contact con =[SELECT ID from contact limit 1];
        if(acc != null){
            acc.CWS_Is_Distributor__c = true;
            update acc;
        }
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id
                };
                    
        Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  
        //opp.Type = 'Renewal';
        //update opp;
        Test.startTest();
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = true;
        existingContracts[0].startdate = Date.newInstance(2020, 09, 1);
        existingContracts[0].ContractTerm = 12;
        existingContracts[0].CWS_Renewal_Category__c = 'Opt-Out';
        existingContracts[0].CWS_Bill_To_Account__c = acc.id;
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        Opportunity renOpportunity=new Opportunity(id=updatedContracts[0].SBQQ__RenewalOpportunity__c, type='Renewal',
                                                   SBQQ__RenewedContract__c=updatedContracts[0].Id);
        update renOpportunity;
        SBQQ__Subscription__c Subs1 = new SBQQ__Subscription__c();      
        Subs1.SBQQ__Contract__c = existingContracts[0].id;
        Subs1.SBQQ__Account__c = acc.Id;
        Subs1.SBQQ__Product__c = [SELECT id FROM Product2 WHERE Name='TestProduct1' LIMIT 1].Id;
        Subs1.SBQQ__QuoteLine__c = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1].Id;            
        Subs1.SBQQ__Quantity__c = 1;
        insert Subs1;      
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Direct',
                'CurrencyIsoCode'=>'EUR',
                'CWS_Quote_Type__c'=> CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                };
        SBQQ__Quote__c quote1 = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
        
        Database.executeBatch(new CWS_75daysRenewalReminderEmailsBatch(),1);
        Test.stopTest();
    }
    
    @isTest
    static void testRenewalbatch_CW_OptOut(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Additional_Emails_for_Invoice__c from Account where Name ='TestAccount' Limit 1];
        Contact con =[SELECT ID from contact limit 1];
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id
                };
                    
        Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  

        Test.startTest();
            existingContracts[0].CWS_Renewal_Type__c = '';
            existingContracts[0].CWS_Renewable_Products__c =2;
            existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
            existingContracts[0].SBQQ__RenewalForecast__c = true;
            existingContracts[0].CWS_Master__c = true;
            existingContracts[0].startdate = Date.newInstance(2020, 09, 1);
            existingContracts[0].ContractTerm = 12;
            existingContracts[0].CWS_Renewal_Category__c = 'Opt-Out';
            existingContracts[0].CWS_Bill_To_Account__c = acc.id;
            update existingContracts[0];
            
            List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                              SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c,
                                              EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                              CWS_Master__c  from contract ];
            Opportunity renOpportunity=new Opportunity(id=updatedContracts[0].SBQQ__RenewalOpportunity__c, type='Renewal',
                                                       SBQQ__RenewedContract__c=updatedContracts[0].Id);
            update renOpportunity;
        
            Product2 prod = [SELECT id, CWS_Source__c FROM Product2 WHERE Name='TestProduct1' LIMIT 1];
            prod.CWS_Source__c = 'CW';
            update prod;
        
        
            SBQQ__Subscription__c Subs1 = new SBQQ__Subscription__c();      
            Subs1.SBQQ__Contract__c = existingContracts[0].id;
            Subs1.SBQQ__Account__c = acc.Id;
            Subs1.SBQQ__Product__c = prod.Id;
            Subs1.SBQQ__QuoteLine__c = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1].Id;            
            Subs1.SBQQ__Quantity__c = 1;
            insert Subs1;   
        
            Database.executeBatch(new CWS_75daysRenewalReminderEmailsBatch(),1);
        Test.stopTest();
    }
    
    @isTest
    static void testRenewalbatch_CW_OptIn(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Additional_Emails_for_Invoice__c from Account where Name ='TestAccount' Limit 1];
        Contact con =[SELECT ID from contact limit 1];
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id
                };
                    
        Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  

        Test.startTest();
            existingContracts[0].CWS_Renewal_Type__c = '';
            existingContracts[0].CWS_Renewable_Products__c =2;
            existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
            existingContracts[0].SBQQ__RenewalForecast__c = true;
            existingContracts[0].CWS_Master__c = true;
            existingContracts[0].startdate = Date.newInstance(2020, 09, 1);
            existingContracts[0].ContractTerm = 12;
            existingContracts[0].CWS_Renewal_Category__c = 'Opt-In';
            existingContracts[0].CWS_Bill_To_Account__c = acc.id;
            update existingContracts[0];
            
            List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                              SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c,
                                              EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                              CWS_Master__c  from contract ];
            Opportunity renOpportunity=new Opportunity(id=updatedContracts[0].SBQQ__RenewalOpportunity__c, type=CWS_ConstantClass.Opportunity_Type_RenewalWithChange,
                                                       SBQQ__RenewedContract__c=updatedContracts[0].Id);
            update renOpportunity;
        
            Product2 prod = [SELECT id, CWS_Source__c FROM Product2 WHERE Name='TestProduct1' LIMIT 1];
            prod.CWS_Source__c = 'CW';
            update prod;
        
        
            SBQQ__Subscription__c Subs1 = new SBQQ__Subscription__c();      
            Subs1.SBQQ__Contract__c = existingContracts[0].id;
            Subs1.SBQQ__Account__c = acc.Id;
            Subs1.SBQQ__Product__c = prod.Id;
            Subs1.SBQQ__QuoteLine__c = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1].Id;            
            Subs1.SBQQ__Quantity__c = 1;
            insert Subs1;   
        	CWS_75daysRenewalReminderEmailsBatch batchInst = new CWS_75daysRenewalReminderEmailsBatch();
        	batchInst.finalCsv = 'Demo Test Run';
            Database.executeBatch(batchInst,1);
        	CWS_75daysRenewalReminderEmailsSchedular myClass = new CWS_75daysRenewalReminderEmailsSchedular ();   
             String chron = '0 0 23 * * ?';        
             system.schedule('Test Sched', chron, myClass);
        
        Test.stopTest();
    }
}