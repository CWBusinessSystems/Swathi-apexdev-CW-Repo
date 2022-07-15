/* Class Name   : CWS_ManageIntegrationCallout_Test
 * Description  : Test Class for CWS_ManageIntegrationCallout Class
 * Created By   : Megha Shetty
 * Created On   : 8/10/2020
 *Modification Log
*------------------------------------------------------------------------------------------
*Developer                          Date            User Story              Description
*------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
public class CWS_ManageIntegrationCallout_Test {
    @testSetup
    static void createTestData(){
        
        // Create Account
        Map<String, Object> accountFieldValues=new Map<String, Object>{
            'CWS_Payment_Terms__c'=>'Due Upon Receipt',
            'currencyIsoCode'=>'USD',
            'CWS_Account_Restriction_Status__c'=>'No Restriction'
            };
        Map<String, Object> accountFieldValues1=new Map<String, Object>{
            'CWS_Payment_Terms__c'=>'Due Upon Receipt',
            'currencyIsoCode'=>'USD',
            'SBQQ__PriceHoldEnd__c'=>Date.ValueOf('2020-01-01')
            };
        Account account1=CWS_UTLDataFactory.createAccount('TestAccount', accountFieldValues,true);
        //Account account2=CWS_UTLDataFactory.createAccount('TestAccount1', accountFieldValues1,true);
        
        Map<String, Object> contactFieldValues=new Map<String, Object>{
            'CWS_Primary_Contact__c'=>true
           
            };
        Contact primaryContact = CWS_UTLDataFactory.createContact('Mark', 'Anthony', account1.Id, contactFieldValues, true);
        //Contact primaryContact2 = CWS_UTLDataFactory.createContact('Mark', 'Gonzalase', account2.Id, contactFieldValues, true);
        
    }
    
    @isTest
    static void testQuoteCategorySearch(){
        
        Test.startTest();
        List<Contact> contactIds = [Select id from Contact];
        List<Id> Ids = new List<Id>();
        for(Contact c: contactIds){
            Ids.add(c.Id);
        }
        ID jobID = System.enqueueJob(new CWS_ManageIntegrationCallout(Ids,'Contact Id'));
        //CWS_ManageIntegrationCallout instance = new CWS_ManageIntegrationCallout();
        //CWS_ManageIntegrationCallout.manageIntegrationCallout(Ids,'Contact Id');
        //CWS_ManageIntegrationCallout.CWS_ManageIntegrationRequest.Id = String.valueOf(contactIds[0]);
        
        Test.stopTest();
    }

}