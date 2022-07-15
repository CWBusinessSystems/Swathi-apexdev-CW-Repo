({
    recordUploaded: function(component, event, helper) {
        var $this = this;
    	if(!$A.util.isEmpty(component.get('v.oppObj'))){
        	component.set("v.oppID",component.get('v.oppObj.Id'));
            component.set("v.accID",component.get('v.oppObj.AccountId'));
            component.set("v.currCode",component.get('v.oppObj.CurrencyIsoCode'));
            component.set("v.isMaster",component.get('v.oppObj.CWS_Master__c'));
            var throwErr = component.get('v.oppObj.CWS_Master__c');
            if(!throwErr){                                            
                helper.trhrowErr(component,event);
            }
        }
	},
    
    uploadHandler: function(component, event, helper) {
       	var filename = event.getSource().get("v.files")[0];
 		var textdata;
        var reader = new FileReader();
        reader.onload = readSuccess; 
		reader.readAsText(filename);
        var minCommObj;
        var oppID = component.get('v.oppID');
        var accID = component.get('v.accID');
        var currCode = component.get('v.currCode');
        
            function readSuccess(event) {
                var text = reader.result; 
                textdata = text;
                var rows = textdata.split('\n');
                var isError;
                var helpText = 'helptext';
                var minArr = {
                    isError,
                    helpText,
                    minCommObj
                }
                
                var finalList = [];
                component.set("v.isUploaded", true);
                for (var i = 1; i < rows.length-1; i++){
                    var cells = rows[i].split(',');
                    var mmc = cells[0].trim();
                    var my = cells[1].trim();
                    if(mmc != "" || my != ""){
                        var minCommObj = {
                            sobjectType : 'CWS_Minimum_Commit__c',
                            CWS_Monthly_Minimum_Commit__c : mmc,
                            CWS_Month_Year__c : my,
                            CWS_Opportunity__c : oppID,
                            CWS_Account__c : accID,
                            CurrencyIsoCode : currCode,
                        }
                        var minArr = {
                            isError : false,
                            helpText : '',
                            minCommObj : minCommObj
                        }
                        finalList.push(minArr);
                    }
                }                        
                component.set("v.minCommList", finalList);                         
          }
    },
    
    removeRow: function(component, event, helper) {
        var minList = component.get("v.minCommList");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        minList.splice(index, 1);
        component.set("v.minCommList", minList);
    },
    
    save: function(component, event, helper) {debugger;
       if(helper.validateminCommList(component,event)){
       		helper.uploadHelper(component, event, helper);
       }
    }
})