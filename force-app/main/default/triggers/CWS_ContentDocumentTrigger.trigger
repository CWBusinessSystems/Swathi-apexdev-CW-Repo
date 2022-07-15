/*Class Name: CWS_ContentDocumentTrigger
*Description: Trigger for ContentDocument object
*Created By: Akhila
*Created On: 23/07/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Akhila                  23/07/2020        BED-3096     		Update Agreement when signed document is deleted
*/

trigger CWS_ContentDocumentTrigger on ContentDocument (before insert,after insert,before update,after update,before delete, after delete) {
    CWS_TriggerDispatcher.Run(new CWS_ContentDocumentHandler());
}