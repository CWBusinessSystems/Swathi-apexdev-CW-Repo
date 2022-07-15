/*Class Name: CWS_CaseClosureTriggerHandler
*Description: Handler class for executing CaseClosure Trigger (supports Gainsight integration)
*Created By: Gainsight
*Created On: Unknown
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Jeff Cochran 10/23/2020 N/A       Test class for Gainsight event on case closure.
*/
@isTest
private class CWS_CaseClosureTriggerHandler_Test{
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
        
        
        List<case> caseList = new list<Case>();
        caseList.add(cas);
        CWS_CaseClosureTriggerHandler.processClosedCases(caseList );
      }
 }