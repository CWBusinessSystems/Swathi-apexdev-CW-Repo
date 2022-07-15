/*Trigger Name: trigger CWS_OpportunityLineItemTrigger on OpportunityLineItem
*Description: Trigger on OpportunityLineItem
*Created By: Aditya
*Created On: 05/19/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Aditya             05/19/2020          BED-8552/226         Default Pricing fields from Product
*
*/
trigger CWS_OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, after insert,after update) {
    CWS_TriggerDispatcher.Run(new CWS_OpportunityLineItemTriggerHandler());
}