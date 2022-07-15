@isTest
public class CWS_TZ_Update_Test {

    public static testmethod void updateAccount(){
        Account a = new Account();
        a.name = 'test acc';
        a.tz_sync__c = false;
        insert a;
        
        Test.startTest();
        Database.executeBatch(new CWS_TZ_Update(),1); 
        Test.stopTest();
    }
}