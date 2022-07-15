/*Class Name: CWS_ApprovalTriggerHandler
*Description: Handler Class for Approval Trigger
*Created By: Khayam
*Created On: 05/10/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                 5/19/2020       BED-8645            Account Restriction - Delinquency 
*/
public with sharing class CWS_ApprovalTriggerHandler implements CWS_ITriggerHandler {

    public static boolean AFTER_UPDATE_EXECUTED = false;

    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_Approval_Trigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_Approval_Trigger__c;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
		CWS_ApprovalTriggerHelper.beforeInsertMethod(newItems);
     }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems) {
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
         if(!AFTER_UPDATE_EXECUTED){
         CWS_ApprovalTriggerHelper.afterUpdate(newItems, oldItems);
        }
        if(!Test.isRunningTest()){
            AFTER_UPDATE_EXECUTED = true;
        }
            
    }
    
    /* Method for After Delete Event*/
    public void AfterDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Undelete Event*/
    public void AfterUndelete(Map<Id, SObject> newItems) {
    }

}