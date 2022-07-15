/*Class Name: CWS_QuoteTriggerHandler
*Description: Handler Class for Quote Trigger
*Created By: Khayam
*Created On: 04/03/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                04/03/2020           BED-6326            Opp Team Member Access to Quote 
*/

public with Sharing class CWS_ContractTriggerHandler implements CWS_ITriggerHandler {
    
    public static boolean BEFORE_UPDATE_EXECUTED = false;



    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_QuoteTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_ContractTrigger__c;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        CWS_ContractTriggerHelper.beforeInsertHelper(newItems);
     }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems) {
        Map<Id,Contract> newMap=(Map<Id, Contract>)newItems;
        Map<Id,Contract> oldMap=(Map<Id, Contract>)oldItems;  
        CWS_ContractTriggerHelper.beforeUpdateHelper(newMap, oldMap);      
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