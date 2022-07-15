@isTest(SeeAllData=false)
public class CWS_ListPriceCalculation_Test {

     @testSetup static void createTestData(){

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        Pricebook2 ConnectwisePricebook = new Pricebook2(Name= CWS_ConstantClass.CONNECTWISE_PRICEBOOK, ISActive = true);
        if(ConnectwisePricebook!=null){
            insert ConnectwisePricebook;
        }
        

        Map<String,Object> additionalFields = new Map<String, Object>();
        Product2 prod = CWS_UTLDataFactory.createProduct('Dummy Product', 'TRDF', additionalFields, True);
        prod.CWS_Category__c = 'Automate';
        prod.CWS_EF_Attribute__c = 'Service';
        prod.IsActive = true;
        if(prod!=null){
           upsert prod;
        }
       

        List<String> currencyCode = new List<String>{'USD','CAD','EUR'};
        List<Pricebookentry> pbeList = CWS_UTLDataFactory.createPBEList(standardPricebook.ID, Prod.Id, 100 ,currencyCode);
        List<Pricebookentry> pbeList1 = CWS_UTLDataFactory.createPBEList(ConnectwisePricebook.ID, Prod.Id, 100 ,currencyCode);
        List<SBQQ__BlockPrice__c> bpe= CWS_UTLDataFactory.createBPList(Prod.Id, 100, currencyCode);
        pbeList.addAll(pbeList1);
        if(pbeList.size()>0){
        insert pbeList;
        }
        if(bpe.size()>0){
             insert bpe;
        }
       
        CWS_Economic_Factor__c ecofac = new CWS_Economic_Factor__c();
        ecofac.CWS_Category__c = 'Automate';
        ecofac.CWS_Product_Type__c = 'Service';
        ecofac.CWS_Economic_Factor__c = 1.2;
        ecofac.CurrencyISOCode = 'EUR';
        if(ecofac!=null){
          insert ecofac;
        }
        
		
        CWS_PBE_Validation_Deactivation__c pbeValidation = new CWS_PBE_Validation_Deactivation__c();
         pbeValidation.CWS_Deactivate__c = false;
         if(pbeValidation!=null){
          insert pbeValidation;
         }
         
     }

     @isTest static void testCase(){
           CurrencyType exchangeList = [Select ISOCode, ConversionRate from CurrencyType where ISOCode = 'EUR' limit 1];
           CWS_Economic_Factor__c ecofac = [Select Id, CWS_Economic_Factor__c from CWS_Economic_Factor__c limit 1];
           system.debug(exchangeList);

           Map<Id, Pricebookentry> pbeMap = new Map<Id, Pricebookentry>([SELECT ID from Pricebookentry]);
           List<Pricebookentry> listPbe = [Select Id, Pricebook2.Name, Product2.Id, Product2.CWS_Category__c, Product2.IsActive, Product2.CWS_EF_Attribute__c, CurrencyIsoCode, UnitPrice, CWS_CostPrice__c, CWS_Exception_Costprice__c, IsActive, CWS_Exception_Pricing__c from PricebookEntry where IsActive = True  and Product2.IsActive = True and Pricebook2.Name =:CWS_ConstantClass.CONNECTWISE_PRICEBOOK];

           Test.startTest();
           
                // CWS_ListPriceCalculationController cont = new CWS_ListPriceCalculationController();
                 List<CWS_Trigger_Batch_Job__c> tbj = new List<CWS_Trigger_Batch_Job__c>();
                 Test.setCurrentPage(page.CWS_PricebookEntryBatchJob);
                 ApexPages.StandardsetController sc = new ApexPages.StandardsetController(tbj);
                 sc.setSelected(tbj);
                 CWS_ListPriceCalculationController q = new CWS_ListPriceCalculationController(sc);
                 PageReference page = CWS_ListPriceCalculationController.invokeBatch();
                 PageReference rpage = CWS_ListPriceCalculationController.closeBatch();
                  CWS_ListPriceCalculationBatch cb = new CWS_ListPriceCalculationBatch();
         		  Database.QueryLocator ql = cb.start(null);
				  cb.execute(null,listPbe);
                  cb.Finish(null);	
                 Pricebookentry pbe = [Select Id, currencyISOCode, unitprice from Pricebookentry where Pricebook2.Name =:CWS_ConstantClass.CONNECTWISE_PRICEBOOK and CurrencyISOCode = 'EUR' limit 1];   
            System.assertequals(pbe.unitprice, 100*exchangeList.ConversionRate*ecofac.CWS_Economic_Factor__c);         
           Test.stopTest();
     }


}