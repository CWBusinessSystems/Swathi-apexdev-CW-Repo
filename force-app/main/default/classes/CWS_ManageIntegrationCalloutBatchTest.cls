/*Class Name: CWS_ManageIntegrationCalloutBatchTest
*Description: Test Class for CWS_ManageIntegrationCalloutBatch and CWS_ManageIntegrationCalloutBatch2
*Created By: Ankit
*Created On: 4/7/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Jeff Cochran           28/11/2020       ********           Test Class for CWS_ManageIntegrationCalloutBatch and CWS_ManageIntegrationCalloutBatch2  
*/

@isTest(SeeAllData=false)
public class CWS_ManageIntegrationCalloutBatchTest {
    
    @isTest static void testMethod1(){ 
        List<Id> listAIds = new List<Id>();
        Account a = new account();
        a.name = 'test accout';
        a.CWS_Manage_Integration_Sync_Status__c  = 'Ready for sync';
        a.CWS_Manage_Integration_Error__c = '';
        insert a;
        listAIds.add(a.id);
        
        CWS_ManageIntegrationCalloutBatch obj = new CWS_ManageIntegrationCalloutBatch(listAIds);
        Database.executeBatch(obj);
       }
}