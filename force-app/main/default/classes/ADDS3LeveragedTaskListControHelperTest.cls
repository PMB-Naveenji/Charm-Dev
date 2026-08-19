/**
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDS3LeveragedTaskListControHelperTest.
 * @Why   : ADDS3LeveragedTaskListControHelperTest class for the ADDS3LeveragedTaskListControllerHelper class.
 * @When  : 27-SEP-2018.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer            Date                  Modification ID             Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                27-SEP-2018           Work ID / Case ID           Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                12-AUG-2020           Code Audit                  Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         13-JUL-2023           CHaRM R3.1                  Crashfix for deleteTasksTest.
 * Split aforementioned method into testDeleteTasksIsAuthorized and testDeleteTasksNotAuthorized.
 * Not related to any IPDR.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest
public class ADDS3LeveragedTaskListControHelperTest {
    private static final String CMSNEXT_NUM = '8785027765093758092875243';
    private static final String EMAIL_AUTH = 'authorized@test.rchacuhcohu';

    /**
     * @Method       : setup.
     * @Description  : To setup test data.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @testSetup static void setup(){
        // R3.1, Larry: Now makes User(s)
        User usr = ADDS3LeveragedTaskListControllerTest.setupMakeAuthorizedUser(EMAIL_AUTH);

        // Run as someone else to avoid Mixed DML and also set the Owner of the ProdEvalTask
        System.runAs(usr) {
            // Create Application Setup data
            ADD_App_Settings__c appConfig = (ADD_App_Settings__c)
                TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

            // Create Complaint
            String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
            CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c)
            TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c  = AspenConstants.DIVISION_DIAGNOSTICS,
                pRE_Status__c  = AspenConstants.STR_Yes,
                Country_of_origin__c  = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c  = 'IA-CC',
                Ticket_Type__c = AspenConstants.STR_Complaint,
                Is_Product_Evaluation_Investigation_chil__c = false,
                CMPL123CME__CMPL123_WF_Status__c  = AspenConstants.STR_Opened,
                CMSNext_Ticket_Number__c = CMSNEXT_NUM
            ), true);
            // Get Investigation
            CMPL123CME__Investigation__c objInvestigation = [
                SELECT Id, CMPL123_WF_Status__c
                FROM CMPL123CME__Investigation__c
                WHERE CMPL123CME__Complaint__c = :complaint.Id];

            // R3.1, Larry: Now sets WF Status so that validation can succeed in
            // preventDeletionifTaskStatusNotOpenedOrNotInprocess
            Task__c tsk =  (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c  = objInvestigation.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
            ), true);

            // R3.1, Larry: No longers inserts a ProdEval-ProdEvalTask junction record
            // because it seems to be made automatically.
        } // end of System.runAs
    }

    /**
     * Pos test(s) for deleteTasks such that the User IS authorized to delete ProdEvalTasks
     * 
     * This test class assumes that authorization is properly validated.
     * That validation is checked in ADDInvestigationTaskTriggerHandlerTest.
     * @revision R3.1, Larry: Fix crash caused by not using an authorized user for the test.
     * Consolidated setup queries for speed. Renamed from deleteTasksTest to
     * differentiate the pos/neg tests
     */
    @isTest
    static void testDeleteTasksIsAuthorized() {
        // R3.1, Larry: Consolidated all queries
        Task_Product_Evaluation_Investigation__c taskAndProdEval = [
            SELECT Id, Investigation_Evaluation__c, Task__c
            FROM Task_Product_Evaluation_Investigation__c
            WHERE Source_Leveraged__c = 'Source' AND
            Investigation_Evaluation__r.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c = :CMSNEXT_NUM AND
            Task__c != null AND
            Investigation_Evaluation__c != null
            LIMIT 1];

        // Pos test to verify that an unauthorized user CAN delete a ProdEval-ProdEvalTask
        User authorizedUser = [SELECT Id FROM User WHERE Email = :EMAIL_AUTH LIMIT 1];
        System.runAs(authorizedUser) {
            ADDS3LeveragedTaskListControllerHelper.deleteTasks(taskAndProdEval.Id);
        }

        //Assert the source task got deleted
        Assert.isTrue([SELECT Id FROM Task_Product_Evaluation_Investigation__c
            WHERE Id = :taskAndProdEval.Id].isEmpty(),
            TestUtil.ERROR_POS + 'ProdEval-ProdEvalTask junction was not deleted');
        Assert.isTrue([SELECT Id FROM Task__c
            WHERE Related_Investigation_Evaluation__c = :taskAndProdEval.Investigation_Evaluation__c].isEmpty(),
            TestUtil.ERROR_POS + 'Should have deleted the ProdEvalTask as well');
    }

    /**
     * Neg test(s) for deleteTasks such that the User is NOT authorized to delete ProdEvalTasks
     * @revision R3.1, Larry: Fix crash caused by not using an authorized user for the test.
     * Consolidated setup queries for speed. Renamed from deleteTasksTest to
     * differentiate the pos/neg tests
     */
    @isTest
    static void testDeleteTasksNotAuthorized() {
        // R3.1, Larry: Consolidated all queries
        Task_Product_Evaluation_Investigation__c taskAndProdEval = [
            SELECT Id, Investigation_Evaluation__c, Task__c
            FROM Task_Product_Evaluation_Investigation__c
            WHERE Source_Leveraged__c = 'Source' AND
            Investigation_Evaluation__r.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c = :CMSNEXT_NUM AND
            Task__c != null AND
            Investigation_Evaluation__c != null
            LIMIT 1];

        // Neg test to verify that an unauthorized user (system context)
        // CANNOT delete a ProdEval-ProdEvalTask
        try {
            ADDS3LeveragedTaskListControllerHelper.deleteTasks(taskAndProdEval.Id);
            Assert.fail(TestUtil.ERROR_NEG + 'Should crash because the system context user ' +
                'is not authorized to delete a ProdEval Task');
        } catch(DmlException ex) {
            Assert.isTrue(ex.getMessage().contains('authorize'), TestUtil.ERROR_NEG +
                'Error should mention that only authorized users can delete the ProdEval Task');
        }
    }

    /**
     * Neg tests for deleteTasks such that invalid parameters are passed
     * @author R3.1, Larry
     */
    @isTest
    static void testDeleteTasksBadParams() {
        final String ERROR_BAD_PARAMS = TestUtil.ERROR_NEG +
            'Should not attempt DML when the function params are invalid';
        final String ERROR_EXPECT_NO_ROWS = TestUtil.ERROR_NEG +
            'Should not attempt DML since no rows should be returned';
        Integer dmlBefore;
        Integer dmlAfter;

        dmlBefore = Limits.getDmlStatements();
        ADDS3LeveragedTaskListControllerHelper.deleteTasks(null);
        dmlAfter = Limits.getDmlStatements();
        Assert.areEqual(dmlBefore, dmlAfter, ERROR_BAD_PARAMS);

        ADDS3LeveragedTaskListControllerHelper.deleteTasks('');
        dmlAfter = Limits.getDmlStatements();
        Assert.areEqual(dmlBefore, dmlAfter, ERROR_BAD_PARAMS);

        try {
            ADDS3LeveragedTaskListControllerHelper.deleteTasks('This is not an Id');
            Assert.fail(TestUtil.ERROR_NEG + 'Should crash because the passed Id is invalid');
        } catch(StringException ex) {
            dmlAfter = Limits.getDmlStatements();
            Assert.areEqual(dmlBefore, dmlAfter, ERROR_BAD_PARAMS);
        }

        Id ticketId = TestUtil.getFakeId(CMPL123CME__Complaint__c.SObjectType);
        ADDS3LeveragedTaskListControllerHelper.deleteTasks(ticketId);
        dmlAfter = Limits.getDmlStatements();
        Assert.areEqual(dmlBefore, dmlAfter, ERROR_EXPECT_NO_ROWS);
        dmlBefore = dmlAfter;

        Id juncId = TestUtil.getFakeId(Task_Product_Evaluation_Investigation__c.SObjectType);
        ADDS3LeveragedTaskListControllerHelper.deleteTasks(ticketId);
        dmlAfter = Limits.getDmlStatements();
        Assert.areEqual(dmlBefore, dmlAfter, ERROR_EXPECT_NO_ROWS);
        dmlBefore = dmlAfter;
    }
}