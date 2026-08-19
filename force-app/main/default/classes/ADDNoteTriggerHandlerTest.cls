/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDNoteTriggerHandlerTest.
* @Why   : ADDNoteTriggerHandlerTest class for the ADDNoteTriggerHandler class.
* @When  : 07-APR-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                07-APR-2020           Additional coverage         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ADDNoteTriggerHandlerTest {
    /*
    * @Method       : testBeforeInsert.
    * @Description  : To test the ADDNoteTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void testBeforeInsert() {
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);
        insert new Country_Submission_Type__c(
            Name = '30 Days',
            Calendar_Days__c = 30,
            Country__c = objCountry.Id
        );

        CMPL123CME__EMDR__c emdr = new CMPL123CME__EMDR__c(CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO');
        insert emdr;

        Test.startTest();
            try {
                insert new Note(Title = 'Test', ParentId = emdr.Id);
            } catch (DmlException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
                System.assertEquals(System.Label.Cannot_Modify_Note_on_EMDR, e.getDmlMessage(0));
            }
        Test.stopTest();
    }
}