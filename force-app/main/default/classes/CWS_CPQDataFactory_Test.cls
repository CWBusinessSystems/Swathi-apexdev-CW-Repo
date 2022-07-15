/**Class Name: CWS_CPQDataFactory_Test
* @description: Test data factory to create Account, Contract, Quote, and Product data to In App Purchasing
* @author Created By: Carl Shahan
* @date 02/11/2022
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 10/04/2020 CWH-996       Test data factory to create Account, Contract, Quote, and Product data to In App Purchasing
*Carl Shahan 02/11/2022 OBD-3769      Modified to add fields I hoped would resolve the bug in Salesforce causing the test class to fail  
*/
/** @description class to create In App test data */
@isTest
public with sharing class CWS_CPQDataFactory_Test {
    
    private static List<User> localUser = [SELECT Id, Name, Email FROM User WHERE Name = 'Carl Shahan' WITH SECURITY_ENFORCED LIMIT 1];
    /** @description private class for passing parameters to createQuote and createContract methods */
    private class CreateQuoteAndContractParameters {
        private Id accountId {get; set;}
        private Id primaryContactId {get; set;}
        private Id billingContactId {get; set;}
        private Id opportunityId {get; set;}
    }
    /** @description private class for passing parameters to createOpoortunityLine method */
    private class CreateOpportunityLineItemParameters {
       
        private Id opportunityId {get; set;}
        private Id productId {get; set;}
        private Id quoteLineId {get; set;}
        private Decimal quoteQuantity {get; set;}
     }   
    /**
     * @description Mock https reponse to simulate API call
     * @return SuccessfulResponse
     */
    public class SuccessfulResponse implements HttpCalloutMock {

        /**
        * @description Mock https reponse to simulate API call
        * @return response
        * @param request
        */
        public HTTPResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"OpportunityId":"a196C000001i4xJQAQ","Error":""}');
            response.setStatusCode(200);

            return response;
        }
    }
    /**
     * @description untility method for creating an Account
     * @return Account
     */
    private static Account createAccount() {

        Account account = new Account(
            Name = 'BB8 Test Account',
            Phone = '727 777 3625',
            CurrencyIsoCode = 'USD',
            OwnerId = localUser[0].Id,
            BillingStreet = '8800 Bay Pines Boulevard',
            BillingCity = 'St. Petersburg',
            BillingCountry = 'United States',
            BillingState = 'Florida',
            BillingPostalCode = '33715',
            CWS_Account_Restriction_Status__c = 'No Restriction',
            CWS_Products_Owned__c = 'Automate',
            CWS_Is_Partner__c = true,
            CWS_SSO_GUID__c = '5f6d07a5e6426900017a3ad5',
            CWS_Territory__c = 'Florida',
            CWS_Region__c = 'NA',
            CWS_Payment_Terms__c = 'Due Upon Receipt',
            CWS_Invoice_Delivery_Preference__c = 'Email'
        );
        
        insert account;
        
        return account;
    }
    /** @description Method that creates the Primary Contact test data
     * @return Contact
     * @param accountId 
     */
    private static Contact createPrimaryContact(Id accountId) {

        Contact contact = new Contact(
            AccountId = accountId,
            FirstName = 'Luke',
            LastName = 'Skywalker',
            Phone = '727 777 3625',
            Email = 'luke.skywalker@bb8fptecc.com.invalid',
            CWS_Active__c = true,
            CWS_Primary_Billing_Contact__c = false,
            CWS_Primary_Contact__c = true,
            CWS_SSO_User_ID__c = '5f6d07a5ba60dafc65b47f92',
            CWS_CW_Login_Email__c = 'luke.skywalker@bb8fptecc.com.invalid'
        );

        insert contact;

        return contact;
    }
    /** @description Method that creates the Primary Billing Contact test data
     * @return Contact
     * @param accountId 
     */
    private static Contact createBillingContact(Id accountId) {

        Contact contact = new Contact(
            AccountId = accountId,
            FirstName = 'Darth',
            LastName = 'Vader',
            Phone = '727 777 3625',
            Email = 'darth.vader@bb8fptecc.com.invalid',
            CWS_Active__c = true,
            CWS_Primary_Billing_Contact__c = true,
            CWS_Primary_Contact__c = false,
            CWS_SSO_User_ID__c = '5f6d07a5ba60dafc65b47f96',
            CWS_CW_Login_Email__c = 'darth.vader@bb8fptecc.com.invalid'
        );

        insert contact;

        return contact;
    }
    /** @description Method that creates the Product test data
     * @return Product2
     */
    private static Product2 createProduct() {

        Product2 product = new Product2(
            SBQQ__ConfigurationEvent__c = 'Always',
			CWS_Category__c = 'Automate',
			SBQQ__QuantityEditable__c = true,
			SBQQ__Hidden__c = false,
			SBQQ__ExcludeFromOpportunity__c = false,
			SBQQ__NonDiscountable__c = false,
			CWS_Included_Units__c = 0.0,
			CWS_Manage_Special_Product__c = false,
			SBQQ__BillingType__c = 'Advance',
			CWS_Avg_Number_of_Days__c = 3.0,
			CWS_Renewal_Uplift__c = 5.0,
            Name = 'Automate Standard',
            ProductCode = 'AUT-LIC-SAASPKSNDSAS',
            SBQQ__SubscriptionTerm__c = 12.0,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__PricingMethod__c = 'List',
            CWS_Description__c = 'Single Automate license sold individually',
            CWS_Billing_Term__c = 'Monthly',
            CWS_ChargeType__c = 'Recurring',
            CWS_Charge_Model__c = 'Per Unit Pricing',
            CWS_Currencies__c = 'USD',
            CWS_Item_Revenue_Category__c = 'SaaS',
            CWS_License_Type__c = 'SaaS',
            CWS_ProductCode__c = 'AUT-LIC-SAASPKSNDSAS',
            CWS_Product_Family__c = 'Unified Monitoring & Management',
            CWS_Renewal_Type__c = 'Opt-out',
            CWS_Route_to_Market__c = 'Direct',
            CWS_SKU_Type__c = 'Package',
            CWS_Status__c = 'Active',
            CWS_Sub_Category__c = 'License',
            CWS_UOM__c = 'Agent',
            CW_Product_Type__c = 'Product'
        );

        insert product;

        return product;
    }
    /** @description Method that creates the PricebookEntry test data
     * @return PricebookEntry
     * @param productId 
     */
    private static PricebookEntry createPricebookEntry(Id productId) {

        PricebookEntry pricebookEntry = new PricebookEntry(
            UnitPrice = 38.4,
			Product2Id = productId,
			IsActive = true,
			Pricebook2Id = Test.getStandardPricebookId(),
            CurrencyIsoCode = 'USD'
        );

        insert pricebookEntry;

        return pricebookEntry;
    }
    /** @description Method that creates the Opportunity test data
     * @return Opportunity
     * @param accountId 
     * @param billingContactId 
     */
    private static Opportunity createOpportunity(Id accountId, Id billingContactId) {

        Opportunity opportunity = new Opportunity(
            AccountId = accountId,    
            Name = 'BB8 Test Account Opportunity',
            StageName = 'Proposal',
            CloseDate = System.today().addDays(30),
            CurrencyIsoCode	= 'USD',
            OwnerId = localUser[0].Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Type = 'New Business',
            LeadSource = 'Sales Generated',
            CWS_Bill_To_Account__c = accountId,
            CWS_Ship_To_Account__c = accountId,
            CWS_Sold_To_Account__c = accountId,
            CWS_Bill_To_Contact__c = billingContactId,
            //CWS_Sold_To_Contact_Name__c = primaryContactId, not writeable
            CWS_Source_By__c = localUser[0].Id,
            CWS_Region__c = 'NA'
        );

        insert opportunity;

        return opportunity;
    }
    /** @description Method that creates the OpportunityLineItem test data
     * @return OpportunityLineItem
     * @param parameters 
     */
    private static OpportunityLineItem createOpportunityLine(CreateOpportunityLineItemParameters parameters) {
        
        OpportunityLineItem line = new OpportunityLineItem(
            Product2Id = parameters.productId,
            OpportunityId = parameters.opportunityId,
            SBQQ__QuoteLine__c = parameters.quoteLineId,
            Quantity = parameters.quoteQuantity
        );

        insert line;
        
        return line;
    }
    /** @description Method that creates the Quote test data
     * @return SBQQ__Quote__c
     * @param parameters 
     */
    private static SBQQ__Quote__c createQuote(CreateQuoteAndContractParameters parameters) {
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = parameters.accountId, 
            SBQQ__PricebookId__c = Test.getStandardPricebookId(), 
            SBQQ__Opportunity2__c = parameters.opportunityId, 
            SBQQ__StartDate__c = System.today(),
            SBQQ__Status__c = 'Approved',
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__Primary__c = true,
            CWS_Bill_To_Account__c = parameters.accountId,
            CWS_Bill_To_Contact__c = parameters.billingContactId,
            SBQQ__PrimaryContact__c = parameters.primaryContactId,
            SBQQ__ContractingMethod__c = 'By Subscription End Date',
            CWS_Route_to_Market__c = 'Direct',
            CWS_Quote_Type__c = 'New Business'
            //SBQQ__MasterContract__c = contractId this is the id of the master contract which there is not one
        );
        
        insert quote;
        
        return quote;
    }
    /** @description Method that creates the QuoteLine test data
     * @return SBQQ__QuoteLine__c
     * @param quoteId 
     * @param productId 
     * @param priceEntry 
     */
    private static SBQQ__QuoteLine__c createQuoteLine(Id quoteId, Id productId, PricebookEntry priceEntry) {

        SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__C(
            SBQQ__Product__c = productId,
            SBQQ__Quote__c = quoteId,
            SBQQ__PricebookEntryId__c = priceEntry.Id,
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__Quantity__c = 50,
            CWS_PromoCode_Applied__c = false,
            CWS_Transaction_Update__c = false,
            SBQQ__StartDate__c = System.today(),
            SBQQ__EndDate__c = System.today().addDays(364),
			CWS_Actual_StartDate__c = System.today(),
            SBQQ__BillingType__c = 'Advance',
            SBQQ__ProratedListPrice__c = 38.4,
            CWS_Margin__c = 0.0,
            SBQQ__NetPrice__c = 38.4,
            CWS_NetTotal__c = 0.0,
            CWS_Automate_Product__c = true,
            SBQQ__OriginalPrice__c = 38.4,
            CWS_EF_Attribute__c = 'Product',
            SBQQ__PriceEditable__c = false,
            SBQQ__RegularPrice__c = 38.4,
			SBQQ__ProratedPrice__c = 38.4,
            SBQQ__PartnerPrice__c = 38.4,
            SBQQ__SubscriptionScope__c = 'Quote',
            SBQQ__SpecialPrice__c = 38.4,
            SBQQ__PricingMethod__c = 'List',
            SBQQ__ListPrice__c = 38.4,
            SBQQ__UnitCost__c = 3.2,
			SBQQ__Existing__c = true,
            //SBQQ__PriorQuantity__c = 50.0, this is new quote, not an upgrade or renewal
            SBQQ__ChargeType__c = 'Recurring',
            CWS_Billing_Term__c = 'Monthly',
            SBQQ__Taxable__c = true,
            SBQQ__TaxCode__c = 'SW053000',
            CurrencyIsoCode = 'USD',
            CWS_Volume_Discount__c = 0,
            SBQQ__CustomerPrice__c = 38.4,
            CWS_ChargeType__c = 'Recurring',
            CWS_Future_Contracted_Price__c = 2.75,
            CWS_Future_pricing_Blocks__c = 1,
            CWS_Future_Price_End_Date__c = System.today().addMonths(12),
            CWS_ServicesProvisioned__c = true,
            CWS_ProvisioningDate__c = System.today(),
            CWS_UOM__c = 'Agent'
        );

        insert line;
        
        return line;
    }
    /** @description Method that creates the Contract test data
     * @return Contract
     * @param parameters 
     * @param quoteId 
     */
    private static Contract createContract(CreateQuoteAndContractParameters parameters, Id quoteId) {
        //EndDate = StartDate.addDays(365), Not writeable and auto calculated in Contract settings
        Contract contract = new Contract(
            Name = 'BB8 Test Account Direct Opt-Out Multiple Contract',    
            AccountId = parameters.accountId, 
            ContractTerm = 12,
            StartDate = Date.today(),
            OwnerId = localUser[0].Id,
            CurrencyIsoCode = 'USD',
            Pricebook2Id = Test.getStandardPricebookId(),
            CWS_Billing_Frequency__c = 'Monthly',
            CWS_Ship_To_Account__c = parameters.accountId,
            CWS_Ship_To_Contact__c = parameters.primaryContactId,
            CWS_Sold_To_Contact__c = parameters.primaryContactId,
            CWS_Bill_To_Account__c = parameters.accountId,
            CWS_Bill_To_Contact__c = parameters.billingContactId,
            // CWS_Status__c = 'Active', Not writeable????
            // CWS_Legal_Entity__c = 'CW US Entity', Bad value
            CWS_Route_to_Market__c = 'Direct',
            CWS_Payment_Term__c = 'Due Upon Receipt',
            SBQQ__Opportunity__c = parameters.opportunityId,
            SBQQ__Quote__c = quoteId,
            SBQQ__PreserveBundleStructureUponRenewals__c = true
        );
        
        // CWS_OF_Signed_Date__c may have to update this after creating the signed quote document?

        insert contract;
        
        return contract;
    }
    /** @description Method that creates the QuoteTemplate test data
     * @return SBQQ__QuoteTemplate__c
     */
    private static SBQQ__QuoteTemplate__c createQuoteTemplate() {

        SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c(
            Name = 'End Customer Order Form English',
            SBQQ__DeploymentStatus__c = 'Deployed',
            CurrencyIsoCode = 'USD',
            SBQQ__PageWidth__c = 8.5,
            SBQQ__TopMargin__c = 1,
            SBQQ__LeftMargin__c = 1,
            SBQQ__PageHeight__c = 11,
            SBQQ__BottomMargin__c = 1,
            SBQQ__RightMargin__c = 1,
            SBQQ__FontFamily__c = 'Courier',
            SBQQ__ShadingColor__c = 'FFFFFF',
            SBQQ__TermBodyIndent__c = 16,
            SBQQ__FontSize__c = 16,
            SBQQ__BorderColor__c = 'FFFFFF',
            SBQQ__GroupGap__c = 16
        );

        insert template;
        
        return template; 
    }
    /** @description Method that creates the Subscription test data
     * @return SBQQ__Subscription__c
     * @param accountId 
     * @param contractId 
     * @param quoteLine 
     */
    private static SBQQ__Subscription__c createSubscription(Id accountId, Id contractId, SBQQ__QuoteLine__c quoteLine) {
        
        Date endDate = Date.today().addDays(364);

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
            OwnerId = localUser[0].Id,
            CurrencyIsoCode = quoteLine.CurrencyIsoCode,
            //CWS_Status__c = 'Active', NW
            CWS_UOM__c = 'Agent',
            //CWS_Product_Source__c = 'CW', NW
            CWS_Subscription_Term__c = 12,
            CWS_Transaction_Type__c = 'New',
            CWS_Future_Contracted_Price__c = quoteLine.CWS_Future_Contracted_Price__c,
            CWS_Future_Price_End_Date__c = quoteLine.CWS_Future_Price_End_Date__c,
            CWS_Future_pricing_Blocks__c = quoteLine.CWS_Future_pricing_Blocks__c,
            //SBQQ__StartDate__c = quoteLine.SBQQ__StartDate__c, NW
            //SBQQ__EndDate__c = quoteLine.SBQQ__EndDate__c, NW
            SBQQ__Contract__c = contractId, 
            SBQQ__Product__c = quoteLine.SBQQ__Product__c,
            SBQQ__Quantity__c = quoteLine.SBQQ__Quantity__c,
            SBQQ__Account__c = accountId,
            SBQQ__ListPrice__c = quoteLine.SBQQ__ListPrice__c,
            SBQQ__NetPrice__c = quoteLine.SBQQ__NetPrice__c,
            SBQQ__RegularPrice__c = 38.4,
            SBQQ__CustomerPrice__c = 38.4,
            SBQQ__SpecialPrice__c = 38.4,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__SubscriptionEndDate__c = quoteLine.SBQQ__EndDate__c,
            SBQQ__QuoteLine__c = quoteLine.Id,
            //SBQQ__SubscriptionType__c = 'Renewable', Controlled by Order Product object !?!?!?
            SBQQ__UnitCost__c = quoteLine.SBQQ__UnitCost__c,
            SBQQ__RenewalQuantity__c = 50,
            SBQQ__BillingType__c = quoteLine.SBQQ__BillingType__c
        );
        
        insert subscription;
        
        return subscription;
    }
    /** @description Primary method for creating all the test data
     * @return TestDataResponse
     */
    public static Boolean generateCPQTestData() {
        // Don't need the Contract Id to create quote
        Account account =  createAccount();
        Contact primaryContact = createPrimaryContact(account.Id);
        Contact billingContact = createBillingContact(account.Id);
        Opportunity opportunity = createOpportunity(account.Id, billingContact.Id);
        Product2 product = createProduct();
        PricebookEntry pricebookEntry = createPricebookEntry(product.Id); 
        
        CreateQuoteAndContractParameters parameters = new CreateQuoteAndContractParameters();
        
        parameters.accountId = account.Id;
        parameters.primaryContactId = primaryContact.Id;
        parameters.billingContactId = billingContact.Id;
        parameters.opportunityId = opportunity.Id;

        SBQQ__Quote__c quote = createQuote(parameters);
        SBQQ__QuoteLine__c quoteLine = createQuoteLine(quote.Id, product.Id, pricebookEntry);
        Contract contract = createContract(parameters, quote.Id);
        SBQQ__Subscription__c subscription = createSubscription(account.Id, contract.Id, quoteLine);
        SBQQ__QuoteTemplate__c  quoteTemplate = createQuoteTemplate();

        //Contract.CWS_OF_Signed_Date__c may have to update this after creating the signed quote document?
        // Need to change quote status to 'Accepted' and Opportunuty status to 'Closed Won'

        quote.SBQQ__Status__c = 'Accepted';
        quote.CWS_Bill_To_Contact__c = billingContact.Id;
        quote.CWS_Bill_To_Account__c = account.Id;

        update quote;

        opportunity.StageName = 'Closed Won';

        update opportunity;

        return true;
    }
}