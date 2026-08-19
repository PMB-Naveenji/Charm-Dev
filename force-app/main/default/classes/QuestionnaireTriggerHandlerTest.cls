/* 
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    27-March-2020          1029/1198 CR         Added medEvalReopenTest() test method.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rslob                    03-June-2020           N/A                  Test class optimization
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    10-Jun-2020            N/A                  Updated code part, which is related to Users' insertion. 
*                                                                        This change designed to prevent a 'DUPLICATE_USERNAME' error during 
*                                                                        deployment to Production environment
*  --------------------------------------------------------------------------------------------------------------------------------------
*   vkaih                    06-11-2020             Defect #104          Added voidedSubmissionsOnReportableMedEvalTest() test method.
*                                                                        Added voidedSubmissionsOnNotReportableMedEvalTest() test method.
*                                                                        Added oneVoidedSubmissionTypeOnReportableMedEvalTest() test method.
*                                                                        Added nonReportableMedEvalWithWaivedMedDevTest() test method.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                   15-06-2020              Code Audit           Fixed logic for population of 'Initial_Awareness_Date__c' field
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   30-DEC-2020             TWD Upgrade issue    Added new methods to test moved WF logic to trigger handler.
* --------------------------------------------------------------------------------------------------------------------------------------
*   Larry Resnik            03-NOV-2021             CHaRM Release 2      Fix medEvalReopenTest crashing due to a new validation rule
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class QuestionnaireTriggerHandlerTest {
    @testSetup
    static void setupData() {

        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User admin = TestUtil.insertTestUser(
                adminProfileId,
                'test@test.com',
                'test@test.com'
        );

        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId), true);
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = questionnaireRTId,
                CMPL123CME__Complaint__c = complaint.Id
        ), true);

    }

    @isTest
    static void eventsTest() {
        Test.startTest();
        String questInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c WHERE RecordTypeId = :questInitialRecordType LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE RecordType.Name = 'Complaint' LIMIT 1];
        CMPL123CME__Questionnaire__c questionnaireReportable = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = questInitialRecordType,
                CMPL123CME__Complaint__c = complaint.Id,
                Reportability_Category__c = 'Adverse Event',
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'It is Reportable',
                Reportability__c = 'Reportable',
                Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                Follow_Up_Awareness_Date__c = System.today(),
                Submitted_Date__c = System.today()
        ), true);
        CMPL123CME__Questionnaire__c questionnaireNonReportable = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = questInitialRecordType,
                CMPL123CME__Complaint__c = complaint.Id,
                Reportability_Category__c = 'Adverse Event',
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'It is Reportable',
                Reportability__c = 'Non-Reportable'
        ), true);

        CMPL123CME__Questionnaire__c questionnaireTPMResponsible = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = questInitialRecordType,
                CMPL123CME__Complaint__c = complaint.Id,
                Reportability_Category__c = 'Adverse Event',
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'It is Reportable',
                Reportability__c = 'TPM Responsible'
        ), true);

        questionnaire.CMPL123_WF_Status__c = 'Regulatory';
        questionnaire.Reportability__c = 'TPM Responsible';
        questionnaire.Reportability_Category__c = 'Adverse Event';
        questionnaire.Reportability_Rationale__c = 'It is Reportable';

        update questionnaire;

        delete questionnaire;
        System.assert([SELECT COUNT() FROM CMPL123CME__Questionnaire__c WHERE Id = : questionnaire.Id] == 0);
        Test.stopTest();
    }

    @isTest
    static void updateEmdrMdiDueDateFieldsTest() {
        
        Test.startTest();
        String questionnaireInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireInitial = [SELECT Id FROM CMPL123CME__Questionnaire__c WHERE RecordTypeId = :questionnaireInitialRecordType LIMIT 1];

        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Id EMDRAwaitingACK = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial - Awaiting ACK').getRecordTypeId();
        Country_Submission_Type__c objCountrySubmissionType = [SELECT Id FROM Country_Submission_Type__c WHERE Name = '30 Days' LIMIT 1];
        CMPL123CME__EMDR__c EMDRInitialRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = EMDRInitial,
                        Medical_Evaluation__c = questionnaireInitial.Id
                ), true);
        CMPL123CME__EMDR__c EMDRAwaitingACKRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = EMDRAwaitingACK,
                        Medical_Evaluation__c = questionnaireInitial.Id
                ), true);
        CMPL123CME__Questionnaire_Items__c questionnaireItem = (CMPL123CME__Questionnaire_Items__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaireInitial.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_Deficiency_DT_Q1,
                        CMPL123CME__Answer__c = 'Yes'
                ), true);
        
        questionnaireInitial.Initial_Awareness_Date__c = Date.newInstance(2018, 12, 8);
        questionnaireInitial.Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8);
        update questionnaireInitial;

        questionnaireInitial.CMPL123_WF_Action__c = 'Reportable - Go to Regulatory';
        questionnaireInitial.CMPL123_WF_Status__c = 'Regulatory';
        questionnaireInitial.Reportability__c = 'Reportable';
        questionnaireInitial.Reportability_Category__c = 'Adverse Event';
        questionnaireInitial.Reportability_Rationale__c = 'It is Reportable';
        questionnaireInitial.Targeted_Assessment_No_of_Days__c = 20;
        questionnaireInitial.Evaluator__c = UserInfo.getUserId();
        update questionnaireInitial;


        CMPL123CME__EMDR__c updateInitialEmdrResult = [
                SELECT CMPL123CME__MDR_Due_Date__c
                FROM CMPL123CME__EMDR__c
                WHERE Id = :EMDRInitialRecord.Id
        ];
        CMPL123CME__EMDR__c updateAwaitingACKEmdrResult = [
                SELECT CMPL123CME__MDR_Due_Date__c
                FROM CMPL123CME__EMDR__c
                WHERE Id = :EMDRAwaitingACKRecord.Id
        ];
        
        System.assertEquals(updateInitialEmdrResult.CMPL123CME__MDR_Due_Date__c, questionnaireInitial.Initial_Awareness_Date__c);
        System.assertEquals(updateAwaitingACKEmdrResult.CMPL123CME__MDR_Due_Date__c, questionnaireInitial.Follow_Up_Awareness_Date__c + 30);
        
        Test.stopTest();
    }

    @isTest
    static void createMedEvalTaskRecordTest() {
        Test.startTest();
        String questionnaireInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireInitial = [SELECT Id FROM CMPL123CME__Questionnaire__c WHERE RecordTypeId = :questionnaireInitialRecordType LIMIT 1];

        questionnaireInitial.Deficiency_to_an_adverse_event__c = true;
        questionnaireInitial.Adverse_Event__c = true;

        CMPL123CME__Questionnaire_Items__c questionnaireItem = (CMPL123CME__Questionnaire_Items__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaireInitial.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_Deficiency_DT_Q1,
                        CMPL123CME__Answer__c = 'Yes'
                ), true);
        update questionnaireInitial;

        List <Medical_Evaluation_Task__c> autoCreatedMedicalEvaluationTasks = [
                SELECT Id
                FROM Medical_Evaluation_Task__c
                WHERE Medical_Evaluation__c = :questionnaireInitial.Id
                AND RecordType.Name = 'RCML Review Task'
        ];
        Test.stopTest();
        System.assert(autoCreatedMedicalEvaluationTasks.size() > 0);
    }

    @isTest
    static void closedQuestinnaireTest() {
        Test.startTest();
        String questionnaireInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireInitial = [SELECT Id FROM CMPL123CME__Questionnaire__c WHERE RecordTypeId = :questionnaireInitialRecordType LIMIT 1];

        questionnaireInitial.CMPL123_WF_Status__c = 'Closed-Done';
        questionnaireInitial.Reportability_Rationale__c = 'Closed';
        questionnaireInitial.Reportability__c = 'Closed';
        questionnaireInitial.Reportability_Category__c = 'Adverse Event';

        update questionnaireInitial;

        questionnaireInitial.CMPL123_WF_Status__c = 'Closed-Voided';
        update questionnaireInitial;

        Test.stopTest();
        
    }

    @IsTest
    private static void medEvalReopenTest() {

        User admin = [SELECT Id FROM User WHERE  Username LIKE 'test@test.com%' LIMIT 1];

        Test.startTest();

        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'), true);
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'In Process-Evaluation'), true);
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Reopen-Go to Evaluation',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Medical Evaluation Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_WORKFLOW',
                        CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)'),
                true
        );

        CMPL123__WF_Step__c wfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule.Id,
                        CMPL123__Action__c = wfAction.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Permission_Group__c = 'Medical Evaluator',
                        CMPL123__Is_Start_Step__c = true,
                        CMPL123__Order__c = 1.0
                ), true);
        Id medEvalGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Medical_Evaluator'].Id;
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        User medicalEvaluator = TestUtil.insertTestUser(aspenUserProfileId, 'medEvalQT@test.com', 'medEvalQT@test.com');
        String questInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c
                .getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        // 03-Nov-2021 Larry R: Now puts a Questionnaire on the MedEvalTask to satisfy validations
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Medical_Evaluation_Task__c medEvalTask = (Medical_Evaluation_Task__c) TestDataFactory.createSObject(
            new Medical_Evaluation_Task__c(
                CMPL123_WF_Action__c = 'Submit',
                CMPL123_WF_Status__c = 'In Process',
                Assignee_Name__c = medicalEvaluator.Id,
                Issue_Summary__c = 'Issue data',
                Medical_Evaluation__c =  questionnaire.Id,
                Question__c = 'Did the Abbott product cause or contribute to the death?'
        ), true);
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE RecordType.Name = 'Complaint' LIMIT 1];
        CMPL123CME__Questionnaire__c medEvalClosed = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = questInitialRecordType,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Evaluator__c = admin.Id,
                        Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                        Targeted_Assessment_No_of_Days__c = 20,
                        Reportability_Category__c = 'Adverse Event',
                        CMPL123_WF_Status__c = 'Closed-Done',
                        Reportability_Rationale__c = 'It is Reportable',
                        Reportability__c = 'Non-Reportable'), true);

        
        System.runAs(admin) {
            insert new GroupMember(
                    GroupId = medEvalGroupId,
                    UserOrGroupId = medicalEvaluator.Id
            );
        }

        System.runAs(medicalEvaluator) {
            medEvalClosed.CMPL123_WF_Status__c = endStatus.Name;
            medEvalClosed.CMPL123_WF_Action__c = wfAction.Name;
            update medEvalClosed;
        }
        Test.stopTest();

        CMPL123CME__Questionnaire__c result = [
                SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c
                FROM CMPL123CME__Questionnaire__c
                WHERE Id =: medEvalClosed.Id
        ];

        System.assertEquals(endStatus.Name, result.CMPL123_WF_Status__c);
        System.assertEquals(wfAction.Name, result.CMPL123_WF_Action__c);
    }

    @IsTest
    private static void voidedSubmissionsOnReportableMedEvalTest() {

        User admin = [SELECT Id FROM User WHERE  Username LIKE 'test@test.com%' LIMIT 1];

        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Regulatory'), true);
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'), true);
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Close',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Action__c wfAction2 = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Void',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Medical Evaluation Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_WORKFLOW',
                        CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)'
                ), true);
    CMPL123__WF_Rule__c wfRule2 = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Medical Evaluation Task Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_TASK_WORKFLOW',
                        CMPL123__Target_Object__c = 'Medical_Evaluation_Task__c(MEDICAL_EVALUATION_TASK_WORKFLOW)'
                ), true);

        
        CMPL123__WF_Step__c wfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule.Id,
                        CMPL123__Action__c = wfAction.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Is_Start_Step__c = true,
                        CMPL123__Permission_Group__c = admin.Id,
                        CMPL123__Order__c = 6.00
                ), true);
        
        CMPL123__WF_Step__c wfStep2 = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule2.Id,
                        CMPL123__Action__c = wfAction2.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Permission_Group__c = 'Medical Evaluator',
                        CMPL123__Is_Start_Step__c = true,
                        CMPL123__Order__c = 1.0
                ), true);


        String questInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c
                .getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE RecordType.Name = 'Complaint' LIMIT 1];
        CMPL123CME__Questionnaire__c medEvalReportable = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = questInitialRecordType,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Evaluator__c = admin.Id,
                        Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                        Targeted_Assessment_No_of_Days__c = 10,
                        Reportability_Category__c = 'Adverse Event',
                        CMPL123_WF_Status__c = startStatus.Name,
                        Reportability_Rationale__c = 'It is Reportable',
                        Reportability__c = 'Reportable'
                ), true);
        Id medEvalGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Medical_Evaluator'].Id;
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
    User medicalEvaluator = TestUtil.insertTestUser(aspenUserProfileId, 'medEvalQT@test.com', 'medEvalQT@test.com');
        Test.startTest();
    Medical_Evaluation_Task__c medEvalTask = (Medical_Evaluation_Task__c) TestDataFactory.createSObject(
            new Medical_Evaluation_Task__c(
                CMPL123_WF_Action__c = 'Submit',
                CMPL123_WF_Status__c = 'In Process',
                Assignee_Name__c = medicalEvaluator.Id,
                Issue_Summary__c = 'Issue data',
                Question__c = 'Did the Abbott product cause or contribute to the death?',
                Medical_Evaluation__c =  medEvalReportable.Id,
                Medical_Opinion__c = 'Medical Opinion'
          ), true);
        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = EMDRInitial,
                        Medical_Evaluation__c = medEvalReportable.Id,
                        CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided'
                ), true);

        CMPL123CME__MEDDEV__c meddev = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        Medical_Evaluation__c = medEvalReportable.Id,
                        Follow_Up_Required__c = 'No',
                        CMPL123_WF_Status__c = 'Closed-Voided',
                        CMPL123CME__Type_of_Report__c = 'Combined initial and final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        CMPL123CME__Whether_Manufacturer_Aware__c = 'No',
                        CMPL123CME__Number_of_similarIncidents__c = '2',
                        CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test'
                ), true);
        medEvalReportable.Initial_Awareness_Date__c = Date.newInstance(2021, 09, 24);
            CMPL123CME__EU_MIR__c eumir = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
                new CMPL123CME__EU_MIR__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        MedicalEvaluation__c = medEvalReportable.Id,
                        Follow_Up_Required__c = 'No',
                        CMPL123_WF_Status__c = 'Closed-Voided',
                        CMPL123CME__Type_of_Report__c = 'Combined initial and final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank'
                ), true);
        /*CMPL123CME__EU_MIR__c eumir2 = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
                new CMPL123CME__EU_MIR__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        MedicalEvaluation__c = medEvalReportable.Id,
                        //Follow_Up_Required__c = 'No',
                        CMPL123_WF_Status__c = 'Opened',
                        CMPL123CME__Type_of_Report__c = 'Initial'
                        //CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        //Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank'
                ), true);*/
    Set<String> newSet = new Set<String>();
        newSet.add(''+medEvalReportable.Id);
        QuestionnaireTriggerHandler.updateOpenTasks(newSet);
        String errorMessageReportable = null;
        
        System.runAs(admin) {
            medEvalReportable.CMPL123_WF_Action__c = wfAction.Name;
            medEvalReportable.CMPL123_WF_Status__c = endStatus.Name;
            try {
                update medEvalReportable;
            } catch (Exception e) {
                errorMessageReportable = e.getMessage();
            }
        }
        Test.stopTest();

        CMPL123CME__Questionnaire__c result = [
                SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c
                FROM CMPL123CME__Questionnaire__c
                WHERE Id =: medEvalReportable.Id
        ];

        //System.assert(errorMessageReportable.contains(System.Label.Medical_Evaluation_Voided_Submissions));
        System.assertEquals(startStatus.Name, result.CMPL123_WF_Status__c);
    }

    @IsTest
    private static void voidedSubmissionsOnNotReportableMedEvalTest() {

        User admin = [SELECT Id FROM User WHERE  Username LIKE 'test@test.com%' LIMIT 1];

        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Regulatory'), true);
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'), true);
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Close',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Medical Evaluation Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_WORKFLOW',
                        CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)'
                ), true);

        CMPL123__WF_Step__c wfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule.Id,
                        CMPL123__Action__c = wfAction.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Is_Start_Step__c = true,
                        CMPL123__Permission_Group__c = admin.Id,
                        CMPL123__Order__c = 6.00
                ), true);

        String questInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c
                .getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE RecordType.Name = 'Complaint' LIMIT 1];

        CMPL123CME__Questionnaire__c medEvalNotReportable = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = questInitialRecordType,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Evaluator__c = admin.Id,
                        Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                        Targeted_Assessment_No_of_Days__c = 10,
                        Reportability_Category__c = 'Adverse Event',
                        CMPL123_WF_Status__c = startStatus.Name,
                        Reportability_Rationale__c = 'It is Not Reportable',
                        Reportability__c = 'Not Reportable'
                ), true);

        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = EMDRInitial,
                        Medical_Evaluation__c = medEvalNotReportable.Id,
                        CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided'
                ), true);

        CMPL123CME__MEDDEV__c meddev = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        Medical_Evaluation__c = medEvalNotReportable.Id,
                        Follow_Up_Required__c = 'No',
                        CMPL123_WF_Status__c = 'Closed-Voided',
                        CMPL123CME__Type_of_Report__c = 'Combined initial and final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Submission_Due_Date__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        CMPL123CME__Whether_Manufacturer_Aware__c = 'No',
                        CMPL123CME__Number_of_similarIncidents__c = '2',
                        CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test'
                ), true);

        Test.startTest();
        System.runAs(admin) {
            medEvalNotReportable.CMPL123_WF_Action__c = wfAction.Name;
            medEvalNotReportable.CMPL123_WF_Status__c = endStatus.Name;
            update medEvalNotReportable;
        }
        Test.stopTest();

        CMPL123CME__Questionnaire__c result = [
                SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c
                FROM CMPL123CME__Questionnaire__c
                WHERE Id =: medEvalNotReportable.Id
        ];

        System.assertEquals(endStatus.Name, result.CMPL123_WF_Status__c);
        System.assertEquals(wfAction.Name, result.CMPL123_WF_Action__c);

    }

    @IsTest
    private static void oneVoidedSubmissionTypeOnReportableMedEvalTest() {

        User admin = [SELECT Id FROM User WHERE  Username LIKE 'test@test.com%' LIMIT 1];

        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Regulatory'), true);
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'), true);
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Close',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Medical Evaluation Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_WORKFLOW',
                        CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)'
                ), true);

        CMPL123__WF_Step__c wfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule.Id,
                        CMPL123__Action__c = wfAction.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Is_Start_Step__c = true,
                        CMPL123__Permission_Group__c = admin.Id,
                        CMPL123__Order__c = 6.00
                ), true);

        String questInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c
                .getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE RecordType.Name = 'Complaint' LIMIT 1];
        CMPL123CME__Questionnaire__c medEvalReportable = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = questInitialRecordType,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Evaluator__c = admin.Id,
                        Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                        Targeted_Assessment_No_of_Days__c = 10,
                        Reportability_Category__c = 'Adverse Event',
                        CMPL123_WF_Status__c = startStatus.Name,
                        Reportability_Rationale__c = 'It is Reportable',
                        Reportability__c = 'Reportable'
                ), true);

        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdrVoided = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = EMDRInitial,
                        Medical_Evaluation__c = medEvalReportable.Id,
                        CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided'
                ), true);

        String errorMessage = null;

        Test.startTest();
        System.runAs(admin) {
            medEvalReportable.CMPL123_WF_Action__c = wfAction.Name;
            medEvalReportable.CMPL123_WF_Status__c = endStatus.Name;

            try {
                update medEvalReportable;
            } catch (Exception e) {
                errorMessage = e.getMessage();
            }
        }
        Test.stopTest();

        CMPL123CME__Questionnaire__c result = [
                SELECT Id, CMPL123_WF_Status__c
                FROM CMPL123CME__Questionnaire__c
                WHERE Id =: medEvalReportable.Id
        ];

        System.assert(errorMessage.contains(System.Label.Medical_Evaluation_Voided_Submissions));
        System.assertEquals(startStatus.Name, result.CMPL123_WF_Status__c);
    }

    @IsTest
    private static void nonReportableMedEvalWithWaivedMedDevTest() {

        User admin = [SELECT Id FROM User WHERE  Username LIKE 'test@test.com%' LIMIT 1];

        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Regulatory'), true);
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'), true);
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Close',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Medical Evaluation Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_WORKFLOW',
                        CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)'),
                true
        );

        CMPL123__WF_Step__c wfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule.Id,
                        CMPL123__Action__c = wfAction.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Is_Start_Step__c = true,
                        CMPL123__Permission_Group__c = admin.Id,
                        CMPL123__Order__c = 6.00
                ), true);

        String questInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c
                .getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE RecordType.Name = 'Complaint' LIMIT 1];
        CMPL123CME__Questionnaire__c medEvalNonReportable = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = questInitialRecordType,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Evaluator__c = admin.Id,
                        Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                        Targeted_Assessment_No_of_Days__c = 10,
                        Reportability_Category__c = 'Adverse Event',
                        CMPL123_WF_Status__c = startStatus.Name,
                        Reportability_Rationale__c = 'It is Not Reportable',
                        Reportability__c = 'Non-Reportable'
                ), true);

        CMPL123CME__MEDDEV__c meddevWaived = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        Medical_Evaluation__c = medEvalNonReportable.Id,
                        Follow_Up_Required__c = 'No',
                        CMPL123_WF_Status__c = 'Closed - Waived',
                        CMPL123CME__Type_of_Report__c = 'Combined initial and final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        CMPL123CME__Whether_Manufacturer_Aware__c = 'No',
                        CMPL123CME__Number_of_similarIncidents__c = '2',
                        CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test'
                ), true);

        String errorMessage = null;

        Test.startTest();
        System.runAs(admin) {
            medEvalNonReportable.CMPL123_WF_Action__c = wfAction.Name;
            medEvalNonReportable.CMPL123_WF_Status__c = endStatus.Name;
            try {
                update medEvalNonReportable;
            } catch (Exception e) {
                errorMessage = e.getMessage();
            }
        }
        Test.stopTest();

        CMPL123CME__Questionnaire__c result = [
                SELECT Id, CMPL123_WF_Status__c
                FROM CMPL123CME__Questionnaire__c
                WHERE Id =: medEvalNonReportable.Id
        ];

        System.assert(errorMessage.contains(System.Label.Medical_Evaluation_Closed_Or_Waived_Submissions));
        System.assertEquals(startStatus.Name, result.CMPL123_WF_Status__c);
    }
    
    /*
    * @Method       : testWFlogic.
    * @Description  : To test logic moved from WF to handler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testWFlogic() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE RecordType.Name = 'Complaint' LIMIT 1];
        Date incDate = date.today().addDays(-3);
        complaint.Date_of_Incidence__c = incDate;
        complaint.CMSNext_Ticket_Number__c = '1234567890';
        complaint.pRE_Status__c = 'Yes';
        update complaint;
        String questInitialRecordType = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = questInitialRecordType,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Evaluator__c = UserInfo.getUserId(),
                        Initial_Awareness_Date__c = Date.newInstance(2019, 05, 12),
                        Targeted_Assessment_No_of_Days__c = 10,
                        Reportability_Category__c = 'Adverse Event',
                        CMPL123_WF_Action__c = 'Reopen',
                        Reportability_Rationale__c = 'It is Not Reportable',
                        Reportability__c = 'Non-Reportable', 
                        CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                        CMPL123_WF_Action_Performed_On__c = date.today()
                ), true);
        //WF: Initiate pRE decision tree    
        System.assertEquals('pRE', [SELECT CMPL123CME__Key_value__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].CMPL123CME__Key_value__c );
        //WF: ADDS3 update assessment start,prompted date and reopen performed date and performed by in medical evaluation. 
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Reopened_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Reopened_By__c );
        medEval.CMPL123_WF_Action__c = 'TPM Responsible - Close';
        medEval.Reportability__c = 'TPM Responsible';
        update medEval;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT TPM_Responsible_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].TPM_Responsible_By__c );
        medEval.CMPL123_WF_Action__c = 'Promote';
        update medEval;
        System.assertNotEquals(null, [SELECT Assessment_Start_Date__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Assessment_Start_Date__c );
        //WF: ADDS3 update Assigned date based on evaluator in medical evaluation.
        medEval.Evaluator__c = UserInfo.getUserId();
        update medEval;
        System.assertNotEquals(null, [SELECT Assigned_Date__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Assigned_Date__c);
        //WF: ADDS3 Update ticket based fields in medical evaluation.   
        System.assertEquals(incDate, [SELECT Date_of_Incidence__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Date_of_Incidence__c );
        //WF: ADDS3 update workflow action performed date and performed by in medical evaluation. 
        medEval.CMPL123_WF_Action__c = 'Close';
        update medEval;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Closed_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Closed_By__c );
        medEval.CMPL123_WF_Action__c = 'Not Reportable - Close';
        medEval.Reportability__c = 'Non-Reportable';
        update medEval;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Not_Reportable_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Not_Reportable_By__c);
        Test.startTest();
        medEval.CMPL123_WF_Action__c = 'Reportable - Go to Regulatory';
        medEval.Reportability__c = 'Reportable';
        update medEval;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Reportable_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Reportable_By__c);
        medEval.CMPL123_WF_Action__c = 'Void';
        medEval.Voided_Rationale__c = 'TEST';
        update medEval;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Voided_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Voided_By__c );
        //WF: ADDS3_Initiate Deficiency Decision Tree   
        medEval.Conclusion_Disposition_Flag__c = 'Deficiency';
        update medEval;
        System.assertEquals('Deficiency', [SELECT CMPL123CME__Key_value__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].CMPL123CME__Key_value__c );
        medEval.Field_Action_Flag__c = true;
        update medEval;
        System.assertEquals('FieldAction', [SELECT CMPL123CME__Key_value__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].CMPL123CME__Key_value__c );
        //WF: Autoset Registration Number
        System.assertEquals('1234567890(Complaint)', [SELECT Registration_Number__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Registration_Number__c);
        //WF: Clear action by and on fields 
        medEval.CMPL123_WF_Status__c = 'In Process-Evaluation';
        medEval.Not_Reportable_On__c = date.today();
        update medEval;
        System.assertEquals(null, [SELECT Not_Reportable_On__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Not_Reportable_On__c );
        //WF: Update Assessment Due date    
        medEval.Initial_Awareness_Date__c = date.today();
        medEval.Targeted_Assessment_No_of_Days__c = 10;
        update medEval;
        System.assertEquals(date.today().addDays(10), [SELECT Assessment_Due_date__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Assessment_Due_date__c );
        //WF: Update Reportability Date Field   
        medEval.Reportability__c = 'Reportable';
        update medEval;
        System.assertNotEquals(null, [SELECT Reportability_Date__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Reportability_Date__c );
        //WF: Workflow - Close  
        medEval.CMPL123_WF_Action__c = 'TPM Responsible - Close';
        medEval.Reportability__c = 'TPM Responsible';
        medEval.Reopened_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        update medEval;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Closed_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Closed_By__c );
        System.assertEquals(null, [SELECT Reopened_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Reopened_By__c );
        //WF: Workflow - Reopen
        medEval.CMPL123_WF_Action__c = 'Reopen';
        medEval.Reopened_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        update medEval;
        System.assertEquals(null, [SELECT Closed_By__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEval.Id].Closed_By__c );
        Test.stopTest();
    }
}