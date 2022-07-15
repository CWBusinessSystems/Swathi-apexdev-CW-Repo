/*Class Name: CWS_TaskTriggerHelper
*Description: Helper Class for CWS_LeadTriggerHandler
*Created By: Manoj
*Created On: 5/5/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Manoj                  05/05/2020      7889                    Prevent deletion of Task
*Ankit                  05/19/2020      7871                    Populate email of related to record user
*Abhishek               05/20/2020      5771                    Error on Demo Record creation
*Nida                   08/26/2020      13226                   Field Marketing Campaign
*Prashant               12/17/2020      Service Ticket #14028898 Remove Demo Task Automation on Due date and Status
*Raja                   04/16/2021      14428826 - Field Marketing Task Enhancements
*Mahak                  06/06/2021      14713243 -Demo Task & Opportunity Updates
*/
public class CWS_TaskTriggerHelper {
    
    public static void beforeDeleteLogic(Map<Id, SObject> oldItems){
              
        String crntUsrProfile = [SELECT Name from Profile WHERE Id=: userinfo.getProfileId() LIMIT 1].Name;
        List<Restricted_Activity_Profiles__mdt> restrictedProfilesList = [SELECT Id,  QualifiedApiName FROM Restricted_Activity_Profiles__mdt
                                                                          WHERE QualifiedApiName =: crntUsrProfile AND  QualifiedApiName != null ];
        //Checking if profile is in restricted list.
        if(!restrictedProfilesList.isempty()){
            for (Id taskId : oldItems.keyset())      
            {                            
                oldItems.get(taskId).addError(Label.Activity_Error_Message); 
            } 
        }
    }
    /*public static void afterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems)  {
        Set<Id> quoteIDs = new Set<Id>();
          Map<Id, Task> newItem = (Map<Id, Task>)newItems;
         Map<Id,Opportunity> mapQuotes;
        List<SBQQ__Quote__C> qtList = new List<SBQQ__Quote__C>();
      try{
          for(Task tas: newItem.values()){
                if( tas.Status == 'Closed' && tas.whatId != null){ 
                    Schema.SObjectType sobjectType = tas.whatId.getSObjectType();
                    System.debug('object name'+sobjectType.getDescribe().getName());
                    if(sobjectType.getDescribe().getName() == 'Opportunity'){
                        System.debug('What ID'+tas.whatId);
                          quoteIDs.add(tas.whatId);
                    }
                }   
            }
          //BED-6236 Standard SOW and Custom SOW     
        if(quoteIDs !=  null){
            mapQuotes =  new map<Id,Opportunity>([Select ID , name ,SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.CWS_File_Attached__c from Opportunity Where Id IN: quoteIDs]); 
        }   
        if(mapQuotes !=  null){
            For(Opportunity opp: mapQuotes.values()){
                opp.SBQQ__PrimaryQuote__r.CWS_File_Attached__c = True;
                qtList.add(opp.SBQQ__PrimaryQuote__r);
            }
            if(!qtList.isempty() && qtList != null){
                Update qtList;
            }
        }
      }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Task' , 'CWS_TaskTriggerHelper', 'afterUpddateLogic' , '', null, null , 'after Update' , null);
        }
    }*/
    
    //BED-1431
    public static void beforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
    
        Set<Id> quoteIDs = new Set<Id>();
        Map<Id, Task> newQMap = (Map<Id, Task>)newMap;
        Map<Id, Task> oldQMap = (Map<Id, Task>)oldMap;
        Map<Id,SBQQ__Quote__C> mapQuotes;
        map<id,opportunity> mapOfOpp;
        List<SBQQ__Quote__C> qtList = new List<SBQQ__Quote__C>();
        set<id> oppIds = new set<id>();
        Task oldTask;

        system.debug('**New Map ='+newQMap.size());
        try{
            for(Task tas: newQMap.values()){
              if(tas.Status == CWS_ConstantClass.TASK_STATUS_CLOSED && tas.whatId != null){ 
                    quoteIDs.add(String.valueOf(tas.CWS_Quote_Id__c));                    
                }  
              if(tas.whatId != null){
                    Schema.SObjectType sobjectType = tas.whatId.getSObjectType();   
                    if(sobjectType.getDescribe().getName() == CWS_ConstantClass.OPPORTUNITY_NAME){
                        //BED- 13226 Get related opportunity Id to query   
                        oppIds.add(tas.whatId);
                    }
                }
                if(tas.recordtypeId == CWS_ConstantClass.TASK_FMC){
                    if(oldQMap != null){
                        if(oldQMap.get(tas.id)!=null){
                            oldTask = oldQMap.get(tas.id);
                        }
                    }
                    if((tas.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS && oldTask.CWS_SQO__c != tas.CWS_SQO__c)  ||
                        (tas.CWS_Hook__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS && oldTask.CWS_Hook__c != tas.CWS_Hook__c) ||
                        (tas.CWS_Discovery__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS && oldTask.CWS_Discovery__c != tas.CWS_Discovery__c) ||
                        (tas.CWS_Demo__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS && oldTask.CWS_Demo__c != tas.CWS_Demo__c) ||
                        (tas.CWS_Trial_Follow_Up__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS && oldTask.CWS_Trial_Follow_Up__c != tas.CWS_Trial_Follow_Up__c)){
                        tas.Status = CWS_ConstantClass.TASK_STATUS_INPROGRESS;                                 
                    }
                    
                    if(tas.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           tas.CWS_SQO_Completion_Date__c = system.today();
                    }
                    if(tas.CWS_Hook__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           tas.CWS_Hook_Completed_Date__c = system.today();
                    }
                    if(tas.CWS_Discovery__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           tas.CWS_Discovery_Completion_Date__c = system.today();
                    }
                    if(tas.CWS_Demo__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           tas.CWS_Demo_Completed_Date__c = system.today();
                    } 
                    if(tas.CWS_Trial_Follow_Up__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           tas.CWS_Trial_Follow_Up_Completion_Date__c = system.today(); 
                    }
                } 
            }
            if(quoteIDs !=  null){
                mapQuotes =  new map<Id,SBQQ__Quote__C>([Select ID , name ,CWS_File_Attached__c,CWS_Custom_sow__c from SBQQ__Quote__c Where Id IN: quoteIDs]); 
            }   
            if(oppIds != null){
                    //BED- 13226
                    mapOfOpp = new map<id,opportunity>([Select id,stagename from opportunity where id IN: oppIds]);
            }
            for(Task task : newQMap.values()){
                if(mapQuotes !=  null){
                    if(mapQuotes.containskey(task.CWS_Quote_Id__c)){
                        For(SBQQ__Quote__C qts: mapQuotes.values()){
                            if(!qts.CWS_File_Attached__c){
                                task.addError(System.Label.CWS_Custom_Sow_Error_Msg);
                            }           
                        }   
                    }
                }
                
                    if(oldQMap != null){
                        if(oldQMap.get(task.id)!=null){
                            oldTask = oldQMap.get(task.id);
                        }
                    }
                if(task.recordtypeId == CWS_ConstantClass.TASK_FMC){
                
                if(task.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_COMPLETED && oldTask.CWS_SQO__c != task.CWS_SQO__c){
                    if(!(mapOfOpp.containskey(task.whatId))){
                        task.addError(Label.CWS_SQOTaskStatusError);    
                    }
                    else
                    {
                        task.Status = CWS_ConstantClass.TASK_STATUS_COMPLETED;
                    }
                }
                if(task.Status == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                        if(task.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_SQO__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;
                        }
                        if(task.CWS_Hook__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_Hook__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_Hook__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;
                        }
                        if(task.CWS_Discovery__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_Discovery__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_Discovery__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;
                        }       
                        if(task.CWS_Demo__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_Demo__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_Demo__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;
                        }
                        if(task.CWS_Trial_Follow_Up__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_Trial_Follow_Up__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_Trial_Follow_Up__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;                                 
                        }
                    }
                }
            }    
        }catch(Exception e){
                CWS_ExceptionHandler.logException( e,'Task' , 'CWS_TaskTriggerHelper', 'afterUpddateLogic' , '', null, null , 'after Update' , null);
        }
    }
    
    //7844 : Populate email of related user object record
    public static void beforeInsertLogic(list<SObject> newItems){
        list<Task> newRecs = (list<Task>) newItems;
        set<id> oppIds = new set<id>();
        try{
            for(Task task: newRecs){
                if(task.whatId != null){
                    Schema.SObjectType sobjectType = task.whatId.getSObjectType();   
                    if(sobjectType.getDescribe().getName() == CWS_ConstantClass.OPPORTUNITY_NAME){
                        //BED- 7844 Get related opportunity Id to query   
                        oppIds.add(task.whatId);
                    }
                }
                // Service Ticket #14028898 - Remove automation to auto close task and set due date to today()
                /*if(task.recordtypeId == CWS_ConstantClass.TASK_DEMO){
                    task.ActivityDate = system.today();
                    task.Status = CWS_ConstantClass.TASK_STATUS_CLOSED;
                }*/
                if(task.recordtypeId == CWS_ConstantClass.TASK_FMC){
                    if( task.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS ||
                        task.CWS_Hook__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS ||
                        task.CWS_Discovery__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS ||
                        task.CWS_Demo__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS ||
                        task.CWS_Trial_Follow_Up__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS){
                        task.Status = CWS_ConstantClass.TASK_STATUS_INPROGRESS;                                 
                    }
                    if(task.Status == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                       if(task.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_SQO__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;
                        }
                        if(task.CWS_Hook__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_Hook__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_Hook__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;
                        }
                        if(task.CWS_Discovery__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_Discovery__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_Discovery__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;
                        }       
                        if(task.CWS_Demo__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_Demo__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_Demo__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;
                        }
                        if(task.CWS_Trial_Follow_Up__c == CWS_ConstantClass.TASK_STATUS_INPROGRESS || task.CWS_Trial_Follow_Up__c == CWS_ConstantClass.TASK_STATUS_NOTSTARTED){
                            task.CWS_Trial_Follow_Up__c = CWS_ConstantClass.TASK_STATUS_SYSCLOSED;                                 
                        }                                
                    }
                    if(task.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           task.CWS_SQO_Completion_Date__c = system.today();
                    }
                    if(task.CWS_Hook__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           task.CWS_Hook_Completed_Date__c = system.today();
                    }
                    if(task.CWS_Discovery__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           task.CWS_Discovery_Completion_Date__c = system.today();
                    }
                    if(task.CWS_Demo__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           task.CWS_Demo_Completed_Date__c = system.today();
                    } 
                    if(task.CWS_Trial_Follow_Up__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                           task.CWS_Trial_Follow_Up_Completion_Date__c = system.today(); 
                    }
                   }   
            }
                
            Map<Id,Opportunity> mapOfOpp;
            
            if(oppIds != null){
                //BED- 7844 Query related opportunities and put in map to get the email of owner
                //Added by Mahak Bansal - 6 June 2021- OBD-601 #14713243 , Added owner email in SOQL
                mapOfOpp = new Map<Id,Opportunity>([SELECT Id,owner.email,owner.firstname,owner.lastname,stagename,CWS_Bill_To_Contact__c
                                                    FROM Opportunity
                                                    WHERE id IN: oppIds]);
                
                if(mapOfOpp != null){
                    for(Task task : newRecs){
                        if(mapOfOpp.containskey(task.whatId) && CWS_ConstantClass.USERINFO_STANDARD != null && 
                            UserInfo.getUserType() != CWS_ConstantClass.USERINFO_STANDARD){
                            //BED-7844 Assign the related opportunity email which will be used as recipient in workflow rule
                            task.CWS_Related_User_Email__c= mapOfOpp.get(task.whatId).owner.email;
                            task.CWS_Related_User_Name__c = mapOfOpp.get(task.whatId).owner.firstname + ' '+mapOfOpp.get(task.whatId).owner.lastname;
                        }
                        // 5771 : User shuld not be able to create Demo on Closed Won opp Stage.
                    if(task.recordtypeId == CWS_ConstantClass.TASK_DEMO && mapOfOpp.containskey(task.whatId) &&
                        (mapofOpp.get(task.whatID).stagename ==CWS_ConstantClass.OpportunityClosedWon_Stage 
                            || mapofOpp.get(task.whatID).stagename ==CWS_ConstantClass.OpportunityClosedLose_Stage )){
                        task.addError(Label.CWS_DemoTask_CreationError);                                 
                    }
                    	
                    //Added by Mahak Bansal - 6 June 2021- OBD-601 #14713243 	
                    //The “Name” field default to Bill To Contact on opp and Due date default to today	
                    if(task.recordtypeId == CWS_ConstantClass.TASK_DEMO){                            	
                        task.WhoId=mapOfOpp.get(task.whatId).CWS_Bill_To_Contact__c;	
                        task.ActivityDate=System.Today();	
                    }	
                        
                    //BED-13226 associate task to respective opportunity before accepting this SQO
                   
                        if(task.recordtypeId == CWS_ConstantClass.TASK_FMC && task.CWS_SQO__c == CWS_ConstantClass.TASK_STATUS_COMPLETED){
                             if(!(mapOfOpp.containskey(task.whatId))){
                                task.addError(Label.CWS_SQOTaskStatusError);    
                            }                          
                        }   // End 
                    }
                }
            }
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Task' , 'CWS_TaskTriggerHelper', 'beforeInserLogic' , '', null, null , 'Before Insert' , null);
        }
    }
    
    //14428826 - Field Marketing Task Enhancements
    public static void updatePhoneAndEmailonTask(List<Task> newTaskList,Map<Id,Task> oldtasksMap){
        Set<Id> conIds = new Set<Id>();
        for(Task tsk: newTaskList){
            if(oldtasksMap == null && tsk.WhoId != null &&  tsk.WhoId.getSObjectType().getDescribe().getName() == 'Contact'){
                conIds.add(tsk.whoId);
            }
            else if(oldtasksMap != null && !oldtasksMap.isEmpty() && tsk.WhoId != null && tsk.WhoId != oldtasksMap.get(tsk.id).WhoId && tsk.WhoId.getSObjectType().getDescribe().getName() == 'Contact'){
                conIds.add(tsk.whoId);
            }
        }
        if(!conIds.isEmpty()){
            Map<Id,Contact> conMap =new Map<Id,Contact>([Select Id,CWS_Phone_Direct__c,Email FROM Contact WHERE id IN: conIds ]);
            for(Task tsk: newTaskList){
                if(tsk.WhoId != null &&  tsk.WhoId.getSObjectType().getDescribe().getName() == 'Contact'){
                    tsk.CWS_Primary_Email__c = conMap.get(tsk.WhoId).Email;
                    tsk.CWS_Direct_Phone__c = conMap.get(tsk.WhoId).CWS_Phone_Direct__c;
                }
            }
        }
    }
}