/*Trigger Name: CWS_SSOAccountContactsUpdate
*Description: Trigger to send updated Account and Contact data to CW Home to create an SSO account
*Created By: Jeff Cochran
*Created On: 10/20/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Jeff Cochran 10/20/2020 N/A       Trigger to send updated Account and Contact data to CW Home to create an SSO account
*/
trigger CWS_CaseClosureUpdate on Case (after update) {
    //Trigger will run only after update of Case records
    if(Trigger.isAfter && Trigger.isUpdate) {
        //CaseClosureTriggerHandler Class will call method processClosedCases
        CWS_CaseClosureTriggerHandler.processClosedCases(trigger.new);
        CWS_CaseClosureTriggerHandler.gsEvent(trigger.new);
    }
}