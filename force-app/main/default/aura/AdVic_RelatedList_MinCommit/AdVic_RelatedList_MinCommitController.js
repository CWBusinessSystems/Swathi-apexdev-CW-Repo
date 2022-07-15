({
    
    init : function(cmp, event, helper){
        var manualRecordId = cmp.get("v.manualRecordId");
        if(manualRecordId != '' && manualRecordId != undefined){
            cmp.set("v.queryId", manualRecordId);
        }
        else{
            cmp.set("v.queryId", cmp.get("v.recordId"));
        }
        
        
        
        
        
        if(cmp.get("v.builderMode") == false){
            helper.initCall(cmp,event,helper,cmp.get("v.sortField"), cmp.get("v.sortDirection"));
            
            var csv = cmp.get("v.fieldsCSV");
            if(csv != undefined){
                cmp.set("v.fields", csv.split(','));
            }
            
            var csv2 = cmp.get("v.moreFieldsCSV");
            if(csv2 != undefined){
                cmp.set("v.moreFields", csv2.split(','));
            }
        }
        var rowCt = cmp.get("v.initRows");
        if(rowCt == 0 || rowCt == undefined){
            rowCt = 1;
        }
        
        cmp.set("v.maxRows", rowCt);
        
        
    },
    setSortBy : function(cmp, evt, hlp){
        cmp.set("v.showSpinner", true);

    	var clickedField = evt.getSource().get("v.value"); 
        var sortDirection = cmp.get("v.sortDirection");
        var sortField = cmp.get("v.sortField");
        
        if(clickedField == sortField){
            if(sortDirection == 'ASC'){
                cmp.set("v.sortDirection", 'DESC');
            }
            else{
                cmp.set("v.sortDirection", 'ASC');
            }
        }
        else{
            cmp.set("v.sortField", clickedField);
            cmp.set("v.sortDirection", 'ASC');
        }
        console.log('will sort '+ cmp.get("v.sortField") + ' '+ cmp.get("v.sortDirection"));
        //re-init here...
        hlp.initCall(cmp,evt,hlp,cmp.get("v.sortField"), cmp.get("v.sortDirection"));
    },
    showAll : function(cmp, evt, hlp){
        cmp.set("v.maxRows", 5000); //...soft limit, we just want to show everything that's brought back
        if(displayRows >= cmpData.length){
            cmp.set("v.showingAllRecs", true);
        }
    },
    showMore : function(cmp, evt, hlp){
        var initRows = cmp.get("v.initRows");
        var displayRows = cmp.get("v.maxRows");
        if(displayRows == undefined){
            displayRows = initRows;
            cmp.set("v.maxRows", displayRows);
        }
        
        
        displayRows = displayRows + initRows;
        
        cmp.set("v.maxRows", displayRows);
        
        var cmpData = cmp.get("v.cmpData");
        
        
        if(displayRows >= cmpData.length){
            cmp.set("v.showingAllRecs", true);
        }
        
    },
    
    
    showNewSection : function(cmp, evt, hlp){
        var showNewSection = cmp.get("v.showNewSection");
        if(showNewSection){
            cmp.set("v.showNewSection", false);
        }
        else{
            cmp.set("v.showNewSection", true);
        }
    },
    hideNewSection : function(cmp, evt, hlp){
        cmp.set("v.showNewSection", false);
    },
    
    doNothing : function(cmp, event, helper){
        event.preventDefault();
        console.log('pause');
        event.stopPropagation();
    },
    
    showSpinner : function(cmp, event, helper) {
        //cmp.set("v.showSpinner",true);    
    },
    
    handleSuccess : function(cmp, event, helper) {
        console.log('event: ', JSON.stringify(event));
        
        helper.initCall(cmp,event,helper, cmp.get("v.sortField"), cmp.get("v.sortDirection"));

        console.log('success!!!!!!!!');
        
        
        var payload = event.getParams();
        console.log(payload.id);
        
        $A.get('e.force:refreshView').fire();
        
        
        
        cmp.find('field').forEach(function(f) {
            f.reset();
            cmp.set("v.val_Create_New_Facility_Account__c", false);
        });
        
        
        
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been created successfully.",
            "duration": 2000
        });
        toastEvent.fire();
        
        
        cmp.set("v.showSpinner",false);
        
        
    },
    clearSpinner : function(cmp,evt,hlp){
    	cmp.set("v.showSpinner",false);    
    }
    
    
    
})