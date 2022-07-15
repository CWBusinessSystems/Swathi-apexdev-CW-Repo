({
    handleCancel : function(component,event,helper) {
        helper.closeModal(component);
    },
    handleOK : function(component, event, helper) {
        helper.changeStatus(component);
    }
})