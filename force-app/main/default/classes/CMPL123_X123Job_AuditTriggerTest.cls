/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CMPL123_X123Job_AuditTriggerTest.
* @Why   : Class to Handle Different scenarios from the CMPL123_X123Job_AuditTrigger trigger.
* @When  : 29-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 29-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 20-AUG-2020         Code Audit                        Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@IsTest
private class CMPL123_X123Job_AuditTriggerTest {
    /*
    * @Method       : testTrigger.
    * @Description  : To test the CMPL123_X123Job_AuditTrigger functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testTrigger() {
        CMPL123__X123Job__c job = new CMPL123__X123Job__c();

        Test.startTest();
        insert job;
        update job;
        delete job;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM CMPL123__X123Job__c]);
    }
}