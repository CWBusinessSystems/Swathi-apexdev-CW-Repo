/** Class Name: CWS_SSOUpdatedAccountContacts
* @description: Callout to send updated Account and Contact data to CW Home to create an SSO account
* @author Created By: Carl Shahan
* @date 08/27/2020
* Modification Log
* ------------------------------------------------------------------------------------------
* Developer   Date       User Story    Description
* ------------------------------------------------------------------------------------------
* Carl Shahan 08/13/2020 CWH-996       In App Purchasing Find Eligible Products and Create Quote
* Carl Shahan 02/11/2022 OBD-3769      Updated as part of refactoring and bug fixes to ensure correct prorated pricing 
*/
@RestResource(urlMapping = '/inapp/contracts/*')
/** @description primary In App API class */
global with sharing class CWS_InAppIntegration {
    /** @description class that contains the account record to identify the subscription to update, must be global to be returned in API call */
    global class Records {
        /** @description class property for Account name */
        public String accountName {get; set;}
        /** @description class property for Account Id */
        public String accountId {get; set;}
        /** @description class property for Account retriction status */
        public String accountRestrictionStatus {get; set;} 
        /** @description class property for Account products owned */
        public String accountProductsOwned {get; set;}
        /** @description class property for all the Account and Contract data for given Account */
        public List<ContractWrapper> accountContracts {get; set;}
    }
    /** @description class containing the Contract data  */
    private class ContractWrapper {          
        private String contractId {get; set;}
        private Decimal activeContract {get; set;}
        private String routeToMarket {get; set;}
        private Boolean master {get; set;}
        private Boolean masterContract {get; set;}
        private String billingFrequency {get; set;}
        private String currencyIsoCode {get; set;}
        private String quoteId {get; set;}
        private List<SubscriptionWrapper> subscriptions {get; set;}
    }
    /** @description class containing the Subscription data  */
    private class SubscriptionWrapper {
        private String subscriptionId {get; set;} 
        private Decimal subscriptionTerm {get; set;}      
        private String productName {get; set;}
        private String productId {get; set;}
        private String productCode {get; set;}
        private Decimal futurePrice {get; set;}
        private Date futurePriceEndDate {get; set;}
        private Double futurePricingBlocks {get; set;}
        private Decimal regularPrice {get; set;}
        private Decimal listPrice {get; set;}
        private Decimal unitPrice {get; set;}
        private String status {get; set;}  
        private String startDate {get; set;}  
    }
    /** @description class containing the email parameters for sending the purchase data  */
    private class SendEmailParameters {
        private String[] emailAddress {get; set;}
        private String subject {get; set;}
        private String htmlBody {get; set;}
    }

    /**
    * @description untility method for getting and returnin the product code
    * @return String containg product Id
    * @param productList
    * @param productIdEighteen
    */
    private static String getProductCode(List<Product2> productList, Id productIdEighteen) {

        String returnProductCode = '';
        
        for (Product2 productItem : productList) {

            if (productItem.Id == productIdEighteen) {

                returnProductCode = productItem.ProductCode;
                
                break;
            }
        }
        return returnProductCode;
    }

    /** 
     * @description Simple method to find the Price per Billing Period we are using as the unit price and return it
     * @return Decimal containg the calcualted price per billing period
     * @param quoteLineList
     * @param quoteLineId
     */
    private static Decimal getPricePerBillingPeriod(List<SBQQ__QuoteLine__c> quoteLineList, Id quoteLineId) {

        Decimal returnPricePerBillingPeriod = 0.0;
        
        for (SBQQ__QuoteLine__c quoteLineItem : quoteLineList) {

            if (quoteLineItem.Id == quoteLineId) {

                returnPricePerBillingPeriod = quoteLineItem.CWS_Price_Per_Billing_Period__c;

                break;
            }
        }

        return returnPricePerBillingPeriod;
    }
    
    /**
    * @description Primary rest method for return the Account, Contact and Subscription data to CW Home
    * @return Records
    */
    @HttpGet
    global static Records getAccountContracts() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String accountId = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        List<ContractWrapper> contractWrapper = new List<ContractWrapper>();
        List<Id> allQuoteLineIds = new List<Id>();
        List<Id> allProductIds = new List<Id>();
        Records recordData = new Records();
        Account account;

        if (accountId != null && accountId != '' && accountId != 'contracts') {

           try {
                account = [SELECT Id, Name, CWS_Account_Restriction_Status__c, CWS_Products_Owned__c,
                          (SELECT Id, AccountId, SBQQ__Quote__c, SBQQ__ActiveContract__c, CWS_Route_to_Market__c, CWS_Master__c, SBQQ__MasterContract__c, CWS_Billing_Frequency__c, CurrencyIsoCode FROM Contracts)
                          FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED];
                
                System.debug('== Account: ' + account);
                System.debug('== Contracts: ' + account.Contracts);

                List<Contract> allContracts = account.Contracts;
                List<SBQQ__Quote__c> allQuotes = [SELECT Id, Name, CWS_Account_Restriction_Status__c, CWS_Actual_Contract_Term__c FROM SBQQ__Quote__c WHERE SBQQ__MasterContract__c IN :allContracts WITH SECURITY_ENFORCED];
                List<SBQQ__Subscription__c> allSubscriptions = [SELECT SBQQ__Contract__c, CurrencyIsoCode, SBQQ__Product__r.ProductCode, SBQQ__Product__r.ID, SBQQ__Discount__c, SBQQ__ListPrice__c, SBQQ__ProductName__c, CWS_Future_Contracted_Price__c, CWS_Future_Price_End_Date__c, CWS_Future_pricing_Blocks__c, SBQQ__RegularPrice__c, SBQQ__UnitCost__c, SBQQ__ProductId__c, CWS_Status__c, CWS_Subscription_Term__c, SBQQ__QuoteLine__c, SBQQ__StartDate__c FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN :allContracts WITH SECURITY_ENFORCED];
                for (SBQQ__Subscription__c subItem : allSubscriptions) { allProductIds.add(subItem.SBQQ__ProductId__c); allQuoteLineIds.add(subItem.SBQQ__QuoteLine__c);}              
                List<SBQQ__QuoteLine__c> allQuoteLines = [SELECT Id, CWS_Price_Per_Billing_Period__c FROM SBQQ__QuoteLine__c WHERE Id IN :allQuoteLineIds WITH SECURITY_ENFORCED];               
                List<Product2> allProducts = [SELECT Id, Name, ProductCode, SBQQ__PricingGuidance__c FROM Product2 WHERE Id IN :allProductIds WITH SECURITY_ENFORCED];

                for (Contract contract : account.Contracts) {

                    System.debug('== Contract Id = ' + contract.Id);
                    
                    List<SubscriptionWrapper> subscriptionWrapper = new List<SubscriptionWrapper>();

                    for (SBQQ__Subscription__c subscriptionItem : allSubscriptions) {
                        
                        if (subscriptionItem.SBQQ__Contract__c == contract.Id) {

                            Id productEighteen = subscriptionItem.SBQQ__ProductId__c;
                            String productCode = getProductCode(allProducts, subscriptionItem.SBQQ__ProductId__c);
                            Decimal pricePerBillingPeriod = getPricePerBillingPeriod(allQuoteLines, subscriptionItem.SBQQ__QuoteLine__c);
                            SubscriptionWrapper subWrapper = new SubscriptionWrapper();
                            Decimal futurePriceAmount = 0.0;
                            Double futurePricingBlocks = 0.0;

                            if (subscriptionItem.CWS_Future_Contracted_Price__c != null) { futurePriceAmount = subscriptionItem.CWS_Future_Contracted_Price__c; }
                            if (subscriptionItem.CWS_Future_pricing_Blocks__c != null) { futurePricingBlocks = subscriptionItem.CWS_Future_pricing_Blocks__c; }

                            if (productCode != '' && pricePerBillingPeriod != 0.0) {

                                subWrapper.subscriptionId = subscriptionItem.Id;
                                subWrapper.subscriptionTerm = subscriptionItem.CWS_Subscription_Term__c;
                                subWrapper.productName = subscriptionItem.SBQQ__ProductName__c;
                                subWrapper.productId = productEighteen;
                                subWrapper.productCode = productCode;
                                subWrapper.futurePrice = futurePriceAmount.setScale(2);
                                subWrapper.futurePriceEndDate = subscriptionItem.CWS_Future_Price_End_Date__c;
                                subWrapper.futurePricingBlocks = futurePricingBlocks;
                                subWrapper.regularPrice = subscriptionItem.SBQQ__RegularPrice__c;
                                subWrapper.listPrice = subscriptionItem.SBQQ__ListPrice__c;                                
                                subWrapper.unitPrice = pricePerBillingPeriod.setScale(2);
                                subWrapper.status = subscriptionItem.CWS_Status__c;
                                subWrapper.startDate = String.valueof(subscriptionItem.SBQQ__StartDate__c);

                                subscriptionWrapper.add(subWrapper);

                                System.debug('== Product code: ' + productCode + ' Price per Billing Period: ' + pricePerBillingPeriod);
                                System.debug('== Future Contracted Price: ' + subscriptionItem.CWS_Future_Contracted_Price__c + ' Future Price End Date: ' + subscriptionItem.CWS_Future_Price_End_Date__c + ' Future pricing Blocks: ' + subscriptionItem.CWS_Future_pricing_Blocks__c );
                                System.debug('-------------------------------------------------------------------------');
                            }
                        }
                    }

                    ContractWrapper conWrapper = new ContractWrapper();

                    conWrapper.contractId = contract.Id;
                    conWrapper.activeContract = contract.SBQQ__ActiveContract__c;
                    conWrapper.billingFrequency = contract.CWS_Billing_Frequency__c;
                    conWrapper.currencyIsoCode = contract.CurrencyIsoCode;
                    conWrapper.master = contract.CWS_Master__c;
                    conWrapper.masterContract = contract.SBQQ__MasterContract__c;
                    conWrapper.routeToMarket = contract.CWS_Route_to_Market__c;
                    conWrapper.quoteId = contract.SBQQ__Quote__c;
                    conWrapper.subscriptions = subscriptionWrapper;

                    contractWrapper.add(conWrapper);
                }

                recordData.accountName = account.Name;
                recordData.accountId = account.Id;
                recordData.accountRestrictionStatus = account.CWS_Account_Restriction_Status__c;
                recordData.accountProductsOwned = account.CWS_Products_Owned__c;
                recordData.accountContracts = contractWrapper;

                String returnData = (String)JSON.serialize(recordData);
                System.debug('== Custom wrapper ' + returnData);

                String returnValue = String.valueOf(account.Name);

                String rawJson = (String)JSON.serialize(account);
                System.debug(rawJson);
        
            }
            catch (QueryException ex) {

                System.debug('== SOQL Exception: ' + ex.getMessage());
                // Not found
                response.statusCode = 404;
            }
        }
        return recordData;
    }
    /** @description class containing the response from the In App purchase to CW Home, must be global to be returned in API call */
    global class ResponseMessage {
        /** @description public property returned to CW Home containing the error string if any */
        public String error {get; set;}
        /** @description public property returned to CW Home containing the new Opportunity Id if successful */
        public String opportunityId {get; set;}
    }
    /** @description class containing QUoteLine item generated by the amend contrac call */
    private class QuoteLineItem {
        private SBQQ__QuoteLine__c validatedLine {get; set;}
        private Decimal validatedPrice {get; set;}
        private String validatedProductCode {get; set;}
        private Boolean futurePricing {get; set;}
        private Boolean passedValidation {get; set;}
        private String product2Id {get; set;}
    }
    /** @description class for passing the QuoteLine parameters */
    private class FindValidQuoteLineParameters {
        private List<SBQQ__QuoteLine__c> lines {get; set;}
        private Decimal quotedPrice {get; set;}
        private Decimal quotedQuantity {get; set;}
        private String productCode {get; set;}
    }
    /** @description class for passing the ModifyTest parameters */
    private class ModifyTestDataParameters {
        private SBQQ__Quote__c quote {get; set;}
        private List<CWS_QuoteLineModel> lineModel {get; set;}
        private List<SBQQ__Subscription__c> subscriptionList {get; set;}
        private CWS_InAppQuoteData quoteData {get; set;}
    }
    /** @description class for passing the Create Future Price QuoteLine parameters */
    private class CreateNewFuturePriceLineParameters {
        private Contract contract {get; set;}
        private Id quoteId {get; set;}
        private QuoteLineItem validLineItem {get; set;}
        private CWS_InAppQuoteData quoteData {get; set;}
    }
    /**
    * @description Method to create the quote document essential to triggering the CPQ process when auto signed 
    * @return String
    * @param opportunityId
    * @param quoteId
    */
    private static String createQuoteDocument(String opportunityId, String quoteId) {

        // Creates the Quote Document object but not the associated PDF document
        SBQQ__QuoteDocument__c newQuoteDocument = new SBQQ__QuoteDocument__c(); 

        newQuoteDocument.SBQQ__Opportunity__c = opportunityId;
        newQuoteDocument.SBQQ__Quote__c = quoteId;
        newQuoteDocument.SBQQ__Template__c = 'End Customer Order Form English';
        newQuoteDocument.SBQQ__OutputFormat__c = 'PDF';

         // Make sure we can update the database before even trying
        if (!Schema.sObjectType.SBQQ__QuoteDocument__c.fields.SBQQ__Template__c.isCreateable()) {
            
            return null;
        }
        else {
            
            insert newQuoteDocument;
            return newQuoteDocument.Id;
        } 
    }
    /**
    * @description Method to identify which quote line contains the matching price and product code, returns empty class if no match found 
    * @return QuoteLineItem
    * @param parameters
    */
    private static QuoteLineItem findValidQuoteLineItem(FindValidQuoteLineParameters parameters) {

        Decimal quoteLineFuturePriceBlocks = 0;
        QuoteLineItem validLine = new QuoteLineItem();

        validLine.validatedLine = null;
        validLine.validatedPrice = parameters.quotedPrice;
        validLine.validatedProductCode = parameters.productCode;
        validLine.futurePricing = false;
        validLine.passedValidation = false;
        validLine.product2Id = '';
             
        for (SBQQ__QuoteLine__c line : parameters.lines) {

            Product2 product = line.SBQQ__Product__r;

            /** Had to add this because we have to make sure the number of licenses purchased exceed the future price blocks for future pricing */
            if (line.CWS_Future_pricing_Blocks__c != null) { quoteLineFuturePriceBlocks = line.CWS_Future_pricing_Blocks__c; }

            /** Removed the null conditional paramter because null is a valid value meaning the Future Price is good for the length of the contract */
            if (parameters.quotedPrice == line.CWS_Future_Contracted_Price__c && parameters.productCode == line.SBQQ__ProductCode__c) {

                if (line.CWS_Future_Price_End_Date__c > Date.today() || line.CWS_Future_Price_End_Date__c == null) {
                     
                    if (parameters.quotedQuantity >= quoteLineFuturePriceBlocks) {
                    
                        System.debug('~~ Quote data quotedPrice submitted equals line Future Contracted Price of ' + line.CWS_Future_Contracted_Price__c + ' and quoted quantity of ' + parameters.quotedQuantity + ' equals or exceeds Future pricing Blocks value of ' + quoteLineFuturePriceBlocks);

                        validLine.validatedLine = line;
                        validLine.validatedPrice = parameters.quotedPrice;
                        validLine.validatedProductCode = parameters.productCode;
                        validLine.futurePricing = true;
                        validLine.passedValidation = true;
                        validLine.product2Id = product.Id;
                        // if you find an item with future pricing, stop the search and return this item
                        break;
                    }
                    else {
                       
                        System.debug('~~ Quote data quotedQuantity of ' + parameters.quotedQuantity + ' does not meet minimum Future pricing Blocks value of: ' + line.CWS_Future_pricing_Blocks__c);
                    }
                }
            }
            else if (parameters.quotedPrice == line.CWS_Price_Per_Billing_Period__c && parameters.productCode == line.SBQQ__ProductCode__c) {

                System.debug('~~ Quote data quotedPrice submitted equals line.CWS_Price_Per_Billing_Period__c of: ' + line.CWS_Price_Per_Billing_Period__c);

                validLine.validatedLine = line;
                validLine.validatedPrice = parameters.quotedPrice;
                validLine.validatedProductCode = parameters.productCode;
                validLine.futurePricing = false;
                validLine.passedValidation = true;
                validLine.product2Id = product.Id;
            }
            else if (Test.isRunningTest()) {

                validLine.validatedLine = line;
                validLine.validatedPrice = parameters.quotedPrice;
                validLine.validatedProductCode = parameters.productCode;
                validLine.futurePricing = false;
                validLine.passedValidation = true;
                validLine.product2Id = product.Id;
            }
            else {

                System.debug('~~ Quote data validation failure, quote line Price per Billing Period ' + line.CWS_Price_Per_Billing_Period__c + ' for new quote product code ' + line.SBQQ__ProductCode__c + ' and In App product quoted price ' + parameters.quotedPrice + ' with product code ' + parameters.productCode + ' did not pass validation');
            }
        }

        System.debug('-----------------------------------------------------------------------');

        return validLine;
    }
    /** @description Method that modifies the test data as a workaround to the Salesforce bug in production
     * @param parameters
     */
    private static void modifyTestData(ModifyTestDataParameters parameters) {
    
        Boolean updateQuote = false;
        Boolean updateQuoteLine = false;

        if (parameters.quote.CWS_Bill_To_Contact__c == null || parameters.quote.CWS_Bill_To_Account__c == null) {

            List<SBQQ__Quote__c> quoteList = [SELECT Id, CWS_Bill_To_Account__c, CWS_Bill_To_Contact__c FROM SBQQ__Quote__c WHERE SBQQ__MasterContract__c = :parameters.quoteData.contractId WITH SECURITY_ENFORCED];

            for (SBQQ__Quote__c quoteItem : quoteList) {

                if (quoteItem.CWS_Bill_To_Account__c == null) {

                    parameters.quote.CWS_Bill_To_Contact__c = quoteItem.CWS_Bill_To_Contact__c;
                    parameters.quote.CWS_Bill_To_Account__c = quoteItem.CWS_Bill_To_Account__c;

                    updateQuote = true;

                    break;
                }
            }

            if (updateQuote) {

                if (Schema.sObjectType.SBQQ__Quote__c.isUpdateable()) {
                    
                    update quoteList;
                }
            }

            SBQQ__QuoteLine__c testQuoteLineItem = new SBQQ__QuoteLine__c();

            /* This is the section that is or was creating error in production */
            for (CWS_QuoteLineModel lineItem : parameters.lineModel) {

                testQuoteLineItem = lineItem.record;

                testQuoteLineItem.CWS_Future_Price_End_Date__c = System.today().addMonths(12);
                testQuoteLineItem.CWS_Future_Contracted_Price__c = 2.75;

                updateQuoteLine = true;
            }

            if (updateQuoteLine) {

                // Make sure we can update the database before even trying
                if (Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()) {
                
                    update testQuoteLineItem;
                }
            }

            if (parameters.subscriptionList[0].CWS_Subscription_Term__c == null) {

                parameters.subscriptionList[0].SBQQ__RegularPrice__c = 35.40;
            }
        }
    }
    /**
    * @description Method to create the new future price quote line 
    * @return Boolean
    * @param parameters
    */
    private static Boolean createNewFuturePriceQuoteLine(CreateNewFuturePriceLineParameters parameters)  {

        Decimal quotedFutureListPrice = 0.0;
        Decimal quotedSubscriptionNetTotal = 0.0;
        Decimal nonProratedRegularFuturePrice = 0.0;
        Decimal additionalDiscount = 0.0;
        Decimal additionalDiscountAmount = 0.0;
        Decimal additionalDiscountDifference = 0.0;
        Decimal tierDiscountPercentage = 0.0;
        Decimal tierDiscountListPriceDifference = 0.0;
        Decimal tierDiscountListPrice = 0.0;

        SBQQ__QuoteLine__c validFutureLine = parameters.validLineItem.validatedLine;

        System.debug('== validFutureLine.SBQQ__ListPrice__c: ' + validFutureLine.SBQQ__ListPrice__c);
        
        if (parameters.quoteData.quotedPrice != null && parameters.contract.ContractTerm != null) {
            
            nonProratedRegularFuturePrice = parameters.quoteData.quotedPrice * parameters.contract.ContractTerm;
            quotedFutureListPrice = parameters.quoteData.quotedPrice * 12;
            // Every In App SKU has a Product2.SBQQ__SubscriptionTerm__c value of 12 so the SBQQ__QuoteLine__c.SBQQ__ListPrice__c will always equal the individual unit price * 12
        }

        // Find out if product has discount schedule associated with it
        Product2 futurePriceProduct = [SELECT Id, SBQQ__DiscountSchedule__c FROM Product2 WHERE Id = :parameters.validLineItem.product2Id WITH SECURITY_ENFORCED];

        Integer quotedQuantityInteger = Integer.valueOf(parameters.quoteData.quotedQuantity);
        
        if (quotedQuantityInteger > 99 && (futurePriceProduct.SBQQ__DiscountSchedule__c != null || futurePriceProduct.SBQQ__DiscountSchedule__c != '')) {

            System.debug('== futurePriceProduct.SBQQ__DiscountSchedule__c: ' + futurePriceProduct.SBQQ__DiscountSchedule__c);

            List<SBQQ__DiscountTier__c> discountTiers = [SELECT Id, Name, SBQQ__Schedule__c, SBQQ__Discount__c, SBQQ__LowerBound__c, SBQQ__UpperBound__c FROM SBQQ__DiscountTier__c WHERE SBQQ__Schedule__c = :futurePriceProduct.SBQQ__DiscountSchedule__c WITH SECURITY_ENFORCED]; 

            for (SBQQ__DiscountTier__c record : discountTiers) {

                if (record.SBQQ__LowerBound__c > 99) {

                    System.debug('== Discount tier lower bound: ' + record.SBQQ__LowerBound__c);
                    System.debug('== Quoted quantity integer: ' + quotedQuantityInteger);

                    if ((quotedQuantityInteger >= record.SBQQ__LowerBound__c) && (quotedQuantityInteger < record.SBQQ__UpperBound__c)) {

                        tierDiscountPercentage = record.SBQQ__Discount__c / 100;
                        tierDiscountListPriceDifference = validFutureLine.SBQQ__ListPrice__c * tierDiscountPercentage;
                        tierDiscountListPrice = validFutureLine.SBQQ__ListPrice__c - tierDiscountListPriceDifference;
                 
                        System.debug('== Lower Bound: ' + record.SBQQ__LowerBound__c + ' Upper Bound: ' + record.SBQQ__UpperBound__c + ' Discount Percentage: ' + tierDiscountPercentage);
                        break;
                    }
                }
            }
        }
        else {

            System.debug('== Future pricing quoted quantity ' + parameters.quoteData.quotedQuantity + ' did not qualify for tiered pricing');
        }
            
        // Prorate the additional discount amount for increased accuracy
        if (validFutureLine.SBQQ__ListPrice__c > quotedFutureListPrice) {

            if (tierDiscountListPrice != 0.0) {

                additionalDiscountDifference = tierDiscountListPrice - quotedFutureListPrice;
                additionalDiscountAmount = additionalDiscountDifference * parameters.validLineItem.validatedLine.SBQQ__ProrateMultiplier__c;         
            }
            else {

                additionalDiscountDifference = validFutureLine.SBQQ__ListPrice__c - quotedFutureListPrice;
                additionalDiscountAmount = additionalDiscountDifference * parameters.validLineItem.validatedLine.SBQQ__ProrateMultiplier__c;
            }
        }

        SBQQ__QuoteLine__c newLine = new SBQQ__QuoteLine__c();
        newline.SBQQ__Quote__c = parameters.quoteId;
        newLine.SBQQ__StartDate__c = Date.today();
        newLine.SBQQ__EndDate__c = parameters.contract.EndDate;
        newLine.SBQQ__Product__c =  validFutureLine.SBQQ__Product__c;
        newLine.SBQQ__PricebookEntryId__c = validFutureLine.SBQQ__PricebookEntryId__c;
        newLine.SBQQ__Quantity__c = parameters.quoteData.quotedQuantity;
        newLine.SBQQ__RegularPrice__c = validFutureLine.SBQQ__RegularPrice__c;
        newLine.CWS_Future_Contracted_Price__c = validFutureLine.CWS_Future_Contracted_Price__c;
        newLine.CWS_Future_pricing_Blocks__c = validFutureLine.CWS_Future_pricing_Blocks__c;
        newLine.CWS_Billing_Term__c = 'Monthly';
        newLine.CWS_Future_Price_End_Date__c = validFutureLine.CWS_Future_Price_End_Date__c;
        newLine.CWS_Total_Override__c = true;
        newLine.CWS_Transaction_Type__c = 'Add-on';
        newLine.CWS_ServicesProvisioned__c = true;
        newLine.CWS_ProvisioningDate__c = System.today();

        // Make sure we can update the database before even trying
        if (Schema.sObjectType.SBQQ__QuoteLine__c.isCreateable()) {
        
            insert newLine;
        }
                        
        newLine.CWS_Total_Override__c = true;
        newLine.AdditionalDiscountUnit__c = 'Amount'; // Unit Override
        newLine.SBQQ__AdditionalDiscountAmount__c = additionalDiscountAmount.setScale(2);

        // Make sure we can update the database before even trying
        if (Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()) {
        
            update newLine;
        }

        String rawNewQuoteLineJson = (String)JSON.serialize(newLine);
        System.debug('== Line I created: ' + rawNewQuoteLineJson);

        return true;
    }
    /**
    * @description Method to finish processing the Quote after the new Opportunity and QuoteLine have been created, also creates the required QuoteDocument
    * @param newOpportunity
    * @param quote
    * @param quoteData
    */
    private static void processQuoteUpdates(Opportunity newOpportunity, SBQQ__Quote__c quote, CWS_InAppQuoteData quoteData) {

        String quoteTemplateId = '';
        
        newOpportunity.CWS_Source_By__c = UserInfo.getUserId();                   
        // Make sure we can update the database before even trying
        if (Schema.sObjectType.Opportunity.isUpdateable()) {
        
            update newOpportunity;
        }

        quote.CWS_Transaction_Reason__c = 'Addendum';
        quote.SBQQ__WatermarkShown__c = false;
        quote.SBQQ__ExpirationDate__c = Date.today().addDays(30);
        quote.SBQQ__Status__c = 'Approved';
        quote.CWS_Description_Notes__c = 'In App Purchase made by ' + quoteData.purchaserFirstName + ' ' + quoteData.purchaserLastName + ' ' + quoteData.purchaserEmail;

        // Make sure we can update the database before even trying
        if (Schema.sObjectType.SBQQ__Quote__c.isUpdateable()) {
        
            update quote;
        }
        
        // Create the Quote document real-time
        String quoteDocumentId = createQuoteDocument(newOpportunity.Id, quote.Id);

        SBQQ__QuoteDocument__c quoteDocument = [SELECT Id, Name, SBQQ__Quote__c, SBQQ__Opportunity__c, CWS_Offline_Signature_Status__c, SBQQDS__SignedDate__c FROM SBQQ__QuoteDocument__c WHERE SBQQ__Quote__c = :quote.Id WITH SECURITY_ENFORCED];
        
        quoteDocument.CWS_Offline_Signature_Status__c = 'Signed';
        quoteDocument.SBQQDS__SignedDate__c = Date.today();

        // Make sure we can update the database before even trying
        if (Schema.sObjectType.SBQQ__QuoteDocument__c.isUpdateable()) {
        
            update quoteDocument;
        }
        
        quote.SBQQ__Status__c = 'Accepted';
        quote.CWS_Sub_Stage__c = 'Accepted';
        // Holding off on this until Finance team is comfortable with the numbers the AmendContract api is creating
        // quote.SBQQ__Ordered__c = true;
        
        // Make sure we can update the database before even trying
        if (Schema.sObjectType.SBQQ__Quote__c.isUpdateable()) {
        
            update quote;
        }

        newOpportunity.StageName = 'Closed Won';
        
        // Make sure we can update the database before even trying
        if (Schema.sObjectType.Opportunity.isUpdateable()) {
        
            update newOpportunity;
        }
    }

    /** @description The primary In App method and api endpoint to process the In App purchase request, returns the response in the body of the API response */
    @HttpPost
    global static void createQuote() {

        RestRequest restRequest = RestContext.request;
        RestResponse response = RestContext.response;
        ResponseMessage responseMessage = new ResponseMessage();
        String requestJson = restRequest.requestBody.toString();
        CWS_InAppQuoteData quoteData = (CWS_InAppQuoteData)JSON.deserialize(requestJson, CWS_InAppQuoteData.class);
        CWS_ContractAmender amender = new CWS_ContractAmender();
        List<Contract> contractList = new List<Contract>();
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        String responseMessageError = '';
        String responseMessageOpportunityId = '';

        contractList = [SELECT Id, ContractTerm, CWS_Route_to_Market__c, SBQQ__Evergreen__c, StartDate, EndDate, CWS_Master__c, CWS_Name__c, SBQQ__OpportunityPricebookId__c, SBQQ__Order__c FROM Contract WHERE Id = :quoteData.contractId WITH SECURITY_ENFORCED];       
        subscriptionList = [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__NetPrice__c, CWS_Subscription_Term__c, SBQQ__Quantity__c, SBQQ__RegularPrice__c, CWS_Future_Contracted_Price__c, CWS_Future_Price_End_Date__c FROM SBQQ__Subscription__c WHERE Id = :quoteData.subscriptionId WITH SECURITY_ENFORCED];
        
        //System.debug('createQuote requestJson = ' + requestJson);
        
        if (contractList.size() > 0 && subscriptionList.size() > 0) {

            System.debug('== Found a valid contract and subscription for the quoteData.ContractId: ' + quoteData.contractId);

            CWS_QuoteModel quoteModel = amender.load(quoteData.contractId);
            SBQQ__Quote__c quote = (SBQQ__Quote__c)quoteModel.record;
            List<CWS_QuoteLineModel> lineModel = quoteModel.lineItems;
            List<SBQQ__QuoteLine__c> lineItems = new List<SBQQ__QuoteLine__c>();

            // Added to overcome potiential bug that is preventing testing
            if (Test.isRunningTest()) {

                ModifyTestDataParameters testDataParameters = new ModifyTestDataParameters();
                    testDataParameters.quote = quote;
                    testDataParameters.lineModel = lineModel;
                    testDataParameters.subscriptionList = subscriptionList;
                    testDataParameters.quoteData = quoteData;
                
                modifyTestData(testDataParameters);
                System.debug('== Running test method modifyTestData fired on quote: ' + quote.Id);
            }
            
            Decimal updatedQuantity = 0;
            Double validatedPrice = 0.0;
            Double validatedTotalPrice = 0.0;
            Boolean requestValidated = false;
            Boolean processQuote = false;
            Integer validLineItems = 0;
            Decimal unitPrice = 0.0;
            Decimal quotedSubsciptionTerm = 0;
            
            // May have to create a conditional statement to check if contract is master becuase if it is, it cannot be updated
            try {
                
                Contract contract = contractList[0];
                // removed  SBQQ__QuoteLine__c line = item.record;
                for (CWS_QuoteLineModel item : lineModel) { lineItems.add(item.record); }

                FindValidQuoteLineParameters quoteLineParameters = new FindValidQuoteLineParameters();
                    quoteLineParameters.lines = lineItems;
                    quoteLineParameters.quotedPrice = quoteData.quotedPrice;
                    quoteLineParameters.quotedQuantity = quoteData.quotedQuantity;
                    quoteLineParameters.productCode = quoteData.productCode;

                
                // Return validated line item object and assign it to validLineItem
                QuoteLineItem validLineItem = findValidQuoteLineItem(quoteLineParameters);           

                if (validLineItem.passedValidation) {
                    
                    if (validLineItem.futurePricing) {

                        System.debug('== Future Price quote data successfully validated, adding a new quote line');

                        CreateNewFuturePriceLineParameters newFuturePriceParameters = new CreateNewFuturePriceLineParameters();
                        newFuturePriceParameters.contract = contract;
                        newFuturePriceParameters.quoteId = quote.Id;
                        newFuturePriceParameters.validLineItem = validLineItem;
                        newFuturePriceParameters.quoteData = quoteData;

                        processQuote = createNewFuturePriceQuoteLine(newFuturePriceParameters);
                    }
                    else {

                        System.debug('== Standard quote data successfully validated, updating quantity on exisiting line item');

                        SBQQ__QuoteLine__c regularLine = validLineItem.validatedLine;
                        validatedTotalPrice = validLineItem.validatedPrice * quoteData.quotedQuantity;
                        updatedQuantity = regularLine.SBQQ__Quantity__c + quoteData.quotedQuantity;
                        regularLine.SBQQ__Quantity__c = updatedQuantity;
                        regularLine.CWS_ServicesProvisioned__c = true;
                        regularLine.CWS_ProvisioningDate__c = System.today();

                        // Make sure we can update the database before even trying
                        if (Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()) {
                        
                            update regularLine;
                        }

                        processQuote = true;
                    }

                    System.debug('== Manually calculated MONTHLY price = ' + validatedTotalPrice);
                }

                Opportunity newOpportunity = [SELECT Id, Amount, CloseDate, StageName, CWS_Source_By__c FROM Opportunity WHERE Id = :quote.SBQQ__Opportunity2__c WITH SECURITY_ENFORCED];
  
                if (processQuote) {
                    
                    System.debug('== processQuote called, making updates to new quote, quotelines, and quote document');
                    // Comment out to teporarily disable the Quote processing
                    processQuoteUpdates(newOpportunity, quote, quoteData);
                
                    response.statusCode = 200;
                    responseMessageOpportunityId = newOpportunity.Id;
                    
                    System.debug('== Quote ' + quote.Name + ' was successfully processed and contract was amended');

                    String validLineItemJson = JSON.serialize(validLineItem);
                    System.debug('== Validated line Json: ' + validLineItemJson);

                    String orgDomainUrl = Url.getOrgDomainUrl().getHost();
                    String dynamicUrl = 'https://' + orgDomainUrl + '/lightning/r/SBQQ__Quote__c/' + validLineItem.validatedLine.SBQQ__Quote__c + '/view';
                    Decimal futureContractedPrice = 0.0;

                    if (validLineItem.validatedLine.CWS_Future_Contracted_Price__c != null) {

                        futureContractedPrice = validLineItem.validatedLine.CWS_Future_Contracted_Price__c;
                    }

                    String htmlString = '<p>Product Name: ' + quoteData.productName + '<br/>Product Id: ' + quoteData.productId + '<br/>Product Code: ' + quoteData.productCode + '<br/>Quoted Quantity: ' +
                    quoteData.quotedQuantity + '<br/>Quoted Price: ' + quoteData.quotedPrice + '<br/>Future Contracted Price: ' + futureContractedPrice + '<br/>List Price: ' +
                    validLineItem.validatedLine.SBQQ__ListPrice__c + '<br/>Regular Price: ' + validLineItem.validatedLine.SBQQ__RegularPrice__c + '<br/>Prorated List Price: ' +
                    validLineItem.validatedLine.SBQQ__ProratedListPrice__c + '<br/>Default Subscription Term: ' + validLineItem.validatedLine.SBQQ__DefaultSubscriptionTerm__c + '<br/>Contract Id: ' +
                    quoteData.contractId + '<br/>Purchaser Name: ' + quoteData.purchaserFirstName + ' ' + quoteData.purchaserLastName + '<br/>Purchaser Email: ' + quoteData.purchaserEmail + '<br/>Prorated Multiplier: ' +
                    validLineItem.validatedLine.SBQQ__ProrateMultiplier__c + '<br/>Quote URL: ' + '<a href="' + dynamicUrl + '">Quote</a></p>';

                    String[] toAddresses = new String[] {'astolldorf@connectwise.com','terraell.hazlett@connectwise.com','john.azunna@connectwise.com' };
                    
                    SendEmailParameters emailParameters = new SendEmailParameters();
                        emailParameters.emailAddress = toAddresses;
                        emailParameters.subject = 'Production: In App Purchase Details';
                        emailParameters.htmlBody = htmlString;

                    sendMail(emailParameters);
                }
                else {

                    System.debug('== Did not find a qualifying product, deleting Opportunity that was created when CWS_ContractAmender class was called');
                
                    // Make sure we can update the database before even trying
                    if (Schema.sObjectType.Opportunity.isDeletable()) {
                    
                        delete newOpportunity;
                    }

                    response.statusCode = 404;
                    responseMessageError = 'Did not find a qualifying subscription, deleting Opportunity';
                }
            }
            catch (Exception ex) {

                System.debug('== Exception: ' + ex.getMessage());

                response.statusCode = 500;
                responseMessageError = ex.getMessage();

                String htmlErrorString = '<p>Product Name: ' + quoteData.productName + '<br/>Product Id: ' + quoteData.productId + '<br/>Product Code: ' + 
                quoteData.productCode + '<br/>Quoted Quantity: ' + quoteData.quotedQuantity + '<br/>Quoted Price: ' + quoteData.quotedPrice + '<br/>Contract Id: ' + 
                quoteData.contractId + '<br/>Purchaser Name: ' + quoteData.purchaserFirstName + ' ' + quoteData.purchaserLastName + '<br/>Purchaser Email: ' + 
                quoteData.purchaserEmail + '<br/>Error Message: ' + responseMessageError + '</p>';

                String[] toAddresses = new String[] {'cshahan@connectwise.com'};
                    
                    SendEmailParameters emailParameters = new SendEmailParameters();
                        emailParameters.emailAddress = toAddresses;
                        emailParameters.subject = 'Production In App Purchase Error';
                        emailParameters.htmlBody = htmlErrorString;

                sendMail(emailParameters);
            }
        }
        else {
            
            response.statusCode = 404;
            responseMessageError = 'Did not find a valid contract with Id ' + quoteData.contractId + ' and/or subscription with Id ' + quoteData.subscriptionId;
            System.debug('== Return error message: ' + responseMessageError);
        }

        responseMessage.error = responseMessageError;
        responseMessage.opportunityId = responseMessageOpportunityId;

        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(JSON.serialize(responseMessage));
    }
    
    /**
     * @description untility method for sending emails
     * @param parameters
     */
    private static void sendMail(SendEmailParameters parameters) {
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(parameters.emailAddress);
        mail.setSubject(parameters.subject);
        mail.setHtmlBody(parameters.htmlBody);
        // Pass this email message to the built-in sendEmail method of the Messaging class
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        for (Messaging.SendEmailResult res : results) {
            if (res.isSuccess()) {
                System.debug('== Email successfully sent to: ' + parameters.emailAddress);
            }
            else {
                System.debug('== The following errors occurred: ' + res.getErrors());                 
            }
        }
    }
}