({
    handleRecordUpdated: function(component, event, helper){
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED"){
           var isValidQuoteDoc = false;
           var quoteDocumentId = component.get("v.recordId");
           var quoteStatus = component.get("v.simpleQuoteRecord.SBQQ__Quote__r.SBQQ__Status__c");
           var signatureStatus = component.get("v.simpleQuoteRecord.SBQQ__SignatureStatus__c");
          // var quoteDocumentId = component.get("v.recordId"); 
            if (quoteDocumentId == null) {
                component.set("v.errorMessage",'Please generate a Quote Document.' ); 
            } else if (quoteStatus != 'Awaiting Signature') {
                component.set("v.errorMessage",'Quote document can be voided only when quote is in Awaiting Signature Stage' ); 
            } else if (signatureStatus != 'Pending' && signatureStatus != 'Sent' && signatureStatus != 'Delivered' ) {
                component.set("v.errorMessage",'Only Sent OR pending Quote documents can be Voided' ); 
               // console.log('entered log 1');
            }
            else {
                 isValidQuoteDoc = true;
            }
                    
            if(isValidQuoteDoc){
                var action = component.get("c.voidQuoteDocument");
                action.setParams({
                    "qDocID" : quoteDocumentId
                });
                $A.enqueueAction(action);
                action.setCallback(this, function(result){

                    if(result.getState() === "SUCCESS"){
                                                
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }
                   
                 
                });
            }else{
                helper.createErrorToastComponent(component, event, helper);
                var spinner = component.find("spinner");
                $A.util.toggleClass(spinner, "slds-hide");
            }
           
    
        }
    }
})