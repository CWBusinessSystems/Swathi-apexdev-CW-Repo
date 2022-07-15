/*Class Name: CWS_NotifySalesRepAboutQuoteExpire_Test
*Description: Batch class to sent email notification to sales about quote expire
*Created By: Harsha
*Created On: 08/12/2020

*Modification Log
*--------------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*--------------------------------------------------------------------------------------------------
*
*/
@isTest
public class CWS_NotifySalesRepAboutQuoteExpire_Test {
    
    @testSetup 
    static void Datasetup() {
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','Order'}); 
        CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'SBQQ__QuoteDocument__c;';
        insert bypassValidate;
        
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
               
              
                'CWS_Bill_To_Account__c'=> account1.Id,
                'Amount'=>1000,
                'Probability'=>50,
                'CurrencyIsoCode'=>'USD',
                'CWS_Legal_Entity__c'=>'CW-US',
                'CWS_Disti_Deal_Phase__c'=>''
                };
                    Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',account1.Id,opportunityFields,true);
        
        //Create quote2
        Map<String, Object> quoteFields2=new Map<String,Object>{
            'SBQQ__Primary__c'=>false,
                'CWS_Quote_Type__c'=>'New Business',
                'CWS_Add_Terms_Manually__c'=>'Test123456',
                'SBQQ__ExpirationDate__c'=> System.today()+7,
               'CWS_Reference_Expiry_Date__c' =>System.today(),
                'CWS_IsCloned__c' => false,
                'CWS_Bill_To_Account__c'=> account1.ID,
                'SBQQ__WatermarkShown__c'=>false,
                'CWS_Route_to_Market__c'=>'Direct',
                'CWS_On_Hold__c' =>false,
                'SBQQ__Type__c' => CWS_ConstantClass.QUOTE_TYPE_QUOTE,
                'CWS_Renewal_Category__c'=>CWS_ConstantClass.Renewal_Type_OptOut
                }; 
                    SBQQ__Quote__c quote2 = CWS_UTLDataFactory.createQuote(account1.id, opty.id, quoteFields2, true);
        
        

           //Create QuoteDOcument
        Map<String, object> docFields = new Map<String, Object>{
            
             'SBQQ__SignatureStatus__c'=>'Pending', 
             'SBQQ__ElectronicSignature__c'=>false,
            // 'SBQQ__DocumentId__c' => doc.id,
              //'CWS_Document_Type__c' => CWS_ConstantClass.QDOC_TYPE_QD,
              'SBQQ__Version__c'=>1
             //  'SBQQ__QuoteTemplate__c' =>rec.CWS_Value__c
        };
        SBQQ__QuoteDocument__c qDoc = CWS_UTLDataFactory.createQuoteDocument(quote2.id, docFields, true);
     
            
        
        
        
    }       
    
    @IsTest
    static void Expalert(){
        Test.startTest();
        
        
        
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__ExpirationDate__c From SBQQ__Quote__c LIMIT 1];
        SchedulableContext sc = null;
        CWS_ScheduleBatchNotifySalesRep tsc = new CWS_ScheduleBatchNotifySalesRep();
        tsc.execute(sc); 
        
        Database.executeBatch(new CWS_BatchNotifySalesRepAboutQuoteExpire(),1);
        
        Test.stopTest();
        
        
    }
    
 @IsTest
    static void Expalert1(){
        Test.startTest();
        
        
        
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__ExpirationDate__c From SBQQ__Quote__c LIMIT 1];
        quote.SBQQ__ExpirationDate__c =System.today();
        Update quote;
        SchedulableContext sc = null;
        CWS_ScheduleBatchNotifySalesRep tsc = new CWS_ScheduleBatchNotifySalesRep();
        tsc.execute(sc); 
        
        Database.executeBatch(new CWS_BatchNotifySalesRepAboutQuoteExpire(),1);
        
        Test.stopTest();
        
        
    }
        
    
    
    


}