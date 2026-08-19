/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : SyncSubmissionsFromMedEvalQueueable.
* @Why   : global class to auto populate fields in submissions (EMDR and MDI) from medical evaluation.
* @When  : 23-MAR-2017.
* @Where : From SyncSubmissionsFromMedEvalQueueable.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-06-2020             Code Audit                        Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-06-2020             Code Audit                        Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman               03-Dec-2020            Charm Upgrade                Changed the field value from CMPL123CME__G4_Date_received_by_MFG__c to CMPL123CME__G3_Date_received_by_Mfg__c.
* ---------------------------------------------------------------------------------------------------------------------------------------
*  Neeraj Soni             11-June-2021           FRS 1470-07
* ---------------------------------------------------------------------------------------------------------------------------------------
* Larry Resnik             14-Sep-2021            CHaRM Release 2                   Consolidate logic for assigning MedEvaluation fields from an EU MIR.
*                                                                                   Now blanks out MedEvaluator's Final Report or Non-Reportable Rationale based on the Workflow status
* ---------------------------------------------------------------------------------------------------------------------------------------
* Larry Resnik             15-Sep-2021            CHaRM Release 2                   No longer does allOrNothing for updates so that bad data in one record does not 
*                                                                                   crash all the other records being updated in the batch
*-----------------------------------------------------------------------------------------------------------------------------------------------
* Larry Resnik             16-Sep-2021            CHaRM Release 2                   Accidentally inverted the Workflow Status comparison, so no EU MIRs got synced
*-----------------------------------------------------------------------------------------------------------------------------------------------
* Juneid                   20-Sep-2021            CHaRM Release 2                   Updated Type Of Report Value of MIR 'Initial Report' to 'Initial'
*-----------------------------------------------------------------------------------------------------------------------------------------------
* Larry Resnik             22-Oct-2021            CHaRM Release 2                   IPDR 301: Fixed "null" being put into the "Incident Description"
*-----------------------------------------------------------------------------------------------------------------------------------------------
* Soumith                  16-JAN-2024            CHaRM-R4.0                        updated 'execute' & 'getCurrentRecord' methods
*-----------------------------------------------------------------------------------------------------------------------------------------------
* Soumith                  16-JAN-2025            CHaRM-R6.0/BTSIT10092             updated 'execute' method
*-----------------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             25-MAR-2025            CHaRM-R6.1/IPDR 727               updated 'execute' method
*-----------------------------------------------------------------------------------------------------------------------------------------------
* Charm COE                19-September-2025      CHaRM R7.0                        updated 'execute' method to auto-populate the fields based on recordtype
*-----------------------------------------------------------------------------------------------------------------------------------------------
* Charm COE                19-FEB-2026            CHaRM R8.0                        updated 'execute' method to add the GB MIR recordtype check as 'or' condition
*-----------------------------------------------------------------------------------------------------------------------------------------------
*/
global class SyncSubmissionsFromMedEvalQueueable implements Queueable,Database.AllowsCallouts{
    global Id medDevId;
    global String EMDRB5Desc;
    global String Question;
    global Map<String,String> recTypeMap;
    //R7 Phase 2
    public static Id recordType7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_2_1') .getRecordTypeId();   
    public static Id recordType_GB_MIR_7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('GB_MIR_7_2_1') .getRecordTypeId();  //R8 - Added to get the GB MIR recordtype id
    public static Id recordType7_3_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('V7_3_1') .getRecordTypeId();
    //R7 Phase 2
    
    global SyncSubmissionsFromMedEvalQueueable(Id recordId){
        medDevId = recordId;        
        Question = SYSTEM.Label.ADDS3_pRE_DT_Q2a;
        recTypeMap = new Map<String, String>();
        recTypeMap = ADDUtil.getRecordTypeMap('CMPL123CME__EMDR__c');  
    }
    
    global void execute(QueueableContext context) {
        List<CMPL123CME__EMDR__c> updatedEMDRList = new List<CMPL123CME__EMDR__c>();
        List<CMPL123CME__MEDDEV__c> updatedMDIList = new List<CMPL123CME__MEDDEV__c>();
        List<CMPL123CME__EU_MIR__c> updateEUMIRList = new List<CMPL123CME__EU_MIR__c>();
        Set<String> deathIndicators = new Set<String>();
        
        List<CMPL123CME__Questionnaire__c> medicalEvalWithChildList = getCurrentRecord(medDevId);
        
        for(CMPL123CME__Questionnaire__c medDevWithSubmisssions : medicalEvalWithChildList){
            if(medDevWithSubmisssions.CMPL123CME__Questionnaire_Items__r.size() > 0){
                for(CMPL123CME__Questionnaire_Items__c qItem : medDevWithSubmisssions.CMPL123CME__Questionnaire_Items__r){
                    if(qItem.CMPL123CME__Question__c.contains('2a') && qItem.CMPL123CME__Answer__c == 'Yes'){
                        deathIndicators.add(medDevWithSubmisssions.Id);
                    }
                }
            }
            if(medDevWithSubmisssions != null && medDevWithSubmisssions.EMDR__r.size() > 0){
                for(CMPL123CME__EMDR__c emdr : medDevWithSubmisssions.EMDR__r){
                    emdr.CMPL123CME__B1_AdverseEvent_ProductProblem__c = medDevWithSubmisssions.B1_Adverse_Event_Product_Problem_New__c;
                    emdr.CMPL123CME__B2_Date_of_Death__c = medDevWithSubmisssions.B2_Date_of_Death__c;
                    emdr.CMPL123CME__B2_Outcomes_attributed_to_AE__c = medDevWithSubmisssions.B2_Outcomes_attributed_to_AE__c;
                    emdr.CMPL123CME__B3_Date_of_Event__c = medDevWithSubmisssions.Date_of_Incidence__c;
                    
                    
                    EMDRB5Desc = medDevWithSubmisssions.Describe_Event_or_Problem__c + ' ' + medDevWithSubmisssions.Patient_Outcome__c;
                    emdr.CMPL123CME__B5_Describe_Event_or_Problem__c =
                        (medDevWithSubmisssions.Describe_Event_or_Problem__c != null ||
                            medDevWithSubmisssions.Patient_Outcome__c != null) && EMDRB5Desc.length() <= 32768 ?
                            EMDRB5Desc : (medDevWithSubmisssions.Describe_Event_or_Problem__c != null ||
                            medDevWithSubmisssions.Patient_Outcome__c != null) && EMDRB5Desc.length() > 32768 ?
                            EMDRB5Desc.subString(0,32768)
                         : emdr.CMPL123CME__B5_Describe_Event_or_Problem__c;
                    //CHaRM R6.1: Updated below logic to assign the value from H9-Correction/Removal Report No. field in Medical eval to H9-Correction/Removal Report No. field in EMDR object and
                    // commented the logic for checking the character length of 24 characters. In R4 field length of both the field was updated to same field size.
                    emdr.CMPL123CME__H9_Correction_Removal_Report_No__c =
                        medDevWithSubmisssions.H9_Correction_Removal_report_No__c != null ?
                        medDevWithSubmisssions.H9_Correction_Removal_report_No__c : emdr.CMPL123CME__H9_Correction_Removal_Report_No__c;
                    /*emdr.CMPL123CME__H9_Correction_Removal_Report_No__c =
                        medDevWithSubmisssions.H9_Correction_Removal_report_No__c != null &&
                        medDevWithSubmisssions.H9_Correction_Removal_report_No__c.length() <= 24 ?
                        medDevWithSubmisssions.H9_Correction_Removal_report_No__c :
                        medDevWithSubmisssions.H9_Correction_Removal_report_No__c != null &&
                        medDevWithSubmisssions.H9_Correction_Removal_report_No__c.length() > 24 ?
                        medDevWithSubmisssions.H9_Correction_Removal_report_No__c.substring(0,24) :
                        emdr.CMPL123CME__H9_Correction_Removal_Report_No__c;*/
                    //CHaRM R6: Start-Autoupdating the Field Action Number field in EMDR from Medical Eval record when Sync Submission button is clicked.
                    emdr.Field_Action_Number__c =
                        medDevWithSubmisssions.Field_Action_Number__c != null ?
                        medDevWithSubmisssions.Field_Action_Number__c : emdr.Field_Action_Number__c;
                    //CHaRM R6: End
                    
                    emdr.CMPL123CME__G3_Date_received_by_Mfg__c = recTypeMap.get(emdr.RecordTypeId) == 'Initial' ?
                        medDevWithSubmisssions.Initial_Awareness_Date__c  :
                        emdr.CMPL123CME__G3_Date_received_by_Mfg__c;
                    emdr.CMPL123CME__G3_Date_received_by_Mfg__c =recTypeMap.get(emdr.RecordTypeId) == 'Supplemental'
                        ? medDevWithSubmisssions.Follow_Up_Awareness_Date__c :
                        emdr.CMPL123CME__G3_Date_received_by_Mfg__c;

                    //CHaRM-R4: CMPL123CME__H10_Addtl_Mfg_Narrative__c is replaced with CMPL123CME__H11_Additional_Mfg_Narrative__c
                    //emdr.CMPL123CME__H10_Addtl_Mfg_Narrative__c = medDevWithSubmisssions.Final_Mfg_Analysis_New__c  != null
                    emdr.CMPL123CME__H11_Additional_Mfg_Narrative__c = medDevWithSubmisssions.Final_Mfg_Analysis_New__c  != null
                        ? medDevWithSubmisssions.Final_Mfg_Analysis_New__c  :
                        medDevWithSubmisssions.Initial_Follow_Up_Mfg_Analysis_New__c ;
                    emdr.Id = emdr.Id;
                    updatedEMDRList.add(emdr);
                }
            }
            if(medDevWithSubmisssions != null && medDevWithSubmisssions.MDI__r.size() >0){
                for(CMPL123CME__MEDDEV__c mdi : medDevWithSubmisssions.MDI__r){
                    mdi.CMPL123CME__Incident_Description_Narrative__c = medDevWithSubmisssions.Describe_Event_or_Problem__c;
                    mdi.CMPL123CME__Manufacturer_Awareness_Date__c = medDevWithSubmisssions.Initial_Awareness_Date__c;
                    mdi.CMPL123CME__PatientOutcome__c = medDevWithSubmisssions.Patient_Outcome__c;
                    mdi.CMPL123CME__Manufacturer_Preliminary_Analysis__c =
                        (mdi.CMPL123CME__Type_of_Report__c == 'Initial report' ||
                            mdi.CMPL123CME__Type_of_Report__c == 'Follow-up report')
                        ? medDevWithSubmisssions.Initial_Follow_Up_Mfg_Analysis_New__c :
                        mdi.CMPL123CME__Manufacturer_Preliminary_Analysis__c;
                    mdi.CMPL123CME__Manufacturer_Device_Analysis_Results__c =
                       (mdi.CMPL123CME__Type_of_Report__c == 'Combined initial and final report' ||
                           mdi.CMPL123CME__Type_of_Report__c == 'Final report') ?
                       medDevWithSubmisssions.Final_Mfg_Analysis_New__c :
                       mdi.CMPL123CME__Manufacturer_Device_Analysis_Results__c;
                    mdi.CMPL123CME__Comments__c = medDevWithSubmisssions.MDI_12_Comments__c;
                    mdi.CMPL123CME__Incident_Date__c = medDevWithSubmisssions.Date_of_Incidence__c;
                     mdi.CMPL123CME__Classification_of_Incident__c = deathIndicators != null &&
                       deathIndicators.contains(medDevWithSubmisssions.Id) == true ? 'Death' : mdi.CMPL123CME__Classification_of_Incident__c;
                    mdi.Id = mdi.Id;
                    updatedMDIList.add(mdi);
                }
            }
            //Code Changes for sprint4 start By : Pavan K
            if(medDevWithSubmisssions != null && medDevWithSubmisssions.EU_MIR__r.size() >0){            
                for(CMPL123CME__EU_MIR__c mir : medDevWithSubmisssions.EU_MIR__r){
                    // 13-Sep-2021 Larry R: Dereference and gave a default value
                    // to Type_Of_Report to simplify code and increase readability
                    String repType = mir.CMPL123CME__Type_Of_Report__c;
                    if (repType == null) {
                        repType = '';
                    }

                    //----------- SET DATA DEFAULTS
                    // 14-Sep-2021 Larry R: Simplify how some values are assigned
                    String manufactEval = mir.CMPL123CME__Manufacturer_s_Evaluation__c;
                    String preliminaryResults = mir.CMPL123CME__Preliminary_Results_And_Conclusions__c;
                    String nonReportableRationale = mir.CMPL123CME__Rationale_For_Non_Reportable_Incident__c;

                    //----------- RE-ASSIGN DATA IF NECESSARY
                    mir.CMPL123CME__Classification_Of_Incident__c = deathIndicators != null && 
                        deathIndicators.contains(medDevWithSubmisssions.Id) == true ? 'Death' : mir.CMPL123CME__Classification_Of_Incident__c; 

                    //Added By Neeraj Soni on June 14th 2021 FRS-1470-07
                    //@Juneid 30 Aug 2021, Fixed applied for #126
                    //@Resnik 22-Oct-2021, Fix "null"s appearing in final string
                    mir.CMPL123CME__Incident_Description__c = mergeStringsWithNewline(
                        medDevWithSubmisssions.Describe_Event_or_Problem__c,
                        medDevWithSubmisssions.Patient_Outcome__c);
                    //@Juneid 20-Sep-2021,  Updated Rype of Report Value 'Initial Report' To 'Initial'
                    if(String.isNotBlank(repType) && 
                       (repType.equalsIgnoreCase('Initial') || repType.equalsIgnoreCase('Follow up'))){
                        preliminaryResults = medDevWithSubmisssions.Initial_Follow_Up_Mfg_Analysis_New__c;
                    } else if(String.isNotBlank(repType) && repType.equalsIgnoreCase('Final (Reportable incident)')){
                        // 14-Sep-2021 Larry R: Now blanks out Non-Reportable Rationale cuz this status IS reportable
                        nonReportableRationale = '';
                        manufactEval = medDevWithSubmisssions.Final_Mfg_Analysis_New__c;
                    } else if (repType == AspenConstants.STR_Combined_Initial_And_Final_Report) {
                        // 14-Sep-2021 Larry R: Added this condition
                        nonReportableRationale = '';
                        manufactEval = medDevWithSubmisssions.Final_Mfg_Analysis_New__c;
                    } else if (repType == AspenConstants.STR_FInal_Non_Reportable_Report) {
                        // 14-Sep-2021 Larry R: Added this condition
                        nonReportableRationale = medDevWithSubmisssions.Final_Mfg_Analysis_New__c;
                        manufactEval = '';
                    }
                    //@Juneid Defect #157 Fixed applied
                    String mdiComments = String.isNotBlank(medDevWithSubmisssions.MDI_12_Comments__c) ?  medDevWithSubmisssions.MDI_12_Comments__c  : '';
                    mdiComments = mdiComments.replace('"','');
                    
                    //----------- SET DATA
                    mir.CMPL123CME__Preliminary_Results_And_Conclusions__c = preliminaryResults; 
                    mir.CMPL123CME__Manufacturer_s_Evaluation__c = manufactEval;
                    mir.CMPL123CME__Date_Of_Incident_From__c = medDevWithSubmisssions.Date_of_Incidence__c;
                    mir.CMPL123CME__Date_Of_Incident_To__c = medDevWithSubmisssions.Date_of_Incidence__c;
                    mir.CMPL123CME__General_Comments__c = mdiComments;
                    //R7 Phase 2
                    if(mir.RecordTypeId == recordType7_2_1 || mir.RecordTypeId == recordType_GB_MIR_7_2_1){   //R8 - Added GB_MIR_7_2_1 recordtype check 
                        mir.CMPL123CME__Manufacturer_Awareness_Date__c = medDevWithSubmisssions.Initial_Awareness_Date__c;
                    }else if(mir.RecordTypeId == recordType7_3_1){
                        mir.CMPL123CME__Mfr_Reportability_awareness_date__c= medDevWithSubmisssions.Initial_Awareness_Date__c;
                    }
                    //R7 Phase 2
                    mir.CMPL123CME__Rationale_For_Non_Reportable_Incident__c = nonReportableRationale;
                    mir.Id = mir.Id;
                    updateEUMIRList.add(mir);
                }
            }
            //Code Changes for sprint4 end By : Pavan K
        }
        
        // 15-Sep-2021 Larry R: Now does allOrNothing=false for all updates
        // Updation of Records below
        if(updatedEMDRList.size() > 0){
            Database.update(updatedEMDRList, false);
        }
        if(updatedMDIList.size() > 0){
            Database.update(updatedMDIList, false);
        }
        
        //Code Changes for sprint4 start By : Pavan K
        if(updateEUMIRList.size() > 0){
            Database.update(updateEUMIRList, false);
        }
        //Code Changes for sprint4 end By : Pavan K
    }

    /**
     * Merges two potentially-null strings with a newline
     * @author Larry Resnik
     * @date 10-Oct-2021
     */
    public static String mergeStringsWithNewline(String s1, String s2) {
        String result = '';
        if (String.isNotBlank(s1) && String.isNotBlank(s2)) {
            result = s1 + '\n' + s2;
        } else if (String.isNotBlank(s1)) {
            result = s1;
        } else if (String.isNotBlank(s2)) {
            result = s2;
        }
        return result;
    }
    
    /**
     * Gets all eMDRs, MDIs, EU MIRs, and Questionnaire Items for the passed Medical Evaluation.
     * The intention is to assign related record fields from the parent Medical Evaluation.
     */
    private static List<CMPL123CME__Questionnaire__c> getCurrentRecord(Id recordId){
        //@Princy Defcet #53 Fixed
        //CHaRM-R4: CMPL123CME__H10_Addtl_Mfg_Narrative__c is replaced with CMPL123CME__H11_Additional_Mfg_Narrative__c
        //CHaRM R6: Added Field_Action_Number__c in the query.
        return [SELECT Id, B1_Adverse_Event_Product_Problem_New__c,Final_Mfg_Analysis__c,
                B2_Date_of_Death__c, B2_Outcomes_attributed_to_AE__c, Date_of_Incidence__c, Submitted_Date__c,
                Describe_Event_or_Problem__c, Patient_Outcome__c, Initial_Awareness_Date__c, Follow_Up_Awareness_Date__c,
                Final_Mfg_Analysis_New__c , Initial_Follow_Up_Mfg_Analysis_New__c , MDI_12_Comments__c,
                H9_Correction_Removal_report_No__c, Field_Action_Number__c,
                (SELECT Id, CMPL123CME__B1_AdverseEvent_ProductProblem__c, CMPL123CME__B2_Date_of_Death__c,
                 CMPL123CME__B2_Outcomes_attributed_to_AE__c, CMPL123CME__B3_Date_of_Event__c,
                 CMPL123CME__B4_Report_Date__c, CMPL123CME__B5_Describe_Event_or_Problem__c,
                 CMPL123CME__G3_Date_received_by_Mfg__c, CMPL123CME__H11_Additional_Mfg_Narrative__c,
                 CMPL123CME__H9_Correction_Removal_Report_No__c,
                 RecordTypeId, CMPL123CME__CMPL123_WF_Status__c,Field_Action_Number__c FROM EMDR__r
                 WHERE CMPL123CME__CMPL123_WF_Status__c = 'Opened' OR CMPL123CME__CMPL123_WF_Status__c = 'MFR Report # Generated'),
                (SELECT Id, CMPL123CME__Incident_Description_Narrative__c, CMPL123CME__Manufacturer_Awareness_Date__c,
                 CMPL123CME__PatientOutcome__c, CMPL123CME__Classification_of_Incident__c,
                 CMPL123CME__Manufacturer_Preliminary_Analysis__c, CMPL123CME__Manufacturer_Device_Analysis_Results__c,
                 CMPL123CME__Comments__c, CMPL123CME__Incident_Date__c, CMPL123_WF_Status__c,
                 CMPL123CME__Type_of_Report__c,Submission_Type__r.Calendar_Days__c FROM MDI__r WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND
                 CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed - Waived' AND CMPL123_WF_Status__c != 'Closed - Voided'),
                // code changes start for sprint 4
                // Larry R: This WHERE clause only fetches records whose fields are allowed to be edited becausef of their workflow status.
                // These statuses work alongside the Workflow Rules.
                // They have the same purpose as the custom setting MIR_Editable_on_Pending_Statuses__c .
                (SELECT Id, CMPL123CME__Classification_Of_Incident__c,CMPL123CME__Incident_Description__c,CMPL123CME__Preliminary_Results_And_Conclusions__c,
                 CMPL123CME__Rationale_For_Non_Reportable_Incident__c,CMPL123CME__Manufacturer_s_Evaluation__c,CMPL123CME__Date_Of_Incident_From__c,
                 CMPL123CME__Date_Of_Incident_To__c,CMPL123CME__Manufacturer_Awareness_Date__c,CMPL123CME__Type_Of_Report__c,
                 CMPL123_WF_Status__c,RecordTypeId,CMPL123CME__Mfr_Reportability_awareness_date__c
                 FROM EU_MIR__r
                 WHERE CMPL123_WF_Status__c = 'Opened'),
                // code changes end for sprint 4
                (SELECT Id, CMPL123CME__Answer__c, CMPL123CME__Question__c FROM CMPL123CME__Questionnaire_Items__r)
                FROM CMPL123CME__Questionnaire__c WHERE Id =: recordId];
    }
}