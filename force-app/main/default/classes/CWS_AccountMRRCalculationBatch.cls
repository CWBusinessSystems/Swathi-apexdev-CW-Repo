/*Class Name: CWS_AccountMRRCalculationBatch
*Description: Batch Class to Calculate MRR based on Contract ACV
*Created By: Abhishek
*Created On: 06/24/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               06/24/2020      BED-5141                Calculate MRR based on Contract ACV
*/
public class CWS_AccountMRRCalculationBatch implements Database.Batchable < sObject >{
    public List<Id> accIds = new List<Id>();
    /* Parameterized cunstructor to run batch for specific Accounts
    */
    Public CWS_AccountMRRCalculationBatch(List<Id> accIds){
        this.accIds = accIds;
    }
    Public CWS_AccountMRRCalculationBatch(){}
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String active = CWS_ConstantClass.PROMOTION_ACTIVE;
        Integer lastNDays = Integer.valueOf(Label.CWS_Account_MRR_Last_N_Days);
        String  query = 'select id,CWS_MRR__c,CWS_Multiple_Contract_Currencies__c,currencyIsoCode, ' ;
                query += ' (Select id,CWS_Status__c,AccountId,CWS_Contract_ACV__c,currencyIsoCode from Contracts where CWS_Status__c =: active AND CWS_Contract_ACV__c !=Null AND CWS_Contract_ACV__c !=0)';// AND LastModifiedDate = LAST_N_DAYS:'+lastNDays;
                query += ' from Account';
                if(accIds.Size()>0){
                    query += ' WHERE Id IN :accIds';
                }
        return Database.getQueryLocator(query);

    }
    public void execute(Database.BatchableContext bc,List<Account> scope) {
        map<String,CurrencyType> convRateMap = new map<String,CurrencyType>();
        decimal convMRR;
        decimal totalMRR;
        boolean multiCurrency=false;
        map<id,Account> cntrAccMap = new map<Id,Account>();
        list<Account> accs = new list<Account>();
        
        try{
            for(CurrencyType convRate : [Select ISOCode, ConversionRate, IsActive from CurrencyType where IsActive = True limit 50]){
                convRateMap.put(convRate.ISOCode,convRate);
            }
            for(Account acc : scope){
                if(acc.contracts.size()>0){
                    totalMRR=0;
                    convMRR=0;
                    for(contract cntr : acc.contracts){
                        // Coverting All Contract ACV in USD
                        convMRR=cntr.CWS_Contract_ACV__c/convRateMap.get(cntr.currencyIsoCode).ConversionRate; 
                        totalMRR= totalMRR+convMRR;
                        //If Contract Currency is diff than Account Currency
                        if(!acc.CWS_Multiple_Contract_Currencies__c && acc.currencyIsoCode != cntr.currencyIsoCode){
                            acc.CWS_Multiple_Contract_Currencies__c=true;
                        }
                    }
                    acc.CWS_MRR__c = (totalMRR/12)*(convRateMap.get(acc.currencyIsoCode).ConversionRate);
                    accs.add(acc);
                }
            }
            if(!accs.isEmpty()){
                system.debug('accs'+accs);
                List<Database.SaveResult> results=Database.update(accs,false);
                CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_AccountMRRCalculationBatch' , 'BatchJob','Update Account MRR ', null , null );
            }
        }catch(exception ex){
            CWS_ExceptionHandler.logException( ex,'BatchClass' , 'CWS_AccountMRRCalculationBatch' , 'Execute' ,'', null , null ,'update' , null);
        }
    }
    public void finish(Database.BatchableContext bc) {

    }
}