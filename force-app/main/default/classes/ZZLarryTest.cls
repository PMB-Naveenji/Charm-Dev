/**
 * This test class verifies that auditing works even though the MedEval trigger looks like it bypasses it.
 * The MedEval trigger is CMPL123CME_Questionnaire_AuditTrigger.
 * The bypass refers to the creation and processing of variable isWeightOrScoreChanged.
 * 
 * This test runs the Process Builder called "Update Deficiency Adverse Event on MedEval"
 * 
 * This test class can be ran just like any other Apex test class.
 * @author R3.1, Larry Resnik
 */
@IsTest
class ZZLarryTest {
    private static final String DEFICIENCY = 'Deficiency';
    private static final List<String> QUESTIONS = new List<String>{
        SYSTEM.Label.ADDS3_pRE_DT_Q1,
        SYSTEM.Label.ADDS3_pRE_DT_Q2,
        SYSTEM.Label.ADDS3_Deficiency_DT_Q1,
        SYSTEM.Label.ADDS3_pRE_DT_Q2a,
        SYSTEM.Label.ADDS3_pRE_DT_Q3,
        SYSTEM.Label.ADDS3_pRE_DT_Q3a,
        SYSTEM.Label.ADDS3_pRE_DT_Q5
    };
    // These fields were obtained by looking at the CMPL123__AuditTrail_Config__c
    // in AspenVal whose Name was 'CMPL123CME__Questionnaire__c'
    private static final List<String> AUDITED_MEDEVAL_FIELDS = new List<String>{
        'Adverse_Event__c',
        'Agency__c',
        'Assessment_Due_date__c',
        'Assessment_Start_Date__c',
        'Assigned_Date__c',
        'B1_Adverse_Event_Product_Problem__c',
        'B2_Date_of_Death__c',
        'B2_Outcomes_attributed_to_AE__c',
        'Closed_By__c',
        'Closed_On__c',
        'Describe_Event_or_Problem__c',
        'Final_Mfg_Analysis__c',
        'H9_Correction_Removal_report_No__c',
        'Initial_Awareness_Date__c',
        'Initial_Follow_Up_Mfg_Analysis__c',
        'KI_Log_Flag__c',
        'MDI_12_Comments__c',
        'Medical_Evaluation_Comments__c',
        'Not_Reportable_By__c',
        'Not_Reportable_On__c',
        'Patient_Outcome__c',
        'Product_List_Number_2__c',
        'Product_List_Number__c',
        'Promoted_On__c',
        'Reopened_By__c',
        'Reopened_On__c',
        'Reportability_Category__c',
        'Reportability_Rationale__c',
        'Reportability__c',
        'Reportable_By__c',
        'Reportable_On__c',
        'Submission_Created__c',
        'Submission_Date_2__c',
        'Submission_Date__c',
        'Submission_Source_2__c',
        'Submission_Source__c',
        'Submitted_Date__c',
        'TPM_Responsible_By__c',
        'TPM_Responsible_On__c',
        'Targeted_Assessment_No_of_Days__c',
        'Voided_By__c',
        'Voided_On__c'
    };

    @TestSetup
    static void makeData(){
        TestDataFactory.createSObject(
        new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = String.join(AUDITED_MEDEVAL_FIELDS, ','),
            CMPL123__Is_Active__c = true,
            Name = 'CMPL123CME__Questionnaire__c'
        ), true);
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c)
            TestDataFactory.createSObject(new CMPL123CME__Complaint__c(), true);
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c)
        TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            CMPL123CME__Complaint__c = complaint.Id,
            Deficiency_to_an_adverse_event__c = false
        ), true);
        insert makeQuestionnaireItemListForSetup(questionnaire);
    }

    private static List<CMPL123CME__Questionnaire_Items__c> makeQuestionnaireItemListForSetup(
        CMPL123CME__Questionnaire__c questionnaire)
    {
        List<CMPL123CME__Questionnaire_Items__c> qItemList = new List<CMPL123CME__Questionnaire_Items__c>();
        for (String question : QUESTIONS) {
            Boolean isFlowActivator = question == System.Label.ADDS3_pRE_DT_Q2a;
            String parentKeyValue = DEFICIENCY;
            String answer = AspenConstants.STR_No;
            if (isFlowActivator) {
                parentKeyValue = null;
                answer = AspenConstants.STR_Yes;
            }

            qItemList.add(new CMPL123CME__Questionnaire_Items__c(
                CMPL123CME__Questionnaire__c = questionnaire.Id,
                CMPL123CME__Question__c = question,
                CMPL123CME__Weight__c = 1,
                CMPL123CME__Parent_Key_Value__c = parentKeyValue,
                CMPL123CME__Answer__c = answer
            ));
        }
        return qItemList;
    }

    /**
     * Gets the Questionnaire Item which can cause the Process Builder flow to run.
     * 
     * There are multiple Questions that a Questionnaire Item could have, but
     * only one specific Question meets the criteria to run the flow
     * "Update Deficiency Adverse Event on MedEval"
     */
    private static CMPL123CME__Questionnaire_Items__c getSetupQuestionnaireItemForFlow() {
        CMPL123CME__Questionnaire_Items__c qItem;
        for (CMPL123CME__Questionnaire_Items__c tempItem : [
            SELECT Id,
            CMPL123CME__Question__c,
            CMPL123CME__Answer__c,
            CMPL123CME__Questionnaire__r.Deficiency_to_an_adverse_event__c
            FROM CMPL123CME__Questionnaire_Items__c
            WHERE CMPL123CME__Answer__c = :AspenConstants.STR_No
        ]) {
            if (tempItem.CMPL123CME__Question__c == System.Label.ADDS3_Deficiency_DT_Q1) {
                qItem = tempItem;
                break;
            }
        }
        Assert.areEqual(
            'Did this confirmed malfunction (deficiency) cause/contribute to an adverse event?',
            qItem.CMPL123CME__Question__c,
            'Setup bug: Fetched the wrong Questionnaire Item');
        Assert.areNotEqual(true, qItem.CMPL123CME__Questionnaire__r.Deficiency_to_an_adverse_event__c,
            'Setup bug: This field needs to be not-true');
        return qItem;
    }

    private static CMPL123CME__Questionnaire__c getSetupMedEval(Id medEvalId) {
        return [SELECT Id,
            Adverse_Event__c,
            Agency__c,
            Assessment_Due_date__c,
            Assessment_Start_Date__c,
            Assigned_Date__c,
            B1_Adverse_Event_Product_Problem__c,
            B2_Date_of_Death__c,
            B2_Outcomes_attributed_to_AE__c,
            Closed_By__c,
            Closed_On__c,
            Describe_Event_or_Problem__c,
            Final_Mfg_Analysis__c,
            H9_Correction_Removal_report_No__c,
            Initial_Awareness_Date__c,
            Initial_Follow_Up_Mfg_Analysis__c,
            KI_Log_Flag__c,
            MDI_12_Comments__c,
            Medical_Evaluation_Comments__c,
            Not_Reportable_By__c,
            Not_Reportable_On__c,
            Patient_Outcome__c,
            Product_List_Number_2__c,
            Product_List_Number__c,
            Promoted_On__c,
            Reopened_By__c,
            Reopened_On__c,
            Reportability_Category__c,
            Reportability_Rationale__c,
            Reportability__c,
            Reportable_By__c,
            Reportable_On__c,
            Submission_Created__c,
            Submission_Date_2__c,
            Submission_Date__c,
            Submission_Source_2__c,
            Submission_Source__c,
            Submitted_Date__c,
            TPM_Responsible_By__c,
            TPM_Responsible_On__c,
            Targeted_Assessment_No_of_Days__c,
            Voided_By__c,
            Voided_On__c
            FROM CMPL123CME__Questionnaire__c
            WHERE Id = :medEvalId
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
     * Verifies that changing a MedEval's Total Score will not bypass auditing
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testChangeTotalScoreDoesNotBypassAudit() {
        final String ERROR_NO_AUDIT_TRAIL_ENTRY = TestUtil.ERROR_POS +
            'Even though an audited field was changed, it did not make an audit trail entry';
        CMPL123CME__Questionnaire_Items__c qItem = getSetupQuestionnaireItemForFlow();
        Map<Id, CMPL123__Audit_Trail_Entry__c> auditTrailEntriesBeforeIdToRecord =
            new Map<Id, CMPL123__Audit_Trail_Entry__c>([
                SELECT Id, CMPL123__Audit_Trail_JSON__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :qItem.CMPL123CME__Questionnaire__c
            ]);
        CMPL123CME__Questionnaire__c medEvalBefore = getSetupMedEval(qItem.CMPL123CME__Questionnaire__c);

        Test.startTest();
        qItem.CMPL123CME__Answer__c = AspenConstants.STR_Yes;
        update qItem;
        Test.stopTest();

        qItem = [
            SELECT Id,
            CMPL123CME__Questionnaire__r.Deficiency_to_an_adverse_event__c
            FROM CMPL123CME__Questionnaire_Items__c
            WHERE Id = :qItem.Id
            LIMIT 1
        ];
        Assert.isTrue(qItem.CMPL123CME__Questionnaire__r.Deficiency_to_an_adverse_event__c,
            'Setup bug?: Process did not run');

        // Test Audit Trail Entry creation
        List<CMPL123__Audit_Trail_Entry__c> auditTrailEntriesAfter = [
            SELECT Id, CMPL123__Audit_Trail_JSON__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :qItem.CMPL123CME__Questionnaire__c
            ORDER BY CreatedDate ASC
        ];
        for (CMPL123__Audit_Trail_Entry__c entry : auditTrailEntriesAfter) {
            System.debug('Printing an audit trail entry');
            mDebugUntruncated(entry.CMPL123__Audit_Trail_JSON__c);
        }
        Assert.areNotEqual(auditTrailEntriesAfter.size(), auditTrailEntriesBeforeIdToRecord.size(),
            'Pos test failure: Should have created new audit trail entries. ' +
            'This might mean that the auditing was bypassed which would be bad. ' +
            'This might mean that no audited fields were changed which could be good or inconclusive. ' +
            'Look at what fields were changed and verify if they are defined in ' +
            'the CMPL123__AuditTrail_Config__c record. Auditing happens if-and-only-if ' +
            'the field was defined in that record, and the field was changed.');

        // Test every field for whether or not it should have been audited
        String newestAuditTrailEntryJson;
        {
            CMPL123__Audit_Trail_Entry__c newestAuditTrailEntry =
                auditTrailEntriesAfter.get(auditTrailEntriesAfter.size() - 1);
            newestAuditTrailEntryJson = newestAuditTrailEntry.CMPL123__Audit_Trail_JSON__c.toLowerCase();
        }
        CMPL123CME__Questionnaire__c medEvalAfter = getSetupMedEval(qItem.CMPL123CME__Questionnaire__c);
        for (String fieldApiName : AUDITED_MEDEVAL_FIELDS) {
            Boolean isFieldChanged = medEvalBefore.get(fieldApiName) != medEvalAfter.get(fieldApiName);
            Boolean isAuditTrailEntryMade = newestAuditTrailEntryJson.indexOf(fieldApiName.toLowerCase()) > -1;
            if (isFieldChanged) {
                Assert.isTrue(isAuditTrailEntryMade, 'SHOULD have made an audit trail entry for ' + fieldApiName);
            } else {
                Assert.isFalse(isAuditTrailEntryMade, 'Should NOT have made an audit trail entry for ' + fieldApiName);
            }
        }
    }
}