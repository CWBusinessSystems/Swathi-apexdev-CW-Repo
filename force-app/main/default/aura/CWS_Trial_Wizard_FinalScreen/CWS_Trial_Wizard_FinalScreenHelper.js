({
    openTrialRec : function(component) {
      // Get the record ID attribute
      var record = component.get("v.trialRecordId");
      this.redirectToSObject(record);
    }
})