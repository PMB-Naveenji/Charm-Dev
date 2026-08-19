/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : CMPL123CME_ConcomitantProductTriggerTest.
 * @Why   : CMPL123CME_ConcomitantProductTriggerTest test class for the CMPL123CME_Concomitant_Product_123Trigger class.
 * @When  : 22-APR-2020.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                Modification ID                   Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 22-APR-2020         CHARM-2400 (67 - General -        Created.
 *                                           Critical /Audit Trail
 *                                           Pick List)
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 15-MAY-2020         CHARM-2586(Migrated process       Modified. Added new unit test.
 *                                           issue)
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                 10-JUN-2020         N/A                               Updated code part, which is related to Users'
 *                                                                             insertion. This change designed to prevent a
 *                                                                             'DUPLICATE_USERNAME' error during
 *                                                                             deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 18-AUG-2020         Code Audit                         Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          23-FEB-2023         CHaRM R3.0, TWD Upgrade            Fixed concominantProductTriggerTest crash due to
 *                                                                              old code doing a now-invalid operation
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest
public class CMPL123CME_ConcomitantProductTriggerTest {
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
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objCountry.Id), true);
        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c EMDRInitialRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                RecordTypeId = EMDRInitial,
                Medical_Evaluation__c = questionnaire.Id
            ), true);
        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
            new CMPL123__AuditTrail_Config__c(
                CMPL123__Child_Relationships_Object__c = 'Attachment__c-EMDR__c,CMPL123CME__Concomitant_Product__c-CMPL123CME__Related_EMDR__c,CMPL123CME__EMDR__c-CMPL123CME__Initial_MDR__c,CMPL123CME__MDR_Code__c-CMPL123CME__EMDR__c,CMPL123CME__Submission_History__c-CMPL123CME__Related_EMDR__c',
                CMPL123__Is_Active__c = true,
                Name = 'CMPL123CME__EMDR__c'),
            true);
    }

    /*
    * @Method       : concominantProductTriggerTest.
    * @Description  : To test the CMPL123CME_Concomitant_Product_123Trigger audit trail configuration.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void concominantProductTriggerTest(){
        CMPL123CME__EMDR__c emdr = [SELECT Id FROM CMPL123CME__EMDR__c];

        Test.startTest();
        CMPL123CME__Concomitant_Product__c  concominantProduct =  (CMPL123CME__Concomitant_Product__c ) TestDataFactory.createSObject(
            new CMPL123CME__Concomitant_Product__c (
                CMPL123CME__Related_EMDR__c = emdr.Id
            ), true);
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit trail entry record should be created');
        delete concominantProduct;

        // 23-FEB-2023 Larry: No longer able to undelete this SObject,
        // so assertions were added to ensure this.
        Boolean isErrorThrown = false;
        try {
            undelete concominantProduct;
        } catch (DmlException ex) {
            isErrorThrown = true;
            System.assert(ex.getMessage().toLowerCase().contains('permission denied'),
                'Unrecognized error message.');
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
            CMPL123CME__Concomitant_Product__c  concominantProduct =  (CMPL123CME__Concomitant_Product__c ) TestDataFactory.createSObject(
                new CMPL123CME__Concomitant_Product__c (
                        CMPL123CME__Related_EMDR__c = emdr.Id
                       ), true);
        }
        System.assertEquals(0, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit trail entry record should not be created');
    }
}