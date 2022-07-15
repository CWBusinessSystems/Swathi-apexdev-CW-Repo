/*Class Name: CWS_ManageIntegrationCalloutBatch2
*Description: Batch job to callout one record at a time
*Created By: Jeff Cochran
*Created On: 28/11/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Jeff Cochran           28/11/2020       ********           Batch job to callout one record at a time 
*/
global class CWS_ManageIntegrationCalloutBatch2 implements Database.Batchable<sObject>, Database.Stateful {

    Set<String> setAccount = new set<String>(); 
    global CWS_ManageIntegrationCalloutBatch2(Set <String> setIds) {
        System.debug('-------0005----'+setIds);   
        setAccount = setIds;
    }      
    global Database.QueryLocator  start(Database.BatchableContext bc) {
         System.debug('-------00051----'+setAccount); 
        String query = 'SELECT id,CWS_Manage_Integration_Error__c ,CWS_Manage_Integration_Sync_Status__c FROM Account where ID IN :setAccount';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Account> records){
        System.debug('-------0006----'+records);  
        List<Account> listAccount = new List<Account>();
        for(Account objAccount : records){
            objAccount.CWS_Manage_Integration_Sync_Status__c = 'Ready for Sync';
            listAccount.add(objAccount);
        }
        update listAccount;
    }    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    } 
}