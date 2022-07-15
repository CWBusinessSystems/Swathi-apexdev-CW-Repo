Public class CWS_ScheduleAcceptRenewalQuotes implements System.Schedulable{

    Public void execute(System.SchedulableContext sc){
        Database.executeBatch(new CWS_BatchAcceptRenewalQuotes(),1);
    }
}