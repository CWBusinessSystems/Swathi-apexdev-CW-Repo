/*Trigger Name: trigger CWS_OpportunityTrigger on Opportunity
*Description: Trigger on Opportunity
*Created By: Nirmal
*Created On: 04/06/2020
*/
trigger CWS_OpportunityTrigger on Opportunity (before insert,before update,after update,after insert) {
    CWS_TriggerDispatcher.Run(new CWS_OpportunityTriggerHandler());
}