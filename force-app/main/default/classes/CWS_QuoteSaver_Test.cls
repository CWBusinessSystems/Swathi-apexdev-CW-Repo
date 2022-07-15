/*Class Name: CWS_QuoteDocumentTriggerHelpher
*Description: Helper Class for CWS_QuoteDocumentTriggerHandler
*Created By: Harsha
*Created On: 8/11/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------

*/
@isTest(SeeAllData=false)
public class CWS_QuoteSaver_Test {
 
    @isTest
    static void createTestData(){
    
    CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','SBQQ__QuoteDocument__c'});
        
     // Create Account
		Map<String, Object> accountFieldValues=new Map<String, Object>{
            'CWS_Payment_Terms__c'=>'Due Upon Receipt',
            'CurrencyIsoCode'=>'USD',
            'CWS_Account_Restriction_Status__c'=>'No Restriction'
            };
        Account account1=CWS_UTLDataFactory.createAccount('TestAccount_QuoteSaver', accountFieldValues,true);
        
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>true
           
            };
        Contact primaryContact = CWS_UTLDataFactory.createContact('Mark', 'Anthony', account1.Id, contactFieldValues, true);
        
		// Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            	'CWS_Route_to_Market__c'=>'Direct', 
                'CloseDate'=> Date.today(),
                'StageName'=>'Prospecting',
                'Type'=>'New',
                'CWS_Master__c' => false,
                'CWS_Bill_To_Account__c'=> account1.Id,
                'Amount'=>30000,
                'Probability'=>50,
                'CurrencyIsoCode'=>'USD',
                'CWS_Legal_Entity__c'=>'CW-US',
				'CWS_Disti_Deal_Phase__c'=>''
        };
		Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',account1.Id,opportunityFields,true);
      
         //Create quote2
         Map<String, Object> quoteFields2=new Map<String,Object>{
             'SBQQ__Primary__c'=>false,
             'CWS_Quote_Type__c'=>'Renewal',
             'CWS_Add_Terms_Manually__c'=>'Test123456',
             'SBQQ__ExpirationDate__c'=> System.today(),
             'CWS_Reference_Expiry_Date__c' =>null,
             'CWS_IsCloned__c' => false,
             'CWS_Bill_To_Account__c'=> account1.ID,
             'SBQQ__WatermarkShown__c'=>false,
             'CWS_Route_to_Market__c'=>'Direct',
             'CWS_On_Hold__c' =>false,
              'SBQQ__Type__c' => CWS_ConstantClass.QUOTE_TYPE_QUOTE,
              'CWS_Renewal_Category__c'=>CWS_ConstantClass.Renewal_Type_OptOut
                 }; 
        SBQQ__Quote__c quote2 = CWS_UTLDataFactory.createQuote(account1.id, opty.id, quoteFields2, true);
 
          Test.startTest();    
        CWS_QuoteModel  CQM = new CWS_QuoteModel ();
        CQM.channelDiscountsOffList = false;
        CQM.record = quote2;
        CQM.lineItems = new List <CWS_QuoteLineModel>();
        CQM.lineItemGroups = new list <CWS_QuoteLineGroupModel>();
        CQM.applyAdditionalDiscountLast = false;
        CQM.applyPartnerDiscountFirst = false;
        CQM.channelDiscountsOffList = false;
      CWS_QuoteSaver cqs = new CWS_QuoteSaver();
        cqs.save(CQM);
        
         Test.stopTest();   
        
       }
    
}