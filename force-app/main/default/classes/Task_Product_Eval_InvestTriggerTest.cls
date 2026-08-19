/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : Task_Product_Eval_InvestTriggerTest.
 * @Why   : To test functionality of 'Task_Product_Evaluation_Investigation_123Trigger' trigger.
 * @When  : 22-APR-2020.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer              Date                   Modification ID                 Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                  22-APR-2020            Work ID / Case ID               Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                  15-MAY-2020            CHARM-2586                      Added new unit test.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oober                  10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
 *                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME'
 *                                                                                   error during deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           05-JUL-2023            CHaRM R3.1                      Fixed taskProductTriggerTest crash.
 * Not related to an IPDR. Set isParallel
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@IsTest(isParallel=true)
public class Task_Product_Eval_InvestTriggerTest {
    private static final String PROFILE_NAME_DATALOADER = 'System Administrator Data Loader';

    /**
     * @Method       : init.
     * @Description  : To insert test data.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Now handles creation of ADD App Settings
     */
    @TestSetup
    public static void init() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_DATALOADER].Id;
        TestDataFactory.createSObject(new ADD_App_Settings__c(
            SetupOwnerId = profileId,
            Restrict_Process_Builders__c = true,
            Restrict_Triggers__c = true,
            Restrict_Validation_Rules__c = true,
            Restrict_Workflow_Updates__c = true
        ), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();

        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
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

        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
            CMPL123CME__Complaint__c = complaint.Id,
            CMPL123_WF_Status__c = 'Opened',
            CMPL123_WF_Action_Performed_On__c = System.today()
        ), true);

        Task__c task = (Task__c) TestDataFactory.createSObject(new Task__c(
            Related_Investigation_Evaluation__c = investigation.Id,
            CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
            Source_Leveraged__c = 'Leveraged',
            CMPL123_WF_Status__c = 'Opened:In Process'
        ), true);

        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
            CMPL123__Child_Relationships_Object__c = 'Attachment__c-Investigation_Evaluation__c,Task__c-Related_Investigation_Evaluation__c,KI_Log__c-Leveraged_Complaint_Investigation__c,Product_Lot__c-Product_Evaluation_Investigation__c,Task_Product_Evaluation_Investigation__c-Investigation_Evaluation__c',
            CMPL123__Is_Active__c = true,
            Name = 'CMPL123CME__Investigation__c'
        ), true);
    }

    /**
     * @Method       : taskProductTriggerTest.
     * @Description  : To test the Task_Product_Evaluation_Investigation_123Trigger audit trail configuration.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Now verifies that undelete is prevented since the managed
     * package now rejects that. Also removed start/stopTest for full code coverage.
     * Merged SOQL for the ProdEval and ProdEvalTask.
     */
    @IsTest
    public static void taskProductTriggerTest() {
        Task__c task = [SELECT Id, Related_Investigation_Evaluation__c FROM Task__c];
        Task_Product_Evaluation_Investigation__c taskProductEvalInvest = (Task_Product_Evaluation_Investigation__c)
            TestDataFactory.createSObject(new Task_Product_Evaluation_Investigation__c(
                Investigation_Evaluation__c = task.Related_Investigation_Evaluation__c,
                Task__c = task.Id
        ), true);
        System.assertEquals(1, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c],
            'Audit trail entry record should be created');

        delete taskProductEvalInvest;
        try {
            undelete taskProductEvalInvest;
            Assert.fail('The managed package is expected to reject this operation');
        } catch(DmlException ex) {
            Assert.isTrue(ex.getMessage().toLowerCase().contains('permission'),
                'Error message should be related to a lack of permissions');
        }
    }

    /**
     * @Method       : testAuditTrailForDataloaderUser.
     * @Description  : To test the audit configuration for dataloader user. No audit trail entries should be created.
     *                   Method added for CHARM-2586(Migrated process issue)
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: User is now IsParallel-friendly.
     * Merged SOQL for the ProdEval and ProdEvalTask.
     */
    @IsTest
    public static void testAuditTrailForDataloaderUser() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_DATALOADER].Id;
        User dataloaderUser = [SELECT Id FROM User
            WHERE ProfileId = :profileId AND IsActive = true LIMIT 1];

        System.runAs(dataloaderUser) {
            Task__c task = [SELECT Id, Related_Investigation_Evaluation__c FROM Task__c];

            Test.startTest();

            Task_Product_Evaluation_Investigation__c taskProductEvalInvest = (Task_Product_Evaluation_Investigation__c) TestDataFactory.createSObject(
                new Task_Product_Evaluation_Investigation__c(
                    Investigation_Evaluation__c = task.Related_Investigation_Evaluation__c,
                    Task__c = task.Id
            ), true);

            Test.stopTest();
        }

        System.assertEquals(0, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c],
            'Audit trail entry record should not be created');
    }
}