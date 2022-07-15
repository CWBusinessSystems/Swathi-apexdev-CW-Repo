/*Class Name: CWS_RenewalFlexQueueSchedulable
*Description: To schedule the batch class for flexqueue error for renewal order records
*Created By: mahak bansal
*Created On:  12/2/2021 
*Ticket no :- 14276942 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*mahak bansal          12/2/2021            -                  Initial Version
*mahak bansal          24/2/2021            -                  updated , Logic of aborting self is added.
*/
public class CWS_RenewalFlexQueueSchedulable implements Schedulable {
	public void execute(SchedulableContext sc) {
      CWS_ProcessFlexQueueExcRecords batch = new CWS_ProcessFlexQueueExcRecords(); 
      Database.executebatch(batch);
        //Abort self post completion
      System.abortJob(sc.getTriggerId());
   }
}