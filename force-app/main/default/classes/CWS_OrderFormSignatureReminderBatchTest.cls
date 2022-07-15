/*Class Name: CWS_OrderFormSignatureReminderBatchTest
*Description: Test Class for CWS_OrderFormSignatureReminderBatch
*Created By: Indra Ganesan
*Created On: 08-18-2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            Description
*------------------------------------------------------------------------------------------
*Indra Ganesan         08-18-2020       Test Class for CWS_OrderFormSignatureReminderBatch             
*/
@isTest
public class CWS_OrderFormSignatureReminderBatchTest {

    @TestSetup
    public static void setupData(){
    
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Quote','SBQQ__QuoteDocument__c'});

        Account acc = CWS_UTLDataFactory.createAccount('TestAccount-OrderForm', new Map<String, Object>{}, true);
        Contact contact = CWS_UTLDataFactory.createContact('tst01 FName', 'tst01 lName', acc.id,new Map<String, Object> {'CWS_Primary_Contact__c'=>true}, true);

        Opportunity opp = CWS_UTLDataFactory.createOpportunity('Test Opportunity - Order Form',acc.id, new Map<String, Object>{'CloseDate'=>System.today(),
        'CWS_Bill_To_Account__c'=>acc.Id,'CWS_Route_to_Market__c'=>'Direct'}, true);     
        
        Map<String, Object> addFields = new Map<String,Object>{
        'CWS_Quote_Type__c'=>'New Business',
        'CWS_Bill_To_Account__c'=>acc.id, 
        'SBQQ__Primary__c'=> true,
        'CWS_Master__c'=>false,
        'SBQQ__StartDate__c'=>Date.newInstance(2019,7,7), 
        'SBQQ__EndDate__c'=>Date.newInstance(2019,7,7), 
        'CWS_Route_to_Market__c'=>'Direct',
        'SBQQ__Status__c'=>'Approved',
        'CWS_Bill_To_Contact__c'=>contact.id,
        'SBQQ__PrimaryContact__c'=>contact.id,
        'SBQQ__WatermarkShown__c'=>false
        };    
        
        SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acc.id,opp.id,addFields, true);
        system.debug('!!! quote SBQQ__WatermarkShown__c  ='+quote.SBQQ__WatermarkShown__c);
        quote.SBQQ__WatermarkShown__c = false;
        update quote;

        SBQQ__QuoteTemplate__c quoteTemplate = CWS_UTLDataFactory.createQuoteTemplate(new Map<String, Object> {
        'Name'=>'End Customer Order Form English', 
        'CurrencyIsoCode'=>'USD'}, true);   

        Document document = new Document();
        document.AuthorId = UserInfo.getUserId();
        document.FolderId = UserInfo.getUserId();
        document.Name = 'TestDoc';
        document.type = 'pdf';
        document.Body = Blob.valueOf('TestBodyDoc');
        insert document;  
                
        Map<String, Object> addDocFields = new Map<String, Object>{
            'SBQQ__Quote__c'=>quote.id,
            'CWS_Envelope_Sent_Date__c'=> System.today()-10,  
            'Name'=>'QuoteDocument',
            'SBQQ__DocumentId__c'=>document.id,
            'SBQQ__QuoteTemplate__c'=>quoteTemplate.id
          };     
         
        Map<Integer, Map<String, Object>> createDocsMap = new Map<Integer, Map<String, Object>>();
        for(Integer i= 0; i<50 ; i++){
           createDocsMap.put(i, addDocFields );               
        }        
        List<SBQQ__QuoteDocument__c> lstQDoc = CWS_UTLDataFactory.createQuoteDocuments(createDocsMap, createDocsMap.size() , true) ;
    }    

    public static testMethod void orderFormSignatureReminderBatchtst(){
        list<SBQQ__QuoteDocument__c> LstQuoteDocuments = [SELECT id, SBQQ__SignatureStatus__c from SBQQ__QuoteDocument__c Limit 50];
        for(SBQQ__QuoteDocument__c qDoc: LstQuoteDocuments){
          qDoc.SBQQ__SignatureStatus__c  = 'Sent';
        }
        Test.startTest();
        update LstQuoteDocuments;
        Id batchId = Database.executeBatch(new CWS_OrderFormSignatureReminderBatch(), 50);
        List<SBQQ__QuoteDocument__c> lstUpdatedDocs = [SELECT Id from SBQQ__QuoteDocument__c where SBQQ__SignatureStatus__c =:'Sent'];
        system.assertEquals(50, lstUpdatedDocs.size());
        Test.stopTest();        
    }
}