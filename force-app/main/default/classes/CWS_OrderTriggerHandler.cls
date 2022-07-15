/*Class Name: CWS_OrderTriggerHandler
* Description: Handler Class for Order Trigger
* Created By: Khayam
* Created On: 04/03/2020
* Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
* swachatterjee        04/03/2020          -                    Intial Version
* swachatterjee        04/06/2020       BED-1278               update BeforeInsert()
*/
public class CWS_OrderTriggerHandler implements CWS_ITriggerHandler {
    
    public static boolean BEFORE_INSERT_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;
    public static boolean AFTER_UPDATE_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;

    Public Static Boolean isTriggerDisabled=False;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_OrderTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_OrderTrigger__c|| isTriggerDisabled;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        Boolean isMigratedOrder = CWS_Trigger_Switch__c.getInstance().CWS_LegacyDataMigration__c;
        if(!BEFORE_INSERT_EXECUTED){
            if(isMigratedOrder){
                CWS_OrderTriggerHelper.beforeLegacyInsert(newItems);
            }else{
                CWS_OrderTriggerHelper.beforeInsert(newItems);
            }         
        } 
        if(!Test.isRunningTest()) {
            BEFORE_INSERT_EXECUTED = true;
        }
    }
    
    /* Method for Before Update Event*/
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Boolean isMigratedOrder = CWS_Trigger_Switch__c.getInstance().CWS_LegacyDataMigration__c;
        if(!BEFORE_UPDATE_EXECUTED){
            if(!isMigratedOrder){
                CWS_OrderTriggerHelper.beforeUpdate(newItems, oldItems);
            }
        } 
        if(!Test.isRunningTest()) {
            BEFORE_UPDATE_EXECUTED = true;
        }
    }
    
    /* Method for Before Delete Event*/
    public void BeforeDelete(Map<Id, SObject> oldItems) {
    }
    
    /* Method for After Insert Event*/
    public void AfterInsert(Map<Id, SObject> newItems) {
        Boolean isMigratedOrder = CWS_Trigger_Switch__c.getInstance().CWS_LegacyDataMigration__c;
        if(!AFTER_INSERT_EXECUTED){
            if(!isMigratedOrder){
                CWS_OrderTriggerHelper.afterInsert(newItems);
            }
        } 
        if(!Test.isRunningTest()) {
            AFTER_INSERT_EXECUTED = true;
        }
    }
    
    /* Method for After Update Event*/
    public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
        Boolean isMigratedOrder = CWS_Trigger_Switch__c.getInstance().CWS_LegacyDataMigration__c;
        if(!AFTER_UPDATE_EXECUTED){
            if(!isMigratedOrder){
                CWS_OrderTriggerHelper.afterUpdate(newItems, oldItems);
            }
        } 
        if(!Test.isRunningTest()) {
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