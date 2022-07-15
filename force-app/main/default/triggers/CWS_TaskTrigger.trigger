/*Trigger Name: trigger CWS_TaskTrigger on Task
*Description: Trigger on Task
*Created By: Manoj
*Created On: 05/05/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Manoj               05/05/2020          BED-7889               Prevent deletion of task        
*
*/
trigger CWS_TaskTrigger on Task (before delete, before insert, after Update, before update) {
    CWS_TriggerDispatcher.Run(new CWS_TaskTriggerHandler()); 
}