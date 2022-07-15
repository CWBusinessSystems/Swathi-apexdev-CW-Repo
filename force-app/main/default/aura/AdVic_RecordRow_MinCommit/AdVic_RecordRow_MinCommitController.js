({
    showModal : function(cmp,evt,hlp){
        cmp.set("v.showModal",true);
    },
    toggleConfirm : function(cmp,evt, hlp){
    	var showConfirm = cmp.get("v.showConfirm");
        if(showConfirm === true)
        	cmp.set("v.showConfirm",false); 
        else
            cmp.set("v.showConfirm",true);
    },
    
    handleRecordUpdated : function(cmp,evt,hlp){
      	console.log('handle updated'); 
        cmp.set("v.showConfirm", false);
    },
    
    deleteRecord : function(cmp,evt,hlp){
        //var id = cmp.get("v.rowRec.Id");
        //alert('delete '+ id);
        //cmp.set("v.showModal",true);
       hlp.helpDelete(cmp,evt, hlp);
    },
    clearSpinner: function(cmp,evt,hlp){
        cmp.set("v.loadStatus", 'loaded');
        console.log('loaded');
    },
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
    recSaved : function(cmp, event, helper){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been updated successfully.",
            "type":"success",
            "duration":5000,
            "type":"pester"
        });
        toastEvent.fire();
        cmp.set("v.rowStatus", "Saved");
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