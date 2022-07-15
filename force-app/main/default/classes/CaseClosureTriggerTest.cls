@isTest
private class CaseClosureTriggerTest {
    @isTest static void unitTest() {
        Account accObj = new Account(Name = 'Continuum');
        insert accObj;
        Id recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Care').getRecordTypeId();
        // Create the Case Record.
        Case cas = new Case(Status ='New', Priority = 'Medium', Origin = 'Email', AccountId = accObj.Id);
        insert cas;
        cas.RecordTypeId = recordtypeId ;
        cas.Status ='Closed';
        update cas;
    }
 }