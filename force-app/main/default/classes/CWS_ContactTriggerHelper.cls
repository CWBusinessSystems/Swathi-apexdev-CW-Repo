/*Class Name: CWS_ContactTriggerHelper
*Description: Helper Class for CWS_ContactTriggerHandler
*Created By: Sudhir Moturu
*Created On: 05/MAY/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Sudhir Moturu          05/MAY/2020     BED-6452                Update recordtype on status change
*Abhishek          		28/MAY/2020     BED-5761                Contact Sync update on Account
*Sudhir Moturu          19/JUN/2020     BED-8704                Populating buinsess development rep with contact owner when user is tele sales and status is MQL or SAL
*Sudhir Moturu          17/JUL/2020     BED-12433               Populating buinsess development rep with lead owner when profile is tele sales
*Sudhir Moturu          27/OCT/2020                             Changed callout from Future to Queueable
*Sudhir Moturu          02/OCT/2020     14003326                Modified BDR logic to populate AM and DAM
*Raja Mouthkapally		4/27/2020		OBD-107					14428826 - Field Marketing Task Enhancements
*Carl Shahan            09/10/2021      OBD-224                 Added isFuture and isQueueable line ~470 to help prevent duplicate contacts
*Carl Shahan            11/10/2021      OBD-224                 Added update to CWS_Manage_New_Contact__c = false in beforeUpdateLogic() for Boomi duplicate contacts
*/
public without sharing class CWS_ContactTriggerHelper {
    /*
    * Method name  : beforeInserLogic
    * Description  : Use this method to write the before insert logic
    * Parameter    : List of new Contacts.
    * Return Type  : None
    * Developer    : Sudhir Moturu
    */
	public static list<Id> ids = new list<Id>();//9325
    public static void beforeInsertLogic(list<Contact> lstNewRecds){ 
        try{
            Map<Id,Boolean> mapPriBillConAcct =  new Map<Id,Boolean>();//Map of account Ids and check for primary billing contact
            Map<Id,Boolean> mapPriConAcct =  new Map<Id,Boolean>();//Map of account Ids and check for primary contact
            List<Contact> lstAllContacts = new List<Contact>();
            List<String> emailDomain =new List<String>();
             // 874 : Get Country, State, Zip Code driven Territory, Region Mapping
             map<String, CWS_Country_Territory_Region_Mapping__mdt> terRegMap = CWS_TerritoryRegionHelper.getTerritoryRegion();
             string key; 
            Map<Id,User> mapUsers = new Map<Id,User>();//BED-12433
            Set<Id> setUserIds = new Set<Id>();//BED-12433

            //Loop can be reused for inserted contacts
            for(Contact objCon: lstNewRecds){
            	
            	//BED-8102 default email domain from Email field
            	if(String.isNotBlank(objCon.Email)){
            		emailDomain = objCon.Email.split(CWS_ConstantClass.EmailDomain);
            		objCon.CWS_Email_Domain__c = emailDomain[1];
            	}
                //Filtering account ids which have one primary billing contact selected
                if(objCon.AccountId!=null && objCon.CWS_Primary_Billing_Contact__c){
                    if(mapPriBillConAcct.containsKey(objCon.AccountId)){
                        mapPriBillConAcct.put(objCon.AccountId,true);
                    } else {
                        mapPriBillConAcct.put(objCon.AccountId,false);
                    }
                }
                //Filtering account ids which have one primary contact selected
                if(objCon.AccountId!=null &&  objCon.CWS_Primary_Contact__c){
                    if(mapPriConAcct.containsKey(objCon.AccountId)){
                        mapPriConAcct.put(objCon.AccountId,true);
                    } else {
                        mapPriConAcct.put(objCon.AccountId,false);
                    }
                }
                //Start 874 : Populate Region and Territory
                if(objCon.mailingcountryCode!=Null){
                    key=CWS_TerritoryRegionHelper.getTerrRegionKey(objCon.mailingcountryCode,objCon.mailingStateCode,objCon.mailingPostalCode);
                    if( terRegMap.get(key) != Null){
                        objCon.CWS_Region__c =terRegMap.get(key).CWS_Region__c;
                        objCon.CWS_No_Territory_Mapping_Found__c=false;
                    }
                    else{
                        objCon.CWS_Region__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Region__c;
                        objCon.CWS_No_Territory_Mapping_Found__c=true;
                    }
                }
                //End 874

                //BED-12433 
                if(String.isNotBlank(objCon.OwnerId)  
                && (objCon.CWS_Contact_Status__c==CWS_ConstantClass.CONTACT_STATUS_MQL || objCon.CWS_Contact_Status__c==CWS_ConstantClass.CONTACT_STATUS_SAL)){
                    setUserIds.add(objCon.OwnerId);
                }
            }

            //BED-12433
            if(setUserIds.size()>0){
                mapUsers.putAll([Select id,CWS_Type__c,Profile.Name from User where id IN :setUserIds]);
            }

            //SOQL can be changed for other logic 
            //Retrieve all contacts related to account which have primary billing and primary contact present
            if(mapPriBillConAcct.size()>0){
                lstAllContacts = [Select Id,AccountId,CWS_Primary_Billing_Contact__c from Contact 
                                where AccountId IN :mapPriBillConAcct.keySet() AND AccountId!=null AND CWS_Primary_Billing_Contact__c=true];
            }
            //Loop can be reused for other logic on retrieved contacts  
            if(lstAllContacts.size()>0){
                for(Contact objCon: lstAllContacts){
                    //Filtering all Account ids which have primary billing contact
                    if(mapPriBillConAcct.containsKey(objCon.AccountId) && objCon.CWS_Primary_Billing_Contact__c){
                        mapPriBillConAcct.put(objCon.AccountId,true);
                    }
                }
            }
            //Loop can be reused for inserted contacts
            for(Contact objCon: lstNewRecds){
                if(objCon.AccountId!=null){
                    //Throw error if account has already a primary billing contact
                    if(objCon.CWS_Primary_Billing_Contact__c && mapPriBillConAcct.containsKey(objCon.AccountId) && mapPriBillConAcct.get(objCon.AccountId)){
                        objCon.addError(Label.CWS_PrimaryBillContact_Error);
                    }
                    //Throw error if account has already a primary contact
                    if(objCon.CWS_Primary_Contact__c && mapPriConAcct.containsKey(objCon.AccountId) && mapPriConAcct.get(objCon.AccountId)){
                        objCon.addError(Label.CWS_PrimaryContact_Error);
                    } 
                }
                //BED-8704 populating Business Development Rep field with owner if profile is tele sales and contact status is MQL or SAL
                //BED-12433
                if(mapUsers.containsKey(objCon.OwnerId) && (mapUsers.get(objCon.OwnerId).Profile.Name==CWS_ConstantClass.PROFILE_TELE_SALES 
                || mapUsers.get(objCon.ownerid).CWS_Type__c == CWS_ConstantClass.USER_TYPE_AM || mapUsers.get(objCon.ownerid).CWS_Type__c == CWS_ConstantClass.USER_TYPE_DAM)
                && (objCon.CWS_Contact_Status__c==CWS_ConstantClass.CONTACT_STATUS_MQL || objCon.CWS_Contact_Status__c==CWS_ConstantClass.CONTACT_STATUS_SAL)){
                    objCon.CWS_Business_Development_Rep__c = objCon.ownerid;        
                }
            }        
            
        } catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Contact' , 'CWS_ContactTriggerHelper', 'beforeInsertLogic' , '', null, null , 'BeforeInsert' , null);
        }
    }
    /*
    * Method name  : afterInserLogic
    * Description  : Use this method to write the after insert logic
    * Parameter    : Map of new Contacts.
    * Return Type  : None
    * Developer    : Sudhir Moturu
    */
    public static void afterInsertLogic(Map<Id, Contact> mapNewRecds){ 
        try{
            Set<Id> setPriConAcct =  new Set<Id>();//Set of account Ids and check for primary contact
            List<Contact> lstAllContacts = new List<Contact>();
            List<Contact> lstContsToUpdate = new List<Contact>();//List of primary contacts which needs to be updated to be made non primary
            List<Database.SaveResult> srList;//Stores the update result

            //Loop can be reused for inserted contacts
            for(Contact objCon: mapNewRecds.values()){
                //Filtering account ids which have one primary contact selected
                if(objCon.AccountId!=null && objCon.CWS_Primary_Contact__c){
                    setPriConAcct.add(objCon.AccountId);
                }
				//9325
				if(objCon.CWS_Manage_Account_Id__c!=null){
                    ids.add(objCon.Id);
                }
            }
            //SOQL can be changed for other logic 
            //Retrieve all contacts related to account which have primary billing and primary contact present
            if(setPriConAcct.size()>0){
                lstAllContacts = [Select Id,AccountId,CWS_Primary_Contact__c from Contact 
                            where AccountId IN :setPriConAcct AND AccountId!=null AND CWS_Primary_Contact__c=true];
            }
            //Loop can be reused for other logic on retrieved contacts 
            if(lstAllContacts.size()>0){
                for(Contact objCon: lstAllContacts){
                    //Filtering all Account ids which have primary billing contact
                    if(setPriConAcct.contains(objCon.AccountId) 
                    && !mapNewRecds.containsKey(objCon.Id)
                    && objCon.CWS_Primary_Contact__c){
                        objCon.CWS_Primary_Contact__c = false;
                        lstContsToUpdate.add(objCon);
                    }
                }
            } 
            if(lstContsToUpdate.size()>0){
                srList = Database.update(lstContsToUpdate);
                CWS_ExceptionHandler.logDMLSaveResults(srList, 'CWS_ContactTriggerHelper' , 'beforeInsert','Update Contacts', null , null );
            }
			 // BED 9325 
             if(ids.size()==1){
                callManageIntegration(Ids);
            }
        } catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Contact' , 'CWS_ContactTriggerHelper', 'beforeInsertLogic' , '', null, null , 'BeforeInsert' , null);
        }
    }

    /*
    * Method name  : beforeUpdateLogic
    * Description  : Use this method to write the before update logic
    * Parameter    : Map of Old and New Contacts.
    * Return Type  : None
    * Developer    : Sudhir Moturu
    */
    public static void beforeUpdateLogic(Map<Id, Contact> mapNewRecds, Map<Id, Contact> mapOldRecds){    
    
        try{
            Map<Id,Boolean> mapPriBillConAcct =  new Map<Id,Boolean>();//Map of account Ids and check for primary billing contact
            Map<Id,Boolean> mapPriConAcct =  new Map<Id,Boolean>();//Map of account Ids and check for primary contact
            Map<Id,Boolean> mapPriConUnChkAcct =  new Map<Id,Boolean>();//Map of account Ids and check for unchecked primary contact
            List<Contact> lstAllContacts = new List<Contact>();
            List<String> emailDomain =new List<String>();
            Boolean bIntegFldsCheck = false;//BED-640 Check for integration fields changed on contact
            // 874 : Get Country, State, Zip Code driven Territory, Region Mapping
            map<String, CWS_Country_Territory_Region_Mapping__mdt> terRegMap = CWS_TerritoryRegionHelper.getTerritoryRegion();
            string key; 
            Map<Id,User> mapUsers = new Map<Id,User>();//BED-12433
            Set<Id> setUserIds = new Set<Id>();//BED-12433
            Boolean manageAlreadyTriggered = !ids.isEmpty() ? true : false;
			List<Id> conIds = new List<Id>();

            //Loop can be reused for updated contacts
            for(Contact objCon: mapNewRecds.values()){
                // Only checks for Phone Direct and Email changes... email is rarely going to chage and we primarily use Preferred Phone field
                if(objCon.Email != mapOldRecds.get(objCon.id).Email || objCon.CWS_Phone_Direct__c != mapOldRecds.get(objCon.id).CWS_Phone_Direct__c){
                    conIds.add(objCon.id);
                }
            	
                // This will not fire if there has already been a Manage Account Id value assigned to Account.CWS_Manage_Company_Rec_Id__c
                //Start BED - 9325
                if(objCon.CWS_Manage_Account_Id__c!=null && !manageAlreadyTriggered){
                    for(Schema.FieldSetMember fld :Schema.SObjectType.Contact.fieldSets.CWS_ManageContactIntegration.getFields()) {
                        
                        // This is the only part that involves the Manage Sync by adding the Contact Id to the global ids variable
                        // if one of the Field Set values (CW Login Email, Active, Primary Email, Phone - Direct, Primary Billing Contact,
                        // SSO User ID, Last Name, Primary Contact, Preferred Phone, Phone - Mobile, First Name) change OR Manage Integration Sync
                        // status changes AND Manage Integration Sync = Ready For Sync
                        //Check if the field value is changed
                        if(mapNewRecds.get(objCon.id).get(fld.getFieldPath())!=mapOldRecds.get(objCon.id).get(fld.getFieldPath()) 
                        || (objCon.CWS_Manage_Integration_Sync_Status__c!=mapOldRecds.get(objCon.Id).CWS_Manage_Integration_Sync_Status__c
                            && objCon.CWS_Manage_Integration_Sync_Status__c==CWS_ConstantClass.INT_STATUS_READY)){
                            
                            System.debug('@@@CWS_ContactTriggerHelper beforeUpdateLogic fired setting CWS_Manage_New_Contact__c to false');
                            // Added this for Satya and his Boomi solution that is taking up to 20 minutes to create a Contact.
                            // If the same Contact is updated before the new Contact is created, this lets Boomi know this is an update  
                            objCon.CWS_Manage_New_Contact__c = false;
                            objCon.CWS_Manage_Integration_Sync_Status__c=CWS_ConstantClass.INT_STATUS_READY;
                            ids.add(objCon.Id);
                            break;
                        }
                    }
                }
                // End BED 9325
            	//BED-8102 update Email domain with Email field
            	if(objCon.Email != mapOldRecds.get(objCon.Id).Email ){
            		if( String.isNotBlank(objCon.Email)){
            			emailDomain = objCon.Email.split(CWS_ConstantClass.EmailDomain);
            			objCon.CWS_Email_Domain__c = emailDomain[1];
            		}
            		else if(String.isBlank(objCon.Email)){
            			objCon.CWS_Email_Domain__c = null;
            		}
            	}
            	
                if(objCon.AccountId!=null){
                    //Filtering account ids which have one primary billing contact selected else throw error for other contacts
                    if(objCon.CWS_Primary_Billing_Contact__c && objCon.CWS_Primary_Billing_Contact__c!=mapOldRecds.get(objCon.Id).CWS_Primary_Billing_Contact__c){
                        if(mapPriBillConAcct.containsKey(objCon.AccountId)){
                            mapPriBillConAcct.put(objCon.AccountId,true);
                        } else {
                            mapPriBillConAcct.put(objCon.AccountId,false);
                        }
                    }
                    //Filtering account ids which have one primary contact selected else throw error for other contacts
                    if(objCon.CWS_Primary_Contact__c && objCon.CWS_Primary_Contact__c!=mapOldRecds.get(objCon.Id).CWS_Primary_Contact__c){
                        if(mapPriConAcct.containsKey(objCon.AccountId)){
                            mapPriConAcct.put(objCon.AccountId,true);
                        } else {
                            mapPriConAcct.put(objCon.AccountId,false);
                        }
                    }
                    //Filtering accounts Ids which have primary contact uncheked
                    if(!objCon.CWS_Primary_Contact__c && objCon.CWS_Primary_Contact__c!=mapOldRecds.get(objCon.Id).CWS_Primary_Contact__c){
                        mapPriConUnChkAcct.put(objCon.AccountId,false);
                    }
                }
                //BED-640 Update the integration status to ready to sync if integration fields are changed
                /* DO NOT REMOVE - Deactivated as part of BED 5761
                bIntegFldsCheck = checkIntegFieldChange(objCon.Id,mapNewRecds,mapOldRecds);
                if(bIntegFldsCheck && 
                (objCon.CWS_Integration_Sync_Status__c == CWS_ConstantClass.INT_STATUS_ERROR
                ||objCon.CWS_Integration_Sync_Status__c == CWS_ConstantClass.INT_STATUS_SYNCED)){
                    objCon.CWS_Integration_Sync_Status__c = CWS_ConstantClass.INT_STATUS_READY;
                }*/

                 //Start 874 : Populate Region and Territory
                 if((objCon.mailingcountryCode!=Null && objCon.mailingcountryCode!=mapOldRecds.get(objCon.id).mailingcountryCode)
                    || objCon.mailingStateCode!=mapOldRecds.get(objCon.id).mailingStateCode
                    || objCon.mailingPostalCode!=mapOldRecds.get(objCon.id).mailingPostalCode){
                    key=CWS_TerritoryRegionHelper.getTerrRegionKey(objCon.mailingcountryCode,objCon.mailingStateCode,objCon.mailingPostalCode);
                    if( terRegMap.get(key) != Null){
                        objCon.CWS_Region__c =terRegMap.get(key).CWS_Region__c;
                        objCon.CWS_No_Territory_Mapping_Found__c=false;
                    }
                    else{
                        objCon.CWS_Region__c =terRegMap.get(CWS_ConstantClass.NA_KEY).CWS_Region__c;
                        objCon.CWS_No_Territory_Mapping_Found__c=true;
                    }
                }
                //End 874

                //BED-12433 
                if(String.isNotBlank(objCon.OwnerId) && (String.isBlank(objCon.CWS_Business_Development_Rep__c) || objCon.OwnerId != mapOldRecds.get(objCon.Id).OwnerId)
                && (objCon.CWS_Contact_Status__c==CWS_ConstantClass.CONTACT_STATUS_MQL || objCon.CWS_Contact_Status__c==CWS_ConstantClass.CONTACT_STATUS_SAL)){
                    setUserIds.add(objCon.OwnerId);        
                }
            }

            //BED-12433 
            if(setUserIds.size()>0){
                mapUsers.putAll([Select id,CWS_Type__c,Profile.Name from User where id IN :setUserIds]);
            }

            //SOQL can be changed for other logic 
            //Retrieve all contacts related to account which have primary billing and primary contact present
            if(mapPriBillConAcct.size()>0||mapPriConUnChkAcct.size()>0){
                lstAllContacts = [Select Id,AccountId,CWS_Primary_Billing_Contact__c,CWS_Primary_Contact__c from Contact 
                            where (AccountId IN :mapPriBillConAcct.keySet() OR AccountId IN:mapPriConUnChkAcct.keySet()) AND AccountId!=null 
                            AND (CWS_Primary_Billing_Contact__c=true OR CWS_Primary_Contact__c=true)];
            }
            //Loop can be reused for other logic on retrieved contacts 
            if(lstAllContacts.size()>0){
                for(Contact objCon: lstAllContacts){
                    if(!mapNewRecds.containsKey(objCon.Id)){
                        //Filtering all Account ids which have primary billing contact
                        if(mapPriBillConAcct.containsKey(objCon.AccountId) && objCon.CWS_Primary_Billing_Contact__c){
                            mapPriBillConAcct.put(objCon.AccountId,true);
                        }
                        if(mapPriConUnChkAcct.containsKey(objCon.AccountId) && objCon.CWS_Primary_Contact__c){
                            mapPriConUnChkAcct.put(objCon.AccountId,true);
                        }
                    }
                }
            } 
            //Loop can be reused for updated contacts
            for(Contact objCon: mapNewRecds.values()){
                if(objCon.AccountId!=null){
                    //Throw error if account has already a primary billing contact
                    if(objCon.CWS_Primary_Billing_Contact__c 
                    && objCon.CWS_Primary_Billing_Contact__c!=mapOldRecds.get(objCon.Id).CWS_Primary_Billing_Contact__c 
                    && mapPriBillConAcct.containsKey(objCon.AccountId) && mapPriBillConAcct.get(objCon.AccountId)){
                        objCon.addError(Label.CWS_PrimaryBillContact_Error);
                    }
                    //Throw error if account has already a primary contact
                    if(objCon.CWS_Primary_Contact__c 
                    && objCon.CWS_Primary_Contact__c!=mapOldRecds.get(objCon.Id).CWS_Primary_Contact__c 
                    && mapPriConAcct.containsKey(objCon.AccountId) && mapPriConAcct.get(objCon.AccountId)){
                        objCon.addError(Label.CWS_PrimaryContact_Error);
                    } 
                    if(!objCon.CWS_Primary_Contact__c && objCon.CWS_Primary_Contact__c!=mapOldRecds.get(objCon.Id).CWS_Primary_Contact__c && 
                    (mapPriConAcct.containsKey(objCon.AccountId) && mapPriConAcct.get(objCon.AccountId)
                    ||(!mapPriConAcct.containsKey(objCon.AccountId) && mapPriConUnChkAcct.containsKey(objCon.AccountId) && !mapPriConUnChkAcct.get(objCon.AccountId)))){
                        objCon.addError(Label.CWS_PrimaryContactUnChk_Error);
                    }
                }
                //BED-8704 populating Business Development Rep field with owner if profile is tele sales and contact status is MQL or SAL
                //BED-12433
                if(mapUsers.containsKey(objCon.OwnerId) && (String.isBlank(objCon.CWS_Business_Development_Rep__c) || objCon.OwnerId != mapOldRecds.get(objCon.Id).OwnerId)
                && (mapUsers.get(objCon.OwnerId).Profile.Name == CWS_ConstantClass.PROFILE_TELE_SALES || mapUsers.get(objCon.ownerid).CWS_Type__c == CWS_ConstantClass.USER_TYPE_AM || mapUsers.get(objCon.ownerid).CWS_Type__c == CWS_ConstantClass.USER_TYPE_DAM)
                && (objCon.CWS_Contact_Status__c==CWS_ConstantClass.CONTACT_STATUS_MQL || objCon.CWS_Contact_Status__c==CWS_ConstantClass.CONTACT_STATUS_SAL)){
                    objCon.CWS_Business_Development_Rep__c = objCon.ownerid;        
                }
            }
            //Ticket Number : OBD-107 14428826 - Field Marketing Task Enhancements 
   			// Parameter    : updating email and phone feild on task object 
   			//Developer    : Raja
          
            if(!conIds.isEmpty()){
                Id taskFMCId =  Schema.SObjectType.Task.getRecordTypeInfosByName().get('Field Marketing Campaign').getRecordTypeId();
                List<Task> tasksToUpdate = new List<Task>();
                for(Contact con : [SELECT id,Email,CWS_Phone_Direct__c, 
                                               (SELECT id,CWS_Primary_Email__c,CWS_Direct_Phone__c FROM Tasks 
                                                WHERE RecordTypeId =:taskFMCId )
                                              FROM Contact 
                                              WHERE ID IN:conIds ])
                {
                    if(!con.Tasks.isEmpty()){
                        for(Task tsk: con.tasks){
                            tsk.CWS_Primary_Email__c = mapNewRecds.get(con.Id).Email;
                            tsk.CWS_Direct_Phone__c = mapNewRecds.get(con.Id).CWS_Phone_Direct__c;
                            tasksToUpdate.add(tsk);
                        }
                    }
                }
                if(!tasksToUpdate.isEmpty()){
                    update tasksToUpdate;
                }
            }
        } catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Contact' , 'CWS_ContactTriggerHelper', 'beforeUpdateLogic' , '', null, null , 'BeforeUpdate' , null);
      }
    }
    /*
    * Method name  : afterUpdateLogic
    * Description  : Use this method to write the after update logic
    * Parameter    : Map of Old and New Contacts.
    * Return Type  : None
    * Developer    : Sudhir Moturu
    */
    public static void afterUpdateLogic(Map<Id, Contact> mapNewRecds, Map<Id, Contact> mapOldRecds){    
        try{
            Set<Id> setPriConAcct =  new Set<Id>();//Set of account Ids and check for primary contact
            List<Contact> lstAllContacts = new List<Contact>();
            List<Contact> lstContsToUpdate = new List<Contact>();//List of primary contacts which needs to be updated to be made non primary
            List<Database.SaveResult> srList;//Stores the update result
            Set<Id> intSyncAccounts =  new Set<Id>();
            List<Account> readyforSyncAccounts = new List<Account>();

            //Loop can be reused for inserted contacts
            // This loop looks for changes in the Primary contact, if the primary contact is changed, the Account Id is added to the setPriConAcct set
            for(Contact objCon: mapNewRecds.values()){
                //Filtering account ids which have one primary contact selected
                if(objCon.AccountId!=null && objCon.CWS_Primary_Contact__c && objCon.CWS_Primary_Contact__c!=mapOldRecds.get(objCon.Id).CWS_Primary_Contact__c) {
                    setPriConAcct.add(objCon.AccountId);
                }
                //Start BED 5761 Checking Changes in Contact fields and capturing Account.
                if(objCon.AccountId!=null){
                    for(Schema.FieldSetMember fld :Schema.SObjectType.Contact.fieldSets.CWS_IntegrationFields.getFields()) {
                        //Check if the field value is changed
                        if(mapNewRecds.get(objCon.id).get(fld.getFieldPath())!=mapOldRecds.get(objCon.id).get(fld.getFieldPath())){
                            
                            intSyncAccounts.add(objCon.accountId);
                            break;
                        }
                    }
			    }
                // End BED - 5761
            }

            //SOQL can be changed for other logic 
            //Retrieve all contacts related to account which have primary billing and primary contact present
            // This checks for the new primary contact identified above and then queries all the contacts looking for the current primary contact. 
            if(setPriConAcct.size()>0){
                lstAllContacts = [SELECT Id,AccountId,CWS_Primary_Contact__c FROM Contact 
                            WHERE AccountId IN :setPriConAcct AND AccountId!=null AND CWS_Primary_Contact__c=true];
            }
            //Loop can be reused for other logic on retrieved contacts  
            if(lstAllContacts.size()>0){
                // This loop changes unchecks the primary contact field for the Contact previously identified as the primary contact so there can only be 1 primary contact
                for(Contact objCon: lstAllContacts) {                    
                    //Filtering all Account ids which have primary billing contact
                    if(setPriConAcct.contains(objCon.AccountId) && !mapNewRecds.containsKey(objCon.Id) && objCon.CWS_Primary_Contact__c) {
                        objCon.CWS_Primary_Contact__c = false;
                        lstContsToUpdate.add(objCon);
                    }
                }
            }
            
             // Start : BED 5761 
             if(!intSyncAccounts.isEmpty()){
                for(Account acc : [SELECT Id,CWS_Integration_Status__c FROM Account WHERE Id IN :intSyncAccounts 
                                   AND (CWS_Integration_Status__c=:CWS_ConstantClass.INT_STATUS_SYNCED 
                                   OR CWS_Integration_Status__c =:CWS_ConstantClass.INT_STATUS_ERROR) ]) {

                    acc.CWS_Integration_Status__c=CWS_ConstantClass.INT_STATUS_READY;
                    readyforSyncAccounts.add(acc);
                }
                if(!readyforSyncAccounts.isEmpty()){
                    srList = Database.update(readyforSyncAccounts);
                    CWS_ExceptionHandler.logDMLSaveResults(srList, 'CWS_ContactTriggerHelper' , 'beforeInsert','Update Account', null , null );
                }
            }
            // END : BED 5761

            if(lstContsToUpdate.size()>0){
                srList = Database.update(lstContsToUpdate);
                CWS_ExceptionHandler.logDMLSaveResults(srList, 'CWS_ContactTriggerHelper' , 'beforeInsert','Update Contacts', null , null );
            } 

            // The ids global variable gets updated in the beforeUpdateLogic method which only adds the Id to this variable under very specific conditions 
            // see line 238
			// BED 9325 
            if(ids.size()==1){
                callManageIntegration(Ids);
            }
        } catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Contact' , 'CWS_ContactTriggerHelper', 'beforeUpdateLogic' , '', null, null , 'BeforeUpdate' , null);
        }
    }
	   /*
    *Description: Calling Contact Manage Integration
    *Developer: abhishek
    *Story : BED-9325
    */
    public static void callManageIntegration(List<Id> contactIds){
        
        if (!System.isFuture() && !System.isQueueable()) {
            ID jobID = System.enqueueJob(new CWS_ManageIntegrationCallout(contactIds,CWS_ConstantClass.CALLOUT_MANAGE_CONTACT));
            System.debug('@@@CWS_ContractTriggerHelper callManageIntegration fired creating job Id: ' + jobID);
        }
    }
	//DO NOT REMOVE - Deactivated as part of BED 5761
    /*
    * Method name  : checkIntegFieldChange
    * Description  : BED-640 Check if any of the integration fields are changed related to zoura and netsuite
    * Parameter    : contact id,Map of Old and New Contacts.
    * Return Type  : Boolean
    * Developer    : Sudhir Moturu
    */
    /*public static boolean checkIntegFieldChange(Id idCon, Map<Id, Contact> mapNewRecds, Map<Id, Contact> mapOldRecds){
        Set<String> setIntegFlds = new Set<String>();//Set of all field api names related to Zoura and Netsuite integration
        //Iterate the integration field set on contact for API names of fields
        for(Schema.FieldSetMember fld :Schema.SObjectType.Contact.fieldSets.CWS_IntegrationFields.getFields()) {
            //Check if the field value is changed
            if(mapNewRecds.get(idCon).get(fld.getFieldPath())!=mapOldRecds.get(idCon).get(fld.getFieldPath())){
                return true;
            }
        }
        return false;
    }*/
}