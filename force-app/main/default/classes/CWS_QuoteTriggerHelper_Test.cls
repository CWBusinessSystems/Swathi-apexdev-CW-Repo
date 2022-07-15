/*Class Name: CWS_QuoteTriggerHelper_Test
*Description: Test Class for CWS_QuoteTriggerHelper
*Created By: Aakash Sharma
*Created On: 4/7/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aakash                 04/03/2020        BED-3696              Quote Cloning
*Ad Victoriam Solutions 02/14/2022          N/A                 Expanded test class coverage for required deployment.
*/

@IsTest(SeeAllData=false)
public class CWS_QuoteTriggerHelper_Test {

    @TestSetup
    private static void testSetup() {
        insertUserAndPermissionSetAssignment();

        CWS_SSOUpdatedAccountContacts.recursion = false;

        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{
                'Quote',
                'SBQQ__QuoteDocument__c'
            }
        );

        CWS_Trigger_Switch__c objTriggerSwitch = CWS_Trigger_Switch__c.getInstance();
        objTriggerSwitch.CWS_AccountTrigger__c = false;
        objTriggerSwitch.CWS_OpportunityTrigger__c = false;
        objTriggerSwitch.CWS_QLITrigger__c = false;
        insert objTriggerSwitch;

        CWS_Bypass_Settings__c bypassValidate = new CWS_Bypass_Settings__c ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c = 'SBQQ__QuoteDocument__c;SBQQ__Quote__c;';
        insert bypassValidate;

        CWS_Create_Order_Switch__c orderSwitch = new CWS_Create_Order_Switch__c();
        orderSwitch.Name = 'create Order';
        orderSwitch.CWS_Create_Order_When_Quote_Is_Accepted__c = true;
        insert orderSwitch;

        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues = new Map<String, Object>{
                'SBQQ__PriceHoldEnd__c' => Date.valueOf('2020-01-01'),
                'currencyIsoCode' => 'EUR',
                'CWS_Is_Distributor__c' => true,
                'CWS_BA_Agreement__c' => 'TestBA',
                'CWS_BA_Agreement_Status__c' => 'Request',
                'CWS_MSA_Agreement__c' => 'TestMSA',
                'CWS_MSA_Agreement_Status__c' => 'Request',
                'CWS_NDA_Agreement__c' => 'NDAStatus',
                'CWS_NDA_Agreement_Status__c' => 'Request',
                'CWS_Need_Recurring__c' => true
        };
        Account soldtoaccount = CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues, true);

        Map<String, Object> contAdditionalFieldValues = new Map<String, Object>{
                'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL,
                'CWS_Quote_SubType__c' => 'Credit',
                'CWS_OF_Signed_Date__c' => System.today(),
                'StartDate' => System.today(),
                'ContractTerm' => 12
        };

        Contract cont = CWS_UTLDataFactory.createContract(soldtoaccount.Id, contAdditionalFieldValues, true);

        Map<String, Object> contAdditionalFieldValues1 = new Map<String, Object>{
                'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL,
                'CWS_Quote_SubType__c' => 'Credit',
                'CWS_OF_Signed_Date__c' => System.today(),
                'StartDate' => System.today(),
                'ContractTerm' => 12
                //'EndDate' =>System.today()+ 2
        };
        Contract cont2 = CWS_UTLDataFactory.createContract(soldtoaccount.Id, contAdditionalFieldValues1, true);


        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues = new Map<String, Object>{
                'SBQQ__PriceHoldEnd__c' => Date.valueOf('2020-01-01'),
                'currencyIsoCode' => 'EUR',
                'CWS_Is_Partner__c' => true,
                'CWS_Is_Distributor__c' => true,
                'CWS_Need_Recurring__c' => true
        };
        Account[] distiAccounts = CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues, 3, true);

        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id, distiAccounts[0].Id, CWS_ConstantClass.DISTRIBUTOR_TYPE, 'Deal Reg', null, null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id, distiAccounts[1].Id, 'Distributor', 'Fulfillment', null, null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id, distiAccounts[2].Id, CWS_ConstantClass.RESELLER_TYPE, 'Deal Reg', null, null, true);

        // Create Opportunity1
        Map<String, Object> opportunityFields = new Map<String, Object>{
                'CWS_Route_to_Market__c' => 'Channel', 'CloseDate' => Date.today(), 'CWS_Bill_To_Account__c' => soldtoaccount.Id,
                'Type' => 'New', 'CurrencyIsoCode' => 'USD', 'StageName' => 'Prospecting'
        };
        Opportunity opty = CWS_UTLDataFactory.createOpportunity('New Business Opty', soldtoaccount.Id, opportunityFields, true);


        // Create Opportunity2
        Map<String, Object> opportunityFields1 = new Map<String, Object>{
                'CWS_Route_to_Market__c' => 'IIT',
                'CloseDate' => Date.today(),
                'CWS_Bill_To_Account__c' => soldtoaccount.Id,
                'Type' => 'New',
                'CurrencyIsoCode' => 'USD'
        };
        Opportunity opty2 = CWS_UTLDataFactory.createOpportunity('NewIIT', soldtoaccount.Id, opportunityFields1, true);


        //Create opp3
        Map<String, Object> opportunityFields2 = new Map<String, Object>{
                'CWS_Route_to_Market__c' => 'Direct', 'CloseDate' => Date.today(), 'CWS_Bill_To_Account__c' => soldtoaccount.Id,
                'Type' => 'New', 'CurrencyIsoCode' => 'USD', 'CWS_Master__c' => true
        };
        Opportunity opty3 = CWS_UTLDataFactory.createOpportunity('MasterTrue', soldtoaccount.Id, opportunityFields2, true);

        // Create Opportunity4
        Map<String, Object> opportunityFields4 = new Map<String, Object>{
                'CWS_Route_to_Market__c' => 'Channel', 'CloseDate' => Date.today(), 'CWS_Bill_To_Account__c' => soldtoaccount.Id,
                'Type' => 'New', 'CurrencyIsoCode' => 'USD'
        };
        Opportunity opty4 = CWS_UTLDataFactory.createOpportunity('NB2', soldtoaccount.Id, opportunityFields4, true);

        // Create Opportunity5
        Map<String, Object> opportunityFields5 = new Map<String, Object>{
                'CWS_Route_to_Market__c' => 'Channel', 'CloseDate' => Date.today(), 'CWS_Bill_To_Account__c' => soldtoaccount.Id,
                'Type' => 'Amendment', 'CurrencyIsoCode' => 'USD'
        };
        Opportunity opty5 = CWS_UTLDataFactory.createOpportunity('Amendment op', soldtoaccount.Id, opportunityFields5, true);

        //Create Quote record
        Map<String, Object> quoteFields = new Map<String, Object>{
                'SBQQ__Status__c' => 'Approved', 'CWS_Quote_Type__c' => 'Renewal',
                'CWS_Bill_to_Account__c' => distiAccounts[0].Id,
                'CWS_Agreement_Numbers__c' => 'ABC123456',
                'CWS_Route_to_Market__c' => 'IIT',
                'CWS_Reseller_Account__c' => distiAccounts[2].Id
        };
        SBQQ__Quote__c quoteWithEconomicFactorQL = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opty2.Id, quoteFields, true);

        Map<String, Object> quoteFields2 = new Map<String, Object>{
                'SBQQ__Status__c' => 'Approved',
                'CWS_Quote_Type__c' => 'New Business',
                // 'SBQQ__Primary__c'=>true,
                'recordtypeid' => CWS_ConstantClass.QUOTE_RTYPE_NEW_EDIT,
                'CWS_Add_Terms_Manually__c' => 'Test12345666666666',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Bill_to_Account__c' => distiAccounts[0].Id
                //'CWS_Route_to_Market__c'=> CWS_ConstantClass.RTM_Value_Channel
        };

        SBQQ__Quote__c quote2 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opty.Id, quoteFields2, true);

        Map<String, Object> quoteFields3 = new Map<String, Object>{
                'SBQQ__Status__c' => 'Approved',
                'CWS_Quote_Type__c' => 'New Business',
                'SBQQ__Primary__c' => true,
                'recordtypeid' => CWS_ConstantClass.QUOTE_RTYPE_NEW_EDIT,
                'CWS_Add_Terms_Manually__c' => 'Test123456',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Bill_to_Account__c' => distiAccounts[0].Id,
                'CWS_Reference_Expiry_Date__c' => null,
                'CWS_IsCloned__c' => false,
                'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_Channel,
                'CWS_Agreement_Numbers__c' => 'ABC1234'
        };
        Test.startTest();
        SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opty.Id, quoteFields3, true);


        Map<String, Object> quoteFields5 = new Map<String, Object>{
                'SBQQ__Primary__c' => true,
                'SBQQ__Type__c' => 'Amendment',
                'CWS_Quote_Type__c' => 'Amendment',
                'CWS_Add_Terms_Manually__c' => 'Test123456',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Bill_to_Account__c' => distiAccounts[0].Id,
                'CWS_Reference_Expiry_Date__c' => null,
                'CWS_IsCloned__c' => false,
                'RecordTypeId' => CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY,
                'SBQQ__WatermarkShown__c' => false,
                'CWS_Route_to_Market__c' => 'Channel'
        };
        SBQQ__Quote__c quote5 = CWS_UTLDataFactory.createQuote(soldtoaccount.id, opty.Id, quoteFields5, true);

        Map<String, Object> docFields = new Map<String, Object>{
                'SBQQ__SignatureStatus__c' => '',
                'SBQQ__ElectronicSignature__c' => false,
                'CWS_Offline_Signature_Status__c' => CWS_ConstantClass.QDOC_SIG_SIGNED,
                'SBQQDS__VoidedReason__c' => 'Quote has expired. Please Contact Your salesrep'
        };

        SBQQ__QuoteDocument__c doc = CWS_UTLDataFactory.createQuoteDocument(quote5.id, docFields, true);

        List<Product2> prodList = new List<Product2>();
        Map<String, Object> productFields = new Map<String, Object>{
                'CWS_Category__c' => 'Automate', 'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 'SBQQ__SubscriptionTerm__c' => 12,
                'CWS_Charge_Model__c' => 'Per Unit Pricing',
                'CWS_License_Type__c' => 'SaaS',
                'CWS_Route_to_Market__c' => 'Direct',
                'CWS_SKU_Type__c' => 'Package',
                'CWS_UOM__c' => 'Each',
                'CWS_Sub_Category__c' => 'License',
                'CWS_Currencies__c' => 'USD;CAD;AUD;EUR;GBP',
                'CWS_Status__c' => 'Active',
                'CWS_Billing_Term__c' => 'Monthly',
                'CWS_Product_Family__c' => 'BDR',
                'CW_Product_Type__c' => 'Charge',
                'CWS_ChargeType__c' => 'Usage',
                'CWS_Item_Revenue_Category__c' => 'Saas-Billing',
                'CWS_Renewal_Type__c' => 'Opt-out',
                'CWS_Product_Line__c' => 'None',
                'SBQQ__BillingType__c' => 'Advance',
                'SBQQ__PricingMethod__c' => 'List',
                'Description' => 'Test',
                'CWS_Description__c' => 'Test',
                'CWS_Base_SKU__c' => '900901'

        };
        Product2 product1 = CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123', productFields, false);
        product1.SBQQ__SubscriptionType__c = 'Renewable';
        product1.SBQQ__SubscriptionBase__c = 'List';
        prodList.add(product1);

        Map<String, Object> productFields1 = new Map<String, Object>{
                'CWS_Category__c' => 'Other', 'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 'SBQQ__SubscriptionTerm__c' => 1,
                'CWS_Charge_Model__c' => 'Per Unit Pricing',
                'CWS_License_Type__c' => 'Other',
                'CWS_Route_to_Market__c' => 'Direct',
                'CWS_SKU_Type__c' => 'Fee',
                'CWS_UOM__c' => 'Each',
                'CWS_Sub_Category__c' => 'Other',
                'CWS_Currencies__c' => 'USD;CAD;AUD;EUR;GBP',
                'CWS_Status__c' => 'Active',
                'CWS_Billing_Term__c' => 'Monthly',
                'CWS_Product_Family__c' => 'Other',
                'CW_Product_Type__c' => 'Product',
                'CWS_ChargeType__c' => 'Usage',
                'CWS_Item_Revenue_Category__c' => ' Other-Billing',
                'CWS_Renewal_Type__c' => 'Opt-out',
                'CWS_Product_Line__c' => 'None',
                'SBQQ__BillingType__c' => ' Arrears',
                'SBQQ__PricingMethod__c' => 'List',
                'Description' => 'Test',
                'CWS_Description__c' => 'Minimum Commitment Charge',
                'CWS_Base_SKU__c' => '900901'

        };

        Product2 product2 = CWS_UTLDataFactory.createProduct('Minimum Commitment Charge', 'CU-OTHERSAAS900901', productFields1, false);
        product2.SBQQ__SubscriptionType__c = 'Renewable';
        product2.SBQQ__SubscriptionBase__c = 'List';
        prodList.add(product2);
        insert prodList;

        PricebookEntry pbe1 = CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(), product1.Id, 1000, 'USD', true);
        PricebookEntry pbe2 = CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(), product2.Id, 1, 'USD', true);

        //Min commit
        Map<String, Object> quoteFields4 = new Map<String, Object>{
                'SBQQ__Status__c' => 'Approved',
                'CWS_Quote_Type__c' => 'New Business',
                'SBQQ__Primary__c' => true,
                'recordtypeid' => CWS_ConstantClass.QUOTE_RTYPE_NEW_EDIT,
                'CWS_Add_Terms_Manually__c' => 'Test123456',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Bill_to_Account__c' => distiAccounts[0].Id,
                'CWS_Reference_Expiry_Date__c' => null,
                'CWS_IsCloned__c' => false,
                'CWS_Route_to_Market__c' => 'Direct'
        };

        CWS_Economic_Factor__c  efUnmatched = new CWS_Economic_Factor__c();
        // these three fields make up a "keyString"
        efUnmatched.CWS_Category__c = 'Other';
        efUnmatched.CWS_Product_Type__c = 'Product';
        efUnmatched.CurrencyIsoCode = 'CAD';
        efUnmatched.CWS_Economic_Factor__c = 1.7;
        efUnmatched.CWS_UniqueId__c = 'USD__Unite__Service';
        insert efUnmatched;

        List<SBQQ__QuoteLine__c> createdQuoteLines = CWS_UTLDataFactory.createQuoteLines(1, quoteWithEconomicFactorQL.Id, pbe1.Product2Id);
        createdQuoteLines[0].SBQQ__PricebookEntryId__c = pbe1.Id;
        createdQuoteLines[0].CWS_Base_SKU__c = '900901';
        createdQuoteLines[0].CWS_Custom_sow__c = true;
        createdQuoteLines[0].SBQQ__Quote__c = quoteWithEconomicFactorQL.Id;
        createdQuoteLines[0].CWS_Economic_Factor__c = efUnmatched.CWS_Economic_Factor__c;
        // these three fields make up a "keyString" for a matching Economic Factor
        createdQuoteLines[0].CWS_Category__c = 'Other';
        createdQuoteLines[0].CWS_EF_Attribute__c = 'Product';
        createdQuoteLines[0].CurrencyIsoCode = 'USD';
        insert createdQuoteLines[0];

        CWS_Economic_Factor__c  ef = new CWS_Economic_Factor__c();
        // these three fields make up a "keyString"
        ef.CWS_Category__c  = 'Other';
        ef.CWS_Product_Type__c  = 'Product';
        ef.CurrencyIsoCode = 'USD';
        ef.CWS_Economic_Factor__c = 1.4;
        ef.CWS_UniqueId__c = 'USD__Unite__Service';
        insert ef;



        /*
        SBQQ__Quote__c quote4=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty3.Id, quoteFields4, true);
        CWS_Promotion__c promo = new CWS_Promotion__c();
        promo.CWS_Promo_Code__c = 'test';
        //promo.CWS_Active__c ='Active';
        promo.CWS_End_date__c = System.today();
        promo.CWS_Start_Date__c = System.today();
        promo.CWS_Category__c = 'Automate;';
        insert promo;
        
        CWS_Quote_Overage_Uplift_Percentage__c upliftPer = new CWS_Quote_Overage_Uplift_Percentage__c();
        upliftPer.CWS_Overage_Uplift_Percentage__c  = 25;
        insert upliftPer;
        */

    }

    @IsTest
    private static void testCloneQuote_NewBusiness() {
        List<SBQQ__Quote__c> testQuotes = [
                SELECT
                        Id,
                        CWS_Quote_Type__c,
                        SBQQ__Type__c,
                        SBQQ__Status__c,
                        SBQQ__Opportunity2__r.CurrencyIsoCode
                FROM SBQQ__Quote__c
        ];

        Test.startTest();
        SBQQ__Quote__c clonedQuote = testQuotes.get(0).clone(false, false, false, false);
        clonedQuote.SBQQ__Status__c = 'Draft';
        clonedQuote.CurrencyIsoCode = clonedQuote.SBQQ__Opportunity2__r.CurrencyIsoCode;
        clonedQuote.CWS_Quote_Type__c = CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS;
        clonedQuote.CWS_Add_Terms_Manually__c = 'testqwe';
        clonedQuote.CWS_Route_to_Market__c = CWS_ConstantClass.RTM_Value_IIT;

        insert clonedQuote;
        Test.stopTest();
    }

    @IsTest
    private static void testCloneQuote_Renewal() {
        List<SBQQ__Quote__c> testQuotes = [
                SELECT
                        Id,
                        CWS_Quote_Type__c,
                        SBQQ__Type__c,
                        SBQQ__Status__c,
                        SBQQ__Opportunity2__r.CurrencyIsoCode
                FROM SBQQ__Quote__c
        ];

        Test.startTest();
        SBQQ__Quote__c clonedQuote = testQuotes.get(0).clone(false, false, false, false);
        clonedQuote.SBQQ__Status__c = 'Draft';
        clonedQuote.CurrencyIsoCode = clonedQuote.SBQQ__Opportunity2__r.CurrencyIsoCode;
        clonedQuote.CWS_Quote_Type__c = 'Renewal';
        clonedQuote.CWS_Add_Terms_Manually__c = 'testqwe';
        clonedQuote.CWS_Route_to_Market__c = CWS_ConstantClass.RTM_Value_IIT;
        clonedQuote.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptIn;
        insert clonedQuote;
        Test.stopTest();

    }

    @IsTest
    private static void testCloneQuote_Amendment() {

        List<SBQQ__Quote__c> testQuotes = [
                SELECT
                        Id,
                        CWS_Quote_Type__c,
                        SBQQ__Type__c,
                        SBQQ__Status__c,
                        SBQQ__Opportunity2__r.CurrencyIsoCode
                FROM SBQQ__Quote__c
        ];
        Test.startTest();
        SBQQ__Quote__c clonedQuote = testQuotes.get(0).clone(false, false, false, false);
        clonedQuote.SBQQ__Status__c = 'Draft';
        clonedQuote.CurrencyIsoCode = clonedQuote.SBQQ__Opportunity2__r.CurrencyIsoCode;
        clonedQuote.CWS_Quote_Type__c = 'Amendment';
        clonedQuote.CWS_Add_Terms_Manually__c = 'testqwe';
        clonedQuote.CWS_Route_to_Market__c = CWS_ConstantClass.RTM_Value_IIT;
        insert clonedQuote;
        Test.stopTest();
    }

    @IsTest
    private static void testCloneQuote_AmendmentWithLegacy() {

        List<SBQQ__Quote__c> testQuotes = [
                SELECT
                        Id,
                        CWS_Quote_Type__c,
                        SBQQ__Type__c,
                        SBQQ__Status__c,
                        SBQQ__Opportunity2__r.CurrencyIsoCode
                FROM SBQQ__Quote__c
        ];

        Test.startTest();
        SBQQ__Quote__c clonedQuote = testQuotes.get(0).clone(false, false, false, false);
        clonedQuote.SBQQ__Status__c = 'Draft';
        clonedQuote.CurrencyIsoCode = clonedQuote.SBQQ__Opportunity2__r.CurrencyIsoCode;
        clonedQuote.CWS_Quote_Type__c = 'Amendment';
        clonedQuote.CWS_Add_Terms_Manually__c = 'testqwe';
        clonedQuote.CWS_Route_to_Market__c = CWS_ConstantClass.RTM_Value_IIT;
        clonedQuote.CWS_LegacyKey__c = '1232352';
        insert clonedQuote;
        Test.stopTest();

    }

    @IsTest
    private static void updateDistributorFulfillmentType_DealReg() {
        String expectedDistributorFulfillmentType = 'Deal Reg';
        testDistributorFulfillmentType(expectedDistributorFulfillmentType);
    }

    @IsTest
    private static void updateDistributorFulfillmentType_Fulfillment() {
        String expectedDistributorFulfillmentType = 'Fulfillment';
        testDistributorFulfillmentType(expectedDistributorFulfillmentType);
    }

    private static void testDistributorFulfillmentType(String expectedDistributorFulfillmentType) {
        SBQQ__Quote__c testQuote = [
                SELECT
                        Id,
                        CWS_Distributor_Fulfillment_Type__c,
                        SBQQ__Distributor__c,
                        SBQQ__Account__c,
                        SBQQ__Status__c
                FROM SBQQ__Quote__c
                LIMIT 1
        ];

        CWS_Distributor_Reseller__c testDistributor = [
                SELECT
                        CWS_Fulfillment_Type__c,
                        CWS_Distributor_ResellerAcc__c
                FROM CWS_Distributor_Reseller__c
                WHERE CWS_Account__c = :testQuote.SBQQ__Account__c
                AND CWS_Type__c = 'Distributor'
                AND CWS_Fulfillment_Type__c = :expectedDistributorFulfillmentType
                LIMIT 1
        ];

        testQuote.SBQQ__Distributor__c = testDistributor.CWS_Distributor_ResellerAcc__c;

        Test.startTest();
        update testQuote;
        Test.stopTest();

        SBQQ__Quote__c actualResultQuote = [
                SELECT CWS_Distributor_Fulfillment_Type__c
                FROM SBQQ__Quote__c
                WHERE Id = :testQuote.Id
                LIMIT 1
        ];

        System.assertEquals(expectedDistributorFulfillmentType, actualResultQuote.CWS_Distributor_Fulfillment_Type__c);
    }


    @IsTest
    static void testOrderGeneration() {

        SBQQ__Quote__c testQuote = [
                SELECT
                        Id
                FROM SBQQ__Quote__c
                WHERE SBQQ__Primary__c = TRUE
                    AND SBQQ__Ordered__c = FALSE
                LIMIT 1
        ];

        testQuote.SBQQ__Status__c = 'Accepted';
        testQuote.SBQQ__ExpirationDate__c = System.today();

        Test.startTest();
        update testQuote;
        Test.stopTest();

    }

    @IsTest
    private static void recallQuoteFutureHelperTest() {
        SBQQ__Quote__c testQuote = [
                SELECT Id
                FROM SBQQ__Quote__c
                LIMIT 1
        ];

        Test.startTest();
        CWS_QuoteTriggerHelper.recallQuoteFutureHelper(new List<Id>{testQuote.Id});
        Test.stopTest();

    }

    @IsTest
    private static void assignDraftToApprovedValuesForOverageQLI_Test() {
        SBQQ__QuoteLine__c quoteLine = [
                SELECT
                        Id,
                        CWS_Overage_Price__c,
                        CWS_Overage_Unit_Price__c,
                        SBQQ__Quote__r.CWS_Original_Overage_Uplift__c,
                        SBQQ__Quote__r.CWS_Overage_Uplift_Percentage__c
                FROM SBQQ__QuoteLine__c
                LIMIT 1
        ];

        quoteLine.CWS_Overage_Unit_Price__c = 100;
        quoteLine.SBQQ__Quote__r.CWS_Original_Overage_Uplift__c = 10.0;
//        quoteLine.SBQQ__Quote__r.CWS_Overage_Uplift_Percentage__c = 15.0;
        quoteLine.CWS_Overage_Price__c = 200;
 
        Test.startTest();
        CWS_QuoteTriggerHelper.assignDraftToApprovedValuesForOverageQLI(quoteLine);
        Test.stopTest();
    }

    //BED-5671
    @IsTest
    private static void testBeforeInsertHelper() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            User[] rep = [
                    SELECT
                            Id,
                            Name,
                            Username
                    FROM User
                    WHERE LastName = 'SalesRep_TestUser'
                        AND Profile.Name = 'CWS_Sales_Rep'
            ];


            Map<String, Object> soldtoaccountFieldValues = new Map<String, Object>{
                    'SBQQ__PriceHoldEnd__c' => Date.valueOf('2020-01-01'),
                    'currencyIsoCode' => 'EUR',
                    'CWS_Region__c' => 'NA',
                    'ownerId' => rep[0].Id,
                    'BillingCountry' => 'India',
                    'BillingStreet' => 'S1',
                    'BillingCity' => 'Hyderabad',
                    'BillingPostalCode' => '492001',
                    'CWS_Account_Restriction_Status__c' => 'Credit Hold'
            };
            Account soldtoAccount = CWS_UTLDataFactory.createAccount('TestAccountwithRegionQuote1', soldtoaccountFieldValues, true);
            Contact soldtoContact = CWS_UTLDataFactory.createContact('soldToFirstName', 'soldToLastName', soldtoAccount.Id, new Map<String, Object>{
            }, true);
            Account billtoAccount = CWS_UTLDataFactory.createAccount('BilltoAccount', soldtoaccountFieldValues, true);
            Contact billtoContact = CWS_UTLDataFactory.createContact('billToFirstName', 'billToLastName', billToAccount.Id,
                    new Map<String, Object>{
                            'CWS_Primary_Billing_Contact__c' => true
                    }, true);
            Account shiptoAccount = CWS_UTLDataFactory.createAccount('ShiptoAccount', soldtoaccountFieldValues, true);

            List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
            for (PermissionSet pset : [SELECT Id FROM PermissionSet WHERE Name = 'SteelBrickCPQUser']) {
                psa.add(new PermissionSetAssignment(AssigneeId = rep[0].Id, PermissionSetId = pset.Id));
            }
            if (!psa.isEmpty()) {
                System.debug('psa--' + psa);
                insert psa;
            }

            System.runAs(rep[0]) {
                // Create Opportunity
                Map<String, Object> opportunityFields = new Map<String, Object>{
                        'CWS_Route_to_Market__c' => 'Direct',
                        'CloseDate' => Date.today(),
                        'CWS_Bill_To_Account__c' => billtoAccount.Id,
                        'Type' => 'New',
                        'CurrencyIsoCode' => 'USD',
                        'CWS_Ship_to_Account__c' => shiptoAccount.Id,
                        'CWS_Sold_to_Contact__c' => soldtoContact.Id,
                        'CWS_Bill_to_Contact__c' => billToContact.Id,
                        'CWS_Legal_Entity__c' => 'CW-US',
                        'CWS_Competitor_Takeaway_BDR__c' => 'NetApp'
                };
                Opportunity opty = CWS_UTLDataFactory.createOpportunity('TestOptyWithRegion', soldtoAccount.Id, opportunityFields, true);

                Map<String, Object> quoteFields2 = new Map<String, Object>{
                        'SBQQ__Status__c' => 'Draft', 'SBQQ__Type__c' => 'New', 'SBQQ__Primary__c' => true, 'CWS_Promo_Code__c' => 'test'
                };
                SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(soldtoAccount.Id, opty.Id, quoteFields2, true);
                quote.CWS_Promo_Code__c = null;
                update quote;
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testSubmitForApproval01() {
        Test.startTest();
        List<SBQQ__Quote__c> quotes = [SELECT id, ApprovalStatus__c,SBQQ__Account__c,SBQQ__Status__c from SBQQ__Quote__c];

        if (!quotes.isEmpty()) {

            quotes[0].ApprovalStatus__c = 'Pending';
            update quotes[0];
            quotes[0].ApprovalStatus__c = 'Approved';
            update quotes[0];
            quotes[0].ApprovalStatus__c = 'Pending';
            update quotes[0];


            CWS_SubmitQuoteForApproval.submitForApproval(quotes[0].id);

            Test.StopTest();
        }
    }

    @isTest
    static void testSubmitForApproval02() {
        Test.startTest();
        List<SBQQ__Quote__c> quotes = [SELECT id, ApprovalStatus__c,SBQQ__Account__c,SBQQ__Status__c from SBQQ__Quote__c];

        if (!quotes.isEmpty()) {

            quotes[0].ApprovalStatus__c = 'Rejected';
            update quotes[0];
            quotes[0].ApprovalStatus__c = 'Recalled';
            update quotes[0];

            CWS_SubmitQuoteForApproval.submitForApproval(quotes[0].id);

            Test.StopTest();
        }
    }

    @isTest
    static void testRenewal() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        Test.startTest();
        Opportunity opp = [Select id from Opportunity where name = 'NB2'] ;
        opp.Type = 'Renewal';
        opp.CWS_On_Hold__c = true;
        opp.CWS_On_Hold_Reason__c = 'ttest';
        // opp.CWS_Master__c = true;
        Account soldtoaccount = [select id from Account where name = 'TestAccount'];
        Contract con = [Select id from Contract limit 1];
        con.CWS_Renewal_Uplift_Applicable__c = 2;
        opp.SBQQ__RenewedContract__c = con.id;


        User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org', 'lName', 'CWS_Sales_Rep',
                'CEO', uniqueName + '@test' + orgId + '.org', new Map<String, Object>(), true);
        User rep1 = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 21), uniqueName + '@test12' + orgId + '.2org', '1lName', 'CWS_Global_Sales_Ops',
                'CEO', uniqueName + '@test.com' + orgId + '.2org', new Map<String, Object>(), true);
        update opp;
        update con;
        Map<String, Object> quoteFields3 = new Map<String, Object>{
                //  'SBQQ__Status__c'=>'Draft',
                'SBQQ__Type__c' => 'Renewal',
                'SBQQ__Primary__c' => true,
                'CWS_Quote_Type__c' => CWS_ConstantClass.QUOTE_TYPE_RENEWAL,

                'recordtypeid' => CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_EDIT,
                'CWS_Add_Terms_Manually__c' => 'Test123456',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Bill_to_Account__c' => soldtoaccount.Id,
                'CWS_Reference_Expiry_Date__c' => null,
                'CWS_IsCloned__c' => false,
                'CWS_Renewal_Category__c' => CWS_ConstantClass.RENEWAL_TYPE_OPTIN,
                'CWS_CreatedBy_AM__c' => true,
                'CWS_Region__c' => 'NA'
        };
        SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opp.Id, quoteFields3, true);
        try {
            System.runAs(rep1) {
                quote3.ownerId = rep.id;
                Update quote3;
            }
        } Catch (Exception e) {
        }
        Test.StopTest();
    }

    @IsTest
    static void testAmendment() {

        Test.startTest();
        Opportunity opp = [Select id, AccountId from Opportunity where name = 'New Business Opty'] ;
        PricebookEntry pbe = [Select id, Product2Id from PricebookEntry where product2.name = 'TestProduct1'];
        SBQQ__Quote__c quote = [Select id, CWS_Bill_to_Account__c from SBQQ__Quote__c where CWS_Agreement_Numbers__c = 'ABC1234'];
        opp.Type = 'Amendment';
        opp.CWS_On_Hold__c = true;
        opp.CWS_On_Hold_Reason__c = 'ttest';
        // Account soldtoaccount = [select id from Account where name = 'TestAccount'];
        Contract con = [Select id,CWS_TransactionReason__c, CWS_Quote_SubType__c, CWS_ConversionType__c, CWS_Route_to_Market__c, CWS_Bill_To_Account__c from Contract limit 1];
        con.CWS_TransactionReason__c = 'Agreement Conversion';
        con.CWS_Quote_SubType__c = 'Credit';
        con.CWS_ConversionType__c = CWS_ConstantClass.CONVERSION_TYPE_PERPETUAL_SAAS;
        con.CWS_Route_to_Market__c = 'Channel';
        con.CWS_Bill_To_Account__c = quote.CWS_Bill_to_Account__c;
        con.SBQQ__Quote__c = quote.id;
        opp.SBQQ__AmendedContract__c = con.id;
        update opp;
        update con;
        SBQQ__Quote__c quote3 = [Select id, CWS_Bill_to_Account__c,CWS_Route_to_Market__c from SBQQ__Quote__c where CWS_Quote_Type__c = 'Amendment'];

        List<SBQQ__QuoteLine__c> quoteLine11 = CWS_UTLDataFactory.createQuoteLines(1, quote3.Id, pbe.Product2Id);
        quoteLine11[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLine11[0].CWS_Base_SKU__c = '900901';
        quoteLine11[0].CWS_Custom_sow__c = true;
        insert quoteline11[0];

        //quote3.SBQQ__MasterEvergreenContract__c = con.id;
        quote3.SBQQ__MasterContract__c = con.id;
        quote3.CWS_Transaction_Reason__c = 'Agreement Conversion';
        quote3.CWS_Conversion_Type__c = CWS_ConstantClass.CONVERSION_TYPE_PERPETUAL_SAAS;
        quote3.CWS_LegacyKey__c = '1234567889563';
        quote3.CWS_Linecount_AddOn__c = 1;
        quote3.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_APPROVED;
        quote3.CWS_Sub_Stage__c = 'In-Progress';
        quote3.CWS_Route_to_Market__c = 'Channel';
        update quote3;
        quote3.SBQQ__Status__c = 'Accepted';
        quote3.CWS_Sub_Stage__c = 'Accepted';
        update quote3;
        Test.StopTest();
    }
    @isTest
    static void testRenewalWC() {
        Test.startTest();
        Opportunity opp = [Select id from Opportunity where name = 'NB2'] ;

        opp.Type = 'Renewal';
        opp.CWS_On_Hold__c = true;
        opp.CWS_On_Hold_Reason__c = 'ttest';
        Account soldtoaccount = [select id from Account where name = 'TestAccount'];
        Contract con = [Select id from Contract limit 1];
        opp.SBQQ__RenewedContract__c = con.id;
        Map<String, Object> confields = new Map<String, Object>{

                'CWS_Primary_Contact__c' => true,
                'CWS_Primary_Billing_Contact__c' => true

        };

        Contact billtoContact = CWS_UTLDataFactory.createContact('billToFirstName', 'billToLastName', soldtoaccount.Id, confields, true);
        opp.CWS_Bill_To_Contact__c = billtoContact.id;
        update opp;
        Map<String, Object> quoteFields3 = new Map<String, Object>{
                //  'SBQQ__Status__c'=>'Draft',
                'SBQQ__Type__c' => 'Renewal',
                'SBQQ__Primary__c' => true,
                'CWS_Quote_Type__c' => 'Renewal with Change',

                'recordtypeid' => CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_EDIT,
                'CWS_Add_Terms_Manually__c' => 'Test123456',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Bill_to_Account__c' => soldtoaccount.Id,
                'CWS_Reference_Expiry_Date__c' => null,
                'CWS_IsCloned__c' => false,
                'CWS_Renewal_Category__c' => CWS_ConstantClass.RENEWAL_TYPE_OPTIN,
                'CWS_Bill_to_Contact__c' => billToContact.Id
        };
        SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opp.Id, quoteFields3, true);

        Test.stopTest();
    }

    @IsTest
    static void testRenewalUserUpdate() {
        System.runAs(new User(Id = Userinfo.getUserId())) {
            Test.startTest();
            Opportunity opp = [Select id from Opportunity where name = 'NB2'] ;
            opp.Type = 'Renewal';
            opp.CWS_On_Hold__c = true;
            opp.CWS_On_Hold_Reason__c = 'ttest';
            // opp.CWS_Master__c = true;
            Account soldtoaccount = [select id from Account where name = 'TestAccount'];
            Contract con = [Select id, CWS_Renewal_Uplift_Applicable__c from Contract limit 1];
            con.CWS_Renewal_Uplift_Applicable__c = 1;

            opp.SBQQ__RenewedContract__c = con.id;


            //Group g1 = CWS_UTLDataFactory.createGroup(CWS_ConstantClass.NA_Region, 'Regular' , true);
            Group g1 = [Select id from Group where DeveloperName = :CWS_ConstantClass.NA_Region];
            User[] rep = [Select id, name, username from user where lastName = 'SalesRep_TestUser' and profile.name = 'CWS_Sales_Rep'];
            User[] salesOps = [Select id, name, username from user where lastName = 'SalesOps_TestUser' and profile.name = 'CWS_Global_Sales_Ops'];
            CWS_UTLDataFactory.createGroupMember(rep[0].Id, g1.id, true);
            CWS_UTLDataFactory.createGroupMember(salesOps[0].Id, g1.id, true);
            //Adding permissionset since failing
            List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
            for (PermissionSet pset : [SELECT Id FROM PermissionSet WHERE Name = 'SteelBrickCPQUser']) {
                psa.add(new PermissionSetAssignment(AssigneeId = salesOps[0].id, PermissionSetId = pset.Id));
            }
            if (!psa.isEmpty()) {
                system.debug('psa--' + psa);
                insert psa;
            }
            System.runAs(salesOps[0]) {
                update con;
                update opp;

                Map<String, Object> quoteFields3 = new Map<String, Object>{
                        //  'SBQQ__Status__c'=>'Draft',
                        'SBQQ__Type__c' => 'Renewal',
                        'SBQQ__Primary__c' => true,
                        'CWS_Quote_Type__c' => CWS_ConstantClass.QUOTE_TYPE_RENEWAL,

                        'recordtypeid' => CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_EDIT,
                        'CWS_Add_Terms_Manually__c' => 'Test123456',
                        'SBQQ__ExpirationDate__c' => System.today(),
                        'CWS_Bill_to_Account__c' => soldtoaccount.Id,
                        'CWS_Reference_Expiry_Date__c' => null,
                        'CWS_IsCloned__c' => false,
                        'CWS_Renewal_Category__c' => CWS_ConstantClass.RENEWAL_TYPE_OPTIN,
                        'CWS_CreatedBy_AM__c' => true,
                        'CWS_Region__c' => 'NA'
                };
                SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opp.Id, quoteFields3, true);
                try {
                    quote3.ownerId = rep[0].id;
                    quote3.CWS_OF_SignedDate__c = System.today();
                    quote3.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN;
                    quote3.CWS_Sub_Stage__c = 'Awaiting Signature';
                    quote3.CWS_Promo_Code__c = 'test23';
                    quote3.SBQQ__ExpirationDate__c = System.today() + 2;
                    quote3.CWS_Route_to_Market__c = CWS_ConstantClass.RTM_Value_IIT;
                    Update quote3;
                } Catch (Exception e) {
                }
            }
            Test.StopTest();
        }
    }

    @isTest
    static void testAmendmentwithErrors() {
        Test.startTest();
        Opportunity opp = [Select id from Opportunity limit 1] ;
        Product2 prod = [Select id from Product2 limit 1];
        PricebookEntry pbe = [Select id from PricebookEntry limit 1];
        opp.Type = 'Amendment';
        opp.CWS_On_Hold__c = true;
        opp.CWS_On_Hold_Reason__c = 'ttest';
        Account soldtoaccount = [select id from Account where name = 'TestAccount'];
        Contract con = [Select id from Contract limit 1];

        update opp;
        try {
            Map<String, Object> quoteFields3 = new Map<String, Object>{
                    'SBQQ__Primary__c' => true,
                    'SBQQ__Type__c' => 'Amendment',
                    'CWS_Quote_Type__c' => 'Amendment',
                    'CWS_Add_Terms_Manually__c' => 'Test123456',
                    'SBQQ__ExpirationDate__c' => System.today(),
                    'CWS_Reference_Expiry_Date__c' => null,
                    'CWS_IsCloned__c' => false,
                    'RecordTypeId' => CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY,
                    'CWS_Route_to_Market__c' => 'Channel',
                    'CWS_Bill_to_Account__c' => soldtoaccount.Id
            };
            SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opp.Id, quoteFields3, true);
            quote3.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
            quote3.SBQQ__MasterEvergreenContract__c = con.id;
            quote3.SBQQ__MasterContract__c = con.id;
            update quote3;
        } catch (Exception e) {
        }
        Test.StopTest();
    }
    @isTest
    static void rtmIITTest() {
        test.startTest();
        Account soldtoaccount = [select id from Account where name = 'TestAccount'];

        Opportunity opp = [Select id from Opportunity where name = 'NewIIT'] ;
        SBQQ__Quote__c quote = [Select id, CWS_Bill_to_Account__c from SBQQ__Quote__c where CWS_Agreement_Numbers__c = 'ABC123456'];

        Map<String, Object> quoteFields3 = new Map<String, Object>{
                'SBQQ__Primary__c' => true,
                'CWS_Quote_Type__c' => 'New Business',
                'CWS_Add_Terms_Manually__c' => 'Test123456',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Reference_Expiry_Date__c' => null,
                'CWS_IsCloned__c' => false,
                'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_IIT,
                'CWS_Bill_to_Account__c' => quote.CWS_Bill_to_Account__c,
                'CWS_Reseller_Account__c' => quote.CWS_Bill_to_Account__c
        };
        SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opp.Id, quoteFields3, true);
        test.stopTest();
    }
    @isTest
    static void rtmIITTestErrors() {
        test.startTest();
        Account soldtoaccount = [select id from Account where name = 'TestAccount'];

        Opportunity opp = [Select id from Opportunity where name = 'NewIIT'] ;
        SBQQ__Quote__c quote = [Select id, CWS_Bill_to_Account__c,CWS_Bill_to_Account__r.CWS_Is_Partner__c,CWS_Bill_to_Account__r.CWS_Is_Distributor__c from SBQQ__Quote__c where CWS_Agreement_Numbers__c = 'ABC123456'];
        Account acc = [Select id,CWS_Is_Partner__c,CWS_Is_Distributor__c from Account where id = :quote.CWS_Bill_to_Account__c];
        acc.CWS_Is_Partner__c = false;
        acc.CWS_Is_Distributor__c = false;
        acc.CWS_Authorized_Reseller__c = null;
        acc.CWS_Is_IIT_Reseller__c = false;

        try {
            update acc;
            Map<String, Object> quoteFields3 = new Map<String, Object>{
                    'SBQQ__Primary__c' => true,
                    'CWS_Quote_Type__c' => 'New Business',
                    'CWS_Add_Terms_Manually__c' => 'Test123456',
                    'SBQQ__ExpirationDate__c' => System.today(),
                    'CWS_Reference_Expiry_Date__c' => null,
                    'CWS_IsCloned__c' => false,
                    'CWS_Route_to_Market__c' => CWS_ConstantClass.RTM_Value_IIT,
                    'CWS_Bill_to_Account__c' => acc.id,
                    'CWS_Reseller_Account__c' => null
            };
            SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(soldtoaccount.Id, opp.Id, quoteFields3, true);
        } Catch (Exception e) {
        }
        test.stopTest();
    }

    @isTest
    static void testMaster() {
        test.startTest();
        Contract con = [Select id, CWS_Master__c from Contract limit 1];
        Date d = System.today();
        con.CWS_Master__c = true;

        //con.CWS_Status__c ='Active';
        Opportunity opp = [Select id,AccountId from Opportunity where name = 'NB2'];
        opp.CWS_Disti_Deal_Phase__c = CWS_ConstantClass.distiEndCustomer;

        update opp;
        update con;
        Map<String, Object> quoteFields3 = new Map<String, Object>{
                'SBQQ__Primary__c' => true,
                'CWS_Quote_Type__c' => 'New Business',
                'CWS_Add_Terms_Manually__c' => 'Test123456',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Reference_Expiry_Date__c' => null,
                'CWS_IsCloned__c' => false,
                'CWS_Bill_to_Account__c' => opp.AccountId,
                'SBQQ__Status__c' => 'Approved',
                'CWS_Sub_Stage__c' => 'In-Progress'
        };
        SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(opp.AccountId, opp.Id, quoteFields3, true);
        quote3.CWS_Promo_Code__c = 'test';
        quote3.SBQQ__Status__c = 'Accepted';
        quote3.CWS_Sub_Stage__c = 'Accepted';
        //update quote3;Gautam Commented 
        test.stopTest();

    }

    @isTest
    static void testAmendment2() {

        Test.startTest();
        Opportunity opp = [Select id, AccountId from Opportunity where name = 'NB2'] ;
        SBQQ__Quote__c quote = [Select id, CWS_Bill_to_Account__c from SBQQ__Quote__c where CWS_Agreement_Numbers__c = 'ABC1234'];
        opp.Type = 'Amendment';
        Contract con = [Select id,CWS_TransactionReason__c, CWS_Quote_SubType__c, CWS_ConversionType__c, CWS_Route_to_Market__c, CWS_Bill_To_Account__c from Contract limit 1];
        con.CWS_ConversionType__c = 'Legal Entity Conversion';
        con.CWS_TransactionReason__c = 'Credit/Re-bill';
        con.CWS_Route_to_Market__c = 'Channel';
        con.CWS_Bill_To_Account__c = quote.CWS_Bill_to_Account__c;
        con.SBQQ__Quote__c = quote.id;
        opp.SBQQ__AmendedContract__c = con.id;
        update opp;
        update con;
        Map<String, Object> quoteFields3 = new Map<String, Object>{
                'SBQQ__Primary__c' => true,
                'SBQQ__Status__c' => 'Draft',
                'CWS_Quote_Type__c' => 'Amendment',
                'CWS_Add_Terms_Manually__c' => 'Test123456',
                'SBQQ__ExpirationDate__c' => System.today(),
                'CWS_Bill_to_Account__c' => quote.CWS_Bill_to_Account__c,
                'CWS_Reference_Expiry_Date__c' => null,
                'CWS_IsCloned__c' => false,
                'RecordTypeId' => CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY,
                'CWS_Renewal_Category__c' => CWS_ConstantClass.RENEWAL_TYPE_OPTIN,
                'SBQQ__WatermarkShown__c' => false,
                'CWS_Route_to_Market__c' => 'Channel'
        };
        SBQQ__Quote__c quote3 = CWS_UTLDataFactory.createQuote(opp.AccountId, opp.Id, quoteFields3, true);
        sbaa__ApprovalChain__c appchain = new sbaa__ApprovalChain__c();
        appchain.Name = CWS_ConstantClass.QUOTE_ACC_RESTRICT_APPROVAL;
        appchain.sbaa__TargetObject__c = 'SBQQ__Quote__c';

        insert appchain;
        sbaa__Approval__c approval = new sbaa__Approval__c();
        approval.CWS_Quote__c = quote3.Id;
        approval.sbaa__Opportunity__c = opp.Id;
        approval.sbaa__Status__c = 'Requested';
        approval.sbaa__ApprovalChain__c = appchain.Id;
        approval.sbaa__ApprovalStep__c = 1;
        approval.sbaa__RecordField__c = 'CWS_Quote__c';
        insert approval;
        sbaa__ApprovalSnapshot__c snap = new sbaa__ApprovalSnapshot__c(sbaa__Approval__c = approval.id);
        insert snap;
        //cover clone method
        SBQQ__Quote__c clonedRecord = quote3.clone(false, true, false, false);
        insert clonedRecord;

        Test.StopTest();
    }

    @IsTest
    static void testOverage() {

        Test.startTest();
        SBQQ__Quote__c quote1 = [Select id, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Id from SBQQ__Quote__c where CWS_Agreement_Numbers__c = 'ABC1234'];
        quote1.SBQQ__Status__c = 'Draft';
        quote1.CWS_Original_Overage_Uplift__c = 10;
        PricebookEntry pbe1 = [Select id, Product2Id from PricebookEntry where Product2.Name = 'TestProduct1'];

        List<SBQQ__QuoteLine__c> quoteLine11 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, pbe1.Product2Id);
        quoteLine11[0].SBQQ__PricebookEntryId__c = pbe1.id;
        quoteLine11[0].CWS_Overage_Price__c = 50000;
        quoteLine11[0].CWS_Overage_Unit_Price__c = 50000;
        //quoteLine11[0].SBQQ__NetPrice__c = 100;
        insert quoteline11[0];
        update quote1;
        //quote3.SBQQ__MasterEvergreenContract__c = con.id;
        quote1.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_APPROVED;
        quote1.CWS_Sub_Stage__c = 'In-Progress';
        quote1.CWS_Route_to_Market__c = 'Channel';
        update quote1;
        quote1.SBQQ__Status__c = 'Accepted';
        quote1.CWS_Sub_Stage__c = 'Accepted';
        update quote1;

        Test.stopTest();
    }


    @IsTest
    static void CWS_QueueableRevokeQuoteDocTest() {

        List<SBQQ__QuoteDocument__c> qDocList = [
                SELECT
                        Id,
                        SBQQDS__VoidedReason__c
                FROM SBQQ__QuoteDocument__c
        ];
        Test.startTest();
        System.enqueueJob(new CWS_QueueableRevokeQuoteDoc(qDocList));
        System.enqueueJob(new CWS_QueueableRevokeQuoteDoc());
        Test.stopTest();


    }

    @Future
    static void insertUserAndPermissionSetAssignment() {
        String orgId = UserInfo.getOrganizationId();
        String uniqueName1 = '' + UserInfo.getOrganizationId() + String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '') +
                Integer.valueOf(math.rint(math.random() * 1000000));
        String userName1 = uniqueName1 + '@test' + orgId + '.org';
        String uniqueName2 = '' + UserInfo.getOrganizationId() + String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '') +
                Integer.valueOf(math.rint(math.random() * 1000000));
        String userName2 = uniqueName2 + '@test' + orgId + '.org';
        User rep = CWS_UTLDataFactory.createUser(uniqueName1.substring(18, 23), userName1, 'SalesRep_TestUser', 'CWS_Sales_Rep',
                'CEO', userName1, new Map<String, Object>(), true);
        User salesops = CWS_UTLDataFactory.createUser(uniqueName2.substring(18, 23), userName2, 'SalesOps_TestUser', 'CWS_Global_Sales_Ops',
                'CEO', userName2, new Map<String, Object>(), true);
        List<PermissionSet> psSalesRep = [SELECT Id FROM PermissionSet WHERE name = :CWS_ConstantClass.SalesRepCPQPermissionSet];
        List<PermissionSet> psSalesOps = [SELECT Id FROM PermissionSet WHERE name = :CWS_ConstantClass.SalesOpsCPQPermissionSet];
        if (psSalesRep.size() > 0) {
            insert new PermissionSetAssignment(AssigneeId = rep.id, PermissionSetId = psSalesRep[0].Id);
        }
        if (psSalesOps.size() > 0) {
            insert new PermissionSetAssignment(AssigneeId = salesops.id, PermissionSetId = psSalesOps[0].Id);
        }
    }

    @IsTest
    public static void checkEvergreenProducts_Test() {
        Map<Id, Contract> con = new Map<Id, Contract>([SELECT Id, SBQQ__Evergreen__c FROM Contract]);

        CWS_Promotion__c promo = new CWS_Promotion__c();
        promo.CWS_Promo_Code__c = 'test';
        promo.CWS_End_Date__c = System.today();
        promo.CWS_Start_Date__c = System.today();
        promo.CWS_Category__c = 'Automate;';
        insert promo;

        Test.startTest();
        CWS_QuoteTriggerHelper.checkEvergreenProducts(con.keySet());
        Test.stopTest();
    }
}