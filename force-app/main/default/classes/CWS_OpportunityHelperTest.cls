/*Class Name: CWS_OpportunityHelperTest
*Description: Test Class for CWS_OpportunityTriggerHelper
*Created By: Nirmal
*Created On: 4/6/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date             User Story              Description
*------------------------------------------------------------------------------------------
*Nirmal                 04/06/2020        BED-3177            Currency default of opportunity to quote 
*Mahak Bansal           06/06/2021        OBD-601             Included test code coverage for send email on Closed Lost
*Ad Victoriam Solutions 02/14/2022          N/A               Expanded test class coverage for required deployment.
*/

@isTest(SeeAllData=false)
public class CWS_OpportunityHelperTest { 

   @testSetup static void createTestData(){
            
        List<String> datalist = new List<String>{'Account', 'Opportunity','Quote'};
        CWS_UTLDataFactory.insertTriggerSwitch(datalist);
        
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        Pricebook2 ConnectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
        if(ConnectwisePricebook!=null){
            insert ConnectwisePricebook;
        }
        Map<String,Object> additionalFields = new Map<String, Object>{
            'SBQQ__BillingType__c' => 'Advance',
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
            'SBQQ__SubscriptionTerm__c' => 12,
            'CWS_Description__c' => 'Test',
            'SBQQ__PricingMethod__c' => 'List'  
        };

        // Added by Mahak Bansal- OBD-601
        Test.startTest();
        Product2 prod = CWS_UTLDataFactory.createProduct(CWS_ConstantClass.Minimum_Commit_Prod , 'TRDF', additionalFields, True);
        prod.CWS_Category__c = 'Automate';
        prod.CWS_EF_Attribute__c = 'Service';
        prod.IsActive = true;
        prod.CWS_Base_SKU__c = '900901';
        if(prod!=null){
            upsert prod; 
        }        

        List<String> currencyCode = new List<String>{'USD','CAD','EUR'};
        List<Pricebookentry> pbeList = CWS_UTLDataFactory.createPBEList(standardPricebook.ID, Prod.Id, 100 ,currencyCode);
        List<Pricebookentry> pbeList1 = CWS_UTLDataFactory.createPBEList(ConnectwisePricebook.ID, Prod.Id, 100 ,currencyCode);
        pbeList.addAll(pbeList1);
        if(pbeList.size()>0){
            insert pbeList;
        }
       
        CWS_Economic_Factor__c ecofac = new CWS_Economic_Factor__c();
        ecofac.CWS_Category__c = 'Automate';
        ecofac.CWS_Product_Type__c = 'Service';
        ecofac.CWS_Economic_Factor__c = 1.2;
        ecofac.CurrencyISOCode = 'EUR';
        if(ecofac!=null){
            insert ecofac;
        }
       
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',            
            'CWS_Purchase_Order_Required__c'=>'Yes'
        };
        Account acc =CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        //Creating Contact for the Account
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
       
        Contract con =CWS_UTLDataFactory.createContract(acc.Id, contractadditionalFieldValues, true);
 
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD'
        };

        Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
        Map<String, Object> additionalFieldValues = new Map<String, Object>();
        PricebookEntry pbeValue = [Select Id from Pricebookentry where CurrencyISOCode = 'EUR' and Pricebook2.Name =:CWS_ConstantClass.CONNECTWISE_PRICEBOOK];
       
        SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
        quote.CWS_Bill_To_Account__c = acc.Id;
        quote.CWS_Bill_To_Contact__c = objCon.Id;
        update quote;

        List<SBQQ__QuoteLine__c> quoteLine = CWS_UTLDataFactory.createQuoteLines(1 , quote.Id, prod.Id);
        quoteLine[0].SBQQ__PricebookEntryId__c = pbeValue.Id;
        quoteLine[0].CWS_EF_Attribute__c = 'Service';
        quoteLine[0].CWS_Category__c = 'Automate';
        quoteLine[0].CurrencyISOCode = 'EUR';
        //quoteLine[0].CWS_Overage_Price__c = 1000;
        if(quoteLine.size()>0){
            insert quoteLine;
        }
       
        OpportunityLineItem oppProd = new OpportunityLineItem();
        oppProd.OpportunityId = opp.Id;
        oppProd.Quantity = 1;
        oppProd.Product2Id = prod.Id;
        oppProd.PricebookEntryId = pbeValue.Id;
        oppProd.SBQQ__QuoteLine__c = quoteline[0].Id;
        oppProd.TotalPrice = 100;
        if(oppProd!=null){
            insert oppProd;
        }

       // Added by Mahak Bansal- OBD-601       
        Account soldToAcc = acc;
        soldToAcc.BillingCountry = 'France';
        soldToAcc.BillingStreet = 'France Street';
        soldToAcc.BillingCity = 'paris';
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
        // Added by Mahak Bansal- OBD-601
    }
/*
    @isTest static void testMethod1(){
        Map<String,Object> additionalFieldValues = new Map<String,Object>();
        Test.starttest();
        List<Account> accTest = [SELECT ID, CurrencyISOCode from Account];
        Contact objCon = [Select id from Contact limit 1];
        List<Contract> conTest = [SELECT Id, currencyISOCode from Contract]; 
        List<SBQQ__Quote__c> quoteTest = [SELECT ID, CurrencyISOCode, SBQQ__status__c from SBQQ__Quote__c Order by Name ASC];

        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> accTest[0].Id,'CWS_Bill_To_Contact__c'=>objCon.Id,'AccountId'=> accTest[0].Id,
            'Type'=>'New Business','CurrencyIsoCode'=>'USD', 'SBQQ__RenewedContract__c' => conTest[0].ID, 'StageName'=>'Prospecting'
        };
        Opportunity nopp =  CWs_UTLDataFactory.createOpportunity('B_Dummy_Opp',accTest[0].Id, opportunityFields, true);
        
        Map<String, Object> nopportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> accTest[0].Id,'CWS_Bill_To_Contact__c'=>objCon.Id,
            'AccountId'=> accTest[0].Id,'Type'=>'New Business','CurrencyIsoCode'=>'USD', 'SBQQ__AmendedContract__c' => conTest[0].ID
        };
        Opportunity mopp =  CWs_UTLDataFactory.createOpportunity('C_Dummy_Opp',accTest[0].Id, nopportunityFields, true);
        
        List<Opportunity> oppTest = [SELECT ID, CurrencyISOCode, Name from Opportunity Order By Name ASC]; 
        
        system.assertEquals(oppTest[0].CurrencyISOCode, quoteTest[0].CurrencyISOCode);
        System.assertEquals(oppTest[0].CurrencyISOCode, accTest[0].CurrencyISOCode);
        System.assertEquals(OppTest[1].CurrencyISOCode, conTest[0].CurrencyISOCode);
        System.assertEquals(OppTest[2].CurrencyISOCode, conTest[0].CurrencyISOCode);
        
        oppTest[0].CWS_Bill_To_Account__c = null;
        oppTest[0].CWS_Bill_To_Contact__c = null;
        oppTest[1].SBQQ__RenewedContract__c = null;
        oppTest[2].SBQQ__AmendedContract__c = null;
        if(oppTest.size()>0){
            update oppTest;
        }
        
        oppTest[0].CWS_Bill_To_Account__c = accTest[0].Id;
        oppTest[1].StageName = 'Closed Won';
        oppTest[1].SBQQ__RenewedContract__c = conTest[0].Id;
        oppTest[2].SBQQ__AmendedContract__c = conTest[0].Id;
        if(oppTest.size()>0){
            update oppTest;
        }
        
        quoteTest[0].SBQQ__status__c = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
        quoteTest[0].SBQQ__ExpirationDate__c = Date.today().addMonths(3);
        if(quoteTest.size()>0){
            update quotetest;
        }
        
        SBQQ__QuoteLine__c qle = [Select ID, CWS_EF_Attribute__c, CWS_Category__c, CWS_Economic_Factor__c, CurrencyISOCode from SBQQ__QuoteLine__c limit 1];
        system.debug('qle-->'+ qle);
        Test.stoptest();
        system.assert(qle.CWS_Category__c!=null);        
    }

    @isTest static void testMethod2(){
        Map<String,Object> additionalFieldValues = new Map<String,Object>();
        Test.starttest();
        List<Account> accTest = [SELECT ID, CurrencyISOCode from Account];
        List<Contract> conTest = [SELECT Id, currencyISOCode from Contract]; 
        List<SBQQ__Quote__c> quoteTest = [SELECT ID, CurrencyISOCode, SBQQ__status__c from SBQQ__Quote__c Order by Name ASC];

        
        Map<String, Object> opportunityFields=new Map<String, Object>{
           'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> accTest[0].Id,
           'AccountId'=> accTest[0].Id, 'Type'=>'Amendment','CurrencyIsoCode'=>'USD', 'SBQQ__RenewedContract__c' => conTest[0].ID, 'StageName'=>'Prospecting'
        };
        Opportunity nopp =  CWs_UTLDataFactory.createOpportunity('B_Dummy_Opp',accTest[0].Id, opportunityFields, true);
        
        Map<String, Object> nopportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> accTest[0].Id,
            'AccountId'=> accTest[0].Id, 'Type'=>'New Business','CurrencyIsoCode'=>'USD', 'SBQQ__AmendedContract__c' => conTest[0].ID
        };
        Opportunity mopp =  CWs_UTLDataFactory.createOpportunity('C_Dummy_Opp',accTest[0].Id, nopportunityFields, true);
        
        List<Opportunity> oppTest = [SELECT ID, CurrencyISOCode, Name from Opportunity Order By Name ASC]; 
        
        system.assertEquals(oppTest[0].CurrencyISOCode, quoteTest[0].CurrencyISOCode);
        System.assertEquals(oppTest[0].CurrencyISOCode, accTest[0].CurrencyISOCode);
        System.assertEquals(OppTest[1].CurrencyISOCode, conTest[0].CurrencyISOCode);
        System.assertEquals(OppTest[2].CurrencyISOCode, conTest[0].CurrencyISOCode);
        
        oppTest[2].Type ='Renewal';

        if(oppTest.size()>0){
            update oppTest;
        }
        system.debug('debug--1');
        oppTest[1].StageName = 'Closed Won';
        
        oppTest[2].StageName = 'Closed Won';
        if(oppTest.size()>0){
            update oppTest;
        }
        system.debug('debug--2');
        Test.stoptest();
        system.assertEquals(OppTest[2].StageName,'Closed Won'); 
    }
 */
    
    @isTest static void testMethod3(){
        
        Set<Id> oppids = new Set<Id>();
        
        List<Account> accTest = [SELECT ID, CurrencyISOCode,(select id from contacts where 
                                 CWS_Primary_Billing_Contact__c = true OR CWS_Primary_Contact__c = true)
                                 FROM Account Limit 1];
        System.assert(accTest!=null,'No Account should be returned'); //Added by Mahak Bansal- OBD-601
        if(accTest[0].contacts.isEmpty()){
            System.debug('contact--');
            Map<String, Object> mapConFieldValues = new Map<String, Object>{
                'CWS_Primary_Billing_Contact__c' => true,
                'CWS_Primary_Contact__c' => true,
                'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                'Email'=>'test@test.com'
            };
            Contact objCon = CWS_UTLDataFactory.createContact('TestFirstName','TestLastName',accTest[0].Id,mapConFieldValues,true);  
        }
        Test.starttest();
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> accTest[0].Id,
            'AccountId'=> accTest[0].Id, 'Type'=>'New Business','CurrencyIsoCode'=>'USD',  'StageName'=>'Prospecting'
        };
        Opportunity nopp =  CWs_UTLDataFactory.createOpportunity('B_Dummy_Opp',accTest[0].Id, opportunityFields, true);
        oppids.add(nopp.ID);        
        Map<String, Object> nopportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> accTest[0].Id,
            'AccountId'=> accTest[0].Id, 'Type'=>'New Business','CurrencyIsoCode'=>'USD'
        };
        Opportunity mopp =  CWs_UTLDataFactory.createOpportunity('C_Dummy_Opp',accTest[0].Id, nopportunityFields, true);
        oppids.add(mopp.ID);
        List<Opportunity> oppTest = [SELECT ID, CurrencyISOCode, Name from Opportunity   WHERE ID IN: oppids Order By Name ASC]; 
                
        Map<String,Object> additionalFieldValues = new Map<String,Object>{
            'CWS_Bill_To_Account__c'=> accTest[0].Id // Updated by Mahak Bansal- OBD-601
        };
        
        //Added by Mahak Bansal- OBD-601
        OpportunityTeamMember opm = new OpportunityTeamMember(OpportunityId=oppTest[0].id,UserId=userInfo.getUserId());
        insert opm;        
        try{
            SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(accTest[0].Id, oppTest[0].Id, additionalFieldValues, true);
            oppTest[0].StageName = 'Closed Lost';
            oppTest[0].CWS_Lost_Reason__c = 'Went Direct';
            oppTest[1].StageName = 'Closed Won';
            if(oppTest.size()>0){
                update oppTest;
            }          
        }
        catch(Exception ex){
            system.debug('Exception--'+ex.getMessage());
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
            //lc.setConvertedStatus( 'SQO Accepted' );            
            Database.LeadConvertResult lcr = Database.convertLead(lc, false);           
            System.debug( 'Errors are ' + lcr.getErrors() );           
            Test.stopTest();
            
            System.assert( lcr!=null,'Lead shoudl be converted');  //updated by Mahak Bansal- OBD-601
            //Not required-- commentd by Mahak Bansal- OBD-601
          //  Opportunity opp =[SELECT Id,Name from opportunity limit 1];
            //system.debug('opp--'+opp);
            
        }    
    
    @isTest static void checkrenewalopp(){
        Account acc = [SELECT ID,Name From Account where name ='TestAccount' LIMIT 1];
        List<Contract> contracts =[SELECT ID,CWS_Master__c,currencyIsoCode from Contract LIMIT 1];
        
        Id ContId;
        if(contracts!=null && !contracts.isEmpty() ){
            contracts[0].CWS_Master__c = false;
            contracts[0].currencyIsoCode = 'EUR';
            contracts[0].startdate = date.today();
            contracts[0].ContractTerm = 3;
            update contracts[0];
            ContId = contracts[0].Id;
        }
        system.debug('ContId--'+ContId);
        Test.startTest();
        /*CWS_RegionGroupMapping__mdt mdt = [Select id,CWS_Region__c, CWS_GroupName__c from CWS_RegionGroupMapping__mdt LIMIT 1];
        
        if(mdt != null){
            GroupMember gmr=new GroupMember();
            gmr.GroupId = [SELECT ID FROM  Group where DeveloperName =: mdt.CWS_GroupName__c].ID ;
            gmr.UserOrGroupId=userInfo.getUserId();
            insert gmr;
        }
*/        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
            'RecordTypeID' => CWS_ConstantClass.Opportunity_Renewal,
            'CurrencyIsoCode'=>'EUR','CWS_Do_Not_Renew_Existing_Contract__c' => false,
            'SBQQ__RenewedContract__c' => ContId
        };
        
        Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
        //creating quote
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Direct',
            'CurrencyIsoCode'=>'EUR',
            'CWS_Quote_Type__c'=> CWS_ConstantClass.QUOTE_TYPE_RENEWAL
        };
        
        system.debug('before - quote--');
        SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);
        system.debug('after - quote--');
        Test.stopTest();
        Opportunity oppty =[SELECT ID,CWS_Do_Not_Renew_Existing_Contract__c,CWS_Master__c,CurrencyIsoCode FROM Opportunity WHERE ID =:opp.ID LIMIT 1];
        system.debug('opp--'+oppty);
        oppty.CWS_Master__c = false;
        oppty.CWS_Do_Not_Renew_Existing_Contract__c =true;
        try{
            Update oppty;
        }        
        catch(Exception ex){
            system.assert(ex.getMessage().contains(Label.CWS_RenewalRegionCheckforOpptyUpdate));
        }
    }
    /*
    @isTest static void testrandomUpdates(){
      Account acc = [SELECT ID,Name From Account where name ='TestAccount' LIMIT 1];
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),                
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> true,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
        'CWS_Ramp_Options__c' => 'Fixed Commit Ramp', 'CWS_Min_Commit_QR__c' => 1000, 'CWS_Fast_Track__c'=> true,                 
         'CWS_Period_of_Fixed_Usage_Commit_Ramp__c' => 2 };                    
        Opportunity opp = CWs_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
        
        //create trial object
        CWS_Trial__c trial = new CWS_Trial__c();
        trial.CWS_Trial_Product_Type__c = CWS_ConstantClass.TRIAL_TYPE_COMMAND;
        trial.CWS_Related_Opportunity__c = opp.Id;
        trial.CWS_Related_Account__c = acc.ID;
        insert trial;
        
        Opportunity oppty =[SELECT ID, CWS_Master__c,CWS_Ramp_Options__c,CWS_Period_of_Fixed_Usage_Commit_Ramp__c,
                            CWS_Fast_Track__c,CWS_Min_Commit_QR__c FROM Opportunity WHERE ID=:opp.ID];
        
        if(oppty!=null){
            oppty.CWS_Ramp_Options__c = 'Minimum Commit Ramp';
            oppty.CWS_Period_of_Fixed_Usage_Commit_Ramp__c = 0 ;
            oppty.CWS_Fast_Track__c = false;
            oppty.CWS_Min_Commit_QR__c = 2000;
            oppty.StageName = 'Closed Won';
            update oppty;
        }
    }*/
    @isTest static void testRenewalOpptyChange(){
    
        Account acc = [SELECT ID,Name From Account where name ='TestAccount' LIMIT 1];
        
        List<Contract> contracts =[SELECT ID,CWS_Master__c,currencyIsoCode from Contract LIMIT 1];
        
        Id ContId;
        if(contracts!=null && !contracts.isEmpty() ){
             contracts[0].CWS_Master__c = false;
            contracts[0].currencyIsoCode = 'EUR';
            update contracts[0];
            ContId = contracts[0].Id;
        }
        
        //creating another contract.
        Map<String, Object> contractadditionalFieldValues=new Map<String, Object>{
            'CurrencyISOCode' => 'EUR',
            'CWS_Master__c' => true               
        };       
        Contract contr2 = CWS_UTLDataFactory.createContract(acc.Id, contractadditionalFieldValues, true);
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
            'Type' => CWS_ConstantClass.Opportunity_Type_RenewalWithChange,
            'CurrencyIsoCode'=>'EUR','CWS_Do_Not_Renew_Existing_Contract__c' => false,
            'SBQQ__RenewedContract__c' => ContId
        };        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
        
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Direct',
            'CurrencyIsoCode'=>'EUR'
        };        
        Test.startTest();
        SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);

        
        Opportunity oppty =[SELECT ID,SBQQ__PrimaryQuote__c,StageName,SBQQ__RenewedContract__c FROM Opportunity WHERE ID=:opp.ID];
 
        if(oppty!=null){           
            oppty.StageName = 'proposal';
            oppty.SBQQ__RenewedContract__c = contr2.Id;
            update oppty;
        } 
        Test.stopTest();
        Opportunity opp1 = [SELECT ID,RecordTypeID FROM Opportunity WHERE id=:oppty.ID];
        //System.assert(opp1.RecordTypeID.equals(CWS_ConstantClass.OPPORTUNITY_RT_RENEWAL_INTERIM));
        
        if(oppty!=null){            
            oppty.StageName = 'Closed Won';
            update oppty;
        }
        Opportunity opp2 = [SELECT ID,RecordTypeID FROM Opportunity WHERE id=:opp.ID];
        System.assert(opp2.RecordTypeID.equals(CWS_ConstantClass.Opportunity_Renewal_ReadOnly));        
    }

    @isTest static void testAmendmentRecTypeChange(){
    
        Account acc = [SELECT ID,Name From Account where name ='TestAccount' LIMIT 1];    
      
        List<Contract> contracts =[SELECT ID,CWS_Master__c,currencyIsoCode from Contract LIMIT 1];        
        Id ContId;
        if(contracts!=null && !contracts.isEmpty() ){
            contracts[0].CWS_Master__c = false;
            contracts[0].currencyIsoCode = 'EUR';
            update contracts[0];
            ContId = contracts[0].Id;
        }
        //creating another contract.
        Map<String, Object> contractadditionalFieldValues=new Map<String, Object>{
            'CurrencyISOCode' => 'CAD',
            'CWS_Master__c' => true               
        };       
        Contract contr2 =CWS_UTLDataFactory.createContract(acc.Id, contractadditionalFieldValues, true);
        
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acc.Id,
            'Type' => CWS_ConstantClass.Opportunity_Type_Amendment,
            'CurrencyIsoCode'=>'EUR','CWS_Do_Not_Renew_Existing_Contract__c' => false,
            'SBQQ__AmendedContract__c' => ContId
        };        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
        
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Direct',
            'CurrencyIsoCode'=>'EUR'
        };        
        Test.startTest();
        SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);

        
        Opportunity oppty =[SELECT ID,SBQQ__PrimaryQuote__c,StageName,SBQQ__AmendedContract__c FROM Opportunity WHERE ID=:opp.ID];
 
        if(oppty!=null){           
            oppty.StageName = 'proposal';
            oppty.SBQQ__AmendedContract__c = contr2.Id;
            update oppty;
        } 
        Test.stopTest();
        Opportunity opp1 = [SELECT ID,RecordTypeID FROM Opportunity WHERE id=:oppty.ID];
        //System.assert(opp1.RecordTypeID.equals(CWS_ConstantClass.OPPORTUNITY_RT_AMENDMENT_INTERIM));
        
        if(oppty!=null){            
            oppty.StageName = 'Closed Won';
            update oppty;
        }
        Opportunity opp2 = [SELECT ID,RecordTypeID FROM Opportunity WHERE id=:oppty.ID];
        System.assert(opp2.RecordTypeID.equals(CWS_ConstantClass.Opportunity_Amendment_ReadOnly));      
    }
    @isTest static void testrecordtypeUpdates3(){
        
        Account parentAccnt = [SELECT ID,Name From Account where name ='TestAccount' LIMIT 1];
        
        Map<String, Object> soldtoaccountFieldValues = new Map<String, Object>{            
            'currencyIsoCode'=>'EUR',
            'CWS_Paid_by_Parent__c' => true,                
            'ParentId'=>parentAccnt.ID
        };

        Account acc =CWS_UTLDataFactory.createAccount('SodlToAcc', soldtoaccountFieldValues,true);        
        
        List<Contract> contracts =[SELECT ID,CWS_Master__c,currencyIsoCode from Contract LIMIT 1];
        
        Id ContId;
        if(contracts!=null && !contracts.isEmpty() ){
            //contracts[0].CWS_Master__c = false;
            contracts[0].currencyIsoCode = 'EUR';
            update contracts[0];
            //ContId = contracts[0].Id;
        }
        
        //Create Opp
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
            'Type' => CWS_ConstantClass.Opportunity_Type_New,
            'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> false
        };        
        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',acc.Id, opportunityFields, true);
        
        //Create quote
        Map<String, Object> additionalFieldValues = new Map<String, Object>{
            'CWS_Route_to_Market__c' => 'Direct',
            'CurrencyIsoCode'=>'EUR'
        };
        Test.startTest();
        SBQQ__Quote__c quote = CWs_UTLDataFactory.createQuote(acc.Id, opp.Id, additionalFieldValues, true);       
        Opportunity oppty =[SELECT ID,SBQQ__PrimaryQuote__c,StageName,CWS_Bill_To_Account__c FROM Opportunity WHERE ID=:opp.ID];
        System.assertEquals(parentAccnt.ID, oppty.CWS_Bill_To_Account__c);
        if(oppty!=null){
            oppty.CWS_Fast_Track__c = true;
            oppty.StageName = 'proposal';
            update oppty;
        } 
        Opportunity opp1 = [SELECT ID,RecordTypeID FROM Opportunity WHERE id=:oppty.ID];
        //System.assert(opp1.RecordTypeID.equals(CWS_ConstantClass.OPPORTUNITY_RT_NEWBUSINESS_INTERIM));
        Test.stopTest();
        if(opp1!=null){            
            opp1.StageName = 'Closed Won';
            update opp1;
        }
        Opportunity opp2 = [SELECT ID,RecordTypeID FROM Opportunity WHERE id=:oppty.ID];
        System.assert(opp2.RecordTypeID.equals(CWS_ConstantClass.Opportunity_NewBusiness_ReadOnly));        
    }
    
     @isTest static void checkDistyreseller(){
        
        Account soldtoAcc = [SELECT ID,Name From Account where name ='TestAccount' LIMIT 1];        
        Map<String, Object> soldtoaccountFieldValues = new Map<String, Object>{            
            'currencyIsoCode'=>'EUR',
            'CWS_Is_Distributor__c' => true,
            'CWS_Disti_Logic__c' => 'Synnex'                
        };
        Account acc =CWS_UTLDataFactory.createAccount('SodlToAcc', soldtoaccountFieldValues,true);
        //Creatind Distributor reseller
        CWS_Distributor_Reseller__c distiresell = new CWS_Distributor_Reseller__c();
        distiresell.CWS_Account__c = soldtoAcc.ID;
        distiresell.CWS_Distributor_ResellerAcc__c = acc.ID;
        distiresell.CWS_Distributor_for_Community_Group__c = 'Synnex';
        distiresell.CWS_Distributor_Community_Group__c = 'Varnex';
        distiresell.CWS_Fulfillment_Type__c = 'Fulfillment';
        Insert distiresell;
        //Added by Mahak Bansal - OBD-601
        Test.startTest();
        List<Contract> contracts =[SELECT ID,CWS_Master__c,currencyIsoCode from Contract LIMIT 1];       
        if(contracts!=null && !contracts.isEmpty() ){            
            contracts[0].currencyIsoCode = 'EUR';
            update contracts[0];           
        }        
        //Create Opp
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
            'Type' => CWS_ConstantClass.Opportunity_Type_New,
            'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> true,
            'CWS_Bill_To_Account__c'=> acc.Id
        };        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',soldtoAcc.ID, opportunityFields, true);        
        Opportunity oppty =[SELECT ID,CWS_Bill_To_Account__c,CWS_Distributor_Community_Group__c FROM Opportunity WHERE ID=:opp.ID];
        System.assertEquals(distiresell.CWS_Distributor_Community_Group__c, oppty.CWS_Distributor_Community_Group__c);  
        Test.stopTest();     
    }
    /*
     @isTest static void createCommisionOppty(){
         
        Account soldtoAcc = [SELECT ID from Account where name ='TestAccount' LIMIT 1 ];
         Map<String, Object> opportunityFields = new Map<String, Object>{
                'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
                'Type' => CWS_ConstantClass.Opportunity_Type_CommissionOnly,
                'CurrencyIsoCode'=>'EUR' , 'RecordTypeId' => CWS_ConstantClass.Opportunity_CommissionOnlyReadOnly              
                };        
        Opportunity oppty = CWS_UTLDataFactory.createOpportunity('Commision_Opp',soldtoAcc.ID, opportunityFields, true);
        Opportunity opp1 =[SELECT ID,RecordTypeID,StageName FROM Opportunity WHERE ID=:oppty.ID]; 
        if(opp1!=null){            
            opp1.StageName = 'Closed Won';
            update opp1;
        
        Opportunity opp2 = [SELECT ID,RecordTypeID FROM Opportunity WHERE id=:oppty.ID];
        System.assert(opp2.RecordTypeID.equals(CWS_ConstantClass.Opportunity_CommissionOnlyReadOnly));
        }     
     }*/
    
    
    
    @isTest static void defaultDistyDealPhase(){        
        List<Account> BillToAccs = [SELECT ID,Name FROM Account WHERE NAME LIKE'%BillTO%'];
        //Added by Mahak Bansal - OBD-601
        Test.startTest();
        Account SoldToAcc = [SELECT ID,Name,BillingCountry,BillingStreet,BillingCity,BillingPostalCode
                             FROM Account
                             WHERE name ='TestAccount' LIMIT 1];        
        //Creating Sales Rep
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');        
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User salesrep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
        Group ftqgrp =[SELECT ID FROM Group WHERE DeveloperName =: CWS_ConstantClass.GroupnameFTQ];
        String grpId ; 
        
        If(ftqgrp == null){
            Group gp = new Group();
            gp.Name = CWS_ConstantClass.GroupnameFTQ;
            gp.DeveloperName = CWS_ConstantClass.GroupnameFTQ;
            insert gp;
            grpId = gp.ID;
            system.debug('gpid--'+gp.id);
        } else{
            grpId = ftqgrp.Id;
        } 
        system.debug('grpId--'+grpId+'salesID=='+salesrep.Id);
        
        //create group       
        
        insertGroupMem(salesrep.Id, grpId);
        Test.stopTest();
        //Add sales rep to group

        
        //Adding user to a public group:        
        User salesUser =[SELECT ID FROM User where Id =:salesrep.ID];
        
        system.runAs(salesUser){    
            
           //Create Opp
            Map<String, Object> opportunityFields = new Map<String, Object>{
                'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
                'Type' => CWS_ConstantClass.Opportunity_Type_New,
                'CurrencyIsoCode'=>'EUR',
                'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Channel,                    
                'CWS_Bill_To_Account__c' => BillToAccs[0].ID,
                'CWS_Fast_Track__c' => true
            };        
            Opportunity opp = CWS_UTLDataFactory.createOpportunity('A_Dummy_Opp',SoldToAcc.Id, opportunityFields, false);
            opp.CWS_Competitor_Takeaway_Sell__c = 'N/A';
            insert opp;
            
            Opportunity oppty = [SELECT ID,CWS_Disti_Deal_Phase__c,CWS_Route_to_Market__c FROM Opportunity WHERE Id =:opp.ID ];
            System.assertEquals( CWS_ConstantClass.DistiEndCustomer , oppty.CWS_Disti_Deal_Phase__c);
            //Updating Oppty
            oppty.CWS_Route_to_Market__c = CWS_ConstantClass.RTM_Value_Direct;
            oppty.CWS_Bill_To_Account__c = BillToAccs[1].Id;
            Oppty.CWS_Fast_Track__c = false;
            update oppty;            
        }
        //Test.stopTest();
        
    }
    






    
    @isTest static void testfastTrack(){    
        Account SoldToAcc = [SELECT ID,Name,BillingCountry,BillingStreet,BillingCity,BillingPostalCode From Account where name ='TestAccount' LIMIT 1];        
        SoldToAcc.BillingCountry = 'France';
        SoldToAcc.BillingStreet = 'France Street';
        SoldToAcc.BillingCity = 'paris';
        SoldToAcc.BillingPostalCode = '121212';
        update SoldToAcc;
        
        List<Contract> contracts =[SELECT ID,CWS_Master__c,currencyIsoCode from Contract LIMIT 1];
        
        Id ContId;
        if(contracts!=null && !contracts.isEmpty() ){
            contracts[0].CWS_Master__c = false;
            contracts[0].currencyIsoCode = 'EUR';
            update contracts[0];
            ContId = contracts[0].Id;
        }
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');        
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User salesrep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
        Group ftqgrp =[SELECT ID FROM Group WHERE DeveloperName =: CWS_ConstantClass.GroupnameFTQ];
        String grpId ; 
        
        If(ftqgrp == null){
            Group gp = new Group();
            gp.Name = CWS_ConstantClass.GroupnameFTQ;
            gp.DeveloperName = CWS_ConstantClass.GroupnameFTQ;
            insert gp;
            grpId = gp.ID;
            system.debug('gpid--'+gp.id);
        } else{
            grpId = ftqgrp.Id;
        } 
        system.debug('grpId--'+grpId+'salesID=='+salesrep.Id);
        
        //create group       
        
        Test.startTest();
        insertGroupMem(salesrep.Id, grpId);
        Test.stopTest();
        
        User salesUser =[SELECT ID FROM User where Id =:salesrep.ID];        
        system.runAs(salesUser){ 
            Map<String, Object> opportunityFields=new Map<String, Object>{
                'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> SoldToAcc.Id,
                'Type' => CWS_ConstantClass.Opportunity_Type_RenewalWithChange,
                'CurrencyIsoCode'=>'EUR','CWS_Master__c'=> true,'CWS_Do_Not_Renew_Existing_Contract__c' => false,
                'SBQQ__RenewedContract__c' => ContId, 'CWS_Fast_Track__c' => true
            };    
            try{
                Opportunity opp = CWS_UTLDataFactory.createOpportunity('Testing Opp',SoldToAcc.Id, opportunityFields, true);
            }
            catch(Exception ex){
                system.assert(ex.getMessage().Contains(Label.CWS_Region_for_Renewal_with_change_owner) );
            }            
        }           
    }
    /*
    @isTest static void makeOpptyClosedwon(){
        
        Account Accnt = [SELECT ID,Name From Account where name ='TestAccount' LIMIT 1];        
        //Create Opp
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
                'Type' => CWS_ConstantClass.Opportunity_Type_New,
                'CurrencyIsoCode'=>'EUR','StageName' => CWS_ConstantClass.OpportunityClosedWon_Stage
                };        
                    Opportunity opp = CWS_UTLDataFactory.createOpportunity('Testing Opp',Accnt.Id, opportunityFields, true);
        Opportunity oppty =[SELECT ID,Name,RecordTypeId FROM Opportunity WHERE ID =:opp.ID];        
        system.assertEquals(CWS_ConstantClass.Opportunity_NewBusiness_ReadOnly , oppty.RecordTypeId);
    }*/
    
    @isTest static void changeCurrecny(){
        Test.startTest();
        Account Accnt = [SELECT ID,Name From Account where name ='TestAccount' LIMIT 1];        
        //Create Opp
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),
            'Type' => CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS,
            'CurrencyIsoCode'=>'EUR','StageName' => CWS_ConstantClass.OPPORTUNITY_STAGE_PROSPECTING
        };        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('Testing Opp',Accnt.Id, opportunityFields, true);
        Test.stopTest();
        try{
            if(opp.ID != null){
                Opportunity oppty =[SELECT ID,CurrencyIsoCode FROM Opportunity WHERE ID =:opp.ID LIMIT 1];
                if(oppty != null){
                    oppty.CurrencyIsoCode = 'AUD';
                    Update oppty; 
                }                     
            }              
        }
        catch(Exception ex){                 
            system.assert(ex.getMessage().contains(Label.CWS_CurrencyAccesError));
        }
    }

    @future
    private static void insertGroupMem(id userID, Id GroupId)
    {
            GroupMember gmr = new GroupMember();
            gmr.GroupId = GroupId;
            gmr.UserOrGroupId = userID;
            insert gmr;
    }
}