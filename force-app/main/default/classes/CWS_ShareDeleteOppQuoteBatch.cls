/*Class Name: CWS_ShareDeleteOppQuoteBatch
*Description: activate the Disty Reseller record
*Created By: Ankit Bobde
*Created On: 23/05/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Ankit Bobde            23/5/2020       Bed-6479                Initial version created
*Sudhir Moturu          03/07/2020      BED-5572                Updated partially completed logic
*
*/
global class CWS_ShareDeleteOppQuoteBatch implements Database.Batchable<sObject>,Database.Stateful{
    
    public CWS_Distributor_Reseller__c distyObj;
    public string context;
    public String queryString;
    public set<id> distyIDSet = new set<id>();
    public set<id> distyErrorIDSet = new set<id>();//BED-5572 ids of disty reseller records failed sharing
    public string license = CWS_ConstantClass.LICENSE_PARTNER;
    public id endCustID;
    public list<CWS_Error_Log__c> errLogList = new list<CWS_Error_Log__c>();
    public Map<id,CWS_Distributor_Reseller__c> mapOfAllDisty = new map<id,CWS_Distributor_Reseller__c>();
	public set<Account> accs = new set<Account>();
    
    
    /*
Constructor initialization
*/
    
    global CWS_ShareDeleteOppQuoteBatch(String endCustID, Map<id,CWS_Distributor_Reseller__c> mapOfAllDisty,String context, list<CWS_Error_Log__c> errList,set<id> setDistyFailIds){
        this.context = context;
        this.endCustID = endCustID;
        this.distyIDSet = mapOfAllDisty.keySet();
        this.distyErrorIDSet = setDistyFailIds;
        this.mapOfAllDisty = mapOfAllDisty;
        if(errList != null){
            //Adding the Error logs from Batch 1 so that can be be combinely inserted in batch 2 when processing is completed
            errLogList.addAll(errList);
        }
        //Querying the opp with account Disty combination
        queryString = 'Select id from opportunity where accountID =: endCustID AND CWS_Store_Bill_To_Id__c IN: distyIDSet';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString );
    }
    
    /*
* Method to Send emails for different criteria
*/
    global void execute(Database.BatchableContext BC, Opportunity[] scope) {
    Map<ID,ID> mapQuoteOpp = new Map<Id,Id>();//BED-5572 Map of user record and opportunity and quote being shared with
	
    list<SObject> sObjList = new list<SObject>();
    try{
        //Getting all the quotes associated with the opportunities with account-Distributor Combination
        for(Opportunity opp : [Select id,CWS_Store_Bill_To_Id__c,CWS_Share_with_Bill_To_Account__c,AccountId,Account.CWS_Established_Disti_Reseller__c,
                                CWS_Bill_To_Account__c,(Select id,CWS_Share_with_Bill_To_Account__c,CWS_Bill_To_Account__c,
                                CWS_Shared_Bill_To_Id__c from SBQQ__Quotes2__r where SBQQ__Account__c=:endCustID and CWS_Shared_Bill_To_Id__c IN: distyIDSet) from Opportunity where id=: scope]){
            mapQuoteOpp.put(opp.Id,opp.CWS_Bill_To_Account__c);//BED-5572 creating the user and records map
            if(context == CWS_ConstantClass.BATCH_ACTIVATE){
                if(opp.CWS_Bill_To_Account__c == opp.CWS_Store_Bill_To_Id__c){
                    opp.CWS_Share_with_Bill_To_Account__c = opp.CWS_Store_Bill_To_Id__c;
                }
            }else{
				 if(opp.CWS_Share_with_Bill_To_Account__c==opp.Account.CWS_Established_Disti_Reseller__c){
                        accs.add(new Account(Id=opp.AccountId,CWS_Established_Disti_Reseller__c=null));
                 }
                opp.CWS_Share_with_Bill_To_Account__c  = null;
            }
            sObjList.add(opp);
            for(SBQQ__Quote__c quote: opp.SBQQ__Quotes2__r){
                mapQuoteOpp.put(quote.Id,quote.CWS_Bill_To_Account__c);//BED-5572 creating user and record map
                if(context == CWS_ConstantClass.BATCH_ACTIVATE){
                    if(quote.CWS_Bill_To_Account__c == quote.CWS_Shared_Bill_To_Id__c){
                        quote.CWS_Share_with_Bill_To_Account__c = quote.CWS_Shared_Bill_To_Id__c;
                    }
                }else{
                    quote.CWS_Share_with_Bill_To_Account__c  = null;
                }
                sObjList.add(quote);
            }
        }
        
		
        if(sObjList.size()>0){
			CWS_OpportunityTriggerHandler.BEFORE_UPDATE_EXECUTED = true;
			CWS_OpportunityTriggerHandler.AFTER_UPDATE_EXECUTED = true;
			CWS_QuoteTriggerHandler.BEFORE_UPDATE_EXECUTED = true;
			CWS_QuoteTriggerHandler.AFTER_UPDATE_EXECUTED = true;
            List<Database.SaveResult> updateResults = Database.update(sObjList, false);
            for(Integer i=0;i<updateResults.size();i++){
                if (!updateResults.get(i).isSuccess()){
                    // DML operation failed
                    //Creating our own Error log records as we need to retain the context in a batch so 
                    //that at the end we can insert the error logs once all records are processed
                    CWS_Error_Log__c errlogObj = CWS_ExceptionHandler.initializeAndReturnDMLErrorLogs('CWS_ShareDeleteOppQuoteBatch','creategenericDMLErrorLogs','',
                                                      JSON.serialize( updateResults.get(i).getErrors()),sObjList.get(i).id,'CWS_Portal_Records_Sharing_Errors','');
                    errLogList.add(errlogObj);
                    //BED-5572 storing all the disy reseller ids which failed sharing with user
                    if(mapQuoteOpp.containsKey(sObjList.get(i).id)){
                        distyErrorIDSet.add(mapQuoteOpp.get(sObjList.get(i).id));
                    }  
                }
            }
        }
    }catch(Exception e){ 
         CWS_ExceptionHandler.logException( e,'Opportunity/Quote' , 'CWS_ShareDeleteOppQuoteBatch', 'Batch class Shares opp/Quote to Channel Reps' , '', null, null , 'CWS_Portal_Records_Sharing_Errors' , null);
    }
}
    
    /*
*Finish method of batch
*/
    global void finish(Database.BatchableContext BC) {
        //BED-5572 updaing disty records based on failure of sharing
		list<Account> accList = new list<Account>();
        try{
            for(CWS_Distributor_Reseller__c objDistRes: mapOfAllDisty.values()){
                if(distyErrorIDSet.contains(objDistRes.CWS_Distributor_ResellerAcc__c)){
                    objDistRes.CWS_Status__c=CWS_ConstantClass.PARTIALLY_COMPLETED;
                } else {
                    objDistRes.CWS_Status__c=CWS_ConstantClass.COMPLETED;
                    if(context == CWS_ConstantClass.BATCH_ACTIVATE){
                        objDistRes.CWS_Active__c = true;
                    }else{
                        objDistRes.CWS_Active__c = false;
                    }
                }   
            }
            if(mapOfAllDisty.size()>0){
                //Populate Active checkbpx depending on the context as soon as the Account/Sharing is done
                List<Database.SaveResult> savedData = Database.update(mapOfAllDisty.values());
            }
			if(accs.size()>0){
                accList.addAll(accs);
                List<Database.SaveResult> savedData = Database.update(accList);
            }
        }catch(Exception e){ 
            CWS_ExceptionHandler.logException( e,'CWS_Distributor_Reseller__c' , 'CWS_ShareDeleteOppQuoteBatch', '' , '', null, null , 'CWS_Portal_Records_Sharing_Errors' , null);
        }
        
        try{
            if(errLogList != NULL){
                insert errLogList;
            }
        }catch(DMLException e){
            CWS_ExceptionHandler.insertException('CWS_Error_Log__c' , 'CWS_ShareDeleteOppQuoteBatch' , 'finish' , e.getCause().getMessage() , '', e.getMessage() , String.valueOf(e.getLineNumber()) , e.getTypeName() , '' , '' , 'While inserting error log record in Finish of a batch class' , '');    
        }
        
        //Query Async Apex job to send the status in email body
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email
                          FROM AsyncApexJob WHERE Id =
                          :BC.getJobId()];
        
        //Below strings are used in email body
        String finalContext = (context == CWS_ConstantClass.BATCH_ACTIVATE ? CWS_ConstantClass.BATCH_ACTIVATION : CWS_ConstantClass.BATCH_DEACTIVATION);
        
        //Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
        mail.setSubject('Distributor/Reseller record '+ finalContext +  ' status: ' + a.Status);
        mail.setPlainTextBody
            (finalContext +' completed with Total '+ a.TotalJobItems +
             ' batches with '+ a.NumberOfErrors + ' failures.' + '\n'+ ( !errLogList.isEmpty() ? finalContext + ': Failed for some of the records you can check the failures on Error Logs object by filtering context as CWS_Portal_Records_Sharing_Errors' :''));
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }Catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Messaging.sendEmail' , 'CWS_ShareDeleteOppQuoteBatch', 'finish' , '', null, null , 'sendEmail' , null);
        }
    }
}