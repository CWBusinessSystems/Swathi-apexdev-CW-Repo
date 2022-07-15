/*Class Name: CWS_ShareRecordsCtrl_Test
*Description: Test Class for CWS_ShareRecordsWithDistyResellerCtrl
*Created By: Ankit
*Created On: 5/24/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                 05/24/2020        BED-6479            Initial Version
*/

@isTest(SeeAllData=false)
public class CWS_ShareRecordsCtrl_Test{

   @testSetup static void createTestData(){
        //create custom setting data
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'CWS_Distributor_Reseller__c','Quote','SBQQ__QuoteDocument__c'});    
        
        //Create Sold TO Account
        Map<String, Object> soldtoaccountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'currencyIsoCode'=>'EUR'};
        Account soldtoaccount=CWS_UTLDataFactory.createAccount('TestAccount', soldtoaccountFieldValues,true);
        
        //UserRole portalRole = [Select Id,name From UserRole Limit 1];
        
        Profile profile1;
        Profile profile;
        
         // Force Reviewer review addtion of set to have null check
        list<String> profSet =  new list<String>{'System Administrator','CWS_Partner_Community_User'};
        
        // Force Reviewer review null check
        if(profSet != null){
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
            'CWS_Is_Distributor__c' => true
            };
        Account[] distiAccounts=CWS_UTLDataFactory.createBulkAccounts('DistributorAccount{!i}', distributorAccountFieldValues,2,true);   
        
        Map<String, Object> additionalFieldValues = new map<String, Object>{'MailingCountry'=> 'United States'};
        Contact conObj = CWS_UTLDataFactory.createContact('Test','PartnerContact',distiaccounts[0].Id,additionalFieldValues,true);
        
        Map<String, Object> partnersExtraFields =new Map<String, Object>{
            'profileid'=>profile.id,
            'ContactId'=>conObj.Id
            };
                                         
        user distyUser = CWS_UTLDataFactory.createPartnerUser(partnersExtraFields,true);
        
        // Create Distributr Reseller Records 
        CWS_UTLDataFactory.createDistributorReseller(soldtoaccount.Id,distiaccounts[0].Id, 'Distributor','Fulfillment', null, null, true);   
        
        Opportunity opp = CWS_UTLDataFactory.createOpportunity('optyName',soldtoaccount.Id, new Map<String, Object>{'CloseDate'=>System.today(),'CWS_Bill_To_Account__c'=>distiaccounts[0].Id,'CWS_Route_to_Market__c'=>'Channel','CWS_Store_Bill_To_Id__c' => distiaccounts[0].Id}, true);
        SBQQ__Quote__c quote = CWS_UTLDataFactory.createQuote(soldtoaccount.Id,opp.id,new Map<String, Object>{'CWS_Bill_To_Account__c'=>distiaccounts[0].Id,'CWS_Route_to_Market__c'=>'Channel','CWS_Shared_Bill_To_Id__c'=> distiaccounts[0].Id}, true);    
   }
   
    @isTest static void testMethod1(){

        Test.starttest();
        
        list<CWS_Distributor_Reseller__c> distyObj = [Select id,CWS_isReactive__c,CWS_Active__c,CWS_Account__c,CWS_Distributor_ResellerAcc__c from CWS_Distributor_Reseller__c];
        
        CWS_ShareRecordsWithDistyResellerCtrl.identifyContext(null,distyObj[0],'Activate');
        
        distyObj[0].CWS_isReactive__c = true;
        
        if(distyObj != null){
            update distyObj;
        }
        
        CWS_ShareRecordsWithDistyResellerCtrl.identifyContext(null,distyObj[0],'Deactivate');
        
       // system.assertEquals(distyObj[0].CWS_Active__c,false);
        
        CWS_ShareRecordsWithDistyResellerCtrl.identifyContext(null,distyObj[0],'Activate');
        
        system.assertEquals(distyObj[0].CWS_Active__c,true);
        
        Test.stopTest();
    }
    
    @isTest static void testMethod2(){

        Test.starttest();
        
        list<CWS_Distributor_Reseller__c> distyObj = [Select id,CWS_isReactive__c,CWS_Active__c,CWS_Account__c,CWS_Distributor_ResellerAcc__c from CWS_Distributor_Reseller__c];
        
        String success = CWS_ShareRecordsWithDistyResellerCtrl.identifyContext(null,distyObj[0],'Activate');
        
        Account acc = [Select id from Account where CWS_Is_Distributor__c = false limit 1];
        String success1 = CWS_ShareRecordsWithDistyResellerCtrl.identifyContext(acc.id,distyObj[0],'Deactivate');
        
        system.assertEquals(distyObj[0].CWS_Active__c,true);
        
        Test.stopTest();
    }
    
    @isTest static void testMethod3(){

        Test.starttest();
        
        list<Account> soldToAcc = [Select id,ownerID from Account where CWS_Is_Distributor__c = false];
        list<User> partnerUser = [Select id from User where contact.lastname = 'PartnerContact'];
        soldToAcc[0].ownerID = partnerUser[0].id;
        
        if(soldToAcc != null){
            update soldToAcc;
        }
        
        list<CWS_Distributor_Reseller__c> distyObj = [Select id,CWS_isReactive__c,CWS_Active__c,CWS_Account__c,CWS_Distributor_ResellerAcc__c from CWS_Distributor_Reseller__c];
        if(distyObj != null){
            CWS_ShareRecordsWithDistyResellerCtrl.identifyContext(null,distyObj[0],'Activate');
        }
        
        system.assertEquals(distyObj[0].CWS_Active__c,true);
        
        Test.stopTest();
    }
    
     @isTest
     static void testMethod4(){

        Test.starttest();
        
        list<CWS_Distributor_Reseller__c> distyObj = [Select id,CWS_isReactive__c,CWS_Active__c,CWS_Account__c,CWS_Distributor_ResellerAcc__c from CWS_Distributor_Reseller__c];
        
        CWS_ShareRecordsWithDistyResellerCtrl.identifyContext(null,distyObj[0],'Activate');
        
        distyObj[0].CWS_isReactive__c = true;
        
        if(distyObj != null){
            update distyObj;
        }
        
        list<Account> soldToAcc = [Select id,ownerID from Account where CWS_Is_Distributor__c = true];
        soldToAcc[0].CWS_Is_Distributor__c = false;
        if(soldToAcc != null){
            update soldToAcc;
        }
        
        CWS_ShareRecordsWithDistyResellerCtrl.identifyContext(null,distyObj[0],'Deactivate');
        
        system.assertEquals(distyObj[0].CWS_Active__c,true);
        
        Test.stopTest();
    }
}