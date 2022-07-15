/*Class Name: CWS_RenewalBatch 
*Description: Batch Class to update RenewalForecast and Renewal Quoted checkboxes on Contract.
*Created On: 4/27/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Karthikeyan 4/10/2020        BED-3402               Automatic and Manual Renewal Creation
*Ankit                 7/6/2020        RENEWALCAT_CHANGE_REQ - Removing Query parameter Renewal type
*/
Public class CWS_RenewalBatch implements Database.Batchable<sObject>, Database.stateful{
    
    private String queryString;
    public List<Id> contractIds;
    private Set<String> contractIdLikeList=new Set<String>();
    private Id accountId;
    
    //Empty Constructor
    public CWS_RenewalBatch(){
    
    }
    // Constructor with Account Id
    public CWS_RenewalBatch(Id accId){
        accountId=accId;
    }
    // Constructor with List of Contracts    
    public CWS_RenewalBatch(List<Id> contractId){
        contractIds = contractId;
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        queryString=' Select Id, SBQQ__RenewalForecast__c, CWS_Renewable_Products__c, SBQQ__RenewalQuoted__c, EndDate, '+
                    ' AccountId, CWS_Renewal_Quote_Schedule__c, CWS_Renewal_Opportunity_Schedule__c '+
                    ' from Contract where '+
                    ' endDate >=TODAY and '+
                    ' ((CWS_Renewal_Opportunity_Schedule__c<=TODAY and SBQQ__RenewalForecast__c=FALSE) or '+
                    ' (CWS_Renewal_Quote_Schedule__c<=TODAY and SBQQ__RenewalQuoted__c=FALSE and '+
                    ' SBQQ__RenewalOpportunity__r.StageName!=\''+ CWS_ConstantClass.OpportunityClosedLose_Stage +'\' and '+
                    ' SBQQ__RenewalOpportunity__r.StageName!=\''+ CWS_ConstantClass.OpportunityClosedWon_Stage  +'\' )) and '+
                    ' CWS_Renewal_Batch_Failed__c=FALSE AND '+ 
					' CWS_Renewable_Products__c>0 AND ' +
                    ' CWS_Renewal_Category__c!=\''+ CWS_ConstantClass.Renewal_Category_SplitPending +'\'';
        if(accountId!=null){
            system.debug('Inside account');
            queryString=queryString+' AND accountId =:accountId';
        }
        if(contractIds!=null && !contractIds.isEmpty()){
            queryString=queryString + ' AND id in : contractIds';
            
        }
        
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        SavePoint sp=Database.setSavePoint();
        List<Contract> contracts=(List<Contract>)scope;
        try{
            for(Contract contract:Contracts){
                contractIds.add(contract.Id);
                contractIdLikeList.add(contract.Id+'::RenewContract');
                contract.SBQQ__RenewalForecast__c=TRUE;
                if(contract.CWS_Renewal_Quote_Schedule__c!=null && contract.CWS_Renewal_Quote_Schedule__c<=Date.today()){
                    contract.SBQQ__RenewalQuoted__c=TRUE;
                }
            }
            if(contracts!=null){
                update contracts;
            }
        }catch(Exception exp){    
            //Rollback partial commit in case of exception.
            Database.rollback(sp);
            //Error when updating Renewal Forecast/Renewal Quoted on Contract.
            CWS_ExceptionHandler.logException( exp,'Contract' , 'CWS_RenewalBatch','execute' ,
                                  '', null, null , 'execute' , null);            
            if(exp.getMessage()==null || (exp.getMessage()!=null && !exp.getMessage().contains('UNABLE_TO_LOCK_ROW'))){
                for(Contract contract: contracts){
                    contract.CWS_Renewal_Batch_Failed__c=true;
                    contract.CWS_Error_Message__c=exp.getMessage();
                }
                if(contracts!=null && !contracts.isEmpty()){
                    update contracts;
                }
            }

        }
    }
    
    Public void finish(Database.BatchableContext bc){
        try{
            // Check the Record Job Status to identify failed records and update the Renewal Batch Failed on Contract.
            if(!contractIdLikeList.isEmpty() && CWS_Trigger_Switch__c.getInstance().CWS_RenewalJobStatusCheck__c){
                checkRecordJobStatus(contractIdLikeList);
            }        
        }
        catch(Exception exc){
            CWS_ExceptionHandler.logException( exc,'Contract' , 'CWS_RenewalBatch','finish' ,
                                  '', null, null , 'finish' , null);                        
        }
    }
    
    Public static void checkRecordJobStatus(Set<String> contractIdLikeList ){
        Set<Id> queuedRecordJobIds=new Set<Id>();
        List<CWS_Renewal_Batch_Status__c> renewalBatchStatusList=new List<CWS_Renewal_Batch_Status__c>();
        List<Contract> contractsToUpdate=new List<Contract>(); 
        //Query the Renewal Batch Status object to fetch the in process records from previous batch.
        for(CWS_Renewal_Batch_Status__c renewalStatus:[Select Id, Name, CWS_RecordJobId__c from CWS_Renewal_Batch_Status__c where 
                            CWS_Processed__c=False and (CWS_JobStatus__c='In Progress' or CWS_JobStatus__c='Queued' or CWS_JobStatus__c=null)
                            LIMIT 1000]){
            queuedRecordJobIds.add(renewalStatus.CWS_RecordJobId__c);
        }
        //Query Record Job with Job Status = Failed or Queued or In Progress
        Id contractId;
        for(SBQQ__RecordJob__c recordJob:[Select Id, Name, SBQQ__RecordId__c, SBQQ__JobId__c, SBQQ__JobStatus__c,SBQQ__JobDetails__c,
                                        SBQQ__StackTrace__c, SBQQ__RedirectUrl__c
                         from SBQQ__RecordJob__c where  ((SBQQ__JobStatus__c='Failed' or SBQQ__JobStatus__c='Queued' or 
                             SBQQ__JobStatus__c='In Progress' or SBQQ__JobStatus__c=null) and SBQQ__RecordId__c like '%RenewContract%'
                        and SBQQ__RecordId__c in :contractIdLikeList) or (id in :queuedRecordJobIds) LIMIT 1000]){
             system.debug(recordJob);
            //If the Job Failed with Record Lock Error, reprocess the records.
            if(recordJob.SBQQ__JobStatus__c=='Failed' && recordJob.SBQQ__JobDetails__c!=null  && String.valueOf(recordJob.SBQQ__JobDetails__c)!=null && 
                String.valueOf(recordJob.SBQQ__JobDetails__c).containsIgnoreCase('UNABLE_TO_LOCK_ROW') &&
                recordJob.SBQQ__RecordId__c!=null){
                contractId=(Id)String.valueOf(recordJob.SBQQ__RecordId__c).subStringBefore('::');
                contractsToUpdate.add(new Contract(Id=contractId, SBQQ__RenewalForecast__c=FALSE, SBQQ__RenewalQuoted__c=FALSE,
                                                   CWS_Renewal_Batch_Failed__c=FALSE));
            }            
            else {
                //Update the Renewal Batch Status with the Renewal Batch Failure status.
                CWS_Renewal_Batch_Status__c batchStatus=new CWS_Renewal_Batch_Status__c();
                batchStatus.CWS_ContractId__c=recordJob.SBQQ__RecordId__c!=null? String.valueOf(recordJob.SBQQ__RecordId__c).subStringBefore('::') :null;
                batchStatus.CWS_JobStatus__c=recordJob.SBQQ__JobStatus__c;
                batchStatus.CWS_JobId__c=recordJob.SBQQ__JobId__c;
                batchStatus.CWS_RecordJobId__c=recordJob.id;
                batchStatus.CWS_Error_Message__c='JOB DETAILS: '+(recordJob.SBQQ__JobDetails__c!=null? recordJob.SBQQ__StackTrace__c:'') +
                                (recordJob.SBQQ__StackTrace__c!=null?'\nSTACK TRACE: '+recordJob.SBQQ__StackTrace__c:'');
                batchStatus.CWS_Processed__c=(recordJob.SBQQ__JobStatus__c=='Failed' || recordJob.SBQQ__JobStatus__c=='Completed') ? true:false;
                renewalBatchStatusList.add(batchStatus);
                if(recordJob.SBQQ__JobStatus__c=='Failed'){
                    //Update Contract's Renewal Batch Failed Flag so that it will not be reprocessed again.
                    contractId=(Id)batchStatus.CWS_ContractId__c;
                    contractsToUpdate.add(new Contract(Id=contractId, CWS_Renewal_Batch_Failed__c=TRUE, 
                        CWS_Error_Message__c=batchStatus.CWS_Error_Message__c));
                }
            }
        }
        
        if(renewalBatchStatusList!=null && !renewalBatchStatusList.isEmpty()){
            upsert renewalBatchStatusList CWS_ContractId__c;
        }
        
        if(contractsToUpdate!=null && !contractsToUpdate.isEmpty()){
            update contractsToUpdate;
        }
    }   
    
}