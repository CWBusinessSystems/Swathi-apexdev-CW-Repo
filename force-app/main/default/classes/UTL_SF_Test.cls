/********************************************************************************************************************************************
* @author         Karolinski Stephane
* @description    Test class related to the SF features Utility Class
* @date           2018-05-30
* @group          Common Libraries - Test Classes
********************************************************************************************************************************************/
@isTest
private class UTL_SF_Test 
{
	/*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is testing the getRecordTypeByName utility method
    * @return           void
    *********************************************************************************************************/
	@isTest private static void test_getRecordTypeByName()
	{
		Test.startTest();

		//No real test feasible since in Standard SF, no object have a record type and this cannot be created for the test
		RecordType rt = UTL_SF.getRecordTypeByName('fakeRTDevName', 'fakeObject');

		Test.stopTest();

		System.assertEquals(null, rt, 'No Record Type Should be returned');
	
	}
	
	/*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is testing the getProfileByName utility method
    * @return           void
    *********************************************************************************************************/
	@isTest private static void test_getProfileByName()
	{
		Test.startTest();

		Profile profile = UTL_SF.getProfileByName('System Administrator');
		
		Test.stopTest();

		System.assertEquals('System Administrator', profile.Name, 'System Administrator Profile is epxected to be retrieved');
	}

	/*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is testing the getUserRoleByName utility method
    * @return           void
    *********************************************************************************************************/
	@isTest private static void test_getUserRoleByName()
	{

		UserRole roleSample = [SELECT Id, Name FROM UserRole LIMIT 1];

		Test.startTest();

		UserRole role = UTL_SF.getUserRoleByName(roleSample.Name);
		
		Test.stopTest();

		System.assertEquals(roleSample.Name, role.Name, 'Role retrieved is not matching the expected role');
	}


	/*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is testing the getStaticResourceByName utility method
    * @return           void
    *********************************************************************************************************/
	@isTest private static void test_getStaticResourceByName()
	{
		Test.startTest();

		//No real test feasible since in Standard SF, there is no static resources
		StaticResource resource;
		try
		{
			resource = UTL_SF.getStaticResourceByName('xxxxxTSTxxxxx');
		}
		catch (Exception e)
		{}

		Test.stopTest();

		System.assertEquals(null, resource, 'No static resource should be found');
	}

	/*********************************************************************************************************
    * @author           Karolinski Stephane
    * @date             2018-05-30
    * @description      The method is testing the sandbox detection utility methods
    * @return           void
    *********************************************************************************************************/
	@isTest private static void test_Sandboxes ()
	{
		Test.startTest();

		//No real test feasible since we cannot control the sandbox/prod where the code is running
		Boolean isSandbox = UTL_SF.isSandbox;
		UTL_SF.isSandbox = true;
		String currentSandbox = UTL_SF.currentSandbox;
		
		Test.stopTest();
	}
	
}