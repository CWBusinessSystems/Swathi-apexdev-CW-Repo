/*Class Name: CWS_SubmitQuoteForApproval_Test
        *Description: Test Class for CWS_SubmitQuohhhteForApproval
        *Created By : Naresh Nunna
        *Created On: 7/30/2020
        *Modification Log
        *------------------------------------------------------------------------------------------
        *Developer              Date            User Story              Description
        *------------------------------------------------------------------------------------------
        *Naresh                7/30/2020       Initial vertion created
        *Indra Ganesan         8/28/2020       Code Modified & formatted
        */
        @isTest(SeeAllData=false)
        public class CWS_SubmitQuoteForApproval_Test {
            public static Profile objSaleRepProfile = [SELECT Id FROM Profile WHERE Name = 'CWS_Sales_Rep'];
            
            // Test data setup 
            @testSetup static void createTestData(){
                //create custom setting data
                //CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Quote'});           
                
                //Create Sold TO Account
                Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
                    'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                    'currencyIsoCode'=>'EUR'};
                Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
                
                //Create Distributor Account
                Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
                    'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'), 'Type'=>'Distributor', 'CWS_Is_Distributor__c'=>true,
                    'currencyIsoCode'=>'EUR'};
                Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);        
                      
                // Create Distributr Reseller Records 
                CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', null, null, true);
                CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[1].Id, 'Distributor','Deal Reg', null, null, true);
                
                //Creating Contact for the Account
                Map<String, Object> mapConFieldValues = new Map<String, Object>{
                    'CWS_Primary_Billing_Contact__c' => true,
                    'CWS_Primary_Contact__c' => true,
                    'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                    'Email'=>'test@test.com'
                };
                Contact sCon = CWS_UTLDataFactory.createContact('TestFirstName','TestLastName', soldtoaccount.Id,mapConFieldValues,true);
                
                
                // Create Opportunity
                Map<String, Object> opportunityFields=new Map<String, Object>{
                    'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> distiAccounts[0].Id,
                    'Type'=>'New','CurrencyIsoCode'=>'USD','CWS_Min_Commit_QR__c'=> 20000
                };
                Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',soldtoaccount.Id,opportunityFields,true);
                        
                //Create Quote record
                Map<String, Object> quoteFields=new Map<String,Object>{
                  'SBQQ__Status__c'=>'Approved', 'SBQQ__Type__c'=>'New', 'SBQQ__Distributor__c'=>distiAccounts[0].Id, 'SBQQ__Account__c'=> soldToAccount.Id,
                 'CWS_Bill_to_Account__c'=> distiAccounts[0].Id, 'CWS_Route_to_Market__c'=>'Channel','CWS_Reseller_Account__c' => soldToAccount.Id,'CWS_Add_Terms_Manually__c' => 'Testing'
                };
                SBQQ__Quote__c quote=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields, true);

                Map<String, Object> quoteFields2=new Map<String,Object>{
                  'CWS_Bill_To_Contact__c' => sCon.id,   'CWS_Quote_Type__c' => 'Renewal with Change', 'CWS_Bill_to_Account__c'=> soldToAccount.Id, 'CWS_Master__c' => true, 'CWS_Vendor_Approval_Received__c' => false,
                    'CWS_Route_to_Market__c'=>'Direct', 'SBQQ__Type__c'=>'Renewal with Change','SBQQ__Status__c'=>'Approved',  'SBQQ__Primary__c'=>true, 'SBQQ__Account__c'=> soldToAccount.Id, 'CWS_Reseller_Account__c' => soldToAccount.Id,'CWS_Add_Terms_Manually__c' => 'Testing'
                };
                SBQQ__Quote__c quote2=CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opty.Id, quoteFields2, true);
                
                CWS_Economic_Factor__c ecofac = new CWS_Economic_Factor__c();
                ecofac.CWS_Category__c = 'Automate';
                ecofac.CWS_Product_Type__c = 'Service';
                ecofac.CWS_Economic_Factor__c = 1.2;
                ecofac.CurrencyISOCode = 'USD';
                if(ecofac!=null){
                  insert ecofac;
                }
               

                Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
                Pricebook2 ConnectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
                if(ConnectwisePricebook!=null){
                    insert ConnectwisePricebook;
                }
                List<Product2> productList=new List<Product2>();
                Map<String,Object> additionalFields1 = new Map<String, Object>{'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c'=>12  ,'SBQQ__SubscriptionType__c' =>'Renewable', 'SBQQ__SubscriptionBase__c'=>'List', 
                    'CWS_ChargeType__c'=>CWS_ConstantClass.ChargeType_Recurring,
                    'CWS_Charge_Model__c' => 'Per Unit Pricing','CWS_License_Type__c' => 'SaaS','CWS_Route_to_Market__c' => 'Direct',
                    'CWS_SKU_Type__c' => 'Package','CWS_UOM__c' => 'Each','CWS_Sub_Category__c' => 'License','CWS_Currencies__c' => 'USD;CAD;AUD;EUR;GBP',
                    'CWS_Status__c' => 'Active','CWS_Status_Type__c' => 'Active','CWS_Billing_Term__c' => 'Monthly','CWS_Product_Family__c' => 'BDR',
                    'CW_Product_Type__c' => 'Charge','CWS_Item_Revenue_Category__c' => 'SaaS-Billing',
                    'CWS_Renewal_Type__c' => 'Opt-out','CWS_Product_Line__c' => 'None', 'CWS_Base_SKU__c' =>  '900901',
                    'CWS_Manage_Special_Product__c' => true,'CWS_Sub_Category__c' =>CWS_ConstantClass.strThirdParty1,'CWS_Manage_Product__c'=> true
                };
                
                
                Product2 prod1 = CWS_UTLDataFactory.createProduct('TestProductRecurring', 'RecurringProduct', additionalFields1, false);
                
                Map<String,Object> additionalFields2 = new Map<String, Object>{'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>    12,'SBQQ__SubscriptionType__c' =>'Renewable', 'SBQQ__SubscriptionBase__c'=>'List', 'CWS_ChargeType__c'=>CWS_ConstantClass.ChargeType_OneTime,
                    'CWS_Charge_Model__c' => 'Per Unit Pricing','CWS_License_Type__c' => 'SaaS','CWS_Route_to_Market__c' => 'Direct',
                    'CWS_SKU_Type__c' => 'Package','CWS_UOM__c' => 'Each','CWS_Sub_Category__c' => 'License','CWS_Currencies__c' => 'USD;CAD;AUD;EUR;GBP',
                    'CWS_Status__c' => 'Active','CWS_Status_Type__c' => 'Active','CWS_Billing_Term__c' => 'Monthly','CWS_Product_Family__c' => 'BDR',
                    'CW_Product_Type__c' => 'Charge','CWS_ProductCode__c' => 'SEL-LIC-SAASSELSTAR','CWS_Item_Revenue_Category__c' => 'SaaS-Billing',
                    'CWS_Renewal_Type__c' => 'Opt-out','CWS_Product_Line__c' => 'None', 'CWS_Base_SKU__c' =>  '900904',
                    'CWS_Manage_Special_Product__c' => true,'SBQQ__PricingMethod__c'=>CWS_ConstantClass.PRICINGMETHOD_BLOCK,'CWS_Sub_Category__c' =>CWS_ConstantClass.strThirdParty1
                };
                Product2 prod2 = CWS_UTLDataFactory.createProduct('TestProductOneTime', 'OneTimeProduct', additionalFields2, false);
                
              /* Map<String,Object> additionalFields3 = new Map<String, Object>{'CWS_Category__c'=>'Automate', 'SBQQ__SubscriptionPricing__c'=>'Fixed Price', 'SBQQ__SubscriptionTerm__c'=>    1,'SBQQ__SubscriptionType__c' =>CWS_ConstantClass.Subscription_Type_Evergreen, 'SBQQ__SubscriptionBase__c'=>'List', 'CWS_ChargeType__c'=>CWS_ConstantClass.ChargeType_OneTime,
                    'CWS_Charge_Model__c' => 'Per Unit Pricing','CWS_License_Type__c' => 'SaaS','CWS_Route_to_Market__c' => 'Direct',
                    'CWS_SKU_Type__c' => 'Package','CWS_UOM__c' => 'Each','CWS_Sub_Category__c' => 'License','CWS_Currencies__c' => 'USD;CAD;AUD;EUR;GBP',
                    'CWS_Status__c' => 'Active','CWS_Status_Type__c' => 'Active','CWS_Billing_Term__c' => 'Monthly','CWS_Product_Family__c' => 'BDR',
                    'CW_Product_Type__c' => 'Charge','CWS_Item_Revenue_Category__c' => 'SaaS-Billing',
                    'CWS_Renewal_Type__c' => 'Opt-out','CWS_Product_Line__c' => 'None', 'CWS_Base_SKU__c' =>  '900904',
                    'CWS_Manage_Special_Product__c' => true,'SBQQ__PricingMethod__c'=>CWS_ConstantClass.PRICINGMETHOD_BLOCK
                };
                Product2 prod3 = CWS_UTLDataFactory.createProduct('TestProductOneTime', 'OneTimeProduct', additionalFields3, false);*/
                
                productList.add(prod1);
                productList.add(prod2);
              //  productList.add(prod3);
                insert productList;
                
                // Insert Standard PricebookEntries.
                List<PriceBookEntry> pbeListStd=new List<PricebookEntry>();
                for(product2 product:productList){
                    Pricebookentry pbe2=CWS_UTLDataFactory.createPBEwithPricebookId(Test.getStandardPricebookId(), product.Id, 1000,'USD', false); 
                    pbeListStd.add(pbe2);
                }
                upsert pbeListStd;

                // Insert PricebookEntries.
                List<PriceBookEntry> pbeList=new List<PricebookEntry>();
                for(product2 product:productList){
                    Pricebookentry pbe=CWS_UTLDataFactory.createPBEwithPricebookId(ConnectwisePricebook.Id, product.Id, 1000,'USD', false);          
                    pbeList.add(pbe);
                }
                upsert pbeList;                
                SBQQ__BlockPrice__c blkPrice = new SBQQ__BlockPrice__c(Name = 'Tst Block Price', SBQQ__Product__c=prod1.id, SBQQ__Price__c = 546);
                insert blkprice;
                List<SBQQ__QuoteLine__c> nquoteLine = CWS_UTLDataFactory.createQuoteLines(1 , quote.Id, prod1.Id);
                List<SBQQ__QuoteLine__c> qLineOneTime = CWS_UTLDataFactory.createQuoteLines(1 , quote2.Id, prod2.Id);
                List<SBQQ__QuoteLine__c> lstQL = new List<SBQQ__QuoteLine__c>();
                lstQL.add(nquoteLine[0]);
                lstQL.add(qLineOneTime[0]);

                if(lstQL != null)
                    Insert lstQL;
                
                //Create Contract
                Map<String, Object> contractFieldsDefaultValues = new Map<String, Object>{
                    'StartDate' => date.today() - 1,
                    'ContractTerm' => 12,
                    'status' => 'Draft'};
                Contract Cntr = CWS_UTLDataFactory.createContract(soldtoaccount.Id,contractFieldsDefaultValues, true);       
                
                SBQQ__Subscription__c Subs1 = new SBQQ__Subscription__c();      
                Subs1.SBQQ__Contract__c = Cntr.id;
                Subs1.SBQQ__Account__c = soldtoaccount.Id;
                Subs1.SBQQ__Product__c = prod1.id;
                Subs1.SBQQ__QuoteLine__c = nquoteLine[0].id;            
                Subs1.SBQQ__Quantity__c = 1;
                insert Subs1;      
            }
              
           testMethod static void SubmitQuoteApproval(){
                Test.startTest();
                list<SBQQ__Quote__c> lstQt=[select id from SBQQ__Quote__c limit 1];
                list<SBQQ__QuoteLine__c> lstQtLn=[select id,SBQQ__Quote__c,CWS_Renewal_Type__c from SBQQ__QuoteLine__c where SBQQ__Quote__c != null limit 1];
                lstQtLn[0].CWS_Renewal_Type__c = 'Opt-out';
                lstQtLn[0].CWS_Billing_Term__c = 'Monthly';
                update lstQtLn;
                CWS_SubmitQuoteForApproval.submitForApproval(lstQtLn[0].SBQQ__Quote__c);
                Test.StopTest();
            }  
             testMethod static void SubmitQuoteApproval2(){
                Test.startTest();
                list<SBQQ__Quote__c> lstQt=[select id from SBQQ__Quote__c];
                list<SBQQ__QuoteLine__c> lstQtLn=[select id,SBQQ__Quote__c,CWS_Renewal_Type__c from SBQQ__QuoteLine__c where SBQQ__Quote__c != null limit 1];
               // lstQtLn[0].CWS_Renewal_Type__c = 'Opt-out';
                lstQtLn[0].CWS_Billing_Term__c = 'One-Time';
                update lstQtLn;
                CWS_SubmitQuoteForApproval.submitForApproval(lstQtLn[0].SBQQ__Quote__c);
                Test.StopTest();
            }  
                
            testMethod static void RecallApproval(){
                Test.startTest();
                list<SBQQ__Quote__c> lstQt=[select id from SBQQ__Quote__c limit 1];
                CWS_SubmitQuoteForApproval.recallApproval(lstQt[0].id);
                Test.StopTest();
            }      

            testMethod static void QuoteStages(){
                Test.startTest();
                List<String> nStages = CWS_SubmitQuoteForApproval.getQuoteStages();
                Test.StopTest();
            } 
                
            testMethod static void ValidateQuote(){
                Test.startTest();
                list<SBQQ__Quote__c> lstQt=[select id,SBQQ__Opportunity2__c,CWS_Quote_Type__c from SBQQ__Quote__c where CWS_Quote_Type__c =: CWS_ConstantClass.QUOTE_TYPE_RENEWALWC limit 1];
                lstQt[0].CWS_Quote_Type__c = 'New Business';
                update lstQt;       
                Opportunity opp = [SELECT id, SBQQ__PrimaryQuote__c FROM Opportunity where id=: lstQt[0].SBQQ__Opportunity2__c];
                opp.SBQQ__PrimaryQuote__c = lstQt[0].id;
                update opp;
                list<SBQQ__Subscription__c> sub=[select id,SBQQ__Quantity__c from SBQQ__Subscription__c limit 1];       
                list<SBQQ__QuoteLine__c> lstQtLn=[select id,SBQQ__Quote__c,CWS_Subscription_Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c != null limit 1];
                lstQtLn[0].CWS_Renewal_Type__c = 'Opt-out';
                lstQtLn[0].CWS_Billing_Term__c = 'Monthly';
                lstQtLn[0].CWS_Manage_Special_Product__c = true ;
                lstQtLn[0].SBQQ__Existing__c = true;
                lstQtLn[0].SBQQ__UpgradedSubscription__c = sub[0].id;
                lstQtLn[0].SBQQ__Quantity__c = sub[0].SBQQ__Quantity__c;
                lstQtLn[0].CWS_Original_Cost_Price__c = 200;
                lstQtLn[0].CWS_Cost_Price__c = 300;     
                //lstQtLn[0].SBQQ__ProductCode__c = CWS_ConstantClass.SellBasic_ProductCode;
                update lstQtLn; 
                CWS_SubmitQuoteForApproval.validateQuoteOnSubmittingForApproval(lstQtLn[0].SBQQ__Quote__c);
                Test.StopTest();
            } 
           
           
            testMethod static void ValidateQuoteCancel(){
                Test.startTest();
                list<SBQQ__Quote__c> lstQt=[select id,SBQQ__Opportunity2__c,CWS_Quote_Type__c from SBQQ__Quote__c where CWS_Quote_Type__c =: CWS_ConstantClass.QUOTE_TYPE_RENEWALWC limit 1];
                system.debug('++CWS_Quote_Type__c in test'+lstQt[0].CWS_Quote_Type__c);
                Opportunity opp = [SELECT id, SBQQ__PrimaryQuote__c FROM Opportunity where id=: lstQt[0].SBQQ__Opportunity2__c];
                opp.SBQQ__PrimaryQuote__c = lstQt[0].id;
                update opp;
                list<SBQQ__Subscription__c> sub=[select id,SBQQ__Quantity__c from SBQQ__Subscription__c limit 1];       
                list<SBQQ__QuoteLine__c> lstQtLn=[select id,CWS_Manage_Product__c,CWS_Transaction_Type__c ,SBQQ__Quote__c,CWS_Subscription_Quantity__c,CWS_Cost_Price__c,CWS_Original_Cost_Price__c,SBQQ__PricingMethod__c,SBQQ__BlockPrice__c from SBQQ__QuoteLine__c where SBQQ__Quote__c != null AND SBQQ__Quote__c =: lstQt[0].id limit 1];
                Product2 p = [select id,CWS_Sub_Category__c from Product2 limit 1];
                p.CWS_Sub_Category__c =CWS_ConstantClass.strThirdParty1;
                update p;
                lstQtLn[0].CWS_Transaction_Type__c = CWS_ConstantClass.TRANSACTION_TYPE_CANCEL;
                lstQtLn[0].CWS_Manage_Special_Product__c= true;
                lstQtLn[0].CWS_Manage_Product__c=true;
                lstQtLn[0].CWS_Cost_Price__c = 900;
                lstQtLn[0].CWS_Original_Cost_Price__c= 1000;
                 lstQtLn[0].SBQQ__Quantity__c = 3;
               // lstQtLn[0].CWS_Sub_category__c = CWS_ConstantClass.strThirdParty1;
                //lstQtLn[0].SBQQ__ProductCode__c = CWS_ConstantClass.SellBasic_ProductCode;
                update lstQtLn; 
                CWS_SubmitQuoteForApproval.validateQuoteOnSubmittingForApproval(lstQtLn[0].SBQQ__Quote__c);
                Test.StopTest();
            } 
            testMethod static void ValidateQuote2(){
                Test.startTest();
                list<SBQQ__Quote__c> lstQt=[select id,SBQQ__Type__c, CWS_Quote_Type__c,SBQQ__Opportunity2__c from SBQQ__Quote__c limit 1];
                lstQt[0].SBQQ__Type__c = 'Amendment';
                //lstQt[0].CWS_Quote_Type__c = 'Amendment';
                lstQt[0].SBQQ__SubscriptionTerm__c = 1;
                update lstQt;
                Opportunity opp = [SELECT id, SBQQ__PrimaryQuote__c FROM Opportunity where id=: lstQt[0].SBQQ__Opportunity2__c];
                opp.SBQQ__PrimaryQuote__c = lstQt[0].id;
                update opp;

                List<Pricebookentry> pbeList = [select id from Pricebookentry limit 1];
                system.debug('NNNNNNNNN testing  fdsfd   '+lstQt[0].CWS_Quote_Type__c);
                list<SBQQ__Subscription__c> sub=[select id,SBQQ__Quantity__c from SBQQ__Subscription__c limit 1];
                list<SBQQ__QuoteLine__c> lstQtLn=[select id,SBQQ__SubscriptionType__c,SBQQ__Quote__c,CWS_Subscription_Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c != null limit 1];
                lstQtLn[0].CWS_Renewal_Type__c = 'Opt-out';
                lstQtLn[0].CWS_SKU_Type__c = 'Package';
                lstQtLn[0].CWS_Billing_Term__c = 'Monthly';
                lstQtLn[0].SBQQ__PriorQuantity__c = 3 ;
                lstQtLn[0].CWS_Manage_Product__c = true;
                lstQtLn[0].SBQQ__Existing__c = true;
                lstQtLn[0].SBQQ__UpgradedSubscription__c = sub[0].id;
                lstQtLn[0].SBQQ__Quantity__c = sub[0].SBQQ__Quantity__c;
                lstQtLn[0].CWS_Original_Cost_Price__c = 200;
                lstQtLn[0].CWS_Cost_Price__c = 300;
                //lstQtLn[0].SBQQ__SubscriptionType__c=CWS_ConstantClass.Subscription_Type_Evergreen;
                lstQtLn[0].SBQQ__SubscriptionTerm__c=1;
                update lstQtLn;    
                CWS_SubmitQuoteForApproval.validateQuoteOnSubmittingForApproval(lstQtLn[0].SBQQ__Quote__c);
                Test.StopTest();
            } 
            
            testMethod static void SurveyCompleted(){
                Test.startTest();
                list<SBQQ__Quote__c> lstQt=[select id from SBQQ__Quote__c limit 1];
                list<SBQQ__QuoteLine__c> lstQtLn=[select id,SBQQ__Quote__c,CWS_Renewal_Type__c from SBQQ__QuoteLine__c where SBQQ__Quote__c != null limit 1];
                lstQtLn[0].CWS_Renewal_Type__c = 'Opt-out';
                lstQtLn[0].CWS_Billing_Term__c = 'Monthly';
                update lstQtLn;
                list<Opportunity> opp=[select id,SBQQ__PrimaryQuote__c from Opportunity limit 1];
                CWS_SubmitQuoteForApproval.isSurveyCompleted(opp[0].SBQQ__PrimaryQuote__c);
                Test.StopTest();
            } 
            
  @isTest
    Public static void testfieldsChk2(){
         CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
      insert bypassValidate;
        Product2 p = [SELECT id from Product2 limit 1];
       
       // Opportunity opp = [SELECT id,type,SBQQ__PrimaryQuote__c FROM Opportunity LIMIT 1];
        
        Account accs = CWS_UTLDataFactory.createAccount('My New Test Accounts01', new Map<String, Object>{'CWS_Is_Distributor__c'=> true}, true);
		accs.CWS_Distributor_Logic_Exclusion__c = true;
        update accs;
        
      /*  List<SBQQ__Quote__c> quoteObj=[select id,SBQQ__Ordered__c,CWS_isFastTrack__c,CWS_Renewal_CAP__c,CWS_Prior_Renewal_CAP__c,CWS_Quote_Type__c,CWS_Bill_To_Account__c,CWS_Bill_To_Contact__c,   CWS_Sub_Stage__c,CWS_Master__c,SBQQ__StartDate__c, SBQQ__EndDate__c,CWS_Addendum_Number__c,                                      
        CWS_Ship_To_Account__c,CWS_Ship_To_Contact__c,CWS_Renewal_Type__c,CWS_Quote_ACV__c,SBQQ__Account__c, CWS_Transaction_Reason__c, 
        SBQQ__PrimaryContact__c,SBQQ__PaymentTerms__c,CWS_Legal_Entity__c,SBQQ__Opportunity2__c,SBQQ__LineItemCount__c, 
        SBQQ__Primary__c,SBQQ__Status__c, CWS_Vendor_Approval_Received__c,
        CWS_OF_Signed_Override_Date__c, CWS_Master_Dedicated_Tech__c,SBQQ__PrimaryContact__r.CWS_Primary_Billing_Contact__c,SBQQ__PrimaryContact__r.CWS_Primary_Contact__c from SBQQ__Quote__c LIMIT 2];*/
      
      //  List<SBQQ__QuoteLine__c> quoteLine = [Select Id,CWS_Subscription_Quantity__c,SBQQ__PriorQuantity__c,SBQQ__Quantity__c,CWS_Manage_Special_Product__c,CWS_Manage_Product__c, CWS_Cost_Price__c, CWS_Original_Cost_Price__c from SBQQ__QuoteLine__c where SBQQ__Quote__c IN :quoteObj];
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id limit 1];
        Contact contactTst = [select id from contact limit 1];
        Test.StartTest();
        Contract con = new Contract(Account = accs, ContractTerm=12, Status='Draft',AccountId = accs.id);
        insert con;
        if(con!=null){
            con.Status = 'Activated';
            con.CWS_Renewal_Category__c = 'Opt-Out';
            con.CWS_Renewable_Products__c  = 1;
            update con;
        }
        system.debug('Contract id :'+ con.id);
       
        Opportunity opps = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty',accs.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>accs.id,'type'=> 'Amendment'}, true);       
        opps.SBQQ__AmendedContract__c = con.id;
        update opps;
        
        system.debug('Opps id :'+opps.id);
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Amendment_Read_Only' AND sObjectType = 'SBQQ__Quote__c'].Id;
        
        Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Master__c'=>false,'SBQQ__StartDate__c'=>Date.today(), 'SBQQ__EndDate__c'=>Date.today()+10, 'CWS_Route_to_Market__c'=>'Channel','RecordTypeId'=>recordTypeId,'SBQQ__Status__c'=>'Draft'
        }; 
       
       /* Map<String, Object> addFields = new Map<String,Object>{
            'CWS_Ship_To_Contact__c'=>contactTst.id,'CWS_Bill_To_Contact__c'=>contactTst.id,'CWS_Ship_To_Account__c'=>accs.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Route_to_Market__c'=>'Direct','RecordTypeId'=>recordTypeId 
        };*/
        SBQQ__Quote__c quotes = CWS_UTLDataFactory.createQuote(accs.id,opps.id,addFields,true);
         quotes.CWS_Quote_Type__c = 'Amendment';
         quotes.CWS_Sub_Type__c ='Credit';
         quotes.SBQQ__Type__c='Amendment';
         SYSTEM.debug([SELECT ID,CWS_Quote_Type__c from SBQQ__Quote__c where SBQQ__opportunity2__c =:opps.id]); 
        
       /* SBQQ__BlockPrice__c blkPrice = [select id, SBQQ__Price__c from SBQQ__BlockPrice__c limit 1];
         List<SBQQ__QuoteLine__c> tstQLs = CWS_UTLDataFactory.createQuoteLinesWithBlkPrice(1,quotes.id, p.Id, blkPrice.id,pbCW.id);
        tstQLs[0].CWS_Manage_Special_Product__c = true;
        tstQLs[0].CWS_Manage_Product__c = true;
         tstQLs[0].SBQQ__PricebookEntryId__c = pbCW.id;
        if(tstQLs[0].id != null){
            insert tstQLs[0];
        }*/
        
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(3, quotes.Id, p.Id);
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem2[0].CWS_Manage_Special_Product__c = true;
        quoteLineItem2[0].CWS_Manage_Product__c = true;
        quoteLineItem2[0].SBQQ__Quantity__c = 4;
        quoteLineItem2[0].CWS_Future_Contracted_Price__c = 602.74;
        quoteLineItem2[0].SBQQ__NetPrice__c = 12;
        quoteLineItem2[0].SBQQ__CustomerPrice__c = 12;
        quoteLineItem2[0].CWS_Future_Price_End_Date__c = System.today() + 10;
        
	    quoteLineItem2[1].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[1].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[1].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[1].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem2[1].CWS_Manage_Special_Product__c = true;
        quoteLineItem2[1].CWS_Manage_Product__c = true;
        quoteLineItem2[1].SBQQ__Quantity__c = 4;
        //quoteLineItem2[1].SBQQ__Existing__c = true; 
        quoteLineItem2[1].SBQQ__NetPrice__c = 12;
        quoteLineItem2[1].SBQQ__CustomerPrice__c = 12;
        quoteLineItem2[1].CWS_Future_Contracted_Price__c = 602.74;
        
         quoteLineItem2[2].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[2].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[2].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[2].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem2[2].CWS_Manage_Special_Product__c = true;
        quoteLineItem2[2].CWS_Manage_Product__c = true;
        quoteLineItem2[2].SBQQ__Quantity__c = 4;
        quoteLineItem2[2].CWS_Future_Contracted_Price__c = 100;
        quoteLineItem2[2].SBQQ__NetPrice__c = 12;
        quoteLineItem2[2].SBQQ__CustomerPrice__c = 12;
        quoteLineItem2[2].CWS_Future_Price_End_Date__c = System.today() + 10;
       
      
        if(quoteLineItem2!=null){
        insert quoteLineItem2;
        }
        
        List<SBQQ__QuoteLine__c> ql = [SELECT ID, CWS_Quote_Doc_Price__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quotes.Id];
        
            ql[1].CWS_Future_Priced_Line__c = ql[0].Id;
            update ql;
        System.debug('NEtprice = ' + ql[0].CWS_Quote_Doc_Price__c);
        System.debug('NEtprice = ' + ql[1].CWS_Quote_Doc_Price__c);
        quotes.SBQQ__Primary__c=true;
        quotes.SBQQ__Status__c='Accepted';
        quotes.SBQQ__ExpirationDate__c = System.today()+10;
        update quotes;
        
       
         CWS_SubmitQuoteForApproval.futurePriceCalculation(quotes.id, true);
         ApexPages.StandardController sc = new ApexPages.StandardController(quotes);
        CWS_QuotePreviewController testAccPlan = new CWS_QuotePreviewController(sc);
      	testAccPlan.approvals = new list<SBAA__Approval__c>(); 
        testAccPlan.onPreview();
        
        Test.StopTest();        
    }   
    
   @isTest
    Public static void testfieldsChk(){
         CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
      insert bypassValidate;
        Product2 p = [SELECT id from Product2 limit 1];
       
       // Opportunity opp = [SELECT id,type,SBQQ__PrimaryQuote__c FROM Opportunity LIMIT 1];
        
        Account accs = CWS_UTLDataFactory.createAccount('My New Test Accounts01', new Map<String, Object>{'CWS_Is_Distributor__c'=> true}, true);
        
      /*  List<SBQQ__Quote__c> quoteObj=[select id,SBQQ__Ordered__c,CWS_isFastTrack__c,CWS_Renewal_CAP__c,CWS_Prior_Renewal_CAP__c,CWS_Quote_Type__c,CWS_Bill_To_Account__c,CWS_Bill_To_Contact__c,   CWS_Sub_Stage__c,CWS_Master__c,SBQQ__StartDate__c, SBQQ__EndDate__c,CWS_Addendum_Number__c,                                      
        CWS_Ship_To_Account__c,CWS_Ship_To_Contact__c,CWS_Renewal_Type__c,CWS_Quote_ACV__c,SBQQ__Account__c, CWS_Transaction_Reason__c, 
        SBQQ__PrimaryContact__c,SBQQ__PaymentTerms__c,CWS_Legal_Entity__c,SBQQ__Opportunity2__c,SBQQ__LineItemCount__c, 
        SBQQ__Primary__c,SBQQ__Status__c, CWS_Vendor_Approval_Received__c,
        CWS_OF_Signed_Override_Date__c, CWS_Master_Dedicated_Tech__c,SBQQ__PrimaryContact__r.CWS_Primary_Billing_Contact__c,SBQQ__PrimaryContact__r.CWS_Primary_Contact__c from SBQQ__Quote__c LIMIT 2];*/
      
      //  List<SBQQ__QuoteLine__c> quoteLine = [Select Id,CWS_Subscription_Quantity__c,SBQQ__PriorQuantity__c,SBQQ__Quantity__c,CWS_Manage_Special_Product__c,CWS_Manage_Product__c, CWS_Cost_Price__c, CWS_Original_Cost_Price__c from SBQQ__QuoteLine__c where SBQQ__Quote__c IN :quoteObj];
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id limit 1];
        Contact contactTst = [select id from contact limit 1];
        Test.StartTest();
        Contract con = new Contract(Account = accs, ContractTerm=12, Status='Draft',AccountId = accs.id);
        insert con;
        if(con!=null){
            con.Status = 'Activated';
            con.CWS_Renewal_Category__c = 'Opt-Out';
            con.CWS_Renewable_Products__c  = 1;
            update con;
        }
        system.debug('Contract id :'+ con.id);
       
        Opportunity opps = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty',accs.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>accs.id,'type'=> 'Amendment'}, true);       
        opps.SBQQ__AmendedContract__c = con.id;
        update opps;
        
        system.debug('Opps id :'+opps.id);
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Amendment_Read_Only' AND sObjectType = 'SBQQ__Quote__c'].Id;
        
        Map<String, Object> addFields = new Map<String,Object>{
            'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.today(), 'SBQQ__EndDate__c'=>Date.today()+10, 'CWS_Route_to_Market__c'=>'Direct','RecordTypeId'=>recordTypeId,'SBQQ__Status__c'=>'Draft'
        }; 
       
       /* Map<String, Object> addFields = new Map<String,Object>{
            'CWS_Ship_To_Contact__c'=>contactTst.id,'CWS_Bill_To_Contact__c'=>contactTst.id,'CWS_Ship_To_Account__c'=>accs.id,'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Route_to_Market__c'=>'Direct','RecordTypeId'=>recordTypeId 
        };*/
        SBQQ__Quote__c quotes = CWS_UTLDataFactory.createQuote(accs.id,opps.id,addFields,true);
         quotes.CWS_Quote_Type__c = 'Amendment';
         quotes.CWS_Sub_Type__c ='Credit';
         quotes.SBQQ__Type__c='Amendment';
         SYSTEM.debug([SELECT ID,CWS_Quote_Type__c from SBQQ__Quote__c where SBQQ__opportunity2__c =:opps.id]); 
        
       /* SBQQ__BlockPrice__c blkPrice = [select id, SBQQ__Price__c from SBQQ__BlockPrice__c limit 1];
         List<SBQQ__QuoteLine__c> tstQLs = CWS_UTLDataFactory.createQuoteLinesWithBlkPrice(1,quotes.id, p.Id, blkPrice.id,pbCW.id);
        tstQLs[0].CWS_Manage_Special_Product__c = true;
        tstQLs[0].CWS_Manage_Product__c = true;
         tstQLs[0].SBQQ__PricebookEntryId__c = pbCW.id;
        if(tstQLs[0].id != null){
            insert tstQLs[0];
        }*/
        
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(2, quotes.Id, p.Id);
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem2[0].CWS_Manage_Special_Product__c = true;
        quoteLineItem2[0].CWS_Manage_Product__c = true;
        quoteLineItem2[0].SBQQ__Quantity__c = 4;
        quoteLineItem2[0].CWS_Future_Contracted_Price__c = 602.74;
        quoteLineItem2[0].SBQQ__NetPrice__c = 12;
        quoteLineItem2[0].SBQQ__CustomerPrice__c = 12;
        quoteLineItem2[0].CWS_Future_Price_End_Date__c = System.today()-1;
        
	    quoteLineItem2[1].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[1].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[1].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[1].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem2[1].CWS_Manage_Special_Product__c = true;
        quoteLineItem2[1].CWS_Manage_Product__c = true;
        quoteLineItem2[1].SBQQ__Quantity__c = 4;
        //quoteLineItem2[1].SBQQ__Existing__c = true; 
        quoteLineItem2[1].SBQQ__NetPrice__c = 12;
        quoteLineItem2[1].SBQQ__CustomerPrice__c = 12;
        quoteLineItem2[1].CWS_Future_Contracted_Price__c = 602.74;
      
        if(quoteLineItem2!=null){
        insert quoteLineItem2;
        }
        
        List<SBQQ__QuoteLine__c> ql = [SELECT ID, CWS_Quote_Doc_Price__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quotes.Id];
        
            ql[1].CWS_Future_Priced_Line__c = ql[0].Id;
            update ql;
        System.debug('NEtprice = ' + ql[0].CWS_Quote_Doc_Price__c);
        System.debug('NEtprice = ' + ql[1].CWS_Quote_Doc_Price__c);
        
        quotes.SBQQ__Status__c='Accepted';
        quotes.SBQQ__ExpirationDate__c = System.today()+10;
        update quotes;
        
        SYSTEM.debug([SELECT ID from SBQQ__QuoteLine__c where SBQQ__Quote__c=:quotes.id]);
        //quotes.SBQQ__Status__c = 'Draft'; 
        quotes.SBQQ__Primary__c=true;
        quotes.SBQQ__Ordered__c=true;
        update quotes;
        
        System.assert([SELECT ID from Order where SBQQ__Quote__c=:quotes.id].size()!=0,'No order is created');  
        SYSTEM.debug([SELECT ID,ORDERNumber,account.name from Order where SBQQ__Quote__c=:quotes.id]);       
 
        Order orderObjs = [select Id from Order where SBQQ__Quote__c=:quotes.Id];
        OrderItem oliObjs = [Select id,SBQQ__OrderedQuantity__c, Product2.CWS_Manage_Special_Product__c, Product2.CWS_Manage_Product__c  from OrderItem where OrderId =: orderObjs.id limit 1];
        CWS_SubmitQuoteForApproval.validateQuoteOnSubmittingForApproval(quotes.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(quotes);
        CWS_QuotePreviewController testAccPlan = new CWS_QuotePreviewController(sc);
      	testAccPlan.approvals = new list<SBAA__Approval__c>(); 
        testAccPlan.onPreview();
        
        Test.StopTest();        
    }         
    
      @isTest 
    Public static void  testCAUserCheckRenewalQT(){
       
        CWS_Bypass_Settings__c  bypassValidate = new CWS_Bypass_Settings__c  ();
        bypassValidate.CWS_Validation_Rules_Disabled__c = true;
        bypassValidate.CWS_Bypass_Objects__c  = 'Order;';
        insert bypassValidate;
        
       Test.Starttest();
        Account accs = CWS_UTLDataFactory.createAccount('ConnectWise012ACC', new Map<String, Object>{'CWS_Is_Distributor__c'=> true,'Industry'=>'MSP'}, true);
        Contact contact = CWS_UTLDataFactory.createContact('CName111', 'lName11', accs.id,new Map<String, Object> {}, true);
        Contract con = new Contract(Account = accs, ContractTerm=12, Status='Draft',AccountId = accs.id);
        insert con;
        if(con!=null){
            con.Status = 'Activated';
            con.CWS_Renewal_Category__c = 'Opt-Out';
            con.CWS_Renewable_Products__c  = 1;
            update con;
        }
        system.debug('Contract id :'+ con.id);
        Opportunity opps = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty667676',accs.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>accs.id,'type'=> 'Renewal with Change'}, true);  
        Product2 p = CWS_UTLDataFactory.createProduct('Test Product001','SKU002',new Map<String, Object>{'CWS_Manage_Special_Product__c'=>true,'CWS_Manage_Product__c'=>true}, true);
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id limit 1];        
        system.debug('Opps id :'+opps.id);
      //  Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Amendment_Read_Only' AND sObjectType = 'SBQQ__Quote__c'].Id;
        //'RecordTypeId'=>recordTypeId 
        Map<String, Object> addFields = new Map<String,Object>{
        }; 
            SBQQ__Quote__c quotes = [Select Id from SBQQ__Quote__c where CWS_Route_to_Market__c =: 'Direct' limit 1];
            quotes.CWS_Quote_Type__c ='Renewal with Change';
        	quotes.CWS_Vendor_Approval_Received__c= false;
        	quotes.SBQQ__PricebookId__c= pbCW.id;
        	quotes.CWS_Bill_To_Account__c=accs.id;
        	quotes.CWS_Master__c=true;
        	quotes.CWS_Bill_To_Contact__c = contact.Id;
            quotes.SBQQ__StartDate__c= Date.today();
        	quotes.SBQQ__EndDate__c= Date.today()+10;
        	update quotes;
        
         //quotes.CWS_Sub_Type__c ='Credit';
        // update quotes;
        // quotes.SBQQ__Type__c='Amendment';
        
        
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(1, quotes.Id, p.Id);
        quoteLineItem2[0].CWS_SKU_Type__c= 'Dedicated Tech';
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;
        quoteLineItem2[0].CWS_Manage_Special_Product__c = true;
        quoteLineItem2[0].CWS_Manage_Product__c = true;
        quoteLineItem2[0].SBQQ__Quantity__c = 1;
        quoteLineItem2[0].CWS_NetTotal__c = 3439;
        
        if(quoteLineItem2!=null){
            insert quoteLineItem2;
        } 
        
        quotes.SBQQ__Status__c = 'Accepted'; 
        update quotes;
        
        List<SBQQ__Subscription__c> sub = CWS_UTLDataFactory.createSubscriptionsfromQuoteLine(accs.id,con.Id,quotes.Id, true);
         sub[0].SBQQ__Quantity__c=1;
         update sub[0];
        quoteLineItem2[0].SBQQ__UpgradedSubscription__c = sub[0].id;
        update quoteLineItem2[0];
        //quotes.SBQQ__Status__c = 'Approved'; 
        quotes.SBQQ__Primary__c=true;
        quotes.SBQQ__Ordered__c=true;
        quotes.CWS_Master__c = true;
        update quotes;
            

        Order orderObjs = [select Id from Order where SBQQ__Quote__c=:quotes.Id];
        OrderItem oliObjs = [Select id,SBQQ__OrderedQuantity__c, Product2.CWS_Manage_Special_Product__c, Product2.CWS_Manage_Product__c  from OrderItem where OrderId =: orderObjs.id limit 1];
        oliObjs.SBQQ__OrderedQuantity__c=1;
        oliObjs.Product2.CWS_Manage_Special_Product__c = true;
        oliObjs.Product2.CWS_Manage_Product__c = true;       
        update oliObjs;
        
       // SBQQ__Quote__c errQuote = new SBQQ__Quote__c (CurrencyIsoCode='USD');
       // insert errQuote; 
        List<String> getErr = new List<String>();
        CWS_SubmitQuoteForApproval.validateQuoteOnSubmittingForApproval(quotes.id);
        Test.StopTest(); 
    }   
       @isTest
    Public static void testfieldsChk03(){
        Account accs = CWS_UTLDataFactory.createAccount('My New Test Accounts02', new Map<String, Object>{'CWS_Is_Distributor__c'=> true}, true);
        
        Product2 p = [SELECT id,CWS_Base_SKU__c,CWS_SKU_Type__c from Product2 limit 1];
        p.CWS_Base_SKU__c = CWS_ConstantClass.MINCOM_BASESKU_900901;
        p.CWS_SKU_Type__c = 'Help Desk';
        update p;
        
        Pricebook2 pbCW = [select id from  Pricebook2 where name =: 'ConnectWise Standard PriceBook'];
        
        PricebookEntry pbe = [SELECT id from PricebookEntry where pricebook2Id=:pbCW.id limit 1];
             
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
                    'CWS_Primary_Billing_Contact__c' => false,
                    'CWS_Primary_Contact__c' => true,
                    'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
                    'Email'=>'test@test1.com'
                };
        Contact contactTst = CWS_UTLDataFactory.createContact('TestFirstName','TestLastName', accs.Id,mapConFieldValues,true);
        /*Contact contactTst = [select id,AccountId,CWS_Primary_Billing_Contact__c,CWS_Primary_Contact__c from contact limit 1];
        contactTst.CWS_Primary_Billing_Contact__c = false;
        //contactTst.CWS_Primary_Contact__c = false;
        update contactTst;*/
        
        
        Opportunity opps = CWS_UTLDataFactory.createOpportunity('ConnectWise Test Oppty03',accs.id, new Map<String, Object>{'CloseDate'=>System.today()+7,'CWS_Bill_To_Account__c'=>accs.id,'type'=> 'New Business'}, true);      
        
        Map<String, Object> addFields = new Map<String,Object>{
         'SBQQ__Account__c' => accs.id, 'SBQQ__PrimaryContact__c'=>contactTst.id,'CWS_Bill_To_Contact__c'=>contactTst.Id, 'CWS_Quote_Type__c' =>'New Business', 'SBQQ__PricebookId__c'=>pbCW.id,'CWS_Bill_To_Account__c'=>accs.id, 'CWS_Master__c'=>true,'SBQQ__StartDate__c'=>Date.today(), 'SBQQ__EndDate__c'=>Date.today()+10, 'CWS_Route_to_Market__c'=>'Direct','CWS_Region__c'=>'NA'
        }; 
        Test.StartTest();    
        SBQQ__Quote__c quoteObj = CWS_UTLDataFactory.createQuote(accs.id,opps.id,addFields,true);
       
        SBQQ__BlockPrice__c blkPrice = new SBQQ__BlockPrice__c(Name = 'Tst Block Price', SBQQ__Product__c=p.id, SBQQ__Price__c = 546);
        insert blkprice;  
              
        SYSTEM.debug([SELECT ID,CWS_Quote_Type__c from SBQQ__Quote__c where SBQQ__opportunity2__c =:opps.id]); 
        
        List<SBQQ__QuoteLine__c> quoteLineItem2 = CWS_UTLDataFactory.createQuoteLines(1, quoteObj.Id, p.Id);
        quoteLineItem2[0].SBQQ__PricebookEntryId__c = pbe.id;
        quoteLineItem2[0].SBQQ__StartDate__c=Date.today();
        quoteLineItem2[0].SBQQ__SubscriptionPricing__c='Fixed Price';
        quoteLineItem2[0].SBQQ__SubscriptionTerm__c=12;        
        quoteLineItem2[0].SBQQ__Quantity__c = 4;
        quoteLineItem2[0].CWS_Renewal_Type__c = 'Opt-out';
        quoteLineItem2[0].CWS_Transaction_Type__c ='Cancel' ;
         quoteLineItem2[0].SBQQ__ListPrice__c = 9000;
         quoteLineItem2[0].SBQQ__PricingMethod__c=CWS_ConstantClass.PRICINGMETHOD_BLOCK;
        if(quoteLineItem2!=null){
        insert quoteLineItem2;
        } 
        
                     
        CWS_SubmitQuoteForApproval.validateQuoteOnSubmittingForApproval(quoteObj.id);
        Test.StopTest();
        
    }
 }