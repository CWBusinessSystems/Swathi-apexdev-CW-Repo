public with sharing class CWS_QuotePreviewController{
    private Id quoteId;
     public SBAA__Approval__c[] approvals {get;set;}
    public CWS_QuotePreviewController(ApexPages.StandardController stdController){
        quoteId = stdController.getId();
    }
    public PageReference onPreview(){
        if(quoteId != null){

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
                                   if(qLine.CWS_Future_Priced_Line__c!=null && (qLine.CWS_Future_Priced_Line__r.CWS_Future_Contracted_Price__c.setScale(2,System.RoundingMode.HALF_UP)==qLine.CWS_CustomerPrice_per_billing_period__c.setScale(2,System.RoundingMode.HALF_UP))
                                    && (qLine.CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c!=null?(qLine.SBQQ__Quantity__c>=qLine.CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c):true)){
                                        futurepriceApproval = true;
                                    }
                                    else if(qLine.CWS_Future_Contracted_Price__c!=null && (qLine.CWS_Future_Contracted_Price__c.setScale(2,System.RoundingMode.HALF_UP)==qLine.CWS_CustomerPrice_per_billing_period__c.setScale(2,System.RoundingMode.HALF_UP))
                                    && (qLine.CWS_Future_pricing_Blocks__c!=null?(qLine.SBQQ__Quantity__c - (qLine.SBQQ__UpgradedSubscription__c!=null?qLine.SBQQ__PriorQuantity__c:0)>=qLine.CWS_Future_pricing_Blocks__c):true)){
                                        futurepriceApproval = true;
                                    } 
                                }
                                else{
                                    if(qLine.CWS_Future_Priced_Line__c!=null && (qLine.CWS_Future_Priced_Line__r.CWS_Future_Contracted_Price__c.setScale(2,System.RoundingMode.HALF_UP)==qLine.CWS_Quote_Doc_Price__c.setScale(2,System.RoundingMode.HALF_UP))
                                    && (qLine.CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c!=null?(qLine.SBQQ__Quantity__c>=qLine.CWS_Future_Priced_Line__r.CWS_Future_pricing_Blocks__c):true)){
                                        futurepriceApproval = true;
                                    }
                                    else if(qLine.CWS_Future_Contracted_Price__c!=null && (qLine.CWS_Future_Contracted_Price__c.setScale(2,System.RoundingMode.HALF_UP)==qLine.CWS_Quote_Doc_Price__c.setScale(2,System.RoundingMode.HALF_UP))
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
                    if(updQuoteLine.size()>0){
                        update updQuoteLine;
                    }

			approvals = SBAA.ApprovalAPI.preview(quoteId, SBAA__Approval__c.CWS_Quote__c);
        }
        return null;
    }
}