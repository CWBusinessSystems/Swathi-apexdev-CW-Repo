/*Class Name: CWS_DocusignEnvelopTrigger
*Description: Trigger Class for Docusign Envelope
*Created By: Akhila
*Created On: 15/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                  15/05/2020        BED-2916     Populate agreement status based on envelope status
*/

trigger CWS_DocusignEnvelopTrigger on Apttus_DocuApi__DocuSignEnvelope__c (before insert,after insert,before update,after update) {
    CWS_TriggerDispatcher.Run(new CWS_DocusignEnvelopHandler());
}