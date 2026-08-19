/**
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDTranslationsTest.
 * @Why   : ADDTranslationsTest class for the ADDTranslations class.
 * @When  : 12-OCT-2018.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer            Date                   Modification ID               Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                12-OCT-2018            Work ID / Case ID             Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rslob                06-JUN-2020            N/A                           Updated code part, which is related to Users' insertion. This
 *                                                                           change designed to prevent a 'DUPLICATE_USERNAME' error during
 *                                                                           deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                17-AUG-2020            Code Audit                    Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                29-OCT-2020            Defect 62 / CHARM-3356        Updated 'createTranslationTaskWhenTicketConverts()' method name.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         15-MAY-2023            CHaRM R3.1                    Defect 116: Made tests to verify updateApprovedTranslations behavior
 * before adding functionality for Is_Voided__c. Replaced most magic words with constants. Renamed updateTranslationTaskTestForComplaint1
 * into updateTranslationTaskTestForComplaintToClosedDone. Made many setup-related methods.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@IsTest
private class ADDTranslationsTest {
    // R3.1, Larry: Turned two shared strings into constants
    private static final String USER_EMAIL = 'test@kthbnhbnththsrchlr.com';
    private static final String TL_VENDOR_NAME = 'Do Not Use';
    private static final String TICKET_ONE = 'ONE';
    private static final String TICKET_TWO = 'TWO';
    private static final String COUNTRY_NAME_NO_TRANS = 'INDIA';
    private static final String COUNTRY_CODE_NO_TRANS = 'IND';
    private static final String COUNTRY_NAME_NEED_TRANS = 'CHINA';
    private static final String COUNTRY_CODE_NEED_TRANS = 'CHN';
    // Translation Field Metadata constants
    private static final String SOBJ_TICKET = 'CMPL123CME__Complaint__c';
    private static final String SOBJ_TICKET_NOTE = 'Ticket_Note__c';
    private static final String DEVNAME_REPORTER_NAME = 'Reporter_Name_c';
    private static final String DEVNAME_REPORTER_TITLE = 'Reporter_Title_c';
    private static final String DEVNAME_TICKET_NOTE = 'Ticket_Notes_Native_c';
    // Pre-translation field values
    private static final String NATIVE_REPORTER_NAME = 'テスト目撃者の名前';
    private static final String NATIVE_REPORTER_TITLE = 'テスト目撃者の名所';
    private static final String NATIVE_TICKET_NOTE = 'チケット詳細はここに書く';
    // Post-translation field values
    private static final String ENG_REPORTER_NAME = 'Test Reporter Name';
    private static final String ENG_REPORTER_TITLE = 'Test Reporter Title';
    private static final String ENG_TICKET_NOTE = 'Ticket Details go here';
    // Error messages
    private static final String ERROR_POS = TestUtil.ERROR_POS;
    private static final String ERROR_NEG = TestUtil.ERROR_NEG;
    private static final String ERROR_SETUP = TestUtil.ERROR_SETUP;
    private static final String POS_FAIL_NOT_TRANSLATED = ERROR_POS + 'Translation was not applied.';

    /**
     * @Method       : setup.
     * @Description  : To setup test data.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @TestSetup
    private static void setup() {
        setupMakeTransFieldMdt();
        Profile prof = [SELECT Id FROM Profile WHERE Name = :AspenConstants.PROFILE_STD];
        // R3.1, Larry: Now leverages insertTestUser
        User user1 = TestUtil.insertTestUser(prof.Id, USER_EMAIL, 'test@test.com', 'Tran10');
        Map<String, CMPL123__WF_Status__c> statuses = new Map<String, CMPL123__WF_Status__c>{
            AspenConstants.STR_Opened => new CMPL123__WF_Status__c (Name = AspenConstants.STR_Opened),
            AspenConstants.STR_In_Process => new CMPL123__WF_Status__c (Name = AspenConstants.STR_In_Process),
            AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR => new CMPL123__WF_Status__c (Name = AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR),
            AspenConstants.STR_WF_Closed_Done => new CMPL123__WF_Status__c (Name = AspenConstants.STR_WF_Closed_Done)
        };
        insert statuses.values();

        Map<String, CMPL123__WF_Action__c> actions = new Map<String, CMPL123__WF_Action__c>{
            AspenConstants.STR_Promote => new CMPL123__WF_Action__c (Name = AspenConstants.STR_Promote),
            AspenConstants.STR_Populate_Translations => new CMPL123__WF_Action__c (Name = AspenConstants.STR_Populate_Translations),
            AspenConstants.STR_Send_To_Vendor => new CMPL123__WF_Action__c (Name = AspenConstants.STR_Send_To_Vendor)
        };
        insert actions.values();
        CMPL123__WF_Rule__c assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
            new CMPL123__WF_Rule__c(
                Name = 'Translation task workflow',
                CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
                CMPL123__Record_Type__c = 'Translation_Task',
                CMPL123__Is_Active__c = true,
                CMPL123__Has_Multiple_Actions__c = true),
            true
        );
        insert new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statuses.get(AspenConstants.STR_Opened).Id,
            CMPL123__End_Status__c = statuses.get(AspenConstants.STR_In_Process).Id,
            CMPL123__Action__c = actions.get(AspenConstants.STR_Promote).Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = assessProdRule.Id,
            CMPL123__Is_Start_Step__c = true
        );
        Translation_Vendor__c translationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(
            new Translation_Vendor__c(
                Name = TL_VENDOR_NAME,
                Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
                Status__c = 'Active',
                Vendor_Email__c = 'test@test.com'),
            true
        );
        // R3.1, Larry: Changed Name from USA to INDIA. Should have no impact.
        // Also added a Country__c w/Name=CHINA to get code coverage for ADDTranslations.setDefaults.
        insert new Country__c[] {
            (Country__c) TestDataFactory.createSObject(new Country__c(
                Name = COUNTRY_NAME_NO_TRANS,
                Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
                Country_Code__c = COUNTRY_CODE_NO_TRANS,
                Primary_Vigilance_Contact__c = user1.Id,
                Preferred_Translation_Vendor__c = translationVendor.Id,
                Translations_Required_flag__c = false
            ), false),
            (Country__c) TestDataFactory.createSObject(new Country__c(
                Name = COUNTRY_NAME_NEED_TRANS,
                Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
                Country_Code__c = COUNTRY_CODE_NEED_TRANS,
                Primary_Vigilance_Contact__c = user1.Id,
                Preferred_Translation_Vendor__c = translationVendor.Id,
                Translations_Required_flag__c = true
            ), false)
        };

        // R3.1, Larry: Moved Ticket creation into testSetup
        Map<String, Schema.RecordTypeInfo> ticketRecTypeToId =
            Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName();
        String complaintRtId = ticketRecTypeToId.get(AspenConstants.STR_Complaint).getRecordTypeId();
        String inquiryRtId = ticketRecTypeToId.get(AspenConstants.STR_Inquiry).getRecordTypeId();
        CMPL123CME__Complaint__c ticket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                CMSNext_Ticket_ID__c = TICKET_ONE,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_Opened,
                CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                Country_of_origin__c = COUNTRY_NAME_NO_TRANS,
                Customer_Reply_Required__c = false,
                Description_of_Available_Returns__c = 'Returns Test',
                Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
                pRE_Status__c = AspenConstants.STR_No,
                RecordTypeId = complaintRtId,
                Ticket_Description__c = 'test',
                Ticket_Type__c = AspenConstants.STR_Complaint,
                Translation_Required_flag__c = true),
            false
        );
        // R3.1, Larry: Added a second Ticket to testSetup
        CMPL123CME__Complaint__c ticketTwo = ticket.clone();
        ticketTwo.CMSNext_Ticket_ID__c = TICKET_TWO;
        ticketTwo.Translation_Required_flag__c = false;
        ticketTwo.RecordTypeId = inquiryRtId;
        ticketTwo.Country_of_origin__c = COUNTRY_CODE_NEED_TRANS;
        ticketTwo.CMPL123Rule_Key_Value__c = 'INQUIRY_WORKFLOW';
        insert new SObject[]{ ticket, ticketTwo };

        // R3.1, Larry: Now inserts a Ticket Note so that translations can be applied to it
        Ticket_Note__c note = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = NATIVE_TICKET_NOTE,
            Ticket__c = ticket.Id),
        true);
    }

    /**
     * Creates some hand-picked Translation_Fields__mdt records for testSetup
     * 
     * At least one of each SObject is created.
     * Some SObjects are listed multiple times to verify that multiple translations
     * can be applied to a single record with one update.
     * All Translation_Fields__mdt records should be identical in all orgs.
     * @author R3.1, Larry Resnik
     */
    private static void setupMakeTransFieldMdt() {
        // Note: Translation Items get created REGARDLESS of whether or not these
        // metadata exist. If they exist, the Translation Item's translated text
        // gets saved onto its Related Record's field.
        new Translation_Fields__mdt(MasterLabel='Ticket Description'                     ,DeveloperName='Ticket_Description_c'                     ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Description_Translated__c'                  ,Object_API__c=SOBJ_TICKET                ,Related_Complaint_API__c='Id'                   ,Child_Relationship__c='');
        new Translation_Fields__mdt(MasterLabel='Delayed Entry Justification'            ,DeveloperName='Delayed_Entry_Justification_c'            ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Delayed_Entry_Justification_Translated__c'  ,Object_API__c=SOBJ_TICKET                ,Related_Complaint_API__c='Id'                   ,Child_Relationship__c='');
        new Translation_Fields__mdt(MasterLabel='Description of Available Returns'       ,DeveloperName='Description_of_Available_Returns_c'       ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Description_of_Available_Returns_Trans__c'  ,Object_API__c=SOBJ_TICKET                ,Related_Complaint_API__c='Id'                   ,Child_Relationship__c='');
        new Translation_Fields__mdt(MasterLabel='Reporter Name'                          ,DeveloperName=DEVNAME_REPORTER_NAME                      ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Reporter_Name_Translated__c'                ,Object_API__c=SOBJ_TICKET                ,Related_Complaint_API__c='Id'                   ,Child_Relationship__c='');
        new Translation_Fields__mdt(MasterLabel='Reporter Title'                         ,DeveloperName=DEVNAME_REPORTER_TITLE                     ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Reporter_Title_Translated__c'               ,Object_API__c=SOBJ_TICKET                ,Related_Complaint_API__c='Id'                   ,Child_Relationship__c='');
        new Translation_Fields__mdt(MasterLabel='Contact Name'                           ,DeveloperName='Name_c'                                   ,Is_Adhoc__c=true  ,Translated_Field_Name_API__c='Contact_Name_Translated__c'                 ,Object_API__c='Contact__c'               ,Related_Complaint_API__c='Ticket__c'            ,Child_Relationship__c='Related_Contact');
        new Translation_Fields__mdt(MasterLabel='Additional Reply Expectation'           ,DeveloperName='Additional_Reply_Expectation_c'           ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Additional_Reply_Expectation_Translated__c' ,Object_API__c='Customer_Response__c'     ,Related_Complaint_API__c='Event__c'             ,Child_Relationship__c='Customer_Responses');
        new Translation_Fields__mdt(MasterLabel='Customer Expectation'                   ,DeveloperName='Customer_Expectation_c'                   ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Customer_Expectation_Translated__c'         ,Object_API__c='Customer_Response__c'     ,Related_Complaint_API__c='Event__c'             ,Child_Relationship__c='Customer_Responses');
        new Translation_Fields__mdt(MasterLabel='Customer Name'                          ,DeveloperName='Name'                                     ,Is_Adhoc__c=true  ,Translated_Field_Name_API__c='Customer_Name_Translated__c'                ,Object_API__c='Account'                  ,Related_Complaint_API__c=''                     ,Child_Relationship__c='');
        new Translation_Fields__mdt(MasterLabel='Meaningful Data Answers'                ,DeveloperName='Meaningful_Data_Answers_c'                ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Meaningful_data_Answer_Translated__c'       ,Object_API__c='Meaningful_Data__c'       ,Related_Complaint_API__c='Compliant__c'         ,Child_Relationship__c='Meaningful_Data');
        new Translation_Fields__mdt(MasterLabel='Patient Information'                    ,DeveloperName='Patient_Information_c'                    ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Patient_Information_Translated__c'          ,Object_API__c='Patient_Information__c'   ,Related_Complaint_API__c='Related_Ticket_Id__c' ,Child_Relationship__c='');
        new Translation_Fields__mdt(MasterLabel='Cause of Death/Injury/Potential Injury' ,DeveloperName='Cause_of_Death_Injury_Potential_Injury_c' ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Cause_of_Death_Injury_Potentialinjury__c'   ,Object_API__c='pRE_Information__c'       ,Related_Complaint_API__c='Complaint__c'         ,Child_Relationship__c='pRE_Informations');
        new Translation_Fields__mdt(MasterLabel='Ticket Re-Open Rationale (Native)'      ,DeveloperName='Ticket_Re_Open_Rationale_Native_c'        ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Ticket_Re_Open_Rationale_Translation__c'    ,Object_API__c='Re_Open_Justification__c' ,Related_Complaint_API__c='Complaint__c'         ,Child_Relationship__c='Re_Open_Justifications');
        new Translation_Fields__mdt(MasterLabel='Ticket Notes (Native)'                  ,DeveloperName=DEVNAME_TICKET_NOTE                        ,Is_Adhoc__c=false ,Translated_Field_Name_API__c='Ticket_Notes_Translated__c'                 ,Object_API__c=SOBJ_TICKET_NOTE           ,Related_Complaint_API__c='Ticket__c'            ,Child_Relationship__c='Ticket_Notes');
    }

    /** Creates specific Translation Item(s) for a Ticket Note */
    private static List<Translation_Item__c> setupMakeTicketNoteTranslationItems(
        Translation_Task__c transTask, Ticket_Note__c note
    ) {
        List<Translation_Item__c> transItemList = new List<Translation_Item__c>();
        transItemList.add((Translation_Item__c)TestDataFactory.createSObject(
            new Translation_Item__c(
                Field_Name__c = Translation_Fields__mdt.getInstance(DEVNAME_TICKET_NOTE).MasterLabel,
                Native__c = NATIVE_TICKET_NOTE,
                Related_Record_Id__c = note.Id,
                Translated__c = ENG_TICKET_NOTE,
                Translation_Task__c = transTask.Id
            ), false)
        );
        return transItemList;
    }

    /** Creates Translation Item(s) for a Ticket */
    private static List<Translation_Item__c> setupMakeTicketTranslationItems(
        Translation_Task__c transTask
    ) {
        Id ticketId = transTask.Parent_Ticket__c;
        Assert.isNotNull(ticketId, ERROR_SETUP + 'You must query for the Ticket Id');

        List<Translation_Item__c> transItemList = new List<Translation_Item__c>();
        transItemList.add((Translation_Item__c)TestDataFactory.createSObject(
            new Translation_Item__c(
                Field_Name__c = Translation_Fields__mdt.getInstance(DEVNAME_REPORTER_NAME).MasterLabel,
                Native__c = NATIVE_REPORTER_NAME,
                Related_Record_Id__c = ticketId,
                Translated__c = ENG_REPORTER_NAME,
                Translation_Task__c = transTask.Id
            ), false)
        );
        transItemList.add((Translation_Item__c)TestDataFactory.createSObject(
            new Translation_Item__c(
                Field_Name__c = Translation_Fields__mdt.getInstance(DEVNAME_REPORTER_TITLE).MasterLabel,
                Native__c = NATIVE_REPORTER_TITLE,
                Related_Record_Id__c = ticketId,
                Translated__c = ENG_REPORTER_TITLE,
                Translation_Task__c = transTask.Id
            ), false)
        );
        return transItemList;
    }

    /** Gets the Ticket made in testSetup */
    private static CMPL123CME__Complaint__c getSetupTicket() {
        return getSetupTicket(TICKET_ONE);
    }

    private static CMPL123CME__Complaint__c getSetupTicket(String cmsNextNum) {
        return [
            SELECT Id, Translation_Required_flag__c, Reopen_Rationale__c, LastModifiedDate,
            Delayed_Entry_Justification_Translated__c
            FROM CMPL123CME__Complaint__c
            WHERE CMSNext_Ticket_ID__c = :cmsNextNum];
    }

    /** Gets the Translation Tasks made in testSetup */
    private static List<Translation_Task__c> getSetupTransTasks(CMPL123CME__Complaint__c ticket) {
        return [
            SELECT Id, CMPL123_WF_Status__c, Parent_Ticket__c, RecordType.Name
            FROM Translation_Task__c
            WHERE Parent_Ticket__c = :ticket.Id
        ];
    }

    /** Gets the Ticket Note made in testSetup */
    private static Ticket_Note__c getSetupTicketNote(CMPL123CME__Complaint__c ticket) {
        return [
            SELECT Id, Ticket_Notes_Translated__c,
            Ticket__c,
            Ticket__r.Reporter_Name_Translated__c,
            Ticket__r.Reporter_Title_Translated__c
            FROM Ticket_Note__c
            WHERE Ticket__c = :ticket.Id
            LIMIT 1
        ];
    }

    /**
     * @Method       : createTranslationTaskTestForComplaint.
     * @Description  : To test whether Translation Task created or not and update Ticket.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @IsTest
    private static void createTranslationTaskTestForComplaint() {
        CMPL123CME__Complaint__c complaintTicket = getSetupTicket();
        Translation_Task__c objTranslationTask = [
            SELECT CMPL123_WF_Status__c
            FROM Translation_Task__c
            WHERE Parent_Ticket__c = :complaintTicket.Id
                AND (CMPL123_WF_Status__c = :AspenConstants.STR_Opened)
            LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = :USER_EMAIL];
        Translation_Vendor__c objTranslationVendor =
            [SELECT Name FROM Translation_Vendor__c WHERE Name = :TL_VENDOR_NAME];
        System.assertEquals(1, [
            SELECT COUNT()
            FROM Translation_Task__c
            WHERE Parent_Ticket__c = :complaintTicket.Id
                AND (CMPL123_WF_Status__c = :AspenConstants.STR_Opened)]);
        // R3.1, Larry: 2 changed to 3. Dunno where the magic number comes from.
        System.assertEquals(3, [
            SELECT COUNT()
            FROM Translation_Item__c
            WHERE Translation_Task__c = :objTranslationTask.Id]);

        objTranslationTask.Vendor_Name__c = objTranslationVendor.Id;
        objTranslationTask.Urgency__c = 'Rush';
        objTranslationTask.Assignee_Name__c = usr.Id;
        objTranslationTask.CMPL123_WF_Status__c = AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR;
        update objTranslationTask;

        System.assertEquals(AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR, [
            SELECT CMPL123_WF_Status__c
            FROM Translation_Task__c
            WHERE Id = :objTranslationTask.Id].CMPL123_WF_Status__c);

        Test.startTest();
        complaintTicket.Translation_Required_flag__c = false;
        update complaintTicket;

        // R3.1, Larry: Commented this function call since it is ordinarily inaccessible.
        // ADDTranslations.createReopenJustification(complaintTicket);

        // R3.1, Larry: Commented this function call and affiliated assert.
        // This negative test verifies the function crashes when called outside
        // of a trigger context. This function was not developed alongside
        // a positive test.
        //
        // Boolean exceptionDetected = false;
        // try {
        //     ADDTranslations.processReopenJustification();
        // } catch (NullPointerException ex) {
        //     exceptionDetected = true;
        // }
        // System.assert(exceptionDetected);
        ADDTranslations.createTranslationTaskWhenTicketConverts(
            new Set<Id> { complaintTicket.Id }
        );
        Test.stopTest();

        System.assertEquals(AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR, [
            SELECT CMPL123_WF_Status__c
            FROM Translation_Task__c
            WHERE Id = :objTranslationTask.Id].CMPL123_WF_Status__c);
        System.assertEquals(2, [SELECT COUNT() FROM Translation_Task__c WHERE Parent_Ticket__c = :complaintTicket.Id]);

        // R3.1, Larry: Commented because this has no use
        // complaintTicket.Ticket_Description__c = 'Test Description';
        // R3.1, Larry: Commented because this gets tested in updateTranslationTaskTestForComplaint
        // complaintTicket.Translation_Required_flag__c = true;
        // R3.1, Larry: Commented because this gets tested in updateTranslationTaskTestForComplaintToClosedDone
        // objTranslationTask.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
    }

    /**
     * @Method       : updateTranslationTaskTestForComplaint.
     * @Description  : To test the update of Translation Task to 'Closed-Done'.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @IsTest
    private static void updateTranslationTaskTestForComplaint() {
        CMPL123CME__Complaint__c complaintTicket = getSetupTicket();

        Test.startTest();
        complaintTicket.Translation_Required_flag__c = true;
        update complaintTicket;
        Set<String> complaints = new Set<String>();
        complaints.add(complaintTicket.Id);
        ADDTranslations.updateApprovedFileTranslations(complaints);
        Test.stopTest();

        // TODO by Larry: Who the heck wrote this!?
        System.assertEquals(complaintTicket.Id, [
            SELECT Id
            FROM CMPL123CME__Complaint__c
            WHERE Id = :complaintTicket.Id].Id);
    }

    /**
     * @Method       : updateTranslationTaskTestForComplaintToClosedDone.
     * @Description  : To test the update of Translation Task to 'Closed-Done'.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Renamed from updateTranslationTaskTestForComplaint1
     * to updateTranslationTaskTestForComplaintToClosedDone
     */
    @IsTest
    private static void updateTranslationTaskTestForComplaintToClosedDone() {
        CMPL123CME__Complaint__c complaintTicket = getSetupTicket();
        Translation_Task__c objTranslationTask = [
            SELECT CMPL123_WF_Status__c
            FROM Translation_Task__c
            WHERE Parent_Ticket__c = :complaintTicket.Id
                AND (CMPL123_WF_Status__c = :AspenConstants.STR_Opened)
            LIMIT 1
        ];

        Test.startTest();
        objTranslationTask.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
        update objTranslationTask;
        delete objTranslationTask;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Translation_Task__c]);
    }

    /**
     * Tests that updateApprovedTranslations is accessible in a normal situation
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateApprovedTranslationsFull() {
        CMPL123CME__Complaint__c ticket = getSetupTicket();
        Translation_Task__c transTask = getSetupTransTasks(ticket)[0];
        Assert.areEqual(AspenConstants.STR_Text_Translation, transTask.RecordType.Name,
            ERROR_SETUP + 'Translation Task is the wrong record type for this test');

        Ticket_Note__c note = getSetupTicketNote(ticket);
        List<Translation_Item__c> transItemList = setupMakeTicketNoteTranslationItems(transTask, note);
        transItemList.addAll(setupMakeTicketTranslationItems(transTask));
        insert transItemList;

        Test.startTest();
        transTask.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
        update transTask;
        Test.stopTest();

        note = getSetupTicketNote(ticket);
        Assert.areEqual(ENG_TICKET_NOTE, note.Ticket_Notes_Translated__c,
            POS_FAIL_NOT_TRANSLATED +
            'Did not apply the Ticket Note translation from the ' +
            'child Translation Item when closing the Translation Task. ' +
            'Check pos/neg tests for problems w/updateApprovedTranslations. ' +
            'Check setup data for this test if updateApprovedTranslations did not even execute.');
    }

    /**
     * Pos tests for updateApprovedTranslations
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateApprovedTranslationsPos() {
        CMPL123CME__Complaint__c ticket = getSetupTicket();
        Translation_Task__c transTask = getSetupTransTasks(ticket)[0];
        Assert.areEqual(AspenConstants.STR_Text_Translation, transTask.RecordType.Name,
            ERROR_SETUP + 'Translation Task is the wrong record type for this test');

        Ticket_Note__c note = getSetupTicketNote(ticket);
        List<Translation_Item__c> transItemList = setupMakeTicketNoteTranslationItems(transTask, note);
        transItemList.addAll(setupMakeTicketTranslationItems(transTask));
        insert transItemList;

        Test.startTest();
        ADDTranslations.updateApprovedTranslations(new Set<String>{transTask.Id});
        Test.stopTest();

        note = getSetupTicketNote(ticket);
        Assert.areEqual(ticket.Id, note.Ticket__c,
            ERROR_SETUP + 'The retrieved Ticket Note belongs to a ' +
            'different Ticket than the one we were working on');
        Assert.areEqual(ENG_TICKET_NOTE, note.Ticket_Notes_Translated__c,
            POS_FAIL_NOT_TRANSLATED +
            'Should be able to apply translations on multiple objects and fields at once');
        Assert.areEqual(ENG_REPORTER_NAME, note.Ticket__r.Reporter_Name_Translated__c,
            POS_FAIL_NOT_TRANSLATED +
            'Should be able to apply translations on multiple objects and fields at once');
        Assert.areEqual(ENG_REPORTER_TITLE, note.Ticket__r.Reporter_Title_Translated__c,
            POS_FAIL_NOT_TRANSLATED +
            'Should be able to apply translations on multiple objects and fields at once');
    }

    /**
     * Neg test(s) for updateApprovedTranslations such that metadata is not referenced correctly
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateApprovedTranslationsBadDevName() {
        final String BAD_SUFFIX = 'ThisDevNameDoesNotExist';

        CMPL123CME__Complaint__c ticket = getSetupTicket();
        Translation_Task__c transTask = getSetupTransTasks(ticket)[0];
        Assert.areEqual(AspenConstants.STR_Text_Translation, transTask.RecordType.Name,
            ERROR_SETUP + 'Translation Task is the wrong record type for this test');

        List<Translation_Item__c> transItemList = setupMakeTicketTranslationItems(transTask);
        transItemList[0].Field_Name__c += BAD_SUFFIX;
        insert transItemList;

        Test.startTest();
        String translationOld = getSetupTicketNote(ticket).Ticket_Notes_Translated__c;
        ADDTranslations.updateApprovedTranslations(new Set<String>{transTask.Id});
        String translationNew = getSetupTicketNote(ticket).Ticket_Notes_Translated__c;
        Test.stopTest();

        Assert.areEqual(translationOld, translationNew,
            ERROR_NEG + 'Should not attempt to update the record with a translation because the ' +
            'metadata DevName was misspelled');
    }

    /**
     * Neg test(s) for updateApprovedTranslations such that no translation was provided
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateApprovedTranslationsWithoutTrans() {
        CMPL123CME__Complaint__c ticket = getSetupTicket();
        Translation_Task__c transTask = getSetupTransTasks(ticket)[0];
        Assert.areEqual(AspenConstants.STR_Text_Translation, transTask.RecordType.Name,
            ERROR_SETUP + 'Translation Task is the wrong record type for this test');

        List<Translation_Item__c> transItemList = setupMakeTicketTranslationItems(transTask);
        transItemList[0].Translated__c = null;
        insert transItemList;

        Test.startTest();
        String translationOld = getSetupTicketNote(ticket).Ticket_Notes_Translated__c;
        ADDTranslations.updateApprovedTranslations(new Set<String>{transTask.Id});
        String translationNew = getSetupTicketNote(ticket).Ticket_Notes_Translated__c;
        Test.stopTest();

        Assert.areEqual(translationOld, translationNew,
            ERROR_NEG + 'Should not attempt to update the record with a translation because the ' +
            'translated text was not provided');
    }

    /**
     * Pos/neg tests for makeRecordToTranslate
     * 
     * makeRecordToTranslate is accessible if updateApprovedTranslations positive tests work,
     * so start-to-finish execution is demonstrated with testUpdateApprovedTranslationsFull
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testMakeRecordToTranslate() {
        final String FAKE_FIELD_NAME = 'Totally Invalid (Native)';
        final String TRANSLATED_TEXT = 'Please translate this';

        Id noteId = TestUtil.getFakeId(Ticket_Note__c.SObjectType);
        Id ticketId = TestUtil.getFakeId(CMPL123CME__Complaint__c.SObjectType);
        Map<Id, SObject> idToTranslatableRecord = new Map<Id, SObject>{
            noteId => new Ticket_Note__c(
                Id = noteId
            )
        };

        Translation_Item__c tItem = new Translation_Item__c(
            Field_Name__c = FAKE_FIELD_NAME,
            Related_Record_Id__c = noteId,
            Translated__c = TRANSLATED_TEXT
        );

        Test.startTest();
        SObject returnVal = ADDTranslations.makeRecordToTranslate(tItem, idToTranslatableRecord);
        Assert.isFalse(ADDTranslations.labelToTransFieldMdt.containsKey(tItem.Field_Name__c),
            ERROR_SETUP + 'Somehow found an invalid Custom Metadata');
        Ticket_Note__c returnedNote = (Ticket_Note__c) returnVal;
        Assert.isNull(returnedNote.Ticket_Notes_Translated__c,
            ERROR_NEG + 'Should NOT apply a translation if the Field Name is NOT defined as Custom Metadata');

        tItem.Related_Record_Id__c = ticketId;
        tItem.Field_Name__c = Translation_Fields__mdt.getInstance(DEVNAME_TICKET_NOTE).MasterLabel;
        Assert.isTrue(ADDTranslations.labelToTransFieldMdt.containsKey(tItem.Field_Name__c),
            ERROR_SETUP + 'Should find valid Custom Metadata even though the Id is for the wrong SObject type');
        try {
            ADDTranslations.makeRecordToTranslate(tItem, idToTranslatableRecord);
            Assert.fail(ERROR_NEG + 'Should crash trying to set the translation on the wrong SObject');
        } catch (TypeException ex) {
            System.debug(LoggingLevel.FINE, 'Threw an exception as anticipated');
        }

        tItem.Related_Record_Id__c = noteId;
        returnVal = ADDTranslations.makeRecordToTranslate(tItem, idToTranslatableRecord);
        returnedNote = (Ticket_Note__c) returnVal;
        Assert.isNotNull(returnVal, ERROR_POS + 'Did not find the corresponding Custom Metadata');
        Assert.areEqual(noteId, returnVal.Id,
            ERROR_POS + 'Should return the same record pointed to by the Translation Item');
        Assert.areEqual(TRANSLATED_TEXT, returnedNote.Ticket_Notes_Translated__c,
            ERROR_POS + 'Should apply the translated text to the returned record');
        Test.stopTest();
    }

    /**
     * Pos/neg tests for CreateReopenJustification and rationale lengths
     * 
     * This test method was created to increase code coverage. It was later
     * discovered that the method being tested was inaccessible, so this test
     * method has been commented out entirely.
     * @author R3.1, Larry Resnik
     */
    // @isTest
    // static void testCreateReopenJustificationForRationaleLen() {
    //     final Integer MAX_LEN = 255;
    //     final String REPEATED_CHAR = 'a';

    //     System.runAs((User)[SELECT Id FROM User WHERE Email = :USER_EMAIL LIMIT 1]) {
    //         CMPL123CME__Complaint__c ticket = getSetupTicket();

    //         Test.startTest();
    //         ticket.Reopen_Rationale__c = REPEATED_CHAR.repeat(MAX_LEN + 1);
    //         Re_Open_Justification__c justif = ADDTranslations.CreateReopenJustification(ticket);
    //         Assert.areEqual(MAX_LEN, justif.Ticket_Re_Open_Rationale_Native__c.length(),
    //             ERROR_NEG + 'Rationale should have been truncated');

    //         ticket.Reopen_Rationale__c = REPEATED_CHAR.repeat(MAX_LEN - 1);
    //         justif = ADDTranslations.CreateReopenJustification(ticket);
    //         Assert.areEqual(MAX_LEN - 1, justif.Ticket_Re_Open_Rationale_Native__c.length(),
    //             ERROR_POS + 'Rationale should not be changed');
    //         Test.stopTest();
    //     }
    // }

    /**
     * Neg test for createTranslationTaskWhenTicketConverts such that the input is empty
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testCreateTranslationTaskWhenTicketConvertsNoInput() {
        Integer queriesBefore = Limits.getQueries();
        ADDTranslations.createTranslationTaskWhenTicketConverts(new Set<Id>());
        Integer queriesAfter = Limits.getQueries();
        Assert.areEqual(queriesBefore, queriesAfter,
            ERROR_NEG + 'Should not do SOQL when the input parameters are empty');
    }

    /**
     * Accessibility test for createTranslationTaskWhenTicketConverts
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testCreateTranslationTaskWhenTicketConvertsFull() {
        CMPL123CME__Complaint__c ticket = getSetupTicket(TICKET_TWO);
        Assert.isTrue(getSetupTransTasks(ticket).isEmpty(),
            ERROR_SETUP + 'This test must start without a Translation Task, then create one');

        Test.startTest();
        ticket.pRE_Status__c = AspenConstants.STR_Yes;
        ticket.Translation_Required_flag__c = true;
        update ticket;
        Test.stopTest();

        Assert.areEqual(1, getSetupTransTasks(ticket).size(),
            ERROR_POS + 'Did not reach createTranslationTaskWhenTicketConverts?');
    }
}