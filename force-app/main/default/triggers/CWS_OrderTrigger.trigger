/*Trigger Name: trigger CWS_OrderTrigger on Order
*Description: Trigger on Order
*Created By: swachatterjee@deloitte.com
*Created On: 04/0e/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*swachatterjee         04/03/2020           -                   Initial Version            
*
*/
trigger CWS_OrderTrigger on Order (before insert,after insert,before update,after update) {
    CWS_TriggerDispatcher.Run(new CWS_OrderTriggerHandler());
}