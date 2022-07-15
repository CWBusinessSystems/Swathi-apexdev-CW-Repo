/* Class Name   : CWS_ConstantClass
 * Description  : Contains constants used through out the application   
 * Created By   : Aakash Sharma
 * Created On   : 4/3/2020

 * Modification Log:     
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                    Modification ID      Description 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Aakash Sharma                 4/3/2020                                     Initial Version
 * Mahak Bansal                  7/13/2021                                    Constants added for #14534574 - OBD-154
 * Ad Victoriam Solutions        02/14/2022                                   Added new values for Opportunity StageName
 */

 public with sharing class CWS_ConstantClass {
    //Constructor
    public CWS_ConstantClass() {
    }
    
   public static final String MINCOM_BASESKU_900901 = '900901';
   public static final String MINCOM_BASESKU_900904  = '900904';
    
    //3204
   public static final String CUSTOM = 'Custom';
   public static final String SOW = 'SOW';

   public static final String PRODUCT_SOURCE_CMS = 'CMS';
   public static final String PRODUCT_SOURCE_R1Soft = 'R1Soft';
   public static final String PRODUCT_SOURCE_CW = 'CW';
   public static final String MINIMUM_COMMIT_MONTHYEAR_jan = 'jan';
   public static final String MINIMUM_COMMIT_MONTHYEAR_feb ='feb';
   public static final String MINIMUM_COMMIT_MONTHYEAR_mar = 'mar';
   public static final String MINIMUM_COMMIT_MONTHYEAR_apr = 'apr';
   public static final String MINIMUM_COMMIT_MONTHYEAR_may = 'may';
   public static final String MINIMUM_COMMIT_MONTHYEAR_jun = 'jun';
   public static final String MINIMUM_COMMIT_MONTHYEAR_jul = 'jul';
   public static final String MINIMUM_COMMIT_MONTHYEAR_aug = 'aug';
   public static final String MINIMUM_COMMIT_MONTHYEAR_sep = 'sep';
   public static final String MINIMUM_COMMIT_MONTHYEAR_oct = 'oct';
   public static final String MINIMUM_COMMIT_MONTHYEAR_nov = 'nov';
   public static final String MINIMUM_COMMIT_MONTHYEAR_dec = 'dec';
   public static final String Minimum_Commit_Code = 'CU-OTHERSAAS900901'; 
    //3204
     public static final String TASK_STATUS_CLOSED = 'Closed';
    public static final String TASK_STATUS_INPROGRESS = 'In Progress';
    public static final String TASK_STATUS_NOTSTARTED = 'Not Started';
    public static final String TASK_STATUS_SYSCLOSED = 'System Closed';
    public static final String TASK_STATUS_COMPLETED = 'Completed';

    //General constants
    public static final String RENEWAL_BATCH_ON = 'ON'; 
    public static final String COMPLETED = 'Completed';
    public static final String PARTIALLY_COMPLETED = 'Partially Completed';    
    public static final String SWITCH_BATCH_ON = 'ON';
     
     // Product Category
    public static final String PRODUCT_CATEGORY_DEDICATED_TECH = 'Assist - Dedicated Tech';
    public static final String PRODUCT_TYPE_Packaging = 'Packaging';
    public static final String PRODUCT_TYPE_Charge = 'Charge';
    public static final String ZUORA_TYPE_STATUS = 'Posted';//BED-13804
    
       // Product Category
    public static final String PRODUCT_SUB_CATEGORY_EVENTS = 'Events';  
    public static final String PRODUCT_CATEGORY_MANAGE = 'Manage';
     
    // Product SKU TYPES
    public static final String PRODUCT_SKU_TYPE_IMPLEMENTATION = 'Implementation';
    public static final String PRODUCT_SKU_TYPE_SERVICES = 'Services';
    public static final String Product_AdditionRestriction_NewAgreement = 'New Agreement and Conversion';
    public static final String Product_AdditionRestriction_Conversion = 'Conversion';
   public static final String Product_AdditionRestriction_Downg = 'Downgrade';
     
    //Product Charge model
    public static final String ChargeModel_perUnit = 'Per Unit Pricing';
    public static final String ChargeModel_flatFee = 'Flat Fee Pricing';
    
    
    //BED-6479
    //Aura Method Return Strings and Batch class Strings
    public static final String AURA_SUCCESS= 'success';
    public static final String AURA_FAILURE= 'failure';//BED-13804
    public static final String BATCH_ACTIVATE= 'Activate';
    public static final String BATCH_DEACTIVATE= 'Deactivate';
    public static final String BATCH_DEACTIVATION= 'Deactivation';
    public static final String BATCH_ACTIVATION= 'Activation';
    public static final String OPPORTUNITY_NAME = 'Opportunity';
    //Query Limit Constant
    public static final String LIMIT_ONE = '1';
    public static final String LIMIT_TWO = '2';
    //User Licence type static constants
    public static final String LICENSE_PARTNER = 'Partner Community';
    public static final String Quote_NAME = 'SBQQ__Quote__c';
    
    //Share Access static constants
    public static final String USERINFO_STANDARD = 'Standard';
    public static final String ACCESS_READ = 'Read';
    public static final String ACCESS_NONE = 'None';
    public static final String ACCESS_EDIT = 'Edit';
    public static final String SOBJECT_ACCOUNT = 'Account';
    public static final String ACCESS_ROWCAUSE = 'Apex Sharing';
    public static final String ACCESS_CUSTOM_OBJECT = '__c';
    public static final String ACCESS_CUSTOM_OBJ_SHARE = '__Share';
    public static final String ACCESS_STD_OBJ_SHARE = 'Share';
    public static final String ACCESS_ACCOUNT_LEVEL = 'AccountAccessLevel';
    public static final String ACCESS_LEVEL = 'AccessLevel';
    public static final String ACCESS_PARENTID = 'ParentId';
    public static final String ACCESS_ID = 'Id';
    public static final String ACCESS_ACC_CONTACT = 'ContactAccessLevel';
    public static final String ACCESS_ACC_OPPTY = 'OpportunityAccessLevel';
    public static final String ACCESS_ACC_CASE = 'CaseAccessLevel';
    public static final String ACCESS_USER_USERGRP = 'UserOrGroupId';
    public static final String ACCESS_SHARE_CAUSE = 'RowCause';
    
    //Lead Static Constants for Sales Generated Leads
    public static final String LEAD_SALES_GENERATED = 'Sales Generated';
    public static final String LEAD_CHANNEL_GENERATED = 'Channel Generated';
    public static final String LEAD_ON_BOARDING = 'Onboarding';
    public static final String LEAD_SOURCE_DETAILS = 'Manual Lead created by ';
    public static final String LEAD_STATUS_REJECTED = 'Rejected';
    public static final String LEAD_STATUS_RECYCLED = 'Recycled';
    public static final String LEAD_STATUS_CONTACTED = 'Contacted';
    public static final String LEAD_STATUS_MQL = 'MQL';
    public static final String LEAD_STATUS_SAL = 'SAL';
    public static final String LEAD_RT_API_READ = 'CWS_Lead_Read_Only';
    public static final String LEAD_RT_API_EDIT = 'CWS_Lead_Edit';
    public static final String LEAD_STATUS_CONVERTED = 'Converted';
    public static final String LEAD_SQO_ACCEPTED     = 'SQO Accepted';
    
    //Contact Static Constants
    public static final String CONTACT_STATUS_MQL = 'MQL';
    public static final String CONTACT_STATUS_SAL = 'SAL';
    
    //Account RecordTypeIDs
    public static final String ACCOUNT_RT_PROSPECT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CWS_Prospect_Account').getRecordTypeId();
    public static final String ACCOUNT_RT_REVIEW = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CWS_Review_Account').getRecordTypeId();
    public static final String ACCOUNT_RT_ACTIVE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CWS_Active_Account').getRecordTypeId();
    
    //Task Record Type
    public static final String TASK_DEMO = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('CWS_Demo').getRecordTypeId();
    public static final String TASK_FMC = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('CWS_Field_Marketing_Campaign').getRecordTypeId();
    
    
    //Account Status Constants
    public static final String ACCOUNT_STATUS_PROSPECT = 'Prospect';
    public static final String ACCOUNT_STATUS_REVIEW = 'In Review';
    public static final String ACCOUNT_STATUS_ACTIVE = 'Active';
    public static final String ACCOUNT_RSTATUS_NORESTRICTION = 'No Restriction';
    public static final String ACCOUNT_RSTATUS_DELINQUENT = 'Delinquent';
    public static final String ACCOUNT_RSTATUS_PAYMENTWORKOUT = 'Payment Workout';
    public static final String ACCOUNT_RSTATUS_CREDITHOLD = 'Credit Hold';
    public static final String ACCOUNT_RSTATUS_SHUTOFF = 'Shut Off';
    public static final String FORMER_PARTNER_STATUS= 'Former Partner';

    //Account Integration Status Constants
    public static final String INT_STATUS_READY = 'Ready For Sync';
    public static final String INT_STATUS_SYNCED = 'Synced';
    public static final String INT_STATUS_ERROR = 'Error';
    public static final String INT_STATUS_NOT_SYNCED = 'Not Synced';

    public static final String INT_MIN_COM_STATUS = 'Ready to sync';
    
    //Quote type Constants
    public static final String QUOTE_TYPE_QUOTE = 'Quote';
    public static final String QUOTE_TYPE_RENEWAL= 'Renewal';
    public static final String QUOTE_TYPE_RENEWALWC= 'Renewal with Change';
    public static final String QUOTE_TYPE_NEW_BUSINESS = 'New Business';
    public static final String QUOTE_TYPE_AMEND = 'Amendment';
    public static final String QUOTE_TYPE_AMENDMENT = 'Amendment';
    public static final String QUOTE_SUB_TYPE_CREDIT = 'Credit';
    public static final String QUOTE_SUB_TYPE_REBILL = 'Rebill';

    //Quote ApprovalStatus Constants
    public static final String QUOTE_Approval_Status_Pending = 'Pending';
    public static final String QUOTE_Approval_Status_Approved= 'Approved';
    public static final String QUOTE_Approval_Status_Rejected= 'Rejected';
    public static final String QUOTE_Approval_Status_Recalled= 'Recalled';

     //transaction reason constants
    public static final String TRANSACTION_REASON_NEW = 'New';
    public static final String TRANSACTION_REASON_CREDIT_REBILL = 'Credit/Re-bill';
    public static final String TRANSACTION_AGREEMENT_CONVERSION = 'Agreement Conversion';
    public static final String TRANSACTION_REASON_MERGER_ACQUISTION = 'Merger & Acquisition';
    public static final String TRANSACTION_REASON_RECOMMIT = 'Recommit';
    public static final String TRANSACTION_REASON_TERMINATION = 'Termination';
    public static final String TRANSACTION_REASON_ADDENDUM = 'Addendum';
    public static final String TRANSACTION_REASON_SWAP = 'Swap';
    public static final String TRANSACTION_REASON_RENEWALWC = 'Renewal with change';
    public static final String CONVERSION_TYPE_EMAIL_TEMPLATE = 'CWS_Install_Team_Email_Template';    
    public static final String CONVERSION_TYPE_PERPETUAL_SAAS = 'Perpetual to SaaS';
    public static final String CONVERSION_TYPE_ONPERM_SAAS = 'On-Prem to SaaS';
    public static final String CONVERSION_TYPE_SAAS_ONPERM = 'SaaS to On-Prem';
    public static final String CONVERSION_TYPE_SAAS_TO_SUB = 'SaaS to Subscription';
    public static final String CONVERSION_TYPE_SUB_TO_SAAS = 'Subscription to SaaS';
    public static final String CONVERSION_TYPE_SAASPKG_TO_SUBPKG = 'SaaS Package to Subscription Package';
    public static final String CONVERSION_TYPE_SUBPKG_TO_SAASPKG = 'Subscription Package to SaaS Package';
    public static final String TRANSACTION_TYPE_UPGRADE = 'Upgrade';
    public static final String TRANSACTION_TYPE_DOWNGRADE = 'Downgrade';
    public static final String TRANSACTION_TYPE_CANCEL = 'Cancel';
    public static final String TRANSACTION_TYPE_SWAPIN = 'Swap-in';
    public static final String TRANSACTION_TYPE_SWAPOUT = 'Swap-out';
    public static final String TRANSACTION_TYPE_ADD_ON = 'Add-on';
    public static final String TRANSACTION_REASON_NEW3='New3';
   public static final String Maintenance_sub_Category='Maintenance';
   public static final String Product_Category_Perch='Perch';
   public static final String Product_Category_Solution_Partners='Solution Partners';


    //Quote Status Constants
    public static final String QUOTE_STATUS_DRAFT= 'Draft';
    public static final String QUOTE_STATUS_APPROVED = 'Approved';
    public static final String QUOTE_STATUS_INREVIEW = 'In Review';
    public static final String QUOTE_STATUS_REVISION = 'Requires Revision';
    public static final String QUOTE_STATUS_ORDERFORM_GEN = 'Order Form Generated';
    public static final String QUOTE_STATUS_AWAIT_SIG = 'Awaiting Signature';
    public static final String QUOTE_STATUS_ACCEPTED = 'Accepted';
    public static final String QUOTE_STATUS_INACTIVE = 'Inactive';

    //Quote RecordTypeIds
    public static final String QUOTE_RTYPE_AMEND_RONLY = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Amendment Read-Only').getRecordTypeId();
    public static final String QUOTE_RTYPE_APPROVED = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Approved Quote').getRecordTypeId();
    public static final String QUOTE_RTYPE_CLOSED_RONLY = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Closed Read-Only').getRecordTypeId();
    public static final String QUOTE_RTYPE_INREVIEW = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('In Review Quote').getRecordTypeId();
    public static final String QUOTE_RTYPE_NEW_EDIT = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('New Editable').getRecordTypeId();
    public static final String QUOTE_RTYPE_RENEWAL_RONLY = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Renewal Read-Only').getRecordTypeId();
    public static final String QUOTE_RTYPE_RENEWAL_EDIT = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Renewal Editable').getRecordTypeId();
    public static final String QUOTE_RTYPE_RENEWAL_APPROVED_RONLY = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Renewal Approved Readonly').getRecordTypeId();   
    public static final String QUOTE_RTYPE_RENEWAL_INREVIEW = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Renewal In Review Quote').getRecordTypeId();
    public static final String QUOTE_RTYPE_LEGACY_EDITABLE = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Legacy Editable').getRecordTypeId(); 
    public static final String QUOTELine_RTYPE = Schema.SObjectType.SBQQ__Quoteline__c.getRecordTypeInfosByName().get('QuoteLine').getRecordTypeId();
 
    // Order Form Expiration Reason
    public static final String QUOTE_OF_EXPIR_REASON = 'Account Restriction';
    public static final String QUOTE_OF_NOTIF_TEMPLATE = 'CWS_Quote_OF_Cancellation_Notification';

    // Approvals Quote Account Restriction
    public static final String QUOTE_ACC_RESTRICT_APPROVAL = 'Approval for Account Restriction';
    
    // QuoteDocument Signature Status
    public static final String QDOC_SIG_SENT = 'Sent';
    public static final String QDOC_SIG_SIGNED = 'Signed';
    public static final String QDOC_SIG_DELIVERED = 'Delivered';
    public static final String QDOC_SIG_COMPLETED = 'Completed';
    public static final String QDOC_SIG_DECLINED = 'Declined';
    public static final String QDOC_SIG_Voided = 'Voided';

    //QuoteDocument Type
    public static final String QDOC_TYPE_QD = 'QuoteDocument';
    public static final String QDOC_TYPE_OF = 'OrderForm';
    
    //QuoteDocument Naming Conventions
    public static final String QDOC_INITIALS_QD = 'QD';
    public static final String QDOC_INITIALS_OF = 'OF';
    public static final String QDOC_QTYPE_NEW = 'New';
    public static final string QDOC_NAME_FORMAT = '{0}-{1}-{2}-{3}-V{4}.0'; //AccName-DocType-QuoteType-QuoteNumber-Version

    // Order Constants
    public static final String ORDER_STATUS_UNDER_REVIEW = 'Under Review';
    public static final String ORDER_REVIEW_REASON_MISSING_PO ='Missing PO';
    public static final String ACCOUNT_PO_REQUIRED_YES='Yes';
    public static final String ORDER_STATUS_READY_FOR_SUBMISSION ='Ready for Submission';
    public static final String ORDER_STATUS_PENDING_FULFILLMENT ='Pending Fulfillment';
    public static final String ORDER_STATUS_PROCESSED ='Activated';
    public static final String ORDER_STATUS_CANCELLED ='Cancelled';
    public static final String ORDER_STATUS_FAILED ='Failed';
    public static final String ORDER_STATUS_PARTIALLY_PROCESSED ='Partially Processed';
    public static final String AMENDMENT_CONTRACT_ACTION ='Quantity Increase';
    public static final String ORDER_TYPE_AMENDMENT ='Amendment'; 
    public static final String ORDER_TYPE_RENEWAL ='Renewal'; 
    public static final String BillCycleType ='DefaultFromCustomer'; 
    
    // Callout constant
    public static final String CALLOUT_ENDPOINT_PREFIX = 'callout:';
    public static final String CALLOUT_SUBMIT_ORDER = 'CWS_SubmitOrder';
    public static final Integer CALLOUT_BATCH_FREQUENCY = 1;
    public static final String CALLOUT_MANAGE_CONTACT  ='CWS_ContactManageIntegration';
    public static final String CALLOUT_MANAGE_ACCOUNT  ='CWS_AccountManageIntegration';
    
    //Added by Mahak Bansal for #14534574
    public static final String CALLOUT_SITEDETAIL_REPORT = 'CWS_SiteDetail';
    public static final String CALLOUT_SITEDETAIL_REPORT_NAME_INITIAL = 'SiteDetails_';
    public static final String CALLOUT_SITEDETAIL_REPORT_EXT = '.xlsx';
    public static final String CALLOUT_SITEDETAIL_REPORT_REQ_HEADER ='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    
    // Provisional Eligibility
    public static final String PROVISIONAL_ELIGIBILITY_IMMEDIATE ='Immediate';
    public static final String PROVISIONAL_ELIGIBILITY_MANUAL ='Manual'; 
    public static final String PROVISIONAL_ELIGIBILITY_NA ='NA'; 
    
    //Payment term
    public static final String Payment_Term_Net_30 = 'Net 30';
    public static final String Payment_Term_Due_Upon_Receipt = 'Due Upon Receipt';

    // Payment Schedule Driver
    public static final String PAYMENT_SCHEDULE_DRIVER_SPREAD = 'Spread';
    public static final String PAYMENT_SCHEDULE_DRIVER_RAMP = 'Ramp';
    public static final String PAYMENT_SCHEDULE_DRIVER_DEFERMENT = 'Deferment';
      //BED-9272: Added Values
    public static final String PAYMENT_SCHEDULE_USAGE_BASED_RAMP = 'Usage Based Ramp';
    public static final String PAYMENT_SCHEDULE_USAGE_BASED_RAMP_ForSane = 'Usage-Based Ramp';
    public static final String PAYMENT_SCHEDULE_MIN_COMMIT_RAMP = 'Minimum Commit Ramp';    

    //PriceBook constant
    public static final String CONNECTWISE_PRICEBOOK = 'ConnectWise Standard PriceBook';
    public static final String TRIGGER_PROCESSING = 'Processing';
    public static final String PROMOTION_ACTIVE = 'Active';


    //Distributor/Reseller Constants
    public static final String DISTRIBUTOR_TYPE='Distributor';
    public static final String RESELLER_TYPE='Reseller';
    public static final String FULFILLMENTTYPE_FULFILLMENT='Fulfillment';
    public static final String FULFILLMENTTYPE_DEALREG='Deal Reg';
   //Account Autorized Reseller Values
   public static final String AUTHORIZED_RESELLER_1TIER_OR_2TIER='1-Tier/2-Tier Authorized';
   public static final String AUTHORIZED_RESELLER_2TIER='2-Tier Authorized';    

    //Product Route to market field values constants 
    public static final String RTM_Value_Channel ='Channel';
    public static final String RTM_Value_Direct ='Direct';
    public static final String RTM_Value_IIT ='IIT';
    public static final String Minimum_Commit_Prod ='Minimum Commitment Charge'; 
    
    //Renewal Notification Email Templates
     public static final String RenewalEmailOptIn='CWS_Renewal_Notification_Opt_In';
     public static final String RenewalEmailOptOut='CWS_Renewal_Notification_Opt_Out';
     public static final String RenewalEmailOptOutDisty='CWS_Renewal_Notification_Opt_Out_Disty';
     public static final String RenewalEmailOptInDisty='CWS_Renewal_Notification_Opt_In_Disty';
     public static final String RenewalEmailOptIn90='CWS_Renewal_Notification_90DayOptIn';
     public static final String RenewalEmailOptOut90='CWS_Renewal_Notification_90DayOptOut';
     public static final String OptOut90='OPT_OUT90';
     public static final String OptIn90='OPT_IN90';
     public static final String OptOutDisty='OPT_OUTDISTY';
     public static final String OptInDisty='OPT_INDISTY';
     public static final String RenewalEmailOptOutlegacy='CWS_Renewal_Notification_Opt_Out_Legacy';

    
    //Profiles for Contract Amendment  
    public static final String amendProfiles='System Administrator,CWS_Global_Sales_Ops,CWS_Sales_Manager,CWS_Contract_Admin,CWS_Order_Management,CWS_Partner_Care';
    public static final String SysAdminProfile='System Administrator';
    public static final String GlobalSalesOpsProfile='CWS_Global_Sales_Ops';
    public static final String ContractAdminProfile='CWS_Contract_Admin';
    public static final String PROFILE_TELE_SALES='CWS_Tele_Sales'; 
    public static final String PROFILE_SALES_REP='CWS_Sales_Rep';
    public static final String Master_Data_Admin_Profile='CWS_Master_Data_Admin';
    public static final String OMProfile='CWS_Order_Management';
    public static final String PROFILE_SALES_MANAGER='CWS_Sales_Manager';
    public static final String PROFILE_PARTNER_CARE='CWS_Partner_Care';

    
    //Limit for query on Group Members
    Public Static final String limitGM='5000'; 
    
    //Opportunity Stage Constants
    public static final String OpportunityClosedWon_Stage = 'Closed Won';
    public static final String OpportunityClosedLose_Stage = 'Closed Lost';
    public static final String OPPORTUNITY_STAGE_CLOSEDWONLEGACY = 'Closed Won - Legacy';//BED-13015
    public static final String OPPORTUNITY_STAGE_PROSPECTING= 'Prospecting';//BED-64
    public static final String OPPORTUNITY_STAGE_ANALYSIS= 'Analysis';//BED-64
    public static final String OPPORTUNITY_STAGE_QUALIFICATION= 'Qualification';//BED-64
    public static final String OPPORTUNITY_STAGE_EVALUATION= 'Evaluation';
    public static final String OPPORTUNITY_STAGE_DEMO= 'Demo';//BED-64
    public static final String OPPORTUNITY_STAGE_PROPOSAL= 'Proposal';
    public static final String OPPORTUNITY_STAGE_FINALIZE_QUOTE= 'Finalize Quote';
    public static final String Opportunity_Type_New = 'New Business';
    public static final String Opportunity_Type_Amendment = 'Amendment';
    public static final String Opportunity_Type_Renewal = 'Renewal';
    public static final String Opportunity_Type_RenewalWithChange = 'Renewal with Change';
    public static final String Opportunity_Type_CommissionOnly = 'Commission Only';
    public static final String OPPORTUNITY_LOST_ACCOUNTRESTRICTED = 'Account Restricted';
    public static final String OPPORTUNITY_RouteToMarket_Direct = 'Direct';
    public static final String OPPORTUNITY_RouteToMarket_IIT = 'IIT'; 
    
    //Opportunity RecordTypeIds
    public static final String Opportunity_NewBusiness_ReadOnly = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_New_Business_ReadOnly').getRecordTypeId();
    public static final String Opportunity_Amendment_ReadOnly = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_Amendment_ReadOnly').getRecordTypeId();
    public static final String Opportunity_Renewal_ReadOnly = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_Renewal_ReadOnly').getRecordTypeId();
    public static final String Opportunity_Amendment = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_Amendment').getRecordTypeId();
    public static final String Opportunity_NewBusiness = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_New_Buisness').getRecordTypeId();
    public static final String Opportunity_Renewal = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_Renewal').getRecordTypeId();
    public static final String Opportunity_CommissionOnly = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_Commision_Only').getRecordTypeId();
    public static final String Opportunity_CommissionOnlyReadOnly = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_Commission_Only_ReadOnly').getRecordTypeId();
    public static final String OPPORTUNITY_RT_NEWBUSINESS_INTERIM = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_New_Business_Interim').getRecordTypeId();
    public static final String OPPORTUNITY_RT_RENEWAL_INTERIM = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_Renewal_Interim').getRecordTypeId();
    public static final String OPPORTUNITY_RT_AMENDMENT_INTERIM = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CWS_Amendment_Interim').getRecordTypeId();
    
    //Trial Product type and stage constants
    public static final String TRIAL_TYPE_COMMAND = 'Command';
    
    //Agreement Recordtypes & Status
    public static final String SOW_Agreement_RT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_SOW_Agreement').getRecordTypeId();
    public static final String NDA_Agreement_RT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_NDA_Agreement').getRecordTypeId();
    public static final String MSA_Agreement_RT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_MSA_Agreement').getRecordTypeId();
    public static final String BAA_Agreement_RT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_BA_Agreement').getRecordTypeId();
    public static final String Distributor_Agreement_RT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_Distributor_Reseller_Agreement').getRecordTypeId();
    public static final String Request_Status = 'Request';
    public static final String In_Signature_Status = 'In Signatures';
    public static final String Ready_for_signature_Status = 'Ready for Signatures';
    public static final String In_Authoring_Status = 'In Authoring';
    public static final String AGREEMENT_STATUS_INEFFECT = 'In Effect';
    public static final String AGREEMENT_STATUS_TERMINATED = 'Terminated';
    public static final String Agreement_Status_Fully_Signed = 'Fully Signed';
    public static final String AGREEMENT_STATUS_Other_party_Signatures = 'Other Party Signatures';
    public static final String AGREEMENT_STATUS_Signature_Declined = 'Signature Declined';
    public static final String AGREEMENT_STATUS_Cancelled = 'Cancelled';
    public static final String AGREEMENT_STATUS_In_Amendment = 'In Amendment';
    public static final String Approval_Not_Submitted = 'Not Submitted';
    
    //Content Document Link Helper values
    public static final String ContentDocLink_ShareType = 'V';
    public static final String ContentDocLink_Visibility = 'InternalUsers';
    public static final String ContentDocLink_Visibility_ALLUSERS = 'AllUsers';
    public static final String agreement_Ext_Id = 'a1Y';
    public static final String account_Ext_Id = '001';
    public static final String quote_Ext_Id = 'a0x';
    public static final String signed_Document_Name = 'signed';

    //Docusign Envelope Statuses
    public static final String Envelope_Status_Completed = 'Completed';
    public static final String Envelope_Status_Sent = 'Sent';
    public static final String Envelope_Status_Voided = 'Voided';
    public static final String Envelope_Status_Declined = 'Declined';

    
    //Quote/Contract Renewal Type
    public static final String Renewal_Type_OptOut='Opt-Out';
    public static final String Renewal_Type_OptIn='Opt-In';
    public static final String Renewal_Type_NonRenewable='Non-Renewable';
    public static final String Renewal_Category_SplitPending='Split-Pending';
    public static final String Renewal_Category_OptIn='Opt-In';
    public static final String Renewal_Category_OptOut='Opt-Out';
    public static final String Subscription_Type_Evergreen='Evergreen';

    //Contract Status 
    public static final String Contract_Status_Draft='Draft';
    public static final String Contract_Status_Activated='Activated';
    
    //Quote Line/Product ChargeType
    public static final String ChargeType_OneTime='One-Time';
    public static final String ChargeType_Recurring='Recurring';
    public static final String ChargeType_Usage='Usage';
    
    //Quote Billing Frequency
    public static final String BillingFrequency_Monthly='Monthly';
    public static final String BillingFrequency_Quarterly='Quarterly';
    public static final String BillingFrequency_Annual='Annual';
    public static final String BillingFrequency_SemiAnnual='Semiannual';
    public static final String BillingFrequency_BiAnnual ='Invoice Plan';
    
    //Quote Line/Product Billing Term
    public static final String BillingTerm_Monthly='Monthly';
    public static final String BillingTerm_Quarterly='Quarterly';
    public static final String BillingTerm_Annual='Annual';
    public static final String BillingTerm_SemiAnnual='Semi-Annual';
    public static final String BillingTerm_BiAnnual ='Bi-Annual';
    public static final String BillingTerm_TriAnnual='Tri-Annual';
    public static final String BillingTerm_OneTime='One-Time';
    
    //Third Party Label
    public static final String strThirdParty='3rd Party';
    public static final String strThirdParty1='Third Party';
    public static final String strPerch='Perch';
    public static final String strSolutionPartners='Solution Partners';
    
     //General Constants
    public static final String notAvailable='Not Available';
    public static final String GB='GB';
    public static final String NA_KEY='NANANA';
    public static final String EmailDomain = '@';
    public static final String Date_Mon_Hr_Sec = '00:00:00';
    public static final String DISCOUNTSCH_SLAB = 'Slab';

    
    //Renewal Opportunity Attention Constants & template name
    public static final String strBilling='Billing-only Product';
    public static final String strPerp='Perpetual Product';
    public static final String strIncorrect='Incorrect Currency';
    public static final String strAccountResrict ='Account Restriction Status Change';
    public static final String strIncorrectLE='Incorrect Legal Entity';
    public static final String StrSANTemplate='CWS_SpecialAttentionNotification';
    public static final String StrActiveBilling='Active\Billing Only';
    public static final String StrBillingonly ='Billing Only';
    public static final String strPerpOnly='Perpetual';
    public static final String strNoRistrict='No Restriction';
    public static final String GroupnameFTQ ='CWS_Fast_Track_Quote_Group';
    public static final String GroupNameEvtSpnShp  = 'CWS_Event_Sponsorship';
    public static final String GroupnameCA ='CWS_Contract_Admin';
    public static final String UK_EMEA_Region ='CWS_UK_EMEA_region';
    public static final String NA_Region ='CWS_NA_Region';
    public static final String APAC_Region ='CWS_APAC_Region';
    public static final String DistiEndCustomer ='Disti-End Customer Pricing';//BED-1018 
    public static final String InagramMicro ='Ingram Micro';//BED-1018 
    public static final String TechData ='TechData';//BED-1018 
    public static final String Disti_Pricing ='CW-Disti Pricing';   
    public static final String DistiEndCustErrMsg = 'Disti End Customer Error Msg';
    public static final String DistiPricingErrMsg = 'Disti Deal Disti Pricing';
    public static final String Master_Data_First_Accepted_Quotes='CWS_Master_Data_First_Accepted_Quotes';
    
     // Product Name for OF
    public static final String SellBasic_ProductCode ='SEL-LIC-SAASSELSTART';
    public static final String PRICINGMETHOD_BLOCK ='Block';
    
    
    //Activity Constants -BED-8750
    public static final String Priority_Normal ='Normal';
     public static final String TASK_STATUS_OPEN = 'Open';
    public static final String TASK_PRIORITY_HIGH = 'HIGH';
     public static final String TASK_TYPE_FOLLOW_UP = 'Follow Up';
     public static final String TASK_TYPE_CUSTOM_SOW_REQUEST = 'Custom SOW Request';
    public static final String CUSTOM_SOW = 'Custom SoW';

    public static final String FollowUp_Type ='Follow Up';
    public static final String Task_Subject = 'Opportunity Created: Follow Up';
     public static final String Task_Priority_FIRST = 'Do First';
   public static final String Task_Type_Other = 'Other';

    //Clauses
    public static final String BACKDATEDDOWNGR = 'Backdated Downgrade';
    
     //QuoteSubStage
     
    public static final String Sub_Stage ='Agreement On-Hold';
    public static final String InProgSub_Stage ='In-Progress';
    public static final String QUOTE_SUB_STAGE_PENDING_FULFILLMENT   ='Pending Fulfillment'; 
    
    //Quote Calculator APIs
    public static final String QUOTECALLBACK = 'CWS_QuoteCallback';

     // Min Commit 
    public static final Map < Integer, String > monthNameMap = new Map < Integer, String > {
      1 => 'Jan',
      2 => 'Feb',
      3 => 'Mar',
      4 => 'Apr',
      5 => 'May',
      6 => 'Jun',
      7 => 'Jul',
      8 => 'Aug',
      9 => 'Sep',
      10 => 'Oct',
      11 => 'Nov',
      12 => 'Dec'
     };
    //PermissionSet Name
    public static final String SalesRepCPQPermissionSet='CWS_Sales_Rep_CPQ';
    public static final String SalesOpsCPQPermissionSet='CWS_Global_Sales_Ops_CPQ';

    //User Constants
    public static final String USER_TYPE_AM='AM';//14003326
    public static final String USER_TYPE_DAM='DAM';//14003326
    
    public static final String createOrderSwitch = 'Create Order';

}