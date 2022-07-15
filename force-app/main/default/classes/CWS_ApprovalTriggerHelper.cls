/*Class Name: CWS_ApprovalTriggerHelper
*Description: Helper Class for CWS_ApprovalTriggerHandler
*Created By: Khayam
*Created On: 5/19/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                 5/19/2020       BED-8645            Account Restriction - Delinquency 
*/
public with sharing class CWS_ApprovalTriggerHelper {

 /* 
 * Method name  : beforeInsertMethod
 * Description  : BED-13161
 * Return Type  : None
 * Developer    : Naresh
 */
 
 public static void beforeInsertMethod(List<SObject> lstNew){
     List<sbaa__Approval__c> lstAppnew=(List<sbaa__Approval__c>)lstNew;
     set<id> idSet = new set<id>();
     for(sbaa__Approval__c appr: lstAppnew){
         if(appr.CWS_Quote__c!= null){
             idSet.add(appr.CWS_Quote__c);
         }
     }
     
     map<id,id> idtoOwnerMap = new map<id,id>();
     map<id,id> idtoOppMap = new map<id,id>();
      map<id,String> idAppCommMap = new map<id,String>();

     
     if(idSet.size() > 0){
         for(SBQQ__Quote__c qObj : [Select id,ownerId,CWS_Approval_Request_Comment__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id IN: idSet]){
             idtoOwnerMap.put(qObj.id,qObj.ownerID);
             idtoOppMap.put(qObj.id, qObj.SBQQ__Opportunity2__c);
             idAppCommMap.put(qObj.id, qObj.CWS_Approval_Request_Comment__c);
         }
     }
     
     for(sbaa__Approval__c appr: lstAppnew){
         if(appr.CWS_Quote__c != null && idtoOwnerMap.containskey(appr.CWS_Quote__c)){
             appr.OwnerID = idtoOwnerMap.get(appr.CWS_Quote__c);
         }
         appr.CWS_Approval_Opportunity__c = idtoOppMap.get(appr.CWS_Quote__c);
         appr.CWS_Approval_Request_Comment__c = idAppCommMap.get(appr.CWS_Quote__c);
     }
 }

    /*
    * Method name  : afterUpdate
    * Description  : BED-8645
    * Parameter    : List of Approval.
    * Return Type  : None
    * Developer    : Khayam
    */
    public static void afterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems){
        Map<Id,sbaa__Approval__c> newMap = (Map<Id,sbaa__Approval__c>) newItems;
        Map<Id,sbaa__Approval__c> oldMap = (Map<Id,sbaa__Approval__c>) oldItems;
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();

        Map<Id,sbaa__Approval__c> appvlsMap = new Map<Id,sbaa__Approval__c>();

        try {

            if (newMap!=null) {
                appvlsMap = new Map<Id,sbaa__Approval__c>([SELECT id,sbaa__Status__c,sbaa__ApprovalChain__r.Name,CWS_Quote__c,CWS_Quote__r.SBQQ__Opportunity2__c,
                                                        CWS_Quote__r.SBQQ__Opportunity2__r.CWS_Rejected_Approval_Count__c
                                                        from sbaa__Approval__c where id in :newMap.keySet()]);   
            }
            
            for (sbaa__Approval__c approval : appvlsMap.values()) {
                if (approval.CWS_Quote__c != null && approval.CWS_Quote__r.SBQQ__Opportunity2__c != null && 
                    approval.sbaa__ApprovalChain__r.Name == CWS_ConstantClass.QUOTE_ACC_RESTRICT_APPROVAL &&  
                    newMap.get(approval.Id).sbaa__Status__c != oldMap.get(approval.Id).sbaa__Status__c) {

                    if (approval.sbaa__Status__c == CWS_ConstantClass.QUOTE_Approval_Status_Rejected) {

                        if (oppMap.containsKey(approval.CWS_Quote__r.SBQQ__Opportunity2__c)) {
                            Opportunity opp = oppMap.get(approval.CWS_Quote__r.SBQQ__Opportunity2__c);
                            Decimal count = approval.CWS_Quote__r.SBQQ__Opportunity2__r.CWS_Rejected_Approval_Count__c;
                            opp.CWS_Rejected_Approval_Count__c = count != null ? count+1 : 1;
                        } else {
                            Opportunity opp = new Opportunity(Id=approval.CWS_Quote__r.SBQQ__Opportunity2__c);
                            Decimal count = approval.CWS_Quote__r.SBQQ__Opportunity2__r.CWS_Rejected_Approval_Count__c;
                            opp.CWS_Rejected_Approval_Count__c = count != null ? count+1 : 1;
                            oppMap.put(opp.Id,opp);
                        }
                        
                    } else if (approval.sbaa__Status__c == CWS_ConstantClass.QUOTE_Approval_Status_Approved) {
                        
                        if (oppMap.containsKey(approval.CWS_Quote__r.SBQQ__Opportunity2__c)) {
                            Opportunity opp = oppMap.get(approval.CWS_Quote__r.SBQQ__Opportunity2__c);
                            opp.CWS_Account_Restriction_Approved__c = TRUE;
                        } else {
                            Opportunity opp = new Opportunity(Id=approval.CWS_Quote__r.SBQQ__Opportunity2__c);
                            opp.CWS_Account_Restriction_Approved__c = TRUE;
                            oppMap.put(opp.Id,opp);
                        }
                    }
    
                    
                }
            }

            if (!oppMap.isEmpty()) {
                List<Database.SaveResult> results = Database.update(oppMap.values());
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_ApprovalTriggerHelper' , 'afterUpdate','Opportunity', null , null ); 
            }

        } catch (Exception e) {
            CWS_ExceptionHandler.logException( e,'sbaa__Approval__c' , 'CWS_ApprovalTriggerHelper', 'afterUpdate' , '', null, null , 'afterUpdate' , null);
        }
    }
}