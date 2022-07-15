/*Class Name: CWS_DiscountTierHelperTest
*Description: Test Class for CWS_DiscountTierTriggerHelper
*Created By: Indra Ganesan
*Created On: 31-07-2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            Description
*------------------------------------------------------------------------------------------
*Indra Ganesan         31-07-2020       Test Class for CWS_DiscountTierTriggerHelper             
*/
@isTest(SeeAllData=false)
public with sharing class CWS_DiscountTierHelperTest {
    
    @TestSetup
    static void init(){
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'DiscountTier','CWS_DiscountTierTrigger__c'});  
        SBQQ__DiscountSchedule__c discSchedule = CWS_UTLDataFactory.createDiscountSchedule();
        Map<String, Object> currentFields=new Map<String,Object>{
            'SBQQ__DiscountSchedule__c'=>discSchedule.id, 'CWS_NetSuite_Product_Sync_Status__c'=>'Synced', 'CWS_Zuora_Product_Sync_Status__c'=>'Synced'
        };		
        Product2 prod = CWS_UTLDataFactory.createProduct('Test Product','SKU001',currentFields, true);
        SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(SBQQ__Number__c=1,SBQQ__OptionalSKU__c = prod.id,SBQQ__ConfiguredSKU__c=prod.id);
        insert prodOption;		
    }
    
	@IsTest
    static void testAfterUpdate(){		
      
        SBQQ__DiscountSchedule__c discSchedule = [select Id from SBQQ__DiscountSchedule__c limit 1];
        SBQQ__DiscountTier__c discTier = CWS_UTLDataFactory.createDiscountTier(discSchedule.id, true);
        Test.startTest();
        Product2 prod =  [select Id,CWS_NetSuite_Product_Sync_Status__c,SBQQ__DiscountSchedule__c  from Product2 limit 1];
        prod.CWS_NetSuite_Product_Sync_Status__c = 'Synced';
        update prod;
        SBQQ__ProductOption__c prodOption = [select id,SBQQ__OptionalSKU__c,SBQQ__ConfiguredSKU__r.SBQQ__DiscountSchedule__c, SBQQ__OptionalSKU__r.SBQQ__DiscountSchedule__c from SBQQ__ProductOption__c limit 1];
        discTier.SBQQ__UpperBound__c= 25;       
        if(discTier != null)
           update discTier;       
        System.assertEquals(25,discTier.SBQQ__UpperBound__c ,'Upper Bound Updated');        
        Test.stopTest();
    }
    
   @IsTest
    static void testAfterInsert(){		
       SBQQ__DiscountSchedule__c discSchedule = [select Id from SBQQ__DiscountSchedule__c limit 1];
       Product2 prod =  [select Id,CWS_NetSuite_Product_Sync_Status__c,SBQQ__DiscountSchedule__c  from Product2 limit 1];
       prod.CWS_NetSuite_Product_Sync_Status__c = 'Synced';
       update prod;
       SBQQ__ProductOption__c prodOption = [select id,SBQQ__OptionalSKU__c,SBQQ__ConfiguredSKU__r.SBQQ__DiscountSchedule__c, SBQQ__OptionalSKU__r.SBQQ__DiscountSchedule__c from SBQQ__ProductOption__c limit 1];
       Test.startTest();        
       SBQQ__DiscountTier__c discTier = CWS_UTLDataFactory.createDiscountTier(discSchedule.id, true);
       List<SBQQ__DiscountTier__c> lstDiscTier =[select id from SBQQ__DiscountTier__c where id=: discTier.id];
       System.assertEquals(1, lstDiscTier.size());    
		    Map<Id, SObject> newItems = new Map<Id, SObject>();
      CWS_DiscountTierTriggerHandler obj = new CWS_DiscountTierTriggerHandler();
      obj.BeforeUpdate(newItems, newItems);
      obj.BeforeDelete(newItems);
      obj.BeforeInsert(new List<SObject>());
      obj.AfterDelete(newItems);
      obj.AfterUndelete(newItems);
       Test.stopTest();
    }
 /* @IsTest
    static void testAfterInsertProdOpt(){		
        Test.startTest();
        SBQQ__DiscountSchedule__c discSchedule = CWS_UTLDataFactory.createDiscountSchedule();
		Map<String, Object> currentFields=new Map<String,Object>{
            'SBQQ__DiscountSchedule__c'=>discSchedule.id, 'CWS_NetSuite_Product_Sync_Status__c'=>'Not Synced', 'CWS_Zuora_Product_Sync_Status__c'=>'Not Synced'
        };		
       Product2 prod = CWS_UTLDataFactory.createProduct('Test Product','SKU001',currentFields, true);    
       SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(SBQQ__Number__c=1,SBQQ__ConfiguredSKU__c=prod.id);
       insert prodOption;
       SBQQ__DiscountTier__c discTier = CWS_UTLDataFactory.createDiscountTier(discSchedule.id, true);
       List<SBQQ__DiscountTier__c> lstDiscTier =[select id from SBQQ__DiscountTier__c where id=: discTier.id];
       System.assertEquals(1, lstDiscTier.size());        
       Test.stopTest();
    }*/
    
}