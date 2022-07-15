/*Class Name: CWS_DiscountTierTriggerHandler
*Description: Handler Class for Discount Tier Trigger
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
Asutosh                 25.5.2020       10641                   Product Sync Logic
*/

public with Sharing class CWS_DiscountTierTriggerHandler implements CWS_ITriggerHandler 
{
	public static boolean AFTER_UPDATE_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;
    
    
     /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
     //CWS_DiscountScheduleTrigger would be set to false to disable the trigger
     return !CWS_Trigger_Switch__c.getInstance().CWS_DiscountTierTrigger__c;
    }
    
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
         if(!AFTER_UPDATE_EXECUTED){
         CWS_DiscountTierTriggerHelper.afterUpdate(newItems, oldItems);
        }
        if(!Test.isRunningTest()){
            AFTER_UPDATE_EXECUTED = true;
        }     
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems)
    {
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems)
    {
    }
    
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) 
    {
        if(!AFTER_INSERT_EXECUTED){
            CWS_DiscountTierTriggerHelper.afterInsert(newItems);
           }
           if(!Test.isRunningTest()){
            AFTER_INSERT_EXECUTED = true;
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