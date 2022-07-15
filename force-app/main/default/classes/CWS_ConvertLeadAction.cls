/**
* @description       : 
* @author            : DPC Advictoriam Solutions
* @group             : 
* @last modified on  : 06-18-2021
* @last modified by  : DPC Advictoriam Solutions
* Modifications Log 
* Ver   Date         Author                      Modification
* 1.0   06-18-2021   DPC Advictoriam Solutions   Initial Version
**/
public Without Sharing class CWS_ConvertLeadAction {
    
    @InvocableMethod(label='Convert Leads')
    public static List<ConvertLeadActionResult> convertLeads(List<ConvertLeadActionRequest> requests) {
        List<ConvertLeadActionResult> results = new List<ConvertLeadActionResult>();
        for (ConvertLeadActionRequest request : requests) {
            results.add(convertLead(request));
        }
        return results;
    }
    
    public static ConvertLeadActionResult convertLead(ConvertLeadActionRequest request) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(request.leadId);
        lc.setConvertedStatus(request.convertedStatus);
        
        if (request.accountId != null) {
            lc.setAccountId(request.accountId);
        }
        
        if (request.contactId != null) {
            lc.setContactId(request.contactId);
        }
        
        if (request.overWriteLeadSource != null && request.overWriteLeadSource) {
            lc.setOverwriteLeadSource(request.overWriteLeadSource);
        }
        
        if (request.createOpportunity != null && !request.createOpportunity) {
            lc.setDoNotCreateOpportunity(!request.createOpportunity);
        }
        
        if (request.opportunityName != null) {
            lc.setOpportunityName(request.opportunityName);
        }
        
        if (request.ownerId != null) {
            lc.setOwnerId(request.ownerId);
        }
        
        if (request.sendEmailToOwner != null && request.sendEmailToOwner) {
            lc.setSendNotificationEmail(request.sendEmailToOwner);
        }
        
        Database.LeadConvertResult lcr = Database.convertLead(lc, true);
        ConvertLeadActionResult result = new ConvertLeadActionResult();
        if (lcr.isSuccess()) {
            
            result.accountId = lcr.getAccountId();
            result.contactId = lcr.getContactId();
            result.opportunityId = lcr.getOpportunityId();
            result.isSuccess = true;
            result.errorMessage = '';
            return result;
        } else {
            // 07-12-2021 DPC updated code to return errors as string message
            //throw new ConvertLeadActionException(lcr.getErrors()[0].getMessage());
            result.isSuccess = false;
            result.errorMessage = getErrorMessages(lcr.getErrors());
            return result;
        }
    }
    
    public class ConvertLeadActionRequest {
        @InvocableVariable(required=true)
        public ID leadId;
        
        @InvocableVariable(required=true)
        public String convertedStatus;
        
        @InvocableVariable
        public ID accountId;
        
        @InvocableVariable
        public ID contactId;
        
        @InvocableVariable
        public Boolean overWriteLeadSource;
        
        @InvocableVariable
        public Boolean createOpportunity;
        
        @InvocableVariable
        public String opportunityName;
        
        @InvocableVariable
        public ID ownerId;
        
        @InvocableVariable
        public Boolean sendEmailToOwner;
        
    }
    
    public class ConvertLeadActionResult {
        @InvocableVariable
        public ID accountId;
        
        @InvocableVariable
        public ID contactId;
        
        @InvocableVariable
        public ID opportunityId;
        
        // 07-12-2021 DPC added return of success flag and errors
        @InvocableVariable
        public Boolean isSuccess;
        
        @InvocableVariable
        public String errorMessage;
    }
    @TestVisible
    private static String getErrorMessages(List<Database.Error> errors){
        String errorMessage = '';
        for(Database.Error dbError : errors){
            errorMessage += dbError.getMessage() + '\n';
        }
        return errorMessage;
    }
    class ConvertLeadActionException extends Exception {}
}