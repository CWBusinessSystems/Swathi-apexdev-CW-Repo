/*Trigger Name: trigger CWS_ApprovalTrigger on Approval
*Description: Trigger on SBAA Approval
*Created By: Khayam
*Created On: 05/19/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Khayam                 5/19/2020       BED-8645            Account Restriction - Delinquency 
*/
trigger CWS_ApprovalTrigger on sbaa__Approval__c (after update,before insert) {
    CWS_TriggerDispatcher.Run(new CWS_ApprovalTriggerHandler());
}