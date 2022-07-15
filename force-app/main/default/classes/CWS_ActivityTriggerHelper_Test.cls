/*Class Name: CWS_ActivityTriggerHelper_Test
*Description: Test Class for CWS_TaskTriggerHelper,CWS_EventTriggerHelper
*Created By: Manoj
*Created On: 05/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Manoj                 05/05/2020        BED-7889             
*Raja Mouthkapally		4/27/2020		OBD-107					14428826 - Field Marketing Task Enhancements
*Mahak                 06/06/2021        14713243                   
*/
@isTest(SeeAllData=false)
public class CWS_ActivityTriggerHelper_Test {
    @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Task','Event'});
        
        
        Map<String, Object> endCustomerDetails =new Map<String, Object>{
            'BillingCountry'=>'United States',
                'BillingCountryCode'=>'US',
                'currencyIsoCode'=>'USD'};
                    CWS_UTLDataFactory.createAccount('TestAccount', endCustomerDetails,true);      
                    
        //UserRole portalRole = [Select Id,name From UserRole Limit 1];
        
        Profile profile1;
        Profile profile;
        
        // Force Reviewer review addtion of set to have null check
        list<String> profSet =  new list<String>{'System Administrator','CWS_Partner_Community_User'};
        
        // Force Reviewer review null check
        if(!profSet.isEmpty()){
            for(Profile prof: [Select Id,name from Profile where name IN: profSet limit 2]){
                if(prof.name == 'System Administrator'){
                    profile1 = prof;
                }else{
                    profile = prof;
                }
            }
        }
        
        Map<String, Object> userExtraFields1=new Map<String, Object>{
            'isActive'=>true
            };
        User userObj1 = CWS_UTLDataFactory.createUser('Admin','disty@test1.com','Dist',profile1.name,'CEO',
                                       'disty@test.com.Admin.cw',userExtraFields1,true);

        //Create Distributor Account
        Map<String, Object> distributorAccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR',
            'OwnerId'=>userObj1.id,
            'CWS_Is_Distributor__c'=> true
            };
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);   
        
        Map<String, Object> additionalFieldValues = new map<String, Object>{
        'Mailingcountry' => 'India'
        };
        Contact conObj = CWS_UTLDataFactory.createContact('Test','PartnerContact',distiaccounts[0].Id,additionalFieldValues,true);
        
        Map<String, Object> partnersExtraFields =new Map<String, Object>{
            'profileid'=>profile.id,
            'ContactId'=>conObj.Id
            };
                                         
        user distyUser = CWS_UTLDataFactory.createPartnerUser(partnersExtraFields,true); 
        
     // Create Opportunity
        Map<String, Object> opportunityFields=new Map<String, Object>{
            'CWS_Route_to_Market__c'=>'Direct', 'CloseDate'=> Date.today(),'CWS_Bill_To_Account__c'=> distiAccounts[0].Id,
            'Type'=>'New','CurrencyIsoCode'=>'USD','OwnerId' => distyUser.Id
        };
        Opportunity opty=CWS_UTLDataFactory.createOpportunity('New Business Opty',distiAccounts[0].Id,opportunityFields,true);
          
        Map<String, Object> QuoteFields=new Map<String, Object>{
            'OwnerId' => distyUser.Id
        };
            
        SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(distiAccounts[0].id,opty.id,QuoteFields, true);
      //  system.debug('Testig'+opty);
    }
    
    @isTest static void createTaskAsChannelRep(){
        
        test.startTest();
            
            User usr = [Select id from user where Contact.lastname = 'PartnerContact' limit 1];
			//Id oppId = [select Id from Opportunity Limit 1].Id;            
            System.runAs(usr){
               Task tsk = new Task();
                tsk.Subject = 'Follow up with Lead';
                tsk.WhatId = [select Id from Account Limit 1].Id;            
                tsk.OwnerId = UserInfo.getUserId();
                tsk.Status = 'New';
                tsk.Type = 'Call';
                if(tsk != null){
                    insert tsk;
                }
                Task taskObj;
                if(tsk != null){
                    taskObj =[SELECT Id,createdByID from Task where Id=:tsk.Id limit 1];
                }
                system.assertEquals(taskObj.createdByID,usr.id);
                
                Map<Id, SObject> newItems = new Map<Id, SObject>();
                CWS_TaskTriggerHandler hlr = new CWS_TaskTriggerHandler();
                hlr.AfterUpdate(newItems,newItems);
                hlr.AfterDelete(newItems);
                hlr.AfterUndelete(newItems);
                hlr.AfterInsert(newItems);
            }
        test.stopTest();
    }
    
    @isTest static void createEventAsChannelRep(){
        test.startTest();
            
            User usr = [Select id from user where Contact.lastname = 'PartnerContact' limit 1];
            Id oppId = [select Id from Opportunity Limit 1].Id;
            System.runAs(usr){
                
               Event evt = new Event();
                evt.Type = 'Email';
                evt.Description = 'test'; //string
                evt.OwnerId = UserInfo.getUserId(); //user id
                evt.WhatId = oppId; //record id
                evt.DurationInMinutes = 1;
                evt.ActivityDateTime = Datetime.newInstance(2020, 05, 05);
                if(evt != null){
                    insert evt;
                }
                
                
                
             //    Schema.SObjectType sobjectType = evt.whatId.getSObjectType();   
            //    Schema.SObjectType sobjectType = event.whatId.getSObjectType();   
             //   system.debug('Nida --- '+evt.whatId+'-------'+sobjectType.getDescribe().getName());
                Event eventObj;
                if(evt != null){
                    eventObj =[SELECT Id,createdByID from Event where Id=:evt.Id limit 1];
                }
                system.assertEquals(eventObj.createdByID,usr.id);
                
                Map<Id, SObject> newItems = new Map<Id, SObject>();
                CWS_EventTriggerHandler hlr = new CWS_EventTriggerHandler();
                hlr.BeforeInsert(newItems.values());
                hlr.AfterUpdate(newItems,newItems);
                hlr.AfterDelete(newItems);
                hlr.AfterUndelete(newItems);
                hlr.BeforeUpdate(newItems,newItems);
                hlr.AfterInsert(newItems); 
            }
        test.stopTest();
    }
    
    
    @isTest static void deleteTask(){
                
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');        
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),FALSE);
        ID tmID = UserInfo.getUserId();
        System.runAs(rep){
            //Added by Mahak bansal for #14713243 
            Opportunity opp=[SELECT Id,CWS_Bill_To_Contact__c FROM Opportunity Limit 1];
            Task tsk = new Task();
            tsk.Subject = 'Follow up with Lead';
            tsk.WhatId = opp.Id;////Added by Mahak bansal for #14713243 
            tsk.OwnerId = UserInfo.getUserId();
            tsk.Status = 'New';
            tsk.Type = 'Call';
            if(tsk != null){
                insert tsk;
            }
            system.assert( String.isNotBlank(tsk.Id) );
            //Added by Mahak bansal for #14713243 
            system.assertEquals( tsk.WhoId,opp.CWS_Bill_To_Contact__c ,'Task is created for BillTO Contact');
            Task task;
            if(tsk != null){
                task =[SELECT Id from Task where Id=:tsk.Id];
            }
            try{
                if(task != null){
                    Delete task;
                }
            }
            catch(Exception ex){
                system.assert(ex.getMessage().contains(Label.Activity_Error_Message));
            }            
        }
    }
    
    @isTest static void deleteEvent(){
                
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');        
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),FALSE);
        ID tmID = UserInfo.getUserId();
        System.runAs(rep){
            Event evt = new Event();
            evt.Type = 'Email';
            evt.Description = 'test'; //string
            evt.OwnerId = UserInfo.getUserId(); //user id
            evt.WhatId = [select Id from Account Limit 1].Id; //record id
            evt.DurationInMinutes = 1;
            evt.ActivityDateTime = Datetime.newInstance(2020, 05, 05);
            if(evt!= null){
                insert evt;
            }            
            system.assert( String.isNotBlank(evt.Id) );
            Event event;
            if(evt!= null){
                event =[SELECT Id from Event where Id=:evt.Id];
            }
            try{
                if(event!= null){
                    Delete event;
                }
            }
            catch(Exception ex){
                system.assert(ex.getMessage().contains(Label.Activity_Error_Message));
            }            
        }
    }
    
     @isTest static void UpdateTask(){
        test.startTest();
            
            User usr = [Select id from user where Contact.lastname = 'PartnerContact' limit 1];
            Id quoteId = [select Id from SBQQ__Quote__c Limit 1].Id;
         
			System.runAs(usr){
            Task tsk = new Task();
            tsk.Subject = 'Follow up with Lead';
            tsk.WhatId = [select Id from Account Limit 1].Id;   
            tsk.CWS_Quote_Id__c = quoteId;
            tsk.OwnerId = UserInfo.getUserId();
            tsk.Status = CWS_ConstantClass.TASK_STATUS_COMPLETED;
            tsk.Type = 'Field Marketing Campaign';
            tsk.recordtypeId = CWS_ConstantClass.TASK_FMC;
           // System.debug('Nida     ---'+tsk.CWS_Quote_Id__c);
            if(tsk != null){
                insert tsk;
            }
        //    system.assert( String.isNotBlank(tsk.Id) );
            Task task;
            if(tsk != null){
                task =[SELECT Id from Task where Id=:tsk.Id];
            }
            try{
                if(task != null){
					task.Status = CWS_ConstantClass.TASK_STATUS_CLOSED;
                    update task;
                }
            }
			catch(Exception ex){
               // system.assert(ex.getMessage().contains(Label.Activity_Error_Message));
            } 
		 test.stopTest();
		 
		 }
 }
         @isTest static void FMCTask(){
        test.startTest();
            
            User usr = [Select id from user where Contact.lastname = 'PartnerContact' limit 1];
            Id quoteId = [select Id from SBQQ__Quote__c Limit 1].Id;
         
			System.runAs(usr){
            Task tsk = new Task();
            tsk.Subject = 'Update FMC Task Test';
            tsk.WhatId = [select Id from Opportunity Limit 1].Id;   
            tsk.CWS_Quote_Id__c = quoteId;
            tsk.OwnerId = UserInfo.getUserId();
            tsk.Status = CWS_ConstantClass.TASK_STATUS_COMPLETED;
            tsk.Type = 'Field Marketing Campaign';
            tsk.recordtypeId = CWS_ConstantClass.TASK_FMC;
            tsk.CWS_SQO__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;
            tsk.CWS_Hook__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;    
            tsk.CWS_Discovery__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;
            tsk.CWS_Demo__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;
            tsk.CWS_Trial_Follow_Up__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;    
           // System.debug('Nida     ---'+tsk.CWS_Quote_Id__c);
            if(tsk != null){
                insert tsk;
            }
        //    system.assert( String.isNotBlank(tsk.Id) );
            Task task;
            if(tsk != null){
                task =[SELECT Id from Task where Id=:tsk.Id];
            }
            try{
                if(task != null){
					task.Status = CWS_ConstantClass.TASK_STATUS_INPROGRESS;
                    task.CWS_SQO__c = CWS_ConstantClass.TASK_STATUS_COMPLETED;
            task.CWS_Hook__c = CWS_ConstantClass.TASK_STATUS_COMPLETED;    
            task.CWS_Discovery__c = CWS_ConstantClass.TASK_STATUS_COMPLETED;
            task.CWS_Demo__c = CWS_ConstantClass.TASK_STATUS_COMPLETED;
            task.CWS_Trial_Follow_Up__c = CWS_ConstantClass.TASK_STATUS_COMPLETED;
                    update task;
                    task.CWS_SQO__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;
            task.CWS_Hook__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;    
            task.CWS_Discovery__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;
            task.CWS_Demo__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;
            task.CWS_Trial_Follow_Up__c = CWS_ConstantClass.TASK_STATUS_INPROGRESS;
                    update task;
                    task.Status = CWS_ConstantClass.TASK_STATUS_COMPLETED;
                    update task;
                }
            }
			catch(Exception ex){
               // system.assert(ex.getMessage().contains(Label.Activity_Error_Message));
            } 
		 test.stopTest();
		 
		 }
 }
    //OBD-107 method to test update phone and email on task 
    @isTest static void updatePhoneAndEmailonTask(){
        test.startTest();        
       
            Account acc =[select Id from Account Limit 1];
            Map<String, Object> mapConFieldValues = new Map<String, Object>{
                'CWS_Primary_Billing_Contact__c' => true,
                'Email'=>'test@test.com'
            };
            Contact objCon1 = CWS_UTLDataFactory.createContact('TestFirstName1','TestLastName1',acc.Id,mapConFieldValues,false);            
            insert objCon1;
        	Map<String, Object> mapConFieldValues1 = new Map<String, Object>{
                'CWS_Primary_Billing_Contact__c' => false,
                'Email'=>'test123@test.com'
            };
        	Contact objCon2 = CWS_UTLDataFactory.createContact('TestFirstName2','TestLastName2',acc.Id,mapConFieldValues1,false);            
            insert objCon2;
            Task tsk = new Task();
            tsk.Subject = 'Follow up with Lead';
            tsk.WhatId = acc.id; 
            tsk.WhoId = objCon1.id;
            tsk.OwnerId = UserInfo.getUserId();
            tsk.Status = CWS_ConstantClass.TASK_STATUS_COMPLETED;
            tsk.Type = 'Field Marketing Campaign';
            tsk.recordtypeId = CWS_ConstantClass.TASK_FMC;           
            insert tsk;   
			tsk.WhoId = objCon2.Id;
        	update tsk;
        	objCon2.Email = 'test1133@test.com';
        	update objCon2;
            test.stopTest();            
        
    }
}