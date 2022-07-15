/* Class Name   : CWS_QuoteTermsCtrl
* Description  : Controller for VF CWS_QuoteTerms for generating XSLFO
* Created By   : Khayam
* Created On   : 6/11/2020

* Modification Log:     
* -------------------------------------------------------------------------------------
* Developer                Date                    Modification ID      Description 
* -------------------------------------------------------------------------------------
* Khayam                   6/11/2020                BED-9847
* Akhila				   6/29/2020				BED-3339
*/
public with sharing class CWS_QuoteTermsCtrl {
    
    public Id recId {get;set;}
    public List<DowngradeQLIWrapper> downgradeQliWrapper {get; private set;}
    public List<futurePricingQLI> futurePriceWrapper {get; private set;}
    public List<implementationSpreadQLI> impSpreadQLIWrapper {get; private set;}
    public List<downgradeAssurance> downgradeAssuranceQL{get; private set;}
    public Boolean isDowngradeOrCancel{get;set;}
    public Boolean isFuturePricing{get;set;}
    public List<List<String>> DowngradeTable{get;set;}
    public Boolean has3rdPartyProds{get;set;}
    public Boolean hasNon3rdPartyProds{get;set;}
    public Decimal AutomatePerpetualLinesCount{get;set;}
    public Decimal AutomateMaintenanceLinesCount{get;set;}
    public Decimal ManagePerpetualLinesCount{get;set;}
    public Decimal ManageMaintenanceLinesCount{get;set;}
    public Boolean isActiveNoAssurance{get;set;}
    public List<String> automatePerpProducts{get;set;}
    public List<String> managePerpProducts{get;set;}
    public String products{get;set;}
    public String automateActiveProds{get;set;}
    public String manageActiveProds{get;set;}
    public Boolean isImpSpread{get;set;}
    public Boolean hasSwappedProd{get;set;}
    public Boolean isMaintenanceProd{get;set;}
    public String paymentTerms{get;set;}
	public Boolean DisplaypaymentTerms{get;set;}
	public String currencySymbol{get;set;}
	public Map<Integer, Decimal> mapMonthsToSpreadValues2{get;set;}

    
    public CWS_QuoteTermsCtrl(){
        recId = (Id)ApexPages.currentPage().getParameters().get('qid').escapeHtml4();
    }
    
    public PageReference fetchData(){
        try {
            downgradeQliWrapper =new List<DowngradeQLIWrapper>();
            futurePriceWrapper = new List<futurePricingQLI>();
            impSpreadQLIWrapper = new List<implementationSpreadQLI>();
            downgradeAssuranceQL = new List<downgradeAssurance>();
            List<SBQQ__Quoteline__c> quotelines = new List<SBQQ__Quoteline__c>();
            isDowngradeOrCancel = false;
            DowngradeTable = new List<List<String>>();  
            isFuturePricing = false;
            has3rdPartyProds = false;
            hasNon3rdPartyProds = false;
            isImpSpread = false;
            AutomatePerpetualLinesCount = 0;
            AutomateMaintenanceLinesCount = 0;
            ManagePerpetualLinesCount = 0;
            ManageMaintenanceLinesCount = 0;
            isActiveNoAssurance = false;
            hasSwappedProd=false;
			DisplaypaymentTerms = false;			
            isMaintenanceProd = false;
            automatePerpProducts = new List<String>();
            managePerpProducts = new List<String>();
            
            if (recId!=null) {
                quotelines = [SELECT SBQQ__Product__c,SBQQ__Quote__r.CWS_Route_to_Market__c,CWS_NetPrice__c,
									CWS_Period_for_Ramp_Spread_Deferment__c,SBQQ__Quote__r.SBQQ__PaymentTerms__c,
									CWS_Quote_Type__c,SBQQ__ChargeType__c,CWS_Payment_Schedule_Driver__c,
									CWS_Min_Commit__c,SBQQ__NetTotal__c,SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
									SBQQ__SubscriptionTerm__c,CWS_Reseller_Net_Total__c,SBQQ__CustomerTotal__c,
									SBQQ__Quote__r.CWS_Partner_Signature_Received__c,SBQQ__Quote__r.CWS_Currency_Symbol__c,
									SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Is_Distributor__c,CWS_Future_Price_End_Date__c,
									SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c,
									SBQQ__Quote__r.CWS_Bill_To_Account__c,CWS_FirstMonthAmountforSpread__c,
									CWS_Swapped_For__c,SBQQ__Quote__r.Name,CWS_Swapped_For__r.Name,SBQQ__Quote__r.SBQQ__StartDate__c,
									CWS_Uneven_Spread__c,CWS_Uneven_Spread_Values__c,CWS_Sub_category__c,
									CWS_License_Type_Perpetual__c,SBQQ__EndDate__c,SBQQ__Product__r.CWS_Category__c,
									CWS_Future_Contracted_Price__c,CWS_Billing_Term__c,CWS_Future_pricing_Blocks__c,
									SBQQ__Product__r.Name,SBQQ__Quantity__c,SBQQ__PriorQuantity__c,SBQQ__StartDate__c,
									CWS_License_Type__c,CWS_Transaction_Type__c,SBQQ__Quote__c,SBQQ__Quote__r.CWS_Quote_Type__c,
                                    SBQQ__UpgradedSubscription__r.SBQQ__StartDate__c									
									from SBQQ__QuoteLine__c 
									where SBQQ__Quote__c =: recId ORDER BY Name];     
            }
            if (!quotelines.isEmpty()) {
                for (SBQQ__Quoteline__c line : quotelines) {
					if(line.SBQQ__Quote__r.CWS_Currency_Symbol__c != null){
						currencySymbol = line.SBQQ__Quote__r.CWS_Currency_Symbol__c;
					}
					else{
						currencySymbol = '';
					}
                    //DowngradeQLIWrapper wrapper = new DowngradeQLIWrapper();
                    futurePricingQLI futurewrapper = new futurePricingQLI();
                    implementationSpreadQLI spreadQLI = new implementationSpreadQLI();
                    downgradeAssurance assuranceQLI = new downgradeAssurance();
					
					if(line.SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Is_Distributor__c == True){
                        DisplaypaymentTerms = true;
                    }
                    
                    if(line.SBQQ__Quote__r.SBQQ__PaymentTerms__c != null){
                        paymentTerms = line.SBQQ__Quote__r.SBQQ__PaymentTerms__c;
                    }
                    if((line.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMEND || line.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC) && line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE && line.CWS_Sub_category__c == CWS_ConstantClass.Maintenance_sub_Category){
                        isMaintenanceProd = true;
                        assuranceQLI.maintenanceProd = line.SBQQ__Product__r.Name;
                        assuranceQLI.maintenanceProd = assuranceQLI.maintenanceProd.replaceAll('[^a-zA-Z0-9\\s+]', '');
                        assuranceQLI.netPrice = line.CWS_NetPrice__c;
                    	downgradeAssuranceQL.add(assuranceQLI);
                    }
                    //Check if Downgrade/Cancel/Swap-out quote lines are present
                    if(line.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMEND && (line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT || line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE || line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL)){
                        DowngradeQLIWrapper wrapper = new DowngradeQLIWrapper();
						isDowngradeOrCancel = true;
                    
                    if(line.SBQQ__Product__r.Name != null){
                        wrapper.name = line.SBQQ__Product__r.Name;
                        wrapper.name = wrapper.name.replaceAll('[^a-zA-Z0-9\\s+]', '');
                    }
                    if(line.CWS_License_Type__c != null){
                        wrapper.licenseType = line.CWS_License_Type__c;
                    }
                    if(line.SBQQ__PriorQuantity__c != null){
                        wrapper.priorQuantity=line.SBQQ__PriorQuantity__c;
                    }
                    if(line.SBQQ__Quantity__c != null){
                        wrapper.quantity = line.SBQQ__Quantity__c;
                    }
                    if(line.SBQQ__StartDate__c != null && 
                        (line.SBQQ__Quote__r.SBQQ__StartDate__c != null && line.SBQQ__StartDate__c != line.SBQQ__Quote__r.SBQQ__StartDate__c) &&
                        (line.SBQQ__UpgradedSubscription__c != null && line.SBQQ__StartDate__c != line.SBQQ__UpgradedSubscription__r.SBQQ__StartDate__c)){
                        wrapper.startDate = line.SBQQ__StartDate__c;
                    }
                        else{
                            wrapper.startDate = null;
                        }
                    
					downgradeQliWrapper.add(wrapper);
                    }
                    //Check if uneven spread is populated for Quote lines
                    if(line.CWS_Uneven_Spread__c && line.CWS_Uneven_Spread_Values__c != null){
						spreadQLI.haveData = true;
                        isImpSpread = true;
                        spreadQLI.prodName = line.SBQQ__Product__r.Name;
                        spreadQLI.prodName = spreadQLI.prodName.replaceAll('[^a-zA-Z0-9\\s+]', '');
                        List<String> lstSpreadValues = new List<String>();
                        lstSpreadValues = line.CWS_Uneven_Spread_Values__c.split(';');
                        
                        spreadQLI.unevenSpread = line.CWS_Period_for_Ramp_Spread_Deferment__c;
		                Integer i=0;
                        
                        if(lstSpreadValues.size() > 0){
                            spreadQLI.mapMonthsToSpreadValues = new map<Integer, Decimal>();   
                            for(String val:lstSpreadValues){
                                i++;
                                spreadQLI.mapMonthsToSpreadValues.put(i, Decimal.valueOf(val));
                            }
                        }
						
						if(spreadQLI.mapMonthsToSpreadValues != null){
							mapMonthsToSpreadValues2 = new map<Integer, Decimal>(spreadQLI.mapMonthsToSpreadValues);
                        }
                    }
                    
                    //Fetch details for swapped QLI's and calculate pricing 
                    if(line.CWS_Swapped_For__c != null && line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN){
						spreadQLI.haveData = true;
                        hasSwappedProd= true;
                        spreadQLI.swapOutProd = line.CWS_Swapped_For__r.Name;
                        spreadQLI.swapOutProd = spreadQLI.swapOutProd.replaceAll('[^a-zA-Z0-9\\s+]', '');
                        spreadQLI.swapInProd = line.SBQQ__Product__r.Name;
                        spreadQLI.swapInProd = spreadQLI.swapInProd.replaceAll('[^a-zA-Z0-9\\s+]', '');
                        spreadQLI.quote = line.SBQQ__Quote__r.Name;
                        if(line.CWS_Period_for_Ramp_Spread_Deferment__c != null && line.CWS_Period_for_Ramp_Spread_Deferment__c >0){
                            spreadQLI.periodForRamp = line.CWS_Period_for_Ramp_Spread_Deferment__c;
                        }
                        if(line.CWS_FirstMonthAmountforSpread__c != null){
                            spreadQLI.month1Amt = line.CWS_FirstMonthAmountforSpread__c;
                        }
                        if(line.SBQQ__StartDate__c != null){
                            spreadQLI.qlStartDate = line.SBQQ__StartDate__c;
                        }
                        if(line.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Direct){
                            spreadQLI.netTotal=line.SBQQ__NetTotal__c!=null? line.SBQQ__NetTotal__c:0;
                        }
                        else if(line.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel){
                            spreadQLI.netTotal=line.SBQQ__NetTotal__c!=null? line.SBQQ__NetTotal__c:0;
                            if(line.SBQQ__Quote__r.CWS_Bill_To_Account__c!=null && 
                               line.SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c==true &&
                               line.SBQQ__Quote__r.CWS_Partner_Signature_Received__c==false){
                                   spreadQLI.netTotal=line.SBQQ__CustomerTotal__c;
                               }
                        }
                        else if(line.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT){
                            if(line.SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c==true && 
                               line.SBQQ__Quote__r.CWS_Partner_Signature_Received__c==false){
                                   spreadQLI.netTotal=line.SBQQ__CustomerTotal__c;
                               }
                            else{
                                spreadQLI.netTotal=line.CWS_Reseller_Net_Total__c;
                            }
                        }
                        //Sub Term
                        if(line.SBQQ__SubscriptionTerm__c!=null){
                            spreadQLI.subTerm=(Integer)line.SBQQ__SubscriptionTerm__c;
                        }
                        else if(line.SBQQ__Quote__c!=null && line.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c!=null){
                            spreadQLI.subTerm=(Integer)line.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                        }
                        if(line.CWS_Payment_Schedule_Driver__c!=null ){
                            spreadQLI.productType=line.CWS_Payment_Schedule_Driver__c;
                        }                    
                        else if(line.SBQQ__ChargeType__c==CWS_ConstantClass.ChargeType_OneTime || 
                                (line.SBQQ__ChargeType__c==null && line.SBQQ__Product__r.SBQQ__ChargeType__c==CWS_ConstantClass.ChargeType_OneTime)){
                                    spreadQLI.productType=CWS_ConstantClass.ChargeType_OneTime;
                                }
                        else if((line.SBQQ__ChargeType__c==CWS_ConstantClass.ChargeType_Recurring || line.SBQQ__ChargeType__c==CWS_ConstantClass.ChargeType_Usage) ||
                                (line.SBQQ__ChargeType__c==null && (line.SBQQ__Product__r.SBQQ__ChargeType__c==CWS_ConstantClass.ChargeType_Recurring ||
                                                                    line.SBQQ__Product__r.SBQQ__ChargeType__c==CWS_ConstantClass.ChargeType_Usage))){
                                                                        spreadQLI.productType=CWS_ConstantClass.ChargeType_Recurring;
                                                                    }
                        
                        if(line.CWS_Min_Commit__c || (line.CWS_Min_Commit__c && (spreadQLI.productType==CWS_ConstantClass.PAYMENT_SCHEDULE_USAGE_BASED_RAMP || spreadQLI.productType==CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP))){
                            spreadQLI.month2Amt= (spreadQLI.subTerm!=null)?(spreadQLI.netTotal/spreadQLI.subTerm).setScale(2,System.RoundingMode.HALF_UP):0;
                        }                   
                        else if(spreadQLI.productType==CWS_ConstantClass.ChargeType_OneTime){
                            spreadQLI.month2Amt=spreadQLI.netTotal;
                        }
                        else if(spreadQLI.productType==CWS_ConstantClass.ChargeType_Recurring){
                            spreadQLI.month2Amt=spreadQLI.subTerm!=null?(spreadQLI.netTotal/spreadQLI.subTerm).setScale(2,System.RoundingMode.HALF_UP):0;
                        }
                    }
                    
                     //START - 14033072 - Changing the Active-No Assurance conditions
                    //Checking Active-No Assurance conditions
                    if(line.SBQQ__Quantity__c > 0){
                        
                        if(line.SBQQ__Product__r.CWS_Category__c == 'Automate'){
                            if((line.CWS_License_Type__c == 'Perpetual' || line.CWS_License_Type__c == 'Hybrid SaaS - Automate Perpetual') 
                                && line.CWS_Sub_category__c != 'Maintenance'){
                                automateActiveProds = line.SBQQ__Product__r.Name;
                                automateActiveProds = automateActiveProds.replaceAll('[^a-zA-Z0-9\\s+]', '');
                                automatePerpProducts.add(automateActiveProds);
                                AutomatePerpetualLinesCount = AutomatePerpetualLinesCount + 1;
                            }
                            
                            if(line.CWS_Sub_category__c == 'Maintenance'){
                                AutomateMaintenanceLinesCount = AutomateMaintenanceLinesCount + 1;
                            }
                            
                        }
                        
                        if(line.SBQQ__Product__r.CWS_Category__c == 'Manage'){
                            if((line.CWS_License_Type__c == 'Perpetual' || line.CWS_License_Type__c == 'Hybrid SaaS - Automate Perpetual') 
                               && line.CWS_Sub_category__c != 'Maintenance'){
                                manageactiveProds = line.SBQQ__Product__r.Name;
                                manageactiveProds = manageactiveProds.replaceAll('[^a-zA-Z0-9\\s+]', '');
                                managePerpProducts.add(manageactiveProds);
                                ManagePerpetualLinesCount = ManagePerpetualLinesCount + 1;
                            }
                            
                            if(line.CWS_Sub_category__c == 'Maintenance'){
                                ManageMaintenanceLinesCount = ManageMaintenanceLinesCount + 1;
                            }
                        }
                    }
                    //END- 14033072 - Changing the Active-No Assurance conditions
                    
                    //downgradeQliWrapper.add(wrapper);
					// 14030753 - Adding Null Check 
                    if(spreadQLI.haveData == true){
						impSpreadQLIWrapper.add(spreadQLI);
					}
                    
                    //Fetch details of future pricing QLIs
                    if(line.CWS_Future_Contracted_Price__c != null){
                        isFuturePricing = true;
                        if(line.SBQQ__Product__r.Name != null){
                            if(line.SBQQ__Product__r.CWS_Category__c == CWS_ConstantClass.Product_Category_Perch || line.SBQQ__Product__r.CWS_Category__c == CWS_ConstantClass.Product_Category_Solution_Partners){
                                futurewrapper.thirdPatyProduct = line.SBQQ__Product__r.Name;
								futurewrapper.thirdPatyProduct = futurewrapper.thirdPatyProduct.replaceAll('[^a-zA-Z0-9\\s+]', '');
                                has3rdPartyProds = true;
                            }
                            else{
                                futurewrapper.name = line.SBQQ__Product__r.Name;
								futurewrapper.name = futurewrapper.name.replaceAll('[^a-zA-Z0-9\\s+]', '');
                                hasNon3rdPartyProds = true;
                            }
                        }
                        if(line.CWS_Future_Contracted_Price__c != null){
                            futurewrapper.futurePrice = line.CWS_Future_Contracted_Price__c;
                        }
                        if(line.CWS_Billing_Term__c != null){
                            futurewrapper.billingTerm = line.CWS_Billing_Term__c;
                        }
                        if(line.CWS_Future_pricing_Blocks__c != null){
                            futurewrapper.futurePriceBlocks = line.CWS_Future_pricing_Blocks__c;
                        }
                        else{
                            futurewrapper.futurePriceBlocks = 1;
                        }
                        if(line.CWS_Future_Price_End_Date__c != null){
                            futurewrapper.futurePriceEndDate = line.CWS_Future_Price_End_Date__c;
                        }
                    }
                    futurePriceWrapper.add(futurewrapper);
                }
            }
            
			//START - 14033072 - Changing the Active-No Assurance conditions
            if(AutomatePerpetualLinesCount >0 && AutomateMaintenanceLinesCount == 0){
                products = String.join(automatePerpProducts,',');
                isActiveNoAssurance = true;
            } 
            if(ManagePerpetualLinesCount >0 && ManageMaintenanceLinesCount == 0){
                products = String.join(managePerpProducts,',');
                isActiveNoAssurance = true;
            }
            //END- 14033072 - Changing the Active-No Assurance conditions
            
        } catch (Exception e) {
            CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_QuoteTermsCtrl', 'fetchData' , '', null, null , 'fetchData' , null);
        }
        return null;
    }
    public class DowngradeQLIWrapper {
        public String name {get; set;}
        public String licenseType {get; set;}
        public Decimal priorQuantity{get; set;}
        public Decimal quantity {get; set;}
        public Date startDate {get; set;}
    }
    public class FuturePricingQLI{
        public String name {get; set;}
        public Decimal futurePrice {get; set;}
        public String billingTerm {get; set;}
        public Decimal futurePriceBlocks {get; set;}
        public Date futurePriceEndDate {get; set;}
        public String thirdPatyProduct {get; set;}
    }
    public class ImplementationSpreadQLI{
		public Boolean haveData{get;set;}
        public String prodName{get;set;}
        public List<String> spreadPrices {get; set;}
        public Map<Integer, Decimal> mapMonthsToSpreadValues{get;set;}
        public Decimal unevenSpread {get;set;}
        public String swapOutProd{get;set;}
        public String swapInProd{get;set;}
        public Date qlStartDate{get;set;}
        public String quote{get;set;}
        public Decimal netTotal{get;set;}
        public Decimal subTerm{get;set;}
        public Decimal month1Amt{get;set;}
        public Decimal month2Amt{get;set;}
        public Decimal periodForRamp{get;set;}
        public String productType{get;set;}
    }
    public class DowngradeAssurance{
        public String maintenanceProd{get;set;}
        public Decimal netPrice{get;set;}
    }
    
}