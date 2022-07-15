public class CWS_AgreementApprovalVFCompCrtlr {

    private static final String FIELD_NAME_ID = 'Id';
    
    public static String instanceURL{get;set;}
    
    public static String accountName{get;set;}
    public static String agreementName{get;set;}
    public static String ownerName{get;set;}
    public static String agreementNumber{get;set;}  
    public static Date projectStartDate{get;set;}  
    public static Decimal totalContractValue{get;set;}
    public static String clauseType{get;set;}
    
    // context controller
    private Apttus_Approval.ContextApprovalEmailController context = null;
    
    //Agreement object
    public Apttus__APTS_Agreement__c agreementSO = null;
    
    /**
     * Class Constructor
     **/
    public CWS_AgreementApprovalVFCompCrtlr() {
        
        // create the context
        this.context = new Apttus_Approval.ContextApprovalEmailController();
        instanceURL = 'https://'+System.URL.getSalesforceBaseURL().getHost()+'/';
        
        //Initializing the variables

    }
    
    /**
     * Gets the context controller
     * @return the context controller
     */
    public Apttus_Approval.ContextApprovalEmailController getContext() {
        return context;
        
    }
    
    /**
     * Gets the Apttus__APTS_Agreement__c sobject
     * @return the Apttus__APTS_Agreement__c sobject
     */
    public Apttus__APTS_Agreement__c getAgreementSO() {
        
        if (agreementSO == null) {
            Apttus_Approval__Approval_Request__c requestSO = Context.getRequestSO();
            // make sure the object id is available. Email Template preview will not have it populated,
            // in which case we create an empty quote object
            agreementSO = (requestSO.Apttus_Approval__Object_Id__c != null 
                      ? getAgreementSO(requestSO.Apttus_Approval__Object_Id__c) 
                      : new Apttus__APTS_Agreement__c());
            
        }
        
        return agreementSO;
        
    }
    
    /**
     * Gets the Agreement sobject for the given Agreement id
     * @param Agreement Id
     * @return the Apttus__APTS_Agreement__c sobject
     */
    public static Apttus__APTS_Agreement__c getAgreementSO(ID agreementId) {
        List<Apttus__APTS_Agreement__c> agreements;
        //Query for quote
		if(agreementId != null){
			agreements = [Select Id, 
								 Apttus__Account__r.Name,
								 Name,
								 Owner.Name,
								 Apttus__FF_Agreement_Number__c,
								 Apttus__Contract_Start_Date__c,
								 CWS_Clause_type__c,
								 Apttus__Total_Contract_Value__c,
								 Apttus__Account__c,
								 RecordType.Name
								 from Apttus__APTS_Agreement__c where id=:agreementId];
        }                                                    
       // if(!agreements.isEmpty()){
            //Setting total Contract Value
            //totalContractValue = agreements[0].SWT_Total_Contract_Value__c;
       // }
        
        return (!agreements.isEmpty() ? agreements[0] : null);
        
    }
}