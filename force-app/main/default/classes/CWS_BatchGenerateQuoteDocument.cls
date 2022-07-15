Public class CWS_BatchGenerateQuoteDocument implements Database.Batchable<sObject>, Database.stateful{
    private String queryString {get;set;}
    private Map<String, String> mapConstants;
    public Set<Id> quoteIds;
	
	public CWS_BatchGenerateQuoteDocument(){
    }
        
    public CWS_BatchGenerateQuoteDocument(Set<Id> tquoteIds){
        quoteIds=tquoteIds;
    }

    
    public Database.QueryLocator start(Database.BatchableContext bc){
    
        mapConstants=new Map<String, String>();
        for(CWS_Renewal_Email_Settings__mdt ren:[Select  MasterLabel, DeveloperName, CWS_Value__c
                 from CWS_Renewal_Email_Settings__mdt Limit 100]){
            mapConstants.put(ren.MasterLabel,ren.CWS_Value__c);
        }
        //BED-11397 Added new Check for 30 days Sent 
        queryString='Select Id, Name, CWS_Route_to_Market__c,SBQQ__Primary__c,CWS_Master__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_Master__c,SBQQ__PrimaryContact__c,CWS_Bill_to_Contact__c,SBQQ__Opportunity2__c,CWS_Renewal_Category__c,SBQQ__Opportunity2__r.Account.CWS_Additional_Emails_for_Invoice__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_Renewal_Quote_Schedule__c,SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__r.CWS_Quote_Type__c from SBQQ__Quote__c where CWS_Quote_Type__c=\''+CWS_ConstantClass.Quote_Type_Renewal+'\' '+
            ' AND SBQQ__Status__c in (\''+CWS_ConstantClass.QUOTE_STATUS_DRAFT+'\', \''+ CWS_ConstantClass.QUOTE_STATUS_APPROVED+
            '\', \''+ CWS_ConstantClass.QUOTE_STATUS_INREVIEW +'\', \''+CWS_ConstantClass.QUOTE_STATUS_REVISION +
            '\') AND '+
            ' (NOT SBQQ__Opportunity2__r.StageName in (\''+CWS_ConstantClass.OpportunityClosedWon_Stage +
            '\', \''+ CWS_ConstantClass.OpportunityClosedLose_Stage +'\')) AND '+
            ' CWS_Renewal_Document_Generated_Date__c=null AND  '+
            ' SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_Renewal_Quote_Schedule__c<=TODAY AND SBQQ__Uncalculated__c=FALSE  '+
            ' AND SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_30_Days_Sent__c=FALSE AND '+
            ' (CWS_On_Hold__c=FALSE OR CWS_Master__c=TRUE)';
        if(quoteIds!=null && !quoteIds.isEmpty()){
			queryString='Select Id,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_Master__c, Name,SBQQ__Primary__c,CWS_Route_to_Market__c,CWS_Master__c,SBQQ__PrimaryContact__c,CWS_Bill_to_Contact__c,SBQQ__Opportunity2__c,CWS_Renewal_Category__c,SBQQ__Opportunity2__r.Account.CWS_Additional_Emails_for_Invoice__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_Renewal_Quote_Schedule__c from SBQQ__Quote__c where id in :quoteIds';
		
        }  		
			
        system.debug(queryString);
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>scope){
        try{
            set<id> masterConId = new set<id>();
            List<SBQQ__Quote__c> quoteList=(List<SBQQ__Quote__c>)scope;
            String jobId;
            List<String> additionalEmailsList = new List<String>();
            String addEmailContent;
            //id templateId;
			id RWCtemplateId;
            id RNCtemplateId;
            List<Messaging.SingleEmailMessage> msgList=new List<Messaging.SingleEmailMessage>();
            list<Contract> conList = new list<Contract>();
			List<SBQQ__Quote__c> lstUpdatedQuote = new List<SBQQ__Quote__c>();

            boolean isMaster = true;

            for(SBQQ__Quote__c quote: quoteList){
               if(!quote.CWS_Master__c){
                   isMaster = false;
                   quote.SBQQ__WaterMarkShown__c = false;
               }
               lstUpdatedQuote.add(quote);
            }
            
            if(lstUpdatedQuote.size()>0 && !isMaster){
				List<Database.SaveResult> results = Database.Update(lstUpdatedQuote);
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_BatchGenerateQuoteDocument' , 
                'execute','SBQQ__Quote__c', null , null ); 
            }
			
			for(SBQQ__Quote__c quote: lstUpdatedQuote){
                if(quote.CWS_Route_to_Market__c==CWS_ConstantClass.RTM_Value_Direct){
                    if(!quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_Master__c){
                        jobId=CWS_QuoteDocumentUtil.quoteDocumentApiCall(quote.Id,mapConstants.get('EndCustomerQuoteTemplateId'));
                    }else{
						if(Label.CWS_Renewal_Email_Batch_Switch30Days == CWS_ConstantClass.RENEWAL_BATCH_ON){

							addEmailContent = '';
							if(additionalEmailsList.size()>0){
								additionalEmailsList.clear();
							}
							
							if(quote.CWS_Renewal_Category__c == CWS_ConstantClass.Renewal_Type_OptOut){
								//Checking for Additional emails on sold to account.
								if(quote.SBQQ__Opportunity2__r.Account.CWS_Additional_Emails_for_Invoice__c != null){
									addEmailContent = quote.SBQQ__Opportunity2__r.Account.CWS_Additional_Emails_for_Invoice__c;
									if(addEmailContent.contains(',')){
										additionalEmailsList = addEmailContent.split(',');
									}
									else{
										additionalEmailsList.add(addEmailContent);
									}
								}
							 }
							 
							if(mapConstants!=null && 
								mapConstants.get('RWCOptOutEmailTemplateLegacy') != null && mapConstants.get('RNOptOutEmailTemplateLegacy') != null &&
								quote.SBQQ__PrimaryContact__c != null){
								 //templateId=mapConstants.get('RNOptOutEmailTemplate');
								 RWCtemplateId=mapConstants.get('RWCOptOutEmailTemplateLegacy');
								 RNCtemplateId=mapConstants.get('RNOptOutEmailTemplateLegacy');
								 Messaging.SingleEmailMessage message1 = new Messaging.SingleEmailMessage();
								 message1.setTargetObjectId(quote.SBQQ__PrimaryContact__c);
								 message1.setSaveAsActivity(true);
								 
								 //BED-13173
								  if(quote.SBQQ__Primary__c){
								 message1.setTemplateID(RNCtemplateId);
								 }
								 else if(!quote.SBQQ__Primary__c && quote.SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__r.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_RenewalWithChange){
								 message1.setTemplateID(RWCtemplateId); 
								 }
								 //BED-13173
								 
								 message1.setWhatId(quote.SBQQ__Opportunity2__c);
								 if(!additionalEmailsList.isEmpty()){ 
									 message1.setCcAddresses(additionalEmailsList);
								 }
								 msgList.add(message1);
								 Messaging.SendEmailResult[] results;
								 if(!msgList.isEmpty()){
									 results = Messaging.sendEmail(msgList);
								 }
								 if(results[0].isSuccess()){
									 masterConId.add(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);
								 }
							}
						}
                    }
                }
                else{
                    jobId=CWS_QuoteDocumentUtil.quoteDocumentApiCall(quote.Id,mapConstants.get('DistiQuoteTemplateId'));
                }
            }
            
            if(masterConId.size()>0){
                for(Contract con: [Select id,CWS_30_Days_Sent__c  from contract where id =: masterConId]){
                    con.CWS_30_Days_Sent__c = true;
                    conList.add(con);
                }
            }
            
            if(conList.size()>0){
                update conList;
            }
        }
        catch(exception exc){
            CWS_ExceptionHandler.logException(exc,'execute' , 'CWS_BatchGenerateQuoteDocument', 'CWS_BatchGenerateQuoteDocument.execute' ,
                         '', null, null , 'execute' , null);
        }
    }
    
    public void finish(Database.BatchableContext bc){
	}
}