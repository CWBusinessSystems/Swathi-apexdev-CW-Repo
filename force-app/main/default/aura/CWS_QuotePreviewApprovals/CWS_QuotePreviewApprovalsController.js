({
    initHandler : function(component, event, helper) {

        var qId = component.get('v.recordId');
        var strURL = '/apex/sbaa__PreviewApprovals?Id='+qId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": strURL
        });
        urlEvent.fire();

    }
})