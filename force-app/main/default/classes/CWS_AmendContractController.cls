/*Class Name: CWS_AmendContractController
*Description: Controller Class for CWS_AmendContract Component
*Created By: Aakash Sharma
*Created On: 4/17/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aakash                 4/17/2020        BED-6317               Amendment Quote Creation Access Logic for AM,System Admins,Sales Manegers,Global Sales Ops
*Divyanshu 				2/6/2021		 OBD-441				Added a popup alert for about to expire Contracts
*/
public without sharing class CWS_AmendContractController {
    
    @AuraEnabled
    public static Boolean ContractExipryCheck(Id contractID){
        List<Contract> contractObj=[select CWS_Is_Contract_near_expiry__c from Contract Where id=: contractID];
        return !contractObj.isEMpty()?contractObj[0].CWS_Is_Contract_near_expiry__c : false;
    }
    
    @AuraEnabled
   public static String validateTerminationApproval(Id contractId){
       String errMsg= 'false';
       Id loggedUser=userInfo.getUserId();
       User userObj=new User();
       if(loggedUser != null){
           Id profileId=userinfo.getProfileId();
           String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
           if(profileName.equalsIgnoreCase('CWS_Sales_Rep') || profileName.equalsIgnoreCase('CWS_Sales_Manager')){
               errMsg = 'true';
           }
       }
       return errMsg;
   }
   
   @AuraEnabled
   public static String AMUserCheck(Id contractID){
   Id loggedUser=userInfo.getUserId();
   boolean BolUserCheck=false;
   String errMsg;
   string strRegion;
   String strGroup;
   Map<id,String> mapUserRegion=new Map<id,String>();
   Map<string,string> mapRegionGroup=new MAp<string,string>();
   list<Group>lstPGroup=new list<Group>();
   String strProfiles=CWS_ConstantClass.amendProfiles;
   Integer intLimit=Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);
   intLimit=intLimit+3500;
   List<CWS_RegionGroupMapping__mdt> lstRegionGroupMD=new List<CWS_RegionGroupMapping__mdt>();
   
   try{
       //Get the region Of the Account of the Contract
       Contract contractObj=new Contract();
       User userObj=new User();
       if(contractID != null){
       contractObj=[select id,Account.CWS_Region__c, CWS_Renewal_Category__c, SBQQ__Evergreen__c from contract where id=:contractID];
       }
       //BED-12497
       if(contractObj.CWS_Renewal_Category__c==CWS_ConstantClass.Renewal_Category_SplitPending && !contractObj.SBQQ__Evergreen__c){
           errMsg = CWS_ConstantClass.Renewal_Category_SplitPending;
       }
       if(loggedUser != null){
       userObj=[select id,Profile.Name,CWS_Region__c from user where id=:loggedUser];
       }
       if(contractObj!=null && contractObj.Account.CWS_Region__c!=null){
       strRegion=contractObj.Account.CWS_Region__c;
       }
       if(strRegion!=null){
       lstRegionGroupMD=[select id,CWS_Region__c,CWS_GroupName__c from CWS_RegionGroupMapping__mdt where CWS_Region__c=:StrRegion];
       }
       if(lstRegionGroupMD.size()>0){
           for(CWS_RegionGroupMapping__mdt RegionGroup:lstRegionGroupMD){
               mapRegionGroup.put(RegionGroup.CWS_Region__c,RegionGroup.CWS_GroupName__c);
           }
       }
       if( mapRegionGroup.containskey(StrRegion) && mapRegionGroup.get(StrRegion)!=null){
           strgroup=mapRegionGroup.get(StrRegion);
       }
       system.debug(intLimit);
       if(strgroup!=null && intLimit != null){
       lstPGroup=[select id,name,DeveloperName,(Select id,UserOrGroupId from GroupMembers LIMIT : intLimit) from Group where DeveloperName =:strGroup];
       }
           if(lstPGroup.size()>0){
           for(Group grp:lstPGroup)
               {
                   for(GroupMember members:grp.GroupMembers)
                   {
                       mapUserRegion.put(members.UserOrGroupId,grp.DeveloperName);
                   }
               }
           }    
           if((strProfiles.contains(userObj.Profile.Name)) || (userObj.Profile.Name== CWS_ConstantClass.PROFILE_SALES_REP && UserObj.CWS_Region__c != null && UserObj.CWS_Region__c.contains(strRegion))){
               BolUserCheck=True;       
           }
           else if(mapUserRegion.containskey(loggedUser) && (mapUserRegion.get(loggedUser))!=null ){
               
                            BolUserCheck=true;
               }
       if(String.isNotEmpty(errMsg)){
           if(!BolUserCheck){
               errMsg = 'False';
           }
       }
       else{
           if(BolUserCheck){
               errMsg = 'True';
           }
           else{
               errMsg = 'False';
           }    
       }
              
       return errMsg;
           
     }catch(Exception e){
     CWS_ExceptionHandler.logException( e,'Contract' , 'CWS_AmendContractController', 'AMUserCheck' , '', null, null , 'CWS_AmendContractController' , null);
     throw new AuraHandledException('Exception occurred while Running this class : '+ e.getMessage());      
     }
      
   }

   //BED-6254
   @AuraEnabled
   public static boolean UserCheckAM(String  AccRegion, User UserObj){
       Boolean CheckAM=true;
       Map<Id,Set<String>> UserRegionMapping =new Map<Id,Set<String>>();
       try{
       if(UserObj != null){
       UserRegionMapping=CWS_CommonUtility.getGroupMemberRegion(new List<id>{UserObj.id});  
       }   
       if( (UserRegionMapping.isEmpty() || (UserRegionMapping.containsKey(UserObj.id) && !UserRegionMapping.get(UserObj.id).contains(AccRegion) )) && UserObj.Profile.Name == CWS_ConstantClass.PROFILE_SALES_REP && UserObj.CWS_Region__c != null && AccRegion!=null && UserObj.CWS_Region__c.contains(AccRegion)){
           CheckAM=false;
       }
       return checkAM;
       }
       catch(Exception e){
           CWS_ExceptionHandler.logException( e,'User' , 'CWS_AmendContractController', 'UserCheckAM' , '', null, null , 'CWS_AmendContractController' , null);
           throw new AuraHandledException('Exception occurred while Running this class : '+ e.getMessage());      
       }
   }
   //BED-6254

//BED-6827
   @AuraEnabled
   public static boolean updateRecord(String trans, String conversion, String status, String recontract, Id conId){
       Boolean errMsg= false;
       Id loggedUser=userInfo.getUserId();
       User userObj=new User();
       String AccRegion;
       Boolean CreatedbyAM=true;
       if(loggedUser != null){
           userObj=[select id,Profile.Name,CWS_Region__c from user where id=:loggedUser];
       }
       List<Database.SaveResult> nresults = new List<Database.SaveResult>();
       try{
       Contract con = [Select Id, CWS_ConversionType__c, CWS_TransactionReason__c, CWS_Quote_SubType__c,CWS_Re_Contract_Type__c,Account.CWS_Region__c,CWS_Created_By_AMCont__c from Contract where Id =:conId limit 1];
       con.CWS_ConversionType__c = conversion;
       con.CWS_TransactionReason__c = trans;
       con.CWS_Quote_SubType__c = status;
       con.CWS_Re_Contract_Type__c = recontract;
       if(con.Accountid!=null && con.Account.CWS_Region__c != null){
       AccRegion=con.Account.CWS_Region__c;
       }
       if(AccRegion!=null && userObj!=null){
       CreatedbyAM=UserCheckAM(AccRegion,userObj);
       }
       if(CreatedbyAM!=null){
       con.CWS_Created_By_AMCont__c=CreatedbyAM;
       }
       Database.SaveResult result = Database.update(con, true);
           if(result.isSuccess()){
               errMsg = true;
           }    
       nresults.add(result);    
       CWS_ExceptionHandler.logDMLSaveResults(nresults, 'CWS_TransactionReasonController' , 'updateRecord','update contract', null , null );    
       }
       catch(exception e){
           CWS_ExceptionHandler.logException( e,'Contract' , 'CWS_TransactionReasonController', 'updateRecord' , '', null, null , 'updateRecord' , null);
           throw new AuraHandledException('Exception occurred while Running this class : '+ e.getMessage());
       }
       return errMsg;
       //return true;
   }

@AuraEnabled 
   public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
       String controllingField = contrfieldApiName.toLowerCase();
       String dependentField = depfieldApiName.toLowerCase();
       
       Map<String,List<String>> objResults = new Map<String,List<String>>();
       try{
       Schema.sObjectType objType = objDetail.getSObjectType();
       if (objType==null){
           return objResults;
       }
       
       Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
       
       if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
           return objResults;     
       }
       
       Schema.SObjectField theField = objFieldMap.get(dependentField);
       Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
       
       List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
       List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
       List<String> controllingValues = new List<String>();
       
       for (Schema.PicklistEntry ple : contrEntries) {
           String label = ple.getValue();
            if(label!='New'&&label!='Renewal'&&label!='Renewal with change'){
           objResults.put(label, new List<String>());
           controllingValues.add(label);
           }   
       }
       
       for (PicklistEntryWrapper plew : depEntries) {
           String label = plew.label;
           String validForBits = base64ToBits(plew.validFor);
           for (Integer i = 0; i < validForBits.length(); i++) {
               String bit = validForBits.mid(i, 1);
               if (bit == '1') {
                   objResults.get(controllingValues.get(i)).add(label);
               }
           }
       }
   }
       catch(exception e){
           CWS_ExceptionHandler.logException( e,'Contract' , 'CWS_TransactionReasonController', 'getDependentMap' , '', null, null , 'getDependentMap' , null);
           throw new AuraHandledException('Exception occurred while Running this class : '+ e.getMessage());
       }
       return objResults;
   }
   
   public static String decimalToBinary(Integer val) {
       String bits = '';
       while (val > 0) {
           Integer remainder = Math.mod(val, 2);
           val = Integer.valueOf(Math.floor(val / 2));
           bits = String.valueOf(remainder) + bits;
       }
       return bits;
   }
   
   public static String base64ToBits(String validFor) {
       if (String.isEmpty(validFor)) return '';
       
       String validForBits = '';
       
       for (Integer i = 0; i < validFor.length(); i++) {
           String thisChar = validFor.mid(i, 1);
           Integer val = base64Chars.indexOf(thisChar);
           String bits = decimalToBinary(val).leftPad(6, '0');
           validForBits += bits;
       }
       
       return validForBits;
   }
   
   private static final String base64Chars = '' +
       'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
       'abcdefghijklmnopqrstuvwxyz' +
       '0123456789+/';
   
   
   private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
       return (List<PicklistEntryWrapper>)
           JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
   }
   
   public class PicklistEntryWrapper{
       public String active {get;set;}
       public String defaultValue {get;set;}
       public String label {get;set;}
       public String value {get;set;}
       public String validFor {get;set;}
       public PicklistEntryWrapper(){            
       }
       
   }
}