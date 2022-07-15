Public class CWS_ScheduleAccpetAndCreateOrdBatch implements System.Schedulable{

    Public void execute(System.SchedulableContext sc){
        Database.executeBatch(new CWS_BatchAcceptQuoteAndCreateOrder(),1);
    }
}