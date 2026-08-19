/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : TicketUtilTest.
 * @Why   : TicketUtilTest class is test class for TicketUtil.
 * @When  : 15-OCT-2018.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer               Date                   Modification ID       Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                   15-OCT-2018            Work ID / Case ID     Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                   04-JUL-2020            N/A                   Added 'testPackageClass()' method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                   09-JUL-2020            Code Audit            Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Oober                   07-SEP-2020            Code Audit            Added assertEquals to afterInsertTicketTest,
 *                                                                      afterUpdateTicketTest, testPackageClass methods.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Juneid                  04-FEB-2021            Fixed Erorr           Updated Wf step to fix workflow Key Value Erorr 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik            06-JUL-2023            CHaRM R3.1            Fixed testPackageClass crash caused by TWD upgrade.
 * Moved that test method to Ticket_Product_Eval_InvestTriggerTest and renamed the method to ticketProductTriggerTest.
 * Not related to an IPDR. Set isParallel
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@IsTest(isParallel=true)
public class TicketUtilTest {
    private static final String OLDVAL_FOR_CLOSED_DONE_TICKET = 'Foo';
    private static final String OLDVAL_FOR_CLOSED_VOID_TICKET = 'Larry';
    private static final String OLDVAL_FOR_NOW_LOCKED_TICKET = 'Duke';
    private static final String OLDVAL_FOR_STILL_OPEN_TICKET = 'Lloyd';
    private static final Map<String, String> OLD_TO_NEW_VAL = new Map<String, String>{
        OLDVAL_FOR_CLOSED_DONE_TICKET => 'Bar',
        OLDVAL_FOR_CLOSED_VOID_TICKET => 'Resnik',
        OLDVAL_FOR_NOW_LOCKED_TICKET => 'Nukem',
        OLDVAL_FOR_STILL_OPEN_TICKET => 'Irving'
    };
    private static final String ERROR_POS = TestUtil.ERROR_POS;
    private static final String ERROR_NEG = TestUtil.ERROR_NEG;
    private static final String ERROR_SETUP = TestUtil.ERROR_SETUP;
    private static final String ERROR_POS_ASSIGNMENT = TestUtil.ERROR_POS +
        'Field was not assigned as expected';

    /**
     * @Method       : setupData.
     * @Description  : To insert test data.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @TestSetup
    static void setupData() {
        insert new ADD_App_Settings__c();

        //Create Workflow Start Status
        CMPL123__WF_Status__c startStatusVoidAndReopen = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
            new CMPL123__WF_Status__c(Name = AspenConstants.STR_Opened), false);

        //Create Workflow End Status
        CMPL123__WF_Status__c endStatusVoid = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
            new CMPL123__WF_Status__c(Name = AspenConstants.STR_WF_Closed_Voided), false);
        CMPL123__WF_Status__c endStatusReopen = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
            new CMPL123__WF_Status__c(Name = AspenConstants.STR_WF_Closed_Done), false);

        //Create Workflow Action
        CMPL123__WF_Action__c workflowActionVoid = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
            new CMPL123__WF_Action__c(Name = AspenConstants.STR_WF_Action_Void), false);
        CMPL123__WF_Action__c workflowActionReopen = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
            new CMPL123__WF_Action__c(Name = AspenConstants.STR_Reopen), false);

        //Create Workflow Rule
        CMPL123__WF_Rule__c workflowRuleVoid = (CMPL123__WF_Rule__c)
        TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Is_Active__c = true,
            Name = 'Inquiry Workflow',
            CMPL123__Record_Type__c = 'INQUIRY_WORKFLOW',
            CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c(INQUIRY_WORKFLOW)'
        ), false);
        CMPL123__WF_Rule__c workflowRuleReopen = (CMPL123__WF_Rule__c)
        TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            Name = 'Inquiry Workflow',
            CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c'
        ), false);
        insert new SObject[]{
            startStatusVoidAndReopen,
            endStatusVoid,
            endStatusReopen,
            workflowActionVoid,
            workflowActionReopen,
            workflowRuleVoid,
            workflowRuleReopen
        };

        insert new SObject[] {
            TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = workflowActionReopen.Id,
                CMPL123__WF_Rule__c = workflowRuleReopen.Id,
                CMPL123__Start_Status__c = startStatusVoidAndReopen.Id,
                CMPL123__Order__c = 1,
                CMPL123__End_Status__c = endStatusReopen.Id
            ) ,false),
            //@Juneid 4 feb 2021, Added is Start step as True to resolve Key value Error
            // R3.1, Larry: Changed Order from one to two since it would conflict
            // with the Reopen WorkFlow Action. Although it was bad data,
            // it was probably harmless.
            TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = workflowActionVoid.Id,
                CMPL123__WF_Rule__c = workflowRuleVoid.Id,
                CMPL123__Start_Status__c = startStatusVoidAndReopen.Id,
                CMPL123__Order__c = 2,
                CMPL123__End_Status__c = endStatusVoid.Id,
                CMPL123__Is_Start_Step__c = true
            ) ,false)
        };

        // Create Ticket
        Id ticketRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Inquiry).getRecordTypeId();
        CMPL123CME__Complaint__c objTicket = (CMPL123CME__Complaint__c)
        TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = ticketRTId,
            CMSNext__c = '',
            CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_Opened,
            Evaluator_Investigator_Pending_MDCs__c = false,
            FA_Quality_Assignee_Pending_MDCs__c = false,
            Med_Evaluator_Pending_MDCs__c = false,
            Prod_Eval_Assessor_Pending_MDCs__c = false,
            Quality_Non_Complaint_Pending_MDCs__c = false,
            CMPL123Rule_Key_Value__c = 'INQUIRY_WORKFLOW',
            Customer_Reply_Required__c = false
        ), true);

        // R3.1, Larry: Commented all record creation below since they seem unused
        //
        //Create Translation Task
        // Id txtTranslationRTId = Schema.SObjectType.Translation_Task__c
        //     .getRecordTypeInfosByName().get(AspenConstants.STR_Text_Translation).getRecordTypeId();
        // insert new Translation_Task__c(
        //     Parent_Ticket__c = objTicket.Id,
        //     CMPL123Rule_Key_Value__c = 'Translation_Task',
        //     CMPL123_WF_Status__c = AspenConstants.STR_In_Process,
        //     RecordTypeId = txtTranslationRTId
        // );

        // //Create Customer Response
        // // R3.1, Larry: WorkFlow Status was accidentally set to 'Open' instead of 'Opened'.
        // // Was probably a harmless typo?
        // insert new Customer_Response__c(
        //     Event__c = objTicket.Id,
        //     Customer_Reply__c = 'Test',
        //     CMPL123_WF_Status__c = AspenConstants.STR_Opened
        // );
    }

    /**
     * @Method       : afterInsertTicketTest.
     * @Description  : To cover updateTicket method in TicketUtil Class.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Moved WorkFlow Step creation into testSetup.
     * Commented this method after determining that the whole method was
     * not meaningful. It claims to cover a non-existent function and
     * is not directly related to TicketUtil. More robust testing for Tickets
     * can be found in ComplaintTriggerHandler_Test.
     */
    // @IsTest
    // static void afterInsertTicketTest() {
    //     // Create Ticket
    //     String ticketRTId = Schema.SObjectType.CMPL123CME__Complaint__c
    //         .getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
    //     CMPL123CME__Complaint__c objTicket = (CMPL123CME__Complaint__c)
    //     TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
    //         RecordTypeId = ticketRTId,
    //         CMSNext__c = 'Closed',
    //         CMPL123CME__CMPL123_WF_Status__c = 'Opened',
    //         Evaluator_Investigator_Pending_MDCs__c = false,
    //         FA_Quality_Assignee_Pending_MDCs__c = false,
    //         Med_Evaluator_Pending_MDCs__c = false,
    //         Prod_Eval_Assessor_Pending_MDCs__c = false,
    //         Quality_Non_Complaint_Pending_MDCs__c = false,
    //         CMPL123Rule_Key_Value__c = 'INQUIRY_WORKFLOW',
    //         CMSNext_Ticket_ID__c = '12345'
    //     ), true);

    //     CMPL123CME__Complaint__c objComplaint = [
    //         SELECT CMPL123CME__CMPL123_WF_Status__c
    //         FROM CMPL123CME__Complaint__c
    //         WHERE CMSNext_Ticket_ID__c = '12345'
    //         LIMIT 1];

    //     // R3.1, Larry: This is the only assert I found. What was this test method
    //     // actually testing? The docstring claims this tests a non-existent function...
    //     System.assertEquals(1,
    //         [SELECT COUNT() FROM CMPL123CME__Complaint__c WHERE CMSNext_Ticket_ID__c = '12345'],
    //         'Ticket should be created');
    // }

    /**
     * @Method       : afterUpdateTicketTest.
     * @Description  : To cover updateTicket method in TicketUtil Class.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @IsTest
    static void afterUpdateTicketTest() {
        CMPL123CME__Complaint__c objTicket = [
            SELECT Id, Follow_up_Status__c, CMSNext__c, CMPL123CME__CMPL123_WF_Status__c
            FROM CMPL123CME__Complaint__c
            WHERE CMSNext__c = ''
            LIMIT 1];
        // R3.1, Larry: Added this assert after determining what this test method
        // was attempting, and verifying that ComplaintTriggerHandler_Test does
        // not do this type of test
        Assert.areNotEqual(AspenConstants.STR_WF_Closed_Voided,
            objTicket.CMPL123CME__CMPL123_WF_Status__c,
            ERROR_SETUP + 'The Ticket must start out in a non-voided WorkFlow Status ' +
            'to perform this test');

        //Update Complaint Followup Status
        objTicket.Follow_up_Status__c = 'Further Review';
        objTicket.CMSNext__c = AspenConstants.CMSNEXT_STATUS_VOID;
        TestDataFactory.updateSObject(objTicket);

        objTicket = [
            SELECT CMPL123CME__CMPL123_WF_Status__c, CMPL123Task_Key_Value__c, Follow_up_Status__c
            FROM CMPL123CME__Complaint__c
            WHERE Follow_up_Status__c = 'Further Review'
            LIMIT 1];

        // R3.1, Larry: Now verifies behavior in ComplaintTriggerHandler's beforeEventHandler
        Assert.areEqual(AspenConstants.STR_WF_Closed_Voided,
            objTicket.CMPL123CME__CMPL123_WF_Status__c,
            ERROR_POS + 'The Ticket should have progressed to Closed-Voided ' +
            'because the CMSNext status was set to "Void"');
        // R3.1, Larry: This assert was checking the old record instead of the
        // newly queried one. Thankfully, it still met the assert criteria.
        Assert.areEqual('Further Review', objTicket.Follow_up_Status__c,
            'Ticket Follow up Status should be updated to Further Review');
    }

    /**
     * Pos/neg test(s) for isFirstRun
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testIsFirstRun() {
        Assert.isTrue(TicketUtil.isFirstRun(), ERROR_POS + 'Flag should be true when first accessed');
        Assert.isFalse(TicketUtil.isFirstRun(), ERROR_POS + 'Flag should be false on the second access');
        Assert.isFalse(TicketUtil.isFirstRun(), ERROR_POS + 'Flag should be false on all subsequent accesses');
    }

    /**
     * Pos/neg test(s) for processAutomatedHistoryRecord
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testProcessAutomatedHistoryRecord() {
        final String ERROR_NEG_GOOD_WITHOUT_ID = ERROR_NEG + 'Field should be assigned even with an invalid Id';
        Id fakeId = TestUtil.getFakeId(Schema.CMPL123CME__Complaint__c.SObjectType);
        CMPL123__WF_Step__c wfStep = [
            SELECT Id, CMPL123__Action__r.Name, CMPL123__Start_Status__r.Name,
            CMPL123__End_Status__r.Name
            FROM CMPL123__WF_Step__c
            WHERE CMPL123__Order__c = 1
            LIMIT 1];

        Test.startTest();
        // Pos test
        CMPL123__WF_History__c wfHistory = TicketUtil.processAutomatedHistoryRecord(fakeId, wfStep);
        Assert.areEqual(fakeId, wfHistory.CMPL123__Related_Id__c, ERROR_POS_ASSIGNMENT);
        Assert.areEqual(wfStep.Id, wfHistory.CMPL123__Workflow_Step__c, ERROR_POS_ASSIGNMENT);
        Assert.areEqual(wfStep.CMPL123__Action__r.Name, wfHistory.CMPL123__Action__c, ERROR_POS_ASSIGNMENT);
        Assert.areEqual(wfStep.CMPL123__End_Status__r.Name, wfHistory.CMPL123__Status__c, ERROR_POS_ASSIGNMENT);

        // Neg test such that the Id is null
        wfHistory = TicketUtil.processAutomatedHistoryRecord(null, wfStep);
        Assert.areEqual(null, wfHistory.CMPL123__Related_Id__c, ERROR_NEG_GOOD_WITHOUT_ID);
        Assert.areEqual(wfStep.Id, wfHistory.CMPL123__Workflow_Step__c, ERROR_NEG_GOOD_WITHOUT_ID);
        Assert.areEqual(wfStep.CMPL123__Action__r.Name, wfHistory.CMPL123__Action__c, ERROR_NEG_GOOD_WITHOUT_ID);
        Assert.areEqual(wfStep.CMPL123__End_Status__r.Name, wfHistory.CMPL123__Status__c, ERROR_NEG_GOOD_WITHOUT_ID);

        // Neg test such that the WorkFlow Step is null
        try {
            TicketUtil.processAutomatedHistoryRecord(fakeId, null);
            Assert.fail(ERROR_NEG + 'Should crash if the passed WorkFlow Step is null');
        } catch (NullPointerException ex) {
            // Getting here is expected
        }
        Test.stopTest();
    }

    /**
     * Pos/neg test(s) for populateWFFields
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testPopulateWFFields() {
        final String ERROR_NEG_GOOD_WITHOUT_WF = ERROR_NEG + 'Field should be assigned even without WorkFlow info';
        final String WF_STATUS = AspenConstants.STR_WF_Opened;
        final String WF_ACTION = AspenConstants.STR_WF_Action_Void;
        Id myId = Userinfo.getUserId();

        // Pos test for the Ticket SObject
        CMPL123CME__Complaint__c ticket = new CMPL123CME__Complaint__c(
            Id = TestUtil.getFakeId(Schema.CMPL123CME__Complaint__c.SObjectType)
        );
        ticket = (CMPL123CME__Complaint__c) TicketUtil.populateWFFields(ticket, WF_STATUS, WF_ACTION);
        Assert.areEqual(WF_STATUS, ticket.CMPL123CME__CMPL123_WF_Status__c, ERROR_POS_ASSIGNMENT);
        Assert.areEqual(WF_ACTION, ticket.CMPL123CME__CMPL123_WF_Action__c, ERROR_POS_ASSIGNMENT);
        Assert.isNotNull(ticket.CMPL123CME__CMPL123_WF_Action_Performed_On__c, ERROR_POS_ASSIGNMENT);
        Assert.areEqual(myId, ticket.CMPL123CME__CMPL123_WF_Action_Performed_By__c, ERROR_POS_ASSIGNMENT);

        // Pos test for a non-Ticket SObject
        Customer_Response__c resp = new Customer_Response__c(
            Id = TestUtil.getFakeId(Schema.Customer_Response__c.SObjectType)
        );
        resp = (Customer_Response__c) TicketUtil.populateWFFields(resp, WF_STATUS, WF_ACTION);
        Assert.areEqual(WF_STATUS, resp.CMPL123_WF_Status__c, ERROR_POS_ASSIGNMENT);
        Assert.areEqual(WF_ACTION, resp.CMPL123_WF_Action__c, ERROR_POS_ASSIGNMENT);
        Assert.isNotNull(resp.CMPL123_WF_Action_Performed_On__c, ERROR_POS_ASSIGNMENT);
        Assert.areEqual(myId, resp.CMPL123_WF_Action_Performed_By__c, ERROR_POS_ASSIGNMENT);

        // Neg test such that WorkFlow strings are not provided
        resp = new Customer_Response__c(
            Id = TestUtil.getFakeId(Schema.Customer_Response__c.SObjectType)
        );
        resp = (Customer_Response__c) TicketUtil.populateWFFields(resp, null, null);
        Assert.isNull(resp.CMPL123_WF_Status__c, ERROR_NEG_GOOD_WITHOUT_WF);
        Assert.isNull(resp.CMPL123_WF_Action__c, ERROR_NEG_GOOD_WITHOUT_WF);
        Assert.isNotNull(resp.CMPL123_WF_Action_Performed_On__c, ERROR_NEG_GOOD_WITHOUT_WF);
        Assert.areEqual(myId, resp.CMPL123_WF_Action_Performed_By__c, ERROR_NEG_GOOD_WITHOUT_WF);

        // Neg test such that a null Id is passed
        try {
            TicketUtil.populateWFFields(null, WF_STATUS, WF_ACTION);
            Assert.fail(ERROR_NEG + 'Should crash when passed a null object');
        } catch (NullPointerException ex) {
            // Getting here is good
        }

        // Neg test such that a non-audited SObject is passed
        CMPL123CME__Complaint_Code__c complaintCode = new CMPL123CME__Complaint_Code__c(
            Id = TestUtil.getFakeId(Schema.CMPL123CME__Complaint_Code__c.SObjectType)
        );
        try {
            TicketUtil.populateWFFields(complaintCode, WF_STATUS, WF_ACTION);
            Assert.fail(ERROR_NEG + 'Should crash when passed a non-audited object');
        } catch (SObjectException ex) {
            // Getting here is good
        }
    }

    /**
     * Pos/neg test(s) for addTrace
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testAddTrace() {
        Assert.isFalse(TicketUtil.isLimitEmailSent, ERROR_SETUP +
            'Too much work in data setup. We already mocked sending the Limits email. ' +
            'Optimize testSetup so that it does not run addTrace on its own');

        Test.startTest();
        TicketUtil.addTrace('TicketUtilTest.testAddTrace');
        Assert.isFalse(TicketUtil.isLimitEmailSent, ERROR_POS +
            'Should NOT send the email when Limits are still good');

        TicketUtil.isForceEmail = true;
        TicketUtil.addTrace('TicketUtilTest.testAddTrace');
        Assert.isTrue(TicketUtil.isLimitEmailSent, ERROR_POS +
            'SHOULD send the email when the testing-only flag is active');
        Test.stopTest();
    }

    /**
     * Pos test(s) for sendLimits
     * 
     * Neg test(s) do not seem possible?
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testSendLimits() {
        Assert.isFalse(TicketUtil.isLimitEmailSent, ERROR_SETUP +
            'Too much work in data setup. We already mocked sending the Limits email. ' +
            'Optimize testSetup so that it does not run addTrace on its own');
        String subjLine = 'Testing';

        Test.startTest();
        Integer numEmailsBefore = Limits.getEmailInvocations();
        TicketUtil.sendLimits(subjLine);
        Integer numEmailsAfter = Limits.getEmailInvocations();
        Test.stopTest();
        
        Assert.isTrue(TicketUtil.isLimitEmailSent, ERROR_POS +
            'Should have mocked sending the email');
        // R3.1, Larry: Made this assert, but it does not work because the Email's
        // Send-To addresses are not set.
        // Assert.areEqual(numEmailsBefore + 1, numEmailsAfter, ERROR_POS +
        //     'Should have mocked sending an email');
    }

    /**
     * Factory for validateRecordLockOnClosedStatus that makes a Ticket for Trigger.oldMap
     * @author R3.1, Larry
     */
    private static CMPL123CME__Complaint__c makeOldTicket(String wfStatusOld, String oldVal) {
        return new CMPL123CME__Complaint__c(
            Id = TestUtil.getFakeId(CMPL123CME__Complaint__c.SObjectType),
            // The WorkFlow Status is considered locked if it has not changed from
            // Closed-Done or Closed-Voided during this trigger context
            CMPL123CME__CMPL123_WF_Status__c = wfStatusOld,
            // Give an old value to a locked field
            Reporter_Name__c = oldVal,
            // Give an old value to an unlocked field
            Likely_Cause__c = AspenConstants.STR_Yes
        );
    }

    /**
     * Factory for validateRecordLockOnClosedStatus all of Trigger.oldMap
     * @author R3.1, Larry
     */
    private static Map<Id, CMPL123CME__Complaint__c> makeOldTicketMap() {
        final List<String> WF_STATUSES = new List<String>{
            AspenConstants.STR_Closed_Done,
            AspenConstants.STR_Closed_Voided,
            AspenConstants.STR_WF_Opened,
            AspenConstants.STR_WF_Opened
        };
        final List<String> OLD_VALS = new List<String>(OLD_TO_NEW_VAL.keySet());

        Map<Id, CMPL123CME__Complaint__c> oldMap = new Map<Id, CMPL123CME__Complaint__c>();
        for (Integer i = 0; i < OLD_VALS.size(); i++) {
            CMPL123CME__Complaint__c ticket = makeOldTicket(WF_STATUSES[i], OLD_VALS[i]);
            oldMap.put(ticket.Id, ticket);
        }
        return oldMap;
    }

    /**
     * Factory for validateRecordLockOnClosedStatus that makes a Ticket for Trigger.new
     * @author R3.1, Larry
     */
    private static CMPL123CME__Complaint__c makeNewTicket(String wfStatusNew,
        CMPL123CME__Complaint__c ticketOld, Boolean isReplaceVal)
    {
        String newVal = ticketOld.Reporter_Name__c;
        if (isReplaceVal) {
            newVal = OLD_TO_NEW_VAL.get(ticketOld.Reporter_Name__c);
        }
        return new CMPL123CME__Complaint__c(
            Id = ticketOld.Id,
            // The WorkFlow Status is considered locked if it has not changed from
            // Closed-Done or Closed-Voided during this trigger context
            CMPL123CME__CMPL123_WF_Status__c = wfStatusNew,
            // Give a new value to a locked field
            Reporter_Name__c = newVal,
            // Give a new value to an unlocked field
            Likely_Cause__c = AspenConstants.STR_No
        );
    }

    /**
     * Verifies that methods for validateRecordLockOnClosedStatus are setting up good data
     * @author R3.1, Larry
     */
    @isTest
    static void testFieldSetUsageInTesters() {
        Boolean isAlwaysEditableFieldFound = false;
        Boolean isRestrictedFieldFound = false;
        for (Schema.FieldSetMember member : SObjectType.CMPL123CME__Complaint__c
            .FieldSets.Fields_editable_on_Closed_Complaint.getFields())
        {
            String fieldName = member.getFieldPath();
            if (fieldName == 'Likely_Cause__c') {
                isAlwaysEditableFieldFound = true;
            } else if (fieldName == 'Reporter_Name__c') {
                isRestrictedFieldFound = true;
            }
        }
        Assert.isTrue(isAlwaysEditableFieldFound,
            ERROR_SETUP + 'The field we are testing is NOT part of the Field Set. ' +
            'Please change all test methods to use a field that CAN be edited in locked records'
        );
        Assert.isFalse(isRestrictedFieldFound,
            ERROR_SETUP + 'This field we are testing IS part of the Field Set. ' +
            'Please change all test methods to use a field that can NOT be edited in locked records'
        );
    }

    /**
     * Pos test(s) for validateRecordLockOnClosedStatus such that fields CAN be edited
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testValidateRecordLockOnClosedStatusForEditable() {
        Map<Id, CMPL123CME__Complaint__c> oldTicketMap = makeOldTicketMap();
        List<CMPL123CME__Complaint__c> newTicketList = new List<CMPL123CME__Complaint__c>();
        for (CMPL123CME__Complaint__c ticketOld : oldTicketMap.values()) {
            String wfStatusNew = ticketOld.CMPL123CME__CMPL123_WF_Status__c;
            if (ticketOld.Reporter_Name__c == OLDVAL_FOR_NOW_LOCKED_TICKET) {
                // Move this Ticket to a locked status.
                // All other Tickets retain their WorkFlow Status.
                // It should NOT consider the Ticket to be locked YET.
                wfStatusNew = AspenConstants.STR_Closed_Voided;
            }
            newTicketList.add(makeNewTicket(wfStatusNew, ticketOld, false));
        }
        Assert.areEqual(oldTicketMap.size(), newTicketList.size(),
            ERROR_SETUP + 'Did not make Trigger.new correctly');
        Assert.areEqual(OLD_TO_NEW_VAL.size(), newTicketList.size(),
            ERROR_SETUP + 'Did not make a record for each set of boilerplate info');

        Test.startTest();
        TicketUtil.validateRecordLockOnClosedStatus(newTicketList, oldTicketMap);
        Test.stopTest();

        // Loop over Trigger.new instead of Trigger.oldMap because that gets the errors
        Integer hitMask = 0;
        for (CMPL123CME__Complaint__c ticket : newTicketList) {
            // Remember, we did NOT change the Reporter Name
            if (ticket.Reporter_Name__c == OLDVAL_FOR_NOW_LOCKED_TICKET) {
                hitMask = hitMask | 1;
                Assert.isFalse(ticket.hasErrors(), ERROR_POS +
                    'Ticket is JUST NOW locked, so any edit should be allowed');
            } else if (ticket.Reporter_Name__c == OLDVAL_FOR_STILL_OPEN_TICKET) {
                hitMask = hitMask | 2;
                Assert.isFalse(ticket.hasErrors(), ERROR_POS +
                    'Ticket is NOT locked, so any edit should be allowed');
            } else {
                hitMask = hitMask | 4;
                Assert.isFalse(ticket.hasErrors(), ERROR_POS + 
                    'Ticket IS locked, but ALL field changes were for fields defined in ' +
                    'the editable-when-locked field set. WorkFlow Status is ' +
                    ticket.CMPL123CME__CMPL123_WF_Status__c);
            }
        }
        Assert.areEqual(7, hitMask, ERROR_SETUP + 'Did not test all scenarios');
    }

    /**
     * Pos test(s) for validateRecordLockOnClosedStatus such that fields can NOT be edited
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testValidateRecordLockOnClosedStatusForNotEditable() {
        Map<Id, CMPL123CME__Complaint__c> oldTicketMap = makeOldTicketMap();
        List<CMPL123CME__Complaint__c> newTicketList = new List<CMPL123CME__Complaint__c>();
        for (CMPL123CME__Complaint__c ticketOld : oldTicketMap.values()) {
            String wfStatusNew = ticketOld.CMPL123CME__CMPL123_WF_Status__c;
            if (ticketOld.Reporter_Name__c == OLDVAL_FOR_NOW_LOCKED_TICKET) {
                // Move this Ticket to a locked status.
                // All other Tickets retain their WorkFlow Status.
                // It should NOT consider the Ticket to be locked YET.
                wfStatusNew = AspenConstants.STR_Closed_Voided;
            }
            newTicketList.add(makeNewTicket(wfStatusNew, ticketOld, true));
        }
        Assert.areEqual(oldTicketMap.size(), newTicketList.size(),
            ERROR_SETUP + 'Did not make Trigger.new correctly');
        Assert.areEqual(OLD_TO_NEW_VAL.size(), newTicketList.size(),
            ERROR_SETUP + 'Did not make a record for each set of boilerplate info');

        Test.startTest();
        TicketUtil.validateRecordLockOnClosedStatus(newTicketList, oldTicketMap);
        Test.stopTest();

        // Loop over Trigger.new instead of Trigger.oldMap because that gets the errors
        Integer hitMask = 0;
        final String NEWVAL_FOR_NOW_LOCKED_TICKET = OLD_TO_NEW_VAL.get(OLDVAL_FOR_NOW_LOCKED_TICKET);
        final String NEWVAL_FOR_STILL_OPEN_TICKET = OLD_TO_NEW_VAL.get(OLDVAL_FOR_STILL_OPEN_TICKET);
        for (CMPL123CME__Complaint__c ticket : newTicketList) {
            // Remember, we DID change the Reporter Name
            if (ticket.Reporter_Name__c == NEWVAL_FOR_NOW_LOCKED_TICKET) {
                hitMask = hitMask | 1;
                Assert.isFalse(ticket.hasErrors(), ERROR_POS +
                    'Ticket is JUST NOW locked, so any edit should be allowed');
            } else if (ticket.Reporter_Name__c == NEWVAL_FOR_STILL_OPEN_TICKET) {
                hitMask = hitMask | 2;
                Assert.isFalse(ticket.hasErrors(), ERROR_POS +
                    'Ticket is NOT locked, so any edit should be allowed');
            } else {
                hitMask = hitMask | 4;
                Assert.isTrue(ticket.hasErrors(), ERROR_POS + 
                    'Ticket IS locked, so it should fail when applying a field change ' +
                    'when that field is NOT IN the editable-when-locked field set. ' +
                    'WorkFlow Status is ' + ticket.CMPL123CME__CMPL123_WF_Status__c);
            }
        }
        Assert.areEqual(7, hitMask, ERROR_SETUP + 'Did not test all scenarios');
    }

    /**
     * Neg test(s) for validateRecordLockOnClosedStatus where parameters are bad
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testValidateRecordLockOnClosedStatusNeg() {
        Id ticketId = TestUtil.getFakeId(CMPL123CME__Complaint__c.SObjectType);
        Map<Id, CMPL123CME__Complaint__c> oldTicketMap = new Map<Id, CMPL123CME__Complaint__c>{
            ticketId => new CMPL123CME__Complaint__c(
                Id = ticketId,
                CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided
            )
        };
        List<CMPL123CME__Complaint__c> newTicketList = new List<CMPL123CME__Complaint__c>{
            new CMPL123CME__Complaint__c(
                Id = ticketId,
                CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided
            )
        };

        try {
            TicketUtil.validateRecordLockOnClosedStatus(
                new List<CMPL123CME__Complaint__c>(),
                new Map<Id, CMPL123CME__Complaint__c>());
        } catch(Exception ex) {
            Assert.fail(ERROR_NEG + 'Should not crash when all passed parameters are empty');
        }

        try {
            TicketUtil.validateRecordLockOnClosedStatus(null, oldTicketMap);
            Assert.fail(ERROR_NEG + 'Should crash since Trigger.new is null');
        } catch(Exception ex) {
            // Getting here is good
        }

        try {
            TicketUtil.validateRecordLockOnClosedStatus(null, null);
            Assert.fail(ERROR_NEG + 'Should crash since all parameters are null');
        } catch(Exception ex) {
            // Getting here is good
        }

        newTicketList = new List<CMPL123CME__Complaint__c>{
            new CMPL123CME__Complaint__c()
        };
        try {
            TicketUtil.validateRecordLockOnClosedStatus(newTicketList, null);
        } catch(Exception ex) {
            Assert.fail(ERROR_NEG + 'Did not expect a crash, even though the inputs were bad');
        }

        newTicketList = new List<CMPL123CME__Complaint__c>{
            new CMPL123CME__Complaint__c(
                Id = ticketId,
                CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided
            )
        };
        try {
            TicketUtil.validateRecordLockOnClosedStatus(newTicketList, null);
            // R3.1, Larry: Made this assertion which only applied to the old code.
            // The current code aborts early when Trigger.oldMap is null.
            //
            // Assert.fail(ERROR_NEG + 'Should crash since Trigger.oldMap is null. ' +
            //     'This is similar to calling the function from an insert context');
        } catch(Exception ex) {
            // Getting here is good
            Assert.isFalse(newTicketList[0].hasErrors(), ERROR_NEG +
                'Should not have processed the Ticket in the first place');
        }
    }
}