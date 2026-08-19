/**
 * @why  : ADDTicketNoteTriggerHandlerTest class for the ADDTicketNoteTriggerHandler,
 * @when : CreatedDate : 18-OCTOBER-2018
 * @what : Class to Handle Different scenarios from ADDTicketNoteTriggerHandler.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *   Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID                                                Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oober                   10-June-2020           N/A                      Updated code part, which is related to Users' insertion.
                                                                             This change designed to prevent a 'DUPLICATE_USERNAME'
                                                                             error during deployment to Production environment
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oivan                   05-JAN-2021            TWD Upgrade issue        Added testWFLogic() for testing disabled WF logic
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik            07-SEP-2022            CHaRM R2.2 IPDR 164      Fix missing coverage for MDCTicketUtil due to not having
 *                                                                           MDC Trigger records
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  CHaRM COE                20-JUL-2026            CHaRM R9.0/IPDR-409     Created "createTicketNote_test1" & "createTicketNote_test2" methods
 * 																			to cover the MDC creation fucntionality when TickeNote record creates.
 * 																			Update the "setup" method to insert the "ADD_App_Settings__c" custom setting
 * 																			& create Medical Evaluation record.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest
public class ADDTicketNoteTriggerHandlerTest {
    // 07-SEP-2022 Larry: Made the MDC_TRIGGER constants for all test methods
    // using MDCTicketUtil have MDC Trigger records like what the org has now.
    // See getMdcTriggersForTicketNotes() for an explanation about the commented values.
    private static final List<String> MDC_TRIGGER_DESCS = new List<String>{
        'MIR Regulatory Response Completed',
        'Product/Lot Expiration/Manufacturing Date change for Medical Evaluator',
        'Regulatory Task is Closed for Medical Evaluator',
        'Customer Response change for Quality non Complaint',
        //'Ticket Notes Change for Quality non Complaint',
        'Product-Ticket Change for Quality non Complaint',
        //'Ticket Notes Change for FA Quality Assignee',
        'Translation Task Completed for med evaluator',
        'Medical Evaluation Task Completed',
        'Ticket Change for FA Quality Assignee',
        'pRE Question Change',
        //'Ticket Notes Change for medical evaluator',
        'Attachment Change for Evaluator/Investigator',
        '"Check QD Number, pRE flag, Receipt Date, Overall Reportable Status, Ticket description, Was an adverse event identified?, Issue Code, Follow-up Status, Re-Open Justification, Returns Available?, Description of Available Returns, Ad hoc Evaluator/Investigator MDC,Customer Reply Required?"',
        'Ticket Review Status Change',
        //'Ticket Notes Change for Evaluator/Investigator',
        '"Check MeaningfulDataQuestion, MeaningfulDataAnswer is changed"',
        'Product-Ticket Change for medical evaluator',
        'Product-Ticket Change for FA Quality Assignee',
        'Ticket Change for medical evaluator',
        'Patient Information Change',
        'Meaningful Data Change for Evaluator/Investigator',
        'Regulatory Response Completed',
        'Translation Task Completed for Assessor',
        'Product-Ticket Change for Evaluator/Investigator',
        'Translation Task Completed for Evaluator/Investigator',
        '"Check Third Return Requested Date, Return not Returned Rationale, Tracking Number"',
        'Translation Task Completed Inquiry for Quality non Complaint',
        'Attachment Change for Medical Evaluator',
        'Inquiry Change for Quality non Complaint',
        'Attachment change for FA Quality Assignee',
        'Attachment Change for Quality non Complaint',
        'It will create MDC for Adhoc Observation Assignee. if Additional Ticket Observations Comments field is changed in Ticket level.',
        'It will create MDC for Adhoc Quality Non Complaint Observation Assignee if Additional Ticket Observations Comments field is changed in Ticket level.',
        'Customer Response change for Evaluator/Investigator'
    };
    private static final List<String> MDC_TRIGGER_LOGIC = new List<String>{
        '1',
        '1 OR 2 OR 3 OR 4 OR 5 OR 6',
        '1',
        '1 OR 2',
        //'1',
        '1 OR 2 OR 3',
        //'1',
        '1',
        '1',
        '1 OR 2 OR 3 OR 4 OR 5',
        '1 OR 3 OR 4 OR 5 OR 6 OR 7 OR 8 OR 9 OR 10 OR 11 OR 12',
        //'1',
        '1 OR 2',
        '1 OR 2 OR 3 OR 4 OR 5 OR 6 OR 7 OR 8 OR 9 OR 10 OR 11 OR 12 OR 13 OR 14',
        '1',
        //'1',
        '1',
        '1 OR 2 OR 3 OR 4',
        '1 OR 2 OR 3',
        '1 OR 2 OR 3 OR 4 OR 5 OR 6 OR 7',
        '1 OR 2 OR 3',
        '1',
        '1',
        '1',
        '1 OR 2 OR 3 OR 4',
        '1',
        '1 OR 2 OR 3',
        '1',
        '1 OR 2',
        '1 OR 2 OR 3 OR 4 OR 5',
        '1 OR 2',
        '1 OR 2',
        '1',
        '1',
        '1'
    };
    private static final List<String> MDC_TRIGGER_FIELD = new List<String>{
        'Registration_Number__c',
        'Registration_Ticket__c',
        'Registration_Number__c',
        'Registration_Ticket__c',
        //'Ticket_Number__c',
        'Ticket_Number__c',
        //'Ticket_Number__c',
        'Registration_Number__c',
        'Registration_Number__c',
        'Registration_Ticket__c',
        'Registration_Number__c',
        //'Ticket_Number__c',
        'Ticket_Number__c',
        'Registration_Ticket__c',
        'Registration_Number__c',
        //'Ticket_Number__c',
        'Registration_Number__c',
        'Ticket_Number__c',
        'Ticket_Number__c',
        'Registration_Ticket__c',
        'Registration_Number__c',
        'Registration_Number__c',
        'Registration_Number__c',
        'Registration_Number__c',
        'Ticket_Number__c',
        'Registration_Number__c',
        'Registration_Number__c',
        'Registration_Number__c',
        'Ticket_Number__c',
        'Registration_Ticket__c',
        'Ticket_Number__c',
        'Ticket_Number__c',
        'Registration_Ticket__c',
        'Registration_Ticket__c',
        'Registration_Ticket__c'
    };
    private static final List<String> MDC_TRIGGER_OBJ = new List<String>{
        'CMPL123CME__EU_MIR__c',
        'Product_Lot__c',
        'Regulatory_Task__c',
        'Customer_Response__c',
        //'Ticket_Note__c',
        'Product_Ticket__c',
        //'Ticket_Note__c',
        'Translation_Task__c',
        'Medical_Evaluation_Task__c',
        'CMPL123CME__Complaint__c',
        'pRE_Question__c',
        //'Ticket_Note__c',
        'Attachment__c',
        'CMPL123CME__Complaint__c',
        'Ticket_Search_Result__c',
        //'Ticket_Note__c',
        'Meaningful_Data__c',
        'Product_Ticket__c',
        'Product_Ticket__c',
        'CMPL123CME__Complaint__c',
        'Patient_Information__c',
        'Meaningful_Data__c',
        'CMPL123CME__MEDDEV__c',
        'Translation_Task__c',
        'Product_Ticket__c',
        'Translation_Task__c',
        'Return__c',
        'Translation_Task__c',
        'Attachment__c',
        'CMPL123CME__Complaint__c',
        'Attachment__c',
        'Attachment__c',
        'CMPL123CME__Complaint__c',
        'CMPL123CME__Complaint__c',
        'Customer_Response__c'
    };
    private static final List<String> MDC_TRIGGER_NAME = new List<String>{
        'MIR Regulatory Response Completed',
        'Expiration/Manufacturing Date change for Medical Evaluator',
        'Regulatory Task is Closed for Medical Evaluator',
        'Customer Response change for Quality non Complaint',
        //'Ticket Notes Change for Quality non Complaint',
        'Product-Ticket Change for Quality non Complaint',
        //'Ticket Notes Change for FA Quality Assignee',
        'Translation Task Completed for med evaluator',
        'Medical Evaluation Task Completed',
        'Ticket Change for FA Quality Assignee',
        'pRE Question Change',
        //'Ticket Notes Change for medical evaluator',
        'Attachment Change for Evaluator/Investigator',
        'Ticket Change for Evaluator/Investigator',
        'Ticket Review Status Change',
        //'Ticket Notes Change for Evaluator/Investigator',
        'Meaningful Data Change for med evaluator',
        'Product-Ticket Change for med evaluator',
        'Product-Ticket Change for FA Quality Assignee',
        'Ticket Change for medical evaluator',
        'Patient Information Change',
        'Meaningful Data Change for Evaluator/Investigator',
        'Regulatory Response Completed',
        'Translation Task Completed for Assessor',
        'Product-Ticket Change for Evaluator/Investigator',
        'Translation Task Completed for Evaluator/Investigator',
        'Return Change for Evaluator/Investigator',
        'Translation Task Completed Inquiry for Quality non Complaint',
        'Attachment Change for Medical Evaluator',
        'Inquiry Change for Quality non Complaint',
        'Attachment change for FA Quality Assignee',
        'Attachment Change for Quality non Complaint',
        'Ticket change for Adhoc Observation Assignee',
        'Ticket Change for Adhoc Quality Non Complaint Observation Assignee',
        'Customer Response change for Evaluator/Investigator'
    };
    private static final List<String> MDC_TRIGGER_GROUP = new List<String>{
        'Medical Evaluator',
        'Medical Evaluator',
        'Medical Evaluator',
        'Quality non Complaint',
        //'Quality non Complaint',
        'Quality non Complaint',
        //'FA Quality Assignee',
        'Medical Evaluator',
        'Medical Evaluator',
        'FA Quality Assignee',
        'Medical Evaluator',
        //'Medical Evaluator',
        'Evaluator/Investigator',
        'Evaluator/Investigator',
        'Medical Evaluator',
        //'Evaluator/Investigator',
        'Medical Evaluator',
        'Medical Evaluator',
        'FA Quality Assignee',
        'Medical Evaluator',
        'Medical Evaluator',
        'Evaluator/Investigator',
        'Medical Evaluator',
        'Prod eval Assessor',
        'Evaluator/Investigator',
        'Evaluator/Investigator',
        'Evaluator/Investigator',
        'Quality non Complaint',
        'Medical Evaluator',
        'Quality non Complaint',
        'FA Quality Assignee',
        'Quality non Complaint',
        'Adhoc Observation Assignee',
        'Adhoc Quality Non Complaint Observation',
        'Evaluator/Investigator'
    };

    /**
     * @Method       : setup
     * @Description  : Creating Ticket Notes
     * @Return       : N/A
     * @Params       : N/A
     **/
    @testSetup static void setup(){

        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
		appConfig.MDC_Generation_Prevention_Minutes__c=10.0;
        update appConfig;
        //Create User
        User u = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'last',
            Email = 'test@test.com',
            Username = 'test@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10'
            //PermissionSet = [SELECT ID From PermissionSet WHERE Name = 'Quality Complaint Approver'].Id
        ), true);

        //Create Workflow Status
        CMPL123__WF_Status__c  statusOpened = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Opened'),true);

        CMPL123__WF_Status__c  statusInProcess = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'In Process'),true);

        CMPL123__WF_Status__c  statusTaskSentToVendor = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Task sent to vendor'),true);

        CMPL123__WF_Status__c  statusClosedDone = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Closed-Done'),true);

        //Create Workflow Action
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Promote'),true);

        CMPL123__WF_Action__c actionPopulateTranslation = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Populate Translations'),true);

        CMPL123__WF_Action__c actionSendToVendor = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Send to Vendor'),true);

        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c  assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            Name = 'Translation task workflow',
            CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
            CMPL123__Record_Type__c  = 'Translation_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step for Prod Eval Assess
        CMPL123__WF_Step__c assessProdStep = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusOpened.Id,
            CMPL123__End_Status__c  = statusInProcess.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = assessProdRule.Id,
            CMPL123__Is_Start_Step__c = true),true);

        //Create Translation Vendor
        Translation_Vendor__c objTranslationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new Translation_Vendor__c(
            Name = 'Do Not Use',
            Division__c = 'ADD',
            Status__c = 'Active',
            Vendor_Email__c = 'test@test.com'),
        true);

        //Create Country
        Country__c objCountryIndia = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'INDIA',
            Division__c = 'ADD',
            Country_Code__c = 'IND',
            Primary_Vigilance_Contact__c = u.id,
            Preferred_Translation_Vendor__c = objTranslationVendor.id,
            Translations_Required_flag__c = true ),
        true);

        // 07-SEP-2022 Larry: Now inserts all Ticket Note MDC Trigger records
        insertMdcTriggersForTicketNotes();

        // Create Complaint of Ticket RecordType
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
        CMPL123CME__Complaint__c complaintTicket = ticketFactory(complaintRTId, AspenConstants.STR_Complaint);
        insert complaintTicket;
        
        //CHaRM R9.0/IPDR-409 Create Medical Evaluation record
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaintTicket.Id
        ), true);

        //Creating TicketNotes
        Ticket_Note__c objTicketNotesForInquiry = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = 'Test',
            CMPL123Rule_Key_Value__c = 'test',
            Ticket__c = complaintTicket.Id),
        true);

        // 07-SEP-2022 Larry: Now inserts all non-Ticket Note MDC Trigger records
        insert getMdcTriggers();
    }

    /**
     * Factory for making Ticket records
     * @author Larry Resnik
     * @date 09-AUG-2022
     */
    private static CMPL123CME__Complaint__c ticketFactory(Id recTypeId, String ticketType) {
        return (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'No',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = ticketType,
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = recTypeId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), false);
    }

    /**
     * Helper fn for the @testSetup that makes MDC Triggers & related records
     * @author Larry Resnik
     * @date 09-AUG-2022
     */
    private static List<CMPL123__MDC_Trigger__c> insertMdcTriggersForTicketNotes() {
        // Insert MDC Triggers so that the audit trail knows which SObjects to act on.
        // Notice that these four MDC Triggers are commented from the MDC_TRIGGER constants
        CMPL123__MDC_Trigger__c mdcTriggerQualityNonCom =
        (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(new CMPL123__MDC_Trigger__c(
            CMPL123__Active__c = true,
            CMPL123__Criteria__c = 'Created or Changed',
            CMPL123__Logic__c = '1',
            CMPL123__Number_of_Acks__c = 1,
            CMPL123__Record_Detail_Field__c = 'Registration_Ticket__c',
            CMPL123__Select_Target_Object__c = 'Ticket_Note__c',
            Name = 'Ticket Notes Change for Quality non Complaint',
            Selected_Group_Name__c = 'Quality non Complaint'
        ), false);
        CMPL123__MDC_Trigger__c mdcTriggerFaQuality = mdcTriggerQualityNonCom.clone();
        mdcTriggerFaQuality.Name = 'Ticket Notes Change for FA Quality Assignee';
        mdcTriggerFaQuality.Selected_Group_Name__c = 'FA Quality Assignee';
        CMPL123__MDC_Trigger__c mdcTriggerMedEval = mdcTriggerQualityNonCom.clone();
        mdcTriggerMedEval.Name = 'Ticket Notes Change for medical evaluator';
        mdcTriggerMedEval.Selected_Group_Name__c = 'Medical Evaluator';
        CMPL123__MDC_Trigger__c mdcTriggerProdEval = mdcTriggerQualityNonCom.clone();
        mdcTriggerProdEval.Name = 'Ticket Notes Change for Evaluator/Investigator';
        mdcTriggerProdEval.Selected_Group_Name__c = 'Evaluator/Investigator';
        insert new CMPL123__MDC_Trigger__c[]{
            mdcTriggerQualityNonCom, mdcTriggerFaQuality, mdcTriggerMedEval, mdcTriggerProdEval
        };

        // Insert Audit Trail Config so that MDCs know which fields to track.
        // This happens in MDCTicketUtil.createMDC
        CMPL123__AuditTrail_Config__c auditTrailConfig = 
        (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = 'Ticket_Note_Added__c,Ticket_Notes_Created_By__c,Ticket_Notes_Created_Date__c,Ticket_Notes_Native__c,Ticket_Notes_Translated__c',
            CMPL123__Is_Active__c = true,
            Name = 'Ticket_Note__c'
        ), true);

        // Insert MDC Field Maps so that field API names can be affiliated with labels
        CMPL123__MDC_Field_Mapping__c fieldMapFaQuality = 
        (CMPL123__MDC_Field_Mapping__c) TestDataFactory.createSObject(new CMPL123__MDC_Field_Mapping__c(
            CMPL123__Condition__c = 'Custom',
            CMPL123__Field_API__c = 'Ticket_Note_Added__c',
            CMPL123__Field_Name__c = 'Ticket Note Added',
            CMPL123__Index__c = 1,
            CMPL123__Parameters__c = 'TicketNoteWithTickteSearchesMDCCustom',
            CMPL123__Parent_object__c = mdcTriggerFaQuality.Id,
            CMPL123__Selected_object__c = 'Ticket_Note__c'
        ), false);
        CMPL123__MDC_Field_Mapping__c fieldMapMedEval = fieldMapFaQuality.clone();
        fieldMapMedEval.CMPL123__Parameters__c = 'TicketNoteWithMedEvalsMDCCustom';
        fieldMapMedEval.CMPL123__Parent_object__c = mdcTriggerMedEval.Id;
        CMPL123__MDC_Field_Mapping__c fieldMapProdEval = fieldMapFaQuality.clone();
        fieldMapProdEval.CMPL123__Parameters__c = 'TicketNoteWithProdEvalsMDCCustom';
        fieldMapProdEval.CMPL123__Parent_object__c = mdcTriggerProdEval.Id;
        CMPL123__MDC_Field_Mapping__c fieldMapQualityNonCom = fieldMapFaQuality.clone();
        fieldMapQualityNonCom.CMPL123__Parameters__c = 'TicketNoteTicketNoteAddedMDCCustom';
        fieldMapQualityNonCom.CMPL123__Parent_object__c = mdcTriggerQualityNonCom.Id;
        insert new CMPL123__MDC_Field_Mapping__c[]{
            fieldMapFaQuality, fieldMapMedEval, fieldMapProdEval, fieldMapQualityNonCom
        };
        return new List<CMPL123__MDC_Trigger__c>{ mdcTriggerQualityNonCom,
            mdcTriggerFaQuality, mdcTriggerMedEval, mdcTriggerProdEval };
    }

    /**
     * @Method       : updateAndDeleteTicketNote
     * @Description  : Updating Ticket Note
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void updateTicketNote(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c WHERE Customer_Reply_Required__c = false AND pRE_Status__c  = 'No' LIMIT 1];

        System.assertEquals(1, [SELECT count() FROM Translation_Task__c WHERE Parent_Ticket__c =: complaintTicket.id]);
        Ticket_Note__c objTicketNotes = [SELECT Id FROM Ticket_Note__c WHERE CMPL123Rule_Key_Value__c = 'test'];

        update objTicketNotes;
    }

    /**
     * @Description  : Creates MDC Trigger records to allow code to flow as intended.
     * This inserts all MDC Triggers EXCEPT the ones for Ticket Notes
     * @Return       : N/A
     * @Params       : N/A
     * @Author       : Larry Resnik
     * @Date         : 06-SEP-2022
     **/
    public static List<CMPL123__MDC_Trigger__c> getMdcTriggers() {
        List<CMPL123__MDC_Trigger__c> mdcTriggers = new List<CMPL123__MDC_Trigger__c>();
        Integer len = MDC_TRIGGER_DESCS.size();
        for (Integer i = 0; i < len; i++) {
            mdcTriggers.add((CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(
                new CMPL123__MDC_Trigger__c(
                    CMPL123__Active__c = true,
                    CMPL123__Criteria__c = 'Created or Changed',
                    CMPL123__Number_of_Acks__c = 1,
                    CMPL123__Description__c = MDC_TRIGGER_DESCS[i],
                    CMPL123__Logic__c = MDC_TRIGGER_LOGIC[i],
                    CMPL123__Record_Detail_Field__c = MDC_TRIGGER_FIELD[i],
                    CMPL123__Select_Target_Object__c = MDC_TRIGGER_OBJ[i],
                    Name = MDC_TRIGGER_NAME[i],
                    Selected_Group_Name__c = MDC_TRIGGER_GROUP[i]
                )
            ));
        }
        return mdcTriggers;
    }

    /**
     * @Method       : deleteTicketNote
     * @Description  : deleting Ticket Note
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void deleteTicketNote(){
        Ticket_Note__c objTicketNotes = [SELECT Id FROM Ticket_Note__c WHERE CMPL123Rule_Key_Value__c = 'test'];
        System.assertEquals(1, [SELECT count() FROM Ticket_Note__c WHERE CMPL123Rule_Key_Value__c ='test']);
        delete objTicketNotes;
    }
    /**
     * @Method       : testWFLogic
     * @Description  : TWD Upgrade issue. Test WF logic that was moved to apex.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void testWFLogic(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c LIMIT 1];
        Ticket_Note__c objTicketNotesForInquiry = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = 'Test123',
            CMPL123Rule_Key_Value__c = 'test',
            Ticket__c = complaintTicket.Id),
        true);
        System.assertEquals('Test123', [SELECT Ticket_Note_Added__c FROM Ticket_Note__c WHERE id =: objTicketNotesForInquiry.Id].Ticket_Note_Added__c);

    }

    /**
     * Tests for createMDCTicket with Ticket where Ticket_Type = Inquiry
     * @author Larry Resnik
     * @date 09-AUG-2022
     */
    @isTest
    static void testCreateMDCTicketInquiry() {
        String recTypeId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Inquiry).getRecordTypeId();
        CMPL123CME__Complaint__c inquiryTicketNoResponse = ticketFactory(recTypeId, AspenConstants.STR_Inquiry);
        inquiryTicketNOResponse.Customer_Reply_Required__c = false;
        CMPL123CME__Complaint__c inquiryTicketNeedsResponse = inquiryTicketNoResponse.clone();
        inquiryTicketNeedsResponse.Customer_Reply_Required__c = true;
        insert new List<CMPL123CME__Complaint__c>{ inquiryTicketNoResponse, inquiryTicketNeedsResponse };

        Test.startTest();
        Ticket_Note__c ticketNotesWithMdc = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = 'Test',
            CMPL123Rule_Key_Value__c = 'test',
            Ticket__c = inquiryTicketNeedsResponse.Id),
        true);
        Ticket_Note__c ticketNotesWithoutMdc = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = 'Test',
            CMPL123Rule_Key_Value__c = 'test',
            Ticket__c = inquiryTicketNoResponse.Id),
        true);

        System.assertEquals(0,
            [SELECT COUNT() FROM CMPL123__MDC_Ticket__c
            WHERE CMPL123__Related_Record_ID__c = :inquiryTicketNoResponse.Id],
            'Neg test failed: Should not make an MDC for an Inquiry Ticket ' +
            'if Customer Response Required is false');
        Test.stopTest();
    }
    /**
     * @Method       : createTicketNote_test1
     * @Description  : Verifies Ticket Note processing and MDC generation when MDC prevention validation is enabled 
     * 				   through application settings.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void createTicketNote_test1(){
        // CHaRM R9.0/IPDR-409 Updated Enable_MDC_Prevention_Logic__c to True, to execute the existing functionality. 
        ADD_App_Settings__c appConfig = [SELECT Id, Enable_MDC_Prevention_Logic__c FROM ADD_App_Settings__c LIMIT 1];
        appConfig.Enable_MDC_Prevention_Logic__c = true;
        update appConfig;
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c LIMIT 1];
        Ticket_Note__c objTicketNotesForInquiry = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = 'Test123',
            CMPL123Rule_Key_Value__c = 'test',
            Ticket__c = complaintTicket.Id),
        true);
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(2, mdcCount);

    }
    /**
     * @Method       : createTicketNote_test2
     * @Description  : Verifies MDC generation for Ticket Notes when the parent Ticket creation time exceeds the 
     * 				   configured MDC prevention interval.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void createTicketNote_test2(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c LIMIT 1];
        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        Ticket_Note__c objTicketNotesForInquiry = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = 'Test123',
            CMPL123Rule_Key_Value__c = 'test',
            Ticket__c = complaintTicket.Id),
        true);
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(2, mdcCount);
    }
}