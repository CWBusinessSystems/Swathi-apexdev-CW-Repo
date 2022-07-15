/*Class Name: CWS_AttachmentTriggerHelper_Test
*Description: test Class for CWS_AttachmentTriggerHelper
*Created By: Nida
*Created On: 08/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Naresh                08/13/2020           BED-6236             
*/
@isTest(SeeAllData=false)
public class CWS_AttachmentTriggerHelper_Test {
    
    @testSetup static void setupTestData(){
        
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Attachment trigger'});  
        
        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'currencyIsoCode'=>'EUR'};
                List<Account> acctLst = CWS_UTLDataFactory.createBulkAccounts('Test Account',accountFieldValues , 1, true);
        
     /*   Map<String, Object> contactFieldValues=new Map<String, Object>{
            'FirstName'=>'test',
                'LastName' => 'contact',
                'AccountId' => acctLst[0].Id,
                'MailingCountry' => 'United States'};
                    List<Contact> contactLst = CWS_UTLDataFactory.createBulkContacts('Test','Contact',acctLst[0].Id,contactFieldValues , 2, true);
        
        Map<String, Object> userFieldValues=new Map<String, Object>{};
                    List<User> userLst = CWS_UTLDataFactory.createBulkUsers('TUser','testuser@test.com','user','System Administrator','CEO','testagr@test.com', userFieldValues,1,true);
        */
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> acctLst[0].Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD','CWS_Min_Commit_QR__c'=> 20000
        };
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',acctLst[0].Id,opportunityFields,true);
        
        
        //Create Quote record
       Map<String, Object> quoteFields=new Map<String,Object>{
             'SBQQ__Primary__c'=>true,
             'CWS_Quote_Type__c'=>'New Business',
             'CWS_Bill_to_Account__c'=> acctLst[0].Id,
             'CWS_Route_to_Market__c'=>'Direct',
             'CWS_Renewal_Category__c'=> CWS_ConstantClass.Renewal_Type_OptIn,
             'SBQQ__StartDate__c'=> Date.today(),
             'SBQQ__SubscriptionTerm__c'=>12
                 }; 
        SBQQ__Quote__c quote=CWS_UTLDataFactory.createQuote(acctLst[0].Id,opty.Id, quoteFields, true);

         //Create Product
        Map<String, Object> productFields=new Map<String, Object>{
            'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12,
            'CWS_Charge_Model__c'=>'Per Unit Pricing', 
      		'CWS_License_Type__c'=>'SaaS', 
      		'CWS_Route_to_Market__c'=>'Direct',
              	'CWS_Source__c' => CWS_ConstantClass.PRODUCT_SOURCE_CMS,
      'CWS_SKU_Type__c'=>'Package', 
      'CWS_UOM__c'=>'Each', 
      'CWS_Sub_Category__c'=>'License', 
      'CWS_Currencies__c'=>'USD;CAD;AUD;EUR;GBP', 
      'CWS_Status__c'=>'Active', 
      'CWS_Billing_Term__c'=>'Monthly', 
      'CWS_Item_Revenue_Category__c'=>'Saas-Billing', 
      'CWS_Renewal_Type__c'=>'Opt-out', 
      'CWS_Product_Line__c'=>'None' ,
      'SBQQ__BillingType__c'=>'Advance',
      'SBQQ__PricingMethod__c'=>'List',
      'Description'=>'Testing',
      'CWS_Description__c'=>'Test1232132'	  
              };
                  
        Product2 product=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,true);
       
        
        
        ContentVersion TestCon = new ContentVersion();
      TestCon.Title = 'Custom SOW test class';
      TestCon.ContentUrl = 'https://test.com';
        
      insert TestCon;
        
        ID sId = [select id, ContentDocumentId from ContentVersion limit 1].ContentDocumentId;
   
     
      
      ContentDocumentLink cd = new ContentDocumentLink();
        cd.ContentDocumentId = sId;
        cd.LinkedEntityId = quote.id;//TestCon.ContentDocumentId;
        insert cd;
        
       ContentDocumentLink cd2 = new ContentDocumentLink();
        cd2.ContentDocumentId = sId;
        cd2.LinkedEntityId = product.id;//TestCon.ContentDocumentId;
        insert cd2;
    }
    @isTest
  static void testAdditionalDocument(){
      Test.StartTest();
      
       list<SBQQ__Quote__c> lstQt=[select id from SBQQ__Quote__c limit 1];
      Set<Id> contentDocumentIdSet =new Set<ID>();     
      
      ContentVersion Att1 = [select id, ContentDocumentId, Title from ContentVersion limit 1];
   
       Map<Id,ContentVersion> Att= new Map<Id,ContentVersion>();
      Att.put(lstQt[0].id,Att1);
      
      If(Att1.ContentDocumentId != null){
            contentDocumentIdSet.add(Att1.ContentDocumentId);
      }  
      
      List<ContentDocumentLink> cd = [select id, ContentDocumentId,  LinkedEntityId , ShareType from ContentDocumentLink WHERE ContentDocumentId IN:contentDocumentIdSet limit 2];

      /*  	 CWS_AttachmentTriggerHelper AttHelp = new CWS_AttachmentTriggerHelper();
      AttHelp.createAdditionalDocument(Att);*/
            CWS_AttachmentTriggerHelper.createAdditionalDocument(Att);
      Map<Id, SObject> newItems = new Map<Id, SObject>();
      CWS_AttachmentTriggerHandler obj = new CWS_AttachmentTriggerHandler();
      obj.BeforeUpdate(newItems, newItems);
      obj.BeforeDelete(newItems);
      obj.AfterUpdate(newItems, newItems);
      obj.AfterDelete(newItems);
      obj.AfterUndelete(newItems);
      
       Test.StopTest();
  }
    
    
    
}