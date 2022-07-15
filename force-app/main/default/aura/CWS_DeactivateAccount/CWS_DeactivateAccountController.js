({
	accHandler : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get('v.userRec'))
           && !$A.util.isEmpty(component.get('v.recordId'))){ 
            helper.accHelper(component, event);
        }
	}
})