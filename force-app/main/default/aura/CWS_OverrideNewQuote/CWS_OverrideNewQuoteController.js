({
	closePage : function(component, event, helper) {
		var homeEvent = $A.get("e.force:navigateToObjectHome");
        homeEvent.setParams({
            "scope": "Opportunity"
        });
        homeEvent.fire();
	}
})