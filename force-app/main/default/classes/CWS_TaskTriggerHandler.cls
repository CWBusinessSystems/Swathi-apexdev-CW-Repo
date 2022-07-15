/*Class Name: CWS_TaskTriggerHandler
*Description: Handler Class for Task Trigger
*Created By: Manoj
*Created On: 05/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Manoj                  05/05/2020      BED-7889                Prevent deletion of task by non admins
*Raja                   20/04/2021      14428826                Update Phone and Email on task
*/
public  class CWS_TaskTriggerHandler implements CWS_ITriggerHandler {

    public static boolean BEFORE_INSERT_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;    
    public static boolean isTriggerDisabled = false;
    
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_AccountTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_TaskTrigger__c|| isTriggerDisabled;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){  
        CWS_TaskTriggerHelper.beforeInsertLogic(newItems);
        CWS_TaskTriggerHelper.updatePhoneAndEmailonTask(newItems,null);
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
	 	CWS_TaskTriggerHelper.beforeUpdate(newItems, oldItems);
        CWS_TaskTriggerHelper.updatePhoneAndEmailonTask(newItems.values(),(Map<Id,Task>)oldItems);
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        CWS_TaskTriggerHelper.beforeDeleteLogic(oldItems);
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {  
    //CWS_TaskTriggerHelper.afterUpdate(newItems,oldItems);	
    }
    
    /* Method for After Delete Event*/
    public void AfterDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Undelete Event*/
    public void AfterUndelete(Map<Id, SObject> newItems) {
    }
    
}