({
    menuSelect :function(cmp, event, helper){
   		cmp.set("v.showModal", true);     
    },
    toggleMoreFields : function(cmp, event, helper){
        var showMore = cmp.get("v.showMore");
        if(showMore){
        	cmp.set("v.showMore",false);	    
        }
        else{
            cmp.set("v.showMore",true);
        }
    },
    flagSubmit : function(cmp,event,helper){
        helper.clearTimer(cmp);
        helper.flagSubmit(cmp);
        helper.doSave(cmp);
    },
    onSearchKeyChange : function(cmp, event, helper) {
        var debounceTimer = cmp.get("v.debounce");
        if(debounceTimer == undefined){
            debounceTimer == 3000;
        }
        
        
        var liveEditActive = cmp.get("v.liveEditActive");
        if(liveEditActive){
            cmp.set("v.rowStatus", "Saving");
            helper.clearTimer(cmp);
            
            let timerHandle = window.setTimeout(
                $A.getCallback(function() {
                    cmp.set("v.saveTest", true);
                    console.log('timer expired, save this record!');
                    helper.flagSubmit(cmp);
                    helper.doSave(cmp);
                }), debounceTimer //5000
            );
            
            console.log(timerHandle);
            cmp.set("v.timerHandle", timerHandle);
        }
        helper.flagSubmit(cmp);
    }
})