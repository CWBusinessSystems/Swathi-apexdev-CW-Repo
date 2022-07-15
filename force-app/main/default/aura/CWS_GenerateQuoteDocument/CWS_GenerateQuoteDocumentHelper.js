({
    validateQuoteOnDocGen: function (component, event) {
        var qId = component.get('v.recordId');
        var action = component.get("c.validateQuoteOnDocGen");
        var warning = $A.get("$Label.c.CWS_Warning");

        action.setParams({ quoteID: qId });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                debugger;
                var mapQuoteDocGenErrs = response.getReturnValue();
                var lstquoteDocGenErrs = [];
				var lstquoteDocGenAlertMsg = [];
                console.log('mapQuoteDocGenErrs - ' + mapQuoteDocGenErrs);
                if (mapQuoteDocGenErrs !== null && mapQuoteDocGenErrs !== '') {
                    for (var quoteDocGenErr in mapQuoteDocGenErrs) {
                        var quoteDocGenErrMsg = mapQuoteDocGenErrs[quoteDocGenErr];
                        if (quoteDocGenErrMsg !== null && quoteDocGenErrMsg !== '' && quoteDocGenErrMsg.length > 0 && quoteDocGenErr.startsWith( warning )) {
                            lstquoteDocGenAlertMsg.push(quoteDocGenErrMsg);
						}else{							
							lstquoteDocGenErrs.push(quoteDocGenErrMsg);							
						}  
                    }
                }
                if(lstquoteDocGenErrs.length > 0){
					component.set("v.hasError", true);
					//var quoteDocGenErrFinal = lstquoteDocGenErrs.join('<br>');
					console.log('quoteDocGenErrFinal - ' + lstquoteDocGenErrs);
					component.set("v.errorMessage", lstquoteDocGenErrs);   
                
                } else if(lstquoteDocGenAlertMsg.length > 0) {
                    component.set("v.hasError", false);
					component.set("v.isOpen", true);
					if (lstquoteDocGenAlertMsg.length > 0)
						component.set("v.lstAlertMessage", lstquoteDocGenAlertMsg);
                }else{
					component.set("v.isOpen", false);
					var quoteId = component.get("v.recordId");
					var strURL = '/apex/SBQQ__GenerateDocument?Id=' + quoteId;
					var urlEvent = $A.get("e.force:navigateToURL");
					urlEvent.setParams({
						"url": strURL
					});
					urlEvent.fire();	
                }     
            }
        });
        $A.enqueueAction(action);
    }  
})