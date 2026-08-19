/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDComplaintCodesTriggerhandlerTest.
* @Why   : ADDComplaintCodesTriggerhandlerTest test class for the ADDComplaintCodesTriggerhandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 N/A                 Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 28-JUL-2020         Code Audit                        Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class ADDComplaintCodesTriggerhandlerTest {
    /*
    * @Method       : triggerEventsTest.
    * @Description  : To test the ADDComplaintCodesTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void triggerEventsTest() {
        CMPL123CME__Complaint_Code__c ccode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint_Code__c(),true);
        update ccode;
        delete ccode;
        System.assert(0 == [SELECT COUNT() FROM CMPL123CME__Complaint_Code__c WHERE Id = :ccode.Id]);
    }
}