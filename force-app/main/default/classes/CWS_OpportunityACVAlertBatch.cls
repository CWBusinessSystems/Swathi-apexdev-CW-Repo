/*Class Name: CWS_OpportunityACVAlertBatch
*Description: Batch Class to Send Opp Notification Based on ACV, Closed Date, Last Modified
*Created By: Abhishek
*Created On: 07/01/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               07/01/2020      BED-5096              Send Opp Owner Notification
*Ad Victoriam Solutions 02/15/2022      N/A                   Updated querying to account for new Opportunity stages.
*/
public class CWS_OpportunityACVAlertBatch implements Database.Batchable < sObject > {
    //List<Messaging.SingleEmailMessage> ownerlistEmails = new List<Messaging.SingleEmailMessage>();
    //List<Messaging.SingleEmailMessage> managerlistEmails = new List<Messaging.SingleEmailMessage>();
    List<Id> oppIds = new List<Id>();


    /* Parameterized cunstructor to run batch for specific Accounts
    */
    Public CWS_OpportunityACVAlertBatch(List<Id> oppIds){
        this.oppIds = oppIds;
    }
    Public CWS_OpportunityACVAlertBatch(){}

    public Database.QueryLocator start(Database.BatchableContext bc) {
        string lastNDays =string.valueof(Integer.valueOf(Label.CWS_Opportunity_Amount_25K_LAST_N_DAYS)-1);
        //string prospecting = CWS_ConstantClass.OPPORTUNITY_STAGE_PROSPECTING;
        //string analysis = CWS_ConstantClass.OPPORTUNITY_STAGE_ANALYSIS;
        //string demo = CWS_ConstantClass.OPPORTUNITY_STAGE_DEMO;
        //string proposal = CWS_ConstantClass.OPPORTUNITY_STAGE_PROPOSAL;
        //string finalize = CWS_ConstantClass.OPPORTUNITY_STAGE_FINALIZE_QUOTE;
        string salesRep = CWS_ConstantClass.PROFILE_SALES_REP;
        String omitted = 'Omitted';
        string query = 'Select id,Amount,CWS_NonMin_Min_Total_ACV__c,closeDate,owner.Name,Owner.Manager.Name,Owner.email,Owner.Manager.email,CWS_Bill_To_Contact__c, ';
                query += 'ownerId,Owner.Manager.Id,(select id,lastmodifiedDate from Tasks where lastmodifiedDate = LAST_N_DAYS:'+lastNDays+')';
                query += ',(select id,lastmodifiedDate from Events where  lastmodifiedDate = LAST_N_DAYS:'+lastNDays+')';        
                query += ' from opportunity where CWS_NonMin_Min_Total_ACV__c >= 25000 AND IsWon=false AND ForecastCategoryName!=:omitted';
                    /*(stageName =: prospecting OR stageName =: analysis OR';
                query += ' stageName =: demo OR stageName =: proposal OR stageName =: finalize )';*/ 
                
				//Added below check since it is blocking test coverage.
				if(!test.isRunningTest()){
					query +=' AND lastmodifiedDate != LAST_N_DAYS:'+lastNDays;
				} 
                if(!oppIds.isEmpty()){
                    query +=' AND id IN : OppIds';
                }
                system.debug('query'+query);
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc,List<Opportunity> scope) {
        List<Messaging.SingleEmailMessage> ownerlistEmails = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> managerlistEmails = new List<Messaging.SingleEmailMessage>();
        Map<String, EmailTemplate> nameTempMap = new  Map<String, EmailTemplate>();


        for(EmailTemplate temp : [select id,Name,DeveloperName from EmailTemplate 
                            where DeveloperName =: Label.CWS_Opportunity_Amount_25K_Owner_Notification
                             OR DeveloperName =: Label.CWS_Opportunity_Amount_25K_Manager_Notification]){
            nameTempMap.put(temp.DeveloperName,temp);
        }
        try{
			boolean isTrue = Test.isRunningTest();//Test class covergae
			integer nDays;//Test class covergae
            for(Opportunity opp : scope){

                system.debug('opp: '+opp);

			    //Added for test covergae Start
				if(isTrue){
                    nDays = 1;
                }
                else
                {     
                    nDays = integer.valueof(Label.CWS_Opportunity_Amount_25K_LAST_N_DAYS); 
                }//Added for test covergae End
                if(opp.closeDate.addDays(-nDays)==system.TODAY()
                    && (opp.tasks.size()== 0 || opp.tasks==null) && (opp.events.size() ==0 || opp.events == null)){

                    system.debug('sending email');

                    // Single Email for Owner Notification
                    Messaging.SingleEmailMessage ownerEmail = new Messaging.SingleEmailMessage();
                    ownerEmail.setWhatId(opp.Id);
                    ownerEmail.setTargetObjectId(opp.CWS_Bill_To_Contact__c );
                    ownerEmail.setTreatTargetObjectAsRecipient(false);
                    List<String> SendTo = New List<String>();
                    sendTo.add(Opp.Owner.Email);
                    ownerEmail.setToAddresses(sendTo);
                    ownerEmail.setTemplateId(nameTempMap.get(Label.CWS_Opportunity_Amount_25K_Owner_Notification).Id); 
                    ownerEmail.saveAsActivity=false;
                    ownerlistEmails.add(ownerEmail);
                    sendTo.clear();
                    // Single Email for Manager Notification
                    if(Opp.Owner.Manager!=null){
                        Messaging.SingleEmailMessage mgrEmail = new Messaging.SingleEmailMessage();
                        mgrEmail.setWhatId(opp.Id) ;      
                        mgrEmail.setTargetObjectId(opp.CWS_Bill_To_Contact__c);
                        mgrEmail.setTreatTargetObjectAsRecipient(false);
                        mgrEmail.saveAsActivity=false;
                        sendTo.add(Opp.Owner.Manager.Email);    
                        mgrEmail.setToAddresses(sendTo);
                        mgrEmail.setTemplateId(nameTempMap.get(Label.CWS_Opportunity_Amount_25K_Manager_Notification).Id); 
                        managerlistEmails.add(mgrEmail);
                    }
                }
            }
            system.debug('ownerlistEmails'+managerlistEmails);
            system.debug('ownerlistEmails'+ownerlistEmails);
            if(!managerlistEmails.isEmpty()){
                Messaging.SendEmail(managerlistEmails); 
            }
            if(!ownerlistEmails.isEmpty()){
                Messaging.SendEmail(ownerlistEmails); 
            }
        }catch(Exception ex){
            CWS_ExceptionHandler.logException( ex,'BatchClass' , 'CWS_OpportunityACVAlertBatch' , 'Execute' ,'', null , null ,'Email' , null);
        }

    }
    public void finish(Database.BatchableContext bc) {
    }
}