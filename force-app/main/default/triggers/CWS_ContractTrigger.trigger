/*Trigger Name: trigger CWS_ContractTrigger on Contract
*Description: Trigger on CPQ Contract

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*
*/
trigger CWS_ContractTrigger on Contract(before insert,after insert,before update,after update) {
    CWS_TriggerDispatcher.Run(new CWS_ContractTriggerHandler());
}