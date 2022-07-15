/*Class Name: CWS_QLITriggerHandler
*Description: Handler Class for QLI Trigger
*Created By: Ankit
*Created On: 10/20/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                10/20/2020           14002423            Nullify the Legacy key from QLI 
*/

public with Sharing class CWS_QLITriggerHandler implements CWS_ITriggerHandler {
    
    public static boolean BEFORE_INSERT_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;
   
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_QuoteTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_QLITrigger__c;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(list<SObject> newItems){
        if(!BEFORE_INSERT_EXECUTED){
            CWS_QLITriggerHelper.beforeInsertandUpdate(newItems);
        } 
        if(!Test.isRunningTest()) {
            BEFORE_INSERT_EXECUTED = true;
        }
     }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems) {
        if(!BEFORE_UPDATE_EXECUTED){
            CWS_QLITriggerHelper.beforeInsertandUpdate(newItems.values());
        }  
        if(!Test.isRunningTest()){
            BEFORE_UPDATE_EXECUTED = true;
        }
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Delete Event*/
    public void AfterDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Undelete Event*/
    public void AfterUndelete(Map<Id, SObject> newItems) {
    }
}