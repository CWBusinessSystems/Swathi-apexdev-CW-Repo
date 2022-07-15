/********************************************************************************************************************************************
* @author         Karolinski Stephane
* @description    Utility Class providing a set of common methods related to SF that can be used cross functionalities
* @date           2018-05-30
* @group          Common Libraries
********************************************************************************************************************************************/
public class UTL_SF 
{
	
	/*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method retrieves the recordtype of a given record type identified providing the RecordType Developper name and associate sObject Name
    * @param            developerName (String): the RecordType Developer Name
    * @param            objectName (String): the sObject Name of the RecordType
    * @return           RecordType: The RecordType object
    *********************************************************************************************************/
    public static RecordType getRecordTypeByName(String developerName, String objectName)
    {
        //BUILD THE MAP FOR ALL THE OBJECTS IF NOT CACHED YET
        if (recordTypesByObjectByName == null)
        {
			//1) Initialize the cache
			recordTypesByObjectByName = new Map<String,Map<String, RecordType>>();

			//2) Retrieve all the record Types
            List<RecordType> recTypes = [SELECT Id, toLabel(Name), SobjectType, DeveloperName FROM RecordType];
            
			//3) Assign record Types per ojbect in the map
			for (RecordType rt:recTypes)
            {
				if (!recordTypesByObjectByName.containsKey(rt.SobjectType))
					recordTypesByObjectByName.put(rt.SobjectType, new  Map<String, RecordType>());

        		recordTypesByObjectByName.get(rt.SobjectType).put(rt.DeveloperName, rt);
            }


        }
        
		//RETRIEVE THE REQUESTED RECORD TYPE FROM THE CACHE
		if (recordTypesByObjectByName.containsKey(objectName))
		{
			Map<String, RecordType> recordTypesForSpecificObject = recordTypesByObjectByName.get(objectName);
			
			if(recordTypesForSpecificObject.containsKey(developerName))
			{
            	return recordTypesForSpecificObject.get(developerName);
        	}
		}
        return null;
    }
    //Cache of the RecordTypes
    private static Map<String,Map<String, RecordType>> recordTypesByObjectByName;


	/*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method retrieves the Profile when providing the correct Profile Name
    * @param            profileName (String): The name of the profile to be retrieved
    * @return           Profile: The Profile record for the searched name
    *********************************************************************************************************/
    public static Profile getProfileByName(String profileName)
    {
        Profile profile = new Profile();
        if (!profilesByName.containsKey(profileName))
        {
            profile = [SELECT Id, Name FROM Profile WHERE Name= :profileName LIMIT 1];
            profilesByName.put(profile.Name, profile);      
        }
        return profilesByName.get(profileName);
    }
    //Cache of the Profiles
    private static Map<String, Profile> profilesByName = new Map<String, Profile>();


 	/*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method retrieves the UserRole when providing the correct UserRole Name
    * @param            userRoleName (String): The name of the user role to be retrieved
    * @return           UserRole: The UserRole record for the searched name
    *********************************************************************************************************/
    public static UserRole getUserRoleByName(String userRoleName)
    {
        UserRole role = new UserRole();
        if (!userRolesByName.containsKey(userRoleName))
        {
            role = [SELECT Id, Name FROM UserRole WHERE Name= :userRoleName LIMIT 1];
            userRolesByName.put(role.Name, role);
        }
        return userRolesByName.get(userRoleName);
    }
    //Cache of the User Roles
    private static Map<String, UserRole> userRolesByName = new Map<String, UserRole>();

    /********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2016-05-12
    * @description      Method used to retrieve the static resource based on the name of this one
    * @param            staticResourceName  (String) : The name of the static resource
    * @return           StaticResource:  The retrieved static resource
    *********************************************************************************************************/
    public static StaticResource getStaticResourceByName(String staticResourceName) 
    {
        if (!staticResourceByName.containsKey(staticResourceName))
        {
           StaticResource staticResource = [SELECT Body FROM StaticResource WHERE Name = :staticResourceName];
           staticResourceByName.put(staticResourceName, staticResource);
        }
      
        return staticResourceByName.get(staticResourceName);
    }
    //Cache of the Static Resources
    private static Map<String, StaticResource> staticResourceByName = new Map<String, StaticResource>();
 	

	/********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      Property returning a boolean indicating if the SFDC is a sandbox or prod environment
    * @return           Boolean: true if it the SFDC Org is a sandbox
    *********************************************************************************************************/
    @TestVisible 
    public static Boolean isSandbox 
	{
        get 
		{
            if (isSandbox == null) 
			{
                isSandbox = [Select IsSandbox from Organization limit 1].IsSandbox;
            }

            return isSandbox;
        }
        private set;
    }

	/********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      Property returning a String indicating if the name of the Sandbox being used. 
	*					This method will work correctly only if the user name of the current user has not been updated since the PROD refresh
    * @return           String: the name of the current sandbox being used
    *********************************************************************************************************/
    @TestVisible 
    public static String currentSandbox 
	{
        get 
		{
            if (String.isEmpty(currentSandbox))
            {
                if (isSandbox)
                {
                    currentSandbox =  UserInfo.getUserName().substringAfterLast('.');	
                }
            }
           
            return currentSandbox;
        }
        private set;
    }

}