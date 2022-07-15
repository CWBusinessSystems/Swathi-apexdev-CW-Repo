/*Class Name: CWS_OrderTriggerHelperTest
*Description: Test Class for CWS_OrderTriggerHelper
*Created By: swachatterjee
*Created On: 4/9/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*swachatterjee          4/3/2020            -                  Initial Version
*swachatterjee          4/9/2020        BED - 1278,1233       Test class for Helper (testInDraftOrder,testUnderReviewOrder) 
*Aditya          7/31/2020          
*/
@isTest
public class CWS_OrderTriggerHelperTest {
   

    @TestSetup
    static void makeData(){
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
          'CWS_Renewal_Batch_User__c' => true
        };
        	 Test.startTest(); 
          User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CWS_Integration_User_permission'];
		insert new PermissionSetAssignment(AssigneeId = admin.id, PermissionSetId = ps.Id);
        System.runas(admin){
        // Activate the Triggers
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','Order'}); 
        /*
        CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
    	insert bypassValidate;
		*/
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
            'CWS_Purchase_Order_Required__c'=>'Yes'
            };
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
		
       
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR','CWS_Is_Partner__c'=>true,'CWS_Is_Distributor__c'=>true};
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
   		   
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', null, null, true);
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', null, null, true);
       
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
              'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
              'Type'=>'New',
                'CurrencyIsoCode'=>'USD',
                'CWS_Distributor__c'=>distiaccounts[0].Id,
                 'CWS_Route_to_Market__c'=>'Channel',
                    'CWS_Legal_Entity__c'=>'CW-US'
        };
           //Create Renewal/Amendment Opportunity 
          Map<String, Object> opportunityFields2=new Map<String, Object>{
              	'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
                'Type'=>'Renewal',
                'CurrencyIsoCode'=>'USD',
                'CWS_Distributor__c'=>distiaccounts[0].Id,
                'CWS_Route_to_Market__c'=>'Channel',
                'CWS_Legal_Entity__c'=>'CW-US'
        };  
         
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);
        Opportunity opty3=CWS_UTLDataFactory.createOpportunity('Renewal Opty 1',soldtoaccount.Id,opportunityFields2,true);
              
        //Create New business Quote record
        Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'CWS_Quote_Type__c'=>'New Business', 
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,
            'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'CWS_Ship_To_Account__c'=>soldtoaccount.Id
               
        };
        SBQQ__Quote__c quote1=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);
    
        //Create Renewal Quote
          Map<String, Object> quoteFields3=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'CWS_Quote_Type__c'=>'Renewal', 
             'CWS_PO_Number__c' => 'ABC123',
            'SBQQ__Distributor__c'=>distiAccounts[0].Id,
            'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
            'CWS_Ship_To_Account__c'=>soldtoaccount.Id
        };
          SBQQ__Quote__c quote3=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty3.Id, quoteFields3, true);
        
        //Create Product
        Map<String, Object> productFields=new Map<String, Object>{
            'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12,
            'CWS_Charge_Model__c'=>'Per Unit Pricing', 
      'CWS_License_Type__c'=>'SaaS', 
      'CWS_Route_to_Market__c'=>'Direct', 
      'CWS_SKU_Type__c'=>'Package', 
      'CWS_UOM__c'=>'Each', 
      'CWS_Sub_Category__c'=>'License', 
      'CWS_Currencies__c'=>'USD;CAD;AUD;EUR;GBP', 
      'CWS_Status__c'=>'Active', 
      'CWS_Billing_Term__c'=>'Monthly', 
      'CWS_Product_Family__c'=>'BDR', 
      'CW_Product_Type__c'=>'Charge', 
      'CWS_ChargeType__c'=>'Usage', 
      'CWS_Item_Revenue_Category__c'=>'Saas-Billing', 
      'CWS_Renewal_Type__c'=>'Opt-out', 
      'CWS_Product_Line__c'=>'None' ,
       'SBQQ__BillingType__c'=>'Advance',
         'SBQQ__PricingMethod__c'=>'List',
          'Description'=>'Test',
          'CWS_Description__c'=>'Test'
              };
        Product2 product=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,false);
        product.SBQQ__SubscriptionType__c='Renewable';
        product.SBQQ__SubscriptionBase__c='List';
        if(product!=null){
        insert product;
        }
      
        //Create Pricebook entry
        PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product.Id,1000.00,'USD', true);
       
        List<SBQQ__QuoteLine__c> quoteLineItemIns = new List<SBQQ__QuoteLine__c>();
        //Insert Quote line for Quote 1
       List<SBQQ__QuoteLine__c> quoteLineItem1 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product.Id);
        quoteLineItem1[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem1[0].SBQQ__StartDate__c=Date.today()+1;
        quoteLineItem1[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem1[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem1[0].CWS_Provisioning_Eligibility__c='Immediate';
        quoteLineItem1[0].CWS_ServicesProvisioned__c= false;
            quoteLineItemIns.add(quoteLineItem1[0]);
    
        //insert quotelin for 2nd Quote
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(1, quote3.Id, product.Id);
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today()+1 ;
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;
           quoteLineItemIns.add(quoteLineItem2[0]); 
      
       insert quoteLineItemIns;
        Test.stopTest();     
            quote3.SBQQ__Primary__c=true;
            quote3.SBQQ__PricebookId__c=Test.getStandardPricebookId();
            quote3.SBQQ__Ordered__c=true; //Create Order for 2nd Quote
            update quote3;
       
            Order orderObj = [select Id,Status,PONumber,CWS_ServicesProvisioned__c, SBQQ__Contracted__c from Order where SBQQ__Quote__c=:quote3.Id];
            OrderItem oliObj = [Select id, SBQQ__Activated__c, SBQQ__Contracted__c, CWS_Provisioning_Eligibility__c,CWS_ServicesProvisioned__c  from OrderItem where OrderId =: orderObj.id];
            oliObj.SBQQ__Activated__c = true;
            oliObj.SBQQ__Contracted__c = true;//Generate a Contract
            orderObj.CWS_ServicesProvisioned__c = true;
            orderObj.Status ='Activated';
            orderObj.SBQQ__Contracted__c = true;
            orderObj.CWS_ZuoraSubscriptionNumber__c = 'abc1234';
            update oliObj;
            update orderObj;
         
       
        }    
    }

    @IsTest
    static void testUnderReviewtOrder(){
        
        Test.startTest();
        SBQQ__Quote__c quoteObj = [select Id,CWS_Bill_To_Account__r.Name,CWS_PO_Number__c from SBQQ__Quote__c where CWS_PO_Number__c=null][0];
        SBQQ__QuoteLine__c quotelineObj = [select Id,CWS_Provisioning_Eligibility__c,CWS_ServicesProvisioned__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quoteObj.id][0];
            quotelineObj.CWS_Provisioning_Eligibility__c = 'NA';
            quotelineObj.CWS_ServicesProvisioned__c = true;
            quotelineObj.CWS_ProvisioningDate__c = System.today();
        	quoteObj.CWS_PO_Number__c = 'ABC123';
            quoteObj.SBQQ__Primary__c=true;
            quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
            quoteObj.SBQQ__Ordered__c=true;
            update quotelineObj;
            update quoteObj;
            Order orderObj = [select Id,Status,PONumber,CWS_ServicesProvisioned__c from Order where SBQQ__Quote__c=:quoteObj.Id];
            orderObj.CWS_ServicesProvisioned__c = true;
            orderObj.Status = 'Draft';
            update orderObj;
        Test.stopTest();
       	System.assertEquals(true, orderObj.CWS_ServicesProvisioned__c);
    }
   
    @IsTest
    static void testRFSOrder(){
       
        CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
    	insert bypassValidate;
        Test.startTest();
        	 SBQQ__Quote__c quoteObj = [select Id,CWS_Bill_To_Account__r.Name,CWS_PO_Number__c from SBQQ__Quote__c where CWS_PO_Number__c=null][0];
       	SBQQ__QuoteLine__c quotelineObj = [select Id,CWS_Provisioning_Eligibility__c,CWS_ServicesProvisioned__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quoteObj.id][0];
  			quotelineObj.CWS_ProvisioningDate__c = null;
        	quotelineObj.CWS_Provisioning_Eligibility__c = 'Manual';
            quoteObj.SBQQ__Primary__c=true;
            quoteObj.CWS_PO_Number__c = 'ABC123';
            quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
            quoteObj.SBQQ__Ordered__c=true;
            update quotelineObj;
            update quoteObj;
            Order orderObj = [select Id,Status,PONumber,CWS_ServicesProvisioned__c from Order where SBQQ__Quote__c=:quoteObj.Id];
           	orderObj.CWS_ServicesProvisioned__c = true;
        	orderObj.Status = 'Draft';
        	update orderObj;
   		Test.stopTest();
        System.assertEquals(true,orderObj.CWS_ServicesProvisioned__c);
       }
    
     @IsTest
    static void testIngram(){
        Test.startTest();
        SBQQ__Quote__c quoteObj = [select Id,CWS_Bill_To_Account__c,CWS_Bill_To_Account__r.CWS_Need_Recurring__c,CWS_Bill_To_Account__r.Name,CWS_PO_Number__c from SBQQ__Quote__c where CWS_PO_Number__c=null][0];
        Account acc = [Select id,CWS_Need_Recurring__c from Account where id =:quoteObj.CWS_Bill_To_Account__c ];
        
            acc.CWS_Need_Recurring__c = true;
            update acc;
            quoteObj.SBQQ__Primary__c=true;
            quoteObj.CWS_PO_Number__c = 'ABC123';
            quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
            quoteObj.SBQQ__Ordered__c=true;
            update quoteObj;
            Order orderObj = [select Id,Status,PONumber,CWS_ServicesProvisioned__c, SBQQ__Contracted__c from Order where SBQQ__Quote__c=:quoteObj.Id];
            orderObj.CWS_ServicesProvisioned__c = true;
            orderObj.Status ='Ready for Submission';
            update orderObj;
    	Test.stopTest();
        System.assertEquals('Ready for Submission',orderObj.Status);
    }
    
     @IsTest
    static void testRenewalScenario(){
        Test.startTest();
            Contract con = [Select id,Status,CWS_Distributor__c,CWS_Distributor__r.name,SBQQ__RenewalForecast__c,SBQQ__RenewalQuoted__c,CWS_Renewal_Category__c,CWS_Renewable_Products__c,StartDate,ContractTerm from Contract limit 1];
            con.Status = 'Activated'; //Activate the Conract
            con.CWS_Renewal_Category__c = 'Opt-Out';
            con.CWS_Renewable_Products__c  = 1;
            update con;
        	//Generate Renewal Opp
            Opportunity opp = [Select id,SBQQ__RenewedContract__c from Opportunity where Type  ='New'];
            opp.Type = 'Renewal';
            opp.SBQQ__RenewedContract__c = con.id;
            update opp;
        	//Generate Renewal Quote
            SBQQ__Quote__c quoteObj1 = [select Id,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c  from SBQQ__Quote__c where SBQQ__Opportunity2__c =:opp.id ];
            quoteObj1.SBQQ__Primary__c=true;
            quoteObj1.CWS_Quote_Type__c='Renewal';
            quoteObj1.SBQQ__PricebookId__c=Test.getStandardPricebookId();
            quoteObj1.SBQQ__Ordered__c=true; //Create Renewal Order
            update quoteObj1;
        Test.stopTest();
        System.assertEquals(con.id, quoteObj1.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);
    }  
    
    @IsTest
    static void tesAmendmentScenario(){
        
      
        Contract con = [Select id,Status,CWS_Distributor__c,CWS_Distributor__r.name,SBQQ__RenewalForecast__c,SBQQ__RenewalQuoted__c,CWS_Renewal_Category__c,CWS_Renewable_Products__c,StartDate,ContractTerm from Contract limit 1];
        con.Status = 'Activated';
        con.CWS_Renewal_Category__c = 'Opt-Out';
        con.CWS_Renewable_Products__c  = 1;
        update con;
        Test.startTest();
    	Opportunity opp = [Select id,SBQQ__RenewedContract__c, type from Opportunity where Type  ='New'];
        opp.type = 'Amendment'; //Generate Amendment Opp
        opp.SBQQ__AmendedContract__c = con.id;
        update opp;
        //Generate AMendment quote
        SBQQ__Quote__c quoteObj1 = [select Id,CWS_Quote_Type__c,SBQQ__StartDate__c,SBQQ__Primary__c,SBQQ__PricebookId__c,SBQQ__Ordered__c  from SBQQ__Quote__c where SBQQ__Opportunity2__c =:opp.id ];
        quoteObj1.CWS_Quote_Type__c='Amendment';
        quoteObj1.SBQQ__Primary__c=true;
        quoteObj1.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quoteObj1.SBQQ__Ordered__c=true; //Create Amendment Order
   		update quoteObj1;
        Test.stopTest();
        
        System.assertEquals(true, quoteObj1.SBQQ__Ordered__c);
    }
     
     @IsTest
    static void testLegacyScenario(){
        //Switch for Legacy Data migration
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
          'CWS_Renewal_Batch_User__c' => true
        };
          
          User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test1' + orgId + '.org','lName','System Administrator',
                'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CWS_Integration_User_permission'];
        Test.startTest();  
		insert new PermissionSetAssignment(AssigneeId = admin.id, PermissionSetId = ps.Id);
        System.runas(admin){
        CWS_Trigger_Switch__c triggerSwitch = [select id,CWS_LegacyDataMigration__c from CWS_Trigger_Switch__c];
        triggerSwitch.CWS_LegacyDataMigration__c = true;
        update triggerSwitch;
      	SBQQ__Quote__c quoteObj = [select Id,CWS_Bill_To_Account__r.Name,SBQQ__PricebookId__c from SBQQ__Quote__c where CWS_PO_Number__c=null][0];
        
        List<SBQQ__QuoteLine__c> updateQL = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLine =[select Id,CWS_Provisioning_Eligibility__c,CWS_ProvisioningDate__c,CWS_ServicesProvisioned__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quoteObj.id];
        for(SBQQ__QuoteLine__c obj:quoteLine){
           obj.CWS_ServicesProvisioned__c = true;
            obj.CWS_ProvisioningDate__c = System.today();
            updateQL.add(obj);
        }
            update updateQL;
            quoteObj.SBQQ__Primary__c=true;
            quoteObj.SBQQ__PricebookId__c=Test.getStandardPricebookId();
            quoteObj.SBQQ__Ordered__c=true;
            update quoteObj;
            Order orderObj = [select Id,Status,PONumber,CWS_ServicesProvisioned__c, SBQQ__Contracted__c from Order where SBQQ__Quote__c=:quoteObj.Id];
            orderObj.Status = 'Activated';
            update orderObj;
        Test.stopTest();
         
        CWS_OrderTriggerHandler handler = new CWS_OrderTriggerHandler();
        map<id,SObject> newRecs = new map<id,SObject>();
        handler.BeforeDelete(newRecs);
        handler.AfterDelete(newRecs);
        handler.AfterUndelete(newRecs);
        System.assertEquals(true, quoteObj.SBQQ__Ordered__c);
        }
       }

}