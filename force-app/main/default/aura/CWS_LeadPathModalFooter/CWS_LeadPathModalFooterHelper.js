({
    changeStatus : function(component) {
        //Update status of lead
        var $this=this;
        var status = component.get("v.leadStatus");
        component.set("v.leadRecord.Status",status);
        $this.callLDSSave(component,"recordSaver",false).then(
            $A.getCallback(function() {$this.closeModal(component)}),
            $A.getCallback(function(result) {
				if(result.error){
					if (result.error[0] && result.error[0].message) {
                        $this.showErrorToast(result.error[0].message)
                    } else {
						$this.showErrorToast($A.get("$Label.c.CWS_SomethingWentWrong"));
					}
				}
				$this.closeModal(component)
			})
        );
    },
    closeModal: function(component){
        $A.get('e.force:refreshView').fire();
        this.closeOverlayModal(component);
    }
})