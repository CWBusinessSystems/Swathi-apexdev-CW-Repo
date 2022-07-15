/*Class Name: CWS_ProductSyncPBEBatch
*Description: Batch Class to mark Products Not Synced if price changes
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
Asutosh                 25.5.2020       10641                   Product Sync Logic
*/

global class CWS_ProductSyncPBEBatch implements Database.Batchable<SObject>  
{
    //Default Constructor
    global CWS_ProductSyncPBEBatch(){  
            
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        String strQuery;
        strQuery = 'Select Id, CWS_Price_Modified__c,Pricebook2.Name, Product2.Id,  Product2.IsActive,  CurrencyIsoCode, UnitPrice, CWS_CostPrice__c, IsActive from PricebookEntry where IsActive = True  and Product2.IsActive = True and CWS_Price_Modified__c= True and Pricebook2.Name = \'' + System.Label.CWS_ConnectwisePricebook + '\'';
        return Database.getQueryLocator(strQuery);
        

   }

   global void execute(Database.BatchableContext bc, List<PriceBookEntry> scope)
   {
        Set<Id> setproductIds = new Set<Id>();
        //List<SBQQ__ProductOption__c> lstproductOptions = new List<SBQQ__ProductOption__c>();
        Map<Id,Product2> productMap;
        List<Id> listproductIds = new List<Id>();
        //List<PriceBookEntry> pbes = new List<PriceBookEntry>();
        List<PriceBookEntry> pbeToUpdates = new List<PriceBookEntry>();
        List<Product2> lstproductsToUpdate = new List<Product2>();
        Map<Id, List<Id>> pbeMap = new Map<Id, List<Id>>();
        //Map<Id, Id> pbeMap2 = new Map<Id, Id>();
        List<Id> pbeIds;
        List<Id> FinalPbeIds = new List<Id>();
        List<SBQQ__ProductOption__c> prodOption = new List<SBQQ__ProductOption__c>();
        System.debug('Entering Batch ');
        for(PriceBookEntry pbe:scope){
            setproductIds.add(pbe.Product2.Id);
            if(pbeMap.containsKey(pbe.Product2.Id))
            {
                List<Id> tempId = pbeMap.get(pbe.Product2.Id);
                tempId.add(pbe.Id);
                pbeMap.put(pbe.Product2.Id,tempId);

            }
            else 
            {
				pbeIds = new List<Id>();
                pbeIds.add(pbe.Id);
                pbeMap.put(pbe.Product2.Id,pbeIds);
            }
             
            //pbeMap2.put(pbe.Product2.Id+pbe.Id,);
        }
        System.debug('setproductIds '+setproductIds);
        System.debug('pbeMap '+pbeMap);
        try {
    
        if(setproductIds.size()>0)
        {   
            prodOption = [Select Id, SBQQ__ConfiguredSKU__c from SBQQ__ProductOption__c where SBQQ__OptionalSKU__c =:setproductIds and SBQQ__OptionalSKU__r.IsActive = True and SBQQ__ConfiguredSKU__r.IsActive = True];
            for(SBQQ__ProductOption__c po: prodOption){
                setproductIds.add(po.SBQQ__ConfiguredSKU__c);
            }
            
            productMap = new Map<Id,Product2>([Select Id from Product2 where isActive = True and Id =:setproductIds]);
            
                for(Product2 prodtoUpdate : productMap.values())
                    {
                        prodtoUpdate.CWS_Zuora_Product_Sync_Status__c = CWS_ConstantClass.INT_STATUS_NOT_SYNCED;
                        prodtoUpdate.CWS_NetSuite_Product_Sync_Status__c = CWS_ConstantClass.INT_STATUS_NOT_SYNCED ;
                        lstproductsToUpdate.add(prodtoUpdate);
                    }
                    System.debug('lstproductsToUpdate '+lstproductsToUpdate);
                    List<Database.SaveResult> resultsList;
                    if(lstproductsToUpdate.size()>0)
                    {
                        resultsList = Database.update(lstproductsToUpdate, false);
                        CWS_ExceptionHandler.logDMLSaveResults(resultsList, 'CWS_ProductSyncPBEBatch' , 'Batch','Products', null , null );
                    }
                    for (Database.SaveResult sr : resultsList) {
                    
                        if (sr.isSuccess()) 
                        {
                            if(pbeMap.containsKey(sr.getId()))
                            {
                                List<id> tempPbe = pbeMap.get(sr.getId());
                                FinalPbeIds.addAll(tempPbe);
                            }
                           
                        }
                    } 
               // pbes = [select id from PriceBookEntry where Pricebook2.Name = :System.Label.CWS_ConnectwisePricebook and Product2.id in :listproductIds];
               System.debug('FinalPbeIds '+FinalPbeIds);
            for(Id pbeId :FinalPbeIds)
            {
                PriceBookEntry pbe = new PriceBookEntry(id=pbeId,CWS_Price_Modified__c=false);
                //pbe.CWS_Price_Modified__c = pbe.CWS_Price_Modified__c = true ? false :pbe.CWS_Price_Modified__c;
                pbeToUpdates.add(pbe);

            }
            System.debug('pbeToUpdates '+pbeToUpdates);   
                if(pbeToUpdates.size()>0)
                {
                    List<Database.SaveResult> resultsList1 = Database.update(pbeToUpdates, false);
                    CWS_ExceptionHandler.logDMLSaveResults(resultsList1, 'CWS_ProductSyncPBEBatch' , 'Batch','PriceBookEntry', null , null );
                }  
                        
        }
    }
    catch(Exception e){
        CWS_ExceptionHandler.logException( e,'BatchClass' , 'CWS_ProductSyncPBEBatch' , 'Execute' ,'', null , null ,'update' , null);
        }
    }
    

    global void finish(Database.BatchableContext bc)
    {

    }

}