/*Class Name: CWS_OpportunityTriggerHandler
*Description: Handler Class for Opportunity Trigger
*Created By: Nirmal
*Created On: 04/06/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nirmal			       04/06/2020			BED-3177 			Currency based on bill to Account 
*/
public class CWS_OpportunityTriggerHandler implements CWS_ITriggerHandler {

    public static boolean BEFORE_INSERT_EXECUTED = false;
	public static boolean BEFORE_UPDATE_EXECUTED = false;
	public static boolean AFTER_UPDATE_EXECUTED = false;
	public static boolean AFTER_INSERT_EXECUTED = false;
	
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_OpportunityTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_OpportunityTrigger__c;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        if (!BEFORE_INSERT_EXECUTED) {
            CWS_OpportunityTriggerHelper.beforeInsertMethod(newItems);
            if (!Test.isRunningTest()) {
                    BEFORE_INSERT_EXECUTED = true;
                }
        }
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        if (!BEFORE_UPDATE_EXECUTED) {
            Map<Id, Opportunity> newMap=(Map<Id, Opportunity>)newItems;
            Map<Id, Opportunity> oldMap=(Map<Id, Opportunity>)oldItems;
        CWS_OpportunityTriggerHelper.beforeUpdateMethod(newMap, oldMap);
        if (!Test.isRunningTest()) {
                    BEFORE_UPDATE_EXECUTED = true;
                }
        }
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
        if (!AFTER_INSERT_EXECUTED) {
            Map<Id, Opportunity> newMap = (Map<Id, Opportunity>)newItems;
            CWS_OpportunityTriggerHelper.afterInsertMethod(newMap);
            if (!Test.isRunningTest()) {
                AFTER_INSERT_EXECUTED = true;
                }
        }
        
    }
    
	/* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
		if (!AFTER_UPDATE_EXECUTED) {
            Map<Id, Opportunity> newMap=(Map<Id, Opportunity>)newItems;
            Map<Id, Opportunity> oldMap=(Map<Id, Opportunity>)oldItems;
        	CWS_OpportunityTriggerHelper.afterUpdate(newMap, oldMap);
        	if (!Test.isRunningTest()) {
                    AFTER_UPDATE_EXECUTED = true;
            }
        }
    }
    
    /* Method for After Delete Event*/
    public void AfterDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Undelete Event*/
    public void AfterUndelete(Map<Id, SObject> newItems) {
    }
}