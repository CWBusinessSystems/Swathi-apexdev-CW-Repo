({
    initHandler : function(component, event, helper) {
  		helper.CheckAMUser(component, event, helper);
        
    },
    //8913 start
    closeModel: function(component, event, helper) {
      			 component.set("v.alertMessage", false);
                $A.get("e.force:closeQuickAction").fire()
	           },
    
    continuebutton: function(component, event, helper) {
    			var QId = component.get('v.recordId');
        		var Continue= true;
      			 var action = component.get("c.fieldsChk");
        			//Setting the Parameter for the Action
    				action.setParams({ quoteId : QId, isContinue:true });
 					action.setCallback(this, function(response) {
            		var state = response.getState();
                        if(state === "SUCCESS"){
                          var mandatoryFieldsError=response.getReturnValue(); 
							if(mandatoryFieldsError.length == 0) 
                            {
                            var AcceptedMessage = $A.get("$Label.c.CWS_AcceptedMessage");
                            component.set("v.Accepted",true);
                    		component.set("v.AcceptedMessage",AcceptedMessage);
                            $A.get("e.force:closeQuickAction").fire();		//added for a refreshed view
                        	$A.get('e.force:refreshView').fire();   		//added for a refreshed view
                                
                            }
                            else{
                            component.set("v.MandatoryErrors",true);
                    		component.set("v.listError",mandatoryFieldsError);
                            }
                         }
                    
                        else if(state == "ERROR"){
                        var errors = response.getError(); 
                        component.set("v.showErrors",true);
                        component.set("v.errorMessage",errors[0].message);
                        }
                    });
                    $A.enqueueAction(action);
               }
 
})
//8913 end