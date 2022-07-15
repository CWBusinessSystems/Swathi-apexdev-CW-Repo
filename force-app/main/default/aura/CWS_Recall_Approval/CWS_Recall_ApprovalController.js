({
    handleRecordUpdated: function(component, event, helper){
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED"){
           var primary = component.get("v.simpleQuoteRecord.SBQQ__Primary__c");
           var isValidQuote = false;
           var quoteId = component.get("v.recordId");
            if (quoteId == null) {
                component.set("v.errorMessage",'Please submit a Quote.' ); 
            } else {
                 isValidQuote = true;
            }
                    
            if(isValidQuote){
                var action = component.get("c.recallApproval");
                action.setParams({
                    "quoteId" : quoteId
                });
                $A.enqueueAction(action);
                action.setCallback(this, function(result){

                    if(result.getState() === "SUCCESS"){
                                                
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }
                   
                 
                });
            }
           
    
        }
    }
})