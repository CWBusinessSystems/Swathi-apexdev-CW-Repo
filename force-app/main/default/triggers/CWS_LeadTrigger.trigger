/*Trigger Name: trigger CWS_LeadTrigger on Lead
*Description: Trigger on Lead
*Created By: Ankit
*Created On: 04/15/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Ankit               04/05/2020          BED-667        Default Campaign  on Sales generated Lead
*
*/
trigger CWS_LeadTrigger on Lead (before insert,after insert,before update) {
    CWS_TriggerDispatcher.Run(new CWS_LeadTriggerHandler());
}