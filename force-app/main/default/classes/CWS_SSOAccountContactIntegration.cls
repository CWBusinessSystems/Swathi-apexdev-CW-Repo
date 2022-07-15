/*Class Name: global with sharing class CWS_SSOAccountContactIntegration
*Description: Apex Rest endpoint to provide Account and Contract data to SSO gateway
*Created By: Carl Shahan
*Created On: 10/03/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 10/03/2020 CWH-996       Single Sign On (SSO) get account and contact data
*/
@RestResource(urlMapping = '/sso/account/*')
global with sharing class CWS_SSOAccountContactIntegration {
   
    @HttpGet
    global static Account getAccountContact() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        Account record;
        String accountId = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        String returnValue = '';

        try {

            if (accountId != null && accountId != '' && accountId != 'account') {

                record = [SELECT Id, Name, Phone, (SELECT Id, FirstName, LastName, Email, Phone, CWS_Phone_Company__c, CWS_Phone_Direct__c, CWS_Phone_Mobile__c, CWS_SSO_User_ID__c, CWS_Primary_Contact__c FROM Contacts) FROM Account WHERE Id = :accountId];
                System.debug('accountId = ' + accountId);
                System.debug('accountData query:' + record);
            }

            returnValue = JSON.serialize(record);
        }
        catch (QueryException ex) {

            System.debug('SOQL Exception: ' + ex.getMessage());

            response.statusCode = 400;
        }

        return record;
    }
}