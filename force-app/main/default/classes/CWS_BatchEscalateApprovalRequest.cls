/*Class Name: CWS_BatchEscalateApprovalRequest
*Description: Batch class to esclate approval requestes that are waiting from 3 days
*Created By: Naresh Nunna
*Created On: 07/07/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Naresh Nunna        07/07/2020          Bed-3438             Initial version created
*
*/
global class CWS_BatchEscalateApprovalRequest implements Database.Batchable<sObject>, Database.AllowsCallouts{
     public String Requested = 'Requested';
     public Date todayMinus3=Date.today();
     List<SBQQ__Quote__c> quot = New List<SBQQ__Quote__c>();
             
/*
Constructor initialization
*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
         String query = 'SELECT Id,CWS_Notify_Higher_level_after_3_days__c ,Name,sbaa__Status__c,CWS_Quote__c,CWS_Quote__r.SBQQ__Status__c,CWS_Quote__r.CWS_Delivery_Date__c,CWS_Quote__r.CWS_Approval_Requested_Date__c FROM sbaa__Approval__c WHERE sbaa__Status__c =: Requested  AND CWS_Quote__c != null AND CWS_Notify_Higher_level_after_3_days__c = True';
        return Database.getQueryLocator(query);
        // 
	}
    /*
* Method to Send emails for different criteria
*/
	global void execute(Database.BatchableContext BC, list<sbaa__Approval__c> approvalLst) {
        try{
             system.debug('todayMinus3 '+todayMinus3);
            if(approvalLst.size()>0 ){
                system.debug('approvalLst '+approvalLst.size());
                for(sbaa__Approval__c app:approvalLst ){
                     system.debug('approvalLst Quote ID'+app.CWS_Quote__r);
                    if(app.CWS_Quote__r.CWS_Approval_Requested_Date__c == app.CWS_Quote__r.CWS_Delivery_Date__c && app.CWS_Quote__r.SBQQ__Status__c =='In Review'){
                        
                       // qList.add(app.CWS_Quote__c);
                        quot.add(app.CWS_Quote__r);
                    }
                    
                }
            }
            if(quot.size()>0){
                for(SBQQ__Quote__c q:quot){
                    system.debug('Entered for loop');
                  SBAA.ApprovalAPI.submit(q.id, SBAA__Approval__c.CWS_Quote__c);  
                }
                 
                // CWS_SubmitQuoteForApproval.submitForApproval(quot);
            }
        } catch(Exception e){ 
         CWS_ExceptionHandler.logException( e,'sbaa__Approval__c' , 'CWS_BatchEscalateApprovalRequest', 'Batch class to esclate approval requestes that are waiting from 3 days' , '', null, null , 'CWS_BatchEscalateApprovalRequest' , null);
     }
    }
    
    /*
 * Finish method of batch
 */
 global void finish(Database.BatchableContext BC) {
     
      AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
    TotalJobItems, CreatedBy.Email
    FROM AsyncApexJob WHERE Id =
    :BC.getJobId()];
 // OPTIONAL: Send an email to the Apex job's submitter notifying of job completion.
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String[] toAddresses = new String[] {a.CreatedBy.Email};
         mail.setToAddresses(toAddresses);
         mail.setSubject('Batch class to escalate approval request raised before 3 days ' + a.Status);
         mail.setPlainTextBody
         ('Batch class to escalate approval request raised before 3 days ' + a.TotalJobItems +
         ' batches with '+ a.NumberOfErrors + ' failures.');
 try{
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
 }catch(Exception e){
      CWS_ExceptionHandler.logException( e,'sbaa__Approval__c' , 'CWS_BatchEscalateApprovalRequest', 'Batch class to esclate approval requestes that are waiting from 3 days' , '', null, null , 'CWS_BatchEscalateApprovalRequest' , null);
     }
 }
  
}