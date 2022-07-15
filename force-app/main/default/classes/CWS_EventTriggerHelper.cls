/*Class Name: CWS_EventTriggerHelper
*Description: Helper Class for CWS_EventTriggerHandler
*Created By: Manoj
*Created On: 05/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Manoj                  05/05/2020      7889                    Prevent deletion of Event
*Ankit                  05/19/2020      7844                    Populate email of related to record user
*/
public class CWS_EventTriggerHelper {
    public static void beforeDeleteLogic(Map<Id, SObject> oldItems){
              
        String crntUsrProfile = [SELECT Name from Profile WHERE Id=: userinfo.getProfileId() LIMIT 1].Name;
        List<Restricted_Activity_Profiles__mdt> restrictedProfilesList = [SELECT Id,  QualifiedApiName FROM Restricted_Activity_Profiles__mdt
                                                                          WHERE QualifiedApiName =: crntUsrProfile AND  QualifiedApiName != null];
        //Checking if profile is in restricted list.
        if(!restrictedProfilesList.isempty()){
            for (Id eventId : oldItems.keyset())      
            {                            
                oldItems.get(eventId).addError(Label.Activity_Error_Message); 
            } 
        }
    }
    
    //7844 : Populate email of related user object record
    public static void beforeInsertLogic(list<SObject> newItems){
        list<Event> newRecs = (list<Event>) newItems;
        set<id> oppIds = new set<id>();
        try{
            if(CWS_ConstantClass.USERINFO_STANDARD != null && 
                UserInfo.getUserType() != CWS_ConstantClass.USERINFO_STANDARD){
                   
                for(Event event : newRecs){
                    if(event.whatId != null){
                        Schema.SObjectType sobjectType = event.whatId.getSObjectType();   
                        if(sobjectType.getDescribe().getName() == CWS_ConstantClass.OPPORTUNITY_NAME){
                            //BED- 7844 Get related opportunity Id to query
                            oppIds.add(event.whatId);
                        }
                    }   
                 }
                   
                 map<id,opportunity> mapOfOpp;
                   
                 if(oppIds != null){
                     //BED- 7844 Query related opportunities and put in map to get the email of owner
                     mapOfOpp = new map<id,opportunity>([Select id,owner.email,owner.firstname,owner.lastname,stagename from opportunity where id IN: oppIds]);
                       
                     if(mapOfOpp != null){
                         for(Event event : newRecs){
                             if(mapOfOpp.containskey(event.whatId)){
                                 //BED-7844 Assign the related opportunity email which will be used as recipient in workflow rule
                                 event.CWS_Related_User_Email__c= mapOfOpp.get(event.whatId).owner.email;
                                 event.CWS_Related_User_Name__c = mapOfOpp.get(event.whatId).owner.firstname+' '+mapOfOpp.get(event.whatId).owner.lastname ;
                             }
                         }
                     }
                 }
              }
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Event' , 'CWS_EventTriggerHelper', 'beforeInserLogic' , '', null, null , 'Before Insert' , null);
        }
    }
}