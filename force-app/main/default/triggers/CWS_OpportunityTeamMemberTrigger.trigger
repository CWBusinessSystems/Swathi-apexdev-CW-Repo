/*Trigger Name: trigger CWS_OpportunityTeamMemberTrigger on OpportunityTeamMember
*Description: Trigger on OpportunityTeamMember
*Created By: Khayam
*Created On: 04/01/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Khayam			       04/01/2020			BED-6326 			Opp Team Member Access to Quote 
*
*/
trigger CWS_OpportunityTeamMemberTrigger on OpportunityTeamMember (after insert,after delete) {
    
    CWS_TriggerDispatcher.Run(new CWS_OpportunityTeamMemberTriggerHandler());

}