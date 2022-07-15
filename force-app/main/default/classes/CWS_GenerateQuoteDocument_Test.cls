/* Class Name   : CWS_GenerateQuoteDocument_Test
 * Description  : Test Class for CWS_GenerateQuoteDocument Controller Class
 * Created By   : Megha Shetty
 * Created On   : 8/3/2020
 *Modification Log
*------------------------------------------------------------------------------------------
*Developer              			Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_GenerateQuoteDocument_Test {
    @testSetup
    static void createTestData(){
		
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','Order','SBQQ__QuoteDocument__c'});
        
        // Create Account
		Map<String, Object> accountFieldValues=new Map<String, Object>{
            'CWS_Payment_Terms__c'=>'Due Upon Receipt',
            'currencyIsoCode'=>'USD',
            'CWS_Account_Restriction_Status__c'=>'No Restriction'
            };
        Account account1=CWS_UTLDataFactory.createAccount('TestAccount', accountFieldValues,true);
        
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>True
            };
        Contact primaryBillingcon = CWS_UTLDataFactory.createContact('Test1', 'Test2',  account1.id, contactFieldValues, true);

		// Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            	'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'StageName'=>'Prospecting',
                'CWS_Bill_To_Account__c'=> account1.Id,
                'Amount'=>30000,
                'Probability'=>50,
            	'Type'=>'New',
                'CurrencyIsoCode'=>'USD',
                'CWS_Legal_Entity__c'=>'CW-US',
				'CWS_Disti_Deal_Phase__c'=>''
        };
		Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',account1.Id,opportunityFields,true);
		
		// Create Quote
		Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'SBQQ__Type__c'=>'New', 
            'CWS_Quote_Type__c'=>'New Business',
            'CWS_Bill_To_Account__c'=> account1.Id,
			'CWS_Ship_To_Account__c'=> account1.Id,
            'CWS_Bill_To_Contact__c'=>primaryBillingcon.id,
			'SBQQ__WatermarkShown__c' => false,
			'CWS_Document_Clauses__c' => 'Special Users Audit - 1;Assurance Prorate;Hen',
            'CWS_Add_Terms_Manually__c' => '',
            'SBQQ__SubscriptionTerm__c'=> 12
        };
 
        SBQQ__Quote__c quote1=CWS_UTLDataFactory.createQuote(account1.Id, opty.Id, quoteFields, true);
		
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
        if(quoteLineItem1!=null){
        insert quoteLineItem1;
        } 
        
		// Create Quote Terms
		Map<String, Object> QTFieldValues1 = new Map<String,Object>{
		'CWS_Clause_Name__c' => 'Assurance Prorate - 1',
		'CW_Manual_Clause__c' => true,
        'SBQQ__PrintOrder__c' => 5
		
		};
		Map<String, Object> QTFieldValues2 = new Map<String,Object>{
		'CWS_Clause_Name__c' => 'Special Users Audit - 1',
		'CW_Manual_Clause__c' => true,
		'SBQQ__PrintOrder__c' => 1
		};
		
		Map<String, Object> QTFieldValues3 = new Map<String,Object>{
		'CWS_Clause_Name__c' => 'Assurance Prorate',
		'CW_Manual_Clause__c' => true,
        'SBQQ__PrintOrder__c' => 2
		
		};
		Map<String, Object> QTFieldValues4 = new Map<String,Object>{
		'CWS_Clause_Name__c' => 'Reseller',
		'CW_Manual_Clause__c' => true,
        'SBQQ__PrintOrder__c' => 3
		
		};
		
		SBQQ__QuoteTerm__c QTerm1 = CWS_UTLDataFactory.createQuoteTerms(quote1.Id, QTFieldValues1, true);
		SBQQ__QuoteTerm__c QTerm2 = CWS_UTLDataFactory.createQuoteTerms(quote1.Id, QTFieldValues2, true);
		SBQQ__QuoteTerm__c QTerm3 = CWS_UTLDataFactory.createQuoteTerms(quote1.Id, QTFieldValues3, true);
		SBQQ__QuoteTerm__c QTerm4 = CWS_UTLDataFactory.createQuoteTerms(quote1.Id, QTFieldValues4, true);
	
        
	}
    
    @isTest
    static void testQuoteWithErrorCase(){
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT id,SBQQ__Status__c,CWS_Custom_sow__c,CWS_Add_Terms_Manually__c, CWS_Document_Clauses__c,CWS_Bill_To_Account__c,SBQQ__SubscriptionTerm__c,SBQQ__WatermarkShown__c,SBQQ__ExpirationDate__c from SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c quotelineObj = [select Id from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quote.id][0];
        List<SBQQ__QuoteTerm__c> lstManClause = [SELECT CWS_Clause_Name__c, CW_Manual_Clause__c FROM SBQQ__QuoteTerm__c WHERE CW_Manual_Clause__c =: true];
        quote.CWS_Add_Terms_Manually__c ='Reseller';
        quote.SBQQ__WatermarkShown__c = false;
        update quote;
        system.debug('document clauses'+quote.CWS_Document_Clauses__c);
        system.debug('SBQQ__Status__c'+quote.SBQQ__Status__c);
        system.debug('SBQQ__WatermarkShown__c'+quote.SBQQ__WatermarkShown__c);
        system.debug('SBQQ__ExpirationDate__c'+quote.SBQQ__ExpirationDate__c);
        // Create Quote template
		Map<String, Object> QuoteTemplateFieldValues = new Map<String,Object>{'Name'=>'End Customer Order Form English'};
        SBQQ__QuoteTemplate__c Qtemplate = CWS_UTLDataFactory.createQuoteTemplate(QuoteTemplateFieldValues, true);

        // Create Quote Document
		Map<String, Object> QDFieldValues = new Map<String,Object>{'SBQQ__QuoteTemplate__c'=>Qtemplate.Id};
		SBQQ__QuoteDocument__c EndCstOF = CWS_UTLDataFactory.createQuoteDocument(quote.Id, QDFieldValues, true);
 		CWS_GenerateQuoteDocumentController.validateQuoteOnDocGen(quote.ID);
        Test.stopTest();
        
    }
    
    @isTest
    static void testNoErrorCase(){
        Test.startTest();
        SBQQ__Quote__c quote2 = [SELECT id,SBQQ__Status__c,CWS_Custom_sow__c,CWS_Add_Terms_Manually__c, CWS_Document_Clauses__c,CWS_Bill_To_Account__c,SBQQ__SubscriptionTerm__c,SBQQ__WatermarkShown__c,SBQQ__ExpirationDate__c from SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c quotelineObj = [select Id from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quote2.id][0];
        List<SBQQ__QuoteTerm__c> lstManClause = [SELECT CWS_Clause_Name__c, CW_Manual_Clause__c FROM SBQQ__QuoteTerm__c WHERE CW_Manual_Clause__c =: true];
        quote2.CWS_Add_Terms_Manually__c ='Reseller';
        quote2.SBQQ__WatermarkShown__c = false;
        quote2.CWS_Document_Clauses__c = 'Special Users Audit - 1;Assurance Prorate;';
        update quote2;
        system.debug('document clauses'+quote2.CWS_Document_Clauses__c);
        system.debug('SBQQ__Status__c'+quote2.SBQQ__Status__c);
        system.debug('SBQQ__WatermarkShown__c'+quote2.SBQQ__WatermarkShown__c);
        system.debug('SBQQ__ExpirationDate__c'+quote2.SBQQ__ExpirationDate__c);
        // Create Quote template
		Map<String, Object> QuoteTemplateFieldValues = new Map<String,Object>{'Name'=>'End Customer Order Form English'};
        SBQQ__QuoteTemplate__c Qtemplate = CWS_UTLDataFactory.createQuoteTemplate(QuoteTemplateFieldValues, true);

        // Create Quote Document
		Map<String, Object> QDFieldValues = new Map<String,Object>{'SBQQ__QuoteTemplate__c'=>Qtemplate.Id};
		SBQQ__QuoteDocument__c EndCstOF = CWS_UTLDataFactory.createQuoteDocument(quote2.Id, QDFieldValues, true);
 		CWS_GenerateQuoteDocumentController.validateQuoteOnDocGen(quote2.ID);
        Test.stopTest();
        
    }

}