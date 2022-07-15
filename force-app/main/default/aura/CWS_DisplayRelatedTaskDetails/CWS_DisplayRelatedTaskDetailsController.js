({
    
    doInit : function(component, event, helper) {
        console.log('in doInit');
        helper.getTaskList(component, event, helper);
    },
    displayPopup : function(component, event, helper) {
        var listValues = event.currentTarget.id;
        document.getElementById(listValues+'task').style.display="";
    },
    hidePopup : function(component, event, helper) {
        var listValues = event.currentTarget.id;
        document.getElementById(listValues+"task").style.display="none";
    }
})