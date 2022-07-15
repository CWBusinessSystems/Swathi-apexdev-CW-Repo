/*Trigger Name: trigger CWS_QuoteTrigger on Quote
*Description: Trigger on CPQ Quote
*Created By: Khayam
*Created On: 04/0e/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Khayam			       04/03/2020			BED-6326 			Opp Team Member Access to Quote 
*
*/
trigger CWS_QuoteTrigger on SBQQ__Quote__c (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
    CWS_TriggerDispatcher.Run(new CWS_QuoteTriggerHandler());
}