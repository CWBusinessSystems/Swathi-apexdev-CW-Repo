/**
* @description       : 
* @author            : DPC Advictoriam Solutions
* @group             : 
* @last modified on  : 06-18-2021
* @last modified by  : DPC Advictoriam Solutions
* Modifications Log 
* Ver   Date         Author                      Modification
* 1.0   06-18-2021   DPC Advictoriam Solutions   Initial Version
**/
public Without Sharing class  CWS_BatchApexProgressIndicatorController {
    @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(Id jobID){
        try{
            AsyncApexJob jobInfo = [SELECT ApexClassId,Status, NumberOfErrors,JobItemsProcessed,TotalJobItems,
                                    CompletedDate,ExtendedStatus,JobType,MethodName FROM AsyncApexJob WHERE Id = :jobID];
            return jobInfo;
        } catch(exception e){
            return null;
        }
    }
}