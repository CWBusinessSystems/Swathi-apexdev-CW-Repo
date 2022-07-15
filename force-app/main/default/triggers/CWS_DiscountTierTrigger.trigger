/*Trigger Name: CWS_DiscountTierTrigger
*Description: Trigger on Discount Tier
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
Asutosh                 25.5.2020       10641                   Product Sync Logic
*/

trigger CWS_DiscountTierTrigger on SBQQ__DiscountTier__c (after insert, after update) 
{
 CWS_TriggerDispatcher.run(new CWS_DiscountTierTriggerHandler());
}