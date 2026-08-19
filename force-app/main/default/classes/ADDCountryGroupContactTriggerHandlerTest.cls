/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDCountryGroupContactTriggerHandlerTest.
* @Why   : ADDCountryGroupContactTriggerHandlerTest test class for the ADDCountryGroupContactTriggerHandler class.
* @When  : 26-SEP-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                 Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                26-SEP-2018          Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                28-JUL-2020          Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDCountryGroupContactTriggerHandlerTest {
    /*
    * @Method       : testADDCountryGroupContactTriggerHandler.
    * @Description  : To test the ADDCountryGroupContactTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDCountryGroupContactTriggerHandler(){

        // Create Application Setup data
        Country_Group_Contact__c countryGroupContactRecord = (Country_Group_Contact__c) TestDataFactory.createSObject(new Country_Group_Contact__c(), true);
        countryGroupContactRecord.Division__c = 'ADD';
        update countryGroupContactRecord;
        System.assertEquals('ADD', [SELECT Id,Division__c FROM Country_Group_Contact__c WHERE Id =: countryGroupContactRecord.Id].Division__c);
        delete countryGroupContactRecord;
    }
}