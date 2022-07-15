/* Class Name   : CWS_MangaeDealConversion_Test
 * Description  : Test Class for ManageDealConversion Controller Class
 * Created By   : Megha Shetty
 * Created On   : 8/5/2020
 *Modification Log
*------------------------------------------------------------------------------------------
*Developer              			Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_MangaeDealConversion_Test {
@testSetup
    static void createTestData(){
		
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','Order'});
        
        // Create Account
		Map<String, Object> accountFieldValues=new Map<String, Object>{
            'CWS_Payment_Terms__c'=>'Due Upon Receipt',
            'currencyIsoCode'=>'USD',
            'CWS_Account_Restriction_Status__c'=>'No Restriction',
            'CWS_MNG_Partner_Log_In__c'=>'login id'
            };
        Account account1=CWS_UTLDataFactory.createAccount('TestAccount', accountFieldValues,true);
        
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>true
           
            };
        Contact primaryContact = CWS_UTLDataFactory.createContact('Mark', 'Anthony', account1.Id, contactFieldValues, true);
        
		// Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            	'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'StageName'=>'Prospecting',
                'Type'=>'Amendment',
                'CWS_Bill_To_Account__c'=> account1.Id,
                'Amount'=>30000,
                'Probability'=>50,
                'CurrencyIsoCode'=>'USD',
                'CWS_Legal_Entity__c'=>'CW-US',
				'CWS_Disti_Deal_Phase__c'=>''
        };
		Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',account1.Id,opportunityFields,true);
		
        //create Promotion

        Map<String, Object> promotionFieldValues=new Map<String, Object>{
            'CWS_Promo_Code__c'=>'NEWCST',
            'CWS_Description__c'=>'Discount for new cst',
            'CWS_Start_Date__c'=>Date.today(),
            'CWS_End_Date__c'=>Date.today().addMonths(12),
            'CWS_Category__c'=>'Manage',
            'CWS_Discount__c' => 20
            };    
        CWS_Promotion__c promotion = CWS_UTLDataFactory.createPromotion( promotionFieldValues,true);
		
        // Create Quote
		Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Draft', 
            'CWS_Quote_Type__c'=>'Amendment',
            'RecordTypeId'=>CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY,
            'CWS_Transaction_Reason__c'=> 'Agreement Conversion',
            'CWS_Conversion_Type__c'=>'Subscription to SaaS',
            'CWS_Promo_Code__c'=>'',
            'CWS_Promotion__c' => promotion.Id,
            'CWS_Promo_Code_Description__c' => 'Discount for new customer',
            'CWS_Bill_To_Account__c'=> account1.Id,
			'CWS_Ship_To_Account__c'=> account1.Id,
            'SBQQ__PrimaryContact__c'=>primaryContact.Id,
            'CWS_Add_Terms_Manually__c' => '',
            'SBQQ__SubscriptionTerm__c'=> 12
            
        };
 
        SBQQ__Quote__c quote1=CWS_UTLDataFactory.createQuote(account1.Id, opty.Id, quoteFields, true);
		
        //Create Product
        Map<String, Object> productFields=new Map<String, Object>{
            'CWS_Category__c'=>'Manage', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12,
            'CWS_Charge_Model__c'=>'Per Unit Pricing', 
      		'CWS_License_Type__c'=>'SaaS', 
      		'CWS_Route_to_Market__c'=>'Direct', 
      'CWS_SKU_Type__c'=>'Services', 
      'CWS_UOM__c'=>'Each', 
      'CWS_Sub_Category__c'=>'License', 
      'CWS_Currencies__c'=>'USD;CAD;AUD;EUR;GBP', 
      'CWS_Status__c'=>'Active', 
      'CWS_Billing_Term__c'=>'Monthly', 
      'CWS_Product_Family__c'=>'BDR', 
      'CW_Product_Type__c'=>'Charge', 
      'CWS_ChargeType__c'=>'Usage', 
      'CWS_Item_Revenue_Category__c'=>'Saas-Billing',  
      'CWS_Product_Line__c'=>'None' ,
      'SBQQ__BillingType__c'=>'Advance',
      'SBQQ__PricingMethod__c'=>'List',
      'Description'=>'Test',
      'CWS_Description__c'=>'Test'
              };
                  
        Product2 product=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,true);
        
        //Create Pricebook entry
        PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product.Id,1000.00,'USD', true);
        
        //Insert Quote line for Quote 1
       	List<SBQQ__QuoteLine__c> quoteLineItem1 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product.Id);
        quoteLineItem1[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem1[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem1[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem1[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem1[0].CWS_Provisioning_Eligibility__c='Immediate';
        quoteLineItem1[0].CWS_ServicesProvisioned__c= false;
        quoteLineItem1[0].CWS_Transaction_Type__c ='';
        if(quoteLineItem1!=null){
        insert quoteLineItem1;
        } 

	}
    
     @isTest
    static void testQuoteWithErrorCase(){
        Test.startTest();
        CWS_Promotion__c promotion =[Select CWS_Promo_Code__c,CWS_Description__c,CWS_Active__c,CWS_Category__c from CWS_Promotion__c];
        system.debug('Promotion created'+promotion.CWS_Active__c+promotion.CWS_Promo_Code__c );
        SBQQ__Quote__c quote = [Select Id, Name, CurrencyIsoCode,CWS_Promotion__c, CWS_Quote_Type__c,SBQQ__PricebookId__c,SBQQ__Ordered__c, CWS_Transaction_Reason__c, CWS_Promo_Code__c, CWS_Promo_Code_Description__c,CWS_Linecount_AddOn__c, CWS_Linecount_Cancel__c, CWS_Conversion_Type__c, SBQQ__Account__r.CWS_MNG_Partner_Log_In__c, SBQQ__Account__r.Name, SBQQ__PrimaryContact__r.Name from SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c quotelineObj = [select Id,CWS_Transaction_Type__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quote.id][0];
        quote.CWS_Promo_Code__c = 'NEWCST';
        quote.CWS_Promo_Code_Description__c = 'Discount for new customer';
        quote.SBQQ__Status__c ='Approved';
        quote.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quote.SBQQ__Ordered__c = true;
       
        quotelineObj.CWS_Transaction_Type__c = 'Add-on';
        update quotelineObj;
        update quote;
        system.debug('Quote.Promo code'+quote.CWS_Promo_Code__c+quote.CWS_Promo_Code_Description__c+quote.CWS_Promo_Code_Description__c.length());
        string s = quote.CWS_Promo_Code_Description__c;
        system.debug('Size'+ s.length());
        	//PageReference pageRef = Page.CWS_ManageDealConversionComp; // Add your VF page Name here
            //pageRef.getParameters().put('qid', String.valueOf(quote.Id));
        	CWS_ManageDealConversionController CntrlInstance = new CWS_ManageDealConversionController();
        	CntrlInstance.quotesId = quote.Id;
        	CntrlInstance.qName =quote.Name;
        	CWS_ManageDealConversionController.EmailDataWrapper eWrap = CntrlInstance.wrap;
        	//CntrlInstance.EmailDataWrapper emailInstance = new CntrlInstance.EmailDataWrapper();
            //Test.setCurrentPage(pageRef);
	        

        Test.stopTest();
        
    }
}