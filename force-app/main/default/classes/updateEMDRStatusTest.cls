/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : updateEMDRStatusTest.
* @Why   : To test EMDR update.
* @When  : 04-JUN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 04-JUN-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 04-JUN-2020         Code Audit                        Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 09-JUL-2020         Code Audit                        Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar          12-FEB-2025         CHaRM R6/IPDR 552                 updated the Country submission typ name to 30-day    
*---------------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class updateEMDRStatusTest {
    private static final String INITIAL = 'Initial';
    private static final String SUPPLEMENTAL = 'Supplemental';

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        ADD_App_Settings__c settings = ADD_App_Settings__c.getInstance();
        settings.Restrict_Validation_Rules__c = false;
        insert settings;

        Country__c objCountry = (Country__c) TestDataFactory.createSObject(
                new Country__c(Name = 'USA'),
                true
        );
        insert new Country_Submission_Type__c(
                Name = '30-day',
                Calendar_Days__c = 30,
                Country__c = objCountry.Id
        );
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c objTickt = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Business_Unit__c = 'Hematology',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Customer_Reply_Required__c = false,
                        Follow_up_Status__c = 'Further Review'),
                true
        );
        String assmntRTId1 = Schema.SObjectType.CMPL123CME__Questionnaire__c
                .getRecordTypeInfosByName()
                .get(INITIAL)
                .getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = assmntRTId1,
                        CMPL123CME__Complaint__c = objTickt.Id,
                        Reportability_Rationale__c = '1234',
                        Reportability__c = 'Reportable',
                        Reportability_Category__c = 'RCML',
                        CMPL123Rule_Key_Value__c = 'MEDICAL_EVALUATION_WORKFLOW',
                        CMPL123_WF_Status__c = 'Regulatory'),
                true
        );

        CMPL123CME__EMDR__c init = new CMPL123CME__EMDR__c(
                RecordTypeId = Schema.SObjectType.CMPL123CME__EMDR__c
                        .getRecordTypeInfosByName()
                        .get(INITIAL)
                        .getRecordTypeId(),
                Medical_Evaluation__c = questionnaire.Id,
                CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done'
        );
        insert init;
        CMPL123CME__EMDR__c supplement = new CMPL123CME__EMDR__c(
                RecordTypeId = Schema.SObjectType.CMPL123CME__EMDR__c
                        .getRecordTypeInfosByName()
                        .get(SUPPLEMENTAL)
                        .getRecordTypeId(),
                Medical_Evaluation__c = questionnaire.Id,
                CMPL123CME__Initial_MDR__c = init.Id);
        insert supplement;
    }

    /*
    * @Method       : test.
    * @Description  : To test insert of CMPL123CME__Submission_History__c without duplicates.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
      //  List<CMPL123CME__EMDR__c> updateEMDR = new List<CMPL123CME__EMDR__c>();
        CMPL123CME__EMDR__c init = [
                SELECT Id
                FROM CMPL123CME__EMDR__c
                WHERE RecordType.Name = :INITIAL
        ];
        CMPL123CME__EMDR__c supplement = [
                SELECT Id
                FROM CMPL123CME__EMDR__c
                WHERE RecordType.Name = :SUPPLEMENTAL
        ];

        List<CMPL123CME__Submission_History__c> histories = new List<CMPL123CME__Submission_History__c>{
                new CMPL123CME__Submission_History__c(
                        CMPL123CME__Stage__c = 'Draft',
                        CMPL123CME__Status__c = 'Internal Error'
                ),
                new CMPL123CME__Submission_History__c(CMPL123CME__Stage__c = 'Submitted'),
                new CMPL123CME__Submission_History__c(
                        CMPL123CME__Stage__c = 'ACK1',
                        CMPL123CME__Related_EMDR__c = init.Id
                ),
                new CMPL123CME__Submission_History__c(
                        CMPL123CME__Stage__c = 'ACK1',
                        CMPL123CME__Related_EMDR__c = supplement.Id
                ),
                new CMPL123CME__Submission_History__c(
                        CMPL123CME__Stage__c = 'ACK2',
                        CMPL123CME__Related_EMDR__c = init.Id
                ),
                new CMPL123CME__Submission_History__c(
                        CMPL123CME__Stage__c = 'ACK2',
                        CMPL123CME__Related_EMDR__c = supplement.Id
                ),
                new CMPL123CME__Submission_History__c(
                        CMPL123CME__Stage__c = 'ACK3',
                        CMPL123CME__Related_EMDR__c = init.Id
                ),
                new CMPL123CME__Submission_History__c(
                        CMPL123CME__Stage__c = 'ACK3',
                        CMPL123CME__Related_EMDR__c = supplement.Id
                )
        };
         
        Boolean insertFailedIdDuplication;

        Test.startTest();
        try {
            insert histories;
        } catch (DmlException ex) {
            insertFailedIdDuplication = ex.getMessage().containsIgnoreCase('Duplicate id in list');
        }
        Test.stopTest();

        if (null != insertFailedIdDuplication) {
            System.assertEquals(insertFailedIdDuplication,False);
        } else {
            System.assertEquals(histories.size(), [SELECT COUNT() FROM CMPL123CME__Submission_History__c]);
        }
    }
}