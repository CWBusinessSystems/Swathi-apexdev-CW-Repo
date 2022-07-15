/*Class Name: CWS_ProductTrigger
*Created By: Ankit
*Created On: 08/18/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                 08/18/2020      Initial version     Default Precision Measure based on UOM
*/
trigger CWS_ProductTrigger on Product2(before insert,before update) 
{
    CWS_TriggerDispatcher.Run(new CWS_ProductTriggerHandler());
}