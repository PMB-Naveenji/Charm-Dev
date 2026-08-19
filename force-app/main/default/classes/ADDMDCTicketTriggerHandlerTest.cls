/*
* @why  : ADDMDCTicketTriggerHandlerTest class for the ADDMDCTicketTriggerHandler,
* @when : CreatedDate : 29-OCT-2018        ModifiedDate : 11-JAN-2021
* @what : Class to Handle Different scenarios from MDCTicketTrigger.
*  Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
*  Developer                Date                   Modification ID         Description
* --------------------------------------------------------------------------------------------------------------------------------------
*  rsitc                    10-JUN-2020            N/A                     Updated code part, which is related to Users' insertion.
*                                                                          This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                          error during deployment to Production environment
* --------------------------------------------------------------------------------------------------------------------------------------
*  DSkak                    28-DEC-2020            TWD Upgrade issue       Added 'executeLogicFromWFRulesTest()' method to test moved
*                                                                          logic from Workflow Rules with Field Updates on 
*                                                                          MDC Ticket to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*  RSlob                    11-JAN-2021            TWD Upgrade             TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
*  lresnik                  08-AUG-2021            CHaRM Release 2         Added setup data and methods to test ticket parents of varying types
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class ADDMDCTicketTriggerHandlerTest {

    //Method to create test data
    @testSetup static void setupData() {

        //Setting default custom settings
        ADD_App_Settings__c appSetting = new ADD_App_Settings__c();
        appSetting.Restrict_Workflow_Updates__c = false;
        appSetting.Name = 'User';
        appSetting.Restrict_Triggers__c = false;
        appSetting.Restrict_Validation_Rules__c = true;
        insert appSetting;

        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        //Create User
        User user = TestUtil.insertTestUser(
            sysAdminProfile.Id,
            'standarduser@test.com',
            'testaspen@test.com',
            'RA16'
        );

        //Create contacts
        List <Contact> contacts = new List <Contact> ();
        contacts.add(
            new Contact (
                Lastname = 'Business Admin',
                Email = 'test@test.com',
                Type__c = 'Group Contact'
            )
        );
        contacts.add(
            new Contact (
                Lastname = 'Adhoc Observation Assignee',
                Email = 'test@test.com',
                Type__c = 'Group Contact'
            )
        );
        insert contacts;

        //Create MDC_Trigger
        CMPL123__MDC_Trigger__c mdcTrigger = new CMPL123__MDC_Trigger__c (
            CMPL123__Select_Target_Object__c = 'Complaint__c',
            CMPL123__Criteria__c = 'Created or Changed',
            CMPL123__Logic__c = '1',
            CMPL123__Active__c = true
        );
        insert mdcTrigger;

        // Create Ticket
        Id complaintRecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaintRecord = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c (
                RecordTypeId = complaintRecordTypeId,
                CMSNext_Ticket_Number__c = '12345',
                CMSNext_Ticket_ID__c = '12345'
            ),
            true
        );

        // Create EU MIR for a Regulatory Task
        EUMIRTriggerHandlerTest.MirInitWrap mirInit = new EUMIRTriggerHandlerTest.MirInitWrap();
        mirInit.complaintId = complaintRecord.Id;
       /* CMPL123CME__EU_MIR__c euMir = EUMIRTriggerHandlerTest.makeEuMir(
            mirInit, AspenConstants.STR_Initial_Report, AspenConstants.STR_WF_Opened);
        insert euMir;

        // Create Regulatory Tasks for EU_MIR__c and MDI__c
        Regulatory_Task__c regTaskForEuMir = (Regulatory_Task__c) TestDataFactory.createSObject(
            new Regulatory_Task__c(
                EU_MIR__c = euMir.Id
            ),
            true
        );*/

        // Create an invalid Attachment (no parent ticket)
        Attachment__c attach = (Attachment__c) TestDataFactory.createSObject(
            new Attachment__c(
                Attachment_Type__c = 'Regulatory Correspondence'
            ),
            true
        );

        // // Create Attachment with a Regulatory Task for an MDI (not an EU MIR)
        // Attachment__c attach = (Attachment__c) TestDataFactory.createSObject(
        //     new Attachment__c(
        //         Attachment_Type__c = 'Regulatory Correspondence'
        //     ),
        //     true
        // );

        // Create an assessment for some records to reference
        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(
                CMPL123CME__Complaint__c = complaintRecord.Id
            ),
            true
        );

        // Create Medical Evaluation Task with an associated evaluation / assessment
        Medical_Evaluation_Task__c medEvalTask = (Medical_Evaluation_Task__c) TestDataFactory.createSObject(
            new Medical_Evaluation_Task__c(
                Medical_Evaluation__c = assessment.Id
            ),
            true
        );
    }

    /**
    * @Method       : testMDCsForEvaluatorInvestigator
    * @Description  : To test the MDCTicketTrigger functionality related to 'Evaluator/Investigator' public group.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testMDCsForEvaluatorInvestigator () {
        //Test-specific data
        String publicGroupName = 'Evaluator/Investigator';
        String flagAPIName = 'Evaluator_Investigator_Pending_MDCs__c';
        //Generic logic
        executeTestLogic(publicGroupName, flagAPIName);
    }

    /**
    * @Method       : testMDCsForMedicalEvaluator
    * @Description  : To test the MDCTicketTrigger functionality related to 'Medical Evaluator' public group.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testMDCsForMedicalEvaluator () {
        //Test-specific data
        String publicGroupName = 'Medical Evaluator';
        String flagAPIName = 'Med_Evaluator_Pending_MDCs__c';
        //Generic logic
        executeTestLogic(publicGroupName, flagAPIName);
    }

    /**
    * @Method       : testMDCsForProdEvalAccesssor
    * @Description  : To test the MDCTicketTrigger functionality related to 'Prod eval Assessor' public group.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testMDCsForProdEvalAccesssor () {
        //Test-specific data
        String publicGroupName = 'Prod eval Assessor';
        String flagAPIName = 'Prod_Eval_Assessor_Pending_MDCs__c';
        //Generic logic
        executeTestLogic(publicGroupName, flagAPIName);
    }

    /**
    * @Method       : testMDCsForFAQualityAssignee
    * @Description  : To test the MDCTicketTrigger functionality related to 'FA Quality Assignee' public group.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testMDCsForFAQualityAssignee () {
        //Test-specific data
        String publicGroupName = 'FA Quality Assignee';
        String flagAPIName = 'FA_Quality_Assignee_Pending_MDCs__c';
        //Generic logic
        executeTestLogic(publicGroupName, flagAPIName);
    }

    /**
    * @Method       : testMDCsForQualityNonComplaint
    * @Description  : To test the MDCTicketTrigger functionality related to 'Quality non Complaint' public group.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testMDCsForQualityNonComplaint () {
        //Test-specific data
        String publicGroupName = 'Quality non Complaint';
        String flagAPIName = 'Quality_Non_Complaint_Pending_MDCs__c';
        //Generic logic
        executeTestLogic(publicGroupName, flagAPIName);
    }

    /**
    * @Method       : testMDCsForAdhocQualityNonComplaintObservation
    * @Description  : To test the MDCTicketTrigger functionality related to 'Adhoc Quality Non Complaint Observation' public group.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testMDCsForAdhocQualityNonComplaintObservation () {
        //Test-specific data
        String publicGroupName = 'Adhoc Quality Non Complaint Observation';
        String flagAPIName = 'Adhoc_Quality_Non_Complaint_Pending_MDCs__c';
        //Generic logic
        executeTestLogic(publicGroupName, flagAPIName);
    }

    /**
    * @Method       : testMDCsForAdhocObservationAssignee
    * @Description  : To test the MDCTicketTrigger functionality related to 'Adhoc Observation Assignee' public group.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testMDCsForAdhocObservationAssignee () {
        //Test-specific data
        String publicGroupName = 'Adhoc Observation Assignee';
        String flagAPIName = 'Adhoc_Observation_Assignee_Pending_MDCs__c';
        //Generic logic
        executeTestLogic(publicGroupName, flagAPIName);
    }

    /**
    * @Method       : executeTestLogic
    * @Description  : Generic logic in scope of this test
    * @Return       : N/A
    * @Params       : N/A
    **/
    static void executeTestLogic (String publicGroupName, String flagAPIName) {
        //Get related records
        CMPL123CME__Complaint__c complaintRecord = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        CMPL123__MDC_Trigger__c mdcTrigger = [SELECT Id FROM CMPL123__MDC_Trigger__c LIMIT 1];

        //Adjust MDC trigger configuration
        mdcTrigger.Selected_Group_Name__c = publicGroupName;
        update mdcTrigger;

        //Create MDC Ticket to set flag on ticket
        Test.startTest();
        CMPL123__MDC_Ticket__c mdcTicket = new CMPL123__MDC_Ticket__c (
            CMPL123__Rule_Description__c  = 'MDC Ticket 1',
            CMPL123__Related_Record_Detail__c = '12345(Complaint)',
            CMPL123__MDC_Trigger__c = mdcTrigger.Id,
            Related_Ticket_Id__c = complaintRecord.Id,
            CMPL123__Related_Record_ID__c = complaintRecord.Id
        );
        insert mdcTicket;
        Test.stopTest();

        //Compose verification query
        String dbQuery = '';
        dbQuery += 'SELECT Id, ' + flagAPIName + ' ';
        dbQuery += 'FROM CMPL123CME__Complaint__c ';
        dbQuery += 'LIMIT 1';

        //Verify that related flag on ticket is set to true
        System.assertEquals(
            true,
            ((SObject) Database.query(dbQuery)).get(flagAPIName),
            flagAPIName + ' does not equal to false'
        );

        //Acknowledge MDC ticket
        mdcTicket.CMPL123__All_Acks_Received__c = true;
        update mdcTicket;

        //Verify that related flag on ticket is set to false
        System.assertEquals(
            false,
            ((SObject) Database.query(dbQuery)).get(flagAPIName),
            flagAPIName + ' does not equal to false'
        );

        //Delete MDC ticket
        delete mdcTicket;

        //Verify that MDC ticket is deleted
        System.assertEquals(
            0,
            [
                SELECT COUNT() 
                FROM CMPL123__MDC_Ticket__c
            ],
            'MDC was not deleted'
        );
    }

    /*
    * @Method       : executeLogicFromWFRulesTest.
    * @Description  : Method to test logic migrated from WF Rules to Apex.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void executeLogicFromWFRulesTest(){
        CMPL123CME__Complaint__c complaintRecord = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        CMPL123__MDC_Trigger__c mdcTrigger = new CMPL123__MDC_Trigger__c(
            CMPL123__Select_Target_Object__c = 'Complaint__c',
            CMPL123__Criteria__c = 'Created or Changed',
            CMPL123__Logic__c = '1',
            CMPL123__Active__c = true,
            Selected_Group_Name__c = 'Evaluator/Investigator',
            CMPL123__Description__c = 'test 123'
        );
        insert mdcTrigger;

      	Test.startTest();

        CMPL123__MDC_Ticket__c mdc = new CMPL123__MDC_Ticket__c(
            CMPL123__Rule_Description__c  = 'MDC Ticket 1',
            CMPL123__Related_Record_Detail__c = '12345(Complaint)',
            CMPL123__MDC_Trigger__c = mdcTrigger.Id,
            Related_Ticket_Id__c =  complaintRecord.Id,
            CMPL123__All_Acks_Received__c = true,
            CMPL123__Related_Record_ID__c = complaintRecord.Id
        );
        insert mdc;

        mdc.CMPL123__All_Acks_Received__c = false;
        update mdc;

        CMPL123__MDC_Ticket__c newMDCTicket = [SELECT Id, CMPL123__Description__c FROM CMPL123__MDC_Ticket__c WHERE Id = :mdc.Id];

        System.assertEquals(mdcTrigger.CMPL123__Description__c, newMDCTicket.CMPL123__Description__c);

        Test.stopTest();
    }

    /**
    * @Method       : testRelatedRecordForRegTask
    * @Description  : To test the MDCTicketTrigger functionality related to 'Regulatory_Task__c' related record.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testRelatedRecordForRegTask () {
        //Test-specific data
        String relatedRecordApiName = 'Regulatory_Task__c';
        //Generic logic
        //executeTestLogicForRelatedRecordId(relatedRecordApiName, false);
    }

    /**
    * @Method       : testRelatedRecordForAttachment
    * @Description  : To test the MDCTicketTrigger functionality related to 'Attachment__c' related record.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testRelatedRecordForAttachment () {
        //Test-specific data
        String relatedRecordApiName = 'Attachment__c';
        //Generic logic
        executeTestLogicForRelatedRecordId(relatedRecordApiName, true);
    }

    /**
    * @Method       : testRelatedRecordForMedEvalTask
    * @Description  : To test the MDCTicketTrigger functionality related to 'Medical_Evaluation_Task__c' related record.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testRelatedRecordForMedEvalTask () {
        //Test-specific data
        String relatedRecordApiName = 'Medical_Evaluation_Task__c';
        //Generic logic
        executeTestLogicForRelatedRecordId(relatedRecordApiName, false);
    }

    /**
    * @Method       : executeTestLogicForRelatedRecordId
    * @Description  : Generic logic for inserting a Ticket against varying RelatedRecords
    * @Return       : N/A
    * @Params       : N/A
    **/
    static void executeTestLogicForRelatedRecordId (String relatedRecordApiName, Boolean expectCrash) {
        String publicGroupName = 'Evaluator/Investigator';
        String flagAPIName = 'Evaluator_Investigator_Pending_MDCs__c';

        //Get related records
        String dbQuery = String.format(
            'SELECT Id FROM {0} LIMIT 1',
            new String[]{relatedRecordApiName}
        );
        SObject relatedRecord = Database.query(dbQuery);
        CMPL123CME__Complaint__c complaintRecord = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        CMPL123__MDC_Trigger__c mdcTrigger = [SELECT Id FROM CMPL123__MDC_Trigger__c LIMIT 1];

        //Adjust MDC trigger configuration
        mdcTrigger.Selected_Group_Name__c = publicGroupName;
        update mdcTrigger;

        //Create MDC Ticket to set flag on ticket
        Boolean crashed = false;
        Test.startTest();
        CMPL123__MDC_Ticket__c mdcTicket = new CMPL123__MDC_Ticket__c (
            CMPL123__Rule_Description__c  = 'MDC Ticket 1',
            CMPL123__Related_Record_Detail__c = '12345(Complaint)',
            CMPL123__MDC_Trigger__c = mdcTrigger.Id,
            Related_Ticket_Id__c = complaintRecord.Id,
            CMPL123__Related_Record_ID__c = (String) relatedRecord.get('Id')
        );
        try {
            insert mdcTicket;
        } catch (DmlException ex) {
            crashed = true;
        }
        Test.stopTest();

        System.assertEquals(expectCrash, crashed, 'Did (not) crash when expected');

        //Compose verification query
        // dbQuery = String.format(
        //     'SELECT Id, {0} FROM {1} LIMIT 1',
        //     new String[]{flagAPIName, relatedRecordApiName}
        // );

        // //Verify that related flag on ticket is set to true
        // System.assertEquals(
        //     true,
        //     ((SObject) Database.query(dbQuery)).get(flagAPIName),
        //     flagAPIName + ' does not equal to false'
        // );

        // //Acknowledge MDC ticket
        // mdcTicket.CMPL123__All_Acks_Received__c = true;
        // update mdcTicket;

        // //Verify that related flag on ticket is set to false
        // System.assertEquals(
        //     false,
        //     ((SObject) Database.query(dbQuery)).get(flagAPIName),
        //     flagAPIName + ' does not equal to false'
        // );

        // //Delete MDC ticket
        // delete mdcTicket;

        // //Verify that MDC ticket is deleted
        // System.assertEquals(
        //     0,
        //     [
        //         SELECT COUNT() 
        //         FROM CMPL123__MDC_Ticket__c
        //     ],
        //     'MDC was not deleted'
        // );
    }
}