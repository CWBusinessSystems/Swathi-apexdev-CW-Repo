/*Class Name: CWS_BatchNotifySalesRepAboutQuoteExpire
*Description: Batch class to sent email notification to sales about quote expire
*Created By: Naresh Nunna
*Created On: 06/05/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Naresh Nunna        06/05/2020          Bed-5267             Initial version created
*
*/
global class CWS_BatchNotifySalesRepAboutQuoteExpire implements Database.Batchable<sObject>, Database.AllowsCallouts{
     public String queryString;
     public String Accepted = 'Accepted';
     public String Renewal = 'Renewal';
     public String Inactive = 'Inactive';
     public Date todayplus7=Date.today()+7;
     public Date todayMinus1=Date.today();
     
/*
Constructor initialization
*/
global Database.QueryLocator start(Database.BatchableContext BC) {
         String query = 'SELECT Id,OwnerId,Owner.Email, Name,CWS_Sales_Rep_Name__c, SBQQ__SalesRep__r.email,CWS_Reference_Expiry_Date__c,SBQQ__ExpirationDate__c,SBQQ__Status__c,CWS_Quote_Type__c FROM SBQQ__Quote__c WHERE SBQQ__Status__c != :Accepted AND SBQQ__Status__c != :Inactive AND (SBQQ__ExpirationDate__c =:todayMinus1 OR SBQQ__ExpirationDate__c =:todayplus7 )';
         return Database.getQueryLocator(query);
}

/*
* Method to Send emails for different criteria
*/
global void execute(Database.BatchableContext BC, list<SBQQ__Quote__c> lstQuote) {
        Set<Id> expireTodayPlus7 = new Set<Id>();
        Set<Id> expireTodayMinus1 = new Set<Id>();
        List<SBQQ__QuoteDocument__c> quoteDocumentList = new List<SBQQ__QuoteDocument__c>(); 
        List<SBQQ__QuoteDocument__c> qDocspluginList = new List<SBQQ__QuoteDocument__c>();
        String body;
        string subject;
        String body2;
        String subject2;
try{
  if(lstQuote.size()>0){
        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
       For(SBQQ__Quote__c qt : lstQuote){
            system.debug('checking record date '+qt.SBQQ__ExpirationDate__c);
           system.debug('checking record date '+Date.today());
           
     if(qt.SBQQ__ExpirationDate__c ==  Date.today()+7 && qt.CWS_Quote_Type__c!=CWS_ConstantClass.Quote_Type_Renewal){
         system.debug('entered 7 days loop');
             expireTodayPlus7.add(qt.id);
         body='Dear '+qt.CWS_Sales_Rep_Name__c+',\n\nYour quote :'+qt.Name + ' will expire in 7 days. Please modify the expiry date or create a clone and re-submit for approval.\n\n'+
     'Please don’t hesitate to reach out to Global SalesOps.Team@connectwise.com if you have any questions regarding this.\n\n'+
             'Sincerely,\n Global Sales Ops';
          subject='Quote is about to expire in 7 days';
             Messaging.SingleEmailMessage emailToexpireTodayPlus7 = new Messaging.SingleEmailMessage();
             emailToexpireTodayPlus7.setToAddresses(new String[] {qt.SBQQ__SalesRep__r.email});
             emailToexpireTodayPlus7.setSaveAsActivity(false);
             emailToexpireTodayPlus7.setTargetObjectId(qt.OwnerId);
             emailToexpireTodayPlus7.subject = subject;
             emailToexpireTodayPlus7.plainTextBody = body;
             if(expireTodayPlus7.size() > 0){
                 messageList.add(emailToexpireTodayPlus7);
                      system.debug('emailToexpireTodayPlus7 is sent Successfully.');
                     }
     }
     if(qt.SBQQ__ExpirationDate__c ==  Date.today() ){
         system.debug('entered today days loop');
             expireTodayMinus1.add(qt.id);
         if(qt.CWS_Quote_Type__c!=CWS_ConstantClass.Quote_Type_Renewal){
              body2 ='Dear '+qt.CWS_Sales_Rep_Name__c+',\n\nYour quote :'+qt.Name + ' has expired. Please modify the expiry date or create a clone and re-submit for approval.\n\n'+
         'Please don’t hesitate to reach out to Global SalesOps.Team@connectwise.com if you have any questions regarding this.\n\n'+
                 'Sincerely,\n Global Sales Ops';
              subject2 ='Quote expire notification';
                 Messaging.SingleEmailMessage emailToexpireTodayMinus1 = new Messaging.SingleEmailMessage();
                 emailToexpireTodayMinus1.setToAddresses(new String[] {qt.SBQQ__SalesRep__r.email});
                 emailToexpireTodayMinus1.setSaveAsActivity(false);
                 emailToexpireTodayMinus1.setTargetObjectId(qt.OwnerId);
                 emailToexpireTodayMinus1.subject = subject2;
                 emailToexpireTodayMinus1.plainTextBody = body2;
                 messageList.add(emailToexpireTodayMinus1);
                system.debug('emailToexpireTodayMinus1 is sent Successfully.');
          }
      }
   }
         
       if(expireTodayMinus1.size() > 0){
        quoteDocumentList = [Select Id, name, SBQQ__Quote__c,SBQQ__SignatureStatus__c, SBQQDS__EnvelopeId__c, SBQQDS__VoidedReason__c,
					(select id, title from AttachedContentDocuments ) From SBQQ__QuoteDocument__c Where (SBQQ__SignatureStatus__c = 'Sent' OR SBQQ__SignatureStatus__c = 'Pending' OR SBQQ__SignatureStatus__c = 'Delivered') AND SBQQ__Quote__c IN :expireTodayMinus1 ];
      } if(quoteDocumentList.size() > 0){
          for(SBQQ__QuoteDocument__c qtdoc : quoteDocumentList){
              if(qtdoc.AttachedContentDocuments.size() == 0){
              qtdoc.SBQQDS__VoidedReason__c=System.Label.CWS_Quote_expire_on_Quote_document;
              qDocspluginList.add(qtdoc);  
              } 
          }
          SBQQDS.DocuSignPlugin plugin = new SBQQDS.DocuSignPlugin();
                 plugin.revoke(qDocspluginList);
      }
        if(!messageList.isEmpty()){
             Messaging.sendEmail(messageList);
              system.debug('Email is sent Successfully.');
         }
                }
    
     }
     catch(Exception e){ 
         CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_BatchNotifySalesRepAboutQuoteExpire', 'Batch class to sent email notification to sales about quote expire' , '', null, null , 'CWS_BatchNotifySalesRepAboutQuoteExpire' , null);
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
         mail.setSubject('Batch class to sent email notification to sales about quote expire ' + a.Status);
         mail.setPlainTextBody
         ('Batch class to sent email notification to sales about quote expire ' + a.TotalJobItems +
         ' batches with '+ a.NumberOfErrors + ' failures.');
 try{
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
 }catch(Exception e){
     CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_BatchNotifySalesRepAboutQuoteExpire', 'Batch class to sent email notification to sales about quote expire' , '', null, null , 'CWS_BatchNotifySalesRepAboutQuoteExpire' , null);
  
 }
 }
}