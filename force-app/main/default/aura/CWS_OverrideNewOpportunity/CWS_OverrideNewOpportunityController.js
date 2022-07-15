/*
Ad Victoriam Solutions - CW11-P1-SFDX-ven
Purpose: 
Dependencies:
Changelog:
    18 Jan 2022 by chase.brammer for JIRA-01
        - Created initial file.
*/

({
    init : function(component) {

        // TODO determine a way to pass in the RecordId for the related list the New button is located on.
        // let flowRecordId = null;
        //
        // console.log('RECORD ID: ');
        // console.log(flowRecordId);
        //
        // let flowInputVariables = [
        //     {
        //         name: "recordId",
        //         type : "String",
        //         value: flowRecordId
        //     }
        // ];
        
        let flowApiName = "New_Opportunity_Screen_Flow";
        // find the component whose aura:id is "flowData"
        let flow = component.find("flowData");
        // in that component, start your flow. reference the flow's API Name.
        flow.startFlow(flowApiName);
    },


})