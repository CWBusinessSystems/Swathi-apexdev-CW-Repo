/*Class Name: CWS_OpportunityTeamMemberTriggerHelper
*Description: Helper Class for CWS_OpportunityTeamMemberTriggerHandler
*Created By: Khayam
*Created On: 04/01/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                04/01/2020       BED-6326            Sales Rep Access to Quote 
*
*/
public without sharing class CWS_OpportunityTeamMemberTriggerHelper {
    
    /*
    * Method name  : shareQuotesofOpportunity
    * Description  : BED-6326 : Sales Rep Access to Quote: After Insert
    * Parameter    : Opp team member records
    * Return Type  : None
    * Developer    : Khayam
    */
    public static void shareQuotesofOpportunity(Map<Id, SObject> newItems){
     try {
        Map<Id, OpportunityTeamMember> mapnewOpportunityTeamMember = (Map<Id, OpportunityTeamMember>) newItems;
        List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__Share> lstQuoteShare = new List<SBQQ__Quote__Share> ();
        Map<String,String> mapOpptyQuote = new   Map<String,String>();
        
        Set<Id> setOppIds = new Set<Id>();

        for(Id key : mapnewOpportunityTeamMember.keySet()){
            OpportunityTeamMember otm = mapnewOpportunityTeamMember.get(key);
            if(otm.OpportunityAccessLevel == 'Edit'){
                setOppIds.add(otm.OpportunityId);
            }
        } 

        if(setOppIds != NULL && setOppIds.size() > 0){
            lstQuotes = [Select Id,SBQQ__Opportunity2__c from SBQQ__Quote__c where SBQQ__Opportunity2__c in :setOppIds];
        }

        for(SBQQ__Quote__c qte: lstQuotes){
            mapOpptyQuote.put(qte.SBQQ__Opportunity2__c + '-' + qte.Id, qte.Id);
        }

        for(OpportunityTeamMember otm : mapnewOpportunityTeamMember.values()){
            for(String oppQId : mapOpptyQuote.keySet()){
                if (oppQId.contains(String.valueOf(otm.OpportunityId)) && otm.OpportunityAccessLevel == 'Edit'){
                    if(mapOpptyQuote.get(oppQId) != null){
                        SBQQ__Quote__Share quoteShr  = new SBQQ__Quote__Share();
                        quoteShr.ParentId = mapOpptyQuote.get(oppQId);
                        quoteShr.UserOrGroupId = otm.UserId;
                        quoteShr.AccessLevel = 'Edit';
                        lstQuoteShare.add(quoteShr);                     
                    }
                }
            }
        }

       
           if(!lstQuoteShare.isEmpty()){
                Database.SaveResult[] results = Database.insert(lstQuoteShare,false);   
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_OpportunityTeamMemberTriggerHelper' , 'shareQuotesofOpportunity','OpportunityTeamMember', null , null );
           }
       } catch(Exception e){                
        CWS_ExceptionHandler.logException( e,'OpportunityTeamMember' , 'CWS_OpportunityTeamMemberTriggerHelper', 'shareQuotesofOpportunity' , '', null, null , 'AfterInsert' , null);            
       }
    }

    /*
    * Method name  : shareQuotesofOpportunity
    * Description  : BED-6326 : Sales Rep Access to Quote: After Delete
    * Parameter    : Opp team member records
    * Return Type  : None
    * Developer    : Khayam
    */
    public static void unshareQuotesofOpportunity(Map<Id, SObject> oldItems){
       try {
        Map<Id, OpportunityTeamMember> mapOpportunityTeamMember = (Map<Id, OpportunityTeamMember>) oldItems;
        List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
        Map<String,String> mapOpptyQuote = new   Map<String,String>();
        List<SBQQ__Quote__Share> lstQuoteShares = new List<SBQQ__Quote__Share>();
        
        Set<Id> setOppIds = new Set<Id>();
        Set<Id> setQteIds = new Set<Id>();
        Set<Id> setUserIds = new Set<Id>();

        for(OpportunityTeamMember otm : mapOpportunityTeamMember.values()){
                setOppIds.add(otm.OpportunityId);
                setUserIds.add(otm.UserId); 
        } 

        if(setOppIds != NULL && setOppIds.size() > 0){
            lstQuotes = [Select Id,SBQQ__Opportunity2__c,(Select Id,ParentId,UserOrGroupId from Shares WHERE AccessLevel = 'Edit') FROM SBQQ__Quote__c where SBQQ__Opportunity2__c in :setOppIds];
        }

        for(SBQQ__Quote__c qte: lstQuotes){
            for(SBQQ__Quote__Share qShare: qte.Shares){
                if (setOppIds.contains(qte.SBQQ__Opportunity2__c) && setUserIds.contains(qShare.UserOrGroupId)) {
                    lstQuoteShares.add(qShare);
                }

            }
        }

       
           if(!lstQuoteShares.isEmpty()){
                Database.DeleteResult[] results = Database.delete(lstQuoteShares,false);
                CWS_ExceptionHandler.logDMLDelResults(results, 'CWS_OpportunityTeamMemberTriggerHelper', 'unshareQuotesofOpportunity','OpportunityTeamMember' , null, null );
           }
       } catch(Exception e){                
        CWS_ExceptionHandler.logException( e,'OpportunityTeamMember' , 'CWS_OpportunityTeamMemberTrigger', 'unshareQuotesofOpportunity' , '', null, null , 'AfterDelete' , null);            
       }
    }

}