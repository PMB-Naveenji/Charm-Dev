/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : RestrictLeveragedTaskDeletionTriggerTest.
 * @Why   : Test class to handle different scenarios from RestrictLeveragedTaskDeletion.
 * @When  : 07-SEP-2018.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer              Date                   Modification ID                 Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                  07-SEP-2018            Work ID / Case ID               Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *   DSkak                10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
 *                                                                                 This change designed to prevent a 'DUPLICATE_USERNAME' error during
 *                                                                                 deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           07-JUL-2023            R3.1                            Fixed testADDReturnFormMasterTriggerHandler crash. Not related to an IPDR
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest
public class RestrictLeveragedTaskDeletionTriggerTest {
    private static final String EMAIL_ONE = 'test@test.com';
    private static final String EMAIL_TWO = 'two@two.com';

    /**
     * Builds data for all test methods
     * @author R3.1, Larry
     */
    @testSetup
    static void makeData(){
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get(AspenConstants.STR_Complaint)
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
            pRE_Status__c = AspenConstants.STR_Yes,
            Country_of_origin__c = 'USA',
            RecordTypeId = complaintRTId,
            Business_Unit__c = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c = 'Opened:Appending Regulatory Correspondence',
            CMSNext_Ticket_Number__c = '12345'),
            true
        );
        Customer_Response__c customerResponse = (Customer_Response__c) TestDataFactory.createSObject(
            new Customer_Response__c(
                Event__c = complaint.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_Opened),
            true
        );

        // R3.1, Larry: User creation now leverages makeTestUser.
        // Unconsequentially, the email and last name of user2 has changed.
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = :AspenConstants.PROFILE_STD].Id;
        User user1 = TestUtil.makeTestUser(aspenUserProfileId, EMAIL_ONE, EMAIL_ONE, 'PEI3', false);
        User user2 = TestUtil.makeTestUser(aspenUserProfileId, EMAIL_TWO, EMAIL_TWO, 'PEA2,PEA4', false);

        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
            new CMPL123CME__Investigation__c(
                Name = 'Test',
                CMPL123_WF_Status__c = 'Assess:In Process-Evaluation:In Process-Investigation:Conclude',
                Product_Evaluation_Type__c = 'FUF',
                Additional_Action_Taken__c = AspenConstants.STR_No,
                Approver__c = user2.Id,
                Assessor__c = user2.Id,
                Conclusion_Disposition__c = AspenConstants.STR_80068_Non_Medical_Device_NO_Product_Problem,
                Conclusion_Summary__c = 'Test',
                Evaluator_Investigator__c = user1.Id,
                CMPL123CME__Complaint__c = complaint.Id),
            true
        );
        Task__c task = (Task__c) TestDataFactory.createSObject(
            new Task__c(
                Related_Investigation_Evaluation__c = investigation.Id,
                CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
                Source_Leveraged__c = 'Leveraged',
                CMPL123_WF_Status__c = 'Opened:In Process'),
            true
        );
    }

    /**
     * @Method       : testADDReturnFormMasterTriggerHandler.
     * @Description  : To test RestrictLeveragedTaskDeletion functionality.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Fixed test failure caused by crash upon delete operation
     */
    @isTest
    public static void testADDReturnFormMasterTriggerHandler(){
        // R3.1, Larry: Moved all record creation into a new testSetup method
        Task__c task = [SELECT Id FROM Task__c LIMIT 1];
        // R3.1, Larry: Added try-catch because deletion throws a validation error now
        try {
            delete task;
            Assert.fail('Expected a crash because this user should be unable to delete ProdEval Tasks');
        } catch (DmlException ex) {
            String msg = ex.getMessage();
            Assert.isTrue(msg.contains('delete'), 'Error should be related to the delete operation. ' +
                'Did a different error get thrown? Message: ' + msg);
        }
        // R3.1, Larry: Changed the assert to find one record instead of zero. Added a failure message
        Assert.areEqual(1, [SELECT COUNT() FROM Task__c WHERE Id = :task.Id],
            'Should fail to delete the ProdEval Task');
    }
}