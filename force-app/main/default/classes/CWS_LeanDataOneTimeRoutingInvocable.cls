/**
* @description       : 
* @author            : DPC Advictoriam Solutions
* @group             : 
* @last modified on  : 12-22-2021
* @last modified by  : Mahak Bansal
* Modifications Log 
* Ver   Date         Author                      Modification
* 1.0   06-18-2021   DPC Advictoriam Solutions   Initial Version
* 1.1   12-22-2021   Mahak Bansal (CWS)          Added parameter to make sure the leandata to respect the User Schedule
**/
public Without Sharing class CWS_LeanDataOneTimeRoutingInvocable {
    public class OneTimeRoutingFlowInput{ 
        @InvocableVariable (label='Object API of Record' description='Object API Name of the record being routed' required='true')
        public String sObjectType;
        @InvocableVariable (label='Record Id to Route' description='Record Id to be routed by LeanData' required='true')
        public Id sObjectId;
        @InvocableVariable (label='LeanData Graph Name' description='The graph name in LeanData to use for one time routing does not need to be active' required='true' )
        public String graphName;
        @InvocableVariable (label='Must be Insert Trigger or Update Trigger' description='Graph entry point' required='true')
        public String nodeType;
        @InvocableVariable (label='Edge Name Path to Follow' description='Edge Name path to follow from Node entry point' required='true')
        public String edgeName;
    }
    public class OneTimeRoutingFlowOutput{
        @InvocableVariable
        public String objectType;
        @InvocableVariable
        public String jobId;
        @InvocableVariable
        public Integer nRecords;
        @InvocableVariable
        public String condition;
        @InvocableVariable
        public String status;
        @InvocableVariable
        public String errorMessage;
    }
    @InvocableMethod(label='LeanData One Time Routing' description='Call LeanData One Time Routing from a Visual Flow')
    public static List<OneTimeRoutingFlowOutput> invocableOneTimeRouting(List<OneTimeRoutingFlowInput> inputs){
        List<OneTimeRoutingFlowOutput> outputs = new List<OneTimeRoutingFlowOutput>();
        
        Map<String, Object> paramsMap = new Map<String, Object>();
        Map<String, Object> resultMap = new Map<String, Object>();
        try{
            paramsMap.put('objectType', inputs[0].sObjectType);
            paramsMap.put('condition', 'Id = \'' + inputs[0].sObjectId+'\'');
            paramsMap.put('graphName', inputs[0].graphName);
            paramsMap.put('nodeType', inputs[0].nodeType);
            paramsMap.put('edgeName', inputs[0].edgeName);
            paramsMap.put('notificationsDisabled', true);
            paramsMap.put('sendEmail', false);
            paramsMap.put('allowDedupe', false);
            //Added by Mahak 22 Dec 2021 - OBD-3068
            //This make sure the leandata to respect the User Schedule
            paramsMap.put('respectSchedules', true);
            if(!Test.isRunningTest()) {resultMap = LeanData.LeanDataAPI.oneTimeRouting(paramsMap);}
            
            outputs.add(parseResultMap(resultMap));
            if(Test.isRunningTest()){ throw new CalloutException('testing Error');}
        } catch(exception e){
            system.debug('exception with one time routing'+e.getMessage());
            resultMap.put('Fatal Error',e.getMessage());
            outputs.add(parseResultMap(resultMap));
        }
        return outputs;
    }
    @testVisible
    private static OneTimeRoutingFlowOutput parseResultMap(Map<String,Object> resultMap){
        OneTimeRoutingFlowOutput flowOutput = new OneTimeRoutingFlowOutput();
        String errorMessage = '';
        for(String s : resultMap.keySet()){
            system.debug('S'+s);
            system.debug('S Get'+resultMap.get(s));
            switch on s {
                when 'objectType'{flowOutput.objectType = String.valueOf(resultMap.get(s));}
                when 'jobId'{flowOutput.jobId = String.valueOf(resultMap.get(s));}
                when 'nRecords'{flowOutput.nRecords = Integer.valueOf(resultMap.get(s));}
                when 'condition'{flowOutput.condition = String.valueOf(resultMap.get(s));}
                when 'status'{flowOutput.status = String.valueOf(resultMap.get(s));}
                when else {errorMessage += s + ' - '+ String.valueOf(resultMap.get(s)) + '\n';}
            }
        }
        if(!String.isBlank(errorMessage)) {flowOutput.errorMessage = errorMessage;}
        
        return flowOutput;
    }
}