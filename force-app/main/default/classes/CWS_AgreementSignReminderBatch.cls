/*Class Name: CWS_AgreementSignReminderBatch
*Description: Batch class to send email notification to Sales rep until the form is viewed by the customer 
*Created By: Akhila
*Created On: 20/05/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Akhila                 20/5/2020       BED-2970           Batch class to send mail to Sales rep if the agreement is not signed by customer for more than a day
*
*/

global class CWS_AgreementSignReminderBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    public String queryString;
    /*
    * start method returns the list of Agreements which requires reminder notification based on filter criteria
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String statusSent = System.Label.CWS_Sent;
        String query = 'SELECT Id, CreatedById,CWS_Sales_Rep__c,CWS_Sales_Rep__r.Email, CWS_Envelope_SentDate__c,Apttus__Account__c,Apttus__Account__r.Name,CWS_No_Of_Days_Passed_From_Envelope_Sent__c, CWS_EnvelopeStatus__c, Owner.Email, OwnerId, Name,Apttus__Other_Party_Signed_By__c,Apttus__Other_Party_Signed_By__r.Name, Owner.Name FROM Apttus__APTS_Agreement__c WHERE CWS_EnvelopeStatus__c =:statusSent AND CWS_No_Of_Days_Passed_From_Envelope_Sent__c > 1';
        return Database.getQueryLocator(query);
    }

    /*
    * This method sends the Reminder Notification to Sales rep
    */
    global void execute(Database.BatchableContext BC, list<Apttus__APTS_Agreement__c> agreementLst) {      
       
        String body;
        string subject;
        EmailTemplate emailTemplate = [Select Id from EmailTemplate where name = 'Agreement Pending Signature Reminder' limit 1];
        
        try{
            if(agreementLst.size()>0){
                List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
                For(Apttus__APTS_Agreement__c agreementRec : agreementLst){
                    Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
                   /* body='Hello '+ agreementRec.CWS_Sales_Rep__r.Name +',\n\nThis is to remind that you have an agreement document pending to be Signed.\n'+
                        'Agreement Name: '+ agreementRec.Name +
                        '\nAccount Name: '+ agreementRec.Apttus__Account__r.Name + 
                        '\nOther Party Signature by: '+agreementRec.Apttus__Other_Party_Signed_By__r.Name+
                        '\nPlease reach out to us at SalesOps.Team@connectwise.com in case of Queries\n\n'+
                        'Sincerely,\nGlobal Sales Ops';
                    subject='You have an unopened Agreement to be Signed - '+ agreementRec.Name;*/
                    emailMsg.setTargetObjectId(agreementRec.ownerId);
                    emailMsg.setTreatTargetObjectAsRecipient(false);
                    emailMsg.setTemplateID(emailTemplate.Id);
                    emailMsg.setToAddresses(new String[] {agreementRec.CWS_Sales_Rep__r.Email});
                    emailMsg.setSaveAsActivity(false);
                    emailMsg.setWhatId(agreementRec.Id);                    
                   // emailMsg.subject = subject;
                  //  emailMsg.plainTextBody = body;

                    messageList.add(emailMsg);
                }   
                if(!messageList.isEmpty()){
                    Messaging.sendEmail(messageList);
                    system.debug('Email is sent Successfully.');
                } 
            }           
            
        }catch(Exception e){ 
            CWS_ExceptionHandler.logException( e,'Apttus__APTS_Agreement__c' , 'CWS_AgreementSignReminderBatch', 'Batch class to send Reminder notification to Sales rep for Agreements Awaiting Signature' , '', null, null , 'CWS_AgreementSignReminderBatch' , null);
        }
    }
     global void finish(Database.BatchableContext BC) {}
 
}