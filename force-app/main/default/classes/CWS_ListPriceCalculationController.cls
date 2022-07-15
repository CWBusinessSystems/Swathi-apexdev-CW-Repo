/*
* Class Name  : CWS_ListPriceCalculationController
* Description : Controller class to support CWS_PriceBookEntryBatchJob visualforce page
* Created By  : Nirmal Kumar 
* Created On  : 4/10/2020

 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID      Description 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Nirmal Kumar             4/10/2020                BED-3492          Initial/First Version      
*/

public with sharing class CWS_ListPriceCalculationController {
   

    //constructor to support the visualforce page to use as standard controller
    public CWS_ListPriceCalculationController(ApexPages.StandardSetController controller){
        
    }
    
    //method which invokes the CWS_ListPriceCalculationBatch and creates a CWS_TRigger_Batch_Job record
   
    public static  PageReference invokeBatch() {
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        //page gets redirected to the CWS_Trigger_Batch_Job list view after invoking the batch
        PageReference page = new PageReference('/' + CWS_Trigger_Batch_Job__c.sObjectType.getDescribe().getKeyPrefix());
        page.setRedirect(true);
        //create a new CWS_Trigger_Batch_Job__c record with status as processing. This status will get updated when the CWS_ListPriceCalculationBatch completes
        CWS_Trigger_Batch_Job__c triggerRecord = new CWS_Trigger_Batch_Job__c();
        triggerRecord.CWS_Status__c = CWS_ConstantClass.TRIGGER_PROCESSING;
        try{
           Database.SaveResult result = Database.insert(triggerRecord, False);
           results.add(result);
           CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_ListPriceCalculationController' , 'invokeBatch','Insert CWS_Trigger_Batch_Job__c', null , null ); 
           if(!String.isBlank(triggerRecord.Id)){
            Database.executeBatch(new CWS_ListPriceCalculationBatch());
           }
           
        }
        catch(exception e){
            CWS_ExceptionHandler.logException( e,'PriceBookEntry' , 'CWS_ListPriceCalculationController' , 'invokeBatch' ,'', null , null ,'Before invoking the batch job' , null);     
        }
        return page; 
    }
    
     //method which invokes the CWS_ListPriceCalculationBatch and creates a CWS_TRigger_Batch_Job record
    public static PageReference closeBatch() {
    	PageReference page = new PageReference('/' + CWS_Trigger_Batch_Job__c.sObjectType.getDescribe().getKeyPrefix());
        page.setRedirect(true);
         return page;
    }
    

}