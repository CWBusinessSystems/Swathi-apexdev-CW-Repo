/*Class Name: CWS_QuoteTriggerHandler
*Description: Handler Class for QuoteDocument Trigger
*Created By: Khayam
*Created On: 04/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                 04/13/2020       BED-5213 			Quote Stage sync with Quote Documents
*Carl Shahan            01/27/2021      #14154761           Changed references to CWS_QuoteDocumentTriggerHelper to CWS_QuoteDocumentTriggerUtility lines 54 and 65	
*/
public with sharing class CWS_QuoteDocumentTriggerHandler implements CWS_ITriggerHandler {

    public static boolean BEFORE_INSERT_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;
    public static boolean AFTER_UPDATE_EXECUTED = false;

    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_QuoteDocument_Trigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_QuoteDocument_Trigger__c;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        if (!BEFORE_INSERT_EXECUTED) {
            CWS_QuoteDocumentTriggerHelper.beforeInsert(newItems);
        }
        if (!Test.isRunningTest()) {
            BEFORE_INSERT_EXECUTED = true;
        }
     }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems) {
		if(!BEFORE_UPDATE_EXECUTED){
            CWS_QuoteDocumentTriggerHelper.BeforeUpdate(newItems,oldItems);
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
            //CWS_QuoteDocumentTriggerHelper.syncQuoteStage(newItems,NULL);
            CWS_QuoteDocumentSyncQuoteStage.syncQuoteDocumentQuoteStage(newItems, null);
        }
        if(!Test.isRunningTest()){
            AFTER_INSERT_EXECUTED = true;
        }
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {     
        if(!AFTER_UPDATE_EXECUTED){
            //CWS_QuoteDocumentTriggerHelper.syncQuoteStage(newItems,oldItems);
           CWS_QuoteDocumentSyncQuoteStage.syncQuoteDocumentQuoteStage(newItems, oldItems);
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