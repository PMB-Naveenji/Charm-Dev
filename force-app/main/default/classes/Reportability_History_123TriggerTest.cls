/**
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : Reportability_History_123TriggerTest.
 * @Why   : Reportability_History_123TriggerTest class for the Reportability_History_123Trigger trigger.
 * @When  : 22-APR-2020.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                Modification ID                   Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 22-APR-2020         CHARM-2400                        Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 15-MAY-2020         CHARM-2586                        Modified. Added new unit test.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                 10-JUN-2020         N/A                               Updated code part, which is related to Users' insertion.
 *                                                                             This change designed to prevent a 'DUPLICATE_USERNAME'
 *                                                                             error during deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Oober                 21-AUG-2020         Code Audit                        Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          06-JUL-2023         CHaRM R3.1                        Fixed reportabilityHistoryTriggerTest crash.
 * Not related to an IPDR. Set isParallel
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest(isParallel=true)
public class Reportability_History_123TriggerTest {
    private static final String PROFILE_NAME_DATALOADER = 'System Administrator Data Loader';

    /**
     * @Method       : init.
     * @Description  : To create data for tests.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Now handles creation of ADD App Settings
     */
    @TestSetup
    public static void init(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_DATALOADER].Id;

        ADD_App_Settings__c restrictionSettings = (ADD_App_Settings__c)TestDataFactory.createSObject(new ADD_App_Settings__c(
            SetupOwnerId = profileId,
            Restrict_Process_Builders__c = true,
            Restrict_Triggers__c = true,
            Restrict_Validation_Rules__c = true,
            Restrict_Workflow_Updates__c = true
        ), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get(AspenConstants.STR_Complaint)
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c)
        TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
            pRE_Status__c = AspenConstants.STR_Yes,
            Country_of_origin__c = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c = 'IA-CC',
            CMSNext__c = AspenConstants.CMSNEXT_STATUS_VOID,
            Likely_Cause__c = AspenConstants.STR_Yes,
            Customer_Reply_Required__c = false,
            Follow_up_Status__c = 'Further Review',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_Opened,
            CMPL123CME__CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void,
            Overall_Reportable_Status__c = AspenConstants.REPORTABILITY_YES,
            Is_Product_Evaluation_Investigation_chil__c = true,
            Med_Evaluator_Pending_MDCs__c = false
        ), true);
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c
            .getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c)
        TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaint.Id
        ), true);
        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c)
        TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
            CMPL123__Child_Relationships_Object__c = 'Attachment__c-Assessment__c,CMPL123CME__EMDR__c-Medical_Evaluation__c,CMPL123CME__MEDDEV__c-Medical_Evaluation__c,Medical_Evaluation_Task__c-Medical_Evaluation__c,CMPL123CME__Questionnaire_Items__c-CMPL123CME__Questionnaire__c,Reportability_History__c-Medical_Evaluation__c',
            CMPL123__Is_Active__c = true,
            Name = 'CMPL123CME__Questionnaire__c'),
        true);
    }

    /**
     * @Method       : reportabilityHistoryTriggerTest.
     * @Description  : To test the Reportability_History_123Trigger audit trail configuration.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Now verifies that undelete is prevented since the managed
     * package now rejects that. Also removed start/stopTest for full code coverage.
     */
    @isTest
    public static void reportabilityHistoryTriggerTest(){
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Reportability_History__c  reportabilityHistory =  (Reportability_History__c ) TestDataFactory.createSObject(
            new Reportability_History__c (
                Medical_Evaluation__c = questionnaire.Id
            ), true);
        System.assertEquals(1, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c],
            'Audit trail entry record should be created');
        delete reportabilityHistory;
        try {
            undelete reportabilityHistory;
            Assert.fail('The managed package is expected to reject this operation');
        } catch(DmlException ex) {
            Assert.isTrue(ex.getMessage().toLowerCase().contains('permission'),
                'Error message should be related to a lack of permissions');
        }
    }

    /**
     * @Method       : testAuditTrailForDataloaderUser.
     * @Description  : To test the audit configuration for dataloader user. No audit trail entries should be created.
     *                 Method added for CHARM-2586(Migrated process issue).
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Made the User isParallel-friendly.
     */
    @isTest
    public static void testAuditTrailForDataloaderUser(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_DATALOADER].Id;
        User dataloaderUser = [SELECT Id FROM User
            WHERE ProfileId = :profileId AND IsActive = true LIMIT 1];
        System.runAs(dataloaderUser){
            CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
            Test.startTest();
            Reportability_History__c  reportabilityHistory =  (Reportability_History__c ) TestDataFactory.createSObject(
                new Reportability_History__c (
                    Medical_Evaluation__c = questionnaire.Id
                ), true);
            Test.stopTest();
        }
        System.assertEquals(0, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c],
            'Audit trail entry record should not be created');
    }
}