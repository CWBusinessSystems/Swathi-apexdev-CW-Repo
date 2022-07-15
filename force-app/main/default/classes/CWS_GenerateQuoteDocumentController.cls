/* Component Name   : CWS_GenerateQuoteDocumentController 
 * Description      : This controller class contains the logic to perform validations for manual clauses
 * Created By       : Indra Ganesan
 * Created On       : 13-06-2020

 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID      Description 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Indra Ganesan          13-06-2020                                  Initial version
 * Harsha                 03-09-2020               BED-13368          ERROR MESSAGE

 */
 public class CWS_GenerateQuoteDocumentController {
    
    @AuraEnabled
    
    public static Map<String, String> validateQuoteOnDocGen(Id quoteID){
        
        Map<String, String> errMessages = new Map<String,String>();
        String strManualClauses ;
        
        if(quoteID != null) {
            system.debug('****inside controller**');
            List<SBQQ__QuoteTerm__c> lstManClause = [SELECT CWS_Clause_Name__c, CW_Manual_Clause__c FROM SBQQ__QuoteTerm__c WHERE CW_Manual_Clause__c =: true limit 1500];            
            Map<String, boolean> mapClause = new Map<String, boolean>();
            
            for(SBQQ__QuoteTerm__c clauseName:lstManClause){
               mapClause.put(clauseName.CWS_Clause_Name__c.toLowerCase(), true);        
            }  

 SBQQ__Quote__c quote = [SELECT id, CWS_Custom_sow__c,  SBQQ__Status__c, SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c, CWS_Add_Terms_Manually__c, CWS_Document_Clauses__c, SBQQ__WatermarkShown__c,SBQQ__ExpirationDate__c,CWS_Previous_Company_Name__c,CWS_Transaction_Reason__c,CWS_Sub_Type__c FROM SBQQ__Quote__c WHERE Id =: quoteID limit 100];
           
		   if(quote!= null && !quote.SBQQ__WatermarkShown__c && quote.CWS_Custom_sow__c > 0 ){
  
                List<Task> taskLst = [Select id, type, CWS_Quote_Id__c, Status from Task 
                WHere CWS_Quote_Id__c  = :quoteID 
                and Status != :CWS_ConstantClass.TASK_STATUS_CLOSED 
                and Type =: CWS_ConstantClass.TASK_TYPE_CUSTOM_SOW_REQUEST
                limit 1 ];
             

                if(!taskLst.isEmpty()){
                    errMessages.put('Custom SOW Task Not Closed',  System.label.CWS_SOW_Task_Close );
                }
            }


           
			//BED-3528-START
            if(quote.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c == CWS_ConstantClass.DistiEndCustomer && !quote.SBQQ__WatermarkShown__c){
                errMessages.put(System.label.CWS_Warning + 'Disti End Customer Error Msg', System.Label.CWS_Disti_End_Customer_Error_Msg);
            }
			
			 //BED-13368-Start
            if(quote.CWS_Previous_Company_Name__c == null && quote.CWS_Transaction_Reason__c == 'Merger & Acquisition' && quote.CWS_Sub_Type__c	== 'Rebill'){
                errMessages.put(System.label.CWS_Warning + 'Please provide Previous company name on Account', System.Label.CWS_Previous_Account);
            }
            //BED-13368-END  
            if(quote.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c ==  CWS_ConstantClass.Disti_Pricing && !quote.SBQQ__WatermarkShown__c){
                errMessages.put(System.label.CWS_Warning + 'Disti Deal Disti Pricing', System.Label.CWS_Disti_Deal_Disti_Pricing);
            }
            //BED-3528-END

            if(!quote.SBQQ__WatermarkShown__c){
			
			   //BED-4970
                if(quote.SBQQ__ExpirationDate__c == null){
                errMessages.put('ExpiresonErrorMessage',System.Label.CWS_ExpiresonErrorMessage);
                }
                //BED-4970
				if(String.isEmpty(quote.CWS_Document_Clauses__c) && String.isNotEmpty(quote.CWS_Add_Terms_Manually__c )){
                    quote.CWS_Add_Terms_Manually__c = '';    
                    update quote;            
                }
				
                if(String.isNotEmpty(quote.CWS_Document_Clauses__c)){                          
                    Set<String> setInvalidClauses = new Set<String>(); 
                    Set<String> setManualClauseHased = new Set<String>(); 
                    List<String> lstManualClauses = quote.CWS_Document_Clauses__c.split(';');
                    
                    for(String qClauseName: lstManualClauses){
                        qClauseName = qClauseName.replace('#','').trim();
                        if(mapClause.size()>0 && !mapClause.ContainsKey(qClauseName.toLowerCase())){
                            setInvalidClauses.add(qClauseName);
                        } else{
                          setManualClauseHased.add('#' +  qClauseName + '#');
                        }
                    }

                    if(!setInvalidClauses.isEmpty()){
                
                        errMessages.put('Invalid Manual Clause' , System.Label.CWS_Invalid_Manual_Clause_ErrorMsg 
                             + ' - ' 
                             + String.join(new List<String>(setInvalidClauses), ',') );
        
                    } else if(!setManualClauseHased.isEmpty()){
                        quote.CWS_Add_Terms_Manually__c = String.join(new List<String>(setManualClauseHased), ';');
                        update quote;
                    }
                }
                
            }
           
        }
       return errMessages;
    }
 }