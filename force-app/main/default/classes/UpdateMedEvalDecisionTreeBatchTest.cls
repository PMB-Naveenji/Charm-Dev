/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateMedEvalDecisionTreeBatchTest.
* @Why   : To test functionality of UpdateMedEvalDecisionTreeBatch class.
* @When  : 31-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  31-MAY-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class UpdateMedEvalDecisionTreeBatchTest {
    /*
    * @Method       : batchTest.
    * @Description  : To test functionality of UpdateMedEvalDecisionTreeBatch class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void batchTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId,
                        Country_of_origin__c = 'USA'
                ), true);
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = assmntRTId,
                        CMPL123CME__Complaint__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Regulatory',
                        Reportability_Rationale__c = 'Regulatory',
                        Reportability__c = 'Reportable',
                        Reportability_Category__c = 'Always Reportable',
                        Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)
                ), true);
        questionnaireRecord.Reportability_Category__c = 'Always Reportable';
        Test.startTest();
        Database.executeBatch(new UpdateMedEvalDecisionTreeBatch(new List<CMPL123CME__Questionnaire__c>{questionnaireRecord}));
        Test.stopTest();
        CMPL123CME__Questionnaire__c questionnaireResult = [SELECT Reportability_Category__c FROM CMPL123CME__Questionnaire__c WHERE Id = :questionnaireRecord.Id];
        System.assert(questionnaireResult.Reportability_Category__c == 'Always Reportable');
    }
}