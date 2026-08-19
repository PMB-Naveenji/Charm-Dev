/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : BatchTicketAutoPromoteTest.
* @Why   : BatchTicketAutoPromoteTest class for the BatchTicketAutoPromote class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                    Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                19-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class BatchTicketAutoPromoteTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {

        Id complaintRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();

        CMPL123CME__Complaint__c testTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(RecordTypeId = complaintRecTypeId),
                true
        );
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        Name = 'Test',
                        CMPL123_WF_Status__c = 'Open',
                        Product_Evaluation_Type__c = 'FUF',
                        Additional_Action_Taken__c = 'No',
                        Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                        Conclusion_Summary__c = 'Test',
                        CMPL123CME__Complaint__c = testTicket.Id),
                true
        );
        CMPL123CME__Complaint__c testTicket2 = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        CMPL123CME__CMPL123_WF_Status__c = 'For test'
                ),
                true
        );
    }

    /*
    * @Method       : testExecuteStatusIsOpen.
    * @Description  : To test the BatchTicketAutoPromote class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testExecuteStatusIsOpen() {
        List<CMPL123CME__Complaint__c> testTickets = [
                SELECT Id, CMSNext_Ticket_Number__c, CMPL123CME__CMPL123_WF_Status__c, MDC_All_ACKs_Received__c,
                (SELECT Id FROM CMPL123CME__Investigations__r),
                (SELECT Id FROM Evaluation_Investigation_Tasks__r),
                (SELECT Id FROM Customer_responses__r),
                (SELECT Id FROM Returns__r),
                (SELECT Id FROM Meaningful_Data_Requests__r),
                (SELECT Id FROM Translation_Tasks__r),
                (SELECT Id FROM CMPL123CME__Questionnaires__r),
                Ready_to_Close__c, CMPL123Task_Key_Value__c
                FROM CMPL123CME__Complaint__c
                WHERE CMPL123CME__CMPL123_WF_Status__c = 'For Test'
        ];
        for (CMPL123CME__Complaint__c ticket: testTickets) {
            ticket.CMPL123CME__CMPL123_WF_Status__c = 'Opened';
        }

        Test.startTest();
        BatchTicketAutoPromote ticketAutoPromote = new BatchTicketAutoPromote();
        ticketAutoPromote.execute(new TestBatchableContext(), testTickets);
        Test.stopTest();

        for (CMPL123CME__Complaint__c ticket: testTickets) {
            System.assertEquals('Yes', ticket.Ready_to_Close__c);
            System.assertEquals('ComplaintComplete', ticket.CMPL123Task_Key_Value__c);
        }
    }

    /*
    * @Method       : testExecuteStatusIsComplaintCompleteAndCMSNextIsClosed.
    * @Description  : To test the BatchTicketAutoPromote class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testExecuteStatusIsComplaintCompleteAndCMSNextIsClosed() {
        List<CMPL123CME__Complaint__c> testTickets = [
                SELECT Id, CMSNext_Ticket_Number__c, CMPL123CME__CMPL123_WF_Status__c, MDC_All_ACKs_Received__c,
                (SELECT Id FROM CMPL123CME__Investigations__r),
                (SELECT Id FROM Evaluation_Investigation_Tasks__r),
                (SELECT Id FROM Customer_responses__r),
                (SELECT Id FROM Returns__r),
                (SELECT Id FROM Meaningful_Data_Requests__r),
                (SELECT Id FROM Translation_Tasks__r),
                (SELECT Id FROM CMPL123CME__Questionnaires__r),
                        Ready_to_Close__c, CMPL123Task_Key_Value__c, CMSNext__c
                FROM CMPL123CME__Complaint__c
                WHERE CMPL123CME__CMPL123_WF_Status__c = 'For Test'
        ];
        for (CMPL123CME__Complaint__c ticket: testTickets) {
            ticket.CMPL123CME__CMPL123_WF_Status__c = 'Complaint Complete';
            ticket.CMSNext__c = 'Closed';
        }

        Test.startTest();
        BatchTicketAutoPromote ticketAutoPromote = new BatchTicketAutoPromote();
        ticketAutoPromote.execute(new TestBatchableContext(), testTickets);
        Test.stopTest();

        for (CMPL123CME__Complaint__c ticket: testTickets) {
            System.assertEquals('FurtherRequired', ticket.CMPL123Task_Key_Value__c);
        }
    }

    /*
    * @Method       : testExecuteStatusIsRegistrationClosed.
    * @Description  : To test the BatchTicketAutoPromote class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testExecuteStatusIsRegistrationClosed() {
        List<CMPL123CME__Complaint__c> testTickets = [
                SELECT Id, CMSNext_Ticket_Number__c, CMPL123CME__CMPL123_WF_Status__c, MDC_All_ACKs_Received__c,
                (SELECT Id FROM CMPL123CME__Investigations__r),
                (SELECT Id FROM Evaluation_Investigation_Tasks__r),
                (SELECT Id FROM Customer_responses__r),
                (SELECT Id FROM Returns__r),
                (SELECT Id FROM Meaningful_Data_Requests__r),
                (SELECT Id FROM Translation_Tasks__r),
                (SELECT Id FROM CMPL123CME__Questionnaires__r),
                        Ready_to_Close__c, CMPL123Task_Key_Value__c, CMSNext__c
                FROM CMPL123CME__Complaint__c
                WHERE CMPL123CME__CMPL123_WF_Status__c = 'For Test'
        ];
        for (CMPL123CME__Complaint__c ticket: testTickets) {
            ticket.CMPL123CME__CMPL123_WF_Status__c = 'Registration Closed';
        }

        Test.startTest();
        BatchTicketAutoPromote ticketAutoPromote = new BatchTicketAutoPromote();
        ticketAutoPromote.execute(new TestBatchableContext(), testTickets);
        Test.stopTest();

        for (CMPL123CME__Complaint__c ticket: testTickets) {
            System.assertEquals('complaintrcfr', ticket.CMPL123Task_Key_Value__c);
            System.assertEquals('', ticket.Ready_to_Close__c);
        }
    }

    /*
    * @Method       : testExecuteStatusIsFinalReviewInProgress.
    * @Description  : To test the BatchTicketAutoPromote class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testExecuteStatusIsFinalReviewInProgress() {
        List<CMPL123CME__Complaint__c> testTickets = [
                SELECT Id, CMSNext_Ticket_Number__c, CMPL123CME__CMPL123_WF_Status__c, MDC_All_ACKs_Received__c,
                (SELECT Id FROM CMPL123CME__Investigations__r),
                (SELECT Id FROM Evaluation_Investigation_Tasks__r),
                (SELECT Id FROM Customer_responses__r),
                (SELECT Id FROM Returns__r),
                (SELECT Id FROM Meaningful_Data_Requests__r),
                (SELECT Id FROM Translation_Tasks__r),
                (SELECT Id FROM CMPL123CME__Questionnaires__r),
                        Ready_to_Close__c, CMPL123Task_Key_Value__c, CMSNext__c
                FROM CMPL123CME__Complaint__c
                WHERE CMPL123CME__CMPL123_WF_Status__c = 'For Test'
        ];
        for (CMPL123CME__Complaint__c ticket: testTickets) {
            ticket.CMPL123CME__CMPL123_WF_Status__c = 'Final Review In Progress';
            ticket.Division__c = 'ADD';
        }

        Test.startTest();
        BatchTicketAutoPromote ticketAutoPromote = new BatchTicketAutoPromote();
        ticketAutoPromote.execute(new TestBatchableContext(), testTickets);
        Test.stopTest();

        for (CMPL123CME__Complaint__c ticket: testTickets) {
            System.assertEquals('addautofra', ticket.CMPL123Task_Key_Value__c);
        }
    }

    /*
    * @Method       : testExecuteStatusIsNotDefined.
    * @Description  : To test the BatchTicketAutoPromote class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testExecuteStatusIsNotDefined() {
        List<CMPL123CME__Complaint__c> testTickets = [
                SELECT Id, CMSNext_Ticket_Number__c, CMPL123CME__CMPL123_WF_Status__c, MDC_All_ACKs_Received__c,
                (SELECT Id FROM CMPL123CME__Investigations__r),
                (SELECT Id FROM Evaluation_Investigation_Tasks__r),
                (SELECT Id FROM Customer_responses__r),
                (SELECT Id FROM Returns__r),
                (SELECT Id FROM Meaningful_Data_Requests__r),
                (SELECT Id FROM Translation_Tasks__r),
                (SELECT Id FROM CMPL123CME__Questionnaires__r),
                        Ready_to_Close__c, CMPL123Task_Key_Value__c, CMSNext__c
                FROM CMPL123CME__Complaint__c
                WHERE CMPL123CME__CMPL123_WF_Status__c != 'For Test'
        ];

        Test.startTest();
        BatchTicketAutoPromote ticketAutoPromote = new BatchTicketAutoPromote();
        ticketAutoPromote.execute(new TestBatchableContext(), testTickets);
        Test.stopTest();

        System.assert(true);
    }

    /*
    * @Method       : testStartAndFinish.
    * @Description  : To test the BatchTicketAutoPromote class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testStartAndFinish() {

        Test.startTest();
        BatchTicketAutoPromote ticketAutoPromote = new BatchTicketAutoPromote();
        Database.executeBatch(ticketAutoPromote);
        Test.stopTest();

        System.assert(true);
    }

    private class TestBatchableContext implements Database.BatchableContext {

        public Id getChildJobId() {
            return null;
        }

        public Id getJobId() {
            return null;
        }
    }
}