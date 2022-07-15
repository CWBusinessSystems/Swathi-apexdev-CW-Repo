/**
* @description       : 
* @author            : DPC Advictoriam Solutions
* @group             : 
* @last modified on  : 06-18-2021
* @last modified by  : DPC Advictoriam Solutions
* Modifications Log 
* Ver   Date         Author                      Modification
* 1.0   06-18-2021   DPC Advictoriam Solutions   Initial Version
**/
public class CWS_BatchApexProgressIndicatorCtrlStub implements Database.Batchable<sObject>{
   public final String Query;
   // code is used to test job record retreival
   public CWS_BatchApexProgressIndicatorCtrlStub(String q){
             Query=q; 
   }

   public Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   public void execute(Database.BatchableContext BC, List<sObject> scope){
      
   }

   public void finish(Database.BatchableContext BC){

   }

}