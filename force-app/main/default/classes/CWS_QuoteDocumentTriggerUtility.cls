/** 
* Class Name: CWS_QuoteDocumentTriggerUtility
* @description Quote document utility class for CWS_QuoteDocumentTriggerHelper class 
* Created By: Carl Shahan
* Created On: 01/19/2021
* Modification Log
* ------------------------------------------------------------------------------------------
* Developer   Date       User Story    Description
* ------------------------------------------------------------------------------------------
* Carl Shahan 01/19/2021  #14154761    Removed the utility methods from the CWS_QuoteDocumentTriggerHelper class and created this new class
*/
public with sharing class CWS_QuoteDocumentTriggerUtility {
    // Create a utility class for the following 4 methods because one of them is used in both places.
    
    /** 
     * @description  BED-5213 : Quote Stage sync with Quote Documents
     * @return Boolean
     * @param quote */
    public static boolean quoteAgreementInEffect(SBQQ__Quote__c quote){
        if(String.isBlank( quote.SBQQ__Account__r.CWS_MSA_Agreement__c ) 
            && String.isBlank( quote.SBQQ__Account__r.CWS_NDA_Agreement__c ) 
            && String.isBlank( quote.SBQQ__Account__r.CWS_BA_Agreement__c )) {    
            return true; 
        }

        if( String.isNotBlank( quote.SBQQ__Account__r.CWS_MSA_Agreement__c ) 
            &&  (String.IsBlank(quote.SBQQ__Account__r.CWS_MSA_Agreement_Status__c)
                 || !(quote.SBQQ__Account__r.CWS_MSA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT || quote.SBQQ__Account__r.CWS_MSA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || quote.SBQQ__Account__r.CWS_MSA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED))){
            return false;
        }
        
        if( String.isNotBlank( quote.SBQQ__Account__r.CWS_NDA_Agreement__c ) 
            && (String.IsBlank(quote.SBQQ__Account__r.CWS_NDA_Agreement_Status__c) 
            || !(quote.SBQQ__Account__r.CWS_NDA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT || quote.SBQQ__Account__r.CWS_NDA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || quote.SBQQ__Account__r.CWS_NDA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED))){
            return false;
        }

        if( String.isNotBlank( quote.SBQQ__Account__r.CWS_BA_Agreement__c ) 
                && (String.IsBlank(quote.SBQQ__Account__r.CWS_BA_Agreement_Status__c) 
                || !(quote.SBQQ__Account__r.CWS_BA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_INEFFECT || quote.SBQQ__Account__r.CWS_BA_Agreement_Status__c == CWS_ConstantClass.AGREEMENT_STATUS_TERMINATED || quote.SBQQ__Account__r.CWS_BA_Agreement_Status__c == CWS_ConstantClass.ORDER_STATUS_CANCELLED))){
                return false;
        }

        return true;
    }

    /** 
     * @description  Method for determining if the Quote Document is signed yet 
     * @return Boolean
     * @param qdoc */
    public static Boolean isSignatureCompleted(SBQQ__QuoteDocument__c qdoc){
        if (qdoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_COMPLETED || 
            qdoc.SBQQ__SignatureStatus__c == CWS_ConstantClass.QDOC_SIG_SIGNED ||
            qdoc.CWS_Offline_Signature_Status__c == CWS_ConstantClass.QDOC_SIG_SIGNED)  { return true; }
        return false;
    }
    
    /** 
     * @description BED-5213 : Method for updating and multiple quotes the primary quote
     * //return void Unexpected return warning Apex PMD Gearset 
     * @param quoteIds */
    @future(callout=true)
    public static void asyncUpdatePrimaryCheckbox(Set<Id> quoteIds){
        List<SBQQ__Quote__c> quotes=new List<SBQQ__Quote__c>();
        for(SBQQ__Quote__c quote: [Select id, SBQQ__Primary__c from SBQQ__Quote__c 
                                    where id in :quoteIds and SBQQ__Primary__c = false]){
            quote.SBQQ__Primary__c=true;
            quotes.add(quote);
        }
        if(quotes!=null && !quotes.isEmpty()){ 
            
            if (Schema.sObjectType.SBQQ__Quote__c.isUpdateable()) {
                update quotes;
            }
        }
    }

    /**
    * Method name  : isProvisioningPending
    * @description BED-8869 : Co-terming Sales Contract - Amendment & Renewal,BED-3222
    * @param quote
    * @return Boolean
    * Developer    : Khayam
    */
    public static Boolean isProvisioningPending(SBQQ__Quote__c quote){
        if (quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT) {
            for (SBQQ__QuoteLine__c line : quote.SBQQ__LineItems__r) {
                if (!line.CWS_ServicesProvisioned__c &&
                ((line.CWS_Provisioning_Eligibility__c == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL && (line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL || line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE || line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT)) ||
                (line.CWS_Additional_Restrictions__c != NULL && line.CWS_Additional_Restrictions__c.contains(CWS_ConstantClass.Product_AdditionRestriction_Downg) && (line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL || line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE || line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT)) ||                
                (line.CWS_Additional_Restrictions__c != NULL && line.CWS_Additional_Restrictions__c.contains(CWS_ConstantClass.Product_AdditionRestriction_Conversion) && quote.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && (line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON || line.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN)))) {

                    return true;
                }
            }
        }
        return false;
    }
}