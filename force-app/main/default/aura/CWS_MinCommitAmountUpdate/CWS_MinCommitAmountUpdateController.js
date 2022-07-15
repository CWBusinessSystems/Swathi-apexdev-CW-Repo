({
	recordUploaded: function(component, event, helper) {
        var $this = this;
    	if(!$A.util.isEmpty(component.get('v.oppObj'))){
        	component.set("v.oppID",component.get('v.oppObj.Id'));
            component.set("v.isMaster",component.get('v.oppObj.CWS_Master__c'));
            var throwErr = component.get('v.oppObj.CWS_Master__c');
            if(!throwErr){                                            
                helper.trhrowErr(component,event);
            }
            
        }
	},
    
    save: function(component, event, helper){debugger;
      helper.submitHelper(component, event, helper);
     }
})