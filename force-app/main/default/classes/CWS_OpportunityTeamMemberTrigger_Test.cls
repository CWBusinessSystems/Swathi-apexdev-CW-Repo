/*Class Name: CWS_OpportunityTeamMemberTrigger_Test
*Description: Test Class for CA_OpportunityTeamMemberTrigger
*Created By: 
*Created On: 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Khayam                 04/03/2020        BED-6326             Opp Team Access to Quote 
*/
@isTest(SeeAllData=false)
public class CWS_OpportunityTeamMemberTrigger_Test {
    
    // Test data setup 
    @testSetup static void createTestData(){
        //To-Do Remove when context is covered
        List<OpportunityTeamMember> Optym = new List<OpportunityTeamMember>();
        CWS_OpportunityTeamMemberTriggerHandler OPTH = new CWS_OpportunityTeamMemberTriggerHandler();
        OPTH.BeforeInsert(Optym);
        CWS_UTLDataFactory.insertTriggerSwitch(new List<String>{'OpportunityTeamMember'});   
        
    
    //Create Account
        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01'),
            'BillingCountry'=>'United States',
                'BillingCountryCode'=>'US',
                'currencyIsoCode'=>'USD'};
        Account sAccount=CWS_UTLDataFactory.createAccount('TestAccount', accountFieldValues,true);
        
    }
    
    /*
* method to test shared Quotes of Oppty
*/
    @isTest static void testshareQuotesofOpportunityUpdate(){
       
        
        System.runAs(new User(Id = Userinfo.getUserId())) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Id accId = [select Id from Account Limit 1].Id;
        
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            String uniqueName = orgId + dateString + randomInt;
            User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
            
            List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
            for(PermissionSet pset:[SELECT Id FROM PermissionSet WHERE Name in('CWS_Sales_Rep_CPQ','SteelBrickCPQUser')] ){
                psa.add(new PermissionSetAssignment(AssigneeId = rep.id, PermissionSetId = pset.Id));
            }
            if(!psa.isEmpty()){
                system.debug('psa--'+psa);
                insert psa;
            }
            ID tmID = UserInfo.getUserId();
        Test.startTest();
        System.runAs(rep){

            Opportunity objOpportunity = new Opportunity(Name='abc',stageName='Analysis',closedate=System.today(),CWS_Bill_To_Account__c=accId);
            if (objOpportunity != NULL) {
                insert objOpportunity;   
            }
            User teamMember;
            if (tmID != NULL) {
                teamMember = [SELECT Id FROM User WHERE Id =: tmID AND UserType = 'Standard' AND IsActive=true LIMIT 1];
            }
            SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c=objOpportunity.id);
                
            if(quote != NULL){
                insert quote;
            }
            
            OpportunityTeamMember opmemRec=new OpportunityTeamMember(OpportunityId=objOpportunity.id,UserId=teamMember.Id,TeamMemberRole='CEO', OpportunityAccessLevel='Edit');

            if (opmemRec != NULL) {
                insert opmemRec;
            }
            if(quote.id != null && quote != NULL){
                List<SBQQ__Quote__Share> results = [SELECT id from SBQQ__Quote__Share where parentid =: quote.id];
                System.assertNotEquals(results.size(),0);
            }   
        }
        }
        
        
        Test.stopTest();
    }
    
    /*
    * method to test unshareQuotesofOpportunity
    */
     @isTest static void testunshareQuotesofOpportunity(){
        System.runAs(new User(Id = Userinfo.getUserId())) {
        Test.startTest();
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Id accId = [select Id from Account Limit 1].Id;
         
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep','CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);

         List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
         for(PermissionSet pset:[SELECT Id FROM PermissionSet WHERE Name in('CWS_Sales_Rep_CPQ','SteelBrickCPQUser')] ){
             psa.add(new PermissionSetAssignment(AssigneeId = rep.id, PermissionSetId = pset.Id));
         }
         if(!psa.isEmpty()){
             system.debug('psa--'+psa);
             insert psa;
         }
         
        ID tmID = UserInfo.getUserId();
        System.runAs(rep){

            Opportunity objOpportunity = new Opportunity(Name='abc',stageName='Analysis',closedate=System.today(),CWS_Bill_To_Account__c=accId);
            if (objOpportunity != NULL) {
                insert objOpportunity;
            }
            User teamMember;
            if (tmID != NULL) {
                teamMember = [SELECT Id FROM User WHERE Id =: tmID AND UserType = 'Standard' AND IsActive=true LIMIT 1];
            }
            SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c=objOpportunity.id);
            if (quote != NULL) {
                insert quote;
            }
            OpportunityTeamMember opmemRec=new OpportunityTeamMember(OpportunityId=objOpportunity.id,UserId=teamMember.Id,TeamMemberRole='CEO', OpportunityAccessLevel='Edit');

            if (opmemRec != NULL) {
                insert opmemRec;
            }
            if(quote.id != NULL && teamMember.id != NULL){
                SBQQ__Quote__share qShare = [SELECT id from SBQQ__Quote__Share where AccessLevel='Edit' and userorgroupid=:teamMember.Id and parentid =: quote.id];

                if (opmemRec != NULL) {
                    delete opmemRec;
                }
                if(qShare.id != NULL){
                    List<SBQQ__Quote__Share> results = [SELECT Id from SBQQ__Quote__Share where id =: qShare.id];
                    System.assertEquals(results.size(),0); 
                }
            }
            
        }
     
        
        Test.stopTest();
        }
     } 
         @isTest
        Static Void OptyMember() {
            ID tmID = UserInfo.getUserId();
            Id accId = [select Id from Account Limit 1].Id;
             Opportunity objOpportunity = new Opportunity(Name='abc',stageName='Analysis',closedate=System.today(),CWS_Bill_To_Account__c=accId);
           // Opportunity objOpportunity = [Select Id, OpportunityId From OpportunitySplit Where OpportunityId = '0062000000a5Ot9'];
            if (objOpportunity != NULL) {
                insert objOpportunity;   
            }
            User teamMember;
            if (tmID != NULL) {
                teamMember = [SELECT Id FROM User WHERE Id !=: tmID AND UserType = 'Standard' AND IsActive=true LIMIT 1];
            }
               Test.startTest();
             OpportunityTeamMember opmemRec=new OpportunityTeamMember(OpportunityId=objOpportunity.id,UserId=teamMember.Id,TeamMemberRole='CEO', OpportunityAccessLevel='Edit');              
           String opmemRecid = opmemRec.id;
            insert opmemRec;
            //List<OpportunitySplit> lstSplit = [Select Id, OpportunityId From OpportunitySplit Where OpportunityId =:objOpportunity.id];
				//delete lstSplit;
              // delete opmemRec;
CWS_OpportunityTeamMemberTriggerHandler opth = new CWS_OpportunityTeamMemberTriggerHandler();
opth.BeforeUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());  
            opth.BeforeDelete(new Map<Id, SObject>());  
              opth.AfterUpdate(new Map<Id, SObject>(), new Map<Id, SObject>()); 
             // opth.AfterUndelete(new Map<Id, SObject>(),new Map<Id, SObject>());

            Test.stopTest();
          // delete opmemRec;
           // undelete new OpportunityTeamMember(id = opmemRecid ) ;
            
        
        
        }

    
    
}