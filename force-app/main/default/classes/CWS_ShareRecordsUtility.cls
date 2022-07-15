/*Class Name: CWS_ShareRecordsUtility
*Description: This class is an utitliy which can be utilized to share/remove access Sobject records
*Created By: Ankit
*Created On: 4/27/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                  4/27/2020         BED-6083              This class is an utitliy which can be utilized to share/remove access Sobject records
*Ankit                  4/24/2020         BED-6479              Added return statement to return conntext to the batch class
*/
public class CWS_ShareRecordsUtility {
    
    /*
    * Method: shareSobjectRecords
    * Developer: abobde@deloitte.com
    * Description: share sobject records with specified group/users
    */
    public static list<sObject> shareSobjectRecords(String objName, map<id,Set<id>> mapOfRecToShare,String accessLevel){
       
       Schema.SObjectType stdShareType;
       boolean isStandard;
       list<SObject> listofnewShareObj = new list<SObject>();
       try{
           //Check if the object name passed is a standard/Custom object accordingly create share object name 
           if(objName.endsWithIgnoreCase(CWS_ConstantClass.ACCESS_CUSTOM_OBJECT)){
               stdShareType = Schema.getGlobalDescribe().get(objName.replace(CWS_ConstantClass.ACCESS_CUSTOM_OBJECT,CWS_ConstantClass.ACCESS_CUSTOM_OBJ_SHARE));
           }else{
               stdShareType = Schema.getGlobalDescribe().get(objName + CWS_ConstantClass.ACCESS_STD_OBJ_SHARE);
               isStandard = true;
           }
           //loop over users associated with end customer accounts create share records 
           //which will be later inserted to actually share the records with partner users
           if(!mapOfRecToShare.isEmpty()){
               for(Id  recId: mapOfRecToShare.keyset()){
                   for(Id userId: mapOfRecToShare.get(recId)){
                       SObject shareObj = stdShareType.newSObject();
                       
                       if(isStandard){
                           shareObj.put(objName+CWS_ConstantClass.ACCESS_LEVEL,accessLevel);
                           shareObj.put(objName+CWS_ConstantClass.ACCESS_ID, recId);
                           //AccountShare object has additional properties
                           if(objName.equalsIgnoreCase(CWS_ConstantClass.SOBJECT_ACCOUNT)) {
                               shareObj.put(CWS_ConstantClass.ACCESS_ACC_CONTACT, CWS_ConstantClass.ACCESS_READ);
                               shareObj.put(CWS_ConstantClass.ACCESS_ACC_CASE, CWS_ConstantClass.ACCESS_NONE);
                               shareObj.put(CWS_ConstantClass.ACCESS_ACC_OPPTY, CWS_ConstantClass.ACCESS_NONE);
                           }
                       }else{
                           shareObj.put(CWS_ConstantClass.ACCESS_LEVEL,accessLevel);
                           shareObj.put(CWS_ConstantClass.ACCESS_PARENTID, recId);
                       }
                       
                       //common details for standard and custom objects
                       shareObj.put(CWS_ConstantClass.ACCESS_USER_USERGRP, userId);
                       shareObj.put(CWS_ConstantClass.ACCESS_SHARE_CAUSE, CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL);
                       
                       listofnewShareObj.add(shareObj);
                   }
               }
            }
            //Start : BED-6479 To return context back to Batch Class and batch class will insert the share records
            return listofnewShareObj;
            //End : BED-6479
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Disty/Reseller' , 'CWS_ShareRecordsUtility', 'shareSobjectRecords' , '', null, null , 'shareSobjectRecords', null);
        }
        return listofnewShareObj;
    }
    
    /**
    * Method: removeSobjectRecords
    * Developer: abobde@deloitte.com
    * Description: remove access of sobject records for specified group/users
    */
    public static list<sObject> removeSobjectRecords(String ObjName,set<id> setParentIdsToDelete,set<id> setUserIdsToDelete){
       
       String shareObjName;
       boolean isStandard;
       list<SObject> removeShareLst = new list<SObject>();
       try{
          
           if(!setParentIdsToDelete.isEmpty()){
               //Identify if the object is standard/Custom and accordingly craete a share record
               if(objName.endsWithIgnoreCase(CWS_ConstantClass.ACCESS_CUSTOM_OBJECT)){
                   shareObjName = objName + CWS_ConstantClass.ACCESS_CUSTOM_OBJ_SHARE;
               }else{
                   shareObjName = objName + CWS_ConstantClass.ACCESS_STD_OBJ_SHARE;
                   isStandard = true;
               }
               
               //Query string to get the sobject share records to delete
               String soqlQuery = 'Select id,UserOrGroupId from ';
               //storing the manual row cause in string
               String rowCause = CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL;
               
               //executes on the basis of standard/custom object as the query needs to be formed differently in both cases
               if(isStandard){
                   soqlQuery = soqlQuery + shareObjName + ' where '+ objName+CWS_ConstantClass.ACCESS_ID +' IN: setParentIdsToDelete AND UserOrGroupId IN: setUserIdsToDelete AND RowCause =: rowCause';
               }else{
                   soqlQuery = soqlQuery + shareObjName + ' where ParentId IN: setParentIdsToDelete AND UserOrGroupId IN: setUserIdsToDelete AND RowCause =: rowCause';
               }
               
               //performing query to get the shared record to delete
               for (SObject sobj : Database.query(soqlQuery)){
                   removeShareLst.add(sobj);
               }
          }
          //Start: BED-6479
          return removeShareLst;
          //End : BED-6479
       }catch(Exception e){
           CWS_ExceptionHandler.logException( e,'Disty/Reseller' , 'CWS_ShareRecordsUtility', 'removeSobjectRecords' , '', null, null , 'removeSobjectRecords', null);
       }
       return removeShareLst;
   }
}