/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : MEDDEVTriggerHandlerTest.
* @Why   : MEDDEVTriggerHandlerTest test class for the MEDDEVTriggerHandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 27-MAR-2020         1029/1198 CR                Added 'medDevReopenTest()' test method.
* --------------------------------------------------------------------------------------------------------------------------------------
* dskak                 27-MAY-2020         #131 / CHARM-2734           Added 'submitOpenedMDI()' method to test #131 defect's fix.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                 10-JUN-2020         N/A                         Updated code part, which is related to Users' insertion.
*                                                                           This change designed to prevent a 'DUPLICATE_USERNAME' error
*                                                                           during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* dskak                 17-JUN-2020         #131 / CHARM-2734           Added next test methods to test #131 defect's fix:
*                                                                           waiveOpenedMDI(), closeMDIRecord(), completeMDIRecord().
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 29-OCT-2020         HC #100/CHARM-3518          Adjusted test data insertion.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 28-DEC-2020         TWD Upgrade issue           Added 'executeLogicFromWFRulesTest()' method to test logic moved
*                                                                           from Workflow Rules with Field Updates on MEDDEV to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
class MEDDEVTriggerHandlerTest {
    @TestSetup
    static void setupData() {
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId()
        ), true);

        insert new Contact__c(
            Ticket__c = complaint.Id,
            pRE__c = true,
            Delete_Flag__c = false,
            External_ID__c = 'a98b1226-7614-e711-bb9a-005056bd0445'
        );

        Profile aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'];

        User aspenUser = new User(
            Alias = 'standt',
            Email = 'aspenUserInteg@test.com' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10),
            EmailEncodingKey = 'UTF-8',
            FirstName = 'testUser',
            LastName = 'Testing',
            Street = 'testStreet',
            Phone = '767-55-23',
            PostalCode = 'testZipCode',
            Country = 'testCountry',
            City = 'testCity',
            Fax = 'testFax',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = aspenInteg.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'aspenUserInteg@test.com.test' + + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10),
            IsActive = true,
            Belongs_to_Text__c = 'PEI3'
        );

        insert aspenUser;

        Country__c country = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'USA',
            Primary_Vigilance_Contact__c = aspenUser.Id
        ), true);

        System.runAs(aspenUser) {
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c = '123',
                List_Number__c = '12345'
            ), true);

            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = product.Id,
                Event_Ticket__c = complaint.Id,
                Batch_Lot_Serial__c = '1235'
            ), true);

            CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                CMPL123CME__Complaint__c = complaint.Id,
                RecordTypeId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId(),
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'Test',
                Evaluator__c = aspenUser.Id,
                Reportability__c = 'Non-Reportable',
                Reportability_Category__c = 'Adverse Event',
                Initial_Awareness_Date__c = Date.newInstance(2018, 05, 07),
                Submitted_Date__c = Date.newInstance(2018, 05, 07)
            ), true);

            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
                Name = '30 Days',
                Calendar_Days__c = 30,
                Country__c = country.Id
            ), true);

            TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
                Medical_Evaluation__c = assessment.Id,
                Country__c = country.Id,
                Product__c = prodTckt.Id,
                CMPL123CME__Complaint__c = complaint.Id,
                CMPL123_WF_Status__c = 'Opened',
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test',
                Submission_Type__c = objCountrySubmissionType.Id
            ), true);
        }
    }

    @IsTest
    static void initialReportCaseTest() {
        Test.startTest();
        CMPL123CME__MEDDEV__c mdi = [SELECT Id, CMPL123CME__Type_of_Report__c FROM CMPL123CME__MEDDEV__c LIMIT 1];
        mdi.CMPL123CME__Type_of_Report__c = 'Initial report';
        update mdi;
        CMPL123CME__MEDDEV__c mdiUpdated = [
                SELECT CMPL123CME__Manufacturer_Device_Analysis_Results__c
                FROM CMPL123CME__MEDDEV__c
                WHERE Id = :mdi.Id
        ];
        mdi.Follow_Up_Required__c = 'Yes';
        mdi.CMPL123_WF_Status__c = 'Pending Follow Up Creation';
        update mdi;
        System.assert(String.isEmpty(mdiUpdated.CMPL123CME__Manufacturer_Device_Analysis_Results__c));
        Test.stopTest();
    }

    @IsTest
    static void waiveActionCaseTest() {
        Test.startTest();
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                        Medical_Evaluation__c = questionnaire.Id,
                        Country__c = country.Id,
                        Product__c = productTicket.Id,
                        CMPL123CME__Complaint__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened',
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test'
                ), true);
        meddevRecord.Follow_Up_Required__c = 'Yes';
        meddevRecord.CMPL123_WF_Status__c = 'Pending Final Review';
        update meddevRecord;

        meddevRecord.CMPL123_WF_Action__c = 'Waive';
        meddevRecord.CMPL123_WF_Status__c = 'Closed - Waived';
        update meddevRecord;
        CMPL123CME__MEDDEV__c mdiUpdated = [
                SELECT CMPL123_WF_Action__c
                FROM CMPL123CME__MEDDEV__c
                WHERE Id = :meddevRecord.Id
        ];
        System.assert(mdiUpdated.CMPL123_WF_Action__c == 'Waive');
        Test.stopTest();
    }

    @IsTest
    static void combinedInitialFinalMedevCaseTest() {
        Test.startTest();
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                        Medical_Evaluation__c = questionnaire.Id,
                        Country__c = country.Id,
                        Product__c = productTicket.Id,
                        CMPL123CME__Complaint__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened',
                        CMPL123CME__Type_of_Report__c = 'Combined initial and final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        CMPL123CME__Whether_Manufacturer_Aware__c = 'No',
                        CMPL123CME__Number_of_similarIncidents__c = '2',
                        CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test'
                ), true);
        meddevRecord.Follow_Up_Required__c = 'Yes';
        meddevRecord.CMPL123_WF_Status__c = 'Pending Final Review';
        update meddevRecord;

        CMPL123CME__MEDDEV__c meddevRecordFinal = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                        Medical_Evaluation__c = questionnaire.Id,
                        Country__c = country.Id,
                        Product__c = productTicket.Id,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Follow_Up_Required__c = 'Yes',
                        CMPL123_WF_Status__c = 'Pending Final Review',
                        CMPL123CME__Type_of_Report__c = 'Final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        CMPL123CME__Whether_Manufacturer_Aware__c = 'No',
                        CMPL123CME__Number_of_similarIncidents__c = '2',
                        CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test'
                ), true);
        meddevRecordFinal.CMPL123CME__Type_of_Report__c = 'Combined initial and final report';
        update meddevRecordFinal;
        CMPL123CME__MEDDEV__c mdiUpdated = [
                SELECT CMPL123CME__Expected_Date_of_Next_Report__c
                FROM CMPL123CME__MEDDEV__c
                WHERE Id = :meddevRecord.Id
        ];
        System.assert(mdiUpdated.CMPL123CME__Expected_Date_of_Next_Report__c == null);
        Test.stopTest();
    }

    @IsTest
    private static void medDevReopenTest() {
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User admin = TestUtil.insertTestUser(
                adminProfileId,
                'admin@test.com',
                'adminTest@test.com'
        );

        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'), true);
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Pending Follow Up Creation'), true);
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Follow Up Required',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'MDI Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'MDI_WORKFLOW',
                        CMPL123__Target_Object__c = 'MDI Workflow'),
                true
        );

        CMPL123__WF_Step__c wfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule.Id,
                        CMPL123__Action__c = wfAction.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Permission_Group__c = 'Medical Evaluator',
                        CMPL123__Order__c = 1.0
                ), true);

        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        Country_Submission_Type__c submissionType = new Country_Submission_Type__c(
                Active__c = true,
                Calendar_Days__c = 10,
                Country__c = country.Id,
                Division__c = 'ADD'
        );
        insert  submissionType;

        CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                        Medical_Evaluation__c = questionnaire.Id,
                        Country__c = country.Id,
                        Product__c = productTicket.Id,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Follow_Up_Required__c = 'Yes',
                        CMPL123_WF_Status__c = 'Closed-Done',
                        CMPL123CME__Type_of_Report__c = 'Combined initial and final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        CMPL123CME__Whether_Manufacturer_Aware__c = 'No',
                        CMPL123CME__Number_of_similarIncidents__c = '2',
                        Submission_Type__c = submissionType.Id,
                        CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test'
                ), true);

        Id evaInvestGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Medical_Evaluator'].Id;
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;

        User evalInvestigator = TestUtil.insertTestUser(
                aspenUserProfileId,
                'test@test.com',
                'medEvalTest@test.com'
        );

        System.runAs(admin) {
            insert new GroupMember(
                    GroupId = evaInvestGroupId,
                    UserOrGroupId = evalInvestigator.Id
            );
        }

        Test.startTest();
        System.runAs(evalInvestigator) {
            meddevRecord.CMPL123_WF_Status__c = endStatus.Name;
            meddevRecord.CMPL123_WF_Action__c = wfAction.Name;
            update meddevRecord;
        }
        Test.stopTest();

        CMPL123CME__MEDDEV__c result = [
                SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c
                FROM CMPL123CME__MEDDEV__c
                WHERE Id =: meddevRecord.Id
        ];

        System.assertEquals(endStatus.Name, result.CMPL123_WF_Status__c);
        System.assertEquals(wfAction.Name, result.CMPL123_WF_Action__c);
    }

    @IsTest
    static void followUpRequiredTest() {
        CMPL123CME__MEDDEV__c meddev = [SELECT Id, CMPL123_WF_Status__c, CMPL123CME__Type_of_Report__c
                                                FROM CMPL123CME__MEDDEV__c LIMIT 1];

        meddev.CMPL123_WF_Status__c = 'Pending Regulatory Decision';
        meddev.CMPL123CME__Type_of_Report__c = 'Follow-up report';
        meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c = 'test';

        update meddev;

        CMPL123CME__MEDDEV__c result = [SELECT CMPL123_WF_Status__c, CMPL123CME__Type_of_Report__c, CMPL123CME__Manufacturer_Preliminary_Analysis__c
                                                FROM CMPL123CME__MEDDEV__c WHERE Id =: meddev.Id];

        System.assertEquals(result.CMPL123_WF_Status__c, meddev.CMPL123_WF_Status__c);
        System.assertEquals(result.CMPL123CME__Type_of_Report__c, meddev.CMPL123CME__Type_of_Report__c);
        System.assertEquals(
                result.CMPL123CME__Manufacturer_Preliminary_Analysis__c,
                meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c
        );
    }

    @IsTest
    static void submitOpenedMDI() {
        CMPL123CME__MEDDEV__c meddev = [SELECT Id FROM CMPL123CME__MEDDEV__c LIMIT 1];

        meddev.CMPL123_WF_Status__c = 'Pending Regulatory Decision';
        meddev.CMPL123_WF_Action__c = 'Submit to Regulatory';
        meddev.CMPL123CME__Type_of_Report__c = 'Follow-up report';
        meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c = 'test';
        meddev.CMPL123CME__Expected_Date_of_Next_Report__c = Date.today();

        update meddev;

        CMPL123CME__MEDDEV__c result = [SELECT CMPL123_WF_Status__c, Submit_to_Regulatory_By__c, Submit_to_Regulatory_Date__c
                                                FROM CMPL123CME__MEDDEV__c WHERE Id = :meddev.Id];

        System.assertEquals(meddev.CMPL123_WF_Status__c, result.CMPL123_WF_Status__c);
        System.assertEquals(UserInfo.getName(), result.Submit_to_Regulatory_By__c);
        System.assertEquals(Date.today(), result.Submit_to_Regulatory_Date__c);
    }

    @IsTest
    static void waiveOpenedMDI() {
        CMPL123CME__MEDDEV__c meddev = [SELECT Id FROM CMPL123CME__MEDDEV__c LIMIT 1];

        meddev.CMPL123_WF_Status__c = 'Closed - Waived';
        meddev.CMPL123_WF_Action__c = 'Waive';
        meddev.CMPL123CME__Type_of_Report__c = 'Follow-up report';
        meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c = 'test';
        meddev.CMPL123CME__Expected_Date_of_Next_Report__c = Date.today();

        update meddev;

        CMPL123CME__MEDDEV__c result = [SELECT CMPL123_WF_Status__c, Waived_By__c FROM CMPL123CME__MEDDEV__c WHERE Id = :meddev.Id];

        System.assertEquals(meddev.CMPL123_WF_Status__c, result.CMPL123_WF_Status__c);
        System.assertEquals(UserInfo.getName(), result.Waived_By__c);
    }

    @IsTest
    static void closeMDIRecord() {
        CMPL123CME__MEDDEV__c meddev = [SELECT Id FROM CMPL123CME__MEDDEV__c LIMIT 1];

        meddev.CMPL123_WF_Status__c = 'Closed-Done';
        meddev.CMPL123_WF_Action__c = 'Close';
        meddev.CMPL123CME__Type_of_Report__c = 'Follow-up report';
        meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c = 'test';
        meddev.CMPL123CME__Expected_Date_of_Next_Report__c = Date.today();
        meddev.CMPL123CME__Medical_Device_Class__c = 'IVD General';
        meddev.CMPL123CME__Classification_of_Incident__c = 'All other reportable incidents';
        meddev.CMPL123CME__Incident_Description_Narrative__c = 'test';
        meddev.CMPL123CME__Serious_Public_Threat__c = 'No';
        meddev.Submission_Due_Date__c = Date.today();
        meddev.CMPL123CME__Commercial_Name__c = 'test';
        meddev.CMPL123CME__Manufacturer_Address__c = 'test';
        meddev.CMPL123CME__Manufacturer_City__c = 'test';
        meddev.CMPL123CME__Manufacturer_Contact__c = 'test';
        meddev.CMPL123CME__ManufacturerCountry__c = 'Albania';
        meddev.CMPL123CME__Manufacturer_Phone__c = '123';
        meddev.CMPL123CME__Manufacturer_Awareness_Date__c = Date.today();
        meddev.CMPL123CME__Manufacturer_Email__c = 'aspenTest@test.com';
        meddev.CMPL123CME__Manufacturer_Postal_code__c = '123';
        meddev.CMPL123CME__Manufacturer_Name__c = 'test';
        meddev.CMPL123CME__NomenclatureSystem_preferable_GMDN__c = 'GMDN';
        meddev.CMPL123CME__Status_of_Submitter__c = 'Manufacturer';
        meddev.CMPL123CME__Nomenclature_Text__c = 'test';
        meddev.CMPL123CME__Nomenclature_Code__c = '123';
        meddev.CMPL123CME__Manufacturer_Reference_Number__c = 'test';
        meddev.CMPL123CME__Address_of_National_Competent_Authority__c = 'test';
        meddev.CMPL123CME__Notified_Body_ID_Number__c = '123456';
        meddev.CMPL123CME__Recipient_Name_of_NCA__c = 'test';

        update meddev;

        CMPL123CME__MEDDEV__c result = [SELECT CMPL123_WF_Status__c, Closed_By__c FROM CMPL123CME__MEDDEV__c WHERE Id = :meddev.Id];

        System.assertEquals(meddev.CMPL123_WF_Status__c, result.CMPL123_WF_Status__c);
        System.assertEquals(UserInfo.getName(), result.Closed_By__c);
    }

    @IsTest
    static void completeMDIRecord() {
        CMPL123CME__MEDDEV__c meddev = [SELECT Id FROM CMPL123CME__MEDDEV__c LIMIT 1];

        meddev.CMPL123_WF_Status__c = 'Pending Final Review';
        meddev.CMPL123_WF_Action__c = 'Complete Regulatory Response';
        meddev.CMPL123CME__Type_of_Report__c = 'Follow-up report';
        meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c = 'test';
        meddev.CMPL123CME__Expected_Date_of_Next_Report__c = Date.today();

        update meddev;

        CMPL123CME__MEDDEV__c result = [SELECT CMPL123_WF_Status__c, Complete_Regulatory_Response_By__c, Complete_Regulatory_Response_Date__c
                                                FROM CMPL123CME__MEDDEV__c WHERE Id = :meddev.Id];

        System.assertEquals(meddev.CMPL123_WF_Status__c, result.CMPL123_WF_Status__c);
        System.assertEquals(UserInfo.getName(), result.Complete_Regulatory_Response_By__c);
        System.assertEquals(Date.today(), result.Complete_Regulatory_Response_Date__c);
    }

    @IsTest
    static void executeLogicFromWFRulesTest() {
        Account customer = new Account(
            Name = 'test account',
            Contact_Address_Line_1__c = 'test address, 101',
            Contact_Address_Line_2__c = 'no test address, 010'
        );

        insert customer;

        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(),
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            CMSNext_Ticket_Number__c = '056056FC1050021',
            CMPL123CME__Customer__c = customer.Id,
            Serial__c = 'test serial'
        ), true);

        Test.startTest();

        Country__c country = [SELECT Id FROM Country__c LIMIT 1];

        country.NCA_Address__c = 'Test address, 101';
        country.NCA_Name__c = 'test test name';
        update country;

        User aspenUser = [SELECT Id FROM User WHERE Username LIKE 'aspenUserInteg%' LIMIT 1];

        CMPL123__Product__c product = null;
        Product_Ticket__c productTicket = null;
        Product_Ticket__c relatedProductTicket = null;

        System.runAs(aspenUser) {
            product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c = '123',
                List_Number__c = '12345',
                Device_Nomenclature_Code__c = '123973',
                Device_Nomenclature_Text__c = 'test test',
                Notified_Body_ID__c = '123' + complaint.Id + '724'
            ), true);

            productTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = product.Id,
                Event_Ticket__c = complaint.Id,
                Batch_Lot_Serial__c = '1235',
                Software_Version__c = '4'
            ), true);

            relatedProductTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = product.Id,
                Event_Ticket__c = complaint.Id,
                Batch_Lot_Serial__c = '1235'
            ), true);
        }

        CMPL123CME__Registered_Site__c registeredSite = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(
            CMPL123CME__G1_Contact_Office_Region_State__c = 'NA',
            Division__c = 'ADD',
            Authorised_Rep_Contact__c = 'test',
            Authorised_Rep_E_mail__c = 'test@test.com',
            Authorised_Rep_Fax__c = '12345784',
            Authorised_Rep_Name__c = 'test name',
            Authorised_Rep_Phone__c = '1234835784',
            Authorised_Rep_Postcode__c = '472'
        ), true);

        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            CMPL123CME__Complaint__c = complaint.Id,
            RecordTypeId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId(),
            CMPL123_WF_Status__c = 'Regulatory',
            CMPL123Rule_Key_Value__c = 'MEDICAL_EVALUATION_WORKFLOW',
            Reportability_Rationale__c = 'Test',
            Evaluator__c = aspenUser.Id,
            Reportability__c = 'Non-Reportable',
            Reportability_Category__c = 'Adverse Event',
            Initial_Awareness_Date__c = Date.newInstance(2018, 05, 07),
            Submitted_Date__c = Date.newInstance(2018, 05, 07),
            Date_of_Incidence__c = Date.today(),
            Describe_Event_or_Problem__c = 'test problem',
            Patient_Outcome__c = 'test 123',
            Initial_Follow_Up_Mfg_Analysis__c = 'test analysis 123',
            Final_Mfg_Analysis__c = 'test analysis 321',
            B2_Outcomes_attributed_to_AE__c = 'Death'
        ), true);

        Id countrySubmissionTypeId = ((Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30 Days',
            Calendar_Days__c = 30,
            Country__c = country.Id
        ), true)).Id;

        CMPL123CME__MEDDEV__c meddev = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
            Medical_Evaluation__c = medEval.Id,
            Country__c = country.Id,
            Product__c = productTicket.Id,
            Related_Product__c = relatedProductTicket.Id,
            CMPL123CME__Complaint__c = complaint.Id,
            CMPL123_WF_Status__c = 'Opened',
            CMPL123Rule_Key_Value__c = 'MDI_WORKFLOW',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test',
            Submission_Type__c = countrySubmissionTypeId
        ), true);

        CMPL123CME__MEDDEV__c newMD = [SELECT Id, CMPL123CME__Catalogue_Number__c, CMPL123CME__Commercial_Name__c,
                                            CMPL123CME__Lot_Numbers__c, Registration_Number__c,
                                            CMPL123CME__Serial_Numbers__c, CMPL123CME__Nomenclature_Code__c, CMPL123CME__Nomenclature_Text__c,
                                            CMPL123CME__Notified_Body_ID_Number__c, CMPL123CME__Software_Version__c, CMPL123CME__Incident_Date__c,
                                            CMPL123CME__Incident_Description_Narrative__c, CMPL123CME__PatientOutcome__c,
                                            CMPL123CME__Manufacturer_Awareness_Date__c, CMPL123CME__Manufacturer_Disclaimer__c,
                                            CMPL123CME__If_usage_of_med_device_is_others_specify__c, CMPL123CME__Medical_Device_Current_Location__c,
                                            CMPL123CME__Model_Number__c, CMPL123CME__Whether_Manufacturer_Aware__c,
                                            CMPL123CME__Address_of_National_Competent_Authority__c, CMPL123CME__Recipient_Name_of_NCA__c,
                                            CMPL123CME__Accessories__c, CMPL123CME__HealthCare_Address__c,
                                            CMPL123CME__Manufacturer_Reference_Number__c, CMPL123CME__Classification_of_Incident__c
                                        FROM CMPL123CME__MEDDEV__c
                                        WHERE Id = :meddev.Id];

        //  Meddev values
        System.assertEquals('IVD, Medical Device', newMD.CMPL123CME__If_usage_of_med_device_is_others_specify__c);
        System.assertEquals('At customer site', newMD.CMPL123CME__Medical_Device_Current_Location__c);
        System.assertEquals('NA', newMD.CMPL123CME__Model_Number__c);
        System.assertEquals('No', newMD.CMPL123CME__Whether_Manufacturer_Aware__c);
        System.assertEquals('Death', newMD.CMPL123CME__Classification_of_Incident__c);
        System.assertEquals(
            complaint.CMSNext_Ticket_Number__c + '(Complaint)',
            newMD.Registration_Number__c
        );

        //  Product-Ticket values
        System.assertEquals(productTicket.Batch_Lot_Serial__c, newMD.CMPL123CME__Lot_Numbers__c);
        System.assertEquals('N/A', newMD.CMPL123CME__Serial_Numbers__c);
        System.assertEquals(product.Device_Nomenclature_Code__c, newMD.CMPL123CME__Nomenclature_Code__c);
        System.assertEquals(product.Device_Nomenclature_Text__c, newMD.CMPL123CME__Nomenclature_Text__c);
        System.assertEquals(product.Notified_Body_ID__c, newMD.CMPL123CME__Notified_Body_ID_Number__c);
        System.assertEquals(productTicket.Software_Version__c, newMD.CMPL123CME__Software_Version__c);

        //  Med Eval values
        System.assertEquals(medEval.Describe_Event_or_Problem__c, newMD.CMPL123CME__Incident_Description_Narrative__c);
        System.assertEquals(medEval.Patient_Outcome__c, newMD.CMPL123CME__PatientOutcome__c);
        System.assertEquals(medEval.Initial_Awareness_Date__c, newMD.CMPL123CME__Manufacturer_Awareness_Date__c);
        System.assert(newMD.CMPL123CME__Manufacturer_Disclaimer__c.contains('Submission of this report does not, in itself, represent'));

        // Country values
        System.assertEquals(country.NCA_Address__c, newMD.CMPL123CME__Address_of_National_Competent_Authority__c);
        System.assertEquals(country.NCA_Name__c, newMD.CMPL123CME__Recipient_Name_of_NCA__c);

        // Complaint values
        System.assertEquals(complaint.CMSNext_Ticket_Number__c, newMD.CMPL123CME__Manufacturer_Reference_Number__c);
        System.assertEquals(
            customer.Contact_Address_Line_1__c + '\n' + customer.Contact_Address_Line_2__c,
            newMD.CMPL123CME__HealthCare_Address__c
        );

        //  Related Product values
        Product_Ticket__c updatedRelatedProductTicket = [SELECT Product__r.Name, Product_List_Number__c, Batch_Lot_Serial__c
                                                            FROM Product_Ticket__c
                                                            WHERE Id = :relatedProductTicket.Id];
        System.assertEquals(
            updatedRelatedProductTicket.Product__r.Name
                + ','
                + updatedRelatedProductTicket.Product_List_Number__c
                + ','
                + updatedRelatedProductTicket.Batch_Lot_Serial__c,
            newMD.CMPL123CME__Accessories__c
        );

        newMD.Registered_Site__c = registeredSite.Id;
        newMD.CMPL123CME__Type_of_Report__c = 'Initial report';
        update newMD;

        newMD = [SELECT CMPL123CME__Authorised_Representative_Contact__c, CMPL123CME__Authorised_Representative_Email__c,
                        CMPL123CME__Authorised_Representative_Fax__c, CMPL123CME__Authorised_Representative_Name__c,
                        CMPL123CME__Authorised_Representative_Phone__c, CMPL123CME__Authorised_Representative_Postal_Code__c,
                        CMPL123CME__Manufacturer_Preliminary_Analysis__c
                    FROM CMPL123CME__MEDDEV__c
                    WHERE Id = :newMD.Id];

        //  Registered Site values
        System.assertEquals(registeredSite.Authorised_Rep_Contact__c, newMD.CMPL123CME__Authorised_Representative_Contact__c);
        System.assertEquals(registeredSite.Authorised_Rep_E_mail__c, newMD.CMPL123CME__Authorised_Representative_Email__c);
        System.assertEquals(registeredSite.Authorised_Rep_Fax__c, newMD.CMPL123CME__Authorised_Representative_Fax__c);
        System.assertEquals(registeredSite.Authorised_Rep_Name__c, newMD.CMPL123CME__Authorised_Representative_Name__c);
        System.assertEquals(registeredSite.Authorised_Rep_Phone__c, newMD.CMPL123CME__Authorised_Representative_Phone__c);
        System.assertEquals(registeredSite.Authorised_Rep_Postcode__c, newMD.CMPL123CME__Authorised_Representative_Postal_Code__c);

        //  Meddev values
        System.assertEquals(medEval.Initial_Follow_Up_Mfg_Analysis__c, newMD.CMPL123CME__Manufacturer_Preliminary_Analysis__c);

        newMD.CMPL123CME__Type_of_Report__c = 'Final report';
        update newMD;

        newMD = [SELECT CMPL123CME__Manufacturer_Device_Analysis_Results__c
                    FROM CMPL123CME__MEDDEV__c
                    WHERE Id = :newMD.Id];

        //  Meddev values
        System.assertEquals(medEval.Final_Mfg_Analysis__c, newMD.CMPL123CME__Manufacturer_Device_Analysis_Results__c);

        Test.stopTest();
    }
}