trigger CWS_ContentVersionTrigger on ContentVersion (before insert,after insert) {
 CWS_TriggerDispatcher.Run(new CWS_AttachmentTriggerHandler());
}