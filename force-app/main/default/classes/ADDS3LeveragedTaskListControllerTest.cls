/**
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDS3LeveragedTaskListControllerTest.
 * @Why   : ADDS3LeveragedTaskListControllerTest class for the ADDS3LeveragedTaskListController class.
 * @When  : 19-APR-2019.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer            Date                  Modification ID             Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                19-APR-2019           Work ID / Case ID           Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                12-AUG-2020           Code Audit                  Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         18-JUL-2023           CHaRM R3.1                  Crashfix for testDeleteTasks.
 * Split aforementioned method into testDeleteTasksIsAuthorized and testDeleteTasksNotAuthorized.
 * Consolidated queries in all test methods. Not related to any IPDR.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest
public class ADDS3LeveragedTaskListControllerTest {
    private static final String CMSNEXT_NUM = '64875875068729687685';
    private static final String EMAIL_AUTH = 'authorized@test.crpfgy';

    /**
     * @Method       : setup.
     * @Description  : To setup test data.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @testSetup static void setup(){
        // R3.1, Larry: Now makes User(s)
        User usr = setupMakeAuthorizedUser(EMAIL_AUTH);

        // Run as someone else to avoid Mixed DML and also set the Owner of the ProdEvalTask
        System.runAs(usr) {
            // Create Application Setup data
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

            // Promote the generated ProdEval to the "Assess" WorkFlow Status
            CMPL123CME__Investigation__c objInvestigation = [
                SELECT Id, CMPL123_WF_Status__c
                FROM CMPL123CME__Investigation__c
                WHERE CMPL123CME__Complaint__c = :complaint.Id];
            objInvestigation.CMPL123_WF_Status__c = AspenConstants.STR_Assess;
            TestDataFactory.updateSObject(objInvestigation);

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

    public static User setupMakeAuthorizedUser(String email) {
        Profile prof = [SELECT Id, Name FROM Profile
            WHERE Name = :AspenConstants.PROFILE_STD LIMIT 1];
        User usr = (User) TestUtil.makeTestUser(
            prof.Id, email, email, true);

        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        for (PermissionSet permSet : [SELECT Id FROM PermissionSet
            WHERE Name = 'Complaint_Assessor' OR
            Name = 'Complaint_Evaluator_Investigator'])
        {
            psaList.add(new PermissionSetAssignment(
                PermissionSetId = permSet.Id,
                AssigneeId = usr.Id
            ));
        }
        insert psaList;

        return usr;
    }

    /** Queries for the ProdEval-ProdEvalTask junction record made in testSetup */
    private static Task_Product_Evaluation_Investigation__c getSetupPEtoPET() {
        return [
            SELECT Id,
            Investigation_Evaluation__r.Id,
            Investigation_Evaluation__r.Name,
            Investigation_Evaluation__r.CMPL123_WF_Status__c,
            Investigation_Evaluation__r.CMPL123CME__Complaint__c,
            Task__r.Id
            FROM Task_Product_Evaluation_Investigation__c
            WHERE Source_Leveraged__c = 'Source'
            LIMIT 1];
    }

    /**
     * @Method       : testADDS3LeveragedTaskListController.
     * @Description  : To test the ADDS3LeveragedTaskListController class functionality.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @isTest
    public static void testADDS3LeveragedTaskListController(){
        Task_Product_Evaluation_Investigation__c taskProductEvalInvestiRecord = getSetupPEtoPET();
        CMPL123CME__Investigation__c objInvestigation = taskProductEvalInvestiRecord.Investigation_Evaluation__r;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(objInvestigation);
        ADDS3LeveragedTaskListController testAccPlan = new ADDS3LeveragedTaskListController(sc);
        PageReference objPageReference = Page.ADDS3LeveragedTaskList;
        Test.setCurrentPage(objPageReference);
        ApexPages.currentPage().getParameters().put('id', objInvestigation.id);
        ApexPages.currentPage().getParameters().put('q', null);
        Test.setCurrentPage(objPageReference);
        ADDS3LeveragedTaskListController obj = new ADDS3LeveragedTaskListController(sc);
        Test.stopTest();
        system.assertEquals(True, obj.childTasks.size() > 0);
    }

    /**
     * @Method       : testDeleteTasksIsAuthorized.
     * @Description  : To test the ADDS3LeveragedTaskListController class functionality.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Repurposed from testDeleteTasks to test
     * authorized vs unathorized user behavior
     */
    @isTest
    public static void testDeleteTasksIsAuthorized(){
        Task_Product_Evaluation_Investigation__c taskProductEvalInvestiRecord = getSetupPEtoPET();
        CMPL123CME__Investigation__c objInvestigation = taskProductEvalInvestiRecord.Investigation_Evaluation__r;
        Task__c tsk = taskProductEvalInvestiRecord.Task__r;

        Test.startTest();
        //To delete Source tasks that are related to Evaluation/Investigation
        ApexPages.StandardController sc = new ApexPages.StandardController(objInvestigation);
        ADDS3LeveragedTaskListController testAccPlan = new ADDS3LeveragedTaskListController(sc);
        PageReference objPageReference = Page.ADDS3LeveragedTaskList;
        Test.setCurrentPage(objPageReference);
        ApexPages.currentPage().getParameters().put('id', objInvestigation.id);
        ApexPages.currentPage().getParameters().put('q', null);
        Test.setCurrentPage(objPageReference);

        ADDS3LeveragedTaskListController obj = new ADDS3LeveragedTaskListController(sc);
        obj.disconnectedId = taskProductEvalInvestiRecord.Id+';'+'';
        // Pos test to verify that an unauthorized user CAN delete a ProdEval-ProdEvalTask
        User authorizedUser = [SELECT Id FROM User WHERE Email = :EMAIL_AUTH LIMIT 1];
        System.runAs(authorizedUser) {
            obj.deleteTasks();
        }
        Test.stopTest();
        //Assert the source task got deleted
        system.assertEquals(false, [SELECT Related_Investigation_Evaluation__c, Id FROM Task__c WHERE Related_Investigation_Evaluation__c =: objInvestigation.Id].size() > 0);
        system.assertEquals(false, [SELECT Id FROM Task_Product_Evaluation_Investigation__c WHERE Investigation_Evaluation__c = :objInvestigation.Id AND Task__c = :tsk.Id].size() > 0);
    }

    /**
     * @Method       : testDeleteTasksNotAuthorized.
     * @Description  : To test the ADDS3LeveragedTaskListController class functionality.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Repurposed from testDeleteTasks to test
     * authorized vs unathorized user behavior
     */
    @isTest
    public static void testDeleteTasksNotAuthorized(){
        Task_Product_Evaluation_Investigation__c taskProductEvalInvestiRecord = getSetupPEtoPET();
        CMPL123CME__Investigation__c objInvestigation = taskProductEvalInvestiRecord.Investigation_Evaluation__r;

        Test.startTest();
        //To delete Source tasks that are related to Evaluation/Investigation
        ApexPages.StandardController sc = new ApexPages.StandardController(objInvestigation);
        ADDS3LeveragedTaskListController testAccPlan = new ADDS3LeveragedTaskListController(sc);
        PageReference objPageReference = Page.ADDS3LeveragedTaskList;
        Test.setCurrentPage(objPageReference);
        ApexPages.currentPage().getParameters().put('id', objInvestigation.id);
        ApexPages.currentPage().getParameters().put('q', null);
        Test.setCurrentPage(objPageReference);

        ADDS3LeveragedTaskListController obj = new ADDS3LeveragedTaskListController(sc);
        obj.disconnectedId = taskProductEvalInvestiRecord.Id+';'+'';
        // Neg test to verify that an unauthorized user (system context)
        // CANNOT delete a ProdEval-ProdEvalTask
        try {
            obj.deleteTasks();
            Assert.fail(TestUtil.ERROR_NEG + 'Should crash because the system context user ' +
                'is not authorized to delete a ProdEval Task');
        } catch(DmlException ex) {
            Assert.isTrue(ex.getMessage().contains('authorize'), TestUtil.ERROR_NEG +
                'Error should mention that only authorized users can delete the ProdEval Task');
        }
        Test.stopTest();
    }

    /**
     * @Method       : testDisconnectTasks.
     * @Description  : To test the ADDS3LeveragedTaskListController class functionality.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @isTest
    public static void testDisconnectTasks(){
        Task_Product_Evaluation_Investigation__c taskProductEvalInvestiRecord = getSetupPEtoPET();
        CMPL123CME__Investigation__c objInvestigation = taskProductEvalInvestiRecord.Investigation_Evaluation__r;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(objInvestigation);
        ADDS3LeveragedTaskListController testAccPlan = new ADDS3LeveragedTaskListController(sc);
        PageReference objPageReference = Page.ADDS3LeveragedTaskList;
        Test.setCurrentPage(objPageReference);
        ApexPages.currentPage().getParameters().put('id', objInvestigation.id);
        ApexPages.currentPage().getParameters().put('q', null);

        ADDS3LeveragedTaskListController obj = new ADDS3LeveragedTaskListController(sc);
        obj.disconnectedId = taskProductEvalInvestiRecord.Id+';'+'';
        obj.disconnectTasks();
        system.assertEquals(false, [SELECT Id FROM Task_Product_Evaluation_Investigation__c WHERE Id = :taskProductEvalInvestiRecord.Id].size() > 0);
        Test.stopTest();
    }

    /**
     * @Method       : testCloneAndClaimAction.
     * @Description  : To test the ADDS3LeveragedTaskListController class functionality.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @isTest
    public static void testCloneAndClaimAction(){
        Task_Product_Evaluation_Investigation__c taskProductEvalInvestiRecord = getSetupPEtoPET();
        CMPL123CME__Investigation__c objInvestigation = taskProductEvalInvestiRecord.Investigation_Evaluation__r;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(objInvestigation);
        ADDS3LeveragedTaskListController testAccPlan = new ADDS3LeveragedTaskListController(sc);
        PageReference objPageReference = Page.ADDS3LeveragedTaskList;
        Test.setCurrentPage(objPageReference);
        ApexPages.currentPage().getParameters().put('id', objInvestigation.id);
        ApexPages.currentPage().getParameters().put('q', null);
        ADDS3LeveragedTaskListController obj = new ADDS3LeveragedTaskListController(sc);
        obj.taskId = taskProductEvalInvestiRecord.Id+';'+'';
        Test.setCurrentPage(objPageReference);
        obj.cloneAndClaimAction();
        Test.stopTest();
        system.assertEquals(false, [SELECT Id FROM Task_Product_Evaluation_Investigation__c WHERE Id = :taskProductEvalInvestiRecord.Id].size() > 0);
    }
}