/*Trigger Name: trigger CWS_QLITrigger on SBQQ__QuoteLine__c 
*Description: Trigger on QLI
*Created By: Ankit
*Created On: 10/20/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Ankit               10/20/2020           14002423            Nullify Legacy Keyon QLI
*
*/

trigger CWS_QLITrigger on SBQQ__QuoteLine__c (before insert,before update) {
    CWS_TriggerDispatcher.Run(new CWS_QLITriggerHandler());
}