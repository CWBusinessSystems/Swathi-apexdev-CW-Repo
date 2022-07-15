trigger DescartesDPSLeadTrigger on Lead (after insert, after update) {List<String> Ids = new List<String>();descartesdps__DPSAppSettings__c oSettings = descartesdps__DPSAppSettings__c.getAll().get('DPSDefaultAppSettings');if(oSettings != null && oSettings.descartesdps__StdUpdateTriggersEnabled__c == true && trigger.isUpdate){for(Lead a: Trigger.new){Ids.add(a.Id);}if (Ids != null && Ids.size() > 0 && descartesdps.DescartesDPSTriggerManager.ProceedWithScreening(Ids.get(0), Trigger.oldMap, Trigger.newMap))descartesdps.DescartesDPSTriggerManager.triggerOnDemandSearchDPS(Ids.get(0));}else if(oSettings != null && oSettings.descartesdps__StdInsertTriggersEnabled__c == true && trigger.isInsert){for(Lead a: Trigger.new){Ids.add(a.Id);}if (Ids != null && Ids.size() > 0 && descartesdps.DescartesDPSTriggerManager.ProceedWithScreening(Ids.get(0), null, Trigger.newMap))descartesdps.DescartesDPSTriggerManager.triggerOnDemandSearchDPS(Ids.get(0));}else{ System.debug('Screening skipped. To screen, enable insert/update trigger for this object.'); }  }