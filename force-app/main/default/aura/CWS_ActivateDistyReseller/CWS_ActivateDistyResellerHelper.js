({
	distyHelper : function(component, event) {
        
        var profName = component.get('v.userRec.Profile.Name');
        var $this = this;
        var loginUserID = $A.get("$SObjectType.CurrentUser.Id");
        
        if(profName !== 'System Administrator' &&
          profName !== 'CWS_Global_Sales_Ops' && 
          profName !== 'CWS_Master_Data_Admin' &&
          profName !== 'CWS_Contract_Admin'  && 
          profName !== 'CWS_Sales_Rep' && 
          profName !== 'CWS_Sales_Manager'){
            this.closeAction();
            this.showWarningToast($A.get("$Label.c.CWS_Not_Authorized"));
        }else if(component.get('v.disty.CWS_Distributor_ResellerAcc__c') != component.get('v.disty.CWS_Account__r.CWS_Established_Disti_Reseller__c')
                && !$A.util.isEmpty(component.get('v.disty.CWS_Account__r.CWS_Established_Disti_Reseller__c'))){
            this.closeAction();
            this.showWarningToast($A.get("$Label.c.CWS_ActiveDistyValidation"));
		}else if(!component.get('v.disty.CWS_Active__c')){
            this.callServer(component, "c.identifyContext", function(result) {
                $this.closeAction();
                if(result === 'success'){
                    this.showSuccessToast($A.get("$Label.c.CWS_Share_Delete_In_Process"));
                }
            },{
                "distyRec" : component.get('v.disty'),
                "context": 'Activate'
			});
        }else{
            this.closeAction();
            this.showWarningToast($A.get("$Label.c.CWS_Records_Already_Shared"));
        }
    }
})