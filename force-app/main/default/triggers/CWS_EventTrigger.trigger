/*Trigger Name: trigger CWS_EventTrigger on Event
*Description: Trigger on Event
*Created By: Manoj
*Created On: 05/05/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Manoj               05/05/2020          BED-7889               Prevent deletion of Event by Restricted profiles
*
*/
trigger CWS_EventTrigger on Event (before delete, before insert) {
     CWS_TriggerDispatcher.Run(new CWS_EventTriggerHandler()); 
}