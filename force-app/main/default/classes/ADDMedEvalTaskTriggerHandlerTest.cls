/**
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDMedEvalTaskTriggerHandlerTest.
 * @Why   : ADDMedEvalTaskTriggerHandlerTest class for the ADDMedEvalTaskTriggerHandler class.
 * @When  : N/A.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                   Modification ID                   Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                 05-AUG-2019            Work ID / Case ID                 Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                 05-JAN-2021            TWD Upgrade issue                 Added method testWfLogic().
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                 28-JAN-2021            Test failure                      Fixed test failure related to dates conversion.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                 01-FEB-2021            Test failure                      Fixed test failure related to wrong status in the
 *                                                                                test data.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          11-JUL-2023            CHaRM R3.1                        Fixed crash with method called "test". Made testSetup
 * --------------------------------------------------------------------------------------------------------------------------------------
 */
@IsTest
private class ADDMedEvalTaskTriggerHandlerTest {
    private static final String CMSNEXT_NUM_ONE = '16216098372' + String.valueOf(Math.random()).remove('.');
    private static final String CMSNEXT_NUM_TWO = '26216098372' + String.valueOf(Math.random()).remove('.');
    private static final String CMSNEXT_NUM_THREE = '36216098372' + String.valueOf(Math.random()).remove('.');

    @TestSetup
    static void makeData(){
        // R3.1, Larry: Made a Ticket for a MedEval
        Id complaintRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get(AspenConstants.STR_Complaint)
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaintRecord = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c (
                RecordTypeId = complaintRecTypeId,
                CMSNext_Ticket_Number__c = CMSNEXT_NUM_ONE,
                CMSNext_Ticket_ID__c = '4975764'
            ),
            true
        );
        // R3.1, Larry: Made a MedEval for MedEvalTasks
        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(
                CMPL123CME__Complaint__c = complaintRecord.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_Regulatory,
                Reportability__c = AspenConstants.REPORTABILITY_NO,
                Reportability_Category__c = 'RCML',
                Reportability_Rationale__c = 'Because there is a monkey in the garage'
            ),
            true
        );
    }

    @IsTest
    private static void test() {
        CMPL123CME__Questionnaire__c medEval = [
            SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Id medTaskRecTypeId = Schema.SObjectType.Medical_Evaluation_Task__c
            .getRecordTypeInfosByName().get('RCML Review Task').getRecordTypeId();
        // R3.1, Larry: Set Medical_Evaluation__c since it is required on insert due to Set_MedEval_only_on_Init
        Medical_Evaluation_Task__c medTask = new Medical_Evaluation_Task__c(
                Reportable_Confirmed_Malfunction_Descrip__c = 'Test',
                Assignee_Name__c = UserInfo.getUserID(),
                RecordTypeId = medTaskRecTypeId,
                Medical_Evaluation__c = medEval.Id,
                No_RCML_Addition_Rationale__c = 'Test information'
        );

        Test.startTest();
        UpdateParentUtility.flag = false;
        insert medTask;
        update medTask;
        delete medTask;
        ADDMedEvalTaskTriggerHandler handler = new ADDMedEvalTaskTriggerHandler();
        handler.afterDelete();
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Medical_Evaluation_Task__c]);
    }

    /**
     * @Method       : testWfLogic.
     * @Description  : To test the logic removed from WF and added to apex.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @IsTest
    private static void testWfLogic() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId,
            CMSNext_Ticket_Number__c = CMSNEXT_NUM_TWO
        ), true);
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c
            .getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaint.Id,
            CMPL123_WF_Status__c  = AspenConstants.STR_Opened
        ), true);
        //Test failure fix BEGIN
        Date todaysDate = datetime.now().dateGMT();
        //Test failure fix END
        Id medTaskRecTypeId = Schema.SObjectType.Medical_Evaluation_Task__c
            .getRecordTypeInfosByName().get('RCML Review Task').getRecordTypeId();
        Medical_Evaluation_Task__c medTask = (Medical_Evaluation_Task__c )TestDataFactory.createSObject(new Medical_Evaluation_Task__c(
            Reportable_Confirmed_Malfunction_Descrip__c = 'Test',
            Assignee_Name__c = UserInfo.getUserID(),
            RecordTypeId = medTaskRecTypeId,
            Medical_Evaluation__c = questionnaire.Id,
            CMPL123_WF_Status__c = AspenConstants.STR_In_Process,
            Issue_Summary__c = 'test',
            CMPL123_WF_Action_Performed_On__c = todaysDate,
            CMPL123_WF_Action_Performed_By__c = UserInfo.getUserID()
        ), true);
        //WF: Autoset Assigned Date field
        System.assertEquals(todaysDate, [SELECT Assigned_Date__c FROM Medical_Evaluation_Task__c WHERE Id=: medTask.Id].Assigned_Date__c);
        //WF: Autoset Registration Number
        System.assertEquals(complaint.CMSNext_Ticket_Number__c + '(Complaint)',
            [SELECT Registration_Number__c FROM Medical_Evaluation_Task__c WHERE Id =: medTask.Id].Registration_Number__c);
        //WF: Autoset Registration Number
        String serviceRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Service).getRecordTypeId();
        CMPL123CME__Complaint__c service = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Complaint_Demotion_rationale__c = '',
            Demotion_rationale__c = '',
            Complaint_Demoted_By__c = UserInfo.getName(),
            Complaint_Demotion_Date__c = System.Now(),
            Division__c  = AspenConstants.DIVISION_DIAGNOSTICS,
            pRE_Status__c  = AspenConstants.STR_Yes,
            Country_of_origin__c = 'INDIA',
            RecordTypeId = serviceRTId,
            Service_Type__c = 'Planned',
            Business_Unit__c  = 'IA-CC',
            Ticket_Type__c = AspenConstants.STR_Service,
            Is_Product_Evaluation_Investigation_chil__c = false,
            CMPL123CME__CMPL123_WF_Status__c  = AspenConstants.STR_Opened,
            CMSNext_Ticket_Number__c = CMSNEXT_NUM_THREE,
            CMPL123Rule_Key_Value__c = 'SERVICE_WORKFLOW',
            Trending_issue_Bucket__c = 'ProdEvel',
            Receipt_Date__c = System.today() - 5
        ), true);
        questionnaire.CMPL123CME__Complaint__c = service.Id;
        update questionnaire;
        medTask.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
        medTask.Add_Confirmed_Malfunction_to_RCML_List__c = AspenConstants.STR_Yes;
        medTask.Issue_Summary__c = 'Test';
        medTask.RCML_CFT_Members__c = 'TEST';
        medTask.RCML_CFT_Review_Date__c = date.today();
        update medTask;
        System.assertEquals(service.CMSNext_Ticket_Number__c + '(Planned Service)',
            [SELECT Registration_Number__c FROM Medical_Evaluation_Task__c WHERE Id =: medTask.Id].Registration_Number__c);
        //WF: Autoset Task Item Completion Date
        System.assertNotEquals(null, [SELECT Task_Item_Completion_Date__c FROM Medical_Evaluation_Task__c WHERE Id =: medTask.Id].Task_Item_Completion_Date__c);
        //WF: Workflow - Reopen
        medTask.CMPL123_WF_Action__c = AspenConstants.STR_Reopen;
        update medTask;
        System.assertEquals(todaysDate, [SELECT Reopened_On__c FROM Medical_Evaluation_Task__c WHERE Id =: medTask.Id].Reopened_On__c);
        //WF: Workflow - Submit
        medTask.CMPL123_WF_Action__c = AspenConstants.STR_WF_ACTION_SUBMIT;
        update medTask;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Submitted_By__c FROM Medical_Evaluation_Task__c WHERE Id =: medTask.Id].Submitted_By__c);
    }
}