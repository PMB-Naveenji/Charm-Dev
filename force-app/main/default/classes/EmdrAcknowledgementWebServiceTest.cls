/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
 * @What  : DemoteToServiceWorkflowProcess_Test.
 * @Why   : Unit tests for CMPL123CME_EMDR_AuditTrigger.
 * @When  : 15-OCT-2018.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer            Date                   Modification ID      Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                05-DEC-2016            N/A                  Created
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                04-JUN-2020            Code Audit           Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                10-JUN-2020            N/A                  Updated code part, which is related
 *                                                                  to Users' insertion. This change designed
 *                                                                  to prevent a 'DUPLICATE_USERNAME' error during
 *                                                                  deployment to Production environment
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                15-JUN-2020            Code Audit          Removed commented code. Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                27-JUL-2020            Code Audit          Adjusted class/methods headers.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman           03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G4_Date_received_by_MFG__c to CMPL123CME__G3_Date_received_by_Mfg__c.
 *                                                                  Changed CMPL123CME__G7_Type_of_Report_MultiSelect__c to CMPL123CME__G6_Type_of_Report__c
 *                                                                  Changed CMPL123CME__D6_Implant_Date__c to CMPL123CME__D6a_Implant_Date__c
 *                                                                  Changed CMPL123CME__D6_Implant_Date_Null__c to CMPL123CME__D6a_Implant_Date_Null__c
 *                                                                  Changed CMPL123CME__D7_Explant_Date__c to CMPL123CME__D6b_Explant_Date__c
 *                                                                  Changed CMPL123CME__D7_Explant_Date_Null__c to CMPL123CME__D6b_Explant_Date_Null__c
 *                                                                  Changed CMPL123CME__D8_Single_Use_Device__c to CMPL123CME__D7a_Single_Use_Device__c
 *                                                                  Changed CMPL123CME__D9_Name__c to CMPL123CME__D7b_Name__c
 *                                                                  Changed CMPL123CME__D9_Address__c to CMPL123CME__D7b_Address_1__c
 *                                                                  Changed CMPL123CME__D9_Address2__c to CMPL123CME__D7b_Address_2__c
 *                                                                  Changed CMPL123CME__D9_City__c to CMPL123CME__D7b_City__c
 *                                                                  Changed CMPL123CME__D9_Region_State__c to CMPL123CME__D7b_Region_State__c
 *                                                                  Changed CMPL123CME__D9_Postal_Code__c to CMPL123CME__D7b_Postal_Code__c
 *                                                                  Changed CMPL123CME__D9_Fax_Number__c to CMPL123CME__D7b_Fax_Number__c
 *                                                                  Changed CMPL123CME__D9_Fax_Number_Null__c to CMPL123CME__D7b_Fax_Number_Null__c
 *                                                                  Changed CMPL123CME__D9_E_mail_Null__c to CMPL123CME__D7b_E_mail_Null__c
 *                                                                  Changed CMPL123CME__D10_Device_available_for_Eval__c to CMPL123CME__D9_Device_available_for_Eval__c
 *                                                                  Changed CMPL123CME__D10_Date_returned_to_MFG__c to CMPL123CME__D9_Date_returned_to_Mfg__c
 *                                                                  Changed CMPL123CME__D10_Date_Returned_to_Mfg_Null__c to CMPL123CME__D9_Date_Returned_to_Mfg_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Sameer               09-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G2_Contact_Office_Phone__c -> CMPL123CME__G1_Contact_Office_Phone_Number__c
 *                                                                  Changed CMPL123CME__G2_Contact_Office_Phone_Null__c -> CMPL123CME__G1_Contact_Office_Phone_Number_Null__c
 *                                                                  Changed CMPL123CME__G5_PMA_510_K__c -> CMPL123CME__G4_PMA_510_k__c
 *                                                                  Changed CMPL123CME__G8_Adverse_Event_Term__c -> CMPL123CME__G7_Adverse_Event_Term_s__c
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         24-FEB-2023            CHaRM R3.0, TWD upgrade   Fixed all test methods which crash due to HL7 Compliance validation changes
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar         16-JAN-2024            CHaRM-R4.0            updated the method autoPopulateRelatedTest
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest
public class EmdrAcknowledgementWebServiceTest {
    // 24-FEB-2023 Larry: Added one constant to differentiate old code using the
    // invalid(?) Problem Code from new code which does not use it.
    private static final String CODE_TYPE_STATE = 'STATE CODE';

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup
    static void setup() {
        //Create User
        Profile aspenIntegrationProfile = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'];
        User aspenInteg = TestUtil.insertTestUser(
                aspenIntegrationProfile.Id,
                'aspenIntegrationTestEMDR@test.com',
                'aspenIntegrationTestEMDR@test.com'
        );
        // Create Application Setup data
        CMPL123__CMPL_App_Config__c appConfig = (CMPL123__CMPL_App_Config__c) TestDataFactory.createSObject(new CMPL123__CMPL_App_Config__c(), true);

        // Create Country
        Country__c country = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'USA'), true);

        // Create Country
        Country__c naCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'NA', Primary_Vigilance_Contact__c = aspenInteg.Id), true);

        //Create Account
        Account account = (Account) TestDataFactory.createSObject(new Account(
                Country__c = country.Id,
                ShippingState = 'NA',
                ShippingCountry = 'USA')
                , true);

        // Create Contact
        Contact contact = (Contact) TestDataFactory.createSObject(new Contact(), true);

        //Create Complaint Code
        // 24-FEB-2023 Larry: Note that I do not think that eMDRs use the
        // "STATE CODE" Problem Code if the Form Version is "2018" or later.
        CMPL123CME__Complaint_Code__c countryCode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(Name = 'NA', CMPL123CME__Type__c = CODE_TYPE_STATE), true);

        // Create Registered Site
        CMPL123CME__Registered_Site__c rs = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(CMPL123CME__G1_Contact_Office_Region_State__c = 'NA', Division__c = 'ADD'), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId), true);


        // Create Assessment
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = assmntRTId,
                CMPL123CME__Complaint__c = complaint.Id
        ), true);

        //System.assertEquals(null, [SELECT Date_Due__c FROM CMPL123CME__Questionnaire__c WHERE Id = :assessment.Id].Date_Due__c);

        // Create Investigation
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
                CMPL123CME__Complaint__c = complaint.Id,
                CMPL123_WF_Status__c = 'Opened',
                CMPL123_WF_Action_Performed_On__c = System.today()
        ), true);

        // 23-FEB-2023 Larry: Now inserts all Problem Code types for section H6
        Map<String, CMPL123CME__Complaint_Code__c> cmpCodeNameToRecord =
            TestUtil.makeMdrProblemCodes();
        insert cmpCodeNameToRecord.values();
    }

    /*
    * @Method       : autoPopulateRelatedTest.
    * @Description  : Events from TriggerHandler before insert of eMDR.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void autoPopulateRelatedTest() {
        User aspenIntegrationUser = [SELECT Id FROM User WHERE Username LIKE 'aspenIntegrationTestEMDR@test.com%'];
        Test.startTest();
        // Get the Complaint Record
        System.runAs(aspenIntegrationUser) {
            CMPL123CME__Complaint__c complaint = [
                    SELECT Id, Name
                    FROM CMPL123CME__Complaint__c
                    WHERE Name != 'cmpltest-00123'
                    LIMIT 1
            ];
            //Get Complaint Code
            CMPL123CME__Complaint_Code__c objComplaintCode = [
                    SELECT ID
                    FROM CMPL123CME__Complaint_Code__c
                    WHERE CMPL123CME__Type__c = :CODE_TYPE_STATE
            ];
            //Get Country
            Country__c objCountry = [SELECT Id FROM Country__c Where Name = 'NA' Limit 1];
            CMPL123CME__Questionnaire__c assessment = [
                    SELECT ID
                    FROM CMPL123CME__Questionnaire__c
                    WHERE CMPL123CME__Complaint__c = :complaint.Id
            ];
            //Create Country
            Country__c objectCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objectCountry.Id), true);

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

            // Create Registered Site
            CMPL123CME__Registered_Site__c regSite = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(CMPL123CME__G1_Contact_Office_Region_State__c = 'NA', Division__c = 'ADD'), true);


            Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
            CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                    RecordTypeId = initialRTId, CMPL123CME__CMPL123_WF_Action__c = 'Open', Submission_Type__c = objCountrySubmissionType.Id, CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                    Products__c = product.id, Product__c = prodTckt.id, CMPL123CME__Registered_Site__c = regSite.id, CMPL123CME__D7b_Region_State__c = objComplaintCode.Id, D9_Country1__c = objCountry.Id, CMPL123CME__D3_Region_State__c = objComplaintCode.Id), true);

            CMPL123CME__EMDR__c emdrUpdated = [
                    /*(SA)
                    SELECT ID, G1_Contact_Office_Country1__c, D3_Country1__c, CMPL123CME__Registered_Site_No__c, CMPL123CME__Registered_Site__c, CMPL123CME__G1_Mfg_Site_Region_State__c, CMPL123CME__D3_Region_State__c, CMPL123CME__G1_Contact_Office_Region_State__c, CMPL123CME__E1_Region_State__c, CMPL123CME__D7b_Region_State__c, CMPL123CME__D7b_Country__c, CMPL123CME__Complaint__c, CMPL123CME__MDR_Due_Date__c, CMPL123CME__B1_AdverseEvent_ProductProblem__c, CMPL123CME__B5_Describe_Event_or_Problem__c, CMPL123CME__B7_Other_Relevant_History__c, CMPL123CME__B2_Date_of_Death__c, CMPL123CME__B3_Date_of_Event__c, CMPL123CME__B6_Relevant_Test_Laboratory_Data__c, CMPL123CME__B2_Death_Date_Null__c, CMPL123CME__B2_Outcomes_attributed_to_AE_Null__c, CMPL123CME__D1_Brand_Name__c, CMPL123CME__D2_Common_Device_Name__c, CMPL123CME__D2b_Procode__c, CMPL123CME__D3_Phone_Number__c, CMPL123CME__D3_Phone_Number_Null__c, CMPL123CME__D4_Expiration_Date__c, CMPL123CME__Unique_Identifier_UDI__c, CMPL123CME__D5_Operator_of_Device__c, CMPL123CME__D5_Other_operator_of_Device__c, CMPL123CME__D3_Name__c, CMPL123CME__D3_Address__c, CMPL123CME__D3_Address2__c, CMPL123CME__D3_City__c, CMPL123CME__A2_Age_at_Time_of_Event__c, CMPL123CME__Become_Aware_Date__c, CMPL123CME__A2_Age_Units_Patient__c, CMPL123CME__A2_DOB__c, CMPL123CME__A2_DOB_Null__c, CMPL123CME__A3_Sex__c, CMPL123CME__A4_Weight__c, CMPL123CME__A4_Weight_Units_Patient__c, CMPL123CME__D3_Postal_Code__c, CMPL123CME__D3_Email__c, CMPL123CME__D3_Email_Null__c, CMPL123CME__D3_Fax_Number__c, CMPL123CME__D3_Fax_Number_Null__c, CMPL123CME__D4_Lot_No__c, CMPL123CME__D4_Catalog_No__c, CMPL123CME__D4_Serial_No__c, CMPL123CME__D4_Expiration_Date_Null__c, CMPL123CME__D6a_Implant_Date__c, CMPL123CME__D6a_Implant_Date_Null__c, CMPL123CME__D6b_Explant_Date__c, CMPL123CME__D6b_Explant_Date_Null__c, CMPL123CME__D4_Model_No__c, CMPL123CME__D7a_Single_Use_Device__c, CMPL123CME__D8_Single_Use_Device_Null__c, CMPL123CME__D7b_Name__c, CMPL123CME__D7b_Address_1__c, CMPL123CME__D7b_Postal_Code__c, CMPL123CME__D7b_Fax_Number__c, CMPL123CME__D7b_E_mail_Null__c, CMPL123CME__D7b_Fax_Number_Null__c, CMPL123CME__D9_Date_returned_to_Mfg__c, CMPL123CME__D9_Device_available_for_Eval__c, CMPL123CME__D9_Date_Returned_to_Mfg_Null__c, CMPL123CME__E1_Last_Name__c, CMPL123CME__E1_First_Name__c, CMPL123CME__E3_Occupation__c, CMPL123CME__E1_Title__c, CMPL123CME__E1_Facility_Name__c, E1_Country1__c, E1_Country1__r.Name, CMPL123CME__E1_Address_1__c, CMPL123CME__E1_City__c, CMPL123CME__E1_Phone__c, CMPL123CME__E1_Fax__c, CMPL123CME__E1_Email__c, CMPL123CME__E1_Address2__c, CMPL123CME__E1_Phone_Null__c, CMPL123CME__E1_E_Mail_Null__c, CMPL123CME__E1_Fax_Number_Null__c, CMPL123CME__E4_Initial_Report_sent_to_FDA__c, CMPL123CME__E1_Postal_Code__c, CMPL123CME__F1_Type_of_Reporter__c, CMPL123CME__F5_Contact_Email_Null__c, CMPL123CME__F6_Aware_Date_Null__c, CMPL123CME__F7_Type_Report_Device__c, CMPL123CME__F8_Date_of_This_Report_Null__c, CMPL123CME__F9_Approximate_Age_of_Device_Units__c, CMPL123CME__F11_Report_Sent_to_FDA__c, CMPL123CME__F11_Date_Sent_to_FDA_Null__c, CMPL123CME__F12_Loc_where_event_occurred__c, CMPL123CME__F13_Report_Sent_to_MFG__c, CMPL123CME__F13_Date_Report_Sent_to_MFG_Null__c, CMPL123CME__F14_Email_Null__c, CMPL123CME__F14_Fax_Null__c, CMPL123CME__F5_Phone_Number_Null__c, CMPL123CME__G1_Contact_Office_First_Name__c, CMPL123CME__G1_Contact_Office_Last_Name__c, CMPL123CME__G1_Contact_Office_Middle_Name__c, CMPL123CME__G1_Contact_Office_Title__c, CMPL123CME__G1_Contact_Office_E_mail__c, CMPL123CME__G1_Contact_Office_Fax_Number__c, CMPL123CME__G1_Contact_Office_Address__c, CMPL123CME__G1_Contact_Office_Address2__c, CMPL123CME__G1_Contact_Office_City__c, CMPL123CME__G1_Contact_Office_Division_Name__c, CMPL123CME__G1_Contact_Office_Facility_Name__c, CMPL123CME__G1_Contact_Office_Postal_Code__c, CMPL123CME__G2_Contact_Office_Phone__c, CMPL123CME__G1_Contact_Office_E_mail_Null__c, CMPL123CME__G1_Contact_Office_Fax_Number_Null__c, CMPL123CME__G2_Contact_Office_Phone_Null__c, CMPL123CME__G1_Mfg_Address__c, CMPL123CME__G1_Mfg_City__c, CMPL123CME__G1_Mfg_Email__c, CMPL123CME__G1_Mfg_Fax_Number__c, CMPL123CME__G1_Mfg_Name__c, G1_Mfg_Site_Country1__r.Name, CMPL123CME__G1_Mfg_Postal_Code__c, CMPL123CME__G1_Mfg_E_mail_Null__c, CMPL123CME__G1_Mfg_Fax_Number_Null__c, CMPL123CME__G3_Date_received_by_Mfg__c, CMPL123CME__G5_PMA_510_K__c, CMPL123CME__G5_OTCProduct__c, CMPL123CME__G5_Pre1938__c, CMPL123CME__G5_CombinationProduct__c, CMPL123CME__G5_A_NDA_No__c, CMPL123CME__G5_STN_No__c, CMPL123CME__G5_IND_No__c, CMPL123CME__G6_If_ind_protocol_no__c, CMPL123CME__G6_Type_of_Report__c, CMPL123CME__H1_Type_of_Reportable_Event__c, CMPL123CME__H5_Labeled_for_Single_Use__c, CMPL123CME__H10_Addtl_Mfg_Narrative__c, CMPL123CME__H4_Device_mfg_date__c, CMPL123CME__H4_DEVICE_MANUFACTURE_DATE_NULL__c, CMPL123CME__H2_IF_FOLLOW_UP_WHAT_TYPE_NULL__c, CMPL123CME__H3_REASON_NO_EVAL_BY_MFG__c, CMPL123CME__H7_If_Remedical_Action_Init__c, CMPL123CME__H8_Usage_of_Device__c, CMPL123CME__H3_Device_Returned__c, CMPL123CME__D7b_Address_2__c, CMPL123CME__D7b_City__c, CMPL123CME__H7_Other_Remedial_Action__c, CMPL123CME__H9_Correction_Removal_Report_No__c
                    FROM CMPL123CME__EMDR__c
                    WHERE Id = :emdr.Id
                    */
                    //CHaRM-R4: CMPL123CME__H10_Addtl_Mfg_Narrative__c is replaced with CMPL123CME__H11_Additional_Mfg_Narrative__c and CMPL123CME__Unique_Identifier_UDI__c is repaced with CMPL123CME__D4_Primary_UDI_Number__c And removed CMPL123CME__H3_REASON_NO_EVAL_BY_MFG__c and CMPL123CME__H3_Device_Returned__c.
                    SELECT ID, G1_Contact_Office_Country1__c, D3_Country1__c, CMPL123CME__Registered_Site_No__c, CMPL123CME__Registered_Site__c, CMPL123CME__G1_Mfg_Site_Region_State__c, CMPL123CME__D3_Region_State__c, CMPL123CME__G1_Contact_Office_Region_State__c, CMPL123CME__E1_Region_State__c, CMPL123CME__D7b_Region_State__c, D9_Country1__c, CMPL123CME__Complaint__c, CMPL123CME__MDR_Due_Date__c, CMPL123CME__B1_AdverseEvent_ProductProblem__c, CMPL123CME__B5_Describe_Event_or_Problem__c, CMPL123CME__B7_Other_Relevant_History__c, CMPL123CME__B2_Date_of_Death__c, CMPL123CME__B3_Date_of_Event__c, CMPL123CME__B6_Relevant_Test_Laboratory_Data__c, CMPL123CME__B2_Death_Date_Null__c, CMPL123CME__B2_Outcomes_attributed_to_AE_Null__c, CMPL123CME__D1_Brand_Name__c, CMPL123CME__D2_Common_Device_Name__c, CMPL123CME__D2b_Procode__c, CMPL123CME__D3_Phone_Number__c, CMPL123CME__D3_Phone_Number_Null__c, CMPL123CME__D4_Expiration_Date__c, CMPL123CME__D4_Primary_UDI_Number__c, CMPL123CME__D5_Operator_of_Device__c, CMPL123CME__D5_Other_operator_of_Device__c, CMPL123CME__D3_Name__c, CMPL123CME__D3_Address__c, CMPL123CME__D3_Address2__c, CMPL123CME__D3_City__c, CMPL123CME__A2_Age_at_Time_of_Event__c, CMPL123CME__Become_Aware_Date__c, CMPL123CME__A2_Age_Units_Patient__c, CMPL123CME__A2_DOB__c, CMPL123CME__A2_DOB_Null__c, CMPL123CME__A3_Sex__c, CMPL123CME__A4_Weight__c, CMPL123CME__A4_Weight_Units_Patient__c, CMPL123CME__D3_Postal_Code__c, CMPL123CME__D3_Email__c, CMPL123CME__D3_Email_Null__c, CMPL123CME__D3_Fax_Number__c, CMPL123CME__D3_Fax_Number_Null__c, CMPL123CME__D4_Lot_No__c, CMPL123CME__D4_Catalog_No__c, CMPL123CME__D4_Serial_No__c, CMPL123CME__D4_Expiration_Date_Null__c, CMPL123CME__D6a_Implant_Date__c, CMPL123CME__D6a_Implant_Date_Null__c, CMPL123CME__D6b_Explant_Date__c, CMPL123CME__D6b_Explant_Date_Null__c, CMPL123CME__D4_Model_No__c, CMPL123CME__D7a_Single_Use_Device__c, CMPL123CME__D8_Single_Use_Device_Null__c, CMPL123CME__D7b_Name__c, CMPL123CME__D7b_Address_1__c, CMPL123CME__D7b_Postal_Code__c, CMPL123CME__D7b_Fax_Number__c, CMPL123CME__D7b_E_mail_Null__c, CMPL123CME__D7b_Fax_Number_Null__c, CMPL123CME__D9_Date_returned_to_Mfg__c, CMPL123CME__D9_Device_available_for_Eval__c, CMPL123CME__D9_Date_Returned_to_Mfg_Null__c, CMPL123CME__E1_Last_Name__c, CMPL123CME__E1_First_Name__c, CMPL123CME__E3_Occupation__c, CMPL123CME__E1_Title__c, CMPL123CME__E1_Facility_Name__c, E1_Country1__c, E1_Country1__r.Name, CMPL123CME__E1_Address_1__c, CMPL123CME__E1_City__c, CMPL123CME__E1_Phone__c, CMPL123CME__E1_Fax__c, CMPL123CME__E1_Email__c, CMPL123CME__E1_Address2__c, CMPL123CME__E1_Phone_Null__c, CMPL123CME__E1_E_Mail_Null__c, CMPL123CME__E1_Fax_Number_Null__c, CMPL123CME__E4_Initial_Report_sent_to_FDA__c, CMPL123CME__E1_Postal_Code__c, CMPL123CME__F1_Type_of_Reporter__c, CMPL123CME__F5_Contact_Email_Null__c, CMPL123CME__F6_Aware_Date_Null__c, CMPL123CME__F7_Type_Report_Device__c, CMPL123CME__F8_Date_of_This_Report_Null__c, CMPL123CME__F9_Approximate_Age_of_Device_Units__c, CMPL123CME__F11_Report_Sent_to_FDA__c, CMPL123CME__F11_Date_Sent_to_FDA_Null__c, CMPL123CME__F12_Loc_where_event_occurred__c, CMPL123CME__F13_Report_Sent_to_MFG__c, CMPL123CME__F13_Date_Report_Sent_to_MFG_Null__c, CMPL123CME__F14_Email_Null__c, CMPL123CME__F14_Fax_Null__c, CMPL123CME__F5_Phone_Number_Null__c, CMPL123CME__G1_Contact_Office_First_Name__c, CMPL123CME__G1_Contact_Office_Last_Name__c, CMPL123CME__G1_Contact_Office_Middle_Name__c, CMPL123CME__G1_Contact_Office_Title__c, CMPL123CME__G1_Contact_Office_E_mail__c, CMPL123CME__G1_Contact_Office_Fax_Number__c, CMPL123CME__G1_Contact_Office_Address__c, CMPL123CME__G1_Contact_Office_Address2__c, CMPL123CME__G1_Contact_Office_City__c, CMPL123CME__G1_Contact_Office_Division_Name__c, CMPL123CME__G1_Contact_Office_Facility_Name__c, CMPL123CME__G1_Contact_Office_Postal_Code__c, CMPL123CME__G1_Contact_Office_Phone_Number__c, CMPL123CME__G1_Contact_Office_E_mail_Null__c, CMPL123CME__G1_Contact_Office_Fax_Number_Null__c, CMPL123CME__G1_Contact_Office_Phone_Number_Null__c, CMPL123CME__G1_Mfg_Address__c, CMPL123CME__G1_Mfg_City__c, CMPL123CME__G1_Mfg_Email__c, CMPL123CME__G1_Mfg_Fax_Number__c, CMPL123CME__G1_Mfg_Name__c, G1_Mfg_Site_Country1__r.Name, CMPL123CME__G1_Mfg_Postal_Code__c, CMPL123CME__G1_Mfg_E_mail_Null__c, CMPL123CME__G1_Mfg_Fax_Number_Null__c, CMPL123CME__G3_Date_received_by_Mfg__c, CMPL123CME__G4_PMA_510_k__c, CMPL123CME__G5_OTCProduct__c, CMPL123CME__G5_Pre1938__c, CMPL123CME__G5_CombinationProduct__c, CMPL123CME__G5_A_NDA_No__c, CMPL123CME__G5_STN_No__c, CMPL123CME__G5_IND_No__c, CMPL123CME__G6_If_ind_protocol_no__c, CMPL123CME__G6_Type_of_Report__c, CMPL123CME__H1_Type_of_Reportable_Event__c, CMPL123CME__H5_Labeled_for_Single_Use__c, CMPL123CME__H11_Additional_Mfg_Narrative__c, CMPL123CME__H4_Device_mfg_date__c, CMPL123CME__H4_DEVICE_MANUFACTURE_DATE_NULL__c, CMPL123CME__H2_IF_FOLLOW_UP_WHAT_TYPE_NULL__c, CMPL123CME__H7_If_Remedical_Action_Init__c, CMPL123CME__H8_Usage_of_Device__c, CMPL123CME__D7b_Address_2__c, CMPL123CME__D7b_City__c, CMPL123CME__H7_Other_Remedial_Action__c, CMPL123CME__H9_Correction_Removal_Report_No__c
                    FROM CMPL123CME__EMDR__c
                    WHERE Id = :emdr.Id
            ];


            // Assert for D9 Region State and Country
            CMPL123CME__Complaint_Code__c complaintCode = [
                    SELECT ID
                    FROM CMPL123CME__Complaint_Code__c
                    WHERE CMPL123CME__Type__c = :CODE_TYPE_STATE
            ];
            System.assertEquals(complaintCode.Id, emdrUpdated.CMPL123CME__D7b_Region_State__c);
            Country__c country = [SELECT Id FROM Country__c Where Name = 'NA' Limit 1];
            System.assertEquals(emdrUpdated.D9_Country1__c, country.Id);

            // Assert for Auto populate states for D,E and G  section
            System.assertEquals(complaintCode.Id, emdrUpdated.CMPL123CME__D3_Region_State__c);
        }
        Test.stopTest();
    }

    /*
    * @Method       : autoCreateSupplementalTestMethod.
    * @Description  : Events from TriggerHandler before insert of eMDR.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void autoCreateSupplementalTestMethod() {
        User aspenIntegrationUser = [SELECT Id FROM User WHERE Username LIKE 'aspenIntegrationTestEMDR@test.com%'];
        Test.startTest();
        // Get the Complaint Record
        System.runAs(aspenIntegrationUser) {
            // Get the Complaint Record
            CMPL123CME__Complaint__c complaint = [
                    SELECT Id
                    FROM CMPL123CME__Complaint__c
                    WHERE Name != 'cmpltest-00123'
                    LIMIT 1
            ];

            CMPL123CME__Questionnaire__c assessment = [
                    SELECT ID
                    FROM CMPL123CME__Questionnaire__c
                    WHERE CMPL123CME__Complaint__c = :complaint.Id
            ];

            //Create Country
            Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objCountry.Id), true);

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

            // Create Registered Site
            CMPL123CME__Registered_Site__c regSite = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(CMPL123CME__G1_Contact_Office_Region_State__c = 'NA', Division__c = 'ADD'), true);


            //Get Complaint Code
            CMPL123CME__Complaint_Code__c objComplaintCode = [
                    SELECT ID
                    FROM CMPL123CME__Complaint_Code__c
                    WHERE CMPL123CME__Type__c = :CODE_TYPE_STATE
            ];

            Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
            CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                    RecordTypeId = initialRTId,
                    CMPL123CME__CMPL123_WF_Action__c = 'Open',
                    Submission_Type__c = objCountrySubmissionType.Id,
                    CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                    Products__c = product.id,
                    Product__c = prodTckt.id,
                    CMPL123CME__Registered_Site__c = regSite.id,
                    CMPL123CME__D7b_Region_State__c = objComplaintCode.Id,
                    D9_Country1__c = objCountry.Id,
                    CMPL123CME__D3_Region_State__c = objComplaintCode.Id), true);


            Country__c country = [SELECT Id FROM Country__c WHERE Name = 'NA' LIMIT 1];
            Id supRecordTypeID = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Supplemental').getRecordTypeId();
            CMPL123CME__EMDR__c emd = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                    // Id = emdr.Id,
                    CMPL123CME__CMPL123_WF_Status__c = 'Pending Final Review',
                    D3_Country1__c = country.Id,
                    CMPL123CME__D9_Date_Returned_to_Mfg_Null__c = null,
                    CMPL123CME__D7b_Fax_Number_Null__c = null,
                    CMPL123CME__G1_Mfg_E_mail_Null__c = null,
                    CMPL123CME__G1_Mfg_Fax_Number_Null__c = null,
                    //(SA)CMPL123CME__G8_Adverse_Event_Term__c = 'OAdverse Event Term(s)',
                    CMPL123CME__G7_Adverse_Event_Term_s__c = 'Adverse Event Term(s)',
                    CMPL123CME__H3_DEVICE_EVAL_ADDL_TEXT__c = 'Test Additional Text',
                    CMPL123CME__H3_DEVICE_EVAL_BY_MFG__c = 'Yes',
                    CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c = null,
                    CMPL123CME__G5_Pre1938__c = 'Yes',
                    CMPL123CME__G5_A_NDA_No__c = 'NA',
                    CMPL123CME__G5_CombinationProduct__c = 'NA',
                    CMPL123CME__G5_IND_No__c = 'NA',
                    CMPL123CME__G5_OTCProduct__c = 'NA',
                    /*(SA)
                    CMPL123CME__G5_PMA_510_K__c = 'NA',
                    */
                    CMPL123CME__G4_PMA_510_k__c = 'NA',
                    CMPL123CME__G5_STN_No__c = 'NA',
                    CMPL123CME__G6_If_ind_protocol_no__c = 'NA'
            ), true);
            TestDataFactory.updateSObject(emd);


            // Close Emdr
            emd.CMPL123CME__CMPL123_WF_Status__c = 'Pending Closure';
            TestDataFactory.updateSObject(emd);
            //Create Suplemental EMDR
            CMPL123CME__EMDR__c objEmdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                    CMPL123CME__Initial_MDR__c = emd.Id,
                    RecordTypeId = supRecordTypeID,
                    CMPL123CME__MDR_Due_Date__c = System.today().addDays(25)), true); 
            // Assert supplemental has been created
            //Id supRecordTypeID = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Supplemental').getRecordTypeId();
            CMPL123CME__EMDR__c supEmdr = [SELECT Id, CMPL123CME__MDR_Due_Date__c FROM CMPL123CME__EMDR__c WHERE CMPL123CME__Initial_MDR__c = :emd.Id AND RecordTypeId = :supRecordTypeID LIMIT 1];
            System.assert(supEmdr.Id != null);

            //@cr - requested dat: 06/01/2018  Assert for Date Due
            System.assertEquals(System.today().addDays(25), supEmdr.CMPL123CME__MDR_Due_Date__c);
        }
        Test.stopTest();
    }

    /*
    * @Method       : validateEMDRAcknowledgementTestMethod.
    * @Description  : Test class for the EmdrAcknowledgementWebService(which will internally
    *                 call the AVE_EmdrAcknowledgementWebServiceHandler class).
    * @Invoke       : Events from EMDRTriggerHandler class  after insert.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void validateEMDRAcknowledgementTestMethod() {
        User aspenIntegrationUser = [SELECT Id FROM User WHERE Username LIKE 'aspenIntegrationTestEMDR@test.com%'];
        Test.startTest();
        // Get the Complaint Record
        System.runAs(aspenIntegrationUser) {
            // Get the Complaint Record
            CMPL123CME__Complaint__c complaint = [
                    SELECT Id
                    FROM CMPL123CME__Complaint__c
                    WHERE Name != 'cmpltest-00123'
                    LIMIT 1
            ];
            // Get Investigation
            CMPL123CME__Investigation__c investigation = [
                    SELECT ID
                    FROM CMPL123CME__Investigation__c
                    WHERE CMPL123_WF_Status__c = 'Opened' AND
                    CMPL123CME__Complaint__c = :complaint.Id
            ];
            // Get Assessment
            CMPL123CME__Questionnaire__c assessment = [
                    SELECT ID
                    FROM CMPL123CME__Questionnaire__c
                    WHERE CMPL123CME__Complaint__c = :complaint.Id
            ];

            //Create Country
            Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objCountry.Id), true);

            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            // Create Product ticket
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            // Create Registered Site
            CMPL123CME__Registered_Site__c registeredSite = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(CMPL123CME__G1_Contact_Office_Region_State__c = 'NA', Division__c = 'ADD'), true);


            //Create EMDR
            Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
            CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                    RecordTypeId = initialRTId, CMPL123CME__CMPL123_WF_Action__c = 'Open', Submission_Type__c = objCountrySubmissionType.Id, CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                    Products__c = product.id, Product__c = prodTckt.id, CMPL123CME__Registered_Site__c = registeredSite.id), true);

            Map<String, CMPL123CME__Complaint_Code__c> cmpCodeNameToRecord =
                new Map<String, CMPL123CME__Complaint_Code__c>();
            for (CMPL123CME__Complaint_Code__c cmpCode : [
                SELECT Id, CMPL123CME__Type__c
                FROM CMPL123CME__Complaint_Code__c
                WHERE CMPL123CME__Type__c != :CODE_TYPE_STATE])
            {
                cmpCodeNameToRecord.put(cmpCode.CMPL123CME__Type__c, cmpCode);
            }

            // 23-FEB-2023 Larry: Succeeded in passing HL7 validations by adding
            // these H6 Problem Code junction records for the EMDR.
            List<CMPL123CME__MDR_Code__c> mdrCodeJuncList = new List<CMPL123CME__MDR_Code__c>();
            for (String codeType : AspenConstants.MDR_CODE_TYPES) {
                System.assertNotEquals(null, cmpCodeNameToRecord.get(codeType).Id);
                mdrCodeJuncList.add(
                    (CMPL123CME__MDR_Code__c) TestDataFactory.createSObject(
                    new CMPL123CME__MDR_Code__c(
                        CMPL123CME__Complaint_Code__c = cmpCodeNameToRecord.get(codeType).Id,
                        CMPL123CME__EMDR__c = emdr.Id,
                        // Note: Category is VITAL when validating the H6 codes. If you get an error like
                        // "H6 Medical Device Problem Code is a mandatory code", then maybe you forgot to set this.
                        CMPL123CME__Category__c = AspenConstants.MDR_CODE_CATEGORY_EVAL
                    ), false)
                );
            }
            insert mdrCodeJuncList;

            //Create Country
            EMDR_Integration__c emdrInteg1 = (EMDR_Integration__c) TestDataFactory.createSObject(new EMDR_Integration__c(Value__c = 'ACK1', name = 'EMDR_Acknowledgement1'), true);
            EMDR_Integration__c emdrInteg2 = (EMDR_Integration__c) TestDataFactory.createSObject(new EMDR_Integration__c(Value__c = 'ACK2', name = 'EMDR_Acknowledgement2'), true);
            EMDR_Integration__c emdrInteg3 = (EMDR_Integration__c) TestDataFactory.createSObject(new EMDR_Integration__c(Value__c = 'ACK3', name = 'EMDR_Acknowledgement3'), true);
            EMDR_Integration__c emdrInteg4 = (EMDR_Integration__c) TestDataFactory.createSObject(new EMDR_Integration__c(Value__c = 'EMDR_Not_Found', name = 'NOT_FOUND'), true);

            // Create Submission History for ACK1
           CMPL123CME__Submission_History__c ack1Submission = (CMPL123CME__Submission_History__c) TestDataFactory.createSObject(new CMPL123CME__Submission_History__c(
                    CMPL123CME__Stage__c = 'ACK1',
                    CMPL123CME__Related_EMDR__c = emdr.Id
            ), true);
            // Create Submission History for ACK2
            CMPL123CME__Submission_History__c ack2Submission = (CMPL123CME__Submission_History__c) TestDataFactory.createSObject(new CMPL123CME__Submission_History__c(
                    CMPL123CME__Stage__c = 'Ack2',
                    CMPL123CME__Related_EMDR__c = emdr.Id,
                    CMPL123CME__Core_Id__c = 'ci1461727908998'
            ), true);
            // Create Submission History for NOT_FOUND
            CMPL123CME__Submission_History__c notFoundSubmission = (CMPL123CME__Submission_History__c) TestDataFactory.createSObject(new CMPL123CME__Submission_History__c(
                    CMPL123CME__Stage__c = 'Ack1',
                    CMPL123CME__Related_EMDR__c = emdr.Id,
                    CMPL123CME__Message_Id__c = '&lt;AS2.17.BizLink&gt'
            ), true);

            Id ack2emdrId = EmdrAcknowledgementWebService.validateEMDRAcknowledgement('Ack2', '&lt;AS2.17.BizLink&gt');
            Id ack3emdrId = EmdrAcknowledgementWebService.validateEMDRAcknowledgement('Ack3', 'ci1461727908998');

            // Assert for returning EMDR Id for ACK2
            System.assertEquals([SELECT Id FROM CMPL123CME__EMDR__c WHERE CMPL123CME__MDR_Submission__c = 'Submitted' LIMIT 1].Id, ack2emdrId);

            // Assert for returning EMDR Id for ACK3
            System.assertEquals([SELECT Id FROM CMPL123CME__EMDR__c WHERE CMPL123CME__MDR_Submission__c = 'Submitted' LIMIT 1].Id, ack3emdrId);

            ack1Submission.CMPL123CME__Message_Id__c = '<AS2.17.BizLink>';

            //Update ACK1 Submission History
            TestDataFactory.updateSObject(ack1Submission);

            EmdrAcknowledgementWebService.validateEMDRAcknowledgement('Ack1', '<AS2.17.BizLink>');

            EmdrAcknowledgementWebService.validateEMDRAcknowledgement('Ack2', '&lt;AS2.17.BizLink&gt');
        }
        Test.stopTest();
    }

    /*
    * @Method       : validateEMDRAckWithoutSubmissionHistoryTestMethod.
    * @Description  : Test class for the EmdrAcknowledgementWebService(which will
    *                 internally call the AVE_EmdrAcknowledgementWebServiceHandler class).
    * @Invoke       : Events from EMDRTriggerHandler class  after insert without Submission History.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void validateEMDRAckWithoutSubmissionHistoryTestMethod() {
        User aspenIntegrationUser = [SELECT Id FROM User WHERE Username LIKE 'aspenIntegrationTestEMDR@test.com%'];
        Test.startTest();
        // Get the Complaint Record
        System.runAs(aspenIntegrationUser) {
            // Get the Complaint Record
            CMPL123CME__Complaint__c complaint = [
                    SELECT Id
                    FROM CMPL123CME__Complaint__c
                    WHERE Name != 'cmpltest-00123'
                    LIMIT 1
            ];
            // Get Investigation
            CMPL123CME__Investigation__c investigation = [
                    SELECT ID
                    FROM CMPL123CME__Investigation__c
                    WHERE CMPL123_WF_Status__c = 'Opened' AND
                    CMPL123CME__Complaint__c = :complaint.Id
            ];
            // Get Assessment
            CMPL123CME__Questionnaire__c assessment = [
                    SELECT ID
                    FROM CMPL123CME__Questionnaire__c
                    WHERE CMPL123CME__Complaint__c = :complaint.Id
            ];

            //Create Country
            Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objCountry.Id), true);

            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            // Create Product ticket
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            // Create Registered Site
            CMPL123CME__Registered_Site__c registeredSite = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(CMPL123CME__G1_Contact_Office_Region_State__c = 'NA', Division__c = 'ADD'), true);

            // Create EMDR
            //Create EMDR  Medical_Evaluation__c = mdi.Id,
            Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
            CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
                    RecordTypeId = initialRTId, CMPL123CME__CMPL123_WF_Action__c = 'Open', Submission_Type__c = objCountrySubmissionType.Id, CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
                    Products__c = product.id, Product__c = prodTckt.id, CMPL123CME__Registered_Site__c = registeredSite.id), true);

            Map<String, CMPL123CME__Complaint_Code__c> cmpCodeNameToRecord =
                new Map<String, CMPL123CME__Complaint_Code__c>();
            for (CMPL123CME__Complaint_Code__c cmpCode : [
                SELECT Id, CMPL123CME__Type__c
                FROM CMPL123CME__Complaint_Code__c
                WHERE CMPL123CME__Type__c != :CODE_TYPE_STATE])
            {
                cmpCodeNameToRecord.put(cmpCode.CMPL123CME__Type__c, cmpCode);
            }

            // 23-FEB-2023 Larry: Succeeded in passing HL7 validations by adding
            // these H6 Problem Code junction records for the EMDR.
            List<CMPL123CME__MDR_Code__c> mdrCodeJuncList = new List<CMPL123CME__MDR_Code__c>();
            for (String codeType : AspenConstants.MDR_CODE_TYPES) {
                System.assertNotEquals(null, cmpCodeNameToRecord.get(codeType).Id);
                mdrCodeJuncList.add(
                    (CMPL123CME__MDR_Code__c) TestDataFactory.createSObject(
                    new CMPL123CME__MDR_Code__c(
                        CMPL123CME__Complaint_Code__c = cmpCodeNameToRecord.get(codeType).Id,
                        CMPL123CME__EMDR__c = emdr.Id,
                        // Note: Category is VITAL when validating the H6 codes. If you get an error like
                        // "H6 Medical Device Problem Code is a mandatory code", then maybe you forgot to set this.
                        CMPL123CME__Category__c = AspenConstants.MDR_CODE_CATEGORY_EVAL
                    ), false)
                );
            }
            insert mdrCodeJuncList;

            //Create emdr Integration
            EMDR_Integration__c emdrInteg1 = (EMDR_Integration__c) TestDataFactory.createSObject(new EMDR_Integration__c(Value__c = 'ACK1', name = 'EMDR_Acknowledgement1'), true);
            EMDR_Integration__c emdrInteg2 = (EMDR_Integration__c) TestDataFactory.createSObject(new EMDR_Integration__c(Value__c = 'ACK2', name = 'EMDR_Acknowledgement2'), true);
            EMDR_Integration__c emdrInteg3 = (EMDR_Integration__c) TestDataFactory.createSObject(new EMDR_Integration__c(Value__c = 'ACK3', name = 'EMDR_Acknowledgement3'), true);
            EMDR_Integration__c emdrInteg4 = (EMDR_Integration__c) TestDataFactory.createSObject(new EMDR_Integration__c(Value__c = 'EMDR_Not_Found', name = 'NOT_FOUND'), true);

            // Create Submission History for NOT_FOUND
            CMPL123CME__Submission_History__c notFoundSubmission = (CMPL123CME__Submission_History__c) TestDataFactory.createSObject(new CMPL123CME__Submission_History__c(
                    CMPL123CME__Stage__c = 'ACK1',
                    CMPL123CME__Related_EMDR__c = emdr.Id,
                    CMPL123CME__Message_Id__c = '&lt;AS2.17.BizLink&gt;'
            ), true);
            String ack1emdrId = EmdrAcknowledgementWebService.validateEMDRAcknowledgement('Ack1', '<AS2.17.BizLink>');
            System.assertEquals('NOT_FOUND', ack1emdrId);

            String ack2emdrId = EmdrAcknowledgementWebService.validateEMDRAcknowledgement('Ack2', '<AS2.17.BizLink>');
            System.assertEquals([SELECT Id FROM CMPL123CME__EMDR__c WHERE CMPL123CME__MDR_Submission__c = 'Submitted' LIMIT 1].Id, ack2emdrId);
        }
        Test.stopTest();
    }

}