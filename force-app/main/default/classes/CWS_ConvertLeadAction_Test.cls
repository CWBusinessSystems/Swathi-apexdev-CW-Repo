@isTest
public class CWS_ConvertLeadAction_Test {
    
    static testMethod void testConvertSuccess() {
        
        Lead leadToCreate1 =new Lead();
        leadToCreate1.FirstName = 'Sammy';
        leadToCreate1.LastName ='Bertha';
        leadToCreate1.Company='Salesforce';
        leadToCreate1.Status='MQL';
        
        leadToCreate1.Email = 'bigbertha@testing.com.invalid';
        leadToCreate1.Street ='1 Union Street';
        leadToCreate1.City = 'Tampa';
        leadToCreate1.State = 'Florida';
        leadToCreate1.PostalCode = '33601';
        leadToCreate1.Country = 'United States';
        leadToCreate1.LeadSource = 'Web Direct';
        insert leadToCreate1;
        Lead leadToCreate2 =new Lead();
        leadToCreate2.FirstName = 'Sammy';
        leadToCreate2.LastName ='Second';
        leadToCreate2.Company='Salesforce';
        leadToCreate2.Status='MQL';
        leadToCreate2.Email = 'samsecond@testing.com.invalid';
        leadToCreate2.Street ='1 Union Street';
        leadToCreate2.City = 'Tampa';
        leadToCreate2.State = 'Florida';
        leadToCreate2.PostalCode = '33601';
        leadToCreate2.Country = 'United States';
        leadToCreate2.LeadSource = 'Web Direct'; 
        insert leadToCreate2;
        Test.startTest();
        List<CWS_ConvertLeadAction.ConvertLeadActionRequest> claList1 = new List<CWS_ConvertLeadAction.ConvertLeadActionRequest>();
        CWS_ConvertLeadAction.ConvertLeadActionRequest claRequest1 = new CWS_ConvertLeadAction.ConvertLeadActionRequest();
        claRequest1.leadId = leadToCreate1.id;
        claRequest1.convertedStatus = 'Converted';
        claRequest1.createOpportunity = false;
        claRequest1.sendEmailToOwner = false;
        claList1.add(claRequest1);
        List<CWS_ConvertLeadAction.ConvertLeadActionResult> results = CWS_ConvertLeadAction.convertLeads(claList1);
        system.debug('results'+results[0]);
        system.assertNotEquals(results[0].accountId,null);
        system.assertEquals(results[0].opportunityId,null);
        // convert with contact and accountid
        List<CWS_ConvertLeadAction.ConvertLeadActionRequest> claList2 = new List<CWS_ConvertLeadAction.ConvertLeadActionRequest>();
        CWS_ConvertLeadAction.ConvertLeadActionRequest claRequest2 = new CWS_ConvertLeadAction.ConvertLeadActionRequest();
        claRequest2.leadId = leadToCreate2.id;
        claRequest2.convertedStatus = 'Converted';
        claRequest2.createOpportunity = true;
        claRequest2.opportunityName = 'Test Opportunity';
        claRequest2.accountId = results[0].accountId;
        claRequest2.contactId = results[0].contactId;
        claRequest2.sendEmailToOwner = false;
        claRequest2.overWriteLeadSource = false;
        claRequest2.ownerId = userinfo.getUserId();
        claList2.add(claRequest2);
        List<CWS_ConvertLeadAction.ConvertLeadActionResult> results2 = CWS_ConvertLeadAction.convertLeads(claList2);
        system.debug('results2'+results2[0]);
        
        system.assertNotEquals(results2[0].opportunityId,null);
        Test.stopTest();
    }
    
}