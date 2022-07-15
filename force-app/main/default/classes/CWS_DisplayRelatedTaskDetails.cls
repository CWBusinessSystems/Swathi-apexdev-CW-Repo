/**
 * @description       : 
 * @author            : DPC Advictoriam Solutions
 * @group             : 
 * @last modified on  : 06-18-2021
 * @last modified by  : DPC Advictoriam Solutions
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   06-18-2021   DPC Advictoriam Solutions   Initial Version
**/
public With Sharing class CWS_DisplayRelatedTaskDetails {
    @AuraEnabled
    public static List<task> taskList ( String originalTaskId, String excludeId) {
        system.debug('excluded ID'+excludeId);
        if(OriginalTaskId != null){
            return [SELECT Id, Subject, Status, Description, ActivityDate, Who.Name, WhoId, Priority,OwnerId,Owner.Name,WhatId,What.Name FROM Task where (CWS_Original_Activity_ID__c = :OriginalTaskId or Id = :originalTaskId) and Id != :excludeId order by activityDate desc]; 
        }
        return null;
    }
    
}