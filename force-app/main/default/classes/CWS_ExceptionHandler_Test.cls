/* Class Name   : CWS_ExceptionHandler_Test
 * Description  : Test Class for CWS_ExceptionHandler_Test
 * Created On   : 06-April-2020
 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID      Description 
 
 * 
 
*/
@isTest(SeeAllData=false)
public class CWS_ExceptionHandler_Test {
    @isTest static  void causeException(){
        Test.StartTest();
        Account acc = new Account();
         try{
            acc.BillingLongitude=1/0;
            if(acc!=null){
            insert acc;
            }
         }
         catch(Exception e){
             CWS_ExceptionHandler.logException(e,'CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'insertException' , 
                                    '',null,null, 'While inserting error log record on handler class' ,null);
         }
         System.assertEquals (acc.id, null);
         Test.stopTest();
         
     }
     @isTest static  void causeException2(){
        Test.StartTest();
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
       
            list<Account> acList = new list <Account>();
             Account acc = new Account();
             acc.name ='name';
             acList.add(acc);
             if(acList.size()>0){
             acc.BillingCountry='United States';
             acc.BillingCity='Mountain View';
             acc.BillingStreet='1600 AMPHITHEATRE PARKWAY';
             insert acList;
             }
             List<CWS_Address__c> lst = new List<CWS_Address__c> ();
             CWS_Address__c newAddr = new CWS_Address__c();
            newAddr.CWS_Country__c =  'Canada';
            newAddr.CWS_Street__c =  'Gachibowli';
            newAddr.CWS_City__c = 'Hyderabad';
            newAddr.CWS_State__c =  'Ontario';
            newAddr.CWS_Zipcode__c =  '500184';
            newAddr.CWS_Account__c = acList[0].id;
          
            if(newAddr!=null){
            insert newAddr;
            }

            newAddr = new CWS_Address__c();
            newAddr.CWS_Country__c =  'Canada';
            newAddr.CWS_Street__c =  'Gachibowli';
            newAddr.CWS_City__c = 'Hyderabad';
            newAddr.CWS_State__c =  'Ontario';
            newAddr.CWS_Zipcode__c =  '500184';
            newAddr.CWS_Account__c = acList[0].id;
           lst.add(newAddr);
            if(lst.size()>0){
            srList = Database.insert(lst,false);
            
            System.debug('--test---'+srList);
            CWS_ExceptionHandler.logDMLSaveResults(srList,'CWS_ExceptionHandler' , 'test','test' , 'test' , 'String context' );
            }
                
        System.assertNotEquals (srList[0].id, null);

        Test.stopTest();
     }
    /*
     @isTest static  void causeException5(){
        Test.StartTest();
        List<Database.DeleteResult> drList= new List<Database.DeleteResult>();
        
            list<Account> accList = new list<Account>();
            Account acc = new Account(name='Test Acc');
            if(acc!=null){
            acc.BillingCountry='United States';
            acc.BillingCity='Mountain View';
            acc.BillingStreet='1600 AMPHITHEATRE PARKWAY';
            insert acc;
            }

            Contact con = new Contact();
            con.Lastname='contactName';
            con.AccountId= acc.Id;
         	con.email ='test@gmail.com';
            if(con!=null){
            insert con;
            }

            Database.DeleteResult dr = Database.delete(acc,false);
            drList.add(dr);
            CWS_ExceptionHandler.logDMLDelResults(drList ,'CWS_ExceptionHandler' , 'test','test' , 'test' , 'String context' );
            System.assertNotEquals (drList[0].id, null);
            Test.stopTest();
     }*/
     @isTest static void causeException4(){
        Test.StartTest();
        List<Database.UpsertResult> upList = new List<Database.UpsertResult>();
        Account acc = new Account();
        list<Account> acList = new list <Account>();
            try{
                 acc.name ='test';
                 acList.add(acc);
                 if(acList.size()>0){
                 acc.BillingCountry='United States';
                 acc.BillingCity='Mountain View';
                 acc.BillingStreet='1600 AMPHITHEATRE PARKWAY';
                 insert acList;
                }
                 List<CWS_Address__c> lst = new List<CWS_Address__c> ();
                 CWS_Address__c newAddr = new CWS_Address__c();
                                  CWS_Address__c newAddr1 = new CWS_Address__c();

                newAddr.CWS_Country__c =  'Canada';
                newAddr.CWS_Street__c =  'Gachibowli';
                newAddr.CWS_City__c = 'Hyderabad';
                newAddr.CWS_State__c =  'Ontario';
                newAddr.CWS_Zipcode__c =  '500184';
                newAddr.CWS_Account__c = acList[0].id;
                
                newAddr1 = new CWS_Address__c();
                newAddr1.CWS_Country__c =  'Canada';
                newAddr1.CWS_Street__c =  'Gachibowli';
                newAddr1.CWS_City__c = 'Hyderabad';
                newAddr1.CWS_State__c =  'Ontario';
                newAddr1.CWS_Zipcode__c =  '787888';
                newAddr1.CWS_Account__c = '7687687677700';
               
                lst.add(newAddr);
                lst.add(newAddr1);
                if(lst.size()>0){
                insert lst;
                }

                lst[0].CWS_Zipcode__c='6767888';
                if(lst.size()>0){
                upList = Database.upsert(lst,false);
                CWS_ExceptionHandler.logDMLUpsertResults(upList,'CWS_ExceptionHandler' , 'test',
                                         'test' , 'test' , 'String context' );
                }
            
            }Catch(Exception e){
                System.debug('uplist --- ' + upList);
                CWS_ExceptionHandler.logDMLUpsertResults(upList,'CWS_ExceptionHandler' , 'test',
                                         'test' , '' , 'String context' );
            }
        System.assertNotEquals (acList[0].id, null);
        Test.stopTest();
     }
     @isTest static  void causeException3(){
        Test.StartTest();
        Account acc = new Account();
         try{
            acc.BillingLongitude=1/0;
            if(acc!=null){
            insert acc;
            }
         }
         catch(Exception e){
             CWS_ExceptionHandler.insertException('CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'insertException' ,null, 'Exception Handler',null ,null ,null,null,null , 'While inserting error log record on handler class' ,null);

         }
         System.assertEquals (acc.id, null);
        Test.stopTest();
     }
    
    @isTest static void initalisedmlexception(){
         String errorResult;
        list<CWS_Error_Log__c> errLogList = new list<CWS_Error_Log__c>();
        List<Account> acclist = new  List<Account>();
        Account acc = new Account();         
        acc.BillingLongitude= 8/123;
        acclist.add(acc);
        List<Database.SaveResult> insertResults = Database.insert(acclist, false);
            for(Integer i=0;i<insertResults.size();i++){
                if (!insertResults.get(i).isSuccess()){
                    if(String.isBlank(errorResult)){
                        errorResult = CWS_ConstantClass.INT_STATUS_ERROR;
                    }
                    CWS_Error_Log__c errlogObj = CWS_ExceptionHandler.initializeAndReturnDMLErrorLogs('CWS_MinCommitUploadCtrl','insertMinCommits','',
                        JSON.serialize( insertResults.get(i).getErrors()),'','CWS_Min_Commit_Errors','');
                        errLogList.add(errlogObj);
                }
    }
    }
    
    @isTest static void logErrors(){        
        try{
            Account acc = new Account();
            acc.BillingLongitude= 8/123;
            insert acc;
        }
        catch(exception ex){
            CWS_ExceptionHandler.logErrors('CWS_QuoteTriggerHelper','AfterUpdate','','Error Occured while sending email','','Sending Email message failed','');
        }
    }
    
    @isTest static void logDmlSaveresults(){
         List<Account> acclist = new  List<Account>();
        Account acc1 = new Account();         
        acc1.BillingLongitude= 8/123;
        acc1.BillingLatitude = 8/123;
        acc1.name ='tets';
        acclist.add(acc1);        
         
        Account acc = new Account();
        acc.name ='tets1';
        acc.BillingCountry='United States';
        acc.BillingCity='Mountain View';
        acc.BillingStreet='1600 AMPHITHEATRE PARKWAY';
        acclist.add(acc); 
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Master_Data_Admin',
                                                 'CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
        system.runAs(rep){          
        List<Database.SaveResult> results = Database.insert(acclist,false);
            CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_QuoteTriggerHelper' , 'AfterInsert','Opportunity', null , null ); 
        } 
    }
    
        @isTest static void logDmlupsertresults(){
         List<Account> acclist = new  List<Account>();
        Account acc1 = new Account();         
        acc1.BillingLongitude= 8/123;
        acc1.BillingLatitude = 8/123;
        acc1.name ='tets';
        acclist.add(acc1);        
         
        Account acc = new Account();
        acc.name ='tets1';
        acc.BillingCountry='United States';
        acc.BillingCity='Mountain View';
        acc.BillingStreet='1600 AMPHITHEATRE PARKWAY';
        acclist.add(acc); 
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Master_Data_Admin',
                                                 'CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
        system.runAs(rep){          
        List<Database.upsertResult> results = Database.upsert(acclist,false);
            CWS_ExceptionHandler.logDMLUpsertResults(results, 'CWS_QuoteTriggerHelper' , 'AfterInsert','Opportunity', null , null ); 
        } 
    }
   
       @isTest static void logDmlDelResults(){
         List<Account> acclist = new  List<Account>();
        Account acc1 = new Account();         
        acc1.BillingLongitude= 8/123;
        acc1.BillingLatitude = 8/123;
        acc1.name ='tets';
        acclist.add(acc1);        
         
        Account acc = new Account();
        acc.name ='tets1';
        acc.BillingCountry='United States';
        acc.BillingCity='Mountain View';
        acc.BillingStreet='1600 AMPHITHEATRE PARKWAY';
        acclist.add(acc); 
        
           Insert acclist;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User rep = CWS_UTLDataFactory.createUser(uniqueName.substring(18, 23), uniqueName + '@test' + orgId + '.org','lName','CWS_Sales_Rep',
                                                 'CEO',uniqueName + '@test' + orgId + '.org',new Map<String, Object>(),true);
        system.runAs(rep){          
        List<Database.DeleteResult> results = Database.Delete(acclist,false);
            CWS_ExceptionHandler.logDMLDelResults(results, 'CWS_QuoteTriggerHelper' , 'AfterInsert','Opportunity', '',''  ); 
        } 
    }
    
    @isTest static  void causeListException(){
        Test.StartTest();
        Account acc = new Account();
		List<String> strList=new List<String>();
        strList.add('test');
        strList.add('xyz');
        try{
            acc.BillingLongitude=1/0;
            if(acc!=null){
            insert acc;
            }
         }
         catch(Exception e){
             CWS_ExceptionHandler.logListException(e,'CWS_Error_Log__c' , 'CWS_ExceptionHandler_Test' , 'insertException' , 
                                    '',null,strList, 'While inserting error log record on handler class' ,null);
         }
         System.assertEquals (acc.id, null);
         Test.stopTest();
         
     }
    
}