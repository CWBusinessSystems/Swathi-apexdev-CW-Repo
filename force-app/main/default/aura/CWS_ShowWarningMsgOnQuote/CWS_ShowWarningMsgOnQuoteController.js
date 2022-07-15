({
	 initHandler : function(component, event, helper) {
        var QId = component.get('v.recordId');
        var action = component.get("c.refreshPriceOnQuote");   
		//Setting the Parameter for the Action
		action.setParams({QuoteId:QId});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(state === "SUCCESS"){
				var hasErrorMsg = response.getReturnValue();
                component.set("v.hasErrorMsg", hasErrorMsg);
				if(hasErrorMsg){
					var warningMsg = $A.get("$Label.c.CWS_UI_RefreshPriceErrorMsg");
					component.set("v.warningMsg",warningMsg);
				}				
				debugger;
			}
			else if(state == "ERROR"){
				var errors = response.getError(); 
				component.set("v.showErrors",true);
				component.set("v.errorMessage",errors[0].message);
			}
		});
		$A.enqueueAction(action);
     },
	 quoteHandler: function(component, event, helper){
		var changeType = event.getParams().changeType;
        var err=component.get('v.recordError')
		if (changeType === "ERROR") { 
			alert('Failed to load details of Quote' +err) ;
        }
      } 
})