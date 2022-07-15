@isTest
private class LeanDataCustomInterfaceTest {
    static testMethod void testMethodd(){
        LeanDataCustomInterface testInterface = new LeanDataCustomInterface();
        
        Account acc = new Account();
        acc.Name = 'Test Company';
        acc.BillingStreet = 'Test Street';
        acc.BillingState = 'California';
        acc.BillingPostalCode = '95051';
        acc.BillingCountry = 'United States';
        acc.BillingCity = 'Sunnyvale';
        insert acc;
        
        Lead primary = new Lead();
        primary.FirstName = 'Test';
        primary.LastName = 'Lead';
        primary.Company = 'Test Company';
        primary.State = 'California';
        primary.Country = 'United States';
        primary.CWS_Product_Intrest__c = 'ITBoost';
        insert primary;
        
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'Test';
        primaryContact.LastName = 'Contact';
        primaryContact.MailingState = 'California';
        primaryContact.MailingCountry = 'United States';
        primaryContact.Email = 'testcontact@testemail.com';
        primaryContact.AccountId = acc.Id;
        primaryContact.CWS_Product_Interest__c = 'ITBoost';
        insert primaryContact;
        
        LeanData_Custom_Interface_Setting__c lcis = new LeanData_Custom_Interface_Setting__c();
        lcis.Key__c = 'ITBoost';
        lcis.Value__c = 'ITBoost';
        
        insert lcis;
        
        Product2 product = new Product2(
            Name='Demo Test Product',
            CWS_ProductCode__c='DEMQ9009',
            CWS_Category__c='ITBoost',
            SBQQ__BillingType__c='Advance',
            SBQQ__PricingMethod__c='Cost',
            SBQQ__SubscriptionTerm__c=12,
            CWS_Description__c='Cloud Access DW Security',     
            CWS_Charge_Model__c='Per Unit Pricing',
            CWS_Product_Family__c='Other',
            CWS_License_Type__c='SaaS',
            CWS_Product_Line__c='Corporate',
            CWS_Status__c='Active',
            CWS_Sub_Category__c='License',
            CW_Product_Type__c='Product',
            CWS_SKU_Type__c='Other',
            CWS_Renewal_Type__c='Opt-out',
            CWS_Route_to_Market__c='Direct',
            CWS_Currencies__c='USD',
            CWS_Billing_Term__c='Monthly',
            CWS_ChargeType__c='Recurring',
            CWS_Item_Revenue_Category__c='Services',
            IsActive= True,
            SBQQ__SubscriptionPricing__c='Fixed Pricing',
            CWS_UOM__c='Cost'     
        );
        
        insert product;
        
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.CWS_Category__c = 'ITBoost';
        subscription.SBQQ__Quantity__c = 1;
        subscription.SBQQ__Account__c = acc.Id;
        subscription.SBQQ__Product__c = product.Id;
        
        insert subscription;
        
        Map<String, SObject> chosenSObjects = new Map<String, SObject>();
        chosenSobjects.put('L2A', acc);
        
        testInterface.customRoutingRule((SObject)primary, chosenSObjects, 'Existing Subscription for Product?');
        testInterface.customRoutingRule((SObject)primaryContact, chosenSObjects, 'Existing Subscription for Product?');
        
        testInterface.customRoutingRule((SObject)primary, chosenSObjects, 'Bad Parameter');
        testInterface.customRoutingRule((SObject)primaryContact, chosenSObjects, 'Bad Parameter');
        
        testInterface.getCustomLeadFields();
        testInterface.getCustomContactFields();
        
        testInterface.getMapOfCustomInterfaceNodeNamesToEdges();
    }
}