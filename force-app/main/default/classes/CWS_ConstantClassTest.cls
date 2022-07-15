/* Class Name   : CWS_ConstantClass_Test
 * Description  : Test Class for CWS_ConstantClass
 * Created By   : Aakash 
 * Created On   : 4/3/2020

 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID      Description 
 Aakash                     4/3/2020                                    Initial Version
 Jeff Cochran               11/23/2020                                    Fake update for test class inclusion in Gearset deployment
 * ---------------------------------------------------------------------------------------------------------------------------------------
 
*/
@isTest
public class CWS_ConstantClassTest {
     //This is to test Constant class variables
     @isTest static void testConstantClassMethod(){
         //Start running the testing scenario
         Test.startTest();
         CWS_ConstantClass constObj = new CWS_ConstantClass(); // Class being called 
         system.assertNotEquals(constObj,null);
         Test.stopTest(); //Stop the executation of test 
     }
}