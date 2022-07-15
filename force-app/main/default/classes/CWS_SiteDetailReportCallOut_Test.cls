/*Class Name: CWS_SiteDetailReportCallOut_Test
*Description: Test Class for CWS_SiteDetailReportCallOut
*Created By: Mahak Bansal
*Created On: 30/6/2021
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Mahak Bansal		    30/6/2021		OBD-154		           Initial Version
*/
@isTest
public class CWS_SiteDetailReportCallOut_Test {
    
    /* @description: Test Setup for CWS_SiteDetailReportCallOutTest
    * @return: void  */
    @TestSetup
    public static void setup() 
    {        
        Account testAccountOne = new Account(
            Name = 'BB8 Test Account',
            Phone = '727 777 3625',
            BillingStreet = '8800 Bay Pines Boulevard',
            BillingCity = 'St. Petersburg',
            BillingCountry = 'United States',
            BillingState = 'Florida',
            BillingPostalCode = '33715',
            CWS_Account_Restriction_Status__c = 'No Restriction',
            CWS_Products_Owned__c = 'Automate',
            CWS_Is_Partner__c = true,
            CWS_Is_Distributor__c = true,
            CWS_Need_Recurring__c = true,
            CWS_SSO_GUID__c = '5f6d07a5e6426900017a3ad5',
            CurrencyIsoCode = 'USD',
            Industry = 'MSP',
            CWS_Sub_Industry__c = 'N/A',
            SBQQ__PriceHoldEnd__c = System.today().addMonths(6),
            CWS_Additional_Emails_for_Invoice__c = 'bmarly@gmail.com.invalid, jcochran@gmail.com.invalid'
        );
        insert testAccountOne;
        Contact contact = new Contact(LastName = 'hello',FirstName = 'World',Email = 'a@dolby.com',AccountId =  testAccountOne.Id);
        insert contact;


        Zuora__ZInvoice__c zInvoice = new Zuora__ZInvoice__c();
        zInvoice.Zuora__Account__c=testAccountOne.Id;
        zInvoice.Name='INV-123';
        zInvoice.Zuora__InvoiceDate__c=System.today()-20;
        zInvoice.CWS_CMS_Invoice__c='FALSE';
        insert zInvoice;

        Zuora__ZInvoice__c zInvoice1 = new Zuora__ZInvoice__c();
        zInvoice1.Zuora__Account__c=testAccountOne.Id;
        zInvoice1.Name='INV-432';
        zInvoice1.Zuora__InvoiceDate__c=System.today()-10;
        zInvoice1.CWS_CMS_Invoice__c='TRUE';
        insert zInvoice1;
    }

      /**
    * @description API test for negative scenario
    */ 
    @isTest static void showSiteDetailReportNegative() {
        Zuora__ZInvoice__c invoice =[SELECT ID,Name,CWS_CMS_Invoice__c,Zuora__InvoiceDate__c,Zuora__Account__r.CWS_Account_Unique_Identifier__c  FROM Zuora__ZInvoice__c where name='INV-123'];
        CWS_SiteDetailReportCallOut.SiteDetailResponse resp=CWS_SiteDetailReportCallOut.showSiteDetailReport(invoice.ID);
        System.assertEquals(false,resp.showSiteDetailButton,'SiteDetailReport response is not visible');
    }

    /**
    * @description API test for positive scenario
    */ 
    @isTest static void succesRes() {

        Zuora__ZInvoice__c invoice2 =[SELECT ID,Name,CWS_CMS_Invoice__c,Zuora__InvoiceDate__c,Zuora__Account__r.CWS_Account_Unique_Identifier__c  FROM Zuora__ZInvoice__c where name='INV-432'];
        CWS_SiteDetailReportCallOut.SiteDetailResponse resp2=CWS_SiteDetailReportCallOut.showSiteDetailReport(invoice2.ID);
        System.assertEquals(true, resp2.showSiteDetailButton,'SiteDetailReport button is visible');

        Test.setMock(HttpCalloutMock.class, new SuccessfulResponse());
        if(resp2!=null &&resp2.showSiteDetailButton){
            Test.startTest();
            CWS_SiteDetailReportCallOut.GetSiteDetailResponse response=CWS_SiteDetailReportCallOut.getSiteDetailReport(invoice2.Id);
            System.assert(response.isSuccess == true,'SiteDetailReport response is success');
            Test.stopTest();
        }
    }

    /**
    * @description API test if the ID is not a valid invoice record in Salesforce 
    */ 
    @isTest static void noInvoiceRecord() {
        //Have to test  using a hardcode value to test the breaking scenarios
        String invoiceId='a3n6t000000GmyjAAC';
        CWS_SiteDetailReportCallOut.SiteDetailResponse showSiteDetailResp=CWS_SiteDetailReportCallOut.showSiteDetailReport(invoiceId);
        System.assertEquals(false, showSiteDetailResp.showSiteDetailButton,'SiteDetailReport button should not be visible');
        
        Test.setMock(HttpCalloutMock.class, new SuccessfulResponse());
        Test.startTest();
        CWS_SiteDetailReportCallOut.GetSiteDetailResponse response=CWS_SiteDetailReportCallOut.getSiteDetailReport(invoiceId);
		System.assert(response.isSuccess == false, 'SiteDetailReport response is false');
        Test.stopTest();
    }

    /**
    * @description Test if the profile is not able to access the Invoice Record.
    */ 
    @isTest static void testPofileInAccessible() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Read Only' LIMIT 1];
        UserRole userRoleRec= [SELECT Id FROM userRole WHERE Name = 'Sales Operations' LIMIT 1];
		
        User user = new User(alias = 'standt', email='a@dolby.com',emailencodingkey='UTF-8',FirstName = 'hello',
                    lastname='Testing',languagelocalekey='en_US',
					localesidkey='en_US',profileid = profile.Id,UserRoleId = userRoleRec.id,timezonesidkey='America/Los_Angeles',
					CommunityNickname = 'Tom',isActive = true,username='a@dolby.com');
		insert user;
        //Have to test  using a hardcode value to test the breaking scenarios
        String invoiceId='a3n6t000000GmyjAAC';
 
        Test.startTest();
        System.runAs(user){         
            CWS_SiteDetailReportCallOut.SiteDetailResponse showSiteDetailResp=CWS_SiteDetailReportCallOut.showSiteDetailReport(invoiceId);
            System.assertEquals(false, showSiteDetailResp.showSiteDetailButton,'SiteDetailReport button should not be visible');   
        }
        Test.stopTest();
    }

    /**
    * @description API test for failed, or negative scenario for CWS_SiteDEtailReport
    */ 
    @isTest static void failedRes() {
        Zuora__ZInvoice__c invoice2 =[SELECT ID,Name,CWS_CMS_Invoice__c,Zuora__InvoiceDate__c,Zuora__Account__r.CWS_Account_Unique_Identifier__c  FROM Zuora__ZInvoice__c where name='INV-432'];
        CWS_SiteDetailReportCallOut.SiteDetailResponse resp2=CWS_SiteDetailReportCallOut.showSiteDetailReport(invoice2.ID);
        System.assertEquals(true, resp2.showSiteDetailButton,'SiteDetailReport button should be visible');
        if(resp2.showSiteDetailButton){
            CWS_SiteDetailReportCallOut.getSiteDetailReport(invoice2.Id);            
        }
    }

    /**
    * @description Mock Response class for the success of the API 
    */ 
    public class SuccessfulResponse implements HttpCalloutMock {

        /**
        * @description Method to generate Mock reposnse of the API
        */ 
        public HTTPResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            Attachment attach=new Attachment();   	
            attach.Name='Unit Test Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.body=bodyBlob;
            String bodyRES='{"body":'+ bodyBlob+'}';
            response.setBody(bodyRES);
            //response.setBody('{"SiteDetail":"testtest","Error":""}');
            response.setStatusCode(200);
            return response;
        }        
    }   
}