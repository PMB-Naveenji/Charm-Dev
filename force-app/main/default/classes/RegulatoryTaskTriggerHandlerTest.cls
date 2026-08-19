/*
* @why  : RegulatoryTaskTriggerHandlerTest class for the ADDRegulatoryTaskTriggerHandler,
* @when : CreatedDate : 15-DEC-2018         
* @what : Test Class.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID        Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    03-05-2020             Def #1 fix             Added Regulatory Opinion Task record.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    10-Jun-2020            N/A                    Updated code part, which is related to Users' insertion. 
*                                                                          This change designed to prevent a 'DUPLICATE_USERNAME' error 
*                                                                          during  deployment to Production environment.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    13-JAN-2021            TWD Upgrade             Moved Prod Eval SF WF Rules into apex. Added
*                                                                           wfFieldUpdateTest test method.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Charm COE                26-AUG-2025            CHaRM R7/IPDR 681       Added new methods "testMDIFieldsAutofillOnClosedDone" and "testEUMIRFieldsAutofillOnClosedDone"
*                                                                           to test 'Regulatory Task After Insert/Update' flow when RegulatoryTask record is moved to 
*																			'Closed-Done' and either MDI__c field or EU_MIR__c field is not null.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class RegulatoryTaskTriggerHandlerTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup static void setup() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        User user1 = TestUtil.insertTestUser(profileId, 'aspUserRT@test.com', 'aspUserRT@test.com');
        user1.Belongs_to_Text__c = 'PEI3';
        update user1;
               
        User user2 = TestUtil.insertTestUser(profileId, 'aspUserRT2@test.com', 'aspUserRT2@test.com');
        user2.Belongs_to_Text__c = 'PEA2,PEA4';
        update user2;        
        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(
                new Country__c(
                        Country_Region__c = 'Test',
                        Primary_Vigilance_Contact__c = user1.Id
                ), true);

        //Create Country Backup Vigilance Contact 
        Country_Backup_Vigilance_Contact__c objCountryBackupVigilanceContact =
                (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(
                        new Country_Backup_Vigilance_Contact__c(
                                Country__c = objCountry.Id,
                                Country_Backup_Vigilance_Contact_Name__c = user2.Id
                        ), true);

        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        TestUtil.insertTestUser(aspenInteg, 'aspenUserIntegRT@test.com', 'aspenUserIntegRT@test.com');
    }

    /*
    * @Method       : afterEventHandlerTestMethod.
    * @Description  : To test the Regulatory_Task_AuditTrigger functionality.
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    public static void afterEventHandlerTestMethod() {


//        User objUserMainContact = [SELECT Id FROM User WHERE LastName = 'MainContact' LIMIT 1];
        User objUserBackupContact = [SELECT Id FROM User WHERE Username Like 'aspUserRT2@test.com%' LIMIT 1];
        User aspenInteg = [SELECT Id FROM User WHERE Username Like 'aspenUserIntegRT@test.com%' LIMIT 1];

        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Primary_Vigilance_Contact__c = objUserBackupContact.id), true);

        //Create Country - Backup Vigilance Contact
        Country_Backup_Vigilance_Contact__c vigilanceCountryContact = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = objUserBackupContact.id,
                Country__c = objCountry.id), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId,
                Country_of_origin__c = 'USA',
                CMSNext_Ticket_Number__c = '123test'), true);

        List< Regulatory_Task__c > newRegTasks = new List< Regulatory_Task__c>();
        //CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(CMPL123_WF_Status__c = 'Regulatory',Reportability_Rationale__c = 'Test',Reportability__c = 'Non-Reportable',Reportability_Category__c = 'Adverse Event'), true);

        // Create Assessment 
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = assmntRTId,
                CMPL123CME__Complaint__c = complaint.Id,
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'Regulatory',
                Reportability__c = 'Reportable',
                Reportability_Category__c = 'Always Reportable',
                Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)
        ), true);

        System.runAs(aspenInteg) {

            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            //Create Product ticket
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objCountry.Id), true);

            //	CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(Medical_Evaluation__c = questionnaireRecord.Id, Country__c = objCountry.Id), true);

            //Create MDI
            CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
                    Medical_Evaluation__c = questionnaireRecord.Id,
                    Product__c = prodTckt.id,
                    Country__c = objCountry.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Regulatory_Evaluator__c = [SELECT id FROM User WHERE Username Like 'aspUserRT2@test.com%' LIMIT 1].id,
                    Submission_Type__c = objCountrySubmissionType.Id,
                    Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
                    CMPL123_WF_Status__c = 'Opened'), true);

            meddevRecord.CMPL123_WF_Status__c = 'Pending Regulatory Decision';

            test.startTest();

            Update meddevRecord;

            meddevRecord.Waived_Rationale__c = 'Test';

            Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Competent Authority Regulatory Response').getRecordTypeId();

            Id regulatoryOpinionRTId = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName()
                    .get('Regulatory Opinion Task').getRecordTypeId();


            //TODO : find a workaround for the Regulatory_Task_AuditTrigger coverage as the flag would be false on insertion of MEDDEV
            UpdateParentUtility.flag = true;

            //Create a Regulatory Task
            Regulatory_Task__c regulatoryTaskRecord = (Regulatory_Task__c) TestDataFactory.createSObject(new Regulatory_Task__c(RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                    MDI__c = meddevRecord.Id
            ), true);// CMPL123_WF_Status__c = 'Opened'

            Regulatory_Task__c regulatoryTaskRecord2 = (Regulatory_Task__c) TestDataFactory.createSObject(new Regulatory_Task__c(RecordTypeId = regulatoryOpinionRTId,
                    MDI__c = meddevRecord.Id
            ), true);
            Regulatory_Task__c regulatoryTaskRecordInserted = [SELECT Registration_Number__c, CMPL123Rule_Key_Value__c FROM Regulatory_Task__c
                                                                WHERE Id = :regulatoryTaskRecord.Id];
            Regulatory_Task__c regulatoryTaskRecordInserted2 = [SELECT Registration_Number__c, CMPL123Rule_Key_Value__c FROM Regulatory_Task__c
                                                                WHERE Id = :regulatoryTaskRecord2.Id];
            String registrationNumberExpected = complaint.CMSNext_Ticket_Number__c + '(' + 'Complaint' + ')';
            System.assertEquals(regulatoryTaskRecord.Assignee_Name__c, regulatoryTaskRecord.Vigilance_Contact_Formula__c);
            // Autoset Registration Number WF Rule Test
            System.assertEquals(registrationNumberExpected, regulatoryTaskRecordInserted.Registration_Number__c);
            // Other Regulatory Opinion Tasks Workflow Update WF Rule Test
            System.assertEquals('REGULATORY_TASK_OTHER_WORKFLOW', regulatoryTaskRecordInserted.CMPL123Rule_Key_Value__c);
            System.assertEquals('REGULATORY_TASK_WORKFLOW', regulatoryTaskRecordInserted2.CMPL123Rule_Key_Value__c);


            regulatoryTaskRecord.MDI__c = meddevRecord.Id;
            regulatoryTaskRecord.CMPL123_WF_Status__c = 'Closed-Done';
            regulatoryTaskRecord.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
            //regulatoryTaskRecord.Other_Justification__c = 'Test';
            regulatoryTaskRecord.Regulatory_Agency_Notification_Required__c = 'No';
            regulatoryTaskRecord.Assignee_Name__c = objUserBackupContact.id;
            newRegTasks.add(regulatoryTaskRecord);

            //TODO : find a workaround for the Regulatory_Task_AuditTrigger coverage as the flag would be false on insertion of MEDDEV
            UpdateParentUtility.flag = true;

            Update regulatoryTaskRecord;
            Regulatory_Task__c regulatoryTaskRecordUpdated = [SELECT Task_Item_Completion_Date__c FROM Regulatory_Task__c 
                                                                WHERE Id = :regulatoryTaskRecord.Id];
            // Autoset Task Item Completion Date WF Rule test
            System.assertEquals(System.today(), regulatoryTaskRecordUpdated.Task_Item_Completion_Date__c.date());

            Set<String> medDevIds = new Set<String>();
            medDevIds.add(regulatoryTaskRecord.MDI__c);
            regulatoryTaskRecord.MDI__c = meddevRecord.Id;
            regulatoryTaskRecord.CMPL123_WF_Status__c = 'Closed-Done';
            regulatoryTaskRecord.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
            //regulatoryTaskRecord.Other_Justification__c = 'Test';
            regulatoryTaskRecord.Regulatory_Agency_Notification_Required__c = 'No';
            regulatoryTaskRecord.Assignee_Name__c = objUserBackupContact.id;
            newRegTasks.clear();
            newRegTasks.add(regulatoryTaskRecord);

            //TODO : find a workaround for the Regulatory_Task_AuditTrigger coverage as the flag would be false on insertion of MEDDEV
            UpdateParentUtility.flag = true;

            Update newRegTasks;

            Delete newRegTasks;

            test.stopTest();
        }
    }

    /*
    * @Method       : wfFieldUpdateTest.
    * @Description  : To test logic from moved to apex SF WF Rules.
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    public static void wfFieldUpdateTest() {
        User objUserBackupContact = [SELECT Id FROM User WHERE Username Like 'aspUserRT2@test.com%' LIMIT 1];
        User aspenInteg = [SELECT Id FROM User WHERE Username Like 'aspenUserIntegRT@test.com%' LIMIT 1];

        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Primary_Vigilance_Contact__c = objUserBackupContact.id), true);

        //Create Country - Backup Vigilance Contact
        Country_Backup_Vigilance_Contact__c vigilanceCountryContact = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = objUserBackupContact.id,
                Country__c = objCountry.id), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId,
                Country_of_origin__c = 'USA',
                CMSNext_Ticket_Number__c = '123test'), true);

        List< Regulatory_Task__c > newRegTasks = new List< Regulatory_Task__c>();
        //CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(CMPL123_WF_Status__c = 'Regulatory',Reportability_Rationale__c = 'Test',Reportability__c = 'Non-Reportable',Reportability_Category__c = 'Adverse Event'), true);

        // Create Assessment
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = assmntRTId,
                CMPL123CME__Complaint__c = complaint.Id,
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'Regulatory',
                Reportability__c = 'Reportable',
                Reportability_Category__c = 'Always Reportable',
                Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)
        ), true);

        System.runAs(aspenInteg) {

            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            //Create Product ticket
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);

            CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
                    Medical_Evaluation__c = questionnaireRecord.Id,
                    Product__c = prodTckt.id,
                    Country__c = objCountry.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Regulatory_Evaluator__c = [SELECT id FROM User WHERE Username Like 'aspUserRT2@test.com%' LIMIT 1].id,
                    Submission_Type__c = objCountrySubmissionType.Id,
                    Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
                    CMPL123_WF_Status__c = 'Opened'), true);

            test.startTest();
            Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName()
                        .get('Competent Authority Regulatory Response').getRecordTypeId();

            // Create a Regulatory Task
            Regulatory_Task__c regulatoryTaskRecord = (Regulatory_Task__c) TestDataFactory.createSObject(
                new Regulatory_Task__c(
                        RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                        MDI__c = meddevRecord.Id
                ), true);

            regulatoryTaskRecord.CMPL123_WF_Status__c = 'In Progress';
            regulatoryTaskRecord.Assignee_Name__c = objUserBackupContact.id;

            update regulatoryTaskRecord;
            Regulatory_Task__c regulatoryTaskRecordUpdated = [SELECT Assigned_Date__c FROM Regulatory_Task__c 
                                                                WHERE Id = :regulatoryTaskRecord.Id];
            // Autoset Assigned Date WF Rule test
            System.assertEquals(System.today(), regulatoryTaskRecordUpdated.Assigned_Date__c);

            regulatoryTaskRecord.CMPL123_WF_Action__c = 'Submit';
            regulatoryTaskRecord.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
            update regulatoryTaskRecord;
            regulatoryTaskRecordUpdated = [SELECT Submitted_On__c FROM Regulatory_Task__c 
                                                                WHERE Id = :regulatoryTaskRecord.Id];
            // Workflow - Submit WF Rule test
            System.assertEquals(regulatoryTaskRecord.CMPL123_WF_Action_Performed_On__c, regulatoryTaskRecordUpdated.Submitted_On__c);

            regulatoryTaskRecord.CMPL123_WF_Action__c = 'Void';
            regulatoryTaskRecord.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
            update regulatoryTaskRecord;
            regulatoryTaskRecordUpdated = [SELECT Voided_On__c FROM Regulatory_Task__c 
                                                                WHERE Id = :regulatoryTaskRecord.Id];
            // Workflow - Void WF Rule test
            System.assertEquals(regulatoryTaskRecord.CMPL123_WF_Action_Performed_On__c, regulatoryTaskRecordUpdated.Voided_On__c);

            regulatoryTaskRecord.CMPL123_WF_Action__c = 'Reopen';
            regulatoryTaskRecord.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
            update regulatoryTaskRecord;
            regulatoryTaskRecordUpdated = [SELECT Reopened_On__c FROM Regulatory_Task__c 
                                                                WHERE Id = :regulatoryTaskRecord.Id];
            // Workflow - Reopen WF Rule test
            System.assertEquals(regulatoryTaskRecord.CMPL123_WF_Action_Performed_On__c, regulatoryTaskRecordUpdated.Reopened_On__c);
            test.stopTest();
        }
    }
    
    /*
    * @Method       : testMDIFieldsAutofillOnClosedDone.
    * @Description  : To test 'Regulatory Task After Insert/Update' flow when RegulatoryTask record is moved to 'Closed-Done' and MDI__c field is not null
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    public static void testMDIFieldsAutofillOnClosedDone() {
        User objUserBackupContact = [SELECT Id FROM User WHERE Username Like 'aspUserRT2@test.com%' LIMIT 1];
        User aspenInteg = [SELECT Id,FirstName,LastName FROM User WHERE Username Like 'aspenUserIntegRT@test.com%' LIMIT 1];

        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Primary_Vigilance_Contact__c = objUserBackupContact.id), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId,
                Country_of_origin__c = 'USA',
                CMSNext_Ticket_Number__c = '123test'), true);

        // Create Assessment
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = assmntRTId,
                CMPL123CME__Complaint__c = complaint.Id,
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'Regulatory',
                Reportability__c = 'Reportable',
                Reportability_Category__c = 'Always Reportable',
                Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)
        ), true);

        System.runAs(aspenInteg) {
            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            //Create Product ticket
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
			
            //Create MDI
            CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
                    Medical_Evaluation__c = questionnaireRecord.Id,
                    Product__c = prodTckt.id,
                    Country__c = objCountry.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Regulatory_Evaluator__c = [SELECT id FROM User WHERE Username Like 'aspUserRT2@test.com%' LIMIT 1].id,
                    Submission_Type__c = objCountrySubmissionType.Id,
                    Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
                    CMPL123_WF_Status__c = 'Opened'), true);

            Test.startTest();
            Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName()
                        .get('Competent Authority Regulatory Response').getRecordTypeId();

            // Create a Regulatory Task
            Regulatory_Task__c regulatoryTaskRecord = (Regulatory_Task__c) TestDataFactory.createSObject(
                new Regulatory_Task__c(
                        RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                        MDI__c = meddevRecord.Id
                ), true);

            regulatoryTaskRecord.CMPL123_WF_Status__c = 'Closed-Done';
            regulatoryTaskRecord.CMPL123_WF_Action__c = 'Complete';
            regulatoryTaskRecord.Medical_Evaluator__c = objUserBackupContact.id;
            regulatoryTaskRecord.Regulatory_Agency_Notification_Required__c = 'Yes';
            regulatoryTaskRecord.CMPL123_WF_Action_Performed_By__c = aspenInteg.Id;
            regulatoryTaskRecord.Regulatory_Agency__c = 'FDA';            
            regulatoryTaskRecord.Submission_Date__c = System.Today()-3;
            regulatoryTaskRecord.Task_Item_Completion_Date__c = System.now();
            update regulatoryTaskRecord;
            
            Regulatory_Task__c regulatoryTaskRecordUpdated = [SELECT Task_Item_Completed_By__c,Submission_Date__c,Task_Item_Completion_Date__c,CMPL123_WF_Action_Performed_By__c FROM Regulatory_Task__c  WHERE Id = :regulatoryTaskRecord.Id];
            CMPL123CME__MEDDEV__c meddevRecordUpdated = [SELECT Report_Submitter__c,Submitted_Date_new__c FROM CMPL123CME__MEDDEV__c WHERE Id = :meddevRecord.Id];
            //Assert to check - 'Report Submitter' field on MDI is auto-populated from the 'Task item completed by' field on the Regulatory Task when the workflow status is moved to 'Closed-Done'.
            System.assertEquals(regulatoryTaskRecordUpdated.Task_Item_Completed_By__c, meddevRecordUpdated.Report_Submitter__c);
            //Assert to check - 'Submitted Date' field on MDI is auto-populated from the 'Submission Date' field on the Regulatory Task when the workflow status is moved to 'Closed-Done'.
            System.assertEquals(regulatoryTaskRecordUpdated.Submission_Date__c, meddevRecordUpdated.Submitted_Date_new__c);
            //Assert to check - 'Submitted Date' field on MDI is not auto-populated from the 'Task Item Completion Date' field on the Regulatory Task when the workflow status is moved to 'Closed-Done'.
            System.assertNotEquals(regulatoryTaskRecordUpdated.Task_Item_Completion_Date__c, meddevRecordUpdated.Submitted_Date_new__c);
            Test.stopTest();
        }
    }
        
    /*
    * @Method       : testEUMIRFieldsAutofillOnClosedDone.
    * @Description  : To test 'Regulatory Task After Insert/Update' flow when RegulatoryTask record is moved to 'Closed-Done' and EU_MIR__c field is not null
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    public static void testEUMIRFieldsAutofillOnClosedDone() {
        User objUserBackupContact = [SELECT Id FROM User WHERE Username Like 'aspUserRT2@test.com%' LIMIT 1];
        User aspenInteg = [SELECT Id,FirstName,LastName FROM User WHERE Username Like 'aspenUserIntegRT@test.com%' LIMIT 1];

        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Primary_Vigilance_Contact__c = objUserBackupContact.id), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId,
                Country_of_origin__c = 'USA',
                CMSNext_Ticket_Number__c = '123test'), true);

        // Create Assessment
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(
                CMPL123CME__Complaint__c = complaint.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_Regulatory,
                Reportability__c = AspenConstants.REPORTABILITY_NO,
                Reportability_Category__c = 'RCML',
                Reportability_Rationale__c = 'Because there is sand in my shoe'
            ),
            true
        );

        System.runAs(aspenInteg) {
            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            //Create Product ticket
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
			
            //Create EU MIR
            CMPL123CME__EU_MIR__c euMirInitial =(CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
                new CMPL123CME__EU_MIR__c(
                    Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                    CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                    CMPL123CME__Type_of_Report__c = AspenConstants.STR_Initial_Report,
                    Date_Due__c = System.Today() + 120,
                    MedicalEvaluation__c = medEval.Id,
                    Product__c = prodTckt.Id,
                    CMPL123CME__Complaint__c = medEval.CMPL123CME__Complaint__c,
                    Registered_Site__c = prodTckt.Product__r.Registered_Site__c,
                    Country__c = prodTckt.Product__r.Registered_Site__r.MIR_MFR_Country__c
                ),
                true
        	);

            Test.startTest();
            Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName()
                        .get('Competent Authority Regulatory Response').getRecordTypeId();

            // Create a Regulatory Task
            Regulatory_Task__c regulatoryTaskRecord = (Regulatory_Task__c) TestDataFactory.createSObject(
                new Regulatory_Task__c(
                        RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                        EU_MIR__c = euMirInitial.Id
                ), true);

            regulatoryTaskRecord.CMPL123_WF_Status__c = 'Closed-Done';
            regulatoryTaskRecord.CMPL123_WF_Action__c = 'Complete';
            regulatoryTaskRecord.Medical_Evaluator__c = objUserBackupContact.id;
            regulatoryTaskRecord.Assignee_Name__c = objUserBackupContact.id;
            regulatoryTaskRecord.Regulatory_Agency_Notification_Required__c = 'Yes';
            regulatoryTaskRecord.CMPL123_WF_Action_Performed_By__c = aspenInteg.Id;
            regulatoryTaskRecord.Regulatory_Agency__c = 'FDA';            
            regulatoryTaskRecord.Submission_Date__c = System.Today()-3;
            regulatoryTaskRecord.Task_Item_Completion_Date__c = System.now();
            update regulatoryTaskRecord;
            
            Regulatory_Task__c regulatoryTaskRecordUpdated = [SELECT Task_Item_Completed_By__c,Submission_Date__c,Task_Item_Completion_Date__c,CMPL123_WF_Action_Performed_By__c FROM Regulatory_Task__c  WHERE Id = :regulatoryTaskRecord.Id];
            CMPL123CME__EU_MIR__c mirRecordUpdated = [SELECT Report_Submitter__c,Submitted_Date__c FROM CMPL123CME__EU_MIR__c WHERE Id = :euMirInitial.Id];            
            //Assert to check - 'Report Submitter' field on EU MIR is auto-populated from the 'Task item completed by' field on the Regulatory Task when the workflow status is moved to 'Closed-Done'.
            System.assertEquals(regulatoryTaskRecordUpdated.Task_Item_Completed_By__c, mirRecordUpdated.Report_Submitter__c);
            //Assert to check - 'Submitted Date' field on EU MIR is auto-populated from the 'Submission Date' field on the Regulatory Task when the workflow status is moved to 'Closed-Done'.
            System.assertEquals(regulatoryTaskRecordUpdated.Submission_Date__c, mirRecordUpdated.Submitted_Date__c);
            //Assert to check - 'Submitted Date' field on EU MIR is not auto-populated from the 'Task Item Completion Date' field on the Regulatory Task when the workflow status is moved to 'Closed-Done'.
            System.assertNotEquals(regulatoryTaskRecordUpdated.Task_Item_Completion_Date__c, mirRecordUpdated.Submitted_Date__c);
            Test.stopTest();
        }
    }

}