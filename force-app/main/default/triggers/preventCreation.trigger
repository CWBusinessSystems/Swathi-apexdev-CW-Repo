trigger preventCreation on Case (before insert) {
CWS_caseInsertTriggerHandler.domainErrorValidation(trigger.new);
}