/*Class Name: CWS_QuoteTriggerHandler
*Description: Handler Class for Quote Trigger
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
Asutosh                 25.5.2020       10641                   Product Sync Logic
*/

public with Sharing class CWS_ProductOptionTriggerHandler implements CWS_ITriggerHandler {
    
    public static boolean AFTER_INSERT_EXECUTED = false;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_QuoteTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_ProductOptionTrigger__c;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){

     }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems) {

    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
        //CWS_ProductOptionTriggerHelper.afterInsertHelper(newItems.values());
        if(!AFTER_INSERT_EXECUTED){
            CWS_ProductOptionTriggerHelper.afterInsertHelper(newItems);
           }
           if(!Test.isRunningTest()){
            AFTER_INSERT_EXECUTED = true;
           } 
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