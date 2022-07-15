/*Class Name: CWS_RenewalEmailBatch
*Description: Batch Class to Send Email Notification to Sold to contact based on Expiration of the Contract and for teh special attention in case of Renewal Exceptions.
*Created On: 4/28/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aakash Sharma       4/28/2020        BED-6407               Email Notification to Sold to Contact.
*Ankit                7/6/2020        RENEWALCAT_CHANGE_REQ - Changed the reference from Renewal Type to Renewal Category
*Ankit                7/7/2020        CWS_BATCH_SWITCH -         Adding a switch to the batch
*/
Public class CWS_RenewalEmailBatch implements Database.Batchable<sObject>,Database.stateful{
    
    
    //Empty Constructor
    public CWS_RenewalEmailBatch(){
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        //String queryString=' Select Id, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c,SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__r.email,SBQQ__RenewalOpportunity__c,contract.SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__c,CWS_Days_Remaining__c from Contract where '+
                    //' ((CWS_Days_Remaining__c=30 or CWS_Days_Remaining__c=60 or CWS_Days_Remaining__c=90 or CWS_Days_Remaining__c=120) and '+
                    //'(endDate >=TODAY and SBQQ__RenewalForecast__c=true and SBQQ__RenewalOpportunity__c!=null ))';
                    //'(CWS_Days_Remaining__c=90 ';
                    //+'CWS_Days_Remaining__c=30 or'+'CWS_Days_Remaining__c=60 or'+ 'CWS_Days_Remaining__c=90)';
                    //' ((CWS_Days_Remaining__c=30 or CWS_Days_Remaining__c=60 or CWS_Days_Remaining__c=90 or CWS_Days_Remaining__c=120) and '+
                    //' (CWS_Renewal_Quote_Schedule__c<=TODAY and SBQQ__RenewalQuoted__c=FALSE and '+
                    //' SBQQ__RenewalOpportunity__r.StageName!=\''+ CWS_ConstantClass.OpportunityClosedWon_Stage +'\' ))
                    
                    
                    String queryString = ' SELECT Id , endDate'
                    + ',SBQQ__RenewalForecast__c '
                    + ',SBQQ__RenewalQuoted__c '
                    + ',SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__r.email '
                    + ',SBQQ__RenewalOpportunity__c '
                    + ',SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__c '
                    + ',SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c '
                    + ',SBQQ__RenewalOpportunity__r.CreatedDate '
                    + ',SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.CreatedDate '
                    + ',CWS_Days_Remaining__c '
                    + ',SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c'
                    + ',CWS_120_Days_Sent__c'
                    + ',CWS_90_Days_Sent__c'
                    + ',CWS_60_Days_Sent__c'
                    + ' FROM '
                    + ' contract '
                    + ' WHERE '
                    + ' (CWS_Days_Remaining__c=30 '
                    + ' OR CWS_Days_Remaining__c=60 '
                    + ' OR CWS_Days_Remaining__c=90 '
                    + ' OR CWS_Days_Remaining__c=120 '
                    + ' OR (CWS_Days_Remaining__c<120 '
                    + '     AND CWS_Days_Remaining__c>90) '
                    + ' OR (CWS_Days_Remaining__c<90 '
                    + '     AND CWS_Days_Remaining__c>60) '
                    + ' OR (CWS_Days_Remaining__c<60 '
                    + '     AND CWS_Days_Remaining__c>30) '
                    + ' OR SBQQ__RenewalOpportunity__r.CREATEDDATE = TODAY '
                    + ' OR ( SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c != \'\' ' 
                    + '     AND SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.CREATEDDATE = TODAY )) ' 
                    + ' AND EndDate >=TODAY '
                    + ' AND SBQQ__RenewalForecast__c = true '
                    + ' AND SBQQ__RenewalOpportunity__c !=null '
                    + ' AND SBQQ__RenewalOpportunity__r.StageName!=\''+ CWS_ConstantClass.OpportunityClosedLose_Stage +'\' '
                    + ' AND SBQQ__RenewalOpportunity__r.StageName!=\''+ CWS_ConstantClass.OpportunityClosedWon_Stage  +'\' '
                    + ' AND (CWS_Master__c=TRUE '
                    + ' OR (CWS_Master__c=FALSE AND SBQQ__RenewalOpportunity__r.CWS_On_Hold__c=FALSE )) ';
                    
                    //CWS_BATCH_SWITCH -> Skip Batch Run based on Switch  
                    /*
                    if(Label.CWS_Renewal_Email_Batch_Switch != CWS_ConstantClass.RENEWAL_BATCH_ON && !test.isRunningTest()){
                        queryString = queryString +  'Limit 0';
                    }
                    */
                    
                    return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
    
        List<Contract> contracts=(List<Contract>)scope; 
        set<id> setOppids=new set<id>();
        Map<id,string> mapOpptyRAN=new Map<id,string>();
        List <Opportunity> listOpptyUpdate=new list<Opportunity>();
        List <SBQQ__Quote__c> listQuoteUpdate=new list<SBQQ__Quote__c>(); 
        List<Contract> lstContract = new List<Contract>();  
        Map<id,Decimal> mapContRU=new Map<id,Decimal>();
        Set<Id> setContIds = (new Map<Id,SObject>(contracts)).keySet();     
        Map<id,string> mapQuoteRAN=new Map<id,string>();
        Map<Opportunity,List<id>> mapOpptyTemplate=new Map<Opportunity,List<id>>();
        Map<Id,List<Id>> mapOpptyTemplateNew=new Map<Id,List<Id>>();
        Set<Opportunity> oppsToProcess = new Set<Opportunity>();
        map<string,string> currLegalEntityMap = CWS_OpportunityTriggerHelper.getLegalEntity();
        set<id> setOpptyUpdate =new set<id>();
        set<id> setOpptyIds=new set<id>();
        Map<Id, Id> mapOptywithOptOutDocumentIds=new Map<Id, Id>();
        Map<Id, Id> mapOptywithOptInQuoteDocumentIds=new Map<Id, Id>();
        Map<id,Decimal> mapContractEmailSent=new Map<id,Decimal>();
        List<Contract> lstContractUpdate=new List<Contract>();
        system.debug(contracts.size());
        System.debug(contracts);

        //BED-10977        
        Set<Id> renOptyIds=new Set<Id>();        
        for(Contract Cont : contracts){
            
            if( Cont.SBQQ__RenewalOpportunity__c != null && ((Cont.SBQQ__RenewalOpportunity__r.CREATEDDATE).date() == Date.TODAY() ||  
             (Cont.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c != null  
             && (cont.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.CREATEDDATE).date() == Date.TODAY()))){
                setOppids.add(Cont.SBQQ__RenewalOpportunity__c);
            }
        
            //BED-11397
            if(Cont.SBQQ__RenewalOpportunity__c != null && Cont.CWS_Days_Remaining__c != null &&
            ((!Cont.CWS_120_Days_Sent__c && (Cont.CWS_Days_Remaining__c == 120 || (Cont.CWS_Days_Remaining__c < 120 && Cont.CWS_Days_Remaining__c > 90)))||
            (!Cont.CWS_90_Days_Sent__c && (Cont.CWS_Days_Remaining__c == 90 ||  (Cont.CWS_Days_Remaining__c < 90 && Cont.CWS_Days_Remaining__c > 60)))||
            (!Cont.CWS_60_Days_Sent__c && (Cont.CWS_Days_Remaining__c == 60 || (Cont.CWS_Days_Remaining__c < 60 && Cont.CWS_Days_Remaining__c > 30))))
             && cont.SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c != null && (Label.CWS_Renewal_Email_Batch_Switch == CWS_ConstantClass.RENEWAL_BATCH_ON || test.isRunningTest())){
            //BED-11397                
                setOpptyIds.add(Cont.SBQQ__RenewalOpportunity__c); 
                system.debug(setOpptyIds);
            }
        }
        list<SBQQ__Subscription__c> lstSubs=new List<SBQQ__Subscription__c>();
        if(setContIds.size()>0){
        lstSubs=[select id,SBQQ__RenewalUpliftRate__c,SBQQ__Contract__r.CWS_Renewal_CAP__c,SBQQ__Contract__r.CWS_Max_Renewal_Uplift__c,SBQQ__Product__r.CWS_Renewal_Uplift__c,SBQQ__Product__c from SBQQ__Subscription__c where SBQQ__Contract__c in : setContIds];
        }
        system.debug(lstSubs.size());
        if(!lstSubs.isEmpty()){
            for(SBQQ__Subscription__c Subs : lstSubs){
                    if(mapContRU.containsKey(Subs.SBQQ__Contract__c) && subs.SBQQ__Product__c != null && subs.SBQQ__Product__r.CWS_Renewal_Uplift__c != null  && mapContRU.get(Subs.SBQQ__Contract__c)< subs.SBQQ__Product__r.CWS_Renewal_Uplift__c){
                        mapContRU.put(Subs.SBQQ__Contract__c,subs.SBQQ__Product__r.CWS_Renewal_Uplift__c);
                    }
                    else if(!mapContRU.containsKey(subs.SBQQ__Contract__c) && subs.SBQQ__Product__r.CWS_Renewal_Uplift__c != null){
                        mapContRU.put(Subs.SBQQ__Contract__c,subs.SBQQ__Product__r.CWS_Renewal_Uplift__c);
                    }
            }
        }
        if(mapContRU!=null){
            for(id Contractid: mapContRU.keyset())
            {
                Contract TempCont=new Contract(id=Contractid,CWS_Max_Renewal_Uplift__c=mapContRU.get(Contractid));
            
                lstContract.add(TempCont);
            }
        }

        if(lstContract.size()>0){
            List<Database.SaveResult> results = Database.update(lstContract, false);
            CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_SBQQ__SubsTriggerHelper' , 'afterInsertHelper','Contract', null , null );
        }

        system.debug(setOppids);
        Map<string,id> mapTempNameID=new Map<string,id>();
        String strTP=CWS_ConstantClass.StrSANTemplate;
        EmailTemplate emailTemplate1;
        List<EmailTemplate> lstemailTemplate = [Select Id,Subject,DeveloperName from EmailTemplate where DeveloperName LIKE 'CWS_Renewal_Notification%' or DeveloperName =: strTP];
        system.debug(lstemailTemplate);
        for(EmailTemplate emailTemp : lstemailTemplate){
            if(emailTemp.DeveloperName == strTP)
            {
                emailTemplate1=emailTemp;   
            }
            if( emailTemp.DeveloperName == CWS_ConstantClass.RenewalEmailOptIn){
                mapTempNameID.put(CWS_ConstantClass.Renewal_Type_OptIn,emailTemp.id);
            }
            if(emailTemp.DeveloperName == CWS_ConstantClass.RenewalEmailOptOut){
                mapTempNameID.put(CWS_ConstantClass.Renewal_Type_OptOut,emailTemp.id);
            }
            if(emailTemp.DeveloperName == CWS_ConstantClass.RenewalEmailOptOutDisty){
                mapTempNameID.put(CWS_ConstantClass.OptOutDisty,emailTemp.id);
            }
            if(emailTemp.DeveloperName == CWS_ConstantClass.RenewalEmailOptInDisty){
                mapTempNameID.put(CWS_ConstantClass.OptInDisty,emailTemp.id);
            }
            if(emailTemp.DeveloperName == CWS_ConstantClass.RenewalEmailOptIn90){
                mapTempNameID.put(CWS_ConstantClass.OptIn90,emailTemp.id);
            }
            if(emailTemp.DeveloperName == CWS_ConstantClass.RenewalEmailOptOut90){
                mapTempNameID.put(CWS_ConstantClass.OptOut90,emailTemp.id);
            }
            
            //BED-13173
             if(emailTemp.DeveloperName == CWS_ConstantClass.RenewalEmailOptOutlegacy){
                mapTempNameID.put(CWS_ConstantClass.RenewalEmailOptOutlegacy,emailTemp.id);
            } 
            //BED-13173 
            
                
        }
        system.debug(mapTempNameID);
        System.debug(emailTemplate1);
        Messaging.SingleEmailMessage[] Emails =   new List<Messaging.SingleEmailMessage>();
        try{
            //RENEWALCAT_CHANGE_REQ -> Added Renewal Category in the query 
            List<Opportunity> lstOppty=[Select id,CWS_Sold_To_Contact__c,CWS_Route_to_Market__c,
            CWS_Bill_To_Contact__c,
            SBQQ__RenewedContract__r.CWS_Renewal_Type__c,SBQQ__RenewedContract__r.CWS_Renewal_Category__c,
            SBQQ__RenewedContract__r.CWS_Days_Remaining__c,CWS_Sold_To_Contact__r.email,CWS_Bill_To_Contact__r.email,SBQQ__RenewedContract__r.CWS_Master__c,Account.CWS_Additional_Emails_for_Invoice__c  
            from opportunity where id in:setOpptyIds];
            System.debug(lstOppty);
            Map<id,string> Map90Days =new Map<id,string>();
            if(!lstOppty.isEmpty()){
                for(opportunity Oppty:lstOppty){
                    
                    //RENEWALCAT_CHANGE_REQ
                    if(oppty.SBQQ__RenewedContract__r.CWS_Renewal_Category__c == CWS_ConstantClass.Renewal_Type_OptIn){
                        
                        if(oppty.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Direct){
                            Id TemplateID=mapTempNameID.get(CWS_ConstantClass.Renewal_Type_OptIn);
                            if(mapOpptyTemplateNew.containsKey(oppty.Id)) {
                                mapOpptyTemplateNew.get(oppty.Id).add(TemplateId);
                                oppsToProcess.add(oppty);
                            }
                            else{
                              mapOpptyTemplateNew.put(oppty.Id,new List<Id> {TemplateID});
                                oppsToProcess.add(oppty);
                            }
                        }
                        else{
                                Id TemplateID=mapTempNameID.get(CWS_ConstantClass.OptInDisty);
                                Id TemplateID2;
                                if(oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c == 90 || (oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c < 90 && oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c > 60)){
                                    TemplateID2=mapTempNameID.get(CWS_ConstantClass.OptIn90);
                                    Map90Days.put(TemplateID2,'90DaysOptIn');
                                    if(mapOpptyTemplateNew.containsKey(oppty.Id)) {
                                        mapOpptyTemplateNew.get(oppty.Id).add(TemplateID2);
                                        oppsToProcess.add(oppty);
                                    }
                                    else{
                                      mapOpptyTemplateNew.put(oppty.Id, new List<Id>{TemplateID2});
                                        oppsToProcess.add(oppty);
                                    }
                                }
                                if(mapOpptyTemplateNew.containsKey(oppty.Id)) {
                                    mapOpptyTemplateNew.get(oppty.Id).add(TemplateID);
                                    oppsToProcess.add(oppty);
                                }
                                else
                                  mapOpptyTemplateNew.put(oppty.Id, new List<Id>{TemplateID});
                                oppsToProcess.add(oppty);
                                }
                    }
                    
                    //RENEWALCAT_CHANGE_REQ
                    if(oppty.SBQQ__RenewedContract__r.CWS_Renewal_Category__c == CWS_ConstantClass.Renewal_Type_OptOut){
                        
                        if(oppty.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Direct){
                                Id TemplateID;
                                //BED-13173         
                                if(oppty.SBQQ__RenewedContract__r.CWS_Master__c){
                                  TemplateID=mapTempNameID.get(CWS_ConstantClass.RenewalEmailOptOutlegacy);
                                }
                                //BED-13173         
                                else{
                                  TemplateID=mapTempNameID.get(CWS_ConstantClass.Renewal_Type_OptOut); 
                                }                            
                            if(mapOpptyTemplateNew.containsKey(oppty.Id)) {
                                mapOpptyTemplateNew.get(oppty.Id).add(TemplateId);
                                oppsToProcess.add(oppty);
                            }
                            else{
                              mapOpptyTemplateNew.put(oppty.Id, new List<Id> {TemplateID});
                                oppsToProcess.add(oppty);
                            }
                        }
                        else{
                                Id TemplateID=mapTempNameID.get(CWS_ConstantClass.OptOutDisty);
                                Id TemplateID2;
                                    if(oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c == 90 || (oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c < 90 && oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c > 60)){
                                    TemplateID2=mapTempNameID.get(CWS_ConstantClass.OptOut90);
                                    Map90Days.put(TemplateID2,'90DaysOptOut');
                                        if(mapOpptyTemplateNew.containsKey(oppty.Id)) {
                                            mapOpptyTemplateNew.get(oppty.Id).add(TemplateID2);
                                            oppsToProcess.add(oppty);
                                        }
                                        else{
                                          mapOpptyTemplateNew.put(oppty.Id, new List<Id> {TemplateID2});
                                            oppsToProcess.add(oppty);
                                        }
                                    }
                                    if(mapOpptyTemplateNew.containsKey(oppty.Id)){
                                        mapOpptyTemplateNew.get(oppty.Id).add(TemplateId);
                                        oppsToProcess.add(oppty);
                                    }
                                    else{
                                      mapOpptyTemplateNew.put(oppty.Id, new List<Id>{TemplateID});
                                        oppsToProcess.add(oppty);
                                    }
                            }             
                    
                    }
                                
                }
            }
            system.debug(mapOpptyTemplate.values());
            system.debug(oppsToProcess);
            if(mapOpptyTemplateNew!=null){
                for(Opportunity oppty : oppsToProcess){
                    List<String> additionalEmailsList = new List<String>(); //BED-12735 To capture emails from additionalEmails field on sold to Account
                    if(!mapOpptyTemplateNew.get(oppty.Id).isEmpty()){    
                        //BED-12735 Start  Checking for additional emails added in field and sending them renewal notifications.                      
                        if(oppty.Account.CWS_Additional_Emails_for_Invoice__c != null){                            
                            if(oppty.Account.CWS_Additional_Emails_for_Invoice__c.contains(',')){
                                additionalEmailsList = oppty.Account.CWS_Additional_Emails_for_Invoice__c.split(',');
                            }else{
                                additionalEmailsList.add(oppty.Account.CWS_Additional_Emails_for_Invoice__c);
                            }  
                            system.debug('12735 debug2 additionalEmailsList --'+additionalEmailsList);
                        }
                        //BED-12735 End
                        for(Id temp : mapOpptyTemplateNew.get(oppty.Id)){
                            if(oppty.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Direct){
                                if(oppty.CWS_Sold_To_Contact__c!=null && temp!= null && oppty.CWS_Sold_To_Contact__r.email != null){
                                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                                    message.setTargetObjectId(oppty.CWS_Sold_To_Contact__c);
                                    message.setSaveAsActivity(true);
                                    message.setTemplateID(temp);
                                    message.setWhatId(oppty.id);
                                    if(!additionalEmailsList.isEmpty()){//BED-12735 start                                                
                                        message.setCcAddresses(additionalEmailsList);
                                        // additionalEmailsList.clear();//Service Ticket #14111056 - Issue Wrong Info Sent To Partners
                                    }
                  //BED-12735 END  
                                    system.debug('***message'+message);
                                    Emails.add(message);
                                }
                            }
                            if(oppty.CWS_Route_to_Market__c != CWS_ConstantClass.RTM_Value_Direct){
                                
                                if((oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c == 90 || (oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c < 90 && oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c > 60)) && Map90Days.containsKey(temp))
                                {   
                                    if(oppty.CWS_Sold_To_Contact__c!=null && temp!= null && oppty.CWS_Sold_To_Contact__r.email != null){
                                        Messaging.SingleEmailMessage message1 = new Messaging.SingleEmailMessage();
                                        message1.setTargetObjectId(oppty.CWS_Sold_To_Contact__c);
                                        message1.setSaveAsActivity(true);
                                        message1.setTemplateID(temp);
                                        message1.setWhatId(oppty.id);
                                        if(!additionalEmailsList.isEmpty()){//BED-12735 start                                                    
                                            message1.setCcAddresses(additionalEmailsList);
                                            // additionalEmailsList.clear();//Service Ticket #14111056 - Issue Wrong Info Sent To Partners
                                        } //BED-12735 END  
                                        system.debug('***message'+message1);
                                        Emails.add(message1);
                                    }
                                }
                                else{
                                    if(oppty.CWS_Bill_To_Contact__c!=null && temp!= null && oppty.CWS_Bill_To_Contact__r.email != null){
                                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                                        message.setTargetObjectId(oppty.CWS_Bill_To_Contact__c);
                                        message.setSaveAsActivity(true);
                                        message.setTemplateID(temp);
                                        message.setWhatId(oppty.id);
                                        if(!additionalEmailsList.isEmpty()){//BED-12735 start                                                     
                                            message.setCcAddresses(additionalEmailsList);
                                            // additionalEmailsList.clear();//Service Ticket #14111056 - Issue Wrong Info Sent To Partners
                                        }//BED-12735 END
                                        system.debug('***message'+message);
                                        Emails.add(message);
                                    }
                                }
                            } 
                        }
                    }
                    if(Emails.size()>0 && Emails!=null){
                        if(oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c == 120 || (oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c < 120 && oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c > 90)){
                            mapContractEmailSent.put(oppty.SBQQ__RenewedContract__c,120);
                        }
                        if(oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c == 90 || (oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c < 90 && oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c > 60)){
                            mapContractEmailSent.put(oppty.SBQQ__RenewedContract__c,90);
                        }
                        if(oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c == 60 || (oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c < 60 && oppty.SBQQ__RenewedContract__r.CWS_Days_Remaining__c > 30)){
                            mapContractEmailSent.put(oppty.SBQQ__RenewedContract__c,60);
                        }
                    }
                }
            }
            /*if(Contracts.size()>0 && emailTemplate != null){
                for(Contract contract:Contracts){
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    if(( contract.SBQQ__RenewalOpportunity__c != null && contract.SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__c != null && contract.SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__r.email != null )
                    &&  (contract.CWS_Days_Remaining__c == 30 || contract.CWS_Days_Remaining__c == 60 || contract.CWS_Days_Remaining__c== 90 || contract.CWS_Days_Remaining__c== 120)){
                        
                        message.setTargetObjectId(contract.SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__c);
                        system.debug('***contract.SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__c'+contract.SBQQ__RenewalOpportunity__r.CWS_Sold_To_Contact__c);
                        message.setSaveAsActivity(true);
                        message.setTemplateID(emailTemplate.Id);
                        message.setWhatId(contract.id);
                        system.debug('***message'+message);
                        Emails.add(message);
                    }
               }
            }
            */
            
            
            List<OpportunityLineItem> lstOP=new List<OpportunityLineItem>();
            List<SBQQ__QuoteLine__c> lstQLI=new List<SBQQ__QuoteLine__c>();
            if(setOppids!=null){
            lstOP = [SELECT Id,OpportunityId,Opportunity.id,Product2.CWS_Route_to_Market_Billing_Only__c,Opportunity.CWS_Route_to_Market__c,Opportunity.CurrencyIsoCode,Opportunity.CWS_Renewal_Attention_Needed__c,Product2.CWS_Currencies_Billing_Only__c,Product2.CWS_Status__c,Opportunity.CWS_Bill_To_Account__r.CurrencyIsoCode,Product2.CWS_License_Type__c,Opportunity.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c,Opportunity.SBQQ__RenewedContract__r.CurrencyIsoCode,Opportunity.SBQQ__PrimaryQuote__c from OpportunityLineItem WHERE OpportunityId in:setOppids];
            lstQLI = [SELECT id, SBQQ__Quote__r.SBQQ__Opportunity2__r.CurrencyIsoCode, SBQQ__Product__r.CWS_Route_to_Market_Billing_Only__c, SBQQ__Product__r.CWS_Status__c, SBQQ__Product__r.CWS_Currencies_Billing_Only__c, SBQQ__Quote__c, SBQQ__Quote__r.CWS_Bill_To_Account__c,SBQQ__Quote__r.CWS_Bill_To_Account__r.CurrencyIsoCode,SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CurrencyIsoCode,SBQQ__Product__r.CWS_License_Type__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Bill_To_Account__r.CurrencyIsoCode, SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Route_to_Market__c  from SBQQ__QuoteLine__c where  SBQQ__Quote__r.SBQQ__Opportunity2__c in:setOppids AND SBQQ__Quote__r.SBQQ__Primary__c = true];
            }

            system.debug('******'+lstQLI);
            system.debug('******'+lstOP);
            //Opportunity Products Iteration
            if(lstOP!=null && lstOP.size()>0 && !lstOP.isEmpty()){
                for(OpportunityLineItem opptyLI : lstOP){
                        if(opptyLI!=null && opptyLI.OpportunityId != null && opptyLI.Opportunity.SBQQ__PrimaryQuote__c == null){
                        system.debug(opptyLI.Opportunity.id);
                        system.debug(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                        if((opptyLI.Product2.CWS_Route_to_Market_Billing_Only__c !=null &&  opptyLI.Product2.CWS_Route_to_Market_Billing_Only__c.contains(opptyLI.Opportunity.CWS_Route_to_Market__c) && opptyLI.Product2.CWS_Currencies_Billing_Only__c!=null  && opptyLI.Product2.CWS_Currencies_Billing_Only__c.contains(opptyLI.Opportunity.CurrencyIsoCode) && opptyLI.Product2.CWS_Status__c == CWS_ConstantClass.StrActiveBilling) || opptyLI.Product2.CWS_Status__c == CWS_ConstantClass.StrBillingonly){
                                if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c == null){
                                    opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c=CWS_ConstantClass.strBilling;
                                    mapOpptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                                }
                                else if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c != null && !opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strBilling)){
                                    opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c=opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c + ';' +CWS_ConstantClass.strBilling;
                                    mapOpptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                                }
                        }
                        system.debug(opptyLI.Opportunity.id);
                        system.debug(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                        if(opptyLI.Product2.CWS_License_Type__c == CWS_ConstantClass.strPerpOnly){
                            if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c == null){
                                    opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c=CWS_ConstantClass.strPerp;
                                    mapOpptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                                }
                                else if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c != null && !opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strPerp)){
                                    opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c=opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c + ';' +CWS_ConstantClass.strPerp;
                                    mapOpptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                                }
                        }
                        system.debug(opptyLI.Opportunity.id);
                        system.debug(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                        if(opptyLI.Opportunity.CWS_Bill_To_Account__r.CurrencyIsoCode != opptyLI.Opportunity.SBQQ__RenewedContract__r.CurrencyIsoCode){
                                if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c == null){
                                    opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c= CWS_ConstantClass.strIncorrect;
                                    mapOpptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                                }
                                else if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c!=null && !opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strIncorrect)){
                                    opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c=opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c + ';' + CWS_ConstantClass.strIncorrect;
                                    mapOpptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                                }
                        }
                        system.debug(opptyLI.Opportunity.id);
                        system.debug(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                        if(opptyLI.Opportunity.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c!=null && opptyLI.Opportunity.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c != CWS_ConstantClass.strNoRistrict)
                        {
                                if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c == null){
                                    opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c=CWS_ConstantClass.strAccountResrict;
                                    mapopptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                                }
                                else if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c!=null && !opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strAccountResrict)){
                                    opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c=opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c + ';' +CWS_ConstantClass.strAccountResrict;
                                    mapopptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                                }
                        }
                        if(currLegalEntityMap.get(opptyLI.Opportunity.SBQQ__RenewedContract__r.CurrencyIsoCode)!=currLegalEntityMap.get(opptyLI.Opportunity.CWS_Bill_To_Account__r.CurrencyIsoCode)){
                                if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c == null){
                                opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c= CWS_ConstantClass.strIncorrectLE;
                                mapopptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                            }
                            else if(opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c!=null && !opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strIncorrectLE)){
                                opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c = opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c + ';' +CWS_ConstantClass.strIncorrectLE;
                                mapopptyRAN.put(opptyLI.Opportunity.id,opptyLI.Opportunity.CWS_Renewal_Attention_Needed__c);
                            }  
                        }
                    }
                }
            }
            //Quote Line Iteration
            system.debug(lstQLI.size());
            if(lstQLI !=null && !lstQLI.isEmpty() && lstQLI.size()>0){
                for(SBQQ__QuoteLine__c QLI : lstQLI){   
                            if((QLI.SBQQ__Product__r.CWS_Route_to_Market_Billing_Only__c !=null && QLI.SBQQ__Product__r.CWS_Route_to_Market_Billing_Only__c.contains(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Route_to_Market__c) && QLI.SBQQ__Product__r.CWS_Currencies_Billing_Only__c!=null  && QLI.SBQQ__Product__r.CWS_Currencies_Billing_Only__c.contains(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CurrencyIsoCode) && QLI.SBQQ__Product__r.CWS_Status__c == CWS_ConstantClass.StrActiveBilling) || QLI.SBQQ__Product__r.CWS_Status__c == CWS_ConstantClass.StrBillingonly){
                                if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c == null){
                                    QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c=CWS_ConstantClass.strBilling;
                                    mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                    mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                }
                                else if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c != null && !QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strBilling)){
                                    QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c=QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c + ';' +CWS_ConstantClass.strBilling;
                                    mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                    mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);

                                }
                        }
                        if(QLI.SBQQ__Product__r.CWS_License_Type__c == CWS_ConstantClass.strPerpOnly){
                            if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c == null){
                                    QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c=CWS_ConstantClass.strPerp;
                                    mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                    mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);

    
                                }
                                else if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c != null && !QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strPerp)){
                                    QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c=QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c + ';' +CWS_ConstantClass.strPerp;
                                    mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                    mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);

                                }
                        }
                        if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Bill_To_Account__r.CurrencyIsoCode != QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CurrencyIsoCode){
                                if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c == null){
                                    QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c= CWS_ConstantClass.strIncorrect;
                                    mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                    mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);

    
                                }
                                else if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c!=null && !QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strIncorrect)){
                                    QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c=QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c + ';' +CWS_ConstantClass.strIncorrect;
                                    mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                    mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
    
                                }
                        }
                        if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c!=null && QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Bill_To_Account__r.CWS_Account_Restriction_Status__c != CWS_ConstantClass.strNoRistrict ){
                                if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c == null){
                                    QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c=CWS_ConstantClass.strAccountResrict;
                                    mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                    mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                }
                                else if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c!=null && !QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strAccountResrict)){
                                    QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c=QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c + ';' +CWS_ConstantClass.strAccountResrict;
                                    mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                    mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                }    
                        }
                        if(currLegalEntityMap.get(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CurrencyIsoCode) != currLegalEntityMap.get(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Bill_To_Account__r.CurrencyIsoCode)){   
                                if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c == null){
                                QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c= CWS_ConstantClass.strIncorrectLE;
                                mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                            }
                            else if(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c!=null && !QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c.contains(CWS_ConstantClass.strIncorrectLE)){
                                QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c=QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c + ';' + CWS_ConstantClass.strIncorrectLE;
                                mapopptyRAN.put(QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                                mapQuoteRAN.put(QLI.SBQQ__Quote__r.id,QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Renewal_Attention_Needed__c);
                            }  
                        }
                    }
                }  
              system.debug('***'+mapopptyRAN.keyset());
              if(mapOpptyRAN.keyset()!=null){
                for(id Opportunityid:mapopptyRAN.keyset()){
                        Opportunity tempOppty=new Opportunity(id=Opportunityid,CWS_Renewal_Attention_Needed__c=mapopptyRAN.get(Opportunityid));
                        listOpptyUpdate.add(tempOppty);
                        setOpptyUpdate.add(tempOppty.id);
                    }
                }
                system.debug('***'+mapQuoteRAN.keyset());
                if(mapQuoteRAN.keyset()!=null){
                for(id Quoteid:mapQuoteRAN.keyset()){
                       SBQQ__Quote__c tempQuote=new SBQQ__Quote__c(id=Quoteid,CWS_Renewal_Attention_Needed__c=mapQuoteRAN.get(Quoteid));
                        listQuoteUpdate.add(tempQuote);
                    }
                }
                if(listOpptyUpdate.size()>0){
                    List<Database.SaveResult> results = Database.update(listOpptyUpdate,false);
                    CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_RenewalEmailBatch' , 'BatchEmail','Opportunity', null , null );
                    system.debug('&&&&'+results);
                }
                if(listQuoteUpdate.size()>0){
                    List<Database.SaveResult> results = Database.update(listQuoteUpdate,false);
                    CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_RenewalEmailBatch' , 'BatchEmail','Quote', null , null );
                    system.debug('&&&&'+results);
                }
                system.debug('***'+setOpptyUpdate); 
                list<Opportunity> lstEmailOpp=new list<Opportunity>(); 
                if(setOpptyUpdate.size() != null)  {            
                lstEmailOpp=[select id,Owner.email,OwnerId from Opportunity where id in:setOpptyUpdate];
                }
                
                system.debug('////'+lstEmailOpp);
                if(lstEmailOpp.size()>0){
                for(Opportunity oppty : lstEmailOpp){
                
                Messaging.SingleEmailMessage message1 = new Messaging.SingleEmailMessage();
                system.debug('*****'+oppty.Owner.email + emailTemplate1 + oppty.OwnerId);
                    if(oppty.Owner.email != null && emailTemplate1 != null && oppty.OwnerId != null){
                        message1.setTargetObjectId(oppty.OwnerId);
                        message1.setSaveAsActivity(false);
                        message1.setTemplateID(emailTemplate1.Id);
                        message1.setWhatId(oppty.id);
                        Emails.add(message1);
                        }
                    }
                }
                system.debug(Emails);
               if(Emails.size()>0 && Emails!=null){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(Emails);
                    if(!mapContractEmailSent.isEmpty()){
                        for(id Contractid:mapContractEmailSent.keyset()){
                            Contract cont=new contract(id=Contractid);
                            if(mapContractEmailSent.get(Contractid) != null && mapContractEmailSent.get(Contractid) == 120)
                            {
                            Cont.CWS_120_Days_Sent__c=true;  
                            }                            
                            if(mapContractEmailSent.get(Contractid) != null && mapContractEmailSent.get(Contractid) == 90)
                            {
                            Cont.CWS_90_Days_Sent__c=true;  
                            } 
                            if(mapContractEmailSent.get(Contractid) != null && mapContractEmailSent.get(Contractid) == 60)
                            {
                            Cont.CWS_60_Days_Sent__c=true;  
                            }
                           lstContractUpdate.add(cont);
                        }
                    }
                }  
                if(!lstContractUpdate.isEmpty()){
                    List<Database.SaveResult> results = Database.update(lstContractUpdate,false);
                    CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_RenewalEmailBatch' , 'BatchEmail','Contract', null , null );
                    system.debug('&&&&'+results);
                } 
            }
            catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Contract' , 'CWS_RenewalEmailBatch','CWS_RenewalEmailBatch' , '', null, null , 'CWS_RenewalEmailBatch' , null);
            }
        }
    
    public void finish(Database.BatchableContext bc){
    }
}