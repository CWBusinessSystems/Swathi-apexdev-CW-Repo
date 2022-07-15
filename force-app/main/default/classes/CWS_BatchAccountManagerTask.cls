/*Class Name: CWS_BatchAccountManagerTask
* @description : To schedule the batch class for creating task automatically for Account Manager if No OAAM is assigned in the Account team.
*Created By: mahak bansal
*Created On:  24/3/2021 
*Ticket no :- 14528272  
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*mahak bansal          24/3/2021            -                  Initial Version
*mahak bansal          2/4/2021             -                  updated , Error Logs records added.
*/
public class CWS_BatchAccountManagerTask implements Database.Batchable<sObject>,Database.Stateful {
	private String queryString ;
    private Set<Id> tasksCreated=new Set<Id>();
    private list<CWS_Error_Log__c> errLogList = new list<CWS_Error_Log__c>();
    
    /**
    * @description Start method of the Batch to fetch all the accounts which have the Account Team associated with it
    */    
    public Database.QueryLocator start(Database.BatchableContext bc){
         queryString='SELECT ID,(SELECT ID,TeamMemberRole,UserId FROM accountTeamMembers) From Account WHERE Id IN (SELECT AccountId FROM accountTeamMember WHERE TeamMemberRole=\'Account Manager\')';
         return Database.getQueryLocator(queryString);
    }

    /**
    * @description Process each batch of the job to create tasks for the Account Managers
    */ 
    public void execute(Database.BatchableContext bc, List<sObject>scope){ 
        List<Account> accList=scope;     
		Map<Id,Id> mapAccMembers=new Map<Id,Id>();
        Set<Id> setAccId = new Set<Id>();
        Boolean isOAAM=false;
        DateTime dTime = Datetime.now();
        Date todaysDate= date.newinstance(dTime.year(), dTime.month(), dTime.day());  
        String currentYear=dTime.year()+'';

        try{    
            if(currentYear.equals(System.Label.CWS_Account_Task_Creation_Year) && (System.Label.CWS_Account_Task_SWITCH_ON).equals(CWS_ConstantClass.SWITCH_BATCH_ON))
            {   
                for(Account acc : accList){
                    if(acc.accountTeamMembers.size()>0){
                        //Condition that will make sure that if there is no OAAM then only create task for AM
                        for(AccountTeamMember teamMember:acc.accountTeamMembers){
                            if(teamMember.TeamMemberRole == 'Outbound Associate Account Manager'){
                                isOAAM=true;
                            }
                        }
                        //If an account manager is present in the Account team, then only process the records.
                        for(AccountTeamMember teamMember:acc.accountTeamMembers){
                            if(teamMember.TeamMemberRole == 'Account Manager' && !isOAAM){
                                mapAccMembers.put(acc.Id,teamMember.UserId);
                                setAccId.add(acc.Id);
                            }
                        }                       
                        isOAAM=false;
                    }
                }                
                createTasks(accList,setAccId,mapAccMembers);                       
            }
        }catch(exception ex){
            CWS_ExceptionHandler.logException( ex,'BatchClass' , 'CWS_BatchAccountManagerTask' , 'Execute' ,'', null , null ,'insert' , null);
        }
    }
    
    /**
    * @description Send the email to the email id mentioned in the CWS Org default field about the records processed.
    */
    public void finish(Database.BatchableContext bc){
        try{
            if(errLogList != NULL){
                //insert Error Logs records once the batch process all the records
                insert errLogList;
            }
        }catch(DMLException e){  
            CWS_ExceptionHandler.insertException('CWS_Error_Log__c' , 'CWS_BatchAccountManagerTask' , 'finish' , e.getCause().getMessage() , '', e.getMessage() , String.valueOf(e.getLineNumber()) , e.getTypeName() , '' , '' , 'While inserting error log record in Finish of a batch class' , '');    
        }
         //Query Async Apex job to send the status in email body
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email
                          FROM AsyncApexJob WHERE Id =
                          :BC.getJobId()];
        
        String subject='Account Manager Task Created with status: '+a.status;
        String msgBody='Dear User, <br/><br/>';
        msgBody+= 'The apex job completed with Total '+ a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.<br/>' ;
        msgBody+= '<br/> <br/> For Failed records you can check the failures on Error Logs object by filtering context as CWS_BatchAccountManagerTask';
                
        CWS_Org_Defaults__c	 cwsDef=CWS_Org_Defaults__c.getOrgDefaults();
        String[] toAddresses =  new String[]{} ;
        toAddresses = CWS_Org_Defaults__c.getOrgDefaults().CWS_Account_Task_Notification_Email__c.split(';');
        
        CWS_CommonUtility.sendEmail(subject, msgBody, toAddresses);
    }

    /**
    * @description This method creates the task for the Account Managers
    */
    private void createTasks(List<Account> accList,Set<Id> setAccId,Map<Id,Id> mapAccMembers){
        List<Task> taskList = new List<Task>();
        Id recordtypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('AMCONTACT').getRecordTypeId();
        DateTime dTime = Datetime.now();
        Date todaysDate= date.newinstance(dTime.year(), dTime.month(), dTime.day());  
        
        for(Account acc : accList){ 
            if(setAccId.contains(acc.Id) && mapAccMembers.get(acc.Id)!=null){ 
                Task task = new Task();
                task.RecordTypeId = recordtypeId;
                task.Subject = 'AMCONTACT '+ dTime.format('MMMM')+ ' ' + dTime.year();
                task.Status = 'Do First';
                task.Priority = 'Normal';
                task.ActivityDate = todaysDate;
                task.Type = 'Call';
                task.WhatId = acc.Id;
                task.OwnerId = mapAccMembers.get(acc.Id);
                taskList.add(task);
                }             
            }    
            System.debug('@@@@in createtask()---taskList.size '+taskList.size());

            if(!taskList.isEmpty()){
                List<Database.SaveResult> insertResults= Database.insert(taskList,false);
                for(Integer i=0;i<insertResults.size();i++){
                    if (!insertResults.get(i).isSuccess()){
                        // DML operation failed
                        //Creating our own Error log records as we need to retain the context in a batch so 
                        //that at the end we can insert the error logs once all records are processed
                        CWS_Error_Log__c errlogObj = CWS_ExceptionHandler.initializeAndReturnDMLErrorLogs('CWS_BatchAccountManagerTask','BATCH CLASS','execute method-batch',
                                                                                                            JSON.serialize( insertResults.get(i).getErrors()),'','','');
                        errLogList.add(errlogObj);                            
                    }
                    else{
                        tasksCreated.add(insertResults.get(i).getId());
                    }
                }
            }        
    }
    
}