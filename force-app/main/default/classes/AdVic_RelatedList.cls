/**
 * @description Controller for AdVic_RelatedList Aura Components.
*/
public with sharing class AdVic_RelatedList {
    /**
     * @param recordId The Id of the parent record for which child records are retrieved.
     * @param relObjType The API Name of the related child SObject.
     * @param parentLookupField The API name of the lookup field to the parent on the Child SObject.
     * @param addOnClause SOQL clause that comes after WHERE
     * @param sortField field by default to sort by. may not be enabled.
     * @param sortDirection default sort direction for the initial query dynamically created.
     *
     * @return a String object that summarizes a List<FieldData> and Rows that are SObjects.
     *
     * @description This queries both the records/rows and the fieldData/Columns for the records that will be displayed.
     * It is all encompassing; the query runs once, and the data returned is processed and filtered client-side.
     */
    // a longer parameter list is critical to this component's clear function and editing.
    @AuraEnabled
    public static String getListDataJSON(String recordId, String relObjType, String parentLookupField, String addOnClause,
                                        String sortField, String sortDirection) {

        CmpData cmpData = new CmpData();
        if(checkRequiredData(recordId, relObjType, parentLookupField) == false) {
            return null;
        }
        if(addOnClause == 'undefined' || addOnClause == null) {
            addOnClause = '';
        }

        cmpData.fieldDataList = getFieldDataList(relObjType);
        
        //AVS Note - we can plug in lots of stuff into Order By, so you may not need to change query here.
        //...no, we don't really use fields param, we just want Ids to feed data-service.
        String query = buildDynamicSObjectQuery(relObjType, parentLookupField, recordId, addOnClause, sortField, sortDirection);
        cmpData.records = Database.query(query);
        cmpData.displayByMdt = true;
        
//        String mdtQuery = 'SELECT Label FROM AdVicConfig__mdt LIMIT 1';
//        SObject mdt = Database.query(mdtQuery);
//        if(mdt != null) {
//            cmpData.displayByMdt = false; //aka show AdVic icon = false;
//        }



        return JSON.serialize(cmpData);
    }

    private static Boolean checkRequiredData(String recordId, String relObjType, String parentLookupField) {
        if(checkRecordId(recordId) && checkRelObjType(relObjType) && checkParentLookupField(parentLookupField)) {
            return true;
        }
        return false;
    }

    private static Boolean checkRecordId(String recordId) {
        if (recordId == '' || recordId == 'undefined' || recordId == null) {
            return false;
        }
        return true;
    }

    private static Boolean checkRelObjType(String relObjType) {
        if(relObjType == '' || relObjType == 'undefined' || relObjType == null) {
            return false;
        }
        return true;
    }

    private static Boolean checkParentLookupField(String parentLookupField) {
        if(parentLookupField == '' || parentLookupField == 'undefined' || parentLookupField == null) {
            return false;
        }
        return true;
    }

    // a longer parameter list is critical to this component's clear function and editing.
    private static String buildDynamicSObjectQuery(String relObjType, String parentLookupField, String recordId,
            String addOnClause, String sortField, String sortDirection) {
        String query = '';
        query += ' SELECT Id FROM ' + String.escapeSingleQuotes(relObjType) + ' ';
        query += ' WHERE ' + String.escapeSingleQuotes(parentLookupField) + ' = :recordId ';
        query += ' ' + addOnClause + ' ';
        query += ' ORDER BY ' + String.escapeSingleQuotes(sortField) + ' ' + String.escapeSingleQuotes(sortDirection);
        return query;
    }

    private static List<FieldData> getFieldDataList(String sObjectName){
		List<FieldData> fDataList = new List<FieldData>();
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(sObjectName).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values()){
            Schema.DescribeFieldResult dfield = sfield.getDescribe();
            FieldData fieldData = new FieldData();
            fieldData.name = dfield.getName();
            fieldData.label = dfield.getLabel();
            fieldData.dType = String.valueOf(dfield.getType());
            fDataList.add(fieldData);
        }
        return fDataList;
    }


    /**
     * @description This class is returned to the Aura Component and contains the SObjects and the FieldData/Columns
     * that will be displayed.
     */
    public class CmpData {
        @AuraEnabled
        public List<FieldData> fieldDataList;
        @AuraEnabled
        public List<SObject> records;
        @AuraEnabled
        public Boolean displayByMdt;
    }

    /**
     * @description An inner class which holds the data about the columns that will be displayed.
     * Used to compose CmpData class objects.
     */
    public class FieldData {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String dType;
    }

}