/*Class Name: CWS_ApprovalTriggerHelper_Test
*Description: Test Class for CWS_ApprovalTriggerHelper
*Created By: Aakash Sharma
*Created On: 4/7/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aakash                 04/03/2020                      
*/
@istest(seealldata = false)
public class CWS_ApprovalTriggerHelper_Test {
 @testSetup static void createTestData(){
    CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Account','Opportunity','Quote','SBQQ__QuoteDocument__c','CWS_Approval_Trigger__c'}); 
 
             //Create Sold To Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                'currencyIsoCode'=>'EUR',
                //'CWS_Additional_Emails_for_Invoice__c'=>'test@gmail.com,test2@gmail.com',
                'CWS_Is_Distributor__c' => true};
                    Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
       
        //Creating Contact for the Account
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
            'CWS_Primary_Contact__c' => true,
            'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
            'Email'=>'test@test.com'
        };
        Contact objCon = CWS_UTLDataFactory.createContact('TestFirstName','TestLastName',soldtoaccount.Id,mapConFieldValues,true); 
 
        
        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                'currencyIsoCode'=>'EUR',
                'CWS_Is_Distributor__c' => true   };
                    Account[] distiAccounts = CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
        
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', 'Automate;Sell', null, true);
        //CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', 'Perch', null, true);
        
        // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Channel', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> soldtoaccount.Id,
                'Type'=>'New','CurrencyIsoCode'=>'EUR'
                };
                    Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,false);
        opty.CurrencyIsoCode='EUR';
        if(opty!=null){
            insert opty;
        }
        
        Map<String, Object> quoteFields2=new Map<String,Object>{
            'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New','CWS_Quote_Type__c'=>CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS ,
                'SBQQ__Primary__c'=>true, 'CWS_Route_to_Market__c'=>'Channel',
                'SBQQ__Distributor__c'=>distiAccounts[0].Id, 'CWS_Renewal_Type__c'=> 'Non-Renewable',
                'SBQQ__StartDate__c'=>Date.today()-345, 'SBQQ__SubscriptionTerm__c'=>12,
                'CWS_Renewal_CAP__c'=>10, 'CWS_Renewal_Uplift_Applicable__c'=>2
                };
                    
                    Map<String, Object> productFields=new Map<String, Object>{
                        'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>12   
                            };
                                Product2 product=CWS_UTLDataFactory.createProduct('TestProduct1', 'SKU123',productFields,false);
        product.SBQQ__SubscriptionType__c='Renewable';
        product.SBQQ__SubscriptionBase__c='List';
        if(product!=null){
            insert product;
        }
        Test.startTest();
        PricebookEntry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(),product.Id,1000.00,'EUR', true);
        SBQQ__Quote__c quote2=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields2, false); 
        quote2.SBQQ__PricebookId__c=Test.getStandardPricebookId();
        quote2.CurrencyIsoCode='EUR';
        if(quote2!=null){
            insert quote2;
        }
        
        List<SBQQ__QuoteLine__c> quoteLineItem = CWS_UTLDataFactory.createQuoteLines(1, quote2.Id, product.Id);
        quoteLineItem[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem[0].SBQQ__SubscriptionTerm__c= 1;
        if(quoteLineItem!=null){
            insert quoteLineItem;
        }
 }
    @isTest static void createApproval(){
        List<Opportunity> opp = [SELECT ID,SBQQ__PrimaryQuote__c from opportunity ];
        List<SBQQ__Quote__c> quoteList = [SELECT ID,SBQQ__Status__c,CWS_Sub_Stage__c from SBQQ__Quote__c];
        List<SBQQ__Quote__c> qtList = new List<SBQQ__Quote__c>();
        system.debug('opp--'+opp);
        system.debug('quoteList--'+quoteList);
        if(!quoteList.isempty()){
            for(SBQQ__Quote__c qt: quoteList){
                qt.SBQQ__ExpirationDate__c = date.today();
                qt.SBQQ__Status__c = 'Accepted';
        		qt.CWS_Sub_Stage__c = 'Accepted';
                qtList.add(qt);
            }
            if(!qtList.isEmpty()){
                update qtList;
            }
        }
        
        sbaa__ApprovalChain__c appchain = new sbaa__ApprovalChain__c();
        appchain.Name =  CWS_ConstantClass.QUOTE_ACC_RESTRICT_APPROVAL;
        appchain.sbaa__TargetObject__c = 'SBQQ__Quote__c';

        insert appchain;
        
		List<sbaa__Approval__c> approvalList = new List<sbaa__Approval__c>();
        sbaa__Approval__c approval = new sbaa__Approval__c();
        	approval.CWS_Quote__c = qtList[0].Id;
            approval.sbaa__Opportunity__c = opp[0].Id;
            approval.sbaa__Status__c = 'Requested';
        	approval.sbaa__ApprovalChain__c= appchain.Id;
        	approval.sbaa__ApprovalStep__c = 1;
            approval.sbaa__RecordField__c = 'CWS_Quote__c';
        approvalList.add(approval);
        
        sbaa__Approval__c approval1 = new sbaa__Approval__c();
        	approval1.CWS_Quote__c = qtList[0].Id;
            approval1.sbaa__Opportunity__c = opp[0].Id;
            approval1.sbaa__Status__c = 'Requested';
        	approval1.sbaa__ApprovalChain__c= appchain.Id;
        	approval1.sbaa__ApprovalStep__c = 1;
            approval1.sbaa__RecordField__c = 'CWS_Quote__c';
        approvalList.add(approval1);       
            Insert approvalList;
        
        List<sbaa__Approval__c> appvlsList = [SELECT id,sbaa__Status__c,sbaa__ApprovalChain__r.Name,CWS_Quote__c,CWS_Quote__r.SBQQ__Opportunity2__c,
                                                        CWS_Quote__r.SBQQ__Opportunity2__r.CWS_Rejected_Approval_Count__c,
                                                           CWS_Quote__r.Id from sbaa__Approval__c];
        system.debug('appvlsMap--'+appvlsList);
        if(appvlsList.size()>0 && appvlsList.size() ==2 ){
            appvlsList[0].sbaa__Status__c = CWS_ConstantClass.QUOTE_Approval_Status_Rejected;
            appvlsList[1].sbaa__Status__c = CWS_ConstantClass.QUOTE_Approval_Status_Rejected;
            update appvlsList;
        }
    }
    
    @isTest static void createApproval1(){
        List<Opportunity> opp = [SELECT ID,SBQQ__PrimaryQuote__c from opportunity ];
        List<SBQQ__Quote__c> quoteList = [SELECT ID,SBQQ__Status__c,CWS_Sub_Stage__c from SBQQ__Quote__c];
        List<SBQQ__Quote__c> qtList = new List<SBQQ__Quote__c>();
        system.debug('opp--'+opp);
        system.debug('quoteList--'+quoteList);
        if(!quoteList.isempty()){
            for(SBQQ__Quote__c qt: quoteList){
                qt.SBQQ__ExpirationDate__c = date.today();
                qt.SBQQ__Status__c = 'Accepted';
        		qt.CWS_Sub_Stage__c = 'Accepted';
                qtList.add(qt);
            }
            if(!qtList.isEmpty()){
                update qtList;
            }
        }
        
        sbaa__ApprovalChain__c appchain = new sbaa__ApprovalChain__c();
        appchain.Name =  CWS_ConstantClass.QUOTE_ACC_RESTRICT_APPROVAL;
        appchain.sbaa__TargetObject__c = 'SBQQ__Quote__c';

        insert appchain;
        
        sbaa__Approval__c approval = new sbaa__Approval__c();
        	approval.CWS_Quote__c = qtList[0].Id;
            //approval.sbaa__Opportunity__c = opp[0].Id;
            approval.sbaa__Status__c = 'Requested';
        	approval.sbaa__ApprovalChain__c= appchain.Id;
        	approval.sbaa__ApprovalStep__c = 1;
            approval.sbaa__RecordField__c = 'CWS_Quote__c';
            Insert approval;
        
        List<sbaa__Approval__c> appvlsList = [SELECT id,sbaa__Status__c,sbaa__ApprovalChain__r.Name,CWS_Quote__c,CWS_Quote__r.SBQQ__Opportunity2__c,
                                                        CWS_Quote__r.SBQQ__Opportunity2__r.CWS_Rejected_Approval_Count__c,
                                                           CWS_Quote__r.Id from sbaa__Approval__c];
        system.debug('appvlsMap--'+appvlsList);
        if(appvlsList.size()>0){
            appvlsList[0].sbaa__Status__c = CWS_ConstantClass.QUOTE_Approval_Status_Rejected;
            update appvlsList[0];
        }
    }
        @isTest static void UpdateApproval(){
        List<Opportunity> opp = [SELECT ID,SBQQ__PrimaryQuote__c from opportunity ];
        List<SBQQ__Quote__c> quoteList = [SELECT ID,SBQQ__Status__c,CWS_Sub_Stage__c from SBQQ__Quote__c];
        List<SBQQ__Quote__c> qtList = new List<SBQQ__Quote__c>();
        system.debug('opp--'+opp);
        system.debug('quoteList--'+quoteList);
        if(!quoteList.isempty()){
            for(SBQQ__Quote__c qt: quoteList){
                qt.SBQQ__ExpirationDate__c = date.today();
                qt.SBQQ__Status__c = 'Accepted';
        		qt.CWS_Sub_Stage__c = 'Accepted';
                qtList.add(qt);
            }
            if(!qtList.isEmpty()){
                update qtList;
            }
        }
        
        sbaa__ApprovalChain__c appchain = new sbaa__ApprovalChain__c();
        appchain.Name =  CWS_ConstantClass.QUOTE_ACC_RESTRICT_APPROVAL;
        appchain.sbaa__TargetObject__c = 'SBQQ__Quote__c';

        insert appchain;
        
		List<sbaa__Approval__c> approvalList = new List<sbaa__Approval__c>();
        sbaa__Approval__c approval = new sbaa__Approval__c();
        	approval.CWS_Quote__c = qtList[0].Id;
            approval.sbaa__Opportunity__c = opp[0].Id;
            approval.sbaa__Status__c = 'Requested';
        	approval.sbaa__ApprovalChain__c= appchain.Id;
        	approval.sbaa__ApprovalStep__c = 1;
            approval.sbaa__RecordField__c = 'CWS_Quote__c';
        approvalList.add(approval);
        
        sbaa__Approval__c approval1 = new sbaa__Approval__c();
        	approval1.CWS_Quote__c = qtList[0].Id;
            approval1.sbaa__Opportunity__c = opp[0].Id;
            approval1.sbaa__Status__c = 'Requested';
        	approval1.sbaa__ApprovalChain__c= appchain.Id;
        	approval1.sbaa__ApprovalStep__c = 1;
            approval1.sbaa__RecordField__c = 'CWS_Quote__c';
        approvalList.add(approval1);       
            Insert approvalList;
        
        List<sbaa__Approval__c> appvlsList = [SELECT id,sbaa__Status__c,sbaa__ApprovalChain__r.Name,CWS_Quote__c,CWS_Quote__r.SBQQ__Opportunity2__c,
                                                        CWS_Quote__r.SBQQ__Opportunity2__r.CWS_Rejected_Approval_Count__c,
                                                           CWS_Quote__r.Id from sbaa__Approval__c];
        system.debug('appvlsMap--'+appvlsList);
        if(appvlsList.size()==2){
            appvlsList[0].sbaa__Status__c = CWS_ConstantClass.QUOTE_Approval_Status_Approved;
            appvlsList[1].sbaa__Status__c = CWS_ConstantClass.QUOTE_Approval_Status_Approved;
            update appvlsList;
        }
    }
    
            @isTest static void UpdateApproval1(){
        List<Opportunity> opp = [SELECT ID,SBQQ__PrimaryQuote__c from opportunity ];
        List<SBQQ__Quote__c> quoteList = [SELECT ID,SBQQ__Status__c,CWS_Sub_Stage__c from SBQQ__Quote__c];
        List<SBQQ__Quote__c> qtList = new List<SBQQ__Quote__c>();
        system.debug('opp--'+opp);
        system.debug('quoteList--'+quoteList);
        if(!quoteList.isempty()){
            for(SBQQ__Quote__c qt: quoteList){
                qt.SBQQ__ExpirationDate__c = date.today();
                qt.SBQQ__Status__c = 'Accepted';
        		qt.CWS_Sub_Stage__c = 'Accepted';
                qtList.add(qt);
            }
            if(!qtList.isEmpty()){
                update qtList;
            }
        }
        
        sbaa__ApprovalChain__c appchain = new sbaa__ApprovalChain__c();
        appchain.Name =  CWS_ConstantClass.QUOTE_ACC_RESTRICT_APPROVAL;
        appchain.sbaa__TargetObject__c = 'SBQQ__Quote__c';

        insert appchain;
        
        sbaa__Approval__c approval = new sbaa__Approval__c();
        	approval.CWS_Quote__c = qtList[0].Id;
            //approval.sbaa__Opportunity__c = opp[0].Id;
            approval.sbaa__Status__c = 'Requested';
        	approval.sbaa__ApprovalChain__c= appchain.Id;
        	approval.sbaa__ApprovalStep__c = 1;
            approval.sbaa__RecordField__c = 'CWS_Quote__c';
            Insert approval;
        
        List<sbaa__Approval__c> appvlsList = [SELECT id,sbaa__Status__c,sbaa__ApprovalChain__r.Name,CWS_Quote__c,CWS_Quote__r.SBQQ__Opportunity2__c,
                                                        CWS_Quote__r.SBQQ__Opportunity2__r.CWS_Rejected_Approval_Count__c,
                                                           CWS_Quote__r.Id from sbaa__Approval__c];
        system.debug('appvlsMap--'+appvlsList);
        if(appvlsList.size()>0){
            appvlsList[0].sbaa__Status__c = CWS_ConstantClass.QUOTE_Approval_Status_Approved;
            update appvlsList[0];
        }
                CWS_ApprovalTriggerHandler triggHandler = new CWS_ApprovalTriggerHandler();
                triggHandler.BeforeInsert(new list<sobject>());
                triggHandler.BeforeUpdate(new Map<Id, SObject>(),new Map<Id, SObject>());
                triggHandler.BeforeDelete(new Map<Id, SObject>());
                triggHandler.AfterInsert(new Map<Id, SObject>());
				triggHandler.AfterDelete(new Map<Id, SObject>());
                triggHandler.AfterUndelete(new Map<Id, SObject>());
                triggHandler.IsDisabled();
    }
}