/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : PREQuestionListControllerTest.
* @Why   : PREQuestionListControllerTest test class for the PREQuestionListController class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 18-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class PREQuestionListControllerTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId,
                        Country_of_origin__c = 'USA',
                        Division__c = 'ADD'),
                true
        );
        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(
                new pRE_Information__c(
                        External_ID__c = 'CHaRM 24102018 - 01',
                        Complaint__c = complaint.Id),
                true
        );
        insert new pRE_Question__c(
                pRE_Information__c = preInfo.Id,
                Answer__c = 'Y'
        );
    }

    /*
    * @Method       : test.
    * @Description  : To test the PREQuestionListController functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', complaint.Id);

        Test.startTest();
        PREQuestionListController controller = new PREQuestionListController(
                new ApexPages.StandardController(complaint)
        );
        Test.stopTest();

        System.assertEquals(false, controller.complaintChildren_pRE.isEmpty());
    }
}