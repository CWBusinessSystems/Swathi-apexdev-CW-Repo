/* Class Name   : CWS_ContentDocumentLinkHelper_Test
 * Description  : Test Class for CWS_ContentDocumentLinkHelper Class
 * Created By   : Megha Shetty
 * Created On   : 8/14/2020
 * Modification Log
*------------------------------------------------------------------------------------------
*Developer              			Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_ContentDocumentLinkHelper_Test {

    @testSetup
    static void createTestData(){
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'SBQQ__Quote__c','Account', 'Opportunity','Content Document'});
        // Create Account
		Map<String, Object> accountFieldValues=new Map<String, Object>{
            'CWS_Payment_Terms__c'=>'Due Upon Receipt',
            'currencyIsoCode'=>'USD',
            'CWS_Account_Restriction_Status__c'=>'No Restriction'
            };
       Account account1=CWS_UTLDataFactory.createAccount('TestAccount', accountFieldValues,true);
       
        //create Contact
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
                'Amount'=>30000,
                'Probability'=>50,
                'CurrencyIsoCode'=>'USD',
                'CWS_Legal_Entity__c'=>'CW-US',
				'CWS_Disti_Deal_Phase__c'=>''
        };
		Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',account1.Id,opportunityFields,true);
        
        Map<String, Object> quoteFields=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 
            'CWS_Quote_Type__c'=>'New Business',
            'CWS_Route_to_Market__c'=>'Direct',
            'CWS_Bill_To_Account__c'=> account1.Id,
			'CWS_Ship_To_Account__c'=> account1.Id,
            'CWS_Bill_To_Contact__c'=>primaryContact.id,
            'SBQQ__PricebookId__c'=>Test.getStandardPricebookId(),
            'SBQQ__SubscriptionTerm__c'=> 12
        };
       SBQQ__Quote__c quote1=CWS_UTLDataFactory.createQuote(account1.Id, opty.Id, quoteFields, true);
       
        //insert Agreement
        Map<String, Object> agreementFields = new Map<String,Object>{
        'RecordTypeId'=> CWS_ConstantClass.SOW_Agreement_RT,
        'CWS_Quote__c'=> quote1.Id,
        'CWS_No_of_Signed_Docs__c'=> 2,
         'Apttus__Status_Category__c'=>'In Effect',
          'Apttus__Status__c'=>'Activated',
          'Apttus__Activated_Date__c'=>System.today()
        
            };
        Map<String, Object> agreementFields1 = new Map<String,Object>{
        'RecordTypeId'=> CWS_ConstantClass.Distributor_Agreement_RT,
        'CWS_No_of_Signed_Docs__c'=> 2,
         'Apttus__Status_Category__c'=>'In Effect',
          'Apttus__Status__c'=>'Activated'
        
            };  
        CWS_UTLDataFactory.createAgreement (account1.Id,agreementFields,true);   
        CWS_UTLDataFactory.createAgreement (account1.Id,agreementFields1,true);  

}
    @isTest
    static void testafterInsert(){
        
        Test.startTest();
        
        List<Apttus__APTS_Agreement__c> agreement =[Select id, CWS_No_of_Signed_Docs__c,CWS_Agreement_Document_Name__c,CWS_Quote__c,Apttus__Account__c from Apttus__APTS_Agreement__c];
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c LIMIT 1];
        
        //insert ContentVersion        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'signed Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
		insert contentVersion; 
        
        //ContentDocument cd = new ContentDocument();
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
		//0690v000001EgPR-AttachedContentDocuments
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = agreement[0].Id;
        contentlink.ShareType = 'V';
        contentlink.ContentDocumentId = documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        ContentDocumentLink contentlink1 = new ContentDocumentLink();
        contentlink1.LinkedEntityId = agreement[1].Id;
        contentlink1.ShareType = 'V';
        contentlink1.ContentDocumentId = documents[0].Id;
        contentlink1.Visibility = 'AllUsers'; 
        insert contentlink1;
        
        Map<Id, ContentDocumentLink> newItems = new Map<Id, ContentDocumentLink>{contentlink.Id=>contentlink};
        Map<Id, ContentDocumentLink> newItems1 = new Map<Id, ContentDocumentLink>{contentlink.Id=>contentlink};
            
        CWS_ContentDocumentLinkHelper.afterInsert(newItems);
        CWS_ContentDocumentLinkHelper.afterInsert(newItems1);
        
        CWS_ContentDocumentLinkHandler obj = new CWS_ContentDocumentLinkHandler();
        obj.BeforeDelete(new Map<Id, SObject>());
        obj.BeforeUpdate(new Map<Id, SObject>(),new Map<Id, SObject>());
        obj.AfterUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
        obj.AfterDelete(new Map<Id, SObject>());
        obj.AfterUndelete(new Map<Id, SObject>());
        Test.stopTest();
    }
    
     @isTest 
    Static void testDelete(){
         List<Apttus__APTS_Agreement__c> agreement =[Select id, CWS_No_of_Signed_Docs__c,CWS_Agreement_Document_Name__c,CWS_Quote__c,Apttus__Account__c from Apttus__APTS_Agreement__c];
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        //insert ContentVersion        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'signed Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
		insert contentVersion; 
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
          ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = agreement[0].Id;
        contentlink.ShareType = 'V';
        contentlink.ContentDocumentId = documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        ContentDocumentLink contentlink1 = new ContentDocumentLink();
        contentlink1.LinkedEntityId = agreement[1].Id;
        contentlink1.ShareType = 'V';
        contentlink1.ContentDocumentId = documents[0].Id;
        contentlink1.Visibility = 'AllUsers'; 
        insert contentlink1;
		delete documents;
        CWS_ContentDocumentHandler obj = new CWS_ContentDocumentHandler();
        obj.AfterUndelete(new Map<Id, SObject>());
        Test.stopTest();
    }
    
     @isTest 
    Static void testAttachBatch(){
         List<Apttus__APTS_Agreement__c> agreement =[Select id, CWS_No_of_Signed_Docs__c,CWS_Agreement_Document_Name__c,CWS_Quote__c,Apttus__Account__c from Apttus__APTS_Agreement__c];
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        //insert ContentVersion        
        Blob b = Blob.valueOf('Test Data');
     
    	 Attachment attachment = new Attachment();
     	attachment.ParentId = agreement[0].id;
     	attachment.Name = 'signed';
     	attachment.Body = b;
     
     insert(attachment);
		//CWS_AttachSignedDocToAccount batch = new CWS_AttachSignedDocToAccount();
        //Database.executeBatch(batch, 1);
       
        Test.stopTest();
    }
    }