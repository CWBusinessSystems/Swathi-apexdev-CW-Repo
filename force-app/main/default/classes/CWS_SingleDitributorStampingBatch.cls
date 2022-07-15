/*Class Name: CWS_SingleDitributorStampingBatch
*Description: Batch Class to Update Establish Partner On Account, Create a Task, Expire Quote docs.
*Created By: Abhishek
*Created On: 07/10/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               07/10/2020     BED-8383              
*/
public class CWS_SingleDitributorStampingBatch implements Database.Batchable < sObject >,Database.AllowsCallouts,Database.Stateful{
    public List<Id> quoteIds = new List<Id>();
    public List<SBQQ__QuoteDocument__c> qDocspluginList = new List<SBQQ__QuoteDocument__c>();
    /* Parameterized cunstructor to run batch for specific Accounts
    */
    Public CWS_SingleDitributorStampingBatch(List<Id> quoteIds){
        this.quoteIds = quoteIds;
    }
    public CWS_SingleDitributorStampingBatch() { }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String accepted = CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;
        String rtm= CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct;
        Integer lastNDays = Integer.valueOf(Label.CWS_Account_MRR_Last_N_Days);
        String  query = 'Select id,SBQQ__Account__r.CWS_Established_Disti_Reseller__c,SBQQ__Account__c,CWS_Share_with_Bill_To_Account__c,';
                query += 'CWS_Bill_To_Account__c from SBQQ__Quote__c where CWS_First_Quote__c =true'; 
                query += ' AND SBQQ__Account__r.CWS_Established_Disti_Reseller__c =Null AND SBQQ__Status__c =:accepted  AND';
                query += '(CWS_Bill_To_Account__r.CWS_Is_Distributor__c=True OR CWS_Bill_To_Account__r.CWS_Is_IIT_Reseller__c=True) AND';
                query += ' CWS_Route_to_Market__c!=:rtm AND SBQQ__Primary__c= True';
        if(quoteIds.Size()>0){
            query += ' and Id IN :quoteIds';
        }
        return Database.getQueryLocator(query);

    }
    public void execute(Database.BatchableContext bc,List<SBQQ__Quote__c> scope) {
        list<Account> acclist = new list<Account>();
        set<Account> accs = new set<Account>();
        list<Task> tasks = new list<Task>();
        
        list<Id> disties = new list<Id>();
        list<Id> quoteIds = new list<Id>();
        try{
            Group masterQueue = [select id,relatedid,name, DeveloperName 
                from Group 
                where Type = 'Queue' 
                AND DeveloperName =:  CWS_ConstantClass.Master_Data_First_Accepted_Quotes
                limit 1];
            for(SBQQ__Quote__c quote : scope){
                // Account Update - Established Partner
                if(quote.SBQQ__Account__r.CWS_Established_Disti_Reseller__c !=quote.CWS_Share_with_Bill_To_Account__c){
                    accs.add(New Account(id=quote.SBQQ__Account__c,CWS_Established_Disti_Reseller__c=quote.CWS_Share_with_Bill_To_Account__c));
                    disties.add(quote.CWS_Share_with_Bill_To_Account__c);
                
                tasks.add(new Task(
                    subject =Label.CWS_TaskSubjectSingleDisty,
                    Status=CWS_ConstantClass.TASK_STATUS_OPEN,
                    type=CWS_ConstantClass.Task_Type_Other,
                    Description=Label.CWS_TaskCommentSingleDisty,
                    whatId=quote.Id,
                    Priority=CWS_ConstantClass.Task_Priority_FIRST,
                    ownerId=masterQueue.Id
                    ));
				}
            }

            if(disties.size()>0){
                for(SBQQ__QuoteDocument__c qtdoc :[Select Id, name, SBQQ__Quote__c,SBQQ__SignatureStatus__c, 
                                                SBQQDS__EnvelopeId__c, SBQQDS__VoidedReason__c 
                                                From SBQQ__QuoteDocument__c 
                                                Where SBQQ__SignatureStatus__c = 'Sent' AND SBQQ__Quote__r.SBQQ__Primary__c=true
                                                AND (NOT SBQQ__Quote__r.CWS_Bill_To_Account__c IN :disties)
                                                AND SBQQ__Quote__r.SBQQ__Account__c IN :accs
                                                AND (SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Is_Distributor__c=true 
                                                OR SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Is_IIT_Reseller__c=true) AND
                                                SBQQ__Quote__r.CWS_Route_to_Market__c!=:CWS_ConstantClass.OPPORTUNITY_RouteToMarket_Direct] ){

                    qtdoc.SBQQDS__VoidedReason__c=System.Label.CWS_FirstQuoteExipiry;
                    qDocspluginList.add(qtdoc);
                }
            }
            system.debug('@@accs'+accs);
            system.debug('@@tasks'+tasks);
            system.debug('@@accs'+qDocspluginList);
            if(accs.size()>0){
				 acclist.addAll(accs);
                database.update(acclist,false);
            }
            if(tasks.size()>0){
                Database.insert(tasks,false);
            }
        }catch(Exception ex){
            CWS_ExceptionHandler.logException( ex,'BatchClass' , 'CWS_SingleDitributorStampingBatch' , 'Execute' ,'', null , null ,'update' , null);
        }
    }
    public void finish(Database.BatchableContext bc) {
        try{
            system.debug('@@qDocspluginList'+qDocspluginList);
            if(qDocspluginList.size()>0){
                SBQQDS.DocuSignPlugin plugin = new SBQQDS.DocuSignPlugin();
            plugin.revoke(qDocspluginList);
            }
        }catch(Exception ex){
            CWS_ExceptionHandler.logException( ex,'BatchClass' , 'CWS_SingleDitributorStampingBatch' , 'Execute' ,'', null , null ,'update' , null);
        }
    }
}