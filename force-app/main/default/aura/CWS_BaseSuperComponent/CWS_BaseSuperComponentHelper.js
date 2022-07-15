({
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method handles server calls
    * @param component --> reference for the component from which this method is called
    * @param method (String) --> method name which needs to be called
    * @param callback(function) --> function to be called when server call completes
    * @param params(JSON) --> parameters to be passed to the server call
    * @param cacheable(boolean) --> boolean to set cacheable call
    * @param background(boolean) --> boolean to set background call
    */
    callServer : function(component, method, callback, params, cacheable, background) {
        try {
            var action = component.get(method);
            var baseComp = component.getSuper();
            this.toggleSpinner(baseComp);
            if (params) {
                action.setParams(params);
            }
            if(background){
                //console.log("In background");
                action.setBackground();
            }
            if (cacheable) {
                action.setStorable();
            }
            
            action.setCallback(this,function(response) {
                var state = response.getState();
                var lightningServerResponse = response.getReturnValue();
                this.toggleSpinner(baseComp);
                if(state === "SUCCESS"){ 
                    callback.call(this, lightningServerResponse);
                }else{
                    this.consoleLog("Error calling the server",true,response.getError());
                    this.showErrorToast($A.get("$Label.c.CWS_SomethingWentWrong"));
                }
            });
            $A.enqueueAction(action);
        } catch(e) {
            this.consoleLog(e.stack, true);
        }
    },
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method to open ovelay modal
    * @param component --> reference for the component from which this method is called
    * @param headerCnt (string|component) --> header content, text or component to be displayed in modal
    * @param bodyCnt (string|component) --> body content, text or component to be displayed in modal
    * @param footerCnt (string|component) --> footer content, text or component to be displayed in modal
    * @param showButton (boolean) --> to show close button on modal
    */
    showOverlayModal : function(component, headerCnt, bodyCnt, footerCnt,showButton) {
        if($A.util.isUndefined(showButton)||$A.util.isEmpty(showButton)){
            showButton=true; 
        }
        component.getSuper().find('overlayLib').showCustomModal({
            header: headerCnt,
            body: bodyCnt,
            footer:footerCnt,
            showCloseButton: showButton
        });
    },
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method to close overlay modal 
    * @param component --> reference for the component from which this method is called
    */
    closeOverlayModal : function(component) {
        component.getSuper().find("overlayLib").notifyClose();  
    },
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method to save record using Lightning data service
    * @param component --> reference for the component from which this method is called
    * @param recordAuraId (string) --> Aura id of force record data
    * @param showError (boolean) --> pass true to show generic error and false to handle error in calling component
    */
    callLDSSave : function(component, recordAuraId, showError) {
        try{
            var baseComp = component.getSuper();
            var $this = this;
            $this.toggleSpinner(baseComp);
            return new Promise($A.getCallback(function(resolve, reject) {
                component.find(recordAuraId).saveRecord($A.getCallback(function(saveResult) {
                    $this.toggleSpinner(baseComp);
                    if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                        resolve(saveResult);
                    } else{
                        $this.consoleLog("Error saving record",true,saveResult.error);
                        if($A.util.isUndefined(showError)||$A.util.isEmpty(showError)||showError){
                            $this.showErrorToast($A.get("$Label.c.CWS_SomethingWentWrong"));
                        }
                        reject(saveResult);
                    }
                }));
            }));
        } catch(e) {
            this.consoleLog(e.stack, true);
        }
    },
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method to create component dynamically
    * @param cmpName (string) --> component name to create
    * @param showError (boolean) --> pass true to show generic error and false to handle error in calling component
    */
    callCreateCmp : function(component,cmpName,params,showError) {
        try{
            var baseComp = component.getSuper();
            var $this = this;
            $this.toggleSpinner(baseComp);
            return new Promise($A.getCallback(function(resolve, reject) {
                $this.toggleSpinner(baseComp);
                $A.createComponent(cmpName,params,function(content, status, errorMessage) {
                    if (status === "SUCCESS") {
                        resolve(content);
                    } else{
                        $this.consoleLog("Error saving record",true,errorMessage);
                        if($A.util.isUndefined(showError)||$A.util.isEmpty(showError)||showError){
                            $this.showErrorToast($A.get("$Label.c.CWS_SomethingWentWrong"));
                        }
                        reject(errorMessage);
                    }
                });
            }));   
        }catch(e) {
            this.consoleLog(e.stack, true);
        }
    },
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method to create component dynamically
    * @param arrCmp (array) --> array of component to create dynamically or nested components data
    * @param showError (boolean) --> pass true to show generic error and false to handle error in calling component
    */
    callCreateNesCmp : function(component,arrCmp,showError) {
        try{
            var baseComp = component.getSuper();
            var $this = this;
            $this.toggleSpinner(baseComp);
            return new Promise($A.getCallback(function(resolve, reject) {
                $A.createComponent(arrCmp,function(components, status, errorMessage) {
                    $this.toggleSpinner(baseComp);
                    if (status === "SUCCESS") {
                        resolve(components);
                    } else{
                        $this.consoleLog("Error saving record",true,errorMessage);
                        if($A.util.isUndefined(showError)||$A.util.isEmpty(showError)||showError){
                            $this.showErrorToast($A.get("$Label.c.CWS_SomethingWentWrong"));
                        }
                        reject(errorMessage);
                    }
                });
            }));   
        }catch(e) {
            this.consoleLog(e.stack, true);
        }
    },
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method shows an error toast of the message passed
    * @param message (string) --> message to be displayed
    * @param error (boolean) --> parameter to be set only for error messages primarily from catch blocks 
    * @param objGeneric(Object) --> Parameter to be set only if an object needs to be printed in the console
    */
    consoleLog: function(message, error, objGeneric){
        try {
            var sCallStack = "";//storing call stack
            try {   throw new Error();  }   catch(e)    {   sCallStack = String(e.stack);   }
            var originalLine = sCallStack.split("\n")[2].trim();
            var sConsoleLog = $A.get("$Label.c.CWS_UI_ConsoleLogger");
            var sShowError = sConsoleLog.split("|")[0];
            var sShowMessage = sConsoleLog.split("|")[1];
            if(objGeneric)
                objGeneric = JSON.stringify(objGeneric);
            if(error && sShowError === "Yes")   {
                if(objGeneric)
                    console.error(message,objGeneric);
                else
                    console.error(message);
                
            }
            else if(sShowMessage === "Yes") {
                if (((Array.isArray(message) && typeof(message[0]) === "object")) && (console.table !== undefined)) {
                    console.table(message);
                } else if(objGeneric){
                    console.debug(message,objGeneric);
                } else {
                    console.debug(message);
                }
                
                console.debug(originalLine);
            }
            
        } catch(e) {
            console.error(e.stack);
        }
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method shows an error toast of the message passed
    * @param strMessage (string) --> message to be shown
    * @param strMode (string) --> mode for toast
    * @param intDuration (number) --> duration
    */
    showErrorToast : function(strMessage, strMode, intDuration) {
        if($A.util.isEmpty(strMode))
            strMode = 'sticky';//by default sticky
        if($A.util.isEmpty(intDuration))
            intDuration = 200;
        this.showToast('Error', strMessage, 'error', strMode, intDuration);
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method shows a success toast of the message passed, by default sticky
    * @param strMessage (string) --> message to be shown
    * @param strMode (string) --> mode for toast
    * @param intDuration (number) --> duration
    */
    showSuccessToast : function(strMessage, strMode, intDuration) {
        if($A.util.isEmpty(strMode))
            strMode = 'sticky';
        if($A.util.isEmpty(intDuration))
            intDuration = 200;
        this.showToast('Success', strMessage, 'success', strMode, intDuration);
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method shows a Warning toast of the message passed, by default sticky
    * @param strMessage (string) --> message to be shown
    * @param strMode (string) --> mode for toast
    * @param intDuration (number) --> duration
    */
    showWarningToast : function(strMessage, strMode, intDuration) {
        if($A.util.isEmpty(strMode))
            strMode = 'sticky';
        if($A.util.isEmpty(intDuration))
            intDuration = 200;
        this.showToast('Warning', strMessage, 'warning', strMode, intDuration);
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method shows a info toast of the message passed, by default sticky
    * @param strMessage (string) --> message to be shown
    * @param strMode (string) --> mode for toast
    * @param intDuration (number) --> duration
    */
    showInfoToast : function(strMessage, strMode, intDuration) {
        if($A.util.isEmpty(strMode))
            strMode = 'sticky';
        if($A.util.isEmpty(intDuration))
            intDuration = 200;
        this.showToast('Info', strMessage, 'info', strMode, intDuration);
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  shows the lightning toast
    * Documentation for toast below
    * https://developer.salesforce.com/docs/component-library/bundle/force:showToast/documentation
    * @param strTitle (string) --> Title to be shown
    * @param strMessage (string) --> message to be shown
    * @param strType (string) --> type of toast to be shown
    * @param strMode (string) --> mode for toast
    * @param intDuration (number) --> duration
    */
    showToast : function(strTitle, strMessage, strType, strMode, intDuration) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : strTitle,
            message : strMessage,
            duration : intDuration,
            mode: strMode,
            type: strType
        });
        toastEvent.fire();
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  toggle the spinner
    * 
    */
    toggleSpinner : function(component){
        component.set("v.isSpinnerActive",!component.get("v.isSpinnerActive"));
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  redirect to a url
    * @param strRedirectURL (string) --> redirection url
    */
    redirectToPageURL : function(strRedirectURL){
        //redirects to the page URL based on URL passed
        this.consoleLog("redirectToPageURL: " + strRedirectURL);
        var strURL = decodeURIComponent(strRedirectURL);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": strURL
        });
        urlEvent.fire();
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  redirect to a record detail
    * @param sRecordId (string) --> record Id
    */
    redirectToSObject : function(sRecordId){
        //redirects to the record
        this.consoleLog("sRecordId: " + sRecordId);
        var navEvt = $A.get("e.force:navigateToSObject");
	    navEvt.setParams({
	    	"recordId": sRecordId
	    });
	    navEvt.fire();
    },
    
    /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  sort the JSON list based on field, sort direction and a parser
    * @param strField (string) --> Field to be sorted
    * eg: arrayVariable.sort(this.sortBy("FieldName"));
    */
    sortBy : function(prop) {
        return function(a, b) {  
            if (a[prop] > b[prop]) {  
                return 1;  
            } else if (a[prop] < b[prop]) {  
                return -1;  
            }  
            return 0;  
        }  
    },
   /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Method Closes the quick Action 
    * @param No Parameters
    */
    closeAction : function() { 
        var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
        dismissActionPanel.fire(); 
    },
    
       /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Refreshes the back ground page
    * @param No Parameters
    */
    refreshPage : function() { 
        $A.get('e.force:refreshView').fire();
    },
    
     /*
    * @author Sudhir Moturu
    * @date   13-MAY-2020
    * @description  Fetch the Parameter value from a Page Url 
    * @param pageUrl (string) --> Page Url that contains attributes
    * @param paramName (String) --> Attribute to be extracted
    * @param No Parameters
    */
    getUrlParameterValue : function(paramName, pageUrl) {
    	if($A.util.isEmpty(pageUrl)){
    		pageUrl= window.location.href;
    	}
    	console.log('pageUrl-->'+pageUrl);
    	paramName = paramName.replace(/[\[\]]/g, "\\$&");
    	var regex = new RegExp("[?&]" + paramName + "(=([^&#]*)|&|#|$)");
    	var results = regex.exec(pageUrl);
    	if (!results) return null;
    	if (!results[2]) return '';
    	return decodeURIComponent(results[2].replace(/\+/g, " "));
    }
})