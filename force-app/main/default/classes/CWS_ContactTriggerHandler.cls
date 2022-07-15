/*Class Name: CWS_ContactTriggerHandler
*Description: Handler Class for Contact Trigger
*Created By: Sudhir Moturu
*Created On: 05/MAY/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Sudhir Moturu          05/MAY/2020     BED-6452                Created Before update, Before Insert logic
*Raja Mouthkapally		4/27/2020		OBD-107					14428826 - Field Marketing Task Enhancements
*/

public with Sharing class CWS_ContactTriggerHandler implements CWS_ITriggerHandler {

    public static boolean BEFORE_INSERT_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;
    public static boolean AFTER_UPDATE_EXECUTED = false;
    
    Public Static Boolean isTriggerDisabled=False;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_ContactTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_ContactTrigger__c|| isTriggerDisabled;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        if(!BEFORE_INSERT_EXECUTED){
            CWS_ContactTriggerHelper.beforeInsertLogic((List<Contact>)newItems);
        }
        if(!Test.isRunningTest()) {
            BEFORE_INSERT_EXECUTED = true;
        }
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        if(!BEFORE_UPDATE_EXECUTED){
            CWS_ContactTriggerHelper.beforeUpdateLogic((Map<Id, Contact>)newItems,(Map<Id, Contact>)oldItems);
        }
        if(!Test.isRunningTest()) {
            BEFORE_UPDATE_EXECUTED = true;
        }
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
        if(!AFTER_INSERT_EXECUTED){
            CWS_ContactTriggerHelper.afterInsertLogic((Map<Id, Contact>)newItems);
        }
        if(!Test.isRunningTest()) {
            AFTER_INSERT_EXECUTED = true;
        }
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
        if(!AFTER_UPDATE_EXECUTED){
            CWS_ContactTriggerHelper.afterUpdateLogic((Map<Id, Contact>)newItems,(Map<Id, Contact>)oldItems);
        }  
        if(!Test.isRunningTest()) {
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