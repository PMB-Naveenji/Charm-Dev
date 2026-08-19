/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2023 Capgemini
 * @What  : EMDRFieldUpdatesTest
 * @Why   : Test class for EMDRFieldUpdates.
 * 
 * Most code coverage comes from EMDRTriggerHandlerTest.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      Description 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             21-MAR-2023            CHaRM R3.0           Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Dinesh Kumar             02-Feb-2024            CHaRM R4.0           Updated the method "testSetDefaultsAndNullFlavorsPosAsNull",
 *                                                                        "testSetDefaultsAndNullFlavorsPosNotNullA",
 *                                                                        "testSetDefaultsAndNullFlavorsQuery" and Added new Method "testForEMDRfields"
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Dinesh KUmar             12-FEB-2025            CHaRM-R6/IPDR 618    Updated the Country Submission type name value to '30-day' and Active field is added
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
@isTest(isParallel=true)
class EMDRFieldUpdatesTest {
    private static final Date TODAY = System.today();
    private static final String THE_EMAIL = 'a@b.com';
    private static final String THE_PHONE = '+1(111)111-2222';
    private static final Integer THE_NUMBER = 2;
    private static final String THE_AGE_UNITS = 'Years';
    private static final String NULL_FLAVOR_NI = 'NI';
    private static final String NULL_FLAVOR_NA = 'NA';
    private static final String ERROR_MUST_BE_NULL_FLAVOR = 'String should BE a null flavor';
    private static final String ERROR_CANNOT_BE_NULL_FLAVOR = 'String should NOT be a null flavor';

    @testSetup
    static void makeData(){
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(), true);
        //CHaRM R6: Updated the Name value to '30-day' and added Active field equal to True for the Country - Submission Type record.
        TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30-day',
            Calendar_Days__c = 30,
            Country__c = objCountry.Id,
            Active__c = true
        ), true);
        //CHaRM-R4-Start
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId),true);  
        //Create Country
        Country__c country = (Country__c) TestDataFactory.createSObject(
            
                new Country__c(Name = 'USA'), true);
        
            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c  = '123',
                List_Number__c = '12345'
            ), true);
            //Create Product ticket
            TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = product.Id,
                Event_Ticket__c= complaint.Id,
                Batch_Lot_Serial__c = '1235',
                Unique_Device_Identifier__c = '1234567890'
            ), true);
            // Create Assessment
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        RecordTypeId = assmntRTId,
                        CMPL123_WF_Status__c = 'Regulatory',
                        Reportability_Rationale__c = 'Test Rationale',
                        Reportability__c = 'Reportable',
                        Reportability_Category__c = 'Per Procedure',
                        Initial_Follow_Up_Mfg_Analysis_New__c = 'Test',
                        Final_Mfg_Analysis_New__c = 'Test Final'         
                ), true);
         //CHaRM-R4-End        
    }

    /**
     * Helper for testSetDefaultsAndNullFlavors that queries for the eMDR.
     * @author 21-MAR-2023 Larry Resnik
     */
    private static CMPL123CME__EMDR__c testSetDefaultsAndNullFlavorsQuery(Id emdrId) {
        return [
            SELECT Id,
            CMPL123CME__A2_DOB_Null__c,
            CMPL123CME__A2_Age_Units_Patient__c,
            CMPL123CME__A4_Weight_Units_Patient__c,
            CMPL123CME__A5_Ethnicity__c,
            CMPL123CME__A6_Race__c,
            CMPL123CME__B2_Death_Date_Null__c,
            CMPL123CME__B2_Outcomes_attributed_to_AE_Null__c,
            B3_Date_of_Event_v1__c,
            CMPL123CME__D9_Date_Returned_to_Mfg_Null__c,
            CMPL123CME__D3_Email_Null__c,
            CMPL123CME__D3_Fax_Number_Null__c,
            //CHaRM-R4 - Start-Added New fields in the Query
            CMPL123CME__D4_Primary_UDI_Number__c,
            CMPL123CME__A3a_Sex__c,
            CMPL123CME__A3b_Gender__c,
            CMPL123CME__H11_Additional_Mfg_Narrative__c,
            //CHaRM-R4- Stop
            CMPL123CME__D4_Expiration_Date_Null__c,
            CMPL123CME__D6a_Implant_Date_Null__c,
            CMPL123CME__D6b_Explant_Date_Null__c,
            CMPL123CME__D7b_E_mail_Null__c,
            CMPL123CME__D7b_Fax_Number_Null__c,
            CMPL123CME__E1_E_Mail_Null__c,
            CMPL123CME__E1_Fax_Number_Null__c,
            CMPL123CME__E1_Phone_Null__c,
            CMPL123CME__G7_Adverse_Event_Term_s__c,
            CMPL123CME__G1_Contact_Office_Fax_Number_Null__c,
            CMPL123CME__G1_Mfg_E_mail_Null__c,
            CMPL123CME__G1_Mfg_Fax_Number_Null__c,
            CMPL123CME__G1_Contact_Office_Phone_Number_Null__c,
            CMPL123CME__H4_DEVICE_MANUFACTURE_DATE_NULL__c,
            CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c,
            CMPL123CME__H5_Labeled_for_Single_Use__c,
            CMPL123CME__D7a_Single_Use_Device__c,
            CMPL123CME__D9_Device_available_for_Eval__c
            FROM CMPL123CME__EMDR__c
            WHERE Id = :emdrId
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Pos tests for setDefaultsAndNullFlavors such that values ARE null
     * 
     * Sections C and F are not used in CHaRM, so their fields are excluded from tests
     * @author 21-MAR-2023 Larry Resnik
     */
    @isTest
    static void testSetDefaultsAndNullFlavorsPosAsNull() {
        Test.startTest();
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                CMPL123CME__A2_DOB__c = null,
                CMPL123CME__A2_Age_at_Time_of_Event__c = null,
                CMPL123CME__A4_Weight__c = null,
                CMPL123CME__A5_Ethnicity__c = null,
                CMPL123CME__A6_Race__c = null,
                CMPL123CME__B2_Date_of_Death__c = null,
                CMPL123CME__B2_Outcomes_attributed_to_AE__c = null,
                CMPL123CME__B3_Date_of_Event__c = null,
                CMPL123CME__D9_Date_returned_to_Mfg__c = null,
                CMPL123CME__D3_Email__c = null,
                CMPL123CME__D3_Fax_Number__c = null,
                CMPL123CME__D3_Phone_Number__c = null,
                CMPL123CME__D4_Expiration_Date__c = null,
                CMPL123CME__D6a_Implant_Date__c = null,
                CMPL123CME__D6b_Explant_Date__c = null,
                CMPL123CME__D7b_E_mail__c = null,
                CMPL123CME__D7b_Fax_Number__c = null,
                CMPL123CME__E1_Email__c = null,
                CMPL123CME__E1_Fax__c = null,
                CMPL123CME__E1_Phone__c = null,
                CMPL123CME__G7_Adverse_Event_Term_s__c = null,
                CMPL123CME__G1_Contact_Office_E_mail__c = null,
                CMPL123CME__G1_Contact_Office_Fax_Number__c = null,
                CMPL123CME__G1_Mfg_Email__c = null,
                CMPL123CME__G1_Mfg_Fax_Number__c = null,
                CMPL123CME__G2_Contact_Office_Phone__c = null,
                CMPL123CME__G1_Contact_Office_Phone_Number__c = null,
                CMPL123CME__H4_Device_mfg_date__c = null,
                CMPL123CME__H7_If_Remedical_Action_Init__c = null,
                CMPL123CME__H5_Labeled_for_Single_Use__c = null,
                CMPL123CME__D7a_Single_Use_Device__c = null,
                CMPL123CME__A3a_Sex__c = null,
                CMPL123CME__A3b_Gender__c = null                
            ), true
        );
        Test.stopTest();

        emdr = testSetDefaultsAndNullFlavorsQuery(emdr.Id);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A2_DOB_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A2_Age_Units_Patient__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A4_Weight_Units_Patient__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A5_Ethnicity__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A6_Race__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__B2_Death_Date_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__B2_Outcomes_attributed_to_AE_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.B3_Date_of_Event_v1__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D9_Date_Returned_to_Mfg_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D3_Email_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D3_Fax_Number_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D4_Expiration_Date_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D6a_Implant_Date_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D6b_Explant_Date_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D7b_E_mail_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D7b_Fax_Number_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__E1_E_Mail_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__E1_Fax_Number_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__E1_Phone_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NA, emdr.CMPL123CME__G7_Adverse_Event_Term_s__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__G1_Contact_Office_Fax_Number_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__G1_Mfg_E_mail_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__G1_Mfg_Fax_Number_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__G1_Contact_Office_Phone_Number_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__H4_DEVICE_MANUFACTURE_DATE_NULL__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        //CHaRM-R4:Start Assert To check A3a-Sex and A3b - gender fields populate NI when blank upon save
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A3a_Sex__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        System.assertEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A3b_Gender__c,
            ERROR_MUST_BE_NULL_FLAVOR);
        //CHaRM-R4:End
        // I do not know what is setting this to "No", but it is not setDefaultsAndNullFlavors
        System.assertEquals(AspenConstants.STR_No, emdr.CMPL123CME__H5_Labeled_for_Single_Use__c,
            'Expected the field to be "No" before getting to setDefaultsAndNullFlavors');
        System.assertEquals(AspenConstants.STR_No, emdr.CMPL123CME__D7a_Single_Use_Device__c,
            'Field should change from null to "No"');
    }

    /**
     * Pos tests for setDefaultsAndNullFlavors such that values are NOT null
     * @author 21-MAR-2023 Larry Resnik
     */
    @isTest
    static void testSetDefaultsAndNullFlavorsPosNotNullA() {
        Test.startTest();
                CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                CMPL123CME__A2_DOB__c = TODAY,
                CMPL123CME__A4_Weight__c = THE_NUMBER,
                CMPL123CME__A5_Ethnicity__c = 'Not Hispanic/Latino',
                CMPL123CME__A6_Race__c = 'White',
                CMPL123CME__B2_Date_of_Death__c = TODAY,
                CMPL123CME__B2_Outcomes_attributed_to_AE__c = 'Disability or Permanent Damage',
                CMPL123CME__B3_Date_of_Event__c = TODAY,
                CMPL123CME__D9_Date_returned_to_Mfg__c = TODAY,
                CMPL123CME__D3_Email__c = THE_EMAIL,
                CMPL123CME__D3_Fax_Number__c = THE_PHONE,
                CMPL123CME__D3_Phone_Number__c = THE_PHONE,
                CMPL123CME__D4_Expiration_Date__c = TODAY,
                CMPL123CME__D6a_Implant_Date__c = TODAY,
                CMPL123CME__D6b_Explant_Date__c = TODAY,
                CMPL123CME__D7b_E_mail__c = THE_EMAIL,
                CMPL123CME__D7b_Fax_Number__c = THE_PHONE,
                CMPL123CME__E1_Email__c = THE_EMAIL,
                CMPL123CME__E1_Fax__c = THE_PHONE,
                CMPL123CME__E1_Phone__c = THE_PHONE,
                CMPL123CME__G7_Adverse_Event_Term_s__c = 'Stuff goes here',
                CMPL123CME__G1_Contact_Office_E_mail__c = THE_EMAIL,
                CMPL123CME__G1_Contact_Office_Fax_Number__c = THE_PHONE,
                CMPL123CME__G1_Mfg_Email__c = THE_EMAIL,
                CMPL123CME__G1_Mfg_Fax_Number__c = THE_PHONE,
                CMPL123CME__G2_Contact_Office_Phone__c = THE_PHONE,
                CMPL123CME__G1_Contact_Office_Phone_Number__c = THE_PHONE,
                CMPL123CME__H4_Device_mfg_date__c = TODAY,
                CMPL123CME__H7_If_Remedical_Action_Init__c = 'Recall',
                CMPL123CME__H5_Labeled_for_Single_Use__c = AspenConstants.STR_Yes,
                CMPL123CME__D7a_Single_Use_Device__c = AspenConstants.STR_Yes,
                //CHaRM-R4:Start
                Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
                Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
                //CHaRM-R4:Stop
                // Fields below this comment must be set because the fields above have been set
                CMPL123CME__A4_Weight_Units_Patient__c = 'LBS'
            ), true
        );
        Test.stopTest();

        emdr = testSetDefaultsAndNullFlavorsQuery(emdr.Id);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A2_DOB_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A4_Weight_Units_Patient__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A5_Ethnicity__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__A6_Race__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__B2_Death_Date_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__B2_Outcomes_attributed_to_AE_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.B3_Date_of_Event_v1__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D9_Date_Returned_to_Mfg_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D3_Email_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D3_Fax_Number_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D4_Expiration_Date_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D6a_Implant_Date_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D6b_Explant_Date_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D7b_E_mail_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__D7b_Fax_Number_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__E1_E_Mail_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__E1_Fax_Number_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__E1_Phone_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NA, emdr.CMPL123CME__G7_Adverse_Event_Term_s__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__G1_Contact_Office_Fax_Number_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__G1_Mfg_E_mail_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__G1_Mfg_Fax_Number_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__G1_Contact_Office_Phone_Number_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__H4_DEVICE_MANUFACTURE_DATE_NULL__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        System.assertNotEquals(NULL_FLAVOR_NI, emdr.CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c,
            ERROR_CANNOT_BE_NULL_FLAVOR);
        // I do not know what is setting this to "No", but it is not setDefaultsAndNullFlavors
        System.assertEquals(AspenConstants.STR_No, emdr.CMPL123CME__H5_Labeled_for_Single_Use__c,
            'Expected the field to be "No" before getting to setDefaultsAndNullFlavors');
        System.assertEquals(AspenConstants.STR_Yes, emdr.CMPL123CME__D7a_Single_Use_Device__c,
            'Field value should not change');
        //CHaRM-R4:Start
        //Check the assert for D4-Primary UDI Number is populated with the value from Product-Tickets Unique Device Identifier
        System.assertEquals('1234567890', emdr.CMPL123CME__D4_Primary_UDI_Number__c,
            'D4-Primary UDI Number should be populated from Product-Tickets Unique Device Identifier');
        //CHaRM-R4:Stop
    }

    /**
     * Pos tests for setDefaultsAndNullFlavors such that values are NOT null.
     * Date of Birth (DOB) and Age at Time of Event are mutually exclusive,
     * so one is tested in the test...NotNullA method and the other tested here.
     * @author 21-MAR-2023 Larry Resnik
     */
    @isTest
    static void testSetDefaultsAndNullFlavorsPosNotNullB() {
        Test.startTest();
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                CMPL123CME__A2_DOB__c = null,
                CMPL123CME__A2_Age_at_Time_of_Event__c = THE_NUMBER,
                CMPL123CME__A2_Age_Units_Patient__c = THE_AGE_UNITS
            ), true
        );
        Test.stopTest();

        emdr = testSetDefaultsAndNullFlavorsQuery(emdr.Id);
        System.assertEquals(THE_AGE_UNITS, emdr.CMPL123CME__A2_Age_Units_Patient__c,
            'Age Unit should be retained if Age at Time of Event is non-null');
    }
    
      //CHaRM-R4-Start
    /**
     * @Method       : testForEMDRfields
     * @Description  : CHaRM-R4- To check the assserts for H11-Additional MFG Narrative and EMDR Form Version field population.
     * @Return       : N/A
     * @Params       : N/A
     **/
    @isTest
    static void testForEMDRfields() {
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
                        Initial_Follow_Up_Mfg_Analysis_New__c = 'Test',
                        Final_Mfg_Analysis_New__c = 'Test Final',
                     B1_Adverse_Event_Product_Problem_New__c = 'Product Problem',
                    Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)
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
                Products__c = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
                Product__c = [SELECT Id FROM Product_Ticket__c LIMIT 1].Id,
                Medical_Evaluation__c = assessment.Id,
                CMPL123CME__G7_Adverse_Event_Term_s__c = 'Stuff goes here',
                CMPL123CME__H7_If_Remedical_Action_Init__c = 'Recall',
                CMPL123CME__H5_Labeled_for_Single_Use__c = AspenConstants.STR_Yes,
                CMPL123CME__D7a_Single_Use_Device__c = AspenConstants.STR_Yes,
                CMPL123CME__A4_Weight_Units_Patient__c = 'LBS'
            ), true
        );
        Test.stopTest(); 
        //Check the Assert for H11 Additional Mfg Narrative field is populated from Final Mfg Analysis field from Medical Evaluation object.
        CMPL123CME__EMDR__c emdR1 = [Select id,CMPL123CME__EMDR_Form_Version__c,CMPL123CME__H11_Additional_Mfg_Narrative__c from CMPL123CME__EMDR__c WHERE id =: emdr.id];
        System.assertEquals('Test Final', emdR1.CMPL123CME__H11_Additional_Mfg_Narrative__c,
            'H11-Additional Mfg Narrative should be populated'); 
        //Check the Assert for EMDR Form Version field is populated with 2023 value
        System.assertEquals('2023', emdR1.CMPL123CME__EMDR_Form_Version__c,
            'EMDR Form version should be 2023'); 
    }
    //CHaRM-R4 : Stop
}