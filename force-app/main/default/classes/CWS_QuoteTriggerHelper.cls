/*Class Name: CWS_QuoteTriggerHelper
*Description: Helper Class for CWS_QuoteTriggerHandler
*Created By: Khayam
*Created On: 4/3/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Indra Ganesan          6/11/2020       BED-3528            Install Team Email Update
*Nirmal                 4/6/2020        BED-3177            Opportunity Currency to default on Quote
*Aakash                 5/18/2020       BED-8807            Before Insert and Before Update changes.
*Khayam                 5/19/2020       BED-8645            Account Restriction - Delinquency 
*Sudhir Moturu          5/19/2020       BED-892             Quote opportunity sync fields and opportunity stage update
*Sudhir Moturu          5/26/2020       BED-892             Added opportunity recortype logic
*Ankit                  5/24/2020       BED-6479            Populating bill to on new lookup to share records with channel Reps
*Ankit                  6/18/2020       BED-8615            Remove Renewal with change opp from on hold when closed won
*Ankit                  7/1/2020        BED-5041            Legal Entity defaulting and error on bill to currency change
*Ankit                  7/2/2020        BED-12239           Defaulting Quote RT once  cloned
*Ankit                  7/6/2020        RENEWALCAT_CHANGE_REQ - Changed the reference from Renewal Type to Renewal Category
*Sudhir Moturu          7/24/2020       BED-12680           Added billto or soldto account change check
*Sudhir Moturu          7/24/2020       BED-8895            Added substage condition for pending fulfillment to close opportunity
*Harsha                 9/17/2020       BED-13644           Expiration Date on Cloned Quote
*Jeff Cochran           11/11/2020      #14037565           Added line 2337 and commented out line 2336
*Carl Shahan            1/27/2021       #14154761           Changed reference to isProvisioningPending() lines 838 and 845 from CWS_QuoteDocumentTriggerHelper to CWS_QuoteDocumentTriggerUtility
*Ad Victoriam Solutions 02/14/2022          N/A             Refactored some methods for expanded test coverage to meet deployment needs.
*Mahak Bansal           03/08/2022      OBD-4193            Renewal Opportunities Not Closing (#15593225)
*/

public with sharing class CWS_QuoteTriggerHelper {

  
    public static final String rebeccaValue = 'Currency Conversion';

    /*
    * Method name  : beforeInsertMethod
    * @Description  : BED-3696 : Cloned Quote status Change-Before Insert
    * @Param    : List of new Quotes.
    * Developer    : Aakash
    */
    public static void beforeInsertMethod(List<SObject> lstNew1) {

        List<SBQQ__Quote__c> lstnew = (List<SBQQ__Quote__c>) lstNew1;
        List<Id> OppList = new List<Id>();
        Map<Id, Opportunity> OppMap = new Map<Id, Opportunity>();
        Map<String, Decimal> exchangeRate = new Map<String, Decimal>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> accountMap;
        Map<Id, Contract> conMap = new Map<Id, Contract>();
        Map<Id, Contract> conAccMap = new Map<Id, Contract>();
        Set<Id> acctList = new Set<Id>();
        //added for BED-3276

        //BED-8807 for Fast Track Quote
        String strgroup = CWS_ConstantClass.GroupnameFTQ;
        Integer intLimit = Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);
        Group lstPGroup;
        Map<Id, String> mapUserGroup = new Map<Id, String>();
        Set<Id> billtoAcct = new Set<Id>();

        Map<String, Id> mapDistributor = new Map<String, Id>();
        Set<String> setDistiReseller = new Set<String>();
        Set<Id> soldToAccountIds = new Set<Id>();
        Id loggedUser = UserInfo.getUserId();
        User userObj = new User();
        if (loggedUser != null) {
            userObj = [
                    SELECT
                        Id,
                        Profile.Name
                    FROM User
                    WHERE Id = :loggedUser
            ];
        }
        if (strgroup != null && intLimit != null) {
            lstPGroup = [
                    SELECT
                            Id,
                            Name,
                            DeveloperName,
                        (SELECT
                                Id,
                                UserOrGroupId
                        FROM GroupMembers
                        LIMIT :intLimit)
                    FROM Group
                    WHERE DeveloperName = :strgroup
            ];
        }
        for (GroupMember members : lstPGroup.GroupMembers) {
            mapUserGroup.put(members.UserOrGroupId, lstPGroup.DeveloperName);
        }

        Map<Id, CWS_Distributor_Reseller__c> distRecord = new Map<Id, CWS_Distributor_Reseller__c>();
        Map<Id, List<Id>> distSoldAcct = new Map<Id, List<Id>>();
        Map<Id, String> distResellerCheck = new Map<Id, String>();
//BED-3276 ends

        try {
            //BED-199 retrieving currencyISoCode from exchangerate
            //ISOCode = QuoteCurrency/CurrencyISOCode
            List<CurrencyType> exchangeList = [
                    SELECT
                            IsoCode,
                            ConversionRate,
                            IsActive
                    FROM CurrencyType
                    WHERE IsActive = TRUE
            ];
            System.debug('SOQL Queries: ' + System.Limits.getQueries());
            //Map of Exchange rate records
            for (CurrencyType exList : exchangeList) {
                exchangeRate.put(exList.IsoCode, exList.ConversionRate);
            }
            for (SBQQ__Quote__c quoteTemp : lstnew) {

                if (quoteTemp.SBQQ__Account__c != null) {
                    soldToAccountIds.add(quoteTemp.SBQQ__Account__c);
                }
                //BED-8825
                if (quoteTemp.SBQQ__Account__c != null && quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS) {
                    acctList.add(quoteTemp.SBQQ__Account__c);
                }
                //BED-8825 End
                accountIds.add(quoteTemp.SBQQ__Account__c);
                accountIds.add(quoteTemp.CWS_Bill_To_Account__c);
                //Every New Quote Created is a Primary Quote
                quoteTemp.SBQQ__Primary__c = true;
                quoteTemp.SBQQ__WatermarkShown__c = true;
                if (quoteTemp.SBQQ__ExpirationDate__c > System.today() + 90 && quoteTemp.CWS_Reference_Expiry_Date__c == null && quoteTemp.CWS_IsCloned__c == false && quoteTemp.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {
                    quoteTemp.addError(System.Label.CWS_Expire_date_canot_be_greater_than_90);
                }


                //BED-3177 creating a list of Ids of Opportunities linked with the quote.
                if (quoteTemp.SBQQ__Opportunity2__c != null) {
                    OppList.add(quoteTemp.SBQQ__Opportunity2__c);
                }

                //14002423 : Nulify CWS_LegacyKey__c field in case of cloning the quote
                if (quoteTemp.isClone()) {
                    quoteTemp.CWS_LegacyKey__c = null;
                    quoteTemp.CWS_IsCloned__c = true;
                }


                //CWS_Quote_Type is Updated with the OOB Type field.
                if (quoteTemp.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {
                    //BED-12862
                    if (quoteTemp.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) {
                        quoteTemp.CWS_Quote_Type__c = CWS_ConstantClass.QUOTE_TYPE_RENEWAL;
                    }
                    quoteTemp.SBQQ__SubscriptionTerm__c = quoteTemp.SBQQ__RenewalTerm__c;
                    //BED-6827
                    quoteTemp.CWS_Transaction_Reason__c = CWS_ConstantClass.QUOTE_TYPE_RENEWAL;
                }
                //Status Change in Case of Cloned Quotes
                if (quoteTemp.isClone()) {
                    //Start BED-12239 Record Type Assignment Once quote is cloned
                    if (quoteTemp.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_DRAFT ||
                            quoteTemp.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_REVISION) {

                        if (quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS) {
                            quoteTemp.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_NEW_EDIT;
                        } else if (quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT &&
                                quoteTemp.CWS_LegacyKey__c == null) {
                            quoteTemp.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY;
                        } else if (quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT &&
                                quoteTemp.CWS_LegacyKey__c != null) {
                            quoteTemp.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_LEGACY_EDITABLE;
                        } else if (quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {
                            quoteTemp.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_RONLY;
                        }

                    }
                    //End BED-12239
                    quoteTemp.CWS_OF_Signed_Override_Date__c = null;
                    quoteTemp.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_DRAFT;

                    //Cloned Quote Sub-Stage Default
                    quoteTemp.CWS_Sub_Stage__c = CWS_ConstantClass.InProgSub_Stage;
                    //Cloned Quote Sub-Stage Default
                    quoteTemp.ApprovalStatus__c = '';
                    quoteTemp.CWS_File_Attached__c = false;
                    quoteTemp.CWS_OF_Expiration_Reason__c = null;
                    // remove # from  CWS_Add_Terms_Manually__c BED-9236
                    if (quoteTemp.CWS_Add_Terms_Manually__c != null) {
                        quoteTemp.CWS_Add_Terms_Manually__c = quoteTemp.CWS_Add_Terms_Manually__c.replaceAll('#', '');
                    }

                    if (quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {
                        quoteTemp.CWS_Quote_Type__c = CWS_ConstantClass.QUOTE_TYPE_RENEWALWC;
                        quoteTemp.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_EDIT;
                        //BED-6827
                        quoteTemp.CWS_Transaction_Reason__c = CWS_ConstantClass.QUOTE_TYPE_RENEWALWC;
                        quoteTemp.CWS_On_Hold__c = false;
                        quoteTemp.CWS_On_Hold_Reason__c = null;
                    }

                    //BED-8807 for Fast Track Quote
                    if (mapUserGroup != null && userObj != null && (quoteTemp.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL || quoteTemp.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_AMEND || !mapUserGroup.containsKey(userObj.Id) && userObj.Profile.Name != CWS_ConstantClass.SysAdminProfile)) {
                        quoteTemp.CWS_isFastTrack__c = false;
                    }
                    //BED-8807 for Fast Track Quote
                }
                if (quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {
                    quoteTemp.SBQQ__OrderBy__c = 'CWS_Split_Order__c';
                } else {
                    quoteTemp.SBQQ__OrderBy__c = 'CWS_Split_Order__c';
                }

                //START - RENEWALCAT_CHANGE_REQ -> Defaulting Expiration Date on the basis of Renewal Category
                if (quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL ||
                        quoteTemp.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) {
                    if (quoteTemp.CWS_Renewal_Category__c == CWS_ConstantClass.Renewal_Type_OptIn) {
                        quoteTemp.SBQQ__ExpirationDate__c = quoteTemp.SBQQ__StartDate__c != null ? quoteTemp.SBQQ__StartDate__c + 30 : quoteTemp.SBQQ__ExpirationDate__c;
                    } else if (quoteTemp.CWS_Renewal_Category__c == CWS_ConstantClass.Renewal_Type_OptOut) {
                        quoteTemp.SBQQ__ExpirationDate__c = quoteTemp.SBQQ__StartDate__c != null ? quoteTemp.SBQQ__StartDate__c : quoteTemp.SBQQ__ExpirationDate__c;
                    }
                    //1341 -> Default Expiry date
                    if (quoteTemp.SBQQ__ExpirationDate__c != null) {
                        quoteTemp.CWS_Reference_Expiry_Date__c = quoteTemp.SBQQ__ExpirationDate__c;
                    }
                }
                //END- RENEWALCAT_CHANGE_REQ

                //added for BED-3276 - creating a set of Ids of the billtoaccount
                if (quoteTemp.CWS_Bill_To_Account__c != null) {
                    billtoAcct.add(quoteTemp.CWS_Bill_To_Account__c);
                }

            }
//BED-8825
            if (acctList.size() > 0) {
                conMap = new Map<Id, Contract>([
                        SELECT Id, Name, AccountId, CWS_Master__c,CWS_Status__c
                        FROM Contract
                        WHERE
                        AccountId IN:acctList AND CWS_Master__c = TRUE AND (CWS_Status__c = 'Active' OR CWS_Status__c = 'Inactive')
                        LIMIT 100
                ]);
            }
            System.debug('SOQL Queries: ' + System.Limits.getQueries());

            for (Contract con : conMap.values()) {
                conAccMap.put(con.AccountId, con);
            }
            //BED-8825 End

            //start BED-5177
            if (!soldToAccountIds.isEmpty() && !billtoAcct.isEmpty()) {
                String keyDistiReseller;
                for (CWS_Distributor_Reseller__c distiReseller : [
                        SELECT Id, CWS_Account__c, CWS_Type__c,
                                CWS_Distributor_ResellerAcc__c, CWS_Distributor_ResellerAcc__r.CWS_Is_Distributor__c,
                                CWS_Active__c
                        FROM CWS_Distributor_Reseller__c
                        WHERE CWS_Active__c = TRUE
                            AND CWS_Account__c IN :soldToAccountIds
                            AND CWS_Distributor_ResellerAcc__c IN :billtoAcct
                            AND (
                                    (CWS_Type__c = :CWS_ConstantClass.DISTRIBUTOR_TYPE
                                    AND CWS_Distributor_ResellerAcc__r.CWS_Is_Distributor__c = TRUE)
                                OR
                                    (CWS_Type__c = :CWS_ConstantClass.RESELLER_TYPE)
                                )
                            AND CWS_Distributor_ResellerAcc__c != NULL
                            AND CWS_Account__c != NULL
                ]) {
                    keyDistiReseller = distiReseller.CWS_Account__c + '-';
                    keyDistiReseller += distiReseller.CWS_Distributor_ResellerAcc__c + '-';
                    keyDistiReseller += distiReseller.CWS_Type__c;

                    setDistiReseller.add(keyDistiReseller);
                    mapDistributor.put(keyDistiReseller, distiReseller.CWS_Distributor_ResellerAcc__c);
                }
            }
            //end BED-5177
            System.debug('SOQL Queries: ' + System.Limits.getQueries());
            //BED-3177 Creating a map of Opportunities linked with the Quote.
            if (OppList != null && OppList.size() > 0) {
                OppMap = new Map<Id, Opportunity>([
                        SELECT Id,Type, CWS_Sub_Type__c, CurrencyIsoCode, SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.CWS_Payment_Term__c, CWS_CreatedByAM__c,
                                SBQQ__RenewedContract__r.CWS_Renewal_Type__c,CWS_Master__c,CWS_On_Hold__c, CWS_On_Hold_Reason__c, CWS_Transaction_Reason__c,
                                SBQQ__RenewedContract__r.CWS_Renewal_CAP__c, SBQQ__RenewedContract__r.CWS_Renewal_Uplift_Applicable__c,
                                SBQQ__AmendedContract__c, SBQQ__AmendedContract__r.CWS_ConversionType__c,SBQQ__AmendedContract__r.CWS_Payment_Term__c,
                                SBQQ__AmendedContract__r.CWS_TransactionReason__c, SBQQ__AmendedContract__r.CWS_OF_Signed_Date__c,
                                SBQQ__AmendedContract__r.CWS_Quote_SubType__c, SBQQ__AmendedContract__r.CWS_Re_Contract_Type__c, OwnerId, CWS_Sold_To_Contact__c, CWS_Bill_To_Account__c,
                                CWS_Bill_To_Contact__c, CWS_Ship_To_Account__c,CWS_Legal_Entity__c, AccountId
                        FROM Opportunity
                        WHERE Id IN:OppList
                ]);
            }
            System.debug('SOQL Queries: ' + System.Limits.getQueries());
            if (accountIds != null && !accountIds.isEmpty()) {
                accountMap = new Map<Id, Account> ([
                        SELECT
                                Id,
                                Name, CWS_Region__c,CWS_Is_IIT_Reseller__c, CWS_Authorized_Reseller__c, OwnerId,CWS_Payment_Terms__c, CWS_BA_Agreement__c, CWS_BA_Agreement_Status__c, CWS_MSA_Agreement__c, CWS_MSA_Agreement_Status__c, CWS_NDA_Agreement__c, CWS_NDA_Agreement_Status__c, CWS_Is_Partner__c, CWS_Is_Distributor__c, ParentId, CWS_Need_Recurring__c
                        FROM Account
                        WHERE Id IN :accountIds
                ]);
            }
            System.debug('SOQL Queries: ' + System.Limits.getQueries());

            String keySoldToBillToAccount;
            for (SBQQ__Quote__c quote : lstnew) {
                //Start BED-5177
                if (quote.SBQQ__Account__c != null && quote.CWS_Bill_To_Account__c != null &&
                        accountMap != null) {
                    keySoldToBillToAccount = quote.SBQQ__Account__c + '-' + quote.CWS_Bill_To_Account__c;
                    if (quote.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel &&
                            accountMap.containsKey(quote.CWS_Bill_To_Account__c)) {
                        if (!accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c) {
                            quote.addError(System.Label.CWS_QuoteErrBillToNotDistiWhenRTMChannel);
                        } else if (!setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE)) {
                            quote.addError(System.Label.CWS_QuoteErrRTMChannelBilltoNotInDistiReseller);
                        } else if (mapDistributor != null &&
                                mapDistributor.containsKey(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE)) {
                            quote.SBQQ__Distributor__c = mapDistributor.get(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE);
                        }
                    } else if (quote.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT &&
                            quote.SBQQ__Account__c != quote.CWS_Bill_To_Account__c &&
                            accountMap.containsKey(quote.CWS_Bill_To_Account__c)) {
                        System.debug('IIT Else If line 256');
                        if (!accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c && quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS &&
                                !accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Partner__c &&
                                accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Authorized_Reseller__c != CWS_ConstantClass.AUTHORIZED_RESELLER_1TIER_OR_2TIER &&
                                (!accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_IIT_Reseller__c ||
                                        !accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Partner__c)) {
                            quote.addError(System.Label.CWS_QuoteErrRTMIITandBillToNotPartnerAuthReseller);
                        } else if (((accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c &&
                                !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE)) ||
                                (accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_IIT_Reseller__c &&
                                        !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.RESELLER_TYPE)) ||
                                (accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Partner__c &&
                                        !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE) &&
                                        !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.RESELLER_TYPE)
                                ))) {
                            quote.addError(System.Label.CWS_QuoteErrRTMIITBillToNotInDistiReseller);
                        }
                        if (quote.CWS_Reseller_Account__c == null &&
                                accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c) {
                            quote.addError(System.Label.CWS_QuoteErrPopulateResellerwhenRTMIIT);
                        }
                        if (accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c &&
                                setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE)
                                ) {
                            quote.CWS_2_Tier_Authorized_Reseller__c = true;
                        }
                    }
                }
                //End BED-5177
                //BED-8204
                if (accountMap != null && quote.CWS_Bill_To_Account__c != null &&
                        accountMap.get(quote.CWS_Bill_To_Account__c) != null &&
                        accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Need_Recurring__c == true &&
                        OppMap != null && quote.SBQQ__Opportunity2__c != null &&
                        OppMap.get(quote.SBQQ__Opportunity2__c) != null &&
                        OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__c != null &&
                        OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_OF_Signed_Date__c != null) {
                    quote.SBQQ__StartDate__c = Date.newInstance(
                            Date.valueOf(OppMap.get(quote.SBQQ__Opportunity2__c)
                                    .SBQQ__AmendedContract__r
                                    .CWS_OF_Signed_Date__c).addMonths(1).year(),
                            Date.valueOf(OppMap.get(quote.SBQQ__Opportunity2__c)
                                    .SBQQ__AmendedContract__r
                                    .CWS_OF_Signed_Date__c).addMonths(1).month(),
                            1);
                }
                //End BED-8204
                //Start: BED-5041 Legal Entity defaulting in case og NB
                if (OppMap != null && quote.SBQQ__Opportunity2__c != null && OppMap.containsKey(quote.SBQQ__Opportunity2__c) &&
                        quote.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_QUOTE) {
                    quote.CWS_Legal_Entity__c = OppMap.get(quote.SBQQ__Opportunity2__c).CWS_Legal_Entity__c;
                }
                //BED-5041

                if (OppMap != null && quote.SBQQ__Opportunity2__c != null && OppMap.containsKey(quote.SBQQ__Opportunity2__c)) {
                    if (OppMap.get(quote.SBQQ__Opportunity2__c).CWS_Master__c == true) {
                        quote.CWS_Master__c = true;
                    } else {
                        quote.CWS_Master__c = false;
                    }
                }

                //BED-6254
                if (OppMap != null && quote.SBQQ__Opportunity2__c != null && OppMap.containsKey(quote.SBQQ__Opportunity2__c) && OppMap.get(quote.SBQQ__Opportunity2__c).CWS_CreatedByAM__c != null) {
                    quote.CWS_CreatedBy_AM__c = OppMap.get(quote.SBQQ__Opportunity2__c).CWS_CreatedByAM__c;
                }
                //BED-6254

                if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL &&
                        OppMap != null && quote.SBQQ__Opportunity2__c != null && OppMap.containsKey(quote.SBQQ__Opportunity2__c)
                        && OppMap.get(quote.SBQQ__Opportunity2__c).CWS_On_Hold__c == true) {
                    quote.CWS_On_Hold__c = true;
                    quote.CWS_On_Hold_Reason__c = OppMap.get(quote.SBQQ__Opportunity2__c).CWS_On_Hold_Reason__c;
                }
                //Start : BED-6479 Sync the Bill To Account with below fields which will be used for sharing opp with Channel Reps
                if (quote.CWS_Bill_To_Account__c != null && accountMap.get(quote.CWS_Bill_To_Account__c) != null
                        && (accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c || accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_IIT_Reseller__c)) {
                    quote.CWS_Share_with_Bill_To_Account__c = quote.CWS_Bill_To_Account__c;
                    quote.CWS_Shared_Bill_To_Id__c = quote.CWS_Bill_To_Account__c;
                }
                //Start : BED-6479

                //BED-6864 START
                //Defaulting New business quote payment term from Bill to Account
                if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && accountMap.containsKey(quote.CWS_Bill_To_Account__c)) {
                    quote.SBQQ__PaymentTerms__c = accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Payment_Terms__c;
                } else if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL && OppMap.containsKey(quote.SBQQ__Opportunity2__c) && OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__c != null) {
                    quote.SBQQ__PaymentTerms__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Payment_Term__c;
                    quote.OwnerId = OppMap.get(quote.SBQQ__Opportunity2__c).OwnerId;
                } else if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMEND && OppMap.containsKey(quote.SBQQ__Opportunity2__c) && OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__c != null) {
                    quote.SBQQ__PaymentTerms__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_Payment_Term__c;
                }
                //BED-6468 END

                //BED-3177 CurrencyISOCode will be defaulted with the Currency of its opportunity.
                if (quote.SBQQ__Opportunity2__c != null && OppMap.containsKey(quote.SBQQ__Opportunity2__c)) {
                    quote.CurrencyIsoCode = OppMap.get(quote.SBQQ__Opportunity2__c).CurrencyIsoCode;
                }
                if (quote.CWS_Quote_Type__c == 'Renewal' && quote.SBQQ__Opportunity2__c != null && OppMap.containsKey(quote.SBQQ__Opportunity2__c) &&
                        OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__c != null) {
                    //quote.CWS_Renewal_Type__c=oppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_Type__c;
                    if (OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_Uplift_Applicable__c == 1) {
                        quote.CWS_Renewal_CAP__c = null;
                        quote.CWS_Renewal_Uplift_Applicable__c = null;
                        quote.CWS_Prior_Renewal_CAP__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_CAP__c;
                    } else if (OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_Uplift_Applicable__c == null ||
                            OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_Uplift_Applicable__c <= 0) {
                        quote.CWS_Renewal_CAP__c = null;
                        quote.CWS_Prior_Renewal_CAP__c = null;
                        quote.CWS_Renewal_Uplift_Applicable__c = null;
                    } else if (OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_Uplift_Applicable__c > 1) {
                        quote.CWS_Renewal_CAP__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_CAP__c;
                        quote.CWS_Prior_Renewal_CAP__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_CAP__c;
                        quote.CWS_Renewal_Uplift_Applicable__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__RenewedContract__r.CWS_Renewal_Uplift_Applicable__c - 1;
                    }
                }

                if (accountMap != null && quote.SBQQ__Account__c != null && accountMap.containsKey(quote.SBQQ__Account__c)) {
                    quote.CWS_Region__c = accountMap.get(quote.SBQQ__Account__c).CWS_Region__c;

                    // added for BED-5930
                    //BED-8949
                    if (accountMap.get(quote.SBQQ__Account__c).CWS_BA_Agreement__c != null && accountMap.get(quote.SBQQ__Account__c).CWS_BA_Agreement_Status__c != null && (accountMap.get(quote.SBQQ__Account__c).CWS_BA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED && accountMap.get(quote.SBQQ__Account__c).CWS_BA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                        quote.CWS_BA_Agreement__c = accountMap.get(quote.SBQQ__Account__c).CWS_BA_Agreement__c;
                        quote.CWS_BA_Agreement_Status__c = accountMap.get(quote.SBQQ__Account__c).CWS_BA_Agreement_Status__c;
                    }
                    if (accountMap.get(quote.SBQQ__Account__c).CWS_MSA_Agreement__c != null && accountMap.get(quote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c != null && (accountMap.get(quote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED && accountMap.get(quote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                        quote.CWS_MSA_Agreement__c = accountMap.get(quote.SBQQ__Account__c).CWS_MSA_Agreement__c;
                        quote.CWS_MSA_Agreement_Status__c = accountMap.get(quote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c;
                    }
                    if (accountMap.get(quote.SBQQ__Account__c).CWS_NDA_Agreement__c != null && accountMap.get(quote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c != null && (accountMap.get(quote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED && accountMap.get(quote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                        quote.CWS_NDA_Agreement__c = accountMap.get(quote.SBQQ__Account__c).CWS_NDA_Agreement__c;
                        quote.CWS_NDA_Agreement_Status__c = accountMap.get(quote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c;
                    }
                    //BED-8949
                }
                //BED-199 Populating exchange rate on the quote header
                if (exchangeRate.containsKey(quote.CurrencyIsoCode)) {
                    quote.CWS_Exchange_Rate__c = exchangeRate.get(quote.CurrencyIsoCode);
                }

                //BED-6827 starts
                if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && !quote.isClone()) {
                    //START_CR_RECOMMIT when transaction reason is populated as recommit in opportunity, the same gets populated in the quote as well.
                    if (OppMap.get(quote.SBQQ__Opportunity2__c).CWS_Transaction_Reason__c != null &&
                            OppMap.get(quote.SBQQ__Opportunity2__c).CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT) {
                        quote.CWS_Transaction_Reason__c = CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT;
                    }

                    else {
                        quote.CWS_Transaction_Reason__c = CWS_ConstantClass.TRANSACTION_REASON_NEW;
                    }
                    //END_CR_RECOMMIT
                } else if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && quote.SBQQ__Opportunity2__c != null && OppMap.containsKey(quote.SBQQ__Opportunity2__c) && OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__c != null) {
                    if (OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_TransactionReason__c != null) {
                        quote.CWS_Transaction_Reason__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_TransactionReason__c;
                        if (quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL && OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_Quote_SubType__c != null) {
                            quote.CWS_Sub_Type__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_Quote_SubType__c;
                        }
                    }
                    if (OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_ConversionType__c != null) {
                        quote.CWS_Conversion_Type__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_ConversionType__c;
                    }
                    if (OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_Re_Contract_Type__c != null) {
                        quote.CWS_Re_Contract_Type__c = OppMap.get(quote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__r.CWS_Re_Contract_Type__c;
                    }
                }
                //bed-6827 ends
                //BED-8825
                /* TODO HAS MASTER CONTRACT, ARE WE KEEPING THIS CHANGE? */
                if (conAccMap.size() > 0 && conAccMap.get(quote.SBQQ__Account__c) != null) {
                    if (quote.CWS_Master__c == false) {
                        quote.CWS_Has_Master_Contract__c = true;
                    } else if ((quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT || quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS) && quote.CWS_Master__c == true && quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT && quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION && quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL) {
                        quote.addError(System.Label.CWS_Only_One_Master_Contract); //CR_RECOMMIT  Error  will be thrown for master and amendment quote.
                    }
                }
            }
        }

        catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CWS_QuoteTriggerHelper', 'CWS_QuoteTriggerHelper:BeforeInsertMethod', '', null, null, 'BeforeInsert', null);

        }
    }
    /*
    * Method name  : updateDistributorFulfillmentType
    * @Description : BED-1251 : Pricing for Channel RTM. updates distributor fulfillment type when a quote is
                    created or when distributor lookup on account is chnaged.
    * @Param    : newList  List of new Quotes,
    *             oldMap Trigger.oldMap
    * Return Type  : None
    * Developer    : Karthikeyan
    */
    public static void updateDistributorFulfillmentType(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        Map<String, String> mapDistributorFulfillmentType = new Map<String, String>();
        Map<String, String> mapDistributorCategory = new Map<String, String>();
        Set<Id> soldToAccountIds = new Set<Id>();
        Set<Id> distributorAccountIds = new Set<Id>();
        for (SBQQ__Quote__c quote : newList) {
            if (((oldMap == null && quote.SBQQ__Distributor__c != null) ||
                    (oldMap != null && quote.SBQQ__Distributor__c != null && oldMap.get(quote.Id) != null &&
                            oldMap.get(quote.Id).SBQQ__Distributor__c != quote.SBQQ__Distributor__c)) &&
                    quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_ACCEPTED) {
                soldToAccountIds.add(quote.SBQQ__Account__c);
                distributorAccountIds.add(quote.SBQQ__Distributor__c);
            }
        }
        if (soldToAccountIds != null && !soldToAccountIds.isEmpty() && distributorAccountIds != null && !distributorAccountIds.isEmpty()) {
            String key;
            for (CWS_Distributor_Reseller__c distributor : [
                    SELECT Id, Name, CWS_Account__c,CWS_Fulfillment_Type__c,
                            CWS_Distributor_ResellerAcc__c, CWS_Category__c, CWS_Sub_Category__c
                    FROM CWS_Distributor_Reseller__c
                    WHERE
                    CWS_Account__c IN :soldToAccountIds AND
                    CWS_Distributor_ResellerAcc__c IN :distributorAccountIds AND
                    CWS_Type__c = :CWS_ConstantClass.DISTRIBUTOR_TYPE
                    ORDER BY CreatedDate DESC
            ]) {
                key = '' + distributor.CWS_Account__c + '-' + distributor.CWS_Distributor_ResellerAcc__c ;
                if (mapDistributorFulfillmentType.get(key) == null) {
                    mapDistributorFulfillmentType.put(key, distributor.CWS_Fulfillment_Type__c);
                }
                if (mapDistributorCategory.get(key) == null) {
                    mapDistributorCategory.put(key, distributor.CWS_Category__c);
                }
            }
            for (SBQQ__Quote__c quote : newList) {
                String keyaccountdistributor;
                if (((oldMap == null && quote.SBQQ__Distributor__c != null) ||
                        (oldMap != null && quote.SBQQ__Distributor__c != null && oldMap.get(quote.Id) != null &&
                                oldMap.get(quote.Id).SBQQ__Distributor__c != quote.SBQQ__Distributor__c)) &&
                        quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_ACCEPTED) {
                    keyaccountdistributor = quote.SBQQ__Account__c + '-' + quote.SBQQ__Distributor__c;
                    if (mapDistributorFulfillmentType.get(keyaccountdistributor) != null) {
                        quote.CWS_Distributor_Fulfillment_Type__c = mapDistributorFulfillmentType.get(keyaccountdistributor);
                        quote.CWS_Distributor_Category__c = mapDistributorCategory.get(keyaccountdistributor);
                    }
                }
            }
        }

    }


    /*
    * Method name  : AfterInsert
    * @Description  : BED-6326 : Opp Team Member Access to Opportunity & Quote.
    * @Param   : newMap List of new Quotes
    * Return Type  : None
    * Developer    : Khayam
    */
    public static void AfterInsert(Map<Id, SObject> newMap) {


        Map<Id, SBQQ__Quote__c> newQMap = (Map<Id, SBQQ__Quote__c>) newMap;


        // Start BED-6326
        Set<Id> oppIds = new Set<Id>();
        List<SBQQ__Quote__Share> lstQuoteShare = new List<SBQQ__Quote__Share> ();
        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        Boolean requiredQuery;
        Product2 prod = new Product2 ();
        // Added to resolve error - BED-10636 Account manager is not able to clone the Renewal quote.
        Set<Id> quoteIDs = new Set<Id>();
        Map<Id, Opportunity> mapOppToUpdate = new Map<Id, Opportunity>();//BED-892 Map of Opportunities to update
        Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>();//BED-892 Map of queried opportunities
        String sOppStage;//BED-892 Opportunity stage string
        String sOppRT;//BED-892 Stores Opportunity recordtype string
        requiredQuery = false;
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>([SELECT Id, SBQQ__ProductName__c, CWS_Base_SKU__c, SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN:newQMap.keySet() AND CWS_Base_SKU__c = '900901']);
        List<Id> quoteWithMin = new List<Id>();
        for (SBQQ__QuoteLine__c qlin : quoteLines) {
            if (!quoteWithMin.contains(qlin.SBQQ__Quote__c)) {
                quoteWithMin.add(qlin.SBQQ__Quote__c);
            }
        }
        for (SBQQ__Quote__c quote : newQMap.values()) {
            oppIds.add(quote.SBQQ__Opportunity2__c);
            quoteIDs.add(quote.Id);  // Added to resolve error - BED-10636 Account manager is not able to clone the Renewal quote.
            //BED-8825
            if (quote.CWS_Master__c == true && quote.CWS_IsCloned__c == false && quoteWithMin.isEmpty()) {
                requiredQuery = true;
            }
        }
        if (requiredQuery != false) {
            prod = [
                    SELECT Id, Name,CWS_Base_SKU__c
                    FROM Product2
                    WHERE Name = :CWS_ConstantClass.Minimum_Commit_Prod
                    AND CWS_Base_SKU__c = '900901'
            ];
        }
        //Query should be resued for general logic
        //BED-892
        if (oppIds.size() > 0) {
            mapOpportunity.putAll([SELECT Id,StageName,RecordTypeId,SBQQ__PrimaryQuote__c,Type FROM Opportunity WHERE Id IN :oppIds]);
        }

        //Loop should be reused for general logic
        for (SBQQ__Quote__c objQuote : newQMap.values()) {
            //BED-892 check for quote is New business and is primary quote to update opp stage
            sOppStage = getOpportunityStage(objQuote, false);//Added parameter false BED-1018,BED-8895
            if (objQuote.SBQQ__Primary__c && String.isNotBlank(sOppStage)
                    && mapOpportunity.containsKey(objQuote.SBQQ__Opportunity2__c)
                    && sOppStage != mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).StageName) {
                sOppRT = getOpportunityRT(objQuote.CWS_Quote_Type__c);
                if (!mapOppToUpdate.containsKey(objQuote.SBQQ__Opportunity2__c)) {
                    mapOppToUpdate.put(objQuote.SBQQ__Opportunity2__c, mapOpportunity.get(objQuote.SBQQ__Opportunity2__c));
                }
                mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).StageName = sOppStage;
                //Update recordtype of opportunity
                if (sOppRT != null && !sOppRT.equals(mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).RecordTypeId)
                        && (sOppStage.equals(CWS_ConstantClass.OPPORTUNITY_STAGE_PROPOSAL) || sOppStage.equals(CWS_ConstantClass.OPPORTUNITY_STAGE_FINALIZE_QUOTE))) {
                    mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).RecordTypeId = sOppRT;
                }
                if (objQuote.Id != mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).SBQQ__PrimaryQuote__c) {
                    mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).SBQQ__PrimaryQuote__c = objQuote.Id;
                }
            }
            // start BED 28
            if (objQuote.SBQQ__Primary__c && mapOpportunity.containsKey(objQuote.SBQQ__Opportunity2__c)
                    && objQuote.CWS_Quote_Type__c != mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).Type
                    && objQuote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) {
                if (!mapOppToUpdate.isEmpty() && mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c) != null) {
                    mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).Type = objQuote.CWS_Quote_Type__c;
                } else {
                    mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).Type = objQuote.CWS_Quote_Type__c;
                    mapOppToUpdate.put(objQuote.SBQQ__Opportunity2__c, mapOpportunity.get(objQuote.SBQQ__Opportunity2__c));
                }
            }
            //BED-8825
            if (objQuote.CWS_Master__c == true && prod.Id != null && objQuote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_AMENDMENT &&
                    objQuote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL &&
                    (objQuote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWALWC ||
                            (objQuote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && !objQuote.isClone()))) {
                SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
                ql.SBQQ__Quote__c = objQuote.Id;
                ql.RecordTypeId = CWS_ConstantClass.QUOTELine_RTYPE;
                ql.SBQQ__Product__c = prod.Id;
                // Default Billing term
                ql.CWS_Billing_Term__c = CWS_ConstantClass.BillingTerm_Monthly;
                qlList.add(ql);
            }
        }

        if (qlList.size() > 0) {
            insert qlList;
        }
        //BED-892 Update opportunities with new stage
        System.debug('msDebug:mapOppToUpdate.size():' + mapOppToUpdate.size());
        if (mapOppToUpdate.size() > 0) {
            List<Database.SaveResult> results = Database.update(mapOppToUpdate.values());
            CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_QuoteTriggerHelper', 'AfterInsert', 'Opportunity', null, null);
        }
        try {


            if (oppIds != null && !oppIds.isEmpty()) {
                List<OpportunityTeamMember> oppTMems = [SELECT Id,UserId,OpportunityId FROM OpportunityTeamMember WHERE OpportunityAccessLevel = 'Edit' AND OpportunityId IN:oppIds];
                for (SBQQ__Quote__c quote : newQMap.values()) {
                    for (OpportunityTeamMember otm : oppTMems) {
                        if (quote.SBQQ__Opportunity2__c == otm.OpportunityId) {

                            SBQQ__Quote__Share quoteShr = new SBQQ__Quote__Share();
                            quoteShr.ParentId = quote.Id;
                            quoteShr.UserOrGroupId = otm.UserId;
                            quoteShr.AccessLevel = 'Edit';
                            lstQuoteShare.add(quoteShr);
                        }
                    }
                }

                if (!lstQuoteShare.isEmpty()) {
                    Database.SaveResult[] results = Database.insert(lstQuoteShare, false);
                    CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_QuoteTriggerHelper', 'opptyTeamMemberShare', 'OpportunityTeamMember', null, null);
                }

            }


        } catch (Exception objExcp) {
            CWS_ExceptionHandler.logException(objExcp, 'OpportunityTeamMember', 'CWS_QuoteTriggerHelper', 'AfterInsert', '', null, null, 'AfterInsert', null);
        }
        // END BED - 6326
        // Added to resolve error - BED-10636 Account manager is not able to clone the Renewal quote. starts
        try {
            Set<Id> quoteIDsToUpdate = new Set<Id>();
            Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
            if (!quoteIDs.isEmpty()) {
                quoteMap = new Map<Id, SBQQ__Quote__c>([
                        SELECT
                                Id,
                                CWS_Quote_Type__c,
                                OwnerId,
                                SBQQ__Opportunity2__r.OwnerId
                        FROM SBQQ__Quote__c
                        WHERE Id IN :quoteIDs
                ]);
            }

            System.debug('quoteMap.values() size -   ' + quoteMap.values().size());
            for (SBQQ__Quote__c quote : quoteMap.values()) {
                if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && quote.OwnerId != quote.SBQQ__Opportunity2__r.OwnerId) {
                    quoteIDsToUpdate.add(quote.Id);
                }
            }

            if (!quoteIDsToUpdate.isEmpty()) {
                CWS_CommonUtility.updateRenewalWCQuoteOwner(quoteIDsToUpdate);
            }
        } catch (Exception objExcp) {
            CWS_ExceptionHandler.logException(objExcp, 'updateRenewalWCQuoteOwner-caller', 'CWS_QuoteTriggerHelper', 'AfterInsert', '', null, null, 'AfterInsert', null);
        }
        // Added to resolve error - BED-10636 Account manager is not able to clone the Renewal quote. ends

    }

    //BED-6200
    /**
     * @description :update monthly min commits
     * @param :newItems new Items to be used
     *        oldItems oldItems to be used.
     */
    public static void updateMonthlyMinCommit(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, SBQQ__Quote__c> newMap = (Map<Id, SBQQ__Quote__c>) newItems;
        Map<Id, SBQQ__Quote__c> oldMap = (Map<Id, SBQQ__Quote__c>) oldItems;
        for (SBQQ__Quote__c quote : newMap.values()) {
            if (quote.CWS_Master__c == true && quote.CWS_Monthly_Minimum_Commit__c != oldMap.get(quote.Id).CWS_Monthly_Minimum_Commit__c) {
                quote.CWS_Negotiated_Minimum_Commit__c = quote.CWS_Monthly_Minimum_Commit__c;
            }
            if (quote.CWS_Master__c == false) {
                quote.CWS_Monthly_Minimum_Commit__c = null;
                quote.CWS_Negotiated_Minimum_Commit__c = null;
            }
        }
    }
    /**
     * @description : check evergreen products.
     * @param : contractIds the contract Ids to be processed.
     * @return :map of Subscription and Type to be returned
     */
    public static Map<Id, Boolean> checkEvergreenProducts(Set<Id> contractIds) {
        Map<Id, Boolean> mapSubscriptionType = new Map<Id, Boolean>();
        if (contractIds != null) {
            for (Contract contract : [
                    SELECT Id, SBQQ__Evergreen__c
                    FROM Contract
                    WHERE Id IN :contractIds
            ]) {
                mapSubscriptionType.put(contract.Id, contract.SBQQ__Evergreen__c);
            }
        }
        return mapSubscriptionType;
    }

    /**
     * @description : Method return the CEO user from the Org.
     * @return : Return the Map of CEO with the Id of the User
     */
    private static Set<Id> getCeoUsers() {
        Map<Id, User> ceoUsers = new Map<Id, User>([
                SELECT
                        Id,
                        Name,
                        UserRoleId,
                        UserRole.DeveloperName
                FROM User
                WHERE UserRole.DeveloperName = 'CWS_CEO'
        ]);
        return ceoUsers.keySet();
    }

    /*
    * Method name  : beforUpdate
    * @description  : BED-5258 : Approval Status SetUp-Before Update
    * @param    : newItems - new List of Quotes.
                  oldItems - old List of Quotes.
    */
    public static void beforUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, SBQQ__Quote__c> newMap = (Map<Id, SBQQ__Quote__c>) newItems;
        Map<Id, SBQQ__Quote__c> oldMap = (Map<Id, SBQQ__Quote__c>) oldItems;
        Map<String, Decimal> exchangeRate = new Map<String, Decimal>();
        Map<Id, Contract> conMap = new Map<Id, Contract>();
        Map<Id, Contract> conAccMap = new Map<Id, Contract>();
        Set<Id> acctList = new Set<Id>();
        //BED-8807 for Fast Track Quote
        String strgroup = CWS_ConstantClass.GroupnameFTQ;
        Integer intLimit = Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);
        Group lstPGroup;
        Group consultingGroup;
        Map<String, Id> mapDistributor = new Map<String, Id>();
        Set<String> setDistiReseller = new Set<String>();
        Set<Id> soldToAccountIds = new Set<Id>();
        Set<Id> billToAccountIds = new Set<Id>();
        Map<Id, String> mapUserGroup = new Map<Id, String>();
        Id loggedUser = UserInfo.getUserId();
        Set<Id> ceoSet = new Set<Id>();
        ceoSet = getCeoUsers();
        User userObj = new User();
        if (loggedUser != null) {
            userObj = [SELECT Id,ProfileId,Profile.Name FROM User WHERE Id = :loggedUser];
        }
        if (strgroup != null && intLimit != null) {
            lstPGroup = [SELECT Id,Name,DeveloperName, (SELECT Id,UserOrGroupId FROM GroupMembers LIMIT :intLimit) FROM Group WHERE DeveloperName = :strgroup];
        }

        for (GroupMember members : lstPGroup.GroupMembers) {
            mapUserGroup.put(members.UserOrGroupId, lstPGroup.DeveloperName);
        }


        Map<Id, String> promoCode = new Map<Id, String>();
        Map<String, CWS_Promotion__c> promoValue = new Map<String, CWS_Promotion__c>();
        List<CWS_Promotion__c> promoList = new List<CWS_Promotion__c>();
        Set<Id> soldToAcntIdSet = new Set<Id>(); // added for BED-5930
        Map<Id, Account> accountMap; // added for BED-5930
        Set<Id> billtoAcct = new Set<Id>();//added for BED-3276
        Map<Id, CWS_Distributor_Reseller__c> distRecord = new Map<Id, CWS_Distributor_Reseller__c>();
        Map<Id, List<Id>> distSoldAcct = new Map<Id, List<Id>>();
        Map<Id, String> distResellerCheck = new Map<Id, String>();
        Map<Id, SBQQ__Quote__c> quoteWithLines = new Map<Id, SBQQ__Quote__c>(); // for BED-8869
        Set<Id> setOwnerIds = new Set<Id>();
        Map<Id, Set<String>> mapOwnerPubicGroups = new Map<Id, Set<String>>();
        SBQQ__QuoteDocument__c QuoteQD;


//Excluding Approvals for CEO


        //BED-8869 starts
        if (newMap.keySet() != null) {
            quoteWithLines = new Map<Id, SBQQ__Quote__c>([
                    SELECT Id,CWS_Transaction_Reason__c,Name,SBQQ__StartDate__c,SBQQ__Opportunity2__c,CWS_Temporary_License__c,CWS_Renewal_Type__c,
                            SBQQ__Opportunity2__r.CWS_Master__c, CWS_Bill_To_Account__r.CWS_Is_Distributor__c,CWS_Bill_To_Account__r.CWS_Is_IIT_Reseller__c,SBQQ__Account__r.CWS_Established_Disti_Reseller__c,
                            SBQQ__Opportunity2__r.CWS_On_Hold__c, SBQQ__Opportunity2__r.CWS_On_Hold_Reason__c, SBQQ__Opportunity2__r.CWS_Fast_Track__c,
                            CWS_Quote_Type__c,SBQQ__Status__c,SBQQ__Primary__c, (SELECT id,SBQQDS__SignedDate__c,SBQQ__SignatureStatus__c FROM R00N70000001lX7YEAU WHERE SBQQ__SignatureStatus__c = :CWS_ConstantClass.QDOC_SIG_SIGNED OR CWS_Offline_Signature_Status__c = :CWS_ConstantClass.QDOC_SIG_SIGNED OR SBQQ__SignatureStatus__c = :CWS_ConstantClass.QDOC_SIG_COMPLETED ORDER BY CreatedDate DESC LIMIT 1), (SELECT Id,CWS_Additional_Restrictions__c,SBQQ__StartDate__c,CWS_Transaction_Type__c,CWS_ServicesProvisioned__c,CWS_Provisioning_Eligibility__c,CWS_ProvisioningDate__c FROM SBQQ__LineItems__r)
                    FROM SBQQ__Quote__c
                    WHERE Id IN :newMap.keySet()
            ]);
        }

        //Start BED-5041
        Set<Id> setOfOldNewBillTo = new Set<Id>();
        //End BED-5041
        Map<Id, Boolean> mapSubscriptionType = new Map<Id, Boolean>();
        Set<Id> evergreenContractIds = new Set<Id>();
        Set<Id> masterContractIds = new Set<Id>();
        for (SBQQ__Quote__c quote : newMap.values()) {
            if (quote.CWS_Temporary_License__c != false && quote.CWS_Renewal_Type__c != CWS_ConstantClass.Renewal_Type_NonRenewable) {
                quote.CWS_Renewal_Type__c = CWS_ConstantClass.Renewal_Type_NonRenewable;
            }
            if (quote.CWS_Temporary_License__c != false && quote.CWS_Promo_Code__c != null) {
                quote.addError(System.Label.CWS_promo_not_applicable_on_temporary_licenses);
            }
            if (quote.SBQQ__MasterEvergreenContract__c != oldMap.get(quote.Id).SBQQ__MasterEvergreenContract__c &&
                    quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT &&
                    quote.CWS_LegacyKey__c != null && quote.SBQQ__MasterEvergreenContract__c != null) {
                evergreenContractIds.add(quote.SBQQ__MasterEvergreenContract__c);
            }
            if (((quote.SBQQ__MasterEvergreenContract__c != oldMap.get(quote.Id).SBQQ__MasterEvergreenContract__c &&
                    quote.SBQQ__MasterEvergreenContract__c != null) ||
                    (quote.SBQQ__MasterContract__c != oldMap.get(quote.Id).SBQQ__MasterEvergreenContract__c &&
                            quote.SBQQ__MasterContract__c != null)) &&
                    quote.CWS_LegacyKey__c != null &&
                    quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT
                    ) {
                if (quote.SBQQ__MasterEvergreenContract__c != null &&
                        quote.SBQQ__MasterContract__c != null) {
                    quote.addError('You cannot populate Master Contract and Master ' +
                            'Evergreen Contract on the same quote.');
                } else if (quote.SBQQ__MasterEvergreenContract__c != null) {
                    masterContractIds.add(quote.SBQQ__MasterEvergreenContract__c);
                } else if (quote.SBQQ__MasterContract__c != null) {
                    masterContractIds.add(quote.SBQQ__MasterContract__c);
                }
            }
            //BED-5177 Start
            if (quote.SBQQ__Account__c != null) {
                soldToAccountIds.add(quote.SBQQ__Account__c);
            }
            if (quote.CWS_Bill_To_Account__c != null) {
                billToAccountIds.add(quote.CWS_Bill_To_Account__c);
            }
            //BED-5177 End
            if (quote.OwnerId != oldMap.get(quote.Id).OwnerId && userObj != null && userObj.Profile.Name != CWS_ConstantClass.SysAdminProfile &&
                    (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL || quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC)) {
                setOwnerIds.add(quote.OwnerId);
            }
            if (quoteWithLines.get(quote.Id) != null && quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED &&
                    // Moved this to the QuoteDocumentTriggerUtility class
                    CWS_QuoteDocumentTriggerUtility.isProvisioningPending(quoteWithLines.get(quote.Id)) && userObj.Profile.Name == CWS_ConstantClass.OMProfile) {
                quote.addError(System.Label.CWS_Req_Complete_Provisioning_Details);
            }

            //BED-6506
            if (quoteWithLines.get(quote.Id) != null && quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED &&
                    // Moved this to the QuoteDocumentTriggerUtility class
                    CWS_QuoteDocumentTriggerUtility.isProvisioningPending(quoteWithLines.get(quote.Id)) && userObj.Profile.Name != CWS_ConstantClass.OMProfile) {
                quote.addError(System.Label.CWS_Req_Complete_Provisioning_OMDetails);
            }
            //BED-6506

            if (quote.CWS_Negotiated_Minimum_Commit__c == null) {
                quote.CWS_Negotiated_Minimum_Commit__c = quote.CWS_Monthly_Minimum_Commit__c;
            }

            //Start BED-5041 Check if Bill To is getting changed
            if (quote.CWS_Bill_To_Account__c != null && quote.CWS_Bill_To_Account__c != oldMap.get(quote.Id).CWS_Bill_To_Account__c) {
                setOfOldNewBillTo.add(oldMap.get(quote.Id).CWS_Bill_To_Account__c);
                setOfOldNewBillTo.add(quote.CWS_Bill_To_Account__c);
            }
            //End BED-5041

            //Start BED 8383
            if (quote.SBQQ__Account__c != null && quote.SBQQ__Status__c != oldMap.get(quote.Id).SBQQ__Status__c
                    && quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED && (quoteWithLines.get(quote.Id).CWS_Bill_To_Account__r.CWS_Is_Distributor__c
                    || quoteWithLines.get(quote.Id).CWS_Bill_To_Account__r.CWS_Is_IIT_Reseller__c) && quote.CWS_Route_to_Market__c != CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct
                    && quoteWithLines.get(quote.Id).SBQQ__Account__r.CWS_Established_Disti_Reseller__c != quote.CWS_Bill_To_Account__c
                    && quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && quote.SBQQ__Primary__c) {
                quote.CWS_First_Quote__c = true;
            }
            //End 8383
        }


        if (!evergreenContractIds.isEmpty()) {
            mapSubscriptionType = checkEvergreenProducts(evergreenContractIds);
        }
        Map<Id, Contract> mapMasterContract = new Map<Id, Contract>();
        if (!masterContractIds.isEmpty()) {
            mapMasterContract = new Map<Id, Contract>([
                    SELECT Id, Name, CWS_Renewal_Type__c, CWS_Payment_Term__c,SBQQ__RenewalTerm__c,
                            CWS_Ship_To_Account__c,CWS_Ship_To_Contact__c,CWS_Renewal_CAP__c,
                            CWS_Legal_Entity__c,CWS_Sold_To_Contact__c,CWS_Bill_To_Contact__c,
                            CWS_Bill_To_Account__c,CWS_Distributor__c,CWS_Distributor_Fulfillment_Type__c,
                            CWS_Distributor_Category__c, CWS_Reseller_Account__c, CWS_Sold_To_Address__c,
                            CWS_End_Partner_Account__c,CWS_Amendment_Renewal_Reason__c,CWS_Secondary_Recipient_Email__c,
                            CWS_Secondary_Recipient_Name__c, CWS_Billing_Frequency__c,OwnerId,
                            CWS_SAT_GAT__c, ContractTerm,CWS_TransactionReason__c,CWS_Renewal_Category__c,
                            CWS_Route_to_Market__c, AccountId
                    FROM Contract
                    WHERE Id IN:masterContractIds
            ]);
        }
        //Start BED-5041
        Map<Id, Account> mapOfOldNewAcc = new Map<Id, Account>();
        if (setOfOldNewBillTo != null) {
            for (Account acc : [SELECT Id,CurrencyIsoCode FROM Account WHERE Id IN:setOfOldNewBillTo]) {
                mapOfOldNewAcc.put(acc.Id, acc);
            }
        }
        //End BED-5041

        //BED-8869 Ends
        try {
            //BED-199 retrieving currencyISoCode from exchangerate
            //ISOCode = Currency/CurrencyISOCode
            List<CurrencyType> exchangeList = [SELECT IsoCode, ConversionRate, IsActive FROM CurrencyType WHERE IsActive = TRUE];
            //Map of Exchange rate records
            for (CurrencyType exList : exchangeList) {
                exchangeRate.put(exList.IsoCode, exList.ConversionRate);
            }

            if (setOwnerIds != null && !setOwnerIds.isEmpty()) {
                for (GroupMember gm : [
                        SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId
                        FROM GroupMember
                        WHERE
                        UserOrGroupId IN :setOwnerIds AND
                        (Group.DeveloperName = :CWS_ConstantClass.UK_EMEA_Region OR
                        Group.DeveloperName = :CWS_ConstantClass.NA_Region OR
                        Group.DeveloperName = :CWS_ConstantClass.APAC_Region)
                ]) {
                    if (mapOwnerPubicGroups.containsKey(gm.UserOrGroupId)) {
                        mapOwnerPubicGroups.get(gm.UserOrGroupId).add(gm.Group.DeveloperName);
                    } else {
                        mapOwnerPubicGroups.put(gm.UserOrGroupId, new Set<String>{
                                gm.Group.DeveloperName
                        });
                    }
                }
            }

            //BED-7563 checks if promocode has been populated on the quote
            for (SBQQ__Quote__c quote : newMap.values()) {
                SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);
                if (quote.SBQQ__MasterEvergreenContract__c != oldQuote.SBQQ__MasterEvergreenContract__c &&
                        quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT &&
                        quote.CWS_LegacyKey__c != null && mapSubscriptionType != null &&
                        quote.SBQQ__MasterEvergreenContract__c != null &&
                        mapSubscriptionType.containsKey(quote.SBQQ__MasterEvergreenContract__c) &&
                        mapSubscriptionType.get(quote.SBQQ__MasterEvergreenContract__c) == false) {
                    quote.addError('Please select a contract Marked Evergreen in the Master Evergreen field.');
                } else if (((quote.SBQQ__MasterEvergreenContract__c != oldQuote.SBQQ__MasterEvergreenContract__c &&
                        quote.SBQQ__MasterEvergreenContract__c != null) ||
                        (quote.SBQQ__MasterContract__c != oldQuote.SBQQ__MasterContract__c &&
                                quote.SBQQ__MasterContract__c != null)) &&
                        quote.CWS_LegacyKey__c != null &&
                        quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {

                    Id contractId = quote.SBQQ__MasterContract__c != null ? quote.SBQQ__MasterContract__c :
                            (quote.SBQQ__MasterEvergreenContract__c != null ? quote.SBQQ__MasterEvergreenContract__c : null);
                    if (mapMasterContract != null && mapMasterContract.containsKey(contractId)) {
                        Contract masterContract = mapMasterContract.get(contractId);
                        if (masterContract != null) {
                            quote.CWS_Renewal_Type__c = (quote.CWS_Renewal_Type__c == null) ?
                                    masterContract.CWS_Renewal_Type__c : quote.CWS_Renewal_Type__c;
                            quote.SBQQ__PaymentTerms__c = (quote.SBQQ__PaymentTerms__c == null) ?
                                    masterContract.CWS_Payment_Term__c : quote.SBQQ__PaymentTerms__c;
                            quote.SBQQ__RenewalTerm__c = (quote.SBQQ__RenewalTerm__c == null) ?
                                    masterContract.SBQQ__RenewalTerm__c : quote.SBQQ__RenewalTerm__c;
                            quote.CWS_Ship_To_Account__c = (quote.CWS_Ship_To_Account__c == null) ?
                                    masterContract.CWS_Ship_To_Account__c : quote.CWS_Ship_To_Account__c;
                            quote.CWS_Renewal_CAP__c = (quote.CWS_Renewal_CAP__c == null) ?
                                    masterContract.CWS_Renewal_CAP__c : quote.CWS_Renewal_CAP__c;
                            quote.CWS_Legal_Entity__c = (quote.CWS_Legal_Entity__c == null) ?
                                    masterContract.CWS_Legal_Entity__c : quote.CWS_Legal_Entity__c;
                            quote.SBQQ__Distributor__c = (quote.SBQQ__Distributor__c == null) ?
                                    masterContract.CWS_Distributor__c : quote.SBQQ__Distributor__c;
                            quote.CWS_Distributor_Fulfillment_Type__c = (quote.CWS_Distributor_Fulfillment_Type__c == null) ?
                                    masterContract.CWS_Distributor_Fulfillment_Type__c : quote.CWS_Distributor_Fulfillment_Type__c;
                            quote.CWS_Distributor_Category__c = (quote.CWS_Distributor_Category__c == null) ?
                                    masterContract.CWS_Distributor_Category__c : quote.CWS_Distributor_Category__c;
                            quote.CWS_Reseller_Account__c = (quote.CWS_Reseller_Account__c == null) ?
                                    masterContract.CWS_Reseller_Account__c : quote.CWS_Reseller_Account__c;
                            quote.SBQQ__Partner__c = (quote.SBQQ__Partner__c == null) ?
                                    masterContract.CWS_End_Partner_Account__c : quote.SBQQ__Partner__c;
                            quote.CWS_Amendment_Renewal_Reason__c = (quote.CWS_Amendment_Renewal_Reason__c == null) ?
                                    masterContract.CWS_Amendment_Renewal_Reason__c : quote.CWS_Amendment_Renewal_Reason__c;
                            quote.CWS_Secondary_Recipient_Email__c = (quote.CWS_Secondary_Recipient_Email__c == null) ?
                                    masterContract.CWS_Secondary_Recipient_Email__c : quote.CWS_Secondary_Recipient_Email__c;
                            quote.CWS_Secondary_Recipient_Name__c = (quote.CWS_Secondary_Recipient_Name__c == null) ?
                                    masterContract.CWS_Secondary_Recipient_Name__c : quote.CWS_Secondary_Recipient_Name__c;
                            quote.SBQQ__BillingFrequency__c = (quote.SBQQ__BillingFrequency__c == null) ?
                                    masterContract.CWS_Billing_Frequency__c : quote.SBQQ__BillingFrequency__c;
                            quote.CWS_SAT_GAT__c = (quote.CWS_SAT_GAT__c == null) ?
                                    masterContract.CWS_SAT_GAT__c : quote.CWS_SAT_GAT__c;
                            quote.CWS_Renewal_Category__c = (quote.CWS_Renewal_Category__c == null) ?
                                    masterContract.CWS_Renewal_Category__c : quote.CWS_Renewal_Category__c;
                            quote.CWS_Contract_Term__c = (quote.CWS_Contract_Term__c == null) ?
                                    masterContract.ContractTerm : quote.CWS_Contract_Term__c;
                            quote.CWS_Route_to_Market__c = (quote.CWS_Renewal_Type__c == null) ?
                                    masterContract.CWS_Route_to_Market__c : quote.CWS_Route_to_Market__c;
                            quote.SBQQ__Account__c = (quote.SBQQ__Account__c == null) ?
                                    masterContract.AccountId : quote.SBQQ__Account__c;
                        }
                    }
                }
                //END-1341
                //Start-BED-5041
                if (mapOfOldNewAcc != null && mapOfOldNewAcc.containsKey(quote.CWS_Bill_To_Account__c) &&
                        mapOfOldNewAcc.containsKey(oldQuote.CWS_Bill_To_Account__c) &&
                        mapOfOldNewAcc.get(quote.CWS_Bill_To_Account__c).CurrencyIsoCode != mapOfOldNewAcc.get(oldQuote.CWS_Bill_To_Account__c).CurrencyIsoCode) {
                    quote.addError(Label.CWS_Bill_to_with_different_currency_change_Error);
                }
                //BED-5041

                //BED-8168
                if (quoteWithLines.get(quote.Id) != null && !quoteWithLines.get(quote.Id).R00N70000001lX7YEAU.isEmpty()) {
                    QuoteQD = quoteWithLines.get(quote.Id).R00N70000001lX7YEAU;
                }
                if (QuoteQD != null && (quote.CWS_OF_SignedDate__c == null || quote.CWS_OF_SignedDate__c != QuoteQD.SBQQDS__SignedDate__c)) {
                    if (QuoteQD.SBQQDS__SignedDate__c != null) {
                        quote.CWS_OF_SignedDate__c = QuoteQD.SBQQDS__SignedDate__c;
                    } else {
                        quote.CWS_OF_SignedDate__c = Date.today();
                    }
                }
                //BED-8168

                //BED-8825
                if (quote.SBQQ__Account__c != null && quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS) {
                    acctList.add(quote.SBQQ__Account__c);
                }
                //BED-8825 End
                if (quote.OwnerId != oldMap.get(quote.Id).OwnerId && userObj != null && userObj.Profile.Name != CWS_ConstantClass.SysAdminProfile &&
                        (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL || quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) &&
                        (!mapOwnerPubicGroups.containsKey(quote.OwnerId) || (mapOwnerPubicGroups.containsKey(quote.OwnerId) &&
                                mapOwnerPubicGroups.get(quote.OwnerId) != null &&
                                ((quote.CWS_Region__c == 'APAC' && !mapOwnerPubicGroups.get(quote.OwnerId).contains(CWS_ConstantClass.APAC_Region)) ||
                                        (quote.CWS_Region__c == 'NA' && !mapOwnerPubicGroups.get(quote.OwnerId).contains(CWS_ConstantClass.NA_Region)) ||
                                        (quote.CWS_Region__c == 'EMEA/ROW' && !mapOwnerPubicGroups.get(quote.OwnerId).contains(CWS_ConstantClass.UK_EMEA_Region)))))) {
                    quote.addError(System.Label.CWS_QuoteErrrorRenewalOwnerUpdate);
                }

                if (quote.CWS_Promo_Code__c != null && (oldQuote.CWS_Promo_Code__c != quote.CWS_Promo_Code__c || oldQuote.SBQQ__ExpirationDate__c != quote.SBQQ__ExpirationDate__c)) {
                    promoCode.put(quote.Id, quote.CWS_Promo_Code__c.toLowerCase());
                }
                //BED-8807-Fast Track Quote
                if (oldQuote.CWS_isFastTrack__c != quote.CWS_isFastTrack__c && userObj != null && mapUserGroup != null && (!mapUserGroup.containsKey(userObj.Id) && userObj.Profile.Name != CWS_ConstantClass.SysAdminProfile)) {
                    quote.addError(System.Label.CWS_accessIssueFTQ);
                }
                //BED-8168
                if (oldQuote.CWS_isFastTrack__c != quote.CWS_isFastTrack__c && userObj != null && mapUserGroup != null && (mapUserGroup.containsKey(userObj.Id) || userObj.Profile.Name == CWS_ConstantClass.SysAdminProfile) && (quoteWithLines.containsKey(quote.Id) && !quoteWithLines.get(quote.Id).SBQQ__Opportunity2__r.CWS_Fast_Track__c)) {
                    quote.addError(System.Label.CWS_OpptyFastTrackError);
                }

                //BED-12640,BED-13052
                //if(quote.CWS_OF_SignedDate__c != null && quote.CWS_OF_Signed_Override_Date__c == null && quote.CWS_OF_SignedDate__c != oldQuote.CWS_OF_SignedDate__c){
                if (quote.CWS_OF_SignedDate__c != null && quote.CWS_OF_Signed_Override_Date__c == null && quote.CWS_OF_SignedDate__c != oldQuote.CWS_OF_SignedDate__c && !(quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS)) {
                    quote.CWS_OF_Signed_Override_Date__c = quote.CWS_OF_SignedDate__c;
                }
                //BED-12640,BED-13052

                //BED-12417
                if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN && quote.CWS_Sub_Stage__c != null && quote.CWS_Sub_Stage__c != CWS_ConstantClass.InProgSub_Stage) {
                    quote.CWS_Sub_Stage__c = CWS_ConstantClass.InProgSub_Stage;
                }
                //BED-12417

                // added for BED-5930
                soldToAcntIdSet.add(quote.SBQQ__Account__c);
                //added for BED-3276
                soldToAcntIdSet.add(quote.CWS_Bill_To_Account__c);
                billtoAcct.add(quote.CWS_Bill_To_Account__c);

            }
            //BED-8825
            if (acctList.size() > 0) {
                conMap = new Map<Id, Contract>([
                        SELECT Id, Name, AccountId, CWS_Master__c,CWS_Status__c
                        FROM Contract
                        WHERE
                        AccountId IN:acctList AND CWS_Master__c = TRUE AND CWS_Status__c = 'Active'
                        LIMIT 100
                ]);
            }

            for (Contract con : conMap.values()) {
                conAccMap.put(con.AccountId, con);
            }
            //BED-8825 End
            // added for BED-5930
            if (!soldToAcntIdSet.isEmpty()) {
                accountMap = new Map<Id, Account> ([
                        SELECT Id, Name, CWS_Region__c, CWS_Is_IIT_Reseller__c, OwnerId,
                                CWS_BA_Agreement__c, IsPartner, CWS_Is_Distributor__c, ParentId, CWS_BA_Agreement_Status__c,
                                CWS_MSA_Agreement__c, CWS_MSA_Agreement_Status__c, CWS_NDA_Agreement__c,
                                CWS_NDA_Agreement_Status__c, CWS_Is_Partner__c, CWS_Authorized_Reseller__c
                        FROM Account
                        WHERE
                                Id IN :soldToAcntIdSet
                ]);
            }
            //added for BED-5177
            if (!soldToAccountIds.isEmpty() && !billToAccountIds.isEmpty()) {
                String keyDistiReseller;
                for (CWS_Distributor_Reseller__c distiReseller : [
                        SELECT Id, CWS_Account__c, CWS_Type__c,
                                CWS_Distributor_ResellerAcc__c, CWS_Distributor_ResellerAcc__r.CWS_Is_Distributor__c,
                                CWS_Active__c
                        FROM CWS_Distributor_Reseller__c
                        WHERE CWS_Active__c = TRUE AND
                        CWS_Account__c IN:soldToAccountIds AND CWS_Distributor_ResellerAcc__c IN :billToAccountIds
                        AND ((CWS_Type__c = :CWS_ConstantClass.DISTRIBUTOR_TYPE
                        AND CWS_Distributor_ResellerAcc__r.CWS_Is_Distributor__c = TRUE) OR
                        (CWS_Type__c = :CWS_ConstantClass.RESELLER_TYPE))
                        AND CWS_Distributor_ResellerAcc__c != NULL AND CWS_Account__c != NULL
                ]) {
                    keyDistiReseller = distiReseller.CWS_Account__c + '-' +
                            distiReseller.CWS_Distributor_ResellerAcc__c + '-' + distiReseller.CWS_Type__c;
                    setDistiReseller.add(keyDistiReseller);
                    mapDistributor.put(keyDistiReseller, distiReseller.CWS_Distributor_ResellerAcc__c);
                }
            }
            //End of BEd-5177

            //query on the promotion object to retrieve records
            if (promoCode.size() > 0) {
                promoList = [SELECT Id, CWS_Promo_Code__c, CWS_Quote_Type__c, CWS_Clause__c, CWS_Route_to_Market__c, CWS_Standard__c, CWS_Currency__c, CWS_Active__c, CWS_ACV__c, CWS_End_Date__c,CWS_Approver__r.Id, CWS_Approver__c, CWS_Description__c FROM CWS_Promotion__c WHERE CWS_Promo_Code__c IN:promoCode.values()];
            }

            for (CWS_Promotion__c promo : promoList) {
                promoValue.put(promo.CWS_Promo_Code__c.toLowerCase(), promo);
            }


            //BED-3276 ends

            // get all users for the Quotes about to be processed:
            Map<Id, Id> quoteIdToQuoteOwnerIdMap = new Map<Id, Id>();
            for (SBQQ__Quote__c quote : newMap.values()) {
                if(quote.OwnerId != null) {
                    quoteIdToQuoteOwnerIdMap.put(quote.Id, quote.OwnerId);
                }
            }
            Map<Id, User> quoteOwnerIdToQuoteOwnerUserMap = new Map<Id, User>([
                    SELECT Id,Manager.Id,Manager.Manager.Id,Manager.Manager.Manager.Id, CWS_Approval_Role_Name__c,
                            Manager.CWS_Approval_Role_Name__c, Manager.Manager.CWS_Approval_Role_Name__c,
                            Manager.Manager.Manager.CWS_Approval_Role_Name__c
                    FROM User
                    WHERE Id IN :quoteIdToQuoteOwnerIdMap.values()
            ]);

            Map<Id, User> quoteIdToQuoteOwnerUserMap = new Map<Id, User>();
            for(Id quoteId : quoteIdToQuoteOwnerIdMap.keySet()) {
                Id quoteOwnerId = quoteIdToQuoteOwnerIdMap.get(quoteId);
                User quoteOwnerUser = quoteOwnerIdToQuoteOwnerUserMap.get(quoteOwnerId);
                quoteIdToQuoteOwnerUserMap.put(quoteId, quoteOwnerUser);
            }

            String keySoldToBillToAccount;
            //mapping approval status with quote status
            for (SBQQ__Quote__c quote : newMap.values()) {
                //BED-5177
                if (quote.SBQQ__Account__c != null && quote.CWS_Bill_To_Account__c != null &&
                        accountMap != null) {
                    keySoldToBillToAccount = quote.SBQQ__Account__c + '-' + quote.CWS_Bill_To_Account__c;
                    if (quote.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel &&
                            accountMap.containsKey(quote.CWS_Bill_To_Account__c)) {
                        if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE &&
                                !accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c) {
                            quote.addError(System.Label.CWS_QuoteErrBillToNotDistiWhenRTMChannel);
                        }
                        //BED-12680 Added billto or soldto account change check
                        else if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE &&
                                !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE)
                                && (quote.CWS_Bill_To_Account__c != oldMap.get(quote.Id).CWS_Bill_To_Account__c
                                || quote.SBQQ__Account__c != oldMap.get(quote.Id).SBQQ__Account__c)) {
                            quote.addError(System.Label.CWS_QuoteErrRTMChannelBilltoNotInDistiReseller);
                        } else if (mapDistributor != null &&
                                mapDistributor.containsKey(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE)) {
                            quote.SBQQ__Distributor__c = mapDistributor.get(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE);
                        }
                    } else if (quote.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT &&
                            quote.SBQQ__Account__c != quote.CWS_Bill_To_Account__c &&
                            accountMap.containsKey(quote.CWS_Bill_To_Account__c)) {
                        if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE &&
                                !accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c && quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS &&
                                !accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Partner__c &&
                                accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Authorized_Reseller__c != CWS_ConstantClass.AUTHORIZED_RESELLER_1TIER_OR_2TIER &&
                                (!accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_IIT_Reseller__c ||
                                        !accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Partner__c)) {
                            quote.addError(System.Label.CWS_QuoteErrRTMIITandBillToNotPartnerAuthReseller);
                        }
                        //BED-12680 Added billto or soldto account change check
                        else if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE &&
                                ((accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c &&
                                        !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE)) ||
                                        (accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_IIT_Reseller__c &&
                                                !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.RESELLER_TYPE)) ||
                                        (accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Partner__c &&
                                                !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE) &&
                                                !setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.RESELLER_TYPE)))
                                && (quote.CWS_Bill_To_Account__c != oldMap.get(quote.Id).CWS_Bill_To_Account__c
                                || quote.SBQQ__Account__c != oldMap.get(quote.Id).SBQQ__Account__c)) {
                            quote.addError(System.Label.CWS_QuoteErrRTMIITBillToNotInDistiReseller);
                        }
                        if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE &&
                                quote.CWS_Reseller_Account__c == null &&
                                accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c) {
                            quote.addError(System.Label.CWS_QuoteErrPopulateResellerwhenRTMIIT);
                        }
                        if (accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c &&
                                setDistiReseller.contains(keySoldToBillToAccount + '-' + CWS_ConstantClass.DISTRIBUTOR_TYPE)
                                ) {
                            quote.CWS_2_Tier_Authorized_Reseller__c = true;
                        }
                    }
                }
                //BED-5177 End
                //BED-8825
                /* TODO HAS MASTER CONTRACT, ARE WE KEEPING THIS CHANGE? */
                if (conAccMap.size() > 0 && conAccMap.get(quote.SBQQ__Account__c) != null) {
                    if (quote.CWS_Master__c == false) {
                        quote.CWS_Has_Master_Contract__c = true;
                    } else if (quote.CWS_Master__c == true && quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT && quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION && quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL) {
                        quote.addError(System.Label.CWS_Only_One_Master_Contract); //CR_RECOMMIT  Error will be thrown when the transaction recommit is not recommit and any edit is being done.
                    }
                } else if (quote.CWS_Master__c == true) {
                    quote.SBQQ__ContractingMethod__c = 'Single Contract';
                }

                //BED-8825 End

                //Start : BED-6479 Sync the Bill To Account with below fields which will be used for sharing opp with Channel Reps
                if (quote.CWS_Bill_To_Account__c != null && quote.CWS_Bill_To_Account__c != oldMap.get(quote.Id).CWS_Bill_To_Account__c && accountMap.get(quote.CWS_Bill_To_Account__c) != null
                        && (accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c || accountMap.get(quote.CWS_Bill_To_Account__c).CWS_Is_IIT_Reseller__c)) {
                    quote.CWS_Share_with_Bill_To_Account__c = quote.CWS_Bill_To_Account__c;
                    quote.CWS_Shared_Bill_To_Id__c = quote.CWS_Bill_To_Account__c;
                }
                //Start : BED-6479

                if ((quote.CWS_Reference_Expiry_Date__c != null && quote.SBQQ__ExpirationDate__c > quote.CWS_Reference_Expiry_Date__c) && quote.CWS_IsCloned__c == false && quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                    quote.addError(System.Label.CWS_Quote_expire_date);
                }
                if (quote.SBQQ__Status__c != oldMap.get(quote.Id).SBQQ__Status__c && System.today() > quote.SBQQ__ExpirationDate__c && quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                    quote.addError(System.Label.CWS_Quote_Expire_Please_Clone_and_use);
                }
                if (quote.CWS_IsCloned__c == true && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_DRAFT
                        && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_REVISION &&
                        quote.SBQQ__ExpirationDate__c != oldMap.get(quote.Id).SBQQ__ExpirationDate__c && oldMap.get(quote.Id).SBQQ__ExpirationDate__c != null) {
                    quote.addError(System.Label.CWS_quote_expire_canot_be_updated);
                }
                if (quote.SBQQ__ExpirationDate__c == null && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INREVIEW
                        && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_APPROVED && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_DRAFT
                        && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_REVISION && quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && !quote.CWS_isFastTrack__c
                        && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                    quote.addError(System.Label.CWS_Expire_date_cannot_be_null);
                }
                //BED-7563 start
                if (promoValue.size() > 0 && quote.CWS_Promo_Code__c != null && promoValue.containsKey(quote.CWS_Promo_Code__c.toLowerCase())) {
                    String currencyCode;
                    if (String.isBlank(promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Currency__c)) {
                        currencyCode = System.Label.CWS_Valid_Currencies;
                    } else {
                        currencyCode = promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Currency__c;
                    }
                    //BED-7563 Checks whether the applied promo has conditions satisfying to enter the quote
                    // BED-5006: Renewal Cancellation Notification: Added check to skip inactive quotes for error
                    if (promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Active__c == CWS_ConstantClass.PROMOTION_ACTIVE) {
                        if (quote.SBQQ__ExpirationDate__c != null && quote.SBQQ__ExpirationDate__c > promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_End_Date__c && quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                            quote.addError(System.Label.CWS_Update_Promo_code_or_quote_expire_date);
                        }
                        if (currencyCode.contains(quote.CurrencyIsoCode) && (promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Quote_Type__c == quote.CWS_Quote_Type__c || String.isBlank(promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Quote_Type__c))
                                && (promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Route_to_Market__c == quote.CWS_Route_to_Market__c || String.isBlank(promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Route_to_Market__c))) {
                            quote.CWS_Promotion__c = promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).Id;
                            quote.CWS_Promo_Code_Description__c = promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Description__c;
                            quote.CWS_Standard_Promo__c = promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Standard__c;
                            quote.CWS_Promo_Approver__c = promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Approver__r.Id;
                            if (!String.isBlank(promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Clause__c)) {
                                quote.CWS_Promotion_Applied__c = true;
                                quote.CWS_Promo_Clause__c = promoValue.get(quote.CWS_Promo_Code__c.toLowerCase()).CWS_Clause__c.left(1000);
                            } else {
                                quote.CWS_Promotion_Applied__c = false;
                                quote.CWS_Promo_Clause__c = null;
                            }
                        } else {
                            // BED-5006: Renewal Cancellation Notification: Added check to skip inactive quotes for error
                            if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                                quote.addError(System.Label.CWS_Promo_Invalid_Error);
                            }
                        }
                    } else {
                        // BED-5006: Renewal Cancellation Notification: Added check to skip inactive quotes for error
                        if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                            quote.addError(System.Label.CWS_Promo_Inactive_Error);
                        }
                    }
                }
                //if promoCode is blanked out then the corresponding promotion object lookup and description will become null
                else if (oldMap.get(quote.Id).CWS_Promo_Code__c != quote.CWS_Promo_Code__c) {
                    if (String.isBlank(quote.CWS_Promo_Code__c)) {
                        quote.CWS_Promotion__c = null;
                        quote.CWS_Promo_Code_Description__c = null;
                        quote.CWS_Standard_Promo__c = false;
                        quote.CWS_Promo_Approver__c = null;
                        quote.CWS_Promotion_Applied__c = false;
                        quote.CWS_Promo_Clause__c = null;
                    } else {
                        // BED-5006: Renewal Cancellation Notification: Added check to skip inactive quotes for error
                        if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                            quote.addError(System.Label.CWS_Promocode_not_exist);
                        }
                    }
                }

                //End of BED-7563


                // Populating approval related fields
                // BED-3750

                // get the Quote Owner's User and do some checks with it.
                User usr = quoteIdToQuoteOwnerUserMap.get(quote.Id);
                assignQuoteOwnerUserLogic(quote, usr, ceoSet);

                //mapping approval status with quote status
                if (quote.ApprovalStatus__c != oldMap.get(quote.Id).ApprovalStatus__c) {

                    if (quote.ApprovalStatus__c == CWS_ConstantClass.QUOTE_Approval_Status_Pending) {
                        quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_INREVIEW;
                        if ((quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && quote.CWS_IsCloned__c == false) ||
                                (quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && quote.CWS_IsCloned__c == true && quote.CWS_Reference_Expiry_Date__c == null)
                                )
                        //13644-End
                        {
                            if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) {
                                quote.CWS_Reference_Expiry_Date__c = quote.SBQQ__ExpirationDate__c;
                            } if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {
                            if (quote.SBQQ__EndDate__c <= System.today() + 90) {
                                quote.CWS_Reference_Expiry_Date__c = quote.SBQQ__EndDate__c;
                            } else {
                                quote.CWS_Reference_Expiry_Date__c = System.today() + 90;
                            }
                        }if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS) {
                            quote.CWS_Reference_Expiry_Date__c = System.today() + 90;
                        }
                        }
                    }
                    if (quote.ApprovalStatus__c == CWS_ConstantClass.QUOTE_Approval_Status_Approved) {
                        quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_APPROVED;
                        quote.SBQQ__WatermarkShown__c = false;
                        if ((quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && quote.CWS_IsCloned__c == false) ||
                                (quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && quote.CWS_IsCloned__c == true && quote.CWS_Reference_Expiry_Date__c == null)
                                )
                        //13644-End

                        {
                            if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) {
                                quote.CWS_Reference_Expiry_Date__c = quote.SBQQ__ExpirationDate__c;
                            } if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {
                            if (quote.SBQQ__EndDate__c <= System.today() + 90) {
                                quote.CWS_Reference_Expiry_Date__c = quote.SBQQ__EndDate__c;
                            } else {
                                quote.CWS_Reference_Expiry_Date__c = System.today() + 90;
                            }
                        }if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS) {
                            quote.CWS_Reference_Expiry_Date__c = System.today() + 90;
                        }
                        }
                    }
                    /**  //BED-9254 starts
               if(Quote.ApprovalStatus__c == CWS_ConstantClass.QUOTE_Approval_Status_Approved &&   Quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_APPROVED && Quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT &&
                    ((Quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL && Quote.CWS_Sub_Type__c == CWS_ConstantClass.QUOTE_SUB_TYPE_CREDIT) ||
                    Quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION ||
                    Quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT ||
                    Quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_TERMINATION)){
                     Quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
                }*/
                    //BED-9254 ends
                    if (quote.ApprovalStatus__c == CWS_ConstantClass.QUOTE_Approval_Status_Rejected) {
                        quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_REVISION;
                    }
                    if (quote.ApprovalStatus__c == CWS_ConstantClass.QUOTE_Approval_Status_Recalled) {
                        if (quote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                            quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_DRAFT;
                        }

                        //BED-8645 starts
                        if (quote.CWS_Account_Restriction_Status__c != null &&
                                quote.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_NORESTRICTION &&
                                quote.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT &&
                                quote.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_PAYMENTWORKOUT &&
                                quote.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_TYPE_CANCEL) {

                            quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_INACTIVE;
                        }
                        //BED-8645 ends
                    }

                }// End BED - 5258

                // mapping quote status with record types - BED-5590
                if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_DRAFT ||
                        quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_REVISION) {

                    if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS) {
                        quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_NEW_EDIT;
                    } else if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT &&
                            quote.CWS_LegacyKey__c == null) {
                        quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY;
                    } else if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT &&
                            quote.CWS_LegacyKey__c != null) {
                        quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_LEGACY_EDITABLE;
                    } else if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {
                        quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_RONLY;
                    } else if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) {
                        quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_EDIT;
                    }

                } else if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INREVIEW) {
                    quote.RecordTypeId = (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) ?
                            CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_INREVIEW : CWS_ConstantClass.QUOTE_RTYPE_INREVIEW;
                    if ((quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) && quote.CWS_IsCloned__c == false) {
                        quote.CWS_Reference_Expiry_Date__c = System.today() + 90;
                    }
                } else if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_APPROVED) {
                    quote.RecordTypeId = (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) ?
                            CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_APPROVED_RONLY : CWS_ConstantClass.QUOTE_RTYPE_APPROVED;
                    if (quote.CWS_Reference_Expiry_Date__c == null && (quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL && quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) && quote.CWS_IsCloned__c == false) {
                        quote.CWS_Reference_Expiry_Date__c = System.today() + 90;
                    }
                } else if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN) {
                    quote.RecordTypeId = (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) ?
                            CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_APPROVED_RONLY : CWS_ConstantClass.QUOTE_RTYPE_APPROVED;
                    if (quote.CWS_Reference_Expiry_Date__c == null
                            && quote.CWS_IsCloned__c == false
                            && (quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                            && quote.CWS_Quote_Type__c != CWS_ConstantClass.QUOTE_TYPE_RENEWALWC)) {
                        quote.CWS_Reference_Expiry_Date__c = System.today() + 90;
                    }
                } else if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG) {
                    quote.RecordTypeId = (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) ?
                            CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_APPROVED_RONLY : CWS_ConstantClass.QUOTE_RTYPE_APPROVED;
                } else if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED) {
                    quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_CLOSED_RONLY;
                } else if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                    quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_CLOSED_RONLY;
                }

                // End BED - 5590
                /**
                * @Description: Generate Order from the Accepted Quote
                * @Developer: swachatterjee@deloitte.com
                * @Issue : BED - 1260
                * */
                // Get the New and Old Quote from the Trigger Context
                SBQQ__Quote__c sObjNewQuote = quote;
                SBQQ__Quote__c sObjOldQuote = oldMap.get(quote.Id);

                // BED-5930 - Change starts
                if (sObjNewQuote.SBQQ__Status__c != sObjOldQuote.SBQQ__Status__c) {
                    if (accountMap != null && sObjNewQuote.SBQQ__Account__c != null && accountMap.containsKey(sObjNewQuote.SBQQ__Account__c)) {

                        //BED-8949
                        if (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement__c != null && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement_Status__c != null && (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                            sObjNewQuote.CWS_BA_Agreement__c = accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement__c;
                            sObjNewQuote.CWS_BA_Agreement_Status__c = accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement_Status__c;
                        }
                        if (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement__c != null && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c != null && (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                            sObjNewQuote.CWS_MSA_Agreement__c = accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement__c;
                            sObjNewQuote.CWS_MSA_Agreement_Status__c = accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c;
                        }
                        if (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement__c != null && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c != null && (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                            sObjNewQuote.CWS_NDA_Agreement__c = accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement__c;
                            sObjNewQuote.CWS_NDA_Agreement_Status__c = accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c;
                        }
                        if (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement__c != null && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement_Status__c != null && (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED || accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_BA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                            sObjNewQuote.CWS_BA_Agreement__c = '';
                            sObjNewQuote.CWS_BA_Agreement_Status__c = '';
                        }
                        if (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement__c != null && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c != null && (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED || accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_MSA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                            sObjNewQuote.CWS_MSA_Agreement__c = '';
                            sObjNewQuote.CWS_MSA_Agreement_Status__c = '';
                        }
                        if (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement__c != null && accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c != null && (accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED || accountMap.get(sObjNewQuote.SBQQ__Account__c).CWS_NDA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED)) {
                            sObjNewQuote.CWS_NDA_Agreement__c = '';
                            sObjNewQuote.CWS_NDA_Agreement_Status__c = '';
                        }

                        //BED-8949


                    }
                }
                // BED-5930 - Chnages ends

                // Check if the Quote Status is updated to Accepted
                // and Ordered Checkbox is not checked
                if (sObjNewQuote.SBQQ__Status__c <> sObjOldQuote.SBQQ__Status__c
                        && sObjNewQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED
                        && sObjNewQuote.SBQQ__Ordered__c == false
                        && sObjNewQuote.SBQQ__Primary__c == true
                        ) {
                    //BED-8869 starts
                    List<CWS_Create_Order_Switch__c> lstorderswitch = CWS_Create_Order_Switch__c.getall().values();
                    Boolean createOrder = false;
                    for (CWS_Create_Order_Switch__c ord : lstorderswitch) {
                        if (ord.CWS_Create_Order_When_Quote_Is_Accepted__c == true && ord.Name == CWS_ConstantClass.createOrderSwitch) {
                            createOrder = true;
                        }
                    }

                    if (sObjNewQuote.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {

                        // update the Ordered Checkbox which creates the Order
                        if (createOrder) {
                            sObjNewQuote.SBQQ__Ordered__c = true;
                            System.debug('****CWS_QuoteTriggerHelper' + sObjNewQuote.SBQQ__Ordered__c);
                        }

                    } else {
                        if (!System.isBatch() && !System.isFuture()) {
                            if (createOrder) {
                                CWS_CommonUtility.quoteCalcHelper(sObjNewQuote.Id); // re-run prices using APIs
                            } else {
                                CWS_CommonUtility.recalcQuote(sObjNewQuote.Id); // re-run prices using recalculating field
                            }
                        }
                    }
                    //BED-8869 ends
                }

                // End BED - 1260
                //BED-199 Populating exchange rate on the quote header
                if (((quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED && sObjOldQuote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_ACCEPTED) || (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INACTIVE && sObjOldQuote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE)) && exchangeRate.containsKey(quote.CurrencyIsoCode)) {
                    if (quote.CWS_Exchange_Rate__c != exchangeRate.get(quote.CurrencyIsoCode)) {
                        quote.CWS_Exchange_Rate__c = exchangeRate.get(quote.CurrencyIsoCode);
                    }
                }

                /*
            Description: retrigger price calculation if OF Signed Override Date is changed
            Developer: Khayam
            Issue: Start/End Date CR
            */
                if (sObjNewQuote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_ACCEPTED && sObjNewQuote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE &&
                        sObjNewQuote.CWS_OF_Signed_Override_Date__c != sObjOldQuote.CWS_OF_Signed_Override_Date__c) {
                    if (!System.isBatch() && !System.isFuture()) {
                        CWS_CommonUtility.recalcQuote(sObjNewQuote.Id); // re-run prices using recalculating field
                    }
                }
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CWS_QuoteTriggerHelper', 'beforUpdate', '', null, null, 'BeforeUpdate', null);

        }
    }

    /**
     * @description: assign the Quote Owner to the Quote.
     * @param: quote The quote to be processed
     *         usr - USer record
     *         ceoSet - Set of User Ids.
     */
    private static SBQQ__Quote__c assignQuoteOwnerUserLogic(SBQQ__Quote__c quote, User usr, Set<Id> ceoSet) {
        if (usr != null) {
            //Salesmanager as per role
            /*   if(Quote.CWS_Sales_Management_Id__c != usr.Manager.Id || Quote.CWS_Director_Id__c != usr.Manager.Manager.Id ||
             Quote.CWS_Vice_President__c != usr.Manager.Manager.Manager.Id ){*/
            if (!ceoSet.contains(usr.Manager.Id) && usr.Manager.CWS_Approval_Role_Name__c != null) {
                quote.CWS_Sales_Management_Id__c = usr.Manager.Id;
            }
            //Director as per role
            if (!ceoSet.contains(usr.Manager.Id) && usr.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.CWS_Approval_Role_Name__c != 'Sales Manager') {
                quote.CWS_Director_Id__c = usr.Manager.Id;
            } else if (!ceoSet.contains(usr.Manager.Manager.Id) && usr.Manager.Manager.CWS_Approval_Role_Name__c != null) {
                quote.CWS_Director_Id__c = usr.Manager.Manager.Id;
            }
            //Vice procident as per role
            if (!ceoSet.contains(usr.Manager.Id) && usr.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.CWS_Approval_Role_Name__c != 'Sales Manager') {
                if (usr.Manager.CWS_Approval_Role_Name__c != 'Director') {
                    quote.CWS_Vice_President__c = usr.Manager.Id;
                } else if (!ceoSet.contains(usr.Manager.Manager.Id) && usr.Manager.Manager.CWS_Approval_Role_Name__c != null && (usr.Manager.Manager.CWS_Approval_Role_Name__c == 'Vice President' ||
                        usr.Manager.Manager.CWS_Approval_Role_Name__c == 'Senior Vice President' || usr.Manager.Manager.CWS_Approval_Role_Name__c == 'CFO' ||
                        usr.Manager.Manager.CWS_Approval_Role_Name__c == 'CRO')) {
                    quote.CWS_Vice_President__c = usr.Manager.Manager.Id;
                }
            } if (!ceoSet.contains(usr.Manager.Manager.Id) && usr.Manager.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.Manager.CWS_Approval_Role_Name__c != 'Director') {
                quote.CWS_Vice_President__c = usr.Manager.Manager.Id;
            } else if (!ceoSet.contains(usr.Manager.Manager.Manager.Id) && usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c != null && (usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'Vice President' ||
                    usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'Senior Vice President' || usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'CFO' ||
                    usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'CRO')) {
                quote.CWS_Vice_President__c = usr.Manager.Manager.Manager.Id;
            }

            List<User> usersNew = [
                    SELECT Id,Manager.Id,Manager.Manager.Id,Manager.Manager.Manager.Id, CWS_Approval_Role_Name__c,
                            Manager.CWS_Approval_Role_Name__c, Manager.Manager.CWS_Approval_Role_Name__c,
                            Manager.Manager.Manager.CWS_Approval_Role_Name__c
                    FROM User
                    WHERE Id = :usr.Manager.Manager.Manager.Id
            ];
            if (usersNew.isEmpty() == false) {
                User usrNew = usersNew[0];
                //Senior vice president as per role
                if (!ceoSet.contains(usr.Manager.Id) && usr.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.CWS_Approval_Role_Name__c != 'Sales Manager') {
                    if (usr.Manager.CWS_Approval_Role_Name__c != 'Director' && usr.Manager.CWS_Approval_Role_Name__c != 'Vice President') {
                        quote.CWS_Senior_Vice_President__c = usr.Manager.Id;
                    } else if (!ceoSet.contains(usr.Manager.Manager.Id) && usr.Manager.Manager.CWS_Approval_Role_Name__c != null && (usr.Manager.Manager.CWS_Approval_Role_Name__c == 'Senior Vice President' ||
                            usr.Manager.Manager.CWS_Approval_Role_Name__c == 'CFO' || usr.Manager.Manager.CWS_Approval_Role_Name__c == 'CRO')) {
                        quote.CWS_Senior_Vice_President__c = usr.Manager.Manager.Id;
                    }
                } if (!ceoSet.contains(usr.Manager.Manager.Id) && usr.Manager.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.Manager.CWS_Approval_Role_Name__c != 'Director' && usr.Manager.Manager.CWS_Approval_Role_Name__c != 'Vice President') {
                    quote.CWS_Senior_Vice_President__c = usr.Manager.Manager.Id;
                } else if (!ceoSet.contains(usr.Manager.Manager.Manager.Id) && usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c != null && (usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'Senior Vice President' ||
                        usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'CFO' || usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'CRO')) {
                    quote.CWS_Senior_Vice_President__c = usr.Manager.Manager.Manager.Id;
                } else if (!ceoSet.contains(usrNew.Manager.Id) && usrNew.Manager.CWS_Approval_Role_Name__c != null &&
                        (usrNew.Manager.CWS_Approval_Role_Name__c == 'Senior Vice President' || usrNew.Manager.CWS_Approval_Role_Name__c != 'CRO' || usrNew.Manager.CWS_Approval_Role_Name__c != 'CFO')) {
                    quote.CWS_Senior_Vice_President__c = usrNew.Manager.Id;
                }

                //CRO as per role
                if (!ceoSet.contains(usr.Manager.Id) && usr.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.CWS_Approval_Role_Name__c == 'CRO') {
                    quote.CWS_CRO_Id__c = usr.Manager.Id;
                } else if (!ceoSet.contains(usr.Manager.Manager.Id) && usr.Manager.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.Manager.CWS_Approval_Role_Name__c == 'CRO') {
                    quote.CWS_CRO_Id__c = usr.Manager.Manager.Id;
                } else if (!ceoSet.contains(usr.Manager.Manager.Manager.Id) && usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'CRO') {
                    quote.CWS_CRO_Id__c = usr.Manager.Manager.Manager.Id;
                } else if (!ceoSet.contains(usrNew.Manager.Id) && usrNew.Manager.CWS_Approval_Role_Name__c != null && usrNew.Manager.CWS_Approval_Role_Name__c == 'CRO') {
                    quote.CWS_CRO_Id__c = usrNew.Manager.Id;
                } else if (!ceoSet.contains(usrNew.Manager.Manager.Id) && usrNew.Manager.Manager.CWS_Approval_Role_Name__c != null) {
                    quote.CWS_CRO_Id__c = usrNew.Manager.Manager.Id;
                }
                //CFO as per role
                if (!ceoSet.contains(usr.Manager.Id) && usr.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.CWS_Approval_Role_Name__c == 'CFO') {
                    quote.CWS_CFO_Id__c = usr.Manager.Id;
                } else if (!ceoSet.contains(usr.Manager.Manager.Id) && usr.Manager.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.Manager.CWS_Approval_Role_Name__c == 'CFO') {
                    quote.CWS_CFO_Id__c = usr.Manager.Manager.Id;
                } else if (!ceoSet.contains(usr.Manager.Manager.Manager.Id) && usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c != null && usr.Manager.Manager.Manager.CWS_Approval_Role_Name__c == 'CFO') {
                    quote.CWS_CFO_Id__c = usr.Manager.Manager.Manager.Id;
                } else if (!ceoSet.contains(usrNew.Manager.Id) && usrNew.Manager.CWS_Approval_Role_Name__c != null && usrNew.Manager.CWS_Approval_Role_Name__c == 'CFO') {
                    quote.CWS_CFO_Id__c = usrNew.Manager.Id;
                } else if (!ceoSet.contains(usrNew.Manager.Manager.Id) && usrNew.Manager.Manager.CWS_Approval_Role_Name__c != null && usrNew.Manager.Manager.CWS_Approval_Role_Name__c == 'CFO') {
                    quote.CWS_CFO_Id__c = usrNew.Manager.Manager.Id;
                } else if (!ceoSet.contains(usrNew.Manager.Manager.Manager.Id) && usrNew.Manager.Manager.Manager.CWS_Approval_Role_Name__c != null) {
                    quote.CWS_CFO_Id__c = usrNew.Manager.Manager.Manager.Id;
                }

            }
        }
        return null;
    }

    /*
    * Method name  : BeforeInsert
    * @description  : BED-3411 : Copy default values from orignal contract.
    * @param   : newItems - List of new Quotes
    * Developer    : Khayam
    */
    public static void copyToRenewalAmendmentQuoteBeforeIns(List<SObject> newItems) {
        List<SBQQ__Quote__c> newQuotes = (List<SBQQ__Quote__c>) newItems;

        List<String> OppIds = new List<String>();

        try {

            for (SBQQ__Quote__c quote : newQuotes) {
                OppIds.add(quote.SBQQ__Opportunity2__c);
            }

            Map<Id, Opportunity> OpportunitiesMap = new Map<Id, Opportunity>();
            if (OppIds != null && !OppIds.isEmpty()) {
                OpportunitiesMap = new Map<Id, Opportunity>([
                        SELECT Id,CWS_Legal_Entity__c, Type, SBQQ__RenewedContract__r.CWS_Legal_Entity__c,
                                SBQQ__RenewedContract__r.CWS_Route_to_Market__c,SBQQ__RenewedContract__r.CWS_Sold_To_Contact__c,
                                SBQQ__RenewedContract__r.CWS_Contract_ACV__c,SBQQ__RenewedContract__r.CWS_Annual_Distributor_Net_Total__c,
                                SBQQ__RenewedContract__r.CWS_Annual_End_Customer_Net_Total__c,SBQQ__RenewedContract__r.CWS_Annual_Reseller_Net_Total__c,
                                SBQQ__RenewedContract__r.CWS_Ship_To_Account__c,SBQQ__RenewedContract__r.CWS_Ship_To_Contact__c,
                                SBQQ__RenewedContract__r.CWS_Bill_To_Contact__c,SBQQ__RenewedContract__r.CWS_Bill_To_Account__c,
                                SBQQ__RenewedContract__r.CWS_Distributor__c, SBQQ__RenewedContract__r.CWS_Distributor_Fulfillment_Type__c,
                                SBQQ__RenewedContract__r.CWS_Distributor_Category__c, SBQQ__RenewedContract__r.CWS_Reseller_Account__c,
                                SBQQ__RenewedContract__r.CWS_Sold_To_Address__c,SBQQ__RenewedContract__r.CWS_End_Partner_Account__c,
                                SBQQ__RenewedContract__r.CWS_Amendment_Renewal_Reason__c,SBQQ__RenewedContract__r.CWS_Secondary_Recipient_Email__c,
                                SBQQ__RenewedContract__r.CWS_Secondary_Recipient_Name__c, SBQQ__RenewedContract__r.CWS_Renewal_CAP__c,
                                SBQQ__RenewedContract__r.CWS_Payment_Term__c,SBQQ__RenewedContract__r.SBQQ__RenewalTerm__c,
                                SBQQ__RenewedContract__r.CWS_Renewal_Type__c,SBQQ__RenewedContract__r.CWS_Billing_Frequency__c,
                                SBQQ__RenewedContract__r.CWS_SAT_GAT__c, SBQQ__RenewedContract__r.ContractTerm,SBQQ__RenewedContract__r.StartDate,
                                SBQQ__RenewedContract__r.CWS_Legacy_Disti_Factor__c,SBQQ__RenewedContract__r.EndDate,SBQQ__AmendedContract__r.CWS_Temporary_License__c,
                                SBQQ__RenewedContract__r.CWS_Min_Commit_Product_Start_Date__c,
                                SBQQ__AmendedContract__r.CWS_Renewal_Type__c, SBQQ__AmendedContract__r.CWS_Payment_Term__c,SBQQ__AmendedContract__r.SBQQ__RenewalTerm__c,
                                SBQQ__AmendedContract__r.CWS_Ship_To_Account__c,SBQQ__AmendedContract__r.CWS_Ship_To_Contact__c,
                                SBQQ__AmendedContract__r.CWS_Renewal_CAP__c,SBQQ__AmendedContract__r.CWS_Legal_Entity__c,
                                SBQQ__AmendedContract__r.SBQQ__Quote__r.CWS_Route_to_Market__c,SBQQ__AmendedContract__r.CWS_Sold_To_Contact__c,
                                SBQQ__AmendedContract__r.CWS_Bill_To_Contact__c,SBQQ__AmendedContract__r.CWS_Bill_To_Account__c,
                                SBQQ__AmendedContract__r.CWS_Distributor__c,SBQQ__AmendedContract__r.CWS_Distributor_Fulfillment_Type__c,
                                SBQQ__AmendedContract__r.CWS_Distributor_Category__c, SBQQ__AmendedContract__r.CWS_Reseller_Account__c,
                                SBQQ__AmendedContract__r.CWS_Sold_To_Address__c,SBQQ__AmendedContract__r.CWS_End_Partner_Account__c,
                                SBQQ__AmendedContract__r.CWS_Amendment_Renewal_Reason__c,SBQQ__AmendedContract__r.CWS_Secondary_Recipient_Email__c,
                                SBQQ__AmendedContract__r.CWS_Secondary_Recipient_Name__c, SBQQ__AmendedContract__r.CWS_Billing_Frequency__c,
                                SBQQ__AmendedContract__r.CWS_SAT_GAT__c, SBQQ__AmendedContract__r.ContractTerm,OwnerId,
                                SBQQ__AmendedContract__r.StartDate,SBQQ__AmendedContract__r.EndDate,SBQQ__AmendedContract__r.CWS_Legacy_Disti_Factor__c,
                                SBQQ__RenewedContract__r.CWS_Renewal_Category__c,SBQQ__AmendedContract__r.CWS_Renewal_Category__c,
                                SBQQ__AmendedContract__r.CWS_Min_Commit_Product_Start_Date__c
                        FROM Opportunity
                        WHERE Id IN:OppIds
                ]);
            }

            Opportunity opp = null;

            for (SBQQ__Quote__c quote : newQuotes) {

                opp = OpportunitiesMap.get(quote.SBQQ__Opportunity2__c);
                if (opp != null && !quote.isClone() && quote.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {
                    //start of bed-5294
                    //BED-12862
                    if (opp.Type == CWS_ConstantClass.Opportunity_Type_RenewalWithChange) {
                        quote.CWS_Quote_Type__c = opp.Type;
                        quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_RENEWAL_EDIT;
                    }
                    quote.CWS_Prior_ACV__c = opp.SBQQ__RenewedContract__r.CWS_Contract_ACV__c;
                    quote.CWS_Prior_Annual_Distributor_Net_Total__c = opp.SBQQ__RenewedContract__r.CWS_Annual_Distributor_Net_Total__c;
                    quote.CWS_Prior_Annual_End_Customer_Net_Total__c = opp.SBQQ__RenewedContract__r.CWS_Annual_End_Customer_Net_Total__c;
                    quote.CWS_Prior_Annual_Reseller_Net_Total__c = opp.SBQQ__RenewedContract__r.CWS_Annual_Reseller_Net_Total__c;

                    //BED-12862 Defaulting Legal Entity from opp in case of manual RWC
                    if (opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC &&
                            opp.CWS_Legal_Entity__c != null &&
                            opp.CWS_Legal_Entity__c != opp.SBQQ__RenewedContract__r.CWS_Legal_Entity__c
                            ) {
                        quote.CWS_Legal_Entity__c = opp.CWS_Legal_Entity__c;
                    } else {
                        quote.CWS_Legal_Entity__c = opp.SBQQ__RenewedContract__r.CWS_Legal_Entity__c;
                    }
                    //BED-12862

                    quote.CWS_Route_to_Market__c = opp.SBQQ__RenewedContract__r.CWS_Route_to_Market__c;
                    quote.SBQQ__PrimaryContact__c = opp.SBQQ__RenewedContract__r.CWS_Sold_To_Contact__c;
                    quote.CWS_Bill_To_Contact__c = opp.SBQQ__RenewedContract__r.CWS_Bill_To_Contact__c;
                    quote.CWS_Bill_To_Account__c = opp.SBQQ__RenewedContract__r.CWS_Bill_To_Account__c;
                    quote.CWS_Ship_To_Account__c = opp.SBQQ__RenewedContract__r.CWS_Ship_To_Account__c;
                    quote.CWS_Ship_To_Contact__c = opp.SBQQ__RenewedContract__r.CWS_Ship_To_Contact__c;
                    quote.SBQQ__Distributor__c = opp.SBQQ__RenewedContract__r.CWS_Distributor__c;
                    quote.CWS_Distributor_Fulfillment_Type__c = opp.SBQQ__RenewedContract__r.CWS_Distributor_Fulfillment_Type__c;
                    quote.CWS_Distributor_Category__c = opp.SBQQ__RenewedContract__r.CWS_Distributor_Category__c;
                    quote.CWS_Reseller_Account__c = opp.SBQQ__RenewedContract__r.CWS_Reseller_Account__c;
                    quote.SBQQ__Partner__c = opp.SBQQ__RenewedContract__r.CWS_End_Partner_Account__c;
                    quote.CWS_Amendment_Renewal_Reason__c = opp.SBQQ__RenewedContract__r.CWS_Amendment_Renewal_Reason__c;
                    quote.CWS_Secondary_Recipient_Email__c = opp.SBQQ__RenewedContract__r.CWS_Secondary_Recipient_Email__c;
                    quote.CWS_Secondary_Recipient_Name__c = opp.SBQQ__RenewedContract__r.CWS_Secondary_Recipient_Name__c;
                    quote.CWS_Renewal_CAP__c = opp.SBQQ__RenewedContract__r.CWS_Renewal_CAP__c;
                    quote.SBQQ__PaymentTerms__c = opp.SBQQ__RenewedContract__r.CWS_Payment_Term__c;
                    quote.SBQQ__RenewalTerm__c = opp.SBQQ__RenewedContract__r.SBQQ__RenewalTerm__c;
                    //quote.CWS_Renewal_Type__c  =opp.SBQQ__RenewedContract__r.CWS_Renewal_Type__c;
                    //RENEWALCAT_CHANGE_REQ
                    quote.CWS_Renewal_Category__c = opp.SBQQ__RenewedContract__r.CWS_Renewal_Category__c;
                    quote.SBQQ__BillingFrequency__c = opp.SBQQ__RenewedContract__r.CWS_Billing_Frequency__c;
                    quote.CWS_SAT_GAT__c = opp.SBQQ__RenewedContract__r.CWS_SAT_GAT__c;
                    quote.CWS_Contract_Effective_Start_Date__c = opp.SBQQ__RenewedContract__r.StartDate;
                    quote.CWS_Contract_End_Date__c = opp.SBQQ__RenewedContract__r.EndDate;
                    quote.CWS_Contract_Term__c = opp.SBQQ__RenewedContract__r.ContractTerm;
                    quote.CWS_Legacy_Disti_Factor__c = opp.SBQQ__RenewedContract__r.CWS_Legacy_Disti_Factor__c;
                    quote.OwnerId = opp.OwnerId;
                    quote.CWS_Min_Commit_Product_Start_Date__c = opp.SBQQ__RenewedContract__r.CWS_Min_Commit_Product_Start_Date__c;
                } else if (opp != null && !quote.isClone() && quote.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {

                    quote.RecordTypeId = CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY;
                    quote.CWS_Quote_Type__c = CWS_ConstantClass.QUOTE_TYPE_AMENDMENT;
                    quote.CWS_Temporary_License__c = opp.SBQQ__AmendedContract__r.CWS_Temporary_License__c;
                    quote.CWS_Legal_Entity__c = opp.SBQQ__AmendedContract__r.CWS_Legal_Entity__c;
                    quote.CWS_Route_to_Market__c = opp.SBQQ__AmendedContract__r.SBQQ__Quote__r.CWS_Route_to_Market__c;
                    quote.SBQQ__PrimaryContact__c = opp.SBQQ__AmendedContract__r.CWS_Sold_To_Contact__c;
                    quote.CWS_Bill_To_Contact__c = opp.SBQQ__AmendedContract__r.CWS_Bill_To_Contact__c;
                    quote.CWS_Bill_To_Account__c = opp.SBQQ__AmendedContract__r.CWS_Bill_To_Account__c;
                    quote.CWS_Ship_To_Account__c = opp.SBQQ__AmendedContract__r.CWS_Ship_To_Account__c;
                    quote.CWS_Ship_To_Contact__c = opp.SBQQ__AmendedContract__r.CWS_Ship_To_Contact__c;
                    quote.SBQQ__Distributor__c = opp.SBQQ__AmendedContract__r.CWS_Distributor__c;
                    quote.CWS_Distributor_Fulfillment_Type__c = opp.SBQQ__AmendedContract__r.CWS_Distributor_Fulfillment_Type__c;
                    quote.CWS_Distributor_Category__c = opp.SBQQ__AmendedContract__r.CWS_Distributor_Category__c;
                    quote.CWS_Reseller_Account__c = opp.SBQQ__AmendedContract__r.CWS_Reseller_Account__c;
                    quote.CWS_Amendment_Renewal_Reason__c = opp.SBQQ__AmendedContract__r.CWS_Amendment_Renewal_Reason__c;
                    quote.CWS_Secondary_Recipient_Email__c = opp.SBQQ__AmendedContract__r.CWS_Secondary_Recipient_Email__c;
                    quote.CWS_Secondary_Recipient_Name__c = opp.SBQQ__AmendedContract__r.CWS_Secondary_Recipient_Name__c;
                    quote.CWS_Renewal_CAP__c = opp.SBQQ__AmendedContract__r.CWS_Renewal_CAP__c;
                    quote.SBQQ__PaymentTerms__c = opp.SBQQ__AmendedContract__r.CWS_Payment_Term__c;
                    quote.SBQQ__RenewalTerm__c = opp.SBQQ__AmendedContract__r.SBQQ__RenewalTerm__c;
                    //quote.CWS_Renewal_Type__c  =opp.SBQQ__AmendedContract__r.CWS_Renewal_Type__c;
                    //RENEWALCAT_CHANGE_REQ
                    quote.CWS_Renewal_Category__c = opp.SBQQ__AmendedContract__r.CWS_Renewal_Category__c;
                    quote.SBQQ__Partner__c = opp.SBQQ__AmendedContract__r.CWS_End_Partner_Account__c;
                    quote.SBQQ__BillingFrequency__c = opp.SBQQ__AmendedContract__r.CWS_Billing_Frequency__c;
                    quote.CWS_SAT_GAT__c = opp.SBQQ__AmendedContract__r.CWS_SAT_GAT__c;
                    quote.CWS_Contract_Effective_Start_Date__c = opp.SBQQ__AmendedContract__r.StartDate;
                    quote.CWS_Contract_End_Date__c = opp.SBQQ__AmendedContract__r.EndDate;
                    quote.CWS_Contract_Term__c = opp.SBQQ__AmendedContract__r.ContractTerm;
                    quote.CWS_Legacy_Disti_Factor__c = opp.SBQQ__AmendedContract__r.CWS_Legacy_Disti_Factor__c;
                    quote.OwnerId = opp.OwnerId;
                    quote.CWS_Min_Commit_Product_Start_Date__c = opp.SBQQ__AmendedContract__r.CWS_Min_Commit_Product_Start_Date__c;
                    //end of bed-5294
                }
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CWS_QuoteTriggerHelper', 'copyToRenewalAmendmentQuoteBeforeIns', '', null, null, 'copyToRenewalAmendmentQuoteBeforeIns', null);
        }
    }

    /*
    * Method name  : afterUpdate
    * @description  : Bed-199
    * @param       : newItems List of Quotes.
                    oldItems - old list of quotes
    * Return Type  : None
    * Developer    :
    */
    public static void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

        Map<Id, SBQQ__Quote__c> newMap = (Map<Id, SBQQ__Quote__c>) newItems;
        Map<Id, SBQQ__Quote__c> oldMap = (Map<Id, SBQQ__Quote__c>) oldItems;
        Map<String, Decimal> ecoFacMap = new Map<String, Decimal>();
        Integer qtyLimit = Integer.valueOf(System.Label.CWS_Custom_Metedata_Query_Limit);
        //KeyString used to prepare keys of category, EW_Attribute and CurrencyISOCode
        String keyString;
        List<SBQQ__QuoteLine__c> updQuoteLines = new List<SBQQ__QuoteLine__c>();
        List<Id> quoteList = new List<Id>();
        List<Id> recallQuoteIds = new List<Id>();
        List<Task> lstTasks = new List<Task>();
        //Start 8383
        Set<Id> soldToAccIds = new Set<Id>();
        List<Opportunity> opps = new List<Opportunity>();
        Set<Id> billToAccountIds = new Set<Id>();
        //End 8383

        try {
            Group consultingGroup = [
                    SELECT Id,RelatedId,Name, DeveloperName
                    FROM Group
                    WHERE Type = 'Queue'
                    AND Name = 'Consulting Team'
                    AND DeveloperName = 'CWS_Consulting_Team'
                    LIMIT 5
            ];

            //Start 5707
            Map<Id, SBQQ__QuoteDocument__c> quoteDocMap = new Map<Id, SBQQ__QuoteDocument__c>();
            EmailTemplate emTemp = new EmailTemplate();
            List<Id> docQuoteList = new List<Id>();
            List<String> conversionType = new List<String>();
            Map<Id, Opportunity> mapOppToUpdate = new Map<Id, Opportunity>();//Map of Opportunities to update
            Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>();//Map of queried opportunities
            Set<Id> setOppIds = new Set<Id>();//Set of opportunity Ids to retrieve
            String sOppStage;//Opportunity stage string
            String sOppRT;//BED-892 Stores Opportunity recordtype string
            Map<String, CWS_QuoteOppSyncFields__c> mapQuoteOppSync = CWS_QuoteOppSyncFields__c.getAll();//Map of quote opportunity sync fields from custom setting
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SAAS_TO_SUB);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SUB_TO_SAAS);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SAASPKG_TO_SUBPKG);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SUBPKG_TO_SAASPKG);
            //conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_ONPERM_SAAS);
            //conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SAAS_ONPERM);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_PERPETUAL_SAAS);
            conversionType.add(rebeccaValue);

            List<SBQQ__QuoteDocument__c> quoteDocs = [
                    SELECT Id, Name, CurrencyIsoCode, SBQQ__Quote__c, SBQQ__Quote__r.CWS_Quote_Type__c, SBQQ__Quote__r.CWS_Transaction_Reason__c,
                            SBQQ__Quote__r.CWS_Linecount_AddOn__c, SBQQ__Quote__r.CWS_Linecount_Cancel__c, SBQQ__DocumentId__c, SBQQ__ElectronicSignature__c,
                            SBQQ__Key__c, CWS_Offline_Signature_Status__c, CWS_Document_Type__c, SBQQ__SignatureStatus__c, SBQQ__Quote__r.CWS_Conversion_Type__c,SBQQ__Quote__r.SBQQ__NetAmount__c,
                            SBQQ__Quote__r.SBQQ__Account__r.CWS_MNG_Partner_Log_In__c, SBQQ__Quote__r.SBQQ__Account__r.Name, SBQQ__Quote__r.SBQQ__PrimaryContact__r.Name
                    FROM SBQQ__QuoteDocument__c
                    WHERE SBQQ__Quote__c IN:newMap.keySet() AND SBQQ__Quote__r.CWS_Conversion_Type__c IN:conversionType AND SBQQ__Quote__r.CWS_Quote_Type__c = :CWS_ConstantClass.QUOTE_TYPE_AMENDMENT AND
                    SBQQ__Quote__r.CWS_Transaction_Reason__c = :CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION
                    AND (SBQQ__Quote__r.CWS_Linecount_AddOn__c > 0 OR SBQQ__Quote__r.CWS_Linecount_Cancel__c > 0)
                    AND (SBQQ__SignatureStatus__c = :CWS_ConstantClass.QDOC_SIG_SIGNED OR CWS_Offline_Signature_Status__c = :CWS_ConstantClass.QDOC_SIG_SIGNED)
            ];

            if (quoteDocs.size() > 0) {
                for (SBQQ__QuoteDocument__c quoteDoc : quoteDocs) {
                    quoteDocMap.put(quoteDoc.SBQQ__Quote__r.Id, quoteDoc);
                }
                emTemp = [SELECT Id, DeveloperName, Name, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = :CWS_ConstantClass.CONVERSION_TYPE_EMAIL_TEMPLATE LIMIT 1];
            }

            //End 5707

            //BED-199 Only quotes of type accepted or inactive needs to be taken into account for quoteList
            for (SBQQ__Quote__c quote : newMap.values()) {
                SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);
                if ((quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED && oldQuote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_ACCEPTED) || (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INACTIVE && oldQuote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_INACTIVE)) {
                    quoteList.add(quote.Id);
                }
                if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED && oldQuote.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_ACCEPTED && quoteDocMap.containsKey(quote.Id) && quote.CWS_Conversion_Type__c != null) {
                    docQuoteList.add(quote.Id);
                }

                //BED-8645 start
                if (quote.SBQQ__Status__c != oldMap.get(quote.Id).SBQQ__Status__c && quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INACTIVE) {
                    recallQuoteIds.add(quote.Id);
                }
                // BED-8645 end
                //BED-892 check for quote status change and is primary quote to retrieve opportunites
                //BED-8895 Added substage condition for pending fulfillment
                if ((quote.CWS_Sub_Stage__c != oldMap.get(quote.Id).CWS_Sub_Stage__c || quote.SBQQ__Status__c != oldMap.get(quote.Id).SBQQ__Status__c ||
                        quote.SBQQ__Primary__c != oldMap.get(quote.Id).SBQQ__Primary__c) && quote.SBQQ__Primary__c) {
                    setOppIds.add(quote.SBQQ__Opportunity2__c);
                }
                //BED-892 check for quote opportunity sync field changes
                for (CWS_QuoteOppSyncFields__c objFields : mapQuoteOppSync.values()) {
                    if (quote.get(objFields.Name) != oldMap.get(quote.Id).get(objFields.Name)) {
                        setOppIds.add(quote.SBQQ__Opportunity2__c);
                    }
                }
                //8383 Start
                if (quote.SBQQ__Account__c != null && quote.SBQQ__Status__c != oldMap.get(quote.Id).SBQQ__Status__c
                        && quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED && quote.CWS_Route_to_Market__c != CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct
                        && quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && quote.SBQQ__Primary__c) {
                    soldToAccIds.add(quote.SBQQ__Account__c);
                    billToAccountIds.add(quote.CWS_Bill_To_Account__c);
                }
                //End 8383
            }

            if (emTemp != null && !docQuoteList.isEmpty() && quoteDocMap.size() > 0) {
                List<Messaging.SingleEmailMessage> emailMessages = sendMails(docQuoteList, quoteDocMap, emTemp);
                if (emailMessages.size() > 0) {
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(emailMessages);
                    for (Messaging.SendEmailResult res : results) {
                        if (res.isSuccess()) {
                            System.debug('Success: sent e-mail.');
                        } else {
                            CWS_ExceptionHandler.logErrors(
                                    'CWS_QuoteTriggerHelper',
                                    'afterUpdate',
                                    '',
                                    'Error occurred while sending email',
                                    '',
                                    'Sending Email message failed',
                                    ''
                            );
                            System.debug(res.getErrors());
                        }
                    }
                }

            }


            if (quoteList.size() > 0) {
                //quoteLineList consists of quotelines from quoteList where the quote stage is either accepted or inactive
                List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
                if (quoteList != null) {
                    quoteLineList = [
                            SELECT
                                    Id,
                                    CWS_Economic_Factor__c,
                                    CurrencyIsoCode,
                                    CWS_EF_Attribute__c,
                                    CWS_Category__c
                            FROM SBQQ__QuoteLine__c
                            WHERE SBQQ__Quote__c IN :quoteList
                    ];
                }

                //all economic factor records will be filtered
                List<CWS_Economic_Factor__c> efList = new List<CWS_Economic_Factor__c>([
                        SELECT
                                Id,
                                CWS_Category__c,
                                CWS_Product_Type__c,
                                CWS_Economic_Factor__c,
                                CurrencyIsoCode
                        FROM CWS_Economic_Factor__c
                        LIMIT :qtyLimit
                ]
                );

                //Map of economic factor records
                for (CWS_Economic_Factor__c ecoFac : efList) {
                    keyString = ecoFac.CWS_Category__c + ecoFac.CWS_Product_Type__c + ecoFac.CurrencyIsoCode;
                    ecoFacMap.put(keyString, ecoFac.CWS_Economic_Factor__c);
                }

                // added test coverage
                if (ecoFacMap.size() > 0) {
                    for (SBQQ__QuoteLine__c quoteLine : quoteLineList) {
                        keyString = quoteLine.CWS_Category__c + quoteLine.CWS_EF_Attribute__c + quoteLine.CurrencyIsoCode;
                        if (ecoFacMap.containsKey(keyString)) {
                            if (quoteLine.CWS_Economic_Factor__c != ecoFacMap.get(keyString)) {
                                quoteLine.CWS_Economic_Factor__c = ecoFacMap.get(keyString);
                                updQuoteLines.add(quoteLine);
                            }
                        }
                    }
                }
            }

            //BED-892 Query can modified and reused
            if (setOppIds.size() > 0) {
                mapOpportunity.putAll([
                        SELECT Id,StageName,CWS_Bill_To_Account__c,CWS_Bill_To_Contact__c,Type,
                                CWS_Exchange_Rate__c,CWS_Legal_Entity__c,CWS_Route_to_Market__c,CWS_Single_Distributor_Validation__c,
                                CWS_Ship_To_Account__c,CWS_TCV__c,AccountId,CWS_Sold_To_Contact__c,CWS_Bill_To_Account__r.CWS_Is_IIT_Reseller__c,
                                CWS_Disti_Deal_Phase__c,CWS_Bill_To_Account__r.CWS_Is_Distributor__c,Account.CWS_Established_Disti_Reseller__c,
                                CWS_On_Hold__c,CWS_On_Hold_Reason__c,SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.CWS_First_Quote__c,
                                SBQQ__PrimaryQuote__r.SBQQ__Status__c,RecordTypeId,CWS_Fast_Track__c
                        FROM Opportunity
                        WHERE Id IN :setOppIds
                            OR (
                                AccountId IN :soldToAccIds
                                AND CWS_Route_to_Market__c != :CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct
                                AND Type = :CWS_ConstantClass.Opportunity_Type_New
                                AND SBQQ__PrimaryQuote__r.SBQQ__Status__c != :CWS_ConstantClass.QUOTE_STATUS_ACCEPTED
                                )
                ]);

            }

            //8383 Start
            if (soldToAccIds.size() > 0) {
                for (Opportunity opp : mapOpportunity.values()) {
                    if (soldToAccIds.contains(opp.AccountId) &&
                            (opp.CWS_Bill_To_Account__r.CWS_Is_Distributor__c || opp.CWS_Bill_To_Account__r.CWS_Is_IIT_Reseller__c)
                            && opp.CWS_Route_to_Market__c != CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct
                            && opp.Type == CWS_ConstantClass.Opportunity_Type_New && opp.Account.CWS_Established_Disti_Reseller__c != opp.CWS_Bill_To_Account__c
                            && opp.SBQQ__PrimaryQuote__c != null && !opp.SBQQ__PrimaryQuote__r.CWS_First_Quote__c
                            && opp.SBQQ__PrimaryQuote__r.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_ACCEPTED
                            && !billToAccountIds.contains(opp.CWS_Bill_To_Account__c)) {
                        opp.CWS_Single_Distributor_Validation__c = true;
                        opps.add(opp);
                        //mapOppToUpdate.put(opp.id,opp);
                    }
                }
            }
            // End 8383
            Id masterContractId;
            //BED-892 Loop can be reused for other logic
            for (SBQQ__Quote__c objQuote : newMap.values()) {
                //BED-1341
                if (((objQuote.SBQQ__MasterEvergreenContract__c != oldMap.get(objQuote.Id).SBQQ__MasterEvergreenContract__c &&
                        objQuote.SBQQ__MasterEvergreenContract__c != null) ||
                        (objQuote.SBQQ__MasterContract__c != oldMap.get(objQuote.Id).SBQQ__MasterContract__c &&
                                objQuote.SBQQ__MasterContract__c != null)) &&
                        objQuote.CWS_LegacyKey__c != null &&
                        objQuote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {
                    masterContractId = objQuote.SBQQ__MasterContract__c != null ? objQuote.SBQQ__MasterContract__c :
                            (objQuote.SBQQ__MasterEvergreenContract__c != null ?
                                    objQuote.SBQQ__MasterEvergreenContract__c : null);
                    if (mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c) != null) {
                        mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).SBQQ__AmendedContract__c =
                                masterContractId;
                    } else {
                        mapOppToUpdate.put(objQuote.SBQQ__Opportunity2__c,
                                new Opportunity(SBQQ__AmendedContract__c = masterContractId));
                    }
                }
                //check for quote status change and is primary quote to update opp stage
                //BED-8895 Added substage condition for pending fulfillment
                if ((objQuote.CWS_Sub_Stage__c != oldMap.get(objQuote.Id).CWS_Sub_Stage__c || objQuote.SBQQ__Status__c != oldMap.get(objQuote.Id).SBQQ__Status__c || objQuote.SBQQ__Primary__c != oldMap.get(objQuote.Id).SBQQ__Primary__c) && objQuote.SBQQ__Primary__c) {
                    //Bed-1018 Start
                    Boolean distyCheck = false;
                    if (mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).CWS_Disti_Deal_Phase__c == CWS_ConstantClass.DistiEndCustomer && mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).CWS_Fast_Track__c == false
                            && ((mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel) ||
                            ((mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).CWS_Route_to_Market__c == CWS_ConstantClass.OPPORTUNITY_RouteToMarket_IIT &&
                                    mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).CWS_Bill_To_Account__c != null &&
                                    mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).CWS_Bill_To_Account__r.CWS_Is_Distributor__c == true))
                    )) {
                        distyCheck = true;
                    }
                    sOppStage = getOpportunityStage(objQuote, distyCheck);//BED-8895
                    //Bed-1018 End
                    //Check if opportunity stage is not same and then update
                    if (String.isNotBlank(sOppStage) && mapOpportunity.containsKey(objQuote.SBQQ__Opportunity2__c)
                            && sOppStage != mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).StageName) {
                        sOppRT = getOpportunityRT(objQuote.CWS_Quote_Type__c);
                        if (!mapOppToUpdate.containsKey(objQuote.SBQQ__Opportunity2__c)) {
                            mapOppToUpdate.put(objQuote.SBQQ__Opportunity2__c, mapOpportunity.get(objQuote.SBQQ__Opportunity2__c));
                        }
                        mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).StageName = sOppStage;
                        //Start BED-8615
                        if (sOppStage == CWS_ConstantClass.OpportunityClosedWon_Stage && objQuote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC &&
                                mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).CWS_On_Hold__c) {
                            mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).CWS_On_Hold_Reason__c = '';
                            mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).CWS_On_Hold__c = false;
                        }
                        //End BED-8615
                        //Update recordtype of opportunity
                        if (sOppRT != null && !sOppRT.equals(mapOpportunity.get(objQuote.SBQQ__Opportunity2__c).RecordTypeId)
                                && (sOppStage.equals(CWS_ConstantClass.OPPORTUNITY_STAGE_PROPOSAL) || sOppStage.equals(CWS_ConstantClass.OPPORTUNITY_STAGE_FINALIZE_QUOTE))) {
                            mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).RecordTypeId = sOppRT;
                        }
                    }
                }
                //BED-892 Update opportunity when quote sync fields are changed
                if (objQuote.SBQQ__Primary__c) {
                    //Looping over custom setting to get sync fields
                    for (CWS_QuoteOppSyncFields__c objFields : mapQuoteOppSync.values()) {
                        //Checking if quote field is changed and update opportunity field
                        if (objQuote.get(objFields.Name) != oldMap.get(objQuote.Id).get(objFields.Name)) {
                            if (!mapOppToUpdate.containsKey(objQuote.SBQQ__Opportunity2__c)) {
                                mapOppToUpdate.put(objQuote.SBQQ__Opportunity2__c, mapOpportunity.get(objQuote.SBQQ__Opportunity2__c));
                            }
                            mapOppToUpdate.get(objQuote.SBQQ__Opportunity2__c).put(objFields.CWS_OpportunityField__c, objQuote.get(objFields.Name));
                        }
                    }
                }
                if (objQuote.SBQQ__Status__c != oldMap.get(objQuote.Id).SBQQ__Status__c
                        && objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_APPROVED
                        && objQuote.CWS_Custom_sow__c >= 1) {


                    System.debug('Enter Main Logic');
                    lstTasks.add(new Task(
                            Status = CWS_ConstantClass.TASK_STATUS_OPEN,
                            Description = System.Label.CWS_Task_Description + ' ' + objQuote.Name,  // Status
                            Subject = System.Label.CWS_Task_Subject,           // Subject
                            ActivityDate = Date.today().addDays(1),  // Due Date
                            Priority = CWS_ConstantClass.TASK_PRIORITY_HIGH,        // Priority
                            OwnerId = consultingGroup.Id,
                            CWS_Quote_Id__c = objQuote.Id,
                            Type = CWS_ConstantClass.TASK_TYPE_CUSTOM_SOW_REQUEST,
                            WhatId = objQuote.SBQQ__Opportunity2__c
                    ));
                }
            }


            if (!lstTasks.isEmpty()) {
                insert lstTasks;
            }
            if (updQuoteLines.size() > 0) {
                List<Database.SaveResult> results = Database.update(updQuoteLines, true);
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_QuoteTriggerHelper', 'AfterUpdate', 'SBQQ__Quote_Line__c', null, null);
            }
            //BED-892 Update opportunities with new stage
            if (mapOppToUpdate.size() > 0) {
                opps.addAll(mapOppToUpdate.values());
            }
            if (opps.size() > 0) {
                List<Database.SaveResult> results = Database.update(opps);
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_QuoteTriggerHelper', 'AfterUpdate', 'Opportunity', null, null);
            }
            // BED-8645 starts
            if (!recallQuoteIds.isEmpty() && System.isBatch() == false && System.isFuture() == false) {
                recallQuoteFutureHelper(recallQuoteIds);
            }
            // BED-8645 ends
        }

        catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CWS_QuoteTriggerHelper', 'afterUpdate', '', null, null, 'afterUpdate', null);
        }

    }

    /*
    * Method name  : updateOverageQLI
    * @description  : Bed-8213 - To update Overage unit Price if Overage uplift percentage is changed.
    * @param    : newItems - List of Quotes , 
                oldItems - Map of Old Items.
    * Developer    : Akhila
    */
    public static void updateOverageQLI(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        try {
            //SBQQ.TriggerControl.disable();
            Map<Id, SBQQ__Quote__c> newMap = (Map<Id, SBQQ__Quote__c>) newItems;
            Map<Id, SBQQ__Quote__c> oldMap = (Map<Id, SBQQ__Quote__c>) oldItems;
            Set<Id> quoteIds = new Set<Id>();
            for (SBQQ__Quote__c quote : newMap.values()) {
                quoteIds.add(quote.Id);
            }

            List<SBQQ__QuoteLine__c> updQuoteLines = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> quoteLineList;
            if (quoteIds != null) {
                quoteLineList = [SELECT Id, SBQQ__Quote__c,CWS_ChargeType__c,SBQQ__UpgradedSubscription__c,CWS_Minimum_Commit_Eligibility__c,SBQQ__RenewedSubscription__c,CWS_RegularPrice__c, CWS_Overage_Unit_Price__c,SBQQ__Quote__r.CWS_Original_Overage_Uplift__c, SBQQ__Quote__r.CWS_Overage_Uplift_Percentage__c, CWS_Overage_Price__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN:quoteIds];
            }
            if (quoteLineList != null) {
                for (SBQQ__QuoteLine__c quoteLine : quoteLineList) {
                    SBQQ__Quote__c oldQuoteRec;
                    SBQQ__Quote__c newQuoteRec;
                    Decimal originalPrice;
                    if (oldMap.containsKey(quoteLine.SBQQ__Quote__c)) {
                        oldQuoteRec = oldMap.get(quoteLine.SBQQ__Quote__c);
                    }
                    if (newMap.containsKey(quoteLine.SBQQ__Quote__c)) {
                        newQuoteRec = newMap.get(quoteLine.SBQQ__Quote__c);
                    }

                    if (
                            (oldQuoteRec.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_DRAFT || oldQuoteRec.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_REVISION)
                            && (newQuoteRec.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_APPROVED || newQuoteRec.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INREVIEW)
                            && quoteLine.CWS_Overage_Price__c > 0
                            && quoteLine.SBQQ__Quote__r.CWS_Overage_Uplift_Percentage__c > 0
                            && quoteLine.CWS_Minimum_Commit_Eligibility__c == true
                            && quoteLine.SBQQ__Quote__r.CWS_Original_Overage_Uplift__c > 0
                            && quoteLine.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Usage
                            && quoteLine.CWS_Overage_Unit_Price__c > 0
                            && quoteLine.CWS_Overage_Unit_Price__c == quoteLine.CWS_Overage_Price__c
                            && quoteLine.SBQQ__Quote__r.CWS_Overage_Uplift_Percentage__c != quoteLine.SBQQ__Quote__r.CWS_Original_Overage_Uplift__c
                            && quoteLine.SBQQ__UpgradedSubscription__c == null
                            && quoteLine.SBQQ__RenewedSubscription__c == null) {

                        updQuoteLines.add(assignDraftToApprovedValuesForOverageQLI(quoteLine));
                    }
                }
            }
            if (!updQuoteLines.isEmpty()) {
                SBQQ.TriggerControl.disable();
                update updQuoteLines;
            }
            for (SBQQ__Quote__c quote : newMap.values()) {
                if (quote.CWS_Original_Overage_Uplift__c != quote.CWS_Overage_Uplift_Percentage__c) {
                    quote.CWS_Original_Overage_Uplift__c = quote.CWS_Overage_Uplift_Percentage__c;
                }
            }

        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CWS_QuoteTriggerHelper', 'updateOverageQLI', '', null, null, 'updateOverageQLI', null);
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }

    /**
     * @description :Method is used to set overage unit price on the quoteline 
     * @param : quoteLine - Quoteline record on which the update is req. to be done
     * @return : the quote line updated with the new value.
     */
    public static SBQQ__QuoteLine__c assignDraftToApprovedValuesForOverageQLI(SBQQ__QuoteLine__c quoteLine) {
        Decimal originalPrice;
        originalPrice = quoteLine.CWS_Overage_Unit_Price__c / (1 + (quoteLine.SBQQ__Quote__r.CWS_Original_Overage_Uplift__c / 100));
        Decimal quoteUpliftPercentage = quoteLine.SBQQ__Quote__r.CWS_Overage_Uplift_Percentage__c;
        Decimal actualQuoteUpliftPercentage = quoteUpliftPercentage == null ? 0 : quoteUpliftPercentage;
        originalPrice = originalPrice * (1 + (actualQuoteUpliftPercentage / 100));
        quoteLine.CWS_Overage_Unit_Price__c = quoteLine.CWS_Overage_Price__c = originalPrice.setScale(2);
        return quoteLine;
    }

    /*
    *@Description: Recalling inactive quote approvals
    *Developer: Khayam
    *Story : BED-8645
    *@param : quoteId - List of auoteIds which are required to be processed.
    */
    @Future
    public static void recallQuoteFutureHelper(List<Id> quoteIds) {
        for (Id qId : quoteIds) {
            SBAA.ApprovalAPI.recall(qId, SBAA__Approval__c.CWS_Quote__c);
        }
    }

    /*
    *@description: Approval Workflow sub-optimal design
    *Developer: Naresh
    *Story : BED-3750
    *@param: newItems - New list of Quotes
    */
    public static void cloneRelatedRecords(Map<Id, SObject> newItems) {
        Map<Id, SBQQ__Quote__c> newQuotes = (Map<Id, SBQQ__Quote__c>) newItems;
        Map<Id, SBQQ__Quote__c> cloneQMap = new Map<Id, SBQQ__Quote__c>();
        Savepoint sp = Database.setSavepoint();

        try {

            for (SBQQ__Quote__c quote : newQuotes.values()) {
                if (quote.isClone()) {
                    cloneQMap.put(quote.getCloneSourceId(), quote);
                }
            }

            if (!cloneQMap.isEmpty()) {
                Map<Id, sbaa__Approval__c> cloneAppMap = new Map<Id, sbaa__Approval__c> ();
                Map<Id, sbaa__ApprovalSnapshot__c> cloneSnapMap = new Map<Id, sbaa__ApprovalSnapshot__c> ();

                List<sbaa__Approval__c> approvals = [SELECT sbaa__ApprovalStep__c, sbaa__RecordField__c, sbaa__Approver__c, sbaa__AssignedTo__c, CWS_Quote__c, sbaa__Rule__c, sbaa__ApprovalChain__c, sbaa__ApprovedBy__c, sbaa__RejectedBy__c, sbaa__CommentsLong__c,sbaa__Status__c, (SELECT sbaa__Approval__c, sbaa__ApprovalCondition__c, sbaa__ApprovedValueNumeric__c, sbaa__ApprovedValueDate__c, sbaa__ApprovedValueText__c, sbaa__ApprovedValueLongText__c FROM sbaa__ApprovalSnapshot__r) FROM sbaa__Approval__c WHERE CWS_Quote__c IN :cloneQMap.keySet()];

                for (sbaa__Approval__c approval : approvals) {
                    sbaa__Approval__c newApproval = approval.clone();
                    //newApproval.sbaa__Status__c = newApproval.sbaa__Status__c == CA_AllOMBConstants.QUOTE_APP_STATUS_REQ ? CA_AllOMBConstants.QUOTE_APP_STATUS_ASSIGN : newApproval.sbaa__Status__c;
                    newApproval.CWS_Quote__c = cloneQMap.get(approval.CWS_Quote__c).Id;

                    cloneAppMap.put(approval.Id, newApproval);
                }

                if (!cloneAppMap.isEmpty()) {
                    insert cloneAppMap.values();

                    for (sbaa__Approval__c approval : approvals) {
                        for (sbaa__ApprovalSnapshot__c snapshot : approval.sbaa__ApprovalSnapshot__r) {
                            sbaa__ApprovalSnapshot__c newSnapshot = snapshot.clone();
                            newSnapshot.sbaa__Approval__c = cloneAppMap.get(snapshot.sbaa__Approval__c).Id;

                            cloneSnapMap.put(snapshot.Id, newSnapshot);
                        }
                    }

                    if (!cloneSnapMap.isEmpty()) {
                        insert cloneSnapMap.values();
                    }
                }
            }

        } catch (Exception e) {
            Database.rollback(sp);
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CA_QuoteTriggerHelper', 'cloneRelatedRecords', '', null, null, 'cloneRelatedRecords', null);
        }

    }
    //Commented out as part of BED-3528 updated US
    /*public static List<Messaging.SingleEmailMessage> sendMails(List<Id> Quote, Map<Id,SBQQ__QuoteDocument__c> quoteDocMap, EmailTemplate emTemp ){
      // Create email
           // Document  doc = docMap.get(docRec.SBQQ__DocumentId__c);

           List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
           try{
           List<String> Addresses = new List<String>();
           Addresses.add(System.label.CWS_Install_Team_Email_Address);

        for(Id quoteId:Quote){
                SBQQ__QuoteDocument__c docRec = quoteDocMap.get(quoteId);
                String subject = emTemp.Subject;
                String htmlBody = emTemp.HtmlValue;
                String plainBody = emTemp.Body;

            subject = subject.replace('{varCompanyName}',docRec.SBQQ__Quote__r.SBQQ__Account__r.Name);
            htmlBody = htmlBody.replace('{varCompanyName}',docRec.SBQQ__Quote__r.SBQQ__Account__r.Name);
            plainBody = plainBody.replace('{varCompanyName}',docRec.SBQQ__Quote__r.SBQQ__Account__r.Name);

            if(docRec.SBQQ__Quote__r.SBQQ__Account__r.CWS_MNG_Partner_Log_In__c==null){
                htmlBody = htmlBody.replace('{varCompanyId}','');
                plainBody = plainBody.replace('{varCompanyId}','');
            }
            else{
            htmlBody = htmlBody.replace('{varCompanyId}',docRec.SBQQ__Quote__r.SBQQ__Account__r.CWS_MNG_Partner_Log_In__c);
            plainBody = plainBody.replace('{varCompanyId}',docRec.SBQQ__Quote__r.SBQQ__Account__r.CWS_MNG_Partner_Log_In__c);
            }
            if(docRec.SBQQ__Quote__r.SBQQ__PrimaryContact__r.Name==null){
                htmlBody = htmlBody.replace('{varSoldContact}','');
                plainBody = plainBody.replace('{varSoldContact}','');
            }
            else{
                htmlBody = htmlBody.replace('{varSoldContact}',docRec.SBQQ__Quote__r.SBQQ__PrimaryContact__r.Name);
                plainBody = plainBody.replace('{varSoldContact}',docRec.SBQQ__Quote__r.SBQQ__PrimaryContact__r.Name);
            }
            if(docRec.SBQQ__Quote__r.CWS_Conversion_Type__c==null){
                htmlBody =  htmlBody.replace('{varConversionType}','');
                plainBody =  plainBody.replace('{varConversionType}','');
            }
            else{
                    htmlBody =  htmlBody.replace('{varConversionType}',docRec.SBQQ__Quote__r.CWS_Conversion_Type__c);
                    plainBody =  plainBody.replace('{varConversionType}',docRec.SBQQ__Quote__r.CWS_Conversion_Type__c);
            }
            htmlBody =  htmlBody.replace('{varLinecountCancel}',String.valueOf(docRec.SBQQ__Quote__r.CWS_Linecount_Cancel__c));
            htmlBody =  htmlBody.replace('{varLinecountAddOn}',String.valueOf(docRec.SBQQ__Quote__r.CWS_Linecount_AddOn__c));
            htmlBody =  htmlBody.replace('{varNetAmount}',String.valueOf(docRec.SBQQ__Quote__r.SBQQ__NetAmount__c));
            htmlBody =  htmlBody.replace('{varCurrency}',docRec.CurrencyISOCode);
            plainBody =  plainBody.replace('{varLinecountCancel}',String.valueOf(docRec.SBQQ__Quote__r.CWS_Linecount_Cancel__c));
            plainBody =  plainBody.replace('{varLinecountAddOn}',String.valueOf(docRec.SBQQ__Quote__r.CWS_Linecount_AddOn__c));
            plainBody =  plainBody.replace('{varNetAmount}',String.valueOf(docRec.SBQQ__Quote__r.SBQQ__NetAmount__c));
            plainBody =  plainBody.replace('{varCurrency}',docRec.CurrencyISOCode);
            htmlBody = htmlBody.replaceAll('<!\\[CDATA\\[', ''); // replace '<![CDATA['
            htmlBody= htmlBody.replaceAll('\\]\\]>', ''); // replace ']]'


                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setToAddresses(Addresses);
                message.setSubject(subject);
                message.setHtmlBody(htmlBody);
                message.setPlainTextBody(plainBody);
                message.setEntityAttachments(new ID[]{docRec.SBQQ__DocumentId__c});
                messageList.add(message);
            }
        }

        catch(Exception e){
            CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_QuoteTriggerHelper', 'sendMails' , '', null, null , 'afterUpdate' , null);
        }
            return messageList;
    }*/

    /*
    * @description  : Retrieve opportunity stage based on quote status.
    * @param : objQuote - quote record req. to be updated
            distyCheck- Boolean check for disty check
    * @Return : Return the Opportunity stage name
    * Developer    : Sudhir Moturu
    */
    //BED-892 Opportunity stage based on quote stage logic
    //BED-8895 Added substage condition for pending fulfillment
    public static String getOpportunityStage(SBQQ__Quote__c objQuote, Boolean distyCheck) {
        if (!distyCheck && (objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED
                || (objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG
                && objQuote.CWS_Sub_Stage__c == CWS_ConstantClass.QUOTE_SUB_STAGE_PENDING_FULFILLMENT))) {//BEd-1018 added distyCheck
            return CWS_ConstantClass.OpportunityClosedWon_Stage;
        }
        //Start Added by Mahak Bansal 8 March 2022 OBD-4193	
        else  if ((distyCheck && objQuote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) 	
                && (objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ACCEPTED	
                || (objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG	
                && objQuote.CWS_Sub_Stage__c == CWS_ConstantClass.QUOTE_SUB_STAGE_PENDING_FULFILLMENT))) {	
            return CWS_ConstantClass.OpportunityClosedWon_Stage;	
        }//End Added by Mahak Bansal 8 March 2022 OBD-4193	
        else if (!distyCheck && (objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN //BEd-1018 added distyCheck
                || objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG)) {
            return CWS_ConstantClass.OPPORTUNITY_STAGE_FINALIZE_QUOTE;
        } else if (objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INREVIEW
                || objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_REVISION
                || objQuote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_APPROVED
                ) {
            return CWS_ConstantClass.OPPORTUNITY_STAGE_PROPOSAL;
        } else {
            return null;
        }
    }

    /*
    * @description  : Retrieve opportunity recordtype.
    * Developer    : Sudhir Moturu
    * @param : quoteType - Quote type passed to ge tthe Opportunity recordtype
    * @return : return the opportunity Record type.
    */
    //BED-892 Opportunity recordtype based on quote type logic
    public static String getOpportunityRT(String quoteType) {
        if (quoteType == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS) {
            return CWS_ConstantClass.OPPORTUNITY_RT_NEWBUSINESS_INTERIM;
        } else if (quoteType == CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                || quoteType == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) {
            return CWS_ConstantClass.OPPORTUNITY_RT_RENEWAL_INTERIM;
        } else if (quoteType == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {
            return CWS_ConstantClass.OPPORTUNITY_RT_AMENDMENT_INTERIM;
        } else {
            return null;
        }
    }

    /*
    *@Description: Install Team Email Modification
    *Developer  : Indra Ganesan
    *User Story : BED-3528
    *@param : quote- quote on which record to be processed.
             quoteDocMap :- QuoteDocument map to be attached as email
             emTemp:- emailTemplate to be sent.
    *@return : Return the singlemessage List , woudl be sent as email 
    */
    public static List<Messaging.SingleEmailMessage> sendMails(List<Id> Quote, Map<Id, SBQQ__QuoteDocument__c> quoteDocMap, EmailTemplate emTemp) {
        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
        List<String> Addresses = new List<String>();
        Addresses.addAll((Label.CWS_Install_Team_Email_Address).split(';'));
        try {
            for (Id quoteId : Quote) {
                if (quoteId != null) {
                    SBQQ__QuoteDocument__c docRec = quoteDocMap.get(quoteId);
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setTemplateId(emTemp.Id);
                    message.setWhatId(quoteId);
                    message.setTargetObjectId(UserInfo.getUserId());
                    message.setToAddresses(Addresses);
                    message.setSaveAsActivity(false);
                    message.setEntityAttachments(new Id[]{
                            docRec.SBQQ__DocumentId__c
                    });
                    messageList.add(message);
                }

            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CWS_QuoteTriggerHelper', 'sendManageDealConversionEmail', '', null, null, 'afterUpdate', null);
        }
        return messageList;
    }

    /*
    * Method name  : Update Approval fields on Quote.
    * @description : Update the approval related fields 
    * Developer    : Naresh
    * @param       : newMap- List of the new records
                   : oldMap - List of old Records
    */
    public static void updateApprovalRelatedFields(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {

        Set<Id> setQuoteIds = new Set<Id>();
        Map<Id, SBQQ__Quote__c> newMaps = (Map<Id, SBQQ__Quote__c>) newMap;
        Map<Id, SBQQ__Quote__c> oldMaps = (Map<Id, SBQQ__Quote__c>) oldMap;
        Set<Id> count = new Set<Id>();
        List<SBQQ__QuoteLine__c> quoteLnItemsLst = new List<SBQQ__QuoteLine__c>();
        List<String> format = new String[]{
                '0', 'number', '###,###,##0.00'
        };
        String oneTimeSubtotal;
        String monthlyRecurringSubtotal;
        String prepaymentAmount;
        String s;
        String s1;
        String s2;
        try {
            for (Id quoteId : newMap.keySet()) {

                if (newMaps.get(quoteId).CWS_One_Time_Subtotal__c != 0 && newMaps.get(quoteId).CWS_One_Time_Subtotal__c != null) {
                    s = newMaps.get(quoteId).CWS_One_Time_Subtotal__c.setScale(0).format();
                } else {
                    s = '0.00';
                }
                if (newMaps.get(quoteId).CWS_Monthly_Recurring_Subtotal__c != 0 && newMaps.get(quoteId).CWS_Monthly_Recurring_Subtotal__c != null) {
                    s1 = newMaps.get(quoteId).CWS_Monthly_Recurring_Subtotal__c.setScale(0).format();
                } else {
                    s1 = '0.00';
                }
                if (newMaps.get(quoteId).CWS_Pre_payment_Amount__c != 0 && newMaps.get(quoteId).CWS_Pre_payment_Amount__c != null) {
                    //s2 = newMaps.get(quoteId).CWS_Pre_payment_Amount__c.setscale(0).format();
                    s2 = String.valueOf((newMaps.get(quoteId).CWS_Pre_payment_Amount__c - newMaps.get(quoteId).CWS_Monthly_Recurring_Subtotal__c).setScale(0).format());
                } else {
                    s2 = '0.00';
                }
                //  String s1 = newMaps.get(quoteId).CWS_Monthly_Recurring_Subtotal__c.setscale(0).format();
                // String s2 = newMaps.get(quoteId).CWS_Pre_payment_Amount__c.setscale(0).format();
                newMaps.get(quoteId).CWS_Pre_Payment_Quote_term__c = newMaps.get(quoteId).CWS_Currency_Symbol__c + s + ' one-time fees and ' + newMaps.get(quoteId).CWS_Currency_Symbol__c + s1 +
                        ' recurring payments with a total payment of ' + newMaps.get(quoteId).CWS_Currency_Symbol__c + s2;
            }


        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CWS_QuoteTriggerHelper', 'updateApprovalRelatedFields', '', null, null, 'beforeUpdate', null);

        }
    }

    /*
    //payment term approvals logic
    // Developer Name :Naresh.
    public static void updatePaymentTermForApproval(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, SBQQ__Quote__c> newMap = (Map<Id, SBQQ__Quote__c>) newItems;
        Integer quoteTermValue;
        Integer originalQuoteTermValue;
        Integer accountTermValue;
        String approvelterm;
        Set<Id> quoteId = new Set<Id>();
        Set<Id> accountId = new Set<Id>();
        Map<Id, SBQQ__Quote__c> originalQuotes = new Map<Id, SBQQ__Quote__c>();
        Map<Id, Account> billingAccounts = new Map<Id, Account>();
        for (SBQQ__Quote__c quote : newMap.values()) {
            if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_DRAFT || quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INREVIEW) {
                if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && (quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT || quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION ||
                        quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION) && quote.CWS_Original_Quote__c != null) {
                    quoteId.add(quote.CWS_Original_Quote__c);
                }
                if (quote.CWS_Bill_To_Account__c != null) {
                    accountId.add(quote.CWS_Bill_To_Account__c);
                }
            }
        }
        if (quoteId.size() > 0) {
            for (SBQQ__Quote__c qt : [SELECT Id, Name, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE Id IN :quoteId]) {
                originalQuotes.put(qt.Id, qt);
            }
        }
        if (accountId.size() > 0) {
            for (Account acc : [SELECT Id,CWS_Payment_Terms__c,CWS_Is_Distributor__c FROM Account WHERE Id IN:accountId]) {
                billingAccounts.put(acc.Id, acc);
            }
        }

        try {
            for (SBQQ__Quote__c quote : newMap.values()) {
                if (quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_DRAFT || quote.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_INREVIEW) {
                    if (quote.SBQQ__PaymentTerms__c != null && quote.SBQQ__PaymentTerms__c != CWS_ConstantClass.Payment_Term_Due_Upon_Receipt) {
                        String quotePaymentTerm = quote.SBQQ__PaymentTerms__c;
                        String[] quotesPterm = quotePaymentTerm.split(' ');
                        String strQuoteNumber = '';
                        // Integer quoteTermValue;
                        if (quotesPterm.size() != null) {
                            strQuoteNumber = quotesPterm[1];
                            quoteTermValue = Integer.valueOf(strQuoteNumber);
                        }
                    } else {
                        quoteTermValue = 0;
                    }

                    if (billingAccounts.get(quote.CWS_Bill_To_Account__c) != null && billingAccounts.get(quote.CWS_Bill_To_Account__c).CWS_Payment_Terms__c != null) {
                        if (billingAccounts.get(quote.CWS_Bill_To_Account__c).CWS_Payment_Terms__c != CWS_ConstantClass.Payment_Term_Due_Upon_Receipt) {
                            String accountPaymentTerm = billingAccounts.get(quote.CWS_Bill_To_Account__c).CWS_Payment_Terms__c;
                            String[] accountPTerm = accountPaymentTerm.split(' '); String accountterm = '';
                            if (accountPTerm.size() != null) {
                                accountterm = accountPTerm[1]; accountTermValue = Integer.valueOf(accountterm);
                            }
                        } else {
                            accountTermValue = 0;
                        }
                    }
                    if (quote.CWS_Original_Quote__c != null && originalQuotes.get(quote.CWS_Original_Quote__c).SBQQ__PaymentTerms__c != null) {
                        String originalQuotePaymentTerm = originalQuotes.get(quote.CWS_Original_Quote__c).SBQQ__PaymentTerms__c;
                        if (originalQuotes.get(quote.CWS_Original_Quote__c).SBQQ__PaymentTerms__c != CWS_ConstantClass.Payment_Term_Due_Upon_Receipt) {
                            String[] originalQuotePTerm = originalQuotePaymentTerm.split(' '); String strOriginalQuoteNumber = '';
                            if (originalQuotePTerm.size() != null) {
                                strOriginalQuoteNumber = originalQuotePTerm[1];
                                originalQuoteTermValue = Integer.valueOf(strOriginalQuoteNumber);
                            }
                        } else {
                            originalQuoteTermValue = 0;
                        }

                    }


                    if (quote.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Direct) {
                        quote.CWS_Approval_for_Payment_Term__c = quote.SBQQ__PaymentTerms__c;
                        approvelterm = quote.SBQQ__PaymentTerms__c;
                    } else if (quote.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel) {
                        if (billingAccounts.get(quote.CWS_Bill_To_Account__c).CWS_Is_Distributor__c == true) {
                            if (quoteTermValue > accountTermValue) {
                                quote.CWS_Approval_for_Payment_Term__c = quote.SBQQ__PaymentTerms__c;
                                approvelterm = quote.SBQQ__PaymentTerms__c;
                            } else {
                                quote.CWS_Approval_for_Payment_Term__c = '';
                            }
                        } else {
                            quote.CWS_Approval_for_Payment_Term__c = quote.SBQQ__PaymentTerms__c;
                            approvelterm = quote.SBQQ__PaymentTerms__c;
                        }

                    } else if (quote.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT) {

                        if (quoteTermValue > accountTermValue && quote.CWS_Approval_for_Payment_Term__c != CWS_ConstantClass.Payment_Term_Net_30) {
                            quote.CWS_Approval_for_Payment_Term__c = quote.SBQQ__PaymentTerms__c;
                            approvelterm = quote.SBQQ__PaymentTerms__c ;
                        } else {
                            quote.CWS_Approval_for_Payment_Term__c = '';
                        }

                    }

                    if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {
                        quote.CWS_Approval_for_Payment_Term__c = '';
                    } else if (quote.CWS_Original_Quote__c != null && (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS || quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) && (quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT || quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION ||
                            quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION)) {
                        if (quoteTermValue > accountTermValue) {
                            quote.CWS_Approval_for_Payment_Term__c = approvelterm;

                        } else {
                            quote.CWS_Approval_for_Payment_Term__c = '';
                        }
                    }
                }
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'SBQQ__Quote__c', 'CWS_QuoteTriggerHelper', 'updatePaymentTermForApproval', '', null, null, 'beforeUpdate', null);

        }

    }

    */
}