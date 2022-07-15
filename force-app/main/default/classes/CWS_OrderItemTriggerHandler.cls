/*Class Name: CWS_OrderItemTriggerHandler
* Description: Handler Class for OrderItem Trigger
* Created By: Khayam
* Created On: 04/03/2020
* Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
* swachatterjee        04/13/2020          -                    Intial Version
* swachatterjee        04/13/2020       BED-1287               update BeforeInsert()
* Vaishnavi            6/9/2020         BED-11017               update AfterUpdate(),AfterUpdate(),AfterDelete
*/
public class CWS_OrderItemTriggerHandler implements CWS_ITriggerHandler {
    
    public static boolean BEFORE_INSERT_EXECUTED = false;
    public static boolean BEFORE_UPDATE_EXECUTED = false;
    public static boolean AFTER_INSERT_EXECUTED = false;
    public static boolean AFTER_UPDATE_EXECUTED = false;
    public static boolean AFTER_DELETE_EXECUTED = false;
    
    Public Static Boolean isTriggerDisabled=False;
    /*Checks to see if the trigger has been disabled either by custom setting or by running code*/
    public Boolean IsDisabled(){
        //CWS_OrderTrigger__c would be set to false to disable the trigger
        return !CWS_Trigger_Switch__c.getInstance().CWS_OrderItemTrigger__c|| isTriggerDisabled;
    }
    
    /* Method for Before Insert Event*/ 
    public void BeforeInsert(List<SObject> newItems){
        Boolean isMigratedOrder = CWS_Trigger_Switch__c.getInstance().CWS_LegacyDataMigration__c;
        if(!BEFORE_INSERT_EXECUTED){
            if(isMigratedOrder){
                CWS_OrderItemTriggerHelper.beforeLegacyInsert(newItems);
            }else{
                CWS_OrderItemTriggerHelper.beforeInsert(newItems);
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
                CWS_OrderItemTriggerHelper.beforeUpdate(newItems, oldItems);
            }
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
        Boolean isMigratedOrder = CWS_Trigger_Switch__c.getInstance().CWS_LegacyDataMigration__c;
        if(!AFTER_INSERT_EXECUTED){
            if(!isMigratedOrder){
                CWS_OrderItemTriggerHelper.afterInsert(newItems);
            }         
        } 
        if(!Test.isRunningTest()) {
            AFTER_INSERT_EXECUTED = true;
        }
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