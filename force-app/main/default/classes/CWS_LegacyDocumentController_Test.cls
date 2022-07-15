/* Class Name   : CWS_LegacyDocument_Controller_Test
 * Description  : Test Class for LegacyDocumentController Class
 * Created By   : Megha Shetty
 * Created On   : 8/7/2020
 * Modification Log:
*------------------------------------------------------------------------------------------
*Developer                          Date            User Story              Description
*------------------------------------------------------------------------------------------
*/

@IsTest(SeeAllData=false)
public class CWS_LegacyDocumentController_Test {
    @TestSetup
    static void createTestData(){

        // Create Account
        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'CWS_Payment_Terms__c'=>'Due Upon Receipt',
            'currencyIsoCode'=>'USD',
            'CWS_Account_Restriction_Status__c'=>'No Restriction'
            };
        Account account1 = CWS_UTLDataFactory.createAccount('TestAccount', accountFieldValues,true);
        
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>true
           
            };
        Contact primaryContact = CWS_UTLDataFactory.createContact('Mark', 'Anthony', account1.Id, contactFieldValues, true);
        
        // Create Opportunity
        Map<String, Object> opportunityFields = new Map<String, Object>{
                'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'StageName'=>'Prospecting',
                'Type'=>'New',
                'CWS_Master__c' => true,
                'CWS_Ramp_Options__c'=>'Minimum Commit Ramp',
                'CWS_Bill_To_Account__c'=> account1.Id,
                'CWS_Period_of_Fixed_Usage_Commit_Ramp__c'=>3,
                'Amount'=>30000,
                'Probability'=>50,
                'CurrencyIsoCode'=>'USD',
                'CWS_Legal_Entity__c'=>'CW-US',
                'CWS_Disti_Deal_Phase__c'=>''
        };
        Opportunity opty = CWS_UTLDataFactory.createOpportunity('New Business Opty',account1.Id,opportunityFields,true);
        Map<String,Object> mincommitFields1 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'JAN-20',
            'CWS_Monthly_Minimum_Commit__c'=> 2000
        };
        Map<String,Object> mincommitFields2 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'MAR-20',
            'CWS_Monthly_Minimum_Commit__c'=> 2800
        };
        Map<String,Object> mincommitFields3 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'APR-20',
            'CWS_Monthly_Minimum_Commit__c'=> 1200
        };
        Map<String,Object> mincommitFields4 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'FEB-20',
            'CWS_Monthly_Minimum_Commit__c'=> 2300
        };
        Map<String,Object> mincommitFields5 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'MAY-20',
            'CWS_Monthly_Minimum_Commit__c'=> 2400
        };
        Map<String,Object> mincommitFields6 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'JUN-20',
            'CWS_Monthly_Minimum_Commit__c'=> 4000
        };
        Map<String,Object> mincommitFields7 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'JUL-20',
            'CWS_Monthly_Minimum_Commit__c'=> 4500
        };
        Map<String,Object> mincommitFields8 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'SEP-20',
            'CWS_Monthly_Minimum_Commit__c'=> 4560
        };
        Map<String,Object> mincommitFields9 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'AUG-20',
            'CWS_Monthly_Minimum_Commit__c'=> 6890
        };
        Map<String,Object> mincommitFields10 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'DEC-20',
            'CWS_Monthly_Minimum_Commit__c'=> 4023
        };
        Map<String,Object> mincommitFields11 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'NOV-20',
            'CWS_Monthly_Minimum_Commit__c'=> 3400
        };
        Map<String,Object> mincommitFields12 = new Map<String,Object>{
            'CWS_Month_Year__c'=> 'OCT-20',
            'CWS_Monthly_Minimum_Commit__c'=> 5690
        };
        CWS_BillingPeriod__c bp = new CWS_BillingPeriod__c(
                CWS_Account__c = account1.Id,
                CWS_MonthYear__c = 'OCT 20'
        );
        insert bp;
        CWS_Minimum_Commit__c minCommit01 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields1, true);
        CWS_Minimum_Commit__c minCommit02 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields2, true);
        CWS_Minimum_Commit__c minCommit03 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields3, true);
        CWS_Minimum_Commit__c minCommit04 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields4, true);
        CWS_Minimum_Commit__c minCommit05 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields5, true);
        CWS_Minimum_Commit__c minCommit06 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields6, true);
        CWS_Minimum_Commit__c minCommit07 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields7, true);
        CWS_Minimum_Commit__c minCommit08 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields8, true);
        CWS_Minimum_Commit__c minCommit09 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields9, true);
        CWS_Minimum_Commit__c minCommit10 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields10, true);
        CWS_Minimum_Commit__c minCommit11 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields11, true);
        CWS_Minimum_Commit__c minCommit12 = CWS_UTLDataFactory.createMinCommit(opty.Id, bp.Id, mincommitFields12, true);

        Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'CWS_Quote_Type__c'=>'Amendment',
            'CWS_Route_to_Market__c'=>'Direct',
            'CWS_Bill_To_Account__c'=> account1.Id,
            'CWS_Ship_To_Account__c'=> account1.Id,
            'CWS_Bill_To_Contact__c'=>primaryContact.id,
            'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
            'SBQQ__SubscriptionTerm__c'=> 12,
             'RecordTypeId'=>CWS_ConstantClass.QUOTE_RTYPE_AMEND_RONLY    
        };
        
        //Create Product
        Map<String, Object> productFields=new Map<String, Object>{
            'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12,
            'CWS_Charge_Model__c'=>'Per Unit Pricing', 
            'CWS_License_Type__c'=>'SaaS', 
            'CWS_Route_to_Market__c'=>'Direct',
            'CWS_Hide_on_OrderForm__c'=> false,
            'CWS_Source__c' => CWS_ConstantClass.PRODUCT_SOURCE_CMS,
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
      'CWS_Description__c'=>'Test',
      'CWS_Include_In_Minimum_Commit__c' => true
      
              };
         Map<String, Object> productFields2=new Map<String, Object>{
            'CWS_Category__c'=>'Other', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>1,
            'CWS_Charge_Model__c'=>'Per Unit Pricing', 
            'CWS_License_Type__c'=>'Other', 
            'CWS_Route_to_Market__c'=>'Direct',
            'CWS_Hide_on_OrderForm__c'=> false,
            'CWS_Source__c' => CWS_ConstantClass.PRODUCT_SOURCE_CMS,
      'CWS_SKU_Type__c'=>'Fee', 
      'CWS_UOM__c'=>'Each', 
      'CWS_Sub_Category__c'=>'Other', 
      'CWS_Currencies__c'=>'USD;CAD;AUD;EUR;GBP', 
      'CWS_Status__c'=>'Active', 
      'CWS_Billing_Term__c'=>'Monthly', 
      'CWS_Product_Family__c'=>'Other', 
      'CW_Product_Type__c'=>'Product', 
      'CWS_ChargeType__c'=>'Usage', 
      'CWS_Item_Revenue_Category__c'=>'Saas-Billing', 
      'CWS_Renewal_Type__c'=>'Opt-out', 
      'CWS_Product_Line__c'=>'None' ,
      'SBQQ__BillingType__c'=>'Advance',
      'SBQQ__PricingMethod__c'=>'List',
      'Description'=>'Minimum Commitment Charge',
      'CWS_Description__c'=>'Minimum Commitment Charge',
      'CWS_Base_SKU__c' => '900901',
      'CWS_Include_In_Minimum_Commit__c' => true
              };
                  
        Product2 product=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,true);
        Product2 product2=CWS_UTLDataFactory.createProduct('Minimum Commitment Charge', 'CU-OTHERSAAS900901',productFields2,true);
        
        //Create Pricebook entry
        PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product.Id,1000.00,'USD', true);
        PricebookEntry pbe1=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product2.Id,10.00,'USD', true);
        
        SBQQ__Quote__c quote1=CWS_UTLDataFactory.createQuote(account1.Id, opty.Id, quoteFields, true);
        
        //Insert Quote line for Quote 1
        List<SBQQ__QuoteLine__c> quoteLineItem1 = CWS_UTLDataFactory.createQuoteLines(1, quote1.Id, product.Id);
        quoteLineItem1[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem1[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem1[0].SBQQ__NetPrice__c= 3000;
        quoteLineItem1[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem1[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem1[0].CWS_Provisioning_Eligibility__c='Immediate';
        quoteLineItem1[0].CWS_ServicesProvisioned__c = false;
        quoteLineItem1[0].CWS_Convenience_Term__c = 10;
        quoteLineItem1[0].CWS_Termination_for_Convenience__c = true;
        quoteLineItem1[0].CWS_Transaction_Type__c = 'Swap-out';
        if(quoteLineItem1!=null){
        insert quoteLineItem1;
        } 
    
    }

    @IsTest
    static void testQuote() {
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c LIMIT 1];
        //SBQQ__QuoteLine__c quotelineObj = [select Id from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quote.id][0];
        
        // Create Quote template
        Map<String, Object> QuoteTemplateFieldValues = new Map<String,Object>{'Name'=>'End Customer Order Form Legacy CMS'};
        SBQQ__QuoteTemplate__c Qtemplate = CWS_UTLDataFactory.createQuoteTemplate(QuoteTemplateFieldValues, true);

        // Create Quote Document
        Map<String, Object> QDFieldValues = new Map<String,Object>{'SBQQ__QuoteTemplate__c'=>Qtemplate.Id};
        SBQQ__QuoteDocument__c EndCstOF = CWS_UTLDataFactory.createQuoteDocument(quote.Id, QDFieldValues, true);
        
        ApexPages.currentPage().getParameters().put('qid', String.valueOf(quote.Id));
        CWS_LegacyDocument_Controller legacyInstance = new CWS_LegacyDocument_Controller();
        legacyInstance.fetchData();
        Test.stopTest();
        
    }
}