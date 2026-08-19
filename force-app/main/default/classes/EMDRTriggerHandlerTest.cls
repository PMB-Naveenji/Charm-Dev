/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
 * @What  : EMDRTriggerHandlerTest.
 * @Why   : Unit tests for EMDRTriggerHandler and EMDRFieldUpdates.
 * @When  : 15-OCT-2018.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID             Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    27-MAR-2020            1029/1198 CR                Added eMDRReopenTest() test method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * dskak                    03-DEC-2020            [CR] 1674                   Modified.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    22-MAY-2020             #123/CHARM-2729            Separated tested functional from data insert
 *                                                                             using Test.startTest() in beforeUpdateHandlerTestMethod().
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    04-JUN-2020             Code Audit                 Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rslob                    03-JUN-2020             N/A                        Test class optimization
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                    10-JUN-2020             N/A                        Updated code part, which is related to Users' insertion.
 *                                                                             This change designed to prevent a 'DUPLICATE_USERNAME'
 *                                                                             error during deployment to Production environment
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-JUN-2020             Code Audit                  Removed commented code. Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    29-OCT-2020             HC #100/CHARM-3518          Adjusted test data insertion.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman               03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G4_Date_received_by_MFG__c to CMPL123CME__G3_Date_received_by_Mfg__c.
 *                                                                      Changed CMPL123CME__G7_Type_of_Report_MultiSelect__c to CMPL123CME__G6_Type_of_Report__c
 *                                                                      Changed CMPL123CME__D6_Implant_Date_Null__c to CMPL123CME__D6a_Implant_Date_Null__c
 *                                                                      Changed CMPL123CME__D7_Explant_Date_Null__c to CMPL123CME__D6b_Explant_Date_Null__c
 *                                                                      Changed CMPL123CME__D8_Single_Use_Device__c to CMPL123CME__D7a_Single_Use_Device__c
 *                                                                      Changed CMPL123CME__D9_Address__c to CMPL123CME__D7b_Address_1__c
 *                                                                      Changed CMPL123CME__D9_Address2__c to CMPL123CME__D7b_Address_2__c
 *                                                                      Changed CMPL123CME__D9_City__c to CMPL123CME__D7b_City__c
 *                                                                      Changed CMPL123CME__D9_Fax_Number_Null__c to CMPL123CME__D7b_Fax_Number_Null__c
 *                                                                      Changed CMPL123CME__D9_E_mail_Null__c to CMPL123CME__D7b_E_mail_Null__c
 *                                                                      Changed CMPL123CME__D10_Device_available_for_Eval__c to CMPL123CME__D9_Device_available_for_Eval__c
 *                                                                      Changed CMPL123CME__D10_Date_Returned_to_Mfg_Null__c to CMPL123CME__D9_Date_Returned_to_Mfg_Null__c
 *                                                                      Changed CMPL123CME__D11_Concomitant_Null__c to CMPL123CME__D10_Concomitant_Product_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Sameer               09-Dec-2020            Charm Upgrade            Changed the field value from CMPL123CME__G2_Contact_Office_Phone__c -> CMPL123CME__G1_Contact_Office_Phone_Number__c
 *                                                                      Changed CMPL123CME__G3_Report_Source__c -> CMPL123CME__G2_Report_Source__c
 *                                                                      Changed CMPL123CME__G5_PMA_510_K__c -> CMPL123CME__G4_PMA_510_k__c
 *                                                                      Changed CMPL123CME__G8_Adverse_Event_Term__c -> CMPL123CME__G7_Adverse_Event_Term_s__c
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Aslam               15-Dec-2020              Code Audit                   Updated Code Coverage.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oober                    05-JAN-2021            TWD Upgrade Issue    Created fieldUpdatesFromWfRulesTest, fieldUpdatesFromWfRulesTest2
 *                                                                      methods.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oober                    26-JAN-2021            Defect #128          Changed from 'Waive' to 'Void' actions check in Voided By and
 *                                                                      Voided On Field Updates tests.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             23-FEB-2023            CHaRM R3.0, TWD upgrade        Fixed all test methods which crash due to HL7 Compliance validation changes
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             28-JUN-2023            CHaRM R3.1, IPDR 496           Added testSetFieldsE1Country
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar             16-JAN-2024            CHaRM-R4.0                     Updated the method "afterUpdateHandlerTestMethod",
 *                                                                                "afterInsertHandlerTestMethod", "beforeUpdateHandlerTestMethod" and 
 *                                                                                 "beforeInsertHandlerTestMethod"
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Dinesh Kumar             16-JAN-2025            CHaRM-R6.0/IPDR 176            Updated the method beforeUpdateHandlerTestMethod
 *  --------------------------------------------------------------------------------------------------------------------------------------
 */

@IsTest
public class EMDRTriggerHandlerTest {
    // 23-FEB-2023 Larry: Added two Phone constants to comply with USA vs non-USA phone numbers
    private static final String PHONE_NOT_USA = '+011()1234567890';
    private static final String PHONE_FOR_USA = '+1(123)456-7890';
    private static final String COUNTRY_NAME = 'US';
    private static final String ERROR_POS = TestUtil.ERROR_POS;
    private static final String ERROR_NEG = TestUtil.ERROR_NEG;

    /**
     * @description:   creating the required test data for EMDR custom code.
     *
     * @param:         void
     * @return:        void
     **/
    @TestSetup static void setup() {
        Profile aspenIntegrationProfile = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'];
        User aspenInteg = TestUtil.insertTestUser(
            aspenIntegrationProfile.Id,
            'aspenIntegrationTestEMDRT@test.com',
            'aspenIntegrationTestEMDRT@test.com'
        );
        // Create Application Setup data
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId),true);
         // Create Product
         // CHaRM-R4: Created Product to be added in the Ticket review
            CMPL123__Product__c product1 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c  = '123',
                List_Number__c = '12345',
                Product_GTIN__c = '00380740050320'
            ), true);
        // Create Ticket Review
        // CHaRM-R4-Added "H10_Addtl_Mfg_Narrative__c" field in Ticket review object
        TestDataFactory.createSObject(new Ticket_Review__c(Medical_Assignee_Name__c = UserInfo.getUserId(), Status__c = 'Active', Search_Frequency__c = 'Two Weeks (14 days)', Field_Action_Number__c = 'Test', H10_Addtl_Mfg_Narrative__c = 'Test for H11 Additional MFG Narrative', Product__c = product1.Id), true);

        //Create Complaint Code
        TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(Name='NI',CMPL123CME__Type__c = 'STATE CODE'), true);

        // Create Assessment
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = assmntRTId,
            CMPL123CME__Complaint__c = complaint.Id,
            Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)
        ),true);

        // Create Registered Site
        TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(CMPL123CME__G1_Contact_Office_Region_State__c = 'NA', Division__c = 'ADD'),true);

        //Create Country
        // 22-JUN-2023 Larry: Added name and country code to test "E1 - Country" logic
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(
            Name = COUNTRY_NAME,
            Country_Code__c = 'USA',
            Primary_Vigilance_Contact__c = UserInfo.getUserId()
        ), true);

        System.runAs(aspenInteg) {
            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c  = '123',
                List_Number__c = '12345',
                Product_GTIN__c = '00380740050320'
            ), true);
            
            //Create Product ticket
            TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = product.Id,
                Event_Ticket__c= complaint.Id,
                Batch_Lot_Serial__c = '1235',
                Unique_Device_Identifier__c = '1234567890'
            ), true);
        }
        //Create Complaint Code
        CMPL123CME__Complaint_Code__c cmpPaCode = (CMPL123CME__Complaint_Code__c)TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(CMPL123CME__Type__c = 'PATIENT CODE' ), true);
        CMPL123CME__Complaint_Code__c cmpDvCode = (CMPL123CME__Complaint_Code__c)TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(CMPL123CME__Type__c = 'DEVICE CODE' ), true);
        CMPL123CME__Complaint_Code__c cmpCliCode = (CMPL123CME__Complaint_Code__c)TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(CMPL123CME__Type__c = 'HEALTH EFFECT - CLINICAL CODE' ), true);
        CMPL123CME__Complaint_Code__c cmpimpCode = (CMPL123CME__Complaint_Code__c)TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(CMPL123CME__Type__c = 'HEALTH EFFECT - IMPACT CODE' ), true);
        CMPL123CME__Complaint_Code__c cmpCoCode = (CMPL123CME__Complaint_Code__c)TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(CMPL123CME__Type__c = 'COMPONENT CODE' ), true);
        CMPL123CME__Complaint_Code__c cmpIsCode = (CMPL123CME__Complaint_Code__c)TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(CMPL123CME__Type__c = 'ISSUE CODE' ), true);
        CMPL123CME__Complaint_Code__c cmpEvaCode = (CMPL123CME__Complaint_Code__c)TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(CMPL123CME__Type__c = 'EVAL CONCLUSION CODE' ), true);
        //Create MDR Code
        TestDataFactory.createSObject(new CMPL123CME__MDR_Code__c(CMPL123CME__Complaint_Code__c = cmpPaCode.Id), true);
        TestDataFactory.createSObject(new CMPL123CME__MDR_Code__c(CMPL123CME__Complaint_Code__c = cmpDvCode.Id), true);
        TestDataFactory.createSObject(new CMPL123CME__MDR_Code__c(CMPL123CME__Complaint_Code__c = cmpCliCode.Id), true);
        TestDataFactory.createSObject(new CMPL123CME__MDR_Code__c(CMPL123CME__Complaint_Code__c = cmpimpCode.Id), true);
        TestDataFactory.createSObject(new CMPL123CME__MDR_Code__c(CMPL123CME__Complaint_Code__c = cmpCoCode.Id), true);
        TestDataFactory.createSObject(new CMPL123CME__MDR_Code__c(CMPL123CME__Complaint_Code__c = cmpIsCode.Id), true);
        TestDataFactory.createSObject(new CMPL123CME__MDR_Code__c(CMPL123CME__Complaint_Code__c = cmpEvaCode.Id), true);

        //Create Country Submission type
        TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30-day', Calendar_Days__c = 30, Country__c = objCountry.Id), true);
    }

    /**
     * @Method       : beforeInsertHandlerTestMethod
     * @Description  : Before insert Of eMDR
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testMethod void beforeInsertHandlerTestMethod() {
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Test.startTest();
        // 10-FEB (2020 or earlier)
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        // Uses TestDataFactory to assign defaults.
        CMPL123CME__EMDR__c emdrTest = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123CME__CMPL123_WF_Action__c = 'Open',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
                CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
                CMPL123CME__G3_Date_received_by_Mfg__c = System.today(),
                CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
                RecordTypeId = initialRTId,
                Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
                Ticket_Review__c = [SELECT Id FROM Ticket_Review__c LIMIT 1].Id,
                Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id
            ),
        false);
        insert emdrTest;
        emdrTest.Follow_Up_Required__c = 'No';
        emdrTest.CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation';
        update emdrTest;
        //CHaRM-R4: Start
        CMPL123CME__EMDR__c emdR1 = [Select id,CMPL123CME__D4_Primary_UDI_Number__c,CMPL123CME__H11_Additional_Mfg_Narrative__c from CMPL123CME__EMDR__c WHERE id =: emdrTest.id];
        //Check the Assert for H11 Additional Mfg Narrative field is populated from Additional Mfg Narrative field from Ticket Review object.
        System.assertEquals('Test for H11 Additional MFG Narrative', emdR1.CMPL123CME__H11_Additional_Mfg_Narrative__c,
            'H11-Additional Mfg Narrative should be populated'); 
        //Check the Assert for D4 Primary UDI Number should be populated from Ticket Reviews Products GTIN field
        System.assertEquals('00380740050320', emdR1.CMPL123CME__D4_Primary_UDI_Number__c,
            'D4 Primary UDI Number should be populated from Ticket Reviews Products GTIN field');
        //CHaRM-R4: End
        try {
            // 10-FEB (2020 or earlier)
            // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
            // Uses TestDataFactory to assign defaults.
            TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                RecordTypeId = initialRTId,
                CMPL123CME__CMPL123_WF_Action__c = 'Follow Up Required',
                Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
                CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
                Follow_Up_Required__c = 'No',
                CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation',
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
                Ticket_Review__c = [SELECT Id FROM Ticket_Review__c LIMIT 1].Id,
                Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
                Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
                CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
                CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
            ),
            true);
        }
        catch (Exception e) {
            // 23-FEB-2023 Larry: Now has a sane assertion error instead of "true".
            System.assert(e.getMessage().contains(
                'FIELD_CUSTOM_VALIDATION_EXCEPTION, If EMDR is child of ticket review it can\'t be child of medical evaluation or ticket or product-ticket.'),
                'Expected an error due to improper parenting of the EMDR record.');
        }
        Test.stopTest();
    }

    /**
     * @Method       : afterInsertHandlerTestMethod
     * @Description  : After insert Of eMDR
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testMethod void afterInsertHandlerTestMethod(){
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Test.startTest();
        //Create EMDR
        // 10-FEB (2020 or earlier)
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        // 22-JUN-2023 Larry: Now sets E1-CountryNew since the field is now required on Submit.
        // Also set E1-Phone since the Country is now named USA instead of null.
        CMPL123CME__EMDR__c testEMDR  = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId =initialRTId,
            E1_Country_New__c = COUNTRY_NAME,
            CMPL123CME__E1_Phone__c = PHONE_FOR_USA,
            CMPL123CME__CMPL123_WF_Action__c = 'Open',
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);
        testEMDR.CMPL123CME__D3_Postal_Code__c = '11111';
        testEMDR.CMPL123CME__G1_Contact_Office_Postal_Code__c = '11111';
        testEMDR.CMPL123CME__G1_Mfg_Postal_Code__c = '11111';
        //CHaRM-R4: Commented the below code since CMPL123CME__H11_Corrected_Data__c is removed from 2023 form.
       // testEMDR.CMPL123CME__H11_Corrected_Data__c = 'Test';
        testEMDR.Medical_Evaluator__c =  [SELECT Id FROM User Where UserName like  'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id;
        testEMDR.CMPL123CME__CMPL123_WF_Action__c = 'Submit';
        testEMDR.Follow_Up_Required__c = 'No';
        testEMDR.CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation';
        try{
            update testEMDR;
        }catch(exception e){
            // 23-FEB-2023 Larry: Now has a sane assertion error message.
            // Changed assertion criteria since the message to look for has changed.
            String msg = e.getMessage();
            //CHaRM R6: Updated the below Error message in the Assert.
            System.assert(msg.contains('required') && msg.contains('H6'),
                'At least 1 code of every type of H6-Adverse Event problem codes is required for initial Manufacturer reports.' + msg);
        }

        try {
            // 10-FEB (2020 or earlier)
            // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
            // 22-JUN-2023 Larry: Now sets E1-CountryNew since the field is now required on Submit.
            TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                RecordTypeId =initialRTId,
                CMPL123CME__CMPL123_WF_Action__c = 'Follow Up Required',
                Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
                CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
                Follow_Up_Required__c = 'No',
                CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation',
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
                Ticket_Review__c = [SELECT Id FROM Ticket_Review__c LIMIT 1].Id,
                Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
                Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
                E1_Country_New__c = COUNTRY_NAME,
                CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
                CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
            ),true);
        }
        catch (Exception e) {
            // 23-FEB-2023 Larry: Now has a sane assertion error instead of "true".
            System.assert(e.getMessage().contains(
                'FIELD_CUSTOM_VALIDATION_EXCEPTION, If EMDR is child of ticket review it can\'t be child of medical evaluation or ticket or product-ticket.'),
                'Validation Rule activated when it should not have');
        }
        Test.stopTest();
    }

    /**
     * @Method       : initializeNullPreferenceFieldValuesTestMethod
     * @Description  : Before insert Of eMDR
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testMethod void initializeNullPreferenceFieldValuesTestMethod() {
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Test.startTest();

        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        //Create Country Submission
        Country_Submission_Type__c  objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30-day',
            Calendar_Days__c = 30,
            Country__c = objCountry.Id
        ), true);
        System.assertEquals('30-day', objCountrySubmissionType.Name);
        //Create EMDR
        CMPL123CME__EMDR__c initialTemp1 = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done'
            ),
            true
        );

        // 10-FEB (2020 or earlier)
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        // Uses TestDataFactory to assign defaults.
        TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__CMPL123_WF_Action__c = 'Open',
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today(),
            CMPL123CME__Initial_MDR__c = initialTemp1.id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            RecordTypeId = initialRTId,
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            Ticket_Review__c = [SELECT Id FROM Ticket_Review__c LIMIT 1].Id
        ), true);

        try {
            // 10-FEB (2020 or earlier)
            // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
            // Uses TestDataFactory to assign defaults.
            TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123CME__CMPL123_WF_Action__c = 'Follow Up Required',
                CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation',
                CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
                CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
                CMPL123CME__G3_Date_received_by_Mfg__c = System.today(),
                CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
                Follow_Up_Required__c = 'No',
                Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
                Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
                RecordTypeId = initialRTId,
                Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
                Ticket_Review__c = [SELECT Id FROM Ticket_Review__c LIMIT 1].Id
            ), true);
        }
        catch(Exception e){
            System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, If EMDR is child of ticket review it can\'t be child of medical evaluation or ticket or product-ticket.'),true);
        }

        Test.stopTest();
    }

    /**
     * @Method       : createSupplementalEMDRTestMethod
     * @Description  : To create a Concomitant for the supplemental emdr
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testMethod void createSupplementalEMDRTestMethod(){
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Test.startTest();
        //Create EMDR
        // 10-FEB (2020 or earlier)
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        CMPL123CME__EMDR__c intEmdr = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId =initialRTId,
            CMPL123CME__CMPL123_WF_Action__c = 'Open',
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);

        intEmdr.Follow_Up_Required__c = 'No';
        intEmdr.CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation';
        update intEmdr;

        //Create EMDR
        // 10-FEB (2020 or earlier)
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            CMPL123CME__CMPL123_WF_Action__c = 'Open',
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            Medical_Evaluator__c =  [SELECT Id FROM User WHERE Username like 'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id,
            Medical_Evaluation__c = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1].Id,
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            //Follow_Up_Required__c = 'No',
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
            CMPL123CME__Initial_MDR__c = intEmdr.Id,
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);

        CMPL123CME__Concomitant_Product__c objConcomitantProduct = (CMPL123CME__Concomitant_Product__c)TestDataFactory.createSObject(new CMPL123CME__Concomitant_Product__c(
            CMPL123CME__Related_EMDR__c = emdr.Id,
            Product_Ticket__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id),true);

        TestDataFactory.updateSObject(objConcomitantProduct);

        TestDataFactory.updateSObject(emdr);

        List<CMPL123CME__Concomitant_Product__c> cpList = [SELECT Id FROM CMPL123CME__Concomitant_Product__c];
        System.assert(cpList.size() >= 1,true);
        Test.stopTest();
    }

    /**
     * @Method       : updateMedicalEvaluationsTestMethod
     * @Description  : update medical evaluations to set submissions created
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testMethod void updateMedicalEvaluationsTestMethod(){
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Test.startTest();
        //Create EMDR
        CMPL123CME__EMDR__c initialTemp = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done'
            ),
            true
        );
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId =initialRTId,
            CMPL123CME__CMPL123_WF_Action__c = 'Ack 1 Failed',
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            Medical_Evaluator__c =  [SELECT Id FROM User WHERE Username like 'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id,
            Medical_Evaluation__c = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1].Id,
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI'
        ),true);

        emdr.Follow_Up_Required__c = 'Yes';
        emdr.CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation';
        emdr.CMPL123CME__Initial_MDR__c = initialTemp.id;
        TestDataFactory.updateSObject(emdr);

        try {
            emdr.Action_on_Follow_Up_Awareness_Date__c = 'Set Date';
            emdr.CMPL123CME__G3_Date_received_by_Mfg__c = System.today();
            TestDataFactory.updateSObject(emdr);
        } catch(DmlException de) {
            System.assert(de.getMessage().contains('New Follow Up Awareness Date is required'),true);
        }

        Test.stopTest();
    }

    /**
     * @Method       : beforeUpdateHandlerTestMethod
     * @Description  : update
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testMethod void beforeUpdateHandlerTestMethod(){
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name FROM CMPL123CME__Complaint__c LIMIT 1];

        // Get the MEDDEV Record
        CMPL123CME__Questionnaire__c assessment = [SELECT Id, Name FROM CMPL123CME__Questionnaire__c LIMIT 1];

        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Id supplRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Supplemental').getRecordTypeId();
        // 10-FEB (2020 or earlier)
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId =initialRTId,
            CMPL123CME__CMPL123_WF_Action__c = 'Follow Up Required',
            CMPL123CME__Complaint__c = complaint.Id,
            Medical_Evaluation__c = assessment.Id,
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            Medical_Evaluator__c =  [SELECT Id FROM User WHERE Username like  'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id,
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);

        //1314
        // 10-FEB (2020 or earlier)
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        CMPL123CME__EMDR__c initialEmdr = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId =initialRTId,
            CMPL123CME__CMPL123_WF_Action__c = 'Go to Closed - Done',
            CMPL123CME__Complaint__c = complaint.Id,
            Medical_Evaluation__c = assessment.Id,
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            Medical_Evaluator__c =  [SELECT Id FROM User WHERE Username like  'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id,
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);

        initialEmdr.CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation';
        update initialEmdr;
        // 10-FEB (2020 or earlier)
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        // 22-JUN-2023 Larry: Now sets E1-CountryNew since the field is now required on Submit.
        CMPL123CME__EMDR__c emdrSupplementalNew= (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            CMPL123CME__Initial_MDR__c = initialEmdr.Id,
            CMPL123CME__CMPL123_WF_Action__c = 'Go to Closed - Done',
            CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done',
            D3_Country1__c = [SELECT Id FROM Country__c LIMIT 1].Id,
            CMPL123CME__D9_Date_Returned_to_Mfg_Null__c = null,
            CMPL123CME__D7b_Fax_Number_Null__c = null,
            E1_Country_New__c = COUNTRY_NAME,
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G1_Mfg_E_mail_Null__c = null,
            CMPL123CME__G1_Mfg_Fax_Number_Null__c = null,
            //(SA)CMPL123CME__G8_Adverse_Event_Term__c = 'Adverse Event Term(s)',
            CMPL123CME__G7_Adverse_Event_Term_s__c = 'Adverse Event Term(s)',
            //CHaRM-R4: Commented the below code since CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c is removed from 2023 form.
           // CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c = 'Test Additional Text',
            CMPL123CME__H3_DEVICE_EVAL_BY_MFG__c = 'Yes',
            CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c = null,
            CMPL123CME__G5_Pre1938__c = 'Yes',
            CMPL123CME__G5_A_NDA_No__c = 'NA',
            CMPL123CME__G5_CombinationProduct__c = 'NA',
            CMPL123CME__G5_IND_No__c = 'NA',
            CMPL123CME__G5_OTCProduct__c = 'NA',
            //(SA)CMPL123CME__G5_PMA_510_K__c = 'NA',
            CMPL123CME__G4_PMA_510_k__c = 'NA',
            CMPL123CME__G5_STN_No__c = 'NA',
            CMPL123CME__G6_If_ind_protocol_no__c = 'NA',
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);

        Test.startTest(); // Defect #123/CHARM-2729: separate tested functional from data insert
        emdrSupplementalNew.CMPL123CME__CMPL123_WF_Action__c = 'Follow Up Required';
        emdrSupplementalNew.CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation';
        try{
            update emdrSupplementalNew;
        } catch(DMLException e) {
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0));
        }
        //Test #555 & #918 CRs begin
        // 22-JUN-2023 Larry: Now sets E1-CountryNew since the field is now required on Submit.
        CMPL123CME__EMDR__c emdrSupplemental= (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId = supplRTId,
            CMPL123CME__Initial_MDR__c = initialEmdr.Id,
            CMPL123CME__CMPL123_WF_Action__c = '',
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            CMPL123CME__B1_AdverseEvent_ProductProblem__c = 'Product Problem',
            CMPL123CME__E4_Initial_Report_sent_to_FDA__c = 'Yes',
            //(SA)CMPL123CME__G3_Report_Source__c = 'Foreign',
            CMPL123CME__G2_Report_Source__c = 'Foreign',
            D3_Country1__c = [SELECT Id FROM Country__c LIMIT 1].Id,
            CMPL123CME__D3_Postal_Code__c = '11111',
            CMPL123CME__D9_Date_Returned_to_Mfg_Null__c = null,
            CMPL123CME__D7b_Fax_Number_Null__c = null,
            E1_Country_New__c = COUNTRY_NAME,
            CMPL123CME__G1_Mfg_E_mail_Null__c = null,
            CMPL123CME__G1_Mfg_Fax_Number_Null__c = null,
            CMPL123CME__G1_Contact_Office_Postal_Code__c = '11111',
            CMPL123CME__G1_Mfg_Postal_Code__c = '11111',
            //(SA)CMPL123CME__G8_Adverse_Event_Term__c = 'Adverse Event Term(s)',
            CMPL123CME__G7_Adverse_Event_Term_s__c = 'Adverse Event Term(s)',
            CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c = 'Test Additional Text',
            CMPL123CME__H3_DEVICE_EVAL_BY_MFG__c = 'Yes',
            CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c = null,
            //CHaRM-R4: Commented the below code since CMPL123CME__H11_Corrected_Data__c is removed from 2023 form.
           // CMPL123CME__H11_Corrected_Data__c = 'Test',
            CMPL123CME__G5_Pre1938__c = 'Yes',
            CMPL123CME__G5_A_NDA_No__c = 'NA',
            CMPL123CME__G5_CombinationProduct__c = 'NA',
            CMPL123CME__G5_IND_No__c = 'NA',
            CMPL123CME__G5_OTCProduct__c = 'NA',
            //(SA)CMPL123CME__G5_PMA_510_K__c = 'NA',
            CMPL123CME__G4_PMA_510_k__c = 'NA',
            CMPL123CME__G5_STN_No__c = 'NA',
            CMPL123CME__G6_If_ind_protocol_no__c = 'NA',
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);

        emdrSupplemental.CMPL123CME__CMPL123_WF_Action__c = 'Submit';
        emdrSupplemental.CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO';

        update emdrSupplemental;
        System.assertEquals('Submitted to TIBCO', emdrSupplemental.CMPL123CME__CMPL123_WF_Status__c);
        //Test #555 & #918 CRs end

        //  Test CHARM_1864 START
        System.assertEquals('Submit', emdrSupplemental.CMPL123CME__CMPL123_WF_Action__c);
        //  Test CHARM_1864 END

        //Create EMDR Supplemental
        CMPL123CME__EMDR__c emdrSuppl= (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            CMPL123CME__Initial_MDR__c = emdr.Id,
            CMPL123CME__CMPL123_WF_Action__c = 'Open',
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            D3_Country1__c = [SELECT Id FROM Country__c LIMIT 1].Id,
            CMPL123CME__D9_Date_Returned_to_Mfg_Null__c = null,
            CMPL123CME__D7b_Fax_Number_Null__c = null,
            CMPL123CME__G1_Mfg_E_mail_Null__c = null,
            CMPL123CME__G1_Mfg_Fax_Number_Null__c = null,
            //(SA)CMPL123CME__G8_Adverse_Event_Term__c = 'Adverse Event Term(s)',
            CMPL123CME__G7_Adverse_Event_Term_s__c = 'Adverse Event Term(s)',
            //CHaRM-R4: Commented the below code since CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c is removed from 2023 form.
           // CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c = 'Test Additional Text',
            CMPL123CME__H3_DEVICE_EVAL_BY_MFG__c = 'Yes',
            CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c = null,
            CMPL123CME__G5_Pre1938__c = 'Yes',
            CMPL123CME__G5_A_NDA_No__c = 'NA',
            CMPL123CME__G5_CombinationProduct__c = 'NA',
            CMPL123CME__G5_IND_No__c = 'NA',
            CMPL123CME__G5_OTCProduct__c = 'NA',
            //(SA)CMPL123CME__G5_PMA_510_K__c = 'NA',
            CMPL123CME__G4_PMA_510_k__c = 'NA',
            CMPL123CME__G5_STN_No__c = 'NA',
            CMPL123CME__G6_If_ind_protocol_no__c = 'NA',
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);

        emdrSuppl.CMPL123CME__CMPL123_WF_Status__c = 'Pending Final Review';
        update emdrSuppl;

        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Follow Up Required';
        try {
            emdrSuppl.CMPL123CME__Complaint__c = complaint.Id;
            emdrSuppl.Medical_Evaluation__c = assessment.Id;
            TestDataFactory.updateSObject(emdr);
            TestDataFactory.updateSObject(emdrSuppl);
        } catch (DmlException de) {
            System.assert(de.getMessage().contains('Follow Up Required action'),true);
        }
        //Create EMDR
         CMPL123CME__EMDR__c emdrInit = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId =initialRTId,
            CMPL123CME__CMPL123_WF_Action__c = 'Follow Up Required',
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            Ticket_Review__c = [SELECT Id FROM Ticket_Review__c LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);
        Test.stopTest();

        //CHarm R6:Start- To check Task key value field is getting Autopopulated by SUBMITTEDTOFDAFAIL when Submission History has Internal error and 
        //The Task key value gets blank out or Null when Submitted to FDA
         CMPL123CME__EMDR__c emdrInitial= (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId = initialRTId,
            CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO',
            CMPL123CME__B1_AdverseEvent_ProductProblem__c = 'Product Problem',
            CMPL123CME__E4_Initial_Report_sent_to_FDA__c = 'Yes',
            CMPL123CME__G2_Report_Source__c = 'Foreign',
            D3_Country1__c = [SELECT Id FROM Country__c LIMIT 1].Id,
            CMPL123CME__D3_Postal_Code__c = '11111',
            CMPL123CME__D9_Date_Returned_to_Mfg_Null__c = null,
            CMPL123CME__D7b_Fax_Number_Null__c = null,
            E1_Country_New__c = COUNTRY_NAME,
            CMPL123CME__G1_Mfg_E_mail_Null__c = null,
            CMPL123CME__G1_Mfg_Fax_Number_Null__c = null,
            CMPL123CME__G1_Contact_Office_Postal_Code__c = '11111',
            CMPL123CME__G1_Mfg_Postal_Code__c = '11111',
            CMPL123CME__G7_Adverse_Event_Term_s__c = 'Adverse Event Term(s)',
            CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c = 'Test Additional Text',
            CMPL123CME__H3_DEVICE_EVAL_BY_MFG__c = 'Yes',
            CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c = null,
            CMPL123CME__G5_Pre1938__c = 'Yes',
            CMPL123CME__G5_A_NDA_No__c = 'NA',
            CMPL123CME__G5_CombinationProduct__c = 'NA',
            CMPL123CME__G5_IND_No__c = 'NA',
            CMPL123CME__G5_OTCProduct__c = 'NA',
            CMPL123CME__G4_PMA_510_k__c = 'NA',
            CMPL123CME__G5_STN_No__c = 'NA',
            CMPL123CME__G6_If_ind_protocol_no__c = 'NA',
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today(),
            CMPL123CME__CMPL123Task_Key_Value__c = null,
            CMPL123CME__D4_Serial_No__c =  '6563254',
            CMPL123CME__D4_Lot_No__c =  '60273Y600',
            CMPL123CME__E1_Phone__c =  '+1(123)456-7890',
            CMPL123CME__Registered_Site__c =  [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id ,
            CMPL123CME__G1_Contact_Office_Phone_Number__c = '+1(123)456-7890',
            Submission_Type__c =  [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            Medical_Evaluator__c =  [SELECT Id FROM User Where UserName like  'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id
        ),true);
        CMPL123CME__Submission_History__c subHis = new CMPL123CME__Submission_History__c(
                        CMPL123CME__Stage__c = 'Draft',
                        CMPL123CME__Status__c = 'Internal Error',
                        CMPL123CME__Related_EMDR__c = emdrInitial.Id
                );
        insert subHis;
        
        CMPL123CME__EMDR__c eMDRInit1 = [SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123Task_Key_Value__c FROM CMPL123CME__EMDR__c where Id =: emdrInitial.Id];
        System.assertEquals('SUBMITTEDTOFDAFAIL', eMDRInit1.CMPL123CME__CMPL123Task_Key_Value__c);
        
        emdrInitial.CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO';
        update emdrInitial;
        
        CMPL123CME__EMDR__c eMDRInit2 = [SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123Task_Key_Value__c FROM CMPL123CME__EMDR__c where Id =: emdrInitial.Id];
        
        System.assertEquals(null, eMDRInit2.CMPL123CME__CMPL123Task_Key_Value__c);  
        //CHarm R6:End
    }

    /**
     * @Method       :
     * @Description  : update
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testMethod void afterUpdateHandlerTestMethod(){
        TestDataFactory.createSObject(new ADD_App_Settings__c(Restrict_Validation_Rules__c = true), true);

        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name FROM CMPL123CME__Complaint__c LIMIT 1];

        CMPL123CME__Questionnaire__c assessment = [SELECT Id, Name FROM CMPL123CME__Questionnaire__c LIMIT 1];

        Contact__c con = new Contact__c();
        con.Ticket__c = complaint.Id;
        con.Delete_Flag__c = false;
        insert con;

        Contact__c conpre = new Contact__c();
        conpre.Ticket__c = complaint.Id;
        conpre.pRE__c = true;
        conpre.Delete_Flag__c = false;
        insert conpre;

        Contact__c conPrimary = new Contact__c();
        conPrimary.Ticket__c = complaint.Id;
        conPrimary.Primary__c = true;
        conPrimary.Delete_Flag__c = false;

        insert conPrimary;

        Contact__c conExtpre = new Contact__c();
        conExtpre.Ticket__c = complaint.Id;
        conExtpre.pRE__c = true;
        conExtpre.Delete_Flag__c = false;
        conExtpre.External_ID__c = 'a98b1226-7614-e711-bb9a-005056bd0445';
        upsert conpre;

        Contact__c conExtPrimary = new Contact__c();
        conExtPrimary.Ticket__c = complaint.Id;
        conExtPrimary.Primary__c = true;
        conExtPrimary.Delete_Flag__c = false;
        conExtPrimary.External_ID__c = 'a98b1226-7614-e711-bb9a-005056bd0445';
        upsert conExtPrimary;
        Test.startTest();

        // 10-FEB-2023 Larry: Changed G1-Postal Code from "60064-3537" to "60064"
        // since it fails the new HL7 Compliance validation.
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            Last_Modified_Date_Time__c =  System.now(),
            Medical_Evaluation__c = assessment.Id,
            Submitted_to_TIBCO__c = false,
            H6_Evaluation_Codes_Required__c =  '0495' ,
            G1_Mfg_Site_Country_New2__c =  'USA ',
            E1_Country_New__c =  'DENMARK' ,
            G1_Contact_Office_Country_New__c =  'US' ,
            D3_Country_New__c =  'USA',
            G1_Mfg_Site_Region_State_New__c =  'Texas' ,
            G1_Contact_Office_Region_State_New__c =  'IL' ,
            E1_Region_State_New__c =  'IL' ,
            D3_Region_State_New__c =  'Texas' ,
            B3_Date_of_Event_v1__c =  'NI' ,
            Medical_Evaluator__c =  [SELECT Id FROM User Where UserName like  'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id,
            Registration_Number__c =  '0780780R1824231' ,
            F3_Region_State_Code__c =  'NI' ,
            F14_Region_State_Code__c =  'NI' ,
            Submission_Type__c =  [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            Division__c =  'ADD' ,
            Classification__c =  '803 Only' ,
            CMPL123CME__F3_Contact_Email_Null__c =  'NI' ,
            CMPL123CME__EMDR_Form_Version__c =  '2023' ,//CHaRM R6: updated the form version from 2018 to 2023
            CMPL123CME__C9_Evt_Abated_After_Use_Stopped2__c = 'NI' ,
            CMPL123CME__C9_Evt_Abated_After_Use_Stopped1__c =  'Yes' ,
            CMPL123CME__C8_Exp_Date2_Null__c =  'NI' ,
            CMPL123CME__C8_Exp_Date1_Null__c =  'NI' ,
            CMPL123CME__C7_Is_the_Product_Over_the_Counter2__c = 'NI' ,
            CMPL123CME__C7_Is_the_Product_Over_the_Counter1__c =  'NI' ,
            CMPL123CME__C6_Is_the_Product_Compounded2__c =  'NI' ,
            CMPL123CME__C6_Is_the_Product_Compounded1__c =  'NI' ,
            CMPL123CME__C4_Therapy_Dates_Start_Date2_Null__c =  'NI' ,
            CMPL123CME__C4_Therapy_Dates_Start_Date1_Null__c =  'NI' ,
            CMPL123CME__C4_Therapy_Date_Stop_Date2_Null__c =  'NI' ,
            CMPL123CME__C4_1_Therapy_Dates_Stop_Date1_Null__c =  'NI' ,
            CMPL123CME__C3_Route_Used2__c =  'NI' ,
            CMPL123CME__C3_Route_Used1__c =  'NI' ,
            CMPL123CME__C3_Frequency_Units2__c =  'NI' ,
            CMPL123CME__C3_Frequency_Units1__c =  'NI' ,
            CMPL123CME__C3_Dose_Units2__c =  'NI',
            CMPL123CME__C3_Dose_Units1__c =  'NI' ,
            CMPL123CME__C2_Concom_Med_Prod_and_Therapy_Dates__c =  'Use Field D11 for Concomitant Products/Dates' ,
            CMPL123CME__C10_Event_Reappeared_After_Reintroduct2__c =  'NI' ,
            CMPL123CME__C10_Event_Reappeared_After_Reintroduct1__c =  'NI' ,
            CMPL123CME__Validate_on_Save__c = false,
            //CHaRM-R4: EMDR HL7 Changes commenting "CMPL123CME__Unique_Identifier_UDI__c" discontinued field.
            //CMPL123CME__Unique_Identifier_UDI__c =  '3.81E+11' ,
            CMPL123CME__Registered_Site__c =  [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id ,
            CMPL123CME__Registered_Site_No__c =  'RS-0002' ,
            CMPL123CME__MDR_Due_Date__c =  Date.newInstance(2019, 12, 8),
            CMPL123CME__H8_Usage_of_Device__c =  'NI' ,
            CMPL123CME__H7_Other_Remedial_Action__c =  'NI' ,
            CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c =  'NI' ,
            CMPL123CME__H5_Labeled_for_Single_Use__c =  'No' ,
            CMPL123CME__H4_DEVICE_MANUFACTURE_DATE_NULL__c =  'NI' ,
             //CHaRM-R4: Commented the below code since CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c,CMPL123CME__H3_Evaluation_Summary_Attached__c,CMPL123CME__H3_Device_Returned__c and CMPL123CME__H11_Corrected_Data__c is removed from 2023 form.
           // CMPL123CME__H3_Evaluation_Summary_Attached__c =  'NI' ,
          //  CMPL123CME__H3_Device_Returned__c =  'NI' ,
            CMPL123CME__H3_DEVICE_EVAL_BY_MFG__c =  'NI' ,
           // CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c =  'NI' ,
            CMPL123CME__H1_Type_of_Reportable_Event__c =  'Malfunction' ,
           // CMPL123CME__H11_Corrected_Data__c =  'Testing' ,
            //(SA)CMPL123CME__G8_Adverse_Event_Term__c =  'NA' ,
            CMPL123CME__G7_Adverse_Event_Term_s__c =  'NA' ,
            CMPL123CME__G6_Type_of_Report__c =  'Initial' ,
            CMPL123CME__G6_If_ind_protocol_no__c =  'NI' ,
            CMPL123CME__G5_STN_No__c =  'NI' ,
            CMPL123CME__G5_Pre1938__c =  'NI' ,
            CMPL123CME__G5_OTCProduct__c =  'NI' ,
            CMPL123CME__G5_IND_No__c =  'NI' ,
            CMPL123CME__G5_CombinationProduct__c =  'NI' ,
            CMPL123CME__G5_A_NDA_No__c =  'NI' ,
            CMPL123CME__G3_Date_received_by_Mfg__c =  Date.newInstance(2018, 12, 8),
            //(SA)CMPL123CME__G3_Report_Source__c =  'Foreign;Study' ,
            CMPL123CME__G2_Report_Source__c =  'Foreign;Study' ,
            //(SA)CMPL123CME__G2_Contact_Office_Phone__c =  '+1(123)456-7890' ,
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G1_Mfg_Zip_Code__c =  '75038' ,
            CMPL123CME__G1_Mfg_Zip_Code_Extension__c =  '0987' ,
            CMPL123CME__G1_Mfg_Name__c =  'Abbott Manufacturing Inc' ,
            CMPL123CME__G1_Mfg_Fax_Number_Null__c =  'NI' ,
            CMPL123CME__G1_Mfg_E_mail_Null__c =  'NI' ,
            CMPL123CME__G1_Mfg_City__c =  'Irving' ,
            CMPL123CME__G1_Mfg_Address__c =  '1921 Hurd Drive' ,
            CMPL123CME__G1_Contact_Office_Title__c =  'RN' ,
            CMPL123CME__G1_Contact_Office_Postal_Code__c =  '60064' ,
            CMPL123CME__G1_Contact_Office_Last_Name__c =  'Romero-Kondos' ,
            CMPL123CME__G1_Contact_Office_First_Name__c =  'Noemi' ,
            CMPL123CME__G1_Contact_Office_Fax_Number__c =  '(224) 668-1167' ,
            CMPL123CME__G1_Contact_Office_Facility_Name__c =  'Abbott Laboratories',
            CMPL123CME__G1_Contact_Office_E_mail__c =  'noemi.romero-kondos@abbott.com' ,
            CMPL123CME__G1_Contact_Office_Division_Name__c =  'Diagnostic Division' ,
            CMPL123CME__G1_Contact_Office_City__c =  'Abbott Park' ,
            CMPL123CME__G1_Contact_Office_Address__c =  '100 Abbott Park Road' ,
            CMPL123CME__G1_Contact_Office_Address2__c =  'Dept. 09B9, LC CP1-3' ,
            CMPL123CME__F9_Approximate_Age_of_Device_Units__c =  'NI' ,
            CMPL123CME__F8_Date_of_This_Report_Null__c =  'NI' ,
            CMPL123CME__F7_Type_Report_Device__c =  'NI' ,
            CMPL123CME__F7_Follow_up_No__c =  'NI' ,
            CMPL123CME__F6_Aware_Date_Null__c =  'NI' ,
            CMPL123CME__F5_Phone_Number_Null__c =  'NI' ,
            CMPL123CME__F5_Contact_Email_Null__c =  'NI' ,
            CMPL123CME__F4_Contact_Title__c =  'NI',
            CMPL123CME__F4_Contact_Middle_Name__c =  'NI' ,
            CMPL123CME__F4_Contact_Last_Name__c =  'NI' ,
            CMPL123CME__F4_Contact_First_Name__c =  'NI' ,
            CMPL123CME__F3_Zip_Code__c =  'NI' ,
            CMPL123CME__F3_Zip_Code_Ext__c =  'NI' ,
            CMPL123CME__F3_Postal_Code__c =  'NI' ,
            CMPL123CME__F3_Name__c =  'NI' ,
            CMPL123CME__F3_City__c =  'NI' ,
            CMPL123CME__F3_Address__c =  'NI' ,
            CMPL123CME__F3_Address2__c =  'NI' ,
            CMPL123CME__F2_UF_Importer_Report_Number__c =  'NI' ,
            CMPL123CME__F1_Type_of_Reporter__c =  'NI' ,
            CMPL123CME__F14_Zip_Code__c =  'NI' ,
            CMPL123CME__F14_Zip_Code_Ext__c =  'NI' ,
            CMPL123CME__F14_Postal_Code__c =  'NI' ,
            CMPL123CME__F14_Name__c =  'NI' ,
            CMPL123CME__F14_Fax_Null__c =  'NI' ,
            CMPL123CME__F14_Email_Null__c =  'NI' ,
            CMPL123CME__F14_City__c =  'NI' ,
            CMPL123CME__F14_Address__c =  'NI' ,
            CMPL123CME__F14_Address2__c =  'NI',
            CMPL123CME__F13_Report_Sent_to_MFG__c =  'NI' ,
            CMPL123CME__F13_Date_Report_Sent_to_MFG_Null__c =  'NI' ,
            CMPL123CME__F12_Loc_where_event_occurred__c =  'NI' ,
            CMPL123CME__F12_Loc_where_event_occured_other__c =  'NI' ,
            CMPL123CME__F11_Report_Sent_to_FDA__c =  'NI' ,
            CMPL123CME__F11_Date_Sent_to_FDA_Null__c =  'NI' ,
            CMPL123CME__F10_Event_Problem_Code__c =  'NI' ,
            CMPL123CME__E4_Initial_Report_sent_to_FDA__c =  'Yes' ,
            CMPL123CME__E3_Occupation__c =  'Other Health Care Professional' ,
            CMPL123CME__E1_Zip_Code__c =  '7500',
            CMPL123CME__E1_Title__c =  'Spec' ,
            CMPL123CME__E1_Phone__c =  '+011()1234567890' ,
            CMPL123CME__E1_Last_Name__c =  'F' ,
            CMPL123CME__E1_Fax_Number_Null__c =  'NI' ,
            CMPL123CME__E1_Facility_Name__c =  'Complaints Division' ,
            CMPL123CME__E1_Email__c =  'test@abbott.com' ,
            CMPL123CME__E1_City__c =  'Waukegan' ,
            CMPL123CME__E1_Address_1__c =  '200' ,
            CMPL123CME__E1_Address2__c =  'Abbott Park' ,
            CMPL123CME__D7b_Fax_Number_Null__c =  'NI' ,
            CMPL123CME__D7b_E_mail_Null__c =  'NI' ,
            CMPL123CME__D7b_City__c =  'NI' ,
            CMPL123CME__D7b_Address_1__c =  'NI' ,
            CMPL123CME__D7b_Address_2__c =  'NI' ,
            CMPL123CME__D7a_Single_Use_Device__c =  'No' ,
            CMPL123CME__D6b_Explant_Date_Null__c = 'NI' ,
            CMPL123CME__D6a_Implant_Date_Null__c =  'NI' ,
            CMPL123CME__D5_Operator_of_Device__c =  'Health Professional' ,
            CMPL123CME__D4_Serial_No__c =  '6563254' ,
            CMPL123CME__D4_Lot_No__c =  '60273Y600' ,
            CMPL123CME__D4_Expiration_Date_Null__c =  'NI' ,
            CMPL123CME__D4_Catalog_No__c =  '06K26-41' ,
            CMPL123CME__D3_Zip_Code__c =  '75038' ,
            CMPL123CME__D3_Zip_Code_Ext__c =  '0987' ,
            CMPL123CME__D3_Phone_Number_Null__c =  'NI' ,
            CMPL123CME__D3_Name__c =  'Abbott Manufacturing Inc' ,
            CMPL123CME__D3_Fax_Number_Null__c =  'NI' ,
            CMPL123CME__D3_Email_Null__c =  'NI' ,
            CMPL123CME__D3_City__c =  'Irving' ,
            CMPL123CME__D3_Address__c =  '1921 Hurd Drive' ,
            CMPL123CME__D2b_Procode__c =  '456' ,
            CMPL123CME__D2_Common_Device_Name__c =  'PDM' ,
            CMPL123CME__D10_Concomitant_Product_Null__c =  'NI' ,
            CMPL123CME__D9_Device_available_for_Eval__c =  ' ' ,
            CMPL123CME__D9_Date_Returned_to_Mfg_Null__c =  'NI' ,
            CMPL123CME__CMPL123_WF_Status__c =  'Submitted to TIBCO' ,
            CMPL123CME__CMPL123_WF_Action__c =  'Sent to FDA' ,
            CMPL123CME__CMPL123_WF_Action_Performed_On__c =  System.now() ,
            CMPL123CME__CMPL123Rule_Key_Value__c =  'EMDR_WORKFLOW' ,
            CMPL123CME__B7_Other_Relevant_History__c =  'NI' ,
            CMPL123CME__B6_Relevant_Test_Laboratory_Data__c =  'NI' ,
            CMPL123CME__B5_Describe_Event_or_Problem__c =  'Death' ,
            CMPL123CME__B2_Outcomes_attributed_to_AE__c =  'Death' ,
            CMPL123CME__B2_Death_Date_Null__c =  'NI' ,
            CMPL123CME__B1_AdverseEvent_ProductProblem__c =  'Adverse Event;Product Problem' ,
            CMPL123CME__A4_Weight_Units_Patient__c =  'NI' ,
            CMPL123CME__A3_Sex__c =  'NI' ,
            CMPL123CME__A2_DOB_Null__c =  'NI' ,
            CMPL123CME__A2_Age_Units_Patient__c =  'NI' ,
            CMPL123CME__A1_Patient_Identifier__c =  'NI',
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            CMPL123CME__Complaint__c = complaint.Id
        ),true);

        //Create EMDR Supplemental
        TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            CMPL123CME__Initial_MDR__c = emdr.Id,
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            CMPL123CME__Complaint__c = complaint.Id,
            Medical_Evaluator__c =  [SELECT Id FROM User Where UserName like  'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Action__c = 'Open',
            Follow_Up_Required__c = 'No',
            CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            D3_Country1__c = [SELECT Id FROM Country__c LIMIT 1].Id,
            CMPL123CME__D9_Date_Returned_to_Mfg_Null__c = null,
            CMPL123CME__D7b_Fax_Number_Null__c = null,
            CMPL123CME__G1_Mfg_E_mail_Null__c = null,
            Medical_Evaluation__c = assessment.Id,
            CMPL123CME__G1_Mfg_Fax_Number_Null__c = null,
            //(SA)CMPL123CME__G8_Adverse_Event_Term__c = 'Adverse Event Term(s)',
            CMPL123CME__G7_Adverse_Event_Term_s__c = 'Adverse Event Term(s)',
            //CHaRM-R4: Commented the below code since CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c is removed from 2023 form.
           // CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c = 'Test Additional Text',
            CMPL123CME__H3_DEVICE_EVAL_BY_MFG__c = 'Yes',
            CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c = null,
            CMPL123CME__G5_Pre1938__c = 'Yes',
            CMPL123CME__G5_A_NDA_No__c = 'NA',
            CMPL123CME__G5_CombinationProduct__c = 'NA',
            CMPL123CME__G5_IND_No__c = 'NA',
            CMPL123CME__G5_OTCProduct__c = 'NA',
            //(SA)CMPL123CME__G5_PMA_510_K__c = 'NA',
            CMPL123CME__G4_PMA_510_k__c = 'NA',
            CMPL123CME__G5_STN_No__c = 'NA',
            CMPL123CME__G6_If_ind_protocol_no__c = 'NA',
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
        ),true);

        try {
            TestDataFactory.updateSObject(emdr);
        } catch (Exception e) {
            String msg = e.getMessage();
            Assert.isTrue(msg.contains('Evaluation') && msg.contains('H6'),
                '"H6 - Evaluation Codes" error message not found. Got: ' + msg);
        }

        CMPL123CME__MDR_Code__c mdrPaCode = [SELECT Id, Name,CMPL123CME__EMDR__c,CMPL123CME__EMDR_MDR_CODE_TYPE__c FROM CMPL123CME__MDR_Code__c WHERE CMPL123CME__EMDR_MDR_CODE_TYPE__c = 'PATIENT CODE' LIMIT 1];//
        mdrPaCode.CMPL123CME__EMDR__c = emdr.Id;
        TestDataFactory.updateSObject(mdrPaCode);
        CMPL123CME__MDR_Code__c mdrdvCode = [SELECT Id, Name,CMPL123CME__EMDR__c,CMPL123CME__EMDR_MDR_CODE_TYPE__c FROM CMPL123CME__MDR_Code__c WHERE CMPL123CME__EMDR_MDR_CODE_TYPE__c = 'DEVICE CODE' LIMIT 1];//
        mdrdvCode.CMPL123CME__EMDR__c = emdr.Id;
        TestDataFactory.updateSObject(mdrdvCode);
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Submit';
        emdr.H6_Evaluation_Codes_Required__c = mdrPaCode.Name;
        // 22-JUN-2023 Larry: Now sets E1-CountryNew since the field is now required on Submit.
        emdr.E1_Country_New__c = COUNTRY_NAME;
        try {
            TestDataFactory.updateSObject(emdr);
        } catch (Exception e) {
            String msg = e.getMessage();
            Assert.isTrue(msg.contains('Adverse') && msg.contains('H6'),
                '"H6 - Adverse Event Problem" error message not found. Got: ' + msg);
        }
        Test.stopTest();
    }

    /**
     * @Method       : updateMedicalEvaluationsTestMethod2
     * @Description  : update  CMPL123CME__EMDR__c.CMPL123CME__CMPL123_WF_Status__c Closed-Done and Create Country with submission
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testMethod void updateMedicalEvaluationsTestMethod2(){
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Test.startTest();

        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        //Create Country Submission
        Country_Submission_Type__c  objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30-day',
            Calendar_Days__c = 30,
            Country__c = objCountry.Id
        ), true);
        System.assertEquals('30-day', objCountrySubmissionType.Name);
        //Create EMDR
        CMPL123CME__EMDR__c initialTemp1 = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done'
            ),
            true
        );
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c)TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId =initialRTId,
            CMPL123CME__CMPL123_WF_Action__c = 'Open',
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
            Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
            Medical_Evaluator__c =  [SELECT Id FROM User WHERE Username like 'aspenIntegrationTestEMDRT@test.com%' LIMIT 1].Id,
            Medical_Evaluation__c = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1].Id,
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI'
        ),true);

        emdr.Follow_Up_Required__c = 'Yes';
        emdr.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done';
        emdr.CMPL123CME__Initial_MDR__c = initialTemp1.id;
        emdr.D9_Country1__c = objCountry.id;
        // 21-FEB-2023 Larry: Added Phone assignment. It overrides the TestDataFactory default.
        // The Country is USA, so it needs a USA phone number.
        emdr.CMPL123CME__E1_Phone__c = PHONE_FOR_USA;
        emdr.CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_FOR_USA;
        TestDataFactory.updateSObject(emdr);
        System.assertEquals('Yes', emdr.Follow_Up_Required__c);
        System.assertEquals('Closed-Done', emdr.CMPL123CME__CMPL123_WF_Status__c);

        try {
            emdr.Action_on_Follow_Up_Awareness_Date__c = 'Set Date';
            emdr.CMPL123CME__G3_Date_received_by_Mfg__c = System.today();
            TestDataFactory.updateSObject(emdr);
        } catch(DmlException de) {
            System.assert(de.getMessage().contains('New Follow Up Awareness Date is required'),true);
        }

        Test.stopTest();
    }

    /**
     * @Method       : fieldUpdatesFromWfRulesTest.
     * @Description  : To test moved to Apex WF Rules functionality.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @isTest
    static void fieldUpdatesFromWfRulesTest() {
        //Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId,
            CMSNext_Ticket_Number__c = '0601590C1446491'
        ),true);

        //Create Medical Evaluation
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = assmntRTId,
            CMPL123CME__Complaint__c = complaint.Id
        ),true);

        //Create Country
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(), true);

        //Create Submission Type
        Country_Submission_Type__c submissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30-day',
            Calendar_Days__c = 30,
            Country__c = objCountry.Id
        ), true);

        // Create Registered Site
        CMPL123CME__Registered_Site__c regSite = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(
            CMPL123CME__G1_Contact_Office_Region_State__c = 'NA',
            Division__c = 'ADD'
        ),true);


        //Create EMDR
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        // 23-FEB-2023 Larry: Now sets G1-Phone since the country is null.
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            CMPL123CME__B1_AdverseEvent_ProductProblem__c = 'Adverse Event;Product Problem',
            CMPL123CME__B2_Outcomes_attributed_to_AE__c = 'Disability or Permanent Damage',
            CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO',
            CMPL123CME__Complaint__c = complaint.Id,
            CMPL123CME__D3_Email_Null__c = 'NI',
            CMPL123CME__D3_Fax_Number_Null__c = 'NI',
            CMPL123CME__D3_Phone_Number_Null__c = 'NI',
            CMPL123CME__D3_Postal_Code__c = '123456',
            CMPL123CME__D4_Lot_No__c = '123456',
            CMPL123CME__D5_Operator_of_Device__c = 'Health Professional',
            CMPL123CME__E3_Occupation__c = 'Other Health Care Professional',
            CMPL123CME__E4_Initial_Report_sent_to_FDA__c = 'Yes',
            CMPL123CME__F9_Approximate_Age_of_Device_Units__c = 'NI',
            CMPL123CME__G1_Contact_Office_Phone_Number__c = PHONE_NOT_USA,
            CMPL123CME__G1_Contact_Office_Postal_Code__c = '123456',
            CMPL123CME__G1_Mfg_Fax_Number_Null__c = 'NI',
            CMPL123CME__G1_Mfg_Zip_Code__c = '75038',
            CMPL123CME__G1_Mfg_Zip_Code_Extension__c = '1234',
            //CHaRM-R4: Commented the below code since CMPL123CME__H11_Corrected_Data__c is removed from 2023 form.
           // CMPL123CME__H11_Corrected_Data__c = 'Corrected Data',
            CMPL123CME__H6_Adverse_Event_Problem__c = '1731',
            CMPL123CME__Registered_Site__c = regSite.Id,
            CMPL123CME__Submitted_Date_Time__c = Date.today(),
            Medical_Evaluation__c = medEval.Id,
            Medical_Evaluator__c = UserInfo.getUserId(),
            RecordTypeId = initialRTId,
            Report_Submitter__c = UserInfo.getUserId(),
            Submission_Type__c = submissionType.Id
        ),true);

        Test.startTest();

        //Ack Failed WF Rule Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Reject';
        emdr.CMPL123CME__CMPL123_WF_Status__c = 'Opened';
        TestDataFactory.updateSObject(emdr);
        
        System.assertEquals(null,
                            [SELECT Id, CMPL123CME__Submitted_Date_Time__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].CMPL123CME__Submitted_Date_Time__c,
                            'Submitted Date/Time should be null');
        System.assertEquals(null,
                            [SELECT Id, Report_Submitter__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Report_Submitter__c,
                            'Report Submitter should be null');

        //Autoset Registration Number WF Rule Test
        System.assertEquals('0601590C1446491',
                            [SELECT Id, Registration_Number__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Registration_Number__c,
                            'Registration Number should be copied from related Ticket');

        //Clear Follow Up Required? WF Rule Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Follow Up Required';
        emdr.CMPL123CME__CMPL123_WF_Status__c = 'Pending Follow Up Creation';
        emdr.Follow_Up_Required__c = 'No';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(null,
                            [SELECT Id, Follow_Up_Required__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Follow_Up_Required__c,
                            'Follow Up Required should be blank');
        System.assertEquals('Set to Blank',
                            [SELECT Id, Action_on_Follow_Up_Awareness_Date__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Action_on_Follow_Up_Awareness_Date__c,
                            'Action on Follow Up Awareness Date should be Set to Blank');

        // 23-FEB-2023 Larry: Removed this test because it is not a normal business practice.
        //
        // Setting "MDR Submission" to "Ready to Submit" makes the TWD package
        // do HL7 Compliance validations AND produce the MFR #. The "Generate MFR Report #"
        // Action supposedly existed to produce the MFR Report Number BEFORE the eMDR was ready.
        // Only documents for field actions might want to do that. HL7 Compliance
        // validations now include H6 Problem Codes, so it broke unit tests such as this.
        //
        //Update MDR Submission WF Rule
        // emdr.CMPL123CME__CMPL123_WF_Action__c = 'Generate MFR Report #';
        // TestDataFactory.updateSObject(emdr);
        // System.assertEquals('Ready to submit',
        //                    [SELECT Id, CMPL123CME__MDR_Submission__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].CMPL123CME__MDR_Submission__c,
        //                    'MDR Submission should be Ready to Submit');

        //Update workflow action based fields in eMDR && Update workflow action based fields in eMDR2 WF Rules

        //Ack 1 Received By Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Ack 1 Received';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),
                            [SELECT Id, Ack_1_Received_By__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Ack_1_Received_By__c,
                            'Ack 1 Received By should be current user');

        //Ack 1 Received On Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Ack 1 Received';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(DateTime.now().day(),
                            [SELECT Id, Ack_1_Received_On__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Ack_1_Received_On__c.day(),
                            'Ack 1 Received On should be current time');

        //Ack 2 Received By Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Ack 2 Received';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),
                            [SELECT Id, Ack_2_Received_By__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Ack_2_Received_By__c,
                            'Ack 2 Received By should be current user');

        //Ack 2 Received On Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Ack 2 Received';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(DateTime.now().day(),
                            [SELECT Id, Ack_2_Received_On__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Ack_2_Received_On__c.day(),
                            'Ack 2 Received On should be current time');

        //Ack 3 Received By Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Ack 3 Received';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),
                            [SELECT Id, Ack_3_Received_By__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Ack_3_Received_By__c,
                            'Ack 3 Received By should be current user');

        //Ack 3 Received On Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Ack 3 Received';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(DateTime.now().day(),
                            [SELECT Id, Ack_3_Received_On__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Ack_3_Received_On__c.day(),
                            'Ack 3 Received On should be current time');

        //Sent to FDA By Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Sent to FDA';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),
                            [SELECT Id, Sent_to_FDA_By__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Sent_to_FDA_By__c,
                            'Sent to FDA By should be current User');

        //Sent to FDA On Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Sent to FDA';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(DateTime.now().day(),
                            [SELECT Id, Sent_to_FDA_On__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Sent_to_FDA_On__c.day(),
                            'Sent to FDA On should be current time');

        Test.stopTest();
    }

    /**
     * @Method       : fieldUpdatesFromWfRulesTest2.
     * @Description  : To test moved to Apex WF Rules functionality.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @isTest
    static void fieldUpdatesFromWfRulesTest2() {
        //Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId,
            CMSNext_Ticket_Number__c = '0601590C1446491'
        ),true);

        //Create Country
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(), true);

        //Create Submission Type
        Country_Submission_Type__c submissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30-day',
            Calendar_Days__c = 30,
            Country__c = objCountry.Id
        ), true);

        //Create EMDR
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId = initialRTId,
            Medical_Evaluator__c = UserInfo.getUserId(),
            CMPL123CME__Complaint__c = complaint.Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Submitted to TIBCO',
            Submission_Type__c = submissionType.Id,
            CMPL123CME__Submitted_Date_Time__c = Date.today(),
            Report_Submitter__c = UserInfo.getUserId()
        ),true);

        //Update workflow panel WF Rule Test
        System.assertEquals('EMDR_WORKFLOW',
                            [SELECT Id, CMPL123CME__CMPL123Rule_Key_Value__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].CMPL123CME__CMPL123Rule_Key_Value__c,
                            'Rule Key Value should be EMDR_WORKFLOW');

        //Clear Report Submitter Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Ack 1 Failed';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(null,
                            [SELECT Id, Report_Submitter__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Report_Submitter__c,
                            'Report Submitter should be blank');

        //Closed By Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Close';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),
                            [SELECT Id, Closed_By__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Closed_By__c,
                            'Closed By should be current User');

        //Closed On Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Close';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(DateTime.now().day(),
                            [SELECT Id, Closed_On__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Closed_On__c.day(),
                            'Closed On should be current time');

        //Voided By Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Void';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),
                            [SELECT Id, Voided_By__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Voided_By__c,
                            'Voided By should be current User');

        //Voided On Field Update Test
        emdr.CMPL123CME__CMPL123_WF_Action__c = 'Void';
        TestDataFactory.updateSObject(emdr);
        System.assertEquals(DateTime.now().day(),
                            [SELECT Id, Voided_On__c FROM CMPL123CME__EMDR__c WHERE Id =: emdr.Id].Voided_On__c.day(),
                            'Voided On should be current time');
    }

     // [CR] 1029/1198
    @IsTest
    private static void eMDRReopenTest() {
        Test.startTest();
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User admin = TestUtil.insertTestUser(
                adminProfileId,
                'adminEMDR@test.com',
                'adminEMDR@test.com'
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
                        Name = 'EMDR Workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'EMDR_WORKFLOW',
                        CMPL123__Target_Object__c = 'CMPL123CME__EMDR__c(EMDR_WORKFLOW)'),
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

        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                RecordTypeId = initialRTId,
                CMPL123CME__CMPL123_WF_Action__c = 'Close',
                Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
                CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
                Follow_Up_Required__c = 'No',
                CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done',
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
                Ticket_Review__c = [SELECT Id FROM Ticket_Review__c LIMIT 1].Id,
                CMPL123CME__G3_Date_received_by_Mfg__c = System.today()),true);


        Id evaInvestGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Medical_Evaluator'].Id;
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;

        User evalInvestigator = TestUtil.insertTestUser(
                aspenUserProfileId,
                'medEvalTestEMDR@test.com',
                'medEvalTestEMDR@test.com'
        );

        System.runAs(admin) {
            insert new GroupMember(
                    GroupId = evaInvestGroupId,
                    UserOrGroupId = evalInvestigator.Id
            );
        }

        System.runAs(evalInvestigator) {
            emdr.CMPL123CME__CMPL123_WF_Status__c = endStatus.Name;
            emdr.CMPL123CME__CMPL123_WF_Action__c = wfAction.Name;
            update emdr;
        }

        Id supplementallRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Supplemental').getRecordTypeId();
        CMPL123CME__EMDR__c emdrSupplemental = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                RecordTypeId = supplementallRTId,
                CMPL123CME__CMPL123_WF_Action__c = 'Close',
                Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
                CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
                Follow_Up_Required__c = 'No',
                CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done',
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
                Ticket_Review__c = [SELECT Id FROM Ticket_Review__c LIMIT 1].Id,
                CMPL123CME__Initial_MDR__c = emdr.Id,
                CMPL123CME__G3_Date_received_by_Mfg__c = System.today()),true);

        System.runAs(evalInvestigator) {
            emdrSupplemental.CMPL123CME__CMPL123_WF_Status__c = endStatus.Name;
            emdrSupplemental.CMPL123CME__CMPL123_WF_Action__c = wfAction.Name;
            update emdrSupplemental;
        }

        CMPL123CME__EMDR__c result = [
                SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c
                FROM CMPL123CME__EMDR__c
                WHERE Id = :emdr.Id
        ];
        CMPL123CME__EMDR__c resultSupplemental = [
                SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c
                FROM CMPL123CME__EMDR__c
                WHERE Id = :emdrSupplemental.Id
        ];
        Test.stopTest();

        System.assertEquals(endStatus.Name, result.CMPL123CME__CMPL123_WF_Status__c);
        System.assertEquals(wfAction.Name, result.CMPL123CME__CMPL123_WF_Action__c);

        System.assertEquals(endStatus.Name, resultSupplemental.CMPL123CME__CMPL123_WF_Status__c);
        System.assertEquals(wfAction.Name, resultSupplemental.CMPL123CME__CMPL123_WF_Action__c);
    }

    /**
     * Pos/neg tests for setFieldsE1Country
     * 
     * Verify accessibility to setFieldsE1Country from beforeUpdateHandlerTestMethod
     * This test assumes that makeCountryLookup is functional
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testSetFieldsE1Country() {
        final CMPL123CME__EMDR__c EMDR_ORIGINAL = new CMPL123CME__EMDR__c(
            RecordTypeId = EMDRTriggerHandler.recordTypeIdInitial
        );
        final String ERROR_MAKE_INVALID = 'Should make the record invalid';
        final String ERROR_EXPECT_VALID = 'Should have no errors';
        final String ERROR_FIND_GOOD_NAME = 'Should find an affiliated Country with a valid country name';
        final String ERROR_FIND_CASED_NAME = 'Should find an affiliated Country even if the name has the incorrect casing';
        final String ERROR_FIND_GOOD_CODE = 'Should find an affiliated Country with a valid country code';
        final String ERROR_FIND_CASED_CODE = 'Should find an affiliated Country even if the code has the incorrect casing';
        final String ERROR_NOT_IN_MAP = 'Should not find a suitable country in the map';
        final String COUNTRY_NAME_CHINA = 'CHINA';
        final String COUNTRY_CODE_INDIA = 'IND';
        final String COUNTRY_INVALID = 'totally invalid!';
        final String EMPTY_STRING = '';

        Country__c countryIndia = new Country__c(
            Name = 'INDIA',
            Country_Code__c = COUNTRY_CODE_INDIA,
            Active__c = true
        );
        Country__c countryChina = new Country__c(
            Name = COUNTRY_NAME_CHINA,
            Country_Code__c = 'CHN',
            Active__c = true
        );
        Map<String, Country__c> countryNameOrCodeToRecord = new Map<String, Country__c>{
            countryIndia.Name            => countryIndia,
            countryIndia.Country_Code__c => countryIndia,
            countryChina.Name            => countryChina,
            countryChina.Country_Code__c => countryChina
        };
        CMPL123CME__EMDR__c emdr = EMDR_ORIGINAL.clone();

        Test.startTest();
        // Tests for Initial EMDRs
        {
            emdr.E1_Country_New__c = COUNTRY_CODE_INDIA;
            Assert.areEqual(countryIndia.Country_Code__c,
                EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_POS + ERROR_FIND_GOOD_CODE);
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = COUNTRY_NAME_CHINA;
            Assert.areEqual(countryChina.Country_Code__c,
                EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_POS + ERROR_FIND_GOOD_NAME);
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = COUNTRY_CODE_INDIA.toLowerCase();
            Assert.areEqual(countryIndia.Country_Code__c,
                EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_POS + ERROR_FIND_CASED_CODE);
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = COUNTRY_NAME_CHINA.toLowerCase();
            Assert.areEqual(countryChina.Country_Code__c,
                EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_POS + ERROR_FIND_CASED_NAME);
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = COUNTRY_INVALID;
            Assert.areEqual(EMPTY_STRING, EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_NEG + ERROR_NOT_IN_MAP);
            Assert.isTrue(emdr.hasErrors(), ERROR_NEG + ERROR_MAKE_INVALID);
            // Use clone to remove errors
            emdr = EMDR_ORIGINAL.clone();

            emdr.E1_Country_New__c = '';
            Assert.areEqual(EMPTY_STRING, EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_NEG + 'Initial EMDRs cannot leave E1-Country blank');
            Assert.isTrue(emdr.hasErrors(), ERROR_NEG + ERROR_MAKE_INVALID);
            emdr = EMDR_ORIGINAL.clone();

            emdr.E1_Country_New__c = null;
            Assert.areEqual(EMPTY_STRING, EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_NEG + 'Initial EMDRs cannot leave E1-Country null');
            Assert.isTrue(emdr.hasErrors(), ERROR_NEG + ERROR_MAKE_INVALID);
            emdr = EMDR_ORIGINAL.clone();
        }

        // Tests for Supplemental EMDRs
        // The main difference with Initial EMDRs is how null and blank countries are treated
        {
            emdr.RecordTypeId = EMDRTriggerHandler.recordTypeIdSuppl;
            emdr.E1_Country_New__c = COUNTRY_CODE_INDIA;
            Assert.areEqual(countryIndia.Country_Code__c,
                EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_POS + ERROR_FIND_GOOD_CODE);
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = COUNTRY_NAME_CHINA;
            Assert.areEqual(countryChina.Country_Code__c,
                EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_POS + ERROR_FIND_GOOD_NAME);
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = COUNTRY_CODE_INDIA.toLowerCase();
            Assert.areEqual(countryIndia.Country_Code__c,
                EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_POS + ERROR_FIND_CASED_CODE);
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = COUNTRY_NAME_CHINA.toLowerCase();
            Assert.areEqual(countryChina.Country_Code__c,
                EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_POS + ERROR_FIND_CASED_NAME);
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = COUNTRY_INVALID;
            Assert.areEqual(EMPTY_STRING, EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_NEG + ERROR_NOT_IN_MAP);
            Assert.isTrue(emdr.hasErrors(), ERROR_NEG + ERROR_MAKE_INVALID);
            emdr = EMDR_ORIGINAL.clone();

            emdr.RecordTypeId = EMDRTriggerHandler.recordTypeIdSuppl;
            emdr.E1_Country_New__c = '';
            Assert.areEqual(EMPTY_STRING, EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_NEG + 'Supplemental EMDRs are ALLOWED to have a blank E1-Country');
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);

            emdr.E1_Country_New__c = null;
            Assert.areEqual(EMPTY_STRING, EMDRTriggerHandler.setFieldsE1Country(countryNameOrCodeToRecord, emdr),
                ERROR_NEG + 'Supplemental EMDRs are ALLOWED to have a null E1-Country');
            Assert.isFalse(emdr.hasErrors(), ERROR_POS + ERROR_EXPECT_VALID);
        }
        Test.stopTest();
    }
}