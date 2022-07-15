({
    handleRecordUpdated:function(component, event) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "ERROR"){
            component.set("v.changePath",false);
        }
    },
    handleSelect : function(component, event, helper) {
        var stepName = event.getParam("detail").value;
        component.find('recordSaver').reloadRecord(true,function(){
            var pathCheck = component.get("v.changePath");
            var leadRec = component.get("v.leadRecord");
            if(pathCheck){
                if(stepName != leadRec.Status){
                    switch(stepName) {
                        case "Rejected":
                            helper.showModal(component,stepName,"Rejected Warning",
                            "If you proceed with moving the Lead to Rejected the Lead will no longer be workable in the future");
                            break;
                        case "Recycled":
                            helper.showModal(component,stepName,"Recycled Warning",
                            "If you proceed with moving the Lead to Recycled you will not be able to work on the Lead until it is re-added to Salesforce");
                            break;
                        default:
                            helper.changeStatus(component,stepName);
                    }
                }
            } else {
                helper.showErrorToast($A.get("$Label.c.CWS_SomethingWentWrong"));
            }
        });
    }
})