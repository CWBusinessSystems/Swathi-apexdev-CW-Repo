/*Class Name: CWS_ActivateDistyResellerBatch
*Description: activate the Disty Reseller record
*Created By: Ankit Bobde
*Created On: 22/05/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*Ankit Bobde            22/5/2020       Bed-6479                Initial version created
*Sudhir Moturu          03/07/2020      BED-5572                Updated partially completed logic
*
*/
global class CWS_ActivateDistyResellerBatch implements Database.Batchable<sObject>,Database.Stateful{
    
    public CWS_Distributor_Reseller__c distyObj;
    public string context;
    public String queryString;
    public set<id> distyIDSet = new set<id>();
    public set<id> setDistyFailIds = new set<id>();//BED-7815 set of disty account failed record ids
    public string license = CWS_ConstantClass.LICENSE_PARTNER;
    public id endCustID;
    public Map<id,CWS_Distributor_Reseller__c> mapOfAllDisty = new map<id,CWS_Distributor_Reseller__c>();
    public list<sObject> listofnewShareObj;
    public list<sObject> removeShareLst;
    public list<CWS_Error_Log__c> errLogList = new list<CWS_Error_Log__c>();
    public boolean isReactie = true; 
    
    /*
Constructor initialization
*/
    
    global CWS_ActivateDistyResellerBatch(String accID,CWS_Distributor_Reseller__c distyObj, String context){
        
        this.distyObj = distyObj;
        this.context = context;
        
        //Checking if the Context is Deactivate and has been clicked on account which means 
        //all the Dist/Reseller which are not partner need to be considered to remove share of records 
        if(String.isNotBlank(accID)){
            endCustID = accID;
            
            //Get All Distys for selected EndCustomer 
            for(CWS_Distributor_Reseller__c disty: [Select id,CWS_Active__c,CWS_Distributor_ResellerAcc__c,CWS_Account__c,CWS_isReactive__c,CWS_Status__c from CWS_Distributor_Reseller__c where CWS_Account__c =: accID and CWS_Active__c = true]){
                mapOfAllDisty.put(disty.CWS_Distributor_ResellerAcc__c,disty);
            }
            
            //Identify Disty for which the Deal is CLosed Won, which means Disty will be Active going foward
            if(mapOfAllDisty != null){
                for(Opportunity opp: [Select id,CWS_Bill_To_Account__c from opportunity where accountID =: endCustID AND CWS_Bill_To_Account__c IN: mapOfAllDisty.keyset() AND stageName =: CWS_ConstantClass.OpportunityClosedWon_Stage]){
                    if(mapOfAllDisty.containskey(opp.CWS_Bill_To_Account__c)){
                        //We need to exclude the Active Disty who closed Deal and Get Aall others
                        mapOfAllDisty.remove(opp.CWS_Bill_To_Account__c);
                    }
                }
            }
            
            //Iterate and Mark the Distys as Inactive as they have not closed any deal 
            if(mapOfAllDisty !=null){
                for(CWS_Distributor_Reseller__c disty: mapOfAllDisty.values()){
                    distyIDSet.add(disty.CWS_Distributor_ResellerAcc__c);
                    disty.CWS_Active__c = false;
                }
            }
            
        }else{
            //This will run when the Activate/Deactivate has been clicked from Disty/Resell Object Record
            endCustID = distyObj.CWS_Account__c;
            distyIDSet.add(distyObj.CWS_Distributor_ResellerAcc__c);
            mapOfAllDisty.put(distyObj.CWS_Distributor_ResellerAcc__c,distyObj);
        }
        
        //Builing query string on Distributor accounts 
        queryString = 'Select id from Account where id IN: distyIDSet';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString );
    }
    
    /*
* Method to perform Delete/Share of records depending on the context
*/
    global void execute(Database.BatchableContext BC, Account[] scope) {
        
        map<id,set<id>> mapOfRecToShare = new map<id,set<id>>();
        set<id> accToShareSet = new set<id>();
        accToShareSet.add(endCustID);
        //set<id> userToShareSet = new set<id>();
        map<id,id> mapOfUserAcct = new map<id,Id>();//BED-7815 Map of user and account id
        try{
            //Creating a map to pass it as parameter to call to share Utility
            for(User usr : [Select id,AccountId from User where AccountId =: scope AND Profile.UserLicense.Name =: license AND IsActive = true]){
                //userToShareSet.add(usr.id);
                mapOfUserAcct.put(usr.Id,usr.AccountId);
                if(mapOfRecToShare.containskey(endCustID)){
                    mapOfRecToShare.get(endCustID).add(usr.id);
                }else{
                    mapOfRecToShare.put(endCustID,new set<id>{usr.id});
                }
            }
            
            if(context == CWS_ConstantClass.BATCH_ACTIVATE && !mapOfRecToShare.isEmpty()){
                listofnewShareObj = CWS_ShareRecordsUtility.shareSobjectRecords(CWS_ConstantClass.SOBJECT_ACCOUNT,mapOfRecToShare,CWS_ConstantClass.ACCESS_READ);
                //insert the share sobject  records
                list<AccountShare>  accShareList = (list<AccountShare>)listofnewShareObj;
                if(!accShareList.isEmpty()){
                    List<Database.SaveResult> insertResults = Database.insert(accShareList, false);
                    for(Integer i=0;i<insertResults.size();i++){
                        if (!insertResults.get(i).isSuccess()){
                            // DML operation failed
                            //Creating our own Error log records as we need to retain the context in a batch so 
                            //that at the end we can insert the error logs once all records are processed
                            CWS_Error_Log__c errlogObj = CWS_ExceptionHandler.initializeAndReturnDMLErrorLogs('CWS_ActivateDistyResellerBatch','creategenericDMLErrorLogs','',
                                                                                                              JSON.serialize( insertResults.get(i).getErrors()),accShareList.get(i).UserOrGroupId,'CWS_Portal_Records_Sharing_Errors','');
                            errLogList.add(errlogObj);
                            if(mapOfUserAcct.containsKey(accShareList.get(i).UserOrGroupId)){
                                setDistyFailIds.add(mapOfUserAcct.get(accShareList.get(i).UserOrGroupId));
                            } 
                        }
                    }
                }
            }else if(!mapOfRecToShare.isEmpty() && mapOfUserAcct.size() > 0){
                removeShareLst = CWS_ShareRecordsUtility.removeSobjectRecords(CWS_ConstantClass.SOBJECT_ACCOUNT,accToShareSet,mapOfUserAcct.keyset());
                //Delete the share sobject  records
                list<AccountShare>  accShareList = (list<AccountShare>)removeShareLst;
                if(!accShareList.isEmpty()){
                    List<Database.DeleteResult> deleteResults = Database.Delete(accShareList, false);
                    for(Integer i=0;i<deleteResults.size();i++){
                        if (!deleteResults.get(i).isSuccess()){
                            // DML operation failed
                            //Creating our own Error log records as we need to retain the context in a batch so 
                            //that at the end we can insert the error logs once all records are processed
                            CWS_Error_Log__c errlogObj = CWS_ExceptionHandler.initializeAndReturnDMLErrorLogs('CWS_ActivateDistyResellerBatch','creategenericDMLErrorLogs','',
                                                                                                              JSON.serialize( deleteResults.get(i).getErrors()),accShareList.get(i).UserOrGroupId,'CWS_Portal_Records_Sharing_Errors','');
                            errLogList.add(errlogObj);
                            if(mapOfUserAcct.containsKey(accShareList.get(i).UserOrGroupId)){
                                setDistyFailIds.add(mapOfUserAcct.get(accShareList.get(i).UserOrGroupId));
                            } 
                        }
                    }
                }
            }
            
        }catch(Exception e){ 
            CWS_ExceptionHandler.logException( e,'Account/Contact' , 'CWS_ActivateDistyResellerBatch', 'execute()' , '', null, null , 'CWS_Portal_Records_Sharing_Errors' , null);
        }
    }
    
    /*
*Finish method of batch
*/
    global void finish(Database.BatchableContext BC){
        for(CWS_Distributor_Reseller__c objDistRes: mapOfAllDisty.values()){
            if(context == CWS_ConstantClass.BATCH_ACTIVATE && !objDistRes.CWS_isReactive__c){
                //This checkbox signifies to consider the reactivate scenario if false
                isReactie = false;
            }
        }
        
        //Call 2nd Batch ONLY in case of Deactivation and Reactivation else send completion email
        //!distyIDSet.isEmpty() => This hhelps in not calling the second batch when Deactivate is clicked from the Account 
        //and all records are already deactivated 
        if((context == CWS_ConstantClass.BATCH_DEACTIVATE || (context == CWS_ConstantClass.BATCH_ACTIVATE && isReactie)) && !distyIDSet.isEmpty()){
            //SCOPE 50 => This gets called in case of Deactivation and Reactivation which means we do not have to bother about which Disty the opp belongs to 
            //We just have to blindly update the opp/Quote Lookup. So we do considering 50 opps at a time.so that the DML context remains within 10000 records 
            Id batchJobId = Database.executeBatch(new CWS_ShareDeleteOppQuoteBatch(endCustID,mapOfAllDisty,context,errLogList,setDistyFailIds),50);
        }else{
            try{
                for(CWS_Distributor_Reseller__c objDistRes: mapOfAllDisty.values()){
                    if(setDistyFailIds.contains(objDistRes.CWS_Distributor_ResellerAcc__c)){
                        objDistRes.CWS_Status__c=CWS_ConstantClass.PARTIALLY_COMPLETED;
                    } else {
                        objDistRes.CWS_Status__c=CWS_ConstantClass.COMPLETED;
                        if(context == CWS_ConstantClass.BATCH_ACTIVATE){
                            if(!objDistRes.CWS_isReactive__c){
                                objDistRes.CWS_isReactive__c = true;
                            }
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
            }catch(Exception e){ 
                CWS_ExceptionHandler.logException( e,'CWS_Distributor_Reseller__c' , 'CWS_ActivateDistyResellerBatch', '' , '', null, null , 'CWS_Portal_Records_Sharing_Errors' , null);
            }
            
            try{
                if(errLogList != NULL){
                    //insert Error Logs records once the batch process all the records
                    insert errLogList;
                }
            }catch(DMLException e){
                CWS_ExceptionHandler.insertException('CWS_Error_Log__c' , 'CWS_ActivateDistyResellerBatch' , 'finish' , e.getCause().getMessage() , '', e.getMessage() , String.valueOf(e.getLineNumber()) , e.getTypeName() , '' , '' , 'While inserting error log record in Finish of a batch class' , '');    
            }
            
            //Query Async Apex job to send the status in email body
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                              TotalJobItems, CreatedBy.Email
                              FROM AsyncApexJob WHERE Id =
                              :BC.getJobId()];
            
            //Below strings are used in email body
            String finalContext = (context == CWS_ConstantClass.BATCH_ACTIVATE ? CWS_ConstantClass.BATCH_ACTIVATION : CWS_ConstantClass.BATCH_DEACTIVATION);
            String finalEmailBody;
            
            //Send an email to the Apex job's submitter notifying of job completion.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {a.CreatedBy.Email};
                mail.setToAddresses(toAddresses);
            mail.setSubject('Distributor/Reseller record '+ finalContext +  ' status: ' + a.Status);
            if(!distyIDSet.isEmpty()){
                
                finalEmailBody = ('Activation' +' completed with Total '+ a.TotalJobItems +
                                  ' batches with '+ a.NumberOfErrors + ' failures.' + '\n'+ (!errLogList.isEmpty() ? 'Activation'+ ': Failed for some of the records you can check the failures on Error Logs object by filtering context as CWS_Portal_Records_Sharing_Errors' :''));
            }else{
                finalEmailBody = Label.CWS_Distys_already_Deactivated_for_End_Customer_Account;
            }
            mail.setPlainTextBody(finalEmailBody);
            try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }Catch(Exception e){
                CWS_ExceptionHandler.logException( e,'Messaging.sendEmail' , 'CWS_ActivateDistyResellerBatch', 'finish' , '', null, null , 'sendEmail' , null);
            }
        }
    }
}