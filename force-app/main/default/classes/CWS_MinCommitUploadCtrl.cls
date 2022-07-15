/*Class Name: CWS_MinCommitUploadCtrl
*Description: Create Min Commit records on opportunity
*Created By: Ankit
*Created On: 4/18/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                 4/18/2020        BED-8615            Create Min Commit records on opportunity loaded by CSV
*/
public class CWS_MinCommitUploadCtrl {
    
    @AuraEnabled
    public static string insertMinCommits(list<SObject> minCommList){
        String errorResult;
        list<CWS_Error_Log__c> errLogList = new list<CWS_Error_Log__c>();
        
        if(minCommList != null){
            List<Database.SaveResult> insertResults = Database.insert(minCommList, false);
            for(Integer i=0;i<insertResults.size();i++){
                if (!insertResults.get(i).isSuccess()){
                    if(String.isBlank(errorResult)){
                        errorResult = CWS_ConstantClass.INT_STATUS_ERROR;
                    }
                    CWS_Error_Log__c errlogObj = CWS_ExceptionHandler.initializeAndReturnDMLErrorLogs('CWS_MinCommitUploadCtrl','insertMinCommits','',
                        JSON.serialize( insertResults.get(i).getErrors()),'','CWS_Min_Commit_Errors','');
                        errLogList.add(errlogObj);
                }
            }
        }
            
        try{
            if(errLogList != NULL){
                //insert Error Logs records once the batch process all the records
                insert errLogList;
            }
        }catch(DMLException e){
            CWS_ExceptionHandler.insertException('CWS_Error_Log__c' , 'CWS_MinCommitUploadCtrl' , 'insertMinCommits' , e.getCause().getMessage() , '', e.getMessage() , String.valueOf(e.getLineNumber()) , e.getTypeName() , '' , '' , 'While inserting min commit dml exceptions' , '');    
        }
        
        if(String.isNotBlank(errorResult)){
            return errorResult;
        }else{
            return CWS_ConstantClass.AURA_SUCCESS;
        }
    }
}