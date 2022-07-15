({
    uploadHelper: function(component, event, helper) {
        var wrapList = component.get('v.minCommList');
        var minList = [];
        var $this = this;
        for(var i=0 ; i<wrapList.length ; i++ ){
            var list = wrapList[i].minCommObj;
            minList.push(wrapList[i].minCommObj);
        }
        
        if(!$A.util.isEmpty(minList)){
            this.callServer(component, "c.insertMinCommits", function(result) {
            if(result == 'success'){
                $this.closeAction();
                this.showSuccessToast($A.get("$Label.c.CWS_Records_Successfully_Inserted"));

            }else{
				this.showWarningToast($A.get("$Label.c.CWS_Duplicate_Month_Year_Found"));
            }
            },{
                "minCommList": minList,
            });
        }
     },
    
    validateminCommList : function(component, event) {
        var wrapList = [];
    	wrapList = component.get('v.minCommList');
        var isErrored = true;
        if(wrapList.length > 0){
            var patt = new RegExp('(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{2}');
            
            for(var i=0 ; i<wrapList.length ; i++){
                wrapList[i].helpText = '';
                wrapList[i].isError = false;
                var mmc = wrapList[i].minCommObj.CWS_Monthly_Minimum_Commit__c.trim();
                var my = wrapList[i].minCommObj.CWS_Month_Year__c.trim();
                
                if(mmc === ""){
                    isErrored = false;
                    wrapList[i].isError = true;
                    wrapList[i].helpText += $A.get("$Label.c.CWS_Monthly_Minimum_Commit_cannot_be_blank");
                }else if(isNaN(mmc)){
                    isErrored = false;
                    wrapList[i].isError = true;
                    wrapList[i].helpText += $A.get("$Label.c.CWS_Monthly_Minimum_Commit_need_to_b_anumber");
                }else{

                    wrapList[i].isError = false;
                }
                
                if(my === ""){
                    isErrored = false;
                    wrapList[i].isError = true;
                    wrapList[i].helpText += ('\n'+ $A.get("$Label.c.CWS_Month_Year_cannot_be_blank"));
                }else if(!patt.test(my)){
                    isErrored = false;
                    wrapList[i].isError = true;
                    wrapList[i].helpText += ('\n'+ $A.get("$Label.c.CWS_Month_Year_needs_to_be_in_proper_format"));
                }else{
                    if(my.length > 6){
                        isErrored = false;
                        wrapList[i].isError = true;
                        wrapList[i].helpText += ('\n'+ $A.get("$Label.c.CWS_Month_Year_needs_to_be_in_proper_format"));
                    }
                    if(!wrapList[i].isError){
                    	wrapList[i].isError = false;
                    }
                }
            }
            component.set("v.minCommList", wrapList);
            if(!isErrored){
                this.showWarningToast($A.get("$Label.c.CWS_Correct_the_data_and_submit"));
            }
        }else{
            isErrored = false;
            this.showWarningToast($A.get("$Label.c.CWS_No_CSV_records_present"));
        }
        return isErrored;
	},
    
    trhrowErr : function(component, event) {
        var err = component.get('v.isMaster');
    	if(!err){
        	this.closeAction();
            this.showWarningToast($A.get("$Label.c.CWS_Restriction_To_Min_Comm_Creation_on_Master"));
        }
    }
})