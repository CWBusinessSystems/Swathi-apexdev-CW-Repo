/*Class Name: CWS_AccountTriggerHandler
*Description: Handler Class for Account Trigger
*Created By: Ankit
*Created On: 04/07/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                  04/07/2020      BED-5150                Default Account currency from billing country 
*Sudhir Moturu          4/29/2020       BED-1009                After Update method
*/

public  class CWS_AccountTriggerHandler implements CWS_ITriggerHandler {
    
    Public Static Boolean isTriggerDisabled=False;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_AccountTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_AccountTrigger__c|| isTriggerDisabled;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        CWS_AccountTriggerHelper.beforeInsertandUpdate(newItems,null);
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        CWS_AccountTriggerHelper.beforeInsertandUpdate(newItems.values(),oldItems);
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {    
        //Update opportunities if the account status is changed to non transactional review status
        CWS_AccountTriggerHelper.afterUpdate((Map<Id, Account>) newItems, (Map<Id, Account>) oldItems); 
    }
    
    /* Method for After Delete Event*/
    public void AfterDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Undelete Event*/
    public void AfterUndelete(Map<Id, SObject> newItems) {
    }
    
}