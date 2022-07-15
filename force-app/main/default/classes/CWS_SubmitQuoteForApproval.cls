/*Class Name: CWS_SubmitQuoteForApproval
*Description: Controller for submit quote for approval aura component
*Created By: Naresh
*Created On: 4/6/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Naresh                 4/06/2020       BED-5258                Submit Approvals
*Khayam                 4/06/2020       BED-5258                Submit Approvals
*Naresh                 4/06/2020       BED-3741                Recall Approvals
*Indra Ganesan          5/20/2020       BED-5240                Price Refresh alert On Quote
*Megha Shetty           5/29/2020       BED-9236                QuoteTerms Manual terms 
*Harsha                 6/16/2020       BED-3555                Expire Date Enchancement
*Megha Shetty           6/18/2020       BED-8913                Warning msg
*Megha Shetty      6/30/2020    BED-5912        Error message for Special Manage product associated orders and subscriptions
*Nirmal                 12/11/2020      BED-13804               QR calculation changes
*Divyanshu        5/31/2021    OBD-526          Added the logic so Products with event category can be quoted with other products
*Mahak Bansal           8/23/2021       OBD-1693                Commented the logic to throw error for submitting quote for approval when your quote lines >$15,000 ACV
*Mahak Bansal           1/03/2022       OBD-3248                Remove validation on Vendor Approval Checkbox
*Ad Victoriam solutions 02/17/2022      OBD-4309                Updated to reflect new Opportunity Stage Names
*/
public class CWS_SubmitQuoteForApproval {

  @AuraEnabled
    public static void submitForApproval(String quoteId){
        try{
      SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.CWS_Quote__c);
           //9236 Changes
            SBQQ__Quote__c quote = new SBQQ__Quote__c();
            quote.Id = ID.valueOf(quoteId);
            Set<Id> resellerId = new Set<Id>();
            List<Contact> contactLst = new List<Contact>();
            List<SBQQ__QuoteLine__c> lstquoteLn = new List<SBQQ__QuoteLine__c>();
            //String manualClauses   ;
            String sellBasicProductName ='';
            String RenewalType; 
            
                if(quote.id != null) {
                    Decimal oneTimeTotal = 0.0;
                    Decimal monthlyRecurringtotal = 0.0;
                    lstquoteLn = [SELECT id
                    , SBQQ__ProductCode__c
                    , SBQQ__ProductName__c
          , SBQQ__SubscriptionType__c
                    , CWS_Billing_Term__c
                    ,SBQQ__Quote__r.CWS_Reseller_Account__r.Id
                    ,SBQQ__Quote__r.CWS_Reseller_Account__c
                    , SBQQ__Quote__r.CWS_Add_Terms_Manually__c
                    ,SBQQ__Quote__r.CWS_Sell_Basic_Product_Name__c
                    ,SBQQ__Quote__r.CWS_Monthly_Recurring_Subtotal__c
                    ,SBQQ__Quote__r.CWS_One_Time_Subtotal__c
                    ,SBQQ__Quantity__c,CWS_Renewal_Type__c
                    , SBQQ__EffectiveQuantity__c,SBQQ__NetTotal__c from SBQQ__QuoteLine__c
                     where 
                     SBQQ__Quote__c = :quote.id];
                    if(!lstquoteLn.isEmpty()){
                        
                        //for populating sell basic product name
                        for(SBQQ__QuoteLine__c qLine : lstquoteLn){                         
                            if( qLine.SBQQ__ProductCode__c == CWS_ConstantClass.SellBasic_ProductCode
                                && qLine.SBQQ__EffectiveQuantity__c != 0 ){
                               sellBasicProductName = qLine.SBQQ__ProductName__c; 
                            }
                            //Start of BED-6434
              //BED-12497
                            if(qline.SBQQ__SubscriptionType__c!= CWS_ConstantClass.Subscription_Type_Evergreen){
                if(qLine.CWS_Renewal_Type__c != null && String.isNotEmpty(RenewalType)){
                  if(RenewalType!=qLine.CWS_Renewal_Type__c){
                    RenewalType = CWS_ConstantClass.Renewal_Category_SplitPending;
                  }
                }
                else if(qLine.CWS_Renewal_Type__c != null){     
                    RenewalType = qLine.CWS_Renewal_Type__c;
                }
              }
              //BED-12497
                            //End of BED-6434
                            
              /*
                            if(qLine.SBQQ__Quote__r.CWS_Add_Terms_Manually__c != null && String.isEmpty(manualClauses)){
                                manualClauses = qLine.SBQQ__Quote__r.CWS_Add_Terms_Manually__c;
                            }*/
                            
                            if(qLine.CWS_Billing_Term__c == CWS_ConstantClass.BillingTerm_OneTime && qLine.SBQQ__NetTotal__c != null){
                                oneTimeTotal = oneTimeTotal + qLine.SBQQ__NetTotal__c;
                            } else if(qLine.CWS_Billing_Term__c == CWS_ConstantClass.BillingTerm_Monthly && qLine.SBQQ__NetTotal__c != null)  {
                                monthlyRecurringtotal = monthlyRecurringtotal + qLine.SBQQ__NetTotal__c;
                            }
              if(qLine.SBQQ__Quote__r.CWS_Reseller_Account__c != null){
                                resellerId.add(qLine.SBQQ__Quote__r.CWS_Reseller_Account__r.Id);
                            }
                        }
            //BED-3438
            quote.CWS_Approval_Requested_Date__c = system.today()+3;
                        //End BED-3438
                        quote.CWS_One_Time_Subtotal__c = oneTimeTotal;
                        quote.CWS_Monthly_Recurring_Subtotal__c =  monthlyRecurringtotal;
                        //start of BED-6434
                        if(String.isNotEmpty(RenewalType)){
                            quote.CWS_Renewal_Category__c = RenewalType;
                        }
                        //End of BED-6434
                        
                    }
          contactLst = [Select Id,CWS_Primary_Billing_Contact__c,CWS_Primary_Contact__c from Contact where AccountId IN: resellerId AND CWS_Primary_Billing_Contact__c = true AND CWS_Primary_Contact__c = true];
                    for(Contact conRec : contactLst){
                        if(conRec.CWS_Primary_Billing_Contact__c == true && conRec.CWS_Primary_Contact__c == true){
                            quote.CWS_Reseller_Contact__c = conRec.Id;                    
                        }
                    }
                } 
                /*for manual clause
                if(String.isNotEmpty(manualClauses)){
                    
                    List<String> manualClauseList  =   manualClauses.split(';');
                    List<String> manualClauseHasedList = new List<String>();
                    
                    for(String manualClause : manualClauseList  ){
                        manualClause = '#' +  manualClause.trim() + '#';
                        manualClauseHasedList.add(manualClause);
                    }
                    if(!manualClauseHasedList.isEmpty())
                    quote.CWS_Add_Terms_Manually__c = String.join(manualClauseHasedList, ';');
                    
                }*/
                quote.CWS_Sell_Basic_Product_Name__c = sellBasicProductName.length()>0 ? sellBasicProductName : '';
                if(quote.id != null){
                    update quote;
                }
           
            //end 9236
           
        } catch(DMLException e){
            String msg = '';
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg += (e.getDmlMessage(i)+' \n'); 
            }
            CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_SubmitQuoteForApproval', 'submitForApproval' , '', null, null , 'CWS_SubmitQuoteForApproval' , null);
            throw new AuraHandledException(msg);
        } catch(Exception e){
           CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_SubmitQuoteForApproval', 'submitForApproval' , '', null, null , 'CWS_SubmitQuoteForApproval' , null);
           throw new AuraHandledException('Exception occurred while submitting for Approval : '+ e.getMessage());
        }
          
    }
//Created this method too recall approval
//Created as part of BED-3741
    @AuraEnabled
    public static void recallApproval(String quoteId){
        try{
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.CWS_Quote__c);
        } catch(Exception e){
           CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_SubmitQuoteForApproval', 'recallApproval' , '', null, null , 'CWS_SubmitQuoteForApproval' , null);
           throw new AuraHandledException('Exception occurred while recalling Approval : '+ e.getMessage());
        }
          
    }

    /*
    *Developer: Khayam
    *Description: BED-8482: Helper method CWS_Quote_Path component
    *return: void   
    */
    @AuraEnabled
    public static List<String> getQuoteStages(){
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldResult = SBQQ__Quote__c.SBQQ__Status__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            stages.add(p.getLabel());
        }
        return stages;
    }
     
 /* Method Name : validateQuote
  * Description : Error Messages after validating quote on submit for approval.
  * Returns     : Boolean
  * Developer   : Indra Ganesan
  */
   @AuraEnabled
     public static Map<String, String> validateQuoteOnSubmittingForApproval(Id QuoteId){

        Map<String, String> quoteErrorMessage = new Map<String, String>();  
        Map<String, String> quoteAlertMessage = new Map<String, String>();

        List<SBQQ__QuoteLine__c> lstquoteLn = new List<SBQQ__QuoteLine__c>();
        set<id> pbeid = new set<id>();
        Map<Id, Double> mapPbToPrice = new Map<Id, Double>();
        Map<Id, Double> mapBlockPrice = new Map<Id, Double>();
        set<String> status = new set<String>();
        set<String> QType = new set<String>();
        List<SBQQ__BlockPrice__c> blockPrice = new List<SBQQ__BlockPrice__c>();
        Set<String> prodCategorySet= new Set<String>() ;

        Set<String> prodSubCategorySet= new Set<String>() ;
       //6515: Validating Vendor Approval Required checkbox
       //Commented by Mahak Bansal 13 Jan 2022 , OBD-3248
       //Remove validation on Vendor Approval Checkbox
       //Set<id> QLIidset = new Set<id>();

         //6173: Validating  Only Event and Sponsorship Sales Reps can quote Event and Sponsorship products
            Id loggedUser=userInfo.getUserId();
            List<GroupMember> grpmmbrLst = new List<GroupMember>();
            Set<id> ESGroupIds = new Set<Id>();
            String userType = Schema.SObjectType.User.getKeyPrefix();
           //5912 starts
           List<OrderItem> lstordersproducts = new List<OrderItem>();
           integer totalQTY=0;
           integer priorTotalQTY=0;
           Boolean checksplManage = false;
      Boolean EvergreenLinePresent = false;
           integer totalPriorQTYForAmmend = 0;
           integer totalPriorQTYForRWC = 0;
      Boolean PrimarySTA=false;
            Boolean PrimaryBTA=false;
            Set<id> setAccoundID = new set<id>();
            
      //5912  ends     
      Boolean evergreenQuote = false;
      //Start BED-12792
            Boolean CancelQuote = false;
            Decimal CancelCount=0;
            Boolean isMinCommit=false;//BED-13804
            //End BED-12792
        try{
            if(quoteId != null){
                //BED-13804 added QR calculated field from opportunity in query
                SBQQ__Quote__c quoteObj = [SELECT Id,CWS_Quote_Type__c,CWS_Renewal_CAP__c,CWS_Prior_Renewal_CAP__c,SBQQ__Opportunity2__c, SBQQ__Account__c,CWS_Bill_To_Account__c,CWS_Master__c,
                        SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c,SBQQ__ExpirationDate__c,CWS_Reference_Expiry_Date__c,
                        SBQQ__Status__c, SBQQ__LineItemCount__c, CWS_Vendor_Approval_Received__c, CWS_Original_Quote__c,CWS_Credit_Quote__c,CWS_Original_Contract__c,CWS_Transaction_Reason__c,
                        CWS_Route_to_Market__c, CWS_Renewal_Category__c, SBQQ__MasterContract__c, CWS_Bill_To_Account__r.id,SBQQ__Account__r.id, 
                        SBQQ__MasterEvergreenContract__c,SBQQ__Opportunity2__r.CWS_Fast_Track__c,CWS_isFastTrack__c,CWS_Master_Dedicated_Tech__c,
            SBQQ__Opportunity2__r.CWS_Total_Forecast_Amount__c  ,SBQQ__Primary__c,SBQQ__Opportunity2__r.StageName,CWS_Pre_payment_Amount__c, SBQQ__Opportunity2__r.CWS_QR_Calculated__c
                        FROM SBQQ__Quote__c where id  = :quoteId];
                 
                //BED-13804 added min commit field in query
                //Matt: Added field skip_validate_flage__c in query
                if(quoteObj.id != null && quoteObj.SBQQ__LineItemCount__c > 0 ) {
                    lstquoteLn = [SELECT id,SBQQ__Product__r.CWS_Base_SKU__c,CWS_Transaction_Type__c,CWS_Subscription_Quantity__c, SBQQ__EffectiveQuantity__c,SBQQ__PriorQuantity__c, CWS_Manage_Product__c,CWS_Manage_Special_Product__c,CWS_Min_Commit__c,
                    SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__PricebookEntryId__c, CWS_Category__c, CWS_Sub_category__c, CWS_Cost_Price__c, CWS_Original_Cost_Price__c, SBQQ__BlockPrice__c, SBQQ__PricingMethod__c, SBQQ__SubscriptionType__c, CWS_future_pricing_approval__c,
                     SBQQ__Existing__c, CWS_Future_Priced_Line__c, CWS_Future_Contracted_Price__c, CWS_Discretionary_Discount_Future_Price__c, CWS_Future_Priced_Line__r.CWS_Future_Price_End_Date__c, CWS_Future_Price_End_Date__c,  
                     CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c, CWS_Future_pricing_Blocks__c, SBQQ__UpgradedSubscription__c, CWS_NetPrice__c, CWS_Future_Priced_Line__r.CWS_Future_Contracted_Price__c,skip_validate_flage__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteObj.id];
                    if(!lstquoteLn.isEmpty()){
                        for(SBQQ__QuoteLine__c qLine : lstquoteLn){
            
              //Start BED-12792 Do not send for approval if the lines are cancelled
                            if(quoteObj != null && quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC){
                                if(qLine.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL || 
                                   qLine.SBQQ__Product__r.CWS_Base_SKU__c == CWS_ConstantClass.MINCOM_BASESKU_900901 ||
                                   qLine.SBQQ__Product__r.CWS_Base_SKU__c == CWS_ConstantClass.MINCOM_BASESKU_900904){
                                       CancelCount+=1;
                                }
                  
                                if(CancelCount == QuoteObj.SBQQ__LineItemCount__c)
                                {
                                    CancelQuote=true;
                                }
                            }        
                            //End BED-12792
                            
                            if(String.isNotEmpty(qLine.CWS_Category__c)) prodCategorySet.add(qLine.CWS_Category__c) ;
                            /*
                            Developer:Matt
                            Reason:When the skip_validate_flage__c is check then the validation will be ignore on that line item
                            Changes:&& qLine.skip_validate_flage__c != true
                            */
                            if(String.isNotEmpty(qLine.CWS_Sub_category__c) && qLine.skip_validate_flage__c != true){ prodSubCategorySet.add(qLine.CWS_Sub_category__c); }

                            if(qLine.SBQQ__PricingMethod__c!=CWS_ConstantClass.PRICINGMETHOD_BLOCK){
                            pbeid.add(qLine.SBQQ__PricebookEntryId__c); // skip if product is block pricing 
                            mapPbToPrice.put(qLine.SBQQ__PricebookEntryId__c, qLine.SBQQ__ListPrice__c);
                            }
                            else if(qLine.SBQQ__BlockPrice__c!=null){
                                mapBlockPrice.put(qLine.SBQQ__BlockPrice__c,qLine.SBQQ__ListPrice__c);
                            }

                            //6515: Validating Vendor Approval Required checkbox
                            //Commented by Mahak Bansal 3 Jan 2022 , OBD-3248
                            //Remove validation on Vendor Approval Checkbox
                            /*if(qLine.CWS_Original_Cost_Price__c != null && qLine.CWS_Cost_Price__c != null &&
                               (qLine.CWS_Original_Cost_Price__c !=qLine.CWS_Cost_Price__c) && (qLine.CWS_Category__c == CWS_ConstantClass.strPerch || qLine.CWS_Category__c == CWS_ConstantClass.strSolutionPartners) ){
                                QLIidset.add(qLine.Id);
                            }*/

                            System.debug('quoteObj.CWS_Quote_Type__c -----> ' + quoteObj.CWS_Quote_Type__c);
                            System.debug('CWS_ConstantClass.QUOTE_TYPE_AMENDMENT ----> ' + CWS_ConstantClass.QUOTE_TYPE_AMENDMENT);
                            System.debug('qline.SBQQ__Existing__c ----> ' + qline.SBQQ__Existing__c);
                            SYstem.debug('qLine.SBQQ__SubscriptionType__c ----> ' + qLine.SBQQ__SubscriptionType__c);
                            System.debug('CWS_ConstantClass.Subscription_Type_Evergreen ----> ' + CWS_ConstantClass.Subscription_Type_Evergreen);
                            System.debug('evergreenQuote -----> ' + evergreenQuote);
                            if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && qline.SBQQ__Existing__c && qLine.SBQQ__SubscriptionType__c != null && qLine.SBQQ__SubscriptionType__c.contains(CWS_ConstantClass.Subscription_Type_Evergreen) && !evergreenQuote){
                                evergreenQuote = true;
                            }
                            //5912 starts
                            if (qLine.CWS_Manage_Special_Product__c == true)
              {  if(qLine.SBQQ__Quantity__c!=0)
                                checksplManage= true;
                               totalQTY += (qLine.SBQQ__Quantity__c).intValue();
                               if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.Quote_Type_Amendment && qLine.SBQQ__PriorQuantity__c!= null)
                                {
                                    totalPriorQTYForAmmend += (qLine.SBQQ__PriorQuantity__c).intValue();
                                }
                               if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && qLine.CWS_Subscription_Quantity__c!= null)
                                {
                                    totalPriorQTYForRWC += (qLine.CWS_Subscription_Quantity__c).intValue();
                                }
              }
              if(qLine.CWS_Manage_Product__c == true)
                            {  totalQTY += (qLine.SBQQ__Quantity__c).intValue();
                              if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.Quote_Type_Amendment && qLine.SBQQ__PriorQuantity__c!= null )
                                {
                                    totalPriorQTYForAmmend += (qLine.SBQQ__PriorQuantity__c).intValue();
                                }
                               if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && qLine.CWS_Subscription_Quantity__c!= null )
                                {
                                    totalPriorQTYForRWC += (qLine.CWS_Subscription_Quantity__c).intValue();
                                }
                            }
              
                            
              //BED-13237
                            if(qline.SBQQ__SubscriptionType__c == CWS_ConstantClass.Subscription_Type_Evergreen && !EvergreenLinePresent){
                                EvergreenLinePresent=true;
                            }
                            //BED-13237
                            
                            //BED-13804
                             if(qLine.CWS_Min_Commit__c){
                                isMinCommit = true;
                            }
              
                        }
            
            //Start BED-12792 Do not send for approval if the lines are cancelled
                        if(CancelQuote){
                            quoteErrorMessage.put('CancelledLinesError', System.Label.CWS_Cannot_Submit_For_Approval_For_Cancelled_Lines);
                        }
                        //End BED-12792
            
                        if(checksplManage == true && totalQTY < 2 && totalQTY!= 0)
            {
              ID soldToAccount = quoteObj.SBQQ__Account__c;                            
                            lstordersproducts =[SELECT id,SBQQ__OrderedQuantity__c, Product2.CWS_Manage_Special_Product__c, Product2.CWS_Manage_Product__c from OrderItem where (Order.AccountId = :soldToAccount and (Product2.CWS_Manage_Product__c=true or Product2.CWS_Manage_Special_Product__c = true))];
                            if(lstordersproducts!= null)
                            for(OrderItem orderProducts : lstordersproducts){
  
              if(orderProducts.Product2.CWS_Manage_Special_Product__c == true && orderProducts.SBQQ__OrderedQuantity__c!= 0)
              priorTotalQTY += (orderProducts.SBQQ__OrderedQuantity__c).intValue();
              
                            if(orderProducts.Product2.CWS_Manage_Product__c == true && orderProducts.SBQQ__OrderedQuantity__c!= 0)
              priorTotalQTY += (orderProducts.SBQQ__OrderedQuantity__c).intValue();
                }

                            if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.Quote_Type_Amendment ){
                              priorTotalQTY -= totalPriorQTYForAmmend;
                            }
                            if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC ){
                              priorTotalQTY -= totalPriorQTYForRWC;
                            }
                            /** 
              if((totalQTY + priorTotalQTY) <2 )
                    {
                      quoteErrorMessage.put('SpecialManageProductError', System.Label.CWS_SpecialManageProductError);
                  }  
                            */
     }
     //5912 ends           
   
            //BED-13423
            
                        if(QuoteObj.CWS_Bill_To_Account__c!=null && QuoteObj.SBQQ__Account__c !=null && QuoteObj.CWS_Bill_To_Account__c == QuoteObj.SBQQ__Account__c){
                            setAccoundID.add(QuoteObj.CWS_Bill_To_Account__r.id);
                        }
                        if(QuoteObj.CWS_Bill_To_Account__c!= null && QuoteObj.SBQQ__Account__c != null &&  QuoteObj.CWS_Bill_To_Account__c != QuoteObj.SBQQ__Account__c){
                            setAccoundID.add(QuoteObj.CWS_Bill_To_Account__r.id);
                            setAccoundID.add(QuoteObj.SBQQ__Account__r.id);
                        }
                        system.debug(setAccoundID);
                        list<Contact> lstcontact=[select id,AccountId,CWS_Primary_Billing_Contact__c,CWS_Primary_Contact__c from contact where AccountId in:setAccoundID and (CWS_Primary_Billing_Contact__c=true OR CWS_Primary_Contact__c=true)];
                        if(!lstcontact.isEmpty()){
            for(Contact Cont:lstcontact){
                if(QuoteObj.CWS_Bill_To_Account__c != null && QuoteObj.SBQQ__Account__c != null &&  QuoteObj.CWS_Bill_To_Account__c == QuoteObj.SBQQ__Account__c){
                  if(Cont.CWS_Primary_Contact__c || Cont.CWS_Primary_Billing_Contact__c)
                  {
                    PrimarySTA=true;
                    PrimaryBTA=true;
                  }

                }
                else{
                  if(Cont.AccountId == QuoteObj.SBQQ__Account__r.id)
                  {
                    if(Cont.CWS_Primary_Contact__c || Cont.CWS_Primary_Billing_Contact__c)
                    {
                    PrimarySTA=true;
                    }
                  }
                  else
                  {
                  if(Cont.CWS_Primary_Contact__c  || cont.CWS_Primary_Billing_Contact__c)
                    {
                    PrimaryBTA=true;
                    }
                  }
                }

              }
                        }
            
                        //BED-13423
            
                        if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS ){
                            List<PricebookEntry> lstPb = new List<PricebookEntry>([select id, UnitPrice from PricebookEntry where id IN :pbeid]);
                            if(mapBlockPrice.size()>0){
                                blockPrice = [Select Id, SBQQ__Price__c from SBQQ__BlockPrice__c where id IN :mapBlockPrice.keyset()];
                            }
                            for(PricebookEntry pb : lstPb) {
                                if(mapPbToPrice.containsKey(pb.id) && mapPbToPrice.get(pb.id)!= pb.UnitPrice.setScale(2,System.RoundingMode.HALF_UP)){
                                    quoteErrorMessage.put('PriceRefreshError',System.Label.CWS_UI_RefreshPriceErrorMsg);
                                }
                            }
                            for(SBQQ__BlockPrice__c bp: blockPrice){
                                if(mapBlockPrice.containsKey(bp.id) && mapBlockPrice.get(bp.id)!= bp.SBQQ__Price__c){
                                    quoteErrorMessage.put('PriceRefreshError',System.Label.CWS_UI_RefreshPriceErrorMsg);
                                }
                            }
                        }
                        
                        //BED-13804
                         /*if((!quoteObj.SBQQ__Opportunity2__r.CWS_QR_Calculated__c) &&  isMinCommit){
                            quoteErrorMessage.put('Quota Retirment Error', System.Label.CWS_Quota_Retirement_Error);
                        }*/
                        
                    }
                        //14052511 start
                    if((quoteObj.CWS_Transaction_Reason__c ==  CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT || quoteObj.CWS_Transaction_Reason__c ==  CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION || 
                        quoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION) && quoteObj.CWS_Original_Quote__c == null && 
                      quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS){
                        quoteErrorMessage.put('PopulateOriginalQuote',System.Label.CWS_Please_populate_original_quote);
                    }
                       //14052511 end
          
                    if(quoteObj.SBQQ__Opportunity2__c!=null && quoteObj.CWS_Master__c==true
                        && quoteObj.CWS_Master_Dedicated_Tech__c==FALSE){
                        Map<String, Integer> mapMonthValue=new Map<String, Integer>{ 'JAN'=>1, 'FEB'=>2, 'MAR'=>3, 'APR'=>4,
                                        'MAY'=>5, 'JUN'=>6, 'JUL'=> 7, 'AUG'=> 8, 'SEP'=>9, 'OCT'=>10,
                                        'NOV'=>11, 'DEC'=>12 };
                        Set<String> lstMinCommitMonths=new Set<String>();
                        String monthString;
                        String yearString;
                        for(CWS_Minimum_Commit__c minCommit:[Select Id, Name, CWS_Legacy_ID__c,
                            CWS_Monthly_Minimum_Commit__c, CWS_Month_Year__c from CWS_Minimum_Commit__c where 
                            CWS_Opportunity__c= :quoteObj.SBQQ__Opportunity2__c]){
                            if(minCommit.CWS_Month_Year__c!=null){
                                monthString=minCommit.CWS_Month_Year__c.subStringBefore('-').trim().toUpperCase();
                                yearString=minCommit.CWS_Month_Year__c.subStringAfter('-').trim();
                                lstMinCommitMonths.add(''+mapMonthValue.get(monthString)+'-'+yearString);
                            }
                        }
                        Set<String> expectedMinCommitMonths=new Set<String>();
                        Date startDate=quoteObj.SBQQ__StartDate__c;
                        Date endDate=quoteObj.SBQQ__EndDate__c;
                        Date tempDate=Date.newInstance(startDate.year(), startDate.month(), 1);
                        while(tempDate<=endDate){
                            expectedMinCommitMonths.add(''+tempDate.month()+'-'+String.valueOf(tempDate.year()).right(2));
                            tempDate=tempDate.addMonths(1);
                        }
                        if(!lstMinCommitMonths.containsAll(expectedMinCommitMonths)){
              if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS){
                                quoteErrorMessage.put('MinCommitError', System.Label.CWS_QuoteErrorMinCommitNewB);
                            } 
                            if((quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && quoteObj.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT) || quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC){
                                quoteErrorMessage.put('MinCommitError', System.Label.CWS_QuoteErrorMinCommitment);
                            } // CR_RECOMMIT added transaction reason check for recommit to avoid error being thrown for min commit.
                        }
                    }
                    //BED-8913
                    if(quoteObj.CWS_Renewal_CAP__c == null && (QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC ||  QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS))
                    {
                        quoteErrorMessage.put(System.label.CWS_Warning + 'RenewalCapBlankAlert', System.Label.CWS_PriorRenewalCapBlankAlert);
                    }
                    //end BED-8913
          
          //BED-13237
                    if(EvergreenLinePresent && quoteObj.CWS_Pre_payment_Amount__c > 0){
                        quoteErrorMessage.put('PrePaymentError', System.Label.CWS_PrePaymentAmountErrorMessage); 
                    }
                    //BED-13237
          //Ticket 14021920 starts
                    if(!lstquoteLn.isEmpty() && quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT){
                          Boolean futureErrMsg = futurePriceCalculation(quoteObj.Id,true);
                        if(futureErrMsg){
                            quoteErrorMessage.put('Future Expiry Error', System.Label.CWS_Future_Expiry_Date_Error);
                        }
                    }
                    //Ticket 14021920 Ends
          
                    //BED-12608
                    //commented as part of OBD-1693 - Mahak Bansal Aug.23 2021
                    /*if( quoteObj.SBQQ__Opportunity2__r.CWS_Total_Forecast_Amount__c  > Integer.valueOf(label.CWS_Opportunity_Amount) &&
                        quoteObj.SBQQ__Opportunity2__r.CWS_Fast_Track__c == false && (quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS ||
                quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT || quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) &&
                 (quoteObj.SBQQ__Opportunity2__r.StageName == CWS_ConstantClass.OPPORTUNITY_STAGE_DEMO || quoteObj.SBQQ__Opportunity2__r.StageName == CWS_ConstantClass.OPPORTUNITY_STAGE_ANALYSIS
                         || quoteObj.SBQQ__Opportunity2__r.StageName == CWS_ConstantClass.OPPORTUNITY_STAGE_PROSPECTING) && isSurveyCompleted(QuoteId) == false ){
                         List<String> parameters = new List<String>();
                         String forecastAmount = '$'+Label.CWS_Opportunity_Amount;
                         parameters.add(forecastAmount);
                         String salesError =  String.format(Label.CWS_Opportunity_Survey_Error , parameters);
                         quoteErrorMessage.put('SalesSurveyError',salesError );
                    }*/
                    //BED-12608
                }

                if(prodCategorySet.contains(CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH) && prodCategorySet.size() > 1){
                      quoteErrorMessage.put('DedicatedTechError',System.Label.CWS_DedicatedTechError);
                }

                //START CR_RECOMMIT  For NB & RWC quotes if transaction reason is recommit and original contract and credit quote field is not populated then error is thrown
                if(quoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT  && (quoteObj.CWS_Original_Contract__c == null || quoteObj.CWS_Credit_Quote__c == null) &&
                      (quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS || quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC)){
                        quoteErrorMessage.put('Recommit Error',System.Label.CWS_Recommit_Contract_Error);
                    }
                //END CR_RECOMMIT  
                
                if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && evergreenQuote && quoteObj.SBQQ__MasterEvergreenContract__c == null){
                    quoteErrorMessage.put('MasterEvergreenContractError',System.Label.CWS_MasterEvergreenContract_Error);
                    
                }
        
             if(quoteObj.CWS_Reference_Expiry_Date__c != null  && quoteObj.SBQQ__ExpirationDate__c == null){
                    quoteErrorMessage.put('ExpireDateError',System.Label.CWS_Expire_Date);
                }
                else if(!evergreenQuote && quoteObj.SBQQ__MasterContract__c == null && quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT){
                    quoteErrorMessage.put('MasterContractError',System.Label.CWS_MasterContract_Error);
                }

               if(prodSubCategorySet.contains(CWS_ConstantClass.PRODUCT_SUB_CATEGORY_EVENTS) && quoteObj.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION){
                      grpmmbrLst  =  [Select UserOrGroupId from GroupMember where Group.DeveloperName = 'CWS_Event_Sponsorship'];
                      for(GroupMember m: grpmmbrLst){
                        if (((String)m.UserOrGroupId).startsWith(userType))
                        {
                            ESGroupIds.add(m.UserOrGroupId);
                        }
                      }
                        if(!ESGroupIds.contains(loggedUser)){
                          quoteErrorMessage.put('UserEventAndSponsorshipError',System.Label.CWS_UserEventAndSponsorshipError);
                        }
                        if(prodSubCategorySet.size() > 1){
                          quoteErrorMessage.put('EventAndSponsorshipError',System.Label.CWS_EventAndSponsorshipError);
                        }
                        if(quoteObj.CWS_Route_to_Market__c != null && quoteObj.CWS_Route_to_Market__c != CWS_ConstantClass.RTM_Value_Direct){
                          quoteErrorMessage.put('RTMEventAndSponsorshipError',System.Label.CWS_RTMEventAndSponsorshipError);
                        }
                    }
                    //6515: Validating Vendor Approval Required checkbox
                    //Commented by Mahak Bansal 3 Jan 2022 , OBD-3248
                    //Remove validation on Vendor Approval Checkbox
                    /*if(!(quoteObj.CWS_Vendor_Approval_Received__c) && QLIidset.size()> 0){
                        quoteErrorMessage.put('VendorApprovalRequiredError',System.Label.CWS_VendorApprovalRequiredError);
                    }*/
          //BED-8168
                    if(quoteObj.SBQQ__Opportunity2__r.CWS_Fast_Track__c  && !quoteObj.CWS_isFastTrack__c){
                        quoteErrorMessage.put('OpportunityQuoteFTError',System.Label.CWS_FTOppQuote);
                    }
                    //BED-8168
          
          //BED-13423
                    if(!PrimarySTA){ 
                        quoteErrorMessage.put('PrimarySoldtoAccount',System.Label.CWS_ErrorMessageSTAPrimary);
                    }
                    if(!PrimaryBTA){
                        quoteErrorMessage.put('PrimaryBilltoAccount',System.Label.CWS_ErrorMessageBTAPrimary);
                    }
                    //BED-13423
            }            
            return quoteErrorMessage;
        }catch(Exception e){
        CWS_ExceptionHandler.logException( e,'Quote' , 'refreshPriceOnQuote', '' , '', null, null , 'AcceptQuote' , null);
            System.debug('Exception is ----> ' + e.getMessage() + '\nStacktrace: ' + e.getStackTraceString());
        throw new AuraHandledException('Exception occurred during Refresh Price '+ e.getMessage());
      }       
    }

    /* Method Name : isSurveyCompleted
    * Description : Validates whether survey fields have been filled out or not.
    * Returns     : Boolean
    * Developer   : Manoj
    */
    //BED-12608
    @AuraEnabled
     public static Boolean isSurveyCompleted(Id quoteId){
     try{         
         SBQQ__Quote__c quote;
         Opportunity opp = [ SELECT Id, CWS_Define_The_Prospects_Challenges__c,CWS_Budget_in_place__c,
                            CWS_Which_CW_Products_Solve_Issues__c,CWS_Detail_the_Challenges__c,
                            CWS_Negative_Impact_To_The_Business__c,CWS_Your_Champion__c,
                            CWS_Has_Champion_Used_CW_In_Past__c,CWS_Were_Deal_Breakers_After_Demo__c,
                            CWS_Decision_Maker__c,CWS_Define_Success_Criteria__c,CWS_Deal_Breakers__c,
                            CWS_Competitor_Takeaway_Automate_Command__c,CWS_Competitor_Takeaway_BDR__c,
                            CWS_Competitor_Takeaway_Control__c,CWS_Competitor_Takeaway_Help_Desk__c,
                            CWS_Competitor_Takeaway_Manage__c,CWS_Competitor_Takeaway_RMM__c,
                            CWS_Competitor_Takeaway_Security__c,CWS_Competitor_Takeaway_Sell__c                            
                            FROM Opportunity WHERE SBQQ__PrimaryQuote__c =:quoteId];    
    if(opp != null ){          
        String fieldName;
        for(Schema.FieldSetMember fld :SObjectType.Opportunity.FieldSets.CWS_Sales_And_Demo_Section_Fields.getFields()){
            fieldName = fld.getFieldPath();            
            if(opp.get(fieldName) == null || opp.get(fieldName) == ''){
                return false;
            }
        }
        for(Schema.FieldSetMember fld :SObjectType.Opportunity.FieldSets.CWS_Competitor_fields.getFields()){
            fieldName = fld.getFieldPath();            
            if(opp.get(fieldName) != null && opp.get(fieldName) != ''){
                return true;
            }
        }        
    }
    return false;
    }
    catch(Exception e){
        CWS_ExceptionHandler.logException( e,'Quote' , 'refreshPriceOnQuote', '' , '', null, null , 'AcceptQuote' , null);
        throw new AuraHandledException('Exception occurred during Refresh Price '+ e.getMessage());
    } 
    } // End BED-12608

    //Ticket 14021920 starts
     @AuraEnabled
     public static Boolean futurePriceCalculation(Id quoteId, Boolean calledMethod){
         try{ 
             Date lowDate;
             List<SBQQ__QuoteLine__c> updQuoteLine = new List<SBQQ__QuoteLine__c>();
             List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

              SBQQ__Quote__c quoteObj = [SELECT Id, CWS_Route_to_Market__c, CWS_Bill_To_Account__c, CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c, CWS_Quote_Type__c,SBQQ__ExpirationDate__c, SBQQ__LineItemCount__c FROM SBQQ__Quote__c where Id =:quoteId];

             if(quoteObj!=null && quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && quoteObj.SBQQ__LineItemCount__c>0){
                 quoteLines = [SELECT Id, SBQQ__EffectiveQuantity__c, CWS_CustomerPrice_per_billing_period__c, CWS_Quote_Doc_Price__c, SBQQ__PriorQuantity__c,SBQQ__Quantity__c, CWS_future_pricing_approval__c,SBQQ__Existing__c, CWS_Future_Priced_Line__c,CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c, 
                 CWS_Future_Priced_Line__r.CWS_Future_Contracted_Price__c, CWS_Future_Contracted_Price__c, CWS_Discretionary_Discount_Future_Price__c, CWS_Future_Priced_Line__r.CWS_Future_Price_End_Date__c,CWS_NetPrice__c, CWS_Future_pricing_Blocks__c, CWS_Future_Price_End_Date__c, 
                 SBQQ__UpgradedSubscription__c, SBQQ__DistributorDiscount__c  from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteObj.id];

             for(SBQQ__QuoteLine__c qLine:quoteLines){
                 Date futureDate;
                 Boolean futurepriceApproval=false;

                 if(quoteObj.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c && quoteObj.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel){
                                   if(qLine.CWS_Future_Priced_Line__c!=null && (qLine.CWS_Future_Priced_Line__r.CWS_Future_Contracted_Price__c.setScale(2,System.RoundingMode.HALF_UP)==qLine.CWS_CustomerPrice_per_billing_period__c)
                                    && (qLine.CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c!=null?(qLine.SBQQ__Quantity__c>=qLine.CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c):true)){
                                        futurepriceApproval = true;
                                    }
                                    else if(qLine.CWS_Future_Contracted_Price__c!=null && (qLine.CWS_Future_Contracted_Price__c.setScale(2,System.RoundingMode.HALF_UP)==qLine.CWS_CustomerPrice_per_billing_period__c)
                                    && (qLine.CWS_Future_pricing_Blocks__c!=null?(qLine.SBQQ__Quantity__c - (qLine.SBQQ__UpgradedSubscription__c!=null?qLine.SBQQ__PriorQuantity__c:0)>=qLine.CWS_Future_pricing_Blocks__c):true)){
                                        futurepriceApproval = true;
                                    } 
                                }
                                else{
                                    if(qLine.CWS_Future_Priced_Line__c!=null && (qLine.CWS_Future_Priced_Line__r.CWS_Future_Contracted_Price__c.setScale(2,System.RoundingMode.HALF_UP)==qLine.CWS_Quote_Doc_Price__c)
                                    && (qLine.CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c!=null?(qLine.SBQQ__Quantity__c>=qLine.CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c):true)){
                                        futurepriceApproval = true;
                                    }
                                    else if(qLine.CWS_Future_Contracted_Price__c!=null && (qLine.CWS_Future_Contracted_Price__c.setScale(2,System.RoundingMode.HALF_UP)==qLine.CWS_Quote_Doc_Price__c)
                                    && (qLine.CWS_Future_pricing_Blocks__c!=null?(qLine.SBQQ__Quantity__c - (qLine.SBQQ__UpgradedSubscription__c!=null?qLine.SBQQ__PriorQuantity__c:0)>=qLine.CWS_Future_pricing_Blocks__c):true)){
                                        futurepriceApproval = true;
                                    }
                                }
                                

                            if(futurepriceApproval){
                                if(qLine.CWS_Future_Priced_Line__c!=null){
                                    futureDate = (qLine.CWS_Future_Priced_Line__r.CWS_Future_Price_End_Date__c!=null)?qLine.CWS_Future_Priced_Line__r.CWS_Future_Price_End_Date__c:null;
                                    if(system.today()<futureDate || futureDate==null){
                                        if(!qLine.CWS_future_pricing_approval__c){
                                        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
                                        ql.Id = ID.valueOf(qLine.Id);
                                        ql.CWS_future_pricing_approval__c = true;
                                        updQuoteLine.add(ql);
                                        }

                                        if(futureDate!=null){
                                         if(lowDate==null){
                                            lowDate = futureDate;
                                        }
                                        else if(lowDate>futureDate){
                                            lowDate = futureDate;
                                        }
                                        }
                                    }
                                }
                                else{
                                    futureDate = (qLine.CWS_Future_Price_End_Date__c!=null)?qLine.CWS_Future_Price_End_Date__c:null;
                                     if(system.today()<futureDate || futureDate == null){
                                        if(!qLine.CWS_future_pricing_approval__c){
                                        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
                                        ql.Id = ID.valueOf(qLine.Id);
                                        ql.CWS_future_pricing_approval__c = true;
                                        updQuoteLine.add(ql);
                                        }
                                        if(futureDate!=null){
                                        if(lowDate==null){
                                            lowDate = futureDate;
                                        }
                                        else if(lowDate>futureDate){
                                            lowDate = futureDate;
                                        }
                                        }
                                    }
                                }    
                            }
                            else if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && (qLine.CWS_Future_Priced_Line__c!=null || qLine.CWS_Future_Contracted_Price__c!=null) && qline.CWS_future_pricing_approval__c){
                                        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();   
                                        ql.Id = ID.valueOf(qLine.Id);
                                        ql.CWS_future_pricing_approval__c = false;
                                        updQuoteLine.add(ql);
                            }
                        }
                    }
                    if(lowDate!=null && quoteObj.SBQQ__ExpirationDate__c>lowDate && calledMethod){
                        return true;
                    }
                    else if(updQuoteLine.size()>0){
                        update updQuoteLine;
                        return false;
                    }
                    else{
                        return false;
                    }
        }
        catch(Exception e){
        CWS_ExceptionHandler.logException( e,'Quote' , 'refreshPriceOnQuote', '' , '', null, null , 'AcceptQuote' , null);
        throw new AuraHandledException('Exception occurred during FuturePriceCalculation '+ e.getMessage());
        }
    }          
     //Ticket 14021920 ends

}