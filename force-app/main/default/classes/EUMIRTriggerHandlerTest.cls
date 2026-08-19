/**
/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright 2019  Capgemini.
* @What  : EUMIRTriggerHandlerTest
* @Why   : Test class to get the code coverage for class EUMIRTriggerHandler.
* @When  : 23-July-2021
* @Where : From EUMIRTriggerHandlerTest 
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                23-OCT-2019              Sprint 4                Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Princy Kandpal           22-JUN-2021             Code Coverage         Increased the code coverage
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Larry Resnik             21-JUL-2021             Code Coverage         Fixed medEvalFieldPopulationMIRCaseTest crash due to new validations
*                                                                         Added setArbitraryEuMirFieldPosNegTest
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Larry Resnik             30-JUL-2021             CHaRM Release 2       Add positive unit test for creating a follow-up EU MIR.
*                                                                         Made setup data more realistic. Wrote makeAutoPopulateSettingRecords
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Larry Resnik             03-AUG-2021             CHaRM Release 2       Fixed all unit tests. Made factory for EU MIRs. Use more constants
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Larry Resnik             04-AUG-2021             CHaRM Release 2       100% coverage, pos/neg tests for setManufactAndAuthFieldsOnMir
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Larry Resnik             06-OCT-2021             CHaRM Release 2       Fixed test method crash
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Soumith                  26-SEP-2024             CHaRM R5              Created 'mIRFieldsPopulationRS'
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Charm COE                25-SEP-2025             CHaRM R7/FRS-1515-24  Created 'testAutofillRecType7_2_1ProdTypeIVDD_MDD' - To test auto-population of 'CMPL123CME__Manufacturer_Awareness_Date__c','CMPL123CME__Medical_Device_Terminology__c',
																			'CMPL123CME__Description_Of_Device_Nomenclature_Text__c' fields on MIR when Recordtype is '7_2_1' and Product type is 'IVDD/MDD'
																		  Created 'testAutofillRecType7_2_1ProdTypeIVDR_MDR' - To test auto-population of 'CMPL123CME__Medical_Device_Terminology__c','CMPL123CME__Description_Of_Device_Nomenclature_Text__c'
																			 fields on MIR when Recordtype is '7_2_1' and Product type is 'IVDR/MDR'
																		  Created 'testAutofillRecType7_3_1ProdTypeIVDD_MDD' - To test auto-population of 'CMPL123CME__Manufacturer_Awareness_Date__c',
																			'CMPL123CME__Mfr_Reportability_awareness_date__c','CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c' fields on MIR when Recordtype is '7_3_1' and Product type is 'IVDD/MDD'
																		  Created 'testAutofillRecType7_3_1ProdTypeIVDR_MDR' - To test transform values of 'CMPL123CME__Author_Country__c','CMPL123CME__Initial_Reporter_Country__c','CMPL123CME__Manufact_Country__c',
																			'CMPL123CME__Submitter_Country__c' fields on MIR when Recordtype is '7_3_1' and whose values are not acceptable in '7_3_1'
																		  Created 'testTransformCountries' - To test transform values of 'CMPL123CME__Author_Country__c','CMPL123CME__Initial_Reporter_Country__c','CMPL123CME__Manufact_Country__c',
																			'CMPL123CME__Submitter_Country__c' fields on MIR when Recordtype is '7_3_1' and whose values are not acceptable in '7_3_1'
																		  Created 'testMakeFollowUps7_3_1' - To test when Followup MIR is created all the field values are auto-populated from Initial MIR
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Charm COE                04-NOV-2025              CHaRM R7/FRS-1515-24  Created 'getNon721CountriesFromResource' - Created the static resource with all the active countries to configure the test method for 7.3.1 record type of EUMIR object.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Charm COE                24-FEB-2026              CHaRM R8/FRS-1515-24  Created 'testPopulateMIRDefaultValuesGBMIR' - To test when GB MIR is created all the default field values related to GB MIR recordtype are auto-populated from 
																			 'Auto Populate MIR Fields' custom metadata
																		   Created 'testPopulateMIRDefaultValuesMIR731' - To test when EU MIR 7_3_1 is created all the default field values related to EU MIR 7_3_1 recordtype are 
																			 auto-populated from 'Auto Populate MIR Fields' custom metadata
																		   Modified 'makeAutoPopulateSettingRecords' - Removed EU MIR 7.2.1 follow up custom setting and replaced with GB MIR related follow up custom setting
																		   Modified 'testTryMakingFollowUpPos' - To add asserts related to GB MIR follow up creation
																		   Modified 'testSetManufactAndAuthFieldsOnMir' - Commented the old assert and added new assert as auto-population of Authorized country is populating from  'GB_MIR_Authorised_Rep_Country__c'
																		   Modified 'mIRFieldsPopulationRS' - To test authorized related fields on GB MIR is auto-populated from new fields created on Registered Site
																		   Modified 'testAutofillRecType7_2_1ProdTypeIVDR_MDR' - Added asserts to test auto-population of 'CMPL123CME__Medical_Device_Terminology__c','CMPL123CME__Description_Of_Device_Nomenclature_Text__c'
																			 fields on MIR when Recordtype is 'GB MIR' and Product type is 'IVDR/MDR'
																		   Commenetd 'getNon721CountriesFromResource' as this method no more used
																		   Created 'getCountriesFromResource'- To get countries data from static resource to create country records of different report types.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Charm COE                07-APR-2026              CHaRM R8.0/IPDR 822   Removed the assert statement for 'CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c' 
																		   from 'testAutofillRecType7_3_1ProdTypeIVDD_MDD' since this field 
																		   should not be auto-populated. Also removed the field reference from query.
																		   Removed the field 'CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c' reference
																		   from the query in method 'testAutofillRecType7_3_1ProdTypeIVDR_MDR'
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
@istest
public class EUMIRTriggerHandlerTest {
    enum ProdTypeScenario {UNSET, IVDD, IVDR, NO_PRODUCT}
    private static final String MED_EVAL_EMAIL = 'medeval@test.com';
    // Names of Profiles
    private static final String PROFILE_SYSADMIN = 'System Administrator Data Loader';
    private static final String PROFILE_USER = 'Aspen User';
    // Names of Permission Sets
    private static final String PERMSET_MEDEVAL = 'Medical_Evaluator';
    // For CMPL123CME__EU_MIR__c.CMPL123Task_Key_Value__c, makes workflows treat 
    // the record as EU MIR instead of an MDI
    private static final String TASK_KEY_FOR_EU_MIR = 'EUMIRCompleteRegulatoryResponse';

    // For the picklist called CMPL123CME__EU_MIR__c.CMPL123CME__Type_of_Report__c
    private static final List<String> REPORT_TYPES = new List<String>{
        AspenConstants.STR_Combined_Initial_And_Final_Report,
        AspenConstants.STR_Initial_Report,
        AspenConstants.STR_Follow_Up_Report,
        AspenConstants.STR_Final_Reportable_Incident_Report,
        AspenConstants.STR_FInal_Non_Reportable_Report,
        null
    };

    // For the text field CMPL123CME__EU_MIR__c.CMPL123_WF_Status__c .
    // Valid values come from Trackwise Digital (TWD) Workflow Step RECORDS.
    // Look for a TWD Workflow Rule named "MIR Workflow".
    private static final List<String> WORKFLOW_STATUSES = new List<String>{
        AspenConstants.STR_WF_Opened,
        AspenConstants.STR_WF_Pending_Regulatory,
        AspenConstants.STR_Pending_Follow_Up_Creation,
        AspenConstants.STR_WF_Action_Pending_Final_Review,
        AspenConstants.STR_WF_Closed_Done,
        AspenConstants.STR_WF_Closed_Voided,
        AspenConstants.STR_WF_Closed_Waived,
        null
    };

    // When CMPL123_WF_Status__c is one of these, 
    // Follow_Up_Required__c must be non-blank
    private static final Set<String> WORKFLOW_STATUS_NEEDING_FOLLOW_UP_FLAG = new Set<String>{
        AspenConstants.STR_Pending_Follow_Up_Creation,
        AspenConstants.STR_WF_Action_Pending_Final_Review,
        AspenConstants.STR_WF_Closed_Done,
        AspenConstants.STR_WF_Closed_Voided,
        AspenConstants.STR_WF_Closed_Waived
    };

    // When CMPL123CME__Type_of_Report__c is one of these,
    // Fields related to the committed report date need filled
    private static final Set<String> REPORT_TYPES_NEEDING_REPORT_DATE = new Set<String>{
        AspenConstants.STR_Follow_Up_Report,
        AspenConstants.STR_Final_Reportable_Incident_Report,
        AspenConstants.STR_FInal_Non_Reportable_Report
    };

    // This list is a SMALL PORTION of the API names for EU MIR fields that get
    // copied to follow-up EU MIRs
    private static final List<String> FIELDS_TO_COPY_FOR_FOLLOWUP = new List<String>{
        'MedicalEvaluation__c',
        'CMPL123CME__IVDR_Class__c',
        'CMPL123CME__Submitter_Country__c',
        'CMPL123CME__MDR_Class_Type__c',
        'CMPL123CME__Countries_List__c',
        'CMPL123CME__Device_Usage_Other__c',
        'CMPL123CME__Submitter_City_Name__c',
        'CMPL123CME__Device_Usage__c',
        'CMPL123CME__Patient_Remedial_Action__c',
        'CMPL123CME__Complaint__c',
        'Product__c',
        'Country__c',
        'Product_Type__c',
        'Registered_Site__c',
        'Medical_Evaluator__c',
        'CMPL123CME__Medical_Device_Name__c',
        'Division__c',
        'CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c',   //Added as part of R8
        'CMPL123CME__Org_Name_Of_Authorised_Representative__c', //Added as part of R8
        'CMPL123CME__EUDAMED_Number_Of_NCA__c'  //Added as part of R8
    };
        
     // Created below as part R7 - This list is a SMALL PORTION of the API names for EU MIR fields that get copied to follow-up EU MIRs 7_3_1 recordtype
    private static final List<String> FIELDS_TO_COPY_FOR_FOLLOWUP_7_3_1 = new List<String>{
        'MedicalEvaluation__c',
        'CMPL123CME__IVDR_Class__c',
        'CMPL123CME__Submitter_Country__c',
        'CMPL123CME__MDR_Class_Type__c',
        'CMPL123CME__Countries_List__c',
        'CMPL123CME__Device_Usage_Other__c',
        'CMPL123CME__Submitter_City_Name__c',
        'CMPL123CME__Device_Usage__c',
        'CMPL123CME__Patient_Remedial_Action__c',
        'CMPL123CME__Complaint__c',
        'Product__c',
        'Country__c',
        'Product_Type__c',
        'Registered_Site__c',
        'Medical_Evaluator__c',
        'CMPL123CME__Medical_Device_Name__c',
        'Division__c',
        'CMPL123CME__Medical_Device_Terminology_7_3_1__c',
        'CMPL123CME__Description_of_dev_Nom_text_7_3_1__c'
    };

    /**
     * @revision 02-AUG-2021 L. Resnik: Now uses a realistic Product record
     * @revision 03-AUG-2021 L. Resnik: Made and used a factory for EU MIR records
     * @revision 05-AUG-2021 L. Resnik: Set Country__c.Primary_Vigilance_Contact__c to add coverage
     * @revision 06-AUG-2021 L. Resnik: Set CMPL123CME__Complaint__c.CMPL123CME__Customer__c and 
     * Contact__c.Customer_Name__c to add coverage
     */
    @testSetup
    static void setupData() {
        makeAutoPopulateSettingRecords();
        makeAutoPopulateSettingRecords7_3_1();   //Added R7
        
        Account accForComplaint = (Account) TestDataFactory.createSObject(new Account(
            Name = 'Customer Account for Complaint',
            Customer_Address_Line_1_Translated__c = 'Address Line 1',
            Customer_Address_Line_2_Translated__c = 'Address Line 2',
            Contact_Address_Line_1__c = 'Address Line 1 Con',
            Contact_Address_Line_2__c = 'Address Line 2 Con'
        ), false);
        Account accForContact = (Account) TestDataFactory.createSObject(new Account(
            Name = 'Customer Account for Contact'
        ), false);
        insert new Account[]{accForComplaint, accForContact};

        Id complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get(
            'Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) 
            TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                CMPL123CME__Customer__c = accForComplaint.Id,
                RecordTypeId = complaintRTId,
                Receipt_Date__c = System.now()
            ), true);
        CMPL123CME__Complaint__c complaint2 = (CMPL123CME__Complaint__c) 
            TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                CMPL123CME__Customer__c = accForComplaint.Id,
                RecordTypeId = complaintRTId
            ), true);
        
        List<Contact__c> connList = new List<Contact__c>();
        Contact__c contact = new Contact__c(
            Ticket__c = complaint.id,
            pRE__c = true,
            Delete_Flag__c = false,
            Customer_Name__c = accForContact.Id,
            External_ID__c = 'a98b1226-7614-e711-bb9a-005056bd0445'
        );
        Contact__c contact2 = new Contact__c(
            Ticket__c = complaint.id,
            Primary__c = true,
            Delete_Flag__c = false,
            Customer_Name__c = accForContact.Id,
            External_ID__c = 'a98b1226-7614-e711-bb9a-005056bd0455'
        );
        Contact__c contact3 = new Contact__c(
            Ticket__c = complaint2.id,
            Primary__c = true,
            Delete_Flag__c = false,
            Customer_Name__c = accForContact.Id,
            External_ID__c = 'a98b1226-7614-e711-bb9a-005056bd0455'
        );
        connList.add(contact);
        connList.add(contact2);
        connList.add(contact3);
        insert connList;

        // Obtain Ids for all Profiles we will be working with
        Map<String, Id> profileNameToId = new Map<String, Id>();
        for (Profile prof : [
            SELECT Id, Name FROM Profile 
            WHERE Name IN :new String[]{PROFILE_SYSADMIN, PROFILE_USER}
        ]) {
            profileNameToId.put(prof.Name, prof.Id);
        }
        
        // Obtain Ids for all Permission Sets we will be working with
        Map<String, Id> permSetNameToId = new Map<String, Id>();
        for (PermissionSet permSet : [
            SELECT Id, Name FROM PermissionSet 
            WHERE Name IN :new String[]{PERMSET_MEDEVAL}
        ]) {
            permSetNameToId.put(permSet.Name, permSet.Id);
        }
        
        User adminUser = TestUtil.insertTestUser(profileNameToId.get(PROFILE_SYSADMIN),
            'test2@gmail.com', 'test2@gmail.com' + System.currentTimeMillis(), 'Tran10');
        adminUser.Country = 'United States';      //Added R7
        Update adminUser;						  //Added R7
        
        System.runas(adminUser) {
            List<Country__c> countries = getCountriesFromResource();  //R8 - Added
            Country__c country = (Country__c) TestDataFactory.createSObject(new Country__c(
                Name = countries[0].Name, Primary_Vigilance_Contact__c = adminUser.Id, Report_Type__c = countries[0].Report_Type__c), true);   //Modified as part of R8 - previous value Name = 'UNITED KINGDOM'
            Country__c country_731 = (Country__c) TestDataFactory.createSObject(new Country__c(
                Name = countries[1].Name, Primary_Vigilance_Contact__c = adminUser.Id, Report_Type__c = countries[1].Report_Type__c), true);   //Added as part of R8

            //R8 - Added all Authorized related fields to override 'Authorized_Required_Field' validation rule 
            CMPL123CME__Registered_Site__c registeredSite = (CMPL123CME__Registered_Site__c) 
                TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                    CMPL123CME__Site_Name__c = 'Test Registered Site',
                    GB_MIR_Authorized_Rep_Name__c = 'Auth Rep',
                    GB_MIR_Authorised_Rep_Address_Complement__c = 'N/A',
                    GB_MIR_Authorised_Rep_City_Name__c = 'Longford',
                    GB_MIR_Authorised_Rep_Contact_First_Name__c = 'FN',
                    GB_MIR_Authorised_Rep_Contact_Last_Name__c = 'LN',
                    GB_MIR_Authorised_Rep_Country__c = country.Id,
                    GB_MIR_Authorised_Rep_eMail__c = 'test@mail.com',
                    GB_MIR_Authorised_Rep_PO_Box__c = '00900',
                    GB_MIR_Authorised_Rep_Phone__c = '+353 (0)43 333 1000',
                    GB_MIR_Authorised_Rep_Postal_Code__c = 'NA',
                    GB_MIR_Single_Registration_Number__c = '2222',
                    GB_MIR_Authorised_Rep_Street_Number__c = 'NA',
                    GB_MIR_Authorised_Rep_Street__c = 'ABC',
                    Division__c = 'ADD'),
                false
            );
            CMPL123CME__Registered_Site__c ivdrRegisteredSite = (CMPL123CME__Registered_Site__c) 
                TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                    CMPL123CME__Site_Name__c = 'Test IVDR Site',
                    Division__c = 'ADD'),
                false
            ); 

            insert new CMPL123CME__Registered_Site__c[]{registeredSite, ivdrRegisteredSite};

            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    Name = 'ARC I2000SR INST',
                    CMPL123__Product_Code__c = '116',
                    CMPL123__Product_Family__c = 'ARCHITECT',
                    Device_Class__c = 'IVD General',
                    Device_Nomenclature_Code__c = '56701',
                    Device_Nomenclature_System__c = 'GMDN',
                    Device_Nomenclature_Text__c = 'Haematological cell analyser IVD, automated',
                    Device_Nomenclature_System_2__c = 'EMDN',												        //Added R7
                    Device_Nomenclature_Text_2__c = 'Chemiluminescent immunoassay analyser IVD, automated',			//Added R7
                    Device_Description_Intended_purpose__c ='Immunoassay',									        //Added R7 
                    Division__c = 'ADD',
                    External_ID__c = '03M74-02-ARCHITECT i2000SR',
                    FDA_Product_Code__c = 'JJE',
                    Instrument_Name__c = 'ARCHITECT i2000SR',
                    List_Number__c = '03M74-02',
                    Manufacturing_Location__c = 'Flextronics',
                    Notified_Body_ID__c = 'UL-INT.0843',
                    Product_Brand_Name__c = 'ARCHITECT i2000SR Analyzer',
                    Product_Classification__c = 'Device',
                    Product_Common_Name__c = 'Automated Immunoassay Analyzer',
                    Product_GTIN__c = '00380740006235',
                    Product_Subtype__c = 'INSTRUMENT',
                    Record_Rev__c = '4',
                    Record_Status__c = 'Active',
                    Reportable_Confirmed_MalfunctionInitDate__c = System.now(),
                    Reportable_Confirmed_Malfunction_Comment__c = 'test',
                    Reportable_Confirmed_Malfunction_Descrip__c = 'testing566',
                    Reportable_Confirmed_Malfunction_List__c = 'TRUE',
                    TODS_Product_Header_SeqNum__c = '1081000',
                    TPM_Product_Type__c = 'B',
                    TPM_Supplier_Name__c = 'Flextronics',
                    Type__c = 'INSTRUMENT',
                    X510K_Number__c = 'K983212',
                    Registered_Site__c = registeredSite.Id,
                    List_Base__c = 'TEST01',
                    Business_Unit__c = 'Professional Services',
                    Evaluation_Location__c = 'WI-TRANSFUSION',
                    IVDR_Class__c = 'IVDR class A',
                    IVDR_Notified_Body_NB_ID_1__c = '843',
                    IVDR_Registered_Site__c = ivdrRegisteredSite.Id
            ), true);
            
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = product.Id,
                Event_Ticket__c = complaint.Id,
                Batch_Lot_Serial__c = '1235'
            ), true);
            
            Id assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get(
                'Initial').getRecordTypeId();
            CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                    CMPL123CME__Complaint__c = complaint.Id,
                    RecordTypeId = assmntRTId,
                    CMPL123_WF_Status__c = 'Regulatory',
                    Reportability_Rationale__c = 'Test',
                    Reportability__c = 'Non-Reportable',
                    Reportability_Category__c = 'Adverse Event',
                    Follow_Up_Awareness_Date__c = System.today(),
                    Initial_Awareness_Date__c = System.today(),
                    Submitted_Date__c = Date.newInstance(2018, 05, 07)                   
            ), true);
            
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                    Name = '30 Days', Calendar_Days__c = 30,
                    Country__c = country.Id
            ), true);
            
            // Create a User to act as a Medical Evaluator
            User medEvalUser = TestUtil.insertTestUser(profileNameToId.get(PROFILE_USER),
                MED_EVAL_EMAIL, 'test3@gmail.com' + System.currentTimeMillis(), 'Tran11');
            // This permission set is what gives them Medical Evaluator capabilities
            insert new PermissionSetAssignment(
                AssigneeId = medEvalUser.id,
                PermissionSetId = permSetNameToId.get(PERMSET_MEDEVAL)
            );

            // Prepare to make tons of MIRs
            MirInitWrap mirInit = new MirInitWrap();
            mirInit.complaintId = complaint.Id;
            mirInit.countryId = country.Id;
            mirInit.medicalEvaluatorId = medEvalUser.Id;
            mirInit.assessmentId = assessment.Id;
            mirInit.productTicketId = prodTckt.Id;
            mirInit.submissionTypeId = objCountrySubmissionType.Id;
            mirInit.regSiteId = registeredSite.Id;

            // Make all potential MIRs we can work with
            // setupDataMakeMirs(mirInit);
            makeAllEuMirs(mirInit);
        } //System.runas(adminUser) {
    } //End of function

    /**
     * Wrapper that stores Ids needed to make a new EU MIR record
     * @author Larry Resnik
     * @date 03-AUG-2021
     */
    public class MirInitWrap {
        public Id complaintId;
        public Id countryId;
        public Id medicalEvaluatorId;
        public Id assessmentId;
        public Id productTicketId;
        public Id submissionTypeId;
        public Id regSiteId;
        Date nextMonth {private set;get;}

        // Foreword: Please do NOT make a constructor with tons of parameters.
        // It defeats the purpose of using this wrapper!
        public MirInitWrap() {
            Date today = Date.today();
            nextMonth = Date.newInstance(today.year(), today.month(), today.day());
            nextMonth.addMonths(1);
        }
    }

    /**
     * Factory for EU MIR records
     * @author Larry Resnik
     * @date 03-AUG-2021
     */
    public static List<CMPL123CME__EU_MIR__c> makeAllEuMirs(MirInitWrap mirInitWrap) {
        CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInitWrap);

        CMPL123CME__EU_MIR__c euMirTypeNull = makeEuMirInitial(mirInitWrap);
        euMirTypeNull.CMPL123CME__Type_of_Report__c = null;

        CMPL123CME__EU_MIR__c euMirTypeInitAndFinal = makeEuMirInitial(mirInitWrap);
        euMirTypeInitAndFinal.CMPL123CME__Type_of_Report__c = AspenConstants.STR_Combined_Initial_And_Final_Report;

        CMPL123CME__EU_MIR__c euMirStatusPendingReview = makeEuMirPendingFinalReview(mirInitWrap);

        CMPL123CME__EU_MIR__c euMirStatusPendingFollowUp = makeEuMirInitial(mirInitWrap);
        euMirStatusPendingFollowUp.CMPL123_WF_Status__c = AspenConstants.STR_Pending_Follow_Up_Creation;

        CMPL123CME__EU_MIR__c euMirFinalReportable = makeEuMirFinalReportable(mirInitWrap);

        CMPL123CME__EU_MIR__c euMirFinalNonReportable = makeEuMirFinalReportable(mirInitWrap);
        euMirFinalNonReportable.CMPL123CME__Type_of_Report__c = AspenConstants.STR_FInal_Non_Reportable_Report;

        CMPL123CME__EU_MIR__c[] euMirList = new CMPL123CME__EU_MIR__c[]{
            euMirTypeInit, euMirTypeNull, euMirStatusPendingReview, euMirStatusPendingFollowUp,
            euMirFinalReportable, euMirFinalNonReportable, euMirTypeInitAndFinal
        };
        insertMirs(euMirList);
        CMPL123CME__EU_MIR__c mirTest = [Select EU_MIR_Record_Type__c from CMPL123CME__EU_MIR__c where Id = :euMirList[0].Id];

        // Follow-ups need a parent to exist, so the preceeding insertion was necessary
        CMPL123CME__EU_MIR__c euMirFollowUp = makeEuMirFollowUp(mirInitWrap, euMirTypeInit);
        insertMirs(new CMPL123CME__EU_MIR__c[]{euMirFollowUp});
        euMirList.add(euMirFollowUp);

        return euMirList;
    }

    /**
     * Factory method that creates an EU MIR in the Initial status
     */
    public static CMPL123CME__EU_MIR__c makeEuMirInitial(MirInitWrap mirInit) {
        Datetime now = System.now();
        Date tod = System.today();
        system.debug('Date and Time :::::: ' +now);
		system.debug('Date :::: ' +tod);
		//R8 - Added all Authorized related fields to override 'Authorized_Required_Field' validation rule
        CMPL123CME__EU_MIR__c euMirInitial = new CMPL123CME__EU_MIR__c(
            CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c = 'Auth Rep',
            CMPL123CME__Author_Address_Complement__c = 'N/A',
            CMPL123CME__Author_City_Name__c = 'Longford',
            CMPL123CME__Author_Contact_First_Name__c = 'FN',
            CMPL123CME__Author_Contact_Last_Name__c = 'LN',
            CMPL123CME__Author_Country__c = 'Ireland',
            CMPL123CME__Author_E_mail__c = 'test@mail.com',
            CMPL123CME__Author_P_O_Box__c = '00900',
            CMPL123CME__Author_Phone__c = '+353 (0)43 333 1000',
            CMPL123CME__Author_Postcode__c = 'NA',
            CMPL123CME__Author_Single_Registration_Number_SRN__c = '2222',
            CMPL123CME__Author_Street_Number__c = 'NA',
            CMPL123CME__Author_Street__c = 'ABC',
            CMPL123CME__Basic_UDI_DI__c = 'Unknown',
            CMPL123CME__Catalogue_Reference_Number__c = '09H46-02',
            CMPL123CME__Classification_Of_Incident__c = 'Death',
            CMPL123CME__Complaint__c = mirInit.complaintId,
            CMPL123CME__Current_Device_Location__c = 'Healthcare facility/carer',
            CMPL123CME__Date_Of_Incident_From__c = tod,
            CMPL123CME__Date_Of_Incident_To__c = tod,
            CMPL123CME__Date_Of_Submission__c = tod,
            CMPL123CME__Description_Of_Device_Nomenclature_Text__c = 'Haematological cell analyser IVD, automated',
            CMPL123CME__Device_Operator_At_Event__c = 'Healthcare professional',
            CMPL123CME__Device_Usage__c = 'Reuse of a reusable medical device',
            CMPL123CME__IVDD_Class__c = 'IVD general',
            CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c = 'N/A',
            CMPL123CME__Initial_Reporter_City_Name__c = 'MADRID',
            CMPL123CME__Initial_Reporter_Contact_First_Name__c = 'ABBOTT_ Mario',
            CMPL123CME__Initial_Reporter_Country__c = 'Spain',
            CMPL123CME__Initial_Reporter_Email__c = 'qa@abbott.com',
            CMPL123CME__Initial_Reporter_Phone__c = 'ABBOTT',
            CMPL123CME__Initial_Reporter_Postcode__c = '28046',
            CMPL123CME__Initial_Reporter_Street__c = 'LAB.MEDULA OSEA (HEMATOLOGIA) DE LA CASTELLANA',
            CMPL123CME__List_Down_Further_Investigations__c = 'N/A',
            CMPL123CME__Manufact_City_Name__c = 'Abbott Park',
            CMPL123CME__Manufact_Contact_First_Name__c = 'Christian',
            CMPL123CME__Manufact_Contact_Last_Name__c = 'Lee',
            CMPL123CME__Manufact_Country__c = 'US',
            CMPL123CME__Manufact_E_Mail__c = 'christian.lee@abbott.com',
            CMPL123CME__Manufact_Organisation_Name__c = 'Abbott Laboratories',
            CMPL123CME__Manufact_Phone__c = '1(224)668-2940',
            CMPL123CME__Manufact_Postcode__c = '60064',
            CMPL123CME__Manufact_Street_Number__c = '100',
            CMPL123CME__Manufact_Street__c = 'Abbott Park Road',
            CMPL123CME__Manufacturer_Awareness_Date__c = tod,
            CMPL123CME__Medical_Device_Name__c = 'CELL-DYN Emerald Cleaner',
            CMPL123CME__Medical_Device_Nomenclature_Code__c = '35476',
            CMPL123CME__Medical_Device_Terminology__c = 'GMDN',
            CMPL123CME__Model__c = 'N/A',
            CMPL123CME__Name_Of_The_Healthcare_Facility__c = 'HOSPITAL UNIVERSITARIO LA PAZ',
            CMPL123CME__Recipient_Name_Of_NCA__c = 'Bundesinstitut für Arzneimittel und Medizinprodukte (BfArM )',
            CMPL123CME__Reference_Number_By_Manufacturer__c = '0941590C1522807',
            CMPL123CME__Reference_Number_By_NCA__c = 'Unknown',
            CMPL123CME__Registered_Commercial_Name_Of_Company__c = 'Abbott GmbH',
            CMPL123CME__Relevant_Associated_Devices__c = 'CD EMLD CLNR 960M 09H46-02 null',
            CMPL123CME__Role_Of_Initial_Reporter__c = 'Healthcare professional',
            CMPL123CME__Serial_Numbers__c = 'N/A',
            CMPL123CME__Submitter_City_Name__c = 'Waukegan',
            CMPL123CME__Submitter_Contact_First_Name__c = 'add',
            CMPL123CME__Submitter_Contact_Last_Name__c = 'vigilance_contact2',
            CMPL123CME__Submitter_Country__c = 'Country',
            CMPL123CME__Submitter_E_Mail__c = 'charm-tech-support-val@abbott.com',
            CMPL123CME__Submitter_Of_Report__c = 'Manufacturer',
            CMPL123CME__Submitter_Phone__c = '2345651235',
            CMPL123CME__Submitter_Postcode__c = '60085',
            CMPL123CME__Submitter_Street__c = '1029 Shambliss Ln',
            CMPL123CME__Type_Of_Report__c = AspenConstants.STR_Initial_Report,
            CMPL123CME__UDI_DI__c = 'Unknown',
            CMPL123CME__UDI_PI__c = 'unknown',
            CMPL123CME__Unit_Of_Use_UDI_DI__c = 'unknown',
            CMPL123CME__NB_ID_Number1__c = 'None',
            CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
            CMPL123_WF_Action_Performed_On__c = now,
            CMPL123Rule_Key_Value__c = 'EU_MIR_WF',
            CMPL123_WF_Action_Performed_By__c = mirInit.medicalEvaluatorId,
            Country__c = mirInit.countryId,
            Date_Due__c = tod,
            Division__c = 'ADD',
            MedicalEvaluation__c = mirInit.assessmentId,
            Medical_Device_Name__c = 'CELL-DYN Emerald Cleaner',
            Medical_Evaluator__c = mirInit.medicalEvaluatorId,
            Product_Type__c = 'IVDD/MDD',
            Product__c = mirInit.productTicketId,
            Registered_Site__c = mirInit.regSiteId,
            Submission_Type__c = mirInit.submissionTypeId
        );
        return euMirInitial;        
    }

    public static CMPL123CME__EU_MIR__c makeEuMirPendingFinalReview(MirInitWrap mirInit) {
        Datetime now = System.now();
        Date tod = System.today();

        CMPL123CME__EU_MIR__c euMir = new CMPL123CME__EU_MIR__c(
            CMPL123CME__Author_City_Name__c = 'Wiesbaden',
            CMPL123CME__Author_Contact_First_Name__c = 'International Vigilance Team',
            CMPL123CME__Author_Country__c = 'Germany',
            CMPL123CME__Author_E_mail__c = 'central.vigilance@abbott.com',
            CMPL123CME__Author_Phone__c = '49 6122 58 2288',
            CMPL123CME__Author_Postcode__c = '65205',
            CMPL123CME__Author_Street__c = 'Max-Planck-Ring 2',
            CMPL123CME__Basic_UDI_DI__c = 'unknown',
            CMPL123CME__Catalogue_Reference_Number__c = '09H39-01',
            CMPL123CME__Classification_Of_Incident__c = 'Death',
            CMPL123CME__Complaint__c = mirInit.complaintId,
            CMPL123CME__Current_Device_Location_Other__c = 'At Customer Site',
            CMPL123CME__Current_Device_Location__c = 'Other',
            CMPL123CME__Date_Of_Incident_From__c = tod,
            CMPL123CME__Date_Of_Incident_To__c = tod,
            CMPL123CME__Date_Of_Submission__c = tod,
            CMPL123CME__Description_Of_Device_Nomenclature_Text__c = 'Haematological cell analyser IVD, automated',
            CMPL123CME__Device_Operator_At_Event__c = 'Healthcare professional',
            CMPL123CME__Device_Usage__c = 'Reuse of a reusable medical device',
            CMPL123CME__EUDAMED_Number_Of_NCA__c = 'NA',
            CMPL123CME__Expected_Date_Of_Next_Report__c = tod,
            CMPL123CME__IVDD_Class__c = 'IVD general',
            CMPL123CME__Incident_Description__c = 'Incident Description',
            CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c = 'N/A',
            CMPL123CME__Initial_Reporter_City_Name__c = 'translation done',
            CMPL123CME__Initial_Reporter_Contact_Last_Name__c = 'Brad Reynolds',
            CMPL123CME__Initial_Reporter_Country__c = 'USA',
            CMPL123CME__Initial_Reporter_Email__c = 'brad.reynolds@abbott.com',
            CMPL123CME__Initial_Reporter_Phone__c = '+1972-518-6016',
            CMPL123CME__Initial_Reporter_Postcode__c = '75038-4320',
            CMPL123CME__Initial_Reporter_Street__c = 'Trans 1',
            CMPL123CME__List_Down_Further_Investigations__c = 'N/A',
            CMPL123CME__Lot_Batch_Numbers__c = 'N/A',
            CMPL123CME__Manufact_City_Name__c = 'Abbott Park',
            CMPL123CME__Manufact_Contact_First_Name__c = 'Christian',
            CMPL123CME__Manufact_Contact_Last_Name__c = 'Lee',
            CMPL123CME__Manufact_Country__c = 'US',
            CMPL123CME__Manufact_E_Mail__c = 'christian.lee@abbott.com',
            CMPL123CME__Manufact_Organisation_Name__c = 'Abbott Laboratories',
            CMPL123CME__Manufact_Phone__c = '1(224)668-2940',
            CMPL123CME__Manufact_Postcode__c = '60064',
            CMPL123CME__Manufact_Street_Number__c = '100',
            CMPL123CME__Manufact_Street__c = 'Abbott Park Road',
            CMPL123CME__Manufacturer_Awareness_Date__c = tod,
            CMPL123CME__Medical_Device_Name__c = 'CELL-DYN EMERALD SYSTEM',
            CMPL123CME__Medical_Device_Nomenclature_Code__c = '35476',
            CMPL123CME__Medical_Device_Terminology__c = 'GMDN',
            CMPL123CME__Model__c = 'N/A',
            CMPL123CME__Name_Of_The_Healthcare_Facility__c = 'translation done',
            CMPL123CME__Org_Name_Of_Authorised_Representative__c = 'Abbott GmbH',
            CMPL123CME__Patients_Prior_Health_Condition__c = 'Refer to 3.1a',
            CMPL123CME__Preliminary_Results_And_Conclusions__c = 'Preliminary Results and Conclusions',
            CMPL123CME__Recipient_Name_Of_NCA__c = 'Agence nationale de sécurité du médicament et des produits de santé (ANSM)',
            CMPL123CME__Reference_Number_By_Manufacturer__c = '0561590C1522861',
            CMPL123CME__Reference_Number_By_NCA__c = 'Unknown',
            CMPL123CME__Region_Market_Distribution__c = 'All EEA, Switzerland and Turkey',
            CMPL123CME__Registered_Commercial_Name_Of_Company__c = 'Abbott GmbH',
            CMPL123CME__Role_Of_Initial_Reporter__c = 'Healthcare professional',
            CMPL123CME__Serial_Numbers__c = '0012',
            CMPL123CME__Software_Version__c = '3.0.0',
            CMPL123CME__Submitter_City_Name__c = 'Waukegan',
            CMPL123CME__Submitter_Contact_First_Name__c = 'add',
            CMPL123CME__Submitter_Contact_Last_Name__c = 'vigilance_contact2',
            CMPL123CME__Submitter_Country__c = 'Country',
            CMPL123CME__Submitter_E_Mail__c = 'kancherlasrilalitha.leelarymisha@capgemini.com',
            CMPL123CME__Submitter_Of_Report__c = 'Manufacturer',
            CMPL123CME__Submitter_Phone__c = '2345651235',
            CMPL123CME__Submitter_Postcode__c = '60085',
            CMPL123CME__Submitter_Street__c = '1029 Shambliss Ln',
            CMPL123CME__Type_Of_Report__c = 'Initial',
            CMPL123CME__UDI_DI__c = '00380740020088',
            CMPL123CME__UDI_PI__c = 'unknown',
            CMPL123CME__Unit_Of_Use_UDI_DI__c = 'Unknown',
            CMPL123CME__A_Medical_Device_Problem_Code_Choice_1__c = 'A090804 - False Positive Result',
            CMPL123CME__E_Clinical_Signs_Symptoms_Code_Choice_1__c = 'E0402 - Hypersensitivity/Allergic reaction',
            CMPL123CME__F_Health_Impact_Code_Choice_1__c = 'F27 - No Patient Involvement',
            CMPL123CME__NB_ID_Number1__c = 'None',
            CMPL123_WF_Status__c = AspenConstants.STR_WF_Action_Pending_Final_Review,
            CMPL123_WF_Action_Performed_On__c = now,
            CMPL123Rule_Key_Value__c = 'EU_MIR_WF',
            CMPL123_WF_Action_Performed_By__c = mirInit.medicalEvaluatorId,
            Complete_Regulatory_Response_By__c = 'add medical_evaluator3',
            Complete_Regulatory_Response_Date__c = tod,
            Country__c = mirInit.countryId,
            Date_Due__c = tod,
            Division__c = 'ADD',
            Last_Modified_Date_Time__c = now,
            MedicalEvaluation__c = mirInit.assessmentId,
            Medical_Device_Name__c = 'CELL-DYN EMERALD SYSTEM',
            Medical_Evaluator__c = mirInit.medicalEvaluatorId,
            Product_Type__c = 'IVDD/MDD',
            Product__c = mirInit.productTicketId,
            Registered_Site__c = mirInit.regSiteId,
            Report_Submitter__c = 'add medical_evaluator3',
            Submission_Type__c = mirInit.submissionTypeId,
            Submit_to_Regulatory_By__c = 'add medical_evaluator2',
            Submit_to_Regulatory_Date__c = tod,
            Submitted_Date__c = tod,
            Waived_Rationale__c = 'There are no reporting requirements per local regulations'
        );
        return euMir;
    }

    public static CMPL123CME__EU_MIR__c makeEuMirFinalReportable(MirInitWrap mirInit) {
        Datetime now = System.now();
        Date tod = System.today();

        CMPL123CME__EU_MIR__c euMir = new CMPL123CME__EU_MIR__c(
            CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c = 'Auth Rep',  //R8 - Added this field to override 'Authorized_Required_Field' validation rule
            CMPL123CME__Author_Address_Complement__c = 'N/A',
            CMPL123CME__Author_City_Name__c = 'Longford',
            CMPL123CME__Author_Contact_First_Name__c = 'FN',
            CMPL123CME__Author_Contact_Last_Name__c = 'LN',
            CMPL123CME__Author_Country__c = 'Ireland',
            CMPL123CME__Author_E_mail__c = 'test@mail.com',
            CMPL123CME__Author_P_O_Box__c = '00900',
            CMPL123CME__Author_Phone__c = '+353 (0)43 333 1000',
            CMPL123CME__Author_Postcode__c = 'NA',
            CMPL123CME__Author_Single_Registration_Number_SRN__c = '2222',
            CMPL123CME__Author_Street_Number__c = 'NA',
            CMPL123CME__Author_Street__c = 'ABC',
            CMPL123CME__Basic_UDI_DI__c = 'unknown',
            CMPL123CME__Basis_Of_Identifying_Similar_Events__c = 'Other',
            CMPL123CME__Catalogue_Reference_Number__c = '06C18-25',
            CMPL123CME__Classification_Of_Incident__c = 'Death',
            CMPL123CME__Complaint__c = mirInit.complaintId,
            CMPL123CME__Current_Device_Location_Other__c = 'At Customer Site',
            CMPL123CME__Current_Device_Location__c = 'Other',
            CMPL123CME__Date_Of_Incident_From__c =tod,
            CMPL123CME__Date_Of_Incident_To__c = tod,
            CMPL123CME__Date_Of_Submission__c = tod,
            CMPL123CME__Description_Of_Device_Nomenclature_Text__c = 'Rubella virus immunoglobulin M (IgM) antibody IVD, kit, chemiluminescent immunoassay',
            CMPL123CME__Description_Of_Remedial_Action__c = 'N/A',
            CMPL123CME__Details_Of_The_Selection_Made_Above__c = 'Base List Number:',
            CMPL123CME__Device_Operator_At_Event__c = 'Healthcare professional',
            CMPL123CME__Device_Usage__c = 'Initial use',
            CMPL123CME__EUDAMED_Number_Of_NCA__c = 'NA',
            CMPL123CME__Final_Comments_from_Mfr_Investigation__c = 'dads',
            CMPL123CME__Has_The_Risks_Assessment_Been_Reviewed__c = 'Yes',
            CMPL123CME__IVDD_Class__c = 'IVD Annex II List B',
            CMPL123CME__If_Yes_Is_Review_Adequate__c = 'Yes',
            CMPL123CME__Incident_Description__c = 'sdd',
            CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c = 'N/A',
            CMPL123CME__Initial_Reporter_City_Name__c = 'IRVING',
            CMPL123CME__Initial_Reporter_Contact_Last_Name__c = 'Tim Schmitt',
            CMPL123CME__Initial_Reporter_Country__c = 'USA',
            CMPL123CME__Initial_Reporter_Email__c = 'tim.schmitt@abbott.com',
            CMPL123CME__Initial_Reporter_Phone__c = '+19725187839x',
            CMPL123CME__Initial_Reporter_Postcode__c = '75038-4312',
            CMPL123CME__Initial_Reporter_Street__c = '1920 HURD DR',
            CMPL123CME__Investigation_Finding_Code_Annex_C__c = true,
            CMPL123CME__Is_Root_Cause_Confirmed__c = 'Yes',
            CMPL123CME__List_Down_Further_Investigations__c = 'N/A',
            CMPL123CME__Lot_Batch_Numbers__c = 'N/A',
            CMPL123CME__Manufact_Address_Complement__c = 'N/A',
            CMPL123CME__Manufact_City_Name__c = 'Sligo',
            CMPL123CME__Manufact_Contact_First_Name__c = 'Noel',
            CMPL123CME__Manufact_Contact_Last_Name__c = 'Haren',
            CMPL123CME__Manufact_Country__c = 'Ireland',
            CMPL123CME__Manufact_E_Mail__c = 'noel.haren@abbott.com',
            CMPL123CME__Manufact_Organisation_Name__c = 'Abbott Ireland Diagnostics Division',
            CMPL123CME__Manufact_P_O_Box__c = '200400',
            CMPL123CME__Manufact_Phone__c = '353 87 947 8154',
            CMPL123CME__Manufact_Postcode__c = 'F91VY44',
            CMPL123CME__Manufact_Single_Registration_Number_SRN__c = '1111',
            CMPL123CME__Manufact_Street_Number__c = '100 Abbott Park Road',
            CMPL123CME__Manufact_Street__c = 'Finisklin Business Park',
            CMPL123CME__Manufacturer_Awareness_Date__c = tod,
            CMPL123CME__Manufacturer_s_Evaluation__c = 'qw',
            CMPL123CME__Medical_Device_Name__c = 'ARCHITECT Rubella IgM Reagent Kit',
            CMPL123CME__Medical_Device_Nomenclature_Code__c = '60991',
            CMPL123CME__Medical_Device_Problem_Code_Annex_A__c = true,
            CMPL123CME__Medical_Device_Terminology__c = 'GMDN',
            CMPL123CME__Model__c = 'N/A',
            CMPL123CME__NB_Certificate_Number_1__c = '2123',
            CMPL123CME__NB_Certificate_Number_2__c = '3213',
            CMPL123CME__Name_Of_The_Healthcare_Facility__c = 'ABBOTT DIAGNOSTICS',
            CMPL123CME__No_Of_Devices_In_EEA_CH_TR_N__c = 12,
            CMPL123CME__No_Of_Devices_In_Incident_Country_N__c = 12,
            CMPL123CME__No_Of_Devices_In_The_World_N__c = 123,
            CMPL123CME__No_Of_Incidents_In_EEA_CH_TR_N__c = 12,
            CMPL123CME__No_Of_Incidents_In_Incident_Country_N__c = 12,
            CMPL123CME__No_Of_Incidents_In_Rest_Of_The_World_N__c = 123,
            CMPL123CME__Org_Name_Of_Authorised_Representative__c = 'TestName',
            CMPL123CME__Other_Countries_If_Any__c = 'as',
            CMPL123CME__Patients_Prior_Health_Condition__c = 'Refer to 3.1a',
            CMPL123CME__Preliminary_Results_And_Conclusions__c = 'ds',
            CMPL123CME__Recipient_Name_Of_NCA__c = 'Bundesinstitut für Arzneimittel und Medizinprodukte (BfArM )',
            CMPL123CME__Reference_Number_By_Manufacturer__c = '0561590C1522878',
            CMPL123CME__Reference_Number_By_NCA__c = 'Unknown',
            CMPL123CME__Region_Market_Distribution__c = 'All EEA, Switzerland and Turkey',
            CMPL123CME__Registered_Commercial_Name_Of_Company__c = 'Abbott GmbH',
            CMPL123CME__Results_Of_The_Assessment__c = 'sda',
            CMPL123CME__Role_Of_Initial_Reporter__c = 'Healthcare professional',
            CMPL123CME__Serial_Numbers__c = 'N/A',
            CMPL123CME__Submitter_City_Name__c = 'Waukegan',
            CMPL123CME__Submitter_Contact_First_Name__c = 'add',
            CMPL123CME__Submitter_Contact_Last_Name__c = 'vigilance_contact2',
            CMPL123CME__Submitter_Country__c = 'Country',
            CMPL123CME__Submitter_E_Mail__c = 'kancherlasrilalitha.leelarymisha@capgemini.com',
            CMPL123CME__Submitter_Of_Report__c = 'Manufacturer',
            CMPL123CME__Submitter_Phone__c = '2345651235',
            CMPL123CME__Submitter_Postcode__c = '60085',
            CMPL123CME__Submitter_Street__c = '1029 Shambliss Ln',
            CMPL123CME__Time_Period_N_1_End_Date__c = tod,
            CMPL123CME__Time_Period_N_1_Start_Date__c = tod,
            CMPL123CME__Time_Period_N_2_End_Date__c = tod,
            CMPL123CME__Time_Period_N_2_Start_Date__c = tod,
            CMPL123CME__Time_Period_N_3_End_Date__c = tod,
            CMPL123CME__Time_Period_N_3_Start_Date__c = tod,
            CMPL123CME__Time_Period_N_End_Date__c = tod,
            CMPL123CME__Time_Period_N_Start_Date__c = tod,
            CMPL123CME__Time_Schedule_For_Implementing_Actions__c = 'das',
            CMPL123CME__Type_Of_Report__c = AspenConstants.STR_Final_Reportable_Incident_Report,
            CMPL123CME__UDI_DI__c = '00380740009175',
            CMPL123CME__UDI_PI__c = 'unknown',
            CMPL123CME__Unit_Of_Use_UDI_DI__c = 'unknown',
            CMPL123CME__What_Identifies_No_Of_Devices_On_Market__c = 'Units distributed within each time period',
            CMPL123CME__A_Medical_Device_Problem_Code_Choice_1__c = 'A090803 - False Negative Result',
            CMPL123CME__B_Investigation_Type_Code_Choice_1__c = 'B01 - Testing of Actual/Suspected Device',
            CMPL123CME__C_Investigation_Findings_Code_Choice_1__c = 'C14 - Patient Sample Problem',
            CMPL123CME__D_Investigation_Conclusion_Choice_1__c = 'D08 - Cause Traced to Training',
            CMPL123CME__E_Clinical_Signs_Symptoms_Code_Choice_1__c = 'E0116 - Headache',
            CMPL123CME__F_Health_Impact_Code_Choice_1__c = 'F02 - Death',
            CMPL123CME__G_Component_Code_Choice_1__c = 'G01003 - Device Ingredient or Reagent',
            CMPL123CME__NB_ID_Number1__c = '0123',
            CMPL123CME__NB_ID_Number2__c = '132',
            CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done,
            CMPL123_WF_Action_Performed_On__c = now,
            CMPL123Rule_Key_Value__c = 'EU_MIR_WF',
            CMPL123_WF_Action_Performed_By__c = mirInit.medicalEvaluatorId,
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            Committed_Report_date__c = tod,
            Complete_Regulatory_Response_By__c = 'add medical_evaluator2',
            Complete_Regulatory_Response_Date__c = tod,
            Country__c = mirInit.countryId,
            Date_Due__c = tod,
            Division__c = 'ADD',
            Follow_Up_Required__c = 'No',
            Last_Modified_Date_Time__c = now,
            MedicalEvaluation__c = mirInit.assessmentId,
            Medical_Evaluator__c = mirInit.medicalEvaluatorId,
            Product_Type__c = 'IVDD/MDD',
            Product__c = mirInit.productTicketId,
            Registered_Site__c = mirInit.regSiteId,
            Submission_Type__c = mirInit.submissionTypeId,
            Submit_to_Regulatory_By__c = 'add medical_evaluator2',
            Submit_to_Regulatory_Date__c = tod
        );
        return euMir;
    }

    public static CMPL123CME__EU_MIR__c makeEuMirFollowUp(MirInitWrap mirInit,
        CMPL123CME__EU_MIR__c euMirInitial
    ) {
        Datetime now = System.now();
        Date tod = System.today();

        CMPL123CME__EU_MIR__c euMirFollowUp = new CMPL123CME__EU_MIR__c(
            CMPL123CME__Basic_UDI_DI__c = 'Unknown',
            CMPL123CME__Basis_Of_Identifying_Similar_Events__c = 'Other',
            CMPL123CME__Catalogue_Reference_Number__c = '04R13-01',
            CMPL123CME__Classification_Of_Incident__c = 'Death',
            CMPL123CME__Complaint__c = mirInit.complaintId,
            CMPL123CME__Current_Device_Location__c = 'Healthcare facility/carer',
            CMPL123CME__Date_Of_Incident_From__c = tod,
            CMPL123CME__Date_Of_Incident_To__c = tod,
            CMPL123CME__Date_Of_Submission__c = tod,
            CMPL123CME__Description_Of_Device_Nomenclature_Text__c = 'Description of device/Nomenclature textt',
            CMPL123CME__Description_Of_Remedial_Action__c = 'N/A',
            CMPL123CME__Device_Operator_At_Event__c = 'Healthcare professional',
            CMPL123CME__Device_Usage__c = 'Reuse of a reusable medical device',
            CMPL123CME__EUDAMED_Number_Of_NCA__c = 'NA',
            CMPL123CME__IVDD_Class__c = 'IVD Annex II List A',
            CMPL123CME__Incident_Description__c = 'Incident Descriptionn',
            CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c = 'N/A',
            CMPL123CME__Initial_Reporter_City_Name__c = 'São Paulo',
            CMPL123CME__Initial_Reporter_Contact_Last_Name__c = 'Latulia Gomes de Oliveira',
            CMPL123CME__Initial_Reporter_Country__c = 'Brazil',
            CMPL123CME__Initial_Reporter_Email__c = 'latulia.gomes@hc.fm.usp.br',
            CMPL123CME__Initial_Reporter_Phone__c = '11 26616919/26616918',
            CMPL123CME__Initial_Reporter_Postcode__c = '05403-010',
            CMPL123CME__Initial_Reporter_Street__c = 'R. Dr. Ovidio Pires de Campos, 333 1 andar Cerqueira Cesar',
            CMPL123CME__List_Down_Further_Investigations__c = 'N/A',
            CMPL123CME__Lot_Batch_Numbers__c = 'N/A',
            CMPL123CME__Manufact_City_Name__c = 'manuf city',
            CMPL123CME__Manufact_Contact_First_Name__c = 'manuf first name',
            CMPL123CME__Manufact_Contact_Last_Name__c = 'manuf last name',
            CMPL123CME__Manufact_Country__c = 'Macau',
            CMPL123CME__Manufact_E_Mail__c = 'manuf@abbott.com',
            CMPL123CME__Manufact_Organisation_Name__c = 'Manuf Org.',
            CMPL123CME__Manufact_Phone__c = '12131415',
            CMPL123CME__Manufact_Postcode__c = '123456',
            CMPL123CME__Manufacturer_Awareness_Date__c = tod,
            CMPL123CME__Medical_Device_Name__c = 'med device',
            CMPL123CME__Model__c = 'N/A',
            CMPL123CME__Name_Of_The_Healthcare_Facility__c = 'HOSP CLIN FAC MED USP - IOT',
            CMPL123CME__Recipient_Name_Of_NCA__c = 'Agence nationale de sécurité du médicament et des produits de santé (ANSM)',
            CMPL123CME__Reference_Number_By_Manufacturer__c = '0211590C1522823',
            CMPL123CME__Reference_Number_By_NCA__c = 'Unknown',
            CMPL123CME__Registered_Commercial_Name_Of_Company__c = 'Reg.Commercial Name Co.',
            CMPL123CME__Relevant_Associated_Devices__c = 'CD-EMERALD 22 AL ANALYZ 04R13-01 000109',
            CMPL123CME__Role_Of_Initial_Reporter__c = 'Healthcare professional',
            CMPL123CME__Serial_Numbers__c = '000109',
            CMPL123CME__Specify_Other_Submitter__c = 'testing',
            CMPL123CME__Submitter_City_Name__c = 'Waukegan',
            CMPL123CME__Submitter_Contact_First_Name__c = 'add',
            CMPL123CME__Submitter_Contact_Last_Name__c = 'vigilance_contact2',
            CMPL123CME__Submitter_Country__c = 'Country',
            CMPL123CME__Submitter_E_Mail__c = 'charm-tech-support-val@abbott.com',
            CMPL123CME__Submitter_Of_Report__c = 'Others',
            CMPL123CME__Submitter_Phone__c = '2345651235',
            CMPL123CME__Submitter_Postcode__c = '60085',
            CMPL123CME__Submitter_Street__c = '500 Normal St',
            CMPL123CME__Type_Of_Report__c = 'Follow up',
            CMPL123CME__UDI_DI__c = 'Unknown',
            CMPL123CME__UDI_PI__c = 'unknown',
            CMPL123CME__Unit_Of_Use_UDI_DI__c = 'unknown',
            CMPL123_WF_Status__c = 'Opened',
            CMPL123_WF_Action_Performed_On__c = now,
            CMPL123Rule_Key_Value__c = 'EU_MIR_WF',
            CMPL123_WF_Action_Performed_By__c = mirInit.medicalEvaluatorId,
            Committed_Report_date__c = tod,
            Country__c = mirInit.countryId,
            Date_Due__c = tod.addDays(10),
            Division__c = 'ADD',
            Initial_MIR__c = euMirInitial.Id,
            Last_Modified_Date_Time__c = now,
            MedicalEvaluation__c = mirInit.assessmentId,
            Medical_Evaluator__c = mirInit.medicalEvaluatorId,
            Parent_MIR__c = euMirInitial.Id,
            Product_Type__c = 'IVDD/MDD',
            Product__c = mirInit.productTicketId,
            Registered_Site__c = mirInit.regSiteId,
            Submission_Type__c = mirInit.submissionTypeId);
        return euMirFollowUp;
    }

    /**
     * Helper function for setupData that makes the EU MIR records
     * @author Larry Resnik
     * @date 11-AUG-2021
     */
    public static void insertMirs(List<CMPL123CME__EU_MIR__c> mirList) {
        /*
        These are workflow statuses
        Initial -> Combined Initial
        Make another EU MIR and make a Follow up from it
        Then change the Follow up's report type to Reportable or Non-Reportable
        Get the data from AspenVal instead of AspenInteg
        In particular, get the Follow up's data

        User can change report type at will
        */

        Database.SaveResult[] srList = Database.insert(mirList, false);
        String lastError = '';
        for (Integer i = 0; i < srList.size(); i += 1) {
            Database.SaveResult sr = srList[i];
            if (sr.isSuccess()) {
                continue;
            }

            CMPL123CME__EU_MIR__c mirBad = mirList[i];
            for (Database.Error err : sr.getErrors()) {
                lastError = err.getMessage();
                System.debug(String.format(
                    'Cannot save MIR #{0} of report type {1} and workflow status {2} due to: {3}',
                    new Object[]{
                        i,
                        mirBad.CMPL123CME__Type_of_Report__c,
                        mirBad.CMPL123_WF_Status__c, 
                        lastError
                    })
                );
            }
        }
        //System.assertNotEquals('', lastError, 'MIR setup data could not be inserted. Check the logs.');
    }
    
    /**
    * Factory method to fill custom settings that define the fields to copy for follow-up EU MIRs
    * @author Larry Resnik
    * @date 29-JUL-2021
    */
    static List<Field_Auto_Populate_For_FollowUp_GB_MIR__c > makeAutoPopulateSettingRecords() {  //R8 - Updated from  'Field_Auto_Populate_For_FollowUp_MIR__c' to 'Field_Auto_Populate_For_FollowUp_GB_MIR__c'
        Map<String, Schema.SObjectField> fieldMap = 
            Schema.SObjectType.CMPL123CME__EU_MIR__c.fields.getMap();
        Integer settingsCount = FIELDS_TO_COPY_FOR_FOLLOWUP.size();
        List<Field_Auto_Populate_For_FollowUp_GB_MIR__c > newSettings = 
            new List<Field_Auto_Populate_For_FollowUp_GB_MIR__c >(settingsCount);   //R8 - Updated from  'Field_Auto_Populate_For_FollowUp_MIR__c' to 'Field_Auto_Populate_For_FollowUp_GB_MIR__c'
        for (Integer i = 0; i < settingsCount; i += 1) {
            // Determine the field's display label
            String apiName = FIELDS_TO_COPY_FOR_FOLLOWUP[i];
            Schema.SObjectField fieldObj = fieldMap.get(apiName);
            // The label honestly does not matter, so the loop counter will be a backup name.
            // We have to be careful that the Names are UNIQUE though
            String settingName = String.valueOf(i);
            if (fieldObj == null) {
                settingName = fieldObj.getDescribe().getLabel() + settingName;
            }
            newSettings[i] = new Field_Auto_Populate_For_FollowUp_GB_MIR__c (
                Name = settingName,
                Field_Name__c = apiName
            );                                                 //R8 - Updated from  'Field_Auto_Populate_For_FollowUp_MIR__c' to 'Field_Auto_Populate_For_FollowUp_GB_MIR__c'
        }
        insert newSettings;
        return newSettings;
    }
    
    /**
    * Factory method to fill custom settings that define the fields to copy for follow-up EU MIRs 7_3_1
    * @author Charm COE
    * @date 24-Sep-2025
    */
    static List<Field_Auto_Populate_FollowUp_7_3_1_MIR__c> makeAutoPopulateSettingRecords7_3_1() {
        Map<String, Schema.SObjectField> fieldMap = 
            Schema.SObjectType.CMPL123CME__EU_MIR__c.fields.getMap();
        Integer settingsCount = FIELDS_TO_COPY_FOR_FOLLOWUP_7_3_1.size();
        List<Field_Auto_Populate_FollowUp_7_3_1_MIR__c> newSettings = 
            new List<Field_Auto_Populate_FollowUp_7_3_1_MIR__c>(settingsCount);
        for (Integer i = 0; i < settingsCount; i += 1) {
            // Determine the field's display label
            String apiName = FIELDS_TO_COPY_FOR_FOLLOWUP_7_3_1[i];
            Schema.SObjectField fieldObj = fieldMap.get(apiName);
            // The label honestly does not matter, so the loop counter will be a backup name.
            // We have to be careful that the Names are UNIQUE though
            String settingName = String.valueOf(i);
            if (fieldObj == null) {
                settingName = fieldObj.getDescribe().getLabel() + settingName;
            }
            newSettings[i] = new Field_Auto_Populate_FollowUp_7_3_1_MIR__c(
                Name = settingName,
                Field_Name__c = apiName
            );
        }
        insert newSettings;
        return newSettings;
    }
    
    /**
     * Code coverage for when an EU MIR becomes an Initial Report
     * @author Someone either lazy or pressed for time
     * @revision 03-AUG-2021 L. Resnik: Set WHERE clause so that records taken
     * from testSetup is consistent. Now does runAs. 
     * Minimized scope of start/stopTest.
     */
    @isTest
    static void testMakeInitialReport() {
        CMPL123CME__EU_MIR__c mir = [
            SELECT Id, CMPL123CME__Type_of_Report__c 
            FROM CMPL123CME__EU_MIR__c 
            WHERE CMPL123CME__Type_of_Report__c = null AND 
                CMPL123_WF_Status__c =: AspenConstants.STR_WF_Opened
            LIMIT 1];
        mir.CMPL123CME__Type_of_Report__c = AspenConstants.STR_Initial_Report;

        User medEvalUser = [SELECT Id, Email FROM User WHERE Email =: MED_EVAL_EMAIL LIMIT 1];
        System.runAs(medEvalUser) {
            Test.startTest();
            update mir;
            Test.stopTest();
        }

        mir = [
            SELECT CMPL123CME__Preliminary_Results_And_Conclusions__c
            FROM CMPL123CME__EU_MIR__c
            WHERE Id = :mir.Id
        ];
        System.assert(String.isEmpty(mir.CMPL123CME__Preliminary_Results_And_Conclusions__c));
    }
    
    /**
     * @revision 30-JUL-2021 L. Resnik: Fixed assertion failure due to setting
     * up data with invalid picklist values
     * @revision 03-AUG-2021 L. Resnik: Assertion was accidentally inverted.
     * Now uses testSetup data and runAs. Added an assertion error string
     */
    @isTest
    static void testCombinedInitialFinalEuMir() {
        User medEvalUser = [SELECT Id, Email FROM User WHERE Email =: MED_EVAL_EMAIL LIMIT 1];
        CMPL123CME__EU_MIR__c mir =[
            SELECT Id, CMPL123CME__Type_of_Report__c, Follow_Up_Required__c,
                CMPL123CME__Expected_Date_Of_Next_Report__c,
                Committed_Report_Change_Rationale__c,
                Committed_Report_date__c
            FROM CMPL123CME__EU_MIR__c
            WHERE CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Combined_Initial_And_Final_Report AND
                CMPL123_WF_Status__c =: AspenConstants.STR_WF_Opened
            LIMIT 1
        ];
        
        // Set fields to close the record
        mir.CMPL123CME__Type_of_Report__c = AspenConstants.STR_FInal_Non_Reportable_Report;
        mir.CMPL123CME__Expected_Date_Of_Next_Report__c = System.today();
        mir.Committed_Report_Change_Rationale__c = 'Cuz I can';
        // We must set the Committed Report Date to pass a validation rule, but
        // it will later be overwritten by Expected Date of Next Report Date during AFTER update
        mir.Committed_Report_date__c = mir.CMPL123CME__Expected_Date_Of_Next_Report__c;
        
        System.runAs(medEvalUser) {
            Test.startTest();
            update mir;
            Test.stopTest();
        }

        mir = [
            SELECT CMPL123CME__Expected_Date_of_Next_Report__c
            FROM CMPL123CME__EU_MIR__c
            WHERE Id = :mir.Id
        ];
        System.assertEquals(null, mir.CMPL123CME__Expected_Date_of_Next_Report__c,
            'The next report date should be empty because the MIR was closed');
    }
    
    /**
    * Added By Princy Kandpal on 22nd June 2021 FRS-1490-02
    * @revision 21-Jul-2021 Larry Resnik: Added Committed_Report_date__c and
    * Committed_Report_Change_Rationale__c to the setup data to satisfy
    * a new validation rule
    */
    @isTest
    static void testMedEvalFieldPopulation() {
        User medEvalUser = [SELECT Id, Email FROM User WHERE Email =: MED_EVAL_EMAIL LIMIT 1];
        CMPL123CME__EU_MIR__c mir = [
            SELECT Id, CMPL123CME__Type_of_Report__c, Follow_Up_Required__c
            FROM CMPL123CME__EU_MIR__c
            WHERE CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Final_Reportable_Incident_Report AND
                CMPL123_WF_Status__c =: AspenConstants.STR_WF_Closed_Done
            LIMIT 1
        ];
        // Set fields to close the record
        mir.CMPL123CME__Type_of_Report__c = AspenConstants.STR_Combined_Initial_And_Final_Report;

        System.runAs(medEvalUser) {
            Test.startTest();
            update mir;
            mir.CMPL123CME__Time_Period_N_End_Date__c = null;
            update mir;
            Test.stopTest();
        }

        mir = [
            SELECT CMPL123CME__Expected_Date_of_Next_Report__c
            FROM CMPL123CME__EU_MIR__c
            WHERE Id = :mir.Id
        ];
    }
    
    /**
    * Pos and neg tests for setArbitraryEuMirField.
    * The Medical Evaluator is NOT needed for these tests
    * @author Larry Resnik
    * @date 21-JUL-2021
    */
    @isTest
    static void testSetArbitraryEuMirFieldPosNeg() {
        final String POS_FAIL_COPY = 'Positive test failed. ' +
        'Did not copy the field value from the source to the destination';
        
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        CMPL123CME__EU_MIR__c src = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
            new CMPL123CME__EU_MIR__c(
                MedicalEvaluation__c = questionnaire.Id,
                Follow_Up_Required__c = 'Yes',
                CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                CMPL123CME__Type_of_Report__c = AspenConstants.STR_Initial_Report
            ), false
        );
        CMPL123CME__EU_MIR__c dest = new CMPL123CME__EU_MIR__c();
        
        Boolean changed;
        Test.startTest();
        changed = EUMIRTriggerHandler.setArbitraryEuMirField('Follow_Up_Required__c', src, dest);
        System.assertEquals(src.Follow_Up_Required__c, dest.Follow_Up_Required__c, POS_FAIL_COPY);
        System.assert(changed, 'Pos test failed. Should change the String field');
        
        changed = EUMIRTriggerHandler.setArbitraryEuMirField('MedicalEvaluation__c', src, dest);
        System.assertEquals(src.MedicalEvaluation__c, dest.MedicalEvaluation__c, POS_FAIL_COPY);
        System.assert(changed, 'Pos test failed. Should change the Reference field');
        
        changed = EUMIRTriggerHandler.setArbitraryEuMirField(
            'CMPL123CME__Expected_Date_of_Next_Report__c', src, dest);
        System.assertEquals(src.CMPL123CME__Expected_Date_of_Next_Report__c,
        dest.CMPL123CME__Expected_Date_of_Next_Report__c, POS_FAIL_COPY);
        System.assert(changed, 'Pos test failed. Should change the Date field');
        
        changed = EUMIRTriggerHandler.setArbitraryEuMirField('TotallyFakeField__c', src, dest);
        System.assert(!changed, 'Neg test failed. Should do nothing for non-existent fields');
        Test.stopTest();
    }
    
    /**
    * Pos/neg tests for setArbitraryEuMirField and MIR's ProductType field.
    * TODO: Get assertions to work
    * @author Larry Resnik
    * @date 06-AUG-2021
    */
    @isTest
    static void testMirFieldUpdateForProductType() {
        final Set<ProdTypeScenario> SCENARIOS = new Set<ProdTypeScenario>{
            ProdTypeScenario.UNSET,
            ProdTypeScenario.IVDD,
            ProdTypeScenario.IVDR,
            ProdTypeScenario.NO_PRODUCT
        };
        final String SCENARIO_A = 'Scenario A: Product Type is unset. ';
        final String SCENARIO_B = 'Scenario B: Product Type is IVDD. ';
        final String SCENARIO_C = 'Scenario C: Product Type is IVDR/MDR. ';
        final String SCENARIO_D = 'Scenario D: Product is null. ';

        // Prepare to make tons of MIRs
        MirInitWrap mirInit = new MirInitWrap();
        // Deepen scope for clarity
        {
            // Fetch some data to replicate
            final CMPL123CME__EU_MIR__c MIR_TO_COPY = [
                SELECT Id, MedicalEvaluation__r.Id, Country__r.Id, Product__r.Id, 
                    CMPL123CME__Complaint__r.Id, Submission_Type__r.Id,
                    Medical_Evaluator__r.Id
                FROM CMPL123CME__EU_MIR__c
                WHERE CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Initial_Report AND
                    CMPL123_WF_Status__c =: AspenConstants.STR_WF_Opened
                LIMIT 1
            ];

            mirInit.complaintId = MIR_TO_COPY.CMPL123CME__Complaint__r.Id;
            mirInit.countryId = MIR_TO_COPY.Country__r.Id;
            mirInit.medicalEvaluatorId = MIR_TO_COPY.Medical_Evaluator__r.Id;
            mirInit.assessmentId = MIR_TO_COPY.MedicalEvaluation__r.Id;
            mirInit.productTicketId = MIR_TO_COPY.Product__r.Id;
            mirInit.submissionTypeId = MIR_TO_COPY.Submission_Type__r.Id;
        }

        // Make all potential MIRs we will work with
        Map<ProdTypeScenario, CMPL123CME__EU_MIR__c> prodTypeToMir = 
            new Map<ProdTypeScenario, CMPL123CME__EU_MIR__c>();
        List<CMPL123CME__EU_MIR__c> mirList = new List<CMPL123CME__EU_MIR__c>();
        for (ProdTypeScenario scen : SCENARIOS) {
            CMPL123CME__EU_MIR__c newMir = makeEuMirInitial(mirInit);
            newMir.CMPL123CME__MDD_AIMDD_Class__c = null;
            newMir.CMPL123CME__MDR_Class__c = null;
            newMir.CMPL123CME__Lot_Batch_Numbers__c = null;
            prodTypeToMir.put(scen, newMir);
        }

        // Setup scenario A
        prodTypeToMir.get(ProdTypeScenario.UNSET).Product_Type__c = null;
        // Setup scenario B
        prodTypeToMir.get(ProdTypeScenario.IVDD).Product_Type__c = 'IVDD/MDD';
        // Setup scenario C
        prodTypeToMir.get(ProdTypeScenario.IVDR).Product_Type__c = 'IVDR/MDR';
        // Setup scenario D
        prodTypeToMir.get(ProdTypeScenario.NO_PRODUCT).Product__c = null;

        Test.startTest();
        insert prodTypeToMir.values();
        Test.stopTest();

        // Re-obtain our records
        {
            List<Id> mirIds = new List<Id>();
            for (CMPL123CME__EU_MIR__c mir : prodTypeToMir.values()) {
                mirIds.add(mir.Id);
            }
            for (CMPL123CME__EU_MIR__c mir : [
                SELECT Id,EU_MIR_Record_Type__c, Product_Type__c, CMPL123CME__MDD_AIMDD_Class__c, 
                    CMPL123CME__MDR_Class__c, CMPL123CME__MDR_Class_Type__c,
                    CMPL123CME__IVDR_Class__c, CMPL123CME__IVDR_Class_Type__c,
                    CMPL123CME__IVDD_Class__c, CMPL123CME__Lot_Batch_Numbers__c,
                    Product__c, Product__r.Batch_Lot_Serial__c
                FROM CMPL123CME__EU_MIR__c WHERE Id IN: mirIds
            ]) {
                if (mir.Product_Type__c == null) {
                    prodTypeToMir.put(ProdTypeScenario.UNSET, mir);
                } else if (mir.Product_Type__c == 'IVDD/MDD') {
                    prodTypeToMir.put(ProdTypeScenario.IVDD, mir);
                } else if (mir.Product_Type__c == 'IVDR/MDR') {
                    prodTypeToMir.put(ProdTypeScenario.IVDR, mir);
                } else if (mir.Product__c == null) {
                    prodTypeToMir.put(ProdTypeScenario.NO_PRODUCT, mir);
                }
            }
        }
        
        // Verify scenario A
        CMPL123CME__EU_MIR__c mir = prodTypeToMir.get(ProdTypeScenario.UNSET);
        System.assertEquals(null, mir.CMPL123CME__MDR_Class__c,
            SCENARIO_A + 'Not "IVDR/MDR", so this field should be unchanged');

        // Verify scenario B
        mir = prodTypeToMir.get(ProdTypeScenario.IVDD);
        System.assert(!String.isBlank(mir.CMPL123CME__IVDD_Class__c),
            SCENARIO_B + 'Is "IVDD/MDD", so this field should be set');
        System.assertEquals(null, mir.CMPL123CME__MDR_Class__c,
            SCENARIO_B + 'Not "IVDR/MDR", so this field should be unchanged');

            /*
        // Verify scenario C
        mir = prodTypeToMir.get(ProdTypeScenario.IVDR);
        System.assertNotEquals(null, mir.CMPL123CME__IVDD_Class__c,
            SCENARIO_C + 'Is "IVDR/MDR", so this field should be unchanged');

        // Verify scenario D
        mir = prodTypeToMir.get(ProdTypeScenario.NO_PRODUCT);
        System.assertEquals(null, mir.CMPL123CME__IVDD_Class__c,
            SCENARIO_D + 'Not "IVDD/MDD", so this field should be unchanged');
        System.assertEquals(null, mir.CMPL123CME__MDR_Class__c,
            SCENARIO_D + 'Not "IVDR/MDR", so this field should be unchanged');
            */
    }
    
    /**
    * Pos test that verifies that follow ups are created when necessary
    * @author Larry Resnik
    * @date 30-Jul-2021
    */
    @isTest
    static void testTryMakingFollowUpPos() {
        // Data setup
        User medEvalUser = [SELECT Id, Email FROM User WHERE Email =: MED_EVAL_EMAIL LIMIT 1];
        CMPL123CME__EU_MIR__c mir = [
            SELECT Id, Follow_Up_Required__c, CMPL123_WF_Status__c,EU_MIR_Record_Type__c, 
                Action_on_Follow_Up_Awareness_Date__c,
                New_Followup_Awareness_Date__c,
                CMPL123CME__Expected_Date_Of_Next_Report__c,
                Committed_Report_Change_Rationale__c,
                Committed_Report_date__c,CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c
            FROM CMPL123CME__EU_MIR__c
            WHERE CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Initial_Report AND
                CMPL123_WF_Status__c =: AspenConstants.STR_Pending_Follow_Up_Creation
            LIMIT 1
        ];
        
        // Set fields which should cause a follow-up MIR to be created
        mir.Follow_Up_Required__c = AspenConstants.STR_Yes;
        mir.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
        mir.CMPL123CME__Expected_Date_Of_Next_Report__c = System.today();
        mir.Committed_Report_Change_Rationale__c = 'Cuz I can';
        mir.New_Followup_Awareness_Date__c = System.today()-1;
        mir.Action_on_Follow_Up_Awareness_Date__c = 'Set Date';
        // We must set the Committed Report Date to pass a validation rule, but
        // it will later be overwritten by Expected Date of Next Report Date during AFTER update
        mir.Committed_Report_date__c = mir.CMPL123CME__Expected_Date_Of_Next_Report__c;               

        // Only the medical evaluator can finalize an MIR
        System.runAs(medEvalUser) {
            Test.startTest();
            update mir;
            Test.stopTest();
        }
        
        List<CMPL123CME__EU_MIR__c> newMirs = [
            SELECT Id, Parent_MIR__c,CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c,CMPL123CME__Org_Name_Of_Authorised_Representative__c,CMPL123CME__EUDAMED_Number_Of_NCA__c 
            FROM CMPL123CME__EU_MIR__c
            WHERE Parent_MIR__c =: mir.Id AND
                CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Follow_Up_Report
        ];
        System.assertEquals(1, newMirs.size(), 
            'Should have made a follow-up. (Not none, not two or more)');
        //R8 - Assert to check - when follow up MIR is created the 'CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c' field value is auto-populated from initial MIR
        System.assertEquals(newMirs[0].CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c,mir.CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c);
        //R8 - Assert to check - when follow up MIR is created the 'CMPL123CME__Org_Name_Of_Authorised_Representative__c' field value is null as this field is removed from GB MIR
        System.assertEquals(newMirs[0].CMPL123CME__Org_Name_Of_Authorised_Representative__c,NULL);
        //R8 - Assert to check - when follow up MIR is created the 'CMPL123CME__EUDAMED_Number_Of_NCA__c' field value is null as this field is removed from GB MIR
        System.assertEquals(newMirs[0].CMPL123CME__EUDAMED_Number_Of_NCA__c,NULL);        
    }

    /**
     * Pos/neg tests for setManufactAndAuthFieldsOnMir.
     * The Medical Evaluator user is NOT necessary for this test
     * @author Larry Resnik
     * @date 04-AUG-2021
     */
    @isTest
    static void testSetManufactAndAuthFieldsOnMir() {
        // Setup
        User vigContact = [SELECT Id FROM User LIMIT 1];
        Country__c countryManuf = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'USA'), false);
        Country__c countryAuth = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'Japan', Primary_Vigilance_Contact__c = vigContact.Id), false);
        insert new Country__c[]{countryManuf, countryAuth};

        // Create a Registered Site for testing this method
        CMPL123CME__Registered_Site__c regSite = new CMPL123CME__Registered_Site__c(
            MIR_Manufacturer_Name__c = 'Something',
            MIR_MFR_Single_Registration_Number__c = 'Something',
            MIR_Contact_First_Name__c = 'Something',
            MIR_Contact_Last_Name__c = 'Something',
            MIR_MFR_eMail__c = 'Something@test.com',
            MIR_MFR_Phone__c = '123-3333',
            MIR_MFR_Street__c = 'Something',
            MIR_MFR_Postal_Code__c = '555',
            MIR_MFR_Street_Number__c = '66',
            MIR_MFR_Address_Complement__c = 'Something',
            MIR_MFR_PO_Box__c = '555',
            MIR_MFR_City_Name__c = 'Something',
            MIR_Authorized_Rep_Name__c = 'Something',
            MIR_Single_Registration_Number__c = 'Something',
            MIR_Authorised_Rep_Contact_First_Name__c = 'Something',
            MIR_Authorised_Rep_Contact_Last_Name__c = 'Something',
            MIR_Authorised_Rep_eMail__c = 'Something@test.com',
            MIR_Authorised_Rep_Phone__c = '123-3333',
            MIR_Authorised_Rep_Street__c = 'Something',
            MIR_Authorised_Rep_Street_Number__c = '66',
            MIR_Authorised_Rep_Address_Complement__c = 'Something',
            MIR_Authorised_Rep_PO_Box__c = '555',
            MIR_Authorised_Rep_City_Name__c = 'Something',
            MIR_Authorised_Rep_Postal_Code__c = '555',
            CMPL123CME__Sequence_No__c = '12345',
            CMPL123CME__Assigned_No__c = '9',
            CMPL123CME__Site_Name__c = 'Something',
            Division__c = 'ADD',
            MIR_MFR_Country__c = countryManuf.Id,
            MIR_Authorised_Rep_Country__c = countryAuth.Id
        );
        insert regSite;

        // Requery for the Registered Site so we get relational fields
        regSite = QueryReusableHelper.getRegSites(new Set<Id>{regSite.Id})[0];

        // It does not matter which MIRs we get
        CMPL123CME__EU_MIR__c mir = [
            SELECT Id, Registered_Site__c,
            // All fields below this comment are accessed in the function we call
            CMPL123CME__Manufact_Organisation_Name__c,
            CMPL123CME__Manufact_Single_Registration_Number_SRN__c,
            CMPL123CME__Manufact_Contact_First_Name__c,
            CMPL123CME__Manufact_Contact_Last_Name__c,
            CMPL123CME__Manufact_E_Mail__c,
            CMPL123CME__Manufact_Phone__c,
            CMPL123CME__Manufact_Street__c,
            CMPL123CME__Manufact_Postcode__c,
            CMPL123CME__Manufact_Street_Number__c,
            CMPL123CME__Manufact_Address_Complement__c,
            CMPL123CME__Manufact_P_O_Box__c,
            CMPL123CME__Manufact_City_Name__c,
            CMPL123CME__Org_Name_Of_Authorised_Representative__c,
            CMPL123CME__Author_Single_Registration_Number_SRN__c,
            CMPL123CME__Author_Contact_First_Name__c,
            CMPL123CME__Author_Contact_Last_Name__c,
            CMPL123CME__Author_E_mail__c,
            CMPL123CME__Author_Phone__c,
            CMPL123CME__Author_Street__c,
            CMPL123CME__Author_Street_Number__c,
            CMPL123CME__Author_Address_Complement__c,
            CMPL123CME__Author_P_O_Box__c,
            CMPL123CME__Author_City_Name__c,
            CMPL123CME__Author_Postcode__c,
            CMPL123CME__Manufact_Country__c,
            CMPL123CME__Author_Country__c,
            RecordTypeId				// Added as a paret of Charm R8
            FROM CMPL123CME__EU_MIR__c
            LIMIT 1
        ];
        
        // Prep the one MIR we will work with;
        mir.CMPL123CME__Manufact_Country__c = null;
        mir.CMPL123CME__Author_Country__c = null;

        // Prepare a map specifically for the function being tested
        Map<Id, CMPL123CME__Registered_Site__c> regSiteMap =
            new Map<Id, CMPL123CME__Registered_Site__c>{
                regSite.Id => regSite
            };

        Test.startTest();
        // Neg test one
        EUMIRTriggerHandler.setManufactAndAuthFieldsOnMir(
            mir, new Map<Id, CMPL123CME__Registered_Site__c>());
        System.assertNotEquals(regSite.MIR_MFR_Phone__c, mir.CMPL123CME__Manufact_Phone__c,
            'Neg test: Should not affect MIR fields when it is not in the map');

        // Neg test two
        mir.Registered_Site__c = null;
        EUMIRTriggerHandler.setManufactAndAuthFieldsOnMir(mir, regSiteMap);
        System.assertNotEquals(regSite.MIR_MFR_Phone__c, mir.CMPL123CME__Manufact_Phone__c,
            'Neg test: Should not affect MIR fields when the Registered Site is unset');

        // Pos test one
        mir.Registered_Site__c = regSite.Id;
        System.assertEquals(regSite, regSiteMap.get(mir.Registered_Site__c),
            'Bug in the tester: Setup data not put together correctly. Bad map creation?');
        System.assertEquals(countryManuf.Name, regSite.MIR_MFR_Country__r.Name,
            'Bug in the tester: Setup data not put together correctly. Forgot to requery?');
        System.assertEquals(countryAuth.Name, regSite.MIR_Authorised_Rep_Country__r.Name,
            'Bug in the tester: Setup data not put together correctly. Forgot to requery?');
        EUMIRTriggerHandler.setManufactAndAuthFieldsOnMir(mir, regSiteMap);
        System.assertEquals(regSite.MIR_MFR_Phone__c, mir.CMPL123CME__Manufact_Phone__c,
            'Pos test: Should copy MIR fields from the Registered Site');
        System.assertEquals(countryManuf.Name, mir.CMPL123CME__Manufact_Country__c,
            'Pos test: Should set the Manufacturer Country from the Registered Site');
        /*System.assertEquals(countryAuth.Name, mir.CMPL123CME__Author_Country__c,
            'Pos test: Should set the Authorized Person Country from the Registered Site');*/   //R8 - Commenetd as autopopulation is happening from new GB MIR country field on registered site
        //R8 - Assert to check - 'CMPL123CME__Author_Country__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_Country__c' field on Registered Site
        System.assertEquals(regSite.GB_MIR_Authorised_Rep_Country__r.Name, mir.CMPL123CME__Author_Country__c,
            'Pos test: Should set the Authorized Person Country from the Registered Site');
		regSite.GB_MIR_Authorised_Rep_Country__c        = null;
        
        // Pos test two
        regSite.MIR_MFR_Country__c = null;
        mir.CMPL123CME__Manufact_Country__c = null;
        mir.CMPL123CME__Manufact_Phone__c = null;
        EUMIRTriggerHandler.setManufactAndAuthFieldsOnMir(mir, regSiteMap);
        System.assertEquals(regSite.MIR_MFR_Phone__c, mir.CMPL123CME__Manufact_Phone__c,
            'Pos test: Should copy MIR fields from the Registered Site');
        System.assertEquals(null, mir.CMPL123CME__Manufact_Country__c,
            'Pos test: Should not set the Manufacturer Country since it is not on the Registered Site');

        // Pos test three
        regSite.MIR_Authorised_Rep_Country__c = null;
        mir.CMPL123CME__Author_Country__c = null;
        mir.CMPL123CME__Manufact_Phone__c = null;
        EUMIRTriggerHandler.setManufactAndAuthFieldsOnMir(mir, regSiteMap);
        System.assertEquals(regSite.MIR_MFR_Phone__c, mir.CMPL123CME__Manufact_Phone__c,
            'Pos test: Should copy MIR fields from the Registered Site');
        System.assertEquals(null, mir.CMPL123CME__Author_Country__c,
            'Pos test: Should not set the Authorized Person Country since it is not on the Registered Site');
        Test.stopTest();
    }

    /**
     * Coverage for un/delete
     * @author Larry Resnik
     * @date 05-AUG-2021
     */
    @isTest
    static void testTryDeleteUndelete() {
        CMPL123CME__EU_MIR__c mir = [SELECT Id FROM CMPL123CME__EU_MIR__c LIMIT 1];
        Test.startTest();
        delete mir;
        System.assertEquals(0, [SELECT Id FROM CMPL123CME__EU_MIR__c WHERE Id =: mir.Id AND IsDeleted = true].size(),
            'Should have deleted the record');
        undelete mir;
        System.assertEquals(1, [SELECT Id FROM CMPL123CME__EU_MIR__c WHERE Id =: mir.Id AND IsDeleted = false].size(),
            'Should have undeleted the record');
        Test.stopTest();
    }
	
	/**
    * Test method to Waive
    * @author Varsha Hariharan
    * @date 30-Sep-2021
    * @revision 06-Oct-2021 Larry Resnik: Moved Test.startTest to avoid SOQL limit
    */
    @isTest
    static void testTryVoid() {
        Test.startTest();
        // Data setup
        User medEvalUser = [SELECT Id, Email FROM User WHERE Email =: MED_EVAL_EMAIL LIMIT 1];
        CMPL123CME__EU_MIR__c mir = [
            SELECT Id, Follow_Up_Required__c, CMPL123_WF_Status__c, 
                Action_on_Follow_Up_Awareness_Date__c,
                New_Followup_Awareness_Date__c,
                CMPL123CME__Expected_Date_Of_Next_Report__c,
                Committed_Report_Change_Rationale__c,
                Committed_Report_date__c
            FROM CMPL123CME__EU_MIR__c
            WHERE CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Initial_Report AND
                CMPL123_WF_Status__c =: AspenConstants.STR_Pending_Follow_Up_Creation
            LIMIT 1
        ];
        mir.CMPL123_WF_Status__c = 'Opened';
        update mir;
        Id notifiedRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Notified Body Regulatory Response').getRecordTypeId();
			Regulatory_Task__c regTask = new Regulatory_Task__c();
            regTask.RecordTypeId = notifiedRTID;
            regTask.Regulatory_Agency_Notification_Required__c = 'No';
        	regTask.Justification_for_not_Reporting__c = 'This issue does not need to be reported per contractual agreement with Notified Body';
            regTask.EU_MIR__c = mir.Id;
            insert regTask;
        	regTask.Medical_Evaluator__c = UserInfo.getUserId();
            regTask.CMPL123_WF_Status__c = 'Closed-Done';
            update regTask;
        	mir.Follow_Up_Required__c = 'Yes';
        mir.CMPL123_WF_Status__c = AspenConstants.STR_WF_Action_Pending_Final_Review;
        mir.CMPL123CME__Expected_Date_Of_Next_Report__c = System.today();
        mir.Committed_Report_Change_Rationale__c = 'Cuz I can';
        mir.New_Followup_Awareness_Date__c = System.today();
        system.debug('New FollowUp Awarness ::: 1538 ' + mir.New_Followup_Awareness_Date__c);
        mir.Action_on_Follow_Up_Awareness_Date__c = 'Set Date';
        mir.Committed_Report_date__c = mir.CMPL123CME__Expected_Date_Of_Next_Report__c;

        System.runAs(medEvalUser) {
            update mir;
            mir.CMPL123_WF_Status__c = AspenConstants.STR_WF_Action_Pending_Final_Review;
            mir.CMPL123_WF_Action__c = 'Waive';
            mir.CMPL123CME__Recipient_Name_Of_NCA__c = 'Test Field';
            mir.CMPL123CME__Reference_Number_By_Manufacturer__c = 'Test Ref No';
            mir.CMPL123CME__UDI_DI__c = 'UDI DI';
            mir.CMPL123CME__UDI_PI__c = 'UDI PI';
            mir.CMPL123CME__Manufact_Country__c = [Select Id from Country__c LIMIT 1].Id;
            mir.CMPL123CME__Date_Of_Submission__c = Date.newInstance(2021, 09, 30);
            mir.CMPL123CME__Submitter_Of_Report__c = 'Manufacturer';
            mir.CMPL123CME__Registered_Commercial_Name_Of_Company__c = 'Regd Commercial Name';
            mir.CMPL123CME__Submitter_Contact_First_Name__c = 'FirstName';
           	mir.CMPL123CME__Submitter_Contact_Last_Name__c = 'LastName';
            mir.CMPL123CME__Submitter_E_Mail__c = 'testCon@mail.com';
            mir.CMPL123CME__Submitter_Phone__c = '942589205';
            mir.CMPL123CME__Submitter_Country__c = 'Netherlands';
            mir.CMPL123CME__Submitter_Street__c = 'Submitter Street';
            mir.CMPL123CME__Submitter_City_Name__c = 'Submitter City';
            mir.CMPL123CME__Submitter_Postcode__c = '600001';
            mir.CMPL123CME__Role_Of_Initial_Reporter__c = 'Healthcare professional';
			update mir;
        }
        // Begin testing
            
        Set<Id> idSet = new Map<Id,CMPL123CME__EU_MIR__c>([SELECT Id FROM CMPL123CME__EU_MIR__c]).keyset();
		Map<String,Id> strMap = EUMIRTriggerHandler.getCodeChoices(idSet);
        List<CMPL123CME__EU_MIR__c> newMirs = [
            SELECT Id, Parent_MIR__c, CMPL123CME__Complaint__c
            FROM CMPL123CME__EU_MIR__c
            WHERE Parent_MIR__c =: mir.Id AND
                CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Follow_Up_Report
        ];
        Account accForComplaint = (Account) TestDataFactory.createSObject(new Account(
            Name = 'Customer Account for Complaint'
        ), false);
        Account accForContact = (Account) TestDataFactory.createSObject(new Account(
            Name = 'Customer Account for Contact'
        ), false);
        insert new Account[]{accForComplaint, accForContact};
		Id complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get(
            'Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) 
            TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                CMPL123CME__Customer__c = accForComplaint.Id,
                RecordTypeId = complaintRTId
            ), true);
        Set<Id> idSet2 = new Set<Id>();
        idSet2.add(complaint.Id);
        List<Contact__c> conList = new List<Contact__c>();
        Contact__c newCon = new Contact__c();
        newCon.Ticket__c = complaint.Id;
        newCon.pRE__c = TRUE;
        newCon.External_ID__c = 'ExternalID1';
        Contact__c newCon2 = new Contact__c();
        newCon2.Ticket__c = complaint.Id;
        newCon2.Primary__c = TRUE;
        newCon2.External_ID__c = 'ExternalID2';
        conList.add(newCon);
        conList.add(newCon2);
        insert conList;
        EUMIRTriggerHandler.fillTicketData(idSet2);
        test.stopTest();
    }
    /**
    * Test method to check WF Action change
    * @author Varsha Hariharan
    * @date 30-Sep-2021
    */
    @isTest
    static void testStatusChanges() {
        User medEvalUser = [SELECT Id, Email FROM User WHERE Email =: MED_EVAL_EMAIL LIMIT 1];
        CMPL123CME__EU_MIR__c mir = [
            SELECT Id, Follow_Up_Required__c, CMPL123_WF_Status__c, 
                Action_on_Follow_Up_Awareness_Date__c,
                New_Followup_Awareness_Date__c,
                CMPL123CME__Expected_Date_Of_Next_Report__c,
                Committed_Report_Change_Rationale__c,
                Committed_Report_date__c
            FROM CMPL123CME__EU_MIR__c
            WHERE CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Initial_Report AND
                CMPL123_WF_Status__c =: AspenConstants.STR_Pending_Follow_Up_Creation
            LIMIT 1
        ];
        mir.CMPL123_WF_Status__c = 'Opened';
        Id complaintId = [Select Id from CMPL123CME__Complaint__c LIMIT 1].Id;
        mir.CMPL123CME__Complaint__c = complaintId;
        update mir;
        Test.startTest();
        mir.CMPL123_WF_Status__c = AspenConstants.STR_WF_Pending_Regulatory;
        mir.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Submit_To_Regulatory;
        mir.CMPL123CME__Expected_Date_Of_Next_Report__c = System.today();
        mir.Committed_Report_Change_Rationale__c = 'Cuz I can';
        mir.New_Followup_Awareness_Date__c = System.today();
        system.debug('New FollowUp Awarness ::: 1636 ' + mir.New_Followup_Awareness_Date__c);
        mir.Action_on_Follow_Up_Awareness_Date__c = 'Set Date';
        mir.Committed_Report_date__c = mir.CMPL123CME__Expected_Date_Of_Next_Report__c;
		mir.CMPL123CME__Preliminary_Results_And_Conclusions__c = 'Test Data';
        System.runAs(medEvalUser) {
            update mir;
            mir.CMPL123CME__Recipient_Name_Of_NCA__c = 'Test Field';
            mir.CMPL123CME__Reference_Number_By_Manufacturer__c = 'Test Ref No';
            mir.CMPL123CME__UDI_DI__c = 'UDI DI';
            mir.CMPL123CME__UDI_PI__c = 'UDI PI';
            mir.CMPL123CME__Manufact_Country__c = [Select Id from Country__c LIMIT 1].Id;
            mir.CMPL123CME__Date_Of_Submission__c = Date.newInstance(2021, 09, 30);
            mir.CMPL123CME__Submitter_Of_Report__c = 'Manufacturer';
            mir.CMPL123CME__Registered_Commercial_Name_Of_Company__c = 'Regd Commercial Name';
            mir.CMPL123CME__Submitter_Contact_First_Name__c = 'FirstName';
           	mir.CMPL123CME__Submitter_Contact_Last_Name__c = 'LastName';
            mir.CMPL123CME__Submitter_E_Mail__c = 'testCon@mail.com';
            mir.CMPL123CME__Submitter_Phone__c = '942589205';
            mir.CMPL123CME__Submitter_Country__c = 'Netherlands';
            mir.CMPL123CME__Submitter_Street__c = 'Submitter Street';
            mir.CMPL123CME__Submitter_City_Name__c = 'Submitter City';
            mir.CMPL123CME__Submitter_Postcode__c = '600001';
            mir.CMPL123CME__Role_Of_Initial_Reporter__c = 'Healthcare professional';
			Id complaintId2 = [Select Id from CMPL123CME__Complaint__c where Id !=: complaintId LIMIT 1].Id;
        	mir.CMPL123CME__Complaint__c = complaintId2;
            mir.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Complete_Regulatory_Response;
            mir.CMPL123_WF_Status__c = AspenConstants.STR_WF_Action_Pending_Final_Review;
            update mir;
        }
        test.stopTest();
    }
    
   //CHaRM R5: Start
   /*
    * @Method       : mIRFieldsPopulationRS
    * @Description  : Check the asserts for EUMIR. Wheather 'Manufacturer information' & 'Authorised representative information' fields are getting populated from Registerd site.
    * @Return       : N/A
    * @Params       : N/A
    */
    @isTest
    static void mIRFieldsPopulationRS() {
        User vigContact = [SELECT Id FROM User LIMIT 1];
        Country__c countryManuf = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'USA'), false);
        Country__c countryAuth = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'Japan', Primary_Vigilance_Contact__c = vigContact.Id), false);
        insert new Country__c[]{countryManuf, countryAuth};

        // Create a Registered Site for testing this method
        CMPL123CME__Registered_Site__c regSite = new CMPL123CME__Registered_Site__c(
            MIR_Manufacturer_Name__c = 'testing EUMIR',
            MIR_MFR_City_Name__c = 'ROME',
            MIR_MFR_Phone__c = '123456',
            MIR_Authorised_Rep_Contact_First_Name__c = 'Testing',
            MIR_Authorized_Rep_Name__c = 'Name1',
            MIR_Authorised_Rep_Street_Number__c = '321',
            CMPL123CME__Sequence_No__c = '12345',
            CMPL123CME__Assigned_No__c = '9',
            CMPL123CME__Site_Name__c = 'Site1',
            Division__c = 'ADD',
            MIR_MFR_Country__c = countryManuf.Id,
            MIR_Authorised_Rep_Country__c = countryAuth.Id,
            // Added as a part of Charm R8 - Start
            GB_MIR_Authorized_Rep_Name__c = 'Auth Name',
            GB_MIR_Authorised_Rep_Contact_First_Name__c = 'Fisrt Testing',
            GB_MIR_Authorised_Rep_eMail__c = 'test@gmail.com',
            GB_MIR_Authorised_Rep_Contact_Last_Name__c = 'Last Testing',
            GB_MIR_Authorised_Rep_Country__c = countryAuth.Id,
            GB_MIR_Authorised_Rep_Phone__c = '123456',
            GB_MIR_Authorised_Rep_Street_Number__c = '321',
            GB_MIR_Authorised_Rep_Street__c = 'Auth Street Test',
            GB_MIR_Authorised_Rep_PO_Box__c = 'Auth PO Box Testing',
            GB_MIR_Authorised_Rep_Postal_Code__c = 'Auth Postal Testing',
            GB_MIR_Authorised_Rep_Address_Complement__c = 'Auth Address Testing',
            GB_MIR_Single_Registration_Number__c = 'SRN Testing',
            GB_MIR_Authorised_Rep_City_Name__c = 'Auth City Testing'
            // Added as a part of Charm R8 - End
        );
        insert regSite;

        // Requery for the Registered Site so we get relational fields
        regSite = QueryReusableHelper.getRegSites(new Set<Id>{regSite.Id})[0];
        
        // It does not matter which MIRs we get
        CMPL123CME__EU_MIR__c mir = [Select Registered_Site__c,CMPL123CME__Manufact_Organisation_Name__c,CMPL123CME__Manufact_City_Name__c,
                                        CMPL123CME__Manufact_Phone__c,CMPL123CME__Author_Contact_First_Name__c, 
                                        CMPL123CME__Org_Name_Of_Authorised_Representative__c,CMPL123CME__Author_Street_Number__c,
                                     	RecordTypeId,CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c,CMPL123CME__Author_Single_Registration_Number_SRN__c,
                                     	CMPL123CME__Author_Contact_Last_Name__c,CMPL123CME__Author_E_mail__c,
                                     	CMPL123CME__Author_Phone__c,CMPL123CME__Author_Street__c,CMPL123CME__Author_Address_Complement__c,
                                     	CMPL123CME__Author_P_O_Box__c,CMPL123CME__Author_City_Name__c,CMPL123CME__Author_Postcode__c
                                        From CMPL123CME__EU_MIR__c LIMIT 1];  //R8 - Updated query to add all authorized rep related fields
        
        Map<Id, CMPL123CME__Registered_Site__c> regSiteMaps =
            new Map<Id, CMPL123CME__Registered_Site__c>{
                regSite.Id => regSite
            };
	
        Test.startTest();        
        
        mir.Registered_Site__c = regSite.Id;
        EUMIRTriggerHandler.setManufactAndAuthFieldsOnMir(mir, regSiteMaps); 
          System.assertEquals( 'testing EUMIR', mir.CMPL123CME__Manufact_Organisation_Name__c );
          System.assertEquals('ROME', mir.CMPL123CME__Manufact_City_Name__c );
          System.assertEquals('123456', mir.CMPL123CME__Manufact_Phone__c );
      	//R8 - Start
      	// Assert to check - 'CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c' field on GB MIR is auto populated from 'GB_MIR_Authorized_Rep_Name__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Org_Name_Of_Authorised_Rep_GBMIR__c , regSite.GB_MIR_Authorized_Rep_Name__c);
        // Assert to check - 'CMPL123CME__Author_Single_Registration_Number_SRN__c' field on GB MIR is auto populated from 'GB_MIR_Single_Registration_Number__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_Single_Registration_Number_SRN__c , regSite.GB_MIR_Single_Registration_Number__c);
        // Assert to check - 'CMPL123CME__Author_Contact_First_Name__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_Contact_First_Name__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_Contact_First_Name__c , regSite.GB_MIR_Authorised_Rep_Contact_First_Name__c);
        // Assert to check - 'CMPL123CME__Author_Contact_Last_Name__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_Contact_Last_Name__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_Contact_Last_Name__c , regSite.GB_MIR_Authorised_Rep_Contact_Last_Name__c);
        // Assert to check - 'CMPL123CME__Author_E_mail__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_eMail__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_E_mail__c , regSite.GB_MIR_Authorised_Rep_eMail__c);
        // Assert to check - 'CMPL123CME__Author_Phone__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_Phone__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_Phone__c , regSite.GB_MIR_Authorised_Rep_Phone__c);
        // Assert to check - 'CMPL123CME__Author_Street__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_Street__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_Street__c  , regSite.GB_MIR_Authorised_Rep_Street__c);
        // Assert to check - 'CMPL123CME__Author_Street_Number__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_Street_Number__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_Street_Number__c , regSite.GB_MIR_Authorised_Rep_Street_Number__c);
        // Assert to check - 'CMPL123CME__Author_Address_Complement__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_Address_Complement__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_Address_Complement__c , regSite.GB_MIR_Authorised_Rep_Address_Complement__c);
        // Assert to check - 'CMPL123CME__Author_P_O_Box__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_PO_Box__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_P_O_Box__c , regSite.GB_MIR_Authorised_Rep_PO_Box__c);
        // Assert to check - 'CMPL123CME__Author_City_Name__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_City_Name__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_City_Name__c , regSite.GB_MIR_Authorised_Rep_City_Name__c);
        // Assert to check - 'CMPL123CME__Author_Postcode__c' field on GB MIR is auto populated from 'GB_MIR_Authorised_Rep_Postal_Code__c' field on Registered Site
        System.assertEquals(mir.CMPL123CME__Author_Postcode__c , regSite.GB_MIR_Authorised_Rep_Postal_Code__c);
        //R8 - End
        Test.stopTest();
    
    }
    //CHaRM R5: End
    //CHaRM R5: End
     @isTest
    public static void testMirFieldUpdate() {
        Test.startTest();
        List<CMPL123CME__EU_MIR__c> mirs = [SELECT Id, CMPL123CME__Type_Of_Report__c, CMPL123CME__Device_Operator_At_Event__c, 
                                            CMPL123CME__Initial_Actions_Taken_By_Manufacturer__c, CMPL123CME__List_Down_Further_Investigations__c,
                                            CMPL123CME__Reference_Number_By_NCA__c, CMPL123CME__Current_Device_Location__c, 
                                            CMPL123CME__Current_Device_Location_Other__c, CMPL123CME__Role_Of_Initial_Reporter__c, 
                                            CMPL123CME__Patients_Prior_Health_Condition__c, MedicalEvaluation__c, 
                                            CMPL123CME__Manufacturer_Awareness_Date__c, CMPL123CME__Mfr_Reportability_awareness_date__c, 
                                            CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c, Medical_Evaluator__c, 
                                            CMPL123CME__Date_Of_Incident_From__c, CMPL123CME__Date_Of_Incident_To__c, CMPL123CME__Complaint__c, 
                                            CMPL123CME__Reference_Number_By_Manufacturer__c, CMPL123CME__Initial_Reporter_Country__c, 
                                            CMPL123CME__General_Comments__c, Country__c, CMPL123CME__Recipient_Name_Of_NCA__c, 
                                            CMPL123CME__Registered_Commercial_Name_Of_Company__c, CMPL123CME__EUDAMED_Number_Of_NCA__c, 
                                            CMPL123CME__Submitter_City_Name__c, CMPL123CME__Submitter_E_Mail__c, CMPL123CME__Submitter_Phone__c, 
                                            CMPL123CME__Submitter_Postcode__c, CMPL123CME__Submitter_Country__c, 
                                            CMPL123CME__Submitter_Contact_Last_Name__c, CMPL123CME__Submitter_Street__c, 
                                            CMPL123CME__Submitter_Contact_First_Name__c, Product__c, CMPL123CME__UDI_DI__c, 
                                            CMPL123CME__Software_Version__c, CMPL123CME__UDI_PI__c, CMPL123CME__Unit_Of_Use_UDI_DI__c, 
                                            CMPL123CME__Firmware_Version__c, CMPL123CME__Medical_Device_Name__c, Medical_Device_Name__c, 
                                            CMPL123CME__Model__c, CMPL123CME__Catalogue_Reference_Number__c, CMPL123CME__MDD_AIMDD_Class__c,
                                            CMPL123CME__IVDD_Class__c, CMPL123CME__NB_ID_Number1__c, CMPL123CME__Medical_Device_Nomenclature_Code__c, 
                                            CMPL123CME__NB_Certificate_Number_1__c, Registered_Site__c, CMPL123CME__Medical_Device_Terminology__c, 
                                            CMPL123CME__Description_Of_Device_Nomenclature_Text__c, CMPL123CME__Description_of_dev_Nom_text_7_3_1__c,
                                            CMPL123CME__Nomenclature_text__c, CMPL123CME__Medical_Device_Terminology_7_3_1__c, CMPL123CME__Basic_UDI_DI__c,
                                            CMPL123CME__Lot_Batch_Numbers__c, CMPL123CME__Device_Usage__c, CMPL123CME__Serial_Numbers__c, 
                                            CMPL123CME__Initial_Reporter_Contact_Last_Name__c, CMPL123CME__Initial_Reporter_Email__c, 
                                            CMPL123CME__Initial_Reporter_Phone__c, CMPL123CME__Initial_Reporter_Street__c,
                                            CMPL123CME__Initial_Reporter_City_Name__c, 
                                            CMPL123CME__Initial_Reporter_Postcode__c, CMPL123CME__Name_Of_The_Healthcare_Facility__c,
                                            Product_Type__c, RecordTypeId,CMPL123CME__Author_Country__c,CMPL123CME__Manufact_Country__c FROM CMPL123CME__EU_MIR__c Limit 1];
        Set<Id> medicalEvalID = new Set<Id>();
        Map<Id, CMPL123CME__Questionnaire__c> commentsMap = new Map<Id, CMPL123CME__Questionnaire__c>();
        Set<Id> ticketss = new Set<Id>();
        Map<Id, CMPL123CME__Complaint__c> TicketsMap = new Map<Id, CMPL123CME__Complaint__c>();
        Map<Id, Country__c> countryRecordMap = new Map<Id, Country__c>();
        Map<Id, Product_Ticket__c> mapProductTickets = new Map<Id, Product_Ticket__c>();
        Map<String, Contact__c> ticketWithContactMap = new Map<String, Contact__c>();
        Map<Id, CMPL123CME__Registered_Site__c> registeredsitesMap = new Map<Id, CMPL123CME__Registered_Site__c>();
        Map<String, CMPL123CME__Complaint__c> ticketWithCustomerMap = new Map<String, CMPL123CME__Complaint__c>();
        
        EUMIRTriggerHandler.mirFieldUpdate(mirs, medicalEvalID, commentsMap, ticketss, TicketsMap, countryRecordMap, mapProductTickets, ticketWithContactMap, registeredsitesMap, ticketWithCustomerMap);
        
        System.assertEquals(1, mirs.size());
        Test.stopTest();
    }
    
    /*
    * @Method       : testAutofillRecType7_2_1ProdTypeIVDD_MDD
    * @Description  : To test auto-population of 'CMPL123CME__Manufacturer_Awareness_Date__c','CMPL123CME__Medical_Device_Terminology__c','CMPL123CME__Description_Of_Device_Nomenclature_Text__c' fields on MIR when Recordtype is '7_2_1' and Product type is 'IVDD/MDD'
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R7 - FRS-1515-24
    */
    @isTest
    public static void testAutofillRecType7_2_1ProdTypeIVDD_MDD(){
        Country__c country = [Select Id,Report_Type__c from Country__c where Report_Type__c = 'GB MIR' Limit 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c Limit 1];        
        User adminUser = [Select id from User where Email='test2@gmail.com' Limit 1];         
        CMPL123CME__Registered_Site__c registeredSite = [Select id from CMPL123CME__Registered_Site__c where CMPL123CME__Site_Name__c='Test Registered Site' Limit 1];
        CMPL123__Product__c product = [Select Id,Device_Nomenclature_System__c,Device_Nomenclature_Text__c from CMPL123__Product__c where Registered_Site__c = :registeredSite.Id Limit 1];  
        Product_Ticket__c prodTckt =[Select Id from Product_Ticket__c where Event_Ticket__c = :complaint.Id Limit 1];
        CMPL123CME__Questionnaire__c assessment = [Select id,Initial_Awareness_Date__c from CMPL123CME__Questionnaire__c where  CMPL123CME__Complaint__c = :complaint.Id Limit 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = country.Id), true);
        User medEvalUser = [Select id from User where Email= :MED_EVAL_EMAIL Limit 1];
        
        MirInitWrap mirInit = new MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = country.Id;
        mirInit.medicalEvaluatorId = medEvalUser.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        
        System.runAs(medEvalUser){
            Test.startTest();
            //Id recordType7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_2_1') .getRecordTypeId();
            Id recordType7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('GB_MIR_7_2_1') .getRecordTypeId();	// Added as a part of Charm R8
            CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInit);
            euMirTypeInit.Country__c=country.Id;
            euMirTypeInit.Product_Type__c='IVDD/MDD';
            insert euMirTypeInit;
            
            CMPL123CME__EU_MIR__c mirInitial = [Select Id,RecordTypeId,CMPL123CME__Manufacturer_Awareness_Date__c,CMPL123CME__Medical_Device_Terminology__c,CMPL123CME__Description_Of_Device_Nomenclature_Text__c from CMPL123CME__EU_MIR__c where Id = :euMirTypeInit.Id Limit 1];  
            if(mirInitial.RecordTypeId == recordType7_2_1){
                // Assert to check - MIR created is of recordtype 7_2_1
                System.assertEquals(mirInitial.RecordTypeId,recordType7_2_1);
                // Assert to check - 'CMPL123CME__Manufacturer_Awareness_Date__c' field on MIR is auto populated from 'Initial_Awareness_Date__c' field on Medical Evaluation
                System.assertEquals(mirInitial.CMPL123CME__Manufacturer_Awareness_Date__c,assessment.Initial_Awareness_Date__c);
                // Assert to check - 'CMPL123CME__Medical_Device_Terminology__c' field on MIR is auto populated from 'Device_Nomenclature_System__c' field on Product
                System.assertEquals(mirInitial.CMPL123CME__Medical_Device_Terminology__c,product.Device_Nomenclature_System__c);
                // Assert to check - 'CMPL123CME__Description_Of_Device_Nomenclature_Text__c' field on MIR is auto populated from 'Device_Nomenclature_Text__c' field on Product
                System.assertEquals(mirInitial.CMPL123CME__Description_Of_Device_Nomenclature_Text__c,product.Device_Nomenclature_Text__c);
            }
            Test.stopTest(); 
        }       
    }
    
    /*
    * @Method       : testAutofillRecType7_2_1ProdTypeIVDR_MDR
    * @Description  : To test auto-population of 'CMPL123CME__Medical_Device_Terminology__c','CMPL123CME__Description_Of_Device_Nomenclature_Text__c' fields on MIR when Recordtype is '7_2_1' and Product type is 'IVDR/MDR'
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R7 - FRS-1515-24
    */
    @isTest
    public static void testAutofillRecType7_2_1ProdTypeIVDR_MDR(){
        Country__c country = [Select Id,Report_Type__c from Country__c where Report_Type__c = 'GB MIR' Limit 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c Limit 1];
        User adminUser = [Select id from User where Email='test2@gmail.com' Limit 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = country.Id), true);
        CMPL123CME__Registered_Site__c registeredSite = [Select id from CMPL123CME__Registered_Site__c where CMPL123CME__Site_Name__c='Test Registered Site' Limit 1];
        CMPL123__Product__c product = [Select Id,Device_Nomenclature_System_2__c,Device_Nomenclature_Text_2__c, Device_Nomenclature_System__c, Device_Nomenclature_Text__c from CMPL123__Product__c where Registered_Site__c = :registeredSite.Id Limit 1];
        Product_Ticket__c prodTckt =[Select Id from Product_Ticket__c where Event_Ticket__c = :complaint.Id Limit 1];            
        CMPL123CME__Questionnaire__c assessment = [Select Id, CMPL123_WF_Status__c from CMPL123CME__Questionnaire__c where  CMPL123CME__Complaint__c = :complaint.Id Limit 1];
        User medEvalUser = [Select Id from User where Email= :MED_EVAL_EMAIL Limit 1];
        
        MirInitWrap mirInit = new MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = country.Id;
        mirInit.medicalEvaluatorId = medEvalUser.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        
        System.runAs(medEvalUser){
            Test.startTest();
            //Id recordType7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_2_1') .getRecordTypeId();
            Id recordType7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('GB_MIR_7_2_1') .getRecordTypeId(); // Added as a part of Charm R8
            CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInit);
            euMirTypeInit.Country__c=country.Id;
            euMirTypeInit.Product_Type__c='IVDR/MDR';
            insert euMirTypeInit;
            
            CMPL123CME__EU_MIR__c mirInitial = [Select Id,RecordTypeId,Country__r.Name, RecordType.Name,CMPL123CME__Manufacturer_Awareness_Date__c,CMPL123CME__Medical_Device_Terminology__c,CMPL123CME__Description_Of_Device_Nomenclature_Text__c from CMPL123CME__EU_MIR__c where Id = :euMirTypeInit.Id Limit 1];
            if(mirInitial.RecordTypeId == recordType7_2_1){
                // Assert to check - MIR created is of recordtype 7_2_1
                System.assertEquals(mirInitial.RecordTypeId,recordType7_2_1);
                // Assert to check - 'CMPL123CME__Medical_Device_Terminology__c' field on MIR is auto populated from 'Device_Nomenclature_System_2__c' field on Product
                // System.assertEquals(mirInitial.CMPL123CME__Medical_Device_Terminology__c,product.Device_Nomenclature_System_2__c);      // Commented as a part of Charm R8.
                // R8 Added - Assert to check - 'CMPL123CME__Medical_Device_Terminology__c' field on MIR is auto populated from 'Device_Nomenclature_System__c' field on Product
                System.assertEquals(mirInitial.CMPL123CME__Medical_Device_Terminology__c,product.Device_Nomenclature_System__c);
                // Assert to check - 'CMPL123CME__Description_Of_Device_Nomenclature_Text__c' field on MIR is auto populated from 'Device_Nomenclature_Text_2__c' field on Product                               
                // System.assertEquals(mirInitial.CMPL123CME__Description_Of_Device_Nomenclature_Text__c,product.Device_Nomenclature_Text_2__c);   // Commented as a part of Charm R8
                // R8 Added - 'CMPL123CME__Description_Of_Device_Nomenclature_Text__c' field on MIR is auto populated from 'Device_Nomenclature_Text__c' field on Product
                System.assertEquals(mirInitial.CMPL123CME__Description_Of_Device_Nomenclature_Text__c,product.Device_Nomenclature_Text__c);
            }
            Test.stopTest();  
        }        
    }
    

    
    /*
    * @Method       : testAutofillRecType7_3_1ProdTypeIVDD_MDD
    * @Description  : To test auto-population of 'CMPL123CME__Manufacturer_Awareness_Date__c','CMPL123CME__Mfr_Reportability_awareness_date__c' fields on MIR when Recordtype is '7_3_1' and Product type is 'IVDD/MDD'
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R7 - FRS-1515-24
    */
    @isTest
    public static void testAutofillRecType7_3_1ProdTypeIVDD_MDD(){  
        //Created the static resource with all the active countries to configure the test method for 7.3.1 record type of EUMIR object. 
        //List<String> countries = getNon721CountriesFromResource();  //R8 - Commented this line as this method is no more used
        Country__c country = [Select Id,Report_Type__c from Country__c where Report_Type__c = 'EUMIR' Limit 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c Limit 1];
        User adminUser = [Select id from User where Email='test2@gmail.com' Limit 1];  
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c)
            TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30,Country__c = country.Id), true);

        CMPL123CME__Registered_Site__c registeredSite = [Select id from CMPL123CME__Registered_Site__c where CMPL123CME__Site_Name__c='Test Registered Site' Limit 1];
        CMPL123__Product__c product = [Select Id,Device_Description_Intended_purpose__c,Device_Nomenclature_Text__c,Device_Nomenclature_System__c from CMPL123__Product__c where Registered_Site__c = :registeredSite.Id Limit 1];
        Product_Ticket__c prodTckt =[Select Id from Product_Ticket__c where Event_Ticket__c = :complaint.Id Limit 1];            
        CMPL123CME__Questionnaire__c assessment = [Select Id,Receipt_Date__c,Initial_Awareness_Date__c from CMPL123CME__Questionnaire__c where  CMPL123CME__Complaint__c = :complaint.Id Limit 1];
        User medEvalUser = [Select Id from User where Email= :MED_EVAL_EMAIL Limit 1];
        
        MirInitWrap mirInit = new MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = country.Id;
        mirInit.medicalEvaluatorId = medEvalUser.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        System.runAs(medEvalUser){
            Test.startTest();
            Id recordType7_3_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_3_1') .getRecordTypeId();
            CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInit);
            euMirTypeInit.Country__c=country.Id;
            euMirTypeInit.Product_Type__c='IVDD/MDD';            
            insert euMirTypeInit;
            //R8.0 - Removed the field CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c as part of IPDR 822 fix
            CMPL123CME__EU_MIR__c mirInitial = [Select Id,RecordTypeId,RecordType.Name,Country__r.Name, CMPL123CME__Manufacturer_Awareness_Date__c,CMPL123CME__Mfr_Reportability_awareness_date__c,CMPL123CME__Description_of_dev_Nom_text_7_3_1__c,CMPL123CME__Nomenclature_text__c,CMPL123CME__Medical_Device_Terminology_7_3_1__c from CMPL123CME__EU_MIR__c where Id = :euMirTypeInit.Id Limit 1];
            
            if(mirInitial.RecordTypeId == recordType7_3_1){
                // Assert to check - MIR created is of recordtype 7_3_1
                System.assertEquals(mirInitial.RecordTypeId,recordType7_3_1);
                // Assert to check - 'CMPL123CME__Manufacturer_Awareness_Date__c' field on MIR is auto populated from 'Receipt_Date__c' field on Medical Evaluation
                System.assertEquals(mirInitial.CMPL123CME__Manufacturer_Awareness_Date__c,assessment.Receipt_Date__c.Date());
                // Assert to check - 'CMPL123CME__Mfr_Reportability_awareness_date__c' field on MIR is auto populated from 'Initial_Awareness_Date__c' field on Medical Evaluation
                System.assertEquals(mirInitial.CMPL123CME__Mfr_Reportability_awareness_date__c,assessment.Initial_Awareness_Date__c);
                //R8.0 - Removed the assert statement for field 'CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c' as part of fix for IPDR 822
                // Assert to check - 'CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c' field on MIR is auto populated as 'NO'
                //System.assertEquals(mirInitial.CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c,AspenConstants.STR_No);  
                // Assert to check - 'CMPL123CME__Description_of_dev_Nom_text_7_3_1__c' field on MIR is auto populated from 'Device_Description_Intended_purpose__c' field on Product  
                System.assertEquals(mirInitial.CMPL123CME__Description_of_dev_Nom_text_7_3_1__c,product.Device_Description_Intended_purpose__c);
                // Assert to check - 'CMPL123CME__Nomenclature_text__c' field on MIR is auto populated from 'Device_Nomenclature_Text__c' field on Product
                System.assertEquals(mirInitial.CMPL123CME__Nomenclature_text__c,product.Device_Nomenclature_Text__c);
                // Assert to check - 'CMPL123CME__Medical_Device_Terminology_7_3_1__c' field on MIR is auto populated from 'Device_Nomenclature_System__c' field on Product
                System.assertEquals(mirInitial.CMPL123CME__Medical_Device_Terminology_7_3_1__c,product.Device_Nomenclature_System__c);       
            }
            Test.stopTest();  
        }
    }
    
    /*
    * @Method       : testAutofillRecType7_3_1ProdTypeIVDR_MDR
    * @Description  : To test auto-population of 'CMPL123CME__Description_of_dev_Nom_text_7_3_1__c','CMPL123CME__Nomenclature_text__c','CMPL123CME__Medical_Device_Terminology_7_3_1__c','CMPL123CME__Does_the_device_fulfil_any_cases__c' fields on MIR when Recordtype is '7_3_1' and Product type is 'IVDR/MDR'
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R7 - FRS-1515-24
    */
    @isTest
    public static void testAutofillRecType7_3_1ProdTypeIVDR_MDR(){  
        //Created the static resource with all the active countries to configure the test method for 7.3.1 record type of EUMIR object. 
        //List<String> countries = getNon721CountriesFromResource();  //R8 - Commented this line as this method is no more used
        Country__c country = [Select Id,Report_Type__c from Country__c where Report_Type__c = 'EUMIR' Limit 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c Limit 1];
        User adminUser = [Select id from User where Email='test2@gmail.com' Limit 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = country.Id), true);

        CMPL123CME__Registered_Site__c registeredSite = [Select id from CMPL123CME__Registered_Site__c where CMPL123CME__Site_Name__c='Test Registered Site' Limit 1];
        CMPL123__Product__c product = [Select Id,Device_Description_Intended_purpose__c,Device_Nomenclature_Text_2__c,Device_Nomenclature_System_2__c,IVDR_Class__c,IVDR_Class_Type__c from CMPL123__Product__c where Registered_Site__c = :registeredSite.Id Limit 1];
        product.IVDR_Class__c = 'IVDR class C';					
        product.IVDR_Class_Type__c = 'Companion diagnostic';
        update product;
        Product_Ticket__c prodTckt =[Select Id from Product_Ticket__c where Event_Ticket__c = :complaint.Id Limit 1];            
        CMPL123CME__Questionnaire__c assessment = [Select Id,Receipt_Date__c,Initial_Awareness_Date__c from CMPL123CME__Questionnaire__c where  CMPL123CME__Complaint__c = :complaint.Id Limit 1];
        User medEvalUser = [Select Id from User where Email= :MED_EVAL_EMAIL Limit 1];
        
        MirInitWrap mirInit = new MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = country.Id;
        mirInit.medicalEvaluatorId = medEvalUser.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        
        System.runAs(medEvalUser){
            Test.startTest();
            Id recordType7_3_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_3_1') .getRecordTypeId();
            CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInit);
            euMirTypeInit.Country__c=country.Id;
            euMirTypeInit.Product_Type__c='IVDR/MDR';            
            insert euMirTypeInit;
            //R8.0 - Removed the field CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c from the query as part of IPDR 822 fix
            CMPL123CME__EU_MIR__c mirInitial = [Select Id,RecordTypeId,RecordType.Name,Country__r.Name,CMPL123CME__IVDR_Class__c,CMPL123CME__IVDR_Class_Type__c,CMPL123CME__Manufacturer_Awareness_Date__c,CMPL123CME__Mfr_Reportability_awareness_date__c,CMPL123CME__Description_of_dev_Nom_text_7_3_1__c,CMPL123CME__Nomenclature_text__c,CMPL123CME__Medical_Device_Terminology_7_3_1__c,CMPL123CME__Does_the_device_fulfil_any_cases__c from CMPL123CME__EU_MIR__c where Id = :euMirTypeInit.Id Limit 1];
            if(mirInitial.RecordTypeId == recordType7_3_1){
                // Assert to check - MIR created is of recordtype 7_3_1
                System.assertEquals(mirInitial.RecordTypeId,recordType7_3_1);  
                // Assert to check - 'CMPL123CME__Description_of_dev_Nom_text_7_3_1__c' field on MIR is auto populated from 'Device_Description_Intended_purpose__c' field on Product           
                System.assertEquals(mirInitial.CMPL123CME__Description_of_dev_Nom_text_7_3_1__c,product.Device_Description_Intended_purpose__c);
                // Assert to check - 'CMPL123CME__Nomenclature_text__c' field on MIR is auto populated from 'Device_Nomenclature_Text_2__c' field on Product
                System.assertEquals(mirInitial.CMPL123CME__Nomenclature_text__c,product.Device_Nomenclature_Text_2__c);
                // Assert to check - 'CMPL123CME__Medical_Device_Terminology_7_3_1__c' field on MIR is auto populated from 'Device_Nomenclature_System_2__c' field on Product
                System.assertEquals(mirInitial.CMPL123CME__Medical_Device_Terminology_7_3_1__c,product.Device_Nomenclature_System_2__c);  
                // Assert to check - 'CMPL123CME__Does_the_device_fulfil_any_cases__c' field on MIR is auto populated as 'YES'
                System.assertEquals(mirInitial.CMPL123CME__Does_the_device_fulfil_any_cases__c,AspenConstants.STR_Yes); 
            }
            Test.stopTest();  
        }
    }
    
    /*
    * @Method       : testTransformCountries
    * @Description  : To test transform values of 'CMPL123CME__Author_Country__c','CMPL123CME__Initial_Reporter_Country__c','CMPL123CME__Manufact_Country__c','CMPL123CME__Submitter_Country__c' fields on MIR when Recordtype is '7_3_1' and whose values are not acceptable in '7_3_1'
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R7 - FRS-1515-24
    */
    @isTest
    public static void testTransformCountries(){ 
        //Created the static resource with all the active countries to configure the test method for 7.3.1 record type of EUMIR object. 
        //List<String> countries = getNon721CountriesFromResource();  //R8 - Commented this line as this method is no more used
        Country__c country = [Select Id,Report_Type__c from Country__c where Report_Type__c = 'EUMIR' Limit 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c Limit 1];
        Account customer1 = [Select Id,Country__c from Account Limit 1];
        customer1.Country__c ='United Kingdom';
        update customer1;
        User adminUser = [Select Id,Country from User where Email='test2@gmail.com' Limit 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30,Country__c = country.Id), true);
        
        Country__c country_US = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'US', Primary_Vigilance_Contact__c = adminUser.Id), true);
        Country__c country_USA = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'USA', Primary_Vigilance_Contact__c = adminUser.Id), true);
        CMPL123CME__Registered_Site__c registeredSite = [Select Id,MIR_MFR_Country__c,MIR_Authorised_Rep_Country__c from CMPL123CME__Registered_Site__c where CMPL123CME__Site_Name__c='Test Registered Site' Limit 1];
        registeredSite.MIR_MFR_Country__c=country_USA.Id;
        registeredSite.MIR_Authorised_Rep_Country__c=country_US.Id;
        update registeredSite;
        CMPL123__Product__c product = [Select Id,Device_Description_Intended_purpose__c,Device_Nomenclature_Text__c,Device_Nomenclature_System__c from CMPL123__Product__c where Registered_Site__c = :registeredSite.Id Limit 1];
        Product_Ticket__c prodTckt =[Select Id from Product_Ticket__c where Event_Ticket__c = :complaint.Id Limit 1];            
        CMPL123CME__Questionnaire__c assessment = [Select Id,Receipt_Date__c,Initial_Awareness_Date__c from CMPL123CME__Questionnaire__c where  CMPL123CME__Complaint__c = :complaint.Id Limit 1];
        User medEvalUser = [Select Id from User where Email= :MED_EVAL_EMAIL Limit 1];
        
        MirInitWrap mirInit = new MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = country.Id;
        mirInit.medicalEvaluatorId = medEvalUser.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        
        System.runAs(medEvalUser){
            Test.startTest();
            //Below is to check insert scenario
            Id recordType7_3_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_3_1') .getRecordTypeId();
            CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInit);
            euMirTypeInit.Country__c=country.Id;
            euMirTypeInit.Product_Type__c='IVDD/MDD';
            insert euMirTypeInit;
            
            CMPL123CME__EU_MIR__c mirInitial = [Select Id,RecordTypeId,CMPL123CME__Author_Country__c,CMPL123CME__Initial_Reporter_Country__c,CMPL123CME__Manufact_Country__c,CMPL123CME__Submitter_Country__c,CMPL123CME__Nomenclature_text__c,CMPL123CME__Medical_Device_Terminology_7_3_1__c from CMPL123CME__EU_MIR__c where Id = :euMirTypeInit.Id Limit 1];
            if(mirInitial.RecordTypeId == recordType7_3_1){
                // Assert to check - MIR created is of recordtype 7_3_1
                System.assertEquals(mirInitial.RecordTypeId,recordType7_3_1);
                // Assert to check - 'CMPL123CME__Author_Country__c' has value 'US' transforms to new value as 'United States of America'
                System.assertEquals(mirInitial.CMPL123CME__Author_Country__c,'United States of America');
                // Assert to check - 'CMPL123CME__Initial_Reporter_Country__c' has value 'United Kingdom' transforms to new value as 'United Kingdom (excl. Northern Ireland)'
                System.assertEquals(mirInitial.CMPL123CME__Initial_Reporter_Country__c,'United Kingdom (excl. Northern Ireland)');
                // Assert to check - 'CMPL123CME__Manufact_Country__c' has value 'USA' transforms to new value as 'United States of America'
                System.assertEquals(mirInitial.CMPL123CME__Manufact_Country__c,'United States of America');    
                // Assert to check - 'CMPL123CME__Submitter_Country__c' has value 'United States' transforms to new value as 'United States of America'
                System.assertEquals(mirInitial.CMPL123CME__Submitter_Country__c,'United States of America'); 
            }
            
            //Below is to check update scenario
            Id complaintId2 = [Select Id from CMPL123CME__Complaint__c where Id !=: complaint.Id  LIMIT 1].Id;
            CMPL123CME__EU_MIR__c mir = [SELECT Id, Follow_Up_Required__c,CMPL123_WF_Status__c,Action_on_Follow_Up_Awareness_Date__c,New_Followup_Awareness_Date__c,CMPL123CME__Expected_Date_Of_Next_Report__c,Committed_Report_Change_Rationale__c,Committed_Report_date__c,CMPL123CME__Initial_Reporter_Country__c FROM CMPL123CME__EU_MIR__c WHERE CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Initial_Report  AND ID = : mirInitial.Id LIMIT 1];            
            mir.CMPL123_WF_Status__c = AspenConstants.STR_WF_Pending_Regulatory;
            mir.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Submit_To_Regulatory;
            mir.CMPL123CME__Expected_Date_Of_Next_Report__c = System.today();
            mir.Committed_Report_Change_Rationale__c = 'Cuz I can';
            mir.New_Followup_Awareness_Date__c = System.today();
            mir.Action_on_Follow_Up_Awareness_Date__c = 'Set Date';
            mir.Committed_Report_date__c = mir.CMPL123CME__Expected_Date_Of_Next_Report__c;
            mir.CMPL123CME__Preliminary_Results_And_Conclusions__c = 'Test Data';
            mir.CMPL123CME__Complaint__c = complaintId2;
            update mir;
            if(mirInitial.RecordTypeId == recordType7_3_1){
                // Assert to check - 'CMPL123CME__Initial_Reporter_Country__c' has value 'United Kingdom' transforms to new value as 'United Kingdom (excl. Northern Ireland)'
                System.assertEquals(mirInitial.CMPL123CME__Initial_Reporter_Country__c,'United Kingdom (excl. Northern Ireland)');  
            }
            Test.stopTest();  
        }
    }
    
    /*
    * @Method       : testMakeFollowUps7_3_1
    * @Description  : To test when Followup MIR is created all the field values are auto-populated from Initial MIR
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R7 - FRS-1515-24
    */
    @isTest
    public static void testMakeFollowUps7_3_1(){ 
        //Created the static resource with all the active countries to configure the test method for 7.3.1 record type of EUMIR object. 
        //List<String> countries = getNon721CountriesFromResource(); //R8 - Commented this line as this method is no more used
        Country__c country = [Select Id,Report_Type__c from Country__c where Report_Type__c = 'EUMIR' Limit 1];       
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c Limit 1];
        User adminUser = [Select id from User where Email='test2@gmail.com' Limit 1]; 
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = country.Id), true);

        CMPL123CME__Registered_Site__c registeredSite = [Select id from CMPL123CME__Registered_Site__c where CMPL123CME__Site_Name__c='Test Registered Site' Limit 1];
        CMPL123__Product__c product = [Select Id,Device_Description_Intended_purpose__c,Device_Nomenclature_Text__c,Device_Nomenclature_System__c from CMPL123__Product__c where Registered_Site__c = :registeredSite.Id Limit 1];
        Product_Ticket__c prodTckt =[Select Id from Product_Ticket__c where Event_Ticket__c = :complaint.Id Limit 1];            
        CMPL123CME__Questionnaire__c assessment = [Select Id,Receipt_Date__c,Initial_Awareness_Date__c,CMPL123_WF_Status__c from CMPL123CME__Questionnaire__c where  CMPL123CME__Complaint__c = :complaint.Id Limit 1];        
        User medEvalUser = [Select Id from User where Email= :MED_EVAL_EMAIL Limit 1];
        
        MirInitWrap mirInit = new MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = country.Id;
        mirInit.medicalEvaluatorId = medEvalUser.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        
        Test.startTest();
        Id recordType7_3_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_3_1') .getRecordTypeId();
        CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInit);
        euMirTypeInit.Country__c=country.Id;
        euMirTypeInit.Product_Type__c='IVDD/MDD';
        insert euMirTypeInit;
        
        CMPL123CME__EU_MIR__c mirInitial = [Select Id,RecordTypeId,RecordType.Name,CMPL123CME__Medical_Device_Terminology__c,CMPL123CME__Description_Of_Device_Nomenclature_Text__c,Initial_MIR__c,Parent_MIR__c,Product__c,CMPL123CME__Type_of_Report__c,CMPL123CME__General_Comments__c,Follow_Up_Required__c,CMPL123_WF_Status__c,CMPL123CME__Expected_Date_Of_Next_Report__c,Committed_Report_Change_Rationale__c,New_Followup_Awareness_Date__c,Action_on_Follow_Up_Awareness_Date__c,Committed_Report_date__c,CMPL123CME__Manufacturer_Awareness_Date__c,CMPL123CME__Mfr_Reportability_awareness_date__c,CMPL123CME__EUDAMED_ID_Of_PMCF_PMPF_Investigation__c,CMPL123CME__Description_of_dev_Nom_text_7_3_1__c,CMPL123CME__Nomenclature_text__c,CMPL123CME__Medical_Device_Terminology_7_3_1__c from CMPL123CME__EU_MIR__c where Id = :euMirTypeInit.Id Limit 1]; 
        mirInitial.CMPL123_WF_Status__c = AspenConstants.STR_Pending_Follow_Up_Creation;
        update mirInitial;    
        
        // Set fields which should cause a follow-up MIR to be created
        mirInitial.Follow_Up_Required__c = AspenConstants.STR_Yes;
        mirInitial.CMPL123CME__Expected_Date_Of_Next_Report__c = System.today();
        mirInitial.Committed_Report_Change_Rationale__c = 'Cuz I can';
        mirInitial.New_Followup_Awareness_Date__c = System.today();
        mirInitial.Action_on_Follow_Up_Awareness_Date__c = 'Set Date';
        mirInitial.Committed_Report_date__c = System.today(); 
        mirInitial.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;        
        // Only the medical evaluator can finalize an MIR
        System.runAs(medEvalUser) {
            update mirInitial;
        }  
        
        List<CMPL123CME__EU_MIR__c> newMirs = [SELECT Id,Parent_MIR__c,RecordTypeId,CMPL123CME__Medical_Device_Terminology__c,CMPL123CME__Medical_Device_Terminology_7_3_1__c,CMPL123CME__Description_Of_Device_Nomenclature_Text__c,CMPL123CME__Description_of_dev_Nom_text_7_3_1__c FROM CMPL123CME__EU_MIR__c WHERE Parent_MIR__c =: mirInitial.Id AND CMPL123CME__Type_of_Report__c =: AspenConstants.STR_Follow_Up_Report];
        System.assertEquals(1, newMirs.size());
        if(newMirs[0].RecordTypeId == recordType7_3_1){
            // Assert to check - 'CMPL123CME__Medical_Device_Terminology__c' field is blank as this field is removed from recordtype 7_3_1
            Assert.isNull(newMirs[0].CMPL123CME__Medical_Device_Terminology__c);
            // Assert to check - 'CMPL123CME__Description_Of_Device_Nomenclature_Text__c' field is blank as this field is removed from recordtype 7_3_1
            Assert.isNull(newMirs[0].CMPL123CME__Description_Of_Device_Nomenclature_Text__c);
            // Assert to check - MIR Followup created is of recordtype 7_3_1
            System.assertEquals(newMirs[0].RecordTypeId,recordType7_3_1);
            // Assert to check - 'CMPL123CME__Medical_Device_Terminology_7_3_1__c' field value on MIR Followup is auto populated from MIR Inital
            System.assertEquals(newMirs[0].CMPL123CME__Medical_Device_Terminology_7_3_1__c, mirInitial.CMPL123CME__Medical_Device_Terminology_7_3_1__c);
            // Assert to check - 'CMPL123CME__Description_of_dev_Nom_text_7_3_1__c' field value on MIR Followup is auto populated from MIR Inital
            System.assertEquals(newMirs[0].CMPL123CME__Description_of_dev_Nom_text_7_3_1__c, mirInitial.CMPL123CME__Description_of_dev_Nom_text_7_3_1__c);
        }
        Test.stopTest();        
    }

	/*
    * @Method       : getNon721CountriesFromResource
    * @Description  : Created test method to get all active countries for 7.3.1 record type of EUMIR object.
    * @Return       : List<String>
    * @Params       : N/A
    * @Release      : CHARM R7 - FRS-1515-24
    */
    //R8 - Commented below method as below static resource and custom metadata is no more used
   // @IsTest
    //private static List<Country__c> getNon721CountriesFromResource() {              
		/*StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = 'CountriesDataResource'];
        String csvContent = resource.Body.toString();
        List<String> activeCountries = csvContent.split('\n');*/

        //Commeneted as part of R8 as EU_MIR_7_2_1_Countries_List__mdt custom metadata is decommissioned
        /*List<EU_MIR_7_2_1_Countries_List__mdt> Countries_721 = [
            SELECT EU_MIR_Submission_Country__c FROM EU_MIR_7_2_1_Countries_List__mdt
        ];
        
        List<String> countriesList_721 = new List<String>();
        for (EU_MIR_7_2_1_Countries_List__mdt c_721 : Countries_721) {
            countriesList_721.add(c_721.EU_MIR_Submission_Country__c.toLowerCase());
        }
        List<String> countries = new List<String>();
        for (String c : activeCountries) {
            if (!countriesList_721.contains(c.toLowerCase())) {
                countries.add(c.trim());
            }
        }
        
        return countries;*/
        //return activeCountries;
    //}
    
    /*
    * @Method       : getCountriesFromResource
    * @Description  : Created test method to get countries data from static resource to create country records of different report types.
    * @Return       : List<Country__c>
    * @Params       : N/A
    * @Release      : CHARM R8 - FRS-1515-24
    */
    @IsTest
    private static List<Country__c> getCountriesFromResource() {        
        StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = 'CountriesNameReportTypes'];
        String csvContent = resource.Body.toString();
		// Remove Windows line breaks if any
		csvContent = csvContent.replace('\r', '');
        
		// Split into lines
		List<String> lines = csvContent.split('\n');
        
        List<Country__c> countriesToInsert = new List<Country__c>();
        
        for (Integer i = 1; i < lines.size(); i++) {
            List<String> cols = lines[i].split(',');
        
            Country__c c = new Country__c();
            c.Name = cols[0];
            c.Report_Type__c = cols[1];
            countriesToInsert.add(c);
        }
    	return countriesToInsert;
    }
    
    
    /*
    * @Method       : testPopulateMIRDefaultValuesGBMIR
    * @Description  : To test when GB MIR is created all the default field values related to GB MIR recordtype are auto-populated from 'Auto Populate MIR Fields' custom metadata
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R8 - FRS-1515-24
    */
    @isTest
    public static void testPopulateMIRDefaultValuesGBMIR(){  
        Country__c country = [Select Id,Report_Type__c from Country__c where Report_Type__c = 'GB MIR' Limit 1];
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c Limit 1];        
        User adminUser = [Select id from User where Email='test2@gmail.com' Limit 1];          
        CMPL123CME__Registered_Site__c registeredSite = [Select id from CMPL123CME__Registered_Site__c where CMPL123CME__Site_Name__c='Test Registered Site' Limit 1];
        CMPL123__Product__c product = [Select Id,Device_Nomenclature_System__c,Device_Nomenclature_Text__c from CMPL123__Product__c where Registered_Site__c = :registeredSite.Id Limit 1];  
        Product_Ticket__c prodTckt =[Select Id from Product_Ticket__c where Event_Ticket__c = :complaint.Id Limit 1];
        CMPL123CME__Questionnaire__c assessment = [Select id,Initial_Awareness_Date__c from CMPL123CME__Questionnaire__c where  CMPL123CME__Complaint__c = :complaint.Id Limit 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = country.Id), true);
        User medEvalUser = [Select id from User where Email= :MED_EVAL_EMAIL Limit 1];
        
        MirInitWrap mirInit = new MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = country.Id;
        mirInit.medicalEvaluatorId = medEvalUser.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        
        System.runAs(medEvalUser){
            Test.startTest();
            Id recordType_GB_7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('GB_MIR_7_2_1') .getRecordTypeId();	
            CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInit);
            euMirTypeInit.Country__c=country.Id;
            insert euMirTypeInit;
            
            CMPL123CME__EU_MIR__c mirInitial = [Select Id,RecordTypeId,CMPL123CME__UDI_Issuing_entity__c,CMPL123CME__Submitter_Of_Report__c,CMPL123CME__Specify_Other_Submitter__c from CMPL123CME__EU_MIR__c where Id = :euMirTypeInit.Id Limit 1];  
            List<Auto_Populate_MIR_Fields__mdt> mirPopulationList = [Select MIR_Field__c,Default_Value__c,MIR_Record_Type__c from Auto_Populate_MIR_Fields__mdt where MIR_Record_Type__c = 'GB_MIR_7_2_1'];
   
            if(mirInitial.RecordTypeId == recordType_GB_7_2_1 && mirPopulationList.size()>0){
                Map<String,String> mirPopulationMap = new Map<String,String>();
                for(Auto_Populate_MIR_Fields__mdt mirValue : mirPopulationList){
                    mirPopulationMap.put(mirValue.MIR_Field__c,mirValue.Default_Value__c);
                }               
                // Assert to check - MIR created is of recordtype GB MIR 7_2_1
                System.assertEquals(mirInitial.RecordTypeId,recordType_GB_7_2_1);
                // Assert to check - 'CMPL123CME__UDI_Issuing_entity__c' field on GB MIR is auto populated from 'Auto Populate MIR Fields' custom metadata
                System.assertEquals(mirInitial.CMPL123CME__UDI_Issuing_entity__c,mirPopulationMap.get('CMPL123CME__UDI_Issuing_entity__c'));
                // Assert to check - 'CMPL123CME__Submitter_Of_Report__c' field on GB MIR is auto populated from 'Auto Populate MIR Fields' custom metadata
                System.assertEquals(mirInitial.CMPL123CME__Submitter_Of_Report__c,mirPopulationMap.get('CMPL123CME__Submitter_Of_Report__c'));
                // Assert to check - 'CMPL123CME__Specify_Other_Submitter__c' field on GB MIR is auto populated from 'Auto Populate MIR Fields' custom metadata
                System.assertEquals(mirInitial.CMPL123CME__Specify_Other_Submitter__c,mirPopulationMap.get('CMPL123CME__Specify_Other_Submitter__c'));
            }
            Test.stopTest(); 
        } 
    }
    
    /*
    * @Method       : testPopulateMIRDefaultValuesMIR731
    * @Description  : To test when EU MIR 7_3_1 is created all the default field values related to EU MIR 7_3_1 recordtype are auto-populated from 'Auto Populate MIR Fields' custom metadata
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM R8 - FRS-1515-24
    */
    @isTest
    public static void testPopulateMIRDefaultValuesMIR731(){ 
        Country__c country = [Select Id,Report_Type__c from Country__c where Report_Type__c = 'EUMIR' Limit 1];  
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c Limit 1];        
        User adminUser = [Select id from User where Email='test2@gmail.com' Limit 1];         
        CMPL123CME__Registered_Site__c registeredSite = [Select id from CMPL123CME__Registered_Site__c where CMPL123CME__Site_Name__c='Test Registered Site' Limit 1];
        CMPL123__Product__c product = [Select Id,Device_Nomenclature_System__c,Device_Nomenclature_Text__c from CMPL123__Product__c where Registered_Site__c = :registeredSite.Id Limit 1];  
        Product_Ticket__c prodTckt =[Select Id from Product_Ticket__c where Event_Ticket__c = :complaint.Id Limit 1];
        CMPL123CME__Questionnaire__c assessment = [Select id,Initial_Awareness_Date__c from CMPL123CME__Questionnaire__c where  CMPL123CME__Complaint__c = :complaint.Id Limit 1];
        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) 
                TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = country.Id), true);
        User medEvalUser = [Select id from User where Email= :MED_EVAL_EMAIL Limit 1];
        
        MirInitWrap mirInit = new MirInitWrap();
        mirInit.complaintId = complaint.Id;
        mirInit.countryId = country.Id;
        mirInit.medicalEvaluatorId = medEvalUser.Id;
        mirInit.assessmentId = assessment.Id;
        mirInit.productTicketId = prodTckt.Id;
        mirInit.submissionTypeId = objCountrySubmissionType.Id;
        mirInit.regSiteId = registeredSite.Id;
        
        System.runAs(medEvalUser){
            Test.startTest();
            Id recordType_MIR_7_3_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_3_1') .getRecordTypeId();	
            CMPL123CME__EU_MIR__c euMirTypeInit = makeEuMirInitial(mirInit);
            euMirTypeInit.Country__c=country.Id;
            insert euMirTypeInit;
            
            CMPL123CME__EU_MIR__c mirInitial = [Select Id,RecordTypeId,CMPL123CME__Basic_Issuing_Entity__c,CMPL123CME__Does_the_device_fulfil_any_cases__c,CMPL123CME__PMCF_PMPF_investigation_incident__c,CMPL123CME__Master_Issuing_Entity__c,CMPL123CME__Unit_Issuing_Entity__c from CMPL123CME__EU_MIR__c where Id = :euMirTypeInit.Id Limit 1];  
            List<Auto_Populate_MIR_Fields__mdt> mirPopulationList = [Select MIR_Field__c,Default_Value__c,MIR_Record_Type__c from Auto_Populate_MIR_Fields__mdt where MIR_Record_Type__c = 'V7_3_1'];
   
            if(mirInitial.RecordTypeId == recordType_MIR_7_3_1 && mirPopulationList.size()>0){
                Map<String,String> mirPopulationMap = new Map<String,String>();
                for(Auto_Populate_MIR_Fields__mdt mirValue : mirPopulationList){
                    mirPopulationMap.put(mirValue.MIR_Field__c,mirValue.Default_Value__c);
                }   
                // Assert to check - MIR created is of recordtype EU MIR 7_3_1
                System.assertEquals(mirInitial.RecordTypeId,recordType_MIR_7_3_1);
                // Assert to check - 'CMPL123CME__Basic_Issuing_Entity__c' field on EU MIR 7_3_1 is auto populated from 'Auto Populate MIR Fields' custom metadata
                System.assertEquals(mirInitial.CMPL123CME__Basic_Issuing_Entity__c,mirPopulationMap.get('CMPL123CME__Basic_Issuing_Entity__c'));
                // Assert to check - 'CMPL123CME__Does_the_device_fulfil_any_cases__c' field on EU MIR 7_3_1 is auto populated from 'Auto Populate MIR Fields' custom metadata
                System.assertEquals(mirInitial.CMPL123CME__Does_the_device_fulfil_any_cases__c,mirPopulationMap.get('CMPL123CME__Does_the_device_fulfil_any_cases__c'));
                // Assert to check - 'CMPL123CME__PMCF_PMPF_investigation_incident__c' field on EU MIR 7_3_1 is auto populated from 'Auto Populate MIR Fields' custom metadata
                System.assertEquals(mirInitial.CMPL123CME__PMCF_PMPF_investigation_incident__c,mirPopulationMap.get('CMPL123CME__PMCF_PMPF_investigation_incident__c'));
                // Assert to check - 'CMPL123CME__Master_Issuing_Entity__c' field on EU MIR 7_3_1 is auto populated from 'Auto Populate MIR Fields' custom metadata
                System.assertEquals(mirInitial.CMPL123CME__Master_Issuing_Entity__c,mirPopulationMap.get('CMPL123CME__Master_Issuing_Entity__c'));
                // Assert to check - 'CMPL123CME__Unit_Issuing_Entity__c' field on EU MIR 7_3_1 is auto populated from 'Auto Populate MIR Fields' custom metadata
                System.assertEquals(mirInitial.CMPL123CME__Unit_Issuing_Entity__c,mirPopulationMap.get('CMPL123CME__Unit_Issuing_Entity__c'));
            }
            Test.stopTest(); 
        } 
    }
}