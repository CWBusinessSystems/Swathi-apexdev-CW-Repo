/*
Class Name: CWS_ApprovalEmailComponentController
*Description: Controller Class for Email Template Component
*Created By: Aakash Sharma
*Created On: 5/6/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aakash                 5/6/2020       BED-4988              Email Template for the Approval Request

*/
public without sharing class CWS_ApprovalEmailComponentController {
    public string quoteId {get;set;}
    public String currencyValue{get;set;}
    public string opptyId{get;set;}
    Public Decimal serviceNetPrice {get;set;}
    Public Decimal nonServiceNetPrice {get;set;}
    Public Decimal serviceRegularPrice {get;set;}
    Public Decimal nonServiceRegularPrice {get;set;}
    Public Decimal serviceRegularDiscountPercentage {get;set;}
    Public Decimal nonServiceRegularDiscountPercentage {get;set;}
    Public Decimal serviceRegularDiscountAmount {get;set;}
    Public Decimal nonServiceRegularDiscountAmount {get;set;}
    Public string currencyCode {get;set;}
    public List<WrapperMargin> listWrap;
    Set<Id> qlID = new Set<ID>();
    //List of Approvals for the Approval History section
    public List<sbaa__Approval__c> approvalList{
        get{
            if(quoteId != null){
                approvalList = [SELECT 
                                sbaa__AssignedTo__r.Name,sbaa__ApprovalChain__c,sbaa__ApprovalChain__r.Name,sbaa__Rule__r.Name,sbaa__Status__c, sbaa__Approver__r.Name, sbaa__ApprovedBy__r.Name, sbaa__CommentsLong__c,sbaa__ApprovalStep__c
                                FROM sbaa__Approval__c
                                WHERE 
                                CWS_Quote__c = :quoteId
                                ORDER BY sbaa__ApprovalStep__c ASC];
            }
            return approvalList;
        }set;
    }
    //List of Quote lines for the PDF Document
    public List<SBQQ__QuoteLine__c> qliList{
        get{
            if(quoteId!=null){
                qliList = [SELECT id,SBQQ__NetTotal__c,CWS_RegularPrice__c,CWS_NetTotal__c,CWS_NetPrice__c,SBQQ__ListPrice__c,SBQQ__Product__c,SBQQ__ProductCode__c, SBQQ__Product__r.CWS_Source__c,
                           CWS_Quote_Type__c,SBQQ__StartDate__c,SBQQ__ProductName__c,CWS_Future_pricing_Blocks__c,CWS_License_Type__c,CWS_Future_Contracted_Price__c,SBQQ__SubscriptionTerm__c,
                           SBQQ__Quantity__c,CWS_Transaction_Type__c,CWS_Period_for_Ramp_Spread_Deferment__c,CWS_Payment_Schedule_Driver__c,CWS_Billing_Term__c,SBQQ__Discount__c, CWS_Category__c,
                           SBQQ__Product__r.CWS_Category__c,CWS_ACVLine__c, SBQQ__Product__r.CWS_Sub_Category__c, CWS_Custom_Discount_Field__c, CWS_Price_Per_Billing_Period__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId];
            }
            return qliList;   
        }set;
    }
    //List of Renewal attention picklist
    public List<string> lstString{
        get{
            List<String> strList = new List<String>();
            String str;
            if(opptyId!=null){
                opportunity opptyObj=[select id,CWS_Renewal_Attention_Needed__c from opportunity where id =:opptyId];
                if(opptyObj.CWS_Renewal_Attention_Needed__c!=null)
                    strList=opptyObj.CWS_Renewal_Attention_Needed__c.split(';');
            }
            return strList;
        }set;
    }
    //List of Margin and Discount Based on the Category of the Product
    public List<WrapperMargin> getlistWrap(){
        list<WrapperMargin> lstMarginWrap = new list<WrapperMargin>();
        list<SBQQ__QuoteLine__c> QLIlist=[SELECT id, name, CWS_ACVLine__c, SBQQ__NetTotal__c, CWS_Margin__c,CWS_NetPrice__c,CWS_RegularPrice__c,SBQQ__CustomerTotal__c,SBQQ__Product__c, SBQQ__Product__r.CWS_Source__c,
                                          CWS_Future_pricing_Blocks__c,SBQQ__StartDate__c,CWS_Quote_Type__c,CWS_Category__c,CWS_License_Type__c,CWS_Future_Contracted_Price__c,CWS_Billing_Term__c,SBQQ__RegularTotal__c,
                                          SBQQ__Product__r.CWS_Sub_Category__c,CWS_Transaction_Type__c,SBQQ__Quote__r.CurrencyIsoCode
                                          FROM SBQQ__QuoteLine__c 
                                          WHERE SBQQ__Quote__c =:quoteId 
                                          ORDER BY CWS_Category__c ASC];
        
        Map<String,WrapperMargin> MapCatMargin=new Map<String,WrapperMargin>();
        list<WrapperMargin> listWrapThird=new list<WrapperMargin>();
        String strTRP=CWS_ConstantClass.strThirdParty1;
        serviceNetPrice = 0;
        nonServiceNetPrice = 0;
        serviceRegularPrice = 0;
        nonServiceRegularPrice = 0;
        serviceRegularDiscountPercentage = 0;
        nonServiceRegularDiscountPercentage =0;
        serviceRegularDiscountAmount = 0;
        nonServiceRegularDiscountAmount =0;
        
        If( QLIlist!=null && !QLIlist.isEmpty()){
            for(SBQQ__QuoteLine__c QLI:QLIlist){
                if(QLI.SBQQ__Product__r.CWS_Sub_Category__c == strTRP){
                    WrapperMargin WrapperX=new WrapperMargin();
                    if(QLI.CWS_Margin__c!=null && QLI.CWS_Category__c!=null && QLI.SBQQ__RegularTotal__c!=null && QLI.SBQQ__CustomerTotal__c!=null  && QLI.SBQQ__Product__c !=null && QLI.SBQQ__Product__r.CWS_Sub_Category__c!=null && QLI.SBQQ__Quote__r.CurrencyIsoCode!=null){
                        {
                            //WrapperX = new WrapperMargin(QLI.CWS_Category__c,QLI.CWS_Margin__c,QLI.SBQQ__RegularTotal__c,QLI.SBQQ__CustomerTotal__c,0,QLI.SBQQ__Product__r.CWS_Sub_Category__c,QLI.SBQQ__Quote__r.CurrencyIsoCode);   
                            WrapperX = new WrapperMargin(QLI.CWS_Category__c,QLI.CWS_ACVLine__c,QLI.SBQQ__RegularTotal__c,QLI.SBQQ__CustomerTotal__c,0,QLI.SBQQ__Product__r.CWS_Sub_Category__c,QLI.SBQQ__Quote__r.CurrencyIsoCode);   
                        }
                        if(WrapperX.Margin!=null)
                        {
                            listWrapThird.add(WrapperX);
                        }
                        system.debug(listWrapThird);
                        system.debug(WrapperX);
                    }
                }
                else if(!MapCatMargin.ContainsKey(QLI.CWS_Category__c) && QLI.SBQQ__Product__r.CWS_Sub_Category__c!=strTRP){
                    WrapperMargin WrapperX1=new WrapperMargin();
                    if(QLI.CWS_Margin__c!=null 
                       && QLI.CWS_Category__c!=null
                       && QLI.SBQQ__RegularTotal__c!=null 
                       && QLI.SBQQ__CustomerTotal__c!=null 
                       && QLI.SBQQ__Product__c !=null 
                       && QLI.SBQQ__Product__r.CWS_Sub_Category__c!=null
                       && QLI.SBQQ__Quote__r.CurrencyIsoCode!=null){
                           //WrapperX1 = new WrapperMargin(QLI.CWS_Category__c,QLI.CWS_Margin__c,QLI.SBQQ__RegularTotal__c,QLI.SBQQ__CustomerTotal__c,0,QLI.SBQQ__Product__r.CWS_Sub_Category__c,QLI.SBQQ__Quote__r.CurrencyIsoCode);
                           WrapperX1 = new WrapperMargin(QLI.CWS_Category__c,QLI.CWS_ACVLine__c,QLI.SBQQ__RegularTotal__c,QLI.SBQQ__CustomerTotal__c,0,QLI.SBQQ__Product__r.CWS_Sub_Category__c,QLI.SBQQ__Quote__r.CurrencyIsoCode);
                       }
                    if(WrapperX1.Margin !=null){
                        MapCatMargin.put(QLI.CWS_Category__c,WrapperX1);
                    }
                    system.debug(MapCatMargin);
                    system.debug(WrapperX1);
                }
                else if(MapCatMargin.ContainsKey(QLI.CWS_Category__c) && QLI.SBQQ__Product__r.CWS_Sub_Category__c!=strTRP)
                {
                    WrapperMargin WrapperX2=MAPCatMargin.get(QLI.CWS_Category__c);
                    decimal MarginNEW;
                    if(QLI.CWS_Margin__c!=null){
                        //MarginNEW=WrapperX2.Margin + QLI.CWS_Margin__c;
                        MarginNEW=WrapperX2.Margin + QLI.CWS_ACVLine__c;
                    }
                    String SubCatNew=QLI.SBQQ__Product__r.CWS_Sub_Category__c;
                    decimal RegularPriceNew=WrapperX2.RegularPriceTotal + QLI.SBQQ__RegularTotal__c;
                    decimal CustomerPriceNew=WrapperX2.CustPriceTotal + QLI.SBQQ__CustomerTotal__c;
                    MapCatMargin.remove(QLI.CWS_Category__c);
                    //WrapperMargin Wrappernew=new WrapperMargin(QLI.CWS_Category__c,MarginNEW,RegularPriceNew,CustomerPriceNew,0,SubCatNew,QLI.SBQQ__Quote__r.CurrencyIsoCode);
                    WrapperMargin Wrappernew=new WrapperMargin(QLI.CWS_Category__c,MarginNEW,RegularPriceNew,CustomerPriceNew,0,SubCatNew,QLI.SBQQ__Quote__r.CurrencyIsoCode);
                    if(Wrappernew.Margin !=null){
                        MapCatMargin.put(QLI.CWS_Category__c,Wrappernew);
                    }
                }
                
                if(QLI.SBQQ__Product__r.CWS_Sub_Category__c == 'Services' && QLI.SBQQ__Product__r.CWS_Source__c == 'CMS'  ){
                    serviceRegularPrice = serviceRegularPrice+QLI.SBQQ__RegularTotal__c;
                    serviceNetPrice = serviceNetPrice+QLI.SBQQ__NetTotal__c;
                    currencyCode = QLI.SBQQ__Quote__r.CurrencyIsoCode; 
                    qlID.add(QLI.ID);
                }
                if(QLI.SBQQ__Product__r.CWS_Sub_Category__c != 'Services' && QLI.SBQQ__Product__r.CWS_Source__c == 'CMS'  ){
                    NonServiceRegularPrice = NonServiceRegularPrice+QLI.SBQQ__RegularTotal__c;
                    NonServiceNetPrice = NonServiceNetPrice+QLI.SBQQ__NetTotal__c;
                    currencyCode = QLI.SBQQ__Quote__r.CurrencyIsoCode;
                    qlID.add(QLI.ID);
                }
                
            }
            if(serviceRegularPrice != serviceNetPrice && serviceRegularPrice != 0 && serviceNetPrice != 0){
                serviceRegularDiscountPercentage = (((serviceRegularPrice - serviceNetPrice )/serviceRegularPrice) * 100);
            }
            if(nonServiceRegularPrice != nonServiceNetPrice && nonServiceRegularPrice != 0 && nonServiceNetPrice != 0){
                nonServiceRegularDiscountPercentage = (((nonServiceRegularPrice - nonServiceNetPrice )/nonServiceRegularPrice)*100);
            }
            if(serviceRegularPrice != serviceNetPrice){
                serviceRegularDiscountAmount =  serviceNetPrice -serviceRegularPrice;
            }
            if(nonServiceRegularPrice !=  nonServiceNetPrice){
                nonServiceRegularDiscountAmount =   nonServiceNetPrice -nonServiceRegularPrice;
            } 
            
            
            
            
        }
        
        system.debug(MapCatMargin);
        //WrapperMargin mergedWrapper = WrapperMargin.mergeWrapper(listWrapThird);
        if(MapCatMargin!=null){
            for(WrapperMargin wrap : MapCatMargin.values()){
                WrapperMargin wrap1 = new WrapperMargin();
                wrap1.category=wrap.category;
                wrap1.SubCategory=wrap.SubCategory;
                wrap1.Margin=wrap.Margin;
                wrap1.RegularPriceTotal=wrap.RegularPriceTotal;
                wrap1.CustPriceTotal=wrap.CustPriceTotal;
                wrap1.Currency1=wrap.Currency1;
                system.debug(wrap.CustPriceTotal+wrap.RegularPriceTotal);
                if(wrap.CustPriceTotal != null && wrap.RegularPriceTotal != null && wrap.RegularPriceTotal != wrap.CustPriceTotal && wrap.RegularPriceTotal != 0 ){
                    wrap1.Discount=(((wrap.RegularPriceTotal-wrap.CustPriceTotal)/wrap.RegularPriceTotal)*100).setscale(2);
                }
                lstMarginWrap.add(wrap1);
            }
        }
        WrapperMargin wrapthird = new WrapperMargin();
        String strTP=CWS_ConstantClass.strThirdParty;
        system.debug(listWrapThird);
        for(WrapperMargin wrap:listWrapThird){
            wrapthird.Margin=wrapthird.Margin + wrap.Margin;
            wrapthird.RegularPriceTotal=wrapthird.RegularPriceTotal + wrap.RegularPriceTotal;
            wrapthird.CustPriceTotal=wrapthird.CustPriceTotal + wrap.CustPriceTotal;
            wrapthird.Currency1= wrap.Currency1;
        }
        wrapthird.Category=strTP;
        if(wrapthird.CustPriceTotal != null && wrapthird.RegularPriceTotal != null && wrapthird.RegularPriceTotal!= wrapthird.CustPriceTotal && wrapthird.RegularPriceTotal != 0){
            wrapthird.Discount=wrapthird.RegularPriceTotal !=0 ? ((wrapthird.RegularPriceTotal-wrapthird.CustPriceTotal)/wrapthird.RegularPriceTotal)*100 : 0;
            wrapthird.Discount=wrapthird.Discount.setscale(2);
        }
        System.debug(wrapthird);
        if(wrapthird!=null && wrapthird.Margin!=null && wrapthird.Discount!=null)
        { 
            lstMarginWrap.add(wrapthird);
        }
        
        
        system.debug(lstMarginWrap);
        return lstMarginWrap;        
        
    }
    
    //Wrapper Class for the Margin Details
    
    public class WrapperMargin {
        
        public String  Category {get; set;} 
        public String  SubCategory{get;set;}
        public decimal Margin {get; set;} 
        public decimal RegularPriceTotal {get; set;} 
        public decimal CustPriceTotal {get; set;}
        public decimal Discount {get; set;} 
        public String  Currency1 {get;set;}
        
        
        public WrapperMargin(String c, decimal m,decimal r,decimal n,decimal d,String sc,String curr) {
            this.Category = c; 
            this.SubCategory=sc;
            this.Margin = m;
            this.RegularPriceTotal=r;
            this.CustPriceTotal=n;
            this.Discount=d;
            this.Currency1=curr;
            
        }
        public WrapperMargin()
        {
            this.Category = ''; 
            this.SubCategory='';
            this.Margin = 0.0;
            this.RegularPriceTotal=0.0;
            this.CustPriceTotal=0.0;
            this.Discount=0.0;
            this.Currency1='';
            
        }
    }
    
    
    
}