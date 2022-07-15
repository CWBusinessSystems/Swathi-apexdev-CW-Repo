/*Class Name: CWS_SubsTriggerHelper
*Description: Helper Class for CWS_SubscriptionHandler
*Created By: Aakash Sharma
*Created On: 4/10/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aakash                 4/10/2020        BED-5894               After Insert Event : Subscription's ACV Roll-up on the Contract ACV field
*Ankit                  7/8/2020         BED-8940               Default Quantity on in Original Quantity field, Once Quantity is changed on say Renewal/Amendemnt will be used for reference 
*Mahak Bansal           19/1/2022        OBD-3379               Salesforce downgrades not reflecting in zuora invoicing
*Mahak Bansal           17/2/2022        OBD-2231               Renewal Product with change shoudl be used while calculating Renewal Products
*/

public with sharing class CWS_SubsTriggerHelper{
     
     
    public static void beforeInsertHelper(List<SBQQ__Subscription__c> newItems){
        try{
            Set<Id> accountIds=new Set<Id>();
            Set<Id> quoteLineIds=new Set<Id>();
            Map<Id, Account> accountMap;
            Map<Id, SBQQ__QuoteLine__c> quoteLineMap;
            for(SBQQ__Subscription__c sub: newItems){
                accountIds.add(sub.SBQQ__Account__c);
                quoteLineIds.add(sub.SBQQ__QuoteLine__c);
                //BED-8940 to Default Quantity on in Original Quantity field, Once Quantity is changed on say Renewal/Amendemnt will be used for reference 
                sub.CWS_Original_Quantity__c = sub.SBQQ__Quantity__c;
            }
            if(accountIds!=null && !accountIds.isEmpty() ){
                accountMap=new Map<Id, Account>([Select Id, Name, CWS_Region__c from Account where id in :accountIds]);
            }
            if(quoteLineIds!=null && !quoteLineIds.isEmpty() ){
                quoteLineMap=new Map<Id, SBQQ__QuoteLine__c>([Select Id, Name, CWS_Calculated_Subscription_Term__c, CWS_NetTotal__c
                         from SBQQ__QuoteLine__c where Id in :quoteLineIds ]);           
            }
            for(SBQQ__Subscription__c sub: newItems){
                if(sub.SBQQ__Account__c!=null && accountMap!=null && accountMap.containsKey(sub.SBQQ__Account__c)){
                    sub.CWS_Region__c=accountMap.get(sub.SBQQ__Account__c).CWS_Region__c;
                }
                if(sub.SBQQ__QuoteLine__c!=null && quoteLineMap!=null && quoteLineMap.containsKey(sub.SBQQ__QuoteLine__c)){
                    sub.CWS_Subscription_Term__c=quoteLineMap.get(sub.SBQQ__QuoteLine__c).CWS_Calculated_Subscription_Term__c;
                    sub.CWS_QLNet_Total__c=quoteLineMap.get(sub.SBQQ__QuoteLine__c).CWS_NetTotal__c;
                }
            }
 
        }
        catch(Exception e){
             CWS_ExceptionHandler.logException( e,'Contract' , 'CWS_SubsTriggerHelper','beforeInsertHelper' ,
                                               '', null, null , 'BeforeInsert' , null);
        }
    }
    
     /*
     * Method name  : afterInsertHelper
     * Description  : BED-5894 : Subscription's ACV Roll-up on the Contract ACV field
     * Parameter    : List of new Quotes.
     * Return Type  : None
     * Developer    : Aakash Sharma
     */
     Public static void afterInsertHelper(Map<Id,SObject> newMap){
          system.debug('Entering afterInsertHelper');
          
          //New Map of Subscription
         Map<Id,SBQQ__Subscription__c> newSMap = (Map<Id,SBQQ__Subscription__c>) newMap;
         //Set of contracts
         set<id> setSubsIDs=new set<id>();
         set<id> setContracts=new set<id>();
         list <SBQQ__Subscription__c> lstSubs = new list <SBQQ__Subscription__c>();
         list<Contract> lstContracts = new list<Contract>();
         map<id,decimal> mapContracts= new map<id,decimal>();
         map<id,decimal> mapMarginContracts= new map<id,decimal>();
          Set<Id> originalSubs=new Set<Id>();
          Map<Id, Integer> mapActiveSubsCount=new Map<Id, Integer>();
          Map<Id,Decimal> mapContractSubsType = new Map<Id,Decimal>();
         Map<Id, String> mapContractCategories=new Map<Id, String>();		 
          //Map<Id,String> MapContRT=new Map<id,String>();
         for(SBQQ__Subscription__c subs:newSMap.Values())
         {
          setSubsIDs.add(subs.id);
          setContracts.add(subs.SBQQ__Contract__c);
          if(subs.SBQQ__TerminatedDate__c!=null && subs.SBQQ__RevisedSubscription__c!=null){
              originalSubs.add(subs.SBQQ__RevisedSubscription__c);
          }
         }
         system.debug('setSubsIDs '+setSubsIDs);
         if(setSubsIDs.size()>0 && setSubsIDs!=null){
           lstSubs = [select id,SBQQ__Contract__r.CWS_Contract_ACV__c,SBQQ__Contract__c,CWS_ACVLine__c,SBQQ__Contract__r.CWS_Margin__c,CWS_Margin__c,SBQQ__Contract__r.CWS_Renewal_Type__c,CWS_Renewal_Type__c,
                     SBQQ__Contract__r.CWS_Total_Reseller_Net_Price__c,SBQQ__Contract__r.CWS_Total_Distributor_Net_Price__c,SBQQ__Contract__r.CWS_Total_Net_Amount__c,
                                 SBQQ__Contract__r.CWS_Total_Regular_Amount__c,SBQQ__Contract__r.CWS_Total_List_Amount__c,SBQQ__Contract__r.CWS_Prior_Annual_Reseller_Net_Total__c,
                                 SBQQ__Contract__r.CWS_Prior_Annual_Distributor_Net_Total__c,SBQQ__Contract__r.CWS_Prior_Annual_End_Customer_Net_Total__c,
                                 SBQQ__Contract__r.CWS_Prior_Annualized_ACV__c,SBQQ__Contract__r.CWS_Annual_Reseller_Net_Total__c,SBQQ__Contract__r.CWS_Annual_Distributor_Net_Total__c,
                                 SBQQ__Contract__r.CWS_Annual_End_Customer_Net_Total__c,SBQQ__Contract__r.CWS_Total_Contract_Value__c,SBQQ__Contract__r.CWS_Addl_Disc_Amount__c,
                                 SBQQ__Contract__r.CWS_Additional_Disc__c,SBQQ__Discount__c,CWS_Reseller_Net_Price__c,SBQQ__AdditionalDiscountAmount__c,SBQQ__NetPrice__c,
                                 CWS_Annualized_End_Customer_Net_Total__c,CWS_Annualized_Distributor_Net_Total__c,CWS_Annualized_Reseller_Net_Total__c,CWS_Prior_Annualized_ACV__c,
                                 CWS_Prior_Annual_End_Customer_Net_Total__c,CWS_Prior_Annual_Distributor_Net_Total__c,CWS_Prior_Annual_Reseller_Net_Total__c,SBQQ__ListPrice__c,
                                 SBQQ__RegularPrice__c,CWS_QLNet_Total__c,CWS_Distributor_Net_Price__c,SBQQ__QuoteLine__r.CWS_Quote_Type__c, SBQQ__QuoteLine__c,
                     SBQQ__SubscriptionType__c,CWS_Transaction_Type__c,SBQQ__Contract__r.CWS_Renewable_Products__c from SBQQ__Subscription__c where Id in:setSubsIDs];
                     }
         Integer count;
         if( !setContracts.isEmpty()){
             for(SBQQ__Subscription__c subs:[Select Id, name, SBQQ__Contract__c,CWS_Category__c,
                                             SBQQ__TerminatedDate__c,CWS_Margin__c 
                                             from SBQQ__Subscription__c where SBQQ__Contract__c in :setContracts  ]){
                 if(!originalSubs.contains(subs.Id)){
                     if(!mapActiveSubsCount.containsKey(subs.SBQQ__Contract__c)){
                         mapActiveSubsCount.put(subs.SBQQ__Contract__c,0);
                     }
                     if(subs.SBQQ__TerminatedDate__c==null){
                         count=mapActiveSubscount.get(subs.SBQQ__Contract__c)+1;
                         mapActiveSubsCount.put(subs.SBQQ__Contract__c,count);
                     }
                 }
                 if(subs.SBQQ__Contract__c!=null && subs.CWS_Category__c!=null){
                     if(mapContractCategories.get(subs.SBQQ__Contract__c)!=null && 
                         !String.valueOf(mapContractCategories.get(subs.SBQQ__Contract__c)).contains(subs.CWS_Category__c)){
                         mapContractCategories.put(subs.SBQQ__Contract__c, 
                             mapContractCategories.get(subs.SBQQ__Contract__c)+';'+subs.CWS_Category__c);
                     }
                     else if(mapContractCategories.get(subs.SBQQ__Contract__c)==null){
                         mapContractCategories.put(subs.SBQQ__Contract__c, subs.CWS_Category__c);
                     }
                 }
             }
         }
         try{
                 if(lstSubs.size()>0){
                     for(SBQQ__Subscription__c subs :lstSubs)
                     {   
                        if(Subs.SBQQ__Contract__c != null 
                        && Subs.SBQQ__SubscriptionType__c != CWS_ConstantClass.ChargeType_OneTime 
                        && Subs.CWS_Transaction_Type__c != null 
                        && (Subs.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW
                        || Subs.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3 
                        || Subs.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON 
                        || (Subs.SBQQ__QuoteLine__c !=null 
                        && Subs.SBQQ__QuoteLine__r.CWS_Quote_Type__c !=null 
                        && Subs.SBQQ__QuoteLine__r.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL
                        || Subs.SBQQ__QuoteLine__r.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC //Added by Mahak Bansal - OBD-2231
                        ))){
                            Decimal RenewableProducts=0;
                             if(Subs.SBQQ__Contract__r.CWS_Renewable_Products__c == 0 && !mapContractSubsType.containsKey(Subs.SBQQ__Contract__c)){
                                 RenewableProducts++;
                                 System.debug(RenewableProducts);
                                 mapContractSubsType.put(Subs.SBQQ__Contract__c,RenewableProducts);
                                 system.debug(mapContractSubsType.containsKey(Subs.SBQQ__Contract__c));
                             }
                             else{
                                 if(mapContractSubsType.containsKey(Subs.SBQQ__Contract__c))
                                 {
                                 RenewableProducts=mapContractSubsType.get(Subs.SBQQ__Contract__c);
                                 RenewableProducts++;
                                 System.debug(RenewableProducts);
                                 mapContractSubsType.put(Subs.SBQQ__Contract__c,RenewableProducts);
                                 }
                                 else{
                                 RenewableProducts=Subs.SBQQ__Contract__r.CWS_Renewable_Products__c;
                                 RenewableProducts++;
                                 System.debug(RenewableProducts);
                                 mapContractSubsType.put(Subs.SBQQ__Contract__c,RenewableProducts);
                                 }
                             }
                         }
                         if(Subs.SBQQ__Contract__c != null && Subs.SBQQ__SubscriptionType__c != CWS_ConstantClass.ChargeType_OneTime && Subs.CWS_Transaction_Type__c != null && Subs.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL){
                             Decimal RenewableProducts=0;
                             if(Subs.SBQQ__Contract__r.CWS_Renewable_Products__c != null){
                                 RenewableProducts=Subs.SBQQ__Contract__r.CWS_Renewable_Products__c;
                                 RenewableProducts--;
                                 System.debug(RenewableProducts);
                                 mapContractSubsType.put(Subs.SBQQ__Contract__c,RenewableProducts);
                             }
                         }
                         System.debug(mapContractSubsType);
 
                         if(mapContracts.containsKey(subs.SBQQ__Contract__c)){
                             if(subs.SBQQ__Contract__r.CWS_Contract_ACV__c != null){
                                     Decimal decmargin = subs.CWS_Margin__c<>null?subs.CWS_Margin__c:0.0d;
                                     decimal tempDec=mapContracts.get(subs.SBQQ__Contract__c) + subs.CWS_ACVLine__c;
                                     decimal tempMar=mapMarginContracts.get(subs.SBQQ__Contract__c) + decmargin;
                                     mapContracts.put(subs.SBQQ__Contract__c,tempDec);
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,tempMar); //Added for 5662
                             }
                         }
                         else
                         { 
                                 if(subs.SBQQ__Contract__r.CWS_Contract_ACV__c==null){
                                 subs.SBQQ__Contract__r.CWS_Contract_ACV__c=0;
                                 }
                                 if(subs.CWS_ACVLine__c!=null){
                                     subs.SBQQ__Contract__r.CWS_Contract_ACV__c+=subs.CWS_ACVLine__c;
                                     mapContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Contract_ACV__c);
                                     }
                                 //Added for 5662 
                                 if(subs.SBQQ__Contract__r.CWS_Margin__c==null){
                                     subs.SBQQ__Contract__r.CWS_Margin__c=0;
                                     }
                             
                                 if(subs.CWS_Margin__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Margin__c+=subs.CWS_Margin__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Margin__c); 
                                 } 
                             }
                         
                           if(subs.SBQQ__Contract__r.CWS_Additional_Disc__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Additional_Disc__c=0;
                                     }
                             
                                 if(subs.SBQQ__Discount__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Additional_Disc__c+=subs.SBQQ__Discount__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Additional_Disc__c); 
                                 } 
                                 
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Addl_Disc_Amount__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Addl_Disc_Amount__c=0;
                                     }
                             
                                 if(subs.SBQQ__AdditionalDiscountAmount__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Addl_Disc_Amount__c+=subs.SBQQ__AdditionalDiscountAmount__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Addl_Disc_Amount__c); 
                                 } 
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Total_Contract_Value__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Total_Contract_Value__c=0;
                                     }
                             
                                 if(subs.SBQQ__NetPrice__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Total_Contract_Value__c+=subs.SBQQ__NetPrice__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Total_Contract_Value__c); 
                                 } 
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Annual_End_Customer_Net_Total__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Annual_End_Customer_Net_Total__c=0;
                                     }
                             
                                 if(subs.CWS_Annualized_End_Customer_Net_Total__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Annual_End_Customer_Net_Total__c+=subs.CWS_Annualized_End_Customer_Net_Total__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Annual_End_Customer_Net_Total__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Annual_Distributor_Net_Total__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Annual_Distributor_Net_Total__c=0;
                                     }
                             
                                 if(subs.CWS_Annualized_Distributor_Net_Total__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Annual_Distributor_Net_Total__c+=subs.CWS_Annualized_Distributor_Net_Total__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Annual_Distributor_Net_Total__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Annual_Reseller_Net_Total__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Annual_Reseller_Net_Total__c=0;
                                     }
                             
                                 if(subs.CWS_Annualized_Reseller_Net_Total__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Annual_Reseller_Net_Total__c+=subs.CWS_Annualized_Reseller_Net_Total__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Annual_Reseller_Net_Total__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Prior_Annualized_ACV__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Prior_Annualized_ACV__c=0;
                                     }
                             
                                 if(subs.CWS_Prior_Annualized_ACV__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Prior_Annualized_ACV__c+=subs.CWS_Prior_Annualized_ACV__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Prior_Annualized_ACV__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Prior_Annual_End_Customer_Net_Total__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Prior_Annual_End_Customer_Net_Total__c=0;
                                     }
                             
                                 if(subs.CWS_Prior_Annual_End_Customer_Net_Total__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Prior_Annual_End_Customer_Net_Total__c+=subs.CWS_Prior_Annual_End_Customer_Net_Total__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Prior_Annual_End_Customer_Net_Total__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Prior_Annual_Distributor_Net_Total__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Prior_Annual_Distributor_Net_Total__c=0;
                                     }
                             
                                 if(subs.CWS_Prior_Annual_Distributor_Net_Total__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Prior_Annual_Distributor_Net_Total__c+=subs.CWS_Prior_Annual_Distributor_Net_Total__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Prior_Annual_Distributor_Net_Total__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Prior_Annual_Reseller_Net_Total__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Prior_Annual_Reseller_Net_Total__c=0;
                                     }
                             
                                 if(subs.CWS_Prior_Annual_Reseller_Net_Total__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Prior_Annual_Reseller_Net_Total__c+=subs.CWS_Prior_Annual_Reseller_Net_Total__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Prior_Annual_Reseller_Net_Total__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Total_List_Amount__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Total_List_Amount__c=0;
                                     }
                             
                                 if(subs.SBQQ__ListPrice__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Total_List_Amount__c+=subs.SBQQ__ListPrice__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Total_List_Amount__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Total_Regular_Amount__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Total_Regular_Amount__c=0;
                                     }
                             
                                 if(subs.SBQQ__RegularPrice__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Total_Regular_Amount__c+=subs.SBQQ__RegularPrice__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Total_Regular_Amount__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Total_Net_Amount__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Total_Net_Amount__c=0;
                                     }
                             
                                 if(subs.CWS_QLNet_Total__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Total_Net_Amount__c+=subs.CWS_QLNet_Total__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Total_Net_Amount__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Total_Distributor_Net_Price__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Total_Distributor_Net_Price__c=0;
                                     }
                             
                                 if(subs.CWS_Distributor_Net_Price__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Total_Distributor_Net_Price__c+=subs.CWS_Distributor_Net_Price__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Total_Distributor_Net_Price__c); 
                                 }
                                 //next field
                                  if(subs.SBQQ__Contract__r.CWS_Total_Reseller_Net_Price__c ==null){
                                     subs.SBQQ__Contract__r.CWS_Total_Reseller_Net_Price__c=0;
                                     }
                             
                                 if(subs.CWS_Reseller_Net_Price__c!=null)
                                 {
                                     subs.SBQQ__Contract__r.CWS_Total_Reseller_Net_Price__c+=subs.CWS_Reseller_Net_Price__c;
                                     mapMarginContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Total_Reseller_Net_Price__c); 
                                 }
                                 
                     }
              }
          
          for(Id contractId :mapActiveSubsCount.keySet()){
              Contract tempContract=new Contract(id=contractId, CWS_Cancelled__c=mapActiveSubsCount.get(contractId)==0?TRUE:FALSE);
              if(mapContracts.containsKey(contractId)){
                  tempContract.CWS_Contract_ACV__c= mapContracts.get(contractId);
                  tempContract.CWS_Margin__c= mapMarginContracts.get(contractId); //Added for 5662
              }
              lstContracts.add(tempContract);            
          }
          /*
          for(id contractId : mapContractSubsType.keyset())
          {               
              Contract tempContract=new Contract(id=contractId);
              system.debug(lstContracts.contains(tempContract));
              Map<id,Contract> mapLatest = new Map<Id,Contract>(lstContracts);
              Set<Id> resultIds = (new Map<Id,SObject>(lstContracts)).keySet();
              system.debug(resultIds);
              if(!resultIds.contains(contractId))
              {
                  tempContract.CWS_Renewal_Type__c=MapContRT.get(contractId);
                  lstContracts.add(tempContract);
              }
              else{
                  mapLatest.get(contractId).CWS_Renewal_Type__c=MapContRT.get(contractId);
                  system.debug(lstContracts.indexOf(mapLatest.get(contractId)));
                  lstContracts.add(mapLatest.get(contractId));
              }
          }
          */
         if(!lstContracts.isEmpty()){
             for(Contract cont:lstContracts){
                 if(mapContractSubsType.Containskey(Cont.id))
                 {
                     cont.CWS_Renewable_Products__c=mapContractSubsType.get(cont.id);
                 }
             }
         }
  
         Map<id,Contract> mapLstContract=new Map<id,Contract>(lstContracts);
         if(!mapContractSubsType.isEmpty()){
             for(id contractid:mapContractSubsType.keyset()){        
                 if(!mapLstContract.isEmpty()){
                     if(!mapLstContract.Containskey(contractid)){
                         Contract tempContract=new Contract(id=contractId,
                             CWS_Renewable_Products__c = mapContractSubsType.get(contractId));
                         lstContracts.add(tempContract);
                         mapLstContract.put(contractId, tempContract);
                     }
                 }
             }
         }
 
         if(!mapContractCategories.isEmpty()){
             for(Id contractId:mapContractCategories.keySet()){
                 if(mapLstContract.isEmpty() || (!mapLstContract.isEmpty() && !mapLstContract.containsKey(contractId))){
                     Contract tempContract=new Contract(id=contractId, 
                         CWS_Product_Categories__c=mapContractCategories.get(contractId));
                     mapLstContract.put(contractId, tempContract);
                 }
                 else{
                     mapLstContract.get(contractId).CWS_Product_Categories__c=mapContractCategories.get(contractId);
                 }
             }
         }
         
         system.debug('lstContracts '+lstContracts);
         if(mapLstContract!=null && mapLstContract.values()!=null && mapLstContract.values().size()>0){
                  List<Database.SaveResult> results = Database.update(mapLstContract.values(), false);
                  CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_SBQQ__SubsTriggerHelper' , 'afterInsertHelper','Contract', null , null );
         }
         //Added by Mahak 26 Jan 22 - OBD-3379
         List<SBQQ__Subscription__c> subscriptionToUpdate=updateRevisedSubscription(newMap,null);
         if(!subscriptionToUpdate.isEmpty()){
             List<Database.SaveResult> results = Database.update(subscriptionToUpdate, false);
             CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS__SubsTriggerHelper' , 'afterInsertHelper','Subscription', null , null );
         }
     }
     catch(Exception e){
           CWS_ExceptionHandler.logException( e,'Contract' , 'CWS_SBQQ__SubsTriggerHelper','afterInsertHelper' , '', null, null , 'AfterInsert' , null);
     }
    }
 
 /*
  * Method name  : afterUpdate
  * Description  : Bed-5662: Added code to negate margin of terminated subscriptions from contract level
  * Parameter    : List of Subscriptions.
  * Return Type  : None
  * Developer    :  Asutosh
  */
 public static void afterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems)
     {
 
         Map<Id,SBQQ__Subscription__c> newMap = (Map<Id,SBQQ__Subscription__c>) newItems;
         Map<Id,SBQQ__Subscription__c> oldMap = (Map<Id,SBQQ__Subscription__c>) oldItems;
         list<Contract> lstContracts = new list<Contract>();
         //list <SBQQ__Subscription__c> lstSubs = new list <SBQQ__Subscription__c>();
         map<id,decimal> mapMarginContracts= new map<id,decimal>();
         map<id,decimal> mapContracts= new map<id,decimal>();
        // map<id,Contract> mapContracts= new map<decimal,decimal>();
         set<id> setSubsIDs=new set<id>();
         set<id> setContracts=new set<id>();
         //map<id,List<SBQQ__Subscription__c>> mapContractsWithSubs = new map<id,List<SBQQ__Subscription__c>>();
         //decimal tempSum;
         system.debug('Entering afterUpdate');
         for(SBQQ__Subscription__c subs : newMap.values())
         {
             if(subs.SBQQ__TerminatedDate__c!=null)
             {
                 setSubsIDs.add(subs.id);
                 //setContracts.add(subs.SBQQ__Contract__c);
             }
         }
         /*
         //system.debug('setSubsIDs '+setSubsIDs);
         if(setSubsIDs.size()>0){
          lstSubs = [select id,SBQQ__Contract__r.CWS_Margin__c,CWS_Margin__c from SBQQ__Subscription__c where Id in:setSubsIDs];
         }
         */
         try{
             if(setSubsIDs.size()>0)
             {
                 for(SBQQ__Subscription__c subs:[Select Id, name, SBQQ__Contract__c,SBQQ__Contract__r.CWS_Margin__c,CWS_Margin__c from SBQQ__Subscription__c where id in :setSubsIDs])
                 {
                     if (mapMarginContracts.containsKey(subs.SBQQ__Contract__c) && mapMarginContracts.get(subs.SBQQ__Contract__c) != null && subs.CWS_Margin__c!=null )
                     {
                             decimal tempSum  = mapMarginContracts.get(subs.SBQQ__Contract__c) + subs.CWS_Margin__c;
                             mapMarginContracts.put(subs.SBQQ__Contract__c,tempSum);
                             //mapContracts.put(subs.SBQQ__Contract__r.CWS_Margin__c,tempSum);
                     }
                     else
                     {
                         mapMarginContracts.put(subs.SBQQ__Contract__c,subs.CWS_Margin__c);
                         mapContracts.put(subs.SBQQ__Contract__c,subs.SBQQ__Contract__r.CWS_Margin__c);
                     }
             
                 }
                 System.debug('mapMarginContracts '+mapMarginContracts);
                 System.debug('mapContracts '+mapContracts);
                 //List listContracts = [select id,CWS_Margin__c from Contract where Id in:mapMarginContracts.keySet()];
                 
                 for (Id contractId : mapMarginContracts.keySet())
                 {
                     if(mapContracts.containsKey(contractId) && mapContracts.get(contractId) != null &&  mapMarginContracts.get(contractId) != null) 
                     {
                         decimal finMargin;
                         finMargin = mapContracts.get(contractId) - mapMarginContracts.get(contractId);
                         System.debug('finMargin '+finMargin);
                         if (finMargin!=null)
                         {
                             Contract cont = new Contract(id = contractId,CWS_Margin__c= finMargin);
                             lstContracts.add(cont);
                         } 
                      }
                 }
                 
             }
             if(lstContracts.size()>0){
                update lstContracts;
             }
         }
         catch(Exception e){
          CWS_ExceptionHandler.logException( e,'Contract' , 'CWS_SBQQ__SubsTriggerHelper','afterupdate' , '', null, null , 'afterupdate' , null);
         }
     }
  
     /*
     * Method name  : before Update
     * Description  : Integration logic
     * Parameter    : newItems, oldItems
     * Return Type  : None
     * Developer    : swachatterjee
     */
     public static void beforeUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems){
         //Added by Mahak Bansal 27 Dec 2021 
         //the code is moved to a new method, so that can be executed in after Insert and before update
         updateRevisedSubscription(newItems,oldItems);
     }
 
     /*
     * Method name  : updateRevisedSubscription
     * Description  : Update Revised Subscription to Null if ContractAction is Quantity Increase - 27 Dec 2021 -OBD-3379 
     * Parameter    : newItems
     * Return Type  : None
     * Developer    : Mahak Bansal
     */
      private static  List<SBQQ__Subscription__c> updateRevisedSubscription(Map<Id, SObject> newItems,Map<Id, SObject> oldItems){
         
         //Create method variables
         Set<Id> setOrderItemIds = null;
         Map<Id,OrderItem> mapOrderItems = null;
         //Added by Mahak - 
         Map<Id,SBQQ__Subscription__c> oldMap =null;
         List<SBQQ__Subscription__c> subscriptionToUpdate=null;
          
         try{
             // Instantiate the collections
             setOrderItemIds = new Set<Id>();
             mapOrderItems = new Map<Id,OrderItem>(); 
             //Added by Mahak -
             oldMap =new Map<Id,SBQQ__Subscription__c>();
             subscriptionToUpdate=new List<SBQQ__Subscription__c>();
             if(oldItems!=null){
                 oldMap = (Map<Id,SBQQ__Subscription__c>) oldItems;
             }
 
             // Iterate through the new items to capture the 
             // Order Item ids
             for(SObject sObj: newItems.values()){
                 SBQQ__Subscription__c sObjSubscription = (SBQQ__Subscription__c)sObj;
                 setOrderItemIds.add(sObjSubscription.SBQQ__OrderProduct__c);
             }
             
             // Query the Order Products 
             if(!setOrderItemIds.isEmpty()){
                 mapOrderItems = new Map<Id,OrderItem>([SELECT Id,SBQQ__ContractAction__c 
                                                         FROM OrderItem
                                                         WHERE Id IN : setOrderItemIds 
                                                         LIMIT 10000]);
             }
 
             for(Id idKey: newItems.keySet()){
                 SBQQ__Subscription__c sObjNewSubscription;
                 Id idOrderItem;
                 //Added by Mahak , to handle if getting called from before update or after insert
                 if(!oldMap.isEmpty()){
                     //in before update - update the same record
                     sObjNewSubscription = (SBQQ__Subscription__c)newItems.get(idKey);
                 }else{
                     SBQQ__Subscription__c sObjSubscription =  (SBQQ__Subscription__c)newItems.get(idKey);
                     //in after insert - create a new Item to be added in the list to update
                     sObjNewSubscription = new SBQQ__Subscription__c();
                     sObjNewSubscription.Id=idKey;
                     sObjNewSubscription.SBQQ__OrderProduct__c=sObjSubscription.SBQQ__OrderProduct__c;
                     sObjNewSubscription.SBQQ__RevisedSubscription__c=sObjSubscription.SBQQ__RevisedSubscription__c;
                 }
                 // Capture the Order Item Id in a variable                
                 if(sObjNewSubscription.SBQQ__OrderProduct__c!=null){
                     idOrderItem = sObjNewSubscription.SBQQ__OrderProduct__c;   
                 }
                 // Map OrderItem : fetch the order item
                 if(mapOrderItems<>null 
                 && idOrderItem<>null 
                 && mapOrderItems.containsKey(idOrderItem)){
                     // Get the Contract action from the order product
                     String strContractAction = mapOrderItems.get(idOrderItem).SBQQ__ContractAction__c;
                     // Check if the Contract Action = Quantity Increase
                     // Remove the Revised Subscription in that case
                     if(!String.isBlank(strContractAction) 
                     && !String.isBlank(sObjNewSubscription.SBQQ__RevisedSubscription__c)
                     && strContractAction == CWS_ConstantClass.AMENDMENT_CONTRACT_ACTION){
                         sObjNewSubscription.SBQQ__RevisedSubscription__c = null;
                     }
                 }
                 if(oldMap.isEmpty()){
                     subscriptionToUpdate.add(sObjNewSubscription);
                 }
             }
             return subscriptionToUpdate;
         }catch(Exception e){
              CWS_ExceptionHandler.logException( e,'Contract' , 'CWS_SubsTriggerHelper','updateRevisedSubscription' , '', null, null , 'updateRevisedSubscription' , null);
             return null;
         }
     }
 }