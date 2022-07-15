({
	doValidations : function(component,event) {
    	var agrmntId = component.get("v.recordId");
		var action = component.get("c.validations");
		action.setParams({
            agreementId : agrmntId
        });
        action.setCallback(this,function(response){
        var result = response.getState();
         if(result === 'SUCCESS'){
             var errormsg = response.getReturnValue();
             if(!$A.util.isEmpty(errormsg)){
                 component.set("v.lstErrorMsgs", errormsg);
             }
             if($A.util.isEmpty(errormsg)){
                 var strURL = decodeURIComponent('/apex/Apttus_Approval__PreviewSubmitApprovals?id='+agrmntId);
                 var redirectToAgreement = $A.get("e.force:navigateToURL");
                 redirectToAgreement.setParams(
                     {"url" : strURL} 
                 ).fire();
             } 
        }
        })
        $A.enqueueAction(action);
	}
})