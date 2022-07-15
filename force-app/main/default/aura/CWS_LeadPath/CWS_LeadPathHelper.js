({
	changeStatus : function(component,stepName) {
        //Update status of lead
        var $this=this;
        component.set("v.leadRecord.Status",stepName);
        $this.callLDSSave(component,"recordSaver",false).then(
            $A.getCallback(function() {$A.get('e.force:refreshView').fire()}),
            $A.getCallback(function(result) {
				if(result.error){
					if (result.error[0] && result.error[0].message) {
                        $this.showErrorToast(result.error[0].message)
                    } else {
						$this.showErrorToast($A.get("$Label.c.CWS_SomethingWentWrong"));
					}
				}
				$A.get('e.force:refreshView').fire()
			})
        );
	},
	showModal : function(component,stepName,headerTxt,bodyTxt){
		var $this=this;
		this.callCreateCmp(component,'c:CWS_LeadPathModalFooter',
		{leadStatus:stepName,
		recordId:component.get("v.recordId")},true).then(
            $A.getCallback(function(content) {
				$this.showOverlayModal(component,headerTxt,bodyTxt,content,false);
			})
        );
	}
})