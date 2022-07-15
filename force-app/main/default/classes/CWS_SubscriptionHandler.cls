/*
Class Name: CWS_SubscriptionHandler
*Description: Handler Class for Subscription Trigger
*Created By: Aakash Sharma
*Created On: 04/10/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aakash                04/10/2020       BED-5894                ACV Roll-up on the Contract from the inidividual Subscriptions.
*/

public with Sharing class CWS_SubscriptionHandler implements CWS_ITriggerHandler {
    
    public static boolean AFTER_INSERT_EXECUTED = false;
    public static boolean AFTER_UPDATE_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;
    
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_QuoteTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_SubscriptionTrigger__c;
    }

    /* Method for Before Insert Event*/
    public void BeforeInsert(List<SObject> newItems){
        CWS_SubsTriggerHelper.beforeInsertHelper(newItems);
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
        if(!AFTER_INSERT_EXECUTED){
            CWS_SubsTriggerHelper.afterInsertHelper(newItems);
        }
        if(!Test.isRunningTest()){
            AFTER_INSERT_EXECUTED = true;
        }
    }
    /* Method for Before update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems) {     
        if(!BEFORE_UPDATE_EXECUTED){
            CWS_SubsTriggerHelper.beforeUpdate(newItems,oldItems);
        }
        if(!Test.isRunningTest()){
            BEFORE_UPDATE_EXECUTED = true;
        }
    }
     /* Method for After Update Event*/
     public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) 
     {     
        if(!AFTER_UPDATE_EXECUTED){
            CWS_SubsTriggerHelper.afterUpdate(newItems, oldItems);
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
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {    
    }
}