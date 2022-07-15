/*Class Name: CWS_LeadTriggerHelper_Test
*Description: Test Class for CWS_LeadTriggerHelper
*Created By: Ankit
*Created On: 4/7/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Nirmal                 04/07/2020        BED-5150            Initial Version(Default Account Currency) 
*Sudhir Moturu          04/16/2020        BED-541                 Created beforeUpdateTestMethod method
*Manoj 					08/03/2020							  Created defaultingCountry Test Method.
*/

@isTest(SeeAllData=false)
public class CWS_LeadTriggerHelper_Test {
    
    @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'Lead'});   
        
        Map<String, Object> campaignFieldDetails =new Map<String, Object>{
            'name'=>Label.CWS_Sales_Generated_Cammpaign,
                'IsActive'=>true,
                'Status'=>'In Progress',
                'StartDate'=>system.today(),
                'EndDate'=>system.today()+365
                };      
                    
                    CWS_UTLDataFactory.createCampaign(campaignFieldDetails,true);  
        
        Map<String, Object> leadFieldDetails =new Map<String, Object>{
            'firstName'=>'Test',
                'LastName'=>'Lead',
                'Email'=>'test@test.com',
                'Country'=>'United States',
                'CountryCode'=>'US',
                'State'=>'California',
                'PostalCode'=>'12311',
                'Status'=> 'Inquiry'
                };
                    
                    Lead newLead = CWS_UTLDataFactory.createLead(leadFieldDetails,true); 
        
        
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
                'currencyIsoCode'=>'EUR'};
                    Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);        
    }
    
    
    
    
    // Methd Used to Cover BED-163, BED - 496,BED-5150
    @isTest static void testMethod1(){
        
        Test.starttest();
        
        list<campaign> lstCamp = [Select id,name from campaign];
        list<campaignMember> campObj = [Select LeadId from campaignMember];
        list<Lead> lstLead = [Select id,name,email from Lead];
        
        System.assertEquals(lstLead[0].id,campObj[0].LeadId);
        
        Test.stoptest();
        if(lstLead.size()>0){
            Delete lstLead;
        }
    }
    
    @isTest static void testMethod3(){
        
        Test.starttest();
        
        list<campaign> lstCamp = [Select id,name from campaign];
        list<campaignMember> campObj = [Select LeadId from campaignMember];
        list<Lead> lstLead = [Select id,name from Lead];
        
        System.assertEquals(lstLead[0].id,campObj[0].LeadId);
        
        Test.stoptest();
        if(lstLead.size()>0){
            Delete lstLead;
        }
    }
    
    @isTest static void beforeUpdateTestMethod(){
        list<Lead> lstLead = [Select id,name,recordtype.Name, email, postalcode,CWS_Rejected_Reason__c from Lead];
        lstLead[0].Status = CWS_ConstantClass.LEAD_STATUS_REJECTED;
        lstLead[0].CWS_Rejected_Reason__c = 'Student';
        lstLead[0].Email = 'test@deloitte.com';
        lstLead[0].postalCode = '121212';
        if(lstLead.size()>0){
            Update lstLead;
        }
        //lstLead = [Select id,name,recordtype.Name from Lead];
        lstLead[0].Status = CWS_ConstantClass.LEAD_STATUS_RECYCLED;
        lstLead[0].CWS_Recycled_Reason__c = 'Timeline';
        if(lstLead.size()>0){
            Update lstLead;
        }  
        
        //lstLead = [Select id,name,recordtype.Name from Lead];
        Id recId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(CWS_ConstantClass.LEAD_RT_API_EDIT).getRecordTypeId();
        System.assertEquals(recId,lstLead[0].RecordTypeId);
        
        //These methods are directly called because of the reason that the trigger context are not firing on them and
        //if we try to save handler removing these context ot throws compile error as its implementing interface
        CWS_LeadTriggerHandler handler = new CWS_LeadTriggerHandler();
        map<id,SObject> newRecs = new map<id,SObject>();
        handler.BeforeDelete(newRecs);
        handler.AfterDelete(newRecs);
        handler.AfterUndelete(newRecs);
        handler.AfterUpdate(newRecs,newRecs);
    }
    @isTest static void createPrtnerUsers(){
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
                //'CWS_Is_Distributor__c'=> true
                'CWS_Is_IIT_Reseller__c' => true,
                'CWS_Distributor_Identifier__c' =>'Other'
                };
                    Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);   
        
        Map<String, Object> additionalFieldValues = new map<String, Object>();
        Contact conObj = CWS_UTLDataFactory.createContact('Test','PartnerContact',distiaccounts[0].Id,additionalFieldValues,true);
        
        Map<String, Object> partnersExtraFields =new Map<String, Object>{
            'profileid'=>profile.id,
                'ContactId'=>conObj.Id
                };
                    
                    user distyUser = CWS_UTLDataFactory.createPartnerUser(partnersExtraFields,true);
        
        system.runAs(distyUser){
            Map<String, Object> leadFieldDetails2 =new Map<String, Object>{
                'firstName'=>'Test',
                    'LastName'=>'Partner Lead',
                    'Email'=>'test@test.com',
                    'Country'=>'United States',
                    'CountryCode'=>'US',
                    'State'=>'California',
                    'PostalCode'=>'12311',
                    'CWS_Distributor__c' => distiAccounts[0].Id,
                    'CWS_Preferred_Distributor__c' => 'Other',
                    'LeadSource' => CWS_ConstantClass.LEAD_ON_BOARDING
                    };                        
                        CWS_UTLDataFactory.createLead(leadFieldDetails2,true); 
        }
    }
    //To Default country and checking for assignment of BDR.
    @isTest static void defaultingCountry(){
        Lead leadObj = [SELECT Id,OwnerId,Status from Lead where EMAIL = 'a@b.com' LIMIT 1];
        if(leadObj!= null){
            //Creating sales rep.            
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');        
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;
            User teleSalesUser = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Tele_Sales','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
            //User tsalesUser = [SELECT ID From user where profile.name = 'CWS_Tele_Sales'  LIMIT 1];   
            if(teleSalesUser.Id!=null){                
                leadObj.OwnerId = teleSalesUser.Id;
                leadObj.Status = CWS_ConstantClass.LEAD_STATUS_MQL;
                update leadObj;                              
            }
            String testing ='test';
            test.startTest();
            system.runAs(teleSalesUser){  
                Lead leadObj1 = [SELECT Id,Status,CountryCode,stateCode FROM Lead LIMIT 1];                
                leadObj1.CountryCode = 'CA';
                leadObj1.stateCode = 'AB';  
                update leadObj1;
                Lead leadobj2 = [SELECT Id,CWS_Business_Development_Rep__c FROM Lead WHERE ID =:leadObj1.Id];
                system.assertEquals(teleSalesUser.Id, leadobj2.CWS_Business_Development_Rep__c); 
            }  
            test.stopTest();
            
        }
    }
}