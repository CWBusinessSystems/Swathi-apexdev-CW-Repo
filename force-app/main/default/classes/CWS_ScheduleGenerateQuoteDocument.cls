Public class CWS_ScheduleGenerateQuoteDocument implements System.Schedulable{

    Public void execute(System.SchedulableContext sc){
        Database.executeBatch(new CWS_BatchGenerateQuoteDocument(),1);
    }
}