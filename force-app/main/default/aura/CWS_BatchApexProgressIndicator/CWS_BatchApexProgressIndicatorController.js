({
	doInit : function(component, event, helper) {
		var jobId = component.get("v.inputJobId");
        console.log('in doInit of progress bar');
        if(jobId) helper.getBatchStatus(component);
	}
})