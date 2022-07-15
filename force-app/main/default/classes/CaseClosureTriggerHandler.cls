//Class is CaseClosureTriggerHandler is public
public class CaseClosureTriggerHandler {

//Method is processClosedCases with parameter List of Cases
    public static void processClosedCases(List<Case> caseList) {
        
        //List of Map with Case Record Details
        List<Map<String,Object>> records = new List<Map<String,Object>>();
        
        //List Of Case Id's where Case Status = Closed and RecordType = Partner Case
        List<String> caseids = new List<String>();
        Id recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Care').getRecordTypeId();
        //Test Account related Cases
        //List<Account> accList = [SELECT ID FROM Account Where Name = 'Continuum' LIMIT 1];
        //if(!accList.isEmpty()){
            //Iterate Over List of all Case to create case Id list of only Case Status = Closed and RecordType = Partner Case
            for(Case updatedCase : caseList){
              if(updatedCase.status == 'Closed' && updatedCase.RecordTypeId == recordtypeId ) {
               caseids.add(updatedCase.Id);
             }
            }
        //}
    
    //Iterate Closed and Partner Case records to create Map of case details
         for(Case updatedCase : [Select CaseNumber,ContactEmail,AccountId,
                                        ClosedDate,Reason, Account.Name, Type, Partner_Facing_Summary__c, 
                                        Owner.Email, Id, Contact.FirstName, Subject, Assigned_To__r.Name,
                                        Language
                                 From Case where Id in :caseids]) {
           Map<String,Object> record = new Map<String,Object>();
           //String prefLanguage = updatedCase.Contact.Language__c;
           record.put('Recipient Email', updatedCase.ContactEmail);
           record.put('SFDCAccount Id', updatedCase.AccountId);
           record.put('SFDCAccount Name', updatedCase.Account.Name);
           record.put('SFDCCase Number', updatedCase.CaseNumber);
           record.put('Reason', updatedCase.Reason);
           record.put('Language', updatedCase.Language);
           record.put('User Email', updatedCase.Owner.Email);
           record.put('SFDCCase Subject',updatedCase.Subject);
           record.put('First Name',updatedCase.Contact.FirstName);
           record.put('Assigned to',updatedCase.Assigned_To__r.Name);
           record.put('Case Type',updatedCase.Type);
           record.put('Case Id',updatedCase.Id);
           record.put('Partner Facing Summary',updatedCase.Partner_Facing_Summary__c);
           //record.put('Language', updatedCase.Contact.Language__c);
    
           record.put('Closed Date',updatedCase.ClosedDate);
           records.add(record);
      }
    
       Map<String,String> headers = new Map<String,String>();
       Map<String,Object> data = new Map<String,Object>();
       data.put('participantInformationList',records);
       data.put('eventName','Case Closure');
       data.put('topicName','Case Closed Survey');
       data.put('eventVersion','1.0');
       data.put('sharedSecret','lWUZhSuFviq+L6ds9kVQxxajwoAEQR84Lp6PCw8ySi9HZ/lntpSZ2z0SLqMK6Bes');
       data.put('tenantId','c143dbef-5f57-4bce-b053-1bcf8a1ec045');
    
       //system.debug('JSONString >> '+JSON.serialize(data));
        // post the event
        JBCXM.GlobalAPI.asyncCallMDA('/api/v0.1/eventManager/event','POST',JSON.serialize(data),headers);
    }
}