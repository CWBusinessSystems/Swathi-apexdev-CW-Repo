/*Class Name: CWS_ProductTriggerHandler
*Created By: Ankit
*Created On: 08/18/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                 08/18/2020      Initial version     Default Precision Measure based on UOM
*/
public with Sharing class CWS_ProductTriggerHandler implements CWS_ITriggerHandler
{
    public static boolean BEFORE_UPDATE_EXECUTED = false;
    
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
     //CWS_DiscountScheduleTrigger would be set to false to disable the trigger
     return !CWS_Trigger_Switch__c.getInstance().CWS_ProductTrigger__c;
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems)
    {
        if(!BEFORE_UPDATE_EXECUTED){
         CWS_ProductTriggerHelper.beforeInserUpdate(newItems.values(), oldItems);
        }
        if(!Test.isRunningTest()){
            BEFORE_UPDATE_EXECUTED = true;
        }  
    }
    
     /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
         
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems)
    {
        CWS_ProductTriggerHelper.beforeInserUpdate(newItems,null);
    }
    
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) 
    {
        
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