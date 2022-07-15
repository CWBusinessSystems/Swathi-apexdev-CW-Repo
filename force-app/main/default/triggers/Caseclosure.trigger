trigger Caseclosure on Case (after update) {
//Trigger will run only after update of Case records
    if(Trigger.isAfter && Trigger.isUpdate){
    //CaseClosureTriggerHandler Class will call method processClosedCases
        CaseClosureTriggerHandler.processClosedCases(trigger.New);
    }
}