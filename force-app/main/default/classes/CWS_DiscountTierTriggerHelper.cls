/*Class Name: CWS_QuoteTriggerHandler
*Description: Handler Class for Quote Trigger
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
Asutosh                 25.5.2020       10641                   Product Sync Logic
*/

public class CWS_DiscountTierTriggerHelper 
{
	public static void afterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems)
    {
        Map<Id,SBQQ__DiscountTier__c> newMap = (Map<Id,SBQQ__DiscountTier__c>) newItems;
        Map<Id,SBQQ__DiscountTier__c> oldMap = (Map<Id,SBQQ__DiscountTier__c>) oldItems;
        Set<Id> setDiscountSchedule = new Set<Id>();
        Set<Id> setDiscountTiers = new Set<Id>();
        List<SBQQ__DiscountTier__c> lstDS = new List<SBQQ__DiscountTier__c>();
        //Set<SBQQ__DiscountSchedule__c> setDiscountSchedules = new Set<SBQQ__DiscountSchedule__c>();
        List<Product2> lstproducts = new List<Product2>();
        Set<Id> setproductIds = new Set<Id>();
        List<Id> listproductIds = new List<Id>();
        List<Product2> lstproductsToUpdate = new List<Product2>();
        List<Id> lstproductsSuccess = new List<Id>();
        Set<Id> setproductsToUpdate = new Set<Id>();
        List<SBQQ__ProductOption__c> lstproductOptions = new List<SBQQ__ProductOption__c>();
        Set<Product2> ProductIds = new Set<Product2>();
        //Map <Id,SBQQ__DiscountSchedule__c> mapDiscountSchedules = new Map <Id,SBQQ__DiscountSchedule__c>();
        system.debug('Entering afterUpdate');
       
       for(SBQQ__DiscountTier__c newtier : newMap.values())
       {
            SBQQ__DiscountTier__c oldtier = oldMap.get(newtier.id);
            if(oldtier.SBQQ__Discount__c!=newtier.SBQQ__Discount__c || oldtier.SBQQ__LowerBound__c!=newtier.SBQQ__LowerBound__c || oldtier.SBQQ__UpperBound__c!=newtier.SBQQ__UpperBound__c)
            {
                setDiscountSchedule.add(newtier.SBQQ__Schedule__c);
                system.debug('setDiscountSchedule '+setDiscountSchedule);
            }
       }
       try
       { 
           if(setDiscountSchedule.size()>0)
           {
               //lstproducts = [Select Id, CWS_Zuora_Product_Sync_Status__c , CWS_NetSuite_Product_Sync_Status__c from product2 where SBQQ__DiscountSchedule__c in :setDiscountSchedule and (CWS_Zuora_Product_Sync_Status__c='Synced' or CWS_NetSuite_Product_Sync_Status__c='Synced') ];
               Map<Id,Product2> mapProducts = new Map<Id,Product2>([Select Id, CWS_Zuora_Product_Sync_Status__c , CWS_NetSuite_Product_Sync_Status__c,SBQQ__DiscountSchedule__c from product2 where SBQQ__DiscountSchedule__c in :setDiscountSchedule and (CWS_Zuora_Product_Sync_Status__c='Synced' or CWS_NetSuite_Product_Sync_Status__c='Synced') ]);
               if(mapProducts.size()>0)
               {
                   setproductIds = mapProducts.keySet();
                   lstproducts = mapProducts.values();
               }   
               if(setproductIds.size()>0)
               {
                    system.debug('setproductIds '+setproductIds);
                   lstproductOptions = [Select Id, SBQQ__ConfiguredSKU__c,SBQQ__OptionalSKU__c,SBQQ__ConfiguredSKU__r.SBQQ__DiscountSchedule__c, SBQQ__OptionalSKU__r.SBQQ__DiscountSchedule__c from SBQQ__ProductOption__c where (SBQQ__ConfiguredSKU__c in :setproductIds or SBQQ__OptionalSKU__c in :setproductIds) ]; 
                   if(lstproductOptions.size()>0)
                   {
                       for(SBQQ__ProductOption__c prodOption : lstproductOptions)
                       {
                       if(prodOption.SBQQ__ConfiguredSKU__r.SBQQ__DiscountSchedule__c!=null && prodOption.SBQQ__OptionalSKU__r.SBQQ__DiscountSchedule__c == null) 
                       { 
                           setproductsToUpdate.add(prodOption.SBQQ__ConfiguredSKU__c);
                       } 
   
                       else if (prodOption.SBQQ__OptionalSKU__r.SBQQ__DiscountSchedule__c != null)
                       {
                           setproductsToUpdate.add(prodOption.SBQQ__ConfiguredSKU__c);
                           setproductsToUpdate.add(prodOption.SBQQ__OptionalSKU__c);
                       }
                           
                       }
                       listproductIds.addAll(setproductsToUpdate);
                   }
                   else 
                   {
                           listproductIds.addAll(setproductIds);
                    }  
                
                 System.debug('listproductIds '+listproductIds);
                   for(Id ProductId : listproductIds)
                   {
                       Product2 prodtoUpdate = new Product2(id=ProductId,CWS_Zuora_Product_Sync_Status__c= CWS_ConstantClass.INT_STATUS_NOT_SYNCED, CWS_NetSuite_Product_Sync_Status__c = CWS_ConstantClass.INT_STATUS_NOT_SYNCED);
                       lstproductsToUpdate.add(prodtoUpdate);
                   }
                   System.debug('lstproductsToUpdate '+lstproductsToUpdate);
                   if(lstproductsToUpdate.size()>0)
                   {
                    List<Database.SaveResult> resultsList = Database.update(lstproductsToUpdate, false);
                       CWS_ExceptionHandler.logDMLSaveResults(resultsList, 'CWS_DiscountTierTriggerHelper' , 'afterUpdate','Products', null , null );
                   }   
           }
           }   
       }
       catch(Exception e){
           CWS_ExceptionHandler.logException( e,'Discount Tiers' , 'CWS_DiscountTierTriggerHelper','afterUpdate' , '', null, null , 'afterUpdate' , null);
          }
    }
    

    public static void AfterInsert(Map<Id,SObject> newItems)
    {
        Map<Id,SBQQ__DiscountTier__c> newMap = (Map<Id,SBQQ__DiscountTier__c>) newItems;
        Set<Id> setDiscountSchedule = new Set<Id>();
        Set<Id> setDiscountTiers = new Set<Id>();
        List<SBQQ__DiscountTier__c> lstDS = new List<SBQQ__DiscountTier__c>();
        //Set<SBQQ__DiscountSchedule__c> setDiscountSchedules = new Set<SBQQ__DiscountSchedule__c>();
        List<Product2> lstproducts = new List<Product2>();
        Set<Id> setproductIds = new Set<Id>();
        List<Id> listproductIds = new List<Id>();
        List<Product2> lstproductsToUpdate = new List<Product2>();
        List<Id> lstproductsSuccess = new List<Id>();
        Set<Id> setproductsToUpdate = new Set<Id>();
        List<SBQQ__ProductOption__c> lstproductOptions = new List<SBQQ__ProductOption__c>();
        Set<Product2> ProductIds = new Set<Product2>();
        //Map <Id,SBQQ__DiscountSchedule__c> mapDiscountSchedules = new Map <Id,SBQQ__DiscountSchedule__c>();
        system.debug('Entering afterInsert');
        for(SBQQ__DiscountTier__c newtier : newMap.values())
        {
            setDiscountSchedule.add(newtier.SBQQ__Schedule__c);
        }
        try
       { 
           if(setDiscountSchedule.size()>0)
           {
               //lstproducts = [Select Id, CWS_Zuora_Product_Sync_Status__c , CWS_NetSuite_Product_Sync_Status__c from product2 where SBQQ__DiscountSchedule__c in :setDiscountSchedule and (CWS_Zuora_Product_Sync_Status__c='Synced' or CWS_NetSuite_Product_Sync_Status__c='Synced') ];
               Map<Id,Product2> mapProducts = new Map<Id,Product2>([Select Id, CWS_Zuora_Product_Sync_Status__c , CWS_NetSuite_Product_Sync_Status__c,SBQQ__DiscountSchedule__c from product2 where SBQQ__DiscountSchedule__c in :setDiscountSchedule and (CWS_Zuora_Product_Sync_Status__c='Synced' or CWS_NetSuite_Product_Sync_Status__c='Synced') ]);
               if(mapProducts.size()>0)
               {
                   setproductIds = mapProducts.keySet();
                   lstproducts = mapProducts.values();
               }   
               if(setproductIds.size()>0)
               {
                   lstproductOptions = [Select Id, SBQQ__ConfiguredSKU__c,SBQQ__OptionalSKU__c,SBQQ__ConfiguredSKU__r.SBQQ__DiscountSchedule__c, SBQQ__OptionalSKU__r.SBQQ__DiscountSchedule__c, SBQQ__ConfiguredSKU__r.CWS_Zuora_Product_Sync_Status__c,SBQQ__ConfiguredSKU__r.CWS_NetSuite_Product_Sync_Status__c,SBQQ__OptionalSKU__r.CWS_Zuora_Product_Sync_Status__c,SBQQ__OptionalSKU__r.CWS_NetSuite_Product_Sync_Status__c from SBQQ__ProductOption__c where (SBQQ__ConfiguredSKU__c in :setproductIds or SBQQ__OptionalSKU__c in :setproductIds) ]; 
                   if(lstproductOptions.size()>0)
                   {
                       for(SBQQ__ProductOption__c prodOption : lstproductOptions)
                       {
                       if(prodOption.SBQQ__ConfiguredSKU__r.SBQQ__DiscountSchedule__c!=null && prodOption.SBQQ__OptionalSKU__r.SBQQ__DiscountSchedule__c == null) 
                       {
                           
                           setproductsToUpdate.add(prodOption.SBQQ__ConfiguredSKU__c);
                       } 
   
                       else if (prodOption.SBQQ__OptionalSKU__r.SBQQ__DiscountSchedule__c != null)
                       {
                            
                           setproductsToUpdate.add(prodOption.SBQQ__ConfiguredSKU__c);
                           setproductsToUpdate.add(prodOption.SBQQ__OptionalSKU__c);
                       }
                           
                       }
                       listproductIds.addAll(setproductsToUpdate);
                   }
                   else 
                   {
                           listproductIds.addAll(setproductIds);        
                   }
                   for(Id ProductId : listproductIds)
                   {
                       Product2 prodtoUpdate = new Product2(id=ProductId,CWS_Zuora_Product_Sync_Status__c='Not Synced',CWS_NetSuite_Product_Sync_Status__c='Not Synced');
                       lstproductsToUpdate.add(prodtoUpdate);
                   }
                  
                   if(lstproductsToUpdate.size()>0)
                   {
                    List<Database.SaveResult> resultsList = Database.update(lstproductsToUpdate, false);
                       CWS_ExceptionHandler.logDMLSaveResults(resultsList, 'CWS_DiscountTierTriggerHelper' , 'afterInsert','Products', null , null );
                   }   
           }
           }   
        }
       catch(Exception e){
           CWS_ExceptionHandler.logException( e,'Discount Tiers' , 'CWS_DiscountTierTriggerHelper','afterInsert' , '', null, null , 'afterInsert' , null);
          }
    }
 
}