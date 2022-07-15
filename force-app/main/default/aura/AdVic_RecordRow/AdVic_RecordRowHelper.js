({
	clearTimer : function(cmp) {
        let y = cmp.get("v.timerHandle");
        cmp.set("v.timerHandle", undefined);
        if(y){
            window.clearTimeout(y);
            console.log('discarded timer');
        }
	},
    helpDelete : function(cmp, evt, hlp){
        cmp.find("recordHandler").deleteRecord($A.getCallback(function(deleteResult) {
            // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
            // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
            if (deleteResult.state === "SUCCESS" || deleteResult.state === "DRAFT") {
                // record is deleted
                console.log("Record is deleted.");
                cmp.set("v.disableRow",true);
            } else if (deleteResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (deleteResult.state === "ERROR") {
                console.log('Problem deleting record, error: ' + JSON.stringify(deleteResult.error));
            } else {
                console.log('Unknown problem, state: ' + deleteResult.state + ', error: ' + JSON.stringify(deleteResult.error));
            }
        }));  
    },
    flagSubmit : function(cmp){
        var liveEditActive = cmp.get("v.liveEditActive");
        if(liveEditActive){
            cmp.set("v.rowStatus", "Saving");
        }
        cmp.set("v.rowStatus", "Pending");
    },
    
    doSave : function(cmp){
        //cmp.find("thisRow").save();
        cmp.find("thisRow").submit();
    }
})