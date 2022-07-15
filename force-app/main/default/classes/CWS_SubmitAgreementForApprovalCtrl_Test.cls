/*Class Name: CWS_SubmitAgreementForApprovalCtrl_Test
*Description: Test Class for CWS_SubmitAgreementForApprovalCtrl
*Created By: Akhila Reddy
*Created On: 4/29/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                 04/29/2020        BED-2799              Agreement Approvals
*/
@isTest(SeeAllData=false)
public class CWS_SubmitAgreementForApprovalCtrl_Test {
    @testSetup static void setupTestData(){
        
        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'EUR'};
                List<Account> acctLst = CWS_UTLDataFactory.createBulkAccounts('Test Account',accountFieldValues , 1, true);
        update acctLst;
        Map<String, Object> agreementFieldValues=new Map<String, Object>{
            'Apttus__Account__c' => acctLst[0].Id};
        List<Apttus__APTS_Agreement__c> agreementLst = CWS_UTLDataFactory.createBulkAgreements(agreementFieldValues, 5,true);
    }
    testMethod static void testValidations(){
        
        Account acctRec = [Select Id from Account];
        List<Apttus__APTS_Agreement__c> agreementList = [Select Id,recordTypeId,CWS_Clause_type__c from Apttus__APTS_Agreement__c];
        System.debug('RecordType'+Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_SOW_Agreement').getRecordTypeId());
        agreementList[0].recordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_SOW_Agreement').getRecordTypeId();
        agreementList[0].Apttus__Account__c = acctRec.Id;
        agreementList[1].recordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_MSA_Agreement').getRecordTypeId();
        agreementList[1].Apttus__Account__c = acctRec.Id;
        
        CWS_SubmitAgreementForApprovalCtrl.validations(agreementList[0].Id);
        
    }
    
}