/*Class Name: CWS_AgreementTrigger
*Description: Trigger for Agreement
*Created By: Akhila
*Created On: 30/04/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                  30/04/2020        BED-3087     Populate MSA/NDA/BAA agreement fields on Account
*/

trigger CWS_AgreementTrigger on Apttus__APTS_Agreement__c (before insert,after insert,before update,after update) {
    CWS_TriggerDispatcher.Run(new CWS_AgreementTriggerHandler());
}