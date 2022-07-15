/*Class Name: CWS_LeadTriggerHelper
*Description: Helper Class for CWS_LeadTriggerHandler
*Created By: Ankit
*Created On: 4/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                 4/13/2020        BED-667     Default Campaign on Sales generated campaign
*Sudhir Moturu         4/16/2020        BED-541                 Update recordtype on status change
*Ankit                 5/18/2020        BED-8302    Default RTM value based on the account type of portal user
*Ankit                 6/5/2020         BED-12054   Get the Disty/Reseller account ID to further identify the distributor rep related lead to populate RTM
*Ankit                 6/10/2020        BED-9124    Send Email to predferred  Disty for reseller business and onboarding reseller lead
*Sudhir Moturu         4/16/2020        BED-8704                 Populating buinsess development rep with lead owner when user is tele sales and status is MQL or SAL
*Sudhir Moturu         7/13/2020        BED-8624                 Populating lead converted status with lead status
*Sudhir Moturu         7/17/2020        BED-12433                Populating buinsess development rep with lead owner when profile is tele sales
*Sudhir Moturu          02/OCT/2020     14003326                Modified BDR logic to populate AM and DAM
*Divyanshu             5/26/2021        OBD-409                 Added the logic that Lead source should not be a default value if created by Marketo
*/
public class CWS_LeadTriggerHelper{

    /*
   * Method name  : beforeInserLogic
   * Description  : Use this method to write the before insert logic
   * Parameter    : List of new Account.
   * Return Type  : None
   * Developer    : Ankit
   */

   public static void beforeInserLogic(list<SObject> NewSObjectRecs){ 
       
       User loggedinUser;
       string currentUserId = UserInfo.getUserId();
       Map<Id,User> mapUsers = new Map<Id,User>();//BED-12433
       Set<Id> setUserIds = new Set<Id>();//BED-12433
       String distyAccId;
       List<String> emailDomain =new List<String>();
      // CWS_TerritoryRegionHelper insta = new CWS_TerritoryRegionHelper();
       //insta.territoryRegionWrapper wrap = new insta.territoryRegionWrapper();
       list<Lead> newRecs = (list<Lead>) NewSObjectRecs;
       // 874 : Get Country, State, Zip Code driven Territory, Region Mapping
       map<String, CWS_Country_Territory_Region_Mapping__mdt> terRegMap = CWS_TerritoryRegionHelper.getTerritoryRegion();
       string key;
       string countryCode;
       string stateCode;

       for(Lead objLead: newRecs){
           //BED-12433 
           if(String.isNotBlank(objLead.OwnerId) 
           && (objLead.Status==CWS_ConstantClass.LEAD_STATUS_MQL || objLead.Status==CWS_ConstantClass.LEAD_STATUS_SAL)){
               setUserIds.add(objLead.OwnerId);
           }
       }
       setUserIds.add(UserInfo.getUserId());
       //Start : BED-7826 changes.Getting the loggedin user to check if the lead is created by portal Rep
       //BED-12433
       
       if(setUserIds.size()>0){
           mapUsers.putAll([Select id,CWS_Type__c,Profile.Name,AccountId,email,name,account.CWS_Is_Distributor__c,account.CWS_Is_IIT_Reseller__c,
           IsPortalEnabled,account.CWS_Preferred_Distributor__c from User where id IN :setUserIds]);
       }
       
       //BED-12433
       if(mapUsers.size()>0 && mapUsers.containsKey(UserInfo.getUserId()) 
       && mapUsers.get(UserInfo.getUserId()).IsPortalEnabled){
           loggedinUser = mapUsers.get(UserInfo.getUserId());
           distyAccId = loggedinUser.AccountId;
       }
       
       //End : BED-7826 changes
       try{
           // Default Lead Source Related fields whenever the Lead is generated manually
           for(Lead lead: newRecs){
               //BED-8102 default email domain from Email field
               if(String.isNotBlank(lead.Email)){
                   emailDomain = lead.Email.split(CWS_ConstantClass.EmailDomain);
                   lead.CWS_Email_Domain__c = emailDomain[1];
               }
               //BED-7678 changes 
               if(distyAccId != null){
                   //Start : BED-7871 populating channel rep email id on lead so that
                   //it can be used when opp is created by lead conversion and channel rep lead owner gets notified 
                   lead.CWS_Channel_Rep_Email__c = loggedinUser.email;
                   lead.CWS_Channel_Rep_Name__c = loggedinUser.name;
                   //Endv : BED-7871
                   lead.CWS_Distributor__c = distyAccId; //BED-7826
                   lead.LeadSource = CWS_ConstantClass.LEAD_CHANNEL_GENERATED;
                  // lead.CWS_Lead_Source_Most_Recent__c = CWS_ConstantClass.LEAD_CHANNEL_GENERATED;
                   lead.CWS_Lead_Source_Details__c = CWS_ConstantClass.LEAD_SOURCE_DETAILS + UserInfo.getName();
                   //lead.CWS_Lead_Source_Details_Most_Recent__c = CWS_ConstantClass.LEAD_SOURCE_DETAILS + UserInfo.getName();
                   //START: BED-8302 -> Defaulting RTM value when Partner User Creates a Lead
                   if(loggedinUser.account.CWS_Is_Distributor__c){
                       lead.CWS_Route_To_Market__c = (lead.CWS_X2_Tier__c == true ? CWS_ConstantClass.RTM_Value_IIT : CWS_ConstantClass.RTM_Value_Channel);
                   }else if(loggedinUser.account.CWS_Is_IIT_Reseller__c){
                       lead.CWS_Route_To_Market__c = CWS_ConstantClass.RTM_Value_IIT;
                       if(loggedinUser.account.CWS_Preferred_Distributor__c != null){
                           lead.CWS_Preferred_Distributor__c = loggedinUser.account.CWS_Preferred_Distributor__c;
                       }
                   }
                   //END: BED-8302
                   
               }//BED-7678 changes end
                else if((lead.LeadSource == null && lead.CWS_Lead_Source_Details__c == null && currentUserId != system.label.CWS_Marketo_User_Id) ||
                  (lead.LeadSource == CWS_ConstantClass.LEAD_SALES_GENERATED)){
                  lead.LeadSource = CWS_ConstantClass.LEAD_SALES_GENERATED;
                  //lead.CWS_Lead_Source_Most_Recent__c = CWS_ConstantClass.LEAD_SALES_GENERATED;
                  lead.CWS_Lead_Source_Details__c = CWS_ConstantClass.LEAD_SOURCE_DETAILS + UserInfo.getName();
                  //lead.CWS_Lead_Source_Details_Most_Recent__c = CWS_ConstantClass.LEAD_SOURCE_DETAILS + UserInfo.getName();                   

               }//BED-12828 start
               if(lead.LeadSource == CWS_ConstantClass.LEAD_CHANNEL_GENERATED){
                   lead.CWS_Lead_Source_Details__c = CWS_ConstantClass.LEAD_SOURCE_DETAILS + UserInfo.getName();
               }//BED-12828 End	
               countryCode='';
               stateCode='';
               //874 : Populate Region and Territory
               if(lead.CountryCode!=Null ){
                   countryCode=lead.CountryCode;
               }
               else if(!String.isBlank(lead.country) && CWS_TerritoryRegionHelper.countryCodeMap.get(lead.country) !=Null){
                   // This block is specific to Marketo creating Leads in Salesforce.
                   countryCode = CWS_TerritoryRegionHelper.countryCodeMap.get(lead.country);
               }
               if(lead.StateCode !=Null){
                   stateCode=lead.stateCode;
               }else if(!String.isBlank(lead.state) && CWS_TerritoryRegionHelper.StateCodeMap.get(lead.state) !=Null){
                   // This block is specific to Marketo creating Leads in Salesforce.
                   stateCode = CWS_TerritoryRegionHelper.StateCodeMap.get(lead.state);
               }
               if(countryCode!= Null){
                   key=CWS_TerritoryRegionHelper.getTerrRegionKey(countryCode,stateCode,lead.postalCode);
                   if( terRegMap.get(key) != Null){
                       lead.CWS_Region__c =terRegMap.get(key).CWS_Region__c;
                       lead.CWS_Territory__c =terRegMap.get(key).CWS_Territory__c;
                       lead.CWS_No_Territory_Mapping_Found__c=false;
                   }
                   else{
                       lead.CWS_Region__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Region__c;
                       lead.CWS_Territory__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Territory__c;
                       lead.CWS_No_Territory_Mapping_Found__c=True;
                   }
                   
               } 
               //BED-8704 populating Business Development Rep field with owner if profile is tele sales and lead status is MQL or SAL
               //BED-12433
               if(mapUsers.containsKey(lead.ownerid) && (mapUsers.get(lead.ownerid).Profile.Name==CWS_ConstantClass.PROFILE_TELE_SALES 
               || mapUsers.get(lead.ownerid).CWS_Type__c == CWS_ConstantClass.USER_TYPE_AM || mapUsers.get(lead.ownerid).CWS_Type__c == CWS_ConstantClass.USER_TYPE_DAM)
               && (lead.Status==CWS_ConstantClass.LEAD_STATUS_MQL || lead.Status==CWS_ConstantClass.LEAD_STATUS_SAL)){
                   lead.CWS_Business_Development_Rep__c = lead.ownerid;        
               }
               //BED-8624 populating Lead Converted Status populating
               if(String.isNotBlank(lead.Status)){
                   if(lead.Status==CWS_ConstantClass.LEAD_STATUS_CONVERTED){
                       lead.CWS_Lead_Converted_Status__c=CWS_ConstantClass.LEAD_SQO_ACCEPTED;
                   }else{
                       lead.CWS_Lead_Converted_Status__c = lead.Status;       
                   }     
               }
               //BED -12861
               if(lead.LeadSource == CWS_ConstantClass.LEAD_CHANNEL_GENERATED){
                   lead.status=CWS_ConstantClass.LEAD_STATUS_MQL;
               }
           }
       }catch(Exception e){
           CWS_ExceptionHandler.logException( e,'Lead' , 'CWS_LeadTriggerHelpher', 'BeforeInsertMethod' , '', null, null , 'Before Insert' , null);
       }
   }

  /*
   * Method name  : afterInserLogic
   * Description  : Use this method to write the after insert logic
   * Parameter    : List of new Account.
   * Return Type  : None
   * Developer    : Ankit
   */
   
   public static void afterInserLogic(list<SObject> NewSObjectRecs){    
       try{
           list<Lead> newRecs = (list<Lead>) NewSObjectRecs;
           list<campaignMember> campMemberList = new list<campaignMember>();
           
           Integer queryLimit = integer.valueOf(CWS_ConstantClass.LIMIT_TWO);
           
           //String campId = '';
           Map<String,String> cmpnNameIdMap = new Map<String,String>();
           //Fetch campaign to assign manually generated leads
           if(Label.CWS_Channel_Generated_Campaign != null && Label.CWS_Sales_Generated_Cammpaign != null){
               for(campaign cmpn: [Select id, name from campaign where IsActive = true And (name =: Label.CWS_Sales_Generated_Cammpaign
                                   OR name =:Label.CWS_Channel_Generated_Campaign) LIMIT: queryLimit]){                                    
                   cmpnNameIdMap.put(cmpn.name , cmpn.Id);
               }   
           }
           
           //Start: BED-9124 Get the Disty/Reseller account ID to further identify the distributor rep related lead 
           set<id> resellerIdSet = new set<id>();
           for(Lead objLead: newRecs){
               if(objLead.CWS_Distributor__c != null){
                   resellerIdSet.add(objLead.CWS_Distributor__c);
               }
           }
           set<id> resellerAccsSet = new set<id>();
           if(resellerIdSet != null){
               for(Account acc : [Select id from Account where id IN: resellerIdSet and CWS_Is_IIT_Reseller__c = true]){
                   resellerAccsSet.add(acc.id);
               }
           }
           
           set<string> prefDistySet = new set<string>(); 
           //End BED-9124
                   
           //Create campaign members for the leads which are sales generated
           //BED-7678 -start
           for(Lead lead: newRecs){
           
               //Start BED-9124
               if((lead.CWS_Distributor__c != null && 
                  resellerAccsSet != null && 
                  resellerAccsSet.contains(lead.CWS_Distributor__c) || 
                  lead.LeadSource == CWS_ConstantClass.LEAD_ON_BOARDING) &&
                  lead.CWS_Preferred_Distributor__c != null){
                  prefDistySet.add(lead.CWS_Preferred_Distributor__c);
               }
               //End BED-9124
           
           
               if((lead.LeadSource == CWS_ConstantClass.LEAD_SALES_GENERATED || 
                    lead.LeadSource == CWS_ConstantClass.LEAD_CHANNEL_GENERATED) 
                     && !cmpnNameIdMap.isEmpty()){
                   campaignMember campMemObj = new campaignMember();
                   campMemObj.campaignId = lead.LeadSource == CWS_ConstantClass.LEAD_SALES_GENERATED ? cmpnNameIdMap.get(Label.CWS_Sales_Generated_Cammpaign) : cmpnNameIdMap.get(Label.CWS_Channel_Generated_Campaign);
                   campMemObj.LeadId = lead.id;
                   campMemberList.add(campMemObj);
               }
           }//BED-7678 -End
           
           //Start BED-9124
           map<string,list<string>> mapofPrefDisty = new map<string,list<string>>();
           if(prefDistySet != null){
               for(User usr: [Select id,email,Account.CWS_Distributor_Identifier__c
                                     from 
                                     User 
                                     where Account.CWS_Distributor_Identifier__c IN: prefDistySet and IsActive = true]){
                   if(mapofPrefDisty.containskey(usr.Account.CWS_Distributor_Identifier__c)){
                       mapofPrefDisty.get(usr.Account.CWS_Distributor_Identifier__c).add(usr.email);
                   }else{
                       mapofPrefDisty.put(usr.Account.CWS_Distributor_Identifier__c,new list<string>{usr.email});
                   }
               }
               
               if(mapofPrefDisty != null){
                   
                   id prefID;
                   id onBoardingID;
                   
                   for(EmailTemplate email: [select id,DeveloperName 
                              from 
                              EmailTemplate 
                              where 
                              DeveloperName =: Label.CWS_Preferred_Disty_email_template_name OR DeveloperName =: Label.CWS_Onboarding_Pref_Disty_Email_Template]){
                       if(email.DeveloperName == Label.CWS_Preferred_Disty_email_template_name){
                           prefID = email.id;
                       }else{
                           onBoardingID = email.id;
                       }
                   }
                   
                   List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
                   for(Lead lead: newRecs){
                       if(mapofPrefDisty.containsKey(lead.CWS_Preferred_Distributor__c) &&
                           mapofPrefDisty.get(lead.CWS_Preferred_Distributor__c) != null){
                           Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                           if(lead.LeadSource == CWS_ConstantClass.LEAD_CHANNEL_GENERATED){
                               msg.setTemplateId(prefID);
                           }else if(lead.LeadSource == CWS_ConstantClass.LEAD_ON_BOARDING){
                               msg.setTemplateId(onBoardingID);
                           }
                           msg.setTargetObjectId(lead.id);
                           msg.setToAddresses(mapofPrefDisty.get(lead.CWS_Preferred_Distributor__c));
                           msgList.add(msg);
                           // Send the emails in a transaction, then roll it back
                           Savepoint sp = Database.setSavepoint();
                           Messaging.sendEmail(msgList); // Dummy email send
                           Database.rollback(sp); // Email will not send as it is rolled Back
                       }
                   }
                   
                   List<Messaging.SingleEmailMessage> msgListToBeSend = new List<Messaging.SingleEmailMessage>();
                   for (Messaging.SingleEmailMessage email : msgList) {
                       Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                       emailToSend.setToAddresses(email.getToAddresses());
                       emailToSend.setPlainTextBody(email.getPlainTextBody());
                       emailToSend.setHTMLBody(email.getHTMLBody());
                       emailToSend.setSubject(email.getSubject());
                       msgListToBeSend .add(emailToSend);
                   }
                   //Actual Email Sending by below method
                   Messaging.sendEmail(msgListToBeSend);
               }
               
           }
           //End BED-9124
                       
           //Insert Campaign members 
           if(campMemberList != null && campMemberList.size()>0){                
               insert campMemberList;
           }
           
       }catch(Exception e){
           CWS_ExceptionHandler.logException( e,'Lead' , 'CWS_LeadTriggerHelpher', 'AfterInsertMethod' , '', null, null , 'AfterInsert' , null);
       }
   }

   /*
   * Method name  : beforeUpdateLogic
   * Description  : BED-541 Update record type based on status
   * Parameter    : Map of Old and New Leads.
   * Return Type  : None
   * Developer    : Sudhir Moturu
   */
   public static void beforeUpdateLogic(Map<Id, Lead> mapNewRecds, Map<Id, Lead> mapOldRecds){    
       try{
           Lead objOldLead;
           List<String> emailDomain = new List<String>();
           //Lead edit and read recordtype ids
           String sReadRTId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(CWS_ConstantClass.LEAD_RT_API_READ).getRecordTypeId();
           String sEditRTId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(CWS_ConstantClass.LEAD_RT_API_EDIT).getRecordTypeId();
          // 874 : Get Country, State, Zip Code driven Territory, Region Mapping
           map<String, CWS_Country_Territory_Region_Mapping__mdt> terRegMap = CWS_TerritoryRegionHelper.getTerritoryRegion();
           string key;
           string countryCode;
           string stateCode;
           Map<Id,User> mapUsers = new Map<Id,User>();//BED-12433
           Set<Id> setUserIds = new Set<Id>();//BED-12433

           //Start: BED-12054 Get the Disty/Reseller account ID to further identify the distributor rep related lead 
           set<id> distyIdSet = new set<id>();
           for(Lead objLead: mapNewRecds.Values()){
               if(objLead.CWS_Distributor__c != null){
                   distyIdSet.add(objLead.CWS_Distributor__c);
               }
               //BED-8624 populating Lead Converted Status populating
               if(objLead.Status != mapOldRecds.get(objLead.Id).Status){
                   if(objLead.Status==CWS_ConstantClass.LEAD_STATUS_CONVERTED){
                       objLead.CWS_Lead_Converted_Status__c=CWS_ConstantClass.LEAD_SQO_ACCEPTED;
                   }else{
                       objLead.CWS_Lead_Converted_Status__c = objLead.Status;        
                   }  
               }
               //BED-12433 
               if(String.isNotBlank(objLead.OwnerId) && (String.isBlank(objLead.CWS_Business_Development_Rep__c) || objLead.OwnerId != mapOldRecds.get(objLead.Id).OwnerId)
               && (objLead.Status==CWS_ConstantClass.LEAD_STATUS_MQL || objLead.Status==CWS_ConstantClass.LEAD_STATUS_SAL)){
                   setUserIds.add(objLead.OwnerId);
               }
           }
           set<id> rtmDistIDSet = new set<id>();
           if(distyIdSet != null){
               for(Account acc : [Select id from Account where id IN: distyIdSet and CWS_Is_Distributor__c = true]){
                   rtmDistIDSet.add(acc.id);
               }
           }
           //End BED-12054
           //BED-12433 
           if(setUserIds.size()>0){
               mapUsers.putAll([Select id,CWS_Type__c,Profile.Name from User where id IN :setUserIds]);
           }
           //Iteration for read only and edit recordtype assignment based on status
           for(Lead objLead: mapNewRecds.Values()){
               objOldLead = mapOldRecds.get(objLead.Id);
               
               //Start 8302 : Change the RTM when the status is changed
               if(objLead.CWS_X2_Tier__c != objOldLead.CWS_X2_Tier__c){
                   //Start: BED-12054 Identify if the lead is created by Disty Rep
                   if(rtmDistIDSet != null && rtmDistIDSet.contains(objLead.CWS_Distributor__c)){      
                   //End BED-12054             
                       objLead.CWS_Route_To_Market__c = (objLead.CWS_X2_Tier__c == true ? CWS_ConstantClass.RTM_Value_IIT : CWS_ConstantClass.RTM_Value_Channel);
                   }
               }
               //End 8302 : 
               
               //BED-8102 Update Email domain from Email
               if(objLead.Email != objOldLead.Email && String.isNotBlank(objLead.Email)){
                   emailDomain = objLead.Email.split(CWS_ConstantClass.EmailDomain);
                   objLead.CWS_Email_Domain__c = emailDomain[1];
               }
               //Record type assignemt when status is changed
               if(objLead.Status != objOldLead.Status){
                   //Read only recordtype assignment if status is rejected or recycled 
                   if((objLead.Status == CWS_ConstantClass.LEAD_STATUS_REJECTED || objLead.Status == CWS_ConstantClass.LEAD_STATUS_RECYCLED)
                       && objLead.RecordTypeId!=sReadRTId){
                       objLead.RecordTypeId = sReadRTId;
                   } 
                   //Edit recordtype assignment if status is not rejected and recycled
                   if((objLead.Status != CWS_ConstantClass.LEAD_STATUS_REJECTED && objLead.Status != CWS_ConstantClass.LEAD_STATUS_RECYCLED)
                       && objLead.RecordTypeId!=sEditRTId){
                       objLead.RecordTypeId = sEditRTId;
                   }
               }
               countryCode='';
               stateCode='';
               //Start 874 : Populate Region and Territory
               if(objLead.CountryCode!=Null && objOldLead.CountryCode != objLead.CountryCode){
                   countryCode = objLead.CountryCode;
               }
               else if(!String.isBlank(objLead.country) && objOldLead.country != objLead.country
                               && CWS_TerritoryRegionHelper.countryCodeMap.get(objLead.country) !=Null){
                   // This block is specific to Marketo creating Leads in Salesforce.
                   countryCode = CWS_TerritoryRegionHelper.countryCodeMap.get(objLead.country);
               }
               if(objLead.StateCode !=Null && objOldLead.StateCode != objLead.StateCode){
                   stateCode=objLead.stateCode;
                   countryCode = objLead.CountryCode;
               }else if(!String.isBlank(objLead.state) && objOldLead.state != objLead.state
                               && CWS_TerritoryRegionHelper.StateCodeMap.get(objLead.state) !=Null){
                   // This block is specific to Marketo creating Leads in Salesforce.
                   stateCode = CWS_TerritoryRegionHelper.StateCodeMap.get(objLead.state);
                   countryCode = CWS_TerritoryRegionHelper.countryCodeMap.get(objLead.country);
               }
               if(countryCode!=Null && countryCode !=''){
                   key=CWS_TerritoryRegionHelper.getTerrRegionKey(countryCode,StateCode,objLead.postalCode);
                   if( terRegMap.get(key) != Null){
                       objLead.CWS_Region__c =terRegMap.get(key).CWS_Region__c;
                       objLead.CWS_Territory__c =terRegMap.get(key).CWS_Territory__c;
                       objLead.CWS_No_Territory_Mapping_Found__c=false;
                   }
                   else{
                       objLead.CWS_Region__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Region__c;
                       objLead.CWS_Territory__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Territory__c;
                       objLead.CWS_No_Territory_Mapping_Found__c=True;
                   }
                   
               }
               //End 874
               //BED-8704 populating Business Development Rep field with owner if profile is tele sales and lead status is MQL or SAL
               //BED-12433
               if(mapUsers.containsKey(objLead.OwnerId) && (String.isBlank(objLead.CWS_Business_Development_Rep__c) || objLead.OwnerId != objOldLead.OwnerId)
               && (mapUsers.get(objLead.OwnerId).Profile.Name == CWS_ConstantClass.PROFILE_TELE_SALES || mapUsers.get(objLead.ownerid).CWS_Type__c == CWS_ConstantClass.USER_TYPE_AM || mapUsers.get(objLead.ownerid).CWS_Type__c == CWS_ConstantClass.USER_TYPE_DAM)
               && (objLead.Status==CWS_ConstantClass.LEAD_STATUS_MQL || objLead.Status==CWS_ConstantClass.LEAD_STATUS_SAL)){
                   objLead.CWS_Business_Development_Rep__c = objLead.ownerid;        
               }
           }
       } catch(Exception e){
           CWS_ExceptionHandler.logException( e,'Lead' , 'CWS_LeadTriggerHelper', 'beforeUpdateLogic' , '', null, null , 'BeforeUpdate' , null);
       }
   }
}