/* Class Name   : CWS_QuoteTemplateLineItemsCtrl
 * Description  : Controller for VF CWS_Quote_Template_LineItems for generating XSLFO
 * Created By   : Khayam
 * Created On   : 5/5/2020

 * Modification Log:     
 * -------------------------------------------------------------------------------------
 * Developer                Date                    Modification ID      Description 
 * -------------------------------------------------------------------------------------
 * Khayam                   5/5/2020                BED-5114
 * Aakash                   6/15/2020               BED-12099           Transaction Type Check
 * Megha                    6/23/2020               BED-9272
 * Gautam                   8/15/2021               OBD-1213            Re-enabled SOW Link functionality previously commented out
 * Pooja 					8/23/2021				OBD-662				Filter Quote line based on active Payment schedule driver
 * Gautam                   9/13/2021               OBD-2057            Ramp/Defer/Spread not appearing on Quotes
*/  
public with sharing class CWS_QuoteTemplateLineItemsCtrl {

   
    public Id recId {get;set;}
    public LineItemWrapper wrap{get;set;}

    public boolean oneTimeProductsAvailable{get;set;}
    //public String sowLink{get;set;}
    public String sowLinkStaticText{get;set;}
    public CWS_QuoteTemplateLineItemsCtrl(){
        recId = (Id)ApexPages.currentPage().getParameters().get('qid').escapeHtml4();
        oneTimeProductsAvailable = false;
        sowLinkStaticText = System.label.Statement_of_Work_Hyperlink_Text;
    }

    public PageReference fetchData(){
        List<SBQQ__Quoteline__c> quotelines = new List<SBQQ__Quoteline__c>();
        try {

            if (recId!=null) {
            quotelines = [SELECT CWS_Is_Active_Ramp_Line__c,SBQQ__DiscountScheduleType__c,CWS_Calculated_Subscription_Term__c,CWS_Disti_Regular_Price__c,SBQQ__ProrateMultiplier__c,SBQQ__DefaultSubscriptionTerm__c,CWS_MM_ListPrice__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c, CWS_Usage_Ramp_Qty__c, CWS_Min_Commit__c,SBQQ__Product__r.CWS_Service_SOW_Link__c, SBQQ__Quote__r.SBQQ__StartDate__c, SBQQ__Quote__r.SBQQ__EndDate__c,SBQQ__StartDate__c,SBQQ__EndDate__c,SBQQ__SubscriptionTerm__c,SBQQ__Quote__r.SBQQ__Account__r.CWS_Is_Distributor__c,SBQQ__Quote__r.SBQQ__Account__r.CWS_Is_IIT_Reseller__c,
                                     SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c,CWS_Payment_Schedule_Driver__c,
                                     CWS_Reseller_Net_Price__c,CWS_MM_UPLIFT__c,CWS_Disti_Factor__c,CWS_Distributor_Net_Price__c,
                                     CWS_RegularPrice__c,SBQQ__CustomerTotal__c,CWS_NetPrice__c,SBQQ__Quote__r.CWS_Route_to_Market__c, 
                                     SBQQ__TotalDiscountAmount__c,CWS_Billing_Term__c,SBQQ__Product__r.CWS_ChargeType__c,SBQQ__ChargeType__c,
                                     SBQQ__Quote__r.CWS_Currency_Symbol__c,SBQQ__ProductCode__c,CWS_Period_for_Ramp_Spread_Deferment__c,
                                     SBQQ__ListPrice__c,SBQQ__CustomerPrice__c,SBQQ__NetTotal__c, SBQQ__ProductName__c,SBQQ__Quantity__c,SBQQ__PriorQuantity__c,CWS_Exclude_from_Net_Total__c,
                                     SBQQ__Product__r.CWS_Description__c, SBQQ__Product__r.CWS_Hide_on_OrderForm__c, CWS_Transaction_Type__c,SBQQ__EffectiveQuantity__c, SBQQ__Quote__r.CWS_Quote_Type__c,SBQQ__Quote__r.SBQQ__Type__c , CWS_Transaction_Quantity__c, SBQQ__Quote__r.CWS_Transaction_Reason__c, CWS_Minimum_Commit_Eligibility__c,SBQQ__PricingMethod__c
                                     from SBQQ__QuoteLine__c 
                          			 where SBQQ__Quote__c =: recId and CWS_Billing_Term__c != NULL  order by SBQQ__Number__c ASC];     
            }
            wrap = new LineItemWrapper();

            if (!quotelines.isEmpty()) {

                wrap.currencySymbol = quotelines[0].SBQQ__Quote__r.CWS_Currency_Symbol__c;
                
                IF(quotelines[0].SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c != System.Label.CWS_Disti_Deal_End_Customer_Pricing && quotelines[0].SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c &&   (quotelines[0].SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT || quotelines[0].SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel)){
                wrap.isCustTotPriceSet = true;
                }   
                        
                for (SBQQ__Quoteline__c line : quotelines) {
                     if(line.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c == System.Label.CWS_Disti_Deal_End_Customer_Pricing){
                         wrap.isDistiOF = true;
                     }
                    if(line.SBQQ__Product__r.CWS_Hide_on_OrderForm__c == false){
                    //Added this Condition as part of BED-12099
                        if(line.CWS_Transaction_Type__c != null && !(line.SBQQ__Quote__r.SBQQ__Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && 
                         (line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW || line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3
                         || line.CWS_Transaction_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL))){
                        makeDefaults(line);
                        BillingTermWrapper bTermWrap = wrap.linesMap.get(line.CWS_Billing_Term__c);
                        if(bTermWrap == NULL){
                                bTermWrap = new BillingTermWrapper(line.CWS_Billing_Term__c);
                                List<UIDisplayColumns> uiLines = bTermWrap.lines;
                                UIDisplayColumns cols = new UIDisplayColumns();
                                populatePrices(cols, line);
                                bTermWrap.lines.add(cols);
                                wrap.linesMap.put(line.CWS_Billing_Term__c, bTermWrap);     
                            
                        } else {
                            List<UIDisplayColumns> uiLines = bTermWrap.lines;
                            UIDisplayColumns cols = new UIDisplayColumns();
                            populatePrices(cols, line);
                            bTermWrap.lines.add(cols);
                            wrap.linesMap.put(line.CWS_Billing_Term__c, bTermWrap);
                        }

                        if( String.isNotEmpty(line.CWS_Billing_Term__c) 
                        && !oneTimeProductsAvailable 
                        && line.CWS_Billing_Term__c ==  CWS_ConstantClass.BillingTerm_OneTime ){
                            oneTimeProductsAvailable = true;
                            }
                        }
                    }
                }
            }
        } catch(Exception e){
            CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_QuoteTemplateLineItemsCtrl', 'fetchData' , '', null, null , 'fetchData' , null);
        }
        return null;
    }
    
    public void populatePrices(UIDisplayColumns cols, SBQQ__QuoteLine__c line){
 
        If(line != Null){
            cols.effectiveQty = line.SBQQ__EffectiveQuantity__c;
            cols.pricingMethod = line.SBQQ__PricingMethod__c;
            cols.productName = line.SBQQ__ProductName__c;
            cols.productCode = line.SBQQ__ProductCode__c;
            //9272
            // commented out as part of BED-12646: Uncommented as part of OBD-1213
            if(line.SBQQ__Product__r.CWS_Service_SOW_Link__c!= null){
            cols.productDescription = line.SBQQ__Product__r.CWS_Description__c;
            cols.staticText = System.label.CWS_Quote_Template;
            cols.sowLink  = line.SBQQ__Product__r.CWS_Service_SOW_Link__c;
            System.debug('Description'+cols.productDescription);
            }            
            else{
            cols.productDescription = line.SBQQ__Product__r.CWS_Description__c;
            cols.staticText = null;
            cols.sowLink  =  null;
            }
            //9272
            cols.minCommit = line.CWS_Min_Commit__c;
            cols.usageRampQty = line.CWS_Usage_Ramp_Qty__c;
            cols.qty = line.SBQQ__Quantity__c;
            cols.custNetPrice = 0;         
            

            String uQty = '';
            if(cols.usageRampQty != null){
                integer i=0;
                for(String qty:cols.usageRampQty.split(';')){
                    if(math.mod(i+1,3)==0){
                        uQty += (qty+';'+' ');
                    } else {
                        uQty += (qty+';');
                    }
                    i=math.mod(i+1,3);
                }
            }
            if(String.isNotEmpty(uQty)){
                cols.usageRampQty = uQty.trim().removeEnd(';');
            }
                         
            IF(line.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c == System.Label.CWS_Disti_Deal_Disti_Pricing_Value && line.SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c && 
            (line.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT || line.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel)){
               wrap.isCustTotPriceSet = true;
            }
            
            if (line.CWS_Period_for_Ramp_Spread_Deferment__c != NULL && ((line.SBQQ__StartDate__c != null && line.CWS_Is_Active_Ramp_Line__c == true) || line.SBQQ__StartDate__c == null)) {
                cols.paymentPeriod = line.CWS_Period_for_Ramp_Spread_Deferment__c + ' months ' + line.CWS_Payment_Schedule_Driver__c;
                cols.paymentPeriod = line.CWS_Period_for_Ramp_Spread_Deferment__c == 1 ? cols.paymentPeriod.replaceAll('months','month') : cols.paymentPeriod;
            }
            
            if(line.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Direct){                  
                cols.lstPrice = line.CWS_RegularPrice__c != null? line.CWS_RegularPrice__c :0;
                if(line.CWS_Exclude_from_Net_Total__c){
                    cols.price = line.CWS_RegularPrice__c != null? line.CWS_RegularPrice__c :0;
                }
                else{
                cols.price = line.CWS_NetPrice__c != null?line.CWS_NetPrice__c :0;
                }

            } else if (line.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel){
                
                cols.lstPrice = line.CWS_Disti_Regular_Price__c != null ? line.CWS_Disti_Regular_Price__c:0;

                if(line.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c == System.Label.CWS_Disti_Deal_End_Customer_Pricing){
                    cols.price = line.SBQQ__CustomerPrice__c != null? line.SBQQ__CustomerPrice__c: 0;
                } else {
                    if(line.CWS_Exclude_from_Net_Total__c){
                    cols.price = line.CWS_RegularPrice__c != null? line.CWS_RegularPrice__c:0;
                    }
                    else{
                    cols.price = line.CWS_NetPrice__c != null?line.CWS_NetPrice__c :0;
                    }
                    cols.custNetPrice = line.SBQQ__CustomerPrice__c*line.SBQQ__Quantity__c;
                }

            } else if (line.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT){
                cols.lstPrice = line.CWS_MM_ListPrice__c != null ? line.CWS_MM_ListPrice__c : 0;
                 
                if(line.SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c && line.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c 
                == System.Label.CWS_Disti_Deal_End_Customer_Pricing){
                   cols.price =line.SBQQ__CustomerPrice__c != null? line.SBQQ__CustomerPrice__c:0;
                 }else{
                        if(line.CWS_Exclude_from_Net_Total__c){
                            cols.price = line.CWS_RegularPrice__c != null? line.CWS_RegularPrice__c:0;
                        }
                        else{
                            cols.price = line.CWS_Reseller_Net_Price__c != null? line.CWS_Reseller_Net_Price__c:0;
                        }  
                   cols.custNetPrice = line.SBQQ__CustomerPrice__c*line.SBQQ__Quantity__c;
                 }
            }  
             
            // BED-12058 start
            if (line.SBQQ__Quote__r.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {
                Date stDate = line.SBQQ__StartDate__c != null ? line.SBQQ__StartDate__c : line.SBQQ__Quote__r.SBQQ__StartDate__c;
                Date edDate = line.SBQQ__EndDate__c != null ? line.SBQQ__EndDate__c: line.SBQQ__Quote__r.SBQQ__EndDate__c;
                line.SBQQ__SubscriptionTerm__c = line.CWS_Calculated_Subscription_Term__c;
            }
            // BED-12058 end

            // ANNUALISE PRICE
            Decimal acvLPrice=0;
            Decimal acvNPrice=0;
            Decimal acvCustPrice=0;
            if(line.SBQQ__SubscriptionTerm__c != null && line.SBQQ__SubscriptionTerm__c != 0){
                if(cols.lstPrice != null){
                acvLPrice = cols.lstPrice * (12/line.SBQQ__SubscriptionTerm__c);
                }
                if(cols.price != null){
                acvNPrice = cols.price * (12/line.SBQQ__SubscriptionTerm__c);
                }
            
                acvCustPrice = cols.custNetPrice * (12/line.SBQQ__SubscriptionTerm__c);
            }

            if (line.CWS_Billing_Term__c == CWS_ConstantClass.BillingTerm_Monthly) {
                cols.lstPrice = acvLPrice / 12;
                cols.price = acvNPrice / 12;
                cols.custNetPrice = acvCustPrice / 12;
            } else if(line.CWS_Billing_Term__c == CWS_ConstantClass.BillingTerm_Quarterly){
                cols.lstPrice = acvLPrice / 4;
                cols.price = acvNPrice / 4;
                cols.custNetPrice = acvCustPrice / 4;
            } else if(line.CWS_Billing_Term__c == CWS_ConstantClass.BillingTerm_SemiAnnual){
                cols.lstPrice = acvLPrice / 2;
                cols.price = acvNPrice / 2;
                cols.custNetPrice = acvCustPrice / 2;
            } else if(line.CWS_Billing_Term__c == CWS_ConstantClass.BillingTerm_Annual){
                cols.lstPrice = acvLPrice;
                cols.price = acvNPrice;
                cols.custNetPrice = acvCustPrice;
            } else if(line.CWS_Billing_Term__c == CWS_ConstantClass.BillingTerm_BiAnnual){
                cols.lstPrice = acvLPrice * 2 ;
                cols.price = acvNPrice * 2 ;
                cols.custNetPrice = acvCustPrice * 2;
            } else if(line.CWS_Billing_Term__c == CWS_ConstantClass.BillingTerm_TriAnnual){
                cols.lstPrice = acvLPrice * 3 ;
                cols.price = acvNPrice * 3 ;
                cols.custNetPrice = acvCustPrice * 3;
            } 

           if(line.SBQQ__DiscountScheduleType__c == CWS_ConstantClass.DISCOUNTSCH_SLAB){
               cols.lstPrice = cols.lstPrice.setScale(2,System.RoundingMode.HALF_UP);
           }
            cols.discAmnt = (cols.lstPrice - cols.price);
            if(cols.pricingMethod == CWS_ConstantClass.PRICINGMETHOD_BLOCK){
                cols.extPrice = (cols.price * cols.effectiveQty);
                cols.totdiscAmnt = (cols.lstPrice - cols.price)*cols.effectiveQty;
            }else{
                cols.extPrice = (cols.price * cols.qty);
                cols.totdiscAmnt = (cols.lstPrice - cols.price)*cols.qty;  
            }
        } 
        
    }

    public void makeDefaults(SBQQ__QuoteLine__c line){
        List<String> transactionType = new String[6];        
        transactionType[0] = CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE;
        transactionType[1] = CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE;
        transactionType[2] = CWS_ConstantClass.TRANSACTION_TYPE_CANCEL;
        transactionType[3] = CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT;
        transactionType[4] = CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN;
        
        line.SBQQ__ListPrice__c = line.SBQQ__ListPrice__c != null ? line.SBQQ__ListPrice__c : 0;
        line.SBQQ__CustomerPrice__c = line.SBQQ__CustomerPrice__c != null ? line.SBQQ__CustomerPrice__c : 0;
        //line.SBQQ__TotalDiscountAmount__c = line.SBQQ__TotalDiscountAmount__c != null ? line.SBQQ__TotalDiscountAmount__c : 0;
        //BED-9254 starts
        if(line.CWS_Transaction_Type__c!=null && line.SBQQ__Quote__r.CWS_Transaction_Reason__c !=null && line.SBQQ__Quote__r.CWS_Quote_Type__c!=null){
         if(transactionType.contains(line.CWS_Transaction_Type__c) && line.SBQQ__Quote__r.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT){
                line.SBQQ__Quantity__c = line.SBQQ__EffectiveQuantity__c;
            }
                      
        transactionType.remove(3);
        transactionType.remove(4);        
         
        if(line.CWS_Transaction_Quantity__c!=null && transactionType.contains(line.CWS_Transaction_Type__c)&& line.SBQQ__Quote__r.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && line.SBQQ__Quote__r.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RENEWALWC){
                line.SBQQ__Quantity__c = line.SBQQ__Quantity__c;//12894 Keeping the Remaining quantity after downgrade ( - line.CWS_Transaction_Quantity__c)
            }
        }
        //BED-9254 ends
    }

    public with sharing class LineItemWrapper {
        
        public String currencySymbol{get;set;}
        public boolean isCustTotPriceSet{get;set;}
        public boolean isDistiOF{get;set;}
        public Map<String,BillingTermWrapper> linesMap{get;set;}
        public Boolean hasRecurrLines{get{
            if (linesMap != null) {
                for (BillingTermWrapper bWrap: linesMap.values()) {
                    for (UIDisplayColumns col : bWrap.lines) {
                        if (bWrap.bType != CWS_ConstantClass.BillingTerm_OneTime && !col.minCommit) {
                            return true;
                        }
                    }
                }
            }
            return false;
        }set;}

        public Boolean hasMinCommLines{get{
            if (linesMap != null) {
                for (BillingTermWrapper bWrap: linesMap.values()) {
                    for (UIDisplayColumns col : bWrap.lines) {
                        if (col.minCommit) {
                            return true;
                        }
                    }
                }
            }
            return false;
        }set;}
        public Boolean hasRecurrDisc{get{
            for (BillingTermWrapper bWrap : linesMap.values()) {
                if (bWrap.bType != CWS_ConstantClass.BillingTerm_OneTime && bWrap.totDisc != 0) {
                    return true;
                }
            }
            return false;
        }set;}

        public Boolean hasMinCommDisc{get{
            if (linesMap != null) {
                for (BillingTermWrapper bWrap: linesMap.values()) {
                    for (UIDisplayColumns col : bWrap.lines) {
                        if (col.minCommit && bWrap.totDiscMinComm != 0) {
                            return true;
                        }
                    }
                }
            }
            return false;
        }set;}
                
        public List<String> bTypes {get{
            List<String> types = new List<String>();
            if (linesMap != NULL) {
                if (linesMap.containsKey(CWS_ConstantClass.BillingTerm_OneTime)) {
                    types.add(CWS_ConstantClass.BillingTerm_OneTime);
                }
                if (linesMap.containsKey(CWS_ConstantClass.BillingTerm_Monthly)) {
                    types.add(CWS_ConstantClass.BillingTerm_Monthly);
                }
                if (linesMap.containsKey(CWS_ConstantClass.BillingTerm_Quarterly)) {
                    types.add(CWS_ConstantClass.BillingTerm_Quarterly);
                }
                if (linesMap.containsKey(CWS_ConstantClass.BillingTerm_SemiAnnual)) {
                    types.add(CWS_ConstantClass.BillingTerm_SemiAnnual);
                }
                if (linesMap.containsKey(CWS_ConstantClass.BillingTerm_Annual)) {
                    types.add(CWS_ConstantClass.BillingTerm_Annual);
                }
                if (linesMap.containsKey(CWS_ConstantClass.BillingTerm_BiAnnual)) {
                    types.add(CWS_ConstantClass.BillingTerm_BiAnnual);
                }
                if (linesMap.containsKey(CWS_ConstantClass.BillingTerm_TriAnnual)) {
                    types.add(CWS_ConstantClass.BillingTerm_TriAnnual);
                }
            }
            return types;
        }set;}

        public LineItemWrapper(){
            linesMap = new Map<String,BillingTermWrapper>();
        }
    }
    
    public with sharing class UIDisplayColumns {
       
        public String productName{get;set;}
        public String productCode{get;set;}
        public String productDescription{get;set;}
        public String staticText{get;set;}
        public String sowLink{get;set;}
        public String paymentPeriod{get;set;}
        public String pricingMethod{get;set;}
        public Decimal qty{get;set;}
        public Decimal effectiveQty{get;set;}
        public Decimal lstPrice{get;set;}
        public Decimal discAmnt{get;set;}
        public Decimal totdiscAmnt{get;set;}
        public Decimal price{get;set;}
        public Decimal extPrice{get;set;}
        public Decimal custNetPrice{get;set;}
        public Boolean minCommit{get;set;}
        public String usageRampQty{get;set;}
    }
      
    public with sharing class BillingTermWrapper {
             
        public Decimal countLines{get;set;}
        public String bType{get;set;}

        public List<UIDisplayColumns> lines{get;set;}      
        public Decimal totFee{get{
            Decimal val = 0;
            for (UIDisplayColumns wrap : lines) {
                if (!wrap.minCommit) {
                    val += wrap.extPrice;
                }
            }
            return val;
        }set;}  
        public Decimal totDisc{get{
            Decimal val = 0;
            for (UIDisplayColumns wrap : lines) {
                if (!wrap.minCommit) {
                    val += wrap.totdiscAmnt;
                }
            }
            return val;
        }set;} 
        public Decimal totFeeMinComm{get{
            Decimal val = 0;
            for (UIDisplayColumns wrap : lines) {
                if (wrap.minCommit) {
                    val += wrap.extPrice;
                }
            }
            return val;
        }set;}  
        public Decimal totDiscMinComm{get{
            Decimal val = 0;
            for (UIDisplayColumns wrap : lines) {
                if (wrap.minCommit) {
                    val += wrap.totdiscAmnt;
                }
            }
            return val;
        }set;} 
        public Boolean hasMinCommLines{get{
            for (UIDisplayColumns wrap : lines) {
                if (wrap.minCommit) {
                    return true;
                }
            }
            return false;
        }set;} 

        public BillingTermWrapper(String billType){
            lines = new List<UIDisplayColumns>();
            countLines = 0;
            bType = billType;
        }
    }
    
}