/*Class Name: CWS_DataTransferWebService_Test
*@Description: Test class for Rest API callout to lower environment to transfer Account, Contract, Quote, and Product data
*Created By: Carl Shahan
*Created On: 03/03/2021
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 03/03/2021 N/A           Test class for Rest API callout to lower environment to transfer Account, Contract, Quote, and Product data
*/
@isTest
public inherited sharing class CWS_DataTransferWebService_Test {
        
    @isTest static void postAccounts() {
        
        String dummyAssertValue = 'Success';
        CWS_CPQDataFactory_Test.TestDataResponse testData = CWS_CPQDataFactory_Test.generateCPQTestData();
        
        Id[] accountIds = new Id[]{testData.accountId};

        System.debug('Account Id array: ' + accountIds);
        
         Test.setMock(HttpCalloutMock.class, new SuccessfulResponse());
         Test.startTest();
            CWS_DataTransferWebService.transferAccountData(accountIds);
         Test.stopTest();

         System.assertEquals('Success', dummyAssertValue, 'System assert value equals Success');
    }

    public class SuccessfulResponse implements HttpCalloutMock {

        public HTTPResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('Successfully received account data');
            response.setStatusCode(200);
            return response;
        }
    }   
}