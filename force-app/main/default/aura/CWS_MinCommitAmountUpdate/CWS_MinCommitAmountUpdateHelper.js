({
	trhrowErr : function(component, event) {
        var err = component.get('v.isMaster');
    	if(!err){
        	this.closeAction();
            this.showWarningToast($A.get("$Label.c.CWS_MinCommitupdateMaster"));
        }
    },
    submitHelper : function(component, event, helper){
        var $this = this;
        var oppId = component.get('v.oppID');
        if(!$A.util.isEmpty(oppId)){
        this.callServer(component, "c.updateMinCommitAmount", function(result) {
            if(result == 'success'){
                $this.closeAction();
                this.showSuccessToast($A.get("$Label.c.CWS_Records_Successfully_Updated"));

            }else if(result == 'MinCommitUnavailable'){
                this.showWarningToast($A.get("$Label.c.CWS_MinCommitRecordUpdate"));
                 $this.closeAction();
            }
            else{
				this.showWarningToast("An Error has occured while updating the records. Please contact your administrator");
            }
            },{
                "oppId": oppId,
            });
        
    }
    }
})