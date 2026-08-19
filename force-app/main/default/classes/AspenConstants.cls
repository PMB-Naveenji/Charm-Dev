/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : AspenConstants.
 * @Why   : Class contains all the contants used in different classes.
 * @When  : 24-AUG-2018.
 * @Where : All constants in one place.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer            Date                   Modification ID                       Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                24-AUG-2018            Work ID / Case ID                     Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                02-JUL-2020            Defect #131 / CHARM-2734              Added new constants.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                29-OCT-2020            Defect 62 / CHARM-3356                Updated 'createTranslationTaskWhenTicketConverts()' method name.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                28-DEC-2020            TWD Upgrade issue                     Added new constants.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         08-AUG-2022            CHaRM R2.2                            Defect 164: Added constants for MDCTicketUtil and ADDTicketNoteTriggerhandler
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         23-AUG-2022            CHaRM R2.2                            Defect 102: Added constants for TicketUtil to work with MDRs
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         30-JAN-2023            CHaRM R3.0                            Defect 411: Added TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH for MDCTicketUtil,
 * and various WF_ACTION constants
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         09-MAY-2023            CHaRM R3.1                            Defect 116: TRANSLATION_NOT_NEEDED, WF_STATUS_TASK_SENT_TO_VENDOR,
 * DIVISION_DIAGNOSTICS, DIVISION_MOLECULAR, PROFILE_ADMIN, PROFILE_STD
 * --------------------------------------------------------------------------------------------------------------------------------------
*/

public without sharing class AspenConstants {
    // STR_: denotes data type. (First 3 characters of the variable Name)

    // Acronym for Abbott Diagnostics Division. Now called "CoreDx"
    public static final String DIVISION_DIAGNOSTICS = 'ADD';
    // Acronym for Abbott Molecular Division
    public static final String DIVISION_MOLECULAR = 'AMD';
    public static final String POTENTIAL_REPORTABLE_EVENT = 'pRE';

    //Used in Class : ADDInvestigationHandler, Methods : afterUpdate, updateMedEvals
    public static final string STR_80067_Deficiency_Malfunction = '80067 Deficiency, Malfunction';

    //Used in Class : ADDInvestigationHandler, Methods : afterUpdate
    public static final string STR_80064_NO_Deficiency_Malfunction = '80064 NO Deficiency, Malfunction';
    public static final string STR_80065_NO_Deficiency_Malfunction_Defect_Distribution_Issue = '80065 NO Deficiency, Malfunction, Manufacturing Defect/Distribution Issue';
    public static final string STR_80066_NO_Deficiency_NO_Malfunction = '80066 NO Deficiency, NO Malfunction';
    public static final string STR_80069_Non_Medical_Device_Product_Problem = '80069 Non-Medical Device, Product Problem';
    public static final string STR_80068_Non_Medical_Device_NO_Product_Problem = '80068 Non-Medical Device, NO Product Problem';

    // 13MAR19 - Added for DEF#552
    public static final string STR_80064_CODE = '80064';
    public static final string STR_80065_CODE = '80065';
    public static final string STR_80066_CODE = '80066';
    public static final string STR_80067_CODE = '80067';
    public static final string STR_80068_CODE = '80068';
    public static final string STR_80069_CODE = '80069';

    // 26MAR19 - Added for DEF#457 fix
    public static final string DUMMY_PRE_ID_STRING = '00000000-0000-0000-0000-000000000000';

    //Used in Class : ADDInvestigationHandler, Methods : updateMedEvals
    public static final string STR_Opened = 'Opened';

    //Used in Class : ADDTranslations, Methods : createTranslationTaskWhenTicketConverts
    public static final string STR_In_Process = 'In Process';
    public static final string WF_STATUS_TASK_SENT_TO_VENDOR = 'Task sent to vendor';
    public static final string STR_Text_Translation = 'Text Translation';
    // 23-MAY-2023 Larry: Added the other Translation Task record type
    public static final string RECTYPE_TRANSTASK_ATTACH = 'Attachment Translation';

    //Used in Class : ADDInvestigationHandler, Methods : updateMedEvals
    //Used in Class : ADDUpdateTicketStatus, Methods : updateTicketStatus
    public static final string STR_In_Process_Evaluation = 'In Process-Evaluation';

    //Used in Class : ADDInvestigationHandler, Methods : updateMedEvals, afterUpdate
    //Used in Class : ADDUpdateTicketStatus, Methods : updateTicketStatus
    public static final string STR_Closed_Done = 'Closed-Done';

    //Used in Class : ADDInvestigationHandler, Methods : updateMedEvals
    public static final string STR_Regulatory = 'Regulatory';

    //Used in Class : ADDInvestigationHandler, Methods : afterUpdate,afterInsert
    //Used in Class : ADDUpdateTicketStatus, Methods : updateTicketStatus
    public static final string STR_Source = 'Source';

    //Used in Class : ADDInvestigationHandler, Methods : updateMedEvals
    public static final string STR_MEDICAL_EVALUATION_WORKFLOW = 'MEDICAL_EVALUATION_WORKFLOW';

    //Used in Class : ADDInvestigationHandler, Methods : updateMedEvals,afterUpdate
    public static final string STR_Deficiency = 'Deficiency';

    //Used in Class : ADDInvestigationHandler, Methods : updateMedEvals
    public static final string STR_Malfunction_Requiring_Med_Eval = 'Malfunction Requiring Med Eval';

    //Used in Class : ADDInvestigationHandler, Methods : afterUpdate,beforeUpdate
    public static final string STR_Closed_Voided = 'Closed-Voided';

    //Used in Class : ADDInvestigationHandler, Methods : afterUpdate
    public static final string STR_No = 'No';

    //Used in Class : ADDInvestigationHandler, Methods : afterUpdate,returnProducts
    public static final string STR_Yes = 'Yes';

    //Used in Class : ADDInvestigationHandler, Methods : afterUpdate
    public static final string STR_New_Line = '\r\n';

    //Used in Class : ADDUpdateTicketStatus, Methods : updateTicketStatus
    public static final string STR_Assess = 'Assess';
    public static final string STR_In_Process_Investigation = 'In Process-Investigation';

    //Used in Class : ADDUpdateTicketStatus, Methods : updateTicketStatus,beforeUpdate
    public static final string STR_Conclude = 'Conclude';

    //Used in Class : ADDUpdateTicketStatus, Methods : updateTicketStatus
    public static final string STR_PE_Review = 'PE Review';

    //Used in Class : ADDInvestigationHandler, Methods : updateMedEvals
    public static final String STR_Reportable = 'Reportable';
    // These three constants are for MedEval.Reportability__c, but these picklist
    // values may be shared by fields in other SObjects.
    public static final String REPORTABILITY_YES = 'Reportable';
    public static final String REPORTABILITY_NO = 'Non-Reportable';
    public static final String REPORTABILITY_TPM = 'TPM Responsible';

    //Used in Class : ADDInvestigationHandler, Methods : beforeUpdate
    public static final String STR_Invest_Req = 'Investigation Required';

    //Used in Class : ADDInvestigationHandler, Methods : beforeUpdate
    public static final String STR_No_Invest_Req = 'No Investigation Required';
    public static final String STR_Complaint_does_not_exceed_the_threshold = 'Complaint does not exceed the threshold';

    //Used in Class : ADDInvestigationHandler, Methods : ADDInvestigationHandler
    public static final String STR_Object_Name = 'Task__c';
    public static final String STR_Record_Type_Threshold_Review = 'Threshold Review';
    public static final String STR_Record_Type_Trend_Review_By_Prod_Number = 'Adverse Trend Review By Product Number (Reagent)';

    //Used in Class : ADDInvestigationHandler, Methods : beforeUpdate
    public static final String STR_Complaint_Desc_Or_Attachment_Review = 'Complaint Description / Attachment Review';
    public static final String STR_Labeling_Review = 'Labeling Review';
    public static final String STR_Ticket_History_Review_By_Lot_Number = 'Ticket History Review By Lot Number';
    public static final String STR_Ticket_History_Review_By_Prod_Lst_Number = 'Ticket History Review By Product List Number';
    public static final String STR_Ticket_History_Review_By_Lot_Number_Or_Prod_List_Number = 'Ticket History Review By Lot Number or Ticket History Review By Product List Number';
    public static final String STR_Complaint = 'Complaint';
    public static final String STR_Service = 'Service';

    //Used in Class : ADDTranslations, Methods : createTranslationTaskWhenTicketConverts
    public static final String STR_Inquiry = 'Inquiry';

    //Used in Class : ADDInvestigationHandler, Methods : beforeUpdate
    // 08-JUN-2023 Larry: TODO: Verify that this non-ASCII hyphen matches the actual WorkFlow record.
    public static final String STR_Reopen_Go_To_Conclude = 'Reopen – Go To Conclude';
    public static final String WF_ACTION_TO_PROC_EVAL = 'Go to In Process-Evaluation';

    //  Used in CustomerResponseTriggerHandler class
    public static final String STR_Responded_Info_On_Labeling = 'Responded Info on Labeling';
    public static final String STR_Responded = 'Responded';
    public static final String STR_Process_Team_Approval = 'Process Team Approval';
    public static final String STR_Quality_Approve_Response = 'Quality Approve Response';
    public static final String STR_Regulatory_Approve = 'Regulatory Approve';
    public static final String STR_Quality_Reject = 'Quality Reject';
    public static final String STR_Tech_Reject = 'Tech Reject';
    public static final String STR_Regulatory_Reject = 'Regulatory Reject';
    // 24-MAY-2023 Larry: Added one WF Status constant
    public static final String WF_STATUS_PENDING_QUALITY_APPROVAL = 'Pending Quality Approval';
    public static final String WF_STATUS_PENDING_PROMOTE_TO_RESPOND = 'Pending Promotion to Responded';

    //  Used in ADDS4TranslationTaskTiggerHandler class
    public static final String STR_Reopen = 'Reopen';

    //  Used in CustomerResponseTriggerHandler class
    public static final String STR_Tech_Approve = 'Tech Approve';

    //  Used in ADDS4TranslationTaskTiggerHandler class
    public static final String STR_Send_Back_To_In_Process = 'Send Back to In Process';
    public static final String STR_Populate_Translations = 'Populate Translations';
    public static final String STR_Promote = 'Promote';
    public static final String STR_Translation_Provided_By_Vendor = 'Translation Provided by Vendor';
    public static final String STR_Request_More_Information = 'Request More Information';
    public static final String STR_Send_To_Vendor = 'Send to Vendor';

    //  Used in MEDDEVTriggerHandler class
    public static final String STR_Pending_Follow_Up_Creation = 'Pending Follow Up Creation';

    //  Used in ADDS4RiskManagementTriggerHandler class
    public static final String STR_Send_Back_To_HA_In_Process = 'Send Back to Hazard Assessment in Process';
    public static final String STR_Send_Back_To_RE_In_Process = 'Send Back to Risk Evaluation in Process';
    public static final String STR_DVP_Marketing_Approval = 'DVP Marketing Approval';
    public static final String STR_DVP_Medical_Affairs_Approval = 'DVP Medical Affairs Approval';
    public static final String STR_DVP_Quality_Assurance_Approval = 'DVP Quality Assurance Approval';
    public static final String STR_DVP_Regulatory_Affairs_Approval = 'DVP Regulatory Affairs Approval';
    public static final String STR_Director_Core_Global_Service_Operations_Approval = 'Director Core Global Service Operations Approval';
    // 08-JUN-2023 Larry: Note that the following three constants use a non-ASCII hyphen.
    // CHaRM does not use Post_Market_Risk_Assessment_Risk_Contr__c, so it should not be a problem.
    public static final String STR_HA_Approve_No_Risk_Eval = 'Hazard Assessment Approve – No Risk Evaluation';
    public static final String STR_HA_Approve_Risk_Eval = 'Hazard Assessment Approve – Risk Evaluation';
    public static final String STR_Approve_No_Hazards_No_Risk_Eval = 'Approve No Hazards – No Risk Evaluation';
    public static final String STR_HA_In_Process = 'Hazard Assessment In Process';
    public static final String STR_QA_Manager_Approval = 'QA Manager Approval';
    public static final String STR_Site_Supply_Chain_QA_Head_Approval = 'Site/Supply Chain QA Head Approval';
    public static final String STR_Risk_Evaluation_In_Process = 'Risk Evaluation In Process';
    public static final String STR_Risk_Evaluation_Reject  = 'Risk Evaluation Reject';
    public static final String STR_Complete_Regulatory_Impact  = 'Complete - Regulatory Impact';
    public static final String STR_Complete_No_Regulatory_Impact  = 'Complete - No Regulatory Impact';
    public static final String STR_Reject  = 'Reject';

    //Used in Class : ADDInvestigationHandler, Methods : beforeUpdate
    public static final String STR_Submit_for_Review = 'Submit for Review';

    //Used in class : EMDRCustomException, Methods : patientDeviceCodeValidate
    public static final String STR_Device_Code = 'DEVICE CODE';

    //Used in class : EMDRCustomException, Methods : patientDeviceCodeValidate
    public static final String STR_Patinent_Code = 'PATIENT CODE';

    //Used in class : ADDS4RiskManagementTriggerHandler, Methods : checkHazardAssessment
    public static final String STR_Pending_Parent_Hazard_Assessment_Approval = 'Pending Parent Hazard Assessment Approval';

    //Used in class : ADDS4RiskManagementTriggerHandler, Methods : checkHazardAssessment
    public static final String STR_Submit_Hazard_Assessment_for_Approval = 'Submit Hazard Assessment for Approval';

    /*added this code for #1247*/
    //Used in class : ADDS4RiskManagementTriggerHandler, Methods : checkHazardAssessment
    public static final String STR_No_Hazards = 'No Hazards';
    /*Ended*/

    //Used in class : ADDS4RiskManagementTriggerHandler, Methods : checkHazardAssessment
    public static final String STR_ADDRiskManagement = 'ADDRiskManagement';

    //Used in class : ADDS4RiskManagementTriggerHandler, Methods : checkHazardAssessment
    public static final String STR_Pending_Parent_Risk_Evaluation_Approval = 'Pending Parent Risk Evaluation Approval';

    //Used in class : ADDS4RiskManagementTriggerHandler, Methods : checkHazardAssessment
    public static final String STR_Submit_Risk_Evaluation_for_Approval = 'Submit Risk Evaluation for Approval';

    //Used in class : ADDS4RiskManagementTriggerHandler, Methods : checkHazardAssessment
    public static final String STR_Risk_Control_Measure_Recommended = 'Risk Control Measure Recommended';

    //Used in class : ADDS4RiskManagementTriggerHandler, Methods : checkHazardAssessment
    public static final String STR_Risk_Control_Measure_Not_Recommended = 'Risk Control Measure Not Recommended';

    //Used in CMPL123CME_MEDDEV_AuditTrigger : Before update
    public static final String STR_WF_Action_Waive = 'Waive';
    public static final String STR_WF_Closed_Voided = 'Closed-Voided';

    //  Defect #131 / CHARM-2734 fix start
    public static final String STR_WF_Action_Submit_To_Regulatory = 'Submit to Regulatory';
    public static final String STR_WF_Pending_Regulatory = 'Pending Regulatory Decision';
    public static final String STR_WF_Closed_Done = 'Closed-Done';
    public static final String STR_WF_Action_Complete_Regulatory_Response = 'Complete Regulatory Response';
    public static final String STR_WF_Action_Pending_Final_Review = 'Pending Final Review';
    //  Defect #131 / CHARM-2734 fix end
    public static final String STR_WF_Action_Void = 'Void';
    public static final String STR_WF_Closed_Waived = 'Closed - Waived';
    public static final String STR_WF_Opened = 'Opened';

    // 23-AUG-2022 Larry: Added one constant
    //Used in TicketUtil. Represents a Workflow Status for a Ticket (aka Complaint)
    public static final String STR_WF_Reg_Closed = 'Registration Closed';

    //Used in Post_Market_Risk_Assessment_Risk_Contr_AuditTrigger : Before update
    public static final String STR_WF_Action_Approve = 'Approve';

    //Used in ADDCustomerResponseMasterHandler
    public static final String STR_WF_Action_Retire = 'Retire';

    //Used in ADDHazardAssessmentTriggerHandler : Before update
    public static final String STR_WF_Action_Close = 'Close';

    //Used in ADDActionTaskTriggerhandler : Before update
    public static final String STR_WF_Action_Complete = 'Complete';

    // 23-AUG-2022 Larry: Added one constant
    //Used in TicketUtil
    public static final String STR_WF_Action_Reopen_Trans_Req = 'Reopen - Translation Required';
    // 03-FEB-2023 Larry: Added six constants
    // Used in ComplaintTriggerHandler
    public static final String STR_WF_ACTION_GO_TO_OPENED = 'Reopen - Go to Opened';
    public static final String STR_WF_ACTION_FURTHER_ACT_REQ = 'Further Action Required';
    // Used in ADDInvestigationTaskTriggerHandler
    public static final String STR_WF_ACTION_SUBMIT = 'Submit';
    public static final String STR_WF_ACTION_REJECT = 'Reject';
    public static final String STR_WF_ACTION_COMPLETE_TASK = 'Complete Task';
    public static final String STR_WF_ACTION_SUBMIT_PRE_APPROVAL = 'Submit for Pre Approval';

    //@Juneid New Report Type used in EUMIRTriggerHandler
    public static final String STR_Combined_Initial_And_Final_Report = 'Combined initial and final';
    //@Juneid New Report Type used in EUMIRTriggerHandler
    public static final String STR_Initial_Report = 'Initial';//@Juneid 20-Sep-2021, Updated Type pf Report value 'Initial Report' to 'Initial'
    //@Juneid New Report Type used in EUMIRTriggerHandler
    public static final String STR_Follow_Up_Report = 'Follow up';
    //@Juneid New Report Type used in EUMIRTriggerHandler
    public static final String STR_Final_Reportable_Incident_Report = 'Final (Reportable incident)';
    //@Juneid New Report Type used in EUMIRTriggerHandler
    public static final String STR_FInal_Non_Reportable_Report = 'Final (Non-reportable incident)';
    //@Juneid New Action For MIR 
    public static final String STR_Follow_Up_Required = 'FOllow Up Required';
    //@Juneid Ticket Review Record Type
    public static final Id Recurrence_Search_RecordType_Id = Schema.SObjectType.Ticket_Review__c.getRecordTypeInfosByName().get('Recurrence Search').getRecordTypeId();
    //@Juneid Added new Default Value 
    public static final String Product_Type_value = 'Initial use';
    //@Juneid Added new Default Value 
    public static final String Product_Type_value_of_Software = 'Reuse of a Reusable Medical Device';
    //@Juneid Added new Default Value 
    public static final String NO_OF_MRKET_DEFAULT = 'Units distributed within each time period';
    public static final String NO_OF_MRKET_DEFAULT_FOR_EQUAL_SERIAL  = 'Active installed base';
    //@Juneid Added new Record Type Value Id
    public static final Id Regulatory_Opinion_Task_RecordType_Id = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Regulatory Opinion Task').getRecordTypeId();

    // MDCTicketUtil constants
    // 08-AUG-2022 Larry: Defect 164: Added five constants. They are arbitrarily named Map keys
    public static final String TICKETFLAG_IS_REPLY_REQUIRED = 'isReplyRequired';
    public static final String TICKETFLAG_HAS_PRODEVAL = 'hasProdEval';
    public static final String TICKETFLAG_HAS_MEDEVAL = 'hasMedEval';
    public static final String TICKETFLAG_IS_INQUIRY = 'isInquiry';
    public static final String TICKETFLAG_HAS_TICKET_SEARCH = 'hasTicketSearch';
    // 30-JAN-2023 Larry: CHaRM R3.0, Defect 411: Added this constant
    public static final String TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH = 'hasActiveTicketSearch';
        

    // Constants for Meaningful Data Requests / MDRs
    // 23-AUG-2022 Larry: Defect 102: Added three constants
    public static final String MDR_STATUS_OPENED = 'Opened';
    public static final String MDR_STATUS_COMPLETED = 'Completed';
    public static final String MDR_STATUS_VOIDED = 'Voided';

    // 30-JAN-2023 Larry: Added two constants for Ticket Reviews (sometimes deceptively called Ticket Searches)
    // See Ticket_Review__c.Status__c
    public static final String TICKSEARCH_STATUS_ACTIVE = 'Active';
    public static final String TICKSEARCH_STATUS_INACTIVE = 'Inactive';

    // 23-FEB-2023 Larry: Added two constants for MDR Code categories.
    // See CMPL123CME__MDR_Code__c.CMPL123CME__Category__c
    public static final String MDR_CODE_CATEGORY_EVAL = 'Evaluation Code';
    public static final String MDR_CODE_CATEGORY_EVPROB = 'Event Problem Code';

    // 23-FEB-2023 Larry: Added ALL_CODE_TYPES and MDR_CODE_TYPES.
    // These were infered from records in AspenVal.
    // ALL_CODE_TYPES may share Problem Codes between eMDR, EU MIR, and MDI.
    // These values are for CMPL123CME__Complaint_Code__c.CMPL123CME__Type__c
    public static final Set<String> ALL_CODE_TYPES = new Set<String>{
        'COMPONENT CODE',
        'COUNTRY CODE',
        'DEVICE CODE',
        'EVAL CONCLUSION CODE',
        'EVAL METHOD CODE',
        'EVAL RESULT CODE',
        'HEALTH EFFECT - CLINICAL CODE',
        'HEALTH EFFECT - IMPACT CODE',
        'ISSUE CODE',
        'PATIENT CODE',
        'STATE CODE',
        'SYMPTOM CODE',
        'TREND BUCKET CODE'
    };
    // MDR Problem Codes are for section H6 or H7
    public static final Set<String> MDR_CODE_TYPES = new Set<String>{
        'COMPONENT CODE',
        'DEVICE CODE',
        'EVAL CONCLUSION CODE',
        'EVAL METHOD CODE',
        'EVAL RESULT CODE',
        'HEALTH EFFECT - CLINICAL CODE',
        'HEALTH EFFECT - IMPACT CODE'
    };

    // 14-SEP-2022 Larry: Added this section and the first constant
    // Constants that define whether an SObject is locked or not based on their Workflow Status
    public static final Map<Boolean, Set<String>> OPEN_WF_STATUSES_PRODEVAL =
    new Map<Boolean, Set<String>>{
        true => new Set<String>{
            STR_Assess,
            STR_Conclude,
            STR_In_Process_Evaluation,
            STR_In_Process_Investigation,
            STR_Opened
        },
        false => new Set<String>{
            STR_Closed_Voided,
            STR_Closed_Done,
            STR_PE_Review
        }
    };

    public static final String TRANSLATION_NOT_NEEDED = 'No translation required';

    public static final String PROFILE_ADMIN = 'System Administrator';
    public static final String PROFILE_STD = 'Aspen User';

    // 23-MAY-2023 Larry: Added this map. Copied from ADDRegulatoryTaskTriggerHandler. For use in ADDUtil.
    public static final Map<Integer, String> MONTH_INDEX_TO_SHORT_NAME = new Map<Integer, String>{
        1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR', 5 => 'MAY',
        6 => 'JUN', 7 => 'JUL', 8 => 'AUG', 9 => 'SEP', 10 => 'OCT',
        11 => 'NOV', 12 => 'DEC'
    };

    // 24-MAY-2023 Larry: Added all three "CMSNext Status" constants for Ticket
    public static final String CMSNEXT_STATUS_OPEN = 'Open';
    public static final String CMSNEXT_STATUS_CLOSE = 'Closed'; // Only this API name is past-tense
    public static final String CMSNEXT_STATUS_VOID = 'Void';

    // 24-MAY-2023 Larry: Added two constants for Public Group names
    public static final String GROUP_QC = 'Quality_Complaint';
    public static final String GROUP_QNC = 'Quality_non_Complaint';

    // R3.1 Larry: Added EMDR Record Type constants
    public static final String RECTYPE_EMDR_INITIAL = 'Initial';
    // Supplemental EMDRs are sometimes called Follow-up EMDRs
    public static final String RECTYPE_EMDR_SUPPLEMENTAL = 'Supplemental';
    
}