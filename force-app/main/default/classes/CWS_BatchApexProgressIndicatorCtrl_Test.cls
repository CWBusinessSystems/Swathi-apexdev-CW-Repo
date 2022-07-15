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
@isTest
public Without Sharing class CWS_BatchApexProgressIndicatorCtrl_Test {
    @isTest
    public static void testGetApexjobRecord() {
        // schedule empty job to retreive job record
        CWS_BatchApexProgressIndicatorCtrlStub dummyJob = new CWS_BatchApexProgressIndicatorCtrlStub('select Id from User limit 5');
        Test.startTest();
        String jobId = database.executeBatch(dummyJob);
        Test.stopTest();
        system.debug('jobID'+jobId);
        AsyncApexJob jobInfo = CWS_BatchApexProgressIndicatorController.getBatchJobStatus(jobId);
        system.assertEquals(jobInfo.Id,jobId);
    }
    @isTest
    public static void testCatchStatment(){
        AsyncApexJob jobInfo = CWS_BatchApexProgressIndicatorController.getBatchJobStatus('7072C00001liO4XQAU');
    }
}