({
    doinit : function(component, event, helper) {
        component.set('v.Spinner', true);
        var action = component.get("c.showSiteDetailReport");
        action.setParams({
            'invoiceId': component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") { 
                var responseWrap = response.getReturnValue();                
                if(responseWrap.showSiteDetailButton){
                   component.set('v.showSiteDetailReport',true);  
                }
               /* else if(!responseWrap.showSiteDetailButton){//Manual update MahaK
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                            message: responseWrap.message,
                            duration:'5000',
                            key: 'info_alt',
                            type: 'error',
                            mode: 'dismissible'
                        });
                    toastEvent.fire();
                }*/
                component.set('v.Spinner', false);
            }
            else if (response.getState() == "ERROR"){
                console.log('ERROR RESPONSE '+response.getReturnValue().message);
                component.set('v.Spinner', false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
						message: $A.get("$Label.c.CWS_Site_Detail_Report_Error"),
                        duration:'5000',
						key: 'info_alt',
						type: 'error',
						mode: 'dismissible'
					});
				toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    getSiteDetailReportjs : function(component, event, helper) {
        component.set('v.Spinner', true);
		var initialhref=component.get('v.initialhref');
       
        //Code Added for OBD-154 by Mahak Bansal
        var action = component.get("c.getSiteDetailReport");
        action.setParams({
            'invoiceId': component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") { 
                var resp = response.getReturnValue();
                if(resp.isSuccess){
                    var hrefVal = initialhref+resp.body;
                    component.set('v.isFileAttached',true);
                    var mydiv = document.getElementById("myDiv");
                    var aTag = document.createElement('a');
                    aTag.setAttribute('href',hrefVal);
                    aTag.innerText = $A.get("$Label.c.CWS_Site_Detail_Report_Anchor");   
                    aTag.target="_blank";
                    //aTag.font= "3vh";
                    mydiv.appendChild(aTag);
                    component.set('v.Spinner', false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                            message: $A.get("$Label.c.CWS_Site_Detail_Success"),   
                            duration:' 5000',
                            key: 'info_alt',
                            type: 'success',
                            mode: 'dismissible'
                        });
                    toastEvent.fire();
                }
                else if(!resp.isSuccess)
                {
                   component.set('v.Spinner', false);
                   var toastEvent = $A.get("e.force:showToast");
                   toastEvent.setParams({
                           message: $A.get("$Label.c.CWS_Site_Detail_Comp_Fail"),  
                           duration:' 5000',
                           key: 'info_alt',
                           type: 'error',
                           mode: 'dismissible'
                       });
                   toastEvent.fire();
               }
                
            }
            else {
                component.set('v.Spinner', false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
						message: $A.get("$Label.c.CWS_Site_Detail_Report_Error"),  
						duration:' 5000',
						key: 'info_alt',
						type: 'error',
						mode: 'dismissible'
					});
				toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
	},
})