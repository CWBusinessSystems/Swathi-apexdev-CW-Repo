({
	accHelper : function(component, event) {
        
        var profName = component.get('v.userRec.Profile.Name');
        var $this = this;
        var loginUserID = $A.get("$SObjectType.CurrentUser.Id");
        
        if(profName !== 'System Administrator' &&
          profName !== 'CWS_Global_Sales_Ops' && 
          profName !== 'CWS_Master_Data_Admin' &&
          profName !== 'CWS_Contract_Admin'){
            this.closeAction();
            this.showWarningToast($A.get("$Label.c.CWS_Not_Authorized"));
        }else{
            this.callServer(component, "c.identifyContext", function(result) {
                $this.closeAction();
                if(result === 'success'){
                    this.showSuccessToast($A.get("$Label.c.CWS_Share_Delete_In_Process"));
                }
                //location.reload();
                //this.refreshPage();
            },{
                "accID" : component.get('v.recordId'),
                "distyRec" : null,
                "context": 'Deactivate'
			});
        }
    }
})