Public class CWS_RenewalSchedule implements System.Schedulable{

    Public void execute(System.SchedulableContext sc){
        Database.executeBatch(new CWS_RenewalBatch(),1);
    }
}