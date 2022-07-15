({
	clearTimer : function(cmp) {
        let y = cmp.get("v.timerHandle");
        cmp.set("v.timerHandle", undefined);
        if(y){
            window.clearTimeout(y);
            console.log('discarded timer');
        }
        
		
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