/*Class Name: CWS_ScheduleBatchAccountManagerTask
* @description: Scheduled class
*Created By: mahak bansal
*Created On:  2/4/2021 
*Ticket no :- 14528272 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*mahak bansal          2/4/2021            -                  Initial Version
*mahak bansal          5/4/2021            -                  updated 
*/
public without sharing class CWS_ScheduleBatchAccountManagerTask  implements System.Schedulable{
	/**
    * @description This method schedules the batch job
    */
    public void execute(SchedulableContext sc) {
      CWS_BatchAccountManagerTask batch = new CWS_BatchAccountManagerTask(); 
      Database.executebatch(batch);
   }
}