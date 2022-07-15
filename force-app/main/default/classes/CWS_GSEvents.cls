/*Class Name: CWS_CWS_GSEvents
*Description: create Events to Gainsight from Salesforce 
*Created By: Jeff Cochran
*Created On: 10/23/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------

*/
public class CWS_GSEvents{
    
    @future(callout=true)
    public static void calloutFromFuture(string records, string sharedSecret, string tenantId, string eventName,string topicName, string eventVersion){
        System.debug('Welcome to Apex Case Closure Trigger!');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://ep.gainsight.com/api/v0.1/eventManager/event');
        request.setMethod('POST');

        request.setHeader('sharedSecret',sharedSecret);
        request.setHeader('tenantId',tenantId);
        request.setHeader('eventName',eventName);
        request.setHeader('topicName',topicName);
        request.setHeader('eventVersion',eventVersion);
        request.setHeader('Content-Type','application/json');
        
        Map<String,Object> data = new Map<String,Object>();
        data.put('participantInformationList',JSON.deserializeUntyped(records));
        
        request.setBody(JSON.serialize(data));
        HttpResponse response;
        if(!Test.isRunningTest()){
         
            response = http.send(request);
        }
        if (response == null || response.getStatusCode() != 201) {
            
            System.debug('Invalid status code returned');

        } else {
            
            System.debug(response.getBody());
        }
    }
    
    
}