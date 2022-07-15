/********************************************************************************************************************************************
* @author         Karolinski Stephane
* @description    Utility Class providing a set of common methods related to Dynamic Apex that can be used cross functionalities
* @date           2018-05-30
* @group          Common Libraries
********************************************************************************************************************************************/
public class CWS_UTLDynamicApex 
{
    /********************************************************************************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      Cash a global describe returning a map of sObjectType per object api name
    * @return           Map<String, Schema.SObjectType> : a map containing per object api name the associated sObjectType of this object
    ********************************************************************************************************************************************************************/
    public static Map<String, Schema.SObjectType> sObjectTypesPerObjectName 
    {
        get 
        {
            if ( sObjectTypesPerObjectName == null ) 
            {
                sObjectTypesPerObjectName = Schema.getGlobalDescribe();
            }
           
            return sObjectTypesPerObjectName;         
        }
        private set;
    }


    /********************************************************************************************************************************************************************
    * @author           Karolinski Stephane
    * @description      Retrieve the description of a given object
    * @date             2018-05-30
    * @param            sObjectName (String): The api name of the object for which the description must be retrieved
    * @return           Schema.DescribeSObjectResult  : The described sObject
    ********************************************************************************************************************************************************************/
    public static Schema.DescribeSObjectResult getsObjectDescription(String sObjectName) 
    {
        if (!sObjectDescriptionByObjectName.containsKey(sObjectName))
        {
            sObjectDescriptionByObjectName.put(sObjectName, sObjectTypesPerObjectName.get(sObjectName).getDescribe());
        }
        return sObjectDescriptionByObjectName.get(sObjectName);    
    }
     //Cache of the object description
    private static Map<String,Schema.DescribeSObjectResult> sObjectDescriptionByObjectName = new Map<String,Schema.DescribeSObjectResult>();


     /********************************************************************************************************************************************************************
    * @author           Karolinski Stephane
    * @description      Retrieve the description of a given field
    * @date             2018-05-30
    * @param            sObjectName (String): The api name of the object of the field for which description must be retrieved
    * @param            fieldName (String): The api name of the field for which description must be retrieved
    * @return           Schema.DescribeFieldResult  : The described field
    ********************************************************************************************************************************************************************/
    public static   Schema.DescribeFieldResult getsFieldDescription(String sObjectName, String fieldName) 
    {
        String fieldFullName = sObjectName + '.' + fieldName;

        if (!sObjectDescriptionByFieldFullName.containsKey(fieldFullName))
        {
            sObjectDescriptionByFieldFullName.put(fieldFullName, getsObjectDescription(sObjectName).fields.getMap().get(fieldName).getDescribe());
        }

        return sObjectDescriptionByFieldFullName.get(fieldFullName);
    }
     //Cache of the field description
    private static Map<String,Schema.DescribeFieldResult> sObjectDescriptionByFieldFullName = new Map<String,Schema.DescribeFieldResult>();


    /********************************************************************************************************************************************************************
   * @author            Karolinski Stephane
   * @description       Retrieve the description of a given picklist value (label, value, ...)
   * @date              2018-09-01
   * @param             sObjectName (String): The api name of the object of the field for which description must be retrieved
   * @param             fieldName (String): The api name of the field for which description must be retrieved
   * @param             picklistValue (String): The api name of the picklist value to be retrieved
   * @return            Schema.PicklistEntry  : The described picklist value
   ********************************************************************************************************************************************************************/
    public static   Schema.PicklistEntry getsPickListValueDescription(String sObjectName, String fieldName, String picklistValue)
    {
        Schema.DescribeFieldResult fieldInfo = getsFieldDescription(sObjectName, fieldName);
        Schema.PicklistEntry picklistInfo;

        for (Schema.PicklistEntry pe : fieldInfo.picklistValues)
        {
            if (pe.value == picklistValue) {
                picklistInfo = pe;
                break;
            }
        }

        return picklistInfo;
    }



    /********************************************************************************************************************************************************************
    * @author           Karolinski Stephane
    * @description      Return an instance of a sObject
    * @date             2018-05-30
    * @param            sObjectName (String): The api name of the object instance to be created
    * @return           sObject : The sObject instance generated
    ********************************************************************************************************************************************************************/
    public static sObject createSObjectInstance(String sObjectName) 
    {
        return sObjectTypesPerObjectName.get(sObjectName).newSObject();      
    }

    /*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is a generic method allowing to create dynamically any sObject record
    * @param            sObjectName (String):   The api name of the object for which an instance must be generated
    * @param            fieldsValues (Map<String, Object>): A map containing per fieldname the associated value to be provided
    * @param            executeDML (Boolean): A boolean value indicating if the DML must be executed or not
    * @return           sObject: Return the sObject instance that has been created
    *********************************************************************************************************/
    public static sObject createRecord(String sObjectName, Map<String, Object> fieldsValues, Boolean executeDML)
    {
        sObject record = CWS_UTLDynamicApex.createSObjectInstance(sObjectName);

        for(String fieldName : fieldsValues.keySet())
        {
            Object fieldValue = fieldsValues.get(fieldName);
            record.put(fieldName, fieldValue);
        }

        if (executeDML && record!=null)
        {
            insert record;
        }

        return record;
    }

    /*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is a generic method allowing to create dynamically a list of sObject records.
    *                   The method supports to introduce a reference to the record # instance in text fields provided (use the following synthax: {!i})
    * @param            sObjectName (String):   The api name of the object for which an instance must be generated
    * @param            fieldsValues (Map<String, Object>): A map containing per fieldname the associated value to be provided
    * @param            nbOfRecords (Integer): The number of records to be generated
    * @param            executeDML (Boolean): A boolean value indicating if the DML must be executed or not
    * @return           sObject: Return the sObject instance that has been created
    *********************************************************************************************************/
    public static List<sObject> createBulkRecords(String sObjectName, Map<String, Object> fieldsValues, Integer nbOfRecords, Boolean executeDML)
    {
        List<sObject> records = new List<sObject>();

        for (Integer i=1; i<= nbOfRecords; i++)
        {
            Map<String, Object> fieldsValuesForInstance = fieldsValues.Clone();

            //1) Check if field value contains mail merge reference for the record # instance and replace it by this instance
            // Record # mail merge reference should be tagged as following: {!i}
            for (String fieldName : fieldsValuesForInstance.keySet())
            {
                Object fieldValue = fieldsValuesForInstance.get(fieldName);
                if (fieldValue instanceOf String)
                {
                    String fieldValueInString = (String) fieldValue;
                    fieldValueInString = fieldValueInString.replace('{!i}', String.valueOf(i).LeftPad(3, '0'));
                    fieldsValuesForInstance.put(fieldName,fieldValueInString);
                }
            }

            //2) Create the sObject Instance
            sObject record = createRecord(sObjectName, fieldsValuesForInstance, false);
            records.add(record);
        }

        if (executeDML && records!=null && !records.isEmpty())
            insert records;

        return records;
    }


    /********************************************************************************************************************************************************************
    * @author           Karolinski Stephane
    * @description      Retrieves the list of the fieldset members for a given fieldSet
    * @date             2018-05-30
    * @param            fieldSetName (String): The name of the fieldSet for which the members must be retrieved
    * @param            objectName (String): The name of the sObject which the FieldSet belongs to.
    * @return           List<Schema.FieldSetMember>:    Returns the FieldSet members associated to the specified fieldSet name
    ********************************************************************************************************************************************************************/
    public static List<Schema.FieldSetMember> retrieveFieldSetMembers(String fieldSetName, String objectName)
    {
        List<Schema.FieldSetMember> result = new List<Schema.FieldSetMember>();

        Schema.DescribeSObjectResult describeSObjectResultObj = getsObjectDescription(objectName);

        Schema.FieldSet fieldSetObject = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

        if (fieldSetObject != null)
            result = fieldSetObject.getFields();

        return  result;
    }

    /********************************************************************************************************************************************************************
    * @author           Karolinski Stephane
    * @description      This method compares two sObject records and return true if at least one of the fields part of the specified FieldSet are different
    * @date             2018-05-30
    * @param            fieldSetName (String): The name of the fieldSet for which the members must be retrieved
    * @param            objectName (String): The name of the sObject which the FieldSet belongs to.
    * @param            newValueRecrod (String): The sObject record containing the new values
    * @param            oldValueRecord (String): The sObject record containing the old values
    * @return           Boolean:    Return true if the two records should be considered has changed or false if they are identical
    ********************************************************************************************************************************************************************/
    public static Boolean isRecordChangedBasedOnFieldSet(String fieldSetName, String objectName, sObject newValueRecord, sObject oldValueRecord)
    {
        List<Schema.FieldSetMember> fieldsToCheck = retrieveFieldSetMembers(fieldSetName,objectName);
        for(Schema.FieldSetMember f : fieldsToCheck)
        {
            Object newValue = newValueRecord.get(f.getFieldPath());
            Object oldValue = oldValueRecord.get(f.getFieldPath());

            if (newValue != oldValue)
            {
                return true;
            }
        }
        return false;
    }
	
	
	 public static List<sObject> createBulkyfiedRecords(String sObjectName, Map<Integer, Map<String, Object>> fieldsValues, Boolean executeDML)
    {
         
        List<sObject> records = new List<sObject>();
        Map<String, Object> getMapvalues = new Map<String, Object>();

        for (Integer i : fieldsValues.keyset())
        {
            getMapValues = fieldsvalues.get(i);
            Map<String, Object> fieldsValuesForInstance = getMapValues.Clone();           

            //1) Check if field value contains mail merge reference for the record # instance and replace it by this instance
            // Record # mail merge reference should be tagged as following: {!i}
           
                for (String fieldName : fieldsValuesForInstance.keySet()) {
                        Object fieldValue = fieldsValuesForInstance.get(fieldName);
                        if (fieldValue instanceOf String)
                        {
                            String fieldValueInString = (String) fieldValue;
                            fieldValueInString = fieldValueInString.replace('{!i}', String.valueOf(i).LeftPad(3, '0'));
                            fieldsValuesForInstance.put(fieldName,fieldValueInString);
                        }
                }
            
            //2) Create the sObject Instance
            sObject record = createRecord(sObjectName, fieldsValuesForInstance, false);
            records.add(record);
        }

        if (executeDML && records!=null && !records.isEmpty())
            insert records;

        return records;
    }
}