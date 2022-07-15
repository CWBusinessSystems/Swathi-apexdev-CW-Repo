/*Class Name: CWS_ContactTriggerTest
*Description: Test Class for CWS_ContactTrigger,CWS_ContactTriggerHandler,CWS_ContactTriggerHelper
*Created By: Sudhir Moturu
*Created On: 05/MAY/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Sudhir Moturu          05/MAY/2020     BED-6452                Initial Version
*Raja Mouthkapally		4/27/2020		OBD-107					14428826 - Field Marketing Task Enhancements
*/
@isTest(SeeAllData=false)
public with sharing class CWS_ContactTriggerTest {
    @testSetup static void createTestData(){
        //Restricting trigger skip
        List<String> datalist = new List<String>{'Account','Contact'};
        CWS_UTLDataFactory.insertTriggerSwitch(datalist);
        
        //Creating Account
        Account objAcct = CWS_UTLDataFactory.createAccount('TestAccount', new Map<String, Object>(),true);
        
        //Creating Contact for the Account
        Map<String, Object> mapConFieldValues = new Map<String, Object>{
            'CWS_Primary_Billing_Contact__c' => true,
            'CWS_Primary_Contact__c' => true,
            'CWS_Integration_Sync_Status__c' => CWS_ConstantClass.INT_STATUS_SYNCED,
            'Email'=>'test@test.com'
        };
        CWS_UTLDataFactory.createContact('TestFirstName','TestLastName',objAcct.Id,mapConFieldValues,true);
        
        //These methods are directly called because of the reason that the trigger context are not firing on them and
        //if we try to save handler removing these context it throws compile error as its implementing interface 
        CWS_ContactTriggerHandler handler = new CWS_ContactTriggerHandler();
        map<id,SObject> newRecs = new map<id,SObject>();
        handler.BeforeDelete(newRecs);
        handler.AfterDelete(newRecs);
        handler.AfterUndelete(newRecs);
    }
    //To test before insert logic when contacts are inserted with multiple primary billing contacts
    @isTest static void testBeforeInsertLogicMultiplePBC(){
        try{
            List<Contact> lstCon = new List<Contact>();
            Account objAcct = [Select id from Account Limit 1];
            Map<String, Object> mapConFieldValues = new Map<String, Object>{
                'CWS_Primary_Billing_Contact__c' => true,
                'Email'=>'test@test.com'
            };
            Contact objCon1 = CWS_UTLDataFactory.createContact('TestFirstName1','TestLastName1',objAcct.Id,mapConFieldValues,false);
            Contact objCon2 = CWS_UTLDataFactory.createContact('TestFirstName2','TestLastName2',objAcct.Id,mapConFieldValues,false);
            lstCon.add(objCon1);
            lstCon.add(objCon2);
            Database.insert(lstCon);                   
            
            objCon1.Email='test@gmail.com';
            objCon2.Email='test@gmail.com';
            Database.update(lstCon);
            
            
        } catch(Exception e){
            Boolean bExpectedExceptionThrown =  (e.getMessage().contains(Label.CWS_PrimaryBillContact_Error)) ? true : false;
            System.AssertEquals(bExpectedExceptionThrown, true);
        } 
    }
    //To test before update logic when contacts are updated with multiple primary billing contacts
    @isTest static void testBeforeUpdateLogicMultiplePBC(){
        try{
            List<Contact> lstCon = new List<Contact>();
            Account objAcct = [Select id from Account Limit 1];
            Contact objCon1 = CWS_UTLDataFactory.createContact('TestFirstName1','TestLastName1',objAcct.Id,new Map<String, Object>(),false);
            Contact objCon2 = CWS_UTLDataFactory.createContact('TestFirstName2','TestLastName2',objAcct.Id,new Map<String, Object>(),false);
            lstCon.add(objCon1);
            lstCon.add(objCon2);
            Database.insert(lstCon);
            objCon1.CWS_Primary_Billing_Contact__c = true;
            objCon1.CWS_Primary_Contact__c = true;
             
            objCon2.CWS_Primary_Billing_Contact__c = true;
            Database.update(lstCon);
        } catch(Exception e){
            Boolean bExpectedExceptionThrown =  (e.getMessage().contains(Label.CWS_PrimaryBillContact_Error)) ? true : false;
            System.AssertEquals(bExpectedExceptionThrown, true);
        } 
    }
    //To test before insert logic when contacts are inserted with multiple primary contacts
    @isTest static void testBeforeInsertLogicMultiplePC(){
        try{
            List<Contact> lstCon = new List<Contact>();
            Account objAcct = [Select id from Account Limit 1];
            Map<String, Object> mapConFieldValues = new Map<String, Object>{
                'CWS_Primary_Contact__c' => true,
                'Email'=>'test@test.com'
            };
            Contact objCon1 = CWS_UTLDataFactory.createContact('TestFirstName1','TestLastName1',objAcct.Id,mapConFieldValues,false);
            Contact objCon2 = CWS_UTLDataFactory.createContact('TestFirstName2','TestLastName2',objAcct.Id,mapConFieldValues,false);
            lstCon.add(objCon1);
            lstCon.add(objCon2);
            Database.insert(lstCon);
        } catch(Exception e){
            Boolean bExpectedExceptionThrown =  (e.getMessage().contains(Label.CWS_PrimaryContact_Error)) ? true : false;
            System.AssertEquals(bExpectedExceptionThrown, true);
        } 
    }
    //To test before update logic when contacts are updated with multiple primary contacts
    @isTest static void testBeforeUpdateLogicMultiplePC(){
        try{
            List<Contact> lstCon = new List<Contact>();
            Account objAcct = [Select id from Account Limit 1];
            Contact objCon1 = CWS_UTLDataFactory.createContact('TestFirstName1','TestLastName1',objAcct.Id,new Map<String, Object>(),false);
            Contact objCon2 = CWS_UTLDataFactory.createContact('TestFirstName2','TestLastName2',objAcct.Id,new Map<String, Object>(),false);
            lstCon.add(objCon1);
            lstCon.add(objCon2);
            Database.insert(lstCon);
            objCon1.CWS_Primary_Contact__c = true;
            objCon2.CWS_Primary_Contact__c = true;
            Database.update(lstCon);
        } catch(Exception e){
            Boolean bExpectedExceptionThrown =  (e.getMessage().contains(Label.CWS_PrimaryContact_Error)) ? true : false;
            System.AssertEquals(bExpectedExceptionThrown, true);
        } 
    }
    //To test After insert/update logic when primary contact is checked
    @isTest static void testAfterInsertUpdateLogicForPC(){
        Map<String, Object> userExtraFields1=new Map<String, Object>{
            'isActive'=>true,                
                'Email' => 'test@gmail.com'               
                };
        //UserRole portalRole = [Select Id,name From UserRole Limit 1];
        User userObj1 = CWS_UTLDataFactory.createUser('Admin','disty@test1.com','Dist','System Administrator','CEO',
                                                      'disty@test.com.Admin.cw',userExtraFields1,true);
        Account objAcct = [Select id from Account Limit 1];
        Contact objCon = CWS_UTLDataFactory.createContact('TestFirstName1','TestLastName1',objAcct.Id,new Map<String, Object>{'CWS_Primary_Contact__c' => true},false);
        Database.insert(objCon);
        
        objCon = [Select id,CWS_Primary_Contact__c,mailingcountryCode,mailingStateCode,mailingPostalCode from Contact where CWS_Primary_Contact__c=false AND AccountId !=null Limit 1];
        objCon.CWS_Primary_Contact__c = true;
        objCon.ownerId = userObj1.Id;
        objCon.CWS_Contact_Status__c = CWS_ConstantClass.CONTACT_STATUS_MQL;
        objCon.mailingcountryCode = 'US';
        objCon.mailingStateCode = 'NY';
        objCon.mailingPostalCode = '12345';
        objCon.Email ='test2@gmail.com';
        objCon.LeadSource = 'Sales Generated';
        system.debug('objCon--'+objCon);
        Database.update(objCon);
        List<Contact> lstCon = [Select Id,Email from Contact where CWS_Primary_Contact__c = true AND AccountId=:objAcct.Id AND AccountId!=null];
        System.AssertEquals(lstCon.size(), 1);
        lstCon[0].Email = '';
        try{
            Database.update(lstCon);
        }
        catch(Exception ex){
            system.assert(ex.getMessage().contains('Please populate the Primary Email Address for this Contact.:'));
        }
        
    }
    //To test before update when the primary contact is unchecked
    @isTest static void testBeforeUpdateUnChkPC(){
        try{
            Account objAcct = [Select id from Account Limit 1];
            Contact objCon = [Select id,CWS_Primary_Contact__c from Contact where AccountId=:objAcct.Id AND AccountId!=null AND CWS_Primary_Contact__c = true Limit 1];
            objCon.CWS_Primary_Contact__c = false;
            Database.update(objCon); 
        } catch(Exception e){
            Boolean bExpectedExceptionThrown =  (e.getMessage().contains(Label.CWS_PrimaryContactUnChk_Error)) ? true : false;
            System.AssertEquals(bExpectedExceptionThrown, true);
        } 
    }
    //BED-640 Method to check integration field change scenario
    @isTest static void testCheckIntegFieldChange(){
        Contact objCon = [Select Id,FirstName from Contact where CWS_Integration_Sync_Status__c=:CWS_ConstantClass.INT_STATUS_SYNCED AND AccountId!=null Limit 1];
        objCon.FirstName = 'changeFirstName1';
        Database.update(objCon);
        objCon = [Select id,CWS_Integration_Sync_Status__c from Contact where id=:objCon.Id AND AccountId!=null Limit 1];
        //system.assertEquals(objCon.CWS_Integration_Sync_Status__c,CWS_ConstantClass.INT_STATUS_READY); 
    }   
//OBD-107 method to test update phone and email on task 
	@isTest static void updatePhoneAndEmailonTask(){
        test.startTest();        
       
            Account acc =[SELECT Id FROM Account LIMIT 1];
            Map<String, Object> mapConFieldValues = new Map<String, Object>{
                'CWS_Primary_Billing_Contact__c' => false,
                'Email'=>'testvv@test.com'
            };
            Contact objCon1 = CWS_UTLDataFactory.createContact('Test11FirstName1','Test11LastName1',acc.Id,mapConFieldValues,false);            
            insert objCon1;
        	Map<String, Object> mapConFieldValues1 = new Map<String, Object>{
                'CWS_Primary_Billing_Contact__c' => false,
                'Email'=>'test123@test.com'
            };
        	Contact objCon2 = CWS_UTLDataFactory.createContact('Test11FirstName2','Test11LastName2',acc.Id,mapConFieldValues1,false);            
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