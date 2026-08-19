/*
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : DemoteToServiceWorkflowProcess_Test.
* @Why   : Unit tests for DemoteToServiceWorkflowProcess, ADDDemoteToServiceHandler.
* @When  : 15-OCT-2018.
* @Where : N/A.
* ---------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* ---------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Admin                   15-OCT-2018                                   Created.
* ---------------------------------------------------------------------------------------------------------------------------------------
* RSitc                   14-APR-2020            Defect #66             Additional coverage.
* ---------------------------------------------------------------------------------------------------------------------------------------
* rslob                   10-JUN-2020            N/A                    Updated code part, which is related to Users' insertion. This
*                                                                       change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                       deployment to Production environment.
* ---------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020           Code Audit              Removed commented code. Formatting.
* ---------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   05-JAN-2021            Upgrade Issue #41      Adjusted test setup data.
---------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class DemoteToServiceWorkflowProcess_Test {
    
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup static void setup(){
        //Create User
        User usr = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'test',
            Email = 'test@test.com',
            Username = 'test@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10'
        ), true);

        // Create Application Setup data
        TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        
        //Create Country
        TestDataFactory.createSObject(new Country__c(Name = 'INDIA', Primary_Vigilance_Contact__c = usr.Id),true);
        
        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Complaint_Demotion_rationale__c  = 'Test Demotion',
            Overall_Reportable_Status__c = 'Not Reportable'
        ), true);
        
        //Create Workflow Status 
        CMPL123__WF_Status__c status = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'Opened'),true);
        
        //Create Workflow Status 
        CMPL123__WF_Status__c inProcessStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'In Process'),true);
        
        //Create Workflow Status 
        CMPL123__WF_Status__c inProcessStatusEvaluation = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'In Process-Evaluation'),true);
        
        //Create Workflow Status 
        CMPL123__WF_Status__c assessStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'Assess'),true);
        
        //Create Workflow Status 
        CMPL123__WF_Status__c statusClosed = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'Closed-Voided'),true);
        
        //Create Workflow Action 
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c) TestDataFactory.createSObject(new CMPL123__WF_Action__c(
            Name = 'Void'),true);
        
        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c  assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'CMPL123CME__Investigation__c(PRODEVAL_WORKFLOW)',
            CMPL123__Record_Type__c  = 'PRODEVAL_WORKFLOW',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for Prod Eval Assess
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = assessStatus.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = assessProdRule.Id),true);
        
        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c assessProdRuleTask = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Task__c(Prod_Eval_Task)',
            CMPL123__Record_Type__c  = 'Prod_Eval_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for Prod Eval Assess
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = status.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = assessProdRuleTask.Id),true);
        
        //Create Workflow rule for customer response
        CMPL123__WF_Rule__c responseRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Customer_Response__c(Complaint_Customer_Response)',
            CMPL123__Record_Type__c  = 'Complaint_Customer_Response',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
            
        //Create workflow step for customer response
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = status.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = responseRule.Id),true);
        
        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c assessMedRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)',
            CMPL123__Record_Type__c  = 'MEDICAL_EVALUATION_WORKFLOW',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for Prod Eval Assess
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = inProcessStatusEvaluation.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = assessMedRule.Id),true);
        
                //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c assessMedTaskRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Medical_Evaluation_Task__c(MEDICAL_EVALUATION_TASK_WORKFLOW)',
            CMPL123__Record_Type__c  = 'MEDICAL_EVALUATION_TASK_WORKFLOW',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for Prod Eval Assess
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = inProcessStatus.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = assessMedTaskRule.Id),true);
        
        //Create Customer Response 
        TestDataFactory.createSObject(new Customer_Response__c(CMPL123_WF_Status__c = 'Opened', Event__c = complaint.Id),true);
        
        //Create Workflow rule for customer response
        CMPL123__WF_Rule__c returnRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Return__c(RETURN_WORKFLOW)',
            CMPL123__Record_Type__c  = 'RETURN_WORKFLOW',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for customer response
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = status.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = returnRule.Id),true);
        
        //Create Return 
        TestDataFactory.createSObject(new Return__c(Ticket__c = complaint.Id, CMPL123_WF_Status__c = 'Opened'),true);
        
        //Create Workflow rule for customer response
        CMPL123__WF_Rule__c  translationTaskRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
            CMPL123__Record_Type__c  = 'Translation_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for customer response
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = inProcessStatus.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = translationTaskRule.Id),true);
        
        //Translation_Task__c
        TestDataFactory.createSObject(new Translation_Task__c(
            Parent_Ticket__c = complaint.Id,
            CMPL123_WF_Status__c = 'Opened'),true);
        
        //Create MeaningfulData Request
        TestDataFactory.createSObject(new Meaningful_Data_Request__c(
                Request_Type__c = 'CSS Request',
                Question_Action__c = 'test?',
                Ticket__c = complaint.Id), true);
    }
    
    /**
    * @Method       : invocableTest
    * @Description  : Creating the required test data for Complaint code.  
    * @Return       : N/A
    * @Params       : N/A
    **/
    static testMethod void invocableTest(){
        // This code runs as the system user
        Profile objProfile = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User usr = new User(Alias = 'standt', 
                            Email='test@test.com', 
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            ProfileId = objProfile.Id, 
                            TimeZoneSidKey='America/Los_Angeles', 
                            Username='test2@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10));
        insert usr;
        
        
        Group grp = [SELECT Id,Name, Type, Email FROM Group WHERE Name = 'Business Admin' LIMIT 1];
        
        GroupMember grpMember = new GroupMember(UserOrGroupId = usr.Id, GroupId = grp.Id);
        insert grpMember;
        
        
        Test.startTest();
        User objUser = [SELECT Id, Username, FirstName, Division, CompanyName FROM User WHERE LastName='Testing'];
        
        
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,Name,CMPL123CME__CMPL123_WF_Status__c,Complaint_Demotion_rationale__c ,
                                              (SELECT Id,Investigation_Evaluation__r.CMPL123_WF_Status__c ,
                                               Investigation_Evaluation__r.CMPL123Rule_Key_Value__c
                                               FROM Ticket_Product_Evaluation_Investigation__r),
                                              (SELECT Id,Name,CMPL123_WF_Status__c,Event__c FROM Customer_Responses__r)
                                              FROM CMPL123CME__Complaint__c WHERE  Business_Unit__c  = 'IA-CC' LIMIT 1];
        //Assert for Prod Eval
        System.assert([SELECT Id, Name FROM CMPL123CME__Investigation__c 
                       WHERE CMPL123CME__Complaint__c =: complaint.Id].size() == 1);

        System.runAs(objUser) {
            PageReference demotePage = Page.DemoteToService;
            demotePage.getParameters().put('id', complaint.Id);
            Test.setCurrentPage(demotePage);
            ADDDemoteToServiceHandler pageController = new ADDDemoteToServiceHandler();
            
            pageController.demotionValue = 'Test Demote';
            pageController.updateDemotionValue();
        }
        complaint = [SELECT Id,Name,CMPL123CME__CMPL123_WF_Status__c,Complaint_Demotion_rationale__c ,
                     (SELECT Id,Investigation_Evaluation__r.CMPL123_WF_Status__c 
                      FROM Ticket_Product_Evaluation_Investigation__r), 
                     (SELECT Id,Name,CMPL123_WF_Status__c,Event__c FROM Customer_Responses__r)
                     FROM CMPL123CME__Complaint__c WHERE Overall_Reportable_Status__c = 'Not Reportable' LIMIT 1];
        //Assert for voiding the Product Eval child record
        System.assertEquals('Closed-Voided', complaint.Ticket_Product_Evaluation_Investigation__r[0].Investigation_Evaluation__r.CMPL123_WF_Status__c);
        
        //Assert for voiding the Customer Response child record
        System.assertEquals('Closed-Voided', complaint.Customer_Responses__r[0].CMPL123_WF_Status__c);
        Test.stopTest();
    }

    /**
    * @Method       : invocableTest
    * @Description  : Creating the required test data for Complaint code.  
    * @Return       : N/A
    * @Params       : N/A
    **/
    static testMethod void invocableTest1(){
        Test.startTest();
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,Name,CMPL123CME__CMPL123_WF_Status__c,Complaint_Demotion_rationale__c ,
                                              (SELECT Id,Investigation_Evaluation__r.CMPL123_WF_Status__c ,
                                               Investigation_Evaluation__r.CMPL123Rule_Key_Value__c
                                               FROM Ticket_Product_Evaluation_Investigation__r),
                                              (SELECT Id,Name,CMPL123_WF_Status__c,Event__c FROM Customer_Responses__r)
                                              FROM CMPL123CME__Complaint__c WHERE  Business_Unit__c  = 'IA-CC' LIMIT 1];
        
        delete [SELECT Id FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c =: complaint.Id];
        
        //Get Investigation 
        CMPL123CME__Investigation__c inv = [SELECT Id,CMPL123_WF_Status__c, Name FROM CMPL123CME__Investigation__c 
                                            WHERE CMPL123CME__Complaint__c =: complaint.Id LIMIT 1];
        
        Task__c investigationEvaluationTaskRecord = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = inv.Id,
                CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
                Source_Leveraged__c = 'Leveraged',
                CMPL123_WF_Status__c = 'Opened'), true);
        TestDataFactory.createSObject(new Task_Product_Evaluation_Investigation__c(
                Investigation_Evaluation__c = inv.Id,
                Task__c = investigationEvaluationTaskRecord.Id), true);

        PageReference demotePage = Page.DemoteToService;
        demotePage.getParameters().put('id', complaint.Id);
        Test.setCurrentPage(demotePage);
        ADDDemoteToServiceHandler pageController = new ADDDemoteToServiceHandler();
        
        pageController.demotionValue = 'Test Demote';
        pageController.updateDemotionValue();
        
        pageController.cancelDemotion();
        Test.stopTest();
    }
    
}