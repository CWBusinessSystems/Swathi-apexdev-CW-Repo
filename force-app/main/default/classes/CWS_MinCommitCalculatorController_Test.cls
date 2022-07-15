/*
Ad Victoriam Solutions - CW11-P1-SFDX-ven
Purpose: provide test coverage for dependencies
Dependencies: CWS_MinCommitCalculatorController
Changelog:
    17 Sep 2021 by chase.brammer for CW11-7
        - Created initial file.
*/

@IsTest
public with sharing class CWS_MinCommitCalculatorController_Test {

    private static final Integer EXPECTED_POPULATED_ROWS = 2;

    @TestSetup
    private static void testSetup() {
        Account testAccount = new Account(Name = 'TestAccount', CurrencyIsoCode = 'CAD');
        insert testAccount;
        Account billToAccount = new Account(Name = 'BillToAccount', CurrencyIsoCode = 'CAD');
        insert billToAccount;
        Account badAccount = new Account(Name='BadAccount', CurrencyIsoCode = null);
        insert badAccount;

        CWS_BillingPeriod__c snaplineBP = new CWS_BillingPeriod__c();
        snaplineBP.CWS_PeriodStartDate__c = System.today();
        snaplineBP.CWS_MonthYear__c = '11-2021';
        snaplineBP.CWS_Account__c = testAccount.Id;
        insert snaplineBP;

        CWS_BillingPeriod__c priorBillingBP = new CWS_BillingPeriod__c();
        priorBillingBP.CWS_PeriodStartDate__c = System.today();
        priorBillingBP.CWS_MonthYear__c = '11-2021';
        priorBillingBP.CWS_Account__c = testAccount.Id;
        insert priorBillingBP;

        CWS_BillingPeriod__c existingBP = new CWS_BillingPeriod__c();
        existingBP.Name = 'ExistingMinCommitPeriod';
        existingBP.CWS_PeriodStartDate__c = System.today();
        existingBP.CWS_MonthYear__c = '10-2021';
        existingBP.CWS_Account__c = testAccount.Id;
        insert existingBP;

        Opportunity testOpportunityFail = new Opportunity(
                Name = 'TestOpportunity_Fail',
                CurrencyIsoCode = null,
                AccountId = badAccount.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addMonths(1),
                CWS_Bill_To_Account__c = badAccount.Id,
                Type = null
        );
        insert testOpportunityFail;

        Opportunity testOpportunity = new Opportunity(
                Name = 'TestOpportunity_Success',
                CurrencyIsoCode = 'CAD',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addMonths(1),
                CWS_Bill_To_Account__c = testAccount.Id,
                Type = 'Amendment',
                CWS_Existing_Min_Commit_Period__c = existingBP.Id
        );
        testOpportunity.CWS_Snapline_Billing_Period__c = snaplineBP.Id;
        testOpportunity.CWS_Prior_Billing_Period__c = priorBillingBP.Id;
        testOpportunity.Pricebook2Id = Test.getStandardPricebookId();
        insert testOpportunity;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = testOpportunity.Id;
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;

//        testOpportunity.CWS_Master__c = true;
        testOpportunity.SBQQ__PrimaryQuote__c = testQuote.Id;
        update testOpportunity;

//        CWS_Minimum_Commit__c mc1 = new CWS_Minimum_Commit__c();
//        mc1.CWS_WonCommitAmount__c = 100.0;
//        mc1.CWS_Billing_Period__c = existingBP.Id;
//        mc1.CWS_Monthly_Minimum_Commit__c = 100.0;
//        mc1.CWS_Month_Year__c = 'Jan-20';
//        mc1.CWS_Opportunity__c = testOpportunity.Id;
//        insert mc1;

        List<Product2> testProducts = new List<Product2>();
        List<PricebookEntry> testPBEs = new List<PricebookEntry>();
        for(Integer i = 0; i < EXPECTED_POPULATED_ROWS; i++) {
            Product2 testProduct = new Product2(
                    Name = 'Demo Test Product' + i,
                    CWS_ProductCode__c = 'DEMQ9009' + i,
                    CWS_Category__c = 'Sell',
                    SBQQ__BillingType__c = 'Advance',
                    SBQQ__PricingMethod__c = 'Cost',
                    SBQQ__SubscriptionTerm__c = 12,
                    CWS_Description__c = 'Demo Test Product' + i,
                    CWS_Charge_Model__c = 'Per Unit Pricing',
                    CWS_Product_Family__c = 'Other',
                    CWS_License_Type__c = 'SaaS',
                    CWS_Product_Line__c = 'Corporate',
                    CWS_Status__c = 'Active',
                    CWS_Sub_Category__c = 'License',
                    CW_Product_Type__c = 'Product',
                    CWS_SKU_Type__c = 'Other',
                    CWS_Renewal_Type__c = 'Opt-out',
                    CWS_Route_to_Market__c = 'Direct',
                    CWS_Currencies__c = 'CAD',
                    CWS_Billing_Term__c = 'Monthly',
                    CWS_ChargeType__c = 'Recurring',
                    CWS_Item_Revenue_Category__c = 'Services',
                    IsActive = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Pricing',
                    CWS_UOM__c = 'Cost',
                    CWS_Include_In_Minimum_Commit__c = true
            );
            testProducts.add(testProduct);
        }
        insert testProducts;

        for(Integer i = 0; i < EXPECTED_POPULATED_ROWS; i++) {
            PricebookEntry testPBE = new PricebookEntry();
            testPBE.Product2Id = testProducts.get(i).Id;
            testPBE.UnitPrice = 10.0 * i;
            testPBE.Pricebook2Id = Test.getStandardPricebookId();
            testPBEs.add(testPBE);
        }
        insert testPBEs;

        List<CWS_BillingItem__c> snaplineItems = new List<CWS_BillingItem__c>();
        List<CWS_BillingItem__c> priorBillingItems = new List<CWS_BillingItem__c>();
        for(Integer i = 0; i < EXPECTED_POPULATED_ROWS; i++) {
            CWS_BillingItem__c snapline = new CWS_BillingItem__c();
            snapline.CWS_BillingPeriod__c = snaplineBP.Id;
            snapline.CWS_MRR__c = (i + 1) * 200.0;
            snapline.CWS_WhiteSpaceGroup__c = CWS_MinCommitCalculatorController.ALL_CONTINUUM_WHITESPACE_GROUPS.get(i);
            snapline.CWS_IncludeinMinCommit__c = true;
            snapline.CWS_Product__c = testProducts.get(i).Id;
            snaplineItems.add(snapline);
            CWS_BillingItem__c snapline2 = new CWS_BillingItem__c();
            snapline2.CWS_BillingPeriod__c = snaplineBP.Id;
            snapline2.CWS_MRR__c = (i + 1) * 200.0;
            snapline2.CWS_WhiteSpaceGroup__c = CWS_MinCommitCalculatorController.ALL_CONTINUUM_WHITESPACE_GROUPS.get(i);
            snapline2.CWS_IncludeinMinCommit__c = true;
            snapline2.CWS_Product__c = testProducts.get(i).Id;
            snaplineItems.add(snapline2);
            CWS_BillingItem__c priorBilling = new CWS_BillingItem__c();
            priorBilling.CWS_BillingPeriod__c = priorBillingBP.Id;
            priorBilling.CWS_MRR__c = (i + 1) * 300.0;
            priorBilling.CWS_WhiteSpaceGroup__c = CWS_MinCommitCalculatorController.ALL_CONTINUUM_WHITESPACE_GROUPS.get(i);
            priorBilling.CWS_IncludeinMinCommit__c = true;
            priorBilling.CWS_Product__c = testProducts.get(i).Id;
            priorBillingItems.add(priorBilling);
        }
        insert snaplineItems;
        insert priorBillingItems;

        SBQQ__QuoteLine__c pql0 = new SBQQ__QuoteLine__c();
        pql0.SBQQ__SubscriptionTerm__c = 12;
        pql0.SBQQ__ProrateMultiplier__c = 1.0;
        pql0.SBQQ__DefaultSubscriptionTerm__c = 12;
//      pql0   pql.CWS_Calculated_Subscription_Term__c;
        pql0.SBQQ__NetPrice__c = (0 + 1) * 100.0;
        pql0.SBQQ__Quantity__c = 2;
        pql0.SBQQ__ChargeType__c = 'Usage';
        pql0.CWS_ChargeType__c = 'Usage';
        pql0.CWS_Transaction_Type__c = 'New';
        pql0.SBQQ__Product__c = testProducts.get(0).Id;
        pql0.SBQQ__PricebookEntryId__c = testPBEs.get(0).Id;
        pql0.CWS_Include_In_Minimum_Commit__c = true;
        pql0.CWS_Whitespace_Group__c = CWS_MinCommitCalculatorController.ALL_CONTINUUM_WHITESPACE_GROUPS.get(0);
        pql0.SBQQ__Quote__c = testQuote.Id;
//      pql0   pql.CWS_Price_Per_Billing_Period__c;
//      pql0   pql.CWS_Quote_Doc_Price__c;
//      pql0   pql.CWS_MRR__c;
        pql0.CWS_Billing_Term__c = 'Monthly';
        /**
            due to a CPQ bug, lines must be inserted less than 4 at a time in this way and not in bulk.
        **/
        insert pql0;
        SBQQ__QuoteLine__c pql1 = new SBQQ__QuoteLine__c();
        pql1.SBQQ__SubscriptionTerm__c = 12;
        pql1.SBQQ__ProrateMultiplier__c = 1.0;
        pql1.SBQQ__DefaultSubscriptionTerm__c = 12;
//      pql1   pql.CWS_Calculated_Subscription_Term__c;
        pql1.SBQQ__NetPrice__c = (1 + 1) * 100.0;
        pql1.SBQQ__Quantity__c = 2;
        pql1.SBQQ__ChargeType__c = 'Usage';
        pql1.CWS_ChargeType__c = 'Usage';
        pql1.CWS_Transaction_Type__c = 'New';
        pql1.SBQQ__Product__c = testProducts.get(1).Id;
        pql1.SBQQ__PricebookEntryId__c = testPBEs.get(1).Id;
        pql1.CWS_Include_In_Minimum_Commit__c = true;
        pql1.CWS_Whitespace_Group__c = CWS_MinCommitCalculatorController.ALL_CONTINUUM_WHITESPACE_GROUPS.get(1);
        pql1.SBQQ__Quote__c = testQuote.Id;
//      pql1   pql.CWS_Price_Per_Billing_Period__c;
//      pql1   pql.CWS_Quote_Doc_Price__c;
//      pql1   pql.CWS_MRR__c;
        pql1.CWS_Billing_Term__c = 'Monthly';
        /**
            due to a CPQ bug, lines must be inserted less than 4 at a time in this way and not in bulk.
        **/
        insert pql1;
    }

    /**
     * @description End-to-end test that verifies that Commit Row Data is fully present and aggregates where needed,
     * but still populates each WhiteSpaceGroup when empty.
     */
    @IsTest
    private static void getCommitRowsSuccess() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity_Success' LIMIT 1];
        String actualResults = null;
        Test.startTest();
        actualResults = CWS_MinCommitCalculatorController.getCalculatorRows(testOpp.Id);
        Test.stopTest();
        List<CWS_MinCommitCalculatorController.CommitCalculatorRow> parsedResults =
                (List<CWS_MinCommitCalculatorController.CommitCalculatorRow>) JSON.deserialize(
                        actualResults,
                        List<CWS_MinCommitCalculatorController.CommitCalculatorRow>.class
                );
        System.assertNotEquals(null, actualResults);
        // due to test data setup, rows where data is not zero should be = EXPECTED_POPULATED_ROWS constant variable
        Integer populatedRows = 0;
        for(CWS_MinCommitCalculatorController.CommitCalculatorRow ccr : parsedResults) {
            if(ccr.snapline != 0.0 && ccr.priorBillingPeriod != 0.0 && ccr.quoteMRR != 0.0) {
                populatedRows++;
            }
        }
        System.assertEquals(EXPECTED_POPULATED_ROWS, populatedRows);
    }

    // all zero rows
    @IsTest
    private static void getCommitRowsFail() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity_Fail' LIMIT 1];
        String actualResults = null;
        Test.startTest();
        actualResults = CWS_MinCommitCalculatorController.getCalculatorRows(testOpp.Id);
        Test.stopTest();
        List<CWS_MinCommitCalculatorController.CommitCalculatorRow> parsedResults =
                (List<CWS_MinCommitCalculatorController.CommitCalculatorRow>) JSON.deserialize(
                        actualResults,
                        List<CWS_MinCommitCalculatorController.CommitCalculatorRow>.class
                );
        System.assertNotEquals(null, actualResults);
        // due to test data setup, rows where data is not zero should be = EXPECTED_POPULATED_ROWS constant variable
        Integer populatedRows = 0;
        for(CWS_MinCommitCalculatorController.CommitCalculatorRow ccr : parsedResults) {
            if(ccr.snapline != 0.0 && ccr.priorBillingPeriod != 0.0 && ccr.quoteMRR != 0.0) {
                populatedRows++;
            }
        }
        System.assertEquals(0, populatedRows);
    }

    @IsTest
    private static void getCurrentOpportunityFail() {
        Opportunity actualResult = new Opportunity();
        Test.startTest();
        actualResult = CWS_MinCommitCalculatorController.queryCurrentOpportunity(null);
        Test.stopTest();
        System.assertEquals(null, actualResult);
    }

    @IsTest
    private static void getBillingItemIdsFromBillingPeriodByIdFail() {
        Set<Id> actualResult = new Set<Id>();
        Test.startTest();
        actualResult = CWS_MinCommitCalculatorController.getBillingItemIdsFromBillingPeriodById(null);
        Test.stopTest();
        System.assertEquals(null, actualResult);
    }

    @IsTest
    private static void convertMinCommitToDecimalSuccess() {
        Decimal expectedResult = 100.0;
        Decimal actualResult;
        Test.startTest();
        actualResult = CWS_MinCommitCalculatorController.convertMinCommitToDecimal(new List<String>{'100.00'}).get(0);
        Test.stopTest();

        System.assertEquals(expectedResult, actualResult);
    }

    @IsTest
    private static void getAllWhiteSpaceGroupsSuccess() {
        Test.startTest();
        List<String> actualResults = CWS_MinCommitCalculatorController.getAllContinuumWhitespaceGroups();
        Test.stopTest();
        System.assert(actualResults != null);
        System.assert(actualResults?.size() >= 0);
    }

    @IsTest
    private static void getCurrencyCodeForOpportunitySuccess() {
        Opportunity testOpportunity = [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Name = 'TestOpportunity_Success' LIMIT 1];
        String expectedResult = testOpportunity.CurrencyIsoCode;
        String actualResult = 'USD';
        Test.startTest();
        actualResult = CWS_MinCommitCalculatorController.getCurrencyCodeForOpportunity(testOpportunity.Id);
        Test.stopTest();
        System.assertEquals(expectedResult, actualResult);
    }

//    @IsTest
//    private static void getExistingMinCommitForOpportunitySuccess() {
//        Opportunity testOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity_Success' LIMIT 1];
//        CWS_BillingPeriod__c testBP = [
//                SELECT Id, CWS_CMSCommitAmount__c, Name
//                FROM CWS_BillingPeriod__c
//                WHERE Name = 'getExistingMinCommitForOpportunity'
//                LIMIT 1
//        ];
//        Decimal expectedResult = testBP.CWS_CMSCommitAmount__c;
//        Decimal actualResult = 0.0;
//        Test.startTest();
//        actualResult = CWS_MinCommitCalculatorController.getExistingMinCommitForOpportunity(testOpportunity.Id);
//        Test.stopTest();
//        System.assertEquals(expectedResult, actualResult);
//    }
//
//    @IsTest
//    private static void getExistingMinCommitForOpportunitySuccessNull() {
//        Opportunity testOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'TestOpportunity_Fail' LIMIT 1];
//        CWS_BillingPeriod__c testBP = [
//                SELECT Id, CWS_CMSCommitAmount__c, Name
//                FROM CWS_BillingPeriod__c
//                WHERE Name = 'ExistingMinCommitPeriod'
//                LIMIT 1
//        ];
//        Decimal expectedResult = testBP.CWS_CMSCommitAmount__c;
//        Decimal actualResult = 0.0;
//        Test.startTest();
//        actualResult = CWS_MinCommitCalculatorController.getExistingMinCommitForOpportunity(testOpportunity.Id);
//        Test.stopTest();
//        System.assertEquals(expectedResult, actualResult);
//    }

}