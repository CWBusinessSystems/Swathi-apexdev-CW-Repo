({
	createErrorToastComponent : function(component, event, helper){
        var errorMessage = component.get("v.errorMessage");
        $A.createComponent(
            "c:CWS_ErrorToastComponent",
            {
                "aura:Id" : "errorToastId",
                "errorMessage" : errorMessage
            },
            function(auraDynCmp, status, errorMessage){
                if(component.isValid() && status === "SUCCESS"){
                    component.set("v.errorToastComponent", []);
                    var errorToastComponent = component.get("v.errorToastComponent");
                    errorToastComponent.push(auraDynCmp);
                    component.set("v.errorToastComponent", errorToastComponent);
                }
                else if(status === "INCOMPLETE"){
                    console.log("No response from server or client is offline.");
                }
                else if(status === "ERROR"){
                    console.log(errorMessage);
                }
            }
        );
	}

})