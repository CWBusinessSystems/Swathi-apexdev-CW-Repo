/*Class Name: CWS_CaseClosureTriggerHandler
*Description: Handler class for executing CaseClosure Trigger (supports Gainsight integration)
*Created By: Gainsight
*Created On: Unknown
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Jeff Cochran 10/23/2020 N/A       Added incremental trigger execution logic to create Gainsight event on case closure.
*Jeff Cochran 11/10/2020 N/A       Changed lines 98 and 103 to support only created GainSight events based on cases that are Partner Care
*Divyanshu 09/09/2021    OBD-442   Added lines 50,51,130,131 to add on a couple of more parameters which are required at GS end
*/
public class CWS_CaseClosureTriggerHandler {
    //Method is processClosedCases with parameter List of Cases
    public static void processClosedCases(List<Case> caseList) {

        //List of Map with Case Record Details
        List<Map<String, Object>> records = new List<Map<String, Object>>();

        //List Of Case Id's where Case Status = Closed and RecordType = Partner Case
        List<String> caseids = new List<String>();
        Id recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Care').getRecordTypeId();
        //Iterate Over List of all Case to create case Id list of only Case Status = Closed and RecordType = Partner Case
        for (Case updatedCase : caseList){
            if (updatedCase.status == 'Closed' && updatedCase.RecordTypeId == recordtypeId){
                caseids.add(updatedCase.Id);
            }
        }

        //Iterate Closed and Partner Case records to create Map of case details
        for (Case updatedCase : [Select CaseNumber, ContactEmail, AccountId, ClosedDate, Reason, Account.Name, Type, Partner_Facing_Summary__c, Owner.Email, Id, Contact.FirstName, Subject, Assigned_To__r.Name, Language,ContactId,OwnerId
                                 From Case
                                 where Id in :caseids]){
            Map<String, Object> record = new Map<String, Object>();
            //String prefLanguage = updatedCase.Contact.Language__c;
            record.put('Recipient Email', updatedCase.ContactEmail);
            record.put('Account Id', updatedCase.AccountId);
            record.put('Account Name', updatedCase.Account.Name);
            record.put('Case Number', updatedCase.CaseNumber);
            record.put('Reason', updatedCase.Reason);
            record.put('Language', updatedCase.Language);
            record.put('User Email', updatedCase.Owner.Email);
            record.put('Case Subject', updatedCase.Subject);
            record.put('First Name', updatedCase.Contact.FirstName);
            record.put('Assigned To', updatedCase.Assigned_To__r.Name);
            record.put('Case Type', updatedCase.Type);
            record.put('Case Id', updatedCase.Id);
            record.put('Partner Facing Summary', updatedCase.Partner_Facing_Summary__c);
            record.put('Closed Date', updatedCase.ClosedDate);
            record.put('Contact Id', updatedCase.ContactId);
            record.put('User Id', updatedCase.OwnerId);
            records.add(record);
        }

        Map<String, String> headers = new Map<String, String>();
        Map<String, Object> data = new Map<String, Object>();
        data.put('participantInformationList', records);

        CWS_GainsightInfo__mdt  gaininfo = new CWS_GainsightInfo__mdt ();
        
        For(CWS_GainsightInfo__mdt  mcs : [SELECT CWS_GSeventName__c,CWS_GSeventVersion__c,CWS_GSsharedSecret__c,CWS_GStenantId__c,CWS_GStopicName__c,DeveloperName,MasterLabel FROM CWS_GainsightInfo__mdt where  MasterLabel = : 'Case Closure']){
            
            if (mcs != null && mcs.MasterLabel =='Case Closure'){
                
                gaininfo = mcs;
            }
        }
       
        data.put('eventName', gaininfo.CWS_GSeventName__c );
        data.put('topicName', gaininfo.CWS_GStopicName__c);
        data.put('eventVersion', String.valueOf(gaininfo.CWS_GSeventVersion__c));
        data.put('sharedSecret', gaininfo.CWS_GSsharedSecret__c );
        data.put('tenantId', gaininfo.CWS_GStenantId__c);

        // post the event
        JBCXM.GlobalAPI.asyncCallMDA('/api/v0.1/eventManager/event', 'POST', JSON.serialize(data), headers);
    }

    public static void gsEvent(List<Case> newCases) {
         string eventName = '';
        string eventVersion = '';
        string topicName = '';
        string tenantId = '';
        string sharedSecret = '';

         CWS_GainsightInfo__mdt  gaininfo = new CWS_GainsightInfo__mdt ();
        For(CWS_GainsightInfo__mdt  mcs:[SELECT CWS_GSeventName__c,CWS_GSeventVersion__c,CWS_GSsharedSecret__c,CWS_GStenantId__c,CWS_GStopicName__c,DeveloperName,MasterLabel FROM CWS_GainsightInfo__mdt where  MasterLabel =: 'Case Closure']){
            if(mcs != null && mcs.MasterLabel =='Case Closure'){
            gaininfo = mcs;
            }
        }
       
        
        if (gaininfo != null) {
          eventName = gaininfo.CWS_GSeventName__c;
          eventVersion = String.valueOf(gaininfo.CWS_GSeventVersion__c);
          topicName = gaininfo.CWS_GStopicName__c;
          tenantId = gaininfo.CWS_GStenantId__c;
          sharedSecret = gaininfo.CWS_GSsharedSecret__c;
        }
        
        Id recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Care').getRecordTypeId();
        if (Trigger.isUpdate){
            List<Map<string, Object>> records = new List<Map<String, Object>>();
            List<String> caseids = new List<String>();
            for (Case updatedCase : newCases){
                if (updatedCase.status.equals('Closed') && updatedCase.RecordTypeId == recordtypeId) {
                    caseids.add(updatedCase.Id);
                }
            }
            List<case> cases = [Select CaseNumber, Contact.Name,Owner.Email, ContactEmail,Assigned_To__r.Name,Partner_Facing_Summary__c, AccountId, Subject, Reason, Account.Name,language, Type,ClosedDate,ContactId,OwnerId
                                from Case
                                where id in :caseids];
            for (Case updatedCase : cases){
                Map<String, Object> record = new Map<String, Object>();
                record.put('Recipient Email', updatedCase.ContactEmail);
                record.put('Account Id', updatedCase.AccountId);
                record.put('Account Name', updatedCase.Account.Name);
                record.put('Case Number', updatedCase.CaseNumber);
                record.put('Reason', updatedCase.Reason);
                record.put('Case Type', updatedCase.Type);
                record.put('First Name', updatedCase.Contact.Name);
                record.put('Case Subject', updatedCase.Subject);
                record.put('Language', updatedCase.Language);
                record.put('Closed Date', updatedCase.ClosedDate);
                record.put('User Email', updatedCase.Owner.Email);
                record.put('Assigned To', updatedCase.Assigned_To__r.Name);
                record.put('Case Id', updatedCase.Id);
                record.put('Partner Facing Summary', updatedCase.Partner_Facing_Summary__c);
                record.put('Contact Id', updatedCase.ContactId);
                record.put('User Id', updatedCase.OwnerId);
                records.add(record);
            }
            if (records.size() > 0){
                 if (!Test.isRunningTest()){
                  
                  CWS_GSEvents.calloutFromFuture(JSON.serialize(records), sharedSecret, tenantId, eventName, topicName, eventVersion);
                }      
            }
        }
    }
}