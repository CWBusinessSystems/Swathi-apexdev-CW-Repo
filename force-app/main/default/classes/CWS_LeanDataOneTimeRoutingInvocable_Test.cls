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
@isTest
public class CWS_LeanDataOneTimeRoutingInvocable_Test {
@isTest
    public static void testLeadRouting(){
        Lead testLead = new Lead(Company='Test Apex',firstName='Fake',lastName='Smith',email='tsmith@invalid.com',country='United States',cws_skip_routing__c=true);
        insert testLead;
        List<CWS_LeanDataOneTimeRoutingInvocable.OneTimeRoutingFlowInput> ldInputs = new List<CWS_LeanDataOneTimeRoutingInvocable.OneTimeRoutingFlowInput>();
        CWS_LeanDataOneTimeRoutingInvocable.OneTimeRoutingFlowInput ldInput = new CWS_LeanDataOneTimeRoutingInvocable.OneTimeRoutingFlowInput();
        ldInput.sObjectType = 'Lead';
        ldInput.sObjectId = testLead.Id;
        ldInput.graphName = 'APEX Test Coverage';
        ldInput.nodeType = 'Updated Lead';
        ldInput.edgeName = 'Edge 1';
        ldInputs.add(ldInput);
        List<CWS_LeanDataOneTimeRoutingInvocable.OneTimeRoutingFlowOutput> ldOutputs = CWS_LeanDataOneTimeRoutingInvocable.invocableOneTimeRouting(ldInputs);
        
    } 
    @isTest
    public static void testResponseParse(){
        Map<String,Object> testMap = new map<String,Object>();
        testMap.put('objectType','Lead');
        testMap.put('jobId','123212321432123123');
        testMap.put('nRecords',1);
        testMap.put('condition','Update');
        testMap.put('status','Success');
        testMap.put('errorstate','error');
        CWS_LeanDataOneTimeRoutingInvocable.OneTimeRoutingFlowOutput testOutput = CWS_LeanDataOneTimeRoutingInvocable.parseResultMap(testMap);
        system.assertEquals(testOutput.condition,'Update');
    }
}