/*Trigger Name: CWS_SubscriptionTrigger
*Description: Trigger on SBQQ__Subscription__c Object
*Created By: Aakash Sharma
*Created On: 04/10/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Aakash Sharma            04/10/2020          BED-5894                ACV Roll-up on the Contract From the Subscription within that Contract.
*
*/
trigger CWS_SubscriptionTrigger on SBQQ__Subscription__c (before insert,after insert,before update,after update, before delete) {
    CWS_TriggerDispatcher.Run(new CWS_SubscriptionHandler());
}