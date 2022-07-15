/**
* Description  : Renewal Notification Batch : 75 days 
* User Story   : Service Ticket #14292767 
**/ 

public class CWS_75daysRenewalReminderEmailsBatch implements Database.Batchable<sObject>, Database.stateful {    
    public Map<String,EmailTemplate> emailTemplateMap;
    public List<CWS_Error_Log__c> errRecsToInsert = new List<CWS_Error_Log__c>();
    public String headerValue = 'Contract Id, Error Message \n';
    public string csvBody = '';
    public String finalCsv = '';
        
    public CWS_75daysRenewalReminderEmailsBatch(){
        Set<String> emailTemplateNames = new Set<String>{'CWS_CW_75_Day_Communication_Auto_renew',
                                                         'CWS_Continuum_75_Day_Comm_Auto_renew','CWS_CMS_CW_75_Day_Reminder_Opt_In'};
            emailTemplateMap = new Map<String,EmailTemplate>();
        for(EmailTemplate et : [SELECT Id, Name, DeveloperName, Markup FROM EmailTemplate where developername IN: emailTemplateNames]){
            emailTemplateMap.put(et.DeveloperName,et);
        }
    }    
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String queryString = ' SELECT Id , endDate'
            + ',SBQQ__RenewalForecast__c '
            + ',SBQQ__RenewalQuoted__c '
            + ',SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__r.email '
            + ',SBQQ__RenewalOpportunity__c '
            + ',SBQQ__RenewalOpportunity__r.Type '
            + ',SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__c '
            + ',SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c '
            + ',SBQQ__RenewalOpportunity__r.CreatedDate '
            + ',SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.CreatedDate '
            + ',CWS_Days_Remaining__c '
            + ',SBQQ__Quote__c '
            + ',CWS_Route_to_Market__c '
            + ',CWS_Renewal_Category__c '
            + ',CWS_Bill_To_Contact__c '
            + ',CWS_Bill_To_Account__c '
            + ',CWS_Bill_To_Account__r.CWS_Additional_Emails_for_Invoice__c '
            + ',SBQQ__Opportunity__c '
            + ',SBQQ__Opportunity__r.Type '
            + ',SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c '
            + ',SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.CWS_Days_Remaining__c '
            + ',SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.SBQQ__ExpirationDate__c '
            + ',CWS_75_Days_Sent__c'
            + ', (SELECT id, CWS_Product_Source__c, SBQQ__Product__r.CWS_Source__c FROM SBQQ__Subscriptions__r)'
            + ' FROM '
            + ' Contract '
            + ' WHERE '
            + ' CWS_Days_Remaining__c='+ Label.CWS_75_Days_Renewal
            + ' AND CWS_75_Days_Sent__c = false'
            + ' AND EndDate >=TODAY '
            + ' AND SBQQ__RenewalForecast__c = true '
            + ' AND CWS_Cancelled__c = false '
            + ' AND CWS_Renewal_Type__c != \'Non-Renewable\''
            + ' AND SBQQ__RenewalOpportunity__c !=null '
            + ' AND SBQQ__RenewalOpportunity__r.StageName!=\''+ CWS_ConstantClass.OpportunityClosedLose_Stage +'\' '
            + ' AND SBQQ__RenewalOpportunity__r.StageName!=\''+ CWS_ConstantClass.OpportunityClosedWon_Stage  +'\' '
            + ' AND (CWS_Master__c=TRUE OR (CWS_Master__c=FALSE AND SBQQ__RenewalOpportunity__r.CWS_On_Hold__c=FALSE ))'
            + ' AND (CWS_Renewal_Category__c = \'Opt-Out\' OR CWS_Renewal_Category__c = \'Opt-In\')';
        
        if(!Label.CWS_75_Days_Renewal_Batch_Switch.equalsIgnoreCase('ON')){ // to terminate the batch processing, change the label to any value other than 'on'
            queryString = queryString +  ' Limit 0';
        }
        
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<Contract> contracts){
        List<Contract> contractsToUpdate = new List<Contract>();
        List<Messaging.SingleEmailMessage> seventyFiveDaysNotificationEmails = new List<Messaging.SingleEmailMessage>();
        SBQQ__Subscription__c subscriptionTempInstance;
        Map<Id,Id> mapOfCPrimaryQuoteandDocumentId = new Map<Id,Id>();
        Set<Id> renewalOpportunityIds = new Set<Id>();
        
        for(Contract con : contracts){
            renewalOpportunityIds.add(con.SBQQ__RenewalOpportunity__c);
        }
        
        for(Contract con : contracts){
            Messaging.SingleEmailMessage tempInstance = new Messaging.SingleEmailMessage();
            List<String> additionalEmailIdsTempList = new List<String>();
            List<Id> tempDocIds = new List<Id>();
            if(String.isNotBlank(con.CWS_Bill_To_Account__r.CWS_Additional_Emails_for_Invoice__c)){
                if(con.CWS_Bill_To_Account__r.CWS_Additional_Emails_for_Invoice__c.contains(',')){
                    additionalEmailIdsTempList = con.CWS_Bill_To_Account__r.CWS_Additional_Emails_for_Invoice__c.split(',');
                }
                else{
                    additionalEmailIdsTempList.add(con.CWS_Bill_To_Account__r.CWS_Additional_Emails_for_Invoice__c);
                }
            }
            
            if(con.SBQQ__Subscriptions__r.size() > 0){
                subscriptionTempInstance = new SBQQ__Subscription__c();
                subscriptionTempInstance = con.SBQQ__Subscriptions__r[0];
            }
            
            if(String.isNotBlank(con.SBQQ__RenewalOpportunity__r.Type) 
               && (con.SBQQ__RenewalOpportunity__r.Type == CWS_ConstantClass.Opportunity_Type_Renewal || con.SBQQ__RenewalOpportunity__r.Type == CWS_ConstantClass.Opportunity_Type_RenewalWithChange)
               && subscriptionTempInstance != null
               && subscriptionTempInstance.SBQQ__Product__r.CWS_Source__c == CWS_ConstantClass.PRODUCT_SOURCE_CMS
               && emailTemplateMap.containsKey('CWS_Continuum_75_Day_Comm_Auto_renew')
               && con.CWS_Renewal_Category__c == 'Opt-Out'){
                   
                   tempInstance = createEmailMessage(emailTemplateMap.get('CWS_Continuum_75_Day_Comm_Auto_renew').Id,con,additionalEmailIdsTempList,null);//tempInstance = (emailTemplateMap.get('CWS_Continuum_75_Day_Comm_Auto_renew').Markup.containsIgnoreCase('attached Order Form') ? createEmailMessage(emailTemplateMap.get('CWS_Continuum_75_Day_Comm_Auto_renew').Id,con,additionalEmailIdsTempList,tempDocIds) : createEmailMessage(emailTemplateMap.get('CWS_Continuum_75_Day_Comm_Auto_renew').Id,con,additionalEmailIdsTempList,null));
                   seventyFiveDaysNotificationEmails.add(tempInstance);
                   con.CWS_75_Days_Sent__c = true;
                   contractsToUpdate.add(con);
               }
            else if(String.isNotBlank(con.SBQQ__RenewalOpportunity__r.Type) 
                   && (con.SBQQ__RenewalOpportunity__r.Type == CWS_ConstantClass.Opportunity_Type_Renewal || con.SBQQ__RenewalOpportunity__r.Type == CWS_ConstantClass.Opportunity_Type_RenewalWithChange)
                   && subscriptionTempInstance != null
                   && subscriptionTempInstance.SBQQ__Product__r.CWS_Source__c == CWS_ConstantClass.PRODUCT_SOURCE_CW
                   && emailTemplateMap.containsKey('CWS_CW_75_Day_Communication_Auto_renew')
                   && con.CWS_Renewal_Category__c == 'Opt-Out'){
                       
                        tempInstance = createEmailMessage(emailTemplateMap.get('CWS_CW_75_Day_Communication_Auto_renew').Id,con,additionalEmailIdsTempList,null);//(emailTemplateMap.get('CWS_CW_75_Day_Communication_Auto_renew').Markup.containsIgnoreCase('attached Order Form') ? createEmailMessage(emailTemplateMap.get('CWS_CW_75_Day_Communication_Auto_renew').Id,con,additionalEmailIdsTempList,tempDocIds) : createEmailMessage(emailTemplateMap.get('CWS_CW_75_Day_Communication_Auto_renew').Id,con,additionalEmailIdsTempList,null));
                        seventyFiveDaysNotificationEmails.add(tempInstance);
                        con.CWS_75_Days_Sent__c = true;
                        contractsToUpdate.add(con);
                    }
            else if(String.isNotBlank(con.SBQQ__RenewalOpportunity__r.Type) 
                   && (con.SBQQ__RenewalOpportunity__r.Type == CWS_ConstantClass.Opportunity_Type_RenewalWithChange)
                   && subscriptionTempInstance != null
                   && (subscriptionTempInstance.SBQQ__Product__r.CWS_Source__c == CWS_ConstantClass.PRODUCT_SOURCE_CW)
                   && emailTemplateMap.containsKey('CWS_CMS_CW_75_Day_Reminder_Opt_In')
                   && con.CWS_Renewal_Category__c == 'Opt-In'){
                       
                        tempInstance = createEmailMessage(emailTemplateMap.get('CWS_CMS_CW_75_Day_Reminder_Opt_In').Id,con,additionalEmailIdsTempList,null);//(emailTemplateMap.get('CWS_CMS_CW_75_Day_Reminder_Opt_In').Markup.containsIgnoreCase('attached Order Form') ? createEmailMessage(emailTemplateMap.get('CWS_CMS_CW_75_Day_Reminder_Opt_In').Id,con,additionalEmailIdsTempList,tempDocIds) : createEmailMessage(emailTemplateMap.get('CWS_CMS_CW_75_Day_Reminder_Opt_In').Id,con,additionalEmailIdsTempList,null));
                        seventyFiveDaysNotificationEmails.add(tempInstance);
                        con.CWS_75_Days_Sent__c = true;
                        contractsToUpdate.add(con);
                    }
        }//End of scope for loop
        if(seventyFiveDaysNotificationEmails.size() > 0){
            //Messaging.sendEmail(seventyFiveDaysNotificationEmails);
            Messaging.SendEmailResult[] emailResult = Messaging.sendEmail(seventyFiveDaysNotificationEmails, false);
            Database.saveResult[] srList = Database.update(contractsToUpdate,false);
            if(srList != null && !srList.isEmpty()){
                String errorString = '';
                for(Integer index = 0 ; index < srList.size() ; index ++){
                    if(!srList[index].isSuccess()){
                        csvBody += contractsToUpdate.get( index ).Id + ',';                        
                        string errorMsg = '';
                        for(Database.Error error : srList[index].getErrors()){
                            errorMsg += error.getMessage() + ',';
                        }
                        errorMsg = errorMsg.removeEnd(',');
                        csvBody += '"'+errorMsg + '"' + ','; 
                        csvBody += '\n';
                        buildErrorRecord(errorMsg,contractsToUpdate.get( index ).Id);
                    }
                }
                
                if(csvBody != null && csvBody != ''){
                    finalCsv = headerValue + csvBody;
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        if( finalCsv != null && finalCsv != ''){
            Set<Id> toUserSet = new Set<Id>();
            for(GroupMember groupMembers : [SELECT UserOrGroupId, GroupId, Id FROM GroupMember WHERE group.DeveloperName ='CWS_75_days_renewal_notification']){
                toUserSet.add(groupMembers.UserOrGroupId);
            }
            list<string> toAddresses = new list<string>();
            for(User userRecord : [SELECT id, Email FROM User WHERE Id IN: toUserSet]){
                toAddresses.add(userRecord.Email);
            }
            String csvname= 'Contract_Update_Errors.csv';
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            csvAttc.setFileName(csvname);
            csvAttc.setBody(Blob.valueOf(finalCsv));    
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            email.setSubject('Renewal Notification Error Logs');
            email.setToAddresses(toAddresses);
            email.setPlainTextBody('Find attached the error records for 75 days Renewal notification batch.' );
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            try{
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }catch(Exception e){
                
            }
        }
    }
    
    public void buildErrorRecord(String errMessage, String recId){
        CWS_Error_Log__c err  = new CWS_Error_Log__c();
        err.CWS_Class_Name__c = 'CWS_75daysRenewalReminderEmailsBatch';
        err.CWS_Method_Name__c = 'execute';
        err.CWS_Error_Message__c = errMessage;
        err.CWS_Record_Id__c = recId;
        errRecsToInsert.add(err);
    }
    
    @TestVisible
    private Messaging.SingleEmailMessage createEmailMessage(String templateId, Contract conRecord, List<String> ccAddresses, List<Id> documentIds){
        OrgWideEmailAddress[] owea = [SELECT id FROM OrgWideEmailAddress WHERE  Address = 'renewals@connectwise.com'];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTargetObjectId(conRecord.CWS_Bill_To_Contact__c);
        message.setSaveAsActivity(true);
        message.setTemplateID(templateId);
        message.setWhatId(conRecord.Id);  
        if(ccAddresses != null && ccAddresses.size() > 0){
            message.setCcAddresses(ccAddresses);    
        }
        if(documentIds != null && documentIds.size() > 0){
            message.setEntityAttachments(documentIds);
        }
        
        if(owea.size() > 0){
            message.setOrgWideEmailAddressId(owea.get(0).id);
        }
        return message;
    }
}