/*Class Name: CWS_ContentDocumentLinkTrigger
*Description: Trigger for ContentDocumentLink object
*Created By: Esha
*Created On: 29/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Esha                  29/05/2020        BED-3096     Attach signed agreement document to respective account and quote
*/

trigger CWS_ContentDocumentLinkTrigger on ContentDocumentLink (before insert,after insert,before update,after update) {
    CWS_TriggerDispatcher.Run(new CWS_ContentDocumentLinkHandler());
}