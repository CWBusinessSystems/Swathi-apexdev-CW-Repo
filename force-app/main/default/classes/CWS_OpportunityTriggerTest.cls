/*Class Name: CWS_OpportunityTriggerTest
*Description: Test Class for CWS_OpportunityTriggerHelper
*Created By: Gautam
*Created On: 16/1/2022
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date             User Story              Description
*------------------------------------------------------------------------------------------
*Gautam               16/01/2022         OBD-3169           Refactored test class for opportunity trigger 

*/
@isTest
public class CWS_OpportunityTriggerTest {

    @testSetup 
    static void createTestData(){
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account', 'Opportunity','Quote'});
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        Pricebook2 connectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
        if(connectwisePricebook!=null){
            insert connectwisePricebook;
        }
        Map<String,Object> additionalFields = new Map<String, Object>{
                                                                        'SBQQ__BillingType__c' => 'Advance',
                                                                        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
                                                                        'SBQQ__SubscriptionTerm__c' => 12,
                                                                        'CWS_Description__c' => 'Test',
                                                                        'SBQQ__PricingMethod__c' => 'List'  
                                                                    };
            Product2 prod = CWS_UTLDataFactory.createProduct(CWS_ConstantClass.Minimum_Commit_Prod , 'TRDF', additionalFields, false);
            prod.CWS_Category__c = 'Automate';
            prod.CWS_EF_Attribute__c = 'Service';
            prod.IsActive = true;
            prod.CWS_Base_SKU__c = '900901';
            upsert prod;  

            List<String> currencyCode = new List<String>{'USD','CAD','EUR'};
            List<Pricebookentry> pbeList = CWS_UTLDataFactory.createPBEList(standardPricebook.Id, prod.Id, 100 ,currencyCode);
            List<Pricebookentry> pbeList1 = CWS_UTLDataFactory.createPBEList(ConnectwisePricebook.Id, prod.Id, 100 ,currencyCode);
            pbeList.addAll(pbeList1);
            if(pbeList.size()>0){
                insert pbeList;
            }
       
            CWS_Economic_Factor__c ecofac = new CWS_Economic_Factor__c();
            ecofac.CWS_Category__c = 'Automate';
            ecofac.CWS_Product_Type__c = 'Service';
            ecofac.CWS_Economic_Factor__c = 1.2;
            ecofac.CurrencyISOCode = 'EUR';
            insert ecofac;
       
            Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
                                                                                    'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                                                                                    'currencyIsoCode'=>'EUR',            
                                                                                    'CWS_Purchase_Order_Required__c'=>'Yes'
                                                                                };
            Account acc = CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues, true);
            Map<String, Object> mapConFieldValues = new Map<String, Object>{
                                                                                'CWS_Primary_Billing_Contact__c' => true,
                                                                                'CWS_Primary_Contact__c' => true,
                                                                                'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                                                                                'Email'=>'test@test.com'
                                                                            };
            Contact objCon = CWS_UTLDataFactory.createContact('TestFirstName','TestLastName',acc.Id,mapConFieldValues,true);
            Map<String, Object> contractadditionalFieldValues=new Map<String, Object>{
                                                                                        'CurrencyISOCode' => 'CAD',
                                                                                        'CWS_Master__c' => true               
                                                                                    };
            Contract con = CWS_UTLDataFactory.createContract(acc.Id, contractadditionalFieldValues, true);
         Test.startTest();
            CWS_OpportunityTriggerHandler.BEFORE_INSERT_EXECUTED = true;
            CWS_OpportunityTriggerHandler.BEFORE_UPDATE_EXECUTED = true;
            CWS_OpportunityTriggerHandler.AFTER_UPDATE_EXECUTED = true;
            CWS_OpportunityTriggerHandler.AFTER_INSERT_EXECUTED = true;
                Map<String, Object> opportunityFields=new Map<String, Object>{
                    'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                    'Type'=>'New','CurrencyIsoCode'=>'USD'
                };
            
                Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, false);
                opp.CurrencyISOCode = 'EUR';
                insert opp;
                Map<String, Object> additionalFieldValues = new Map<String, Object>();
                PricebookEntry pbeValue = [SELECT Id FROM Pricebookentry 
                                           WHERE CurrencyISOCode = 'EUR' 
                                           AND Pricebook2.Name =:CWS_ConstantClass.CONNECTWISE_PRICEBOOK];
                CWS_QuoteTriggerHandler.BEFORE_INSERT_EXECUTED = TRUE;
                CWS_QuoteTriggerHandler.AFTER_INSERT_EXECUTED = TRUE;
                CWS_QuoteTriggerHandler.AFTER_UPDATE_EXECUTED = TRUE;
                CWS_QuoteTriggerHandler.BEFORE_UPDATE_EXECUTED = TRUE;
                SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
                quote.CWS_Bill_To_Account__c = acc.Id;
                quote.CWS_Bill_To_Contact__c = objCon.Id;
                update quote;
        
                List<SBQQ__QuoteLine__c> quoteLine = CWS_UTLDataFactory.createQuoteLines(1 , quote.Id, prod.Id);
                quoteLine[0].SBQQ__PricebookEntryId__c = pbeValue.Id;
                quoteLine[0].CWS_EF_Attribute__c = 'Service';
                quoteLine[0].CWS_Category__c = 'Automate';
                quoteLine[0].CurrencyISOCode = 'EUR';
                insert quoteLine;
               
               /* OpportunityLineItem oppProd = new OpportunityLineItem();
                oppProd.OpportunityId       = opp.Id;
                oppProd.Quantity            = 1;
                oppProd.Product2Id          = prod.Id;
                oppProd.PricebookEntryId    = pbeValue.Id;
                oppProd.SBQQ__QuoteLine__c  = quoteline[0].Id;
                oppProd.TotalPrice          = 100;
                insert oppProd;*/
        
                Account soldToAcc           = acc;
                soldToAcc.BillingCountry    = 'France';
                soldToAcc.BillingStreet     = 'France Street';
                soldToAcc.BillingCity       = 'paris';
                soldToAcc.BillingPostalCode = '121212';
                update soldToAcc;
                
                Map<String, Object> soldToAccountFieldValuesEUR = new Map<String, Object>{            
                                                                                            'currencyIsoCode'=>'EUR',
                                                                                            'CWS_Distributor_Logic_Exclusion__c' => true,
                                                                                            'CWS_Is_Distributor__c' => true,
                                                                                            'BillingCountry' => 'France',
                                                                                            'BillingStreet' => 'France Street',
                                                                                            'BillingCity' => 'paris',
                                                                                            'BillingPostalCode' => '121212'
                                                                                            };
                Account billToAcc1 =CWS_UTLDataFactory.createAccount('BillToAcc1', soldToAccountFieldValuesEUR,false);
                Account billToAcc2 =CWS_UTLDataFactory.createAccount('BillToAcc2', soldToAccountFieldValuesEUR,false);
                List<Account> accs = new List<Account>();
                accs.add(billToAcc1);
                accs.add(billToAcc2);
                Insert accs;
            Test.stopTest(); 
    }

    @isTest 
    static void testForBeforeLogic(){ 
        Test.startTest();
            List<Account> accTest = [SELECT Id, CurrencyISOCode FROM Account];
            Contact objCon = [SELECT id FROM Contact LIMIT 1];
            List<Contract> conTest = [SELECT Id, currencyISOCode FROM Contract]; 
            List<SBQQ__Quote__c> quoteTest = [SELECT Id, CurrencyISOCode, SBQQ__status__c FROM SBQQ__Quote__c Order BY Name ASC];

        
            List<Opportunity> oppTest         = [SELECT Id, CurrencyISOCode, Name FROM Opportunity Order BY Name ASC]; 
            oppTest[0].CWS_Bill_To_Account__c = null;
            oppTest[0].CWS_Bill_To_Contact__c = null;
            oppTest[0].CWS_Bill_To_Account__c = accTest[0].Id;
            oppTest[0].StageName              = CWS_ConstantClass.OpportunityClosedWon_Stage;
        
            CWS_Trial__c trial                = new CWS_Trial__c();
            trial.CWS_Trial_Product_Type__c   = CWS_ConstantClass.TRIAL_TYPE_COMMAND;
            trial.CWS_Related_Opportunity__c  = oppTest[0].Id;
            trial.CWS_Related_Account__c      = accTest[0].Id;
            insert trial;
        
            if(oppTest.size()>0){
                update oppTest;
            }
            
            quoteTest[0].SBQQ__status__c = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
            quoteTest[0].SBQQ__ExpirationDate__c = Date.today().addMonths(3);
            if(quoteTest.size()>0){
                update quotetest;
            }
            
            SBQQ__QuoteLine__c qle = [SELECT Id, CWS_EF_Attribute__c, CWS_Category__c, CWS_Economic_Factor__c, CurrencyISOCode 
                                      FROM SBQQ__QuoteLine__c LIMIT 1];
        Test.stoptest();
        system.assert(qle.CWS_Category__c!=null);        
    }
    
    @isTest 
    static void testOppClosedLostLogic(){ 
        Test.startTest();
            List<Account> accTest             = [SELECT Id, CurrencyISOCode FROM Account];
            Contact objCon                    = [Select id FROM Contact LIMIT 1];
            List<Contract> conTest            = [SELECT Id, currencyISOCode FROM Contract]; 
            List<SBQQ__Quote__c> quoteTest    = [SELECT Id, CurrencyISOCode, SBQQ__status__c FROM SBQQ__Quote__c Order BY Name ASC];
            List<Opportunity> oppTest         = [SELECT Id, CurrencyISOCode, Name FROM Opportunity Order BY Name ASC]; 
            oppTest[0].CWS_Bill_To_Account__c = null;
            oppTest[0].CWS_Bill_To_Contact__c = null;
            oppTest[0].CWS_Bill_To_Account__c = accTest[0].Id;
            oppTest[0].StageName              = CWS_ConstantClass.OpportunityClosedLose_Stage;
            oppTest[0].CWS_Lost_Reason__c     = 'Duplicate'; 
            oppTest[0].CWS_Lost_Reason_Detail__c = 'Test';
            oppTest[0].CWS_Competitve__c      = 'No Contact'; 
        
            CWS_Trial__c trial               = new CWS_Trial__c();
            trial.CWS_Trial_Product_Type__c  = CWS_ConstantClass.TRIAL_TYPE_COMMAND;
            trial.CWS_Related_Opportunity__c = oppTest[0].Id;
            trial.CWS_Related_Account__c     = accTest[0].Id;
            insert trial;
        
            if(oppTest.size()>0){
                update oppTest;
            }
        Test.stoptest();
    }
    
    @isTest static void testLeadConv() { 
            Test.startTest();
                Map<String, Object> leadFieldDetails2 =new Map<String, Object>{
                                                                                'firstName'=>'Test',
                                                                                'LastName'=>'Partner Lead',
                                                                                'Email'=>'test@test.com',
                                                                                'Country'=>'United States',
                                                                                'CountryCode'=>'US',
                                                                                'State'=>'California',
                                                                                'PostalCode'=>'12311'
                                                                                };
            
                Lead testLead = CWS_UTLDataFactory.createLead(leadFieldDetails2,true);  
                System.assert(testLead!=null,'Test Lead should be available');
                Database.LeadConvert lc = new database.LeadConvert();  
                lc.setLeadId( testLead.Id );  
                lc.setDoNotCreateOpportunity(false); 
                LeadStatus convertStatus = [SELECT Id,Apiname, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
                lc.setConvertedStatus(convertStatus.Apiname);            
                Database.LeadConvertResult lcr = Database.convertLead(lc, false);           
            Test.stopTest();
            System.assert( lcr!=null,'Lead should be converted'); 
        }    
    
    @isTest static void checkrenewalopp(){
        Account acc = [SELECT Id, Name FROM Account WHERE Name ='TestAccount' LIMIT 1];
        List<Contract> contracts =[SELECT Id, CWS_Master__c, CurrencyIsoCode FROM Contract LIMIT 1];
        Id contId;
        if(contracts!=null && !contracts.isEmpty() ){
            contracts[0].CWS_Master__c   = false;
            contracts[0].currencyIsoCode = 'EUR';
            contracts[0].startdate       = Date.today();
            contracts[0].ContractTerm    = 3;
            update contracts[0];
            
            contId = contracts[0].Id;
        }
        Test.startTest();
            Map<String, Object> opportunityFields=new Map<String, Object>{
                                                                            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                                                                            'RecordTypeId' => CWS_ConstantClass.Opportunity_Renewal,
                                                                            'CurrencyIsoCode'=>'EUR','CWS_Do_Not_Renew_Existing_Contract__c' => false,
                                                                            'SBQQ__RenewedContract__c' => contId
                                                                        };
            Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
            Map<String, Object> additionalFieldValues = new Map<String, Object>{
                                                                                    'CWS_Route_to_Market__c' => 'Direct',
                                                                                    'CurrencyIsoCode'=>'EUR',
                                                                                    'CWS_Quote_Type__c'=> CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                                                                                };
            SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
        Test.stopTest();
        
        Opportunity oppty                           = [SELECT Id,CWS_Do_Not_Renew_Existing_Contract__c,CWS_Master__c,CurrencyIsoCode FROM Opportunity WHERE Id =:opp.Id LIMIT 1];
        oppty.CWS_Master__c                         = false;
        oppty.CWS_Do_Not_Renew_Existing_Contract__c = true;
        try{
            update oppty;
        }        
        catch(Exception ex){
            system.assert(ex.getMessage().contains(Label.CWS_RenewalRegionCheckforOpptyUpdate));
        }
    }
    
    @isTest static void testRenewalOpptyChange(){
        Account acc = [SELECT Id,Name FROM Account WHERE name ='TestAccount' LIMIT 1];
        List<Contract> contractList =[SELECT Id, CWS_Master__c, CurrencyIsoCode FROM Contract LIMIT 1];
        Id contId;
        if(contractList != null && !contractList.isEmpty() ){
            contractList[0].CWS_Master__c = false;
            contractList[0].CurrencyIsoCode = 'EUR';
            update contractList[0];
            contId = contractList[0].Id;
        }
        
        Map<String, Object> contractadditionalFieldValues=new Map<String, Object>{
                                                                                    'CurrencyISOCode' => 'EUR',
                                                                                    'CWS_Master__c' => true               
                                                                                };       
        Contract contr2 = CWS_UTLDataFactory.createContract(acc.Id, contractadditionalFieldValues, true);
        Map<String, Object> opportunityFields=new Map<String, Object>{
                                                                        'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                                                                        'Type' => CWS_ConstantClass.Opportunity_Type_RenewalWithChange,
                                                                        'CurrencyIsoCode'=>'EUR','CWS_Do_Not_Renew_Existing_Contract__c' => false,
                                                                        'SBQQ__RenewedContract__c' => contId
                                                                    };        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp', acc.Id, opportunityFields, true);
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
                                                                            'CWS_Route_to_Market__c' => 'Direct',
                                                                                'CurrencyIsoCode'=>'EUR'
                                                                           };        
        Test.startTest();
            SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
            Opportunity oppty =[SELECT Id,SBQQ__PrimaryQuote__c,StageName,SBQQ__RenewedContract__c 
                                FROM Opportunity 
                                WHERE Id=:opp.Id];
            if(oppty!=null){           
                oppty.StageName = 'proposal';
                oppty.SBQQ__RenewedContract__c = contr2.Id;
                update oppty;
            } 
        Test.stopTest();
        
        Opportunity opp1 = [SELECT Id,RecordTypeId FROM Opportunity WHERE id=:oppty.Id];
        if(oppty!=null){            
            oppty.StageName = 'Closed Won';
            update oppty;
        }
        Opportunity opp2 = [SELECT Id, RecordTypeId FROM Opportunity WHERE id=:opp.Id];
        System.assert(opp2.RecordTypeId.equals(CWS_ConstantClass.Opportunity_Renewal_ReadOnly));        
    }

    @isTest static void testAmendmentRecTypeChange(){
        Account acc = [SELECT Id,Name FROM Account WHERE name ='TestAccount' LIMIT 1];    
        List<Contract> contractList =[SELECT Id,CWS_Master__c,currencyIsoCode from Contract LIMIT 1];        
        Id contId;
        if(contractList!=null && !contractList.isEmpty() ){
            contractList[0].CWS_Master__c   = false;
            contractList[0].currencyIsoCode = 'EUR';
            update contractList[0];
            contId = contractList[0].Id;
        }
        
        Map<String, Object> contractadditionalFieldValues=new Map<String, Object>{
                                                                                    'CurrencyISOCode' => 'CAD',
                                                                                    'CWS_Master__c' => true               
                                                                                };       
        Contract contr2 =CWS_UTLDataFactory.createContract(acc.Id, contractadditionalFieldValues, true);
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
                                                                            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
                                                                            'Type' => CWS_ConstantClass.Opportunity_Type_Amendment,
                                                                            'CurrencyIsoCode'=>'EUR','CWS_Do_Not_Renew_Existing_Contract__c' => false,
                                                                            'SBQQ__AmendedContract__c' => contId
                                                                        };        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
                                                                                'CWS_Route_to_Market__c' => 'Direct',
                                                                                'CurrencyIsoCode'=>'EUR'
                                                                            };        
        Test.startTest();
            SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
            Opportunity oppty =[SELECT Id,SBQQ__PrimaryQuote__c,StageName,SBQQ__AmendedContract__c FROM Opportunity WHERE Id=:opp.Id];
            if(oppty!=null){           
                oppty.StageName = 'proposal';
                oppty.SBQQ__AmendedContract__c = contr2.Id;
                update oppty;
            } 
        Test.stopTest();
        if(oppty!=null){            
            oppty.StageName = 'Closed Won';
            update oppty;
        }
        Opportunity opp2 = [SELECT Id,RecordTypeId FROM Opportunity WHERE id=:oppty.Id];
        System.assert(opp2.RecordTypeId.equals(CWS_ConstantClass.Opportunity_Amendment_ReadOnly));      
    }
    
    @isTest 
    static void testrecordtypeUpdates3(){
        Account parentAccnt = [SELECT Id, Name FROM Account WHERE Name ='TestAccount' LIMIT 1];
        Map<String, Object> soldtoaccountFieldValues = new Map<String, Object>{            
                                                                                    'currencyIsoCode'=>'EUR',
                                                                                    'CWS_Paid_by_Parent__c' => true,                
                                                                                    'ParentId'=>parentAccnt.Id
                                                                                };
        Account acc = CWS_UTLDataFactory.createAccount('SodlToAcc', soldtoaccountFieldValues, true); 
        List<Contract> contracts =[SELECT Id,CWS_Master__c,currencyIsoCode FROM Contract LIMIT 1];
        if(contracts!=null && !contracts.isEmpty() ){
            contracts[0].currencyIsoCode = 'EUR';
            update contracts[0];
        }
        Map<String, Object> opportunityFields=new Map<String, Object>{
                                                                            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
                                                                            'Type' => CWS_ConstantClass.Opportunity_Type_New,
                                                                            'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false
                                                                        };        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
                                                                                'CWS_Route_to_Market__c' => 'Direct',
                                                                                'CurrencyIsoCode'=>'EUR'
                                                                            };
        Test.startTest();
            SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);       
            Opportunity oppty =[SELECT Id, SBQQ__PrimaryQuote__c, StageName, CWS_Bill_To_Account__c 
                                FROM Opportunity 
                                WHERE Id=:opp.Id];
            System.assertEquals(parentAccnt.Id, oppty.CWS_Bill_To_Account__c);
            if(oppty!=null){
                oppty.CWS_Fast_Track__c = true;
                oppty.StageName         = 'Closed Won';
                oppty.Type              = CWS_ConstantClass.Opportunity_Type_New;
                update oppty;
            } 
        Test.stopTest();
        
        Opportunity opp2 = [SELECT Id,RecordTypeId FROM Opportunity WHERE id=:oppty.Id];
        System.assert(opp2.RecordTypeId.equals(CWS_ConstantClass.Opportunity_NewBusiness_ReadOnly));        
    }
    
     @isTest static void checkDistyreseller(){
        Account soldtoAcc = [SELECT Id,Name FROM Account WHERE name ='TestAccount' LIMIT 1];        
        Map<String, Object> soldtoaccountFieldValues = new Map<String, Object>{            
                                                                                    'currencyIsoCode'=>'EUR',
                                                                                    'CWS_Is_Distributor__c' => true,
                                                                                    'CWS_Disti_Logic__c' => 'Synnex'                
                                                                                };
        Account acc = CWS_UTLDataFactory.createAccount('SodlToAcc', soldtoaccountFieldValues,true);
        CWS_Distributor_Reseller__c distiresell              = new CWS_Distributor_Reseller__c();
        distiresell.CWS_Account__c                           = soldtoAcc.Id;
        distiresell.CWS_Distributor_ResellerAcc__c           = acc.Id;
        distiresell.CWS_Distributor_for_Community_Group__c   = 'Synnex';
        distiresell.CWS_Distributor_Community_Group__c       = 'Varnex';
        distiresell.CWS_Fulfillment_Type__c                  = 'Fulfillment';
        Insert distiresell;
        
        Test.startTest();
            List<Contract> contractList =[SELECT Id, CWS_Master__c, CurrencyIsoCode FROM Contract LIMIT 1];       
            if(contractList!=null && !contractList.isEmpty() ){            
                contractList[0].currencyIsoCode = 'EUR';
                update contractList[0];           
            }        
            
            Map<String, Object> opportunityFields=new Map<String, Object>{
                                                                            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
                                                                            'Type' => CWS_ConstantClass.Opportunity_Type_New,
                                                                            'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> true,
                                                                            'CWS_Bill_To_Account__c'=> acc.Id
                                                                        };        
            Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',soldtoAcc.Id, opportunityFields, true);        
            Opportunity oppty =[SELECT Id,CWS_Bill_To_Account__c,CWS_Distributor_Community_Group__c 
                                FROM Opportunity WHERE Id=:opp.Id];
            System.assertEquals(distiresell.CWS_Distributor_Community_Group__c, oppty.CWS_Distributor_Community_Group__c);  
        Test.stopTest();     
    }
    
    @isTest static void defaultDistyDealPhase(){        
        List<Account> billToAccs = [SELECT Id, Name FROM Account WHERE NAME LIKE'%BillTO%'];
        Test.startTest();
            Account soldToAcc = [SELECT Id,Name,BillingCountry,BillingStreet,BillingCity,BillingPostalCode
                                 FROM Account
                                 WHERE name ='TestAccount' LIMIT 1];        
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');        
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;
            User salesrep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
            Group ftqgrp =[SELECT Id FROM Group WHERE DeveloperName =: CWS_ConstantClass.GroupnameFTQ];
            String grpId ; 
            If(ftqgrp == null){
                Group gp = new Group();
                gp.Name = CWS_ConstantClass.GroupnameFTQ;
                gp.DeveloperName = CWS_ConstantClass.GroupnameFTQ;
                insert gp;
                grpId = gp.Id;
            } else{
                grpId = ftqgrp.Id;
            } 
            insertGroupMem(salesrep.Id, grpId);
        Test.stopTest();        
        User salesUser =[SELECT Id FROM User WHERE Id =:salesrep.Id];
        system.runAs(salesUser){    
            Map<String, Object> opportunityFields = new Map<String, Object>{
                                                                            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
                                                                                'Type' => CWS_ConstantClass.Opportunity_Type_New,
                                                                                'CurrencyIsoCode'=>'EUR',
                                                                                'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Channel,                    
                                                                                'CWS_Bill_To_Account__c' => billToAccs[0].Id,
                                                                                'CWS_Fast_Track__c' => true,
                                                                                'CWS_Competitor_Takeaway_Sell__c'=> 'Run Rate Sale'
                                                                                };        
            Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp', soldToAcc.Id, opportunityFields, true);
            Opportunity oppty = [SELECT Id,CWS_Disti_Deal_Phase__c,CWS_Route_to_Market__c 
                                 FROM Opportunity 
                                 WHERE Id =:opp.Id ];
            System.assertEquals( CWS_ConstantClass.DistiEndCustomer , oppty.CWS_Disti_Deal_Phase__c);
            oppty.CWS_Route_to_Market__c = CWS_ConstantClass.RTM_Value_Direct;
            oppty.CWS_Bill_To_Account__c = BillToAccs[1].Id;
            oppty.CWS_Fast_Track__c      = false;
            update oppty;            
        }
    }
    
    @isTest static void testfastTrack(){    
        Account soldToAcc = [SELECT Id, Name, BillingCountry, BillingStreet, BillingCity, BillingPostalCode 
                             FROM Account 
                             WHERE Name ='TestAccount' LIMIT 1];        
        soldToAcc.BillingCountry    = 'France';
        soldToAcc.BillingStreet     = 'France Street';
        soldToAcc.BillingCity       = 'paris';
        soldToAcc.BillingPostalCode = '121212';
        update soldToAcc;
        
        List<Contract> contractList =[SELECT Id, CWS_Master__c, CurrencyIsoCode FROM Contract LIMIT 1];
        
        Id contId;
        if(contractList!=null && !contractList.isEmpty() ){
            contractList[0].CWS_Master__c   = false;
            contractList[0].CurrencyIsoCode = 'EUR';
            update contractList[0];
            contId = contractList[0].Id;
        }
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');        
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User salesrep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
        Group ftqgrp =[SELECT Id FROM Group WHERE DeveloperName =: CWS_ConstantClass.GroupnameFTQ];
        String grpId ; 
        
        If(ftqgrp == null){
            Group gp = new Group();
            gp.Name = CWS_ConstantClass.GroupnameFTQ;
            gp.DeveloperName = CWS_ConstantClass.GroupnameFTQ;
            insert gp;
            grpId = gp.Id;
        } else{
            grpId = ftqgrp.Id;
        } 
        Test.startTest();
        	insertGroupMem(salesrep.Id, grpId);
        Test.stopTest();
        
        User salesUser =[SELECT Id FROM User WHERE Id =:salesrep.Id];        
        system.runAs(salesUser){ 
            Map<String, Object> opportunityFields=new Map<String, Object>{
                                                                            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldToAcc.Id,
                                                                            'Type' => CWS_ConstantClass.Opportunity_Type_RenewalWithChange,
                                                                            'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> true,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                                                                            'SBQQ__RenewedContract__c' => contId, 'CWS_Fast_Track__c' => true
                                                                        };    
            try{
                Opportunity opp = CWS_UTLDataFactory.createOpportunity('Testing Opp',soldToAcc.Id, opportunityFields, true);
            }
            catch(Exception ex){
                system.assert(ex.getMessage().Contains(Label.CWS_Region_for_Renewal_with_change_owner) );
            }            
        }           
    }
    
    @isTest static void changeCurrecny(){
        Test.startTest();
            Account accountRecord = [SELECT Id, Name FROM Account WHERE Name ='TestAccount' LIMIT 1];   
            Map<String, Object> opportunityFields=new Map<String, Object>{
                                                                            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
                                                                            'Type' => CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS,
                                                                            'CurrencyIsoCode'=>'EUR','StageName' => CWS_ConstantClass.OPPORTUNITY_STAGE_PROSPECTING
                                                                        };        
            Opportunity opp = CWS_UTLDataFactory.createOpportunity('Testing Opp',accountRecord.Id, opportunityFields, true);
        Test.stopTest();
        try{
            if(opp.Id != null){
                Opportunity oppty =[SELECT Id, CurrencyIsoCode 
                                    FROM Opportunity 
                                    WHERE Id =:opp.Id LIMIT 1];
                if(oppty != null){
                    oppty.currencyIsoCode = 'AUD';
                    update oppty; 
                }                     
            }              
        }
        catch(Exception ex){                 
            system.assert(ex.getMessage().contains(Label.CWS_CurrencyAccesError));
        }
    }

    @future
    private static void insertGroupMem(id userId, Id groupId)
    {
            GroupMember gmr = new GroupMember();
            gmr.groupId = groupId;
            gmr.userOrGroupId = userId;
            insert gmr;
    }
}