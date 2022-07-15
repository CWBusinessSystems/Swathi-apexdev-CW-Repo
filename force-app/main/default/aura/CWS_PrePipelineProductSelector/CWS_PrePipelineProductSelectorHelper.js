({
	sortData : function(component,attributeName,fieldName,fieldType,sortDirection){
        var data = component.get(attributeName);
        //function to return the value stored in the field
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        
        // to handel number/currency type fields 
        if(fieldType == 'Number'){ 
            data.sort(function(a,b){
                var a = key(a) ? key(a) : '';
                var b = key(b) ? key(b) : '';
                return reverse * ((a>b) - (b>a));
            }); 
        }
        else{// to handel text type fields 
            data.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                var b = key(b) ? key(b).toLowerCase() : '';
                return reverse * ((a>b) - (b>a));
            });    
        }
        //set sorted data to accountData attribute
        component.set(attributeName,data);
    },
    filterAvailable : function(component, event, helper){
        var opptyLines = component.get("v.opportunityLineItems");
        var pbeItems = component.get("v.pricebookEntries");
        
    
    
        var oli = [];
        
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
                          
                          });
            }
        }
        console.log('available products'+JSON.stringify(oli));
        var result = oli.filter(function(o1){
            return !opptyLines.some(function(o2){
                return o1.PricebookEntryId === o2.PricebookEntryId;
            });
        });
        console.log('result'+JSON.stringify(result));
        component.set("v.availableLineItems",result);
    },
    filterExcluded : function(component,event,helper){
        console.log('in filter excluded');
        var allExclusions = component.get("v.products");
        var availableProducts = component.get("v.availableLineItems");
        console.log('excluded products'+JSON.stringify(allExclusions));
        var opptyLines = component.get("v.opportunityLineItems");
        var updatedAvailableProducts = [];
        var result = allExclusions.filter(function(o1){
            return opptyLines.some(function(o2){
                return o1.Name === o2.ProductCode;
            });
        });
        console.log('filter excluded'+JSON.stringify(result));
        var resultLen = result.length;
        var excludedProducts = [];
        
       
        for(var i = 0; i < resultLen; i++){
            var substrings = result[i].CWS_Product_Exclusions__c.split(';');
        	
            console.log('substrings'+substrings.length);
            for(var z=0;z < substrings.length;z++){
                console.log('sub'+substrings[z]);
                excludedProducts.push(String(substrings[z]));
            }
            
        }
        console.log('excluded products'+excludedProducts);
        
        for (var y = 0; y < availableProducts.length; y++){
            if(excludedProducts.includes(availableProducts[y].ProductCode)){
                var updateLine = availableProducts[y];
                updateLine.disableInput = true;
                updatedAvailableProducts.push(updateLine);
                
            } else {
                updatedAvailableProducts.push(availableProducts[y]); 
            }
        }
        component.set("v.availableLineItems",updatedAvailableProducts);
    }
    
})