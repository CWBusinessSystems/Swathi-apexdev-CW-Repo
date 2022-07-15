/*Class Name: CWS_ProductSearchPlugin
*Description: Product search plugin used to add additional filters on the Quoteline editor page. 
*Created By: Naresh
*Created On: 4/6/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Naresh                4/6/2020          BED-5716               Product search plugin 

*/
Global class CWS_ProductSearchPlugin implements SBQQ.ProductSearchPlugin
{

    global CWS_ProductSearchPlugin()
    {
        // Constructor
    }
    
    global static Boolean isFilterHidden(SObject quote, String fieldName)
    {
        
        return fieldName == 'CWS_Add_On_SKU__c' || fieldName == 'CWS_Status__c' || fieldName =='CWS_Route_to_Market__c' || fieldName =='CWS_NetSuite_Product_Sync_Status__c' || fieldName == 'CWS_Zuora_Product_Sync_Status__c' ;  
       //return true;
    }
    
    global static String getAdditionalSuggestFilters(SObject s, Map<String,Object> m)
    {
        return null;
    }
    
    global static List<PricebookEntry> suggest(SObject s, Map<String,Object> m)
    {
        return null;
    }
    
    global static String getFilterDefaultValue(SObject quote, String fieldName)
    {
        System.debug('METHOD CALLED: getFilterDefaultValue');
       
        return NULL;
    }
    
    global static Boolean isSearchCustom(SObject quote, Map<String,Object> fieldValuesMap)
    {
        System.debug('METHOD CALLED: isSearchCustom');
       
        return false;
    }

    global static String getInputDefaultValue(SObject quote, String input)
    {
        System.debug('METHOD CALLED: getInputDefaultValue');
        return NULL;
    }
    
    global static Boolean isSuggestCustom(SObject quote, Map<String,Object> inputValuesMap)
    {
        return false;
    }
    
        
    global static String getAdditionalSearchFilters(SObject quote, Map<String,Object> fieldValuesMap)
    { 
        // Start of BED-5716 AND BED-3168
        System.debug('METHOD CALLED: getAdditionalSearchFilters');
        String additionalFilter = null;
        String[] applicableQuoteDistiCategories;
        String routeToMarket;
        String quoteDistiCategories;        
        String quoteType=quote.get('CWS_Quote_Type__c')!=null ? String.valueOf(quote.get('CWS_Quote_Type__c')): null;
        //Start BED-6434
        String quoteRenewalCategory;
        //End BED- 6434
        //Start BED-13278
        String quoteTransactionReason;
        //End BEd-13278
        Boolean master=false;
        try{
            List<Id> BillingOnlyProductIDList = new List<Id>();
            Set<Id> billingOnlyProductCodeSet = new Set<Id>();
            Set<Id> activebillingOnlyProductCodeSet = new Set<Id>();
            List<Id> activebillingOnlyProductCodeList = new List<Id>();
            String quoteId = String.valueOf(quote.get('Id'));
            String currIsoCode;
            
            
            if(quoteId != null){
                SBQQ__Quote__c quoteRecord = [SELECT Id, CWS_Renewal_Category__c, CWS_Transaction_Reason__c, CWS_Master__c from SBQQ__Quote__c where Id =:quoteId];
                master=quoteRecord.CWS_Master__c;
                routeToMarket = quote.get('CWS_Route_to_Market__c')!=null ? String.valueOf(quote.get('CWS_Route_to_Market__c')): null;
                quoteDistiCategories = quote.get('CWS_Distributor_Category__c')!=null ? String.valueOf(quote.get('CWS_Distributor_Category__c')): null;
                System.debug('quoteDistiCategories'+quoteDistiCategories);
                currIsoCode = quote.get('CurrencyIsoCode')!=null ? String.valueOf(quote.get('CurrencyIsoCode')): null;
                quoteRenewalCategory = (String.isNotBlank(quoteRecord.CWS_Renewal_Category__c)&&String.valueOf(quoteRecord.CWS_Renewal_Category__c)!=CWS_ConstantClass.Renewal_Category_SplitPending)?String.valueOf(quoteRecord.CWS_Renewal_Category__c):null;
                 quoteTransactionReason = String.isNotBlank(quoteRecord.CWS_Transaction_Reason__c)?String.valueOf(quoteRecord.CWS_Transaction_Reason__c):null;

                if(master){
                    additionalFilter=' Product2.CWS_Source__c= \''+ CWS_ConstantClass.PRODUCT_SOURCE_CMS + '\'';
                }
                if(quoteType == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT ){
                List<SBQQ__QuoteLine__c> QlList=  new List<SBQQ__QuoteLine__c>([Select Id,SBQQ__EndDate__c,SBQQ__EffectiveEndDate__c, SBQQ__ProductCode__c,SBQQ__PriorQuantity__c,SBQQ__SubscriptionType__c, SBQQ__Product__c,SBQQ__Product__r.CWS_ProductCode__c,SBQQ__Product__r.CWS_Status__c,SBQQ__Quote__c,
                SBQQ__Quote__r.CWS_Quote_Type__c, SBQQ__Quote__r.CWS_Route_to_Market__c,SBQQ__Quote__r.CWS_Distributor_Category__c from SBQQ__QuoteLine__c Where SBQQ__Quote__c =:quoteId ]);
                
                if(!QlList.isEmpty()){
                   For(SBQQ__QuoteLine__c QL :QlList){
                       // Checking if product status is Billing-Only and is active in the contract            
                       if(QL.SBQQ__Product__r.CWS_Status__c == 'Billing Only' && QL.SBQQ__PriorQuantity__c > 0 && QL.SBQQ__Quote__r.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && (QL.SBQQ__EffectiveEndDate__c >= Date.Today() || QL.SBQQ__SubscriptionType__c == CWS_ConstantClass.Subscription_Type_Evergreen) ){
                        billingOnlyProductCodeSet.add(ql.SBQQ__Product__c);
                            }

                        if(QL.SBQQ__Product__r.CWS_Status__c == 'Active\\Billing Only' && QL.SBQQ__PriorQuantity__c > 0 && QL.SBQQ__Quote__r.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && (QL.SBQQ__EffectiveEndDate__c >= Date.Today() || QL.SBQQ__SubscriptionType__c == CWS_ConstantClass.Subscription_Type_Evergreen)){
                        activebillingOnlyProductCodeSet.add(ql.SBQQ__Product__c);
                            }    
                        }
                    }
                }   
               applicableQuoteDistiCategories=quoteDistiCategories!=null? quoteDistiCategories.split(';') : new List<String>();  
                system.debug('applicableQuoteDistiCategories'+applicableQuoteDistiCategories);
                if(!(quoteType == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && (quoteTransactionReason==CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL || quoteTransactionReason==CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT))){
                //Adding logic for 7385 to only allow products with Status:Active/Billing satisying below condition
               if(!activebillingOnlyProductCodeSet.isEmpty()){
                    activebillingOnlyProductCodeList.addall(activebillingOnlyProductCodeSet);
               }
                if(additionalFilter==''  || additionalFilter==null){
                    if(activebillingOnlyProductCodeList.isEmpty()){
                        additionalFilter = '((Product2.CWS_Status__c != \'Active\\\\Billing Only\') OR (Product2.CWS_Status__c = \'Active\\\\Billing Only\' AND Product2.CWS_Route_to_Market__c includes (\'' + +routeToMarket + '\') AND Product2.CWS_Currencies__c includes (\'' + currIsoCode + '\') AND (Product2.CWS_Route_to_Market_Billing_Only__c excludes (\'' + routeToMarket + '\') OR Product2.CWS_Currencies_Billing_Only__c excludes (\'' + currIsoCode + '\'))))';
                    }
                    else{
                        additionalFilter = '((Product2.CWS_Status__c != \'Active\\\\Billing Only\') OR ((Product2.CWS_Status__c = \'Active\\\\Billing Only\' AND Product2.CWS_Route_to_Market__c includes (\'' + +routeToMarket + '\') AND Product2.CWS_Currencies__c includes (\'' + currIsoCode + '\') AND (Product2.CWS_Route_to_Market_Billing_Only__c excludes (\'' + routeToMarket + '\') OR Product2.CWS_Currencies_Billing_Only__c excludes (\'' + currIsoCode + '\'))) OR (Product2.Id in (\''+String.join(activebillingOnlyProductCodeList,'\', \'') +'\'))))';
                    }
                              }
               else{
                   if(activebillingOnlyProductCodeList.isEmpty()){
                    additionalFilter =additionalFilter + ' AND ((Product2.CWS_Status__c != \'Active\\\\Billing Only\') OR (Product2.CWS_Status__c = \'Active\\\\Billing Only\' AND Product2.CWS_Route_to_Market__c includes (\'' + +routeToMarket + '\') AND Product2.CWS_Currencies__c includes (\'' + currIsoCode + '\') AND (Product2.CWS_Route_to_Market_Billing_Only__c excludes (\'' + routeToMarket + '\') OR Product2.CWS_Currencies_Billing_Only__c excludes (\'' + currIsoCode + '\'))))';
                   }
                   else{
                    additionalFilter = additionalFilter + ' AND ((Product2.CWS_Status__c != \'Active\\\\Billing Only\') OR ((Product2.CWS_Status__c = \'Active\\\\Billing Only\' AND Product2.CWS_Route_to_Market__c includes (\'' + +routeToMarket + '\') AND Product2.CWS_Currencies__c includes (\'' + currIsoCode + '\') AND (Product2.CWS_Route_to_Market_Billing_Only__c excludes (\'' + routeToMarket + '\') OR Product2.CWS_Currencies_Billing_Only__c excludes (\'' + currIsoCode + '\'))) OR (Product2.Id in (\''+String.join(activebillingOnlyProductCodeList,'\', \'') +'\'))))';
                   }
                               }
            }
               System.debug ('Initial additionalFilter '+additionalFilter);
           //Adding conditions based on Quote type and checking Billing only condition            
            if(quoteType == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS){
                If(quoteTransactionReason!=CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL && quoteTransactionReason!=CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT){
                additionalFilter = '' + ( additionalFilter==null? '':additionalFilter+' AND ') +   ' Product2.CWS_Add_On_SKU__c = FALSE  AND Product2.CWS_Status__c != \'Billing Only\'' ;
                }   
                if(routeToMarket==CWS_ConstantClass.RTM_Value_Channel && !applicableQuoteDistiCategories.isEmpty()){
                    additionalFilter=''+ ( additionalFilter==null? '':additionalFilter+' AND ') + 
                        ' Product2.CWS_Category__c in (\''+String.join(applicableQuoteDistiCategories,'\', \'') +'\')';
                    }
               }        
                //Adding conditions based on Quote type and checking Billing only condition
               else if (quoteType == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && !billingOnlyProductCodeSet.isEmpty()){
                                    BillingOnlyProductIDList.addall(billingOnlyProductCodeSet);
                               if(quoteRenewalCategory!=null){
                                   additionalFilter = additionalFilter + ' AND Product2.CWS_Renewal_Type__c = \'' + quoteRenewalCategory + '\''; 
                               }     
                               additionalFilter = additionalFilter + ' AND ( Product2.CWS_Status__c != \'Billing Only\' OR '+
                               ' Product2.Id in (\''+String.join(BillingOnlyProductIDList,'\', \'') +'\') )'; //SHOW ONLY THESE PRODUCTS SCENARIO
                          if(routeToMarket==CWS_ConstantClass.RTM_Value_Channel && !applicableQuoteDistiCategories.isEmpty()){
                               additionalFilter=''+ ( additionalFilter==null? '':additionalFilter+' AND ') + 
                                   ' Product2.CWS_Category__c in (\''+String.join(applicableQuoteDistiCategories,'\', \'') +'\')';
                               }
               }
               //Adding conditions based on Quote type and checking Billing only condition
               else if (quoteType == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && billingOnlyProductCodeSet.isEmpty()){
                                if(quoteRenewalCategory!=null){
                                   additionalFilter = additionalFilter + ' AND Product2.CWS_Renewal_Type__c = \'' + quoteRenewalCategory + '\''; 
                               }  
                                additionalFilter = additionalFilter + ' AND Product2.CWS_Status__c != \'Billing Only\' ' ;
                               if(routeToMarket==CWS_ConstantClass.RTM_Value_Channel && !applicableQuoteDistiCategories.isEmpty()){
                               additionalFilter=''+ ( additionalFilter==null? '':additionalFilter+' AND ') + 
                                   ' Product2.CWS_Category__c in (\''+String.join(applicableQuoteDistiCategories,'\', \'') +'\')';
                               }   
               }
               //Adding conditions based on Quote type and checking Billing only condition
               else if (quoteType == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC ){
                            if(quoteRenewalCategory!=null){
                                   additionalFilter = additionalFilter + ' AND Product2.CWS_Renewal_Type__c = \'' + quoteRenewalCategory + '\''; 
                               }  
                            additionalFilter = additionalFilter + ' AND Product2.CWS_Status__c != \'Billing Only\' ' ;
                               if(routeToMarket==CWS_ConstantClass.RTM_Value_Channel && !applicableQuoteDistiCategories.isEmpty()){
                               additionalFilter=''+ ( additionalFilter==null? '':additionalFilter+' AND ') + 
                                   ' Product2.CWS_Category__c in (\''+String.join(applicableQuoteDistiCategories,'\', \'') +'\')';
                               }  
                    }       
               }
              
               System.debug ('Final additionalFilter '+additionalFilter);                  
     }catch(Exception e){
        CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_ProductSearchPlugin', 'getAdditionalSearchFilters' , '', null, null , 'get Additional Search Filters' , null);
                      }
        return additionalFilter;
        // Start of BED-5716 AND BED-3168
    }
    
    global static Boolean isInputHidden(SObject quote, String input)
    {
       
        return false;
    }
    
    global static List<PriceBookEntry> search(SObject quote, Map<String,Object> fieldValuesMap)
    {
        return null;
    }
}