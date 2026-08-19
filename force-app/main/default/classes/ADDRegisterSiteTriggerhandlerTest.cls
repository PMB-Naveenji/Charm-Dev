/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDRegisterSiteTriggerhandlerTest.
* @Why   : ADDRegisterSiteTriggerhandlerTest class for the ADDRegisterSiteTriggerhandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class ADDRegisterSiteTriggerhandlerTest {
    /*
    * @Method       : triggerEventsTest.
    * @Description  : To test the ADDRegisterSiteTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void testRegisterSiteHandler() {
        CMPL123CME__Registered_Site__c rs = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                        CMPL123CME__G1_Contact_Office_Region_State__c = 'NA',
                        Division__c = 'ADD'
                ), true);
        update rs;
        delete rs;
        System.assert(0 == [SELECT COUNT() FROM CMPL123CME__Registered_Site__c WHERE Id = : rs.Id]);
    }
}