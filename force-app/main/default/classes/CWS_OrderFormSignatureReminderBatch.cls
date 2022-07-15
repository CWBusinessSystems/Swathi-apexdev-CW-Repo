/*Class Name: CWS_OrderFormSignatureReminderBatch
*Description: Batch class to send email notification to Sales Rep until the form is viewed by the customer 
*Created By: Indra Ganesan
*Created On: 15/05/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Indra Ganesan      15/5/2020           BED-3767           Initial version created
*
*/
global class CWS_OrderFormSignatureReminderBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    public String queryString;
    /*
    * start method returns the list of Quote Documents which requires reminder notification based on filter criteria
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String statusSent = System.Label.CWS_Sent;
        String query = 'SELECT Id, CreatedById, CWS_Envelope_Sent_Date__c, CWS_No_Of_Days_Passed_From_Envelope_Sent__c, SBQQ__SignatureStatus__c, SBQQ__Quote__r.Owner.Email, SBQQ__Quote__r.Owner.Id, Name, SBQQ__Quote__r.Owner.Name FROM SBQQ__QuoteDocument__c WHERE SBQQ__SignatureStatus__c =:statusSent AND CWS_No_Of_Days_Passed_From_Envelope_Sent__c > 1';
        return Database.getQueryLocator(query);
    }

    /*
    * This method sends the Reminder Notification to the Sales Rep
    */
    global void execute(Database.BatchableContext BC, list<SBQQ__QuoteDocument__c> lstQtDoc) {      
       
        String body;
        string subject;
        
        try{
            if(lstQtDoc.size()>0){
                List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
                For(SBQQ__QuoteDocument__c doc : lstQtDoc){
                    system.debug('loop through Quote Document..');  
                    body='Dear '+ doc.SBQQ__Quote__r.Owner.Name +',\n\nThis is to remind that you have a Quote Document - '+ doc.Name +' pending to be Signed.'+
                         'Please reach out to us at SalesOps.Team@connectwise.com in case of Queries\n\n'+
                         'Sincerely,\nGlobal Sales Ops';
                    subject='You have an unopened Quote to be Signed - '+ doc.Name;
                    emailMsg.setToAddresses(new String[] {doc.SBQQ__Quote__r.Owner.Email});
                    emailMsg.setSaveAsActivity(false);
                    emailMsg.setTargetObjectId(doc.CreatedById);
                    emailMsg.subject = subject;
                    emailMsg.plainTextBody = body;
                    messageList.add(emailMsg);
                }   
                if(!messageList.isEmpty()){
                    Messaging.sendEmail(messageList);
                    system.debug('Email is sent Successfully.');
                } 
            }           
            
        }catch(Exception e){ 
            CWS_ExceptionHandler.logException( e,'SBQQ__QuoteDocument__c' , 'CWS_OrderFormSignatureReminderBatch', 'Batch class to send Reminder notification to Sales Rep for documents Awaiting Signature' , '', null, null , 'CWS_OrderFormSignatureReminderBatch' , null);
        }
    }
     global void finish(Database.BatchableContext BC) {}
 
 }