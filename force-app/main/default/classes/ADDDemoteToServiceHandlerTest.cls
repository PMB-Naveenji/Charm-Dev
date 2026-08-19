/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDDemoteToServiceHandlerTest.
* @Why   : ADDDemoteToServiceHandlerTest class for the ADDDemoteToServiceHandler class.
* @When  : 30-AUG-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-AUG-2018           Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                 03-JUN-2020           N/A                         Test class optimization.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 10-JUN-2020           N/A                         Updated code part, which is related to Users' insertion.
*                                                                         This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                         error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 05-JAN-2021           Upgrade Issue #41           Adjusted test setup data.
* --------------------------------------------------------------------------------------------------------------------------------------
* Larry Resnik          30-SEP-2021           CHaRM 2                     Fixed testSetup
* --------------------------------------------------------------------------------------------------------------------------------------
* Nicholas D Sutanto    24-FEB-2023           CHaRM R3.0, TWD Upgrade     Fixed testADDDemoteToServiceHandler by creating missing
                                                                          CMPL123__WF_Step__c test setup data.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDDemoteToServiceHandlerTest {
    private static final String NON_REPORTABILITY = 'Non-Reportable';
    private static final String ADVERSE_EVENT = 'Adverse Event';
    
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    * @Revision     : 30-Sep-2021 Larry Resnik: Made a Medical Evalutation and set it on the MDI and MIR to allow insertion
    */
    @testSetup static void setup () {
        
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true); 
        Profile aspenUserProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];
        //Create User
        User u = TestUtil.insertTestUser(
            aspenUserProfile.Id,
            'test@test.com',
            'testUser@test.com',
            'Tran10'
        );
        
        //Create Group 
        Group objGroup = (Group)TestDataFactory.createSobject(new Group(Name = 'Business Admin', Type = 'Regular'), true);
        
        //Create GroupMember
        GroupMember objGroupMember = (GroupMember)TestDataFactory.createSObject(new GroupMember(UserOrGroupId = u.Id, GroupId = objGroup.Id));
        
        insertData();
    }
    
    /*
    * @Method       : insertData.
    * @Description  : To insert test data asynchronously.
    * @Invoke       : From ADDDemoteToServiceHandlerTest test class.
    * @Return       : N/A.
    * @Params       : N/A.
    * @Revision     : 24-FEB-2023 Nicholas D Sutanto: Created Return, Translation Task, and Med Eval Workflow Steps
    *                 test data to fix testADDDemoteToServiceHandler().
    */
    @future
    public static void insertData () {
        //Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Overall_Reportable_Status__c = 'Not Reportable'
        ), true);
        
        //Create Workflow Status 
        CMPL123__WF_Status__c  statusClosed = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Closed-Voided'),true);
        CMPL123__WF_Status__c statusOpened = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'Opened'),true);
        // 24-FEB-2023 Danny: Added to create Translation Task and Medical Evaluation Workflow Steps test data.
        CMPL123__WF_Status__c statusInProcess = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'In Process'),true);
        CMPL123__WF_Status__c statusInProcessEvaluation = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'In Process-Evaluation'),true);
        
        //Create Workflow Action 
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Void'),true);
        
        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c  assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Task__c(Prod_Eval_Task)',
            CMPL123__Record_Type__c  = 'Prod_Eval_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        CMPL123__WF_Step__c prodEvalTaskWfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__WF_Rule__c = assessProdRule.Id,
            CMPL123__Action__c = action.Id,
            CMPL123__End_Status__c = statusClosed.Id,
            CMPL123__Start_Status__c = statusOpened.Id,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__Order__c = 1.0
        ), true);

        //Create Customer Response
        Customer_Response__c customerRes = (Customer_Response__c) TestDataFactory.createSObject(new Customer_Response__c(
            Event__c  = objComplaint.Id,
           CMPL123_WF_Status__c = 'Opened'),true);
        
        //Create Return 
        Return__c objReturn = (Return__c) TestDataFactory.createSObject(new Return__c(
            Ticket__c = objComplaint.Id,
          CMPL123_WF_Status__c = 'Opened'),true);
        
        // 24-FEB-2023 Danny: Create a Return Workflow Rule to create a Return Workflow Step.
        CMPL123__WF_Rule__c returnRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Return__c(RETURN_WORKFLOW)',
            CMPL123__Record_Type__c  = 'RETURN_WORKFLOW',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true
        ), true);
        
        CMPL123__WF_Step__c returnWfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__WF_Rule__c = returnRule.Id,
            CMPL123__Action__c = action.Id,
            CMPL123__End_Status__c = statusClosed.Id,
            CMPL123__Start_Status__c = statusOpened.Id,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__Order__c = 1.0
        ), true);
        
        //Translation_Task__c
        Translation_Task__c objTranslation = (Translation_Task__c)TestDataFactory.createSObject(new Translation_Task__c(
                                                Parent_Ticket__c =  objComplaint.Id,
                            CMPL123_WF_Status__c = 'Opened'),true);
        
        // 24-FEB-2023 Danny: Create a Translation Task Workflow Rule to create a Translation Task Workflow Step.
        CMPL123__WF_Rule__c translationRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
            CMPL123__Record_Type__c  = 'Translation_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true
        ), true);
        
        CMPL123__WF_Step__c translationWfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__WF_Rule__c = translationRule.Id,
            CMPL123__Action__c = action.Id,
            CMPL123__End_Status__c = statusClosed.Id,
            CMPL123__Start_Status__c = statusInProcess.Id,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__Order__c = 1.0
        ), true);

        //Create Country
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(), true);
        
        //Create Country Submission type
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30 Days', Calendar_Days__c = 30, Country__c = objCountry.Id), true);

        //Create Medical Evaluation
        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
          CMPL123CME__Complaint__c = objComplaint.Id, CMPL123_WF_Status__c = AspenConstants.STR_Regulatory, 
          Reportability__c = NON_REPORTABILITY, Reportability_Rationale__c = 'Just because',
          Reportability_Category__c = ADVERSE_EVENT), true);
        
        // 24-FEB-2023 Danny: Create a Medical Evaluation Workflow Rule to create a Medical Evaluation Workflow Step.
        CMPL123__WF_Rule__c medEvalRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)',
            CMPL123__Record_Type__c  = 'MEDICAL_EVALUATION_WORKFLOW',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true
        ), true);
        
        CMPL123__WF_Step__c medEvalWfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__WF_Rule__c = medEvalRule.Id,
            CMPL123__Action__c = action.Id,
            CMPL123__End_Status__c = statusClosed.Id,
            CMPL123__Start_Status__c = statusInProcessEvaluation.Id,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__Order__c = 1.0
        ), true);

        //Create EMDR
        CMPL123CME__EMDR__c objEmdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
          CMPL123CME__Complaint__c = objComplaint.Id), true);
        
        //Create MDI
        CMPL123CME__MEDDEV__c objMdi = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
          CMPL123CME__Complaint__c = objComplaint.Id, Medical_Evaluation__c = assessment.Id), true);
        
        //Create MIR
        CMPL123CME__EU_MIR__c objMir = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(new CMPL123CME__EU_MIR__c(
          CMPL123CME__Complaint__c = objComplaint.Id, MedicalEvaluation__c = assessment.Id), true);
    }
    
    /*
    * @Method       : testADDDemoteToServiceHandler.
    * @Description  : To test the ADDDemoteToServiceHandler class functionality..
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDDemoteToServiceHandler () {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name, RecordType.Name, 
                                        (SELECT Id, Name,CMPL123_WF_Status__c 
                                         FROM Customer_Responses__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
                                        (SELECT Id, Name, CMPL123_WF_Status__c FROM Returns__r 
                                         WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
                                        (SELECT Id, Investigation_Evaluation__r.Name, Ticket__c, Type__c, Investigation_Evaluation__r.CMPL123_WF_Status__c 
                                         FROM Ticket_Product_Evaluation_Investigation__r 
                                         WHERE (NOT Investigation_Evaluation__r.CMPL123_WF_Status__c LIKE 'Closed%') AND Type__c = 'Source'),
                                        (SELECT Id, Name, CMPL123_WF_Status__c FROM Translation_Tasks__r 
                                         WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
                                        (SELECT Id, Name, Registration_Ticket_Number__c, Ticket__c, Ticket__r.Registration_Ticket__c, 
                                         Request_Status__c FROM Meaningful_Data_Requests__r
                                         WHERE Request_Status__c = 'Opened')
                                        FROM CMPL123CME__Complaint__c WHERE  Business_Unit__c  = 'IA-CC' LIMIT 1];
        
        Test.startTest();
        //Create Task
        Task__c investigationEvaluationTaskRecord = (Task__c) TestDataFactory.createSObject(new Task__c(
            Related_Investigation_Evaluation__c = complaint.Ticket_Product_Evaluation_Investigation__r[0].Investigation_Evaluation__c), true);
        
        PageReference demotePage = Page.DemoteToService;
        demotePage.getParameters().put('id', complaint.id);
        Test.setCurrentPage(demotePage);
        ADDDemoteToServiceHandler pageController = new ADDDemoteToServiceHandler();
        
        pageController.demotionValue = 'Test Demote';

        //Lakshman-Start
        pageController.returnMessage = 'Valid';
        ADDDemoteToServiceHandler.isDemotedOrPromoted = false;
        pageController.cancelDemotion();
        pageController.updateDemotionValue();
        //Lakshman-End
        Test.stopTest();
        
        System.assertEquals('Test Demote', pageController.demotionValue);
    }
}