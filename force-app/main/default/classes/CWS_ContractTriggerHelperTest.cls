/*Class Name: CWS_ContractTriggerHelperTest
*Description: Test Class for CWS_ContractTriggerHelper
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_ContractTriggerHelperTest{
    @testSetup
    static void createTestData(){
       //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','SBQQ__Quote__c'});
         CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
        insert bypassValidate;
        //Create Sold To Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR','CWS_Is_Distributor__c'=>true};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR','CWS_Is_Partner__c'=>true,'CWS_Is_Distributor__c'=>true, 'CWS_Need_Recurring__c'=>true};
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
              
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', 'Automate;Sell', null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', 'Perch', null, true);
        Pricebook2 connectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
        if(connectwisePricebook!=null){
            insert connectwisePricebook;
        }
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'EUR', 'Pricebook2Id'=>ConnectwisePricebook.Id
        };
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);
        //opty.CurrencyIsoCode='EUR';
        //insert opty;
        Test.startTest();
        Map<String, Object> quoteFields2=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New', 'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Channel',
            'SBQQ__Distributor__c'=>distiAccounts[0].Id, 'SBQQ__Pricebook__c'=>connectwisePricebook.Id, 'SBQQ__StartDate__c'=> Date.today(),
            'SBQQ__SubscriptionTerm__c'=>12, 'CurrencyIsoCode'=>'EUR', 
            'CWS_Renewal_CAP__c'=>10, 'CWS_Renewal_Uplift_Applicable__c'=>null,'CWS_Bill_To_Account__c'=>distiaccounts[0].Id, 'CWS_OF_Signed_Override_Date__c'=>Date.today()
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
        
        Map<String, Object> mapQuoteLineFields=new Map<String, Object>{'SBQQ__Quote__c'=>quote2.Id, 'SBQQ__Product__c'=> productA.Id, 
                'SBQQ__PricebookEntryId__c'=> pbeA.Id,'SBQQ__Quantity__c'=>1,'SBQQ__ListPrice__c'=>1000.00, 'SBQQ__CustomerPrice__c'=>1000.00,
                'SBQQ__RegularPrice__c'=>1000, 'SBQQ__SpecialPrice__c'=>1000, 'SBQQ__NetPrice__c'=>1000,
                'SBQQ__SubscriptionTerm__c' =>12,'SBQQ__StartDate__c'=>(Date)Date.today(), 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 
                'SBQQ__ChargeType__c'=>CWS_ConstantClass.ChargeType_Recurring, 'SBQQ__BillingType__c'=>'Advance', 'CWS_Transaction_Type__c'=>'New', 
                'SBQQ__PricebookEntryId__c' => pbeA.Id};
        SBQQ__QuoteLine__c quoteLineItemA = CWS_UTLDataFactory.createQuoteLine(mapQuoteLineFields,true);
        mapQuoteLineFields.put('SBQQ__Product__c', productB.Id);
        mapQuoteLineFields.put('SBQQ__PricebookEntryId__c',pbeB.Id);
        SBQQ__QuoteLine__c quoteLineItemB = CWS_UTLDataFactory.createQuoteLine(mapQuoteLineFields,true);
        Test.stopTest();
    }
    
    //BED-3402
    @isTest
    static void testContractCreation(){
        Pricebook2[] connectWisePricebook=[Select Id from Pricebook2 where name=:CWS_ConstantClass.CONNECTWISE_PRICEBOOK Limit 1];
        List<SBQQ__Quote__c> quoteList=[Select Id, Name,CWS_Renewal_Type__c,SBQQ__StartDate__c, SBQQ__EndDate__c,
                SBQQ__Ordered__c,SBQQ__PricebookId__c,SBQQ__PriceBook__c,CWS_Quote_ACV__c, CWS_Renewal_CAP__c,
                CWS_Renewal_Uplift_Applicable__c from SBQQ__Quote__c];
        quoteList[0].SBQQ__Ordered__c=true;
        if(quoteList!=null){
        update quoteList;
        }
        system.debug(quoteList[0]);
        
        Test.startTest();        
        List<order> orderList=(List<order>)Database.query('Select Id,SBQQ__Contracted__c from order ');
        System.debug(orderList);
        orderList[0].Pricebook2Id=connectWisePricebook[0].Id;
        orderList[0].Status='Activated';
        if(orderList!=null){
        update  orderList;
        }


        list<OrderItem> lstOLI =[select id,SBQQ__Activated__c, servicedate, CWS_Provisioning_Eligibility__c from OrderItem];
        System.debug(lstOLI);
        lstOLI[0].SBQQ__Activated__c = true;
        lstOLI[0].servicedate=quoteList[0].SBQQ__StartDate__c;
        lstOLI[0].CWS_Provisioning_Eligibility__c='NA';
        if(lstOLI!=null){
        update lstOLI;        
        }



        orderList[0].SBQQ__Contracted__c=true;
        if(orderList!=null){
        update orderList;
        }
        Test.StopTest();
         List<Contract> lstContracts =[SELECT Id,CWS_Renewal_Type__c, status, SBQQ__RenewalTerm__c,SBQQ__RenewalOwner__c,
                                        CWS_Renewal_Opportunity_Schedule__c, CWS_Renewal_Quote_Schedule__c, StartDate, ContractTerm, EndDate,
                                        Account.OwnerId, CWS_Renewal_CAP__c, CWS_Renewal_Uplift_Applicable__c from Contract];
        System.assertEquals(FALSE, lstContracts.isEmpty());
       
        
        lstContracts[0].StartDate=lstContracts[0].StartDate+10;
        lstContracts[0].CWS_Bill_to_Account__c=null;
       // lstContracts[0].SBQQ__RenewalForecast__c = true;
        if(lstContracts!=null  && !lstContracts.isEmpty()){
            update lstContracts[0];
        }
        
        List<Contract> updatedContracts=[Select id, StartDate, EndDate, ContractTerm, CWS_Renewal_Opportunity_Schedule__c, 
                                                CWS_Renewal_Quote_Schedule__c from Contract];
        CWS_ContractTriggerHandler obj = new CWS_ContractTriggerHandler();
        obj.AfterDelete(new Map<Id, SObject>());
        obj.BeforeDelete(new Map<Id, SObject>());
        obj.AfterUndelete(new Map<Id, SObject>());
       // System.assertEquals(updatedContracts[0].CWS_Renewal_Opportunity_Schedule__c, updatedContracts[0].endDate-120);
        //System.assertEquals(updatedContracts[0].CWS_Renewal_Quote_Schedule__c, updatedContracts[0].endDate-30);
    }
    
}