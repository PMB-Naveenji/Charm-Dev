/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CMPL123CME_EMDR_AuditTriggerTest.
* @Why   : CMPL123CME_EMDR_AuditTriggerTest test class for the CMPL123CME_EMDR_AuditTrigger class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                 18-AUG-2020         Code Audit                        Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class CMPL123CME_EMDR_AuditTriggerTest {

    /*
    * @Method       : test.
    * @Description  : To test the CMPL123CME_EMDR_AuditTrigger functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void test() {

        CMPL123CME__Complaint_Code__c complaintCode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint_Code__c(
                        CMPL123CME__Type__c = 'STATE CODE',
                        Name = 'NI'
                ),
                true
        );
        CMPL123CME__Complaint_Code__c complaintCode2 = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint_Code__c(
                        CMPL123CME__Type__c = 'STATE CODE'
                ),
                true
        );
        Country__c country = (Country__c) TestDataFactory.createSObject(
                new Country__c (
                        Name = 'USA'
                ),
                true
        );
        Country_Submission_Type__c countrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Country__c = country.Id,
                        Calendar_Days__c = 30
                ),
                true
        );
        Id complaintRecTypeId = Schema.SObjectType.CMPL123CME__EMDR__c
                .getRecordTypeInfosByName()
                .get('Supplemental')
                .getRecordTypeId();

        CMPL123CME__EMDR__c initialTemp = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done'
                ),
                true
        );
        CMPL123CME__EMDR__c temp = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = complaintRecTypeId,
                        CMPL123CME__Initial_MDR__c = initialTemp.Id
                ),
                true
        );
        System.assert(true);

        CMPL123CME__EMDR__c temp2 = [SELECT Id FROM CMPL123CME__EMDR__c LIMIT 1];
        temp2.Follow_Up_Required__c = 'test';
        update temp;
        System.assert(true);

        CMPL123CME__EMDR__c temp3 = [SELECT Id FROM CMPL123CME__EMDR__c LIMIT 1];
        delete temp3;
        System.assert(true);
    }
}