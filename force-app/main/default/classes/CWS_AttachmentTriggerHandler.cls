/*Class Name: CWS_AttachmentTriggerHandler
*Description: Handler Class for CWS_AttachmentTrigger
*Created By: Naresh
*Created On: 05/30/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Naresh                05/30/2020           BED-6236             
*/

public with Sharing class CWS_AttachmentTriggerHandler implements CWS_ITriggerHandler {

    public static boolean BEFORE_INSERT_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;
    public static boolean AFTER_UPDATE_EXECUTED = false;
    
     /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
       
        return !CWS_Trigger_Switch__c.getInstance().CWS_QuoteTrigger__c;  
    }
    
    
     /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        if(!BEFORE_INSERT_EXECUTED){
                   
        } 
        if(!Test.isRunningTest()) {
            BEFORE_INSERT_EXECUTED = true;
        }
     }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems) {
        if(!BEFORE_UPDATE_EXECUTED){
           
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
            system.debug('entered attachement handler');
           CWS_AttachmentTriggerHelper.createAdditionalDocument(newItems);  
            system.debug('completed attachement handler');
        }
        if(!Test.isRunningTest()){
            AFTER_INSERT_EXECUTED = true;
        }
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
         if(!AFTER_UPDATE_EXECUTED){
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