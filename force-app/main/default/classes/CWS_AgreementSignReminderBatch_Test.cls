/*Class Name: CWS_AgreementSignReminderBatch_Test
*Description: Test class for CWS_AgreementSignReminderBatch 
*Created By: Akhila
*Created On: 20/05/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Akhila                 20/5/2020       BED-2970           Test Class for CWS_AgreementSignReminderBatch
*Indra Ganesan         19/8/2020                           Test Class Updation
*/

@isTest(SeeAllData=false)
public class CWS_AgreementSignReminderBatch_Test {
   
   @testSetup 
   static void setupTestData(){
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Agreement','DocusignEnvelope'}); 

        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'EUR'};
        List<Account> acctLst = CWS_UTLDataFactory.createBulkAccounts('Test Account',accountFieldValues , 1, true);
       
        Map<String, Object> agreementFieldValues=new Map<String, Object>{
            'Apttus__Account__c' => acctLst[0].Id};
        List<Apttus__APTS_Agreement__c> agreementLst = CWS_UTLDataFactory.createBulkAgreements(agreementFieldValues, 1,true);
        
        Map<String, Object> envelopeFieldValues=new Map<String, Object>{
                'Apttus_DocuApi__Status__c' => 'Pending', 'Apttus_CMDSign__Agreement__c' =>  agreementLst[0].id     
        };
        List<Apttus_DocuApi__DocuSignEnvelope__c> DSEnvelopeLst = CWS_UTLDataFactory.createBulkDSEnvelope(envelopeFieldValues, 50,true);
    }
	
    testMethod static void testAgreementSign(){
        
        Account acctRec = [Select Id,CWS_BA_Agreement__c,CWS_BA_Agreement_Status__c from Account];                
       
        List<Apttus__APTS_Agreement__c> agreementLst = [Select Id,CWS_Envelope_SentDate__c,Apttus__Account__c,CWS_EnvelopeStatus__c,Apttus__Account__r.Name,CWS_No_Of_Days_Passed_From_Envelope_Sent__c, Owner.Email, OwnerId,Name,Apttus__Other_Party_Signed_By__c,Apttus__Other_Party_Signed_By__r.Name, Owner.Name from Apttus__APTS_Agreement__c];
        agreementLst[0].CWS_EnvelopeStatus__c ='Sent';
        agreementLst[0].CWS_Envelope_SentDate__c = Date.today()-7;
        update agreementLst[0];        
        
        List<Apttus_DocuApi__DocuSignEnvelope__c> LstEnvelopes = [select id, Apttus_CMDSign__Agreement__c from Apttus_DocuApi__DocuSignEnvelope__c];
        Datetime yesterday = Datetime.now().addDays(-1);
        for(Apttus_DocuApi__DocuSignEnvelope__c d:LstEnvelopes){
             Test.setCreatedDate(d.Id, yesterday);
             d.Apttus_DocuApi__Status__c = 'Sent';
        }        
        Test.startTest();
        if(LstEnvelopes !=null)
           update LstEnvelopes;               
        CWS_AgreementSignReminderBatch batch = new CWS_AgreementSignReminderBatch();
        DataBase.executeBatch(batch,50);
        List<Apttus_DocuApi__DocuSignEnvelope__c> lstUpdatedDocs = [SELECT Id from Apttus_DocuApi__DocuSignEnvelope__c where Apttus_DocuApi__Status__c =:'Sent'];
        system.assertEquals(50, lstUpdatedDocs.size());
        Test.stopTest();
    }
}