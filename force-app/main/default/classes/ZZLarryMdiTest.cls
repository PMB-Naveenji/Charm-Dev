/**
 * This test class verifies that auditing works when an MDI is triggered from a MedEval.
 * The MDI trigger is CMPL123CME_MEDDEV_AuditTrigger.
 * The auditing is bypassed based on the variable isDueDateChanged.
 * 
 * This test runs the Process Builder called "Set Follow-up Submission Dates"
 * 
 * This test class can be ran just like any other Apex test class.
 * @author R3.1, Larry Resnik
 */
@isTest
public with sharing class ZZLarryMdiTest {
    private static final String MDI_REPORT_TYPE_FOLLOWUP = 'Follow-up report';
    // These fields were obtained by looking at the CMPL123__AuditTrail_Config__c
    // in AspenVal whose Name was 'CMPL123CME__MEDDEV__c'
    private static final List<String> AUDITED_MDI_FIELDS = new List<String>{
        'CMPL123CME__Accessories__c',
        'CMPL123CME__Address_of_National_Competent_Authority__c',
        'CMPL123CME__AuthorisedRepresentativeCountry__c',
        'CMPL123CME__Authorised_Representative_Address__c',
        'CMPL123CME__Authorised_Representative_City__c',
        'CMPL123CME__Authorised_Representative_Contact__c',
        'CMPL123CME__Authorised_Representative_Email__c',
        'CMPL123CME__Authorised_Representative_Fax__c',
        'CMPL123CME__Authorised_Representative_Name__c',
        'CMPL123CME__Authorised_Representative_Phone__c',
        'CMPL123CME__Authorised_Representative_Postal_Code__c',
        'CMPL123CME__Catalogue_Number__c',
        'CMPL123CME__Classification_of_Incident__c',
        'CMPL123CME__Comments__c',
        'CMPL123CME__Commercial_Name__c',
        'CMPL123CME__Contact_Person_in_Facility__c',
        'CMPL123CME__Countries_list__c',
        'CMPL123CME__Device_Expiry_Date__c',
        'CMPL123CME__Device_Mfr_Date__c',
        'CMPL123CME__Duration_of_Implantation__c',
        'CMPL123CME__Expected_Date_of_Next_Report__c',
        'CMPL123CME__Explant_Date__c',
        'CMPL123CME__Final_Comments_of_Manufacturer__c',
        'CMPL123CME__Further_Investigations__c',
        'CMPL123CME__Gender__c',
        'CMPL123CME__HealthCare_Address__c',
        'CMPL123CME__HealthCare_City__c',
        'CMPL123CME__HealthCare_Email__c',
        'CMPL123CME__HealthCare_Fax__c',
        'CMPL123CME__HealthCare_Phone__c',
        'CMPL123CME__HealthCare_Postal_Code__c',
        'CMPL123CME__HealthcareCountry__c',
        'CMPL123CME__If_device_operator_is_others_specify__c',
        'CMPL123CME__If_status_of_submitter_is_others_specify__c',
        'CMPL123CME__If_yes_state_report_ref_and_countries_LT__c',
        'CMPL123CME__Implant_Date__c',
        'CMPL123CME__Incident_Date__c',
        'CMPL123CME__Incident_Description_Narrative__c',
        'CMPL123CME__Initial_Corrective_Preventive_Actions__c',
        'CMPL123CME__Lot_Numbers__c',
        'CMPL123CME__ManufacturerCountry__c',
        'CMPL123CME__Manufacturer_Address__c',
        'CMPL123CME__Manufacturer_Awareness_Date__c',
        'CMPL123CME__Manufacturer_City__c',
        'CMPL123CME__Manufacturer_Contact__c',
        'CMPL123CME__Manufacturer_Device_Analysis_Results__c',
        'CMPL123CME__Manufacturer_Disclaimer__c',
        'CMPL123CME__Manufacturer_Email__c',
        'CMPL123CME__Manufacturer_Fax__c',
        'CMPL123CME__Manufacturer_Name__c',
        'CMPL123CME__Manufacturer_Phone__c',
        'CMPL123CME__Manufacturer_Postal_code__c',
        'CMPL123CME__Manufacturer_Preliminary_Analysis__c',
        'CMPL123CME__Manufacturer_Reference_Number__c',
        'CMPL123CME__Manufacturer_Remedial_Action__c',
        'CMPL123CME__Medical_Device_Class__c',
        'CMPL123CME__Medical_Device_Current_Location__c',
        'CMPL123CME__Medical_Device_Distributed_Countries__c',
        'CMPL123CME__Medical_Device_Operator_During_Incident__c',
        'CMPL123CME__Model_Number__c',
        'CMPL123CME__NCA_Reference_Number__c',
        'CMPL123CME__Name_of_Healthcare_Facility__c',
        'CMPL123CME__NomenclatureSystem_preferable_GMDN__c',
        'CMPL123CME__Nomenclature_Code__c',
        'CMPL123CME__Nomenclature_Text__c',
        'CMPL123CME__Notified_Body_ID_Number__c',
        'CMPL123CME__Number_of_similarIncidents__c',
        'CMPL123CME__Numberof_Medical_Devices_Involved__c',
        'CMPL123CME__Numberof_patients_involved__c',
        'CMPL123CME__Other_Countries__c',
        'CMPL123CME__Other_NCA__c',
        'CMPL123CME__Patient_Outcome__c',
        'CMPL123CME__Patient_Weight__c',
        'CMPL123CME__Patient_age__c',
        'CMPL123CME__Recipient_Name_of_NCA__c',
        'CMPL123CME__Remedial_Action__c',
        'CMPL123CME__Report_Date__c',
        'CMPL123CME__Scheduled_Time_for_Identified_Actions__c',
        'CMPL123CME__Serial_Numbers__c',
        'CMPL123CME__Serious_Public_Threat__c',
        'CMPL123CME__Software_Version__c',
        'CMPL123CME__Status_of_Submitter__c',
        'CMPL123CME__SubmitterCountry__c',
        'CMPL123CME__Submitter_Address__c',
        'CMPL123CME__Submitter_City__c',
        'CMPL123CME__Submitter_Contact__c',
        'CMPL123CME__Submitter_Email__c',
        'CMPL123CME__Submitter_Fax__c',
        'CMPL123CME__Submitter_Name__c',
        'CMPL123CME__Submitter_Phone__c',
        'CMPL123CME__Submitter_Postal_Code__c',
        'CMPL123CME__Type_of_Report__c',
        'CMPL123CME__Usage_of_Medical_Device__c',
        'CMPL123CME__User_Facility_Report_Reference__c',
        'CMPL123CME__Whether_Manufacturer_Aware__c',
        'CMPL123_WF_Action__c',
        'CMPL123_WF_Status__c',
        'Committed_Next_Report_Change_Rationale__c',
        'Committed_Next_Report_date__c',
        'Complete_Regulatory_Response_By__c',
        'Complete_Regulatory_Response_Date__c',
        'Follow_Up_Required__c',
        'Manufacturing_Site__c',
        'Submission_Due_Date__c',
        'Submit_to_Regulatory_By__c',
        'Submit_to_Regulatory_Date__c',
        'Waived_Rationale__c'
    };
    private static final String AUDITED_MDI_CHILD_RELATIONS =
        'Attachment__c-MEDDEV__c,CMPL123CME__MEDDEV__c-Initial_MDI__c,Regulatory_Task__c-MDI__c';
    private static final String AUDITED_MDI_PARENT_RELATIONS =
        'CMPL123CME__Complaint__r,Regulatory_Evaluator__r,Product__r,Registered_Site__r,Country__r,Submission_Type__r,CMPL123_WF_Action_Performed_By__r';

    @TestSetup
    static void makeData(){
        TestDataFactory.createSObject(
        new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = String.join(AUDITED_MDI_FIELDS, ','),
            CMPL123__Is_Active__c = true,
            Name = 'CMPL123CME__MEDDEV__c',
            CMPL123__Child_Relationships_Object__c = AUDITED_MDI_CHILD_RELATIONS,
            CMPL123__Parent_Relationship_Object__c = AUDITED_MDI_PARENT_RELATIONS
        ), true);

        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c)
            TestDataFactory.createSObject(new CMPL123CME__Complaint__c(), true);

        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c)
        TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            CMPL123CME__Complaint__c = complaint.Id,
            CMPL123_WF_Status__c = AspenConstants.STR_Regulatory,
            Reportability__c = AspenConstants.REPORTABILITY_NO,
            Reportability_Category__c = 'RCML',
            Reportability_Rationale__c = 'Because the refridgerator ran away'
        ), true);

        CMPL123CME__MEDDEV__c mdi = (CMPL123CME__MEDDEV__c)
        TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
            CMPL123CME__Complaint__c = complaint.Id,
            Medical_Evaluation__c = medEval.Id,
            CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
            CMPL123CME__Type_of_Report__c = MDI_REPORT_TYPE_FOLLOWUP
        ), true);
    }

    private static CMPL123CME__MEDDEV__c getMdiFromSetup() {
        return [
            SELECT Id,
            // Fields that need to be cloned
            CMPL123CME__Complaint__c,
            // Audited fields
            CMPL123CME__Accessories__c,
            CMPL123CME__Address_of_National_Competent_Authority__c,
            CMPL123CME__AuthorisedRepresentativeCountry__c,
            CMPL123CME__Authorised_Representative_Address__c,
            CMPL123CME__Authorised_Representative_City__c,
            CMPL123CME__Authorised_Representative_Contact__c,
            CMPL123CME__Authorised_Representative_Email__c,
            CMPL123CME__Authorised_Representative_Fax__c,
            CMPL123CME__Authorised_Representative_Name__c,
            CMPL123CME__Authorised_Representative_Phone__c,
            CMPL123CME__Authorised_Representative_Postal_Code__c,
            CMPL123CME__Catalogue_Number__c,
            CMPL123CME__Classification_of_Incident__c,
            CMPL123CME__Comments__c,
            CMPL123CME__Commercial_Name__c,
            CMPL123CME__Contact_Person_in_Facility__c,
            CMPL123CME__Countries_list__c,
            CMPL123CME__Device_Expiry_Date__c,
            CMPL123CME__Device_Mfr_Date__c,
            CMPL123CME__Duration_of_Implantation__c,
            CMPL123CME__Expected_Date_of_Next_Report__c,
            CMPL123CME__Explant_Date__c,
            CMPL123CME__Final_Comments_of_Manufacturer__c,
            CMPL123CME__Further_Investigations__c,
            CMPL123CME__Gender__c,
            CMPL123CME__HealthCare_Address__c,
            CMPL123CME__HealthCare_City__c,
            CMPL123CME__HealthCare_Email__c,
            CMPL123CME__HealthCare_Fax__c,
            CMPL123CME__HealthCare_Phone__c,
            CMPL123CME__HealthCare_Postal_Code__c,
            CMPL123CME__HealthcareCountry__c,
            CMPL123CME__If_device_operator_is_others_specify__c,
            CMPL123CME__If_status_of_submitter_is_others_specify__c,
            CMPL123CME__If_yes_state_report_ref_and_countries_LT__c,
            CMPL123CME__Implant_Date__c,
            CMPL123CME__Incident_Date__c,
            CMPL123CME__Incident_Description_Narrative__c,
            CMPL123CME__Initial_Corrective_Preventive_Actions__c,
            CMPL123CME__Lot_Numbers__c,
            CMPL123CME__ManufacturerCountry__c,
            CMPL123CME__Manufacturer_Address__c,
            CMPL123CME__Manufacturer_Awareness_Date__c,
            CMPL123CME__Manufacturer_City__c,
            CMPL123CME__Manufacturer_Contact__c,
            CMPL123CME__Manufacturer_Device_Analysis_Results__c,
            CMPL123CME__Manufacturer_Disclaimer__c,
            CMPL123CME__Manufacturer_Email__c,
            CMPL123CME__Manufacturer_Fax__c,
            CMPL123CME__Manufacturer_Name__c,
            CMPL123CME__Manufacturer_Phone__c,
            CMPL123CME__Manufacturer_Postal_code__c,
            CMPL123CME__Manufacturer_Preliminary_Analysis__c,
            CMPL123CME__Manufacturer_Reference_Number__c,
            CMPL123CME__Manufacturer_Remedial_Action__c,
            CMPL123CME__Medical_Device_Class__c,
            CMPL123CME__Medical_Device_Current_Location__c,
            CMPL123CME__Medical_Device_Distributed_Countries__c,
            CMPL123CME__Medical_Device_Operator_During_Incident__c,
            CMPL123CME__Model_Number__c,
            CMPL123CME__NCA_Reference_Number__c,
            CMPL123CME__Name_of_Healthcare_Facility__c,
            CMPL123CME__NomenclatureSystem_preferable_GMDN__c,
            CMPL123CME__Nomenclature_Code__c,
            CMPL123CME__Nomenclature_Text__c,
            CMPL123CME__Notified_Body_ID_Number__c,
            CMPL123CME__Number_of_similarIncidents__c,
            CMPL123CME__Numberof_Medical_Devices_Involved__c,
            CMPL123CME__Numberof_patients_involved__c,
            CMPL123CME__Other_Countries__c,
            CMPL123CME__Other_NCA__c,
            CMPL123CME__Patient_Outcome__c,
            CMPL123CME__Patient_Weight__c,
            CMPL123CME__Patient_age__c,
            CMPL123CME__Recipient_Name_of_NCA__c,
            CMPL123CME__Remedial_Action__c,
            CMPL123CME__Report_Date__c,
            CMPL123CME__Scheduled_Time_for_Identified_Actions__c,
            CMPL123CME__Serial_Numbers__c,
            CMPL123CME__Serious_Public_Threat__c,
            CMPL123CME__Software_Version__c,
            CMPL123CME__Status_of_Submitter__c,
            CMPL123CME__SubmitterCountry__c,
            CMPL123CME__Submitter_Address__c,
            CMPL123CME__Submitter_City__c,
            CMPL123CME__Submitter_Contact__c,
            CMPL123CME__Submitter_Email__c,
            CMPL123CME__Submitter_Fax__c,
            CMPL123CME__Submitter_Name__c,
            CMPL123CME__Submitter_Phone__c,
            CMPL123CME__Submitter_Postal_Code__c,
            CMPL123CME__Type_of_Report__c,
            CMPL123CME__Usage_of_Medical_Device__c,
            CMPL123CME__User_Facility_Report_Reference__c,
            CMPL123CME__Whether_Manufacturer_Aware__c,
            CMPL123_WF_Action__c,
            CMPL123_WF_Status__c,
            Committed_Next_Report_Change_Rationale__c,
            Committed_Next_Report_date__c,
            Complete_Regulatory_Response_By__c,
            Complete_Regulatory_Response_Date__c,
            Follow_Up_Required__c,
            Manufacturing_Site__c,
            Submission_Due_Date__c,
            Submit_to_Regulatory_By__c,
            Submit_to_Regulatory_Date__c,
            Waived_Rationale__c,
            // MedEval fields
            Medical_Evaluation__c,
            Medical_Evaluation__r.LastModifiedDate,
            Medical_Evaluation__r.Follow_Up_Awareness_Date__c,
            // System fields for assertions
            CreatedDate,
            LastModifiedDate
            FROM CMPL123CME__MEDDEV__c
            LIMIT 1
        ];
    }

    private static List<CMPL123__Audit_Trail_Entry__c> getAuditTrailEntries(Id parentId) {
        return [
            SELECT Id, CMPL123__Audit_Trail_JSON__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :parentId
        ];
    }

    /**
     * Modified from https://salesforce.stackexchange.com/questions/116502/console-log-truncates-my-debug
     */
    public static void mDebugUntruncated(String sMsg) {
        final Integer STEP = 250;
        for (Integer i = 0; i < sMsg.length(); i=i+STEP) {
            System.debug(sMsg.mid(i, STEP));
        }
    }

    /**
     * Pos test(s) for the Process Builder "Set Follow-up Submission Dates"
     * 
     * Verifies that changing a MedEval's "Follow-up Awareness Date" will
     * update a child MDI's "Date Due".
     * Also verifies that auditing was handled for the MDI.
     * 
     * In "Investigations of Audit Bypasses", it is MDI scenario two.
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testFlowSetFollowUpSubmissionDates() {
        CMPL123CME__MEDDEV__c mdiOld = getMdiFromSetup();
        CMPL123CME__Questionnaire__c parentMedEval = mdiOld.Medical_Evaluation__r;
        Assert.isNull(parentMedEval.Follow_Up_Awareness_Date__c,
            'Setup bug: This date must start out null');
        Datetime medEvalLastModifiedDateBefore = parentMedEval.LastModifiedDate;

        List<CMPL123__Audit_Trail_Entry__c> auditTrailEntriesBefore =
            getAuditTrailEntries(mdiOld.Id);

        Test.startTest();
        parentMedEval.Follow_Up_Awareness_Date__c = System.today();
        update parentMedEval;
        Test.stopTest();

        CMPL123CME__MEDDEV__c mdiNew = getMdiFromSetup();
        parentMedEval = mdiNew.Medical_Evaluation__r;
        Datetime medEvalLastModifiedDateAfter = parentMedEval.LastModifiedDate;
        Assert.areNotEqual(
            medEvalLastModifiedDateAfter,
            medEvalLastModifiedDateBefore,
            'Should have updated the MDI that the MedEval pointed to. ' +
            'Did the Process Builder flow not run?'
        );
        Date expectedDateDue = parentMedEval.Follow_Up_Awareness_Date__c + 30;
        Assert.areEqual(
            parentMedEval.Follow_Up_Awareness_Date__c + 30,
            mdiNew.Submission_Due_Date__c,
            TestUtil.ERROR_POS + 'The due date assigned from the Process Builder is incorrect'
        );

        List<CMPL123__Audit_Trail_Entry__c> auditTrailEntriesAfter =
            getAuditTrailEntries(mdiNew.Id);
        for (CMPL123__Audit_Trail_Entry__c entry : auditTrailEntriesAfter) {
            System.debug('Printing an audit trail entry');
            mDebugUntruncated(entry.CMPL123__Audit_Trail_JSON__c);
        }
        Boolean gotNewAuditTrailEntryRecord = auditTrailEntriesAfter.size() > auditTrailEntriesBefore.size();

        String newestAuditTrailEntryJson = '';
        if (gotNewAuditTrailEntryRecord) {
            CMPL123__Audit_Trail_Entry__c newestAuditTrailEntry =
                auditTrailEntriesAfter.get(auditTrailEntriesAfter.size() - 1);
            newestAuditTrailEntryJson = newestAuditTrailEntry.CMPL123__Audit_Trail_JSON__c.toLowerCase();
        }

        List<String> errors = new List<String>();
        Boolean shouldHaveMadeAuditTrailEntry = false;
        // Test every field for whether or not it should have been audited
        for (String fieldApiName : AUDITED_MDI_FIELDS) {
            Boolean isFieldChanged = mdiOld.get(fieldApiName) != mdiNew.get(fieldApiName);
            Boolean isFieldMentionedInAudit =
                newestAuditTrailEntryJson.indexOf(fieldApiName.toLowerCase()) > -1;
            if (isFieldChanged) {
                shouldHaveMadeAuditTrailEntry = true;
                if (!isFieldMentionedInAudit || !gotNewAuditTrailEntryRecord) {
                    errors.add('SHOULD have made an audit trail entry for ' + fieldApiName);
                }
            } else if (!isFieldChanged && isFieldMentionedInAudit) {
                errors.add('Should NOT have made an audit trail entry for ' + fieldApiName);
            }
        }

        if (shouldHaveMadeAuditTrailEntry && !gotNewAuditTrailEntryRecord) {
            errors.add(
                'Pos test failure: Should have created new audit trail entries. ' +
                'This might mean that the auditing was bypassed which would be bad. ' +
                'This might mean that no audited fields were changed which could be good or inconclusive. ' +
                'Look at what fields were changed and verify if they are defined in ' +
                'the CMPL123__AuditTrail_Config__c record. Auditing happens if-and-only-if ' +
                'the field was defined in that record, and the field was changed.'
            );
        }

        Assert.isTrue(errors.isEmpty(), String.join(errors, '; \n'));
    }

    /**
     * Verifies that inserting an MDI does not cause it to recursively update the same MDI.
     * 
     * In "Investigations of Audit Bypasses", it is MDI scenario three.
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testInsertMdiDoesNotAlsoCauseUpdate() {
        CMPL123CME__MEDDEV__c mdi = getMdiFromSetup().clone(false, true, false, false);

        Test.startTest();
        insert mdi;
        Test.stopTest();

        Assert.areEqual(mdi.CreatedDate, mdi.LastModifiedDate, 'Should only do one DML operation. ' +
            'If inserts are recursive, then they are at risk of activating the audit bypass');
    }

    /**
     * Pos test(s) for MedEval's updateEmdrMdiDueDateFields such that an MDI is affected
     * 
     * Verifies that changing a MedEval's "Follow-up Awareness Date" will
     * update a child MDI's "Date Due".
     * Also verifies that auditing was handled for the MDI.
     * 
     * In "Investigations of Audit Bypasses", it is MDI scenario five.
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateEmdrMdiDueDateFieldsForMdi() {
        CMPL123CME__MEDDEV__c mdiOld = getMdiFromSetup();
        CMPL123CME__Questionnaire__c parentMedEval = mdiOld.Medical_Evaluation__r;
        if (parentMedEval.Follow_Up_Awareness_Date__c == null) {
            parentMedEval.Follow_Up_Awareness_Date__c = System.today();
            // This should also update the MDI's "Date Due"
            update parentMedEval;

            mdiOld = getMdiFromSetup();
            Assert.isNotNull(mdiOld.Submission_Due_Date__c,
                'Unexpected bug: Is it ok that the MDI Date Due was not assigned after updating the MedEval?');

            mdiOld.Submission_Due_Date__c = null;
            update mdiOld;
            mdiOld = getMdiFromSetup();
            Assert.isNull(mdiOld.Submission_Due_Date__c,
                'Setup bug: The MDI Date Due must be null before the test execution');
        }
        Datetime medEvalLastModifiedDateBefore = parentMedEval.LastModifiedDate;

        CMPL123CME__MEDDEV__c thing = [SELECT Id, Submission_Due_Date__c, Medical_Evaluation__r.Initial_Awareness_Date__c,
            CMPL123CME__Type_of_Report__c, Medical_Evaluation__r.Follow_Up_Awareness_Date__c, Submission_Type__r.Calendar_Days__c
            FROM CMPL123CME__MEDDEV__c
            WHERE Medical_Evaluation__c = :mdiOld.Medical_Evaluation__c];
        Assert.isNotNull(thing);

        List<CMPL123__Audit_Trail_Entry__c> auditTrailEntriesBefore =
            getAuditTrailEntries(mdiOld.Id);

        Test.startTest();
        parentMedEval.Follow_Up_Awareness_Date__c += 1;
        update parentMedEval;
        Test.stopTest();

        CMPL123CME__MEDDEV__c mdiNew = getMdiFromSetup();
        parentMedEval = mdiNew.Medical_Evaluation__r;
        Datetime medEvalLastModifiedDateAfter = parentMedEval.LastModifiedDate;
        Assert.areNotEqual(
            medEvalLastModifiedDateAfter,
            medEvalLastModifiedDateBefore,
            'Should have updated the MDI that the MedEval pointed to. ' +
            'Did the Process Builder flow not run?'
        );
        Date expectedDateDue = parentMedEval.Follow_Up_Awareness_Date__c + 30;
        Assert.areEqual(
            parentMedEval.Follow_Up_Awareness_Date__c + 30,
            mdiNew.Submission_Due_Date__c,
            TestUtil.ERROR_POS + 'The due date assigned from the Process Builder is incorrect'
        );

        List<CMPL123__Audit_Trail_Entry__c> auditTrailEntriesAfter =
            getAuditTrailEntries(mdiNew.Id);
        for (CMPL123__Audit_Trail_Entry__c entry : auditTrailEntriesAfter) {
            System.debug('Printing an audit trail entry');
            mDebugUntruncated(entry.CMPL123__Audit_Trail_JSON__c);
        }
        Boolean gotNewAuditTrailEntryRecord = auditTrailEntriesAfter.size() > auditTrailEntriesBefore.size();

        String newestAuditTrailEntryJson = '';
        if (gotNewAuditTrailEntryRecord) {
            CMPL123__Audit_Trail_Entry__c newestAuditTrailEntry =
                auditTrailEntriesAfter.get(auditTrailEntriesAfter.size() - 1);
            newestAuditTrailEntryJson = newestAuditTrailEntry.CMPL123__Audit_Trail_JSON__c.toLowerCase();
        }

        List<String> errors = new List<String>();
        Boolean shouldHaveMadeAuditTrailEntry = false;
        // Test every field for whether or not it should have been audited
        for (String fieldApiName : AUDITED_MDI_FIELDS) {
            Boolean isFieldChanged = mdiOld.get(fieldApiName) != mdiNew.get(fieldApiName);
            Boolean isFieldMentionedInAudit =
                newestAuditTrailEntryJson.indexOf(fieldApiName.toLowerCase()) > -1;
            if (isFieldChanged) {
                shouldHaveMadeAuditTrailEntry = true;
                if (!isFieldMentionedInAudit || !gotNewAuditTrailEntryRecord) {
                    errors.add('SHOULD have made an audit trail entry for ' + fieldApiName);
                }
            } else if (!isFieldChanged && isFieldMentionedInAudit) {
                errors.add('Should NOT have made an audit trail entry for ' + fieldApiName);
            }
        }

        if (shouldHaveMadeAuditTrailEntry && !gotNewAuditTrailEntryRecord) {
            errors.add(
                'Pos test failure: Should have created new audit trail entries. ' +
                'This might mean that the auditing was bypassed which would be bad. ' +
                'This might mean that no audited fields were changed which could be good or inconclusive. ' +
                'Look at what fields were changed and verify if they are defined in ' +
                'the CMPL123__AuditTrail_Config__c record. Auditing happens if-and-only-if ' +
                'the field was defined in that record, and the field was changed.'
            );
        }

        Assert.isTrue(errors.isEmpty(), String.join(errors, '; \n'));
    }
}