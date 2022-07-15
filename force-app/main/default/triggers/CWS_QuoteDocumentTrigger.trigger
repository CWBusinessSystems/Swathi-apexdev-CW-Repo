/*Trigger Name: trigger CWS_QuoteTrigger on Quote
*Description: Trigger on CPQ Quote
*Created By: Khayam
*Created On: 04/13/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Khayam			       04/13/2020			BED-5213 			Quote Stage sync with Quote Documents
*
*/
trigger CWS_QuoteDocumentTrigger on SBQQ__QuoteDocument__c (before insert, after insert, before update, after update) {
    CWS_TriggerDispatcher.Run(new CWS_QuoteDocumentTriggerHandler());
}