({
	handleLoad: function(component, event,helper) {
		var today = new Date();
		component.set('v.today', today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate());
		
		component.set("v.isSpinnerActive",false);
	},
	oppHandler: function(component, event, helper){
		var changeType = event.getParams().changeType;
		if (changeType === "ERROR") { 
			alert('Failed to load details of Opportunity');
        }else{
            if(component.get("v.opp.Type")=='Renewal'){
                var strValue='New Quote cannot be created from Renewal Opportunity. '+
                    'Please use Renewal Quoted checkbox on Contract to create a Renewal Quote.';
                component.set("v.errorMessage",strValue);
                component.set("v.showError",true);
            }
        }
	},
	handleSubmit: function(component, event, helper) {
		event.preventDefault();       // stop the form from submitting
		/*Added lines 24 to 43 to add a toast message as part of OBD-3530 */
        
		var soldtocontact = component.get("v.opp.CWS_Sold_To_Contact__c");
        var billtocontact = component.get("v.opp.CWS_Bill_To_Contact__c");
        console.log('aaa' + JSON.stringify(soldtocontact));
        console.log('bbb' + JSON.stringify(billtocontact));
        if(soldtocontact == '' || billtocontact == '' || soldtocontact === null || billtocontact === null)
        {   
            var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			"title": "Error!",
			"type":"error",
			"duration":"2000",
			"message": "Please fill out Sold to Contact and Bill to contact on Opportunity record"
			
		});
		
		toastEvent.fire();
            console.log('Inside If method');
            return;
            
        }
		
		component.set("v.isSpinnerActive",true);
		var fields = event.getParam('fields');
		fields.SBQQ__Primary__c = true;
        /* Added this block for BED-6272, If Opportunity Type is Renewal with Change,
         * Quote should be marked as Renewal with Change.
         */
		fields.SBQQ__Type__c = 'Quote';
        if(component.get('v.opp.Type')=='Renewal with Change'){
			fields.CWS_Quote_Type__c = 'Renewal with Change';
			fields.OwnerId = component.get('v.opp.OwnerId');
			fields.SBQQ__Type__c = 'Renewal';
        }
        else{
            fields.CWS_Quote_Type__c = 'New Business';
        }
		
		fields.SBQQ__StartDate__c = component.get('v.today');
		//fields.SBQQ__Account__c = component.get('v.opp.AccountId');
		fields.SBQQ__Opportunity2__c = component.get('v.opp.Id');
        fields.CWS_Ship_To_Account__c = component.get('v.opp.CWS_Ship_To_Account__c');
       // fields.CWS_Bill_To_Account__c = component.get('v.opp.CWS_Bill_To_Account__c');
		fields.SBQQ__Distributor__c = component.get('v.opp.CWS_Distributor__c');
		fields.SBQQ__Partner__c = component.get('v.opp.AccountId');
		fields.CWS_Reseller_Account__c = component.get('v.opp.CWS_Reseller__c');
		fields.CWS_Bill_To_Contact__c = component.get('v.opp.CWS_Bill_To_Contact__c');
		//fields.CWS_Ship_To_Contact__c = component.get('v.opp.CWS_Ship_To_Contact__c');
		fields.SBQQ__PrimaryContact__c = component.get('v.opp.CWS_Sold_To_Contact__c');
        fields.CWS_Legal_Entity__c=component.get('v.opp.CWS_Legal_Entity__c');
        
		var action = component.get("c.NBQuoteDefaults");

        action.setCallback(this, function(result) {
            if(result.getState() === "SUCCESS"){
                var valueMap = result.getReturnValue();
				console.log(valueMap);
				for (var index=0; index<valueMap.length;index++) {
					var obj = JSON.parse(valueMap[index]);
					fields[obj.fieldName] = obj.fieldValue;
				}
				component.find('quoteForm').submit(fields);
            }
            else if(result.getState() === "ERROR"){
                console.log('Callback Error');
                var errors = result.getError();
                if(errors[0] && errors[0].message){
					console.log(errors);
					component.set("v.recordError",errors[0].message);
					component.set("v.isSpinnerActive",false);
                }
            }
            else{
                console.log('Unexpected error!');
            }
             
        });
        $A.enqueueAction(action);

	},
    /* Changed this block for FORCE-3; removed toast, added redirect to created quote */
	handleSuccess: function(component, event, helper) {
		var quoteRecord = JSON.parse(JSON.stringify(event.getParams()));
		var quoteId = quoteRecord.response.id;
        var urlEvent = $A.get("e.force:navigateToURL");
		console.log(quoteRecord);

		urlEvent.setParams({
				url:'/apex/SBQQ__sb?id=' +quoteId
		});
				
		$A.get("e.force:closeQuickAction").fire();    
		urlEvent.fire();
	},
	handleError: function (component, event, helper) {
		component.set("v.isSpinnerActive",false);
	}
})