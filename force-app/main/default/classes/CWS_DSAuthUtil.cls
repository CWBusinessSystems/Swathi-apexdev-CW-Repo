Public Class CWS_DSAuthUtil{

    public static Boolean isSandbox{
        get{
            if (isSandbox == null){
                isSandbox = [Select IsSandbox from Organization limit 1].IsSandbox;
            }
            return isSandbox;
        }
        private set;
    }
    
    Public Static String getAccessToken(){
        String accesstoken;
        Map<String, String> mapDSSettings=new Map<String, String>();
        for(CWS_Renewal_Email_Settings__mdt mdt:[Select DeveloperName, MasterLabel, CWS_Value__c from 
                            CWS_Renewal_Email_Settings__mdt Limit 100]){
            mapDSSettings.put(mdt.MasterLabel, mdt.CWS_value__c);
        } 
        
        //HEADER
        String headerString='{\"typ\":\"JWT\",\"alg\":\"RS256\"}';
        //HEADER ENCODED
        String headerEncoded=base64URLencode(Blob.valueOf(headerString));
        
        //BODY
        String bodyString='{\"iss\":\"'+mapDSSettings.get('DSINTEGRATIONKEY')+'\",'+
                           '\"sub\":\"'+mapDSSettings.get('DSAPIUSERID')+'\",'+
                           '\"iat\":'+Datetime.now().getTime()/1000+','+
                           '\"exp\":'+Datetime.now().addMinutes(55).getTime()/1000+','+
                           (isSandbox==true?
                           '\"aud\":\"account-d.docusign.com\",':
                           '\"aud\":\"account.docusign.com\",')+
                           '\"scope\":\"signature impersonation\"}';
        //BODY ENCODED
        String bodyEncoded=base64URLencode(Blob.valueOf(bodyString));
        
        //TEMP JWT STRING
        String tempJWTString=headerEncoded+'.'+bodyEncoded;
        
        //SIGNATURE USING RSA PRIVATE KEY
        blob blobSign= Crypto.sign('rsa-sha256', Blob.valueOf(tempJWTString), EncodingUtil.Base64Decode(mapDSSettings.get('PRIVATEKEY')));
        String rs256sign=base64UrlEncode(blobSign);
        
        //FINAL JWT TOKEN
        String jwtToken=tempJWTString+'.'+rs256sign;
        
        //HTTP REQUEST
        HTTP http=new HTTP();        
        HTTPRequest req=new HTTPRequest();
        req.setMethod('POST');
        if(isSandbox){
            req.setEndPoint('https://account-d.docusign.com/oauth/token');        
        }
        else{
            req.setEndPoint('https://account.docusign.com/oauth/token');
        }
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type='+EncodingUtil.urlEncode('urn:ietf:params:oauth:grant-type:jwt-bearer', 'UTF-8')+'&assertion='+jwtToken);
         HTTPResponse res;
        //PARSE RESPONSE
        if(test.isRunningTest()){
            res = new HTTPResponse();
            res.setstatuscode(200);     
            accesstoken='ajsdjash';         
        }else{
            res=http.send(req);
            if(res.getStatusCode()==200){
                CWS_DSAuthUtil.Response resp=(CWS_DSAuthUtil.Response)JSON.deSerialize(res.getBody(), CWS_DSAuthUtil.response.class);
                accesstoken=resp.access_token;
            }
        }
        System.debug('Res__'+res);
       
        return accesstoken;
    }

    Private Static String base64URLencode(Blob input){ 
        String output = '';
        if (input != null) {
            output = encodingUtil.base64Encode(input);
            
            output = output.replace('+', '-');
            output = output.replace('/', '_');
            while ( output.endsWith('=')){
                output = output.subString(0,output.length()-1);
            }
        }    
        return output;
    }   
    
    Public class response{
        Public String access_token {get;set;}
        Public String token_type {get;set;}
        Public Integer expires_in {get;set;}
    }    
}