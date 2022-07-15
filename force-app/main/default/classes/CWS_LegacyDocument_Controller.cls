/* Class Name   : CWS_LegacyDocument_Controller
 * Description  : Controller for VF CWS_LegacyDocument_FeePaymentTerms for generating Legacy OF Document's Continuum and MinCommit Tables
 * Created By   : Megha Shetty
 * Created On   : 7/9/2020
 * Edited On    : 8/17/2021
 * Edited By    : Ad Victoriam Solutions
 * Description  : Addition of Termination For Convenience Quote Lines
 */

public class CWS_LegacyDocument_Controller {
    public Id recId { get; set; }
    public List<ContinuumProductsWrapper> continuumWrap { get; set; }
    public List<MinimumCommitWrapper> commitWrap { get; set; }
    public List<TermForConvWrapper> termWrap { get; set; }
    public List<DowngradeQLIWrapper> downgradeWrap { get; set; }
    public Boolean continuumProductsAvailable { get; set; }
    public Boolean minimumCommitDataAvailable { get; set; }
    public Boolean isAmendmentQuote { get; set; }
    public Boolean termWrapperHasData { get; set; }
    public Boolean downgradeWrapperHasData { get; set; }
    public String sowLinkStaticText{get;set;}


    public CWS_LegacyDocument_Controller() {
        recId = (Id) ApexPages.currentPage()
                .getParameters()
                .get('qid')
                .escapeHtml4();
        continuumProductsAvailable = false;
        minimumCommitDataAvailable = false;
        isAmendmentQuote = false;
        termWrapperHasData = false;
        downgradeWrapperHasData = false;
        sowLinkStaticText = System.Label.Statement_of_Work_Hyperlink_Text;
    }

    /** TODO REFACTOR IF POSSIBLE AS FOLLOWS...
    public PageReference fetchData() {
        fetchContinuumWrapData();
        fetchCommitWrapData();
        fetchTermWrapData();
        // and now this too
        fetchDowngradeWrapData();
    }
    **/

    public PageReference fetchData() {
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        Decimal listPricePerMonth = 0.0;
        try {
            if (recId != null) {
                quoteLines = [
                        SELECT
                                SBQQ__ProductName__c,
                                SBQQ__PriorQuantity__c,
                                CWS_RegularPrice__c,
                                SBQQ__CustomerTotal__c,
                                CWS_Exclude_from_Net_Total__c,
                                SBQQ__DiscountScheduleType__c,
                                SBQQ__Quantity__c,
                                SBQQ__CustomerPrice__c,
                                SBQQ__Product__r.CWS_Hide_on_OrderForm__c,
                                CWS_NetPrice__c,
                                SBQQ__NetPrice__c,
                                CWS_Calculated_Subscription_Term__c,
                                SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                                SBQQ__SubscriptionTerm__c,
                                CWS_Transaction_Type__c,
                                SBQQ__Product__r.CWS_Source__c,
                                SBQQ__Quote__r.CWS_Master__c,
                                SBQQ__Quote__r.SBQQ__Opportunity2__c,
                                SBQQ__Quote__r.SBQQ__Type__c,
                                SBQQ__Quote__r.CWS_Currency_Symbol__c,
                                SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Period_of_Fixed_Usage_Commit_Ramp__c,
                                SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Ramp_Options__c,
                                CWS_Termination_for_Convenience__c,
                                CWS_Convenience_Term__c,
                                CWS_Convenience_Expiration_Date__c,
                                CWS_Quote_Type__c,
                                SBQQ__Product__r.Name,
                                CWS_License_Type__c,
                                SBQQ__StartDate__c,
                                SBQQ__Quote__r.SBQQ__StartDate__c,
                                SBQQ__UpgradedSubscription__c,
                                SBQQ__UpgradedSubscription__r.SBQQ__StartDate__c,
                                SBQQ__Product__r.CWS_Show_CMS_Description__c,
                                SBQQ__Product__r.CWS_Show_CMS_Units__c,
                                SBQQ__Product__r.CWS_Description__c,
                                SBQQ__Product__r.CWS_Service_SOW_Link__c,
                                CWS_Included_Units__c 
                        FROM SBQQ__QuoteLine__c
                        WHERE SBQQ__Quote__c = :recId
                        ORDER BY SBQQ__Number__c ASC
                ];

                if (quoteLines.isEmpty() == false) {
                    // populate continuumWrap
                    String currencyS = quoteLines.get(0).SBQQ__Quote__r.CWS_Currency_Symbol__c;
                    continuumWrap = new List<ContinuumProductsWrapper>();

                    for(SBQQ__QuoteLine__c ql :quoteLines) {
                        //Ticket - 14008266 fix
                        if(ql.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment'){
                            isAmendmentQuote = true;
                        }
                        if(ql.SBQQ__Quantity__c <= 0) {
                            continue;
                        }
                        if(ql.SBQQ__Product__r.CWS_Hide_on_OrderForm__c == false) {
                            if(!( ql.CWS_Transaction_Type__c != null && ql.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW
                                    && ql.SBQQ__Quote__r.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT )
                                    && !(ql.CWS_Transaction_Type__c != null && ql.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3
                                    && ql.SBQQ__Quote__r.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT)) {
                                ContinuumProductsWrapper wrapperInstance = new ContinuumProductsWrapper();

                                if((ql.SBQQ__Product__r.CWS_Source__c == CWS_ConstantClass.PRODUCT_SOURCE_CMS || ql.SBQQ__Product__r.CWS_Source__c == CWS_ConstantClass.PRODUCT_SOURCE_R1Soft) && ql.SBQQ__Product__r.CWS_Hide_on_OrderForm__c == false){
                                    continuumProductsAvailable = true;
                                    if(ql.SBQQ__SubscriptionTerm__c != null && ql.SBQQ__SubscriptionTerm__c != 0) {
                                        if(ql.CWS_Exclude_from_Net_Total__c && ql.CWS_RegularPrice__c != null) {
                                            listPricePerMonth = (ql.CWS_RegularPrice__c / ql.SBQQ__SubscriptionTerm__c).setScale(2,System.RoundingMode.HALF_UP);
                                        } else if(ql.CWS_NetPrice__c!= null) {
                                            listPricePerMonth = (ql.CWS_NetPrice__c / ql.SBQQ__SubscriptionTerm__c).setScale(2,System.RoundingMode.HALF_UP);
                                        }
                                    } else {
                                        if(ql.CWS_Exclude_from_Net_Total__c && ql.CWS_Calculated_Subscription_Term__c != null && ql.CWS_Calculated_Subscription_Term__c!= 0 && ql.CWS_RegularPrice__c!= null) {
                                            listPricePerMonth = (ql.CWS_RegularPrice__c / ql.CWS_Calculated_Subscription_Term__c).setScale(2,System.RoundingMode.HALF_UP);
                                        } else if(ql.CWS_Calculated_Subscription_Term__c!= null && ql.CWS_Calculated_Subscription_Term__c!= 0 && ql.CWS_NetPrice__c!= null){
                                            listPricePerMonth = (ql.CWS_NetPrice__c / ql.CWS_Calculated_Subscription_Term__c).setScale(2,System.RoundingMode.HALF_UP);
                                        }
                                    }

                                    wrapperInstance.currencySymbol = currencyS;
                                    wrapperInstance.continummProducts = ql.SBQQ__ProductName__c;
                                    wrapperInstance.listPriceperMonth = listPricePerMonth;
                                    wrapperInstance.sowLink = ql.SBQQ__Product__r.CWS_Service_SOW_Link__c;
                                    wrapperInstance.longDescription = ql.SBQQ__Product__r.CWS_Description__c;
                                    wrapperInstance.displayLongDescription = ql.SBQQ__Product__r.CWS_Show_CMS_Description__c;
                                    wrapperInstance.displayUnits = ql.SBQQ__Product__r.CWS_Show_CMS_Units__c;
                                    wrapperInstance.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                                    wrapperInstance.freeUnits = (ql.CWS_Included_Units__c != null && ql.CWS_Included_Units__c != 0 ? Integer.valueOf(ql.CWS_Included_Units__c) : 0);
                                    continuumWrap.add(wrapperInstance);
                                }
                            }
                        }
                    }

                    commitWrap = new List<MinimumCommitWrapper>();
                    // assign currency symbol from "parent" quote line
                    String minCommitWrapCurrencySymbol = quoteLines?.get(0)?.SBQQ__Quote__r.CWS_Currency_Symbol__c;
                    // get the minimum commit records
                    Id parentOpportunityId = quoteLines?.get(0)?.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                    List<CWS_Minimum_Commit__c> minCommits = new List<CWS_Minimum_Commit__c>();
                    minCommits = [
                            SELECT CWS_Start_Of_Month__c, CWS_Month_Year__c, CWS_Monthly_Minimum_Commit__c
                            FROM CWS_Minimum_Commit__c
                            WHERE CWS_Opportunity__c = :parentOpportunityId
                            ORDER BY CWS_Start_Of_Month__c ASC
                    ];
                    if (minCommits.isEmpty() == false) {
                        minimumCommitDataAvailable = true;
                        for (CWS_Minimum_Commit__c minCommit : minCommits) {
                            MinimumCommitWrapper mcw = new MinimumCommitWrapper();
                            mcw.monthYear = minCommit.CWS_Month_Year__c;
                            mcw.startDate = minCommit.CWS_Start_Of_Month__c;
                            mcw.currencySymbol = minCommitWrapCurrencySymbol;
                            mcw.minCommitValue = minCommit.CWS_Monthly_Minimum_Commit__c;
                            commitWrap.add(mcw);
                        }
                    }

                    // FORCE-63 populate termWrapper
                    termWrap = new List<TermForConvWrapper>();
                    for (SBQQ__QuoteLine__c ql : quoteLines) {
                        if (ql.CWS_Termination_for_Convenience__c != null && ql.CWS_Termination_for_Convenience__c == true) {
                            TermForConvWrapper item = new TermForConvWrapper();
                            item.productName = ql.SBQQ__ProductName__c;
                            item.convMonths = 'N/A';
                            item.convExp = null;
                            if (ql.CWS_Convenience_Term__c != null) {
                                item.convMonths = String.valueOf(Integer.valueOf(ql.CWS_Convenience_Term__c));
                            }
                            if (ql.CWS_Convenience_Expiration_Date__c != null) {
                                item.convExp = ql.CWS_Convenience_Expiration_Date__c;
                            }
                            termWrap.add(item);
                        }
                    }
                    if (termWrap.size() > 0) {
                        termWrapperHasData = true;
                    }

                    // populate downgraded Quote Line Items
                    downgradeWrap = new List<DowngradeQLIWrapper>();
                    for (SBQQ__QuoteLine__c ql : quoteLines) {
                        if (ql.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMEND &&
                                (ql.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT ||
                                        ql.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE ||
                                        ql.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL)) {
                            DowngradeQLIWrapper wrapper = new DowngradeQLIWrapper();
                            if (ql.SBQQ__Product__r.Name != null) {
                                wrapper.name = ql.SBQQ__Product__r.Name;
                                wrapper.name = wrapper.name.replaceAll('[^a-zA-Z0-9\\s+]', '');
                            }
                            String localCurrencySymbol = quoteLines.get(0).SBQQ__Quote__r.CWS_Currency_Symbol__c;
                            if(currencyS != null) {
                                wrapper.currencySymbol = localCurrencySymbol;
                            }
                            if (ql.CWS_License_Type__c != null) {
                                wrapper.licenseType = ql.CWS_License_Type__c;
                            }
                            if (ql.SBQQ__PriorQuantity__c != null) {
                                wrapper.priorQuantity = ql.SBQQ__PriorQuantity__c;
                            }
                            if (ql.SBQQ__Quantity__c != null) {
                                wrapper.quantity = ql.SBQQ__Quantity__c;
                            }
                            // added
                            Decimal unitPrice;
                            if(ql.SBQQ__SubscriptionTerm__c != null && ql.SBQQ__SubscriptionTerm__c != 0) {
                                if(ql.CWS_Exclude_from_Net_Total__c && ql.CWS_RegularPrice__c != null) {
                                    unitPrice = (ql.CWS_RegularPrice__c / ql.SBQQ__SubscriptionTerm__c).setScale(2,System.RoundingMode.HALF_UP);
                                } else if(ql.CWS_NetPrice__c!= null) {
                                    unitPrice = (ql.CWS_NetPrice__c / ql.SBQQ__SubscriptionTerm__c).setScale(2,System.RoundingMode.HALF_UP);
                                }
                            } else {
                                if(ql.CWS_Exclude_from_Net_Total__c && ql.CWS_Calculated_Subscription_Term__c != null && ql.CWS_Calculated_Subscription_Term__c!= 0 && ql.CWS_RegularPrice__c!= null) {
                                    unitPrice = (ql.CWS_RegularPrice__c / ql.CWS_Calculated_Subscription_Term__c).setScale(2,System.RoundingMode.HALF_UP);
                                } else if(ql.CWS_Calculated_Subscription_Term__c!= null && ql.CWS_Calculated_Subscription_Term__c!= 0 && ql.CWS_NetPrice__c!= null){
                                    unitPrice = (ql.CWS_NetPrice__c / ql.CWS_Calculated_Subscription_Term__c).setScale(2,System.RoundingMode.HALF_UP);
                                }
                            }
                            if(unitPrice != null) {
                                wrapper.unitPrice = unitPrice;
                            }
                            // todo check startdate logic
                            if (ql.SBQQ__StartDate__c != null &&
                                    (ql.SBQQ__Quote__r.SBQQ__StartDate__c != null && ql.SBQQ__StartDate__c != ql.SBQQ__Quote__r.SBQQ__StartDate__c) &&
                                    (ql.SBQQ__UpgradedSubscription__c != null && ql.SBQQ__StartDate__c != ql.SBQQ__UpgradedSubscription__r.SBQQ__StartDate__c)) {
                                wrapper.startDate = ql.SBQQ__StartDate__c;
                            } else {
                                wrapper.startDate = null;
                            }
                            downgradeWrap.add(wrapper);
                        }
                    }
                    System.debug(JSON.serializePretty(downgradeWrap));
                    if(downgradeWrap.size() > 0) {
                        downgradeWrapperHasData = true;
                    }
                    System.debug(termWrap);
                    System.debug(commitWrap);
                    System.debug(continuumWrap);
                    System.debug(downgradeWrap);
                }
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug(ex.getCause());
            System.debug(ex.getTypeName());
            CWS_ExceptionHandler.logException(
                    ex,
                    'SBQQ__QuoteDocument__c',
                    'CWS_LegacyDocument_Controller',
                    'fetchData',
                    '',
                    null,
                    null,
                    'fetchData',
                    null
            );
        }
        return null;
    }

    public with sharing class ContinuumProductsWrapper {
        public String currencySymbol { get; set; }
        public Decimal listPriceperMonth { get; set; }
        public String continummProducts { get; set; }
        public Integer quantity {get;set;}
        public Integer freeUnits {get;set;}
        public String longDescription{get;set;}
        public String sowLink {get;set;}
        public Boolean displayLongDescription{get;set;}
        public Boolean displayUnits{get;set;}
    }


    public with sharing class MinimumCommitWrapper {
        public Date startDate { get; set; }
        public String monthYear { get; set; }
        public String currencySymbol { get; set; }
        public Decimal minCommitValue { get; set; }
    }

    public with sharing class TermForConvWrapper {
        public String productName { get; set; }
        public Date convExp { get; set; }
        public String convMonths { get; set; }
    }

    public class DowngradeQLIWrapper {
        public String name { get; set; }
        public String currencySymbol { get; set; }
        public String licenseType { get; set; }
        public Decimal priorQuantity { get; set; }
        public Decimal quantity { get; set; }
        public Decimal unitPrice { get; set; }
        public Date startDate { get; set; }
    }

}