Public class CWS_SplitContractSchedule implements System.Schedulable{

    Public void execute(System.SchedulableContext sc){
        Database.executeBatch(new CWS_SplitContract(),1);
    }
}