/*Class Name: CWS_QuoteDocumentTriggerHelper_Test
*Description: Helper Class for CWS_QuoteDocumentTriggerHandler
*Created By: Khayam
*Created On: 4/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                 4/6/2020        BED-5213            Quote Stage sync with Quote Documents
*Aditya                 8/11//2020 
*/
@isTest(SeeAllData=false)
public with sharing class CWS_QuoteDocumentTriggerHelper_Test {
    
    @TestSetup
    static void init(){
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Quote','SBQQ__QuoteDocument__c'});
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                'currencyIsoCode'=>'EUR',
                'CWS_Is_Distributor__c'=>true,
                'Industry'=>'MSP',
                'CWS_Sub_Industry__c'=>'N/A',
                'CWS_Additional_Emails_for_Invoice__c'=>'test@add.com'
                };
                    Account acc = CWS_UTLDataFactory.createAccount('accountName', soldtoaccountFieldValues, true);
        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                'currencyIsoCode'=>'EUR',
                'CWS_Is_Partner__c'=>true,
                'CWS_Is_Distributor__c'=>true,
                'CWS_Need_Recurring__c'=>true,
                'Industry'=>'MSP',
                'CWS_Sub_Industry__c'=>'N/A'
                };
                    Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,3,true);        
        
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(acc.Id,distiaccounts[0].Id, CWS_ConstantClass.DISTRIBUTOR_TYPE,'Deal Reg', null, null, true);
        
        //Create Contract
        Map<String, Object> contAdditionalFieldValues = new Map<String, Object>{
            'CWS_Transaction_Reason__c' => CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL,
                'CWS_Quote_SubType__c' => 'Credit',
                'CWS_OF_Signed_Date__c'=>System.today(),
                'StartDate' => System.today(),
                'CWS_30_Days_Sent__c'=>false,
                'ContractTerm' =>1
                };
                    Contract cont = CWS_UTLDataFactory.createContract(acc.id, contAdditionalFieldValues, true);
        
        // Create Opportunity1
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
                'Type'=>'Renewal','CurrencyIsoCode'=>'USD', 'SBQQ__RenewedContract__c'=>cont.id
                }; 
                    Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',acc.id, opportunityFields, true);
        
        // Create Opportunity2
        Map<String, Object> opportunityFields2=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> distiaccounts[0].Id,
                'Type'=>'Renewal','CurrencyIsoCode'=>'USD', 'SBQQ__RenewedContract__c'=>cont.id
                }; 
                    Opportunity opp2 = CWS_UTLDataFactory.createOpportunity('optyName',acc.id, opportunityFields2, true);
        
        //Create Contact1
        Map<String, Object> conFields = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
                'Email'=> 'test@test.com'
                };
                    Contact contact=CWS_UTLDataFactory.createContact('soldToFirstName','soldToLastName', acc.Id, conFields, true);
        
        //Create Contact2
        Map<String, Object> conFields2 = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
                'Email'=> 'test@test2.com'
                };
                    Contact contact2=CWS_UTLDataFactory.createContact('soldToFirstName','soldToLastName2', distiaccounts[0].Id, conFields2, true);
        
        Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Primary__c'=>false,
                'CWS_Quote_Type__c'=>'Renewal',
                'CWS_Add_Terms_Manually__c'=>'Test123456',
                'SBQQ__ExpirationDate__c'=> System.today(),
                'CWS_Bill_to_Account__c'=> distiaccounts[0].Id,
                'CWS_Reference_Expiry_Date__c' =>null,
                'CWS_IsCloned__c' => false,
                // 'SBQQ__WatermarkShown__c'=>false,
                'CWS_Route_to_Market__c'=>'Direct',
                'CWS_On_Hold__c' =>false,
                'SBQQ__Type__c' => CWS_ConstantClass.QUOTE_TYPE_QUOTE,
                'CWS_Renewal_Category__c'=> CWS_ConstantClass.Renewal_Type_OptIn,
                'SBQQ__PrimaryContact__c'=>contact.id,
                'CWS_Bill_to_Contact__c'=> contact2.id,
                'CWS_Renewal_Document_Generated_Date__c' =>null
                }; 
                    SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(acc.id, opp.id, quoteFields, true);
        
        //Create quote2
        Map<String, Object> quoteFields2=new Map<String,Object>{
            'SBQQ__Primary__c'=>false,
                'CWS_Quote_Type__c'=>'Renewal',
                'CWS_Add_Terms_Manually__c'=>'Test123456',
                'SBQQ__ExpirationDate__c'=> System.today(),
                'CWS_Bill_to_Account__c'=> distiaccounts[0].Id,
                'CWS_Reference_Expiry_Date__c' =>null,
                'CWS_IsCloned__c' => false,
                //'SBQQ__WatermarkShown__c'=>false,
                'CWS_Route_to_Market__c'=>'Channel',
                'CWS_On_Hold__c' =>false,
                'SBQQ__Type__c' => CWS_ConstantClass.QUOTE_TYPE_QUOTE,
                'CWS_Renewal_Category__c'=>CWS_ConstantClass.Renewal_Type_OptOut,
                'SBQQ__PrimaryContact__c'=>contact.id,
                'CWS_Bill_to_Contact__c'=> contact2.id
                }; 
                    SBQQ__Quote__c quote2 = CWS_UTLDataFactory.createQuote(acc.id, opp2.id, quoteFields2, true);
        
        /*
        //Create template
        Map<String, Object> quoteTemplate = new Map<String, Object>{
        'Name' => 'End Customer Order Form English'
        };
        SBQQ__QuoteTemplate__c qTemp1= CWS_UTLDataFactory.createQuoteTemplate(quoteTemplate,true);

        List<CWS_Renewal_Email_Settings__mdt> lstRecs = new List<CWS_Renewal_Email_Settings__mdt>();
        CWS_Renewal_Email_Settings__mdt recs = new CWS_Renewal_Email_Settings__mdt();
        recs.MasterLabel = 'EndCustomerQuoteTemplateId';
        recs.CWS_Value__c = qTemp1.id;
        lstRecs.add(recs);
        insert lstRecs;
        */
        Document document = new Document();
        document.AuthorId = UserInfo.getUserId();
        document.FolderId = UserInfo.getUserId();
        document.Name = 'TestDoc';
        document.type = 'pdf';
        document.Body = Blob.valueOf('TestBodyDoc');
        insert document;  
        
    } 
    
    @IsTest
    static void testQuoteOFG(){
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
            'CWS_Renewal_Batch_User__c' => true
                };
                    
                    User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                                                               'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        
        SBQQ__Quote__c quote = [SELECT id, CWS_Renewal_Category__c from SBQQ__Quote__c where CWS_Route_to_Market__c ='Direct'];
        quote.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptOut;
        quote.SBQQ__WatermarkShown__c = false;
        update quote;
        
        CWS_Renewal_Email_Settings__mdt rec = [Select id, CWS_Value__c from CWS_Renewal_Email_Settings__mdt where MasterLabel = 'EndCustomerQuoteTemplateId'];
        Document doc = [Select id from Document Limit 1];
        System.runAs(admin){
            Test.startTest();
            
            //Create QuoteDOcument
            Map<String, object> docFields = new Map<String, Object>{
                
                //'SBQQ__SignatureStatus__c'=> CWS_ConstantClass.QDOC_SIG_SIGNED, 
                'SBQQ__ElectronicSignature__c'=>false,
                    'SBQQ__DocumentId__c' => doc.id,
                    //'CWS_Document_Type__c' => CWS_ConstantClass.QDOC_TYPE_OF,
                    'SBQQ__Version__c'=>1,
                    'SBQQ__QuoteTemplate__c' =>rec.CWS_Value__c
                    };
                        SBQQ__QuoteDocument__c qDoc = CWS_UTLDataFactory.createQuoteDocument(quote.id, docFields, true);
            if (quote.id != NULL) {
                quote = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c where id=: quote.id];
            }
            //CWS_QuoteDocumentTriggerHelper obj = new CWS_QuoteDocumentTriggerHelper();
            Set<Id> quoteId = new Set<Id>();
            
            quote.SBQQ__Primary__c = false;
            update quote;
            quoteId.add(quote.id);
            CWS_QuoteDocumentTriggerHelper.voidQuoteDocument(qDoc.Id);
            // Moved this to CWS_QuoteDocumentTriggerUtility.cls
            CWS_QuoteDocumentTriggerUtility.asyncUpdatePrimaryCheckbox(quoteId);
            //System.assertEquals(CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN,quote.SBQQ__Status__c,'Quote status should be Order Form Generated');
            
            Test.stopTest();
        } 
    }
    
    @IsTest
    static void testQuoteAwaitSign(){
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c where CWS_Route_to_Market__c ='Channel'];
        quote.SBQQ__WatermarkShown__c = false;
        update quote;
        
        CWS_Renewal_Email_Settings__mdt rec = [Select id, CWS_Value__c from CWS_Renewal_Email_Settings__mdt where MasterLabel = 'DistiQuoteTemplateId'];
        Document doc = [Select id from Document Limit 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
            'CWS_Renewal_Batch_User__c' => true
                };
                    
                    User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                                                               'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        
        System.runAs(admin){ 
            
            Test.startTest();
                 
            //Create QuoteDOcument
            Map<String, object> docFields = new Map<String, Object>{
                
                //'SBQQ__SignatureStatus__c' => CWS_ConstantClass.QDOC_SIG_SIGNED,  
                'SBQQ__ElectronicSignature__c'=>false,
                    'SBQQ__DocumentId__c' => doc.id,
                    'SBQQ__Version__c'=>1,
                    'SBQQ__QuoteTemplate__c' =>rec.CWS_Value__c
                    };
                        SBQQ__QuoteDocument__c qDoc = CWS_UTLDataFactory.createQuoteDocument(quote.id,docFields, true);
            qDoc.CWS_Offline_Signature_Status__c = CWS_ConstantClass.QDOC_SIG_SENT;
            if (qDoc != NULL) {
                update qDoc;
            }
            if (quote.id != NULL) {
                quote = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c where id=: quote.id];    
            }
            //System.assertEquals(CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG,quote.SBQQ__Status__c,'Quote status should be Awaiting Signature');
            
            Test.stopTest();
        }  
    }
    
    @IsTest
    static void testQuoteAccepted(){
        
        SBQQ__Quote__c quote = [SELECT id,CWS_Renewal_Document_Generated_Date__c,CWS_Renewal_Category__c from SBQQ__Quote__c where CWS_Route_to_Market__c ='Direct'];
        quote.SBQQ__WatermarkShown__c = false;
        quote.CWS_Renewal_Document_Generated_Date__c = null;
        quote.CWS_Renewal_Category__c=CWS_ConstantClass.Renewal_Type_OptOut;
        update quote;
        
        CWS_Renewal_Email_Settings__mdt rec = [Select id, CWS_Value__c from CWS_Renewal_Email_Settings__mdt where MasterLabel = 'DistiQuoteTemplateId'];
        
        Document doc = [Select id from Document Limit 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
            'CWS_Renewal_Batch_User__c' => true
                };
                    
                    User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                                                               'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        
        System.runAs(admin){ 
            Test.startTest();
            //Create QuoteDocument
            Map<String, object> docFields = new Map<String, Object>{
                
                //'SBQQ__SignatureStatus__c'=> CWS_ConstantClass.QDOC_SIG_SIGNED,  
                'SBQQ__ElectronicSignature__c'=>false,
                    'SBQQ__DocumentId__c' => doc.id,
                    'SBQQ__Version__c'=>1,
                    'SBQQ__QuoteTemplate__c' =>rec.CWS_Value__c
                    };
                        SBQQ__QuoteDocument__c qDoc = CWS_UTLDataFactory.createQuoteDocument(quote.id,docFields, true);
            qDoc.CWS_Offline_Signature_Status__c = CWS_ConstantClass.QDOC_SIG_SIGNED;
            if (qDoc != NULL) {
                update qDoc;
            }
            if (quote.id != NULL) {
                quote = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c where id=: quote.id];    
            }
            //System.assertEquals(CWS_ConstantClass.QUOTE_STATUS_ACCEPTED,quote.SBQQ__Status__c,'Quote status should be Accepted');
            
            Test.stopTest();
        }  
    }
    
    
    
    
    
    @isTest
    static void testUnCovertedMethods(){
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c LIMIT 1];
        quote.SBQQ__WatermarkShown__c = false;
        update quote;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
            'CWS_Renewal_Batch_User__c' => true
                };
                    
                    User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                                                               'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        
        System.runAs(admin){ 
            Test.startTest();
            
            SBQQ__QuoteDocument__c qDoc = CWS_UTLDataFactory.createQuoteDocument(quote.id,new Map<String, Object>{}, true);
            List<SBQQ__QuoteDocument__c> qDocList = new List<SBQQ__QuoteDocument__c>();
            Map<Id,SBQQ__QuoteDocument__c> qDocMap = new Map<Id,SBQQ__QuoteDocument__c>();
            
            CWS_QuoteDocumentTriggerHandler handler = new CWS_QuoteDocumentTriggerHandler();
            handler.BeforeUpdate(qDocMap,qDocMap);
            handler.BeforeDelete(qDocMap);
            handler.AfterDelete(qDocMap);
            handler.AfterUndelete(qDocMap);
            
            Test.stopTest();
            System.assertNotEquals(qDoc,NULL,'Failed to create Quote Document');
        }
    }     
    
    @IsTest
    static void testChannelOptIn(){
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c where CWS_Route_to_Market__c ='Channel'];
        CWS_Renewal_Email_Settings__mdt rec = [Select id, CWS_Value__c from CWS_Renewal_Email_Settings__mdt where MasterLabel = 'DistiQuoteTemplateId'];
        quote.CWS_Renewal_Category__c = CWS_ConstantClass.Renewal_Type_OptIn;
        quote.SBQQ__Status__c = 'Approved';
        quote.SBQQ__WatermarkShown__c = false;
        
        update quote;
        Document doc = [Select id from Document Limit 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
            'CWS_Renewal_Batch_User__c' => true
                };
                    
                    User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                                                               'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        
        System.runAs(admin){  
            Test.startTest();
            
            //Create QuoteDOcument
            Map<String, object> docFields = new Map<String, Object>{
                
                //'SBQQ__SignatureStatus__c'=> CWS_ConstantClass.QDOC_SIG_SIGNED,  
                'SBQQ__ElectronicSignature__c'=>false,
                    'SBQQ__DocumentId__c' => doc.id,
                    'SBQQ__Version__c'=>1,
                    'SBQQ__QuoteTemplate__c' =>rec.CWS_Value__c
                    };
                        SBQQ__QuoteDocument__c qDoc = CWS_UTLDataFactory.createQuoteDocument(quote.id,docFields, true);
            qDoc.CWS_Offline_Signature_Status__c = CWS_ConstantClass.QDOC_SIG_SENT;
            if (qDoc != NULL) {
                update qDoc;
            }
            if (quote.id != NULL) {
                quote = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c where id=: quote.id];    
            }
            
            
            //System.assertEquals(CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG,quote.SBQQ__Status__c,'Quote status should be Awaiting Signature');
            
            Test.stopTest();
        }  
    }
    
    @IsTest
    static void testQuoteAgreementInEffect(){
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c where CWS_Route_to_Market__c ='Channel'];
        quote.SBQQ__WatermarkShown__c = false;
        update quote;
        
        CWS_Renewal_Email_Settings__mdt rec = [Select id, CWS_Value__c from CWS_Renewal_Email_Settings__mdt where MasterLabel = 'DistiQuoteTemplateId'];
        Document doc = [Select id from Document Limit 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Map<String, Object> userFields = new Map<String, Object>{
            'CWS_Renewal_Batch_User__c' => true
                };
                    
                    User admin = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','System Administrator',
                                                               'CEO',uniqueName + '@test' + orgId + '.org',userFields ,true);
        
        System.runAs(admin){ 
            Test.startTest();
            Map<String, object> docFields = new Map<String, Object>{ 
                'SBQQ__ElectronicSignature__c'=>false,
                    'SBQQ__DocumentId__c' => doc.id,
                    'SBQQ__Version__c'=>1,
                    'SBQQ__QuoteTemplate__c' =>rec.CWS_Value__c
                    };
                        SBQQ__QuoteDocument__c qDoc = CWS_UTLDataFactory.createQuoteDocument(quote.id,docFields, true);
            //qDoc.CWS_Offline_Signature_Status__c = CWS_ConstantClass.QDOC_SIG_SENT;
            qDoc.SBQQ__SignatureStatus__c = CWS_ConstantClass.QDOC_SIG_SIGNED;
            if (qDoc != NULL) {
                update qDoc;
            }
            Test.stopTest();
            
        }  
    }
    
}