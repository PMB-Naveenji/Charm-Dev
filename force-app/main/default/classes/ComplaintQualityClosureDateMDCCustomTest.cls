/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ComplaintQualityClosureDateMDCCustomTest class.
 * @Why   : To cover setDefaults method in ComplaintQualityClosureDateMDCCustom class.
 * @When  : 26-DEC-2018.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                   Modification ID                 Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                 26-DEC-2018            Work ID / Case ID               Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                 10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion. This
 *                                                                              change designed to prevent a 'DUPLICATE_USERNAME' error during
 *                                                                              deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                 20-AUG-2020            Code Audit                      Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          29-JUN-2023            CHaRM R3.1, Defect 299          Made thorough tests for setDefaults
 * --------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
private class ComplaintQualityClosureDateMDCCustomTest {
    // External Id for CMSNext Ticket Number. Use these to pinpoint Tickets made in testSetup
    private static final String CMSNEXT_NUM_ONE = '123456';
    private static final String CMSNEXT_NUM_TWO = '222222';
    private static final String CMSNEXT_NUM_THREE = '333333';
    private static final String CMSNEXT_NUM_FOUR = '444444';
    private static final String CMSNEXT_NO_PRODEVAL = '555555';
    private static final String ERROR_POS = TestUtil.ERROR_POS;
    private static final String ERROR_NEG = TestUtil.ERROR_NEG;
    private static final String ERROR_SETUP = TestUtil.ERROR_SETUP;
    private static final String ERROR_POS_THIS_CASE =
        ERROR_POS + 'This case should have succeeded';
    private static final String ERROR_POS_ANY_CASE =
        ERROR_POS + 'If at least one case succeeds, "any case" should succeed';
    private static final String ERROR_SETUP_NOT_CASE_ONE =
        ERROR_SETUP + 'Only the first case should have Ticket as Overall Reportable. ' +
        'The test data cannot check the other cases like this';

    /**
     * @Method       : setupData.
     * @Description  : To insert test data.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @testSetup static void setupData() {

        //Create User
        Id profileId = [SELECT Id FROM Profile WHERE Name = :AspenConstants.PROFILE_STD].Id;
        User aspenUser1 = TestUtil.insertTestUser(
            profileId,
            'test@test.com',
            'test@test.com',
            'Tran10'
        );

        User aspenUser2 = TestUtil.insertTestUser(
            profileId,
            'test2@test.com',
            'test2@test.com',
            'Tran10'
        );


        // Create Tickets.
        // The suffixes on their names represent the case it is testing from
        // ComplaintQualityClosureDateMDCCustom.
        CMPL123CME__Complaint__c ticketOne =
        (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Ticket_Type__c = AspenConstants.STR_Complaint,
                Customer_Reply_Required__c = true,
                CMSNext_Ticket_Number__c = CMSNEXT_NUM_ONE
        ), false);
        CMPL123CME__Complaint__c ticketTwo = ticketOne.clone();
        ticketTwo.CMSNext_Ticket_Number__c = CMSNEXT_NUM_TWO;
        CMPL123CME__Complaint__c ticketThree = ticketOne.clone();
        ticketThree.CMSNext_Ticket_Number__c = CMSNEXT_NUM_THREE;
        CMPL123CME__Complaint__c ticketFour = ticketOne.clone();
        ticketFour.CMSNext_Ticket_Number__c = CMSNEXT_NUM_FOUR;
        CMPL123CME__Complaint__c ticketNoProdEval = ticketOne.clone();
        ticketNoProdEval.CMSNext_Ticket_Number__c = CMSNEXT_NO_PRODEVAL;
        insert new CMPL123CME__Complaint__c[]{
            ticketOne, ticketTwo, ticketThree, ticketFour, ticketNoProdEval
        };

        // Create MedEvals.
        // For Ticket #1, there is just one MedEval and it is Reportable,
        // so Ticket #1 will have Overall_Reportable_Status as true.
        // For all other tickets, the MedEvals are not Reportable or they are voided,
        // so those tickets will have Overall_Reportable_Status as false.
        CMPL123CME__Questionnaire__c medEvalOne =
        (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            CMPL123CME__Complaint__c = ticketOne.Id,
            Reportability_Rationale__c = 'It is Reportable',
            Reportability_Category__c = 'RCML',
            CMPL123_WF_Status__c = AspenConstants.STR_Regulatory,
            Reportability__c = AspenConstants.REPORTABILITY_YES
        ), false);
        CMPL123CME__Questionnaire__c medEvalTwo = medEvalOne.clone();
        medEvalTwo.Reportability__c = AspenConstants.REPORTABILITY_NO;
        medEvalTwo.CMPL123CME__Complaint__c = ticketTwo.Id;
        CMPL123CME__Questionnaire__c medEvalThree = medEvalOne.clone();
        medEvalThree.Reportability__c = AspenConstants.REPORTABILITY_NO;
        medEvalThree.CMPL123CME__Complaint__c = ticketThree.Id;
        CMPL123CME__Questionnaire__c medEvalFour = medEvalOne.clone();
        medEvalFour.Reportability__c = AspenConstants.REPORTABILITY_YES;
        medEvalFour.CMPL123CME__Complaint__c = ticketFour.Id;

        // Create ProdEvals.
        // For Ticket #1, the number of non-Closed-Done ProdEvals does not matter.
        // For other tickets in positive tests, all ProdEvals must be Closed-Done.
        // The main method only makes sense if we assume there is exactly one Closed-Done ProdEval on a Ticket.
        CMPL123CME__Investigation__c prodEvalOne =
        (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
            Name = 'Prod Eval',
            CMPL123CME__Complaint__c = ticketOne.Id,
            Assessor__c = aspenUser2.Id,
            Approver__c = aspenUser1.Id,
            Evaluator_Investigator__c = aspenUser2.Id,
            Additional_Action_Taken__c = AspenConstants.STR_No,
            Conclusion_Summary__c = 'malfunction',
            Product_Evaluation_Type__c = 'Lot to lot variability',
            Conclusion_Disposition__c = AspenConstants.STR_80067_Deficiency_Malfunction
        ), false);
        CMPL123CME__Investigation__c prodEvalTwo = prodEvalOne.clone();
        prodEvalTwo.CMPL123CME__Complaint__c = ticketTwo.Id;
        CMPL123CME__Investigation__c prodEvalThree = prodEvalOne.clone();
        prodEvalThree.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
        prodEvalThree.CMPL123CME__Complaint__c = ticketThree.Id;
        CMPL123CME__Investigation__c prodEvalFour = prodEvalOne.clone();
        prodEvalFour.CMPL123CME__Complaint__c = ticketFour.Id;
        insert new SObject[]{
            medEvalOne, medEvalTwo, medEvalThree, medEvalFour,
            prodEvalOne, prodEvalTwo, prodEvalThree, prodEvalFour
        };

        // We need these ProdEvals to be Closed-Done, but inserting them
        // as Closed-Done causes a "Record Locked" validation error... Do an update instead
        prodEvalTwo.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
        prodEvalThree.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
        prodEvalFour.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
        // For the fourth Ticket, mimic the scenario where it is not reportable
        // because a MedEval was recently voided
        ticketFour.Overall_Reportable_Status__c = AspenConstants.REPORTABILITY_NO;
        update new SObject[] {
            prodEvalTwo, prodEvalThree, prodEvalFour, ticketFour
        };
    }

    /**
     * Helper fn that queries for the Ticket and its children
     * @author R3.1, Larry
     */
    private static CMPL123CME__Complaint__c getSetupTicket(String cmsNextNum) {
        return [
            SELECT Id, Complaint_Quality_Closure_Date__c,
            // Fetches the ProdEval children
            (
                SELECT Id,
                CMPL123_WF_Status__c,
                // The four fields below are "cumulative fields"
                Product_Lot_Numbers__c,
                Product_List_Numbers__c,
                Products__c,
                Has_Product_Lot_Child__c,
                Conclusion_Disposition__c
                FROM CMPL123CME__Investigations__r
                // With the proper WorkFlow records inserted into the org,
                // ProdEvals actually start in the 'Assess' WF_Status instead
                // of null. The "system-generated ProdEval" will have a null
                // WF_Status because of this missing piece of testSetup data.
                WHERE CMPL123_WF_Status__c != null
            ),
            // Fetches the Product-Ticket children
            (
                SELECT Id,
                Product__c,
                // The three fields below contribute to ProdEval "cumulative fields"
                Batch_Lot_Serial__c,
                Product_List_Number__c,
                Product_Name__c
                FROM Products_Events__r
                WHERE Likely_Cause__c = :AspenConstants.STR_Yes
                AND Delete_Flag__c = false
                AND Product__c != null
            ),
            // Fetches the MedEval children
            (
                SELECT Id, Follow_Up_Awareness_Date__c,
                Conclusion_Disposition_Flag__c, CMPL123_WF_Status__c,
                Reportability__c, LastModifiedDate,
                CMPL123CME__Key_value__c
                FROM CMPL123CME__Questionnaires__r
            )
            FROM CMPL123CME__Complaint__c
            WHERE CMSNext_Ticket_Number__c = :cmsNextNum
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    /**
     * Neg test for setDefaults such that it is passed a null parameter
     * @author R3.1, Larry
     */
    @isTest
    static void testSetDefaultsNegNoInput() {
        final String ERROR_NO_INPUT = ERROR_NEG + 'Should fail all cases when the input is invalid';

        Test.startTest();
        ComplaintQualityClosureDateMDCCustom.setDefaults(null);
        Test.stopTest();

        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseOne, ERROR_NO_INPUT);
        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseTwo, ERROR_NO_INPUT);
        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseThree, ERROR_NO_INPUT);
        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseFour, ERROR_NO_INPUT);
        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingAnyCase, ERROR_NO_INPUT);
    }

    /**
     * Pos test for setDefaults such that the first case succeeds.
     * 
     * This scenario succeeds when Ticket's Overall Reportable Status = 'Reportable'.
     * Due to this test's simplicity, ALL other scenarios would account for
     * the negative version of this test.
     * @revision R3.1, Larry: Accesses the isMeetingCase* variables instead of other vars which became localized.
     * Renamed from setDefaultsTest to better describe what it actually tests.
     */
    @isTest
    static void testSetDefaultsPosCaseOne() {
        CMPL123CME__Complaint__c ticket = getSetupTicket(CMSNEXT_NUM_ONE);

        Test.startTest();
        ComplaintQualityClosureDateMDCCustom.setDefaults(ticket.Id);
        Test.stopTest();

        // Cases 2, 3, 4 should fail, but that will not matter.
        // We care about "Any Case" because that makes the MDC.
        Assert.isTrue(ComplaintQualityClosureDateMDCCustom.isMeetingCaseOne, ERROR_POS_THIS_CASE);
        Assert.isTrue(ComplaintQualityClosureDateMDCCustom.isMeetingAnyCase, ERROR_POS_ANY_CASE);
    }

    /**
     * Pos test for setDefaults such that the second case succeeds.
     * 
     * This scenario succeeds when all of the following are true:
     * 1) The Ticket's Overall Reportable Status is NOT 'Reportable'.
     * 2) The one ProdEval's Conclusion Disposition is 80067.
     * 3) The one ProdEval is Closed-Done.
     * 4) All non-voided MedEvals are NOT Reportability.
     *     -) #3 meets the criteria if ALL MedEvals are voided.
     * @author R3.1, Larry
     */
    @isTest
    static void testSetDefaultsPosCaseTwo() {
        CMPL123CME__Complaint__c ticket = getSetupTicket(CMSNEXT_NUM_TWO);

        Test.startTest();
        ComplaintQualityClosureDateMDCCustom.setDefaults(ticket.Id);
        Test.stopTest();

        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseOne, ERROR_SETUP_NOT_CASE_ONE);
        // Cases 3, 4 should fail, but that will not matter.
        // We care about "Any Case" because that makes the MDC.
        Assert.isTrue(ComplaintQualityClosureDateMDCCustom.isMeetingCaseTwo, ERROR_POS_THIS_CASE);
        Assert.isTrue(ComplaintQualityClosureDateMDCCustom.isMeetingAnyCase, ERROR_POS_ANY_CASE);
    }

    /**
     * Pos test for setDefaults such that the third case succeeds.
     * 
     * This scenario succeeds when all of the following are true:
     * 1) The Ticket's Overall Reportable Status is NOT 'Reportable'.
     * 2) The one ProdEval's Conclusion Disposition is 80064.
     * 3) The one ProdEval is Closed-Done.
     * 4) All non-voided MedEvals are NOT Reportability.
     *     -) #3 meets the criteria if ALL MedEvals are voided.
     * @author R3.1, Larry
     */
    @isTest
    static void testSetDefaultsPosCaseThree() {
        CMPL123CME__Complaint__c ticket = getSetupTicket(CMSNEXT_NUM_THREE);

        Test.startTest();
        ComplaintQualityClosureDateMDCCustom.setDefaults(ticket.Id);
        Test.stopTest();

        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseOne, ERROR_SETUP_NOT_CASE_ONE);
        // Cases 2, 4 should fail, but that will not matter.
        // We care about "Any Case" because that makes the MDC.
        Assert.isTrue(ComplaintQualityClosureDateMDCCustom.isMeetingCaseThree, ERROR_POS_THIS_CASE);
        Assert.isTrue(ComplaintQualityClosureDateMDCCustom.isMeetingAnyCase, ERROR_POS_ANY_CASE);
    }

    /**
     * Pos test for setDefaults such that the second case succeeds.
     * 
     * This scenario succeeds when all of the following are true:
     * 1) The Ticket's Overall Reportable Status is NOT 'Reportable'.
     * 2) The one ProdEval's Conclusion Disposition is 80067.
     * 3) The one ProdEval is Closed-Done.
     * 4) All non-voided MedEvals are NOT Reportability.
     *     -) #3 meets the criteria if ALL MedEvals are voided.
     * @author R3.1, Larry
     */
    @isTest
    static void testSetDefaultsPosCaseFour() {
        CMPL123CME__Complaint__c ticket = getSetupTicket(CMSNEXT_NUM_FOUR);

        Test.startTest();
        ComplaintQualityClosureDateMDCCustom.setDefaults(ticket.Id);
        Test.stopTest();

        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseOne, ERROR_SETUP_NOT_CASE_ONE);
        // Cases 2, 3 should fail, but that will not matter.
        // We care about "Any Case" because that makes the MDC.
        Assert.isTrue(ComplaintQualityClosureDateMDCCustom.isMeetingCaseFour, ERROR_POS_THIS_CASE);
        Assert.isTrue(ComplaintQualityClosureDateMDCCustom.isMeetingAnyCase, ERROR_POS_ANY_CASE);
    }

    /**
     * Neg test for setDefaults such that there are no applicable ProdEvals.
     * 
     * The first case should fail because the Ticket's Overall Reportable Status is NOT 'Reportable'.
     * The other three cases should fail because the Ticket does not have any Closed-Done ProdEvals.
     * @author R3.1, Larry
     */
    @isTest
    static void testSetDefaultsNegNoProdEval() {
        final String ERROR_NO_PRODEVAL = ERROR_NEG +
            'There should not be any applicable ProdEvals on this Ticket, ' +
            'so cases 2, 3, and 4 should fail';
        CMPL123CME__Complaint__c ticket = getSetupTicket(CMSNEXT_NO_PRODEVAL);

        Test.startTest();
        ComplaintQualityClosureDateMDCCustom.setDefaults(ticket.Id);
        Test.stopTest();

        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseOne, ERROR_SETUP_NOT_CASE_ONE);
        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseTwo, ERROR_NO_PRODEVAL);
        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseThree, ERROR_NO_PRODEVAL);
        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingCaseFour, ERROR_NO_PRODEVAL);
        Assert.isFalse(ComplaintQualityClosureDateMDCCustom.isMeetingAnyCase, ERROR_NO_PRODEVAL);
    }
}