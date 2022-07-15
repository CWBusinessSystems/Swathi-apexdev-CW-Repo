({
    getTaskList : function(component, event, helper) {
        var action = component.get("c.taskList");
        var activityId = component.get("v.originalActivityId");
        var taskId = component.get("v.excludeTaskId");
        console.log('excluded Id'+taskId);
        console.log('activity id'+activityId);
        action.setParams({originalTaskId : activityId, excludeId: taskId});
        console.log('in get task list');
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            console.log('state'+state);
            if (state === "SUCCESS") {
               console.log('tasks '+JSON.stringify(response.getReturnValue()));
               component.set("v.taskList",response.getReturnValue());
            }
            
        });
        $A.enqueueAction(action);
    }
})