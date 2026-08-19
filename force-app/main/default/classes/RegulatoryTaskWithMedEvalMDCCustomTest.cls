/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 14-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    XX-XXX-XXXX            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    10-JUN-2020            N/A                  Updated code part, which is related to Users' insertion. This
*                                                                      change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                      deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class RegulatoryTaskWithMedEvalMDCCustomTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    private static void setup() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get('Complaint')
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId,
                CMSNext_Ticket_Number__c = 'TicketNumber',
                Country_of_origin__c = 'USA'),
            true
        );
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c
            .getRecordTypeInfosByName()
            .get('Initial')
            .getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(
                RecordTypeId = assmntRTId,
                CMPL123CME__Complaint__c = complaint.Id,
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'Regulatory',
                Reportability__c = 'Reportable',
                Reportability_Category__c = 'Always Reportable',
                Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)),
            true
        );
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User ssTestUser = TestUtil.insertTestUser(aspenInteg, 'ssAspTestUser2@test.com', 'ssAspTestUser2@test.com');
        System.runAs(ssTestUser) {
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'),
                true
            );
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'),
                true
            );
            Country__c objCountry = (Country__c) TestDataFactory.createSObject(
                new Country__c(Primary_Vigilance_Contact__c = UserInfo.getUserId(), Report_Type__c ='MDI'),
                true
            );
            Country__c objCountry2 = (Country__c) TestDataFactory.createSObject(
                new Country__c(Primary_Vigilance_Contact__c = UserInfo.getUserId(), Report_Type__c ='EUMIR', Country_Name__c='Germany',Active__c = TRUE),
                true
            );
            Country_Backup_Vigilance_Contact__c vigCon = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(
                new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = UserInfo.getUserId(), Country__c = objCountry.Id), true);
            Country_Backup_Vigilance_Contact__c vigCon2 = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(
                new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = UserInfo.getUserId(), Country__c = objCountry2.Id), true);
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                    Name = '30 Days',
                    Calendar_Days__c = 30,
                    Country__c = objCountry.Id),
                true
            );
            Country_Submission_Type__c objCountrySubmissionType2 = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                    Name = '30 Days',
                    Calendar_Days__c = 30,
                    Country__c = objCountry2.Id),
                true
            );
            CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                    Medical_Evaluation__c = questionnaireRecord.Id,
                    Product__c = prodTckt.Id,
                    Country__c = objCountry.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Regulatory_Evaluator__c = [SELECT Id FROM User WHERE Username like 'ssAspTestUser2@test.com%' LIMIT 1].Id,
                    Submission_Type__c = objCountrySubmissionType.Id,
                    Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
                    CMPL123_WF_Status__c = 'Opened'),
                true
            );
            CMPL123CME__EU_MIR__c euMIRRecord = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
                new CMPL123CME__EU_MIR__c(
                    MedicalEvaluation__c = questionnaireRecord.Id,
                    Product__c = prodTckt.Id,
                    Country__c = objCountry2.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Medical_Evaluator__c = [SELECT Id FROM User WHERE Username like 'ssAspTestUser2@test.com%' LIMIT 1].Id,
                    Submission_Type__c = objCountrySubmissionType2.Id,
                    Date_Due__c = Date.newInstance(2021, 07, 28),
                    CMPL123_WF_Status__c = 'Opened',
                	CMPL123CME__Device_Has_Been_Placed_On_Market_Before__c = 'This device has been placed on the market before the implementation of the MDD/AIMDD/IVDD'),
                true
            );
            CMPL123CME__EU_MIR__c euMIRRecord2 = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
                new CMPL123CME__EU_MIR__c(
                    MedicalEvaluation__c = questionnaireRecord.Id,
                    Product__c = prodTckt.Id,
                    Country__c = objCountry2.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Medical_Evaluator__c = [SELECT Id FROM User WHERE Username like 'ssAspTestUser2@test.com%' LIMIT 1].Id,
                    Submission_Type__c = objCountrySubmissionType2.Id,
                    Date_Due__c = Date.newInstance(2021, 07, 28),
                    CMPL123_WF_Status__c = 'Opened',
                	CMPL123CME__Device_Has_Been_Placed_On_Market_Before__c = 'This device has been placed on the market before the implementation of the MDD/AIMDD/IVDD'),
                true
            );
            Id regOpinionTaskRTID = Schema.SObjectType.Regulatory_Task__c
                .getRecordTypeInfosByName()
                .get('Regulatory Opinion Task')
                .getRecordTypeId();
            insert new Regulatory_Task__c(
                RecordTypeId = regOpinionTaskRTID,
                MDI__c = meddevRecord.Id,
                CMPL123_WF_Action__c = 'New',
            	Assignee_Name__c = UserInfo.getUserId());
            TestUtil.setupMDC(
                RegulatoryTaskWithMedEvalMDCCustom.class,
                Regulatory_Task__c.getSObjectType(),
                Regulatory_Task__c.CMPL123_WF_Action__c
            );
            insert new Regulatory_Task__c(
                RecordTypeId = regOpinionTaskRTID,
                MDI__c = meddevRecord.Id,
                CMPL123_WF_Action__c = 'Submit',
            	Assignee_Name__c = UserInfo.getUserId());
            TestUtil.setupMDC(
                RegulatoryTaskWithMedEvalMDCCustom.class,
                Regulatory_Task__c.getSObjectType(),
                Regulatory_Task__c.CMPL123_WF_Action__c
            );
            insert new Regulatory_Task__c(
                RecordTypeId = regOpinionTaskRTID,
                EU_MIR__c = euMIRRecord.Id,
                CMPL123_WF_Action__c = 'New',
            	Assignee_Name__c = UserInfo.getUserId());
            TestUtil.setupMDC(
                RegulatoryTaskWithMedEvalMDCCustom.class,
                Regulatory_Task__c.getSObjectType(),
                Regulatory_Task__c.CMPL123_WF_Action__c
            );
            insert new Regulatory_Task__c(
                RecordTypeId = regOpinionTaskRTID,
                EU_MIR__c = euMIRRecord2.Id,
                CMPL123_WF_Action__c = 'New',
            	Assignee_Name__c = UserInfo.getUserId());
            TestUtil.setupMDC(
                RegulatoryTaskWithMedEvalMDCCustom.class,
                Regulatory_Task__c.getSObjectType(),
                Regulatory_Task__c.CMPL123_WF_Action__c
            );
        }

    }
    
    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test() {
        //TWD Upgrade BEGIN
        Id competentRTID = Schema.SObjectType.Regulatory_Task__c
                .getRecordTypeInfosByName()
                .get('Competent Authority Regulatory Response')
                .getRecordTypeId();
        Id regulatoryRTID = Schema.SObjectType.Regulatory_Task__c
                .getRecordTypeInfosByName()
                .get('Regulatory Opinion Task')
                .getRecordTypeId();
        Regulatory_Task__c regulatoryTask2 = [SELECT Id FROM Regulatory_Task__c WHERE RecordTypeId =:regulatoryRTID AND EU_MIR__c != NULL LIMIT 1];
        //TWD Upgrade END
        
        Test.startTest();
        List<Regulatory_Task__c> listToUpdate = new List<Regulatory_Task__c>();
        regulatoryTask2.CMPL123_WF_Action__c = 'Complete';
        regulatoryTask2.CMPL123_WF_Status__c = 'Closed-Done';
        regulatoryTask2.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTask2.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        regulatoryTask2.Medical_Evaluator__c = UserInfo.getUserId();
        regulatoryTask2.Due_Date__c = Date.newInstance(2021, 07, 28);
        regulatoryTask2.MDI_required__c = 'No';
        regulatoryTask2.Issue_Summary__c = 'Issue Summary Test';
        regulatoryTask2.Question__c = 'Does the following event meet reporting criteria in your country and require an MDI report from MEG?';
        listToUpdate.add(regulatoryTask2);
        update listToUpdate;
        Regulatory_Task__c regulatoryTask3 = [SELECT Id FROM Regulatory_Task__c WHERE RecordTypeId =:regulatoryRTID AND EU_MIR__c != NULL AND CMPL123_WF_Action__c = 'New' LIMIT 1];
        regulatoryTask3.CMPL123_WF_Action__c = 'Submit';
        regulatoryTask3.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTask3.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        regulatoryTask3.Medical_Evaluator__c = UserInfo.getUserId();
        regulatoryTask3.Due_Date__c = Date.newInstance(2021, 07, 28);
        regulatoryTask3.MDI_required__c = 'No';
        regulatoryTask3.Issue_Summary__c = 'Issue Summary Test';
        regulatoryTask3.Question__c = 'Does the following event meet reporting criteria in your country and require an MDI report from MEG?';
        Regulatory_Task__c regulatoryTask4 = [SELECT Id FROM Regulatory_Task__c WHERE RecordTypeId =:regulatoryRTID AND MDI__c != NULL AND CMPL123_WF_Action__c = 'New' LIMIT 1];
        regulatoryTask4.CMPL123_WF_Action__c = 'Submit';
        regulatoryTask4.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTask4.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        regulatoryTask4.Medical_Evaluator__c = UserInfo.getUserId();
        regulatoryTask4.Due_Date__c = Date.newInstance(2021, 07, 28);
        regulatoryTask4.MDI_required__c = 'No';
        regulatoryTask4.Issue_Summary__c = 'Issue Summary Test';
        regulatoryTask4.Question__c = 'Does the following event meet reporting criteria in your country and require an MDI report from MEG?';
        Regulatory_Task__c regulatoryTask5 = [SELECT Id FROM Regulatory_Task__c WHERE RecordTypeId =:regulatoryRTID AND MDI__c != NULL AND CMPL123_WF_Action__c = 'Submit' LIMIT 1];
        regulatoryTask5.CMPL123_WF_Status__c = 'Closed-Done';
        regulatoryTask5.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTask5.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        regulatoryTask5.Medical_Evaluator__c = UserInfo.getUserId();
        regulatoryTask5.Due_Date__c = Date.newInstance(2021, 07, 28);
        regulatoryTask5.MDI_required__c = 'No';
        regulatoryTask5.Issue_Summary__c = 'Issue Summary Test';
        regulatoryTask5.Question__c = 'Does the following event meet reporting criteria in your country and require an MDI report from MEG?';
        listToUpdate.clear();
        listToUpdate.add(regulatoryTask3);
        listToUpdate.add(regulatoryTask4);
        listToUpdate.add(regulatoryTask5);
        update listToUpdate;
        Test.stopTest();
    }
    /**
    * @Method       : test2
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test2() {
        //TWD Upgrade BEGIN
        Id regulatoryRTID = Schema.SObjectType.Regulatory_Task__c
                .getRecordTypeInfosByName()
                .get('Regulatory Opinion Task')
                .getRecordTypeId();
        Test.startTest();
        String serviceRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get('Service')
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                RecordTypeId = serviceRTId,
                CMSNext_Ticket_Number__c = 'TestContent',
                Country_of_origin__c = 'USA'),
            true
        );
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c
            .getRecordTypeInfosByName()
            .get('Initial')
            .getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(
                RecordTypeId = assmntRTId,
                CMPL123CME__Complaint__c = complaint.Id,
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'Regulatory',
                Reportability__c = 'Reportable',
                Reportability_Category__c = 'Always Reportable',
                Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)),
            true
        );
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User ssTestUser = TestUtil.insertTestUser(aspenInteg, 'ssAspTestUser2@test.com', 'ssAspTestUser2@test.com');
        System.runAs(ssTestUser) {
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'),
                true
            );
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'),
                true
            );
            Country__c objCountry = (Country__c) TestDataFactory.createSObject(
                new Country__c(Primary_Vigilance_Contact__c = UserInfo.getUserId(), Report_Type__c ='MDI'),
                true
            );
            Country__c objCountry2 = (Country__c) TestDataFactory.createSObject(
                new Country__c(Primary_Vigilance_Contact__c = UserInfo.getUserId(), Report_Type__c ='EUMIR', Country_Name__c='Germany',Active__c = TRUE),
                true
            );
            Country_Backup_Vigilance_Contact__c vigCon = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(
                new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = UserInfo.getUserId(), Country__c = objCountry.Id), true);
            Country_Backup_Vigilance_Contact__c vigCon2 = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(
                new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = UserInfo.getUserId(), Country__c = objCountry2.Id), true);
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                    Name = '30 Days',
                    Calendar_Days__c = 30,
                    Country__c = objCountry.Id),
                true
            );
            Country_Submission_Type__c objCountrySubmissionType2 = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                    Name = '30 Days',
                    Calendar_Days__c = 30,
                    Country__c = objCountry2.Id),
                true
            );
            CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                    Medical_Evaluation__c = questionnaireRecord.Id,
                    Product__c = prodTckt.Id,
                    Country__c = objCountry.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Regulatory_Evaluator__c = [SELECT Id FROM User WHERE Username like 'ssAspTestUser2@test.com%' LIMIT 1].Id,
                    Submission_Type__c = objCountrySubmissionType.Id,
                    Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
                    CMPL123_WF_Status__c = 'Status_Opened'),
                true
            );
        	CMPL123CME__MEDDEV__c mdiRec = [Select Id from CMPL123CME__MEDDEV__c WHERE CMPL123_WF_Status__c = 'Status_Opened' LIMIT 1];
            mdiRec.CMPL123_WF_Status__c = 'Pending Regulatory Decision';
            mdiRec.Regulatory_Evaluator__c = UserInfo.getUserId();
            update mdiRec;
            insert new Regulatory_Task__c(
                RecordTypeId = regulatoryRTID,
                MDI__c = meddevRecord.Id,
                CMPL123_WF_Status__c = 'Opened',
                CMPL123_WF_Action__c = 'Void',
                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                Assignee_Name__c = UserInfo.getUserId());
            TestUtil.setupMDC(
                RegulatoryTaskWithMedEvalMDCCustom.class,
                Regulatory_Task__c.getSObjectType(),
                Regulatory_Task__c.CMPL123_WF_Action__c
            );
        }
        Regulatory_Task__c regulatoryTask6 = [SELECT Id FROM Regulatory_Task__c WHERE RecordTypeId =:regulatoryRTID AND MDI__c != NULL AND CMPL123_WF_Status__c = 'Opened' LIMIT 1];
        regulatoryTask6.CMPL123_WF_Status__c = 'Closed-Done';
        regulatoryTask6.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTask6.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        regulatoryTask6.Medical_Evaluator__c = UserInfo.getUserId();
        regulatoryTask6.Due_Date__c = Date.newInstance(2021, 07, 28);
        regulatoryTask6.MDI_required__c = 'No';
        regulatoryTask6.Issue_Summary__c = 'Issue Summary Test';
        regulatoryTask6.Question__c = 'Does the following event meet reporting criteria in your country and require an MDI report from MEG?';
        update regulatoryTask6;
        regulatoryTask6.CMPL123_WF_Action__c = 'Reopen';
        update regulatoryTask6;
        Test.stopTest();
    }
}