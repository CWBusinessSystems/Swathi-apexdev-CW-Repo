({
    doInit : function(component, event, helper) {

        var action = component.get("c.getQuoteStages");
        action.setCallback(this, function(result) {
            if(result.getState() === "SUCCESS"){
                var stages = result.getReturnValue();
                console.log(stages);
                component.set("v.stages",stages);
                if (component.get("v.stageMap") == '' || component.get("v.stageMap") == null) {
                    helper.prepareMap(component,event);
                }
            }
            else if(result.getState() === "ERROR"){
                console.log('Callback Error');
                var errors = result.getError();
                if(errors[0] && errors[0].message){
                    console.log(errors);
                }
            }
            else{
                console.log('Unexpected error!');
            }
             
        });
        $A.enqueueAction(action);

    },
    quoteHandler: function(component, event, helper){
		var changeType = event.getParams().changeType;
		if(changeType === "LOADED") {
            console.log("Record is loaded successfully.");
            if (component.get("v.stageMap") == '' || component.get("v.stageMap") == null) {
                helper.prepareMap(component,event);
            }

        } else if(changeType === "CHANGED") {
            helper.prepareMap(component,event);
        } else if (changeType === "ERROR") { 
			alert('Failed to load details of Quote');
		 }
	},
})