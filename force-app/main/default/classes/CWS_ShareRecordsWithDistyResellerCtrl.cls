/*Class Name: CWS_ShareRecordsWithDistyResellerCtrl
*Description: This controller is used to handle the Activate/Deactivate Request coming from Qyuick actions
*Created By: Ankit
*Created On: 5/24/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                  5/24/2020         BED-6479              Initia Version
*/
public class CWS_ShareRecordsWithDistyResellerCtrl{
    @AuraEnabled
    public static String identifyContext(String accID,CWS_Distributor_Reseller__c distyRec, String context){
        //Checking if the context is not blank context can be Activate,Deactivate
        if(String.isNotBlank(context)){
            //Calling Batch Class to perform share/Delete records to channel Reps depending upon the context
            //Scope => 1 : which means Sharing/Deletion for shrare records of account/Contact/Opp/QUote will hapeen for 
            //Channel Reps belonging to 1 Disty at a time 
            Id batchJobId = Database.executeBatch(new CWS_ActivateDistyResellerBatch(accID,distyRec,context),1);
        }
        //As  the batch runs in asynchronous mode we cannot hold for the batch completion 
        //and do polling instead we give successn message on page saying email will be sent once the batch completes the run 
        return CWS_ConstantClass.AURA_SUCCESS;
    }
}