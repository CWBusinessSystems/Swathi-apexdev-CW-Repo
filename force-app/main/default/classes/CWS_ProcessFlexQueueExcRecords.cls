/*Class Name: CWS_ProcessFlexQueueExcRecords
*Description: To process the renew Orders, which are not processed because of flex queue error
*Created By: mahak bansal
*Created On:  27/1/2021 
*Ticket no :- 14276942 
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*mahak bansal          27/1/2021            -                  Initial Version
*mahak bansal          24/2/2021            -                  updated , Logic of Scheduling embeded in the code
*/
public class CWS_ProcessFlexQueueExcRecords implements Database.Batchable<sObject>,Database.Stateful {  
    public List<Order> ordersList;
    public List<CWS_Error_Log__c> errLogListToPurge;    
    public Map<ID,CWS_Error_Log__c> errLogListToPurgeMap;
   
    public CWS_ProcessFlexQueueExcRecords(){
        ordersList = new List<Order>();
        errLogListToPurge = new List<CWS_Error_Log__c>();
        errLogListToPurgeMap= new Map<ID,CWS_Error_Log__c>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String queryString = 'SELECT id, CWS_Record_Id__c, CWS_Error_Message__c,CWS_List_of_Records_Error__c FROM CWS_Error_Log__c where CWS_Class_Name__c=\'CWS_OrderTriggerHelper\' and CWS_Error_Type__c=\'System.AsyncException\' LIMIT 40';
    	return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext BC, List<CWS_Error_Log__c> scope){        
        Set<Id> orderIdsToProcess = new Set<Id>();
        List<Order> orderListInt=new List<Order>();
        String[] recordIds ;
        for(CWS_Error_Log__c errLog : scope){
            if(errLog.CWS_Error_Message__c.contains('exceeded the limit of 100 jobs in the flex queue for org')){
                if(errLog.CWS_Record_Id__c!=null){
                    orderIdsToProcess.add(errLog.CWS_Record_Id__c);                
                    errLogListToPurgeMap.put(errLog.CWS_Record_Id__c,errLog);
                }   
            }
        }
        if(orderIdsToProcess.size() > 0){
           orderListInt= new List<Order>([SELECT id,OrderNumber FROM Order WHERE Id IN: orderIdsToProcess and Status!='Activated' and Type='Renewal']);//put order status condition here---
           ordersList.addAll(orderListInt);         
        }
    }
    
    public void finish(Database.BatchableContext BC){
        List<Order> orList= new List<Order>();
        set<Id> orderIdsProcessed=new Set<Id>();
        errLogListToPurge = new List<CWS_Error_Log__c>();
        if(ordersList.size() > 0){
            Boolean purgeRecords = false;
            List<String> orderRecToProcessIds=new List<String>();
            try{
                //Added for 14276942 -by mahak
                AggregateResult[] groupedResults = [Select Count(Id) FROM AsyncApexJob Where Status = 'Holding'];
                String exp0 = String.valueOf(groupedResults[0].get('expr0'));
                Integer availableLimit = 100 - Integer.valueOf(exp0);
                if(availableLimit > 40){
                    for(Order order:ordersList){
                        orList.add(order);
                        orderRecToProcessIds.add(order.id+';');
                        Database.executeBatch(new CWS_SubmitOrderBatch(orList),orList.size());
                        errLogListToPurge.add(errLogListToPurgeMap.get(order.Id));
                        orList= new List<Order>();
                        orderIdsProcessed.add(order.Id);
                    }
                }              
                purgeRecords = true;
                if(purgeRecords){
                    Database.Delete(errLogListToPurge);
                }                
                
                //Schedule the next job from here 
                schdeuleNextJob();
                //Query Async Apex job to send the status in email body
        		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email
                          FROM AsyncApexJob WHERE Id =
                          :BC.getJobId()];

                String subject='Flex Queue Records Processed with status: '+a.status;
                String msgBody='Dear User, <br/><br/>';
                msgBody+= 'The apex job completed with Total '+ a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.<br/>' ;
                msgBody+= '<br/>' + ' Ids of the Records processed successfully-<br/> '+orderIdsProcessed  + '<br/> <br/> For Failed records you can check the failures on Error Logs object by filtering context as CWS_ProcessFlexQueueExcRecords';
                
                CWS_Org_Defaults__c	 cwsDef=CWS_Org_Defaults__c.getOrgDefaults();
                String[] toAddresses = new String[]{} ;
                toAddresses = CWS_Org_Defaults__c.getOrgDefaults().CWS_Renewal_QuoteFlexQueue_email__c.split(';');
                CWS_CommonUtility.sendEmail(subject, msgBody, toAddresses);
            }
            catch(Exception ex){                
                CWS_ExceptionHandler.logListException(ex, 'CWS_ProcessFlexQueueExcRecords' , 'CWS_ProcessFlexQueueExcRecords','finish' ,'', null, orderRecToProcessIds ,'finish' , null);
            }
            
        }
    }   
    /**
	* This method is basically used to schedule the next job. For Renewal Batch processing , we needed the batch to be scheduled every 5 min between 
	* 6 am to 10 am on 1st of every month. This time period is handled with custom labels. So it is configurable
    **/
    public void schdeuleNextJob()
    {        
        Integer min= Integer.valueOf(System.Label.CWS_FlexQueueBatch_Rep_Minutes);
		DateTime dt =  System.now().addMinutes(min);       
        String day = string.valueOf(dt.day());
        String month = string.valueOf(dt.month());
        String hour = string.valueOf(dt.hour());
        //If the scheduled hour is complete or for eg. its 10 am on the 1st of the month then enters in if and Schedule a job for next month
        if(hour==System.Label.CWS_FlexQueueBatch_Last_Schedule_Hour){
            System.debug('in if--113');
            DateTime dt2 =  System.now().addMonths(1);                  
            String day1 = System.Label.CWS_FlexQueueBatch_StartDate;
            String month1 = string.valueOf(dt2.month());
            String hour1 = System.Label.CWS_FlexQueueBatch_Start_Schedule_Hour;
            String minute1 ='0' ;
            String second1 = '00';
            String year1 = string.valueOf(dt2.year());
            String jobName = 'CWS_RenewalFlexQueueSchedulable-'+year1+'-'+month1+'-'+day1+' '+hour1+':'+minute1+':'+second1;
            String strSchedule = '00 '+minute1 +' '+hour1+' '+day1+' '+month1+' ?'+' '+year1;
            System.schedule(jobName,strSchedule, new CWS_RenewalFlexQueueSchedulable());        
        }else{
        //Else Schedule the job after the defined repetitive minutes mentioned in the Custom label
            System.debug('in else--- 126');            
            String minute = string.valueOf(dt.minute());
            String second = '00';
            String year = string.valueOf(dt.year());
            String jobName = 'CWS_RenewalFlexQueueSchedulable-'+year+'-'+month+'-'+day+' '+hour+':'+minute+':'+second;
            String strSchedule = '00 '+minute +' '+hour+' '+day+' '+month+' ?'+' '+year;
            System.schedule(jobName,strSchedule, new CWS_RenewalFlexQueueSchedulable());
        }
    }
    
    
}