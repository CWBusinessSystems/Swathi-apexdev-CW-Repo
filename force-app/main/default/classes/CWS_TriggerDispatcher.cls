/*Class Name: CWS_TriggerDispatcher
*Description: Trigger Dispacther to route the request to appropriate trigger handler
*Created On: 03/09/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Deloitte            03/09/2020                            Initial version created                                                                         
*
*/
public class CWS_TriggerDispatcher {
    
    /*
    Description: Dispatcher method to call appropriate handler for Trigger
    */
    public static void Run(CWS_ITriggerHandler handler) {
    
        // Check to see if the trigger has been disabled. If it has, return
        if (handler.IsDisabled())
            return;
             
 
        // Before trigger logic
        if (Trigger.IsBefore )
        {
            if (Trigger.IsInsert)
                handler.BeforeInsert(trigger.new);
 
            if (Trigger.IsUpdate)
                handler.BeforeUpdate(trigger.newMap, trigger.oldMap);
 
            if (Trigger.IsDelete)
                handler.BeforeDelete(trigger.oldMap);
        }
         
        // After trigger logic
        if (Trigger.IsAfter)
        {
            if (Trigger.IsInsert)
                handler.AfterInsert(Trigger.newMap);
 
            if (Trigger.IsUpdate)
                handler.AfterUpdate(trigger.newMap, trigger.oldMap);
 
            if (trigger.IsDelete)
                handler.AfterDelete(trigger.oldMap);
 
            if (trigger.isUndelete)
                handler.AfterUndelete(trigger.newMap);
        }
    }
}