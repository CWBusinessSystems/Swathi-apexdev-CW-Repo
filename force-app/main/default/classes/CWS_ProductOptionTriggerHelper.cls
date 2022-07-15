/*Class Name: CWS_ProductOptionTriggerHelper
*Description: Helper Class for Product option Trigger
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
Asutosh                 25.5.2020       10641                   Product Sync Logic
*/

Public with Sharing class CWS_ProductOptionTriggerHelper{

   
    Public static void afterInsertHelper(Map<Id,SObject> newItems){
        System.debug('Inside  afterInsertHelper');
        Map<Id,SBQQ__ProductOption__c> newMap = (Map<Id,SBQQ__ProductOption__c>) newItems;
        Set<Id> productIds=new Set<Id>();
        List<Product2> productsToUpdate=new List<Product2>();
        for(SBQQ__ProductOption__c option: newMap.values()){
            productIds.add(option.SBQQ__ConfiguredSKU__c);
            productIds.add(option.SBQQ__OptionalSKU__c);
        }
        try{
      System.debug('productIds '+productIds);
        if(!productIds.isEmpty()){
            for(Product2 product: [Select Id, CWS_Zuora_Product_Sync_Status__c , CWS_NetSuite_Product_Sync_Status__c from product2 where
                                    id in : productIds and (CWS_Zuora_Product_Sync_Status__c='Synced' or CWS_NetSuite_Product_Sync_Status__c='Synced')]){
                 product.CWS_Zuora_Product_Sync_Status__c = CWS_ConstantClass.INT_STATUS_NOT_SYNCED;
                 product.CWS_NetSuite_Product_Sync_Status__c = CWS_ConstantClass.INT_STATUS_NOT_SYNCED;
                 productsToUpdate.add(product);                        
            }
        }
        System.debug('productsToUpdate '+productsToUpdate);
        if(!productsToUpdate.isEmpty()){
            List<Database.SaveResult> resultsList = Database.update(productsToUpdate, false);
            CWS_ExceptionHandler.logDMLSaveResults(resultsList, 'CWS_ProductOptionTriggerHelper' , 'afterInsert','Products', null , null );
        }
    }
    catch(Exception e){
        CWS_ExceptionHandler.logException( e,'Products' , 'CWS_ProductOptionTriggerHelper','afterInsert' , '', null, null , 'afterInsert' , null);
       }
    }
}