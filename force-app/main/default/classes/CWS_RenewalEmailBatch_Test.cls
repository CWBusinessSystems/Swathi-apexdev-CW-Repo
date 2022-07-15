/*Class Name: CWS_RenewalEmailBatch_Test
*Description: Test Class for CWS_RenewalEmailBatch
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_RenewalEmailBatch_Test{
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
                    'CWS_Is_Distributor__c' => true};
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
                            'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12   
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
    static void testRenewalbatch1(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        
        Account acc = [SELECT ID,CWS_Is_Distributor__c from Account where Name ='TestAccount' Limit 1];
        Contact con =[SELECT ID from contact limit 1];
        if(acc != null){
            acc.CWS_Is_Distributor__c = true;
            update acc;
        }
        //Opportunity opp = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        //existingContracts[0].Enddate = Date.today().addmonths(2);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].startdate = date.today().addDays(-260);
        existingContracts[0].ContractTerm = 36;
        existingContracts[0].CWS_Renewal_Category__c = 'Opt-In';
        existingContracts[0].SBQQ__RenewalQuoted__c = false;
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        Opportunity renOpportunity=new Opportunity(id=updatedContracts[0].SBQQ__RenewalOpportunity__c, 
                                                   SBQQ__RenewedContract__c=updatedContracts[0].Id);
        update renOpportunity;
        system.debug('updatedContracts--'+updatedContracts); 
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Direct',
                'CurrencyIsoCode'=>'EUR',
                'CWS_Quote_Type__c'=> CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                };                    
                    system.debug('before - quote--');
        SBQQ__Quote__c quote1 = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
        Test.startTest();
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
    }
    
    @isTest
    static void testRenewalbatch2(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c,CurrencyIsoCode  from contract];
        
        Account acc = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        Contact con = [SELECT ID from contact limit 1];
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
        existingContracts[0].startDate=Date.today().addDays(-260);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 10;
        existingContracts[0].CurrencyIsoCode='GBP';
        existingContracts[0].CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptOut;
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        system.debug('updatedContracts--'+updatedContracts); 
        Opportunity renOpportunity=new Opportunity(id=updatedContracts[0].SBQQ__RenewalOpportunity__c, 
                                                   SBQQ__RenewedContract__c=updatedContracts[0].Id);
        update renOpportunity;        
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Direct',
                'CurrencyIsoCode'=>'EUR',
                'CWS_Quote_Type__c'=> CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                };                    
                    system.debug('before - quote--');
        SBQQ__Quote__c quote1 = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
        System.assertNotEquals(null,quote1.id);
        
    }
    
    @isTest
    static void testRenewalbatch3(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        Contact con =[SELECT ID from contact limit 1];
        if(acc != null){
            acc.CWS_Is_Distributor__c = true;
            acc.CWS_Account_Restriction_Status__c=CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT;
            update acc;
        }
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id, 'CWS_Bill_To_Contact__c'=>con.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        //existingContracts[0].Enddate = Date.today().addmonths(2);
        existingContracts[0].startDate=Date.today().addDays(-299);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 12;
        existingContracts[0].CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptIn;
        update existingContracts[0];
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        Test.startTest();
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
        System.assertNotEquals(null,existingContracts[0].CWS_Renewal_Category__c);
    }
    
    @isTest
    static void testRenewalbatch4(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        
        Account acc = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        Contact con = [SELECT ID from contact limit 1];
        //Opportunity opp = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id, 'CWS_Bill_To_Contact__c'=>con.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-299);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 12;
        existingContracts[0].CWS_Renewal_Category__c = 'Opt-In';
        existingContracts[0].CurrencyIsoCode='GBP';
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        system.debug('updatedContracts--'+updatedContracts); 
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Channel',
                'CurrencyIsoCode'=>'EUR',
                'CWS_Quote_Type__c'=> CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                };                    
                    system.debug('before - quote--');
        //SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
        Test.startTest();
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
    }
    
    @isTest
    static void testRenewalbatch5(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c,CurrencyIsoCode  from contract];
        CWS_Distributor_Reseller__c drs = [Select id,CWS_Account__c,CWS_Distributor_ResellerAcc__c from CWS_Distributor_Reseller__c Limit 1];
        Id accId = drs.CWS_Account__c; //[SELECT ID from Account where Name ='TestAccount' Limit 1];
        
        Contact con = [SELECT ID from contact limit 1];
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
                'CWS_Primary_Contact__c' => true,
                'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                'Email'=>'test2@test.com'
                };
                    Contact objCon = CWS_UTLDataFactory.createContact('TestName','LastName', drs.CWS_Distributor_ResellerAcc__c,mapConFieldValues,true); 
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> drs.CWS_Distributor_ResellerAcc__c,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,
                'CWS_Sold_To_Contact__c' =>con.Id,
                'CWS_Bill_To_Contact__c' =>objCon.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',accId, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-290);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 10;
        existingContracts[0].CWS_Renewal_Category__c = 'Opt-In';
        existingContracts[0].CurrencyIsoCode='GBP';
        update existingContracts[0];
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        
        
        Map<String, Object> quoteFields=new Map<String,Object>{
            'CWS_Quote_Type__c'=>'Renewal', 
                'CWS_Bill_to_Account__c'=> drs.CWS_Distributor_ResellerAcc__c,
                'CWS_Agreement_Numbers__c'=> 'ABC123456',
                'CWS_Route_to_Market__c'=>'Channel'             
                };
                    SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(drs.CWS_Account__c,opp.Id, quoteFields, false);        
        
        Product2 prod = [SELECT ID,CWS_License_Type__c from product2 limit 1];
        Test.startTest();
        createQuoteAndQL cql = new createQuoteAndQL(quote,prod.ID);
        System.enqueueJob(cql);
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
        System.assertNotEquals(null,opp.id);
    }
        @isTest
     static void testRenewalbatch6(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        Contact con =[SELECT ID from contact limit 1];
        if(acc != null){
            acc.CWS_Is_Distributor__c = true;
            update acc;
        }
        //Opportunity opp = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id, 'CWS_Bill_To_Contact__c'=>con.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-290);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 10;
        existingContracts[0].CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptOut;
        existingContracts[0].CurrencyIsoCode='GBP';
        update existingContracts[0];                   
        Test.startTest();
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
        System.assertNotEquals(true,opp.CWS_Master__c);
    }
    @isTest
     static void testRenewalbatch7(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        Contact con =[SELECT ID from contact limit 1];
        if(acc != null){
            acc.CWS_Is_Distributor__c = true;
            update acc;
        }
         product2 prod1=[select id,CWS_License_Type__c from product2 where name='TestProduct1' limit 1];
         prod1.CWS_License_Type__c = CWS_ConstantClass.strPerpOnly; 
         update prod1;
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id, 'CWS_Bill_To_Contact__c'=>con.Id
                };
                    
        Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        //existingContracts[0].Enddate = Date.today().addmonths(2);
        existingContracts[0].startDate=Date.today().addDays(-290);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 10;
        existingContracts[0].CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptOut;
        update existingContracts[0];  
        Test.startTest();
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
        System.assertNotEquals(true,existingContracts[0].CWS_Master__c);
         
    }
    @isTest
     static void testRenewalbatch8(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        Contact con =[SELECT ID from contact limit 1];
        if(acc != null){
            acc.CWS_Is_Distributor__c = true;
            acc.CWS_Account_Restriction_Status__c=CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT;
            update acc;
        }
        //Opportunity opp = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        //product.CWS_License_Type__c = CWS_ConstantClass.strPerpOnly;
         product2 prod1=[select id,CWS_License_Type__c from product2 where name='TestProduct1' limit 1];
         prod1.CWS_Status__c = CWS_ConstantClass.StrBillingonly;
         update prod1;
        SBQQ__Quote__c quote = [SELECT Id From SBQQ__Quote__c LIMIT 1];        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id, 'CWS_Bill_To_Contact__c'=>con.Id
                };
                    
        Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-260);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 10;
        existingContracts[0].CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptOut;
        existingContracts[0].CurrencyIsoCode='GBP';
        update existingContracts[0];
         
        Test.startTest();
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
        System.assertNotEquals(null,existingContracts[0].CWS_Renewal_Category__c);
    }
    @isTest
    static void testRenewalbatch9(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        if(acc != null){
            acc.CWS_Account_Restriction_Status__c=CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT;
            update acc;
        }
        Contact con = [SELECT ID from contact limit 1];
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
                'CWS_Primary_Contact__c' => true,
                'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                'Email'=>'test2@test.com'
                };
                    Contact objCon = CWS_UTLDataFactory.createContact('TestName','LastName', acc.id,mapConFieldValues,true); 
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,
                'CWS_Sold_To_Contact__c' =>con.Id,
                'CWS_Bill_To_Contact__c' =>objCon.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-260);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 12;
        existingContracts[0].CWS_Renewal_Category__c = 'Opt-In';
        existingContracts[0].CurrencyIsoCode='GBP';
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        
        
        Map<String, Object> quoteFields=new Map<String,Object>{
            'CWS_Quote_Type__c'=>'Renewal', 
                'CWS_Bill_to_Account__c'=> acc.id,
                'CWS_Agreement_Numbers__c'=> 'ABC123456',
                'CWS_Route_to_Market__c'=>'Channel'             
                };
                    SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acc.id,opp.Id, quoteFields, false);        
        
        Product2 prod = [SELECT ID,CWS_License_Type__c from product2 limit 1];
        prod.CWS_License_Type__c = CWS_ConstantClass.strPerpOnly;   
        update prod;
        Test.startTest();
        createQuoteAndQL cql = new createQuoteAndQL(quote,prod.ID);
        System.enqueueJob(cql);
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
    }
     @isTest
    static void testRenewalbatch10(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        if(acc != null){
            acc.CWS_Account_Restriction_Status__c=CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT;
            update acc;
        }
        CWS_Distributor_Reseller__c drs = [Select id,CWS_Account__c,CWS_Distributor_ResellerAcc__c from CWS_Distributor_Reseller__c Limit 1];
        Id accId = drs.CWS_Account__c; //[SELECT ID from Account where Name ='TestAccount' Limit 1];
        Contact con = [SELECT ID from contact limit 1];
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
                'CWS_Primary_Contact__c' => true,
                'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                'Email'=>'test2@test.com'
                };
                    Contact objCon = CWS_UTLDataFactory.createContact('TestName','LastName', drs.CWS_Distributor_ResellerAcc__c,mapConFieldValues,true); 
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> drs.CWS_Distributor_ResellerAcc__c,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,
                'CWS_Sold_To_Contact__c' =>con.Id,
                'CWS_Bill_To_Contact__c' =>objCon.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',accId, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-260);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 12;
        existingContracts[0].CWS_Renewal_Category__c = 'Opt-In';
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        
        
        Map<String, Object> quoteFields=new Map<String,Object>{
            'CWS_Quote_Type__c'=>'Renewal', 
                'CWS_Bill_to_Account__c'=> drs.CWS_Distributor_ResellerAcc__c,
                'CWS_Agreement_Numbers__c'=> 'ABC123456',
                'CWS_Route_to_Market__c'=>'Channel'             
                };
                    SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(drs.CWS_Account__c,opp.Id, quoteFields, false);        
        
        Product2 prod = [SELECT ID,CWS_License_Type__c,CWS_Status__c from product2 limit 1];
        prod.CWS_Status__c = CWS_ConstantClass.StrBillingonly;
        prod.CWS_License_Type__c = CWS_ConstantClass.strPerpOnly;  
        update prod;
        Test.startTest();
        createQuoteAndQL cql = new createQuoteAndQL(quote,prod.ID);
        System.enqueueJob(cql);
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
    }
    @isTest
    static void testRenewalbatch11(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        if(acc != null){
            acc.CWS_Account_Restriction_Status__c=CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT;
            update acc;
        }
        //Id accId = drs.CWS_Account__c; //[SELECT ID from Account where Name ='TestAccount' Limit 1];
        Contact con = [SELECT ID from contact limit 1];
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
                'CWS_Primary_Contact__c' => true,
                'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                'Email'=>'test2@test.com'
                };
                    Contact objCon = CWS_UTLDataFactory.createContact('TestName','LastName', acc.id,mapConFieldValues,true); 
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,
                'CWS_Sold_To_Contact__c' =>con.Id,
                'CWS_Bill_To_Contact__c' =>objCon.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-260);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 12;
        existingContracts[0].CWS_Renewal_Category__c = 'Opt-In';
        existingContracts[0].CurrencyIsoCode='GBP';
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        
        
        Map<String, Object> quoteFields=new Map<String,Object>{
            'CWS_Quote_Type__c'=>'Renewal', 
                'CWS_Bill_to_Account__c'=> acc.id,
                'CWS_Agreement_Numbers__c'=> 'ABC123456',
                'CWS_Route_to_Market__c'=>'Channel'             
                };
                    SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acc.id,opp.Id, quoteFields, false);        
        
        Product2 prod = [SELECT ID,CWS_License_Type__c,CWS_Status__c from product2 limit 1];
        prod.CWS_Status__c = CWS_ConstantClass.StrBillingonly;
        prod.CWS_Renewal_Uplift__c=5;
        update prod;
        Test.startTest();
        createQuoteAndQL cql = new createQuoteAndQL(quote,prod.ID);
        System.enqueueJob(cql);
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
    }
     @isTest
    static void testRenewalbatch12(){
        List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        Contact con =[SELECT ID from contact limit 1];
        //Opportunity opp = [SELECT ID from Account where Name ='TestAccount' Limit 1];
        SBQQ__Quote__c quote = [SELECT Id,CWS_Renewal_Attention_Needed__c From SBQQ__Quote__c LIMIT 1];
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,'SBQQ__PrimaryQuote__c' => quote.Id,
                'CWS_Sold_To_Contact__c' =>con.Id, 'CWS_Bill_To_Contact__c'=>con.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-260);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = false;
        existingContracts[0].ContractTerm = 10;
        existingContracts[0].CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptIn;
        existingContracts[0].CurrencyIsoCode='GBP';
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        system.debug('updatedContracts--'+updatedContracts); 
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Channel',
                'CurrencyIsoCode'=>'EUR',
                'CWS_Quote_Type__c'=> CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                };                    
                    system.debug('before - quote--');
        //SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
        Test.startTest();
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
        System.assertNotEquals(null,quote.id);
    }
    @isTest
    static void testRenewalbatch13(){
    List<Contract> existingContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                           EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                           CWS_Master__c,CWS_Renewable_Products__c,CWS_Renewal_Type__c  from contract];
        system.debug('existingContracts--'+existingContracts);
        Account acc = [SELECT ID,CWS_Is_Distributor__c,CWS_Account_Restriction_Status__c from Account where Name ='TestAccount' Limit 1];
        if(acc != null){
            acc.CWS_Account_Restriction_Status__c=CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT;
            update acc;
        }
        Contact con = [SELECT ID from contact limit 1];
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
                'CWS_Primary_Contact__c' => true,
                'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                'Email'=>'test2@test.com'
                };
                    Contact objCon = CWS_UTLDataFactory.createContact('TestName','LastName', acc.id,mapConFieldValues,true); 
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.id,
                'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => existingContracts[0].Id,
                'CWS_Sold_To_Contact__c' =>con.Id,
                'CWS_Bill_To_Contact__c' =>objCon.Id
                };
                    
                    Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.id, opportunityFields, true);  
        
        existingContracts[0].CWS_Renewal_Type__c = '';
        existingContracts[0].CWS_Renewable_Products__c =2;
        existingContracts[0].startDate=Date.today().addDays(-260);
        existingContracts[0].SBQQ__RenewalOpportunity__c = opp.ID;
        existingContracts[0].SBQQ__RenewalForecast__c = true;
        existingContracts[0].CWS_Master__c = true;
        existingContracts[0].ContractTerm = 12;
        existingContracts[0].CWS_Renewal_Category__c = 'Opt-Out';
        update existingContracts[0];
        system.debug('after contr upt--');
        
        List<Contract> updatedContracts =[SELECT ID,CWS_Days_Remaining__c ,SBQQ__RenewalOpportunity__c ,
                                          EndDate ,SBQQ__RenewalForecast__c,ContractTerm,
                                          CWS_Master__c  from contract ];
        
        
        Map<String, Object> quoteFields=new Map<String,Object>{
            'CWS_Quote_Type__c'=>'Renewal', 
                'CWS_Bill_to_Account__c'=> acc.id,
                'CWS_Agreement_Numbers__c'=> 'ABC123456',
                'CWS_Route_to_Market__c'=>'Channel'             
                };
                    SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acc.id,opp.Id, quoteFields, false);        
        
        Product2 prod = [SELECT ID,CWS_License_Type__c,CWS_Status__c from product2 limit 1];
        Test.startTest();
        createQuoteAndQL cql = new createQuoteAndQL(quote,prod.ID);
        System.enqueueJob(cql);
        Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        Test.stopTest();
    }
    //Class for enhancing limits
    public class createQuoteAndQL implements Queueable{
        private SBQQ__Quote__c quote;
        private Id ProdId;
        public createQuoteAndQL(SBQQ__Quote__c quote,Id ProdId){
            this.quote = quote;
            this.ProdId = ProdId;     
        }
        public void execute(QueueableContext context){  
            
            Insert quote;
            
            List<SBQQ__QuoteLine__c> quoteLine11 = CWS_UTLDataFactory.createQuoteLines(1, quote.Id, ProdId);
            //quoteLine11[0].SBQQ__PricebookEntryId__c = pbe.id;
            quoteLine11[0].CWS_Base_SKU__c = '900901';
            quoteLine11[0].CWS_Custom_sow__c =true;
            insert quoteline11[0];
            
            Database.executeBatch(new CWS_RenewalEmailBatch(),1);
        }
        
    }
    
}