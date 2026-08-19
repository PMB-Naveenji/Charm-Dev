/* 
* @why  : SyncSubmissionsFromMedEvalTest test class for the SyncSubmissionsFromMedEval class
* @when : CreatedDate : 15-DEC-2018
* @what : Test Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID          Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*    rslob                   03-June-2020           N/A                      Test class optimization
*  --------------------------------------------------------------------------------------------------------------------------------------
* Lakshman               03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D9_Region_State__c to CMPL123CME__D7b_Region_State__c
* ---------------------------------------------------------------------------------------------------------------------------------------
* Princy Kandpal          16-June-2021           Code Coverage                    Increased the code coverage
*---------------------------------------------------------------------------------------------------------------------------------------------
* Larry Resnik            04-Oct-2021            CHaRM R2                    Fix testSyncSubmissionsFromMedEvalWithEUMIR setup due to a validation rule
*---------------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             13-Feb-2024            CHaRM R4                  Added new method 'testForEMDRfields'     
*---------------------------------------------------------------------------------------------------------------------------------------------
* Soumith Ganta            18-Dec-2024            CHaRM R6/BTSIT10092       Added new method 'syncSubmissionFieldActionNumber'     
*---------------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             25-Mar-2025            CHaRM R6/IPDR 727         Added new method 'syncSubmissionFieldActionNumber'     
*---------------------------------------------------------------------------------------------------------------------------------------------
* Charm COE                24-Sep-2025            CHaRM R7/FRS-1515-24      Added new method 'testSyncSubmissionsFromMedEvalWithEUMIR7_2_1' - to test auto-population of 'CMPL123CME__Manufacturer_Awareness_Date__c' field on MIR with 'Initial_Awareness_Date__c' field on Medical Evaluation when Recordtype is 7_2_1   
*---------------------------------------------------------------------------------------------------------------------------------------------
* Charm COE                26-FEB-2026            CHaRM R8/FRS-1515-24      Added new method 'testSyncSubmissionsFromMedEvalWithGBMIR' - to test auto-population of 'CMPL123CME__Manufacturer_Awareness_Date__c' field on MIR with 'Initial_Awareness_Date__c' field on Medical Evaluation when Recordtype is GB MIR 
																			Commented 'testSyncSubmissionsFromMedEvalWithEUMIR7_2_1' method as record type 7.2.1 is no more used
*---------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class SyncSubmissionsFromMedEvalTest {
        @TestSetup static void setup() {
                insertTestData();
        }

        @future
        static void insertTestData() {
                CMPL123__CMPL_App_Config__c appConfig = (CMPL123__CMPL_App_Config__c)
                        TestDataFactory.createSObject(new CMPL123__CMPL_App_Config__c(), true);

        Country__c country = (Country__c) TestDataFactory.createSObject(
            
                new Country__c(Name = 'USA'), true);

        Country__c naCountry = (Country__c) TestDataFactory.createSObject(
                new Country__c(Name = 'NA', Primary_Vigilance_Contact__c = UserInfo.getUserId()), true);

        Account account = (Account) TestDataFactory.createSObject(new Account(
                Country__c = country.Id,
                ShippingState = 'NA',
                ShippingCountry = 'USA'
        ), true);

        Contact contact = (Contact) TestDataFactory.createSObject(new Contact(), true);

        CMPL123CME__Complaint_Code__c countryCode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint_Code__c(
                        Name = 'NA',
                        CMPL123CME__Type__c = 'STATE CODE'
                ), true);

        CMPL123CME__Registered_Site__c rs = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                        CMPL123CME__G1_Contact_Office_Region_State__c = 'NA',
                        Division__c = 'ADD'
                ), true);

        Product_Ticket__c product = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId
                ), true);

        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        RecordTypeId = assmntRTId,
                        //CMPL123_WF_Status__c = 'Regulatory',
                        CMPL123_WF_Status__c = 'In Process-Evaluation',
                        Reportability_Rationale__c = 'Test',
                        Reportability__c = 'Non-Reportable',
                        Reportability_Category__c = 'Adverse Event',
                        Initial_Awareness_Date__c = System.Today()
                ), true);
        List<CMPL123CME__Questionnaire_Items__c> questionnaireItems = new List<CMPL123CME__Questionnaire_Items__c>{
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = assessment.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q1,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = assessment.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q1,
                        CMPL123CME__Answer__c = 'Yes'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = assessment.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q2,
                        CMPL123CME__Answer__c = 'No'
                )

        };
        insert questionnaireItems;
        assessment.CMPL123_WF_Status__c = 'Regulatory';
        update assessment;
        CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                        Medical_Evaluation__c = assessment.Id,
                        Country__c = country.Id,
                        Product__c = product.Id
                ), true);

        // Create Investigation 
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened',
                        CMPL123_WF_Action_Performed_On__c = System.today()
                ), true);

        //Create Country Submission type
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30-day', Calendar_Days__c = 30,
                        Country__c = country.Id
                ), true);
    }

    /**
    * @Method       :  
    * @Description  : To test the SyncSubmissionsFromMedEval Functionality.
    * @Return       : N/A
    * @Params       : N/A
    **/
    static testmethod void testSyncSubmissionsFromMedEval() {
        Test.startTest();
        CMPL123CME__Questionnaire__c questionnaireRecord = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        SyncSubmissionsFromMedEval.submissionFieldUpdateMethod(questionnaireRecord.Id);
        Test.stopTest();
    }

    /**
     * @revision 04-Oct-2021 Larry Resnik: Now sets Vigilance Contact on the Country record
     * to satisfy the validation rule Primary_Vigilance_Contact_is_required
     */
    static testmethod void testSyncSubmissionsFromMedEvalWithMDR() {
        CMPL123CME__Questionnaire__c questionnaireRecord = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c WHERE Name = 'USA' LIMIT 1];
        CMPL123CME__Complaint_Code__c complaintCode = [SELECT Id FROM CMPL123CME__Complaint_Code__c LIMIT 1];

        Test.startTest();
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        Medical_Evaluation__c = questionnaireRecord.Id,
                        CMPL123CME__D7b_Region_State__c = complaintCode.Id,
                        D9_Country1__c = country.Id,
                        CMPL123CME__D3_Region_State__c = complaintCode.Id
                ), true);
        SyncSubmissionsFromMedEval.submissionFieldUpdateMethod(questionnaireRecord.Id);
        Test.stopTest();
    }
    static testmethod void testSyncSubmissionsFromMedEvalWithEUMIR() {
        CMPL123CME__Questionnaire__c questionnaireRecord = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c WHERE Name = 'USA' LIMIT 1];
        CMPL123CME__Complaint_Code__c complaintCode = [SELECT Id FROM CMPL123CME__Complaint_Code__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c LIMIT 1];
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'GERMANY', 
                Primary_Vigilance_Contact__c = UserInfo.getUserId()), true);
        CMPL123CME__Questionnaire__c assessment = [Select Id from CMPL123CME__Questionnaire__c LIMIT 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30-day', Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        Product_Ticket__c prodTckt = [Select Id from Product_Ticket__c LIMIT 1];
        CMPL123CME__Registered_Site__c registeredSite = [Select Id from CMPL123CME__Registered_Site__c LIMIT 1];
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
        Test.startTest();
        EUMIRTriggerHandlerTest.MirInitWrap mirInit = new EUMIRTriggerHandlerTest.MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = objCountry.Id;
        mirInit.medicalEvaluatorId = user2.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        CMPL123CME__EU_MIR__c euMirTypeInitAndFinal = EUMIRTriggerHandlerTest.makeEuMirInitial(mirInit);
        euMirTypeInitAndFinal.CMPL123CME__Type_of_Report__c = AspenConstants.STR_Combined_Initial_And_Final_Report;
        euMirTypeInitAndFinal.CMPL123_WF_Status__c = 'Opened';        
        insert euMirTypeInitAndFinal;
        SyncSubmissionsFromMedEval.submissionFieldUpdateMethod(questionnaireRecord.Id);
        Test.stopTest();
    }
    
    /*
    * @Method       : testSyncSubmissionsFromMedEvalWithEUMIR7_2_1
    * @Description  : To test auto-population of 'CMPL123CME__Manufacturer_Awareness_Date__c' field on MIR with 'Initial_Awareness_Date__c' field on Medical Evaluation when Recordtype is 7_2_1
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R7 - FRS-1515-24
    */
    /*static testmethod void testSyncSubmissionsFromMedEvalWithEUMIR7_2_1() {
        CMPL123CME__Questionnaire__c questionnaireRecord = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        CMPL123CME__Complaint_Code__c complaintCode = [SELECT Id FROM CMPL123CME__Complaint_Code__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c LIMIT 1];
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'UNITED KINGDOM', 
                Primary_Vigilance_Contact__c = UserInfo.getUserId()), true);
        CMPL123CME__Questionnaire__c assessment = [Select Id,Initial_Awareness_Date__c from CMPL123CME__Questionnaire__c LIMIT 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30-day', Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        Product_Ticket__c prodTckt = [Select Id from Product_Ticket__c LIMIT 1];
        CMPL123CME__Registered_Site__c registeredSite = [Select Id from CMPL123CME__Registered_Site__c LIMIT 1];
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
        Test.startTest();
        Id recordType7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_2_1') .getRecordTypeId();
        EUMIRTriggerHandlerTest.MirInitWrap mirInit = new EUMIRTriggerHandlerTest.MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = objCountry.Id;
        mirInit.medicalEvaluatorId = user2.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        CMPL123CME__EU_MIR__c euMirTypeInitAndFinal = EUMIRTriggerHandlerTest.makeEuMirInitial(mirInit);
        euMirTypeInitAndFinal.CMPL123CME__Type_of_Report__c = AspenConstants.STR_Combined_Initial_And_Final_Report;
        euMirTypeInitAndFinal.CMPL123_WF_Status__c = 'Opened';        
        insert euMirTypeInitAndFinal;
        SyncSubmissionsFromMedEval.submissionFieldUpdateMethod(questionnaireRecord.Id);
        Test.stopTest();
        CMPL123CME__EU_MIR__c mirInitial = [SELECT Id,RecordTypeId,CMPL123CME__Manufacturer_Awareness_Date__c FROM CMPL123CME__EU_MIR__c WHERE ID = : euMirTypeInitAndFinal.Id LIMIT 1]; 
        // Assert to check - MIR created is of recordtype 7_2_1
        System.assertEquals(mirInitial.RecordTypeId,recordType7_2_1);
        // Assert to check - 'CMPL123CME__Manufacturer_Awareness_Date__c' field on MIR is auto populated from 'Initial_Awareness_Date__c' field on Medical Evaluation
        System.assertEquals(mirInitial.CMPL123CME__Manufacturer_Awareness_Date__c,assessment.Initial_Awareness_Date__c);        
    }*/
    
    /*
    * @Method       : testSyncSubmissionsFromMedEvalWithGBMIR
    * @Description  : To test auto-population of 'CMPL123CME__Manufacturer_Awareness_Date__c' field on MIR with 'Initial_Awareness_Date__c' field on Medical Evaluation when Recordtype is GB MIR
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R8 - FRS-
    */
    static testmethod void testSyncSubmissionsFromMedEvalWithGBMIR() {
        CMPL123CME__Questionnaire__c questionnaireRecord = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        CMPL123CME__Complaint_Code__c complaintCode = [SELECT Id FROM CMPL123CME__Complaint_Code__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c LIMIT 1];
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'UNITED KINGDOM', 
                Primary_Vigilance_Contact__c = UserInfo.getUserId(), Report_Type__c = 'GB MIR'), true);
        CMPL123CME__Questionnaire__c assessment = [Select Id,Initial_Awareness_Date__c from CMPL123CME__Questionnaire__c LIMIT 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30-day', Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        Product_Ticket__c prodTckt = [Select Id from Product_Ticket__c LIMIT 1];
        CMPL123CME__Registered_Site__c registeredSite = [Select Id from CMPL123CME__Registered_Site__c LIMIT 1];
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
        Test.startTest();
        Id recordType_GB_MIR_7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('GB_MIR_7_2_1') .getRecordTypeId();
        EUMIRTriggerHandlerTest.MirInitWrap mirInit = new EUMIRTriggerHandlerTest.MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = objCountry.Id;
        mirInit.medicalEvaluatorId = user2.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        CMPL123CME__EU_MIR__c euMirTypeInitAndFinal = EUMIRTriggerHandlerTest.makeEuMirInitial(mirInit);
        euMirTypeInitAndFinal.CMPL123CME__Type_of_Report__c = AspenConstants.STR_Combined_Initial_And_Final_Report;
        euMirTypeInitAndFinal.CMPL123_WF_Status__c = 'Opened';        
        insert euMirTypeInitAndFinal;
        SyncSubmissionsFromMedEval.submissionFieldUpdateMethod(questionnaireRecord.Id);
        Test.stopTest();
        CMPL123CME__EU_MIR__c mirInitial = [SELECT Id,RecordTypeId,CMPL123CME__Manufacturer_Awareness_Date__c FROM CMPL123CME__EU_MIR__c WHERE ID = : euMirTypeInitAndFinal.Id LIMIT 1]; 
        // Assert to check - MIR created is of recordtype GB MIR
        System.assertEquals(mirInitial.RecordTypeId,recordType_GB_MIR_7_2_1);
        // Assert to check - 'CMPL123CME__Manufacturer_Awareness_Date__c' field on MIR is auto populated from 'Initial_Awareness_Date__c' field on Medical Evaluation
        System.assertEquals(mirInitial.CMPL123CME__Manufacturer_Awareness_Date__c,assessment.Initial_Awareness_Date__c);        
    }
        //CHaRM-R4-Start
    /**
     * @Method       : testForEMDRfields
     * @Description  : CHaRM-R4- To check the assserts for H11-Additional MFG Narrative field population.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void testForEMDRfields() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId
                ), true);
            String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        RecordTypeId = assmntRTId,
                        CMPL123_WF_Status__c = 'In Process-Evaluation',
                        Reportability_Rationale__c = 'Test',
                        Reportability__c = 'Non-Reportable',
                        Reportability_Category__c = 'Adverse Event',
                        Describe_Event_or_Problem__c = 'test',
                        Patient_Outcome__c = 'Test',
                        Final_Mfg_Analysis_New__c = 'Test Final'
                ), true);
            system.debug('assessment1'+ assessment);
            List<CMPL123CME__Questionnaire_Items__c> questionnaireItems = new List<CMPL123CME__Questionnaire_Items__c>{
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = assessment.Id,
                        CMPL123CME__Question__c = '2A',
                        CMPL123CME__Answer__c = 'Yes'
                )
        };
        insert questionnaireItems;
        assessment.CMPL123_WF_Status__c = 'Regulatory';
        update assessment;
        Test.startTest();
                CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                CMPL123CME__A5_Ethnicity__c = 'Not Hispanic/Latino',
                CMPL123CME__A6_Race__c = 'White',
                CMPL123CME__B2_Outcomes_attributed_to_AE__c = 'Disability or Permanent Damage',
                Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
                Medical_Evaluation__c = assessment.Id,
                CMPL123CME__G7_Adverse_Event_Term_s__c = 'Stuff goes here',
                CMPL123CME__H7_If_Remedical_Action_Init__c = 'Recall',
                CMPL123CME__H5_Labeled_for_Single_Use__c = AspenConstants.STR_Yes,
                CMPL123CME__D7a_Single_Use_Device__c = AspenConstants.STR_Yes,
                CMPL123CME__A4_Weight_Units_Patient__c = 'LBS'
            ), true
        );
        system.debug('EMDR1'+ emdr);
        Test.stopTest();
        CMPL123CME__EMDR__c emdR1 = [Select id,CMPL123CME__H11_Additional_Mfg_Narrative__c from CMPL123CME__EMDR__c WHERE id =: emdr.id]; 
        //Check the Assert for H11 Additional Mfg Narrative field is populated from Final Mfg Analysis field from Medical Evaluation object
        System.assertEquals('Test Final', emdR1.CMPL123CME__H11_Additional_Mfg_Narrative__c,
            'H11-Additional Mfg Narrative should be populated'); 
    }
    //CHaRM-R4 : Stop
    
    //CHaRM-R6: Start
    /**
     * @Method       : syncSubmissionFieldActionNumber
     * @Description  : CHaRM-R6- To check the assserts for auto-populating 'Field Action Number' field using SyncSubmission method.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void syncSubmissionFieldActionNumber() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId
                ), true);
            String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        RecordTypeId = assmntRTId,
                        CMPL123_WF_Status__c = 'In Process-Evaluation',
                        Reportability_Rationale__c = 'Test',
                        Reportability__c = 'Non-Reportable',
                        Reportability_Category__c = 'Adverse Event',
                        Describe_Event_or_Problem__c = 'test',
                        Patient_Outcome__c = 'Test',
                        Final_Mfg_Analysis_New__c = 'Test Final',
                        Field_Action_Number__c = 'Test Field action',
                        H9_Correction_Removal_report_No__c = 'Charater length testing for H9-Correction Removal'//CHaRM R6.1: added the H9 field to check the assesrt
                ), true);
            List<CMPL123CME__Questionnaire_Items__c> questionnaireItems = new List<CMPL123CME__Questionnaire_Items__c>{
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = assessment.Id,
                        CMPL123CME__Question__c = '2A',
                        CMPL123CME__Answer__c = 'Yes'
                )
        };
        insert questionnaireItems;
        assessment.CMPL123_WF_Status__c = 'Regulatory';
        update assessment;
        Test.startTest();
                CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                CMPL123CME__A5_Ethnicity__c = 'Not Hispanic/Latino',
                CMPL123CME__A6_Race__c = 'White',
                CMPL123CME__B2_Outcomes_attributed_to_AE__c = 'Disability or Permanent Damage',
                Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
                Medical_Evaluation__c = assessment.Id,
                CMPL123CME__G7_Adverse_Event_Term_s__c = 'Stuff goes here',
                CMPL123CME__H7_If_Remedical_Action_Init__c = 'Recall',
                CMPL123CME__H5_Labeled_for_Single_Use__c = AspenConstants.STR_Yes,
                CMPL123CME__D7a_Single_Use_Device__c = AspenConstants.STR_Yes,
                CMPL123CME__A4_Weight_Units_Patient__c = 'LBS'
            ), true
        );
        SyncSubmissionsFromMedEval.submissionFieldUpdateMethod(assessment.Id);
        Test.stopTest();
        CMPL123CME__EMDR__c emdR1 = [Select id,Field_Action_Number__c,CMPL123CME__H9_Correction_Removal_Report_No__c from CMPL123CME__EMDR__c WHERE id =: emdr.id]; 
        //Check the Assert for Field Action Number field is populated from Field Action Number field from Medical Evaluation object using SyncSubmission method.
        System.assertEquals('Test Field action', emdR1.Field_Action_Number__c);
        //CHaRM R6.1: Check the Assert for H9-Correction/Removal Report No. field in EMDR is populated from H9-Correction/Removal Report No. field from Medical Evaluation object using SyncSubmission method.
        System.assertEquals('Charater length testing for H9-Correction Removal', emdR1.CMPL123CME__H9_Correction_Removal_Report_No__c);
    }
    //CHaRM-R6 : Stop

}