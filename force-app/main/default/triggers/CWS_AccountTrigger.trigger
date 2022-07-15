/*Trigger Name: trigger CWS_AccountTrigger on Account
*Description: Trigger on Account
*Created By: Ankit
*Created On: 04/07/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Ankit                  04/07/2020      BED-5150                Default Account currency from Billing country
*Sudhir Moturu          4/29/2020       BED-1009                After Update added for opportunities to closed lost if the account restriction status is changed to non transactional
*Carl Shahan            09/14/2021                              Had to modifiy previous Deloitte solution because it would only fire it the CWS_Is_Partner value changed
*/
trigger CWS_AccountTrigger on Account (before insert,before update,after update) {

    CWS_TriggerDispatcher.Run(new CWS_AccountTriggerHandler());

    System.debug('Account trigger CWS_AccountTrigger fired');
  
    if (Trigger.isAfter) {

        System.debug('Account CWS_AccountTrigger Trigger.isAfter fired');
    
        if (CWS_SSOUpdatedAccountContacts.recursion) {
            
            String userInfoName = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

            System.debug('User currently triggering the CWS_AccountTrigger is ' + userInfoName);
            
            if (!System.isFuture() && !System.isBatch() && !System.isQueueable() && userInfoName != 'Integration User') {
                
                System.debug('Account trigger passed recursion and conditional parameters, checking if update is required');
                
                for (Account account : Trigger.New) { 
                    
                    if ((account.CWS_SSO_GUID__c == null || account.CWS_SSO_GUID__c.length() < 24) && (account.CWS_Is_Partner__c == true || account.CWS_Access_to_CW_University__c == true )) {

                        CWS_SSOUpdatedAccountContacts.postContactData(account.Id);
                        CWS_SSOUpdatedAccountContacts.recursion = false;
                        System.debug('Account trigger CWS_SSOUpdatedAccountContacts.postContactData fired with Account Id: ' + account.Id);
                    }
                }
            }
        }
    }
}