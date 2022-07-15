({
    prepareMap : function(component,event) {
        var currentStage = component.get("v.quote.SBQQ__Status__c");
        var stages = component.get("v.stages");
        var stageMap = [];
        var completed = true;
        if(currentStage != null){
            for (var index = 0; index < stages.length; index++) {
                if(stages[index].includes(currentStage)){
                    stageMap.push({'name':stages[index],'css':'slds-is-current slds-is-active'});
                    completed = false;
                } else if(completed){
                    stageMap.push({'name':stages[index],'css':'slds-is-complete'});
                } else {
                    stageMap.push({'name':stages[index],'css':'slds-is-incomplete'});
                }
            }
        }
        component.set("v.stageMap",stageMap);

    }
})