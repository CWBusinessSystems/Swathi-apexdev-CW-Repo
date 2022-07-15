/*Class Name: CWS_DataTransferWebService
*@Description: Rest API callout to lower environment to transfer Account, Contract, Quote, and Product data
*Created By: Carl Shahan
*Created On: 12/09/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 12/09/2020 N/A           Rest API callout to lower environment to transfer Account, Contract, Quote, and Product data
*/
public with sharing class CWS_DataTransferWebService {
    
    public static Http http = new Http();
    public static HTTPResponse response;
    public static HttpRequest request;
 
    
    public static void transferAccountData(Id[] targetAccounts) {

        // Get a map of all the Account field names schema.
        Map<String, Schema.SObjectField> accountFieldMap = Account.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String accountFieldNames = '';
        for (String key : accountFieldMap.keySet()) { accountFieldNames += accountFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] accountQueryValues = accountFieldNames.split(' ');
        // Build a dynamic query string.
        String accountQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(accountQueryValues, ',')) + ' FROM Account WHERE Id IN :targetAccounts';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<Account> accountList = Database.query(accountQuery);  
    

        // Get a map of all the Contact field names schema.
        Map<String, Schema.SObjectField> contactFieldMap = Contact.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String contactFieldNames = '';
        for (String key : contactFieldMap.keySet()) { contactFieldNames += contactFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] contactQueryValues = contactFieldNames.split(' ');
        // Build a dynamic query string.
        String contactQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(contactQueryValues, ',')) + ' FROM Contact WHERE AccountId IN :targetAccounts';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<Contact> contactList = Database.query(contactQuery);  


        // Get a map of all the Contract field names schema.
        Map<String, Schema.SObjectField> contractFieldMap = Contract.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String contractFieldNames = '';
        for (String key : contractFieldMap.keySet()) { contractFieldNames += contractFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] contractQueryValues = contractFieldNames.split(' ');
        // Build a dynamic query string.
        String contractQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(contractQueryValues, ',')) + ' FROM Contract WHERE AccountId IN :targetAccounts';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<Contract> contractList = Database.query(contractQuery); 

        
        // Get a map of all the Opportunity field names schema.
        Map<String, Schema.SObjectField> opportunityFieldMap = Opportunity.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String opportunityFieldNames = '';
        for (String key : opportunityFieldMap.keySet()) { opportunityFieldNames += opportunityFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] opportunityQueryValues = opportunityFieldNames.split(' ');
        // Build a dynamic query string.
        String opportunityQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(opportunityQueryValues, ',')) + ' FROM Opportunity WHERE AccountId IN :targetAccounts';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<Opportunity> opportunityList = Database.query(opportunityQuery); 
        // Get all the Opportunity recird Ids to query the OpportunityLineItems
        List<Id> allOpportunityIds = new List<Id>();
        for (Opportunity opportunityItem : opportunityList) { allOpportunityIds.add(opportunityItem.Id); }

        
        // Get a map of all the OpportunityLineItem field names schema.
        Map<String, Schema.SObjectField> opportunityLineItemFieldMap = OpportunityLineItem.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String opportunityLineItemFieldNames = '';
        for (String key : opportunityLineItemFieldMap.keySet()) { opportunityLineItemFieldNames += opportunityLineItemFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] opportunityLineItemQueryValues = opportunityLineItemFieldNames.split(' ');
        // Build a dynamic query string.
        String opportunityLineItemQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(opportunityLineItemQueryValues, ',')) + ' FROM OpportunityLineItem WHERE OpportunityId IN :allOpportunityIds';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<OpportunityLineItem> opportunityLineItemList = Database.query(opportunityLineItemQuery); 

        
        // Get a map of all the Quote field names schema.
        Map<String, Schema.SObjectField> quoteFieldMap = SBQQ__Quote__c.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String quoteFieldNames = '';
        for (String key : quoteFieldMap.keySet()) { quoteFieldNames += quoteFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] quoteQueryValues = quoteFieldNames.split(' ');
        // Build a dynamic query string.
        String quoteQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(quoteQueryValues, ',')) + ' FROM SBQQ__Quote__c WHERE SBQQ__Account__c  IN :targetAccounts';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<SBQQ__Quote__c> quoteList = Database.query(quoteQuery); 
        // Get all the Quote record Ids to query the SBQQ__QuoteLine__c items
        List<Id> allQuoteIds = new List<Id>();
        for (SBQQ__Quote__c quoteItem : quoteList) { allQuoteIds.add(quoteItem.Id); }
         
        
        // Get a map of all the SBQQ__QuoteLine__c field name schema.
        Map<String, Schema.SObjectField> quoteLineFieldMap = SBQQ__QuoteLine__c.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String quoteLineFieldNames = '';
        for (String key : quoteLineFieldMap.keySet()) { quoteLineFieldNames += quoteLineFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] quoteLineQueryValues = quoteLineFieldNames.split(' ');
        // Build a dynamic query string.
        String quoteLineQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(quoteLineQueryValues, ',')) + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :allQuoteIds';
        // Execute the dynamic query
        List<SBQQ__QuoteLine__c> quoteLineList = Database.query(quoteLineQuery);


        // Get a map of all the QuoteDocument field names schema.
        Map<String, Schema.SObjectField> quoteDocumentFieldMap = SBQQ__QuoteDocument__c.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String quoteDocumentFieldNames = '';
        for (String key : quoteDocumentFieldMap.keySet()) { quoteDocumentFieldNames += quoteDocumentFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] quoteDocumentQueryValues = quoteDocumentFieldNames.split(' ');
        // Build a dynamic query string.
        String quoteDocumentQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(quoteDocumentQueryValues, ',')) + ' FROM SBQQ__QuoteDocument__c WHERE SBQQ__Quote__c IN :allQuoteIds';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<SBQQ__QuoteDocument__c> quoteDocumentList = Database.query(quoteDocumentQuery); 
        
        
        // Get a map of all the Subscription field names schema.
        Map<String, Schema.SObjectField> subscriptionFieldMap = SBQQ__Subscription__c.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String subscriptionFieldNames = '';
        for (String key : subscriptionFieldMap.keySet()) { subscriptionFieldNames += subscriptionFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] subscriptionQueryValues = subscriptionFieldNames.split(' ');
        // Build a dynamic query string.
        String subscriptionQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(subscriptionQueryValues, ',')) + ' FROM SBQQ__Subscription__c WHERE SBQQ__Account__c  IN :targetAccounts';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<SBQQ__Subscription__c> subscriptionList = Database.query(subscriptionQuery); 


        // Get a map of all the Order field names schema.
        Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String orderFieldNames = '';
        for (String key : orderFieldMap.keySet()) { orderFieldNames += orderFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] orderQueryValues = orderFieldNames.split(' ');
        // Build a dynamic query string.
        String orderQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(orderQueryValues, ',')) + ' FROM Order WHERE AccountId IN :targetAccounts';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<Order> orderList = Database.query(orderQuery);
        List<Id> allOrderIds = new List<Id>();
        for (Order orderItem : orderList) { allOrderIds.add(orderItem.Id); }


        // Get a map of all the OrderItem field names schema.
        Map<String, Schema.SObjectField> orderItemFieldMap = OrderItem.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String orderItemFieldNames = '';
        for (String key : orderItemFieldMap.keySet()) { orderItemFieldNames += orderItemFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] orderItemQueryValues = orderItemFieldNames.split(' ');
        // Build a dynamic query string.
        String orderItemQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(orderItemQueryValues, ',')) + ' FROM OrderItem WHERE OrderId IN :allOrderIds';
        // Execute the dynamic query making sure to use the escapeSingleQuotes method to prevent SOQL injection security vunerability
        List<OrderItem> orderItemList = Database.query(orderItemQuery);


        // Get a map of all the Zuora__Subscription__c field name schema.
        Map<String, Schema.SObjectField> zuoraSubscriptionFieldMap = Zuora__Subscription__c.sObjectType.getDescribe().fields.getMap();
        // Convert the key set schema values to strings
        String zuoraSubscriptionFieldNames = '';
        for (String key : zuoraSubscriptionFieldMap.keySet()) { zuoraSubscriptionFieldNames += zuoraSubscriptionFieldMap.get(key) + ' '; }
        // Split the sting into an array 
        String[] zuoraSubscriptionQueryValues = zuoraSubscriptionFieldNames.split(' ');
        // Build a dynamic query string.
        String zuoraSubscriptionQuery = 'SELECT ' + String.escapeSingleQuotes(String.join(zuoraSubscriptionQueryValues, ',')) + ' FROM Zuora__Subscription__c WHERE Zuora__Account__c IN :targetAccounts';
        // Execute the dynamic query
        List<Zuora__Subscription__c> zuoraSubscriptionList = Database.query(zuoraSubscriptionQuery);

        CWS_AccountDataWrapper dataWrapper = new CWS_AccountDataWrapper();

        dataWrapper.accountData = accountList;
        dataWrapper.contactData = contactList;
        dataWrapper.contractData = contractList;
        dataWrapper.opportunityData = opportunityList;
        dataWrapper.opportunityLineItemData = opportunityLineItemList;
        dataWrapper.quoteData = quoteList;
        dataWrapper.quoteLineData = quoteLineList;
        dataWrapper.quoteDocumentData = quoteDocumentList;
        dataWrapper.subscriptionData = subscriptionList;
        dataWrapper.orderData = orderList;
        dataWrapper.orderItemData = orderItemList;
        dataWrapper.zuoraSubscriptionData = zuoraSubscriptionList;


        String dataWrapperJson = (String)JSON.serialize(dataWrapper);
        System.debug('dataWrapperJson = ' + dataWrapperJson);
        addAccount(dataWrapperJson);
    }
 
    @future(callout=true)
    public static void addAccount(String wrapperJson) {
 
        request = new HttpRequest();
        request.setTimeout(120000);
        request.setMethod('POST');
        request.setEndpoint('callout:DataTransferWebService/services/apexrest/transfer/data');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(wrapperJson);
 
        response = http.send(request); 
 
        System.debug(response.getBody());
    }
}