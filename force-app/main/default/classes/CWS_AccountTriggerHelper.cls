/*Class Name: CWS_AccountTriggerHelpher
*Description: Helper Class for CWS_AccountTriggerHandler
*Created By: Ankit
*Created On: 4/7/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                  4/7/2020        BED-5150     Default Account currency from billing country
*Sudhir Moturu          4/29/2020       BED-1009     afterUpdate method to Update opportunities to closed lost if the account is changed to restricted
*Manoj Kumar            05/05/2020      BED-847      Before Update validating Restricted fields are not edited by non admins.   
*Sudhir Moturu          05/27/2020      BED-5168     afterUpdate method to Update opportunities to closed lost if the account is changed to restricted
*Sudhir Moturu          10/27/2020                              Changed callout from Future to Queueable
*Jeff Cochran           11/27/2020      14164768     Added lines 411-414
*Carl Shahan            09/10/2021       OBD-224     Added isFuture and isQueueable line ~419 to prevent --too many queueable jobs added to the queue 2-- error 
*/
public class CWS_AccountTriggerHelper {

    /*
    * Method name  : beforeInsertandUpdate
    * Description  : Use this method to write the before insert logic
    * Parameter    : List of new Account.
    * Return Type  : None
    * Developer    : Ankit
    */
    public static String currentUserProfile = null;//BED-847
    public static list<Id> manageAccIds = new list<Id>();//9325
    public static void beforeInsertandUpdate(list<SObject> NewSObjectRecs, map<id,SObject> mapOfOldSObjectRecs){    
        list<Id> manageAccIdsSync = new list<Id>();
        try{
            List<Account> actList = new List<Account>();
            list<Account> NewRecs = (list<Account>) NewSObjectRecs;
            map<Id,Account> mapOfNewRecs = new map<Id,Account>();//BED-847
            map<Id,Account> mapOfOldRecs = (map<Id,Account>) mapOfOldSObjectRecs;
            currentUserProfile = getCurrentUserProfile();
            string fieldName ='';
            integer queryLimit = 0;
            if(Label.CWS_Custom_Metedata_Query_Limit != null){
                queryLimit = Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);
            }
            // 874 : Get Country, State, Zip Code driven Territory, Region Mapping
            map<String, CWS_Country_Territory_Region_Mapping__mdt> terRegMap = CWS_TerritoryRegionHelper.getTerritoryRegion();
            string key;       
            
            map<string,string> mapOfAccCurrency = new map<string,string>();
            //Querying all countries data at once as the record count is less this will 
            //help in reducing the loops to get the country to query
            if(queryLimit != null){
                for(CWS_Account_Currency__mdt actCurr: [Select label,DeveloperName 
                                                                from 
                                                                CWS_Account_Currency__mdt LIMIT : queryLimit]){
                    mapOfAccCurrency.put(actCurr.DeveloperName,actCurr.label);
                }
            }
            //This if block lets business logic run on before update logic
            if(mapOfOldRecs != null){
                Set<Id> restrFldsAccIds = new Set<Id>();//BED-847
                Map<id,SBQQ__Quote__c>MapAccQuotes=new Map<id,SBQQ__Quote__c>();
                Set<id>setAccIds=new set<id>();
                Account oldAcc;
                Set<id> accIds=new set<id>(); // BED-12943
                Set<id> activeAccIds=new set<id>(); // BED-12943
                for(Account acc : newRecs)
                {   
                    if(mapOfOldRecs.get(acc.id)!=null){
                        oldAcc=mapOfOldRecs.get(acc.id);
                    }
                    if(acc.CWS_BA_Agreement_Status__c!=oldAcc.CWS_BA_Agreement_Status__c || acc.CWS_MSA_Agreement_Status__c!=oldAcc.CWS_MSA_Agreement_Status__c || acc.CWS_NDA_Agreement_Status__c!=oldAcc.CWS_NDA_Agreement_Status__c){
                        setAccids.add(acc.id);
                    }
                    //BED-12943
                    if(acc.CurrencyIsoCode != oldAcc.CurrencyIsoCode ){
                        accIds.add(acc.Id);
                    }
                    //BED-13010
                    if(acc.Industry != null &&  acc.CWS_Sub_Industry__c ==null){
                        acc.CWS_Sub_Industry__c = 'N/A';
                    }//BED-13010
                     //Start BED - 9325
                    if(acc.CWS_Manage_Company_Rec_Id__c!=null){
                        for(Schema.FieldSetMember fld :SObjectType.Account.FieldSets.CWS_AccountManageIntegration.getFields()){
                            fieldName=fld.getFieldPath();
                            if(acc.get(fieldName) != mapOfOldRecs.get(acc.id).get(fieldName)
                            || (acc.CWS_Manage_Integration_Sync_Status__c!=mapOfOldRecs.get(acc.Id).CWS_Manage_Integration_Sync_Status__c
                                && acc.CWS_Manage_Integration_Sync_Status__c==CWS_ConstantClass.INT_STATUS_READY)){
                                acc.CWS_Manage_Integration_Sync_Status__c=CWS_ConstantClass.INT_STATUS_READY;
                                    system.debug('-----PPP--'+acc.Id);
                                manageAccIds.add(acc.Id);
                                manageAccIdsSync.add(acc.Id);
                                break;
                            }
                        }
                    }
                    // End BED 9325
                }
                //BED-12943 start
                //14027677 - Ability to update currency/legal entity on accounts
                if(!accIds.isEmpty()){
                   for(account acc : [select id,(select id from contracts where CWS_Status__c =: CWS_ConstantClass.ACCOUNT_STATUS_ACTIVE) from Account where Id IN : accIds]){
                        if(acc.contracts!=null && acc.contracts.size()>0 
                                            && currentUserProfile != CWS_ConstantClass.ContractAdminProfile 
                                            && currentUserProfile != CWS_ConstantClass.SysAdminProfile){
                            activeAccIds.add(acc.Id);
                        }
                    
                        /*if((acc.contracts == null || acc.contracts.size()==0) && currentUserProfile==CWS_ConstantClass.SysAdminProfile){
                            accIds.remove(acc.id);
                        }*/
                    }
                    
                }
                //BED-12943 End 
                List<SBQQ__Quote__c> lstQuotes=new List<SBQQ__Quote__c>();
                if(!setAccids.isEmpty()){
                lstQuotes = [select id,SBQQ__Account__c,SBQQ__Status__c from SBQQ__Quote__c where SBQQ__Status__c =:CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG AND SBQQ__Account__c in:setAccids];
                }
                if(!lstQuotes.isEmpty()){
                for(SBQQ__Quote__c Quotes : lstQuotes){
                        if(!MapAccQuotes.Containskey(Quotes.SBQQ__Account__c)){
                            MapAccQuotes.put(Quotes.SBQQ__Account__c,Quotes);
                        }
                    }
                }
                for(Account acc : NewRecs){
                      Account oldAct =   mapOfOldRecs.get(acc.id);
                      //BED-5581
                      if(acc.CWS_Minimum_Commit_Amount__c != null && 
                         acc.CWS_Minimum_Commit_Amount__c != oldAct.CWS_Minimum_Commit_Amount__c){
                          acc.CWS_Min_Commit_Sync_Status__c = CWS_ConstantClass.INT_MIN_COM_STATUS;
                      }
                      //BED-5581
                      
                     //BED-8597
                     if(acc.CWS_Is_IIT_Reseller__c!=oldAct.CWS_Is_IIT_Reseller__c && acc.CWS_Is_IIT_Reseller__c == false && oldAct.CWS_Authorized_Reseller__c!=null){
                        acc.CWS_Authorized_Reseller__c = null;
                     }
                     if (acc.CWS_Authorized_Reseller__c!=oldAct.CWS_Authorized_Reseller__c && acc.CWS_Authorized_Reseller__c!=null && !acc.CWS_Is_IIT_Reseller__c){
                        acc.CWS_Is_IIT_Reseller__c = true;
                     } 
                     if(acc.CWS_Partner_Type__c != oldAct.CWS_Partner_Type__c || acc.CWS_Is_Partner__c != oldAct.CWS_Is_Partner__c || acc.CWS_Is_Distributor__c!= oldAct.CWS_Is_Distributor__c || acc.CWS_Is_IIT_Reseller__c != oldAct.CWS_Is_IIT_Reseller__c ) { 
                        actList.add(acc);   
                     }  // END of //BED-8597
                     //BED-5545 Start
                     if(acc.CWS_Is_Partner__c != oldAct.CWS_Is_Partner__c  ) { 
                        if(acc.CWS_Is_Partner__c == true){
                            acc.CWS_Partner_Type__c ='';
                        }
                        else{
                            acc.CWS_Partner_Type__c = CWS_ConstantClass.FORMER_PARTNER_STATUS;
                        }
                    }//BED-5545 END                            
                     mapOfNewRecs.put(acc.Id, acc);//BED-847
                    //Start of BED-163 - Changes to change the record type of Account whenever review status changes
                    if(((acc.CWS_Account_Review_Status__c != mapOfOldRecs.get(acc.id).CWS_Account_Review_Status__c) && acc.CWS_Account_Review_Status__c != null)){
                        if(acc.CWS_Account_Review_Status__c == CWS_ConstantClass.ACCOUNT_STATUS_REVIEW){
                            acc.recordTypeId = CWS_ConstantClass.ACCOUNT_RT_REVIEW;
                        }else if(acc.CWS_Account_Review_Status__c == CWS_ConstantClass.ACCOUNT_STATUS_ACTIVE){
                            acc.recordTypeId = CWS_ConstantClass.ACCOUNT_RT_ACTIVE;
                        }else if(acc.CWS_Account_Review_Status__c == CWS_ConstantClass.ACCOUNT_STATUS_PROSPECT){
                            acc.recordTypeId = CWS_ConstantClass.ACCOUNT_RT_PROSPECT;
                        }
                    }
                    //End of BED-163
                    // BED - 12943 accMap will only be populated if currency is changed by Admin and there is Active contract.
                    if(acc.CurrencyIsoCode!=mapOfOldRecs.get(acc.id).CurrencyIsoCode && activeAccIds.size()>0 && activeAccIds.contains(acc.id)){
                        acc.addError(Label.CWS_Account_Currency_Error);
                    }
                    //14027677 - Ability to update currency/legal entity on accounts
                    if((acc.billingcountryCode != null && acc.billingcountryCode != mapOfOldRecs.get(acc.id).billingcountryCode)
                        ||(acc.CurrencyIsoCode != null && accIds.contains(acc.id) && acc.CurrencyIsoCode != mapOfOldRecs.get(acc.id).CurrencyIsoCode)
                            && currentUserProfile != CWS_ConstantClass.ContractAdminProfile 
                            && currentUserProfile != CWS_ConstantClass.SysAdminProfile ){
                        if(mapOfAccCurrency.size()>0 && mapOfAccCurrency.containsKey(acc.billingcountryCode)){
                            acc.CurrencyIsoCode = mapOfAccCurrency.get(acc.billingcountryCode);
                        }
                    }

                     // Start BED - 496 - INT045: Account from Salesforce to NetSuite
                    if(acc.CWS_Integration_Status__c == CWS_ConstantClass.INT_STATUS_SYNCED ||
                            acc.CWS_Integration_Status__c == CWS_ConstantClass.INT_STATUS_ERROR){
                        for(Schema.FieldSetMember fld :SObjectType.Account.FieldSets.CWS_Account_Integration_Sync_Fields.getFields()){
                            fieldName=fld.getFieldPath();
                            if(acc.get(fieldName) != mapOfOldRecs.get(acc.id).get(fieldName)){
                               acc.CWS_Integration_Status__c=CWS_ConstantClass.INT_STATUS_READY;
                               break;
                            }
                        }
                    }
                    // End BED - 496
                    //Bed-847 start
                    for(Schema.FieldSetMember fld :SObjectType.Account.FieldSets.CWS_Restricted_Account_Fields.getFields()){
                        fieldName = fld.getFieldPath();
                        if(acc.get(fieldName) != mapOfOldRecs.get(acc.id).get(fieldName)){                            
                            if(!acc.CWS_Is_Partner__c){
                                restrFldsAccIds.add(acc.Id);
                            }
                            else{
                                if(!isAdminProfile(getCurrentUserProfile(),'CWS_Is_After_Partner__c')){//14000462
                                    acc.addError(Label.CWS_Acc_Restr_Fields_Error);    
                                }
                            }                              
                            break;
                        }
                    }
                    //Bed-847 End     
                    
                    //Start 874 : Populate Region and Territory
                    if((acc.billingcountryCode!=Null && acc.billingcountryCode!=mapOfOldRecs.get(acc.id).billingcountryCode)
                            || acc.billingStateCode!=mapOfOldRecs.get(acc.id).billingStateCode
                            || acc.BillingPostalCode!=mapOfOldRecs.get(acc.id).BillingPostalCode){
                        key=CWS_TerritoryRegionHelper.getTerrRegionKey(acc.billingcountryCode,acc.billingStateCode,acc.BillingPostalCode);
                        if( terRegMap.get(key) != Null){
                            acc.CWS_Region__c =terRegMap.get(key).CWS_Region__c;
                            acc.CWS_Territory__c =terRegMap.get(key).CWS_Territory__c;
                            acc.CWS_No_Territory_Mapping_Found__c=false;
                        }
                        else{
                            acc.CWS_Region__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Region__c;
                            acc.CWS_Territory__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Territory__c;
                            acc.CWS_No_Territory_Mapping_Found__c=True;
                        }
                    }
                    //End 874
                    //BED-8949-Start
                    if((MapAccQuotes.containsKey(acc.id) && MapAccQuotes.get(acc.id) != null) && ((acc.CWS_MSA_Agreement__c == null || (acc.CWS_MSA_Agreement__c!=null && oldAct.CWS_MSA_Agreement_Status__c !=null && (acc.CWS_MSA_Agreement_Status__c != null && (acc.CWS_MSA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || acc.CWS_MSA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT || acc.CWS_MSA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED))))&&
                    (acc.CWS_NDA_Agreement__c == null || (acc.CWS_NDA_Agreement__c!=null && acc.CWS_NDA_Agreement_Status__c!=null && oldAct.CWS_NDA_Agreement_Status__c!=null && (acc.CWS_NDA_Agreement_Status__c != null && (acc.CWS_NDA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || acc.CWS_NDA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT|| acc.CWS_NDA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED))))&&
                    (acc.CWS_BA_Agreement__c == null || (acc.CWS_BA_Agreement__c!=null && acc.CWS_BA_Agreement_Status__c!=null && oldAct.CWS_BA_Agreement_Status__c!=null && (acc.CWS_BA_Agreement_Status__c!=null && (acc.CWS_BA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || acc.CWS_BA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT || acc.CWS_BA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED)))))){
                        acc.CWS_AgreementStatus__c=true;
                    }
                    else if((acc.CWS_MSA_Agreement__c != null && (acc.CWS_MSA_Agreement_Status__c!=null && oldAct.CWS_MSA_Agreement_Status__c!=null && (acc.CWS_MSA_Agreement_Status__c != null && (acc.CWS_MSA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || acc.CWS_MSA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT || acc.CWS_MSA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED))))||
                    (acc.CWS_NDA_Agreement__c != null && (acc.CWS_NDA_Agreement_Status__c!=null && oldAct.CWS_NDA_Agreement_Status__c != null && (acc.CWS_NDA_Agreement_Status__c != null && (acc.CWS_NDA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || acc.CWS_NDA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT || acc.CWS_NDA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED))))||
                    (acc.CWS_BA_Agreement__c != null && (acc.CWS_BA_Agreement_Status__c!=null && oldAct.CWS_BA_Agreement_Status__c != null && (acc.CWS_BA_Agreement_Status__c != null && (acc.CWS_BA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || acc.CWS_BA_Agreement_Status__c != CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT || acc.CWS_BA_Agreement_Status__c != CWS_ConstantClass.ORDER_STATUS_CANCELLED))))){
                        acc.CWS_AgreementStatus__c=false;
                    }
                    //BED-8949-End
                }
                //Bed-847 start
                Set<Id> restAccIds = new Set<Id>();
                if(!restrFldsAccIds.isEmpty() && !isAdminProfile(getCurrentUserProfile(),'CWS_Is_Before_partner__c')){ //14000462
                    for(AggregateResult ar: [SELECT SBQQ__Account__c FROM SBQQ__Quote__c WHERE SBQQ__Primary__c = TRUE 
                                               AND (SBQQ__Status__c =: CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG OR
                                                    SBQQ__Status__c =: CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN )                                                                                             
                                               AND SBQQ__Account__c IN:restrFldsAccIds Group By SBQQ__Account__c])
                    {                         
                        mapOfNewRecs.get((ID)ar.get('SBQQ__Account__c')).addError(Label.CWS_Acc_Restr_Fields_Error);
                    }                                                                        
                }                
            //BED-8597 BEfore update scenario
            if(actList.size()>0){
                validatePartnerFields(actList);
            }//Bed-8597
            
            if(manageAccIdsSync.size()>1){
                system.debug('----000TT2--'+manageAccIdsSync.size());
                CWS_ManageIntegrationCalloutBatch obj = new CWS_ManageIntegrationCalloutBatch(manageAccIdsSync);
                Database.executeBatch(obj);
            }
            //Bed-847 End                
            //This else block lets business logic run on before insert logic    
            }else{
                set<string> setOfCountry = new set<string>();
                for(Account acc : NewRecs){
                    
                    //BED - 8597
                    if (acc.CWS_Authorized_Reseller__c!=null){
                        acc.CWS_Is_IIT_Reseller__c = true;
                     }//End of 8597
                     
                    //BED-6263
                    acc.SBQQ__RenewalPricingMethod__c='List';           
                    if(acc.billingcountryCode != null && mapOfAccCurrency.size()>0 && mapOfAccCurrency.containsKey(acc.billingcountryCode)){
                        acc.CurrencyIsoCode = mapOfAccCurrency.get(acc.billingcountryCode);
                    }
                    //BED-13010
                    if(acc.Industry != null &&  acc.CWS_Sub_Industry__c == null){
                        acc.CWS_Sub_Industry__c = 'N/A';
                    }//BED-13010
                    //Start 874 : Populate Region and Territory
                    if(acc.billingcountryCode!=Null){
                        key=CWS_TerritoryRegionHelper.getTerrRegionKey(acc.billingcountryCode,acc.billingStateCode,acc.billingPostalCode);
                        if( terRegMap.get(key) != Null){
                            acc.CWS_Region__c =terRegMap.get(key).CWS_Region__c;
                            acc.CWS_Territory__c =terRegMap.get(key).CWS_Territory__c;
                            acc.CWS_No_Territory_Mapping_Found__c=false;
                        }
                        else{
                            acc.CWS_Region__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Region__c;
                            acc.CWS_Territory__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Territory__c;
                            acc.CWS_No_Territory_Mapping_Found__c=True;
                        }
                    }
                    //End 874
                }
                validatePartnerFields(NewRecs);
            }
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Account' , 'CWS_AccountTriggerHelpher', 'BeforeInserMethod' , '', null, null , 'Beforeinsert' , null);
        }
    }

    /*
    * Method name  : afterUpdate
    * Description  : Move all opportunities to closed lost if the account restriction status is moved to non transactional
    * Parameter    : mapNewItems,mapOldItems.
    * Return Type  : None
    * Developer    : Sudhir Moturu
    */
    public static void afterUpdate(Map<Id, Account> mapNewItems, Map<Id, Account> mapOldItems){
        try{
            System.debug('msDebug:Insideafterupdate');
            List<Database.SaveResult> srList;
            //To store accountids which are moved to restricted
            set<Id> setAcctIds = new set<Id>();
            Set<Id> setDelinPaymtAcctIds = new Set<Id>();
            Map<Id,Opportunity> mapOppToUpdate = new Map<Id,Opportunity>();//BED-5168 map to update opportunities
            List<SBQQ__Quote__c> recallQuotes = new List<SBQQ__Quote__c>();   
            List<SBQQ__Quote__c> updQuotes = new List<SBQQ__Quote__c>();
            List<SBQQ__QuoteDocument__c> qDocs = new List<SBQQ__QuoteDocument__c>();
             
            
            //Retrieve all accounts which are moved to restricted in account restriction status
            for(Account objAcct: mapNewItems.values()){
                if(objAcct.CWS_Account_Restriction_Status__c != mapOldItems.get(objAcct.Id).CWS_Account_Restriction_Status__c 
                    && objAcct.CWS_Account_Restriction_Status__c != Null
                    && objAcct.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_NORESTRICTION
                    && objAcct.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT
                    && objAcct.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_PAYMENTWORKOUT){
                        setAcctIds.add(objAcct.Id);        
                }

                // BED-8645
                if(objAcct.CWS_Account_Restriction_Status__c != mapOldItems.get(objAcct.Id).CWS_Account_Restriction_Status__c 
                    && (objAcct.CWS_Account_Restriction_Status__c == CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT
                    || objAcct.CWS_Account_Restriction_Status__c == CWS_ConstantClass.ACCOUNT_RSTATUS_PAYMENTWORKOUT)){
                        setDelinPaymtAcctIds.add(objAcct.Id);        
                }
                // BED-8645 end
            }
            
            System.debug('msDebug:setAcctIds:'+setAcctIds);
            if(setAcctIds.size()>0 || setDelinPaymtAcctIds.size()>0){
                //BED-5168 updated query to match the criteria
                for(Opportunity objOpp: [Select id,CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c,CWS_Bill_To_Account__r.CWS_Is_Distributor__c,Type,IsClosed,CWS_Account_Restriction_Approved__c,SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.CWS_Quote_Type__c,SBQQ__PrimaryQuote__r.ApprovalStatus__c,
                                        AccountId,CWS_Bill_To_Account__c,StageName,CWS_Lost_Reason__c,CWS_Lost_Reason_Detail__c,CWS_Route_to_Market__c,
                                        (select id,SBQQ__SignatureStatus__c,SBQQDS__EnvelopeId__c,SBQQ__PrimaryContactId__c,SBQQ__Quote__c,SBQQ__Quote__r.OwnerId from SBQQ__R00N700000029COgEAM__r where SBQQ__Quote__r.SBQQ__Primary__c=true AND (CWS_Offline_Signature_Status__c=:CWS_ConstantClass.QDOC_SIG_SENT OR SBQQ__SignatureStatus__c=:CWS_ConstantClass.QDOC_SIG_SENT OR SBQQ__SignatureStatus__c=:CWS_ConstantClass.QDOC_SIG_DELIVERED)) from Opportunity 
                                    where (CWS_Bill_To_Account__c IN :setAcctIds OR CWS_Bill_To_Account__c IN :setDelinPaymtAcctIds) AND
                                    SBQQ__PrimaryQuote__r.CWS_Transaction_Reason__c<>:CWS_ConstantClass.TRANSACTION_REASON_TERMINATION AND 
                                    (CWS_Bill_To_Account__r.CWS_Is_Distributor__c = FALSE OR (CWS_Bill_To_Account__r.CWS_Is_Distributor__c = TRUE AND CWS_Route_to_Market__c <> :CWS_ConstantClass.RTM_Value_IIT AND CWS_Route_to_Market__c <> :CWS_ConstantClass.RTM_Value_Channel))]){
                    //Checking the conditions if in future the query is modified to get more opportunities
                    //BED-5168 Update opportunity to closed lost, if not a renewal opportunity and bill to account restriction status is not credit hold or shut off and bill to account is distributor and RTM is IIT or Channel
                    if(setAcctIds.contains(objOpp.CWS_Bill_To_Account__c) 
                        && !(objOpp.Type == CWS_ConstantClass.Opportunity_Type_Renewal && (objOpp.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c == CWS_ConstantClass.ACCOUNT_RSTATUS_CREDITHOLD || objOpp.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c == CWS_ConstantClass.ACCOUNT_RSTATUS_SHUTOFF))
                        && !(objOpp.CWS_Bill_To_Account__r.CWS_Is_Distributor__c == True && (objOpp.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT || objOpp.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel))
                        && objOpp.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c != Null
                        && objOpp.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_NORESTRICTION
                        && objOpp.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_DELINQUENT
                        && objOpp.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c != CWS_ConstantClass.ACCOUNT_RSTATUS_PAYMENTWORKOUT
                        && objOpp.StageName != CWS_ConstantClass.OpportunityClosedWon_Stage
                        && objOpp.StageName != CWS_ConstantClass.OpportunityClosedLose_Stage){

                            if(!mapOppToUpdate.containsKey(objOpp.Id)){
                                mapOppToUpdate.put(objOpp.Id,objOpp);
                            }
                            mapOppToUpdate.get(objOpp.Id).stageName = CWS_ConstantClass.OpportunityClosedLose_Stage;             
                            mapOppToUpdate.get(objOpp.Id).CWS_Lost_Reason__c = CWS_ConstantClass.OPPORTUNITY_LOST_ACCOUNTRESTRICTED;                            
                            if(objOpp.SBQQ__PrimaryQuote__r!=Null){
                                objOpp.SBQQ__PrimaryQuote__r.CWS_OF_Expiration_Reason__c = CWS_ConstantClass.QUOTE_OF_EXPIR_REASON;
                                updQuotes.add(objOpp.SBQQ__PrimaryQuote__r);
                                qDocs.addAll(objOpp.SBQQ__R00N700000029COgEAM__r);
                            }
                    }

                    //BED-8645 starts
                    if(objOpp.SBQQ__PrimaryQuote__r!=Null){
                        if (setDelinPaymtAcctIds.contains(objOpp.CWS_Bill_To_Account__c) && 
                            objOpp.SBQQ__PrimaryQuote__r.ApprovalStatus__c == CWS_ConstantClass.QUOTE_Approval_Status_Pending){
                            recallQuotes.add(objOpp.SBQQ__PrimaryQuote__r);
                        }
                        if (setDelinPaymtAcctIds.contains(objOpp.CWS_Bill_To_Account__c) && !objOpp.IsClosed &&
                            objOpp.SBQQ__PrimaryQuote__r.ApprovalStatus__c == CWS_ConstantClass.QUOTE_Approval_Status_Approved){

                            objOpp.SBQQ__PrimaryQuote__r.CWS_OF_Expiration_Reason__c = CWS_ConstantClass.QUOTE_OF_EXPIR_REASON;
                            updQuotes.add(objOpp.SBQQ__PrimaryQuote__r);
                            qDocs.addAll(objOpp.SBQQ__R00N700000029COgEAM__r);
                        }
                    }
                    //BED-8645 ends
                }  
            }
            System.debug('msDebug:mapOppToUpdate::'+mapOppToUpdate);
            System.debug('msDebug:recallQuotes::'+recallQuotes);
            System.debug('msDebug:updQuotes::'+updQuotes);
            //Update opportunites to closed lost for the non transactional accounts
            if(mapOppToUpdate.size()>0 || updQuotes.size()>0){
                List<sobject> dmlObjList = new List<sobject>();
                dmlObjList.addAll(mapOppToUpdate.values());
                dmlObjList.addAll(updQuotes);
                srList = Database.update(dmlObjList);  
                CWS_ExceptionHandler.logDMLSaveResults(srList, 'CWS_AccountTriggerHelpher' , 'afterUpdate','Update Quote & Opportunities', null , null );
            }
            //BED-8645 starts
            if(recallQuotes.size()>0){
                for (SBQQ__Quote__c quote : recallQuotes) {
                    SBAA.ApprovalAPI.recall(quote.id, SBAA__Approval__c.CWS_Quote__c);
                }  
            }
            if (!qDocs.isEmpty()) {
                for (SBQQ__QuoteDocument__c qdoc : qDocs) {
                    if (qdoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_SENT || qdoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_DELIVERED) {
                        qdoc.SBQQDS__VoidedReason__c = CWS_ConstantClass.QUOTE_OF_EXPIR_REASON;   
                    }
                }
                System.enqueueJob(new CWS_QueueableRevokeQuoteDoc(qDocs));
                CWS_CommonUtility.sendOFCancellationEmail(qDocs);
            }
               system.debug('----000TT0--'+manageAccIds.size());
            // BED-8645 ends
             // BED 9325 
            if(manageAccIds.size()==1 && !System.isFuture() && !System.isQueueable()){                
                system.debug('----000TT1--'+manageAccIds.size());
                callManageIntegration(manageAccIds);
            }
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Account' , 'CWS_AccountTriggerHelpher', 'afterUpdate' , '', null, null , 'AfterInsert' , null);
        }
    }
    /*
    *Description: Calling Account Manage Integration
    *Developer: abhishek
    *Story : BED-9325
    */
    public static void callManageIntegration(List<Id> accIds){
        ID jobID = System.enqueueJob(new CWS_ManageIntegrationCallout(accIds,CWS_ConstantClass.CALLOUT_MANAGE_ACCOUNT));
    }
    /*
    * Method name  : getCurrentUserProfile- BED-847
    * Description  : Fetches Current Logged in user profile
    * Parameter    : 
    * Return Type  : String
    * Developer    : Manoj Kumar
    */
    public static String getCurrentUserProfile(){
        if(currentUserProfile == null){
            currentUserProfile = [SELECT Name from Profile WHERE Id=: userinfo.getProfileId() LIMIT 1].Name;
        }        
        return currentUserProfile;
    }
    
    /*
    * Method name  : getCurrentUserProfile- BED-847
    * Description  : Method to check if the logged in user profile in Metadata List.
    * Parameter    : String
    * Return Type  : Bolean
    * Developer    : Manoj Kumar
    */
    public static Boolean isAdminProfile(String profileName,String partnerStatus){
        String  queryStr = 'SELECT Id, Profile__c FROM CWS_Acc_Admin_Profiles__mdt WHERE Profile__c =\''+profileName+'\' AND '+ partnerStatus + '=True';
        List<CWS_Acc_Admin_Profiles__mdt> AdmnProfilesList = database.query(queryStr);//14000462
        //checking logged in profile is non admin.
        if(AdmnProfilesList.isEmpty()){
            return false;
        }
        return true;
    }
    
   /*
    * Method name  : validatePartnerFields- BED-8597
    * Description  : Method to validate partner type on the basis of account type
    * Parameter    : List of Account
    * Return Type  : void
    * Developer    : Aditya
    */ 
    public static void validatePartnerFields(List<Account> acctlist){
        for(Account act:acctlist){
            if((act.CWS_Is_Partner__c == false && act.CWS_Is_Distributor__c==false && act.CWS_Is_IIT_Reseller__c == false)){
                if(act.CWS_Partner_Type__c!='Former Partner' && act.CWS_Partner_Type__c!=null){
                    act.addError(System.Label.CWS_nonActivePartner);
                }
            }
            if(act.CWS_Is_Distributor__c== true && act.CWS_Is_IIT_Reseller__c == true ){
                act.addError(System.Label.CWS_distributir_reseller);
            }
            /*
            if(act.CWS_Is_Distributor__c== true && act.CWS_Authorized_Reseller__c != null){
                act.addError('Account cannot be both Distributor and Authorized Reseller at the same time');
            }*/
        }
    }
}