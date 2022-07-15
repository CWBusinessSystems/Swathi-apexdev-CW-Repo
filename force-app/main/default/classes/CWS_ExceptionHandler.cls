/*
Class Name : CWS_ExceptionHandler
Description : Utility class to insert error log records.
Developer : 
Date : 04/05/2020
*Modification Logs
*----------------------------------------------------------------------------------------------------------------------------
* Date                           Developer                User Story             Description
*----------------------------------------------------------------------------------------------------------------------------
*25/5/2020                      Ankit Bobde               BED-6479               Added a method which returns Error log Instance
*/
public class CWS_ExceptionHandler {

    //Start: BED- 6479
    /*
    Method Name : initializeAndReturnDMLErrorLogs
    Returns : CWS_Error_Log__c
    Description : Method to initialize and return error log records which can be used for Exception handling for DML Errors.
    Test Coverage : This method covers by Test Class : CWS_ShareRecordsCtrl_Test
    */
    
    public static CWS_Error_Log__c initializeAndReturnDMLErrorLogs(String className , 
                                            String methodName ,String errSrc, String errMsg, String recordId ,
                                            String context , String intgrtName){
        CWS_Error_Log__c errorLog = new CWS_Error_Log__c();
        errorLog.CWS_Class_Name__c = className;
        errorLog.CWS_Method_Name__c = methodName;
        errorLog.CWS_Error_Source__c = errSrc;
        errorLog.CWS_Error_Message__c = errMsg;
        errorLog.CWS_Record_Id__c = recordId;
        errorLog.CWS_Context__c = context;
        errorLog.CWS_Integration_Name__c = intgrtName;
        return errorLog;
    }
    //BED-6479
    

    /*
    Method Name : insertException
    Parameters : Object Name (String), Class Name(String) , Method Name (String), Error Cause (String), Error Source(String) , 
                 Error Message (String) , Error Line Number (String) , Error Type (String) , Integration Error Code (String),
                 Record Id (String) , Context (String) , Integration Name (String)
    Returns : void
    Description : Method to insert error log records for normal database operations.
    */

    public static void insertException( String objName , String className , 
                                        String methodName , String errCause , String errSrc ,
                                        String errMsg , String errLineNo , String errType , 
                                        String intgrtErrCode, String recordId ,
                                        String context , String intgrtName){
        try{
            System.debug('Exception on Class : ' + className + ' - ' + methodName +  
                            + ', Error : ' 
                            + errMsg 
                            + ' Line Number : ' 
                            + errLineNo
                            + ' Cause : '
                            + errCause
                            + ' Type : '
                            + errType);
            
            CWS_Error_Log__c errorLog = new CWS_Error_Log__c();
            
            errorLog.CWS_Object_Name__c = objName;
            errorLog.CWS_Class_Name__c = className;
            errorLog.CWS_Method_Name__c = methodName;
            errorLog.CWS_Error_Cause__c = errCause;
            errorLog.CWS_Error_Source__c = errSrc;
            errorLog.CWS_Error_Message__c = errMsg;
            errorLog.CWS_Error_Line_Number__c = errLineNo;
            errorLog.CWS_Error_Type__c = errType;
            errorLog.CWS_Error_Description__c = errType;
            errorLog.CWS_Integration_Error_Code__c = intgrtErrCode;
            errorLog.CWS_Record_Id__c = recordId;
            errorLog.CWS_Context__c = context;
            errorLog.CWS_Integration_Name__c = intgrtName;
            
            if(errorLog != NULL){
                insert errorLog;            
            }
               
                
        }
        catch(Exception e){
            insertException('CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'insertException Method' , e.getCause().getMessage(), 'Exception Handler', e.getMessage() , String.valueOf(e.getLineNumber()) , e.getTypeName() , '' , '' , 'While inserting error log record on handler class' , '');
        }
        
    }

     /*
    Method Name : logException
    Parameters : Exception,Object Name (String), Class Name(String) , Method Name (String)
                , Integration Error Code (String),
                 Record Id (String) , Context (String) , Integration Name (String)
    Returns : void
    Description : Method to insert error log records for normal database operations.
    */

    public static void logException( Exception objEx,String objName , String className , 
                                        String methodName ,String errSrc, String intgrtErrCode, String recordId ,
                                        String context , String intgrtName){
        try{
            
            CWS_Error_Log__c errorLog = new CWS_Error_Log__c();
            
            errorLog.CWS_Object_Name__c = objName;
            errorLog.CWS_Class_Name__c = className;
            errorLog.CWS_Method_Name__c = methodName;
            errorLog.CWS_Error_Source__c = errSrc;
            errorLog.CWS_Error_Message__c = objEx.getMessage();
            errorLog.CWS_Error_Line_Number__c = String.valueOf(objEx.getLineNumber());
            errorLog.CWS_Error_Type__c = objEx.getTypeName();
            errorLog.CWS_Integration_Error_Code__c = intgrtErrCode;
            errorLog.CWS_Record_Id__c = recordId;
            errorLog.CWS_Context__c = context;
            errorLog.CWS_Integration_Name__c = intgrtName;
            
            if(errorLog != NULL){
                insert errorLog;
            }
                
        }
        catch(Exception e){
            logException(e,'CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'insertException Method' , 
                                    'Exception Handler', '','' , 'While inserting error log record on handler class' , '');
        }
        
    }

    
     /*
    Method Name : logListException
    Parameters : Exception,Object Name (String), Class Name(String) , Method Name (String)
                , Integration Error Code (String),
                 recordIdList(String) , Context (String) , Integration Name (String)
    Returns : void
    Description : Method to insert error log records for list of records failed- basically in case of batch 
    */

    public static void logListException( Exception objEx,String objName , String className , 
                                        String methodName ,String errSrc, String intgrtErrCode, List<String> recordIdList ,
                                        String context , String intgrtName){
        try{
            
            CWS_Error_Log__c errorLog = new CWS_Error_Log__c();
            
            errorLog.CWS_Object_Name__c = objName;
            errorLog.CWS_Class_Name__c = className;
            errorLog.CWS_Method_Name__c = methodName;
            errorLog.CWS_Error_Source__c = errSrc;
            errorLog.CWS_Error_Message__c = objEx.getMessage();
            errorLog.CWS_Error_Line_Number__c = String.valueOf(objEx.getLineNumber());
            errorLog.CWS_Error_Type__c = objEx.getTypeName();
            errorLog.CWS_Integration_Error_Code__c = intgrtErrCode;
            errorLog.CWS_List_of_Records_Error__c = String.join(recordIdList, '\n');
            errorLog.CWS_Context__c = context;
            errorLog.CWS_Integration_Name__c = intgrtName;
            
            if(errorLog != NULL){
                insert errorLog;
            }
                
        }
        catch(Exception e){
            logException(e,'CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'insertException Method' , 
                                    'Exception Handler', '','' , 'While inserting error log record on handler class' , '');
        }
        
    }
    /*
    Method Name : logDMLSaveResults
    Parameters : SaveResult , Class Name (String) , Method Name (String) , Object Name (String) , Error Source (String), Context (String)
    Returns : void
    Description : Method to insert error log records for Database insert
    */
    public static void logDMLSaveResults( List< Database.SaveResult> saveresults , String className , String methodName,
                                     String objName , String errSrc , String context ){
        Boolean hasErrors = false;
        List<CWS_Error_Log__c> lstErrorLog = new List<CWS_Error_Log__c>();
        /*CWS_Error_Log__c errorLog = new CWS_Error_Log__c(CWS_Class_Name__c = className , CWS_Error_Source__c = errSrc , 
                                                    CWS_Method_Name__c = methodName , CWS_Object_Name__c = objName , 
                                                    CWS_Context__c = context
                                                    );*/
            
        for( Database.SaveResult res : saveresults ){
            if( !res.isSuccess() ){
                if( !hasErrors ){
                    hasErrors = true;
                }
                CWS_Error_Log__c errorLog = new CWS_Error_Log__c(CWS_Class_Name__c = className , CWS_Error_Source__c = errSrc , 
                                                    CWS_Method_Name__c = methodName, CWS_Object_Name__c = objName , 
                                                    CWS_Context__c = context, CWS_Error_Message__c=JSON.serialize( res.getErrors( ) ));
                //errorLog.CWS_Error_Message__c += JSON.serialize( res.getErrors( ) ) + '\n' ;
				if(res.getId() != Null){
                    errorLog.CWS_Record_Id__c=res.getId(); 
                }
                lstErrorLog.add(errorLog);
            }
                    
        }
           
        if( hasErrors ){
            try{
                if(lstErrorLog != NULL){
                    insert lstErrorLog;
                }
                
            }
            catch(DMLException e){
                insertException('CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'logDMLResults' , e.getCause().getMessage() , 'Exception Handler', e.getMessage() , String.valueOf(e.getLineNumber()) , e.getTypeName() , '' , '' , 'While inserting error log record on handler class' , '');    
            }
        }
    }
        
    /*
    Method Name : logDMLUpsertResults
    Parameters : UpsertResult , Class Name (String) , Method Name (String) , Object Name (String) , Error Source (String), Context (String)
    Returns : void
    Description : Method to insert error log records for Database upsert
    */

    public static void logDMLUpsertResults(List< Database.UpsertResult> saveresults , String className , String methodName,
                                          String objName , String errSrc , String context){
        Boolean hasErrors=false;
        List<CWS_Error_Log__c> lstErrorLog = new List<CWS_Error_Log__c>();
        /*CWS_Error_Log__c errorLog = new CWS_Error_Log__c(CWS_Class_Name__c = className , CWS_Error_Source__c = errSrc , 
                                                         CWS_Method_Name__c = methodName , CWS_Object_Name__c = objName , 
                                                         CWS_Context__c = context
                                                        );*/
        
        for( Database.UpsertResult res : saveresults ){
            if( !res.isSuccess() ){
                if( !hasErrors ){
                    hasErrors = true;
                }
                 CWS_Error_Log__c errorLog = new CWS_Error_Log__c(CWS_Class_Name__c = className , CWS_Error_Source__c = errSrc , 
                                                         CWS_Method_Name__c = methodName , CWS_Object_Name__c = objName , 
                                                         CWS_Context__c = context,CWS_Error_Message__c=JSON.serialize( res.getErrors( ) )
                                                        );
                lstErrorLog.add(errorLog);
                //errorLog.CWS_Error_Message__c += JSON.serialize( res.getErrors() ) + '\n';
            }
                
        }
        
        if( hasErrors ){
            try{
                if(lstErrorLog != NULL){
                    insert lstErrorLog;
                }
            }
            catch(DMLException e){
                insertException('CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'logDMLUpsertResults' , e.getCause().getMessage() , 'Exception Handler', e.getMessage() , String.valueOf(e.getLineNumber()) , e.getTypeName() , '' , '' , 'While inserting error log record on handler class' , '');    
            }
        }
    }

    /*
    Method Name : logDMLDelResults
    Parameters : DeleteResult , Class Name (String) , Method Name (String) , Object Name (String) , Error Source (String), Context (String)
    Returns : void
    Description : Method to insert error log records for Database delete
    */  

    public static void logDMLDelResults(List< Database.DeleteResult> deleteresults , String className , String methodName,
                                        String objName , String errSrc , String context ){
        Boolean hasErrors=false;
        List<CWS_Error_Log__c> lstErrorLog = new List<CWS_Error_Log__c>();
        /*CWS_Error_Log__c errorLog = new CWS_Error_Log__c(CWS_Class_Name__c = className , CWS_Error_Source__c = errSrc , 
                                                        CWS_Method_Name__c = methodName , CWS_Object_Name__c = objName , 
                                                        CWS_Context__c = context
                                                        );*/
        
        for( Database.DeleteResult res : deleteresults ){
            if( !res.isSuccess() ){
                if( !hasErrors ){
                    hasErrors = true;
                }
                CWS_Error_Log__c errorLog = new CWS_Error_Log__c(CWS_Class_Name__c = className , CWS_Error_Source__c = errSrc , 
                                                                 CWS_Method_Name__c = methodName , CWS_Object_Name__c = objName , 
                                                                 CWS_Context__c = context, CWS_Error_Message__c=JSON.serialize( res.getErrors( ) )
                                                                );
                lstErrorLog.add(errorLog);
                //errorLog.CWS_Error_Message__c += JSON.serialize( res.getErrors() ) + '\n' ;
            }
                
        }
            
            
        if( hasErrors ){
            try{
                if(lstErrorLog != NULL){
                    insert lstErrorLog;
                }
                
            }
            catch(DMLException e){
               insertException('CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'logDMLDelResults' , e.getCause().getMessage() , 'Exception Handler', e.getMessage() , String.valueOf(e.getLineNumber()) , e.getTypeName() , '' , '' , 'While inserting error log record on handler class' , '');    
            }
        }
    }

    /*
    Method Name : logGenericErrors
    Parameters : Class Name(String) , Method Name (String), 
                 err Source (String) , err message (String), recordId (String), Context (String) , Integration Name (String)
    Returns : void
    Description : Method to insert error log records.
    */

    public static void logErrors(String className , 
                                        String methodName ,String errSrc, String errMsg, String recordId ,
                                        String context , String intgrtName){
        try{
            
            CWS_Error_Log__c errorLog = new CWS_Error_Log__c();
            
            errorLog.CWS_Class_Name__c = className;
            errorLog.CWS_Method_Name__c = methodName;
            errorLog.CWS_Error_Source__c = errSrc;
            errorLog.CWS_Error_Message__c = errMsg;
            errorLog.CWS_Record_Id__c = recordId;
            errorLog.CWS_Context__c = context;
            errorLog.CWS_Integration_Name__c = intgrtName;
            
            if(errorLog != NULL){
                insert errorLog;
            }
                
        }
        catch(Exception e){
            logException(e,'CWS_Error_Log__c' , 'CWS_ExceptionHandler' , 'insertException Method' , 
                                    'Exception Handler', '','' , 'While inserting error log record on handler class' , '');
        }
        
    }
}