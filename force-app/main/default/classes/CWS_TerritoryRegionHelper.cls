/*Class Name: CWS_TerritoryRegionHelper
*Description: Class to be used to Get Territory/Region information
*Created By: Abhishek
*Created On: 02/07/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Abhishek               02/07/2020      BED-874      
*/
public class CWS_TerritoryRegionHelper {
    public static map<String, String> countryCodeMap= new map<String,String>();
    public static map<String, String> StateCodeMap= new map<String,String>();

    /** Mehtod used to return Territory Region information with unique key */
    public static map<String, CWS_Country_Territory_Region_Mapping__mdt> getTerritoryRegion(){

        map<String, CWS_Country_Territory_Region_Mapping__mdt> terRegionMap = new map<String, CWS_Country_Territory_Region_Mapping__mdt>();
        integer queryLimit = Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);
        string key;
        for(CWS_Country_Territory_Region_Mapping__mdt terRegion: [Select label,DeveloperName,CWS_Zip_Code__c,CWS_Country_Code__c,
                                                                    CWS_State_Code__c,CWS_Region__c,CWS_Territory__c,CWS_State__c
                                                                    from 
                                                                    CWS_Country_Territory_Region_Mapping__mdt 
                                                                    Limit : queryLimit ]){
            key=terRegion.CWS_Country_Code__c 
                    + (terRegion.CWS_State_Code__c==CWS_ConstantClass.notAvailable ? '' : terRegion.CWS_State_Code__c)
                    + (terRegion.CWS_Zip_Code__c==CWS_ConstantClass.notAvailable ? '' : terRegion.CWS_Zip_Code__c);
            terRegionMap.put(key,terRegion);
            countryCodeMap.put(terRegion.label,terRegion.CWS_Country_Code__c);
            if(terRegion.CWS_State__c != CWS_ConstantClass.notAvailable){
                StateCodeMap.put(terRegion.CWS_State__c,terRegion.CWS_State_Code__c);
            }
        }
        return terRegionMap;
        
   }

   /** Mehtod used to return unique key based on Object data */
    public static string getTerrRegionKey(string country,string state,string zip){
        if(country == CWS_ConstantClass.GB && zip !=Null ){
            zip=zip.ToUpperCase();
            return country + (state==Null ? '' : state ) + ( zip.length() == 1 ? zip : (zip.substring(0,2).isAlpha() ? zip.substring(0,2) : zip.substring(0,1)));
        }
        else{
            return country + (state==Null ? '' : state );
        }
    
    }
}