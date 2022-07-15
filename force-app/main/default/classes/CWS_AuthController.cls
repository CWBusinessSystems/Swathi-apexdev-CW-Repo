public with sharing class CWS_AuthController{
    Public Map<String, String> mapDSSettings;
    Public ApexPages.Standardcontroller controller;
    public static Boolean isSandbox{
        get{
            if (isSandbox == null){
                isSandbox = [Select IsSandbox from Organization limit 1].IsSandbox;
            }
            return isSandbox;
        }
        private set;
    }
    Public CWS_AuthController(){
        //GET DSAPIUSERID, DSINTEGRATIONKEY, PRIVATEKEY, DSAPIACCOUNTID    
        mapDSSettings=new Map<String, String>();
        for(CWS_Renewal_Email_Settings__mdt mdt:[Select DeveloperName, MasterLabel, CWS_Value__c
                from CWS_Renewal_Email_Settings__mdt limit 100]){
            mapDSSettings.put(mdt.MasterLabel, mdt.CWS_Value__c);
        }
    }
    
    Public PageReference getConsent(){
        String baseUrl;
        if(isSandbox==true){
            baseUrl='https://account-d.docusign.com/oauth/auth';
        }
        else{
            baseUrl='https://account.docusign.com/oauth/auth';
        }
        Pagereference ref=new Pagereference(baseUrl+'?response_type=code&scope=signature%20impersonation&client_id='+
             mapDSSettings.get('DSINTEGRATIONKEY')+
            '&redirect_uri='+mapDSSettings.get('REDIRECTURI'));
        return ref;
    }
    

}