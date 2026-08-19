/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : MedicalEvaluationTaskTriggerHandlerTest.
* @Why   : MedicalEvaluationTaskTriggerHandlerTest test class for the MedicalEvaluationTaskTriggerHandler class.
* @When  : 31-AUG-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    31-AUG-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-MAR-2020            1029/1198 CR         Added taskReopenTest() test method.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                    03-JUN-2020            N/A                  Test class optimization.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    10-JUN-2020            N/A                  Updated code part, which is related to Users' insertion. 
*                                                                      This change designed to prevent a 'DUPLICATE_USERNAME' 
*                                                                      error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                    13-AUG-2020            Unit Test Audit      medicalEvaluationTaskTriggerHandler method optimization.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    21-AUG-2020            Code Audit           Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid                   25-Jan-2021            Error Fix          Resolved workflow key value error.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class MedicalEvaluationTaskTriggerHandlerTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMSNext_Ticket_Number__c = '12345'),
                true
        );
        insert new CMPL123CME__Questionnaire__c(CMPL123CME__Complaint__c = complaint.Id);
    }

    /*
    * @Method       : medicalEvaluationTaskTriggerHandler.
    * @Description  : To test the MedicalEvaluationTaskTriggerHandler functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static testMethod void medicalEvaluationTaskTriggerHandler() {
        
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User aspenUser = TestUtil.insertTestUser(aspenInteg, 'aspenUserIntegMedOk@test.com', 'aspenUserIntegMed@test.com');
        
        Id taskRecordTypeId = Schema.SObjectType.Medical_Evaluation_Task__c
                .getRecordTypeInfosByName()
                .get('RCML Review Task')
                .getRecordTypeId();
        Medical_Evaluation_Task__c medTask = (Medical_Evaluation_Task__c) TestDataFactory.createSObject(new Medical_Evaluation_Task__c(
                Reportable_Confirmed_Malfunction_Descrip__c = 'Test',
                Assignee_Name__c = aspenUser.Id,
                RecordTypeId = taskRecordTypeId,
                CMPL123_WF_Status__c = 'Opened',
            	Issue_Summary__c = 'Summary',
            	Add_Confirmed_Malfunction_to_RCML_List__c = 'Yes',
            	RCML_CFT_Members__c = 'Members',
            	RCML_CFT_Review_Date__c = Date.today(),
                Medical_Evaluation__c = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1].Id), true);

        System.runAs(aspenUser) {
            CMPL123__Product__c prod = (CMPL123__Product__c) TestDataFactory.createSObject(
                    new CMPL123__Product__c(),
                    true
            );
            RCML_Task_Product__c RCMLTaskRec = (RCML_Task_Product__c) TestDataFactory.createSObject(
                    new RCML_Task_Product__c(
                            Product_ID__c = prod.Id,
                            RCML_Task_ID__c = medTask.Id),
                    true
            );
        }

        Test.startTest();
        medTask.CMPL123_WF_Action__c = 'Submit';
        medTask.CMPL123_WF_Status__c = 'In Process';
		
        UpdateParentUtility.flag = true;
        TestDataFactory.updateSObject(medTask);

        System.runAs(aspenUser){
            medTask.CMPL123_WF_Action__c = 'Complete';
            medTask.CMPL123_WF_Status__c = 'Closed-Done';
            TestDataFactory.updateSObject(medTask);
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Medical_Evaluation_Task__c]);
    }

    /*
    * @Method       : taskReopenTest.
    * @Description  : To test Medical_Evaluation_Task__c reopening.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void taskReopenTest() {
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User admin = TestUtil.insertTestUser(
                adminProfileId,
                'adminTestMed4@test.com',
                'adminTestMed4@test.com'
        );

        Test.startTest();
        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'), true);
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Opened'), true);
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Reopen',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Medical Evaluation Task Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_TASK_WORKFLOW',
                        CMPL123__Target_Object__c = 'Medical_Evaluation_Task__c(MEDICAL_EVALUATION_TASK_WORKFLOW)'),
                true
        );

        CMPL123__WF_Step__c wfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule.Id,
                        CMPL123__Action__c = wfAction.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Permission_Group__c = 'Medical Evaluator',
                        CMPL123__Order__c = 1.0,
                     CMPL123__Is_Start_Step__c = true //25 jan 2021,Juneid, Added start step to fix workflow key value error
                ), true);

        CMPL123CME__Questionnaire__c medEval = [SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Questionnaire__c LIMIT 1];
        medEval.CMPL123_WF_Status__c = 'In Process-Evaluation';
        medEval.CMPL123_WF_Action__c = 'Promote';
        medEval.Evaluator__c = admin.Id;
        medEval.Initial_Awareness_Date__c = System.today();
        medEval.Targeted_Assessment_No_of_Days__c = 10;
        update medEval;

        Id taskRecordTypeId = Schema.SObjectType.Medical_Evaluation_Task__c
                .getRecordTypeInfosByName()
                .get('RCML Review Task')
                .getRecordTypeId();
        Medical_Evaluation_Task__c medTask = new Medical_Evaluation_Task__c(
                Reportable_Confirmed_Malfunction_Descrip__c = 'Test',
                Assignee_Name__c = UserInfo.getUserId(),
                RecordTypeId = taskRecordTypeId,
                Add_Confirmed_Malfunction_to_RCML_List__c = 'Test',
                No_RCML_Addition_Rationale__c = 'Test information',
                Issue_Summary__c = 'Test',
                RCML_CFT_Review_Date__c = System.today(),
                RCML_CFT_Members__c = 'test',
                CMPL123_WF_Status__c = 'Closed-Done',
                Medical_Evaluation__c = medEval.Id);
        insert medTask;

        Id evaInvestGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Evaluator_Investigator'].Id;
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;

        User evalInvestigator = TestUtil.insertTestUser(
                aspenUserProfileId,
                'medEvalTest2@test.com',
                'medEvalTest2@test.com'
        );

        System.runAs(admin) {
            insert new GroupMember(
                    GroupId = evaInvestGroupId,
                    UserOrGroupId = evalInvestigator.Id
            );
        }

        System.runAs(evalInvestigator) {
            medTask.CMPL123_WF_Status__c = endStatus.Name;
            medTask.CMPL123_WF_Action__c = wfAction.Name;
            update medTask;
        }
        Test.stopTest();

        Medical_Evaluation_Task__c result = [
                SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c
                FROM Medical_Evaluation_Task__c
                WHERE Id =: medTask.Id
        ];

        System.assertEquals(endStatus.Name, result.CMPL123_WF_Status__c);
        System.assertEquals(wfAction.Name, result.CMPL123_WF_Action__c);
    }
}