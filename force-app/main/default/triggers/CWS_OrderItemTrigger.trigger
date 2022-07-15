/*Trigger Name: trigger CWS_OrderItemTrigger on Order
*Description: Trigger on Order Item
*Created By: swachatterjee@deloitte.com
*Created On: 04/13/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*swachatterjee         04/13/2020           -                   Initial Version            
*
*/
trigger CWS_OrderItemTrigger on OrderItem (before insert,before update,after insert) {
    CWS_TriggerDispatcher.Run(new CWS_OrderItemTriggerHandler());
}