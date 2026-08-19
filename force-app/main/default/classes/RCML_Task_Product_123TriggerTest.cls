/**
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : RCML_Task_Product_123TriggerTest.
 * @Why   : RCML_Task_Product_123TriggerTest test Class for the Trigger RCML_Task_Product_123Trigger.
 * @When  : 22-APR-2020
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
 * oivan                 10-JUN-2020         N/A                               Updated code part, which is related to Users' insertion.
 *                                                                             This change designed to prevent a 'DUPLICATE_USERNAME'
 *                                                                             error during deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Oober                 20-AUG-2020         Code Audit                        Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          07-JUL-2023         CHaRM R3.1                        Fixed rcmlTriggerTest crash. Set isParallel.
 * Not related to an IPDR.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest(isParallel=true)
public class RCML_Task_Product_123TriggerTest {
    private static final String PROFILE_NAME_DATALOADER = 'System Administrator Data Loader';
    private static final String MEDEVALTASK_ONE = 'cg7kfrcbdurhad1';
    private static final String MEDEVALTASK_TWO = 'cg7kfrcbdurhad2';

    /**
     * @Method       : init
     * @Description  : To create data for tests.
     * @Invoke       : N/A.
     * @Return       : N/A
     * @Params       : N/A
     * @Revision     : R3.1, Larry: Now handles creation of ADD App Settings
     */
    @TestSetup
    public static void init(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_DATALOADER].Id;

        TestDataFactory.createSObject(new ADD_App_Settings__c(
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
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
        new CMPL123CME__Complaint__c(
            Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
            pRE_Status__c = AspenConstants.STR_Yes,
            Country_of_origin__c = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_Opened,
            CMSNext_Ticket_Number__c = '12345'),
        true);
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(CMPL123CME__Complaint__c = complaint.Id),
            true
        );
        Id taskRecordTypeId = Schema.SObjectType.Medical_Evaluation_Task__c
            .getRecordTypeInfosByName()
            .get('General Task')
            .getRecordTypeId();
        Medical_Evaluation_Task__c taskOne = (Medical_Evaluation_Task__c)TestDataFactory.createSObject(
        new Medical_Evaluation_Task__c(
            Reportable_Confirmed_Malfunction_Descrip__c = 'Test',
            Assignee_Name__c = UserInfo.getUserId(),
            RecordTypeId = taskRecordTypeId,
            No_RCML_Addition_Rationale__c = 'Test information',
            Medical_Evaluation__c = questionnaire.Id,
            CMPL123_WF_Status__c = 'Old',
            Conclusion__c = 'Test',
            Task_Instructions__c = 'Test',
            External_ID__c = MEDEVALTASK_ONE
        ), false);
        Medical_Evaluation_Task__c taskTwo = taskOne.clone(false, true, false, false);
        taskTwo.External_ID__c = MEDEVALTASK_TWO;
        insert new Medical_Evaluation_Task__c[]{ taskOne, taskTwo };

        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
        new CMPL123__AuditTrail_Config__c(
            CMPL123__Child_Relationships_Object__c = 'Attachment__c-Medical_Evaluation_Task__c,RCML_Task_Product__c-RCML_Task_ID__c',
            CMPL123__Is_Active__c = true,
            Name = 'Medical_Evaluation_Task__c'),
        true);
    }

    /**
     * @Method       : rcmlTriggerTest.
     * @Description  : To test the RCML_Task_Product_123Trigger audit trail configuration.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Now verifies that undelete is prevented since the managed
     * package now rejects that. Also removed start/stopTest for full code coverage.
     */
    @isTest
    public static void rcmlTriggerTest(){
        Medical_Evaluation_Task__c task = [SELECT Id FROM Medical_Evaluation_Task__c
            WHERE External_ID__c = :MEDEVALTASK_ONE];

        RCML_Task_Product__c rcml = (RCML_Task_Product__c) TestDataFactory.createSObject(
            new RCML_Task_Product__c (
                RCML_Task_ID__c = task.Id
            ), true);
        System.assertEquals(1, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c],
            'Audit trail entry record should be created');
        delete rcml;
        try {
            undelete rcml;
            Assert.fail('The managed package is expected to reject this operation');
        } catch(DmlException ex) {
            Assert.isTrue(ex.getMessage().toLowerCase().contains('permission'),
                'Error message should be related to a lack of permissions');
        }
    }

    /**
     * @Method       : testAuditTrailForDataloaderUser.
     * @Description  : To test the audit configuration for dataloader user. No audit trail entries should be created.
     *                 Method added for CHARM-2586(Migrated process issue)
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
            Medical_Evaluation_Task__c task = [SELECT Id FROM Medical_Evaluation_Task__c
                WHERE External_ID__c = :MEDEVALTASK_TWO];
            RCML_Task_Product__c rcml = (RCML_Task_Product__c) TestDataFactory.createSObject(
                new RCML_Task_Product__c (
                    RCML_Task_ID__c = task.Id
                ), true);
        }
        System.assertEquals(0, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c],
            'Audit trail entry record should not be created');
    }
}