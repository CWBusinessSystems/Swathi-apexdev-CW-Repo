/*Class Name: CWS_QuoteTriggerHelper_Test
    *Description: Test Class for CWS_QuoteTriggerHelper

    *Created By: Akhila
    *Created On:  08/11/2020
    *Modification Log
    *------------------------------------------------------------------------------------------
    *Developer              Date            User Story              Description
    *------------------------------------------------------------------------------------------
    *Harsha                 08/11/2020     
    */
    @isTest(SeeAllData=false)
    public class CWS_DocusignEnvelopHelper_Test {
        
        @testSetup 
        static void setupTestData(){
            CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'DocusignEnvelope'}); 
            Map<String, Object> accountFieldValues=new Map<String, Object>{
                'currencyIsoCode'=>'EUR'};
                    List<Account> acctLst = CWS_UTLDataFactory.createBulkAccounts('Test Account',accountFieldValues , 1, true);
            
             Map<String, Object> contactFieldValues=new Map<String, Object>{
                'FirstName'=>'test',
                    'LastName' => 'contact',
                    'AccountId' => acctLst[0].Id,
                    'MailingCountry' => 'United States'};
                        List<Contact> contactLst = CWS_UTLDataFactory.createBulkContacts('Test','Contact',acctLst[0].Id,contactFieldValues , 2, true);
            
            Map<String, Object> userFieldValues=new Map<String, Object>{};
                        List<User> userLst = CWS_UTLDataFactory.createBulkUsers('TUser','testuser@test.com','user','System Administrator','CEO','testagr@test.com', userFieldValues,1,true);
            
            Map<String, Object> agreementFieldValues=new Map<String, Object>{
                'Apttus__Account__c' => acctLst[0].Id,
                'Apttus__Other_Party_Signed_By__c' => contactLst[0].Id,
                'CWS_Sales_Rep__c' => userLst[0].Id,
                'Apttus__Status_Category__c' => 'In Signatures'};
            List<Apttus__APTS_Agreement__c> agreementLst = CWS_UTLDataFactory.createBulkAgreements(agreementFieldValues, 5,true);
             
            Map<String, Object> envelopeFieldValues=new Map<String, Object>{
                'Apttus_DocuApi__Status__c' => 'Pending'
            };
            List<Apttus_DocuApi__DocuSignEnvelope__c> DSEnvelopeLst = CWS_UTLDataFactory.createBulkDSEnvelope(envelopeFieldValues, 5,true);
             
        }
        
        testMethod static void testAgreementStatus(){
            Account acctRec = [Select Id from Account];
            List<Contact> contactList = [Select Id from Contact where AccountId =: acctRec.Id];
            List<User> userList =[Select Id from User];
            
            List<Apttus__APTS_Agreement__c> agreementLst = [Select Id,Apttus__Other_Party_Signed_By__c,CWS_Sales_Rep__c,Apttus__Status_Category__c from Apttus__APTS_Agreement__c];
                    
            
            List<Apttus_DocuApi__DocuSignEnvelope__c> envelopeLst = [Select Id,Apttus_CMDSign__Agreement__c,Apttus_DocuApi__Status__c from Apttus_DocuApi__DocuSignEnvelope__c];
            system.debug('ENvelopeList Size'+envelopeLst.size());
            
            envelopeLst[0].Apttus_CMDSign__Agreement__c = agreementLst[0].Id;
            envelopeLst[0].Apttus_DocuApi__Status__c = 'Sent';
            envelopeLst[1].Apttus_CMDSign__Agreement__c = agreementLst[1].Id;
            envelopeLst[1].Apttus_DocuApi__Status__c = 'Completed';
            envelopeLst[2].Apttus_CMDSign__Agreement__c = agreementLst[2].Id;
            envelopeLst[2].Apttus_DocuApi__Status__c = 'Voided';
            envelopeLst[3].Apttus_CMDSign__Agreement__c = agreementLst[3].Id;
            envelopeLst[3].Apttus_DocuApi__Status__c = 'Declined';
          
            Test.StartTest();
             system.debug('ENvelopeList Size -1'+envelopeLst.size());
            if(envelopeLst!=null)
                update envelopeLst;  
            
            system.assertEquals(true, envelopeLst.size()>0);
            Test.StopTest();
        }
		
		testMethod static void testMiscMethods(){
            CWS_DocusignEnvelopHandler handler = new CWS_DocusignEnvelopHandler();
            Map<id, SObject> oldItems = new Map<id, SObject>();
            Test.startTest();
            handler.BeforeDelete(oldItems);
            handler.AfterDelete(oldItems);
            handler.AfterUndelete(oldItems);
            Test.stopTest();
        }
    }