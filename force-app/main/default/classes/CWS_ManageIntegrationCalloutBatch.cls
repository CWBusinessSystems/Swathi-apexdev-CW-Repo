/*Class Name: CWS_ManageIntegrationCalloutBatch
*Description: Batch job to clear the Ready for sync values
*Created By: Jeff Cochran
*Created On: 28/11/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Jeff Cochran           28/11/2020       ********     Batch job to clear the Ready for sync values 
*/
global class CWS_ManageIntegrationCalloutBatch implements Database.Batchable<sObject> , Database.Stateful{
    
    Set<String> setAccount = new set<String>(); 
    global CWS_ManageIntegrationCalloutBatch(List <String> listIds) {
        System.debug('-------0005----'+listIds);   
        setAccount.addAll(listIds);
    } 
    
    //Set<String> setAccount = new set<String>();   
    global Database.QueryLocator  start(Database.BatchableContext bc) {
        String query = 'SELECT id,CWS_Manage_Integration_Error__c ,CWS_Manage_Integration_Sync_Status__c FROM Account where  CWS_Manage_Integration_Sync_Status__c = \'Ready for Sync\' and CWS_Manage_Integration_Error__c != \'Synced\' and ID in : setAccount limit 5';
       
         System.debug('-------0001----'+setAccount);    
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Account> records){
        List<Account> listAccount = new List<Account>();
        for(Account objAccount : records){
            objAccount.CWS_Manage_Integration_Sync_Status__c = '';
            listAccount.add(objAccount);
             System.debug('-------0002----');   
        }
        update listAccount;
        System.debug('-------0003----');   
    }    
    global void finish(Database.BatchableContext bc){
        System.debug('-------0004----'+setAccount);   
       CWS_ManageIntegrationCalloutBatch2 obj = new CWS_ManageIntegrationCalloutBatch2(setAccount);
       Database.executeBatch(obj,1);
    } 
}