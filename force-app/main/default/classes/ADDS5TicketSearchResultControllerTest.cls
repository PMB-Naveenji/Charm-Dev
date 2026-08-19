/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS5TicketSearchResultControllerTest.
* @Why   : ADDS5TicketSearchResultControllerTest class for the ADDS5TicketSearchResultController class.
* @When  : 18-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                18-OCT-2018           Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                13-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid               03-Feb-2021           Fixed Error                 Updated Wf step to fix workflow Key Value Erorr 
* ----------------------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDS5TicketSearchResultControllerTest {
    /*
    * @Method       : setupData.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup
    static void setupData() {
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

        CMPL123__WF_Status__c status = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Opened'), true);
        
        CMPL123__WF_Status__c complaintComplete = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Complaint Complete'), true);

        CMPL123__WF_Status__c inProcessStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'In Process-Evaluation'), true);

        CMPL123__WF_Status__c regulatoryStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Regulatory'), true);

        CMPL123__WF_Status__c openStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Opened'), true);

        CMPL123__WF_Status__c statusClosed = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Closed-Voided'), true);

        CMPL123__WF_Status__c statusClosedDone = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Closed-Done'), true);

        CMPL123__WF_Status__c inProcessEvaluationStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'In Process-Evaluation'), true);

        CMPL123__WF_Action__c voidAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c (Name = 'Void'), true);

        CMPL123__WF_Action__c reopenToEvaluationAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c (Name = 'Reopen-Go to Evaluation'), true);
        CMPL123__WF_Action__c reopenAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c (Name = 'Reopen'), true);
        CMPL123__WF_Action__c closeAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c (Name = 'Close'), true);

        CMPL123__WF_Rule__c assessMedicalEvalRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)',
                        CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_WORKFLOW',
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
                CMPL123__Order__c = 1.0
                
            ), true);
        
        //@Juneid 01 Feb 2020, Added workflow step to resolve key value error
  CMPL123__WF_Step__c complaintWorkflowStep1 = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
            new CMPL123__WF_Step__c (
                CMPL123__End_Status__c = complaintComplete.Id,
                CMPL123__Start_Status__c = openStatus.Id,
                CMPL123__Action__c = reopenAction.Id,
                CMPL123__WF_Rule__c = assessComplaintRule.Id,
                CMPL123__Is_Start_Step__c = true,//changed true to false
                CMPL123__Order__c = 1.0
            ), true);

        CMPL123__WF_Step__c medicalEvaluationWorkflowStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c (
                        CMPL123__End_Status__c = inProcessEvaluationStatus.Id,
                        CMPL123__Start_Status__c = regulatoryStatus.Id,
                        CMPL123__Action__c = reopenToEvaluationAction.Id,
                        CMPL123__WF_Rule__c = assessMedicalEvalRule.Id,
                        CMPL123__Order__c = 1.0,
                        CMPL123__Is_Start_Step__c = true //@Juneid 3 Feb 2021,Added is Start step as True to resolve Key value Error
                   
                ), true);
    }

    /*
    * @Method       : ticketSearchRegulatoryCaseTest.
    * @Description  : To test the ADDS5TicketSearchResultController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void ticketSearchRegulatoryCaseTest() {
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
        ApexPages.standardController stdCon = new ApexPages.standardController(objTicketSearchResult);
        ADDS5TicketSearchResultController ticketSearchResultController = new ADDS5TicketSearchResultController(stdCon);
        ticketSearchResultController.processTicketSearchResults();
        Test.stopTest();

        System.assert('In Process-Evaluation' == [
                SELECT CMPL123_WF_Status__c
                FROM CMPL123CME__Questionnaire__c
                WHERE CMPL123CME__Complaint__c = :objTicketSearchResult.Ticket__c
        ].CMPL123_WF_Status__c);
    }

    /*
    * @Method       : ticketClosedQuestionnaireCaseTest.
    * @Description  : To test the ADDS5TicketSearchResultController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void ticketClosedQuestionnaireCaseTest() {
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
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
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
        ApexPages.standardController stdCon = new ApexPages.standardController(objTicketSearchResult);
        ADDS5TicketSearchResultController ticketSearchResultController = new ADDS5TicketSearchResultController(stdCon);
        ticketSearchResultController.processTicketSearchResults();
        Test.StopTest();

        System.assert('Opened' == [
                SELECT CMPL123_WF_Status__c
                FROM CMPL123CME__Questionnaire__c
                WHERE CMPL123CME__Complaint__c = :objTicketSearchResult.Ticket__c
        ].CMPL123_WF_Status__c);
    }

    /*
    * @Method       : getPageNumberListTest.
    * @Description  : To test the ADDS5TicketSearchResultController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void getPageNumberListTest() {
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

        ApexPages.currentPage().getParameters().put('TRID', objTicketReview.Id);
        ApexPages.standardController stdCon = new ApexPages.standardController(objTicketSearchResult);
        ADDS5TicketSearchResultController ticketSearchResultController = new ADDS5TicketSearchResultController(stdCon);
        ticketSearchResultController.toPageNumber = 10;
        ticketSearchResultController.setPgNumber();
        ticketSearchResultController.changePageSize();
        List<Integer> pageNumList = ticketSearchResultController.getPageNumberList();
        System.assert(pageNumList.size() > 0);
    }
}