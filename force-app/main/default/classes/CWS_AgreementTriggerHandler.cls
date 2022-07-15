/*Class Name: CWS_AgreementTriggerHandler
*Description: Handler Class for Agreement Trigger
*Created By: Akhila
*Created On: 30/04/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                  30/04/2020        BED-3087     Populate MSA/NDA/BAA agreement fields on Account
*Akhila					 05/05/2020		   BED-2880		Update status to In authoring on document generation
*/

public class CWS_AgreementTriggerHandler implements CWS_ITriggerHandler{
    Public Static Boolean isTriggerDisabled=False;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_AgreementTrigger would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_AgreementTrigger__c|| isTriggerDisabled;
    }
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        CWS_AgreementTriggerHelper.beforeInsert((List<Apttus__APTS_Agreement__c>) newItems);
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        CWS_AgreementTriggerHelper.beforeUpdate((Map<Id, Apttus__APTS_Agreement__c>) newItems, (Map<Id, Apttus__APTS_Agreement__c>) oldItems);
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
        CWS_AgreementTriggerHelper.afterInsert(newItems);
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) { 
        CWS_AgreementTriggerHelper.afterUpdate((Map<Id, Apttus__APTS_Agreement__c>) newItems, (Map<Id, Apttus__APTS_Agreement__c>) oldItems);
    }
    
    /* Method for After Delete Event*/
    public void AfterDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Undelete Event*/
    public void AfterUndelete(Map<Id, SObject> newItems) {
    }    
}