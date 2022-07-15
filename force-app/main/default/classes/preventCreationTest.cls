@IsTest
private class preventCreationTest{
    @isTest static void testCaseCreation(){
       
       Blocked_Domains__c objBlcked = new Blocked_Domains__c(Name='home.com');
        insert objBlcked;
        
        Account acc = new Account(Name = 'TestAcc2');
        Insert acc;
         
        Contact con = new Contact(LastName = 'TestCont2', AccountId = acc.Id,Email='test@home.com');
        Insert con;
        
        try{
        Case cas = new Case(Status ='New', Priority = 'Medium', Origin = 'Email', AccountId = acc.Id,Contactid = con.id);
        insert cas;
        }
        catch(Exception ex){
        }
         
    }

}