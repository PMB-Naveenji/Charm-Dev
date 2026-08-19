/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright 2019  Capgemini.
* @What  : ADDRegulatoryTaskTriggerHandlerTest
* @Why   : Test class to get the code coverage for class ADDRegulatoryTaskTriggerHandler.
* @When  : 23-OCT-2019
* @Where : From ADDRegulatoryTaskTriggerHandlerTest 
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                23-OCT-2019              Sprint 4                Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*    Varsha Hariharan       06-JUL-2021              Charm Release 2      Modified code for EUMIR code coverage
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class ADDRegulatoryTaskTriggerHandlerTest {

    @isTest
    public static void setup2(){
        Id AspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
       User newUser1 = new User(ProfileId = AspenUserProfileId, LastName = 'admin1', Email = 'test0@0te0st.com',
                Username = 'test0@0te0st.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'TEST', Title = 'test', Alias = 'test', TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
        insert newUser1;
        User newUser2 = new User(ProfileId = AspenUserProfileId, LastName = 'admin2', Email = 'test1@1te1st.com',
                Username = 'test1@1te1st.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'TEST', Title = 'test', Alias = 'test', TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
        insert newUser2;
       User objUserMainContact = [SELECT Id FROM User WHERE LastName = 'admin1' LIMIT 1];
       User objUserBackupContact = [SELECT Id FROM User WHERE LastName = 'admin2' LIMIT 1];
        
        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Primary_Vigilance_Contact__c = objUserBackupContact.id), true);
        
        //Create Country - Backup Vigilance Contact
        Country_Backup_Vigilance_Contact__c vigilanceCountryContact = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = objUserBackupContact.id,
                                                                                                                                                                                  Country__c = objCountry.id), true);
        
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId,
            Country_of_origin__c = 'USA'), true);
        
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
        
        User user2 = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator Data Loader'].Id,
                LastName = 'test2',
                Email = 'test2@gmail.com',
                Username = 'test2@gmail.com' + System.currentTimeMillis(),
                CompanyName = 'TEST2',
                Title = 'title2',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10'
        ), true);
        
        System.runas(user2) {
        
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
        
        //  CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(Medical_Evaluation__c = questionnaireRecord.Id, Country__c = objCountry.Id), true);
        
        CMPL123CME__Registered_Site__c registeredSite = (CMPL123CME__Registered_Site__c) 
                TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                    CMPL123CME__Site_Name__c = 'Test Registered Site',
                    Division__c = 'ADD'),
                false
            );
        
        EUMIRTriggerHandlerTest.MirInitWrap mirInit = new EUMIRTriggerHandlerTest.MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = objCountry.Id;
        mirInit.medicalEvaluatorId = user2.Id;
        mirInit.assessmentId = questionnaireRecord.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        CMPL123CME__EU_MIR__c euMirTypeInitAndFinal = EUMIRTriggerHandlerTest.makeEuMirInitial(mirInit);
        euMirTypeInitAndFinal.CMPL123CME__Type_of_Report__c = AspenConstants.STR_Combined_Initial_And_Final_Report;
        euMirTypeInitAndFinal.CMPL123_WF_Status__c = 'Opened';        
        insert euMirTypeInitAndFinal;
        euMirTypeInitAndFinal.CMPL123_WF_Status__c = 'Pending Regulatory Decision';        
        update euMirTypeInitAndFinal;
        
        
        test.startTest();
        
        Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Competent Authority Regulatory Response').getRecordTypeId();
        Id regOpinionTaskRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Regulatory Opinion Task').getRecordTypeId();
        Id notifiedRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Notified Body Regulatory Response').getRecordTypeId();
        //TODO : find a workaround for the Regulatory_Task_AuditTrigger coverage as the flag would be false on insertion of MEDDEV
        UpdateParentUtility.flag = true;
        
        //Create a Regulatory Task
        Regulatory_Task__c regulatoryTaskRecord2 = (Regulatory_Task__c) TestDataFactory.createSObject(new Regulatory_Task__c(RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                                                                                                                    EU_MIR__c = euMirTypeInitAndFinal.Id
                                                                                                                   ), false);// CMPL123_WF_Status__c = 'Opened'
        Regulatory_Task__c regulatoryTaskRecord4 = (Regulatory_Task__c) TestDataFactory.createSObject(new Regulatory_Task__c(RecordTypeId = notifiedRTID,
                                                                                                                    EU_MIR__c = euMirTypeInitAndFinal.Id
                                                                                                                   ), false);// CMPL123_WF_Status__c = 'Opened'
        Regulatory_Task__c regulatoryTaskRecord3 = (Regulatory_Task__c) TestDataFactory.createSObject(new Regulatory_Task__c(RecordTypeId = regOpinionTaskRTID,
                                                                                                                    EU_MIR__c = euMirTypeInitAndFinal.Id
                                                                                                                   ), false);// CMPL123_WF_Status__c = 'Opened'
        List<Regulatory_Task__c> listToInsert = new List<Regulatory_Task__c>();
        listToInsert.add(regulatoryTaskRecord2);
        listToInsert.add(regulatoryTaskRecord4);
        listToInsert.add(regulatoryTaskRecord3);
        insert listToInsert;
        regulatoryTaskRecord2.EU_MIR__c = euMirTypeInitAndFinal.Id;
        regulatoryTaskRecord2.CMPL123_WF_Status__c = 'Closed-Done';
        regulatoryTaskRecord2.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        //regulatoryTaskRecord.Other_Justification__c = 'Test';
        regulatoryTaskRecord2.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTaskRecord2.Assignee_Name__c = objUserBackupContact.id;
        newRegTasks.add(regulatoryTaskRecord2);
        regulatoryTaskRecord3.EU_MIR__c = euMirTypeInitAndFinal.Id;
        regulatoryTaskRecord3.CMPL123_WF_Status__c = 'In Process';
        regulatoryTaskRecord3.CMPL123_WF_Action__c = 'Submit';
        regulatoryTaskRecord3.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        //regulatoryTaskRecord.Other_Justification__c = 'Test';
        regulatoryTaskRecord3.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTaskRecord3.Assignee_Name__c = objUserBackupContact.id;
        regulatoryTaskRecord3.Due_Date__c = Date.newInstance(2021,09,27);
        regulatoryTaskRecord3.Issue_Summary__c = 'Issue Summary data';
        regulatoryTaskRecord3.Question__c = 'Does the following event meet reporting criteria in your country and require an MDI report from MEG?';
        //update regulatoryTaskRecord3;
        List<Regulatory_Task__c> newList = new List<Regulatory_Task__c>();
        regulatoryTaskRecord4.EU_MIR__c = euMirTypeInitAndFinal.Id;
        regulatoryTaskRecord4.CMPL123_WF_Status__c = 'Closed-Done';
        regulatoryTaskRecord4.Justification_for_not_Reporting__c = 'This issue does not need to be reported per contractual agreement with Notified Body';
        //regulatoryTaskRecord.Other_Justification__c = 'Test';
        regulatoryTaskRecord4.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTaskRecord4.Assignee_Name__c = objUserBackupContact.id;
        //update regulatoryTaskRecord4;
        newList.add(regulatoryTaskRecord3);
        newList.add(regulatoryTaskRecord2);
        newList.add(regulatoryTaskRecord4);
        update newList;
        newRegTasks.add(regulatoryTaskRecord3);
        
        //TODO : find a workaround for the Regulatory_Task_AuditTrigger coverage as the flag would be false on insertion of MEDDEV
        UpdateParentUtility.flag = true;
        
        Set<String> eumirIds = new Set<String>();
        eumirIds.add(regulatoryTaskRecord2.EU_MIR__c);
        regulatoryTaskRecord2.EU_MIR__c = euMirTypeInitAndFinal.Id;
        regulatoryTaskRecord2.CMPL123_WF_Status__c = 'Closed-Done';
        regulatoryTaskRecord2.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        //regulatoryTaskRecord.Other_Justification__c = 'Test';
        regulatoryTaskRecord2.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTaskRecord2.Assignee_Name__c = objUserBackupContact.id;
        newRegTasks.clear();
        newRegTasks.add(regulatoryTaskRecord2);
        regulatoryTaskRecord2.CMPL123_WF_Action__c = 'Reopen';
        update regulatoryTaskRecord2;
        }
        
        //TODO : find a workaround for the Regulatory_Task_AuditTrigger coverage as the flag would be false on insertion of MEDDEV
        UpdateParentUtility.flag = true;
        
        Update newRegTasks;
        
        Delete newRegTasks;
        test.stopTest();        
    }    
    
    @isTest
    Public static void setup(){
       Id AspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
       User newUser1 = new User(ProfileId = AspenUserProfileId, LastName = 'admin1', Email = 'test0@0te0st.com',
                Username = 'test0@0te0st.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'TEST', Title = 'test', Alias = 'test', TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
        insert newUser1;
        User newUser2 = new User(ProfileId = AspenUserProfileId, LastName = 'admin2', Email = 'test1@1te1st.com',
                Username = 'test1@1te1st.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'TEST', Title = 'test', Alias = 'test', TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
        insert newUser2;
       User objUserMainContact = [SELECT Id FROM User WHERE LastName = 'admin1' LIMIT 1];
       User objUserBackupContact = [SELECT Id FROM User WHERE LastName = 'admin2' LIMIT 1];
        
        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Primary_Vigilance_Contact__c = objUserBackupContact.id), true);
        
        //Create Country - Backup Vigilance Contact
        Country_Backup_Vigilance_Contact__c vigilanceCountryContact = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(new Country_Backup_Vigilance_Contact__c(Country_Backup_Vigilance_Contact_Name__c = objUserBackupContact.id,
                                                                                                                                                                                  Country__c = objCountry.id), true);
        
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId,
            Country_of_origin__c = 'USA'), true);
        
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
        
        User user2 = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator Data Loader'].Id,
                LastName = 'test2',
                Email = 'test2@gmail.com',
                Username = 'test2@gmail.com' + System.currentTimeMillis(),
                CompanyName = 'TEST2',
                Title = 'title2',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10'
        ), true);
        
        System.runas(user2) {
        
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
        
        //  CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(Medical_Evaluation__c = questionnaireRecord.Id, Country__c = objCountry.Id), true);
        
        //Create MDI
        CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
            Medical_Evaluation__c = questionnaireRecord.Id,
            Product__c = prodTckt.id,
            Country__c = objCountry.Id,
            CMPL123CME__Complaint__c = complaint.Id,
            Regulatory_Evaluator__c = [SELECT id FROM User LIMIT 1].id,
            Submission_Type__c = objCountrySubmissionType.Id,
            Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
            CMPL123_WF_Status__c = 'Opened'), true);
        
        meddevRecord.CMPL123_WF_Status__c = 'Pending Regulatory Decision';
        
        CMPL123CME__Registered_Site__c registeredSite = (CMPL123CME__Registered_Site__c) 
                TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                    CMPL123CME__Site_Name__c = 'Test Registered Site',
                    Division__c = 'ADD'),
                false
            );
        
        
        Update meddevRecord;
        
        meddevRecord.Waived_Rationale__c = 'Test';
        test.startTest();
        
        Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Competent Authority Regulatory Response').getRecordTypeId();
        //TODO : find a workaround for the Regulatory_Task_AuditTrigger coverage as the flag would be false on insertion of MEDDEV
        UpdateParentUtility.flag = true;
        
        //Create a Regulatory Task
        Regulatory_Task__c regulatoryTaskRecord = (Regulatory_Task__c) TestDataFactory.createSObject(new Regulatory_Task__c(RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                                                                                                                            MDI__c = meddevRecord.Id
                                                                                                                           ), false);// CMPL123_WF_Status__c = 'Opened'
        list<Regulatory_Task__c> listToInsert = new List<Regulatory_Task__c>();
        listToInsert.add(regulatoryTaskRecord);
        insert listToInsert;
        System.assertEquals(regulatoryTaskRecord.Assignee_Name__c, regulatoryTaskRecord.Vigilance_Contact_Formula__c);
        
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
        regulatoryTaskRecord.CMPL123_WF_Action__c = 'Reopen';
        update regulatoryTaskRecord;
        Id regOpinionTaskRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Regulatory Opinion Task').getRecordTypeId();
        Regulatory_Task__c regulatoryTaskRecord3 = (Regulatory_Task__c) TestDataFactory.createSObject(new Regulatory_Task__c(RecordTypeId = regOpinionTaskRTID,
                                                                                                                    MDI__c = meddevRecord.Id
                                                                                                                   ), false);// CMPL123_WF_Status__c = 'Opened'
        insert regulatoryTaskRecord3;                                
        regulatoryTaskRecord3.MDI__c = meddevRecord.Id;
        regulatoryTaskRecord3.CMPL123_WF_Status__c = 'In Process';
        regulatoryTaskRecord3.CMPL123_WF_Action__c = 'Submit';
        regulatoryTaskRecord3.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        //regulatoryTaskRecord.Other_Justification__c = 'Test';
        regulatoryTaskRecord3.Regulatory_Agency_Notification_Required__c = 'No';
        regulatoryTaskRecord3.Assignee_Name__c = objUserBackupContact.id;
        regulatoryTaskRecord3.Due_Date__c = Date.newInstance(2021,09,27);
        regulatoryTaskRecord3.Issue_Summary__c = 'Issue Summary data';
        regulatoryTaskRecord3.Question__c = 'Does the following event meet reporting criteria in your country and require an MDI report from MEG?';
        update regulatoryTaskRecord3;
        }
        
        //TODO : find a workaround for the Regulatory_Task_AuditTrigger coverage as the flag would be false on insertion of MEDDEV
        UpdateParentUtility.flag = true;
        
        Update newRegTasks;
        
        Delete newRegTasks;
        test.stopTest();
    }     
    
}