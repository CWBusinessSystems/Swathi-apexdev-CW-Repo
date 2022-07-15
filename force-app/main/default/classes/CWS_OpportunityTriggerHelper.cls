/*Class Name: CWS_OpportunityTriggerHelper
*Description: Helper Class for BeforeInsert instance of CWS_OpportunityTriggerHelper
*Created By: Nirmal
*Created On: 4/6/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nirmal                 4/6/2020        BED-3177            Currency default based on account
*Aditya                 4/23/2020       BED-937             ReadOnly RecordType assignment when Opportunity is closed
*Aditya                 4/30/2020       BED-5159            Currency default based on Bill to Account and Sales Contract
*Sudhir Moturu          4/28/2020       BED-1009            Update stage to closed lost if opportunity is rejected twice
*Aditya                 5/5/2020        BED-271             Update End customer account to Partner account when Opportunity is closed won
*Aditya                 5/11/2020       BED-7880            Update Quotes as Inactive when Opportunity is close Lost
*Aditya                 5/15/2020       BED-910             Renewal and Amendment Type and Record type default
*Ankit                  5/24/2020       BED-6479            Populating bill to on new lookup to share records with channel Reps
*Ankit                  5/28/2020       BED-9115            Populate Disty Comm Group on opportunity
*Aditya                 5/28/2020       BED-9078            Default Bill to account for New Business when Paid parent is true
*Aditya                 6/4/2020        BED-208             Default CW Standard Pricebook for all opportunities
*Ankit                  6/10/2020       BED-9124            Populate Bill to owner Email on opportunity
*Aditya                 6/12/2020       BED-9469            Renewal with change Opportunity manual creation
*Sudhir Moturu          6/17/2020       BED-8762            Update trial records if the opportunity is closed won
*Ankit                  6/17/2020       BED-8615            Default RTM when Opp is master
*Sudhir Moturu          6/24/2020       BED-64              Default stage for renewal and amendment opportunities
*Sudhir Moturu          6/29/2020       BED-118             Fast track opportunity error logic
*Nida                   8/10/2020       BED-13036           Default Close Date to Creation Dt + 1 month for amendment Oppotunities
*Manoj                  8/20/2020       BED-13043           Only event sponsor group members should be able to change currency on new business,renewal,amendment opptys.
*Manoj                  8/25/2020       BED-13313           For commission only opportunities Currency should not get defaulted by sold to account currency.
*Sudhir Moturu          11/11/2020      14080320            Skipped closedate logic for closed opp
*Mahak Bansal           06/06/2021      14713243            Send opportunity lost email to opportunityteammembers - Also Code optimised - It was failing for SOQL(101) Error
*Ad Victoriam Solutions 02/14/2022      N/A                 Updated for compatibility with new Opportunity StageNames.
*Mahak Bansal           03/28/2022      OBD-2303            Users should be able to update the close date on amendment opportunities
*/

public class CWS_OpportunityTriggerHelper {
    
    //BED-208
    static Pricebook2 cwsPriceBook;

    /*
   * Method name  : beforeInsertMethod
   * Parameter    : List of new Quotes.
   * Return Type  : None
   * Developer    : Nirmal
   */

    /*
    TEST COMMENT 2
     */
    public static void beforeInsertMethod(List<Opportunity> lstNew){

        system.debug('=== Before Insert - helper');
        
         system.debug('===lstNew: '+lstNew);
        
        List<Id> contractList = new List<Id>();
        List<Id> accountList = new List<Id>();
        Map<Id, Contract> contractMap = new Map<Id, Contract>();
        List<Account> endCustmerAcctList = new List<Account>();
        Map<Id, Account> accountMap =  new Map<Id, Account>();
        map<string,string> currLegalEntityMap = getLegalEntity();
        Set<Id> soldtoAccountIds=new Set<Id>();
        List<Database.SaveResult> accUpdate;
        Integer qtyLimit = Integer.valueOf(System.Label.CWS_Custom_Metedata_Query_Limit);
        Map<String, Decimal> exchangeRate = new Map<String, Decimal>();
        Id loggedUser=userInfo.getUserId();
        Id loggedUserprofileid=userInfo.getProfileId();
        Profile profileObj;
        Map<Id,Set<String>> userRegion= new Map<Id,Set<String>>();
        List<Opportunity> rwcOppty = new List<Opportunity>();
        Boolean bFastTrackOpp = false;//BED-118 flag to enable if fast track opportunities are modified
        Boolean bFastTrackGroup = false;//BED-118 flag to enable if user present in fast track group
        List<GroupMember> lstGroupMember = new List<GroupMember>();//BED-118 stores group details of user
         Map<Id,Contract> conMap = new Map<Id,Contract>();
          Map<Id,Contract> conAccMap = new Map<Id,Contract>();
          Set<Id> acctList = new Set<Id>();
        //Map<id,User> MapOwnerIdsAmendment=new Map<id,User>();
        //set<id> setOwnerIds=new set<id>();
        
        try{
        for(Opportunity opp:lstNew){
                    
            
            //Start BED-8615
            if(opp.CWS_Master__c){
                opp.CWS_Route_to_Market__c = CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct;
                if(opp.CWS_Ramp_Options__c != null && opp.CWS_Period_of_Fixed_Usage_Commit_Ramp__c==Null){
                    opp.CWS_Period_of_Fixed_Usage_Commit_Ramp__c = 3;
                }
            }
            //End BED-8615
            opp.CWS_Snapline_Reset_Date__c = date.today().addmonths(Integer.valueOf(System.Label.CWS_Snapline_Reset_Date));
             //BED - 289 Billto/Shipto Account Defaulting Based on Sold to Account (End Customer)
            if(opp.AccountId !=null && opp.CWS_Bill_To_Account__c==Null && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION 
                    && (opp.CWS_Route_to_Market__c == CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct 
                        || opp.CWS_Route_to_Market__c == CWS_ConstantClass.OPPORTUNITY_RouteToMarket_IIT)){
                opp.CWS_Bill_To_Account__c=opp.AccountId;
                opp.CWS_Ship_To_Account__c = opp.AccountId;
            }
                // End BED -289
            //BED-3177 Adding the Ids of renewed contracts linked with the Opportunity to contractList.
           if(opp.SBQQ__RenewedContract__c != NULL){
               contractList.add(opp.SBQQ__RenewedContract__c);
           }
           
           //Adding the Owner Ids for Amendment Flow(BED-6254)
           //if(opp.SBQQ__AmendedContract__c!=null && opp.ownerId !=null){
               //setOwnerIds.add(opp.ownerid);
           //}

            
           system.debug('===opp.SBQQ__AmendedContract__c: '+opp.SBQQ__AmendedContract__c);

           //BED-3177 Adding the Ids of amended contracts linked with the Opportunity to contractList.
           if(opp.SBQQ__AmendedContract__c != NULL){
               contractList.add(opp.SBQQ__AmendedContract__c);
           }
           //BED-3177 Adding the Ids of bill to account linked with the Opportunity to AccountList.
           if(opp.CWS_Bill_To_Account__c!=NULL){
               accountList.add(opp.CWS_Bill_To_Account__c);
           }
           if(opp.AccountId!=null){
               soldtoAccountIds.add(opp.AccountId); 
           }
           if(opp.Type == CWS_ConstantClass.Opportunity_Type_RenewalWithChange){
               rwcOppty.add(opp);
           }
            //BED-8825
               if(opp.Accountid != null && opp.SBQQ__AmendedContract__c == null && opp.SBQQ__RenewedContract__c == null){
                    acctList.add(opp.AccountId);
                }
            //BED-118 fast track opp check
            if(!bFastTrackOpp && opp.CWS_Fast_Track__c){
                bFastTrackOpp=true;
            }
            //BED-487 Populating total forecast value(formula) on total forecast reporting field. 
            if(opp.CWS_Min_Commit_QR__c != null ){
                opp.CWS_Total_Forecast_For_Report__c = opp.CWS_Min_Commit_QR__c;
            }
            //Bed-487 End
        }
          //BED-8825
           if(acctList.size() > 0 ){
               conMap = new Map<Id,Contract> ([Select Id, Name, AccountId, CWS_Master__c,CWS_Status__c from
                                                Contract Where AccountId IN: acctList AND CWS_Master__c = True AND (CWS_Status__c = 'Active' OR CWS_Status__c = 'Inactive') Limit 100]);
           }
              for(Contract con : conMap.values()){
             conAccMap.put(con.AccountId,con);
         }  
        /*
        //BED-6254
            if(!setOwnerIds.isEmpty()){
                for(User Owner:[select id,CWS_Region__c,Profile.name from user where id IN:setOwnerIds])
                {
                        MapOwnerIdsAmendment.put(Owner.id,Owner);
                }
            }
        //BED-6254
        */
        
       //Start : BED-9115 create a map to get the Disty Comm Group value to insert     
       map<id,CWS_Distributor_Reseller__c> mapOfDistyResller = new map<id,CWS_Distributor_Reseller__c>();
       
       if(soldtoAccountIds.size() > 0 && accountList.size() > 0){
         for(CWS_Distributor_Reseller__c disty : [Select id,CWS_Distributor_Community_Group__c,CWS_Distributor_ResellerAcc__c  
                                                                             from 
                                                                             CWS_Distributor_Reseller__c 
                                                                             where 
                                                                             CWS_Account__c IN: soldtoAccountIds AND CWS_Distributor_ResellerAcc__c IN: accountList
                                                                             AND CWS_Distributor_Community_Group__c != null AND CWS_Distributor_ResellerAcc__r.CWS_Is_Distributor__c = true]){
           mapOfDistyResller.put(disty.CWS_Distributor_ResellerAcc__c,disty);
         }
       }     
        //BED-9115
       
        //BED-208
        cwsPriceBook = CWS_CommonUtility.queryCWPriceBook();
           

        // BED - 91 : Getting Currency Rate 
        for(CurrencyType exList : [Select ISOCode, ConversionRate, IsActive 
                                        from CurrencyType 
                                              where IsActive = true LIMIT : qtyLimit]){
                  exchangeRate.put(exList.ISOCode, exList.ConversionRate);
        }
            
        system.debug('===contractList.size(): '+contractList.size());
        // End BED 91 
        if(contractList.size()>0){
            contractMap = new Map<Id,Contract>([SELECT ID,CWS_Master__c , CurrencyIsoCode,CWS_Created_By_AMCont__c,EndDate,ContractNumber from Contract where ID in:ContractList]);
        	system.debug('contractMap - line 186: '+contractMap);
        }
   
        if(accountList.size()>0 || soldtoAccountIds.size()>0){
           accountMap = new Map<Id,Account>([SELECT Id, name, CurrencyISOCode, ownerId,owner.email,CWS_Is_Distributor__c, 
                                                    CWS_Paid_by_Parent__c, CWS_Is_Partner__c,CWS_Partner_Type__c,CWS_Is_IIT_Reseller__c ,CWS_Region__c,
                                                    CWS_Distributor_Logic_Exclusion__c,ParentId,Owner.ManagerId, owner.IsActive,owner.Manager.isActive,
                                                        (select id,CWS_Primary_Billing_Contact__c,CWS_Primary_Contact__c from contacts 
                                                           where CWS_Primary_Billing_Contact__c =True or CWS_Primary_Contact__c =true)
                                                    from Account where Id in:AccountList or id in : soldtoAccountIds]);
        }
        
        //BED-9469
            if(rwcOppty.size()>0){
                userRegion=CWS_CommonUtility.getGroupMemberRegion(new list<Id>{loggedUser});
                profileObj=[select Name from Profile where id=:loggedUserprofileid limit 1];
            }
        //BED-118 retrieve group of user is present in 
        //Query can be reused and condition can be modified
         if(bFastTrackOpp && loggedUser!=null && profileObj!=null 
            && profileObj.Name !=CWS_ConstantClass.SysAdminProfile){
            lstGroupMember = [select userorgroupid,group.DeveloperName from groupmember where group.DeveloperName =:CWS_ConstantClass.GroupnameFTQ and userorgroupid=:loggedUser];
            if(lstGroupMember.size()>0){
                for(groupmember objGrpMem: lstGroupMember){
                    if(objGrpMem.group.DeveloperName==CWS_ConstantClass.GroupnameFTQ){
                        bFastTrackGroup=true;
                        system.debug('===break');
                        break;
                    }
                }  
            } 
        }   
        for(Opportunity opp:lstNew) {
			
			system.debug('===second lstNew loop on Opp');    
            system.debug('===opp.CreatedDate: '+opp.CreatedDate); 
            
            Date currentDate = Date.today();
            
            //Start of BED-13036 / CWSALES-16   
            if(opp.SBQQ__AmendedContract__c != NULL && 
                opp.StageName != CWS_ConstantClass.OpportunityClosedWon_Stage && 
                opp.StageName != CWS_ConstantClass.OPPORTUNITY_STAGE_CLOSEDWONLEGACY && 
                opp.StageName != CWS_ConstantClass.OpportunityClosedLose_Stage && 
                (opp.CloseDate==currentDate 
                //Commented by Mahak Bansal,- OBD-2303 03/28/2022 
                //|| opp.closeDate< currentDate.addDays(Integer.valueOf(Label.CWS_DefaultOppCloseDate)))
            )){
                opp.CloseDate = currentDate.addDays(Integer.valueOf(Label.CWS_DefaultOppCloseDate));
            }//End of BED-13036 / CWSALES-16
            
             //BED-8825
            if(conAccMap.size()>0 && conAccMap.get(opp.AccountId) != null) {
               if(opp.Type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && opp.CWS_Master__c == false){
                  opp.CWS_Has_Master_Contract__c = true;
              }
                //START CR_RECOMMIT  
              if(opp.Type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && opp.CWS_Master__c == true && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL){
                  system.debug('add error line 235');
                  opp.addError(System.Label.CWS_Only_One_Master_Contract_Recommit);
              }
                 //END CR_RECOMMIT  
            }
            //BED-8825 End 
             // BED-9469 
                if(opp.Type == CWS_ConstantClass.Opportunity_Type_RenewalWithChange ){
                    if(!accountMap.isEmpty()){
                        if(userRegion.isEmpty() || (!userRegion.isEmpty() 
                                                    && userRegion.get(userinfo.getUserId())!=Null 
                                                      && !userRegion.get(userinfo.getUserId()).contains(accountMap.get(opp.AccountId).CWS_Region__c))){
                             if(profileObj.Name !=CWS_ConstantClass.SysAdminProfile 
                                    && profileObj.Name !=CWS_ConstantClass.ContractAdminProfile 
                                        && profileObj.Name !=CWS_ConstantClass.GlobalSalesOpsProfile){
                                system.debug('add error line 250');
                                opp.addError(Label.CWS_Region_for_Renewal_with_change_owner);
                             }
                        }
                        else{    //Start BED 568 
                            if(accountMap.containskey(opp.AccountId)){
                                opp.ownerId=accountMap.get(opp.AccountId).ownerId;
                             }  // End BED 568
                        }
                    }       
                }
                // End BED-9469
        
            //BED-9078
            if(opp.Type == CWS_ConstantClass.Opportunity_Type_New 
                && accountMap.get(opp.AccountId).CWS_Paid_by_Parent__c == true  
                    && accountMap.get(opp.AccountId).ParentId !=null 
                        && (opp.CWS_Route_to_Market__c == CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct 
                        || opp.CWS_Route_to_Market__c == CWS_ConstantClass.OPPORTUNITY_RouteToMarket_IIT)){
                
                if(opp.CWS_Bill_To_Account__c != accountMap.get(opp.AccountId).ParentId){
                    opp.CWS_Bill_To_Contact__c = null;
                    opp.CWS_Bill_To_Account__c = accountMap.get(opp.AccountId).ParentId;
                }
            }//End of 9078
            
            //BED -289 Primary contact Defaulting, Index values used to avoid for loop
            if(opp.CWS_Bill_To_Contact__c == null && !accountMap.isEmpty() && accountMap.get(opp.CWS_Bill_To_Account__c)!=null && accountMap.get(opp.CWS_Bill_To_Account__c).contacts.size()>0){
                if(accountMap.get(opp.CWS_Bill_To_Account__c).contacts[0].CWS_Primary_Billing_Contact__c
                    || accountMap.get(opp.CWS_Bill_To_Account__c).contacts[0].CWS_Primary_Contact__c){
                    opp.CWS_Bill_To_Contact__c=accountMap.get(opp.CWS_Bill_To_Account__c).contacts[0].id;
                }
                if(accountMap.get(opp.CWS_Bill_To_Account__c).contacts.size()==2 
                    && accountMap.get(opp.CWS_Bill_To_Account__c).contacts[1].CWS_Primary_Billing_Contact__c ){
                    opp.CWS_Bill_To_Contact__c=accountMap.get(opp.CWS_Bill_To_Account__c).contacts[1].id;
                }
            }
                // End BED - 289
                
            //Start BED-9124
            if(accountMap != null && accountMap.containsKey(opp.CWS_Bill_To_Account__c)){
                opp.CWS_DAM_Email__c = accountMap.get(opp.CWS_Bill_To_Account__c).owner.email;
            }
            //End BED-9124
            
            //Start-BED-6254
            if(accountMap != null && accountMap.containsKey(opp.accountID) && accountMap.get(opp.accountID).CWS_Region__c != null){
              opp.CWS_Region__c=accountMap.get(opp.accountID).CWS_Region__c;
              }
            //END-BED-6254
                
            //Start : BED-9115 Assigning Disty Comm Group value to opp from Disty/Reseller Junction
             if(mapOfDistyResller != null && mapOfDistyResller.containskey(opp.CWS_Bill_To_Account__c)){
                opp.CWS_Distributor_Community_Group__c = mapOfDistyResller.get(opp.CWS_Bill_To_Account__c).CWS_Distributor_Community_Group__c;
             }
             //End: BED-9115
             
        
     
            //Start : BED-6479 Sync the Bill To Account with below fields which will be used for sharing opp with Channel Reps  
            if(opp.CWS_Bill_To_Account__c != null && accountMap.get(opp.CWS_Bill_To_Account__c) != null
                && (accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Is_Distributor__c || accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Is_IIT_Reseller__c)){
                opp.CWS_Share_with_Bill_To_Account__c = opp.CWS_Bill_To_Account__c; 
                opp.CWS_Store_Bill_To_Id__c = opp.CWS_Bill_To_Account__c;
            }
            //END : BED-6479

            // BED-6047, BED-1018 Start                
            if((opp.Type == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT || opp.Type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS 
                || opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) && opp.CWS_Bill_To_Account__c != null
                && accountMap.get(opp.CWS_Bill_To_Account__c) != null && accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Distributor_Logic_Exclusion__c != null){                        
                    if((opp.CWS_Route_to_Market__c ==  CWS_ConstantClass.RTM_Value_Channel ) && accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Distributor_Logic_Exclusion__c == true ){ 
                            opp.CWS_Disti_Deal_Phase__c = CWS_ConstantClass.DistiEndCustomer;
                    } 
                }
            // BED-6047, BED-1018 End
       
            system.debug('=== opp.SBQQ__RenewedContract__c: '+opp.SBQQ__RenewedContract__c);
            system.debug('=== opp.SBQQ__AmendedContract__c: '+opp.SBQQ__AmendedContract__c);
            system.debug('=== contractMap: '+contractMap);
     
           //BED-3177, 5159 CurrencyISOCode will be defaulted with the Renewed Contract's Currency for a renewed Opportunity.
           if(opp.SBQQ__RenewedContract__c!=NULL){
               if(contractMap.containsKey(opp.SBQQ__RenewedContract__c)){
                    //Start BED-8615
                    if(contractMap.get(opp.SBQQ__RenewedContract__c).CWS_Master__c){
                        opp.CWS_Master__c = true;
                        opp.CWS_On_Hold__c = true;
                        opp.CWS_On_Hold_Reason__c = Label.CWS_CMS_Opportunity_On_Hold_Reason;
                    }
                    
                    //End BED-8615
                    //if(contractMap.get(opp.SBQQ__RenewedContract__c).CWS_Created_By_AMCont__c != null){
                    //opp.CWS_CreatedByAM__c=contractMap.get(opp.SBQQ__RenewedContract__c).CWS_Created_By_AMCont__c;
                    //}
                    opp.CurrencyIsoCode = contractMap.get(opp.SBQQ__RenewedContract__c).CurrencyIsoCode;
                    //BED-910 Renewal type default 
                    if(opp.Type != CWS_ConstantClass.QUOTE_TYPE_RENEWALWC){
                        opp.Type = CWS_ConstantClass.Opportunity_Type_Renewal;
                    }
                    
                    opp.RecordTypeID = CWS_ConstantClass.Opportunity_Renewal;
                    //BED-64 Defaulting oppotunity stage to 'Evaluation' on renewal opportunity creation
                    opp.StageName=CWS_ConstantClass.OPPORTUNITY_STAGE_EVALUATION;
               }

           
               if(accountMap.containskey(opp.AccountId)){
                    //BED-12841
                        if(accountMap.get(opp.AccountId).owner.isActive){
                            opp.ownerId=accountMap.get(opp.AccountId).ownerId;
                        }else if(accountMap.get(opp.AccountId).owner.Manager.isActive){
                            opp.ownerId=accountMap.get(opp.AccountId).owner.ManagerId;
                        }
               }
               //BED-5939 - Defaulting opp name format
               if(contractMap.get(opp.SBQQ__RenewedContract__c).ContractNumber !=null){
                   system.debug('opp namebefore --'+opp.name);
                   String formattedEndDate ='';
                   if(contractMap.get(opp.SBQQ__RenewedContract__c).EndDate !=null){
                       formattedEndDate = String.valueOf(contractMap.get(opp.SBQQ__RenewedContract__c).EndDate.addDays(1)).removeEnd(CWS_ConstantClass.Date_Mon_Hr_Sec);
                   }                                
                   opp.name = CWS_ConstantClass.QUOTE_TYPE_RENEWAL +'_'+ (FormattedEndDate == null ? '' : (FormattedEndDate+'_')) +'#'+contractMap.get(opp.SBQQ__RenewedContract__c).ContractNumber;
               }                            
            //BED-5939
            }//BED-3177, 5159 CurrencyISOCode will be defaulted with the Amended Contract's Currency for a amended Opportunity.
            else if(opp.SBQQ__AmendedContract__c != NULL && contractMap.containsKey(opp.SBQQ__AmendedContract__c)){
                //Start BED-8615
                if(contractMap.get(opp.SBQQ__AmendedContract__c).CWS_Master__c){
                    opp.CWS_Master__c = true;
                }
                //End BED-8615
                opp.CurrencyIsoCode = contractMap.get(opp.SBQQ__AmendedContract__c).CurrencyIsoCode;
                //BED-910 Amendment type default
                opp.Type = CWS_ConstantClass.Opportunity_Type_Amendment;
                
                system.debug('=== change to amendment');
                opp.RecordTypeID = CWS_ConstantClass.Opportunity_Amendment;
                //BED-64 Defaulting oppotunity stage to prospecting on renewal opportunity creation
                opp.StageName=CWS_ConstantClass.OPPORTUNITY_STAGE_QUALIFICATION;
                //BED-6254
                //opp.CWS_CreatedByAM__c=((userRegion.isEmpty()) && MapOwnerIdsAmendment.get(opp.Ownerid).Profile.Name == CWS_ConstantClass.PROFILE_SALES_REP && MapOwnerIdsAmendment.get(opp.Ownerid).CWS_Region__c.Contains(accountMap.get(opp.Accountid).CWS_Region__c))?false:true;
                if(contractMap.get(opp.SBQQ__AmendedContract__c).CWS_Created_By_AMCont__c != null){
                opp.CWS_CreatedByAM__c=contractMap.get(opp.SBQQ__AmendedContract__c).CWS_Created_By_AMCont__c;
                }
                //BED-6254
                //Start 658 : Defaulting Amendment Opportuntiy Owner with Account Owner
                if(accountMap.containsKey(opp.AccountId) && opp.CWS_CreatedByAM__c){
                    //BED-12841
                                if(accountMap.get(opp.AccountId).owner.isActive){
                                    opp.ownerId=accountMap.get(opp.AccountId).ownerId;
                                }else if(accountMap.get(opp.AccountId).owner.Manager.isActive){
                                    opp.ownerId=accountMap.get(opp.AccountId).owner.ManagerId;
                                }
                }
                //End
        
            }
           else{    //BED-5159
               if(accountMap.containsKey(opp.CWS_Bill_To_Account__c)){
                   opp.CurrencyISOCode = accountMap.get(opp.CWS_Bill_To_Account__c).CurrencyIsoCode;
               }   
            }
           // BED -937 Start : Legal Entity Defaulting
            if(opp.CurrencyISOCode != Null && currLegalEntityMap != Null && currLegalEntityMap.get(opp.CurrencyISOCode) != Null  &&  opp.SBQQ__AmendedContract__c == Null && (opp.SBQQ__RenewedContract__c == Null || opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC )){
                opp.CWS_Legal_Entity__c=currLegalEntityMap.get(opp.CurrencyISOCode);
            }
            // BED- 937 
            
            //973 ReadOnly RT assignment on Opportunity Close
            if(opp.StageName == CWS_ConstantClass.OpportunityClosedWon_Stage || opp.StageName == CWS_ConstantClass.OpportunityClosedLose_Stage){
                opp.RecordTypeID = assignReadOnlyRT(opp).RecordTypeID;
                
                 //BED-271
                if((opp.Type == CWS_ConstantClass.Opportunity_Type_New || opp.Type == CWS_ConstantClass.Opportunity_Type_CommissionOnly) && opp.StageName == CWS_ConstantClass.OpportunityClosedWon_Stage && accountMap.get(opp.AccountId).CWS_Is_Partner__c == False){  
                    
                    /*//BED-8597 As part of BED-5545 This logic is not required.
                    if(accountMap.get(opp.AccountId).CWS_Partner_Type__c == CWS_ConstantClass.FORMER_PARTNER_STATUS){
                        opp.addError(System.Label.CWS_is_active_Partner);
                    }//BED-8597 */
                    accountMap.get(opp.AccountId).CWS_Is_Partner__c  = True;
                    endCustmerAcctList.add(accountMap.get(opp.AccountId));
                }
           
            }
        
            // BED-13313 Commenting Below logic,  currency shouldnt get defaulted by Sold to currency ,user should select manually.
            /*if(opp.Type == CWS_ConstantClass.Opportunity_Type_CommissionOnly){
                opp.CurrencyIsoCode = accountMap.get(opp.AccountId).CurrencyIsoCode; //Default currency using soldToAccount for Commission only
                
            }*/
             // BED-208 Default Pricebook for Opportunity
            if(cwsPriceBook!=null){
                opp.Pricebook2Id = cwsPriceBook.id;
            } 
            // Start BED -91 : Exchange Rate Defaulting
            if(!exchangeRate.isEmpty() && exchangeRate.get(opp.CurrencyISOCode)!= Null){
                    opp.CWS_Exchange_Rate__c=exchangeRate.get(opp.CurrencyISOCode);
            }// End BED 91
            //Start 5939
            if(((opp.name == null || String.isBlank(opp.name)) && accountMap != null && !accountMap.isEmpty() && accountMap.get(opp.AccountId)!= null )
             || (Test.isRunningTest() && opp.name == 'Testing Opp')){
                String name = accountMap.get(opp.AccountId).name +'_'+Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opp.recordtypeid).getname() 
                +'_'+String.valueOf(Date.today()).removeEnd(CWS_ConstantClass.Date_Mon_Hr_Sec);
                if(!String.isBlank(name)){
                    opp.name = name;
                } 
            }
            //End 5939
            //BED-118 
            if(!bFastTrackGroup && opp.CWS_Fast_Track__c && profileObj!=null 
                && profileObj.Name !=CWS_ConstantClass.SysAdminProfile){
                opp.addError(Label.CWS_FastTrackOpp_Error);
            }
        }
        //BED-271 
        if(endCustmerAcctList.size()>0){  
           accUpdate = Database.update(endCustmerAcctList);
           CWS_ExceptionHandler.logDMLSaveResults(accUpdate, 'CWS_OpportunityTriggerHelper', 'beforeInsert', 'Account', null, null);
        }
                                    
        }catch(Exception e){
            system.debug('Exception caught: '+e.getMessage()+' | '+e.getStackTraceString());
            CWS_ExceptionHandler.logException( e,'Opportunity' , 'CWS_OpportunityTriggerHelper', 'CWS_OpportunityTriggerHelper:BeforeInsertMethod' , '', null, null , 'BeforeInsert' , null);
        }

    }

public static void beforeUpdateMethod(Map<Id, Opportunity> newItems, Map<Id, Opportunity> oldItems){
    
    system.debug('=== Before Update - Opp helper');
  
  set<id> distyIdSet = new set<id>();
  List<Id> contractList = new List<Id>();
  List<Id> accountList = new List<Id>();
  set<Id> billTOIdset = new set<Id>();
  List<Account> endCustmerAcctList = new List<Account>();
  Map<Id, Contract> contractMap = new Map<Id, Contract>();
  Map<Id, Account> accountMap =  new Map<Id, Account>();
  map<string,string> currLegalEntityMap = getLegalEntity();
  List<Database.SaveResult> accUpdate;
  Map<String, Decimal> exchangeRate = new Map<String, Decimal>();
  Integer qtyLimit = Integer.valueOf(System.Label.CWS_Custom_Metedata_Query_Limit);
  Boolean bFastTrackOpp = false;//BED-118 flag to enable if fast track opportunities are modified
  Boolean bFastTrackGroup = false;//BED-118 flag to enable if user present in fast track group
  List<GroupMember> lstGroupMember = new List<GroupMember>();//BED-118 stores group details of user
  Map<Id,Contract> conMap = new Map<Id,Contract>();
  Map<Id,Contract> conAccMap = new Map<Id,Contract>();
  Set<Id> acctList = new Set<Id>();
  Boolean newBusinessOpp = false;//Bed-13043
        
  // BED-5006: Renewal Cancellation Notification
  Map<Id,Set<String>> userRegion= new Map<Id,Set<String>>();
  Id loggedUser=userInfo.getUserId();
  Id loggedUserprofileid=userInfo.getProfileId();
  Profile profileObj;
  List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();

  
  try{
   for(Opportunity opp:newItems.values()){
        
        Opportunity oldOpp = oldItems.get(opp.Id);
        
          //Start BED-8615
            if(opp.CWS_Master__c && !oldOpp.CWS_Master__c){
                opp.CWS_Route_to_Market__c = CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct;
            }
            //BED-12175
            else if(oldOpp.CWS_Master__c && !opp.CWS_Master__c){
                opp.CWS_Period_of_Fixed_Usage_Commit_Ramp__c=null;
            }
            //End BED-8615
            
            if(opp.CWS_Master__c && oldOpp.CWS_Ramp_Options__c != opp.CWS_Ramp_Options__c){ 
                if(opp.CWS_Ramp_Options__c != null && (opp.CWS_Period_of_Fixed_Usage_Commit_Ramp__c==Null || opp.CWS_Period_of_Fixed_Usage_Commit_Ramp__c== 0)){
                    opp.CWS_Period_of_Fixed_Usage_Commit_Ramp__c=3;
                }else if(opp.CWS_Ramp_Options__c == null){
                    opp.CWS_Period_of_Fixed_Usage_Commit_Ramp__c=null;
                }
            }

        //BED-3177 Adding the Ids of renewed contracts linked with the Opportunity to contractList.
        //BED-9115 Clubbed the condition in OR as contractList is getting used to store bot amendment and Renewal contract lookup
       if(opp.SBQQ__RenewedContract__c != NULL || opp.SBQQ__AmendedContract__c != NULL){
           contractList.add(opp.SBQQ__RenewedContract__c);
       }
       
       //BED-3177 Adding the Ids of bill to account linked with the Opportunity to AccountList.
       //BED-9115 Added Bill to change then only execute if statement
       if(opp.CWS_Bill_To_Account__c!=NULL 
           && opp.CWS_Bill_To_Account__c != oldOpp.CWS_Bill_To_Account__c){
           billTOIdset.add(opp.CWS_Bill_To_Account__c);
       }
       //BED-9115
       
       if(opp.Accountid != null){
         accountList.add(opp.AccountId);
       }
       //BED-1009 Update stage to closed lost if opportunity is rejected twice
        if(opp.CWS_Rejected_Approval_Count__c == 2 && opp.CWS_Rejected_Approval_Count__c!=oldItems.get(opp.Id).CWS_Rejected_Approval_Count__c){
            opp.StageName = CWS_ConstantClass.OpportunityClosedLose_Stage;
            opp.CWS_Lost_Reason__c = CWS_ConstantClass.OPPORTUNITY_LOST_ACCOUNTRESTRICTED;
        }
        //BED-118 fast track opp check
        if(!bFastTrackOpp && opp.CWS_Fast_Track__c!=oldOpp.CWS_Fast_Track__c){
            bFastTrackOpp=true;
        }//Bed-13043 start
        if(opp.type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS || opp.type == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT 
            || opp.type == CWS_ConstantClass.QUOTE_TYPE_RENEWAL ){
            newBusinessOpp = true;
        }//Bed-13043 End    
        //BED-487
        if(Opp.CWS_Total_Forecast_Amount__c != oldOpp.CWS_Total_Forecast_Amount__c){
            Opp.CWS_Total_Forecast_For_Report__c = Opp.CWS_Total_Forecast_Amount__c;
        }
        //BED-487       
    }
    
    //Start : BED-9115 create a map to get the Disty Comm Group value to insert     
   map<id,CWS_Distributor_Reseller__c> mapOfDistyResller = new map<id,CWS_Distributor_Reseller__c>();
   
   if(billTOIdset.size() > 0 && accountList.size() > 0){
     for(CWS_Distributor_Reseller__c disty : [Select id,CWS_Distributor_Community_Group__c,CWS_Distributor_ResellerAcc__c  
                                                                         from 
                                                                         CWS_Distributor_Reseller__c 
                                                                         where 
                                                                         CWS_Account__c IN: accountList AND CWS_Distributor_ResellerAcc__c IN: billTOIdset
                                                                         AND CWS_Distributor_Community_Group__c != null AND CWS_Distributor_ResellerAcc__r.CWS_Is_Distributor__c = true]){
       mapOfDistyResller.put(disty.CWS_Distributor_ResellerAcc__c,disty);
     }
   }     
   //End BED-9115
    
       //BED-8825
           if(accountList.size() > 0 ){
               conMap = new Map<Id,Contract> ([Select Id, Name, AccountId, CWS_Master__c,CWS_Status__c, SBQQ__Opportunity__c from
                                                Contract Where AccountId IN: accountList AND CWS_Master__c = True AND CWS_Status__c = 'Active' Limit 100]);
           }
              for(Contract con : conMap.values()){
             conAccMap.put(con.AccountId,con);
         }   

    // BED - 91 : Getting Currency Rate 
    for(CurrencyType exList : [Select ISOCode, ConversionRate, IsActive 
                                            from CurrencyType 
                                                where IsActive = true LIMIT : qtyLimit]){
              exchangeRate.put(exList.ISOCode, exList.ConversionRate);
    }
    // End BED 91 

   
// BED-5006: Renewal Cancellation Notification: Adding ContractNumber to the Query
   if(contractList.size()>0){
   contractMap = new Map<Id,Contract>([SELECT ID, CurrencyIsoCode, ContractNumber from Contract where ID in:ContractList]);
   }
   
   // BED-5006: Renewal Cancellation Notification: Adding CWS_Region__c, Name to the Query
   if(accountList.size()>0){
       accountMap = new Map<Id,Account>([SELECT Id, CurrencyISOCode, CWS_Is_Partner__c,CWS_Partner_Type__c, CWS_Is_Distributor__c, CWS_Is_IIT_Reseller__c, CWS_Distributor_Logic_Exclusion__c, CWS_Region__c, Name FROM Account where Id in:AccountList OR Id IN: billTOIdset]);
   }
    //Start: BED-5006: Renewal Cancellation Notification
    if(loggedUser!= null && loggedUserprofileid != null){
        profileObj=[select Name from Profile where id=:loggedUserprofileid limit 1];
        userRegion=CWS_CommonUtility.getGroupMemberRegion(new list<Id>{loggedUser});
        system.debug('***userRegion'+userRegion);
     }
    //BED-118 retrieve group of user is present in 
    //Query can be reused and condition can be modified
        List<String> grpnames = new List<String>();//Bed-13043
        if(bFastTrackOpp && loggedUser!=null && profileObj!=null 
        && profileObj.Name !=CWS_ConstantClass.SysAdminProfile){
            grpnames.add(CWS_ConstantClass.GroupnameFTQ);
        }
        if(newBusinessOpp == true){
            grpnames.add(CWS_ConstantClass.GroupNameEvtSpnShp);
        }

        if(!grpNames.isEmpty() && grpNames.size() >0 ){
            lstGroupMember = fetchGrpMems(grpNames);
            if(lstGroupMember.size()>0 && grpNames.Contains(CWS_ConstantClass.GroupnameFTQ) ){
                for(groupmember objGrpMem: lstGroupMember){
                    if(objGrpMem.group.DeveloperName==CWS_ConstantClass.GroupnameFTQ){
                        bFastTrackGroup=true;
                        break;
                    }
                }              
            } 
        }

     for(Opportunity opp:newItems.values()){
     
       Opportunity oldOpp = oldItems.get(opp.Id);
         
          
        //Start : BED-9115 Assigning Disty Comm Group value to opp from Disty/Reseller Junction
       if(mapOfDistyResller != null && mapOfDistyResller.containsKey(opp.CWS_Bill_To_Account__c)){
           opp.CWS_Distributor_Community_Group__c = mapOfDistyResller.get(opp.CWS_Bill_To_Account__c).CWS_Distributor_Community_Group__c;
       }
       //End: BED-9115

            // BED-8825
            /* TODO DETERMINE IF WE ARE KEEPING THIS CHANGE */
            if(conAccMap.size()>0 && conAccMap.containsKey(opp.AccountId) && conAccMap.get(opp.AccountId).SBQQ__Opportunity__c != opp.Id) {
                if(opp.Type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && opp.CWS_Master__c == false) {
                    opp.CWS_Has_Master_Contract__c = true;
                }
                // START CR_RECOMMIT
                if(opp.Type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && opp.CWS_Master__c == true && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && opp.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL){
                    opp.addError(System.Label.CWS_Only_One_Master_Contract_Recommit);
                }
                // END CR_RECOMMIT
            }
            //BED-8825 End
       //Start : BED-6479 Sync the Bill To Account with below fields which will be used for sharing opp with Channel Reps  
        if(opp.CWS_Bill_To_Account__c != null && opp.CWS_Bill_To_Account__c != oldOpp.CWS_Bill_To_Account__c &&accountMap.get(opp.CWS_Bill_To_Account__c) != null
            && (accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Is_Distributor__c || accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Is_IIT_Reseller__c)){
            opp.CWS_Share_with_Bill_To_Account__c = opp.CWS_Bill_To_Account__c; 
            opp.CWS_Store_Bill_To_Id__c = opp.CWS_Bill_To_Account__c;
        }
        //Start : BED-6479
        
        //BED-6047,BED-1018         
        if((opp.Type == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT || opp.Type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS 
            || opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) && opp.CWS_Bill_To_Account__c != null && 
            opp.CWS_Bill_To_Account__c != oldOpp.CWS_Bill_To_Account__c && accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Distributor_Logic_Exclusion__c != null){
                if((opp.CWS_Route_to_Market__c ==  CWS_ConstantClass.RTM_Value_Channel ) && accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Distributor_Logic_Exclusion__c == true ) {
               opp.CWS_Disti_Deal_Phase__c = CWS_ConstantClass.DistiEndCustomer;
            } 
        }
        //BED-6047,BED-1018 END
         //BED-631 Defaulting deal phase to blank when RTM is direct 
         if(opp.CWS_Route_to_Market__c != oldOpp.CWS_Route_to_Market__c && (opp.CWS_Route_to_Market__c ==  CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct ||                 
                (opp.CWS_Route_to_Market__c == CWS_ConstantClass.OPPORTUNITY_RouteToMarket_IIT && accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Is_Distributor__c != null && 
                    accountMap.get(opp.CWS_Bill_To_Account__c).CWS_Is_Distributor__c == false )) ){
                        opp.CWS_Disti_Deal_Phase__c = '';
                }
         //BED-631 END  
        //BED-13043 Start   
        //Defect 14025495 - NB Currency Change Access
        if(opp.CurrencyIsoCode != oldOpp.CurrencyIsoCode && (opp.type == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT 
            || opp.type == CWS_ConstantClass.QUOTE_TYPE_RENEWAL
            || (opp.type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && profileObj.Name !=CWS_ConstantClass.SysAdminProfile 
                    && profileObj.Name !=CWS_ConstantClass.ContractAdminProfile && profileObj.Name !=CWS_ConstantClass.PROFILE_SALES_MANAGER 
                    && profileObj.Name !=CWS_ConstantClass.GlobalSalesOpsProfile && profileObj.Name !=CWS_ConstantClass.OMProfile 
                    && profileObj.Name !=CWS_ConstantClass.Master_Data_Admin_Profile && profileObj.Name !=CWS_ConstantClass.PROFILE_SALES_REP))){                          
            if(lstGroupMember.size()>0){
                Boolean eventSpnsrUser = false;
                for(groupmember objGrpMem: lstGroupMember){
                    if(objGrpMem.group.DeveloperName == CWS_ConstantClass.GroupNameEvtSpnShp){
                        eventSpnsrUser  = true;
                        break;
                    }                        
                }   
                system.debug('eventSpnsrUser--'+eventSpnsrUser);
                if(!eventSpnsrUser) opp.addError(Label.CWS_CurrencyAccesError);
            } else{
                opp.addError(Label.CWS_CurrencyAccesError);
            }
        } //BED-13043 End

       //BED-3177, 5159 CurrencyISOCode will be defaulted with the Renewed Contract's Currency for a renewed Opportunity.
       if(opp.SBQQ__RenewedContract__c!=NULL && opp.SBQQ__RenewedContract__c!=oldOpp.SBQQ__RenewedContract__c){
           if(contractMap.containsKey(opp.SBQQ__RenewedContract__c)){
           opp.CurrencyIsoCode = contractMap.get(opp.SBQQ__RenewedContract__c).CurrencyIsoCode;
           }
       }//BED-3177, 5159 CurrencyISOCode will be defaulted with the Amended Contract's Currency for a amended Opportunity.
       else if(opp.SBQQ__AmendedContract__c != NULL  && opp.SBQQ__AmendedContract__c!=oldOpp.SBQQ__AmendedContract__c){
           if(contractMap.containsKey(opp.SBQQ__AmendedContract__c)){
           opp.CurrencyIsoCode = contractMap.get(opp.SBQQ__AmendedContract__c).CurrencyIsoCode;
           }
       }
       else if(accountMap.containsKey(opp.CWS_Bill_To_Account__c) && (opp.CWS_Bill_To_Account__c!=oldOpp.CWS_Bill_To_Account__c)){
               opp.CurrencyISOCode = accountMap.get(opp.CWS_Bill_To_Account__c).CurrencyIsoCode;
               
               // Start BED -91 : Exchange Rate Defaulting
               if(!exchangeRate.isEmpty() && exchangeRate.get(opp.CurrencyISOCode)!= Null){
                    opp.CWS_Exchange_Rate__c=exchangeRate.get(opp.CurrencyISOCode);
               }// End BED 91
                 
           }
           
       //BED-226
       // BED-13313 Commenting Below logic,  currency shouldnt get defaulted based on Sold to currency ,user should select manually.
       /*if(opp.CurrencyISOCode != oldOpp.CurrencyISOCode && opp.Type == CWS_ConstantClass.Opportunity_Type_CommissionOnly && opp.RecordTypeID == CWS_ConstantClass.Opportunity_CommissionOnly){
            opp.CurrencyISOCode = accountMap.get(opp.AccountId).CurrencyIsoCode;
       }*/
       
       // BED -937 Start : Legal Entity Defaulting
        if(opp.CurrencyISOCode != Null && currLegalEntityMap != Null 
                    && currLegalEntityMap.get(opp.CurrencyISOCode) !=Null
                    && (opp.SBQQ__RenewedContract__c == null || opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC)
                    && opp.SBQQ__AmendedContract__c== null 
                    && (opp.CWS_Bill_To_Account__c!=oldOpp.CWS_Bill_To_Account__c
                                || opp.CurrencyISOCode!=oldOpp.CurrencyISOCode)){
            opp.CWS_Legal_Entity__c=currLegalEntityMap.get(opp.CurrencyISOCode);
        }
        // BED- 937 
      //BED-973 ReadOnly Record Type assignment when opportunity is Closed Lost/Won
      if( opp.StageName!= oldOpp.StageName && (opp.StageName == CWS_ConstantClass.OpportunityClosedWon_Stage || opp.StageName == CWS_ConstantClass.OpportunityClosedLose_Stage) ){
           opp.RecordTypeID = assignReadOnlyRT(opp).RecordTypeID;
           
           
            //BED-271
             if((opp.Type == CWS_ConstantClass.Opportunity_Type_New || opp.Type == CWS_ConstantClass.Opportunity_Type_CommissionOnly)&& opp.StageName == CWS_ConstantClass.OpportunityClosedWon_Stage && accountMap.get(opp.AccountId).CWS_Is_Partner__c == False){
                
                /* //BED-8597 Commenting this as part of BED-5545
                if(accountMap.get(opp.AccountId).CWS_Partner_Type__c == CWS_ConstantClass.FORMER_PARTNER_STATUS){
                System.debug('@@'+opp);
                    opp.addError(System.Label.CWS_is_active_Partner);
                }//End 8597 */
                accountMap.get(opp.AccountId).CWS_Is_Partner__c  = True;
                endCustmerAcctList.add(accountMap.get(opp.AccountId));
             }
       }
        //14024872 - Non RO record type
            if( opp.StageName!= oldOpp.StageName && opp.StageName != CWS_ConstantClass.OpportunityClosedWon_Stage && opp.StageName != CWS_ConstantClass.OpportunityClosedLose_Stage){
                opp.RecordTypeID = assignNonReadOnlyRT(opp).RecordTypeID;
            }
       
        //Start: BED-5006: Renewal Cancellation Notification
        if(opp.Type == CWS_ConstantClass.Opportunity_Type_Renewal && opp.CWS_Do_Not_Renew_Existing_Contract__c && !oldOpp.CWS_Do_Not_Renew_Existing_Contract__c){

                if(!accountMap.isEmpty()){
                
                     if(userRegion.isEmpty() || (!userRegion.isEmpty() && userRegion.get(userinfo.getUserId())!=Null && !userRegion.get(userinfo.getUserId()).contains(accountMap.get(opp.AccountId).CWS_Region__c))){
                          opp.addError(Label.CWS_RenewalRegionCheckforOpptyUpdate);
                }
                else{
                  string accountname = accountMap.get(opp.AccountId).Name;
                  string contractname = string.valueof(contractMap.get(opp.SBQQ__RenewedContract__c).ContractNumber);
                  Messaging.SingleEmailMessage emails = new Messaging.SingleEmailMessage();
                  List<String> sendTo = new List<String>();
                  String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
                  sendTo.addAll((Label.CWS_Partner_Success_Team_Emails).split(';'));
                  emails.setToAddresses(sendTo);
                  emails.setSubject('Notice : Partner decided to not renew the contract');
                  string body = '<p>Hi Team,</p>' + '<p>Partner decided to not renew the contract. </p>' + 'Account Name : ' +accountname + '<br/>' + 'Contract Number : ' +contractname + '<p>'+ 'Link to Opportunity: ' +baseUrl+'/'+ opp.Id+'</p>' + '<p>\nPlease take necessary actions.</p>';
                  emails.setHtmlBody(body); 
                  listEmails.add(emails);
                }
            }
        }
        //End: BED-5006: Renewal Cancellation Notification 
        //BED-118
        if(!bFastTrackGroup && opp.CWS_Fast_Track__c != oldOpp.CWS_Fast_Track__c
        && profileObj!=null && profileObj.Name !=CWS_ConstantClass.SysAdminProfile){
            opp.addError(Label.CWS_FastTrackOpp_Error);
        }
   }
   
  //Start: BED-5006: Renewal Cancellation Notification
   if(listEmails.size()>0 && listEmails!=null){
    Messaging.SendEmail(listEmails); 
   }

   
    if(endCustmerAcctList.size()>0){  
       accUpdate = Database.update(endCustmerAcctList);
       CWS_ExceptionHandler.logDMLSaveResults(accUpdate, 'CWS_OpportunityTriggerHelper', 'beforeUpdate', 'Account', null, null);
    }
   }
   catch(Exception e){
        CWS_ExceptionHandler.logException( e,'Opportunity' , 'CWS_OpportunityTriggerHelper', 'CWS_OpportunityTriggerHelper:BeforeUpdateMethod' , '', null, null , 'BeforeUpdate' , null);
   }
    
    
    system.debug('===newItems: '+newItems);

}

    /*
    * Method name  : AfterUpdate
    * Description  : Method used to perform after update operations on Opportunity
    * Parameter    : List of new and old Opportunities
    * Return Type  : None
    * Developer    : Aditya
    */

    public static void afterUpdate(Map<Id, Opportunity> newItems, Map<Id, Opportunity> oldItems){
        List<Opportunity> lostOpportunity = new List<Opportunity>();
        List<SBQQ__Quote__c> inactiveQuotes = new List<SBQQ__Quote__c>();
        List<Database.SaveResult> quoteUpdate;
        Set<Id> setOppWonIds = new Set<Id>();//BED-8762 Set of closed won opportunity ids
        Map<Id,CWS_Trial__c> mapTrialsToUpdate = new Map<Id,CWS_Trial__c>();//BED-8762 map of trial records for the closed won opporunities
        List<Database.SaveResult> srList;//BED-8762
        List<sobject> lstDMLObj = new List<sobject>();//BED-8762
        Map<Id, Opportunity> mapOnHoldOpty=new Map<Id, Opportunity>();      
        try{  
            for(Opportunity opp:newItems.values()){
                Opportunity oldOpp = oldItems.get(opp.Id);
                if( opp.StageName!= oldOpp.StageName && opp.StageName == CWS_ConstantClass.OpportunityClosedLose_Stage){
                    lostOpportunity.add(opp);
                }
                //BED-8762 add all closed won opportunity ids
                if( opp.StageName!= oldOpp.StageName && opp.StageName == CWS_ConstantClass.OpportunityClosedWon_Stage){
                    setOppWonIds.add(opp.Id);
                }
                //BED-8816
                if((opp.Type==CWS_ConstantClass.Opportunity_Type_Renewal ||
                    opp.Type==CWS_ConstantClass.Opportunity_Type_RenewalWithChange) && 
                    (opp.CWS_On_Hold__c!=oldOpp.CWS_On_Hold__c ||
                    opp.CWS_On_Hold_Reason__c!=oldOpp.CWS_On_Hold_Reason__c ||
                    opp.CWS_Master__c!=oldOpp.CWS_Master__c) &&
                    opp.StageName!=CWS_ConstantClass.OpportunityClosedLose_Stage){
                        mapOnHoldOpty.put(opp.Id, opp);
                }
            }
            //BED-8762 Retrieving all trials and adding it to trial update map
            //SOQL Query can be modified to be reused
            if(setOppWonIds.size()>0){
                for(CWS_Trial__c objTrial: [Select id,CWS_Related_Opportunity__c,CWS_Trial_Product_Type__c,
                CWS_Related_Opportunity_Won__c from CWS_Trial__c where CWS_Related_Opportunity__c IN :setOppWonIds 
                AND CWS_Trial_Product_Type__c=:CWS_ConstantClass.TRIAL_TYPE_COMMAND]){
                    if(setOppWonIds.contains(objTrial.CWS_Related_Opportunity__c) 
                    &&objTrial.CWS_Trial_Product_Type__c==CWS_ConstantClass.TRIAL_TYPE_COMMAND){
                        if(!mapTrialsToUpdate.containsKey(objTrial.Id)){
                            mapTrialsToUpdate.put(objTrial.Id,objTrial);
                        }
                        mapTrialsToUpdate.get(objTrial.Id).CWS_Related_Opportunity_Won__c=true;
                    }
                }
            }

            //BED-8762 Modified to list of sobject to insert or update
            if(mapTrialsToUpdate.size()>0){
                lstDMLObj.addAll(mapTrialsToUpdate.values());
            }
            if(lostOpportunity.size()>0){
                //update mahak - OBD-601 #14713243  Start- Send opportunity lost email to opportunityteammembers
                Set<Id> lostOppSet=new Set<Id>();
                for(Opportunity opp:lostOpportunity){
                    lostOppSet.add(opp.Id);
                }
                sendLostOppEmail(lostOppSet);                          
                //update mahak - #14713243  End- Send opportunity lost email to opportunityteammembers

                inactiveQuotes = deactivateQuotes(lostOpportunity);
                //BED-7880 updating Quotes as inactive when opportunity is lost
                if(inactiveQuotes.size()>0){
                    lstDMLObj.addAll(inactiveQuotes);
                }
            }
            if(mapOnHoldOpty!=null && !mapOnHoldOpty.isEmpty()){
                for(SBQQ__Quote__c quote:[Select id, name,SBQQ__Opportunity2__c,CWS_Master__c,
                                         CWS_On_Hold__c, CWS_On_Hold_Reason__c
                                         from SBQQ__Quote__c where 
                                        SBQQ__Opportunity2__c in :mapOnHoldOpty.keySet() and 
                                        CWS_Quote_Type__c=:CWS_ConstantClass.QUOTE_TYPE_RENEWAL]){
                    if(mapOnHoldOpty.get(quote.SBQQ__Opportunity2__c)!=null){
                        if(quote.CWS_Master__c!=mapOnHoldOpty.get(quote.SBQQ__Opportunity2__c).CWS_Master__c ||
                            quote.CWS_On_Hold__c!=mapOnHoldOpty.get(quote.SBQQ__Opportunity2__c).CWS_On_Hold__c ||
                            quote.CWS_On_Hold_Reason__c!=mapOnHoldOpty.get(quote.SBQQ__Opportunity2__c).CWS_On_Hold_Reason__c){
                            quote.CWS_On_Hold__c=mapOnHoldOpty.get(quote.SBQQ__Opportunity2__c).CWS_On_Hold__c;
                            quote.CWS_On_Hold_Reason__c=mapOnHoldOpty.get(quote.SBQQ__Opportunity2__c).CWS_On_Hold_Reason__c;
                            quote.CWS_Master__c=mapOnHoldOpty.get(quote.SBQQ__Opportunity2__c).CWS_Master__c;
                            lstDMLObj.add(quote);
                        }
                    }
                }
            }
            if(lstDMLObj.size()>0){
                srList = Database.update(lstDMLObj); 
                CWS_EXceptionHandler.logDMLSaveResults(srList, 'CWS_OpportunityTriggerHelper', 'afterUpdate','', null,null );
            }
        }
        catch(Exception e){
            CWS_EXceptionHandler.logException( e,'Opportunity' , 'CWS_OpportunityTriggerHelper' , 'afterUpdateMethod' ,'', null , null ,'afterUpdate' , null);
        }
    }
    
   /*
    * Method name  : deactivateQuotes
    * Description  : Method to deactivate quotes of a Lost Oppportunities 
    * Parameter    : List of Opportunity
    * Return Type  : List of Quotes
    * Developer    : Aditya
    */      

    //BED-7880 Marking Quotes as inactive for Lost Opportunities
    public static List<SBQQ__Quote__c> deactivateQuotes(List<Opportunity> oppList){
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> inactiveQuotes = new List<SBQQ__Quote__c>();
        quoteList = [SELECT id, SBQQ__Status__c 
                    FROM SBQQ__Quote__c 
                    WHERE SBQQ__Opportunity2__c IN:oppList];
        if(quoteList.size()>0){
            for(SBQQ__Quote__c quote:quoteList){
                quote.SBQQ__Status__c = CWS_ConstantClass.QUOTE_STATUS_INACTIVE;
                inactiveQuotes.add(quote);
            }
        }
        return inactiveQuotes;
    }   


  /*
   * Method name  : assignReadOnlyRT
   * Parameter    : Opportunity Record
   * Return Type  : Opportunity
   * Developer    : Aditya
   */
  
   public static Opportunity assignReadOnlyRT(Opportunity opp){
       if(opp.Type == CWS_ConstantClass.Opportunity_Type_New)
        { 
            opp.RecordTypeId = CWS_ConstantClass.Opportunity_NewBusiness_ReadOnly;
        }
        else if(opp.Type == CWS_ConstantClass.Opportunity_Type_Amendment)
        { 
            opp.RecordTypeId = CWS_ConstantClass.Opportunity_Amendment_ReadOnly;
        }
        else if(opp.Type == CWS_ConstantClass.Opportunity_Type_Renewal || opp.Type == CWS_ConstantClass.Opportunity_Type_RenewalWithChange)
        { 
          opp.RecordTypeId = CWS_ConstantClass.Opportunity_Renewal_ReadOnly;
        }
        else if(opp.Type == CWS_ConstantClass.Opportunity_Type_CommissionOnly)
        { 
          opp.RecordTypeId = CWS_ConstantClass.Opportunity_CommissionOnlyReadOnly;
        }
        return opp;
    }
    /*
   * Method name  : assignNonReadOnlyRT
   * Defect # : 14024872
   */
  
   public static Opportunity assignNonReadOnlyRT(Opportunity opp){
    if(opp.Type == CWS_ConstantClass.Opportunity_Type_New)
     { 
         system.debug('===setting to new business in Opp Trigger helper');
         
         opp.RecordTypeId = CWS_ConstantClass.Opportunity_NewBusiness;
     }
     else if(opp.Type == CWS_ConstantClass.Opportunity_Type_Amendment)
     { 
         opp.RecordTypeId = CWS_ConstantClass.Opportunity_Amendment;
     }
     else if(opp.Type == CWS_ConstantClass.Opportunity_Type_Renewal || opp.Type == CWS_ConstantClass.Opportunity_Type_RenewalWithChange)
     { 
       opp.RecordTypeId = CWS_ConstantClass.Opportunity_Renewal;
     }
     return opp;
 }
     
    /* Method name  : getLegalEntity
    *  Parameter    : Opportunity Record
    *  Return Type  : String
    *  Developer    : Abhishek
    *  User Story   : BED-937
    */
    public static map<string,string> getLegalEntity(){
        map<string,string> currencyLegalEntityMap = new map<string,string>();
        integer queryLimit = Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);
        for(CWS_Currency_Legal_Entity_Mapping__mdt curLegal: [SELECT label,DeveloperName,CWS_Legal_Entity__c
                                                                FROM CWS_Currency_Legal_Entity_Mapping__mdt 
                                                                LIMIT : Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit)]){
            currencyLegalEntityMap.put(curLegal.DeveloperName,curLegal.CWS_Legal_Entity__c);
        }
         return currencyLegalEntityMap;
   }
   
    /* Method name  : afterInsertMethod
    *  Parameter    : Opportunity Map
    *  Return Type  : Void
    *  Developer    : Manoj
    *  User Story   : BED-8750
    */
    public static void afterInsertMethod(Map<Id, Opportunity> newItems){
        //Added by - Mahak Bansal- OBD-601 - To reduce SOQL 
        createFollowUpTasks(newItems.keyset());
    //The below mentioned code is moved to another method. - Mahak Bansal- OBD-601 - To reduce SOQL 
   /* try{
    List<Task> followUpTasks = new List<Task>();
        for (Opportunity opp: newItems.values()){
        
            if ((opp.Type == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT || opp.Type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS 
                || opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC || opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) ){                    
                Task followUpTask = new Task();              
                followUpTask.ActivityDate = Date.Today().addDays(5);        
                followUpTask.Priority = CWS_ConstantClass.Priority_Normal;           
                followUpTask.Subject = CWS_ConstantClass.Task_Subject;
                followUpTask.Type = CWS_ConstantClass.FollowUp_Type;
                followUpTask.Description = opp.CWS_Task_Comments__c;
                followUpTask.WhatId = opp.Id;
                followUpTask.OwnerId = opp.OwnerID;
                followUpTasks.add(followUpTask);
            }
        }
        if(!followUpTasks.isEmpty()){            
            List<Database.SaveResult> taskInsert = Database.insert(followUpTasks);
            CWS_ExceptionHandler.logDMLSaveResults(taskInsert, 'CWS_OpportunityTriggerHelper', 'afterInsertMethod', 'Task', null, null);
        }
    }
    catch(Exception e){
        CWS_EXceptionHandler.logException( e,'Opportunity' , 'CWS_OpportunityTriggerHelper' , 'afterUpdateMethod' ,'', null , null ,'afterUpdate' , null);
    }*/
    }
    
    //BED-13043 Method to get group members Associated to groups:
    public static List<groupmember> fetchGrpMems(List<String> grpNames){
        return [SELECT userorgroupid,group.DeveloperName 
                FROM Groupmember 
                WHERE group.DeveloperName IN:grpNames AND userorgroupid =: userInfo.getUserId()];
        
        }
    
    /**
    * Added by Mahak Bansal- OBD-601
    * @description Create Follow Up tasks post insertion of Opportunity
    * The future method have been created in order to reduce the SOQL queries from Opportunity 
    * This task creation, can be done asynchrously as soon as resources are available. 
    * @params opportunitySet - Stors the list of Opportunity, where task are to be created
    * */ 
    @future
    public static void createFollowUpTasks(Set<Id> opportunitySet){
        try{
            List<Opportunity> newItems=[SELECT ID,Type,CWS_Task_Comments__c,OwnerId 
                                        FROM Opportunity 
                                        WHERE ID IN:opportunitySet];
            List<Task> followUpTasks = new List<Task>();
                for (Opportunity opp: newItems){
                
                    if ((opp.Type == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT || opp.Type == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS 
                        || opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC || opp.Type == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) ){                    
                        Task followUpTask = new Task();              
                        followUpTask.ActivityDate = Date.Today().addDays(5);        
                        followUpTask.Priority = CWS_ConstantClass.Priority_Normal;           
                        followUpTask.Subject = CWS_ConstantClass.Task_Subject;
                        followUpTask.Type = CWS_ConstantClass.FollowUp_Type;
                        followUpTask.Description = opp.CWS_Task_Comments__c;
                        followUpTask.WhatId = opp.Id;
                        followUpTask.OwnerId = opp.OwnerID;
                        followUpTasks.add(followUpTask);
                    }
                }
                if(!followUpTasks.isEmpty()){            
                    List<Database.SaveResult> taskInsert = Database.insert(followUpTasks);
                    CWS_ExceptionHandler.logDMLSaveResults(taskInsert, 'CWS_OpportunityTriggerHelper', 'afterInsertMethod', 'Task', null, null);
                }
            }
            catch(Exception e){
                CWS_EXceptionHandler.logException( e,'Opportunity' , 'CWS_OpportunityTriggerHelper' , 'afterUpdateMethod' ,'', null , null ,'afterUpdate' , null);
            }
    }

    /**
    * Added by Mahak Bansal- OBD-601
    * @description Send Lost Opportunity email to Oppportunity Team members
    * The method is a future method, the emails would be sent asynchronously, as soon as the resouces are available, would not hamper 
    * Opportunity Trigger insertion/Updation. REDUCE SOQL Queries in a transaction
    * @params lostOpportunity - all the lost opportunity, where status is closed Lost
    * */ 
    @future
    public static void sendLostOppEmail(Set<Id> lostOpportunity){       
        try{
            List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();
            List<Opportunity> lostOppList= [SELECT Id,CWS_Opportunity_No__c, 
                                                (SELECT Id,User.email
                                                FROM OpportunityTeamMembers) 
                                            FROM OPPORTUNITY
                                            WHERE Id IN :lostOpportunity  WITH SECURITY_ENFORCED];
           
            Map<Id,List<String>> oppMemmberMap=new Map<Id,List<String>>();
            List<String> otmEmails=new List<String>();
            for(Opportunity opp:lostOppList){ 
                if(opp.OpportunityTeamMembers.size()>0){   
                    for(OpportunityTeamMember oppTeamMem:opp.OpportunityTeamMembers){
                        otmEmails.add(oppTeamMem.user.email);
                    }         
                    oppMemmberMap.put(opp.Id,otmEmails);
                }
            }

            for(Opportunity opp:lostOppList){
                if(oppMemmberMap.containsKey(opp.Id)){
                    Messaging.SingleEmailMessage emails = new Messaging.SingleEmailMessage();
                    List<String> sendTo = oppMemmberMap.get(opp.Id);                
                    String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
                    emails.setToAddresses(sendTo);
                    emails.setSubject('OPPORTUNITY UPDATED TO CLOSED LOST');
                    string body = '<p>Hi Team,</p>' + '<p>'+opp.CWS_Opportunity_No__c+' has been moved to closed lost.  </p>';
                    emails.setHtmlBody(body); 
                    listEmails.add(emails);
                }            
            }        
            if(listEmails.size()>0 && listEmails!=null){
                Messaging.SendEmail(listEmails); 
            }  
           
        }
        catch(Exception e){
            CWS_EXceptionHandler.logException( e,'Opportunity' , 'CWS_OpportunityTriggerHelper' , 'sendLostOppEmail' ,'', null , null ,'afterUpdate' , null);
        }
    }
}