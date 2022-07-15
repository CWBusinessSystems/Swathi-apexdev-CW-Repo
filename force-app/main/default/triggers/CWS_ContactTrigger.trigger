/*Trigger Name: trigger CWS_ContactTrigger on Contact
*Description: Trigger on Contact
*Created By: Sudhir Moturu
*Created On: 05/MAY/2020

*Modification Log
*---------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*---------------------------------------------------------------------------------------------
*Sudhir Moturu          05/MAY/2020     BED-6452                After Update added for opportunities to closed lost if the account restriction status is changed to non transactional
*Carl Shahan            09/14/2021                              Had to modifiy previous Deloitte solution because it would only fire it the CWS_Is_Partner value changed
*/
trigger CWS_ContactTrigger on Contact (before insert, before update, after insert, after update) {

    CWS_TriggerDispatcher.Run(new CWS_ContactTriggerHandler());

    System.debug('Contact trigger CWS_ContactTrigger fired');

    if(Trigger.isAfter) {
    
        if (CWS_SSOUpdatedAccountContacts.recursion) {

            String userInfoName = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

            System.debug('User currently triggering the CWS_ContactTrigger is ' + userInfoName);

            if (!System.isFuture() && !System.isBatch() && !System.isQueueable() && userInfoName != 'Integration User') {

                System.debug('Contact trigger passed recursion and conditional parameters, checking if update is required');
            
                for (Contact contact : Trigger.New) { 

                    if (contact.CWS_Primary_Contact__c == true && (contact.CWS_SSO_User_ID__c == null || contact.CWS_SSO_User_ID__c.length() < 24)) {

                        CWS_SSOUpdatedAccountContacts.postContactData(contact.AccountId);
                        CWS_SSOUpdatedAccountContacts.recursion = false;
                        System.debug('Contact trigger CWS_SSOUpdatedAccountContacts.postContactData fired with Account Id: ' + contact.AccountId);
                    }
                }
            }
        }
    }   
}