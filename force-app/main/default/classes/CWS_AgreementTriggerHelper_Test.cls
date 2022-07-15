/*Class Name: CWS_AgreementTriggerHelper_Test
*Description: Test Class for CWS_AgreementTriggerHelper
*Created By: Akhila
*Created On: 30/04/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                 30/04/2020        BED-3087            Populate Agreement fields on Account 
*/

@isTest(SeeAllData=false)
public class CWS_AgreementTriggerHelper_Test {
    
    @testSetup static void setupTestData(){
        
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
                //'Apttus__Status_Category__c' => 'Request',
               // 'Apttus__Status__c' => 'Request',
                'Apttus__Workflow_Trigger_Viewed_Final__c' => false};
                List<Apttus__APTS_Agreement__c> agreementLst = CWS_UTLDataFactory.createBulkAgreements(agreementFieldValues, 10,true);
        agreementLst[0].recordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_MSA_Agreement').getRecordTypeId();
        agreementLst[1].recordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_NDA_Agreement').getRecordTypeId();
        agreementLst[2].recordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_BA_Agreement').getRecordTypeId();
        agreementLst[3].recordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_NDA_Agreement').getRecordTypeId();
        agreementLst[4].recordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByDeveloperName().get('CWS_BA_Agreement').getRecordTypeId();
        if(agreementLst != null && !agreementLst.isEmpty()){
            update agreementLst;
        }
    }
    testMethod static void testBAAagreement(){
        
        Account acctRec = [Select Id,CWS_BA_Agreement__c,CWS_BA_Agreement_Status__c from Account];
        List<Contact> contactList = [Select Id from Contact where AccountId =: acctRec.Id];
        List<User> userList =[Select Id from User];
        
        List<Apttus__APTS_Agreement__c> agreementLst = [Select Id,RecordTypeId,RecordType.DeveloperName,Apttus__Account__c,Apttus__Contract_Number__c,Apttus__Status_Category__c from Apttus__APTS_Agreement__c where RecordTypeId =: CWS_ConstantClass.BAA_Agreement_RT ];
        agreementLst[0].Apttus__Status_Category__c = 'Request';
        agreementLst[0].Apttus__Status__c = 'Request';
        agreementLst[0].CWS_Contact_for_Breach__c = contactList[0].Id;
        if(agreementLst != null && !agreementLst.isEmpty()){
            update agreementLst;
        }
        Map<id,Apttus__APTS_Agreement__c> oldRecs = new map<id,Apttus__APTS_Agreement__c>();
        oldRecs.put(agreementLst[0].Id,agreementLst[1]);
        
        agreementLst[1].Apttus__Other_Party_Signed_By__c = null;
        agreementLst[1].CWS_Secondary_Recipient__c = null;
        agreementLst[0].Apttus__Account__c = acctRec.Id;
        agreementLst[0].Apttus__Other_Party_Signed_By__c = contactList[0].Id;
        agreementLst[0].CWS_Secondary_Recipient__c = contactList[1].Id;
        agreementLst[0].CWS_Sales_Rep__c = userList[0].Id;
        agreementLst[0].Apttus__Status_Category__c = 'In Signatures';
        agreementLst[0].Apttus__Status__c = 'Ready for Signatures';
        if(agreementLst != null && !agreementLst.isEmpty()){
            update agreementLst; 
        }
        Test.StartTest();
        CWS_AgreementTriggerHandler handler = new CWS_AgreementTriggerHandler();
        map<id,Apttus__APTS_Agreement__c> newRecs = new map<id,Apttus__APTS_Agreement__c>();
        newRecs.put(agreementLst[0].Id,agreementLst[0]);
        handler.BeforeUpdate(newRecs,oldRecs);
        handler.AfterInsert(newRecs);
        handler.AfterUpdate(newRecs,oldRecs);
        Test.StopTest();
    }
    testMethod static void testMSAagreement(){
        
        Account acctRec = [Select Id,CWS_MSA_Agreement__c,CWS_MSA_Agreement_Status__c from Account];
        
        List<Apttus__APTS_Agreement__c> agreementLst = [Select Id,RecordTypeId,RecordType.DeveloperName,Apttus__Account__c,Apttus__Contract_Number__c,Apttus__Status_Category__c from Apttus__APTS_Agreement__c where RecordTypeId =: CWS_ConstantClass.MSA_Agreement_RT];
        
        Test.StartTest();
        CWS_AgreementTriggerHandler handler = new CWS_AgreementTriggerHandler();
        map<id,Apttus__APTS_Agreement__c> newRecs = new map<id,Apttus__APTS_Agreement__c>();
        newRecs.put(agreementLst[0].Id,agreementLst[0]);
        handler.AfterInsert(newRecs);
        Test.StopTest();
    }
    testMethod static void testNDAagreement(){
        
        Account acctRec = [Select Id,CWS_NDA_Agreement__c,CWS_NDA_Agreement_Status__c from Account];
        List<Contact> contactList = [Select Id from Contact where AccountId =: acctRec.Id];
        List<User> userList =[Select Id from User];
        
        List<Apttus__APTS_Agreement__c> agreementLst = [Select Id,RecordTypeId,RecordType.DeveloperName,Apttus__Account__c,Apttus__Contract_Number__c,Apttus__Status_Category__c from Apttus__APTS_Agreement__c where RecordTypeId =: CWS_ConstantClass.NDA_Agreement_RT];
        agreementLst[0].Apttus__Account__c = acctRec.Id;
        agreementLst[0].Apttus__Status_Category__c = 'In Authoring';
        agreementLst[0].Apttus__Status__c = 'In Authoring';
        if(agreementLst != null && !agreementLst.isEmpty()){
            update agreementLst;
        }
        Map<id,Apttus__APTS_Agreement__c> oldRecs = new map<id,Apttus__APTS_Agreement__c>();
        oldRecs.put(agreementLst[0].Id,agreementLst[1]);
        
        agreementLst[0].Apttus__Other_Party_Signed_By__c = contactList[0].Id;
        agreementLst[0].CWS_Sales_Rep__c = userList[0].Id;
        agreementLst[0].Apttus__Status_Category__c = 'In Signatures';
        agreementLst[0].Apttus__Status__c = 'Ready for Signatures';
        if(agreementLst != null && !agreementLst.isEmpty()){
            update agreementLst;
        }
        Test.StartTest();
        CWS_AgreementTriggerHandler handler = new CWS_AgreementTriggerHandler();
        map<id,Apttus__APTS_Agreement__c> newRecs = new map<id,Apttus__APTS_Agreement__c>();
        newRecs.put(agreementLst[0].Id,agreementLst[0]);
        handler.AfterInsert(newRecs);
        handler.AfterUpdate(newRecs,oldRecs);
        Test.StopTest();
    }
    testMethod static void testMethod2(){
        
        Account acctRec = [Select Id,CWS_NDA_Agreement__c,CWS_NDA_Agreement_Status__c,CWS_MSA_Agreement__c,CWS_MSA_Agreement_Status__c,CWS_BA_Agreement__c,CWS_BA_Agreement_Status__c from Account];
        List<Contact> contactList = [Select Id from Contact where AccountId =: acctRec.Id];
        List<User> userList =[Select Id from User];

        List<Apttus__APTS_Agreement__c> agreementList = [Select Id,Apttus__Workflow_Trigger_Viewed_Final__c,RecordTypeId,Apttus__Account__c,Apttus__Status__c,Apttus__Contract_Number__c,Apttus__Status_Category__c from Apttus__APTS_Agreement__c];
        agreementList[0].Apttus__Account__c = acctRec.Id;
        agreementList[0].Apttus__Workflow_Trigger_Viewed_Final__c = true;
        agreementList[0].Apttus__Status_Category__c = 'In Authoring';
        agreementList[0].Apttus__Status__c = 'In Authoring';
        agreementList[1].Apttus__Status__c = 'In Amendment';
        agreementList[1].Apttus__Other_Party_Signed_Date__c =System.today();
        if(agreementList != null && !agreementList.isEmpty()){
            update agreementList;
        }
        Map<id,Apttus__APTS_Agreement__c> oldRecs = new map<id,Apttus__APTS_Agreement__c>();
        oldRecs.put(agreementList[0].Id,agreementList[1]);
        
        agreementList[0].Apttus__Other_Party_Signed_By__c = contactList[0].Id;
        agreementList[0].CWS_Sales_Rep__c = userList[0].Id;
        agreementList[0].Apttus__Status_Category__c = 'In Signatures';
        agreementList[0].Apttus__Status__c = 'Ready for Signatures';
        if(agreementList != null && !agreementList.isEmpty()){
            update agreementList;
        }
        map<id,Apttus__APTS_Agreement__c> newRecs = new map<id,Apttus__APTS_Agreement__c>();
        newRecs.put(agreementList[0].Id,agreementList[0]);
        
        Test.StartTest();
        CWS_AgreementTriggerHandler handler = new CWS_AgreementTriggerHandler();
        handler.BeforeUpdate(newRecs,oldRecs);
        handler.AfterUpdate(newRecs,oldRecs);
        handler.BeforeInsert(agreementList);
        Test.StopTest();
    }
    testMethod static void testMethod3(){
        
        Account acctRec = [Select Id,CWS_NDA_Agreement__c,CWS_NDA_Agreement_Status__c,CWS_MSA_Agreement__c,CWS_MSA_Agreement_Status__c,CWS_BA_Agreement__c,CWS_BA_Agreement_Status__c from Account];
        List<Contact> contactList = [Select Id from Contact where AccountId =: acctRec.Id];

        List<Apttus__APTS_Agreement__c> agreementList = [Select Id,CWS_Cancellation_Termination_Comments__c,Apttus__Workflow_Trigger_Viewed_Final__c,RecordTypeId,Apttus__Account__c,Apttus__Status__c,Apttus__Contract_Number__c,Apttus__Status_Category__c from Apttus__APTS_Agreement__c];
        agreementList[0].Apttus__Account__c = acctRec.Id;
        if(agreementList != null && !agreementList.isEmpty()){
            update agreementList;
        }
        Map<id,Apttus__APTS_Agreement__c> oldRecs = new map<id,Apttus__APTS_Agreement__c>();
        oldRecs.put(agreementList[0].Id,agreementList[1]);
        
        agreementList[0].Apttus__Other_Party_Signed_By__c = contactList[0].Id;
        agreementList[0].CWS_Cancellation_Termination_Comments__c = 'Test';
        agreementList[0].Apttus__Status_Category__c = 'Cancelled';
        if(agreementList != null && !agreementList.isEmpty()){
            update agreementList;
        }
        map<id,Apttus__APTS_Agreement__c> newRecs = new map<id,Apttus__APTS_Agreement__c>();
        newRecs.put(agreementList[0].Id,agreementList[0]);
        
        Test.StartTest();
        CWS_AgreementTriggerHandler handler = new CWS_AgreementTriggerHandler();
        handler.BeforeUpdate(newRecs,oldRecs);
		handler.AfterDelete(new Map<Id, SObject>());
        handler.AfterUndelete(new Map<Id, SObject>());
        Test.StopTest();
    }
    /*testMethod static void testMethodTermination(){
        
        Account acctRec = [Select Id,CWS_NDA_Agreement__c,CWS_NDA_Agreement_Status__c,CWS_MSA_Agreement__c,CWS_MSA_Agreement_Status__c,CWS_BA_Agreement__c,CWS_BA_Agreement_Status__c from Account];
		List<Contact> contactList = [Select Id from Contact where AccountId =: acctRec.Id];
        List<User> userList =[Select Id from User];
        
        List<Apttus__APTS_Agreement__c> agreementList = [Select Id,CWS_Termination_Reason__c,Apttus__Workflow_Trigger_Viewed_Final__c,RecordTypeId,Apttus__Account__c,Apttus__Status__c,Apttus__Contract_Number__c,Apttus__Status_Category__c from Apttus__APTS_Agreement__c];
        agreementList[0].Apttus__Other_Party_Signed_By__c = contactList[0].Id;
        agreementList[0].CWS_Sales_Rep__c = userList[0].Id;
        agreementList[0].Apttus__Status_Category__c = 'In Signatures';
        agreementList[0].Apttus__Status__c = 'Ready for Signatures';
        if(agreementList != null && !agreementList.isEmpty()){
            update agreementList;
        }
        Map<id,Apttus__APTS_Agreement__c> oldRecs = new map<id,Apttus__APTS_Agreement__c>();
        oldRecs.put(agreementList[0].Id,agreementList[1]);
        
        agreementList[0].Apttus__Status__c = 'Other Party Signatures';
        agreementList[0].CWS_Termination_Reason__c = 'Termination';
        agreementList[0].Apttus__Status_Category__c = 'Terminated';
        if(agreementList != null && !agreementList.isEmpty()){
            update agreementList;
        }
        map<id,Apttus__APTS_Agreement__c> newRecs = new map<id,Apttus__APTS_Agreement__c>();
        newRecs.put(agreementList[0].Id,agreementList[0]);
        
        Test.StartTest();
        CWS_AgreementTriggerHandler handler = new CWS_AgreementTriggerHandler();
        handler.BeforeUpdate(newRecs,oldRecs);
        Test.StopTest();
    }*/
}