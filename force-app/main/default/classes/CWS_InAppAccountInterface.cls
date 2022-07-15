/*Class Name: CWS_InAppAccountInterface
*Description: Apex Rest endpoint to provide Account, Contract, Quote, and Product data to In App Purchasing
*Created By: Carl Shahan
*Created On: 08/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 08/13/2020 CWH-996       In App Purchasing get account data
*/
@RestResource(urlMapping='/inapp/account/*')
global with sharing class CWS_InAppAccountInterface {
    
    @HttpGet
    global static Account getAccounts() {
      
        Account accountData;  
        RestRequest request = RestContext.request;
        String accountId = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);

        System.debug(accountId);

        if (accountId != null && accountId != '' && accountId != 'Accounts') {

            List<Account> account = [SELECT Id, Name, CWS_Account_Restriction_Status__c FROM Account WHERE Id = :accountId];

            if (!account.isEmpty()) {

                accountData = account[0];

                System.debug('Successfully found account with accountId ' + accountId);
                System.debug('Successfully found account query result: ' + accountData);
            }
            else {
                // Account for account id not found and invalid id format
                try {
                    accountData = new Account();
                    accountData.Id = accountId;
                }
                catch (Exception e) {

                    accountData = new Account();
                    System.debug('Empty account exception ' + e );
                }

                System.debug('Did NOT find accountId ' + accountId);
                System.debug('Did NOT find account creating shell:' + accountData);
            }
        }
        else {
            // Account Id was not provided, return an empty object
            accountData = new Account();
            
            System.debug('accountId was not provided returning empty object');
        }

        System.debug('Id ' + accountData.Id + ' Name ' + accountData.Name + ' CWS_Account_Restriction_Status__c ' + accountData.CWS_Account_Restriction_Status__c);

        String returnData = JSON.serialize(accountData);

        System.debug(accountData);
        
        return accountData;
    }
}