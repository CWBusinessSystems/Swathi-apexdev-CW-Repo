/*Class Name: CWS_ProductSearchPlugin_Test
*Description: Test Class for CWS_ProuctSearchPlugin
*Created By   : 
*Created On   : 
*Modification Log
*---------------------------------------------------------------------------------------------------------------
*Developer                          Date            User Story              Description
*
*--------------------------------------------------------------------------------------------------------------
*Last Modified: Megha Shetty        8/11/2020                               Test Class
 * Indra Ganesan                   25/8/2020                                Test Data Methods Bulkification
*/
@isTest(SeeAllData=false)
public class CWS_ProductSearchPlugin_Test{
    @testSetup
    static void createTestDataProductSearch(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Opportunity','SBQQ__Quote__c'});           
       
        //Create Sold To Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR'};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>true
           
        };
        Contact contact = CWS_UTLDataFactory.createContact('tst01 FName', 'tst01 lName', soldtoaccount.id,contactFieldValues, true);
        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
            'CWS_Is_Distributor__c'=> true
                
                };
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
        
        Contact primaryContact = CWS_UTLDataFactory.createContact('Mark', 'Anthony', distiaccounts[0].Id, contactFieldValues, true);
        
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', 'Automate;Sell', null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', 'Perch;Sell', null, true);
        
        /********** Create Opportunities**********************/
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'Name'=>'New Business Opty','CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD'
        };
        Map<String, Object> opportunityFields1=new Map<String, Object>{
            'Name'=>'New Business Opty1','CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'Amendment','CurrencyIsoCode'=>'USD'
        };
        Map<String, Object> opportunityFields2=new Map<String, Object>{
            'Name'=>'New Business Opty2','CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'Renewal with Change','CurrencyIsoCode'=>'USD'
        };
         Map<String, Object> opportunityFields3=new Map<String, Object>{
            'Name'=>'New Business Opty','CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD'
        };
        Map<Integer, Map<String, Object>> bulkOppCreationMap = new Map<Integer, Map<String, Object>>();
        bulkOppCreationMap.put(1, opportunityFields);
        bulkOppCreationMap.put(2, opportunityFields1);
        bulkOppCreationMap.put(3, opportunityFields2);    
        bulkOppCreationMap.put(4, opportunityFields3);      
        List<Opportunity> lstOpty = CWS_UTLDataFactory.createOpportunities(bulkOppCreationMap,bulkOppCreationMap.size(), true);
        /********** Create Opportunities**********************/
        
        /********** Create Quotes******************************/
        Map<String, Object> quoteFields2=new Map<String,Object>{
            'CWS_IsCloned__c'=>true,'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New', 'CWS_Quote_Type__c'=>'New Business', 'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Direct',
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CurrencyIsoCode'=>'USD','CWS_Bill_To_Account__c'=> distiAccounts[0].Id,
            'CWS_Ship_To_Account__c'=> distiAccounts[0].Id,'SBQQ__opportunity2__c'=>lstOpty[0].Id,'CWS_Master__c'=>true,'CWS_Distributor_Category__c'=>'Automate'
        };
        Map<String, Object> quoteFields3=new Map<String,Object>{
            'CWS_IsCloned__c'=>true,'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'Amendment', 'CWS_Quote_Type__c'=>'Amendment', 'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Channel',
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CurrencyIsoCode'=>'USD','CWS_Bill_To_Account__c'=> distiAccounts[0].Id,
             'CWS_Renewal_Category__c'=>'Opt-Out',
            'CWS_Ship_To_Account__c'=> distiAccounts[0].Id,'CWS_Bill_To_Contact__c'=>primaryContact.id,'SBQQ__opportunity2__c'=>lstOpty[1].Id,'CWS_Distributor_Category__c'=>'Automate'
        };
         Map<String, Object> quoteFields4=new Map<String,Object>{
            'CWS_IsCloned__c'=>true,'SBQQ__Status__c'=>'Approved', 'CWS_Quote_Type__c'=>'Renewal with Change', 'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Channel',
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CurrencyIsoCode'=>'USD','CWS_Bill_To_Account__c'=> distiAccounts[0].Id,
            'CWS_Ship_To_Account__c'=> distiAccounts[0].Id,'CWS_Bill_To_Contact__c'=>primaryContact.id,'SBQQ__opportunity2__c'=>lstOpty[2].Id,'CWS_Distributor_Category__c'=>'Automate'
         };
         Map<String, Object> quoteFields5=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New', 'CWS_Quote_Type__c'=>'New Business', 'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Channel',
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,'CurrencyIsoCode'=>'USD','CWS_Bill_To_Account__c'=> distiAccounts[0].Id,
            'CWS_Ship_To_Account__c'=> distiAccounts[0].Id,'SBQQ__opportunity2__c'=>lstOpty[3].Id,'CWS_Distributor_Category__c'=>'Automate'
        };
        Map<Integer, Map<String, Object>> bulkQuotesMap = new Map<Integer, Map<String, Object>>();
        bulkQuotesMap.put(1,quoteFields2);
        bulkQuotesMap.put(2,quoteFields3);
        bulkQuotesMap.put(3, quoteFields4);
         bulkQuotesMap.put(4,quoteFields5);
        List<SBQQ__Quote__c> lstQuotes = CWS_UTLDataFactory.createQuotes(bulkQuotesMap,bulkQuotesMap.size(), true);

        /********** Create Quotes******************************/
        
        Map<String, Object> productFields=new Map<String, Object>{
            'CWS_Base_SKU__c'=>'900901','CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12, 'CWS_Status__c'=>'Billing Only'
        };
        Product2 product=CWS_UTLDataFactory.createProduct(CWS_ConstantClass.Minimum_Commit_Prod, '900901',productFields,true);
        PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product.Id,1000.00,'USD', true);
        
        List<SBQQ__QuoteLine__c> quoteLineItem1 = CWS_UTLDataFactory.createQuoteLines(1, lstQuotes[1].Id, product.Id);
        quoteLineItem1[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem1[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem1[0].SBQQ__NetPrice__c= 3000;
        quoteLineItem1[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem1[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem1[0].CWS_Provisioning_Eligibility__c='Immediate';
        quoteLineItem1[0].CWS_ServicesProvisioned__c= false;
        quoteLineItem1[0].SBQQ__EndDate__c = Date.Today();
        quoteLineItem1[0].SBQQ__PriorQuantity__c = 2;
        if(quoteLineItem1!=null){
        insert quoteLineItem1;
        } 
    }
    //BED-1251
    @isTest
    static void testQuoteCategorySearch(){
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Test.startTest();
        User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org',
            'lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),FALSE); 
         
        System.runas(rep){
            CWS_ProductSearchPlugin plugin=new CWS_ProductSearchPlugin();

            List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)Database.query(
                'Select Id, Name, CWS_Distributor_Category__c,CurrencyIsoCode, CWS_Route_to_Market__c, CWS_Quote_Type__c from SBQQ__Quote__c ');
            System.debug('Quote2+ SBQQ__Type__c'+quoteList[1].CWS_Distributor_Category__c+quoteList[1].CWS_Quote_Type__c);
            String additionalFilters=CWS_ProductSearchPlugin.getAdditionalSearchFilters(quoteList[0], new Map<String, Object>());
            String additionalFilters1=CWS_ProductSearchPlugin.getAdditionalSearchFilters(quoteList[1], new Map<String, Object>());
            String additionalFilters2=CWS_ProductSearchPlugin.getAdditionalSearchFilters(quoteList[2], new Map<String, Object>());
            String additionalFilters3=CWS_ProductSearchPlugin.getAdditionalSearchFilters(quoteList[3], new Map<String, Object>());

            //system.assertNotEquals(NULL,additionalFilters);
            //system.assertEquals(TRUE, additionalFilters.containsIgnoreCase('Product2.CWS_Category__c'));
            
            //Adding the following method calls for Test class code coverage. 
            //Following methods are not used as part of the plugin.
            CWS_ProductSearchPlugin.isFilterHidden(quoteList[0], 'ProductCode');   
            CWS_ProductSearchPlugin.getFilterDefaultValue(quoteList[0], 'Family');
            CWS_ProductSearchPlugin.isSearchCustom(quoteList[0],null);
            CWS_ProductSearchPlugin.getInputDefaultValue(quoteList[0], null);
            CWS_ProductSearchPlugin.isSuggestCustom(quoteList[0], null);
            CWS_ProductSearchPlugin.isInputHidden(quoteList[0],'input');
            CWS_ProductSearchPlugin.search(quoteList[0],null);
            CWS_ProductSearchPlugin.getAdditionalSuggestFilters(quoteList[0],null);
            CWS_ProductSearchPlugin.suggest(quoteList[0], null);
            
        }
        Test.stopTest();
    }

}