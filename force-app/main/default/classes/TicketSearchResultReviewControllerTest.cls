@isTest
class TicketSearchResultReviewControllerTest {
    @testSetup
    static void setupData() {
        insert new ADD_App_Settings__c(Restrict_Validation_Rules__c = true);

        CMPL123__WF_Status__c regulatoryStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = AspenConstants.STR_Regulatory), true);

        CMPL123__WF_Status__c openStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Opened'), true);

        CMPL123__WF_Status__c statusClosedDone = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Closed-Done'), true);

        CMPL123__WF_Status__c inProcessEvaluationStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = AspenConstants.STR_In_Process_Evaluation), true);

        CMPL123__WF_Action__c reopenToEvaluationAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c (Name = 'Go to In Process-Evaluation'), true);

        CMPL123__WF_Action__c reopenAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c (Name = 'Reopen'), true);

        CMPL123__WF_Rule__c assessMedicalEvalRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)',
                        CMPL123__Record_Type__c = AspenConstants.STR_MEDICAL_EVALUATION_WORKFLOW,
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true
                ), true);

        CMPL123__WF_Rule__c assessComplaintRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c(COMPLAINT_WORKFLOW)',
                        CMPL123__Record_Type__c = 'COMPLAINT_WORKFLOW',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true
                ), true);

        CMPL123__WF_Step__c complaintWorkflowStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c (
                        CMPL123__End_Status__c = openStatus.Id,
                        CMPL123__Start_Status__c = statusClosedDone.Id,
                        CMPL123__Action__c = reopenAction.Id,
                        CMPL123__WF_Rule__c = assessComplaintRule.Id,
                        CMPL123__Order__c = 1.0,
                        CMPL123__Is_Start_Step__c = true //@Juneid 2 feb 2021,Added is Start step as True to resolve Key value Error
                ), true);

        CMPL123__WF_Step__c medicalEvaluationWorkflowReopenToEvaluationStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c (
                        CMPL123__End_Status__c = inProcessEvaluationStatus.Id,
                        CMPL123__Start_Status__c = regulatoryStatus.Id,
                        CMPL123__Action__c = reopenToEvaluationAction.Id,
                        CMPL123__WF_Rule__c = assessMedicalEvalRule.Id,
                        CMPL123__Order__c = 1.0,
                        CMPL123__Is_Start_Step__c = false // @Juneid 2 feb 2021,Added is Start step as false to resolve Key value Error
                ), true);

        CMPL123__WF_Step__c medicalEvaluationWorkflowReopenStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c (
                        CMPL123__End_Status__c = inProcessEvaluationStatus.Id,
                        CMPL123__Start_Status__c = statusClosedDone.Id,
                        CMPL123__Action__c = reopenAction.Id,
                        CMPL123__WF_Rule__c = assessMedicalEvalRule.Id,
                        CMPL123__Order__c = 1.0,
                      CMPL123__Is_Start_Step__c = true //@Juneid 2 feb 2021,Added is Start step as True to resolve Key value Error
                ), true);
    }

    @isTest
    static void ticketSearchRegulatoryCaseTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c objTickt = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Business_Unit__c = 'Hematology',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Customer_Reply_Required__c = false,
                        Follow_up_Status__c = 'Further Review'
                ), true);
        String assmntRTId1 = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c openAssesmnt = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = assmntRTId1,
                        CMPL123CME__Complaint__c = objTickt.Id,
                        Reportability_Rationale__c = '1234',
                        Reportability__c = 'Reportable',
                        Reportability_Category__c = 'RCML',
                        CMPL123Rule_Key_Value__c = 'MEDICAL_EVALUATION_WORKFLOW',
                        CMPL123_WF_Status__c = 'Regulatory',
                        Evaluator__c = UserInfo.getUserId(),
                        Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                        Targeted_Assessment_No_of_Days__c = 12
                ), true);
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        CMPL123CME__EMDR__c objEmdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        Medical_Evaluation__c = openAssesmnt.Id
                ), true);
        Ticket_Review__c objTicketReview = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        Status__c = 'Active',
                        Search_Frequency__c = 'Two Weeks (14 days)',
                        Pending_Batch_Jobs__c = '7070j00000OO6fAAAT',
                        Field_Action_Number__c = 'Test',
                        Medical_Assignee_Name__c = UserInfo.getUserId()
                ), true);
        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                new Ticket_Search_Result__c(
                        Ticket_Review__c = objTicketReview.Id,
                        Unique_Identifier__c = objTicketReview.Id + '-' + objTickt.Id,
                        Ticket_Review_Status__c = 'Related with Malfunction',
                        Ticket__c = objTickt.Id
                ), true);

        Test.startTest();
        ApexPages.currentPage().getParameters().put('TRID', objTicketReview.Id);
        TicketSearchResultsReviewController ticketSearchResultController = new TicketSearchResultsReviewController();
        ticketSearchResultController.strJSONticketSearchResults = JSON.serialize(new List<Ticket_Search_Result__c>{objTicketSearchResult});
        ticketSearchResultController.processTicketSearchResults();
        ticketSearchResultController.getticketReviewStatusPicklists();
        Test.stopTest();

        System.assert('In Process-Evaluation' == [
                SELECT CMPL123_WF_Status__c
                FROM CMPL123CME__Questionnaire__c
                WHERE CMPL123CME__Complaint__c = :objTicketSearchResult.Ticket__c
        ].CMPL123_WF_Status__c);
    }

    @isTest
    static void ticketSearchClosedCaseTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c objTickt = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Business_Unit__c = 'Hematology',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Customer_Reply_Required__c = false,
                        Follow_up_Status__c = 'Further Review'
                ), true);
        String assmntRTId1 = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c closedAssesmnt = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = assmntRTId1,
                        CMPL123CME__Complaint__c = objTickt.Id,
                        Reportability_Rationale__c = '1234',
                        Reportability__c = 'Reportable',
                        Reportability_Category__c = 'RCML',
                        CMPL123Rule_Key_Value__c = AspenConstants.STR_MEDICAL_EVALUATION_WORKFLOW ,
                        CMPL123_WF_Status__c = 'Closed-Done',
                        Evaluator__c = UserInfo.getUserId(),
                        Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                        Targeted_Assessment_No_of_Days__c = 12
                ), true);
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        Ticket_Review__c objTicketReview = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        Status__c = 'Active',
                        Search_Frequency__c = 'Two Weeks (14 days)',
                        Field_Action_Number__c = 'Test',
                        Medical_Assignee_Name__c = UserInfo.getUserId()
                ), true);
        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                new Ticket_Search_Result__c(
                        Ticket_Review__c = objTicketReview.Id,
                        Unique_Identifier__c = objTicketReview.Id + '-' + objTickt.Id,
                        Ticket_Review_Status__c = 'Related with Malfunction',
                        Ticket__c = objTickt.Id
                ), true);
        Test.startTest();

        ApexPages.currentPage().getParameters().put('TRID', objTicketReview.Id);
        TicketSearchResultsReviewController ticketSearchResultController = new TicketSearchResultsReviewController();
        ticketSearchResultController.strJSONticketSearchResults = JSON.serialize(new List<Ticket_Search_Result__c>{objTicketSearchResult});
        ticketSearchResultController.processTicketSearchResults();
        Test.StopTest();

        System.assert('In Process-Evaluation' == [
                SELECT CMPL123_WF_Status__c
                FROM CMPL123CME__Questionnaire__c
                WHERE CMPL123CME__Complaint__c = :objTicketSearchResult.Ticket__c
        ].CMPL123_WF_Status__c);
    }

    @IsTest
    public static void getTicketSearchResultsTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c objTickt = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Business_Unit__c = 'Hematology',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Customer_Reply_Required__c = false,
                        Follow_up_Status__c = 'Further Review'
                ), true);
        Ticket_Review__c ticketReviewInactive = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        Status__c = 'Inactive',
                        Search_Frequency__c = 'Two Weeks (14 days)',
                        Field_Action_Number__c = 'Test',
                        Medical_Assignee_Name__c = UserInfo.getUserId()
                ), true);
        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                new Ticket_Search_Result__c(
                        Ticket_Review__c = ticketReviewInactive.Id,
                        Unique_Identifier__c = ticketReviewInactive.Id + '-' + objTickt.Id,
                        Ticket_Review_Status__c = 'Related with Malfunction',
                        Ticket__c = objTickt.Id
                ), true);

        Test.startTest();
        // Execute logic for inactive Ticket_Review__c
        ApexPages.currentPage().getParameters().put('TRID', ticketReviewInactive.Id);
        TicketSearchResultsReviewController controller = new TicketSearchResultsReviewController();
        Boolean isCorrect = false;
        for (ApexPages.Message msg : ApexPages.getMessages()) {
            if (msg.getDetail().contains(Label.Ticket_Review_Cannot_Display_Search_Results)) {
                isCorrect = true;
            }
        }
        System.assert(isCorrect);

        // Create Ticket_Review__c withot Ticket_Search_Result__c and test behaviour
        Ticket_Review__c ticketReviewWithoutSearches = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        FA_CAPA_Short_Description__c = 'test',
                        CAPA_Number__c = 'test',
                        Search_Frequency__c = 'Two Weeks (14 days)',
                        Division__c = 'ADD',
                        Status__c = 'Active',
                        Medical_Assignee_Name__c = Userinfo.getUserId()
                ), true);
        ApexPages.currentPage().getParameters().put('TRID', ticketReviewWithoutSearches.Id);
        controller = new TicketSearchResultsReviewController();
        isCorrect = false;
        for (ApexPages.Message msg : ApexPages.getMessages()) {
            if (msg.getDetail().contains(Label.Ticket_Review_No_Search_Results)) {
                isCorrect = true;
            }
        }
        System.assert(isCorrect);
        controller.getticketReviewStatusPicklists();
        Test.stopTest();
    }

    @IsTest
    public static void ticketClosedTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c objTickt = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Business_Unit__c = 'Hematology',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMSNext__c = 'Open',
                        CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done',
                        Likely_Cause__c = 'Yes',
                        Customer_Reply_Required__c = false,
                        Follow_up_Status__c = 'Further Review'
                ), true);

        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        Ticket_Review__c objTicketReview = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        Status__c = 'Active',
                        Search_Frequency__c = 'Two Weeks (14 days)',
                        Field_Action_Number__c = 'Test',
                        Medical_Assignee_Name__c = UserInfo.getUserId()
                ), true);
        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                new Ticket_Search_Result__c(
                        Ticket_Review__c = objTicketReview.Id,
                        Unique_Identifier__c = objTicketReview.Id + '-' + objTickt.Id,
                        Ticket_Review_Status__c = 'Related with Malfunction',
                        Ticket__c = objTickt.Id
                ), true);
        Test.startTest();

        ApexPages.currentPage().getParameters().put('TRID', objTicketReview.Id);
        TicketSearchResultsReviewController ticketSearchResultController = new TicketSearchResultsReviewController();
        ticketSearchResultController.strJSONticketSearchResults = JSON.serialize(new List<Ticket_Search_Result__c>{objTicketSearchResult});
        ticketSearchResultController.processTicketSearchResults();
        Test.StopTest();

        System.assert('Opened' == [
                SELECT CMPL123CME__CMPL123_WF_Status__c
                FROM CMPL123CME__Complaint__c
                WHERE Id = : objTickt.Id
        ].CMPL123CME__CMPL123_WF_Status__c);
    }
}