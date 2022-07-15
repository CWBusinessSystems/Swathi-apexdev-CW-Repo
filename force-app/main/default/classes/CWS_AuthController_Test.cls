@istest(seealldata = false)
public class CWS_AuthController_Test {
    
    @istest static void testOrg(){
        // CWS_AuthController.isSandbox = null;
        CWS_AuthController ca = new CWS_AuthController();
        PageReference pr = ca.getConsent();
        Boolean isSandbox = [Select IsSandbox from Organization limit 1].IsSandbox;
        system.assertEquals(CWS_AuthController.isSandbox, isSandbox);
    }
}