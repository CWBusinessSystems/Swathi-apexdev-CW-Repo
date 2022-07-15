/*
Ad Victoriam Solutions - CW11-P1-SFDX-rwdev, -ven
Purpose: Queries records and performs aggregate calculations
    for data to display in "Min Commit Calculator" LWC.
Dependencies: MinCommitCalculatorController_Test
Changelog:
    17 Aug 2021 by chase.brammer for CW11-7, CW11-67
        - Created initial file.
*/

/**
* @author chase.brammer, Ad Victoriam Solutions
* @date 1 Nov, 2021
*
* @description Queries records and performs aggregate calculations on for data to display in
*   "Min Commit Calculator" LWC.
*/
public with sharing class CWS_MinCommitCalculatorController {

    public static final List<String> ALL_CONTINUUM_WHITESPACE_GROUPS = getAllContinuumWhitespaceGroups();
    public static Decimal currentOpportunityCurrencyTypeConversionRate = 1.0;
    public static final Decimal ZERO_DECIMAL = 0.0;

    /**
     * @param minCommitStrings a List of String values that are a valid numeric Min Commit number
     *
     * @return a List of Decimal values for use in a SF Flow
     *
     * @description This method is necessary because api tagged properties in a LWC cannot return Decimal values
     *  to a SF flow.
     */
    @InvocableMethod(Label='Convert Min Commit Value to Decimal Number' Description='This is necessary because as of API version 52.0, you still cannot return a numeric value from a LWC to a Flow.')
    public static List<Decimal> convertMinCommitToDecimal(List<String> minCommitStrings) {
        return new List<Decimal>{Decimal.valueOf(minCommitStrings?.get(0))};
    }

    /**
     * @return a List of String names for the Continuum Products' White Space groups.
     *
     * @description To get the list of White Space Groups that display on the Calculator Component,
     *  this method pulls the groups and their values from the Custom Metadata that holds which
     *  White Space groups are Continuum Products.
     */
    @TestVisible
    private static List<String> getAllContinuumWhitespaceGroups() {
        List<CWS_Continuum_Whitespace_Groups__mdt> cwgs = CWS_Continuum_Whitespace_Groups__mdt.getAll().values();
        List<String> whitespaceGroupNames = new List<String>();
        for(CWS_Continuum_Whitespace_Groups__mdt cwg : cwgs) {
            whitespaceGroupNames.add(cwg.CWS_Whitespace_Group_API_Name__c);
        }
        return whitespaceGroupNames;
    }

    /**
     * @param opportunityId 18-char caseSafeId for SF Opportunity SObject
     *
     * @return an Opportunity SObject specified by the Id
     *
     * @description this method exists to get the Opportunity and its details
     *  for the current Opportunity on which the LWC this controls resides.
     */
    @TestVisible
    private static Opportunity queryCurrentOpportunity(Id opportunityId) {
        List<Opportunity> currentOpportunities = new List<Opportunity>();
        currentOpportunities = [
                SELECT
                        Id, Name, CurrencyIsoCode,
                        CWS_Min_Commit_QR__c,
                        CWS_Prior_Billing_Period__c, CWS_Prior_Billing_Period__r.CWS_CMSCommitAmount__c,
                        CWS_Snapline_Billing_Period__c,
                        SBQQ__PrimaryQuote__c,
                        CWS_Existing_Min_Commit_Period__c,
                        Type
                FROM Opportunity
                WHERE Id = :opportunityId
                WITH SECURITY_ENFORCED
                LIMIT 1
        ];
        if (currentOpportunities.size() > 0) {
            return currentOpportunities.get(0);
        }
        return null;
    }


    /**
     * @param opportunityId Id for the current Opportunity the LWC is on.
     *
     * @description provides the Opportunity's Type field value as a String to the LWC.
     *
     * @return the String value of the Opportunity.Type field.
     */
    @AuraEnabled
    public static String getOpportunityType(Id opportunityId) {
        Opportunity opportunity = queryCurrentOpportunity(opportunityId);
        if(opportunity.Type != null) {
            return opportunity.Type;
        }
        return null;
    }

    @TestVisible
    private static Set<Id> getBillingItemIdsFromBillingPeriodById(Id billingPeriodId) {
        List<CWS_BillingPeriod__c> bp = new List<CWS_BillingPeriod__c>();
        bp = [
                SELECT Id, Name, (SELECT Id, Name, CWS_WhiteSpaceGroup__c FROM Billing_Items__r)
                FROM CWS_BillingPeriod__c
                WHERE Id = :billingPeriodId
                WITH SECURITY_ENFORCED
                LIMIT 1
        ];
        if (bp.size() > 0 && bp.get(0)?.Billing_Items__r.size() > 0) {
            Set<Id> billingItemIds = new Set<Id>();
            for(CWS_BillingItem__c bi : bp.get(0)?.Billing_Items__r) {
                billingItemIds.add(bi.Id);
            }
            return billingItemIds;
        }
        return null;
    }

    private static List<AggregateResult> queryAggregateBillingItemsInBillingPeriod(Set<Id> billingItemIds) {
        List<AggregateResult> ar = new List<AggregateResult>();
        try {
            ar = [
                    SELECT CWS_WhiteSpaceGroup__c wsg, SUM(CWS_MRR__c) sum_mrr
                    FROM CWS_BillingItem__c
                    WHERE Id IN :billingItemIds
                        AND CWS_IncludeinMinCommit__c = TRUE
                    WITH SECURITY_ENFORCED
                    GROUP BY CWS_WhiteSpaceGroup__c
                    ORDER BY CWS_WhiteSpaceGroup__c DESC
            ];
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return ar;
    }

    private static List<AggregateResult> queryAggregateQuoteLinesOnPrimaryQuote(Id primaryQuoteId) {
        List<AggregateResult> ar = new List<AggregateResult>();
        try {
            ar = [
                    SELECT CWS_Whitespace_Group__c wsg, SUM(CWS_MRR__c) sum_mrr
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :primaryQuoteId
                    AND CWS_Include_In_Minimum_Commit__c = TRUE
                    WITH SECURITY_ENFORCED
                    GROUP BY CWS_Whitespace_Group__c
                    ORDER BY CWS_Whitespace_Group__c DESC
            ];
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return ar;
    }

    private static Decimal getSumMrrValueForWhiteSpaceGroupFromAggregateResults(String currentWhiteSpaceGroup, List<AggregateResult> billingItemsAggregate) {
        // get snapline or prior billing period
        for (AggregateResult ar : billingItemsAggregate) {
            String arWhiteSpaceGroup = (String) ar.get('wsg');
            if (arWhiteSpaceGroup == currentWhiteSpaceGroup) {
                Decimal currentWhiteSpaceTotal = (Decimal) ar.get('sum_mrr');
                if (currentWhiteSpaceTotal != null && currentWhiteSpaceTotal > 0.0) {
                    return convertToCurrentOpportunityCurrency(currentWhiteSpaceTotal).setScale(3);
                }
            }
        }
        return ZERO_DECIMAL;
    }

    private static List<CommitCalculatorRow> generateCommitCalculatorRowData(List<AggregateResult> snaplineBillingItemsAggregate,
            List<AggregateResult> priorBillingItemsAggregate, List<AggregateResult> quoteLinesAggregate) {
        List<CommitCalculatorRow> commitCalculatorRowData = new List<CommitCalculatorRow>();
        for (String currentWhiteSpaceGroup : ALL_CONTINUUM_WHITESPACE_GROUPS) {
            CommitCalculatorRow ccr = new CommitCalculatorRow();
            ccr.whiteSpaceGroup = currentWhiteSpaceGroup;
            ccr.snapline = ZERO_DECIMAL;
            ccr.priorBillingPeriod = ZERO_DECIMAL;
            ccr.quoteMRR = ZERO_DECIMAL;
            ccr.newMinCommitIncrease = ZERO_DECIMAL;

            ccr.snapline = getSumMrrValueForWhiteSpaceGroupFromAggregateResults(currentWhiteSpaceGroup, snaplineBillingItemsAggregate);
            ccr.priorBillingPeriod = getSumMrrValueForWhiteSpaceGroupFromAggregateResults(currentWhiteSpaceGroup, priorBillingItemsAggregate);
            ccr.quoteMRR = getSumMrrValueForWhiteSpaceGroupFromAggregateResults(currentWhiteSpaceGroup, quoteLinesAggregate);
            // could assign a default new Min Commit Increase here if desired.

            commitCalculatorRowData.add(ccr);
        }
        return commitCalculatorRowData;
    }

    // we always convert because Aggregate Queries with SUM() functions in SOQL
    // always return currency in the Org Default Currency (org corporate currency)
    // this means these amounts are always in USD, and always require conversion to Opp currency.
    private static Decimal convertToCurrentOpportunityCurrency(Decimal amount) {
        return amount * currentOpportunityCurrencyTypeConversionRate;
    }

    /**
     * @param opportunityId the String Id
     *
     * @return a JSON-string of a List<CommitCalculatorRow>, which is a class that summarizes the essential data
     * needed to display a row in the Min Commit Calculator LWC. Returned as a JSON string for parsing by the LWC.
     *
     * @description This method queries required data from Billing Period and Quote Line SObjects for a given opportunity,
     * then calculates and converts the data to the appropriate currency, ordered into a row for each Continuum Product's
     * whitespace group. This populates the data you see in the Min Commit Calculator LWC, basically.
     */
    @AuraEnabled
    public static String getCalculatorRows(Id opportunityId) {
        // get the current opportunity and the Ids of related records we need from it.
        Opportunity currentOpportunity = new Opportunity();
        currentOpportunity = queryCurrentOpportunity(opportunityId);
        currentOpportunityCurrencyTypeConversionRate = getConversionRateForOpportunity(opportunityId);

        Set<Id> snaplineBillingItemIds = new Set<Id>();
        if (currentOpportunity.CWS_Snapline_Billing_Period__c != null) {
            snaplineBillingItemIds = getBillingItemIdsFromBillingPeriodById(
                    currentOpportunity.CWS_Snapline_Billing_Period__c
            );
        }

        Set<Id> priorBillingItemIds = new Set<Id>();
        if (currentOpportunity.CWS_Prior_Billing_Period__c != null) {
            priorBillingItemIds = getBillingItemIdsFromBillingPeriodById(
                    currentOpportunity.CWS_Prior_Billing_Period__c
            );
        }

        List<AggregateResult> snaplineBillingItemsAggregate = new List<AggregateResult>();
        if (snaplineBillingItemIds != null) {
            snaplineBillingItemsAggregate = queryAggregateBillingItemsInBillingPeriod(snaplineBillingItemIds);
        }

        List<AggregateResult> priorBillingItemsAggregate = new List<AggregateResult>();
        if (priorBillingItemIds != null) {
            priorBillingItemsAggregate = queryAggregateBillingItemsInBillingPeriod(priorBillingItemIds);
        }

        List<AggregateResult> quoteLinesAggregate = new List<AggregateResult>();
        if(currentOpportunity?.SBQQ__PrimaryQuote__c != null) {
            quoteLinesAggregate = queryAggregateQuoteLinesOnPrimaryQuote(currentOpportunity.SBQQ__PrimaryQuote__c);
        }

        List<CommitCalculatorRow> commitCalculatorRowData = new List<CommitCalculatorRow>();
        commitCalculatorRowData = generateCommitCalculatorRowData(
                snaplineBillingItemsAggregate, priorBillingItemsAggregate, quoteLinesAggregate
        );

        String serializedResult = JSON.serialize(commitCalculatorRowData);
        return serializedResult;
    }

    /**
    * @param opportunityId String Id of the current opportunity record.
    * @description returns Opportunity.CurrencyIsoCode to populate the Table Header in Min Commit Calc.
    * @return a 3-char ISO Currency Code.
    */
    @AuraEnabled
    public static String getCurrencyCodeForOpportunity(String opportunityId) {
        Opportunity currentOpportunity = queryCurrentOpportunity(opportunityId);
        return currentOpportunity.CurrencyIsoCode;
    }

    private static CurrencyType queryCurrencyTypeForOpportunity(Id opportunityId) {
        Opportunity opp = queryCurrentOpportunity(opportunityId);
        List<CurrencyType> ct = new List<CurrencyType>();
        ct = [
                SELECT Id, IsActive, IsoCode, DecimalPlaces, ConversionRate
                FROM CurrencyType
                WHERE IsoCode = :opp.CurrencyIsoCode AND IsActive = TRUE
                WITH SECURITY_ENFORCED
                LIMIT 1
        ];
        return ct.get(0);
    }

    private static Decimal getConversionRateForOpportunity(Id opportunityId) {
        CurrencyType ct = queryCurrencyTypeForOpportunity(opportunityId);
        return ct.ConversionRate;
    }

    /**
     * @param opportunityId String Id of the current Opportunity record on the component.
     *
     * @description Queries the Billing Period for the Opportunity's Existing Min Commit Period lookup, and returns the
     * CMS Commit Amount to the LWC.
     *
     * @return a Decimal that is the current Opportunity record's related Existing Min Commit Period's CWS_CMSCommitAmount__c
     */
    @AuraEnabled
    public static Decimal getExistingMinCommitForOpportunity(String opportunityId) {
        Opportunity currentOpp = queryCurrentOpportunity(opportunityId);
        CWS_BillingPeriod__c existingBillingPeriod = new CWS_BillingPeriod__c();
        existingBillingPeriod = [
                SELECT Id, CWS_CMSCommitAmount__c
                FROM CWS_BillingPeriod__c
                WHERE Id = :currentOpp.CWS_Existing_Min_Commit_Period__c
                WITH SECURITY_ENFORCED
                LIMIT 1
        ];
        if(existingBillingPeriod.CWS_CMSCommitAmount__c == null) {
            return 0.0;
        }
        return existingBillingPeriod.CWS_CMSCommitAmount__c;
    }

    /**
     * @description This class is a delegator to provide structure for the data going into the
     * table. It represents one row of data in the Min Commit Calculator LWC.
     */
    public class CommitCalculatorRow {
        @AuraEnabled
        public String whiteSpaceGroup;
        @AuraEnabled
        public Decimal snapline;
        @AuraEnabled
        public Decimal priorBillingPeriod;
        @AuraEnabled
        public Decimal quoteMRR;
        @AuraEnabled
        public Decimal newMinCommitIncrease;
    }

}