public class CWS_QuoteModel {
    public SBQQ__Quote__c record;
    public CWS_QuoteLineModel[] lineItems;
    public CWS_QuoteLineGroupModel[] lineItemGroups;
    public Integer nextKey;
    public Boolean applyAdditionalDiscountLast;
    public Boolean applyPartnerDiscountFirst;
    public Boolean channelDiscountsOffList;
    public Decimal customerTotal;
    public Decimal netTotal;
    public Decimal netNonSegmentTotal;
}