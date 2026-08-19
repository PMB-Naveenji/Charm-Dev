/*
* @why  : Test class for the ADDS4RiskManagementTriggerHandler.
* @when : 24-OCT-2018.
* @what : Class to handle different scenarios from ADDS4RiskManagementTriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                    Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 04-JUN-2020             Code Audit                      Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 15-JUN-2020             Code Audit                      Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                 30-JUN-2020             #164.1(CHARM-2939)              Added new testMethods to test new scenarious.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 28-DEC-2020             TWD Upgrade issue               Added 'executeLogicFromWFRulesTest' methods to test moved
*                                                                                   logic from Workflow Rules with Field Updates on PMRA to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 15-JAN-2020             Code Audit                      Modified 'cloneWhenReopenTest()' and created
*                                                                                   'autoCreateRiskAsstChildRecordTest()' methods.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ADDS4RiskManagementTriggerHandlerTest {
    /*
    * @Method       : setup
    * @Description  : Creating records for Ticket object
    * @Return       : N/A
    * @Params       : N/A
    */
    @TestSetup
    private static void setup() {
        CMPL123__WF_Status__c statusOpened = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
            new CMPL123__WF_Status__c (Name = 'Opened'), true);
        CMPL123__WF_Status__c statusRiskControlMeasureInProcess = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
            new CMPL123__WF_Status__c (Name = 'Risk Control Measure in Process'), true);
        CMPL123__WF_Status__c statusClosedVoided = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
            new CMPL123__WF_Status__c (Name = 'Closed-Voided'), true);
        CMPL123__WF_Action__c actionPassThrough = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
            new CMPL123__WF_Action__c (Name = 'Pass-Through'), true);
        CMPL123__WF_Action__c actionVoid = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
            new CMPL123__WF_Action__c (Name = 'Void'), true);

        CMPL123__WF_Rule__c assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            Name = 'ADD Risk Managment Workflow',
            CMPL123__Target_Object__c = 'Post_Market_Risk_Assessment_Risk_Contr__c(ADDRiskManagement)',
            CMPL123__Record_Type__c = 'ADDRiskManagement',
            CMPL123__Is_Active__c = true,
            CMPL123__Has_Multiple_Actions__c = true
        ), true);

        insert new List<CMPL123__WF_Step__c>{
            new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = statusOpened.Id,
                CMPL123__End_Status__c = statusRiskControlMeasureInProcess.Id,
                CMPL123__Action__c = actionPassThrough.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__WF_Rule__c = assessProdRule.Id,
                CMPL123__Is_Start_Step__c = true
            ),
            new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = statusOpened.Id,
                CMPL123__End_Status__c = statusClosedVoided.Id,
                CMPL123__Action__c = actionVoid.Id,
                CMPL123__Order__c = 2.0,
                CMPL123__WF_Rule__c = assessProdRule.Id,
                CMPL123__Is_Start_Step__c = false
            )
        };

        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c (
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                CMPL123Rule_Key_Value__c = 'ADDRiskManagement',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Division__c = 'ADD',
                Description_of_Issue__c = 'QR: On 05/28/2018, during Alinity s factory (Wiesbaden) testing of PC2'
                    + '(positive control level 2) bulk material for the HTLV assay unexpected low results were generated for two '
                    + 'of five replicates aspirated from the same sample tube. Reps 1,3, and 5 generate results that were '
                    + 'consistent with this low positive material but reps 2 and 4 had very low signal that would be negative for HTLV.'
        ), true);

        insert new Action_Task__c(
            Action_Description__c = 'Test',
            Action_Type__c = 'Version Risk Record',
            Assignee__c = UserInfo.getUserId(),
            Post_Market_Risk_Assessment_Risk_Contr__c = objRisk.Id,
            CMPL123Rule_Key_Value__c = 'HAZARD_ASSESSMENT_ADD_WORKFLOW',
            CMPL123_WF_Status__c = 'Opened'
        );

        insert new Regulatory_Assessment__c(
            Post_Market_Risk_Assessment_Risk_Contr__c = objRisk.Id,
            CMPL123Rule_Key_Value__c = 'REGULATORY_ASSESSMENT_WORKFLOW'
        );

        insert new Hazard_Assessment__c(
            Post_Market_Risk_Assessment_Risk_Contr__c = objRisk.Id,
            CMPL123Rule_Key_Value__c = 'ACTION_TASK_WORKFLOW',
            Hazard_Type__c = 'Incorrect Results',
            Rationale_Associated_to_Delay_of_Results__c = 'N/A'
        );

        insert new Additional_Approval__c(
            Post_Market_ID__c = objRisk.Id,
            Approval_Type__c = 'Other',
            Approver__c = UserInfo.getUserId(),
            Is_Cloned__c = false
        );
    }

    /*
    * @Method       : cloneWhenReopenTest
    * @Description  : Clone When Reopening Risk Record
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void cloneWhenReopenTest() {
        insert new ADD_App_Settings__c(Restrict_Validation_Rules__c = true);
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];
        objRisk.CMPL123_WF_Status__c = 'Closed-Done';
        objRisk.CMPL123_WF_Action__c = 'Related Child Records and Tasks Closed';
        objRisk.Recognition_Date__c = System.today();
        objRisk.Notification_Date__c = System.today();
        objRisk.Risk_Control_Management_Decision_Date__c = System.today();
        objRisk.Closure_Date__c = System.today();
        try {
                update objRisk;
        } catch (Exception e) {
                System.assert(e.getMessage().contains('There are Action Tasks which are not closed'));
        }

        Test.startTest();

        //  Code Audit - Fix Start
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(),
            Division__c  = 'ADD',
            pRE_Status__c  = 'No',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Complaint',
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'INDIA',
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = false
        ), true);

        insert new List<Attachment__c>{
            new Attachment__c(
                Attachment_Type__c = 'Medical Evaluation',
                Ticket__c = complaint.Id
            ),
            new Attachment__c(
                Attachment_Type__c = 'Medical Evaluation',
                Post_Market_Risk_Asst_Risk_Ctrl__c = objRisk.Id
            ),
            new Attachment__c(
                Attachment_Type__c = 'Medical Evaluation',
                Hazard_Assessment__c = [SELECT Id FROM Hazard_Assessment__c LIMIT 1].Id
            ),
            new Attachment__c(
                Attachment_Type__c = 'Medical Evaluation',
                Regulatory_Assessment__c = [SELECT Id FROM Regulatory_Assessment__c LIMIT 1].Id
            ),
            new Attachment__c(
                Attachment_Type__c = 'Medical Evaluation',
                Additional_Approval__c = [SELECT Id FROM Additional_Approval__c LIMIT 1].Id
            ),
            new Attachment__c(
                Attachment_Type__c = 'Medical Evaluation',
                Action_Task__c = [SELECT Id FROM Action_Task__c LIMIT 1].Id
            )
        };

        List<Attachment> standardAttachments = new List<Attachment>();

        for (Attachment__c customAttachment :[SELECT Id FROM Attachment__c]) {
            standardAttachments.add(new Attachment(
                ParentId = customAttachment.Id,
                Body = Blob.valueOf('Customer Letter'),
                Name = 'Test.txt'
            ));
        }

        insert standardAttachments;

        List<CMPL123__WF_History__c> wfHistories = new List<CMPL123__WF_History__c>();

        for (CMPL123__WF_Step__c wfStep :[SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                                                CMPL123__Start_Status__r.Name
                                            FROM CMPL123__WF_Step__c
                                            LIMIT 2]) {
            wfHistories.add(new CMPL123__WF_History__c(
                CMPL123__Related_Id__c = String.valueOf(complaint.Id),
                CMPL123__Workflow_Step__c = wfStep.Id,
                CMPL123__Action__c = wfStep.CMPL123__Action__r.Name,
                CMPL123__ESign_Applied__c = false,
                CMPL123__Comment__c = 'Applied through task update',
                CMPL123__Status__c = wfStep.CMPL123__End_Status__r.Name,
                CMPL123__Change_Summary__c = 'Updated Status From ' + wfStep.CMPL123__Start_Status__r.Name + ' to ' + wfStep.CMPL123__End_Status__r.Name
            ));
        }

        insert wfHistories;

        objRisk.CMPL123_WF_Status__c = 'Opened';
        objRisk.CMPL123_WF_Action__c = 'Reopen';
        update objRisk;

        System.assertEquals(2, [
                SELECT COUNT()
                FROM Regulatory_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c = :objRisk.Id
        ]);
        //  Code Audit - Fix End

        Test.stopTest();
    }

    /*
    * @Method       : autoCreateRiskAsstChildHazardAssessment
    * @Description  : Auto Create RiskAsst HazardAssessment
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void autoCreateRiskAsstChildHazardAssessment() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
            SELECT Id
            FROM Post_Market_Risk_Assessment_Risk_Contr__c
            WHERE Source__c = 'Nonconformance'
        ];
        Boolean result = true;

        Test.startTest();
        objRisk.CMPL123_WF_Status__c = 'Hazard Assessment In Process';
        objRisk.CMPL123_WF_Action__c = 'Submit to Risk Evaluation';
        objRisk.Is_Auto_Hazard_Assessment_Created__c = false;
        try {
            update objRisk;
        } catch (Exception e) {
            result = e.getMessage().contains('User cannot edit these HA fields in Pending Parent Hazard Assessment Approval and beyond');
        }
        Test.stopTest();
        System.assertEquals(result,false);
    }

    /*
    * @Method       : autoCreateRiskAsstChildActionTaskTest
    * @Description  : Auto Create RiskAsst ActionTask
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void autoCreateRiskAsstChildActionTaskTest(){
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
            SELECT Id
            FROM Post_Market_Risk_Assessment_Risk_Contr__c
            WHERE Source__c = 'Nonconformance'
        ];
        Action_Task__c objActionTask =[
            SELECT Id
            FROM Action_Task__c
            WHERE Post_Market_Risk_Assessment_Risk_Contr__c =:objRisk.Id
            LIMIT 1
        ];

        Test.startTest();
        objRisk.CMPL123_WF_Status__c = 'Risk Evaluation in Process';
        objRisk.CMPL123_WF_Action__c = 'Submit to Risk Evaluation';
        objRisk.Is_Auto_Action_Task_Created__c = false;
        update objRisk;

        objActionTask.CMPL123_WF_Status__c = 'Closed-Done';
        update objActionTask;
        try {
            objRisk.CMPL123_WF_Action__c = 'Related Child Records and Tasks Closed';
            update objRisk;
            System.assertEquals(
                'Closed-Done',
                [SELECT CMPL123_WF_Status__c
                    FROM Action_Task__c
                    WHERE Post_Market_Risk_Assessment_Risk_Contr__c = :objRisk.Id].CMPL123_WF_Status__c
            );
        } catch (Exception e) {
                System.assert(e.getMessage().contains('There are Action Tasks which are not closed'));
        }
        Test.stopTest();
    }

    /*
    * @Method       : ClosedVoidAllRelatedChildrenTest
    * @Description  : Closed Void All Related Children
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void closedVoidAllRelatedChildrenTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id,CMPL123Rule_Key_Value__c,
                (SELECT Id,CMPL123Rule_Key_Value__c FROM Regulatory_Assessments__r),
                (SELECT Id,CMPL123Rule_Key_Value__c FROM Hazard_Assessments__r),
                (SELECT Id,CMPL123Rule_Key_Value__c FROM Action_Tasks__r),
                (SELECT Id,CMPL123Rule_Key_Value__c FROM Additional_Approval__r)
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];

        Test.startTest();
        objRisk.CMPL123_WF_Status__c = 'Closed-Voided';
        objRisk.CMPL123_WF_Action__c = 'Void';
        update objRisk;
        Test.stopTest();

        System.assertEquals('REGULATORY_ASSESSMENT_WORKFLOW', [
                SELECT CMPL123Rule_Key_Value__c
                FROM Regulatory_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c = :objRisk.Id
                LIMIT 1].CMPL123Rule_Key_Value__c);
    }

    /*
    * @Method       : checkRegulatoryAssessment
    * @Description  : Check RegulatoryAssessment's workflow status
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void checkRegulatoryAssessment() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];
        Boolean validationExceptionTracked = false;

        Test.startTest();
        objRisk.CMPL123_WF_Status__c = 'Risk Control Measure in Process';
        objRisk.CMPL123_WF_Action__c = 'Risk Control Measure Recommended';
        try {
                update objRisk;
        } catch (DmlException e) {
                validationExceptionTracked = e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION');
        }
        Test.stopTest();

        System.assert(validationExceptionTracked);
    }

    /*
    * @Method       : RCMDateChangeSeniourManAppTest
    * @Description  : #164.1(CHARM-2939) The RCM Approval Date should be populated only when PMRA is in the “Pending Closure of Related Child Records & Tasks”
    *                 status from Pending Senior Management Approval, Pending TSB Senior Management Approval or Pending Pass-Through Approval status.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void RCMDateChangeSeniourManAppTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];
        Boolean validationExceptionTracked = false;

        Test.startTest();
        objRisk.CMPL123_WF_Status__c = 'Pending Senior Management Approval';
        objRisk.DVP_Marketing_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Medical_Affairs_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Quality_Assurance_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Regulatory_Affairs_Approver__c = UserInfo.getUserId();
        objRisk.RCM_Approval_Date__c = null;
        update objRisk;
        objRisk.CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks';
        update objRisk;
        objRisk = [
                SELECT RCM_Approval_Date__c
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Id =: objRisk.Id
        ];
        Test.stopTest();
        System.assertNotEquals(null, objRisk.RCM_Approval_Date__c, 'Date should be populated to current Date/time');
    }

    /*
    * @Method       : RCMDateChangeTSBTest
    * @Description  : #164.1(CHARM-2939)The RCM Approval Date should be populated only when PMRA is in the “Pending Closure of Related Child Records & Tasks”
    *                status from Pending Senior Management Approval, Pending TSB Senior Management Approval or Pending Pass-Through Approval status.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void RCMDateChangeTSBTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];
        Boolean validationExceptionTracked = false;

        Test.startTest();
        objRisk.CMPL123_WF_Status__c = 'Pending TSB - Senior Management Approval';
        objRisk.DVP_Marketing_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Medical_Affairs_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Quality_Assurance_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Regulatory_Affairs_Approver__c = UserInfo.getUserId();
        objRisk.Director_Core_Global_Serv_Ops_Approver__c  = UserInfo.getUserId();
        objRisk.RCM_Approval_Date__c = null;
        update objRisk;
        objRisk.CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks';
        update objRisk;
        objRisk = [
                SELECT RCM_Approval_Date__c
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Id =: objRisk.Id
        ];
        Test.stopTest();
        System.assertNotEquals(null, objRisk.RCM_Approval_Date__c, 'Date should be populated to current Date/time');
    }

    /*
    * @Method       : RCMDateChangeP_TTest
    * @Description  : #164.1(CHARM-2939) The RCM Approval Date should be populated only when PMRA is in the “Pending Closure of Related Child Records & Tasks”
    *                status from Pending Senior Management Approval, Pending TSB Senior Management Approval or Pending Pass-Through Approval status.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void RCMDateChangeP_TTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];
        objRisk.Source__c = 'Pass-Through';
        update objRisk;
        Boolean validationExceptionTracked = false;

        Test.startTest();
        objRisk.CMPL123_WF_Status__c = 'Pending Pass-Through Approval';
        objRisk.DVP_Marketing_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Medical_Affairs_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Quality_Assurance_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Regulatory_Affairs_Approver__c = UserInfo.getUserId();
        update objRisk;
        objRisk.CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks';
        update objRisk;
        objRisk = [
                SELECT RCM_Approval_Date__c
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Id =: objRisk.Id
        ];
        Test.stopTest();
        System.assertNotEquals(null, objRisk.RCM_Approval_Date__c, 'Date should be populated to current Date/time');
    }

    /*
    * @Method       : RCMDateChangeNotRecomTest
    * @Description  : #164.1(CHARM-2939) The RCM Approval Date should not be populated since the package did not route for RCM approval.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void RCMDateChangeNotRecomTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];
        Boolean validationExceptionTracked = false;

        Test.startTest();
        objRisk.CMPL123_WF_Status__c = 'Pending Risk Control Measure Recommendation';
        objRisk.DVP_Marketing_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Medical_Affairs_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Quality_Assurance_Approver__c = UserInfo.getUserId();
        objRisk.DVP_Regulatory_Affairs_Approver__c = UserInfo.getUserId();
        objRisk.Is_a_Risk_Control_Measure_Required__c = 'No';
        objRisk.RCM_Approval_Date__c = null;
        objRisk.Risk_Control_Measure_Recommendation_Rati__c = 'TEST';
        update objRisk;
        List <Regulatory_Assessment__c> regAssessments = [Select Id from Regulatory_Assessment__c where Post_Market_Risk_Assessment_Risk_Contr__c =: objRisk.Id];
        for (Regulatory_Assessment__c regAssessment: regAssessments ) {
            regAssessment.CMPL123_WF_Status__c  = 'Closed-Done';
        }
        update regAssessments ;
        delete  [Select Id from Hazard_Assessment__c where Post_Market_Risk_Assessment_Risk_Contr__c =: objRisk.Id];

        objRisk.CMPL123_WF_Action__c = 'Risk Control Measure Not Recommended';
        objRisk.CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks';
        update objRisk;
        objRisk = [
                SELECT RCM_Approval_Date__c
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Id =: objRisk.Id
        ];
        Test.stopTest();
        System.assertEquals(null, objRisk.RCM_Approval_Date__c, 'Date should stay blank');
    }

    /*
    * @Method       : riskEvalDateChangeTest
    * @Description  : #164.1(CHARM-2939) The Risk Evaluation Approval Date should be blanked out when the PMRA is moved back to Risk Evaluation In Process.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void riskEvalDateChangeTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];
        Boolean validationExceptionTracked = false;
        objRisk.Risk_Evaluation_Approval_Date__c = Datetime.now();
        objRisk.CMPL123_WF_Status__c = 'Pending Risk Control Measure Recommendation';
        update objRisk;
        Test.startTest();
        objRisk.CMPL123_WF_Action__c = 'Send Back to Risk Evaluation in Process';
        objRisk.CMPL123_WF_Status__c = 'Risk Evaluation in Process';
        update objRisk;
        objRisk = [
                SELECT Risk_Evaluation_Approval_Date__c
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Id =: objRisk.Id
        ];
        Test.stopTest();
        System.assertEquals(null, objRisk.Risk_Evaluation_Approval_Date__c, 'Date should be blank');
    }

    /*
    * @Method       : approvalBy_OnChangeTest
    * @Description  : #164.1(CHARM-2939) The Approval By and Approval On fields in the Risk Control Measure Approvals section on a PMRA record should be blanked out
    *                  when the “RCM Reject” action is performed and the PMRA record moves back to “Risk Control Measure in Process” status."
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void approvalBy_OnChangeTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c objRisk = [
                SELECT Id
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Source__c = 'Nonconformance'
        ];
        Boolean validationExceptionTracked = false;
        objRisk.Risk_Evaluation_Approval_Date__c = Datetime.now();
        objRisk.DVP_Marketing_Approval_By__c = UserInfo.getUserId();
        objRisk.DVP_Marketing_Approval_On__c = Datetime.now();
        objRisk.DVP_Medical_Affairs_Approval_By__c = UserInfo.getUserId();
        objRisk.DVP_Medical_Affairs_Approval_On__c = Datetime.now();
        objRisk.DVP_Quality_Assurance_Approval_By__c = UserInfo.getUserId();
        objRisk.DVP_Quality_Assurance_Approval_On__c = Datetime.now();
        objRisk.DVP_Regulatory_Affairs_Approval_By__c = UserInfo.getUserId();
        objRisk.DVP_Regulatory_Affairs_Approval_On__c = Datetime.now();
        objRisk.Director_Core_Global_Service_Ops_By__c = UserInfo.getUserId();
        objRisk.Director_Core_Global_Service_Ops_On__c = Datetime.now();
        update objRisk;
        List <Regulatory_Assessment__c> regAssessments = [Select Id from Regulatory_Assessment__c where Post_Market_Risk_Assessment_Risk_Contr__c =: objRisk.Id];
        for (Regulatory_Assessment__c regAssessment: regAssessments ) {
            regAssessment.CMPL123_WF_Status__c  = 'Closed-Done';
        }
        update regAssessments ;
        Test.startTest();
        objRisk.CMPL123_WF_Action__c = 'RCM Reject';
        objRisk.CMPL123_WF_Status__c = 'Risk Control Measure in Process';
        objRisk.RCM_Rejection_Reason__c = 'TEST';
        update objRisk;
        objRisk = [
                SELECT  DVP_Marketing_Approval_By__c, DVP_Marketing_Approval_On__c, DVP_Medical_Affairs_Approval_By__c, DVP_Medical_Affairs_Approval_On__c,
                        DVP_Quality_Assurance_Approval_By__c, DVP_Quality_Assurance_Approval_On__c, DVP_Regulatory_Affairs_Approval_By__c, DVP_Regulatory_Affairs_Approval_On__c,
                        Director_Core_Global_Service_Ops_By__c, Director_Core_Global_Service_Ops_On__c
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                WHERE Id =: objRisk.Id
        ];
        Test.stopTest();

        System.assertEquals(null, objRisk.DVP_Marketing_Approval_By__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.DVP_Marketing_Approval_On__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.DVP_Medical_Affairs_Approval_By__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.DVP_Medical_Affairs_Approval_On__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.DVP_Quality_Assurance_Approval_By__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.DVP_Quality_Assurance_Approval_On__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.DVP_Regulatory_Affairs_Approval_By__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.DVP_Regulatory_Affairs_Approval_On__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.Director_Core_Global_Service_Ops_By__c, 'Field should be blanked');
        System.assertEquals(null, objRisk.Director_Core_Global_Service_Ops_On__c, 'Field should be blanked');
    }

    /*
    * @Method       : executeLogicFromWFRulesTestPartA.
    * @Description  : Method to test logic migrated from WF Rules to Apex.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void executeLogicFromWFRulesTestPartA() {
        Profile aspenUserProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];

        User ceiUser = TestUtil.insertTestUser(
            aspenUserProfile.Id,
            'raj@test.com',
            'cei@test.com',
            'PEA4'
        );

        Post_Market_Risk_Assessment_Risk_Contr__c pmra = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                CMPL123_WF_Status__c = 'Opened',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan'
        ), true);

        String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

        Test.startTest();

        Post_Market_Risk_Assessment_Risk_Contr__c newPMRA = [SELECT Id, Initiator__c, Initiated_Date__c, CMPL123Rule_Key_Value__c
                                                                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                                                                WHERE Id = :pmra.Id];

        System.assertEquals(actionPerformedBy, newPMRA.Initiator__c);
        System.assertEquals('ADDRiskManagement', newPMRA.CMPL123Rule_Key_Value__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra2 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                CMPL123_WF_Status__c = 'Hazard Assessment In Process',
                CMPL123_WF_Action__c = 'Promote to Hazard Assessment',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale'
        ), true);

        newPMRA = [SELECT Id, Hazard_Assessment_Initiation_Date__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra2.Id];

        System.assert(newPMRA.Hazard_Assessment_Initiation_Date__c != null);
        System.assertEquals(DateTime.now().day(), newPMRA.Hazard_Assessment_Initiation_Date__c.day());

        Post_Market_Risk_Assessment_Risk_Contr__c pmra3 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                CMPL123_WF_Status__c = 'Pending Risk Control Measure Recommendation',
                CMPL123_WF_Action__c = 'Approve No Hazards – No Risk Evaluation',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale'
        ), true);

        newPMRA = [SELECT Id, Hazard_Assessment_Approved_By__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra3.Id];

        System.assertEquals(actionPerformedBy, newPMRA.Hazard_Assessment_Approved_By__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra4 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                CMPL123_WF_Status__c = 'Risk Control Measure in Process',
                CMPL123_WF_Action__c = 'Risk Control Measure Recommended',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale'
        ), true);

        newPMRA = [SELECT Id, RCM_Initiation_Date__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra4.Id];

        System.assert(newPMRA.RCM_Initiation_Date__c != null);
        System.assertEquals(DateTime.now().day(), newPMRA.RCM_Initiation_Date__c.day());

        Post_Market_Risk_Assessment_Risk_Contr__c pmra5 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Risk Evaluation in Process',
                CMPL123_WF_Action__c = 'Send Back to Risk Evaluation in Process',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        newPMRA = [SELECT Id, Risk_Evaluation_Quality_Approved_By__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra5.Id];

        System.assertEquals(null, newPMRA.Risk_Evaluation_Quality_Approved_By__c);

        Test.stopTest();
    }

    /*
    * @Method       : executeLogicFromWFRulesTestPartB.
    * @Description  : Method to test logic migrated from WF Rules to Apex.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void executeLogicFromWFRulesTestPartB() {
        Profile aspenUserProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];

        User ceiUser = TestUtil.insertTestUser(
            aspenUserProfile.Id,
            'raj@test.com',
            'cei@test.com',
            'PEA4'
        );

        Post_Market_Risk_Assessment_Risk_Contr__c pmra = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks',
                CMPL123_WF_Action__c = 'DVP Marketing Approval',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

        Test.startTest();

        Post_Market_Risk_Assessment_Risk_Contr__c newPMRA = [SELECT Id, DVP_Marketing_Approval_By__c
                                                                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                                                                WHERE Id = :pmra.Id];

        System.assertEquals(actionPerformedBy, newPMRA.DVP_Marketing_Approval_By__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra2 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Hazard Assessment In Process',
                CMPL123_WF_Action__c = 'Send Back to Hazard Assessment in Process',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        newPMRA = [SELECT Id, Hazard_Assessment_Approval_Date__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra2.Id];

        System.assertEquals(null, newPMRA.Hazard_Assessment_Approval_Date__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra3 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Risk Evaluation in Process',
                CMPL123_WF_Action__c = 'Risk Evaluation Reject',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id,
                Risk_Evaluation_Rejection_Reason__c = 'test reason'
        ), true);

        newPMRA = [SELECT Id, Risk_Evaluation_Exec_Quality_Approved_By__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra3.Id];

        System.assertEquals(null, newPMRA.Risk_Evaluation_Exec_Quality_Approved_By__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra4 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Pending Risk Control Measure Recommendation',
                CMPL123_WF_Action__c = 'Site/Supply Chain QA Head Approval',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        newPMRA = [SELECT Id, Risk_Evaluation_Exec_Quality_Approved_By__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra4.Id];

        System.assertEquals(actionPerformedBy, newPMRA.Risk_Evaluation_Exec_Quality_Approved_By__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra5 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks',
                CMPL123_WF_Action__c = 'DVP Medical Affairs Approval',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        newPMRA = [SELECT Id, DVP_Medical_Affairs_Approval_By__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra5.Id];

        System.assertEquals(actionPerformedBy, newPMRA.DVP_Medical_Affairs_Approval_By__c);

        Test.stopTest();
    }

    /*
    * @Method       : executeLogicFromWFRulesTestPartC.
    * @Description  : Method to test logic migrated from WF Rules to Apex.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void executeLogicFromWFRulesTestPartC() {
        Profile aspenUserProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];

        User ceiUser = TestUtil.insertTestUser(
            aspenUserProfile.Id,
            'raj@test.com',
            'cei@test.com',
            'PEA4'
        );

        Post_Market_Risk_Assessment_Risk_Contr__c pmra = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks',
                CMPL123_WF_Action__c = 'DVP Regulatory Affairs Approval',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

        Test.startTest();

        Post_Market_Risk_Assessment_Risk_Contr__c newPMRA = [SELECT Id, DVP_Regulatory_Affairs_Approval_By__c
                                                                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                                                                WHERE Id = :pmra.Id];

        System.assertEquals(actionPerformedBy, newPMRA.DVP_Regulatory_Affairs_Approval_By__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra2 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks',
                CMPL123_WF_Action__c = 'Director Core Global Service Operations Approval',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        newPMRA = [SELECT Id, Director_Core_Global_Service_Ops_By__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra2.Id];

        System.assertEquals(actionPerformedBy, newPMRA.Director_Core_Global_Service_Ops_By__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra3 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Pending Risk Control Measure Recommendation',
                CMPL123_WF_Action__c = 'QA Manager Approval',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        newPMRA = [SELECT Id, QA_Manager_Approval_By__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra3.Id];

        System.assertEquals(actionPerformedBy, newPMRA.QA_Manager_Approval_By__c);

        Post_Market_Risk_Assessment_Risk_Contr__c pmra4 = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale',
                Is_a_Risk_Control_Measure_Required__c = 'Yes',
                Proposed_Risk_Control_Measure_Rationale__c = 'test',
                Reportability_Decision__c = 'Reportable',
                Rationalle_for_Reportability_Decision__c = 'test',
                Is_a_21_CFR_806_Report_required__c = 'Yes',
                MDR_needed_for_reportable_RCM__c = 'Yes',
                Is_the_MDR_a_5_day_or_30_day_MDR__c = '5-day',
                Risk_Control_Measure_Recommendation_Rati__c = 'test rationale',
                CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks',
                CMPL123_WF_Action__c = 'DVP Quality Assurance Approval',
                Is_HHR_greater_than_documented_in_RMF__c = 'Yes',
                Overall_Health_Hazard_Risk_Level__c = 'Medium',
                Risk_Evaluation_Quality_Approver__c = UserInfo.getUserId(),
                Risk_Evaluation_Exec_Quality_Approver__c = ceiUser.Id
        ), true);

        newPMRA = [SELECT Id, DVP_Quality_Assurance_Approval_By__c
                    FROM Post_Market_Risk_Assessment_Risk_Contr__c
                    WHERE Id = :pmra4.Id];

        System.assertEquals(actionPerformedBy, newPMRA.DVP_Quality_Assurance_Approval_By__c);

        Test.stopTest();
    }

    /*
    * @Method       : autoCreateRiskAsstChildRecordTest.
    * @Description  : Method to test lautoCreateRiskAsstChildRecord() method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void autoCreateRiskAsstChildRecordTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c pmra = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                CMPL123_WF_Status__c = 'Hazard Assessment In Process',
                CMPL123_WF_Action__c = 'Promote to Hazard Assessment',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan',
                Initial_Hazard_Assessment_By__c = UserInfo.getUserId(),
                Rationale_if_No_Hazards_Are_Identified__c = 'test rationale'
        ), true);

        Test.startTest();
        pmra.Is_Auto_Hazard_Assessment_Created__c = false;
        update pmra;

        System.assertEquals(
            1,
            [SELECT Id
                FROM Hazard_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c = :pmra.Id].size()
        );

        Test.stopTest();
    }
}