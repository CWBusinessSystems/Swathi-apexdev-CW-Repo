Public class CWS_DSEnvelopeUtil{
    Public Static Map<String, String> mapDSSettings;
    Static{
        mapDSSettings=new Map<String, String>();
        for(CWS_Renewal_Email_Settings__mdt mdt:[Select DeveloperName, MasterLabel, CWS_Value__c 
                        from CWS_Renewal_Email_Settings__mdt Limit 100]){
            mapDSSettings.put(mdt.MasterLabel, mdt.CWS_Value__c);
        }
    }
    
    Public Static HTTPResponse sendRequest(String templateId, String documentId, Map<Id, Document> mapDocument, 
                        String email1, String email2, String roleName1, String roleName2, String name1, String name2,
                        String subject, String contractEndDate, String productCategoryString, String renewalType, String routeToMarket,
                        String soldToAccountName){
        String bodyString=createEnvelopeRequest(templateId, documentId, mapDocument,email1, email2, roleName1, roleName2, 
                                            name1, name2, subject, contractEndDate, productCategoryString, renewalType, routeToMarket,
                                            soldToAccountName);
        if(bodyString!=null){
            HTTP http=new HTTP();
            HTTPRequest request=new HTTPRequest();
            request.setMethod('POST');
            request.setEndPoint(''+mapDSSettings.get('DSENVELOPEBASEURL')+ mapDSSettings.get('DSACCOUNTID')+'/envelopes');
            request.setHeader('grant_type', 'Bearer');
            request.setHeader('Authorization', 'Bearer ' + CWS_DSAuthUtil.getAccessToken());
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-type', 'application/json');
            request.setBody(bodyString);
            
            HTTPResponse response=http.send(request);
            return response;        
        }
        return null;
    }
    
    Public Static String createEnvelopeRequest(String templateId, String documentId, Map<Id, Document> mapDocument,
               String email1, String email2, String roleName1, String roleName2, String name1, String name2,
               String subject, String contractEndDate, String productCategoryString, String renewalType,String routeToMarket,
               String soldToAccountName){
        CWS_EnvelopeModel.EnvelopeRequest envelopeRequest=new CWS_EnvelopeModel.EnvelopeRequest();
        envelopeRequest.templateId=templateId;        
        envelopeRequest.status='Sent';
        envelopeRequest.emailSubject=subject;
        if(routeToMarket==CWS_ConstantClass.RTM_Value_Direct){
            envelopeRequest.emailBlurb= 'Dear '+name1+', \n\n'+
               'We would like to once again thank you for your partnership with ConnectWise.'+
               ' We are reaching out to remind you that the expiration of your current '+productCategoryString+
               ' contract is approaching within the next 30 days and we have not yet received a signed copy'+
               ' of the negotiated Order Form. Please let us know if you would like us to resend for signature.'+
               ' In the absence of an executed negotiated Order Form, your contract will automatically expire on '+ contractEndDate+
               '\n\nIf you have any questions or concerns, we want to hear them. Please email PartnerSuccess@ConnectWise.com.\n\n'+
               'Best regards,\nBusiness Operations';
        }
        else{
            envelopeRequest.emailBlurb= 
                'We would like to once again thank you for your partnership with ConnectWise'+
                ' and look forward to continuing the relationship in the year to come. We are reaching out to remind'+
                ' you that the expiration of '+soldToAccountName+'\'s current '+productCategoryString+' contract is approaching within the next '+
                Date.today().daysBetween(Date.parse(contractEndDate))+ ' days.\n\n'+
                'Please note that your contract is not set to auto-renew and will automatically expire on '+
                contractEndDate + ' if a new Order Form is not executed.'+
                '\n\nBest regards,\nBusiness Operations';
        }
        List<CWS_EnvelopeModel.TemplateRole> trs=new List<CWS_EnvelopeModel.TemplateRole>();
        if(email1!=null){
            List<CWS_EnvelopeModel.TabWrapper> signHereTabsList=new List<CWS_EnvelopeModel.TabWrapper>();
            List<CWS_EnvelopeModel.TabWrapper> fullNameTabsList=new List<CWS_EnvelopeModel.TabWrapper>();  
            List<CWS_EnvelopeModel.TabWrapper> initialHereTabsList=new List<CWS_EnvelopeModel.TabWrapper>();  
            List<CWS_EnvelopeModel.TabWrapper> dateSignedTabsList=new List<CWS_EnvelopeModel.TabWrapper>();  
            List<CWS_EnvelopeModel.TabWrapper> emailAddressTabsList=new List<CWS_EnvelopeModel.TabWrapper>();  
            CWS_EnvelopeModel.TabWrapper signHereTab=new CWS_EnvelopeModel.TabWrapper();
            signHereTab.anchorString='/S1/';
            signHereTab.required=String.valueOf('true');
            signHereTab.anchorXOffset='0';            
            signHereTab.anchorYOffset='-2';
            signHereTab.anchorUnits='mms';              
            signHereTabsList.add(signHereTab);
            CWS_EnvelopeModel.TabWrapper fullNameTab=new CWS_EnvelopeModel.TabWrapper();
            fullNameTab.anchorString='/N1/';
            fullNameTab.required=String.valueOf('true');
            fullNameTab.anchorXOffset='0';                        
            fullNameTab.anchorYOffset='-2';
            fullNameTab.anchorUnits='mms';              
            fullNameTabsList.add(fullNameTab);
            CWS_EnvelopeModel.TabWrapper initialHereTab=new CWS_EnvelopeModel.TabWrapper();
            initialHereTab.anchorString='/INI1/';
            initialHereTab.required=String.valueOf('true'); 
            initialHereTab.anchorXOffset='0';   
            initialHereTab.anchorYOffset='-2';          
            initialHereTab.anchorUnits='mms'; 
            initialHereTabsList.add(initialHereTab);
            CWS_EnvelopeModel.TabWrapper emailAddressTab=new CWS_EnvelopeModel.TabWrapper();
            emailAddressTab.anchorString='/EM1/';
            emailAddressTab.required=String.valueOf('true');  
            emailAddressTab.anchorXOffset='0';  
            emailAddressTab.anchorYOffset='-2';         
            emailAddressTab.anchorUnits='mms'; 
            emailAddressTabsList.add(emailAddressTab);
            CWS_EnvelopeModel.TabWrapper dateSignedTab=new CWS_EnvelopeModel.TabWrapper();
            dateSignedTab.anchorString='/D1/';
            dateSignedTab.required=String.valueOf('true'); 
            dateSignedTab.anchorXOffset='0';  
            dateSignedTab.anchorYOffset='-2';           
            dateSignedTab.anchorUnits='mms';             
            dateSignedTabsList.add(dateSignedTab);                        
            CWS_EnvelopeModel.DocusignTabsWrapper tabs=new CWS_EnvelopeModel.DocusignTabsWrapper();
            tabs.signHereTabs=signHereTabsList;
            tabs.dateSignedTabs= dateSignedTabsList;
            tabs.initialHereTabs =initialHereTabsList;
            tabs.emailAddressTabs =emailAddressTabsList;
            tabs.fullNameTabs =fullNameTabsList;
            
            CWS_EnvelopeModel.TemplateRole tr=new CWS_EnvelopeModel.TemplateRole();
            tr.email=email1;
            tr.roleName=roleName1;
            tr.name=name1;
            tr.tabs=tabs;
            tr.routingOrder='1';
            trs.add(tr);
            envelopeRequest.templateRoles=trs;
        }
        if(email2!=null){
            List<CWS_EnvelopeModel.TabWrapper> signHereTabsList=new List<CWS_EnvelopeModel.TabWrapper>();
            List<CWS_EnvelopeModel.TabWrapper> fullNameTabsList=new List<CWS_EnvelopeModel.TabWrapper>();  
            List<CWS_EnvelopeModel.TabWrapper> initialHereTabsList=new List<CWS_EnvelopeModel.TabWrapper>();  
            List<CWS_EnvelopeModel.TabWrapper> dateSignedTabsList=new List<CWS_EnvelopeModel.TabWrapper>();  
            List<CWS_EnvelopeModel.TabWrapper> emailAddressTabsList=new List<CWS_EnvelopeModel.TabWrapper>();  
            CWS_EnvelopeModel.TabWrapper signHereTab=new CWS_EnvelopeModel.TabWrapper();
            signHereTab.anchorString='/S2/';
            signHereTab.required=String.valueOf('true');
            signHereTab.anchorXOffset='0';            
            signHereTab.anchorYOffset='-2';
            signHereTab.anchorUnits='mms';            
            signHereTabsList.add(signHereTab);
            CWS_EnvelopeModel.TabWrapper fullNameTab=new CWS_EnvelopeModel.TabWrapper();
            fullNameTab.anchorString='/N2/';
            fullNameTab.required=String.valueOf('true');
            fullNameTab.anchorXOffset='0';            
            fullNameTab.anchorYOffset='-2';
            fullNameTab.anchorUnits='mms';
            fullNameTabsList.add(fullNameTab);
            CWS_EnvelopeModel.TabWrapper initialHereTab=new CWS_EnvelopeModel.TabWrapper();
            initialHereTab.anchorString='/INI2/';
            initialHereTab.required=String.valueOf('true');  
            initialHereTab.anchorXOffset='0';             
            initialHereTab.anchorYOffset='-2'; 
            initialHereTab.anchorUnits='mms';                     
            initialHereTabsList.add(initialHereTab);
            CWS_EnvelopeModel.TabWrapper emailAddressTab=new CWS_EnvelopeModel.TabWrapper();
            emailAddressTab.anchorString='/EM2/';
            emailAddressTab.required=String.valueOf('true');  
            emailAddressTab.anchorXOffset='0';            
            emailAddressTab.anchorYOffset='-2'; 
            emailAddressTab.anchorUnits='mms';                     
            emailAddressTabsList.add(emailAddressTab);
            CWS_EnvelopeModel.TabWrapper dateSignedTab=new CWS_EnvelopeModel.TabWrapper();
            dateSignedTab.anchorString='/D2/';
            dateSignedTab.required=String.valueOf('true'); 
            dateSignedTab.anchorXOffset='0';            
            dateSignedTab.anchorYOffset='-2';
            dateSignedTab.anchorUnits='mms';                                 
            dateSignedTabsList.add(dateSignedTab);                    
            CWS_EnvelopeModel.DocusignTabsWrapper tabs=new CWS_EnvelopeModel.DocusignTabsWrapper();
            tabs.signHereTabs=signHereTabsList;
            tabs.dateSignedTabs= dateSignedTabsList;
            tabs.initialHereTabs =initialHereTabsList;
            tabs.emailAddressTabs =emailAddressTabsList;
            tabs.fullNameTabs =fullNameTabsList;        
            CWS_EnvelopeModel.TemplateRole tr=new CWS_EnvelopeModel.TemplateRole();
            tr.email=email2;
            tr.roleName=roleName2;
            tr.name=name2;
            tr.routingOrder='2';
            tr.tabs=tabs;
            trs.add(tr);
            envelopeRequest.templateRoles=trs;             
        }        
       
        if(documentId!=null){
            List<CWS_EnvelopeModel.Document> docs=new List<CWS_EnvelopeModel.Document>(); 
            CWS_EnvelopeModel.Document doc=new CWS_EnvelopeModel.Document();
            doc.documentBase64=EncodingUtil.Base64Encode(mapDocument.get(documentId).body);
            doc.name=mapDocument.get(documentId).Name;
            doc.fileExtension=mapDocument.get(documentId).type;
            doc.documentId='1';
            docs.add(doc);
            envelopeRequest.documents=docs;
        }

        return JSON.serialize(envelopeRequest);       


    }
}