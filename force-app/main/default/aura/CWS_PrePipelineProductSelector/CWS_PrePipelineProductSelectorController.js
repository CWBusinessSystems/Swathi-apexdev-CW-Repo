({
	doInit: function(component, event, helper) {
        console.log('In doInit');
        var oli = [];
        var pbeItems = component.get("v.pricebookEntries");
        if(pbeItems){
            var pbeLen = pbeItems.length;
            for(var i = 0; i < pbeLen; i++){
                var pbe = pbeItems[i];
                
                oli.push({'sobjectType':'OpportunityLineItem'
                          ,'PricebookEntryId':pbe.Id
                          ,'Quantity': null
                          ,'UnitPrice':pbe.UnitPrice
                          ,'Product2Id': pbe.Product2Id
                          ,'CurrencyIsoCode': pbe.CurrencyIsoCode
                          ,'ProductCode': pbe.Name
                          ,'OpportunityId' : null
                          
                          });
            }
        }
        console.log('oli'+JSON.stringify(oli));
        component.set("v.availableLineItems",oli);
    },
    handleQuantityInput: function(component, event, helper){
        console.log('in handle input');
        var qtyInput = event.getSource().get("v.value");
        var indexNum = event.getSource().get("v.name");
        var oppty = component.get("v.opportunityRecord");
        var opptyItems = component.get("v.opportunityLineItems");
        var availableItems = component.get("v.availableLineItems");
        var selectedItem = availableItems[indexNum];
        if(oppty) selectedItem.OpportunityId = oppty.Id;
        // multiple monthly unit price by 12
        
        if(selectedItem.disableInput){
            selectedItem.UnitPrice = 0;
        } else {
            selectedItem.UnitPrice = selectedItem.UnitPrice * 12;
        }
        selectedItem.Quantity = qtyInput;
        
        //selectedItem.CWS_ACVLine__c = (qtyInput * selectedItem.UnitPrice)*12;
        console.log('selected item'+JSON.stringify(selectedItem));
        opptyItems.push(selectedItem);
        availableItems.splice(indexNum,1);
        component.set("v.opportunityLineItems",opptyItems);
        helper.filterExcluded(component,event,helper);
        //helper.sortData(component,"v.opportunityLineItems","ProductCode","Text","asc");
        component.set("v.availableLineItems",availableItems);
    },
    handleRemoveLine: function(component, event, helper){
        console.log('in Line Remove');
        var indexNum = event.getSource().get("v.name");
        var opptyItems = component.get("v.opportunityLineItems");
        opptyItems.splice(indexNum,1);
        component.set("v.opportunityLineItems",opptyItems);
        helper.filterAvailable(component,event,helper);
        helper.filterExcluded(component,event,helper);
        
    }
})