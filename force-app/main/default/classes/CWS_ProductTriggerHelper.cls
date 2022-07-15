/*Class Name: CWS_ProductTriggerHelper
*Created By: Ankit
*Created On: 08/18/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Ankit                 08/18/2020      Initial version     Default Precision Measure based on UOM
*/
public class CWS_ProductTriggerHelper 
{
    public static void beforeInserUpdate(list<SObject> newItems,Map<Id, SObject> oldItems)
    {
        list<Product2> newProdList= (list<Product2>) newItems;
        
        integer queryLimit = 0;
        
        if(Label.CWS_Custom_Metedata_Query_Limit != null){
            queryLimit = Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);
        }
        
        map<string,string> mapOfPrecision = new map<string,string>(); 
        if(queryLimit != null){
            for(CWS_Precision_Measure_Mapping__mdt  precision: [Select label,DeveloperName 
                                                           from 
                                                           CWS_Precision_Measure_Mapping__mdt LIMIT : queryLimit]){
                mapOfPrecision.put(precision.DeveloperName,precision.label);
            }
        }
        
        String nonSpacedStr;
        
        if(oldItems != null){
            Map<Id,Product2> oldMap = (Map<Id,Product2>) oldItems;
            for(Product2 prod: newProdList){
                nonSpacedStr = '';
                if(prod.CWS_UOM__c != null && prod.CWS_UOM__c != oldMap.get(prod.id).CWS_UOM__c){
                    nonSpacedStr = prod.CWS_UOM__c;
                    nonSpacedStr = nonSpacedStr.replaceAll( '\\s+', '');
                }
            
                if(String.isNotBlank(nonSpacedStr) && 
                    mapOfPrecision != null && 
                    mapOfPrecision.containskey(nonSpacedStr) && 
                    mapOfPrecision.get(nonSpacedStr) != null){
                    prod.CWS_Precision_Measure__c = mapOfPrecision.get(nonSpacedStr);
                }
            }
         }else{
            for(Product2 prod: newProdList){
                nonSpacedStr = '';
                if(prod.CWS_UOM__c != null){
                    nonSpacedStr = prod.CWS_UOM__c;
                    nonSpacedStr = nonSpacedStr.replaceAll( '\\s+', '');
                }
            
                if(String.isNotBlank(nonSpacedStr) && 
                    mapOfPrecision != null && 
                    mapOfPrecision.containskey(nonSpacedStr) && 
                    mapOfPrecision.get(nonSpacedStr) != null){
                    prod.CWS_Precision_Measure__c = mapOfPrecision.get(nonSpacedStr);
                }
            }
        }
    }
}