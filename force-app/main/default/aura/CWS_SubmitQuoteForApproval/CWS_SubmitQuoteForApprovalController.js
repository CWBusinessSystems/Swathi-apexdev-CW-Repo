({
    initHandler: function (component, event, helper) {
        //Calling the Helper method for the Contract Admin/Global Sales Ops Access
        helper.refreshPriceOnQuotes(component, event, helper);
    },
    handleRecordUpdated: function(component, event, helper){
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED"){
            var QId = component.get('v.recordId');
			var imgTag = '<img width="3%" src="'+$A.get('$Resource.sbaa__SLDS214') + '/assets/icons/standard/unmatched_60.png'+'"/>'; 
            var action = component.get("c.validateQuoteOnSubmittingForApproval");
            var quoteType = component.get("v.simpleQuoteRecord.CWS_Quote_Type__c");
			 var transReason = component.get("v.simpleQuoteRecord.CWS_Transaction_Reason__c");
            //Setting the Parameter for the Action
            action.setParams({ QuoteId: QId });
            action.setCallback(this, function (response) {
                var state = response.getState();
                console.log('validateQuoteOnSubmittingForApproval state -  ' + state);
                if (state === "SUCCESS") {
                   debugger;
                    var quoteErrorMap = response.getReturnValue();
                  //  component.set("v.hasErrorMsg", hasErrorMsg);
                    console.log('validateQuoteOnSubmittingForApproval state -  ' + state);

                    var warning = $A.get("$Label.c.CWS_Warning");
                    var quoteErrorMessagesList = []; 
                    var quoteAlertMessageList=[];
                    if (quoteErrorMap !== null && quoteErrorMap !== '' ) {
                        for( var quoteErrMsgKey in quoteErrorMap){
                            var quoteErrMsg = quoteErrorMap[quoteErrMsgKey];
                            if(quoteErrMsg !== null &&  quoteErrMsg !== '' && quoteErrMsg.length > 0 ){
                                if(quoteErrMsgKey !== null && quoteErrMsgKey !== '' &&  quoteErrMsgKey.startsWith( warning )){
                                    quoteAlertMessageList.push(quoteErrMsg);
                                } else {
                                    quoteErrorMessagesList.push(imgTag+quoteErrMsg);
                                }
                            }
                        }
                     //   quoteErrorMessagesList.add = $A.get("$Label.c.CWS_UI_RefreshPriceErrorMsg");
                    }
                    console.log( 'quoteErrorMessagesList : '+ quoteErrorMessagesList);
           var primary = component.get("v.simpleQuoteRecord.SBQQ__Primary__c");
           var isValidQuote = false;
           //Added validation for USBed-3741
           // Starting BED-3741
           var billToAccount = component.get("v.simpleQuoteRecord.CWS_Bill_To_Account__c");
           var billtoContact = component.get("v.simpleQuoteRecord.CWS_Bill_To_Contact__c");
           var shipToAccount = component.get("v.simpleQuoteRecord.CWS_Ship_To_Account__c");
           
		   //BED-4970
		   //var shiptoContact = component.get("v.simpleQuoteRecord.CWS_Ship_To_Contact__c");
           //BED-4970
		   
		   var soldToAccount = component.get("v.simpleQuoteRecord.SBQQ__Account__c");
           var soldtoContact = component.get("v.simpleQuoteRecord.SBQQ__PrimaryContact__c");
           var legalEntity = component.get("v.simpleQuoteRecord.CWS_Legal_Entity__c");
           var opportunity = component.get("v.simpleQuoteRecord.SBQQ__Opportunity2__c");
           var paymentTerms = component.get("v.simpleQuoteRecord.SBQQ__PaymentTerms__c");
           var renewalType = component.get("v.simpleQuoteRecord.CWS_Renewal_Type__c");
           var acvQuote = component.get("v.simpleQuoteRecord.CWS_Quote_ACV__c"); 
           var lineItemCount = component.get("v.simpleQuoteRecord.SBQQ__LineItemCount__c"); 
           
           
           var staticLable2 = $A.get("$Label.c.CWS_Promotion_ACV_Error");
           var staticLable3 = $A.get("$Label.c.CWS_Add_Products_before_submiting_quote_for_approval"); 
            var staticLable4 = $A.get("$Label.c.CWS_Transaction_Reason_Population");
           var acvPromo = component.get("v.simpleQuoteRecord.CWS_Promotion__r.CWS_ACV__c"); 
           var transactionReason = component.get("v.simpleQuoteRecord.CWS_Transaction_Reason__c");
           var resellerAccount = component.get("v.simpleQuoteRecord.CWS_Reseller_Account__c");
            var RTM = component.get("v.simpleQuoteRecord.CWS_Route_to_Market__c");
            var billtoDisti = component.get("v.simpleQuoteRecord.CWS_2_Tier_Authorized_Reseller__c");
           var quoteId = component.get("v.recordId");
           var staticLable5 = $A.get("$Label.c.CWS_Reseller_Account_Blank");
		   var populatePrimarysoldtoContact = $A.get("$Label.c.CWS_populate_primary_sol_to_contact");
           //BED-3204
           var addendumNo =  component.get("v.simpleQuoteRecord.CWS_Addendum_Number__c");
           var masterQuote = component.get("v.simpleQuoteRecord.CWS_Master__c");
           var typeQuote = component.get("v.simpleQuoteRecord.CWS_Quote_Type__c");
           //BED-12610
           var isSourceBy = component.get("v.simpleQuoteRecord.SBQQ__Opportunity2__r.CWS_Source_By__c");
           var sourceByError = $A.get("$Label.c.CWS_SourceBy_Error");
           //BED-3204
           var reqFields = [];
           var msgList = [];
            if (!billToAccount)
            {
                reqFields.push(imgTag+'Bill To Account');
            }
             
             if (!billtoContact)
            {   
                reqFields.push(imgTag+'Bill To Contact');
            }
            
            if (!shipToAccount)
            {
                reqFields.push(imgTag+'Ship To Account');
            }
            
			//BED-4970
			/*
            if (!shiptoContact)
            {
                reqFields.push(imgTag+'Ship To Contact');
            }
			*/
			//BED-4970
            
            if (!soldToAccount)
            {
                reqFields.push(imgTag+'Sold To Account');
            }
            
            if (!soldtoContact)
            {
                reqFields.push(imgTag+'Sold To Contact');
            }
             
            if (!legalEntity)
            {
                reqFields.push(imgTag+'Legal Entity');
            }
            
            if (!paymentTerms)
            {
                reqFields.push(imgTag+'Payment Terms');
            }
            
            //BED-3204       
            if (addendumNo == null && masterQuote== true && typeQuote == 'Amendment')
            {
                reqFields.push(imgTag+'Addendum Number');
            }
			
		   //BED- 12710        
            var isprimarySoldTOContact = component.get("v.simpleQuoteRecord.SBQQ__PrimaryContact__r.CWS_Primary_Contact__c");
            var isprimaryBillingSoldTOContact = component.get("v.simpleQuoteRecord.SBQQ__PrimaryContact__r.CWS_Primary_Billing_Contact__c");
           //BED- 12710
		   
            //BED-3204
            //RENEWALCAT_CHANGE_REQ - commenting this out as deactivating Opt-In/Opt-Out value
            /*if (!renewalType)
            {   
                reqFields.push(imgTag+'Renewal Type');
            }*/
            
            
             if (acvPromo != null && acvPromo > acvQuote) {
                msgList.push(imgTag+staticLable2);
            }

            if (lineItemCount == '0') {
                msgList.push(imgTag+staticLable3);
            }
            
            if (transactionReason == null){
                msgList.push(imgTag+staticLable4);
            }
                   // if (priceRefreshErrorMessage) {
                    //    msgList.push(priceRefreshErrorMessage);
                   // }
            //BED-12610 BED 13049
            if ((quoteType == 'New Business' || (quoteType=='Amendment' && transReason !='Termination')) && $A.util.isEmpty(isSourceBy)){
                msgList.push(imgTag+sourceByError);
            }
            if(quoteErrorMessagesList.length > 0){
                msgList =  msgList.concat(quoteErrorMessagesList);
            }
            if(billToAccount !=null && billtoDisti && !resellerAccount & RTM == 'IIT'){
                msgList.push(imgTag+staticLable5); 
            }
			
            //BED-12710        
			//if(soldtoContact !=null && isprimarySoldTOContact != true  && isprimaryBillingSoldTOContact != true){
                //msgList.push(imgTag+populatePrimarysoldtoContact); 
            //}
			//BED-12710              

             // Ending BED-3741  
                    console.log('msgList.length - ' + msgList.length);
             if(msgList.length == 0 && reqFields.length == 0){
                isValidQuote =true;
                
             }  else {
                var finalMsg = (reqFields.length > 0) ? 'Required Fields are missing: <br>'+reqFields.join('<br>')+'<br><br> ' :'';
                finalMsg += (msgList.length > 0) ? 'Fix the below errors before submitting for approval: <br>'+msgList.join('<br>') : '';
                component.set("v.errorMessage", finalMsg);
             } 

            if(isValidQuote){
                // helper.createErrorToastComponent(component, event, helper);
                //  var spinner = component.find("spinner");
        		//$A.util.toggleClass(spinner, "slds-hide"); 
                 component.set("v.displayError", false);
                 component.set("v.isOpen", true);
                if(quoteAlertMessageList.length > 0 ){
                    component.set("v.lstAlertMessage", quoteAlertMessageList);
                }
              
            }else{
                helper.createErrorToastComponent(component, event, helper);
                var spinner = component.find("spinner");
                $A.util.toggleClass(spinner, "slds-hide");
            }
           
                }
                else if (state == "ERROR") {
					helper.createErrorToastComponent(component, event, helper);
                    var errors = response.getError();
                    console.log(errors[0].message);
                    console.log(errors[0]);
                    component.set("v.displayError", true);
                    component.set("v.errorMessage", errors[0].message);
					var spinner = component.find("spinner");
					$A.util.toggleClass(spinner, "slds-hide");	
                }
            });
            $A.enqueueAction(action);   
        }
    },
	closeModel: function(component, event, helper) {
      			 component.set("v.isOpen", false);
                $A.get("e.force:closeQuickAction").fire()
	           },
 
   submit: function(component, event, helper) {
        var quoteId = component.get("v.recordId");
       component.set("v.displayError", true);
                 component.set("v.isOpen", false);
       var action = component.get("c.submitForApproval");
                 action.setParams({
                    "quoteId" : quoteId
                });
               $A.enqueueAction(action);
               action.setCallback(this, function(result){
 			     if(result.getState() === "SUCCESS"){                    
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                 }
                    else if(result.getState() === "ERROR"){
                        console.log('Callback Error');
                        var errors = result.getError();
                        if(errors[0] && errors[0].message){
                            console.log(errors);
                            component.set("v.errorMessage", errors[0].message);
                            helper.createErrorToastComponent(component, event, helper);
                            var spinner = component.find("spinner");
        					$A.util.toggleClass(spinner, "slds-hide");
                        }
                    }
                    else{
                        console.log('Unexpected error!');
                        component.set("v.errorMessage", 'Unexpected error occurred while submitting for Approval');
                       }
                });
   }
})