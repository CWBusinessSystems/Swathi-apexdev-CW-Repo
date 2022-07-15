global class CWS_TZ_Update implements Database.Batchable<sObject> {

global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,tz_sync__c FROM Account where tz_sync__c = false limit 90000';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accList) {
        for(Account acc : accList)
        {        
            acc.tz_sync__c = true;
            system.debug(acc.id);
            database.update(acc,false);
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        
  }
}