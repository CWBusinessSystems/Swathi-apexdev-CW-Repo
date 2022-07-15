/*Class Name: CWS_OpportunityLineItemTriggerHandler
*Description: Handler Class for OpportunityLineItem Trigger
*Created By: Aditya
*Created On: 05/19/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aditya             05/19/2020          BED-8552/226         Default Pricing fields from Product
*/

public class CWS_OpportunityLineItemTriggerHandler implements CWS_ITriggerHandler {
	
	public static boolean BEFORE_INSERT_EXECUTED = false;
	public static boolean BEFORE_UPDATE_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;
	public static boolean AFTER_UPDATE_EXECUTED = false;
	
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_AccountTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_OLITrigger__c;       
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
    	  if (!BEFORE_INSERT_EXECUTED) {
            CWS_OLITriggerHelper.beforeInsertUpdatetMethod(newItems,null);
            if (!Test.isRunningTest()) {
                    BEFORE_INSERT_EXECUTED = true;
                }
        }
       
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    	 if (!BEFORE_UPDATE_EXECUTED) {
        	List<OpportunityLineItem> oliNewItems = newItems.values() ;
        	Map<id,OpportunityLineItem> oliOldItems = (Map<id,OpportunityLineItem>)oldItems ;
            CWS_OLITriggerHelper.beforeInsertUpdatetMethod(oliNewItems, oliOldItems);
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
        if(!AFTER_INSERT_EXECUTED){
            List<OpportunityLineItem> oliNewItems = newItems.values() ;
        	CWS_OLITriggerHelper.afterInsertUpdateMethod(oliNewItems, null);
        }
        if(!Test.isRunningTest()){
            AFTER_INSERT_EXECUTED = true;
        }
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {   
		if(!AFTER_UPDATE_EXECUTED){
			List<OpportunityLineItem> oliNewItems = newItems.values() ;
			Map<id,OpportunityLineItem> oliOldItems = (Map<id,OpportunityLineItem>)oldItems ;
			CWS_OLITriggerHelper.afterInsertUpdateMethod(oliNewItems, oliOldItems);
			if(!Test.isRunningTest()){
				AFTER_UPDATE_EXECUTED=true;
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