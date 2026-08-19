/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : CMPL123CME_Submission_HistoryTriggerTest.
 * @Why   : CMPL123CME_Submission_HistoryTriggerTest test class for the CMPL123CME_Submission_History_123Trigger class.
 * @When  : 22-APR-2020.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                Modification ID                   Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 22-APR-2020         CHARM-2400 (67 - General -        Created.
 *                                           Critical /Audit Trail Pick List
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 15-MAY-2020         CHARM-2586(Migrated process       Modified. Added new unit test.
 *                                           issue)
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                 10-JUN-2020         N/A                               Updated code part, which is related to Users'
 *                                                                             insertion. This change designed to prevent a
 *                                                                             'DUPLICATE_USERNAME' error during
 *                                                                             deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 18-AUG-2020         Code Audit                        Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          23-FEB-2023         CHaRM R3.0, TWD upgrade           Fixed submissionHistoryTriggerTest which crashed 
 *                                                                             due to HL7 Compliance validation changes
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar          16-JAN-2025         CHaRM R6.0/IPDR 552              Updated method submissionHistoryTriggerTest
 * --------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public class CMPL123CME_Submission_HistoryTriggerTest {
    private static final String PHONE_NOT_USA = '+011()1234567890';
    /*
    * @Method       : init.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    public static void init(){
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName()
            .get(AspenConstants.STR_Complaint).getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId), true);
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaint.Id
        ), true);
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(), true);

        //Create Country Submission type
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
        new Country_Submission_Type__c(
            Name = '30-day',
            Calendar_Days__c = 30,
            Country__c = objCountry.Id
        ), true);

        // 23-FEB-2023 Larry: Now inserts all Problem Code types for section H6
        Map<String, CMPL123CME__Complaint_Code__c> cmpCodeNameToRecord =
            TestUtil.makeMdrProblemCodes();
        insert cmpCodeNameToRecord.values();

        Id emdrRecordType = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdrInitialRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                RecordTypeId = emdrRecordType,
                Medical_Evaluation__c = questionnaire.Id,
                CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO' //Davis Jan 25 2021
            ), true); 
        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
            new CMPL123__AuditTrail_Config__c(
                CMPL123__Child_Relationships_Object__c = 'Attachment__c-EMDR__c,CMPL123CME__Concomitant_Product__c-CMPL123CME__Related_EMDR__c,CMPL123CME__EMDR__c-CMPL123CME__Initial_MDR__c,CMPL123CME__MDR_Code__c-CMPL123CME__EMDR__c,CMPL123CME__Submission_History__c-CMPL123CME__Related_EMDR__c',
                CMPL123__Is_Active__c = true,
                Name = 'CMPL123CME__EMDR__c'),
            true);

        // 23-FEB-2023 Larry: Succeeded in passing HL7 validations by adding
        // these H6 Problem Code junction records for the EMDR.
        List<CMPL123CME__MDR_Code__c> mdrCodeJuncList = new List<CMPL123CME__MDR_Code__c>();
        for (String codeType : AspenConstants.MDR_CODE_TYPES) {
            System.assertNotEquals(null, cmpCodeNameToRecord.get(codeType).Id);
            mdrCodeJuncList.add(
                (CMPL123CME__MDR_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__MDR_Code__c(
                    CMPL123CME__Complaint_Code__c = cmpCodeNameToRecord.get(codeType).Id,
                    CMPL123CME__EMDR__c = emdrInitialRecord.Id,
                    // Note: Category is VITAL when validating the H6 codes. If you get an error like
                    // "H6 Medical Device Problem Code is a mandatory code", then maybe you forgot to set this.
                    CMPL123CME__Category__c = AspenConstants.MDR_CODE_CATEGORY_EVAL
                ), false)
            );
        }
        insert mdrCodeJuncList;
    }

    /*
    * @Method       : submissionHistoryTriggerTest.
    * @Description  : To test the CMPL123CME_Submission_History_123Trigger audit trail configuration.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void submissionHistoryTriggerTest(){
        //Soumith: Added CMPL123CME__Submitted_Date_Time__c in the CMPL123CME__EMDR__c query
        CMPL123CME__EMDR__c emdr = [SELECT Id, CMPL123CME__CMPL123_WF_Action__c, CMPL123CME__MDR_Submission__c,
                                    CMPL123CME__Submitted_Date_Time__c FROM CMPL123CME__EMDR__c];
        Test.startTest();
        CMPL123CME__Submission_History__c  submHistory =  (CMPL123CME__Submission_History__c ) TestDataFactory.createSObject(
            new CMPL123CME__Submission_History__c (
                CMPL123CME__Related_EMDR__c = emdr.Id
            ), true);

        //Davis: Start
        CMPL123CME__Submission_History__c  submHistory1 =  (CMPL123CME__Submission_History__c ) TestDataFactory.createSObject(
            new CMPL123CME__Submission_History__c (
                CMPL123CME__Related_EMDR__c = emdr.Id,
                CMPL123CME__Stage__c = 'Submitted'
            ), true);
        CMPL123CME__Submission_History__c  submHistory2 =  (CMPL123CME__Submission_History__c ) TestDataFactory.createSObject(
            new CMPL123CME__Submission_History__c (
                CMPL123CME__Related_EMDR__c = emdr.Id,
                CMPL123CME__Stage__c = 'ACK1',
                CMPL123CME__Status__c = 'Passed',
                CMPL123CME__FDA_Submission_Date__c = System.Now()
            ), true);
        //CHaRM R6: Start - To check Submitted Date time field is getting autopopulated with FDA Submission Date field from Submission History object.
        CMPL123CME__Submission_History__c subH = [Select id,CMPL123CME__Status__c,CMPL123CME__Related_EMDR__c,CMPL123CME__Stage__c,CMPL123CME__FDA_Submission_Date__c FROM 
                                                 CMPL123CME__Submission_History__c WHERE id =: submHistory2.id AND
                                                 CMPL123CME__Related_EMDR__c =: emdr.id AND 
                                                 CMPL123CME__Stage__c = 'ACK1' ];

        CMPL123CME__EMDR__c emdrNew = [SELECT Id, CMPL123CME__CMPL123_WF_Action__c, CMPL123CME__MDR_Submission__c,CMPL123CME__CMPL123Task_Key_Value__c,
                                    CMPL123CME__Submitted_Date_Time__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.id];
        System.assertequals(subH.CMPL123CME__FDA_Submission_Date__c, emdrNew.CMPL123CME__Submitted_Date_Time__c);
        //CHaRM R6 : End
        CMPL123CME__Submission_History__c  submHistory3 =  (CMPL123CME__Submission_History__c ) TestDataFactory.createSObject(
            new CMPL123CME__Submission_History__c (
                CMPL123CME__Related_EMDR__c = emdr.Id,
                CMPL123CME__Stage__c = 'ACK2'
            ), true);
        CMPL123CME__Submission_History__c  submHistory4 =  (CMPL123CME__Submission_History__c ) TestDataFactory.createSObject(
            new CMPL123CME__Submission_History__c (
                CMPL123CME__Related_EMDR__c = emdr.Id,
                CMPL123CME__Stage__c = 'ACK3'
            ), true);
        Test.stopTest();
        System.assertEquals(5, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit trail entry record should be created'); //Davis - changed assert equals expected value FROM 1 to 5
        delete submHistory;

        // 23-FEB-2023 Larry: No longer able to undelete this SObject,
        // so assertions were added to ensure this.
        Boolean isErrorThrown = false;
        try {
            undelete submHistory;
        } catch (DmlException ex) {
            isErrorThrown = true;
            System.assert(ex.getMessage().toLowerCase().contains('permission denied'),
                'Unrecognized error message');
        }
        System.assert(isErrorThrown, 'Expected TWD to prevent undeletion for this SObject');
    }

    /*
    * @Method       : testAuditTrailForDataloaderUser.
    * @Description  : To test the audit configuration for dataloader user. No audit trail entries should be created.
    *                 Method added for CHARM-2586(Migrated process issue)
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testAuditTrailForDataloaderUser(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator Data Loader'].Id;

        ADD_App_Settings__c restrictionSettings = (ADD_App_Settings__c)TestDataFactory.createSObject(new ADD_App_Settings__c(
                SetupOwnerId = profileId,
                Restrict_Process_Builders__c = true,
                Restrict_Triggers__c = true,
                Restrict_Validation_Rules__c = true,
                Restrict_Workflow_Updates__c = true
            ), true);

        User dataloaderUser = (User) TestDataFactory.createSObject(new User(
            ProfileId = profileId,
            LastName = 'MainContact',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        ), true);
        System.runAs(dataloaderUser){
            CMPL123CME__EMDR__c emdr = [SELECT Id FROM CMPL123CME__EMDR__c];

            CMPL123CME__Submission_History__c  submHistory =  (CMPL123CME__Submission_History__c ) TestDataFactory.createSObject(
                new CMPL123CME__Submission_History__c (
                    CMPL123CME__Related_EMDR__c = emdr.Id
                ), true);
        }
        System.assertEquals(0, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit trail entry record should not be created');
    }
}