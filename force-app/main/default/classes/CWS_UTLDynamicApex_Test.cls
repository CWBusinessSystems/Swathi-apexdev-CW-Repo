/********************************************************************************************************************************************
* @author         Karolinski Stephane
* @description    Test class related to the Dynamic Apex Utility Class
* @date           2018-05-30
* @group          Common Libraries - Test Classes
********************************************************************************************************************************************/
@IsTest
private class CWS_UTLDynamicApex_Test 
{
    /*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is testing the different describe features
    * @return           void
    *********************************************************************************************************/
    @IsTest private static void test_DescribeFeatures()
    {
        Test.StartTest();

        Schema.DescribeSObjectResult objDescription = CWS_UTLDynamicApex.getsObjectDescription('Account');
        Schema.DescribeFieldResult fieldDescription = CWS_UTLDynamicApex.getsFieldDescription('Account', 'Name');
        Schema.PicklistEntry picklistValue = CWS_UTLDynamicApex.getsPickListValueDescription('User', 'LanguageLocaleKey', 'en_US');

        Test.StopTest();

        System.assertEquals('Account', objDescription.getLocalName(), 'Account object description should be retrieved');
        System.assertEquals('Name', fieldDescription.getLocalName(), 'Account Name field description should be retrieved');
        System.assertEquals('en_US', picklistValue.value);
    }
    
    /*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is testing the dynamic generation of a sObject instance
    * @return           void
    *********************************************************************************************************/
    @IsTest private static void test_createSObjectInstance()
    {
        Test.StartTest();

        sObject account = CWS_UTLDynamicApex.createSObjectInstance('Account');

        Test.StopTest();

        System.assertEquals(true, account instanceOf Account, 'Instanciated sObject should be of type Account');
    }

    /*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is testing the dynamic creation of a sObject in Bulks
    * @return           void
    *********************************************************************************************************/
    @IsTest private static void test_createRecords()
    {
        Test.StartTest();

        List<Lead> leads = (List<Lead>) CWS_UTLDynamicApex.createBulkRecords('Lead', new Map<String, Object>{'LastName' => 'MyLead{!i}'},2, false);

        Test.stopTest();

        System.assertEquals(2, leads.size());
        System.assertEquals('MyLead001', leads[0].LastName);
        System.assertEquals('MyLead002', leads[1].LastName);
    }

    /*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method getting some code coverage for the fieldset member retrieval.
    *                   No real testing can be done due to the fact that fieldSet are not necessarily existing
    * @return           void
    *********************************************************************************************************/
    @IsTest private static void test_retrieveFieldSetMembers()
    {
        List<Schema.FieldSetMember> fieldSetMembers;

                Test.StartTest();


        fieldSetMembers = CWS_UTLDynamicApex.retrieveFieldSetMembers('fakename', 'Account');

        Test.StopTest();

        System.assert(fieldSetMembers != null);
        System.assertEquals(0, fieldSetMembers.size());
    }

    /*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method getting some code coverage for the fieldset member retrieval.
    *                   No real testing can be done due to the fact that fieldSet are not necessarily existing
    * @return           void
    *********************************************************************************************************/
    @IsTest private static void test_comparesObjects()
    {
        List<Schema.FieldSetMember> fieldSetMembers;

        Test.StartTest();

        Boolean result = CWS_UTLDynamicApex.isRecordChangedBasedOnFieldSet('fakeFieldSet', 'Account', new Account(Name='Hello'), new Account(Name='World'));

        Test.StopTest();

        System.assertEquals(false, result);
    }
}