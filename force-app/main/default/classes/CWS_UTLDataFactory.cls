/********************************************************************************************************************************************
* @author         Karolinski Stephane
* @description    Utility Class providing methods to generate test data. This class is flagged as a Test Class and can be used only in the context
*                 of test methods with the purpose to provide a generic way to generate test data. This class can be enriched with specific project methods
*                 in case of need.
* @date           2018-05-30
* @group          Common Libraries
********************************************************************************************************************************************/
@isTest
public class CWS_UTLDataFactory
{
    /***************************************************************************************************************************************************
    //THE BELOW CODE IS AN EXAMPLE ON HOW TO IMPLEMENT THE DATA FACTORY FOR EACH TYPE OF OBJECT TO BE CREATED FOR YOUR TEST CLASSES
    //
    //It provides an example for the creation of simple account
    //It provides an example for the creation of accounts in bulk
    //It provides an example for the creation of simple contact
    //It provides an example for the creation of contacts in bulk
    //It provides an example for the creation of a simple user
    //It provides an example for the creation of users in Bulk
    //
    //Key Concept is to:
    //
    //  - Define as input the key fields (limited) that you would like to specify when creating a record
    //  - Define a map with all the mandatory fields (mandatory in the Database, but also mandatory due to validation rule) and thier default value to be used if not provided
    //  - When creating a record the user will invoke the create[ObjectName] or createBulk[ObjectName]s method, providing as input the key fields + a may with additional fields if needed
    //
    //  The code below automatically enrich the provided input with default values for the mandatory fields.
    //  This will allow to manage each object creation in one central place and to easily add mandatory fields afterward without having to rework all the test classes
    /**************************************************************************************************************************************************/

    //**************************************************DEFAULT VALUES MAPPING DEFINITION***********************************************************
    private static Map<String, Object> accountFieldsDefaultValues = new Map<String, Object> //TO BE ADAPTED
    {
            'Name' => 'Default Name',
            'BillingCountry'=>'United States',
            'BillingCity'=>'Philadelphia',
            'BillingStreet'=>'123 '
            
    };
    private static Map<String, Object> contactFieldsDefaultValues = new Map<String, Object> //TO BE ADPATED
    {
            'FirstName' => 'Default FirstName',
            'LastName' => 'Default LastName',
            'Email' => 'user@test.com.invalid'
    };
        
         private static Map<String, Object> contractFieldsDefaultValues = new Map<String, Object> //TO BE ADPATED
    {
            'StartDate' => date.today(),
            'status' => 'Draft'
    };
        
    private static Map<String, Object> userFieldsDefaultValues = new Map<String, Object> //TO BE ADPATED
    {
            'Alias' => 'utst',
            'Email' => 'utst@test.com',
            'LastName' => 'Default Last Name',
            'FirstName' => 'Default First Name',
            'ProfileId' => UserInfo.getProfileId(),
            'UserName' => 'utst@test.com',
            'UserRoleId' => UserInfo.getUserRoleId(),
            'EmailEncodingKey' => 'UTF-8',
            'LocaleSidKey' => 'en_US',
            'LanguageLocaleKey' => 'en_US',
            'TimeZoneSidKey' => 'Europe/Brussels'
    };
    private static Map<String, Object> quoteFieldsDefaultValues=new Map<String, Object>{
            'SBQQ__StartDate__c'=>Date.today(),
            'SBQQ__SubscriptionTerm__c'=>12,
            'SBQQ__Primary__c'=>True,
            'SBQQ__Status__c'=>'Draft'
    };
    
        private static Map<String,Object> agreementFieldDefaultValues= new Map<String,Object>{
            'Name' =>'Test Agreement',
                'Apttus__Status_Category__c' => 'Request',
                'Apttus__Status__c' => 'Request' 
                };
    
    private static Map<String, Object> opportunityFieldsDefaultValues=new Map<String, Object>{
            'Amount'=>1000,
            'StageName'=>'Prospecting',
            'CWS_Route_to_Market__c'=>'Channel'
    };
	
	private static Map<String,Object> DSEnvelopeFieldDefaultValues= new Map<String,Object>{
                };
    
    private static Map<String, Object> productFieldsDefaultValues=new Map<String, Object>{
        'Name'=>'Demo Test Product',
        'SBQQ__BillingType__c'=>'Advance',
        'SBQQ__PricingMethod__c'=>'Cost',
        'SBQQ__SubscriptionTerm__c'=>12,
        'CWS_Description__c'=>'Cloud Access DW Security',       
        'CWS_ProductCode__c'=>'DEMQ9009',
        'CWS_Category__c'=>'Sell',
        'CWS_Charge_Model__c'=>'Per Unit Pricing',
        'CWS_Product_Family__c'=>'Other',
        'CWS_License_Type__c'=>'SaaS',
        'CWS_Product_Line__c'=>'Corporate',
        'CWS_Status__c'=>'Active',
        'CWS_Sub_Category__c'=>'License',
        'CW_Product_Type__c'=>'Product',
        'CWS_SKU_Type__c'=>'Other',
        'CWS_Renewal_Type__c'=>'Opt-out',
        'CWS_Route_to_Market__c'=>'Direct',
        'CWS_Currencies__c'=>'USD',
        'CWS_Billing_Term__c'=>'Monthly',
        'CWS_ChargeType__c'=>'Recurring',
        'CWS_Item_Revenue_Category__c'=>'Services',
        'IsActive'=> True,
        'SBQQ__SubscriptionPricing__c'=>'Fixed Pricing',
        'CWS_UOM__c'=>'Cost'
    };

    private static Map<String, Object> quoteDocFieldsDefaultValues=new Map<String, Object>{
        
    };
    
    private static Map<String, Object> leadFieldsDefaultValues=new Map<String, Object>{
            'Country'=>'India',
            'CWS_Marketo_ID__c'=>'12345',
            'CWS_Region__c'=>'APAC',
            'CWS_Territory__c'=>'Australia East',
            'Company'=>'ABC',
            'status'=>'Inquiry',
            'email'=>'a@b.com'
    };
    
    private static Map<String, Object> partnerAccountFields =new Map<String, Object>{
            'email'=>'dity.reseller@gmail.com',
            'UserName'=>'dity.reseller@gmail.com.partner.cw',
            'Alias'=>'DR',
            'TimeZoneSidKey'=>'America/New_York',
            'EmailEncodingKey'=>'ISO-8859-1',
            'LocaleSidKey'=>'en_US',
            'LanguageLocaleKey'=>'en_US',
            'PortalRole'=> 'Manager',
            'FirstName' => 'Disty',
            'LastName' => 'Reseller'
    };
    
    private static Map<String, Object> campaignFieldsDefaultValues = new Map<String, Object>{
    
    };
    
    private static Map<String, Object> quoteLineFieldDefaultValues = new Map<String, Object>{
        
    };
    private static Map<String, Object> contractFieldDefaultValues  = new Map<String, Object>{
        
    };    

    // Add one map per object you want to be able to create
    //TO BE ENRICHED


    //**************************************************************************************************************************************************


    //**************************************************OBJECT CREATION METHODS***********************************************************

    //**************************************ACCOUNT*********************************************
    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a single account test data
    * @date         2018-09-04
    * @param        accountName (String):                           The name of the account to be created
    * @param        additionalFieldValues (Map<String, Object>):    A map with the additional fields to be populated on the object
    * @param        executeDML (Boolean):                           Indicates if the DML must be executed or not
    * @return       Account:                                        Returns the generated Account
    **************************************************************************************************************************************************************************/
    public static Account createAccount(String accountName, Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        return createBulkAccounts(accountName, additionalFieldValues, 1, executeDML)[0];
    }

    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a multiple accounts test data
    * @date         2018-09-04
    * @param        accountName (String):                           The name of the account to be created (can include the {!i} merge syntax to allow to have different names
    * @param        additionalFieldValues (Map<String, Object>):    A map with the additional fields to be populated on the object
    * @param        nbOfRecords (Integer):                          The number of records to be created
    * @param        executeDML (Boolean):                           Indicates if the DML must be executed or not
    * @return       List<Account>:                                  Returns the generated Accounts
    **************************************************************************************************************************************************************************/
    public static List<Account> createBulkAccounts(String accountName, Map<String, Object> additionalFieldValues, Integer nbOfRecords,  Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues.put('Name', accountName);
        return createBulkAccounts(additionalFieldValues, nbOfRecords, executeDML);
    }

    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a single account test data
    * @date         2018-09-04
    * @param        additionalFieldValues (Map<String, Object>):    A map with the fields to be populated on the object
    * @param        executeDML (Boolean):                           Indicates if the DML must be executed or not
    * @return       Account:                                        Returns the generated Account
    **************************************************************************************************************************************************************************/
    public static Account createAccount(Map<String, Object> additionalFieldValues, Boolean executeDML) //Default method for account creation
    {
        return createBulkAccounts(additionalFieldValues, 1, executeDML)[0];
    }

    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a multiple accounts test data
    * @date         2018-09-04
    * @param        additionalFieldValues (Map<String, Object>):    A map with the additional fields to be populated on the object
    * @param        nbOfRecords (Integer):                          The number of records to be created
    * @param        executeDML (Boolean):                           Indicates if the DML must be executed or not
    * @return       List<Account>:                                  Returns the generated Accounts
    **************************************************************************************************************************************************************************/
    public static List<Account> createBulkAccounts(Map<String, Object> additionalFieldValues, Integer nbOfRecords,  Boolean executeDML) //Default method for account creation
    {
        //1) Enrich Fields Values Map
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, accountFieldsDefaultValues);

        //2) Generate and (Insert) the record
        return (List<Account>) CWS_UTLDynamicApex.createBulkRecords('Account', additionalFieldValues, nbOfRecords, executeDML);
    }
    //*******************************************************************************************
    //**************************************CONTACT**********************************************

    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a single contact test data
    * @date         2018-09-04
    * @param        firstName (String):                             The firstname of the contact to be created
    * @param        lastName (String):                              The lastname of the contact to be created
    * @param        accountId (Id):                                 The account SF Id of the account to which to contact should be linked to.
    * @param        additionalFieldValues (Map<String, Object>):    A map with the additional fields to be populated on the object
    * @param        executeDML (Boolean):                           Indicates if the DML must be executed or not
    * @return       Contact:                                        Returns the generated Contact
    **************************************************************************************************************************************************************************/
    public static Contact createContact(String firstName, String lastName, Id accountId, Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        return createBulkContacts(firstName,lastName,accountId,additionalFieldValues,1,executeDML)[0];
    }

    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a single contact test data
    * @date         2018-09-04
    * @param        firstName (String):                             The firstname of the contacts to be created (You can include the {!i} merge fields)
    * @param        lastName (String):                              The lastname of the contacts to be created (You can include the {!i} merge fields)
    * @param        accountId (Id):                                 The account SF Id of the account to which to contacts should be linked to.
    * @param        additionalFieldValues (Map<String, Object>):    A map with the additional fields to be populated on the object
    * @param        nbOfRecords (Integer):                          The number of records to be created
    * @param        executeDML (Boolean):                           Indicates if the DML must be executed or not
    * @return       List<Contact>:                                  Returns the generated Contact
    **************************************************************************************************************************************************************************/
    public static List<Contact> createBulkContacts(String firstName, String lastName, Id accountId, Map<String, Object> additionalFieldValues, Integer nbOfRecords,  Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues.put('FirstName', firstName);
        additionalFieldValues.put('LastName', lastName);
        additionalFieldValues.put('AccountId', accountId);
        return createBulkContacts(additionalFieldValues, nbOfRecords, executeDML);
    }

    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a single contact test data
    * @date         2018-09-04
    * @param        additionalFieldValues (Map<String, Object>):    A map with the fields to be populated on the object
    * @param        executeDML (Boolean):                           Indicates if the DML must be executed or not
    * @return       Contact:                                        Returns the generated Contact
    **************************************************************************************************************************************************************************/
    public static Contact createContact(Map<String, Object> additionalFieldValues, Boolean executeDML) //Default method for contact creation
    {
        return (Contact) createBulkContacts(additionalFieldValues, 1, executeDML)[0];
    }

    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a multiple contacts test data
    * @date         2018-09-04
    * @param        additionalFieldValues (Map<String, Object>):    A map with the additional fields to be populated on the object
    * @param        nbOfRecords (Integer):                          The number of records to be created
    * @param        executeDML (Boolean):                           Indicates if the DML must be executed or not
    * @return       List<Contact>:                                  Returns the generated Accounts
    **************************************************************************************************************************************************************************/
    public static List<Contact> createBulkContacts(Map<String, Object> additionalFieldValues, Integer nbOfRecords,  Boolean executeDML) //Default method for contact creation
    {
        //1) Enrich Fields Values Map
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, contactFieldsDefaultValues);

        //2) Generate and (Insert) the record
        return (List<Contact>) CWS_UTLDynamicApex.createBulkRecords('Contact', additionalFieldValues, nbOfRecords, executeDML);
    }


    //*******************************************************************************************


    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates a User with a role & profile
    * @date         2018-05-30
    * @param        userALias (Id):                 The User's Alias
    * @param        userEmail (String):             The User's Email
    * @param        userLastName (String):          The User's LastName
    * @param        userProfileName (String):       The User's Profile Name
    * @param        userRole (String):              The User's Role Name
    * @param        userUserName (String):          The User's UserName
    * @param        additionalFieldValues (String): A map with the additional fields to be populated on the object
    * @param        executeDML (Boolean):           Indicates if the DML must be executed or not
    * @return       User:                           Returns the generated User
    **************************************************************************************************************************************************************************/
    public static User createUser (String userAlias,
                                   String userEmail,
                                   String userLastName,
                                   String userProfileName,
                                   String userRoleName,
                                   String userUserName,
                                   Map<String, Object> additionalFieldValues,
                                   Boolean executeDML)
    {
        List<User> usrs = createBulkUsers(userAlias,userEmail,userLastName,userProfileName,userRoleName,userUserName, additionalFieldValues, 1, executeDML);
        return usrs.get(0);
    }



    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method creates Users in Bulk with a role & profile.
    *               Use the special merge field {!i} in order to insert dynamically the user #  in the UserName and other relevant fields
    * @date         2018-05-30
    * @param        userALias (Id):                 The User's Alias
    * @param        userEmail (String):             The User's Email
    * @param        userLastName (String):          The User's LastName
    * @param        userProfileName (String):       The User's Profile Name
    * @param        userRole (String):              The User's Role Name
    * @param        userUserName (String):          The User's UserName (You must include the tag {!i} otherwise the username will not be unique)
    * @param        additionalFieldValues (String): A map with the additional fields to be populated on the object
    * @param        nbOfRecords (String):           The number of records to be created
    * @param        executeDML (Boolean):           Indicates if the DML must be executed or not
    * @return       User:                           Returns the generated Userhttps://connectwise20--dev.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#
    **************************************************************************************************************************************************************************/
    public static List<User> createBulkUsers (String userAlias,
                                              String userEmail,
                                              String userLastName,
                                              String userProfileName,
                                              String userRoleName,
                                              String userUserName,
                                              Map<String, Object> additionalFieldValues,
                                              Integer nbOfRecords,
                                              Boolean executeDML)
    {

        //1) Enrich Fields Values Map
        additionalFieldValues.put('Alias', userAlias);
        additionalFieldValues.put('Email', userEmail);
        additionalFieldValues.put('LastName', userLastName);
        additionalFieldValues.put('UserName', userUserName);
        additionalFieldValues.put('ProfileId', UTL_SF.getProfileByName(userProfileName).Id);
        additionalFieldValues.put('UserRoleId', UTL_SF.getUserRoleByName(userRoleName).Id);

        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, userFieldsDefaultValues);

        //2) Generate and (Insert) the record
        List<User> usrs =  (List<User>) CWS_UTLDynamicApex.createBulkRecords('User', additionalFieldValues, nbOfRecords, false);

        //3) Insert the users if needed
        if(executeDML && usrs.size()>0)
        {
            User currentUser = new User(Id = UserInfo.getUserId());
            System.runAs(currentUser)
            {
                insert usrs;                
                //Assigning salesforce cpq permissionset license while user creation.
                if(usrs.size()>0 && !usrs.isEmpty() && executeDML){
                    PermissionSetLicense license = [SELECT Id, DeveloperName  FROM PermissionSetLicense where  DeveloperName ='SalesforceCPQ_CPQStandardPerm'];
                    if(license != null){
                        List<PermissionSetLicenseAssign> psetLicList = new List<PermissionSetLicenseAssign>();
                        for(User usr:usrs){
                            PermissionSetLicenseAssign  psla = new PermissionSetLicenseAssign();
                            psla.PermissionSetLicenseId = license.id;
                            psla.AssigneeId = usr.Id;
                            psetLicList.add(psla);                    
                        }  
                        if(!psetLicList.isEmpty()){
                            Insert psetLicList;
                        }
                    }
                }
            }
            
        }
        return usrs;

    }

    //**************************************TO BE EXTENDED FOR OTHER OBJECTS**********************************************

    // TO IMPLEMENT

    //********************************************************************************************************************


    /**************************************************************************************************************************************************************************
    * @author       Karolinski Stephane
    * @description  This method enrich the current object mapping with the default values needed to ensure the record is created with the needed values
    * @date         2018-09-04
    * @param        currentFieldsValues (Map<String, Object>):  The current fields to be filled when creating the object. This mapping will be enriched by the default values
    * @param        defaultValuesMap (Map<String, Object>):     The map containing the default values to be used to enrich the current Fields Values Map
    * @return       Map<String, Object>:                        Returns the mapping enriched by the needed default values
    **************************************************************************************************************************************************************************/
    private static Map<String, Object> enrichFieldsValuesMapWithDefaultValues(Map<String, Object> currentFieldsValues, Map<String, Object> defaultValuesMap)
    {
        //Enrich the fields with the mandatory fields default values if not provided yet
        for (String fieldName : defaultValuesMap.keySet())
        {
            if (!currentFieldsValues.containsKey(fieldName))
            {
                currentFieldsValues.put(fieldName, defaultValuesMap.get(fieldName));
            }
        }

        return currentFieldsValues;
    }
    /*Method to Create Quote*/
    public static SBQQ__Quote__c createQuote(Id accountId, Id optyId,Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues.put('SBQQ__Account__c', accountId);
        additionalFieldValues.put('SBQQ__opportunity2__c', optyId);
        additionalFieldValues.put('SBQQ__Distributor__c', accountId);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, quoteFieldsDefaultValues);
        return ((List<SBQQ__Quote__c>) CWS_UTLDynamicApex.createBulkRecords('SBQQ__Quote__c', additionalFieldValues, 1, executeDML))[0];
    }
        
    /*BED-1251 - Method to Create Opportunity*/
    public static Opportunity createOpportunity(String optyName,Id accountId, Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues.put('Name', optyName);
        additionalFieldValues.put('accountID', accountId);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, opportunityFieldsDefaultValues);
        
        return ((List<Opportunity>) CWS_UTLDynamicApex.createBulkRecords('Opportunity', additionalFieldValues, 1, executeDML))[0];
    }
    
    /*BED-1251 - Create Distributor Reseller*/
    Public static CWS_Distributor_Reseller__c createDistributorReseller(Id soldtoAccId, Id distiAccountId, String type,
                 String fulfillmentType,String category, String subcategory, Boolean executeDML){
        CWS_Distributor_Reseller__c distireseller=new CWS_Distributor_Reseller__c(
                CWS_Account__c=soldtoAccId, CWS_Distributor_ResellerAcc__c=distiAccountId, CWS_Type__c=type, 
                CWS_Fulfillment_Type__c=fulfillmentType,CWS_Category__c=category,  CWS_Sub_Category__c=subcategory,CWS_Active__c = true); 
        if(executeDML && distireseller!=null){
            insert distireseller;
        }
        return distireseller;
    }
    

    public static void insertTriggerSwitch(List<String> objList){
        //create custom setting data
        CWS_Trigger_Switch__c objTriggerSwitch = new CWS_Trigger_Switch__c();
        objTriggerSwitch.SetupOwnerId = UserInfo.getOrganizationId();
        
        for(String objName:objList){
            if(objName == 'Opportunity'){
                objTriggerSwitch.CWS_OpportunityTrigger__c = True;
            } else if(objName == 'OpportunityTeamMember') {
                objTriggerSwitch.CWS_OpportunityTeamMember_Trigger__c = True;
            } else if(objName == 'OpportunityLineItem') {
                objTriggerSwitch.CWS_OLITrigger__c = True;
            } else if(objName == 'Quote') {
                objTriggerSwitch.CWS_QuoteTrigger__c = True; 
            }   else if(objName == 'Account'){
                objTriggerSwitch.CWS_AccountTrigger__c = True; 
            }else if (objName=='Order') {
                objTriggerSwitch.CWS_OrderTrigger__c = True; 
            }else if(objName=='OrderItem') {
                objTriggerSwitch.CWS_OrderItemTrigger__c = True;    
            }else if(objName=='SBQQ__QuoteDocument__c') {
                objTriggerSwitch.CWS_QuoteDocument_Trigger__c = True;    
           }else if(objName=='CWS_Distributor_Reseller__c') {
                objTriggerSwitch.CWS_Disy_Reseller_Trigger__c = True;    
           }else if(objName=='Event') {
               objTriggerSwitch.CWS_EventTrigger__c = True;
           }else if(objName=='DiscountTier') {
               objTriggerSwitch.CWS_DiscountTierTrigger__c = True;
           }else if(objName=='DocusignEnvelope') {
              objTriggerSwitch.CWS_DocusignEnvelopTrigger__c= True;
           }else if(objName=='Legacy Data') {
               objTriggerSwitch.CWS_LegacyDataMigration__c = True;
           }else if(objName == 'Attachment trigger') {
                objTriggerSwitch.CWS_Attachment_trigger__c = True;
            }
            else if(objName == 'Product') {
                objTriggerSwitch.CWS_ProductTrigger__c = True;
            }
            else if(objName == 'ProductOption') {
                objTriggerSwitch.CWS_ProductOptionTrigger__c = True;
            }
           if(objName=='CWS_RenewalJobStatusCheck') {
               objTriggerSwitch.CWS_RenewalJobStatusCheck__c=true;
           }
        }
        if(objTriggerSwitch!=null) {
            insert objTriggerSwitch;
        }
        
    }
    
    public static CWS_Economic_Factor__c createEconomicFactor(String Category, String ProductType, Decimal Economicfactor, String currencyCode){
        CWS_Economic_Factor__c eF = new CWS_Economic_Factor__c();
        ef.CWS_Product_Type__c = ProductType;
        ef.CWS_Economic_Factor__c = EconomicFactor;
        ef.CWS_Category__c = Category;
        ef.CurrencyIsoCode = currencyCode;
        insert ef;
        return ef;
          
    }
	
	public static Pricebook2 createCustomPB(String name, Boolean isActive){
       Pricebook2 customPB = new Pricebook2(Name= name, isActive=true);
       insert customPB;   
       return customPB; 
    }
	
    //BED-1251
    Public Static Product2 createProduct(String productName,String productCode, Map<String, Object> additionalFields, Boolean executeDML){
        additionalFields.put('Name', productName);
        additionalFields.put('ProductCode', productCode);
        additionalFields.put('CWS_ProductCode__c',productCode);
        
        additionalFields= enrichFieldsValuesMapWithDefaultValues(additionalFields, productFieldsDefaultValues);
        return ((List<Product2>) CWS_UTLDynamicApex.createBulkRecords('Product2', additionalFields, 1, executeDML))[0];
    }
    
    //BED-1251
    Public Static PricebookEntry createPBEwithPricebookId(Id pricebookId, Id ProductId, Decimal unitPrice,String currencyIsoCode, Boolean executeDML){
        PricebookEntry pbe=new PricebookEntry(Product2Id=productId, pricebook2Id=pricebookId, currencyIsoCode=currencyIsoCode,
                                    unitPrice=unitPrice, isActive = true);
        if(pbe!=null && executeDML){
            insert pbe;
        }
        return pbe;
    }

     Public Static List<SBQQ__BlockPrice__c> createBPList(Id ProductId, Decimal unitPrice, List<String> currencyCode){
        List<SBQQ__BlockPrice__c> BpList = new List<SBQQ__BlockPrice__c>(); 
        for(integer i=0; i<currencyCode.size(); i++){
            SBQQ__BlockPrice__c bP = new SBQQ__BlockPrice__c();
            bP.SBQQ__Product__c = productId;
            bP.currencyIsoCode=currencyCode[i];
            bP.SBQQ__Price__c=unitPrice;
            bP.CWS_Exception_Price__c = false;
            bP.CWS_Exception_Zuora_Price__c = false;
            bP.SBQQ__LowerBound__c = 1;
            bP.SBQQ__UpperBound__c = 10;
            bP.CWS_Zuora_Price__c = unitPrice;
            BpList.add(bP);
         }       
        
        return BpList;
    }

     Public Static List<PricebookEntry> createPBEList(Id pricebookId, Id ProductId, Decimal unitPrice, List<String> currencyCode){
        List<PricebookEntry> pbeList = new List<PricebookEntry>(); 
        for(integer i=0; i<currencyCode.size(); i++){
            PricebookEntry pbe = new PricebookEntry();
            pbe.Product2Id = productId;
            pbe.pricebook2Id=pricebookId;
            pbe.currencyIsoCode=currencyCode[i];
            pbe.unitPrice=unitPrice;
            pbe.IsActive = true;
            pbe.CWS_Exception_Pricing__c = false;
            pbe.CWS_CostPrice__c = unitPrice;
            pbeList.add(pbe);
         }       
        
        return pbeList;
    }
    
    /** createQuoteLines
     * Creating Quote Lines
     * @params : No of QuoteLines, quote id, product id
     * @return : 
     */
    public static List<SBQQ__QuoteLine__c> createQuoteLinesWithBlkPrice(Integer noOfLines,Id quoteId,Id prodId, Id blkPrice, Id pbe){
        list<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        for(integer i=0;i <noOfLines;i++){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Quote__c=  quoteId;
            ql.SBQQ__Product__c = prodId;
            ql.SBQQ__Description__c = 'quote line'+i;
            ql.SBQQ__Quantity__c = 1;
            ql.SBQQ__CustomerPrice__c = 17100;
            ql.SBQQ__MaximumPrice__c = 25000;
            ql.SBQQ__MinimumPrice__c = 10000;
            ql.SBQQ__NetPrice__c = 20000;
            ql.SBQQ__RegularPrice__c = 20000;
            ql.SBQQ__ListPrice__c = 20000;
            ql.SBQQ__UnitCost__c = 20000;
            ql.SBQQ__BlockPrice__c = blkPrice ;
            ql.SBQQ__PricingMethod__c = CWS_ConstantClass.PRICINGMETHOD_BLOCK;
            ql.SBQQ__PricebookEntryId__c = pbe;
            quoteLineList.add(ql);
            
        }
        return quoteLineList;
    }
	
	 /** createQuoteLines
     * Creating Quote Lines
     * @params : No of QuoteLines, quote id, product id
     * @return : 
     */
     public static List<SBQQ__QuoteLine__c> createQuoteLines(Integer noOfLines,Id quoteId,Id prodId){
        list<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        for(integer i=0;i <noOfLines;i++){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Quote__c=  quoteId;
            ql.SBQQ__Product__c = prodId;
            ql.SBQQ__Description__c = 'quote line'+i;
            ql.SBQQ__Quantity__c = 1;
            ql.SBQQ__CustomerPrice__c = 17100;
            ql.SBQQ__MaximumPrice__c = 25000;
            ql.SBQQ__MinimumPrice__c = 10000;
            ql.SBQQ__NetPrice__c = 20000;
            ql.SBQQ__RegularPrice__c = 20000;
            ql.SBQQ__ListPrice__c = 20000;
            ql.SBQQ__UnitCost__c = 20000;
            ql.SBQQ__PricingMethod__c = 'Cost';
            ql.SBQQ__PriorQuantity__c = 4;      
            ql.CWS_Cost_Price__c = 1000;
            ql.CWS_Original_Cost_Price__c = 1025;                
            quoteLineList.add(ql);
            
        }
        return quoteLineList;
    }
    

    public static SBQQ__QuoteDocument__c createQuoteDocument(Id quoteid, Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues.put('SBQQ__Quote__c', quoteid);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, quoteDocFieldsDefaultValues);
        return ((List<SBQQ__QuoteDocument__c>) CWS_UTLDynamicApex.createBulkRecords('SBQQ__QuoteDocument__c', additionalFieldValues, 1, executeDML))[0];
    }
    //creating SBQQ__QuoteTerm__c
    public static SBQQ__QuoteTerm__c createQuoteTerms(Id quoteid, Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues.put('SBQQ__Quote__c', quoteid);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, quoteDocFieldsDefaultValues);
        return ((List<SBQQ__QuoteTerm__c>) CWS_UTLDynamicApex.createBulkRecords('SBQQ__QuoteTerm__c', additionalFieldValues, 1, executeDML))[0];
    }
    //creating SBQQ__QuoteTemplate__c
    public static SBQQ__QuoteTemplate__c createQuoteTemplate( Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        //additionalFieldValues.put('SBQQ__Quote__c', quoteid);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, quoteDocFieldsDefaultValues);
        return ((List<SBQQ__QuoteTemplate__c>) CWS_UTLDynamicApex.createBulkRecords('SBQQ__QuoteTemplate__c', additionalFieldValues, 1, executeDML))[0];
    }
    
    //creating CWS_Promotion__c
    public static CWS_Promotion__c createPromotion( Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        //additionalFieldValues.put('SBQQ__Quote__c', quoteid);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, quoteDocFieldsDefaultValues);
        return ((List<CWS_Promotion__c>) CWS_UTLDynamicApex.createBulkRecords('CWS_Promotion__c', additionalFieldValues, 1, executeDML))[0];
    }
    
    // creating CWS_Minimum_Commit__c
    public static CWS_Minimum_Commit__c createMinCommit(Id oppId, Id billingPeriodId, Map<String, Object> additionalFieldValues, Boolean executeDML) {
        additionalFieldValues.put('CWS_Billing_Period__c', billingPeriodId);
        additionalFieldValues.put('CWS_Opportunity__c', oppId);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, quoteDocFieldsDefaultValues);
        return ((List<CWS_Minimum_Commit__c>) CWS_UTLDynamicApex.createBulkRecords('CWS_Minimum_Commit__c', additionalFieldValues, 1, executeDML))[0];
    }
    
    public static Lead createLead(Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, leadFieldsDefaultValues);
        return ((List<Lead>) CWS_UTLDynamicApex.createBulkRecords('Lead', additionalFieldValues, 1, executeDML))[0];
    }
    
    public static Campaign createCampaign(Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, campaignFieldsDefaultValues);
        return ((List<Campaign>) CWS_UTLDynamicApex.createBulkRecords('Campaign', additionalFieldValues, 1, executeDML))[0];
    }
    
     public static Contract createContract(Id accountId,Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {   
         additionalFieldValues.put('AccountId', accountId);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, contractFieldsDefaultValues);
        return ((List<Contract>) CWS_UTLDynamicApex.createBulkRecords('Contract', additionalFieldValues, 1, executeDML))[0];
    }
    
    public static Apttus__APTS_Agreement__c createAgreement(Id accountId,Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {   
        additionalFieldValues.put('Apttus__Account__c', accountId);
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, agreementFieldDefaultValues);
        return ((List<Apttus__APTS_Agreement__c>) CWS_UTLDynamicApex.createBulkRecords('Apttus__APTS_Agreement__c', additionalFieldValues, 1, executeDML))[0];
    }
    
    public static List<Apttus__APTS_Agreement__c> createBulkAgreements(Map<String, Object> additionalFieldValues, Integer nbOfRecords,  Boolean executeDML) //Default method for contact creation
    {
        //1) Enrich Fields Values Map
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, agreementFieldDefaultValues);

        //2) Generate and (Insert) the record
        return (List<Apttus__APTS_Agreement__c>) CWS_UTLDynamicApex.createBulkRecords('Apttus__APTS_Agreement__c', additionalFieldValues, nbOfRecords, executeDML);
    }
    
    
    public static User createPartnerUser(Map<String, Object> additionalFieldValues, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, partnerAccountFields);
        return ((List<User>) CWS_UTLDynamicApex.createBulkRecords('User', additionalFieldValues, 1, executeDML))[0];
    }
    
    public static SBQQ__QuoteLine__c createQuoteLine(Map<String, Object> additionalFieldValues, Boolean executeDML){
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, quoteLineFieldDefaultValues);
        return ((List<SBQQ__QuoteLine__c>) CWS_UTLDynamicApex.createBulkRecords('SBQQ__QuoteLine__c', additionalFieldValues, 1, executeDML))[0];        
    }
    
    Public static Contract createSalesContract(Map<String, Object> additionalFieldValues, Boolean executeDML){
        additionalFieldValues=enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, contractFieldDefaultValues);
        return ((List<Contract>) CWS_UTLDynamicApex.createBulkRecords('Contract', additionalFieldValues,1,executeDML))[0];
    }
     public static List<Apttus_DocuApi__DocuSignEnvelope__c> createBulkDSEnvelope(Map<String, Object> additionalFieldValues, Integer nbOfRecords,  Boolean executeDML) //Default method for contact creation
    {
        //1) Enrich Fields Values Map
        additionalFieldValues = enrichFieldsValuesMapWithDefaultValues(additionalFieldValues, DSEnvelopeFieldDefaultValues);

        //2) Generate and (Insert) the record
        return (List<Apttus_DocuApi__DocuSignEnvelope__c>) CWS_UTLDynamicApex.createBulkRecords('Apttus_DocuApi__DocuSignEnvelope__c', additionalFieldValues, nbOfRecords, executeDML);
    }
    
   Public static List<SBQQ__Subscription__c> createSubscriptionsfromQuoteLine(Id accountId, Id contractId, Id quoteId, 
                                                                            Boolean executeDML){
        List<SBQQ__Subscription__c> subsList=new List<SBQQ__Subscription__c>();
        for(SBQQ__QuoteLine__c quoteLine: [Select Id, SBQQ__ListPrice__c, CWS_Transaction_Type__c, CWS_Margin__c, CWS_ACVLine__c,SBQQ__RegularPrice__c, SBQQ__NetPrice__c, SBQQ__SubscriptionTerm__c,
                                        SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Quantity__c, SBQQ__ChargeType__c, SBQQ__BillingType__c,
                                        SBQQ__Product__c, SBQQ__ProrateMultiplier__c, SBQQ__Quote__c, SBQQ__Quote__r.CWS_Region__c,
                                        SBQQ__SubscriptionType__c, CurrencyIsoCode from SBQQ__QuoteLine__c where 
                                        SBQQ__Quote__c =:quoteId]){
            SBQQ__Subscription__c sub=new SBQQ__Subscription__c();
            sub.SBQQ__Contract__c=contractId;
            sub.SBQQ__Account__c=accountId;
            sub.SBQQ__Product__c=quoteLine.SBQQ__Product__c;
            sub.SBQQ__QuoteLine__c=quoteLine.Id;
            sub.SBQQ__ListPrice__c=quoteLine.SBQQ__ListPrice__c;
            sub.SBQQ__RegularPrice__c=quoteLine.SBQQ__RegularPrice__c;
            sub.SBQQ__NetPrice__c=quoteLine.SBQQ__NetPrice__c;
            sub.SBQQ__SubscriptionStartDate__c=quoteLine.SBQQ__StartDate__c;
            sub.SBQQ__SubscriptionEndDate__c=quoteLine.SBQQ__EndDate__c;
            sub.SBQQ__Quantity__c=quoteLine.SBQQ__Quantity__c;
            sub.SBQQ__ChargeType__c=quoteLine.SBQQ__ChargeType__c;
            sub.SBQQ__BillingType__c=quoteLine.SBQQ__BillingType__c;
            sub.SBQQ__ProrateMultiplier__c=quoteLine.SBQQ__ProrateMultiplier__c;
            sub.CurrencyIsoCode=quoteLine.CurrencyIsoCode;
            if(quoteLine.SBQQ__Quote__c!=null){
            sub.CWS_Region__c=quoteLine.SBQQ__Quote__r.CWS_Region__c;
            }
            sub.CWS_ACVLine__c = quoteLine.CWS_ACVLine__c;
            sub.CWS_Margin__c = quoteLine.CWS_Margin__c;                               
            sub.CWS_Transaction_Type__c = quoteLine.CWS_Transaction_Type__c;
            sub.SBQQ__ProductSubscriptionType__c = quoteLine.SBQQ__SubscriptionType__c;                               
            sub.SBQQ__SubscriptionType__c=quoteLine.SBQQ__SubscriptionType__c;
            subsList.add(sub);
        }
        if(executeDML==TRUE && subsList!=null && !subsList.isEmpty()){
            insert subsList;
        }
        return subsList;
    }
	
	//Creates Discount Schedule
    public static SBQQ__DiscountSchedule__c createDiscountSchedule(){
        SBQQ__DiscountSchedule__c discSchedule = new SBQQ__DiscountSchedule__c(); 
        discSchedule.SBQQ__Type__c = 'Slab';
        discSchedule.SBQQ__DiscountUnit__c = 'Price';
        discSchedule.Name = 'Test Discount' ;            
        insert discSchedule;        
        return discSchedule;        
    }
	
    //Creates Disount Tier
    public static SBQQ__DiscountTier__c createDiscountTier(Id scheduleId, Boolean executeDML){
        SBQQ__DiscountTier__c discountTier = new SBQQ__DiscountTier__c(); 
        discountTier.SBQQ__DiscountAmount__c = 2000;
        discountTier.SBQQ__Discount__c = 10;
        discountTier.SBQQ__LowerBound__c = 1;
        discountTier.SBQQ__Number__c = 3;
        discountTier.SBQQ__Price__c = 5000;
        discountTier.SBQQ__Schedule__c = scheduleId;
        discountTier.SBQQ__UpperBound__c = 20;
        //discountTier.CWS_Usage_Percent__c = 3;       
        insert discountTier;        
        return discountTier;        
    }
	//Creates Minimum Commit
     public static CWS_Minimum_Commit__c createMinimumCommit(Id oppId,Id accId,Boolean executeDML){
        CWS_Minimum_Commit__c minCommit = new CWS_Minimum_Commit__c(
           CWS_Account__c = accId,
          // CWS_Contract__c = contractId,
           CWS_Monthly_Minimum_Commit__c = 5,
           CWS_Month_Year__c = 'Jan-20',
           CWS_Opportunity__c = oppId            
        );
        if(minCommit !=null & executeDML)
            insert minCommit;
        
        return minCommit;
    }
	
    public static Group createGroup(String grpName, String grpType, Boolean executeDML){
        Group grp = new Group();
        grp.name = grpName;
        grp.Type = grpType; 
        grp.DeveloperName = grpName;
        if(grp !=null && executeDML){
          Insert grp;     
        }
        return grp;
    }
    public static GroupMember createGroupMember(Id userId, Id grpId, Boolean executeDML){
        GroupMember grpMember = new GroupMember();
        grpMember.UserOrGroupId = userId;
        grpMember.GroupId = grpId;
        if(grpMember  !=null && executeDML){
          Insert grpMember ;     
        }
        return grpMember;
    }
    
    public static List<Opportunity> createOpportunities(Map<Integer, Map<String, Object>> additionalFieldValues, Integer NoOfRecs, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        List<Opportunity> oppLst = new List<Opportunity>();     
        Map<Integer, Map<String, Object>> passRecordsMap = new  Map<Integer, Map<String, Object>>();

        for (Integer i: additionalFieldValues.keyset()){
           
           additionalFieldValues.put(i,enrichFieldsValuesMapWithDefaultValues(additionalFieldValues.get(i), opportunityFieldsDefaultValues));
           passRecordsMap.put(i, additionalFieldValues.get(i));

        }
        oppLst.addAll((List<Opportunity>)CWS_UTLDynamicApex.createBulkyfiedRecords('Opportunity', passRecordsMap, executeDML));
        return oppLst;
    }
     
     
    public static List<SBQQ__Quote__c> createQuotes(Map<Integer, Map<String, Object>> additionalFieldValues, Integer NoOfRecs, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        List<SBQQ__Quote__c> quotesLst = new List<SBQQ__Quote__c>();     
        Map<Integer, Map<String, Object>> passRecordsMap = new  Map<Integer, Map<String, Object>>();
        
        for (Integer i: additionalFieldValues.keyset()){
           
           additionalFieldValues.put(i,enrichFieldsValuesMapWithDefaultValues(additionalFieldValues.get(i), quoteFieldsDefaultValues));
           passRecordsMap.put(i, additionalFieldValues.get(i));
        }
        quotesLst.addAll((List<SBQQ__Quote__c>)CWS_UTLDynamicApex.createBulkyfiedRecords('SBQQ__Quote__c', passRecordsMap, executeDML));

        return quotesLst;
    }
	
	   public static List<SBQQ__QuoteLine__c> createQuoteLines(Map<Integer, Map<String, Object>> additionalFieldValues, Integer NoOfRecs, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        List<SBQQ__QuoteLine__c> quotesLst = new List<SBQQ__QuoteLine__c>();     
        Map<Integer, Map<String, Object>> passRecordsMap = new  Map<Integer, Map<String, Object>>();
        
        for (Integer i: additionalFieldValues.keyset()){
           
           additionalFieldValues.put(i,enrichFieldsValuesMapWithDefaultValues(additionalFieldValues.get(i), quoteLineFieldDefaultValues ));
           passRecordsMap.put(i, additionalFieldValues.get(i));
        }
        quotesLst.addAll((List<SBQQ__QuoteLine__c>)CWS_UTLDynamicApex.createBulkyfiedRecords('SBQQ__QuoteLine__c', passRecordsMap, executeDML));

        return quotesLst;
    }
	
	  public static List<SBQQ__QuoteDocument__c> createQuoteDocuments(Map<Integer, Map<String, Object>> additionalFieldValues, Integer NoOfRecs, Boolean executeDML) //Extend here with additional input parameters that are used most of the time
    {
        List<SBQQ__QuoteDocument__c > quotesLst = new List<SBQQ__QuoteDocument__c >();     
        Map<Integer, Map<String, Object>> passRecordsMap = new  Map<Integer, Map<String, Object>>();
        
        for (Integer i: additionalFieldValues.keyset()){
           
           additionalFieldValues.put(i,enrichFieldsValuesMapWithDefaultValues(additionalFieldValues.get(i), quoteDocFieldsDefaultValues));
           passRecordsMap.put(i, additionalFieldValues.get(i));
        }
        quotesLst.addAll((List<SBQQ__QuoteDocument__c>)CWS_UTLDynamicApex.createBulkyfiedRecords('SBQQ__QuoteDocument__c', passRecordsMap, executeDML));

        return quotesLst;
    }
     
}