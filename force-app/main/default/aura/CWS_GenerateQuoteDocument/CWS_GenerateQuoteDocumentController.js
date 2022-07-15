({
	initHandler : function(component, event, helper) {
        helper.validateQuoteOnDocGen(component, event);	
	},
	submit: function(component, event, helper) {		
		var quoteId = component.get("v.recordId");
		var strURL = '/apex/SBQQ__GenerateDocument?Id=' + quoteId;
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": strURL
		});
		urlEvent.fire();	
	},
    closeModel: function(component, event, helper) {
        component.set("v.isOpen", false);
        $A.get("e.force:closeQuickAction").fire();
	}
})