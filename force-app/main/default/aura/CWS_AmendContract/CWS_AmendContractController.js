({
    initHandler : function(component, event, helper) {
        helper.CheckAMUser(component, event, helper);
        helper.checkIfContractisExpiring(component, event, helper);
        
    },
    
    onControllerFieldChange: function(component, event, helper) {     
        var controllerValueKey = event.getSource().get("v.value"); // get selected controller field value
        var dependentFieldMap = component.get("v.dependentFieldMap");
        
        if (controllerValueKey != '--- None ---') {
            var ListOfDependentFields = dependentFieldMap[controllerValueKey];
            var transaction = component.find("transaction").get("v.value");
                if(transaction == 'Credit/Re-bill'){
                    component.set('v.condition',false);
                }
                else{
                    component.set('v.condition', true);
                    component.find("subType").set("v.value", "None");
                }
            	if(transaction == 'Credit/Re-bill' || transaction == 'Agreement Conversion' || transaction == 'Merger & Acquisition' || transaction == 'Recommit'){
                    component.set('v.Type',false);
                }
                else{
                    component.set('v.Type', true);
                    component.find("recontractType").set("v.value", "None");
                }
            if(ListOfDependentFields.length > 0){
                component.set("v.bDisabledDependentFld" , false);  
                helper.fetchDepValues(component, ListOfDependentFields);    
            }else{
                component.set("v.bDisabledDependentFld" , true); 
                component.set("v.listDependingValues", ['--- None ---']);
            }  
            
        } else {
            component.set("v.listDependingValues", ['--- None ---']);
            component.set("v.bDisabledDependentFld" , true);
        }
    },
    
    handleClick : function(component, event, helper) {
        // get the fields API name and pass it to helper function  
        var transaction = null;
        var staticLable4 = $A.get("$Label.c.CWS_Amend_Contract_Transaction_Reason");
        var conversion = '--- None ---';
        var status = null;
        var recontract = null;
        transaction = component.find("transaction").get("v.value"); 
        var conCheck = component.get("v.bDisabledDependentFld");
        var statCheck = component.get("v.condition"); 
        var typeCheck = component.get("v.Type");
        if(!conCheck){                                             
       		conversion = component.find("conversion").get("v.value");
        }
        if(!typeCheck){                                             
       		recontract = component.find("recontractType").get("v.value");
        }
        if(!statCheck){
        	 status = component.find("subType").get("v.value");
        }    
        var conId = component.get("v.recordId");
        // call the helper function 
        if ((!(conCheck) && conversion == '--- None ---' && transaction == 'Credit/Re-bill')||transaction == ''||transaction == '--- None ---'||( !(statCheck) && status == 'None')){
               component.set("v.showaltError",true);
               component.set("v.errorMessage",staticLable4); 
            }                             
        else{ 
            if(conversion == '--- None ---'){
                conversion=null;
            }
            if(recontract == 'None'){
                recontract= null;
            }
            if(status == 'None'){
                status = null;
            }
            component.set("v.showaltError",false);
            component.set("v.errorMessage",'');
            //Code Modified for OBD-132 by Pooja Dhiman
            var action = component.get("c.validateTerminationApproval");
            action.setParams({
            'contractId': conId
        	});
            action.setCallback(this, function(response) {
                if (response.getState() == "SUCCESS") { 
                    var resp = response.getReturnValue();
                    if(resp == 'true' && transaction == 'Termination'){
                         component.set("v.showErrors",true);
                		component.set("v.errorMessage","You do not have permission to select \"Termination\" as a reason for amending the contract.  Please make another selection.");
                    }else{
                        helper.updateRecord(component,transaction,conversion,status,recontract,conId);
                    }
                }
            });
            $A.enqueueAction(action);
        }    
    },
    
    onCancel : function(component, event, helper) {
    // Navigate back to the record view
    var navigateEvent = $A.get("e.force:navigateToSObject");
    navigateEvent.setParams({ "recordId": component.get('v.recordId') });
    navigateEvent.fire();
	}
})