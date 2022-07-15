@isTest(SeeAllData=false)
public class CWS_AgreementApprovalVFCompCtrlTest {
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
        
    }
    
      @isTest
    Public static void testAgreementController(){
     test.startTest();
      Apttus__APTS_Agreement__c aggObj = [Select Id, 
                          Apttus__Account__r.Name,
                          Name,
                          Owner.Name,
                          Apttus__FF_Agreement_Number__c,
                          Apttus__Contract_Start_Date__c,
                          CWS_Clause_type__c,
                          Apttus__Total_Contract_Value__c,
                          Apttus__Account__c,
                          RecordType.Name
                          from Apttus__APTS_Agreement__c LIMIT 1];
      CWS_AgreementApprovalVFCompCrtlr.getAgreementSO(aggObj.id);
      System.assertEquals(true, aggObj.id!=null);   
      CWS_AgreementApprovalVFCompCrtlr ctrl = new CWS_AgreementApprovalVFCompCrtlr();
      ctrl.agreementSO = aggObj;
      Apttus_Approval__Approval_Request__c reqSSO = new Apttus_Approval__Approval_Request__c(Apttus_Approval__Object_Id__c= aggObj.id);  
      insert reqSSO;  
      ctrl.getContext();
      ctrl.getAgreementSO();      
      system.debug('&&&reqSSO = '+reqSSO);      
      CWS_AgreementApprovalVFCompCrtlr.accountName = 'Test AccName';
      CWS_AgreementApprovalVFCompCrtlr.agreementName = 'NDA Agreement';
      CWS_AgreementApprovalVFCompCrtlr.ownerName = 'Test User';
      CWS_AgreementApprovalVFCompCrtlr.agreementNumber = 'NDA0909';
      CWS_AgreementApprovalVFCompCrtlr.projectStartDate = Date.today();
      CWS_AgreementApprovalVFCompCrtlr.totalContractValue = 9090;
      CWS_AgreementApprovalVFCompCrtlr.clauseType = 'Manual';
      System.assertEquals('Test AccName',  CWS_AgreementApprovalVFCompCrtlr.accountName); 
      System.assertEquals('NDA Agreement',CWS_AgreementApprovalVFCompCrtlr.agreementName); 
      System.assertEquals('Test User',CWS_AgreementApprovalVFCompCrtlr.ownerName); 
      System.assertEquals('NDA0909',CWS_AgreementApprovalVFCompCrtlr.agreementNumber); 
      System.assertEquals(Date.today(),  CWS_AgreementApprovalVFCompCrtlr.projectStartDate); 
      System.assertEquals(9090,  CWS_AgreementApprovalVFCompCrtlr.totalContractValue); 
      System.assertEquals('Manual', CWS_AgreementApprovalVFCompCrtlr.clauseType); 
      
      Test.stopTest();
    
    }
    
}