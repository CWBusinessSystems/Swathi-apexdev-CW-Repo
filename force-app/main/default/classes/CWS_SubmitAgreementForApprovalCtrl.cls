/*Class Name: CWS_SubmitAgreementForApprovalCtrl
*Description: Validations for Agreement approvals
*Created By: Akhila Reddy
*Created On: 4/27/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                 04/27/2020        BED-2799              Agreement Approvals
*/

public class CWS_SubmitAgreementForApprovalCtrl {
    
    @AuraEnabled
    public static List<String> validations(String agreementId){
        
        boolean hasError = false; 
        List<string> lstErrorMsgs = new List<String>();
        Apttus__APTS_Agreement__c agreementRec = new Apttus__APTS_Agreement__c();
        if(agreementId != null){
            agreementRec = [Select Id,RecordTypeId,CWS_Clause_type__c from Apttus__APTS_Agreement__c where Id =: agreementId];
        }
        if(agreementRec.CWS_Clause_type__c == null && agreementRec.RecordTypeId != CWS_ConstantClass.SOW_Agreement_RT){
            hasError = true;
            lstErrorMsgs.add(System.Label.CWS_Agreement_Approval_Validation); 
        }
        return lstErrorMsgs; 
        
    }
}