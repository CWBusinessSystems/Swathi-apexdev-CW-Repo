public class CWS_caseInsertTriggerHandler{
 public static void domainErrorValidation(list<case> lstCases){
     set<String> setDomains = new set<String>();
  set<Id> setContactIds = new set<Id>();
  set<Id> setCaseIds = new set<id>();
  map<id,Contact> mapCaseContactEmails = new map<id,Contact>();
   for(Case objCase : lstCases){
     if(objCase.Contactid != null ){
      setContactIds.add(objCase.Contactid );
      }
   }
   for(Contact objCaseContact :  [Select id,Email,Blocked_Domains__c from Contact where id in :setContactIds]){
        mapCaseContactEmails.put(objCaseContact.id,objCaseContact);
   }
   for(Case objCase : lstCases){
     if(mapCaseContactEmails !=null && mapCaseContactEmails.containskey(objCase.contactid) && mapCaseContactEmails.get(objCase.Contactid).Blocked_Domains__c!=null && mapCaseContactEmails.get(objCase.Contactid).Email.contains(mapCaseContactEmails.get(objCase.Contactid).Blocked_Domains__c)){
objCase.adderror('Using this domain to create a case is not allowed');
      }
   }
 }

}