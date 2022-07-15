/*Class Name: CWS_DocusignEnvelopHandler
*Description: Handler Class for CWS_DocusignEnvelopTrigger
*Created By: Akhila
*Created On: 15/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                  15/05/2020        BED-2916     Populate agreement status based on envelope status
*/

public class CWS_DocusignEnvelopHandler implements CWS_ITriggerHandler{
	Public Static Boolean isTriggerDisabled=False;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_DocusignEnvelopTrigger would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_DocusignEnvelopTrigger__c|| isTriggerDisabled;
    }
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) { 
        CWS_DocusignEnvelopHelper.afterUpdate((Map<Id, Apttus_DocuApi__DocuSignEnvelope__c>) newItems, (Map<Id, Apttus_DocuApi__DocuSignEnvelope__c>) oldItems);
    }
    
    /* Method for After Delete Event*/
    public void AfterDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Undelete Event*/
    public void AfterUndelete(Map<Id, SObject> newItems) {
    }    
}