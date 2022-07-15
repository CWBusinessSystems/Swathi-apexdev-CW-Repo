/*Class Name: CWS_MinCommitAccountBatch
*Description: Batch Class to Calculate Min Commit amount for specific month
*Created By: Abhishek
*Created On: 06/12/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               06/12/2020      BED-5581              Calculate Min Commit amount for specific month
*/
public class CWS_MinCommitAccountBatch implements Database.Batchable < sObject >,Database.stateful{
    public List<Id> accIds = new List<Id>();
    public map<String,CurrencyType> convRateMap = new map<String,CurrencyType>();
    public map<id,Account> accMin = new map<Id,Account>();
    /* Parameterized cunstructor to run batch for specific Accounts
    */
    Public CWS_MinCommitAccountBatch(List<Id> accIds){
        this.accIds = accIds;
    }
    Public CWS_MinCommitAccountBatch(){}

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String monthYear = DateTime.now().format('MMM-YY');
        List<String> lstStages = System.Label.CWS_MinCommitOppStages.split(',');
        
        String query = 'Select id,CWS_Account__c,CWS_Account__r.CWS_Minimum_Commit_Amount__c,'+
                        'CWS_Monthly_Minimum_Commit__c,CurrencyIsoCode,CWS_Account__r.currencyIsoCode '+
                        'from CWS_Minimum_Commit__c where CWS_Month_Year__c =: monthYear '+
                        'AND CWS_Opportunity__r.StageName IN :lstStages';
            if(accIds.Size()>0){
                query += ' AND CWS_Account__c IN :accIds';
            }
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc,List<CWS_Minimum_Commit__c> scope) {
        
        decimal minConv;
        
        try{
            if(convRateMap.isEmpty()){
                for(CurrencyType convRate : [Select ISOCode, ConversionRate, IsActive from CurrencyType where IsActive = True limit 50]){
                    convRateMap.put(convRate.ISOCode,convRate);
                }
            }
            for(CWS_Minimum_Commit__c mCommit : scope){
                minConv=mCommit.CWS_Monthly_Minimum_Commit__c; //Service Ticket #14253443#14488347 /convRateMap.get(mCommit.currencyIsoCode).ConversionRate) *(convRateMap.get(mCommit.CWS_Account__r.currencyIsoCode).ConversionRate); 
                if(!accMin.isEmpty() && accMin.keyset().contains(mCommit.CWS_Account__c) &&  accMin.get(mCommit.CWS_Account__c) != Null){
                    accMin.get(mCommit.CWS_Account__c).CWS_Minimum_Commit_Amount__c = accMin.get(mCommit.CWS_Account__c).CWS_Minimum_Commit_Amount__c+minConv;
                }
                else{
                    Account acc = new Account(Id=mCommit.CWS_Account__c,CWS_Minimum_Commit_Amount__c= minConv);
                    accMin.put(acc.id,Acc);    
                }
            }

        }catch(Exception ex){
            CWS_ExceptionHandler.logException( ex,'BatchClass' , 'CWS_MinCommitAccountBatch' , 'Execute' ,'', null , null ,'update' , null);
        }

    }
    public void finish(Database.BatchableContext bc) {
        try{
            if(accMin.keySet().size()>0){
                system.debug('@@@accMin'+accMin);
                for(Account acc : accMin.values()){
                    acc.CWS_Minimum_Commit_Amount__c  = acc.CWS_Minimum_Commit_Amount__c.setScale(2);
                }
                List<Database.SaveResult> results =  Database.Update(accMin.values(), False);
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_MinCommitAccountBatch' , 'BatchJob','Update Min Commit Value ', null , null );
            }
        }catch(Exception ex){
            CWS_ExceptionHandler.logException( ex,'BatchClass' , 'CWS_MinCommitAccountBatch' , 'Execute' ,'', null , null ,'update' , null);
        }
    }
}