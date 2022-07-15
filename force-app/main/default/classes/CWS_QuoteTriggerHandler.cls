/*Class Name: CWS_QuoteTriggerHandler
*Description: Handler Class for Quote Trigger
*Created By: Khayam
*Created On: 04/03/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                04/03/2020           BED-6326            Opp Team Member Access to Quote
*Ad Victoriam Solutions 02/14/2022          N/A                 Reformatted code.
*/

public with sharing class CWS_QuoteTriggerHandler implements CWS_ITriggerHandler {
    
    public static Boolean BEFORE_INSERT_EXECUTED = false;
    public static Boolean AFTER_INSERT_EXECUTED = false;
	public static Boolean BEFORE_UPDATE_EXECUTED = false;
    public static Boolean AFTER_UPDATE_EXECUTED = false;

    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled() {
        // CWS_QuoteTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_QuoteTrigger__c;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems) {
        if(!BEFORE_INSERT_EXECUTED) {
            CWS_QuoteTriggerHelper.copyToRenewalAmendmentQuoteBeforeIns(newItems);
            CWS_QuoteTriggerHelper.beforeInsertMethod(newItems);
            CWS_QuoteTriggerHelper.updateDistributorFulfillmentType(newItems, null);            
        } 
        if(!Test.isRunningTest()) {
            BEFORE_INSERT_EXECUTED = true;
        }
     }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, sObject> oldItems) {
		CWS_QuoteTriggerHelper.updateMonthlyMinCommit(newItems, oldItems);
        if(!BEFORE_UPDATE_EXECUTED) {
            Map<Id, SBQQ__Quote__c> oldMap = (Map<Id, SBQQ__Quote__c>) oldItems;
            CWS_QuoteTriggerHelper.beforUpdate(newItems,oldItems);
            CWS_QuoteTriggerHelper.updateDistributorFulfillmentType(newItems.values(), oldMap);
            CWS_QuoteTriggerHelper.updateOverageQLI(newItems, oldItems);
			CWS_QuoteTriggerHelper.updateApprovalRelatedFields(newItems,oldItems);
			if(!Test.isRunningTest()) {
				BEFORE_UPDATE_EXECUTED = true;
			}
        }  

    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        // not implemented
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
        if(!AFTER_INSERT_EXECUTED){
            CWS_QuoteTriggerHelper.afterInsert(newItems);
            CWS_QuoteTriggerHelper.cloneRelatedRecords(newItems);
        }
        if(!Test.isRunningTest()){
            AFTER_INSERT_EXECUTED = true;
        }
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {     
        if(!AFTER_UPDATE_EXECUTED) {
            CWS_QuoteTriggerHelper.afterUpdate(newItems, oldItems);
        }
        if(!Test.isRunningTest()) {
            AFTER_UPDATE_EXECUTED = true;
        }
            
    }
    
    /* Method for After Delete Event*/
    public void AfterDelete(Map<Id, SObject> oldItems) {
        // not implemented
    }
    
    /* Method for After Undelete Event*/
    public void AfterUndelete(Map<Id, SObject> newItems) {
        // not implemented
    }
}