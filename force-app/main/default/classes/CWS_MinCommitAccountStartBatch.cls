/*Class Name: CWS_MinCommitAccountStartBatch
*Description: Batch Class replaces all min commit amount with 0
*Created By: Sudhir Moturu
*Created On: 08/06/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Sudhir Moturu               08/06/2020      BED-13015          Populate mincommit value with 0 for all accounts
*/
public with sharing class CWS_MinCommitAccountStartBatch implements Database.Batchable < sObject >,Database.stateful{
    public List<Id> lstAcctIds = new List<Id>();
    /* Parameterized cunstructor to run batch for specific Accounts
    */
    Public CWS_MinCommitAccountStartBatch(List<Id> lstAcctIds){
        this.lstAcctIds = lstAcctIds;
    }
    Public CWS_MinCommitAccountStartBatch(){}

    public Database.QueryLocator start(Database.BatchableContext bc) {        
        String query = 'Select id,CWS_Minimum_Commit_Amount__c from Account '+ 
                        'where CWS_Minimum_Commit_Amount__c != null AND CWS_Minimum_Commit_Amount__c != 0';
            if(lstAcctIds.Size()>0){
                query += ' AND Id IN :lstAcctIds';
            }
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc,List<Account> scope) {
        
        try{
            if(scope.size()>0){
                for(Account objAcct: scope){
                    objAcct.CWS_Minimum_Commit_Amount__c = 0;
                }
                List<Database.SaveResult> results = Database.update(scope);
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_MinCommitAccountStartBatch' , 'BatchJob','Update Min Commit Amount ', null , null );
            }
        }catch(Exception ex){
            CWS_ExceptionHandler.logException( ex,'BatchClass' , 'CWS_MinCommitAccountBatch' , 'Execute' ,'', null , null ,'update' , null);
        }

    }
    public void finish(Database.BatchableContext bc) {
        if(lstAcctIds.size()>0){
            Id batchJobId = Database.executeBatch(new CWS_MinCommitAccountBatch(lstAcctIds),200);
        }
        else{
            Id batchJobId = Database.executeBatch(new CWS_MinCommitAccountBatch(),200);
        }
    }
}