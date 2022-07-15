({
	distyHandler : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get('v.userRec'))
           && !$A.util.isEmpty(component.get('v.disty'))){ 
        	helper.distyHelper(component, event);
        }
	}
})