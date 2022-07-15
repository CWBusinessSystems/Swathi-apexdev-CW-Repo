({	    
	CheckAMUser : function(component, event, helper) {
        var QId = component.get('v.recordId');
        var action = component.get("c.CAUserCheck"); 
        //8913 start
        var isCont=false;
        var quoteErrorMessagesList = [];
        var quoteAlertMessageList=[]; 
        var warning = $A.get("$Label.c.CWS_Warning"); 
        var alert;
        //8913 end
        //Setting the Parameter for the Action
        action.setParams({QuoteId:QId});
 		action.setCallback(this, function(response) {
            var state = response.getState();
            //If the Response State is Success
            if (state === "SUCCESS") {
                var CanAcceptVar=response.getReturnValue();
                    //If the Callback Returns True
                    if(CanAcceptVar.length == 0){

                     var actionFieldsChk = component.get("c.fieldsChk");
                    //Setting the Parameter for the Action
                    actionFieldsChk.setParams({ quoteId : QId, isContinue:false });
                    actionFieldsChk.setCallback(this, function(response) {
            		var state = response.getState();
                        if(state === "SUCCESS"){
                          var mandatoryFieldsError=response.getReturnValue(); 
                           //8913 start
                            for(var i=0; i<mandatoryFieldsError.length;i++)
                            {
                            	if(mandatoryFieldsError[i].startsWith( warning ))
                            	{
                               		alert = mandatoryFieldsError[i].replace(warning,""); 
                                    quoteAlertMessageList.push(alert);

                            	}
                                else
                                    quoteErrorMessagesList.push(mandatoryFieldsError[i]);
                            }
                            if(quoteErrorMessagesList.length == 0){
                            if(quoteAlertMessageList.length > 0 )
                           		{
                    				console.log(quoteAlertMessageList);
                                    component.set("v.alertMessage",true);
                                    component.set("v.lstAlertMessage", quoteAlertMessageList);
                				}
                                //8913 end
                                else{
                            var AcceptedMessage = $A.get("$Label.c.CWS_AcceptedMessage");
                            component.set("v.Accepted",true);
                    		component.set("v.AcceptedMessage",AcceptedMessage);
                                }
                            }
                            else{
                            component.set("v.MandatoryErrors",true);
                    		component.set("v.listError",quoteErrorMessagesList);
                            }
                         }
                        else if(state == "ERROR"){
                        var errors = response.getError(); 
                        component.set("v.showErrors",true);
                        component.set("v.errorMessage",errors[0].message);
                        }
                    });
                    $A.enqueueAction(actionFieldsChk);
                    }
                    //If the Callback Returns False
                    else
                    {
                    component.set("v.showErrors",true);
                    component.set("v.listError1",CanAcceptVar);
                    }
            }
            //If the Response State is Error
            else if(state == "ERROR"){
            var errors = response.getError();        
            component.set("v.showErrors",true);
            component.set("v.errorMessage",errors[0].message);
            }
        });
        $A.enqueueAction(action);
	}
})