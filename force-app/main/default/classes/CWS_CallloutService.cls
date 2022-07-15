/*Class Name: CWS_CallloutService
*Description: Service Class for handling integration callouts
              Singleton = Eager loading
*Created By: swachatterjee
*Created On: 5/4/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*swachatterjee		    5/4/2020		 BED-1350		           Initial Version
*/
public without sharing class CWS_CallloutService {
    
    // Declare Instane variables
    public static Map<String, CWS_CalloutDetails> mapCalloutDetails {get; private set;}
    // Eager loading of class instance
    private static final CWS_CallloutService SERVICE =new CWS_CallloutService(); 
    
    /**
     * @Developer: swachatterjee
     * @Description : private constructor for singleton usage
     * @Requirement/issue: BED - 1305
     */
    private CWS_CallloutService() {
        try {
            mapCalloutDetails = new Map<String, CWS_CalloutDetails>();
            // Query through the custom metadata to get the Named credential against the operation name
            // Store the details recieved in an instance of child class 
            // CWS_CalloutDouts - to be used as a wrapper
            for(CWS_CalloutSettling__mdt mdtCallout: [select DeveloperName,CWS_IsActive__c,CWS_Method__c,CWS_NamedCredential__c from CWS_CalloutSettling__mdt limit 50]){
                // Create an instance of the wrapper - CWS_CalloutDetails
                CWS_CalloutDetails details = new CWS_CalloutDetails();
                // Copy the information from Metadata to callout details wrapper
                details.strEndpoint=mdtCallout.CWS_NamedCredential__c;
                details.strMethod=mdtCallout.CWS_Method__c;
                details.isActive=mdtCallout.CWS_IsActive__c;
                // Put the details in a map
                mapCalloutDetails.put(mdtCallout.DeveloperName, details);
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'CWS_CallloutService' , 'CWS_CallloutService','CWS_CallloutService' ,'', null, null ,'Constructor' , null);
        }
    }

    /**
     * @Developer: swachatterjee
     * @Description : public static method for retriving instance for public usage
     * @Requirement/issue: BED - 1305
     */
    public static CWS_CallloutService getCalloutService(){
        return SERVICE;
    }

    /**
     * @Developer: swachatterjee
     * @Description : private wrapper class for data maintenance
     * @Requirement/issue: BED - 1305
     */
    private class CWS_CalloutDetails {
        // instant variables of wrapper class
        public Boolean isActive {get;set;}
        public String strEndpoint {get;set;}
        public String strMethod {get;set;}
    }

    /**
     * @Developer: swachatterjee
     * @Description : invokes callout based on operation name (uses the JSON Body passed)
     * @Requirement/issue: BED - 1305
     */
    public static HttpResponse invokeCallout (String strOperationName, String strJSONBody){
        CWS_CalloutDetails calloutDetails = null;
        HttpRequest request = null;
        HttpResponse response = null;
        Http http = null;
        try {
            // Verify if the map of callout details contains the operation name
            if(mapCalloutDetails<>null && mapCalloutDetails.containsKey(strOperationName)){
                calloutDetails = mapCalloutDetails.get(strOperationName);
            }
            // Validates if an active callout detail is available
            if(calloutDetails<>null && calloutDetails.isActive){
                // Create the HTTP Request
                request = new HttpRequest();
                // Set the endpoint in the HTTP Request
                request.setEndpoint(CWS_ConstantClass.CALLOUT_ENDPOINT_PREFIX+calloutDetails.strEndpoint);
                // Validates if the JSON Body passed is blank string
                if(!String.isBlank(strJSONBody)){
                    request.setBody(strJSONBody);
                }
                // Set the HTTP method in the HTTP request
                request.setMethod(calloutDetails.strMethod);
                // Create a HTTP instance
                http = new Http();
            }
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


}