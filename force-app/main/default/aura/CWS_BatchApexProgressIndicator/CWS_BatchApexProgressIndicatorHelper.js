({
    getBatchStatus : function (cmp){
        var refreshInterval = cmp.get("v.refreshInterval");
        var interval = setInterval($A.getCallback(function () {
            console.log('in refresh interval');
            var jobStatus = cmp.get("c.getBatchJobStatus");
            var batchJobId = cmp.get("v.inputJobId");
            if(jobStatus != null){
                jobStatus.setParams({ jobID : batchJobId});
                jobStatus.setCallback(this, function(jobStatusResponse){
                    var state = jobStatus.getState();
                    if (state === "SUCCESS"){
                        var job = jobStatusResponse.getReturnValue();
                        if(job.Status) cmp.set("v.batchStatus",job.Status);
                        console.log('Job Status'+job.Status);
                        
                        cmp.set('v.apexJob',job);
                        if(job.Status && job.Status === 'Completed'){
                            cmp.set("v.progress",100);
                            cmp.set("v.isComplete",true);
                            clearInterval(interval);
                            console.log("Completed");
                        }
                        
                        var progress = cmp.get('v.progress');
                        progress += 1;
                        cmp.set('v.progress', progress);
                    }
                });
                $A.enqueueAction(jobStatus);
            }
        }), refreshInterval);
    }
});