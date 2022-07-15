/* Component Name   : CWS_ManageDealConversionController 
 * Description      : This visualforce component contains UI elements required for apttus approval notification email.
 * Created By       : Indra Ganesan
 * Created On       : 07-06-2020

 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID      Description 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Indra Ganesan          07-06-2020                                  Initial version
 */

public class CWS_ManageDealConversionController {

   public String quotesId { get;set; }
   public String qName { get;set; }
   public String setQuotesId { 
     get 
     {
        return qt!=null? qt.id : null;
     } set;
   }
    
    private final SBQQ__Quote__c qt{
        get{
            if(quotesId!=null){
                qt = [Select id,name from SBQQ__Quote__c where Id=: quotesId limit 1];
                return qt;
            } 
            return null;       
        }
        set;
    }

    public EmailDataWrapper wrap{
    get {
            wrap = new EmailDataWrapper(); 
            List<String> conversionType = new List<String>();
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SAAS_TO_SUB);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SUB_TO_SAAS);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SAASPKG_TO_SUBPKG);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SUBPKG_TO_SAASPKG);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_ONPERM_SAAS);
            conversionType.add(CWS_ConstantClass.CONVERSION_TYPE_SAAS_ONPERM);
            if(setQuotesId != null){
                SBQQ__Quote__c q = [Select Id, Name, CurrencyIsoCode, CWS_Quote_Type__c, CWS_Transaction_Reason__c, CWS_Promo_Code__c, CWS_Promo_Code_Description__c,CWS_Linecount_AddOn__c, CWS_Linecount_Cancel__c, CWS_Conversion_Type__c, SBQQ__Account__r.CWS_MNG_Partner_Log_In__c, SBQQ__Account__r.Name, SBQQ__PrimaryContact__r.Name FROM SBQQ__Quote__c where Id =: setQuotesId];
                wrap.strCompanyName = q.SBQQ__Account__r.Name != null ? q.SBQQ__Account__r.Name : '';
                wrap.strDirection = q.CWS_Conversion_Type__c != null ? q.CWS_Conversion_Type__c : '';
                wrap.cancelledCount = q.CWS_Linecount_Cancel__c >0 ? q.CWS_Linecount_Cancel__c : 0;
                wrap.addOnCount = q.CWS_Linecount_AddOn__c > 0 ? q.CWS_Linecount_AddOn__c : 0;
                if(q.SBQQ__Account__r.CWS_MNG_Partner_Log_In__c !=null)
                    wrap.strCompanyId = q.SBQQ__Account__r.CWS_MNG_Partner_Log_In__c;
                if(q.SBQQ__PrimaryContact__r.Name != null)
                    wrap.strCompanyContact = q.SBQQ__PrimaryContact__r.Name;
                if(q.CWS_Promo_Code__c != null && q.CWS_Promo_Code_Description__c.length() >0)
                    wrap.strPromoDesc = q.CWS_Promo_Code_Description__c;    
            
                List<SBQQ__QuoteLine__c> lstQuoteLns = [SELECT SBQQ__Product__r.Name,SBQQ__NetTotal__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =:quotesId AND 
                                                               SBQQ__Product__r.CWS_Category__c =: CWS_ConstantClass.PRODUCT_CATEGORY_MANAGE AND
                                                               SBQQ__Product__r.CWS_SKU_Type__c =: CWS_ConstantClass.PRODUCT_SKU_TYPE_SERVICES AND
                                                               CWS_Transaction_Type__c =: CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON];
            
                if(lstQuoteLns.size()>0){
                    for(SBQQ__QuoteLine__c ql:lstQuoteLns){
                        if(ql.SBQQ__Product__r.Name != null)
                           wrap.productNames.add(ql.SBQQ__Product__r.Name);
                        if(ql.SBQQ__NetTotal__c > 0){
                            wrap.totalFee+= ql.SBQQ__NetTotal__c;
                        }
                    } 
                }               
        }
        return wrap;           
    }   
    set; 
  }
  public with sharing class EmailDataWrapper{ 
    public String strCompanyName{get;set;}
    public String strDirection{get;set;}
    public String strCompanyId{get;set;}
    public String strCompanyContact{get;set;}
    public String strPromoDesc{get;set;}
    public Decimal cancelledCount{get;set;}
    public Decimal addOnCount{get;set;}
    public Decimal totalFee{get;set;} 
    public List<String> productNames{get;set;}   
    public EmailDataWrapper(){
      strCompanyName = '';
      strDirection = '';
      strCompanyId ='';
      strCompanyContact = '';
      strPromoDesc = '';
      cancelledCount = 0.0;
      addOnCount = 0.0;
      totalFee=0.0;
      productNames = new List<String>();        
    }
  }
}