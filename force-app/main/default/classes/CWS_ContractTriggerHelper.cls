/*Class Name: CWS_ContractTriggerHelper
*Description: Handler Class for Quote Trigger
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Karthikeyan            04/03/2020           BED-3402           Copy Renewal Type on Quote to Contract.
*Khayam                 5/11/2020           BED-10611           Copy Sold To and Bill To Contact on Contract.
*Abhishek               5/22/2020           BED-568           Logged In User Region and Account Region should Be same.
*/

public class CWS_ContractTriggerHelper{
    //BED-3402 - Update Renewal Type on Contract from Quote.
    Public static void beforeInsertHelper(List<Contract> newItems){
        try{
            Set<Id> quoteIds=new Set<Id>();
            Map<Id, SBQQ__Quote__c> mapQuote;
            Map<Id, Account> mapAccount;
            Set<Id> accountIds=new Set<Id>();
            for(Contract contract: newItems){
                quoteIds.add(contract.SBQQ__Quote__c);
                accountIds.add(contract.AccountId);
                if(contract.CWS_Bill_To_Account__c!=null){
                    accountIds.add(contract.CWS_Bill_To_Account__c);
                }
            }
            if(!quoteIds.isEmpty()){
                mapQuote=new Map<Id, SBQQ__Quote__c>([Select Id, Name,SBQQ__PaymentTerms__c, CWS_Renewal_Type__c, SBQQ__Account__c,SBQQ__NetAmount__c,
                                                    SBQQ__Account__r.ownerId,CWS_Additional_Terms_Clauses__c,CWS_SAT_GAT__c,SBQQ__BillingFrequency__c,SBQQ__RegularAmount__c,
                                                    CWS_BA_Agreement__c,CWS_Quote_Type__c,CWS_NDA_Agreement__c,CWS_MSA_Agreement__c,CWS_Ship_To_Account__c,CWS_Ship_To_Contact__c,
                                                    CWS_Legal_Entity__c,CWS_Bill_To_Contact__c,CWS_Route_to_Market__c, SBQQ__PrimaryContact__c, CWS_Tax_VAT__c,CWS_Total_Distributor_Net_Price__c,
                                                    CWS_Bill_To_Account__c, CWS_Transaction_Reason__c, CWS_Conversion_Type__c, SBQQ__Distributor__c,SBQQ__ListAmount__c,
                                                    CWS_Distributor_Fulfillment_Type__c, CWS_Distributor_Category__c, CWS_Reseller_Account__c, SBQQ__CustomerDiscount__c,SBQQ__AdditionalDiscountAmount__c,
                                                    CWS_Contract_Effective_Start_Date__c, CWS_Amendment_Renewal_Reason__c, CWS_Sub_Type__c,CWS_PO_Number__c,CWS_Annualized_Reseller_Net_Total__c,CWS_Annual_End_Customer_Net_Total__c,
                                                    CWS_Annual_Distributor_Net_Total__c, CWS_Prior_Annual_Distributor_Net_Total__c,CWS_Prior_Annual_End_Customer_Net_Total__c,CWS_Prior_Annual_Reseller_Net_Total__c, 
                                                    CWS_Credit_Quote__c, CWS_Rebill_Quote__c,CWS_Secondary_Recipient_Email__c,SBQQ__Partner__c,CWS_Total_Contract_Value__c,CWS_Prior_ACV__c,
                                                    CWS_MNG_Partner_Log_In__c,CWS_IT_Support_Portal_ID__c,CWS_Legacy_MNG_Account_ID__c,CWS_Legacy_Salesforce_Account_ID_18__c,CWS_Pre_payment_Amount__c,
                                                    CWS_Renewal_Uplift_Applicable__c, CWS_Renewal_CAP__c, CWS_Secondary_Recipient_Name__c, SBQQ__PricebookId__c, CWS_Renewal_Category__c,CWS_MRR_Reduction__c,
                                                    CWS_Master__c, CWS_OF_Signed_Date__c, CWS_Legacy_Disti_Factor__c, CWS_Bill_to_Account__r.CWS_Need_Recurring__c,CWS_Temporary_License__c,CWS_Re_Contract_Type__c
                                                    from SBQQ__Quote__c where Id in : quoteIds]);            
            }
            if(!accountIds.isEmpty()){
                mapAccount=new Map<Id, Account>([Select id, Name from Account where id in :accountIds]);
            }
            for(Contract contract:newItems){
                if(contract.SBQQ__Quote__c!=null && mapQuote!=null && mapQuote.get(contract.SBQQ__Quote__c)!=null){
                    contract.CWS_Renewal_Type__c=mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Type__c;
                    contract.Pricebook2Id = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__PricebookId__c;
					
					//Added for the Evergreen Contract(BED-12497)
                    if(contract.SBQQ__Evergreen__c){
                        contract.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Category_SplitPending;
                    }
                    //Added for the Evergreen Contract
    
                    //Added for the Cloned Contract
                    if(contract.CWS_Source__c == null && !(contract.SBQQ__Evergreen__c)){
                    contract.CWS_Renewal_Category__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Category__c;
                    }
                    //Added for the Cloned Contract
					contract.CWS_Temporary_License__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Temporary_License__c;
                    contract.CWS_Total_Regular_Amount__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__RegularAmount__c;
                    contract.CWS_Total_Net_Amount__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__NetAmount__c;
                    contract.CWS_Total_Distributor_Net_Price__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Total_Distributor_Net_Price__c;
                    // start of BED-5294
                    contract.CWS_Total_List_Amount__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__ListAmount__c;
                    contract.CWS_Legacy_MNG_Account_ID__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Legacy_MNG_Account_ID__c;
					contract.CWS_Legacy_Disti_Factor__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Legacy_Disti_Factor__c;
                    contract.CWS_IT_Support_Portal_ID__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_IT_Support_Portal_ID__c;
                    contract.CWS_MNG_Partner_Log_In__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_MNG_Partner_Log_In__c;
                    contract.CWS_Pre_Payment_Amount__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Pre_payment_Amount__c;
                    contract.CWS_Annual_Distributor_Net_Total__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Annual_Distributor_Net_Total__c;
                    contract.CWS_Annual_End_Customer_Net_Total__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Annual_End_Customer_Net_Total__c;
                    contract.CWS_Annual_Reseller_Net_Total__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Annualized_Reseller_Net_Total__c;
                    contract.CWS_Prior_Annualized_ACV__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Prior_ACV__c;
                    contract.CWS_Prior_Annual_Distributor_Net_Total__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Prior_Annual_Distributor_Net_Total__c;
                    contract.CWS_Prior_Annual_End_Customer_Net_Total__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Prior_Annual_End_Customer_Net_Total__c;
                    contract.CWS_Prior_Annual_Reseller_Net_Total__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Prior_Annual_Reseller_Net_Total__c;
                    contract.CWS_Total_End_Customer_Net_Price__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__NetAmount__c;
                    contract.CWS_MRR_Reduction__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_MRR_Reduction__c;
                    contract.CWS_Legacy_Salesforce_Account_ID_18__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Legacy_Salesforce_Account_ID_18__c;
                    contract.CWS_Additional_Disc__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__CustomerDiscount__c;
                    contract.CWS_Addl_Disc_Amount__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__AdditionalDiscountAmount__c;
                    contract.CWS_Total_Contract_Value__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Total_Contract_Value__c;
                    contract.CWS_Tax_VAT__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Tax_VAT__c;
                    contract.CWS_PO_Number__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_PO_Number__c;
                    contract.CWS_Route_to_Market__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Route_to_Market__c;
                    contract.CWS_End_Partner_Account__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__Partner__c;
                    contract.CWS_Quote_Type__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Quote_Type__c;
                    contract.CWS_Legal_Entity__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Legal_Entity__c;
					contract.CWS_Transaction_Reason__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Transaction_Reason__c;
					contract.CWS_TransactionReason__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Transaction_Reason__c;
                    contract.CWS_ConversionType__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Conversion_Type__c;
                    contract.CWS_Ship_To_Account__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Ship_To_Account__c;
                    contract.CWS_Ship_To_Contact__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Ship_To_Contact__c;
                    contract.CWS_MSA_Agreement__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_MSA_Agreement__c;
                    contract.CWS_NDA_Agreement__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_NDA_Agreement__c;
                    contract.CWS_BA_Agreement__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_BA_Agreement__c;
                    contract.CWS_Billing_Frequency__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__BillingFrequency__c;
                    contract.CWS_SAT_GAT__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_SAT_GAT__c;
                    contract.CWS_Additional_Terms_Clauses__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Additional_Terms_Clauses__c;
                    contract.CWS_Distributor__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__Distributor__c;
                    contract.CWS_Distributor_Fulfillment_Type__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Distributor_Fulfillment_Type__c;
                    contract.CWS_Distributor_Category__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Distributor_Category__c;
                    contract.CWS_Reseller_Account__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Reseller_Account__c;
                    contract.CWS_Contract_Effective_Start_Date__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Contract_Effective_Start_Date__c;
                    contract.CWS_Amendment_Renewal_Reason__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Amendment_Renewal_Reason__c;
                    contract.CWS_Quote_Sub_Type__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Sub_Type__c;
                    contract.CWS_Re_Contract_Type__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Re_Contract_Type__c;
                    contract.CWS_Credit_Quote__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Credit_Quote__c;
                    contract.CWS_Rebill_Quote__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Rebill_Quote__c;
                    contract.CWS_Secondary_Recipient_Email__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Secondary_Recipient_Email__c;
                    contract.CWS_Secondary_Recipient_Name__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Secondary_Recipient_Name__c;
					contract.CWS_Master__c=mapQuote.get(contract.SBQQ__Quote__c).CWS_Master__c;
					contract.CWS_OF_Signed_Date__c=mapQuote.get(contract.SBQQ__Quote__c).CWS_OF_Signed_Date__c;
                    if( mapQuote.get(contract.SBQQ__Quote__c).CWS_Bill_to_Account__c!=null &&
                        mapQuote.get(contract.SBQQ__Quote__c).CWS_Bill_to_Account__r.CWS_Need_Recurring__c==true &&
                        contract.CWS_OF_Signed_Date__c!=null){
                        Date tempDate=contract.CWS_OF_Signed_Date__c.addMonths(1);
                        contract.SBQQ__AmendmentStartDate__c=Date.newInstance(tempDate.year(),
                                                                tempDate.month(),1);
                    }					
                    //end of bed- 5294

                    // BED-10611
                    contract.CWS_Bill_To_Contact__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Bill_To_Contact__c;
                    contract.CWS_Sold_To_Contact__c = mapQuote.get(contract.SBQQ__Quote__c).SBQQ__PrimaryContact__c;
                    contract.CWS_Bill_To_Account__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Bill_To_Account__c;

                    if(String.isBlank(contract.CWS_Renewal_Category__c)){
                        contract.CWS_Renewal_Category__c = mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Category__c;
                    }

                    if(String.isBlank(contract.CWS_Renewal_Type__c)){
                    contract.CWS_Renewal_Type__c=mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Type__c;
                    }

                    if((mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Uplift_Applicable__c==0  || 
                        mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Uplift_Applicable__c==null) && 
                       mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_CAP__c==null){
                        contract.CWS_Renewal_Uplift_Applicable__c=null;
                        contract.CWS_Renewal_CAP__c=null;
                    }
                    else if((mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Uplift_Applicable__c==0 ||
                        mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Uplift_Applicable__c==null) &&
                        mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_CAP__c!=null){
                        contract.CWS_Renewal_Uplift_Applicable__c=2;
                        contract.CWS_Renewal_CAP__c=mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_CAP__c;
                    }
                    else if(mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Uplift_Applicable__c!=null &&
                        mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_CAP__c==null){
                        contract.CWS_Renewal_Uplift_Applicable__c=null;
                        contract.CWS_Renewal_CAP__c=null;                            
                    }
                    else if(mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Uplift_Applicable__c!=null &&
                        mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_CAP__c!=null){
                        contract.CWS_Renewal_Uplift_Applicable__c=mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_Uplift_Applicable__c;
                        contract.CWS_Renewal_CAP__c=mapQuote.get(contract.SBQQ__Quote__c).CWS_Renewal_CAP__c;                                
                    }
                }
                //BED-6864 Default payment terms from quote
                if(mapQuote!=null && mapQuote.get(contract.SBQQ__Quote__c)!=null && mapQuote.get(contract.SBQQ__Quote__c).SBQQ__PaymentTerms__c != null){
                    contract.CWS_Payment_Term__c=mapQuote.get(contract.SBQQ__Quote__c).SBQQ__PaymentTerms__c;
                }
                if(contract.startDate!=null && contract.contractTerm!=null && contract.CWS_Renewal_Type__c!=CWS_ConstantClass.Renewal_Type_NonRenewable){
                    if(contract.startDate.month()==2 && contract.startDate.day()==29 ){
                        contract.CWS_Renewal_Opportunity_Schedule__c= contract.startDate.addMonths(contract.ContractTerm)-120;
                        contract.CWS_Renewal_Quote_Schedule__c= contract.startDate.addMonths(contract.ContractTerm)-30;
                    }
                    else{
                        contract.CWS_Renewal_Opportunity_Schedule__c= contract.startDate.addMonths(contract.ContractTerm)-121;
                        contract.CWS_Renewal_Quote_Schedule__c= contract.startDate.addMonths(contract.ContractTerm)-31;
                    }
                }
				if(contract.AccountId!=null && mapAccount!=null && mapAccount.containsKey(contract.AccountId) ){
                    contract.CWS_Name__c=mapAccount.get(contract.AccountId).Name + ' ' +
                        (contract.CWS_Route_to_Market__c!=null? contract.CWS_Route_To_Market__c+ ' ': '') +
                        (contract.SBQQ__Evergreen__c ? 'Evergreen'+' ':((contract.CWS_Renewal_Category__c!=null && 
                        contract.CWS_Renewal_Category__c!=CWS_ConstantClass.Renewal_Category_SplitPending)? 
                        contract.CWS_Renewal_Category__c +' ': '')) +
                        ((contract.CWS_Bill_to_Account__c!=null && contract.CWS_Bill_to_Account__c!=contract.AccountId &&
                        mapAccount.containsKey(contract.CWS_Bill_to_Account__c))?
                        mapAccount.get(contract.CWS_Bill_to_Account__c).Name+' ':'')+
                         'Multiple Contract';
                }
                //BED-7734
                contract.SBQQ__RenewalTerm__c=12;
            }
        }
        catch(Exception exp){
            CWS_ExceptionHandler.logException( exp,'CWS_ContractTriggerHelper' , 'CWS_ContractTriggerHelper', 'beforeInsertHelper' , '', null, null , 'BeforeInsert' , null);
        }
    }
    
    //BED-3402 - Update Renewal 
    Public static void beforeUpdateHelper(Map<Id, Contract> newMap, Map<Id, Contract> oldMap){
        try{
            Set<Id> renewalOpportunityIds=new Set<Id>();
            Map<Id, Opportunity> mapRenewalOpportunity;
            Set<Id> orderIds=new Set<Id>();
            Map<Id, Order> mapOrder;
            // BED 568 Variables - Do not use for Other Functionality
            Set<Id> soldtoAccountIds=new Set<Id>();
            Map<Id,Account> accountMap = new Map<Id,Account>();
            Map<Id,Account> accountNameMap = new Map<Id,Account>();
            Map<Id,Set<String>> userRegion= new Map<Id,Set<String>>();
            Id loggedUser=userInfo.getUserId();
            Set<Id> accountIds=new Set<Id>();
            for(Contract contract:newMap.values()){
                if((contract.CWS_Renewal_Category__c!=CWS_ConstantClass.Renewal_Category_SplitPending && 
                    contract.CWS_Renewal_Category__c!=oldMap.get(contract.Id).CWS_Renewal_Category__c) ||
                    contract.CWS_Route_to_Market__c!=oldMap.get(contract.Id).CWS_Route_to_Market__c ||
                    contract.CWS_Product_Categories__c!=oldMap.get(contract.Id).CWS_Product_Categories__c ||
                    contract.CWS_Bill_to_Account__c!=oldMap.get(contract.Id).CWS_Bill_to_Account__c){
                        accountIds.add(contract.AccountId);
                        if(contract.CWS_Bill_to_Account__c!=null){
                            accountIds.add(contract.CWS_Bill_to_Account__c);
                        }
                }
                if(contract.startDate!=null && contract.contractTerm!=null &&
                    (contract.StartDate!=oldMap.get(contract.Id).StartDate|| 
                        contract.ContractTerm!=oldMap.get(contract.Id).ContractTerm ||
                        (contract.CWS_Renewal_Type__c!=CWS_ConstantClass.Renewal_Type_NonRenewable && 
                        contract.CWS_Renewal_Type__c!=oldMap.get(contract.Id).CWS_Renewal_Type__c) )){
                    renewalOpportunityIds.add(contract.SBQQ__RenewalOpportunity__c);
                }
                //Start BED 568 : Renewal Or Renewal Forcast Flag Check
                if(contract.CWS_Renewal_Type__c!=CWS_ConstantClass.Renewal_Type_NonRenewable
                    && ((contract.SBQQ__RenewalForecast__c && !oldMap.get(contract.Id).SBQQ__RenewalForecast__c)
                    || (contract.SBQQ__RenewalQuoted__c && !oldMap.get(contract.Id).SBQQ__RenewalQuoted__c))){
                        soldtoAccountIds.add(contract.AccountId);
                }
                // End BED 568
                
                /**
                 * Integration Requirement: Copy the original order information
                 * @Developer: swachatterjee
                 */
                 // Since the order id changes on each amenemdment
                 // Copy the Order id on before insert from the Contract's Order lookup to
                 // Original Order lookup
                 if(contract.SBQQ__Order__c<>null && oldMap.get(Contract.Id).SBQQ__Order__c==null) {
                     contract.CWS_OriginalOrder__c = contract.SBQQ__Order__c;
                 } 
                 // Integration logic ends
                 orderIds.add(contract.SBQQ__Order__c);
            }      
            if(!renewalOpportunityIds.isEmpty()){
                mapRenewalOpportunity=new Map<Id, Opportunity>([Select Id, SBQQ__PrimaryQuote__c, StageName
                                                                from Opportunity 
                                                                where id in: renewalOpportunityIds]);
            }
            //Start BED 568 : Getting User Id and Region Map based on Public group and Metadata and related Account Region.
            if(!soldtoAccountIds.isEmpty()){
                if(loggedUser != null){
                    User userObj=[select id,Profile.Name from user where id=:loggedUser ];
                    if(userObj.Profile.Name !=CWS_ConstantClass.SysAdminProfile 
                        && userObj.Profile.Name !=CWS_ConstantClass.ContractAdminProfile 
                        && userObj.Profile.Name !=CWS_ConstantClass.GlobalSalesOpsProfile ){
                        
                        userRegion=CWS_CommonUtility.getGroupMemberRegion(new list<Id>{userObj.id});
                        
                        accountMap = new Map<Id,Account>([SELECT Id,CWS_Region__c 
                                                            from Account 
                                                            where Id in : soldtoAccountIds]);
                    }
                }
                system.debug('@@@@userRegion'+userRegion);
                system.debug('@@@@accountMap'+accountMap);
            }
            if(!accountIds.isEmpty()){
                accountNameMap=new Map<Id, Account>([Select id, Name from Account where id in :accountIds]);
            }
             // End BED 568
            if(!orderIds.isEmpty()){
                mapOrder=new Map<Id, Order>([Select id, CWS_Order_Start_Date__c from Order where id in :orderIds]);
            }
            for(Contract contract:newMap.values()){
                if(accountNameMap!=null && accountNameMap.containsKey(contract.AccountId) && 
                    ((contract.CWS_Renewal_Category__c!=CWS_ConstantClass.Renewal_Category_SplitPending && 
                    contract.CWS_Renewal_Category__c!=oldMap.get(contract.Id).CWS_Renewal_Category__c) ||
                    contract.CWS_Route_to_Market__c!=oldMap.get(contract.Id).CWS_Route_to_Market__c ||
                    contract.CWS_Product_Categories__c!=oldMap.get(contract.Id).CWS_Product_Categories__c ||
                    contract.SBQQ__Evergreen__c!=oldMap.get(contract.Id).SBQQ__Evergreen__c ||
                    contract.CWS_Bill_to_Account__c!=oldMap.get(contract.Id).CWS_Bill_to_Account__c)){
                        contract.CWS_Name__c=accountNameMap.get(contract.AccountId).Name + ' ' +
                            (contract.CWS_Route_to_Market__c!=null? contract.CWS_Route_To_Market__c+ ' ': '') +
                            (contract.SBQQ__Evergreen__c ? 'Evergreen'+' ':((contract.CWS_Renewal_Category__c!=null && 
                                contract.CWS_Renewal_Category__c!=CWS_ConstantClass.Renewal_Category_SplitPending)? 
                                contract.CWS_Renewal_Category__c +' ': '')) +
                            ((contract.CWS_Bill_to_Account__c!=null && contract.CWS_Bill_to_Account__c!=contract.AccountId &&
                            accountNameMap.containsKey(contract.CWS_Bill_to_Account__c))?
                                accountNameMap.get(contract.CWS_Bill_To_Account__c).Name +' ':'') +
                            ((contract.CWS_Product_Categories__c!=null && String.valueOf(contract.CWS_Product_Categories__c).split(';')!=null && 
                                String.valueOf(contract.CWS_Product_Categories__c).split(';').size()==1)?
                                String.valueOf(contract.CWS_Product_Categories__c).removeEnd(';'):'Multiple Contract');
                }
                if( contract.startDate!=null && contract.contractTerm!=null && contract.CWS_Renewal_Type__c!=CWS_ConstantClass.Renewal_Type_NonRenewable &&
                    (contract.StartDate!=oldMap.get(contract.Id).StartDate|| 
                     contract.ContractTerm!=oldMap.get(contract.Id).ContractTerm  || 
                     (contract.CWS_Renewal_Type__c!=CWS_ConstantClass.Renewal_Type_NonRenewable && 
                    contract.CWS_Renewal_Type__c!=oldMap.get(contract.Id).CWS_Renewal_Type__c) )){
                    if(contract.SBQQ__RenewalOpportunity__c==null){
                           if(contract.startDate.month()==2 && contract.startDate.day()==29 ){
                               contract.CWS_Renewal_Opportunity_Schedule__c= contract.startDate.addMonths(contract.ContractTerm)-120;
                           }
                           else{
                               contract.CWS_Renewal_Opportunity_Schedule__c= contract.startDate.addMonths(contract.ContractTerm)-121;
                           }
                    }
                    if((contract.SBQQ__RenewalOpportunity__c==null || (contract.SBQQ__RenewalOpportunity__c!=null && 
                           mapRenewalOpportunity.containsKey(contract.SBQQ__RenewalOpportunity__c) && 
                           mapRenewalOpportunity.get(contract.SBQQ__RenewalOpportunity__c)!=null && 
                           mapRenewalOpportunity.get(contract.SBQQ__RenewalOpportunity__c).SBQQ__PrimaryQuote__c==null))){
                           if(contract.startDate.month()==2 && contract.startDate.day()==29 ){
                               contract.CWS_Renewal_Quote_Schedule__c= contract.startDate.addMonths(contract.ContractTerm)-30;
                           }
                           else{
                               contract.CWS_Renewal_Quote_Schedule__c= contract.startDate.addMonths(contract.ContractTerm)-31;
                           }
                    }
                }
                // Start BED 568 Checking if Account and User Region is Same.
                if(!accountMap.isEmpty()){
                    if(userRegion.isEmpty() 
                                || (!userRegion.isEmpty()
                                    && userRegion.get(userinfo.getUserId())!=Null 
                                    && !userRegion.get(userinfo.getUserId()).contains(accountMap.get(contract.accountId).CWS_Region__c))){
                        contract.addError(Label.CWS_RenewalRegionCheck);
                    }
                }
                //End BED 568 
                if(contract.SBQQ__Order__c!=null && mapOrder!=null && mapOrder.get(contract.SBQQ__Order__c)!=null && contract.SBQQ__Evergreen__c && contract.SBQQ__Order__c == contract.CWS_OriginalOrder__c){
                    contract.startdate = mapOrder.get(contract.SBQQ__Order__c).CWS_Order_Start_Date__c;
                }
            }
        }
        catch(Exception exp){
          CWS_ExceptionHandler.logException( exp,'CWS_ContractTriggerHelper' , 'CWS_ContractTriggerHelper', 'beforeUpdateHelper' , '', null, null , 'BeforeUpdate' , null);
        }
    }
}