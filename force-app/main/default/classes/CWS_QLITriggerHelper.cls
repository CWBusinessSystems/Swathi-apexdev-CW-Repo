/*Class Name: CWS_QLITriggerHelper
*Description: Helper Class for QLI Trigger
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
Ankit                 10.20.2020       14002423              Nullify Legacy Key from QLI
*/

Public with Sharing class CWS_QLITriggerHelper{

    Public static void beforeInsertandUpdate(List<SObject> newItems){
        List<SBQQ__QuoteLine__c> newList = (List<SBQQ__QuoteLine__c>) newItems;
        for(SBQQ__QuoteLine__c qli: newList){
            if(qli.isClone() && qli.CWS_LegacyKey__c != null){
                qli.CWS_LegacyKey__c = null;
            }
        }
    }
}