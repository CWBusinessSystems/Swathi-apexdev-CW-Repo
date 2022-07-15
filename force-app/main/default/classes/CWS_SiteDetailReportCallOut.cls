/*Class Name: CWS_SiteDetailReportCallOut
*Description: Class for making integration callouts of SiteDetailReport Component added on the Invoice Lightning Page
*Created By: Mahak Bansal
*Created On: 30/6/2021
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Mahak Bansal		    30/6/2021		OBD-154		           Initial Version
*/
public without sharing class CWS_SiteDetailReportCallOut {
   
    /**
    * @description Method to hit to check if need to show the Site Detail Report button on the UI
    * @params invoiceId - the recordId of the invoice , where SiteDetailReport API is required to be fetched
    */
    @AuraEnabled
    public static SiteDetailResponse showSiteDetailReport(String invoiceId)
    {
        SiteDetailResponse sResponse;
        try{ 
            Zuora__ZInvoice__c invoiceRec;  
            if(
                Zuora__ZInvoice__c.SObjectType.getDescribe().isAccessible() &&
                Schema.SObjectType.Zuora__ZInvoice__c.fields.Name.isAccessible() &&
                Schema.SObjectType.Zuora__ZInvoice__c.fields.CWS_CMS_Invoice__c.isAccessible() &&
                Schema.SObjectType.Zuora__ZInvoice__c.fields.Zuora__InvoiceDate__c.isAccessible() &&
                Schema.SObjectType.Zuora__ZInvoice__c.fields.Zuora__Account__c.isAccessible()  
            ){
                invoiceRec= [SELECT ID,Name,CWS_CMS_Invoice__c,Zuora__InvoiceDate__c,Zuora__Account__r.CWS_Account_Unique_Identifier__c  
                            FROM Zuora__ZInvoice__c 
                            WHERE id=:invoiceId];    
            } 
            else {
                sResponse=new SiteDetailResponse();
                sResponse.showSiteDetailButton=false;
                sResponse.message=Label.CWS_Site_Detail_Comp_Permission;
                return sResponse;
            }
            
            if( invoiceRec!=null && invoiceRec.CWS_CMS_Invoice__c== 'TRUE'){
                sResponse=new SiteDetailResponse();
                sResponse.showSiteDetailButton=true;
                sResponse.message='success';
                return sResponse;              
            }else{
            	sResponse=new SiteDetailResponse();
                sResponse.showSiteDetailButton=false;
                sResponse.message='No invoice record available';
                return sResponse;    
            }
            
        }
        catch(Exception e){
            sResponse=new SiteDetailResponse();
            sResponse.showSiteDetailButton=false;
            sResponse.message='Exception:'+e.getMessage();
            CWS_ExceptionHandler.logException(e, 'CallOut' , 'CWS_SiteDetailReportCallOut','showSiteDetailReport' ,'API response', null, invoiceId ,'showSiteDetailReport' , null);
            return sResponse;
        }
    }

    public class SiteDetailResponse{
       @AuraEnabled
       public Boolean showSiteDetailButton{get;set;}
       @AuraEnabled
       public String message{get;set;}
    }
    /**
    * @description Method to hit the SiteDetailReport API 
    * @params invoiceId - the recordId of the invoice , where SiteDetailReport API is required to be fetched
    */
    @AuraEnabled
    public static GetSiteDetailResponse getSiteDetailReport(Id invoiceId){
        GetSiteDetailResponse getSiteDetailResponse =new GetSiteDetailResponse();        
        getSiteDetailResponse.isSuccess=false;
        getSiteDetailResponse.body='Error/Issue';
        
        String siteDetailReport;
        try{           
            //Fetch the invoice record detail, as required to be passed in the parameters of the API Call.
            Zuora__ZInvoice__c invoiceRec;
            if(
                Zuora__ZInvoice__c.SObjectType.getDescribe().isAccessible() &&
                Schema.SObjectType.Zuora__ZInvoice__c.fields.Name.isAccessible() &&
                Schema.SObjectType.Zuora__ZInvoice__c.fields.CWS_CMS_Invoice__c.isAccessible() &&
                Schema.SObjectType.Zuora__ZInvoice__c.fields.Zuora__InvoiceDate__c.isAccessible()   &&
                Schema.SObjectType.Zuora__ZInvoice__c.fields.Zuora__Account__c.isAccessible()                
            ){
                List<Zuora__ZInvoice__c> invoiceRecList= [SELECT Id,Name,Zuora__InvoiceDate__c,Zuora__Account__r.CWS_Account_Unique_Identifier__c  
                                                        FROM Zuora__ZInvoice__c 
                                                        WHERE Id=:invoiceId];
                if(invoiceRecList.size()>0){
                    invoiceRec=invoiceRecList[0];
                }
            }
			
            System.debug('--98--'+invoiceRec);
            if(invoiceRec!=null){
                Integer dateDay= invoiceRec.Zuora__InvoiceDate__c.day();
                Integer dateMonth= invoiceRec.Zuora__InvoiceDate__c.month();
                Integer dateYear= invoiceRec.Zuora__InvoiceDate__c.year();
                String strApendToURL='/'+invoiceRec.Zuora__Account__r.CWS_Account_Unique_Identifier__c+
                                '/'+dateYear+'/'+dateMonth+'/'
                                +invoiceRec.Name+'/'+CWS_ConstantClass.CALLOUT_SITEDETAIL_REPORT_NAME_INITIAL+ invoiceRec.Zuora__Account__r.CWS_Account_Unique_Identifier__c+'_'
                                +invoiceRec.Name+CWS_ConstantClass.CALLOUT_SITEDETAIL_REPORT_EXT; 
                
            	System.debug('@@@102@@strApendToURL'+strApendToURL);
                //strApendToURL ='/ACT-00030433/2019/10/IN00046244/SiteDetails_ACT-00030433_IN00046244.xlsx';//Manual change Mahak
                // Capture the HTTP Response from the callout
                HttpResponse response = invokeCalloutWithParams(CWS_ConstantClass.CALLOUT_SITEDETAIL_REPORT, strApendToURL);
                system.debug('@@@@107@@@RESPONSE'+response);
                if(response.getStatusCode()==200){
                    Blob body = response.getBodyAsBlob();
                    siteDetailReport = EncodingUtil.base64Encode(body);
                    getSiteDetailResponse.isSuccess=true;
            		getSiteDetailResponse.body=siteDetailReport;
            
                    System.debug(response.getStatus());
                    return getSiteDetailResponse;
                }                    
                else {
                    getSiteDetailResponse.isSuccess=false;
            		getSiteDetailResponse.body='InCorrect';
                    return getSiteDetailResponse;
                }        
            }            
            return getSiteDetailResponse;
        }
        catch(Exception e){
            system.debug('@@@Exception@@@');
            CWS_ExceptionHandler.logException(e, 'CallOut' , 'CWS_SiteDetailReportCallOut','getSiteDetailReport' ,'API response', null, invoiceId ,'getSiteDetailReport' , null);
            return getSiteDetailResponse;
        }
        
    }
    
    /**
     * @Developer: Mahak Bansal
     * @Description :  invoke API by appending params in URL
     * @Requirement/issue: OBD-154
     */
    public static HttpResponse invokeCalloutWithParams (String strOperationName, String strApendToURL){

        Map<String, CWS_CalloutDetails>  mapCalloutDetails = new Map<String, CWS_CalloutDetails>();
        // Query through the custom metadata to get the Named credential against the operation name
        // Store the details recieved in an instance of child class 
        // CWS_CalloutDetails - to be used as a wrapper
		List<CWS_CalloutSettling__mdt> mdtCalloutList = [SELECT DeveloperName,CWS_IsActive__c,CWS_Method__c,CWS_NamedCredential__c 
                                                          FROM CWS_CalloutSettling__mdt 
                                                        ];//pdated by Mahak Oct 12,201 .Removed LIMIT from the query.
        //Updated  by Mahak Bansal - Oct. 12, 2021  Removing this security check as all the users dont have access to this metadata, 
        //Also, we would not like the Users to be able to access the custom metadata records to view or update
        //SObjectAccessDecision securityDecision = Security.stripInaccessible( AccessType.READABLE, mdtCalloutList);
        
        //for(CWS_CalloutSettling__mdt mdtCallout : (List<CWS_CalloutSettling__mdt>)securityDecision.getRecords()){
        for(CWS_CalloutSettling__mdt mdtCallout : mdtCalloutList){
            // Create an instance of the wrapper - CWS_CalloutDetails
            CWS_CalloutDetails details = new CWS_CalloutDetails();
            // Copy the information from Metadata to callout details wrapper
            details.strEndpoint=mdtCallout.CWS_NamedCredential__c;
            details.strMethod=mdtCallout.CWS_Method__c;
            details.isActive=mdtCallout.CWS_IsActive__c;
            // Put the details in a map
            mapCalloutDetails.put(mdtCallout.DeveloperName, details);
        }
		
        CWS_CalloutDetails calloutDetails = null;
        HttpRequest request = null;
        HttpResponse response = null;
        Http http = null;
        try {
            // Verify if the map of callout details contains the operation name
            if(mapCalloutDetails<>null && mapCalloutDetails.containsKey(strOperationName)){
                calloutDetails = mapCalloutDetails.get(strOperationName);
            }
            System.debug('@@@@@@calloutDetails::::'+calloutDetails);
            // Validates if an active callout detail is available
            if(calloutDetails<>null && calloutDetails.isActive){
                // Create the HTTP Request
                request = new HttpRequest();
                // Set the endpoint in the HTTP Request
                request.setEndpoint(CWS_ConstantClass.CALLOUT_ENDPOINT_PREFIX+calloutDetails.strEndpoint+strApendToURL);
                // Set the HTTP method in the HTTP request
                request.setMethod(calloutDetails.strMethod);
                // Create a HTTP instance
                http = new Http();
            }
            System.debug('****request***'+request);
            // If the http instance is not null then send the request
            // Validate if the number of callouts made are within limits
            if(http<>null && Limits.getCallouts()<Limits.getLimitCallouts()){
                // Capture the callout response recieved from the callout request
                response = http.send(request);                
            }

        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'CWS_CallloutService' , 'CWS_CallloutService','invokeCallout' ,'', null, null ,null , null);
        }
        return response;
    }
	
    public class GetSiteDetailResponse{
       @AuraEnabled
       public Boolean isSuccess{get;set;}
       @AuraEnabled
       public String body{get;set;}
    }

    private class CWS_CalloutDetails {
        // instant variables of wrapper class
        public Boolean isActive {get;set;}
        public String strEndpoint {get;set;}
        public String strMethod {get;set;}
    }
}