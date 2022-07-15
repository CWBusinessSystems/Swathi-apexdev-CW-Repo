/*Class Name: CWS_SplitContract 
*Description: Batch Class to Split Contract in to Opt-Out and Opt-In by cloning.
*Created On: 4/27/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Karthikeyan 4/10/2020        BED-3402               Automatic and Manual Renewal Creation
*Aakash      4/10/2020        BED-8886               Changes related to the One time Product not to be Renewed.
*Ankit                 7/6/2020        RENEWALCAT_CHANGE_REQ - Commenting the Renewal type assignemnt as Opt-In Opt-Out Values will be Deactivated
*/
Public class CWS_SplitContract implements Database.Batchable<sObject>, Database.stateful{
    
    private String queryString;
    public List<Id> contractIds;
    public Id accountId;
    private String contractFields {
        get {
            if(contractFields==null){
                contractFields='Select ';
                Map<String, Schema.sObjectField> mapContractFields=Schema.getGlobalDescribe().get('Contract').getDescribe().Fields.getMap();
                if(mapContractFields!=null){
                    for(Schema.sObjectField field:mapContractFields.values()){
                        Schema.DescribeFieldResult fieldResult=field.getDescribe();
                        if(fieldResult.isCreateable()){
                              contractFields=contractFields + fieldResult.getName() + ', ';
                        }
                    }
                }
                if(contractFields!=null){
                    contractFields=contractFields.trim().removeEnd(',');
                }
                return contractFields;
            }
            else{
                return contractFields;
            }
            
        }
        set;
    }
    
    //Empty Constructor
    public CWS_SplitContract(){
    
    }
    // Constructor with Account Id
    public CWS_SplitContract(Id accountId){
        accountId=accountId;
    }
    // Constructor with List of Contracts    
    public CWS_SplitContract(List<Id> tcontractIds){
        contractIds=tcontractIds;
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        queryString=' Select Id, CWS_Renewal_Category__c, CWS_Renewable_Products__c, CWS_Renewal_Type__c, '+
        ' AccountId, CWS_Renewal_Quote_Schedule__c, SBQQ__Evergreen__c, CWS_Renewal_Opportunity_Schedule__c, Status '+
        ' from Contract where '+
        ' CWS_Renewal_Category__c=\''+ CWS_ConstantClass.Renewal_Category_SplitPending +'\''+
        ' AND SBQQ__Evergreen__c = false ';
        if(accountId!=null){
            queryString=queryString+' AND accountId =:accountId';
        }
        if(contractIds!=null && !contractIds.isEmpty()){
            queryString=queryString + ' AND id in : contractIds';
        }
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        SavePoint sp=Database.setSavePoint();
        List<Contract> contracts=(List<Contract>)scope;
        List<Id> sourceContractIds=new List<Id>();
        List<Contract> clonedContractList=new List<Contract>();        
        try{
            for(Contract contract: contracts){
                sourceContractIds.add(contract.Id);
            }
            List<SBQQ__Subscription__c> lstSubs=[Select Id, SBQQ__Contract__c, CWS_ACVLine__c, CWS_Margin__c,SBQQ__SubscriptionType__c,CWS_Transaction_Type__c,
                                    SBQQ__Product__c,  SBQQ__Product__r.CWS_Renewal_Type__c,SBQQ__Contract__r.CWS_Renewable_Products__c,
                                    SBQQ__RequiredByProduct__c, SBQQ__RequiredByProduct__r.CWS_Renewal_Type__c
                                    from  SBQQ__Subscription__c 
                                    where SBQQ__Contract__c in :sourceContractIds
                                    and SBQQ__Product__c!=null];
            if(lstSubs!=null && !lstSubs.isEmpty()){
                Map<Id, Decimal> mapOptInContractACV=new Map<Id, Decimal>();
                Map<Id, Decimal> mapOptOutContractACV=new Map<Id, Decimal>();
                Map<Id, Decimal> mapOptInContractMargin=new Map<Id, Decimal>();
                Map<Id, Decimal> mapOptOutContractMargin=new Map<Id, Decimal>();
                Map<Id,Decimal> mapCContractRP=new Map<Id,Decimal>();
                Map<Id,Decimal> mapSContractRP=new Map<Id,Decimal>();
                Decimal acvValue;
                Decimal marginValue;
                Integer countOptInProducts=0;
                Integer countOptOutProducts=0;
                Integer countBlankRenewalType=0;
                for(SBQQ__Subscription__c sub: lstSubs){
                    if(sub.SBQQ__Product__c!=null && ((sub.SBQQ__RequiredByProduct__c==null && 
                        sub.SBQQ__Product__r.CWS_Renewal_Type__c==CWS_ConstantClass.Renewal_Type_OptOut) ||
                        (sub.SBQQ__RequiredByProduct__c!=null && 
                        sub.SBQQ__RequiredByProduct__r.CWS_Renewal_Type__c==CWS_ConstantClass.Renewal_Type_OptOut))){
                        countOptOutProducts++;
                    }
                    else if(sub.SBQQ__Product__c!=null && ((sub.SBQQ__RequiredByProduct__c==null && 
                        sub.SBQQ__Product__r.CWS_Renewal_Type__c==CWS_ConstantClass.Renewal_Type_OptIn) ||
                        (sub.SBQQ__RequiredByProduct__c!=null && 
                        sub.SBQQ__RequiredByProduct__r.CWS_Renewal_Type__c==CWS_ConstantClass.Renewal_Type_OptIn))){
                        countOptInProducts++;
                    }
                    else if(sub.SBQQ__Product__c!=null && ((sub.SBQQ__RequiredByProduct__c==null && 
                        sub.SBQQ__Product__r.CWS_Renewal_Type__c==null) ||
                        (sub.SBQQ__RequiredByProduct__c!=null && 
                        sub.SBQQ__RequiredByProduct__r.CWS_Renewal_Type__c==null))){
                        countBlankRenewalType++;
                    }
                    if(sub.SBQQ__Product__c!=null && ( (sub.SBQQ__RequiredByProduct__c==null && 
                        sub.SBQQ__Product__r.CWS_Renewal_Type__c==CWS_ConstantClass.Renewal_Type_OptIn) ||
                        (sub.SBQQ__RequiredByProduct__c!=null && 
                        sub.SBQQ__RequiredByProduct__r.CWS_Renewal_Type__c==CWS_ConstantClass.Renewal_Type_OptIn))){
                        //BED-8886
                        if(Sub.SBQQ__Contract__c != null && Sub.SBQQ__SubscriptionType__c != CWS_ConstantClass.ChargeType_OneTime && Sub.CWS_Transaction_Type__c != null && (Sub.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW || Sub.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3 || Sub.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON)){
                            Decimal RenewableProducts=0;
                            if(Sub.SBQQ__Contract__r.CWS_Renewable_Products__c == 0 && !mapCContractRP.containsKey(Sub.SBQQ__Contract__c)){
                                RenewableProducts++;
                                System.debug(RenewableProducts);
                                mapCContractRP.put(Sub.SBQQ__Contract__c,RenewableProducts);
                            }
                            else{
                                if(mapCContractRP.containsKey(Sub.SBQQ__Contract__c))
                                {
                                RenewableProducts=mapCContractRP.get(Sub.SBQQ__Contract__c);
                                RenewableProducts++;
                                System.debug(RenewableProducts);
                                mapCContractRP.put(Sub.SBQQ__Contract__c,RenewableProducts);
                                }
                                else{
                                    if(Sub.SBQQ__Contract__r.CWS_Renewable_Products__c != null){
                                    RenewableProducts=Sub.SBQQ__Contract__r.CWS_Renewable_Products__c;
                                    RenewableProducts++;
                                    System.debug(RenewableProducts);
                                    mapCContractRP.put(Sub.SBQQ__Contract__c,RenewableProducts);
                                    }
                                }
                            }
                        }
                        if(Sub.SBQQ__Contract__c != null && Sub.SBQQ__SubscriptionType__c != CWS_ConstantClass.ChargeType_OneTime && Sub.CWS_Transaction_Type__c != null && Sub.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL){
                            Decimal RenewableProducts=0;
                            if(Sub.SBQQ__Contract__r.CWS_Renewable_Products__c != null && Sub.SBQQ__Contract__r.CWS_Renewable_Products__c>0 ){
                                RenewableProducts=Sub.SBQQ__Contract__r.CWS_Renewable_Products__c;
                                RenewableProducts--;
                                System.debug(RenewableProducts);
                                mapSContractRP.put(Sub.SBQQ__Contract__c,RenewableProducts);
                            }
                        }
                        System.debug(mapSContractRP);
                        //BED-8886

                        if(!mapOptInContractACV.containsKey(sub.SBQQ__Contract__c)){
                            if(sub.CWS_ACVLine__c!=null){
                                mapOptInContractACV.put(sub.SBQQ__Contract__c, sub.CWS_ACVLine__c);
                            }
                            else{
                                mapOptInContractACV.put(sub.SBQQ__Contract__c, 0);                                
                            }
                        }
                        else{
                            acvValue=mapOptInContractACV.get(sub.SBQQ__Contract__c);
                            if(sub.CWS_ACVLine__c!=null){
                                mapOptInContractACV.put(sub.SBQQ__Contract__c, sub.CWS_ACVLine__c+acvValue);
                            }
                        }
                        if(!mapOptInContractMargin.containsKey(sub.SBQQ__Contract__c)){
                            if(sub.CWS_Margin__c!=null){
                                mapOptInContractMargin.put(sub.SBQQ__Contract__c, sub.CWS_Margin__c);
                            }
                            else{
                                mapOptInContractMargin.put(sub.SBQQ__Contract__c, 0);                             
                            }
                        }
                        else{
                            acvValue=mapOptInContractMargin.get(sub.SBQQ__Contract__c);
                            if(sub.CWS_Margin__c!=null){
                                mapOptInContractMargin.put(sub.SBQQ__Contract__c, sub.CWS_Margin__c+acvValue);
                            }
                        }
                    }
                    else{
                        //BED-8886
                        if(Sub.SBQQ__Contract__c != null && Sub.SBQQ__SubscriptionType__c != CWS_ConstantClass.ChargeType_OneTime && Sub.CWS_Transaction_Type__c != null && (Sub.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW || Sub.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3 || Sub.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON)){
                            Decimal RenewableProducts=0;
                            if(Sub.SBQQ__Contract__r.CWS_Renewable_Products__c == 0 && !mapSContractRP.containsKey(Sub.SBQQ__Contract__c)){
                                RenewableProducts++;
                                System.debug(RenewableProducts);
                                mapSContractRP.put(Sub.SBQQ__Contract__c,RenewableProducts);
                            }
                            else{
                                if(mapSContractRP.containsKey(Sub.SBQQ__Contract__c))
                                {
                                RenewableProducts=mapSContractRP.get(Sub.SBQQ__Contract__c);
                                RenewableProducts++;
                                System.debug(RenewableProducts);
                                mapSContractRP.put(Sub.SBQQ__Contract__c,RenewableProducts);
                                }
                                else{
                                    if(Sub.SBQQ__Contract__r.CWS_Renewable_Products__c != null){
                                    RenewableProducts=Sub.SBQQ__Contract__r.CWS_Renewable_Products__c;
                                    RenewableProducts++;
                                    System.debug(RenewableProducts);
                                    mapSContractRP.put(Sub.SBQQ__Contract__c,RenewableProducts);
                                    }
                                }
                            }
                        }
                        if(Sub.SBQQ__Contract__c != null && Sub.SBQQ__SubscriptionType__c != CWS_ConstantClass.ChargeType_OneTime && Sub.CWS_Transaction_Type__c != null && Sub.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL){
                            Decimal RenewableProducts=0;
                            if(Sub.SBQQ__Contract__r.CWS_Renewable_Products__c != null && Sub.SBQQ__Contract__r.CWS_Renewable_Products__c>0 ){
                                RenewableProducts=Sub.SBQQ__Contract__r.CWS_Renewable_Products__c;
                                RenewableProducts--;
                                System.debug(RenewableProducts);
                                mapSContractRP.put(Sub.SBQQ__Contract__c,RenewableProducts);
                            }
                        }
                        System.debug(mapSContractRP);
                        //BED-8886
                        
                        if(!mapOptOutContractACV.containsKey(sub.SBQQ__Contract__c)){
                            if(sub.CWS_ACVLine__c!=null){
                                mapOptOutContractACV.put(sub.SBQQ__Contract__c, sub.CWS_ACVLine__c);
                            }
                            else{
                                mapOptOutContractACV.put(sub.SBQQ__Contract__c, 0);                                
                            }
                        }
                        else{
                            acvValue=mapOptOutContractACV.get(sub.SBQQ__Contract__c);
                            if(sub.CWS_ACVLine__c!=null){
                                mapOptOutContractACV.put(sub.SBQQ__Contract__c, sub.CWS_ACVLine__c+acvValue);
                            }
                        }
                        if(!mapOptOutContractMargin.containsKey(sub.SBQQ__Contract__c)){
                            if(sub.CWS_Margin__c!=null){
                                mapOptOutContractMargin.put(sub.SBQQ__Contract__c, sub.CWS_Margin__c);
                            }
                            else{
                                mapOptOutContractMargin.put(sub.SBQQ__Contract__c, 0);                                
                            }
                        }
                        else{
                            acvValue=mapOptOutContractMargin.get(sub.SBQQ__Contract__c);
                            if(sub.CWS_Margin__c!=null){
                                mapOptOutContractMargin.put(sub.SBQQ__Contract__c, sub.CWS_Margin__c+acvValue);
                            }
                        }                    
                    }
                }
                
                if(countOptInProducts!=0 && countOptOutProducts!=0){
                    List<Contract> sourceContractsList=(List<Contract>)Database.query(contractFields +
                                    ' from Contract where id in (\''+String.join(sourceContractIds,'\', \'')+'\') ');
                    for(Contract contract:sourceContractsList){
                        contract.CWS_Renewal_Category__c=CWS_ConstantClass.Renewal_Type_OptOut;
                        //RENEWALCAT_CHANGE_REQ
                        //contract.CWS_Renewal_Type__c=CWS_ConstantClass.Renewal_Type_OptOut;
                        if(mapSContractRP.containsKey(contract.id)){
                        contract.CWS_Renewable_Products__c=mapSContractRP.get(contract.id);
                        }
                        if(mapOptOutContractACV.containsKey(contract.Id)){
                            contract.CWS_Contract_ACV__c=mapOptOutContractACV.get(contract.Id);
                        }
                        if(mapOptOutContractmargin.containsKey(contract.Id)){
                            contract.CWS_Margin__c=mapOptOutContractMargin.get(contract.Id);
                        }
                        
                        Contract clonedContract=contract.clone(false,true, false, false);
                        clonedContract.CWS_Source__c=contract.Id;
                        clonedContract.Status='Draft';
                        clonedContract.CWS_Renewal_Category__c=CWS_ConstantClass.Renewal_Type_OptIn;
                        //RENEWALCAT_CHANGE_REQ
                        //clonedContract.CWS_Renewal_Type__c=CWS_ConstantClass.Renewal_Type_OptIn;
                        if(mapCContractRP.containsKey(contract.id)){
                            clonedContract.CWS_Renewable_Products__c=mapCContractRP.get(contract.id);
                        }
                        if(mapOptInContractACV.containsKey(contract.Id)){
                            clonedContract.CWS_Contract_ACV__c=mapOptInContractACV.get(contract.Id);
                        }
                        if(mapOptInContractmargin.containsKey(contract.Id)){
                            clonedContract.CWS_Margin__c=mapOptInContractACV.get(contract.Id);
                        }
                        clonedContractList.add(clonedContract);
                        contract.status='Activated';                        
                    }
                    
                    if(sourceContractsList!=null && !sourceContractsList.isEmpty()){
                        update sourceContractsList;
                    }
                    if(clonedContractList!=null && !clonedContractList.isEmpty()){
                        insert clonedContractList;       
                    }
                    
                    Map<Id, Id> mapClonedContractIds=new Map<Id, Id>();
                    for(Contract contract:[Select Id,Name, CWS_Source__c from Contract where CWS_Source__c in :sourceContractIds]){
                        mapClonedContractIds.put(contract.CWS_Source__c,contract.Id);
                    }
                    
                    List<SBQQ__Subscription__c> lstSubscriptions=[Select Id, SBQQ__Contract__c from SBQQ__Subscription__c
                                            where SBQQ__Contract__c in :sourceContractIds and 
                            ((SBQQ__RequiredByProduct__c=null and 
                             SBQQ__Product__r.CWS_Renewal_Type__c=:CWS_ConstantClass.Renewal_Type_OptIn) or
                            (SBQQ__RequiredByProduct__c!=null and
                            (SBQQ__RequiredByProduct__r.CWS_Renewal_Type__c=:CWS_ConstantClass.Renewal_Type_OptIn)))];
                    if(lstSubscriptions!=null && !lstSubscriptions.isEmpty() && mapClonedContractIds!=null){
                        for(SBQQ__Subscription__c sub: lstSubscriptions){
                            if(mapClonedContractIds.containsKey(sub.SBQQ__Contract__c)){
                                sub.SBQQ__Contract__c = mapClonedContractIds.get(sub.SBQQ__Contract__c);
                            }
                        }
                        update lstSubscriptions;
                    }
                }
                else if(countOptOutProducts!=0 && countOptInProducts==0){
                    for(Contract contract: contracts){
                        contract.CWS_Renewal_Category__c=CWS_ConstantClass.Renewal_Type_OptOut;
                        contract.status='Activated';
                    }
                    if(contracts!=null && !contracts.isEmpty()){
                        update contracts;
                    }
                }
                else if(countOptInProducts!=0 && countOptOutProducts==0){
                    for(Contract contract: contracts){
                        contract.CWS_Renewal_Category__c=CWS_ConstantClass.Renewal_Type_OptIn;
                        contract.Status='Activated';
                    }
                    if(contracts!=null && !contracts.isEmpty()){
                        update contracts;
                    }
                }
                else if(countOptOutProducts==0 && countOptInProducts==0 ){
                    for(Contract contract: contracts){
                        contract.CWS_Renewal_Category__c=CWS_ConstantClass.Renewal_Type_OptOut;
                        if(countBlankRenewalType==0){
                            contract.Status='Activated';
                        }
                    }
                    if(contracts!=null && !contracts.isEmpty()){
                        update contracts;
                    }
                }
            }
            
        }catch(Exception exp){
            //Rollback partial commit in case of exception.
            Database.rollback(sp);
            //Error when updating Renewal Forecast/Renewal Quoted on Contract.
            CWS_ExceptionHandler.logException( exp,'Contract' , 'CWS_SplitContract','execute' ,
                                  '', null, null , 'execute' , null);
        }
    }
    
    Public void finish(Database.BatchableContext bc){
    }
    
}