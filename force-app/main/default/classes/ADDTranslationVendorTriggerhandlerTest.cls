/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDTranslationVendorTriggerhandlerTest.
* @Why   : ADDTranslationVendorTriggerhandlerTest class for the ADDTranslationVendorTriggerhandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                    Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                17-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class ADDTranslationVendorTriggerhandlerTest {
    /*
    * @Method       : triggerEventsTest.
    * @Description  : To test the ADDTranslationVendorTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void triggerEventsTest() {
        Translation_Vendor__c objTranslationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new Translation_Vendor__c(
                Name = 'Do Not Use',
                Division__c = 'ADD',
                Status__c = 'Active',
                Vendor_Email__c = 'test@test.com'),
                true);
        update objTranslationVendor;
        delete objTranslationVendor;
        System.assert(0 == [SELECT COUNT() FROM Translation_Vendor__c WHERE Id = :objTranslationVendor.Id]);
    }
}