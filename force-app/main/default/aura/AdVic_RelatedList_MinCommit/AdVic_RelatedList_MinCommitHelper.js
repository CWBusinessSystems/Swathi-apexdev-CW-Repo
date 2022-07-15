({
	initCall : function(cmp,event,helper,sortFieldIn,sortDirectionIn) {
		cmp.set("v.showSpinner", true);
        var action = cmp.get("c.getListDataJSON");
        //String getListDataJSON(String recordId, String relObjType, String parentLookupField, List<String> fields)
        console.log('doing init, '+ sortFieldIn+'/'+sortDirectionIn);
        action.setParams({ 
            recordId : cmp.get("v.queryId"),
            relObjType : cmp.get("v.relObjType"),
            parentLookupField : cmp.get("v.parentLookupField"),
            orderByClause : cmp.get("v.orderByClause"),
            sortField : sortFieldIn,
            sortDirection : sortDirectionIn
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp = JSON.parse(response.getReturnValue());
                console.log(resp);
                cmp.set("v.showSpinner", state != "SUCCESS");
                cmp.set("v.cmpData", JSON.parse(response.getReturnValue()));
                cmp.set("v.overrideParams", resp.displayByMdt);
            }
        });
        $A.enqueueAction(action);
	}
})