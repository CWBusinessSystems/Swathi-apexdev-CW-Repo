/*Trigger Name: CWS_ProductOptionTrigger
*Description: Trigger on Product option
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
Asutosh                 25.5.2020       10641                   Product Sync Logic
*/

trigger CWS_ProductOptionTrigger on SBQQ__ProductOption__c (after insert) {
    CWS_TriggerDispatcher.Run(new CWS_ProductOptionTriggerHandler());
}