({
	closeModal : function(cmp, event, helper) {
        cmp.set("v.showModal",false);
		
	},
    
    handleSubmit : function(cmp, event, helper) {
        event.preventDefault();       // stop the form from submitting
        const fields = event.getParam('fields');
        cmp.find('minCommitRecordForm').submit(fields);
    }
})