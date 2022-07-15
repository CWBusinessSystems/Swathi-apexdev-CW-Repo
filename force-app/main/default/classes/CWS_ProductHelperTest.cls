/*Class Name: CWS_ProductHelperTest
*Description: Test Class for CWS_ProductTriggerHelper
*Created By: Aditya
*Created On: 8/19/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            Description
*------------------------------------------------------------------------------------------
*Aditya         		8/19/2020     Test Class for CWS_ProductTriggerHelper             
*/
@isTest
public class CWS_ProductHelperTest {
	@TestSetup
    static void init(){
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Product','ProductOption'});  
        
        Map<String, Object> currentFields=new Map<String,Object>{
          'CWS_UOM__c'=> 'Agent'
        };		
        Product2 prod = CWS_UTLDataFactory.createProduct('Test Product','SKU001',currentFields, true);
   	
    }
    @isTest
    static void testMethod1(){
        Test.startTest();
        Product2 prod = [Select id, CWS_UOM__c from Product2 limit 1];
        prod.CWS_UOM__c = 'Each';
        update prod;
       
		prod.CWS_NetSuite_Product_Sync_Status__c= 'Synced';
        prod.CWS_Zuora_Product_Sync_Status__c ='Synced';
        update prod;
        
      	SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(SBQQ__Number__c=1,SBQQ__OptionalSKU__c = prod.id,SBQQ__ConfiguredSKU__c=prod.id);
        insert prodOption;	
        Test.stopTest();
         Map<Id, SObject> newItems = new Map<Id, SObject>();
      CWS_ProductTriggerHandler obj = new CWS_ProductTriggerHandler();
      obj.AfterUpdate(newItems, newItems);
      obj.BeforeDelete(newItems);
      obj.AfterDelete(newItems);
      obj.AfterInsert(newItems);
      obj.AfterUndelete(newItems);
     
      CWS_ProductOptionTriggerHandler obj1 = new CWS_ProductOptionTriggerHandler();
      obj1.AfterUpdate(newItems, newItems);
      obj1.BeforeDelete(newItems);
      obj1.AfterDelete(newItems);
      obj1.AfterUndelete(newItems);
      obj1.BeforeInsert(new List<SObject>());
      obj1.BeforeUpdate(newItems, newItems);
        
    }
}