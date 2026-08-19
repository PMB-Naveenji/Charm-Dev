/**
 * @why  : ADDTicketReviewTriggerHandlerTest class for Ticket_Review_AuditTrigger
 * @when : CreatedDate : 27-SEPTEMBER-2018
 * @what : Class to Handle Different scenarios from Ticket_Review_AuditTrigger
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID            Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oivan                   23-APR-2020             CHARM-2484 in scope of     Updated
 *                                                   CHARM-2400 (Defect #67)
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                   15-06-2020              Code Audit                 Updated Jira reference with reference from Defect Tracker.
 *                                                                              Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oivan                    06-JAN-2021            TWD Upgrade issue          Added Logic to test WF rules that are moved to apex
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oober                    20-JAN-2021            TWD Upgrade issue          In testWFlogic method changed assertion expected result from
 *                                                                              date.today() to datetime.now().dateGMT().
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik            23-FEB-2023             CHaRM R3.0, TWD upgrade    Fixed beforeUpdateTest to not crash. Presumably caused by
 *                                                                              TWD package upgrades.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public class ADDTicketReviewTriggerHandlerTest {
    private static final String MED_EVAL_EMAIL = 'medeval@test.com';

    /**
     * @author 23-FEB-2023 Larry Resnik
     */
    @TestSetup
    static void makeData() {
        // Names of Profiles
        final String PROFILE_SYSADMIN = 'System Administrator Data Loader';
        final String PROFILE_USER = 'Aspen User';
        // Names of Permission Sets
        final String PERMSET_MEDEVAL = 'Medical_Evaluator';

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

        // Create a User to act as a Medical Evaluator
        User medEvalUser = TestUtil.insertTestUser(profileNameToId.get(PROFILE_USER),
            MED_EVAL_EMAIL, 'test3@gmail.com' + System.currentTimeMillis(), 'Tran11');
        // This permission set is what gives them Medical Evaluator capabilities
        insert new PermissionSetAssignment(
            AssigneeId = medEvalUser.id,
            PermissionSetId = permSetNameToId.get(PERMSET_MEDEVAL)
        );
    }

    /**
    * @Method       :
    * @Description  :   To test the Ticket_Review_AuditTrigger functionality.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    public static void testADDS3LeveragedTaskListControllerHelper() {
        User userMedEval = [SELECT Id FROM User WHERE Email =: MED_EVAL_EMAIL];

        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
            new Country_Submission_Type__c(
                Name = '30 Days',
                Calendar_Days__c = 30,
                Country__c = objCountry.Id
            ), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaintRecord = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                Overall_Reportable_Status__c = 'Not Reportable'
            ), true);
        Ticket_Review__c ticketReviewRecord = (Ticket_Review__c) TestDataFactory.createSObject(
            new Ticket_Review__c(
                FA_CAPA_Short_Description__c = 'test',
                CAPA_Number__c = 'test',
                Parent_Awareness_Date__c = Date.newInstance(2018, 05, 12),
                Follow_Up_Awareness_Date__c = Date.newInstance(2018, 05, 11),
                Search_Frequency__c = 'Two Weeks (14 days)',
                Division__c = 'ADD',
                Status__c = 'Active',
                Medical_Assignee_Name__c = userMedEval.Id
            ), true);
        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Id EMDRAwaitingACK = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial - Awaiting ACK').getRecordTypeId();
        CMPL123CME__EMDR__c EMDRInitialRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                RecordTypeId = EMDRInitial,
                Ticket_Review__c = ticketReviewRecord.Id
            ), true);
        CMPL123CME__EMDR__c EMDRAwaitingACKRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                RecordTypeId = EMDRAwaitingACK,
                Ticket_Review__c = ticketReviewRecord.Id
            ), true);

        Date parentAwareness = Date.newInstance(2019, 05, 11);
        Date followUpAwareness = Date.newInstance(2019, 02, 13);
        ticketReviewRecord.Parent_Awareness_Date__c = parentAwareness;
        ticketReviewRecord.Follow_Up_Awareness_Date__c = followUpAwareness;
        update ticketReviewRecord;
        CMPL123CME__EMDR__c updateInitialEmdrResult = [
            SELECT CMPL123CME__MDR_Due_Date__c
            FROM CMPL123CME__EMDR__c
            WHERE Id = :EMDRInitialRecord.Id
        ];
        CMPL123CME__EMDR__c updateAwaitingACKEmdrResult = [
            SELECT CMPL123CME__MDR_Due_Date__c
            FROM CMPL123CME__EMDR__c
            WHERE Id = :EMDRAwaitingACKRecord.Id
        ];
        System.assertEquals(updateInitialEmdrResult.CMPL123CME__MDR_Due_Date__c, ticketReviewRecord.Parent_Awareness_Date__c);
        System.assertEquals(updateAwaitingACKEmdrResult.CMPL123CME__MDR_Due_Date__c, ticketReviewRecord.Follow_Up_Awareness_Date__c + 30);
        delete ticketReviewRecord;
        System.assert(0 == [SELECT COUNT() FROM Ticket_Review__c WHERE Id = :ticketReviewRecord.Id]);
    }

    /**
    * @Method       :
    * @Description  :   To test the Ticket_Review_AuditTrigger before update functionality. Defect #67 (CHARM-2484) test
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    public static void beforeUpdateTest() {
        User userMedEval = [SELECT Id FROM User WHERE Email =: MED_EVAL_EMAIL];
        Test.startTest();

        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
            new CMPL123__AuditTrail_Config__c(
                CMPL123__Fields__c = 'CAPA_Number__c,Division__c,FA_CAPA_Short_Description__c,Field_Action_Number__c,H10_Addtl_Mfg_Narrative__c,H9_Correction_Removal_report_No__c,Number_of_AEs__c,Number_of_MDIs__c,Number_of_eMDR__c,Number_of_tickets__c,Parent_Awareness_Date__c,Reportability_Rationale__c,Search_Frequency__c,Status__c',
                CMPL123__Is_Active__c = true,
                Name = 'Ticket_Review__c'),
            true);

        // 23-FEB-2023 Larry: Removed assignment of Parent_Awareness_Date__c.
        // For some reason, it causes this crash:
        // CMPL123.ToggleFeatureException: The parameters "sObjectApiName" or "packageNamespace" or "featureName" are invalid.
        Ticket_Review__c ticketReviewRecord = (Ticket_Review__c) TestDataFactory.createSObject(
            new Ticket_Review__c(
                FA_CAPA_Short_Description__c = 'test',
                CAPA_Number__c = 'test',
                // Parent_Awareness_Date__c = Date.newInstance(2018, 05, 12),
                Follow_Up_Awareness_Date__c = Date.newInstance(2018, 05, 11),
                Search_Frequency__c = 'Two Weeks (14 days)',
                Division__c = 'ADD',
                Status__c = 'Active',
                Medical_Assignee_Name__c = userMedEval.Id
            ), true);
        ticketReviewRecord.Reportability_Rationale__c = 'Test123';
        update ticketReviewRecord;
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c WHERE CMPL123__Action__c = 'Update'].size(),
            'Audit trail entry record should be created');
    }

    /*
    * @Method       : testWFlogic
    * @Description  : Test logic from disabled WF rules
    * @Return       : N/A
    * @Params       : N/A
    */
    @isTest static void testWFlogic(){
        User userMedEval = [SELECT Id FROM User WHERE Email =: MED_EVAL_EMAIL];
        Ticket_Review__c ticketReviewRecord = (Ticket_Review__c) TestDataFactory.createSObject(
            new Ticket_Review__c(
                FA_CAPA_Short_Description__c = 'test',
                CAPA_Number__c = 'test',
                Parent_Awareness_Date__c = Date.newInstance(2018, 05, 12),
                Follow_Up_Awareness_Date__c = Date.newInstance(2018, 05, 11),
                Search_Frequency__c = 'Two Weeks (14 days)',
                Division__c = 'ADD',
                Status__c = 'Active',
                Medical_Assignee_Name__c = userMedEval.Id
            ), true);
        System.assertEquals(null, [SELECT Last_Search_Date__c FROM Ticket_Review__c WHERE Id =: ticketReviewRecord.Id].Last_Search_Date__c );
        //WF: Remove_Due_Date_On_Inactive_Review
        ticketReviewRecord.Last_Search_Log_created_Date_Time__c = datetime.now();
        ticketReviewRecord.Status__c = 'Inactive';
        ticketReviewRecord.Last_Search_Date__c = date.today().addDays(-3);
        update ticketReviewRecord;
        System.assertEquals(null, [SELECT Last_Search_Date__c FROM Ticket_Review__c WHERE Id =: ticketReviewRecord.Id].Last_Search_Date__c );
        //WF: Restore_Due_Date_On_Inactive_Review
        ticketReviewRecord.Status__c = 'Active';
        update ticketReviewRecord;
        System.assertEquals(datetime.now().dateGMT(), [SELECT Last_Search_Date__c FROM Ticket_Review__c WHERE Id =: ticketReviewRecord.Id].Last_Search_Date__c );
    }
}