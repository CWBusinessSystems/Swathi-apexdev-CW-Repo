/*Class Name: CWS_ContentDocumentHandler
*Description: Handler for CWS_ContentDocumentTrigger
*Created By: Akhila
*Created On: 23/07/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                 23/07/2020        BED-3096     			Update Agreement when signed document is deleted
*/

public class CWS_ContentDocumentHandler implements CWS_ITriggerHandler{
	Public Static Boolean isTriggerDisabled=False;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_DocusignEnvelopTrigger would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_ContentDocumentTrigger__c|| isTriggerDisabled;
    }
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        CWS_ContentDocumentHelper.beforeDelete((Map<Id,ContentDocument>) oldItems);
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
        //CWS_ContentDocumentLinkHelper.afterInsert((Map<Id, ContentDocumentLink>) newItems);
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