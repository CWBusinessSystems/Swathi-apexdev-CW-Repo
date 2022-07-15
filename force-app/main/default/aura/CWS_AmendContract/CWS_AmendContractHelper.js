({
    checkIfContractisExpiring : function(component, event, helper) {
        var cId = component.get('v.recordId');
        var action = component.get("c.ContractExipryCheck");
        //Setting the Parameter for the Action
        action.setParams({contractID:cId});
 		action.setCallback(this, function(response) {
            var state = response.getState();
            //If the Response State is Success
            if (state === "SUCCESS") {
                let isExpiring = response.getReturnValue();
                if(isExpiring){
                   var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                         "mode": 'sticky',
                        "type" : "warning",
                        "title": 'Alert',
                        "message": "Contract is expiring in less than 30 days, please do Renewal with Change."
                    });
                    toastEvent.fire(); 
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
    },
	CheckAMUser : function(component, event, helper) {
        var cId = component.get('v.recordId');
        var action = component.get("c.AMUserCheck");
        //Setting the Parameter for the Action
        action.setParams({contractID:cId});
 		action.setCallback(this, function(response) {
            var state = response.getState();
            //If the Response State is Success
            if (state === "SUCCESS") {
            	component.set('v.CanAmend',response.getReturnValue());
                var CanAmendVar = component.get('v.CanAmend');
                    //If the Callback Returns True
                    if(CanAmendVar=="True"){ 
                    var controllingFieldAPI = component.get("v.controllingFieldAPI");debugger
        			var dependingFieldAPI = component.get("v.dependingFieldAPI");
        			var objDetails = component.get("v.objDetail");
                    // call the helper function
                    this.fetchPicklistValues(component,objDetails,controllingFieldAPI, dependingFieldAPI);
                    }
                    //If the Callback Returns False
                    //BED-6434 starts
                    else
                    {
                        if (CanAmendVar=="False"){
                            var staticLabel = $A.get("$Label.c.CWS_AmendmentError");
                            component.set("v.showErrors",true);
                            component.set("v.errorMessage",staticLabel);
                        }
                        else{
                            var nstaticLabel = $A.get("$Label.c.CWS_SplitPending_Error");
                            component.set("v.showErrors", true);
                            component.set("v.errorMessage", nstaticLabel);
                        }  
                    }
                    //BED-6434 Ends
            }
            //If the Response State is Error
            else if(state == "ERROR"){
            var errors = response.getError();        
            component.set("v.showErrors",true);
            component.set("v.errorMessage",errors[0].message);
            }
        });
        $A.enqueueAction(action);
	},
    fetchPicklistValues: function(component,objDetails,controllerField, dependentField) {
        // call the server side function  
        var action = component.get("c.getDependentMap");
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        action.setParams({
            'objDetail' : objDetails,
            'contrfieldApiName': controllerField,
            'depfieldApiName': dependentField 
        });
        //set callback   
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = response.getReturnValue();
                
                // once set #StoreResponse to depnedentFieldMap attribute 
                component.set("v.dependentFieldMap",StoreResponse);
                
                // create a empty array for store map keys(@@--->which is controller picklist values) 
                var listOfkeys = []; // for store all map keys (controller picklist values)
                var ControllerField = []; // for store controller picklist value to set on lightning:select. 
                
                // play a for loop on Return map 
                // and fill the all map key on listOfkeys variable.
                for (var singlekey in StoreResponse) {
                    listOfkeys.push(singlekey);
                }
                
                //set the controller field value for lightning:select
                if (listOfkeys != undefined && listOfkeys.length > 0) {
                    ControllerField.push('--- None ---');
                }
                
                for (var i = 0; i < listOfkeys.length; i++) {
                    ControllerField.push(listOfkeys[i]);
                }  
                // set the ControllerField variable values to country(controller picklist field)
                component.set("v.listControllingValues", ControllerField);
            }else{
                var staticLabel5 = $A.get("$Label.c.CWS_Generic_Error");
                component.set("v.showErrors", true);
                component.set("v.errorMessage", staticLabel5);
            }
        });
        $A.enqueueAction(action);
    },
    
    fetchDepValues: function(component, ListOfDependentFields) {
        // create a empty array var for store dependent picklist values for controller field  
        var dependentFields = [];
        dependentFields.push('--- None ---');
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            dependentFields.push(ListOfDependentFields[i]);
        }
        // set the dependentFields variable values to store(dependent picklist field) on lightning:select
        component.set("v.listDependingValues", dependentFields);
        
    },
    
    updateRecord: function(component,transaction,conversion,status,recontract,conId) {
     var action = component.get("c.updateRecord");
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        action.setParams({
            'trans' : transaction,
            'conversion': conversion,
            'status':status,
            'recontract': recontract,
            'conId': conId
        });
        //set callback   
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") { 
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = response.getReturnValue();
                if(StoreResponse){ 
                    var cId = component.get('v.recordId');
                    var strURL = '/apex/SBQQ__AmendContract?id='+cId;
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": strURL
                    });
                    urlEvent.fire();
                }
                else{ 
                    var staticLabel5 = $A.get("$Label.c.CWS_Generic_Error");
                    component.set("v.showErrors",true);
                    component.set("v.errorMessage",staticLabel5);
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