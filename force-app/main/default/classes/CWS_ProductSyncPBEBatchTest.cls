/*Class Name: CWS_DiscountTierHelperTest
*Description: Test Class for CWS_DiscountTierTriggerHelper
*Created By: Indra Ganesan
*Created On: 31-07-2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            Description
*------------------------------------------------------------------------------------------
*Indra Ganesan         31-07-2020       Test Class for CWS_DiscountTierTriggerHelper             
*/
@isTest(SeeAllData=false)
public with Sharing class CWS_ProductSyncPBEBatchTest {
    @TestSetup
    static void init(){
        List<Product2> lstProduct= new List<Product2>();        
        Product2 p = new Product2(
            Name='Demo Test Product',
            CWS_ProductCode__c='DEMQ9009',
            CWS_Category__c='Sell',
            SBQQ__BillingType__c='Advance',
            SBQQ__PricingMethod__c='Cost',
            SBQQ__SubscriptionTerm__c=12,
            CWS_Description__c='Cloud Access DW Security',     
            CWS_Charge_Model__c='Per Unit Pricing',
            CWS_Product_Family__c='Other',
            CWS_License_Type__c='SaaS',
            CWS_Product_Line__c='Corporate',
            CWS_Status__c='Active',
            CWS_Sub_Category__c='License',
            CW_Product_Type__c='Product',
            CWS_SKU_Type__c='Other',
            CWS_Renewal_Type__c='Opt-out',
            CWS_Route_to_Market__c='Direct',
            CWS_Currencies__c='USD',
            CWS_Billing_Term__c='Monthly',
            CWS_ChargeType__c='Recurring',
            CWS_Item_Revenue_Category__c='Services',
            IsActive= True,
            SBQQ__SubscriptionPricing__c='Fixed Pricing',
            CWS_UOM__c='Cost'     
        );
        
        insert P;       
        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id=Test.getStandardPricebookId(), Product2Id = p.Id, UnitPrice = 1000, IsActive = true);
        insert standardPBE;
        Pricebook2 pbCW =CWS_UTLDataFactory.createCustomPB('ConnectWise Standard PriceBook', true);     
        PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(pbCW.Id,p.id,1000.00,'USD', true);      
    }
    
    @isTest 
    static void testProductSyncBatch() 
    {
        Test.startTest();
		Pricebook2 pb = [SELECT Id, Name , isActive from Pricebook2 where name='ConnectWise Standard PriceBook'];
		List<PricebookEntry> lstPriceBookEntry = [Select Id,Product2.IsActive, Pricebook2.Name,Product2Id,CWS_Price_Modified__c,pricebook2Id,CurrencyIsoCode, UnitPrice, CWS_CostPrice__c, IsActive from PricebookEntry where IsActive = True  and Product2.IsActive = True and CWS_Price_Modified__c= True and Pricebook2.Name = 'System.Label.CWS_ConnectwisePricebook' limit 1];       
		CWS_ProductSyncPBEBatch tstBatch = new CWS_ProductSyncPBEBatch();
		DataBase.executeBatch(tstBatch);
		System.assertEquals(true,lstPriceBookEntry.size() !=null);
        Test.stopTest();
    }

}