/*Class Name: CWS_ScheduleBatchNotifySalesRep
*Description: Schedule class for CWS_BatchNotifySalesRepAboutQuoteExpire
*Created By:Naresh
*Created On: 05/07/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Naresh              05/07/2020        BED-5267                 Initial version created 
*/

global without sharing class CWS_ScheduleBatchNotifySalesRep implements Schedulable { 
   global void execute(SchedulableContext sc) {
      Id batchInstanceId = Database.executeBatch(new CWS_BatchNotifySalesRepAboutQuoteExpire(), 50); 
      
      
   }
}