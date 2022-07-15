/*Class Name: CWS_OpportunityLineItemHelperTest
*Description: Test Class for CWS_OpportunityLineItemHelperTest
*Created By: Aditya
*Created On: 5/22/2020
*/
@isTest
private class CWS_OpportunityLineItemHelperTest {

    @testSetup static void createTestData() {
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'OpportunityLineItem'}); 
        // TO DO: implement unit test
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'BillingCountry'=>'United States',
            'BillingCountryCode'=>'US',
            'currencyIsoCode'=>'USD'
            };
        Account acc =CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        //Creating Contact for the Account
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
            'CWS_Primary_Contact__c' => true,
            'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
            'Email'=>'test@test.com',
            'MailingCountry'=>'United States'
        };
        Contact con = CWS_UTLDataFactory.createContact('TestFirstName','TestLastName',acc.Id,mapConFieldValues,true);
        //String id = CWS_ConstantClass.Opportunity_CommissionOnly;
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 
            'CloseDate'=> Date.today(),
            'CWS_Bill_To_Account__c'=> acc.Id,
            'Type'=>'Commission Only',
            'CurrencyIsoCode'=>'USD',
            'CWS_Bill_To_Contact__c'=>con.id,
            'RecordTypeId'=>CWS_ConstantClass.Opportunity_CommissionOnly
            };
        Opportunity opp = CWs_UTLDataFactory.createOpportunity('Test Opp',acc.Id, opportunityFields, true);
        
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        Pricebook2 ConnectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
        if(ConnectwisePricebook!=null){
            insert ConnectwisePricebook;
        }
        Map<String,Object> additionalFields = new Map<String, Object>();
        Product2 prod = CWS_UTLDataFactory.createProduct('Dummy Product', 'TRDF', additionalFields, True);
        prod.CWS_Category__c = 'Automate';
        prod.CWS_EF_Attribute__c = 'Service';
        prod.SBQQ__SubscriptionTerm__c = 12;
        prod.CWS_SKU_Type__c = 'Products';
        prod.CWS_License_Type__c = 'Saas';
        prod.IsActive = true;
        if(prod!=null){
           upsert prod; 
        }
        List<String> currencyCode = new List<String>{'USD'};
        List<Pricebookentry> pbeList = CWS_UTLDataFactory.createPBEList(standardPricebook.ID, prod.Id, 100 ,currencyCode);
        List<Pricebookentry> pbeList1 = CWS_UTLDataFactory.createPBEList(ConnectwisePricebook.ID, prod.Id, 100 ,currencyCode);
        pbeList.addAll(pbeList1);
        if(pbeList.size()>0){
            insert pbeList;
        }
    }
    
    @isTest public static void testMethod1(){
        Test.startTest();
         List<Opportunity> oppList = [Select id from Opportunity];
         List<Product2> prodList = [Select id,CWS_SKU_Type__c,CWS_License_Type__c from Product2];
         List<PriceBookEntry> pbeList = [Select id from PriceBookEntry];
         OpportunityLineItem oppProd = new OpportunityLineItem();
         oppProd.OpportunityId = oppList[0].Id;
         oppProd.Quantity = 1;
         oppProd.Product2Id = prodList[0].Id;
         oppProd.PricebookEntryId = pbeList[0].Id;
         oppProd.CWS_Commission_Only__c = true;
         //oppProd.CWS_Subscription_Number__c = 12;
         //oppProd.CWS_SKU_Type__c = prodList[0].CWS_SKU_Type__c;
         oppProd.CWS_License_Type__c = prodList[0].CWS_License_Type__c;
         oppProd.TotalPrice = 100;
         if(oppProd!=null){
            insert oppProd;
         }
         oppProd.Quantity = 10;
         oppProd.UnitPrice = 100;
         if(oppProd!=null){
            update oppProd;
         }
         System.assertEquals(oppProd.CWS_Commission_Only__c, True);
        Test.stopTest();
        
         //These methods are directly called because of the reason that the trigger context are not firing on them and
        //if we try to save handler removing these context ot throws compile error as its implementing interface
        CWS_OpportunityLineItemTriggerHandler handler = new CWS_OpportunityLineItemTriggerHandler();
        map<id,OpportunityLineItem> newRecs = new map<id,OpportunityLineItem>();
        handler.AfterInsert(newRecs);
        handler.BeforeDelete(newRecs);
        handler.AfterDelete(newRecs);
        handler.AfterUndelete(newRecs);
        handler.AfterUpdate(newRecs,newRecs);
    }
}