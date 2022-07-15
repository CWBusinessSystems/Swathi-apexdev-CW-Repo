/*Class Name: CWS_CWS_GSEvents
*Description: create Events to Gainsight from Salesforce 
*Created By: Jeff Cochran
*Created On: 10/23/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------

*/
@isTest
private class CWS_GSEvents_Test {

      private static testMethod void CWS_GSEventsTestMethod(){
          string eventName = 'copy_value_from_gainsight_events_page';
        string eventVersion = 'copy_value_from_gainsight_events_page';
        string topicName = 'copy_value_from_gainsight_events_page';
        string tenantId = 'contact yourcsm toget yourtenantId';
        string sharedSecret = 'copy_value_from_gainsight_events_page';
        
        List<Map<string, Object>> records = new List<Map<String, Object>>();
        
        Account accObj = new Account(Name = 'Continuum');
        insert accObj;
        
        Case cas = new Case(Status ='New', Priority = 'Medium', Origin = 'Email', AccountId = accObj.Id);
        insert cas;
        
        Case cas1 = new Case(Status ='New', Priority = 'Medium', Origin = 'Email', AccountId = accObj.Id);
        insert cas1;
          
         Map<String, Object> record = new Map<String, Object>();
                record.put('Recipient Email', cas.ContactEmail);
                record.put('Account Id', cas.AccountId);
                record.put('Account Name', cas.Account.Name);
                record.put('Case Number', cas.CaseNumber);
                record.put('Reason', cas.Reason);
                record.put('Type', cas.Type);
                record.put('Contact', cas.Contact.Name);
                record.put('Subject', cas.Subject);
                records.add(record);
          
         Map<String, Object> record1 = new Map<String, Object>();
                record1.put('Recipient Email', cas1.ContactEmail);
                record1.put('Account Id', cas1.AccountId);
                record1.put('Account Name', cas1.Account.Name);
                record1.put('Case Number', cas1.CaseNumber);
                record1.put('Reason', cas1.Reason);
                record1.put('Type', cas1.Type);
                record1.put('Contact', cas1.Contact.Name);
                record1.put('Subject', cas1.Subject);
                records.add(record1); 
        //Test.startTest();
          //Test.setMock(HttpCalloutMock.class, new CWS_GSEvents_Mock());
         CWS_GSEvents cws = new CWS_GSEvents();
         CWS_GSEvents.calloutFromFuture(JSON.serialize(records),sharedSecret, tenantId, eventName, topicName, eventVersion);
        //Test.stopTest();
    }
    
}