@IsTest
public class AdVic_RelatedListTest {

    @TestSetup
    static void testSetup() {
        Account acct = new Account(Name = 'Apex Test');
        insert acct;
        Contact con = new Contact(FirstName = 'Johnny', LastName = 'Test', AccountId = acct.Id, Email = 'apextest@advic.com');
        insert con; 
    }

    // TODO increase test robustness.
    @IsTest
    static void validateCmpData() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Apex Test'];
        
        String respJSON = AdVic_RelatedList.getListDataJSON(a.Id, 'Contact', 'AccountId', 'AND FirstName = \'Johnny\'', 'Id', 'ASC');
        AdVic_RelatedList.CmpData dataObj = (AdVic_RelatedList.CmpData) JSON.deserialize(respJSON, AdVic_RelatedList.CmpData.class);
        respJSON = AdVic_RelatedList.getListDataJSON(a.Id, 'Contact', 'AccountId', null, 'Id', 'DESC');
        
        Contact assertC = [SELECT Id FROM Contact WHERE LastName ='Test'];
        
        System.assert(dataObj.records[0].Id == assertC.Id);
    }
    
}