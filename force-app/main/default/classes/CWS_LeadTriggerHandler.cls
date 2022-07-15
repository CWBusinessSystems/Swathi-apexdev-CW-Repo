/*Class Name: CWS_LeadTriggerHandler
*Description: Handler Class for Lead Trigger
*Created By: Ankit
*Created On: 04/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                  04/13/2020      BED-667                 Default Campaign on Sales generated Leads 
*Sudhir Moturu          04/26/2020      BED-541                 Created Before update logic
*/

public  class CWS_LeadTriggerHandler implements CWS_ITriggerHandler {

    public static boolean BEFORE_INSERT_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;
    
    Public Static Boolean isTriggerDisabled=False;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_AccountTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_LeadTrigger__c|| isTriggerDisabled;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        CWS_LeadTriggerHelper.beforeInserLogic(newItems);
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        if(!BEFORE_UPDATE_EXECUTED){
            CWS_LeadTriggerHelper.beforeUpdateLogic((Map<Id, Lead>)newItems,(Map<Id, Lead>)oldItems);
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
        if(!AFTER_INSERT_EXECUTED){
            CWS_LeadTriggerHelper.afterInserLogic(newItems.values());
        }
        AFTER_INSERT_EXECUTED = true;
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