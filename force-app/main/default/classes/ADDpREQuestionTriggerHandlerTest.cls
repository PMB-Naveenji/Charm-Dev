/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDpREQuestionTriggerHandlerTest.
* @Why   : ADDpREQuestionTriggerHandlerTest class for the ADDpREQuestionTriggerHandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                   Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020           Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                07-SEP-2020           Code Audit                Removed empty catch statements.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ADDpREQuestionTriggerHandlerTest {
    /*
    * @Method       : test.
    * @Description  : To test the ADDpREQuestionTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();

        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            CMSNext_Ticket_Number__c = '12345'
        ), true);

        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(new pRE_Information__c(
            External_ID__c = 'CHaRM 24102018 - 01',
            Complaint__c = complaint.Id
        ), true);

        List<pRE_Question__c> pREQuestions = new List<pRE_Question__c> {
            new pRE_Question__c(
                pRE_Information__c = preInfo.Id,
                Answer__c = 'Y'
            )
        };

        Test.startTest();
        insert pREQuestions;
        update pREQuestions;
        delete pREQuestions;
        Test.stopTest();

        System.assertEquals(pREQuestions.size(), [SELECT COUNT() FROM pRE_Question__c ALL ROWS]);
    }
}