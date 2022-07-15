global class CWS_ProductSyncPbeScheduler implements Schedulable 
{
    global void execute(SchedulableContext sc) {
        CWS_ProductSyncPBEBatch pbe = new CWS_ProductSyncPBEBatch(); 
        database.executebatch(pbe);
    }    
}