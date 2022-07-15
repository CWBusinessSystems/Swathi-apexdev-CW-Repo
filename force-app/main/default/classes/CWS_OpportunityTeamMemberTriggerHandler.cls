/*Class Name: CWS_OpportunityTeamMemberTriggerHandler
*Description: Handler Class for OpportunityTeamMember Trigger
*Created By: Khayam
*Created On: 04/01/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                04/01/2020           BED-6326            Sales Rep Access to Quote 
*
*/
public without sharing class CWS_OpportunityTeamMemberTriggerHandler implements CWS_ITriggerHandler {
    public static boolean AFTER_INSERT_EXECUTED = false;
    public static boolean AFTER_DELETE_EXECUTED = false;

    public Boolean IsDisabled(){
        
        return !CWS_Trigger_Switch__c.getInstance().CWS_OpportunityTeamMember_Trigger__c;
    }
    public void BeforeInsert(List<SObject> newItems){}
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
    
    public void AfterInsert(Map<Id, SObject> newItems) {
      if(!AFTER_INSERT_EXECUTED  ){
        CWS_OpportunityTeamMemberTriggerHelper.shareQuotesofOpportunity(newItems);
       } 
       
       if (!Test.isRunningTest()) {
           AFTER_INSERT_EXECUTED  = true;
       }
    }
       
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems) {
        if(!AFTER_DELETE_EXECUTED ){
            CWS_OpportunityTeamMemberTriggerHelper.unshareQuotesofOpportunity(oldItems);
            
        }
        
        if (!Test.isRunningTest()) {
           AFTER_DELETE_EXECUTED = true;
       }
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems) {} 
}