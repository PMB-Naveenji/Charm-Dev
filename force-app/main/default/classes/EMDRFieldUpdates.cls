/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
 * @What  : EMDRFieldUpdates
 * @Why   : Public claas to perform the configurations required on EMDR object.
 * @When  : 23-03-2017
 * @Where : From EMDRFieldUpdates class
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      Description 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Admin                    23-03-2017             Work ID / Case ID    Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    15-06-2020             Code Audit           Removed commented code. Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Oober                    15-07-2020             Defect #182          Adjusted if statement to copy E1 fields only for Initial EMDRs.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   rsitc                    04-08-2020             Defect #201          Added Submission Type to G7 - Type of report for Initial EMDRs.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 25-Nov-2020            Charm Upgrade        Added New Picklist Value Check in Line no: 616.
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G4_Date_received_by_MFG__c to CMPL123CME__G3_Date_received_by_Mfg__c.
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G7_Type_of_Report_MultiSelect__c to CMPL123CME__G6_Type_of_Report__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D6_Implant_Date__c to CMPL123CME__D6a_Implant_Date__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D6_Implant_Date_Null__c to CMPL123CME__D6a_Implant_Date_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D7_Explant_Date__c to CMPL123CME__D6b_Explant_Date__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D7_Explant_Date_Null__c to CMPL123CME__D6b_Explant_Date_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D8_Single_Use_Device__c to CMPL123CME__D7a_Single_Use_Device__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D9_Fax_Number__c to CMPL123CME__D7b_Fax_Number__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D9_Fax_Number_Null__c to CMPL123CME__D7b_Fax_Number_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D9_E_mail__c to CMPL123CME__D7b_E_mail__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D9_E_mail_Null__c to CMPL123CME__D7b_E_mail_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D10_Device_available_for_Eval__c to CMPL123CME__D9_Device_available_for_Eval__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D10_Date_returned_to_MFG__c to CMPL123CME__D9_Date_returned_to_Mfg__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D10_Date_Returned_to_Mfg_Null__c to CMPL123CME__D9_Date_Returned_to_Mfg_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D11_Concomitant_Null__c to CMPL123CME__D10_Concomitant_Product_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Sameer                   12-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G2_Contact_Office_Phone__c to CMPL123CME__G1_Contact_Office_Phone_Number__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Sameer                   12-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G2_Contact_Office_Phone_Null__c to CMPL123CME__G1_Contact_Office_Phone_Number_Null__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Sameer                   12-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G5_PMA_510_K__c to CMPL123CME__G4_PMA_510_k__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Sameer                   12-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G8_Adverse_Event_Term__c to CMPL123CME__G7_Adverse_Event_Term_s__c
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   oober                    31-DEC-2020            TWD Upgrade Issue    Created fieldUpdatesFromWfRules method to move EMDR WF Rules to
 *                                                                        Apex logic.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oober                    26-JAN-2021            Defect #128          Added wfActionIsChanged, wfStatusIsChanged cheks to 
 *                                                                        fieldUpdatesFromWfRules method, changed from 'Waive' to 'Void' 
 *                                                                        actions check in Voided By and Voided On Field Updates.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   rsitc                    26-FEB-2021            Defect #168          Adjusted related to "//Ack Failed WF Rule" condition in the
 *                                                                        fieldUpdatesFromWfRules method.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             22-FEB-2022            CHaRM R2.1           Replaced fields that were part of the TWD Winter '22 upgrade
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             09-FEB-2023            CHaRM R3.0           No longer assigns "E1 - Contact Email Null" because eMDR forms will now require the "E1 - Contact Email" to be filled in.
 * As a result, the eMDR specifications were changed to no longer require "E1 - Contact Email Null" to be filled under any situation. Hence, this code was changed to match requirements.
 * Similarly removed logic on "D3 - Phone Number" and its accompanying Null field. Added "with sharing".
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             21-MAR-2023            CHaRM R3.0           "E1 - Contact Email Null" was supposed to be "G1 - Contact Email Null".
 * Moved the null flavor field logic into a new function called setDefaultsAndNullFlavors.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Dinesh KUmar             15-JAN-2023            CHaRM-R4             Updated the method "autoPopulateFieldValue"
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Dinesh KUmar             12-FEB-2025            CHaRM-R6/IPDR 618    Updated the Query for 'objCountrySubmissionType'
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
public with sharing class EMDRFieldUpdates {
    
    private static CMPL123CME__Complaint_Code__c objComplaintCode = New CMPL123CME__Complaint_Code__c();
    private static List<CMPL123CME__Complaint_Code__c> statesAndCountryList = New List<CMPL123CME__Complaint_Code__c>();
    private static List<Country__c> countriesList = New List<Country__c>();
    //Added for W-000242 
    
    
    private static Country_Submission_Type__c objCountrySubmissionType = new Country_Submission_Type__c();
    
    static{
        for(CMPL123CME__Complaint_Code__c objComplaintCodeTemp 
            : [SELECT Id, Name, CMPL123CME__Type__c, 
               CMPL123CME__Name__c FROM CMPL123CME__Complaint_Code__c 
               WHERE CMPL123CME__Type__c = 'STATE CODE' OR CMPL123CME__Type__c = 'COUNTRY CODE']){
                   if(objComplaintCodeTemp.Name == 'NI'){
                       objComplaintCode = objComplaintCodeTemp;
                   }
                   statesAndCountryList.add(objComplaintCodeTemp);
               }
        
        countriesList = [ SELECT Id, Name, Country_Code__c FROM Country__c ];
        
        //Added for W-000242
        //CHaRM R6: Updated the Country - Submission Type name to 30-day and added active check in the Query.
        objCountrySubmissionType =  [
                SELECT Id, Name,Country__c
                FROM Country_Submission_Type__c
                WHERE (Name = '30-day') AND Calendar_Days__c = 30 AND Active__c = true AND(
                    Country__r.Name = 'USA' 
                    OR Country__r.Name = 'US'
                    OR Country__r.Name = 'United States')
                LIMIT 1];
    }
    
    public static Boolean isExecuted = false;
    
    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : Method to set NI in field 2 if field 1 is blank while saving and auto populate fie
    ld values
    * @Return       : N/A
    * @Params       : N/A
    **/
    public static void autoPopulateFieldValue(){
        //Added Boolean variable to avoid recursion
        if(!isExecuted || null == Trigger.oldMap){
            // Variable Declarations
            List<CMPL123CME__EMDR__c> newEMDRs = (List<CMPL123CME__EMDR__c>)Trigger.New;
            Map<Id,CMPL123CME__EMDR__c> oldEMDRMap = (Map<Id,CMPL123CME__EMDR__c>)Trigger.oldMap;
            Map<Id,CMPL123CME__EMDR__c> newEMDRMap = (Map<Id,CMPL123CME__EMDR__c>)Trigger.newMap;
            Map<Id,CMPL123CME__EMDR__c> mapInitialeMDRValuesToSupplemental = New Map<Id,CMPL123CME__EMDR__c>();
            Set<String> ticketIdSet = new Set<String>();
            Map<String,Contact__c> ticketWithContactMap = new Map<String,Contact__c>();
            Set<Id> medicalEvlas = new Set<Id>();
            Set<Id> setProductTicketIds = new Set<Id>();
            Set<Id> regSitesSet = new Set<Id>();
            Map<String,String> recordTypeNameWithIdMap;
            Map<String,Date> returnDateMap = new Map<String,Date>();
            Map<String, CMPL123CME__Registered_Site__c> regSitesMap = new Map<String, CMPL123CME__Registered_Site__c>();
            Map<Id, CMPL123CME__Questionnaire__c> medEvalMap = new Map<Id, CMPL123CME__Questionnaire__c>();
            Map<String, Product_Ticket__c>  mapProductTickets = new Map<String, Product_Ticket__c>();
            // Def #201/CHARM-3078: added submissionTypeIds and mapSubmissionTypes
            Set<Id> submissionTypeIds = new Set<Id>();
            Map<Id, Country_Submission_Type__c>  mapSubmissionTypes = new Map<Id, Country_Submission_Type__c>();

            // Collect record type Id with name in map.
            if(recordTypeNameWithIdMap == null){
                recordTypeNameWithIdMap = new Map<String,String>();
                for(RecordType rt : [SELECT Id, Name, SobjectType FROM RecordType 
                                     Where SobjectType  = 'CMPL123CME__EMDR__c']){
                                         recordTypeNameWithIdMap.put(rt.Name, rt.Id);
                                         recordTypeNameWithIdMap.put(rt.Id,rt.Name);
                                     }
            }
            
            //Collect all parent medical evaluations
            //Added W-000231 Description:Autopoulation of 'G4 Date recieved by MFG' on Medical Evaluation change
            for(CMPL123CME__EMDR__c emdr : newEMDRs){
                if(emdr.CMPL123CME__CMPL123_WF_Action__c != null && emdr.CMPL123CME__CMPL123_WF_Action__c.containsIgnoreCase('failed')){
                    emdr.CMPL123CME__CMPL123Task_Key_Value__c = '';
                }
                // Workflow : ADDS3 Update defaults in EMDR
                if(String.isBlank(emdr.CMPL123CME__D9_Device_available_for_Eval__c) == true || String.isBlank(emdr.CMPL123CME__D5_Operator_of_Device__c) == true){
                    emdr.CMPL123CME__D9_Device_available_for_Eval__c = AspenConstants.STR_Yes;
                    emdr.CMPL123CME__D5_Operator_of_Device__c = 'Health Professional';
                    emdr.CMPL123CME__H5_Labeled_for_Single_Use__c = AspenConstants.STR_No;
                }
                
                
                
                CMPL123CME__EMDR__c oldEMDRId = Trigger.isUpdate && oldEMDRMap != null ? oldEMDRMap.get(emdr.ID) : null;
                if(emdr.Medical_Evaluation__c != null && (oldEMDRId != null && emdr.Medical_Evaluation__c != oldEMDRId.Medical_Evaluation__c) && recordTypeNameWithIdMap != null && recordTypeNameWithIdMap.get(Emdr.RecordTypeId) == 'Supplemental' ){
                       
                       emdr.CMPL123CME__G3_Date_received_by_Mfg__c = emdr.Follow_Up_Awareness_Date__c != null 
                           ? emdr.Follow_Up_Awareness_Date__c : null;  
                   } 
                
                if(Trigger.isInsert && Trigger.isBefore 
                   && recordTypeNameWithIdMap.get(emdr.RecordTypeId) == 'Supplemental' && emdr.CMPL123CME__Initial_MDR__c != null) {
                       mapInitialeMDRValuesToSupplemental.put(emdr.CMPL123CME__Initial_MDR__c, null);
                   }
                if(emdr.Medical_Evaluation__c != null){
                    medicalEvlas.add(emdr.Medical_Evaluation__c);
                }
                if(emdr.CMPL123CME__Registered_Site__c != null){
                    regSitesSet.add(emdr.CMPL123CME__Registered_Site__c);
                }
                if(emdr.Product__c != null){
                    setProductTicketIds.add(emdr.Product__c);
                }
                
                //Added for W-000242 - Populating '30 Days' to Submission Type for Supplemental EMDR
                if((recordTypeNameWithIdMap.get(emdr.RecordTypeId) == 'Supplemental') 
                   && objCountrySubmissionType != null && emdr.Ticket_Review__c == null){
                    emdr.Submission_Type__c = objCountrySubmissionType.id;
                }

                // Def #201/CHARM-3078: collect Submission_Type__c ids
                if (emdr.Submission_Type__c != null) {
                    submissionTypeIds.add(emdr.Submission_Type__c);
                }  
            }
            if(setProductTicketIds.size() > 0){
                //Collect products related to EMDR 
                //CHaRM-R4: Added Unique Device Identified in the query to map CMPL123CME__D4_Primary_UDI_Number__c
                for(Product_Ticket__c objProductTicket : [
                    SELECT Id, Product__c, Batch_Lot_Serial__c, Product__r.Registered_Site__c,
                    Product__r.FDA_Product_Code__c, GTIN_Static__c, Unique_Device_Identifier__c, Product__r.Product_Common_Name__c,
                    Product_List_Number__c, Product__r.X510K_Number__c, Product__r.Product_Brand_Name__c
                    FROM Product_Ticket__c WHERE Id IN: setProductTicketIds])
                {
                    mapProductTickets.put(objProductTicket.Id, objProductTicket);
                }
            }
            
            if(regSitesSet.size() > 0){
                // Collect registered site related to EMDR
                for(CMPL123CME__Registered_Site__c regSite : [
                    SELECT Id,Name,G1_Mfg_Site_Postal_Code__c, G1_Contact_Office_Country__c, Mfg_Site_Country__c,
                    CMPL123CME__G1_Contact_Office_Region_State__c,G1_Mfg_Site_Zip_Code__c,
                    G1_Mfg_Site_Zip_Code_Extension__c, G1_Mfg_Site_Region_State__c,
                    CMPL123CME__G1_Contact_Office_Country__c, CMPL123CME__G2_Contact_Office_Phone_Number__c,
                    G1_Mfg_Site_Address_1__c, G1_Mfg_Site_Address_2__c, G1_Mfg_Site_City__c, G1_Mfg_Site_Email__c,
                    G1_Mfg_Site_Fax_Number__c, G1_Mfg_Site_Name__c, G1_Mfg_Site_Phone_Number__c, 
                    CMPL123CME__G1_Contact_Office_Postal_Code__c, CMPL123CME__G1_Contact_Office_Title__c,
                    CMPL123CME__G1_Contact_Office_Zip_Code__c, CMPL123CME__G1_Contact_Office_Zip_Code_Extension__c,
                    CMPL123CME__G1_Contact_Office_Fax_Number__c, CMPL123CME__G1_Contact_Office_Address_1__c,
                    CMPL123CME__G1_Contact_Office_Address_2__c, CMPL123CME__G1_Contact_Office_City__c, 
                    CMPL123CME__G1_Contact_Office_Division_Name__c, CMPL123CME__G1_Contact_Office_E_mail__c,
                    CMPL123CME__G1_Contact_Office_Facility_Name__c, CMPL123CME__G1_Contact_Office_First_Name__c,
                    CMPL123CME__G1_Contact_Office_Last_Name__c, CMPL123CME__G1_Contact_Office_Middle_Name__c
                    FROM CMPL123CME__Registered_Site__c WHERE Id IN: regSitesSet])
                {
                    regSitesMap.put(regSite.Id, regSite);
                }
            }
            
            if(medicalEvlas.size() > 0){
                // Collect related medical evaluations
                // Added - W-000080 - B1_Adverse_Event_Product_Problem_New__c instead of B1_Adverse_Event_Product_Problem__c
                for(CMPL123CME__Questionnaire__c medEval : [
                    SELECT Id, Final_Mfg_Analysis__c, Evaluator__c,
                    B1_Adverse_Event_Product_Problem_New__c, B2_Outcomes_attributed_to_AE__c,
                    H9_Correction_Removal_report_No__c, Expiration_Date__c, B2_Date_of_Death__c,
                    Date_of_Incidence__c, Describe_Event_or_Problem__c, Patient_Outcome__c,
                    Initial_Awareness_Date__c,Follow_Up_Awareness_Date__c , Final_Mfg_Analysis_New__c, Initial_Follow_Up_Mfg_Analysis_New__c
                    FROM CMPL123CME__Questionnaire__c WHERE Id IN: medicalEvlas])
                {
                    medEvalMap.put(medEval.Id, medEval);
                }
            }
            
            //W-000131 - Collect NI from Complaint Code
            if(!mapInitialeMDRValuesToSupplemental.isEmpty()){
                Set<Id> setEMDRIDs = mapInitialeMDRValuesToSupplemental.keySet();
                String strQuery = 'SELECT ';
                for(Schema.FieldSetMember f : SObjectType.CMPL123CME__EMDR__c.FieldSets.Follow_up_auto_populate.getFields()) {
                    strQuery += f.getFieldPath() + ', ';
                }
                strQuery += ' Id,Follow_Up_Awareness_Date__c FROM CMPL123CME__EMDR__c WHERE Id IN: setEMDRIDs';
                for(CMPL123CME__EMDR__c objEMDR : database.query(strQuery)){
                    mapInitialeMDRValuesToSupplemental.put(objEMDR.Id,objEMDR);
                }
            }

            // Def #201/CHARM-3078: query related Country_Submission_Type__c 
            if (!submissionTypeIds.isEmpty()) {
                mapSubmissionTypes = new Map<Id, Country_Submission_Type__c>(
                    [SELECT Name FROM Country_Submission_Type__c WHERE Id IN :submissionTypeIds]
                );
            }

            // Update fields
            for(CMPL123CME__EMDR__c emdr : newEMDRs){
                
                CMPL123CME__EMDR__c oldEMDRId = Trigger.isUpdate && oldEMDRMap != null ? oldEMDRMap.get(emdr.ID) : null;

                // Def #201/CHARM-3078: set G7 - Type of report with record type and submission type upon creation of initial EMDR
                if (Trigger.isInsert && recordTypeNameWithIdMap != null && recordTypeNameWithIdMap.get(Emdr.RecordTypeId) == 'Initial') {
                    emdr.CMPL123CME__G6_Type_of_Report__c = emdr.Submission_Type__c != null ? recordTypeNameWithIdMap.get(Emdr.RecordTypeId) 
                        + ';' + mapSubmissionTypes.get(emdr.Submission_Type__c).Name : recordTypeNameWithIdMap.get(Emdr.RecordTypeId); 
                }

                //W-000131 - set CMPL123CME__F3_Region_State__c to NI if blank upon save.
                emdr.CMPL123CME__F3_Region_State__c = emdr.CMPL123CME__F3_Region_State__c == null && objComplaintCode != null && objComplaintCode.Id != null ?
                        objComplaintCode.id : emdr.CMPL123CME__F3_Region_State__c;


                //W-000131 - set CMPL123CME__F14_Region_State__c to NI if blank upon save.
                emdr.CMPL123CME__F14_Region_State__c = emdr.CMPL123CME__F14_Region_State__c == null && objComplaintCode != null && objComplaintCode.Id != null ?
                        objComplaintCode.id : emdr.CMPL123CME__F14_Region_State__c;

                //Process builder - Update FDA status on eMDR
                if(emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT){
                    emdr.FDA_Status__c = null;
                } 
                
                //Process Builder - update eMDR status to Pass
                if(emdr.CMPL123CME__CMPL123_WF_Status__c == 'Pending Closure'){
                    emdr.FDA_Status__c = 'Pass';
                }

                // Workflow : ADDS3 update medical evaluation based fields in EMDR
                if((emdr.Medical_Evaluation__c != null &&  recordTypeNameWithIdMap != null && 
                    recordTypeNameWithIdMap.get(Emdr.RecordTypeId) == 'Initial' ) && (
                        (Trigger.isInsert) || 
                        (oldEMDRId != null && emdr.Medical_Evaluation__c != oldEMDRId.Medical_Evaluation__c)))
                {

                    emdr.CMPL123CME__H9_Correction_Removal_Report_No__c = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).H9_Correction_Removal_report_No__c!= null
                        ? medEvalMap.get(emdr.Medical_Evaluation__c).H9_Correction_Removal_report_No__c
                        : null;

                    //Set B2 - Outcomes attributed to AE with Medical Evaluation.B2 - Outcomes attributed to AdverseEvent.
                    emdr.CMPL123CME__B2_Outcomes_attributed_to_AE__c  = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c) != null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).B2_Outcomes_attributed_to_AE__c != null ?
                        medEvalMap.get(emdr.Medical_Evaluation__c).B2_Outcomes_attributed_to_AE__c : 
                    null;

                    emdr.CMPL123CME__B1_AdverseEvent_ProductProblem__c = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).B1_Adverse_Event_Product_Problem_New__c!= null
                        ? medEvalMap.get(emdr.Medical_Evaluation__c).B1_Adverse_Event_Product_Problem_New__c
                        : null;

                    emdr.CMPL123CME__D4_Expiration_Date__c = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).Expiration_Date__c!= null
                        ? medEvalMap.get(emdr.Medical_Evaluation__c).Expiration_Date__c
                        : null;

                    emdr.CMPL123CME__B2_Date_of_Death__c = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).B2_Date_of_Death__c!= null
                        ? medEvalMap.get(emdr.Medical_Evaluation__c).B2_Date_of_Death__c
                        : null;

                    emdr.CMPL123CME__B3_Date_of_Event__c = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).Date_of_Incidence__c!= null
                        ? medEvalMap.get(emdr.Medical_Evaluation__c).Date_of_Incidence__c
                        : null;
                    
                    String EMDRB5Desc = '';
                    EMDRB5Desc = medEvalMap.get(emdr.Medical_Evaluation__c).Describe_Event_or_Problem__c + ' ' +medEvalMap.get(emdr.Medical_Evaluation__c).Patient_Outcome__c;
                    emdr.CMPL123CME__B5_Describe_Event_or_Problem__c = medEvalMap != null && (medEvalMap.get(emdr.Medical_Evaluation__c).Describe_Event_or_Problem__c != null ||
                                                                                            medEvalMap.get(emdr.Medical_Evaluation__c).Patient_Outcome__c != null) && EMDRB5Desc.length() <= 32768 ?
                        EMDRB5Desc : (medEvalMap.get(emdr.Medical_Evaluation__c).Describe_Event_or_Problem__c != null ||
                                    medEvalMap.get(emdr.Medical_Evaluation__c).Patient_Outcome__c != null) && EMDRB5Desc.length() > 32768 ?
                                        EMDRB5Desc.subString(0,32768)
                                        : emdr.CMPL123CME__B5_Describe_Event_or_Problem__c;
                    
                    emdr.CMPL123CME__G3_Date_received_by_Mfg__c = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).Initial_Awareness_Date__c!= null
                        ? medEvalMap.get(emdr.Medical_Evaluation__c).Initial_Awareness_Date__c
                        : null;
                    //CHaRM-R4: CMPL123CME__H10_Addtl_Mfg_Narrative__c is replaced with CMPL123CME__H11_Additional_Mfg_Narrative__c
                    //emdr.CMPL123CME__H10_Addtl_Mfg_Narrative__c = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                    emdr.CMPL123CME__H11_Additional_Mfg_Narrative__c = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).Final_Mfg_Analysis_New__c != null
                        ? medEvalMap.get(emdr.Medical_Evaluation__c).Final_Mfg_Analysis_New__c 
                        : medEvalMap.get(emdr.Medical_Evaluation__c).Initial_Follow_Up_Mfg_Analysis_New__c  != null
                            ? medEvalMap.get(emdr.Medical_Evaluation__c).Initial_Follow_Up_Mfg_Analysis_New__c  
                            : null;
                } 
                // Set contact based fields in the EMDR.
                CMPL123CME__EMDR__c oldEMDR = Trigger.isUpdate && oldEMDRMap != null ? oldEMDRMap.get(emdr.ID) : null;
                if((emdr.CMPL123CME__Complaint__c != null && oldEMDR == null)
                   || (oldEMDR != null && emdr.CMPL123CME__Complaint__c != oldEMDR.CMPL123CME__Complaint__c)){
                       ticketIdSet.add(emdr.CMPL123CME__Complaint__c);
                   }
                
                if(emdr.Product__c != null && mapProductTickets != null &&  
                   mapProductTickets.get(emdr.Product__c) != null &&
                   mapProductTickets.get(emdr.Product__c).Product__c != null &&
                   mapProductTickets.get(emdr.Product__c).Product__r.Registered_Site__c != null &&
                   emdr.Ticket_Review__c == null){
                       emdr.CMPL123CME__Registered_Site__c = ((oldEMDR == null || emdr.Product__c != oldEMDR.Product__c) ? mapProductTickets.get(emdr.Product__c).Product__r.Registered_Site__c :
                                                              emdr.CMPL123CME__Registered_Site__c);
                   }
                
                //Workflow : ADDS3 update product - ticket based fields in EMDR
                if(emdr.Product__c != null && mapProductTickets != null &&  
                   mapProductTickets.get(emdr.Product__c) != null &&
                   mapProductTickets.get(emdr.Product__c).Product__c != null &&
                   ((Trigger.isInsert && recordTypeNameWithIdMap != null && 
                   recordTypeNameWithIdMap.get(Emdr.RecordTypeId) != 'Supplemental' ) || 
                   (oldEMDRId != null && emdr.Product__c != oldEMDRId.Product__c))){
                       
                       emdr.CMPL123CME__D2b_Procode__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Product__c != null &&
                           mapProductTickets.get(emdr.Product__c).Product__r.FDA_Product_Code__c != null ?
                           mapProductTickets.get(emdr.Product__c).Product__r.FDA_Product_Code__c:
                       null;
                       
                       emdr.CMPL123CME__Registered_Site__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Product__c != null &&
                           mapProductTickets.get(emdr.Product__c).Product__r.Registered_Site__c != null ?
                           mapProductTickets.get(emdr.Product__c).Product__r.Registered_Site__c:
                       null;
                       //CHaRM-R4-Start: EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c".
                       //And mapping the CMPL123CME__D4_Primary_UDI_Number__c with Unique_Device_Identifier__c field from Product-Ticket.
                       /*emdr.CMPL123CME__Unique_Identifier_UDI__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).GTIN_Static__c != null ?
                           mapProductTickets.get(emdr.Product__c).GTIN_Static__c:
                       null;*/
                       emdr.CMPL123CME__D4_Primary_UDI_Number__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Unique_Device_Identifier__c != null ?
                           mapProductTickets.get(emdr.Product__c).Unique_Device_Identifier__c:
                       null;
                       //CHaRM-R4-End
                       emdr.CMPL123CME__D2_Common_Device_Name__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Product__c != null &&
                           mapProductTickets.get(emdr.Product__c).Product__r.Product_Common_Name__c != null ?
                           mapProductTickets.get(emdr.Product__c).Product__r.Product_Common_Name__c:
                       null;
                       
                       emdr.CMPL123CME__D4_Catalog_No__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Product_List_Number__c != null ?
                           mapProductTickets.get(emdr.Product__c).Product_List_Number__c:
                       null;
                       
                       emdr.CMPL123CME__D1_Brand_Name__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Product__c != null &&
                           mapProductTickets.get(emdr.Product__c).Product__r.Product_Brand_Name__c != null ?
                           mapProductTickets.get(emdr.Product__c).Product__r.Product_Brand_Name__c:
                       null;
                       
                       //(SA)emdr.CMPL123CME__G5_PMA_510_K__c = mapProductTickets != null &&
                       emdr.CMPL123CME__G4_PMA_510_k__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Product__c != null &&
                           mapProductTickets.get(emdr.Product__c).Product__r.X510K_Number__c != null ?
                           mapProductTickets.get(emdr.Product__c).Product__r.X510K_Number__c:
                       null;
                       
                       emdr.CMPL123CME__D4_Lot_No__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Batch_Lot_Serial__c  != emdr.Complaint_Serial__c ?
                           mapProductTickets.get(emdr.Product__c).Batch_Lot_Serial__c:
                       null;
                       
                       emdr.CMPL123CME__D4_Serial_No__c = mapProductTickets != null &&
                           mapProductTickets.get(emdr.Product__c) != null && 
                           mapProductTickets.get(emdr.Product__c).Batch_Lot_Serial__c  == emdr.Complaint_Serial__c ?
                           mapProductTickets.get(emdr.Product__c).Batch_Lot_Serial__c:
                       null;
                }
                
                // Workflow : ADDS3 update registered site MFG based information fields in EMDR
                // Workflow : ADDS3 update registered site based basic inforrmation fields in EMDR
                // Workflow : ADDS3 update registered site contact based information fields in EMDR
                if((Trigger.isInsert && emdr.CMPL123CME__Registered_Site__c  != null &&  recordTypeNameWithIdMap != null && 
                    recordTypeNameWithIdMap.get(Emdr.RecordTypeId) != 'Supplemental' ) || ( 
                        emdr.CMPL123CME__Registered_Site__c != null && 
                        (oldEMDRId != null && emdr.CMPL123CME__Registered_Site__c != oldEMDRId.CMPL123CME__Registered_Site__c))){
                            
                            // G1 - Mfg Site Country field update
                            emdr.G1_Mfg_Site_Country_New2__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null
                                && regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).Mfg_Site_Country__c != null
                                ? regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).Mfg_Site_Country__c : null;
                            
                            
                            emdr.D3_Region_State_New__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Region_State__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Region_State__c:
                            null;
                            
                            emdr.G1_Contact_Office_Region_State_New__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Region_State__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Region_State__c:
                            null;
                            
                            emdr.G1_Mfg_Site_Region_State_New__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Region_State__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Region_State__c:
                            null;
                            
                            emdr.D3_Country_New__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).Mfg_Site_Country__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).Mfg_Site_Country__c:
                            null;
                            
                            emdr.G1_Contact_Office_Country_New__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Country__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Country__c:
                            null;
                            
                            //Updated postal code logic, #882
                            if(regSitesMap != null && regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null){
                                String zipCodeWithExt;
                                if(regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Zip_Code__c != null){
                                    zipCodeWithExt = regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Zip_Code__c;
                                    if(zipCodeWithExt != null 
                                       && regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Zip_Code_Extension__c != null){
                                        zipCodeWithExt += '-' + regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Zip_Code_Extension__c;
                                    }
                                }
                                emdr.CMPL123CME__G1_Mfg_Postal_Code__c = regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Postal_Code__c != null 
                                    ? regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Postal_Code__c : zipCodeWithExt;
                                
                                emdr.CMPL123CME__D3_Postal_Code__c = regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Postal_Code__c != null 
                                    ? regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Postal_Code__c : zipCodeWithExt;
                            }
                            //(SA) emdr.CMPL123CME__G2_Contact_Office_Phone__c = regSitesMap != null &&
                            emdr.CMPL123CME__G1_Contact_Office_Phone_Number__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G2_Contact_Office_Phone_Number__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G2_Contact_Office_Phone_Number__c:
                            null;
                            
                            emdr.CMPL123CME__D3_Address__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Address_1__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Address_1__c:
                            null;
                            
                            emdr.CMPL123CME__D3_Address2__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Address_2__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Address_2__c:
                            null;
                            
                            emdr.CMPL123CME__D3_City__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_City__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_City__c:
                            null;
                            
                            emdr.CMPL123CME__D3_Email__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Email__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Email__c:
                            null;
                            
                            emdr.CMPL123CME__D3_Fax_Number__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Fax_Number__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Fax_Number__c:
                            null;
                            
                            emdr.CMPL123CME__D3_Name__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Name__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Name__c:
                            null;
                            
                            // 15-FEB-2023 Larry: Commented this assignment because "D3 - Phone Number" is not on the UI anymore
                            // emdr.CMPL123CME__D3_Phone_Number__c = regSitesMap != null &&
                            //     regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                            //     regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Phone_Number__c != null ?
                            //     regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Phone_Number__c:
                            // null;
                            //Updated postal code logic, #882
                            if(regSitesMap != null && regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null){
                                String zipCodeWithExt;
                                if(regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Zip_Code__c != null){
                                    zipCodeWithExt = regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Zip_Code__c;
                                    if(zipCodeWithExt != null && regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Zip_Code_Extension__c != null){
                                        zipCodeWithExt += '-' + regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Zip_Code_Extension__c;
                                    }
                                }
                                emdr.CMPL123CME__G1_Contact_Office_Postal_Code__c = regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Postal_Code__c != null ? regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Postal_Code__c : zipCodeWithExt;
                            }
                            emdr.CMPL123CME__G1_Mfg_Address__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Address_1__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Address_1__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Mfg_Address_2__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Address_2__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Address_2__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Mfg_City__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_City__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_City__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Mfg_Email__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Email__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Email__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Mfg_Fax_Number__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Fax_Number__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Fax_Number__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Mfg_Name__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Name__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Name__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_Fax_Number__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Fax_Number__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Fax_Number__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_Address__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Address_1__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Address_1__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_Address2__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Address_2__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Address_2__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_City__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_City__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_City__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_Division_Name__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Division_Name__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Division_Name__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_E_mail__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_E_mail__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_E_mail__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_Facility_Name__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Facility_Name__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Facility_Name__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_First_Name__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_First_Name__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_First_Name__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_Last_Name__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Last_Name__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Last_Name__c:
                            null;
                            
                            emdr.CMPL123CME__G1_Contact_Office_Middle_Name__c = regSitesMap != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Middle_Name__c != null ?
                                regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).CMPL123CME__G1_Contact_Office_Middle_Name__c:
                            null;   
                        }
                //Set B1 - Adverse Event/Product Problem with Medical Evaluation.B1 - Adverse Event/Product Problem value.
                // Added - W-000080 - B1_Adverse_Event_Product_Problem_New__c instead of B1_Adverse_Event_Product_Problem__c
                
                //Added - W-000111 - only for Insert
                if(Trigger.isInsert) {
                    
                    if(Trigger.isBefore && recordTypeNameWithIdMap.get(emdr.RecordTypeId) == 'Supplemental' 
                       && emdr.CMPL123CME__Initial_MDR__c != null && !mapInitialeMDRValuesToSupplemental.isEmpty() 
                       && mapInitialeMDRValuesToSupplemental.containsKey(emdr.CMPL123CME__Initial_MDR__c) && 
                       mapInitialeMDRValuesToSupplemental.get(emdr.CMPL123CME__Initial_MDR__c) != null){
                           emdr.CMPL123CME__G6_Type_of_Report__c = 'Follow Up';
                           emdr.CMPL123CME__CMPL123Rule_Key_Value__c = 'EMDR_WORKFLOW_SUPPLEMENTAL';
                           emdr.CMPL123CME__G3_Date_received_by_Mfg__c = mapInitialeMDRValuesToSupplemental.get(emdr.CMPL123CME__Initial_MDR__c).Follow_Up_Awareness_Date__c;
                           
                           for(Schema.FieldSetMember f: SObjectType.CMPL123CME__EMDR__c.FieldSets.Follow_up_auto_populate.getFields()) {
                               emdr.put(f.getFieldPath(), mapInitialeMDRValuesToSupplemental.get(emdr.CMPL123CME__Initial_MDR__c).get(f.getFieldPath()));
                           }     
                       }
                    
                    //Set D11 - Concomitant Product - Null to NI
                    emdr.CMPL123CME__D10_Concomitant_Product_Null__c = emdr.CMPL123CME__D10_Concomitant_Product_Null__c == null ? 'NI' : emdr.CMPL123CME__D10_Concomitant_Product_Null__c;
                    //Start: Charm Upgrade - Lakshman
                    //emdr.CMPL123CME__EMDR_Form_Version__c = emdr.CMPL123CME__EMDR_Form_Version__c == null ? '2021 Nov-30' : emdr.CMPL123CME__EMDR_Form_Version__c;
                    //End: Charm Upgrade - Lakshman
                    //CHaRM-R4: Commented the above EMDR version "2021 Nov-30" and replaced with "2023" version in Custom label by Dinesh Kumar
                    emdr.CMPL123CME__EMDR_Form_Version__c = emdr.CMPL123CME__EMDR_Form_Version__c == null ? Label.EMDR_Form_Version : emdr.CMPL123CME__EMDR_Form_Version__c;
                    emdr.Medical_Evaluator__c = medEvalMap != null && emdr.Medical_Evaluation__c != null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c) != null &&
                        medEvalMap.get(emdr.Medical_Evaluation__c).Evaluator__c != null ?
                        medEvalMap.get(emdr.Medical_Evaluation__c).Evaluator__c :
                    emdr.Medical_Evaluator__c;
                }
                
                // Registered_Site_No_Update field update
                emdr.CMPL123CME__Registered_Site_No__c = regSitesMap != null &&
                    regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null
                    && regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).Name != null
                    ? regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).Name : emdr.CMPL123CME__Registered_Site_No__c;
                    
                // Set D3 - Region State field value with Registered Site.G1 - Mfg Site Region (State) value.
                
                for(CMPL123CME__Complaint_Code__c country : statesAndCountryList){
                    
                    emdr.CMPL123CME__G1_Contact_Office_Country__c = regSitesMap != null &&
                        country.CMPL123CME__Type__c == 'COUNTRY CODE' && Trigger.isUpdate &&
                        regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null
                        && regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Contact_Office_Country__c != null &&
                        String.valueof(regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Contact_Office_Country__c) 
                        == country.CMPL123CME__Name__c ? country.Id : emdr.CMPL123CME__G1_Contact_Office_Country__c;
                    
                    
                    // D3 - Region (State) field update
                    emdr.CMPL123CME__D3_Region_State__c = emdr.CMPL123CME__D3_Region_State__c == null &&
                        regSitesMap != null &&
                        country.CMPL123CME__Type__c == 'STATE CODE' && Trigger.isUpdate &&
                        regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                        regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Region_State__c != null &&
                        regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Region_State__c == 
                        country.CMPL123CME__Name__c ? country.Id : emdr.CMPL123CME__D3_Region_State__c;
                    
                    emdr.F3_Region_State_Code__c  = 
                        country.CMPL123CME__Type__c == 'STATE CODE' && emdr.CMPL123CME__F3_Region_State__c == country.Id?
                        country.Name : emdr.F3_Region_State_Code__c;
                    
                    emdr.F14_Region_State_Code__c  = 
                        country.CMPL123CME__Type__c == 'STATE CODE' && emdr.CMPL123CME__F14_Region_State__c == country.Id?
                        country.Name : emdr.F14_Region_State_Code__c;
                    
                    // G1 - Mfg Site Region (State) field update
                    emdr.CMPL123CME__G1_Mfg_Site_Region_State__c = emdr.CMPL123CME__G1_Mfg_Site_Region_State__c == null &&
                        regSitesMap != null &&
                        country.CMPL123CME__Type__c == 'STATE CODE' && Trigger.isUpdate &&
                        regSitesMap.get(emdr.CMPL123CME__Registered_Site__c) != null &&
                        regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Region_State__c != null &&
                        regSitesMap.get(emdr.CMPL123CME__Registered_Site__c).G1_Mfg_Site_Region_State__c == 
                        country.CMPL123CME__Name__c ? country.Id : emdr.CMPL123CME__G1_Mfg_Site_Region_State__c;
                    
                }
                
                
            }   
            
            Map<String, CMPL123CME__Complaint__c> ticketWithCustomerMap = New Map<String, CMPL123CME__Complaint__c>();
            if(ticketIdSet.size() > 0){
                for(CMPL123CME__Complaint__c ticket 
                    : [SELECT Id,Division__c,CMPL123CME__Customer__r.Country__c,CMPL123CME__Customer__c,CMPL123CME__Customer__r.Zip_Postal_Code__c,
                       CMPL123CME__Customer__r.Name,CMPL123CME__Customer__r.State__c,CMPL123CME__Customer__r.Customer_Name_Translated__c,
                       CMPL123CME__Customer__r.Contact_Address_Line_1__c,CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c,
                       CMPL123CME__Customer__r.Contact_Address_Line_2__c,CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c,
                       CMPL123CME__Customer__r.City__c,CMPL123CME__Customer__r.Customer_City_Translated__c,CMPL123CME__Customer__r.Customer_State__c,
                       (SELECT Id, Name, City__c, Country__c, 
                        Contact_Email__c, State__c, Contact_Fax__c, Contact_Phone_Number__c, 
                        Zip_Postal_Code__c, Customer_Name__c, Primary__c, pRE__c,Address_Area_Line_1__c,
                        Address_Area_Line_2__c,Occupation__c, Contact_Occupation_Translated__c,Customer_Name__r.Name,Name__c,
                        Contact_Name_Translated__c,Customer_Name_Translated__c,Customer_Name__r.Contact_Address_Line_1__c,
                        Customer_Name__r.Customer_Address_Line_1_Translated__c,Customer_Name__r.Contact_Address_Line_2__c,
                        Customer_Name__r.Customer_Address_Line_2_Translated__c,Customer_Name__r.City__c,
                        Customer_Name__r.Customer_City_Translated__c,Customer_Name__r.State__c,
                        Customer_Name__r.Customer_State__c,External_ID__c
                        FROM Related_Contact__r WHERE (pRE__c = true OR Primary__c = true) AND External_ID__c != null AND Delete_Flag__c = false ORDER BY External_ID__c NULLS LAST),
                       (SELECT Id, Name,Ticket__c,Date_Return_Received__c FROM Returns__r)
                       FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIdSet]){
                           
                           ticketWithCustomerMap.put(ticket.Id,ticket);
                           
                           if(ticket.Related_Contact__r.size() > 0){
                               Contact__c pREContactExternal;
                               Contact__c primaryContactExternal;
                               Contact__c pREContact;
                               Contact__c primaryContact;
                               
                               for(Contact__c contactRecord : ticket.Related_Contact__r){
                                   if(pREContactExternal == null && contactRecord.pRE__c && contactRecord.External_ID__c != null){
                                       pREContactExternal = contactRecord;    
                                   }else if(primaryContactExternal == null && contactRecord.Primary__c && contactRecord.External_ID__c != null){
                                       primaryContactExternal = contactRecord;
                                   }else if(pREContact == null && contactRecord.pRE__c){
                                       pREContact = contactRecord;    
                                   }else if(primaryContact == null && contactRecord.Primary__c){
                                       primaryContact = contactRecord;
                                   }
                               }
                               
                               if(pREContactExternal != null || primaryContactExternal != null || pREContact != null || primaryContact != null ){    
                                   if(pREContactExternal != null){
                                       ticketWithContactMap.put(ticket.Id, pREContactExternal);
                                   }else if(primaryContactExternal != null){
                                       ticketWithContactMap.put(ticket.Id, primaryContactExternal);
                                   }else if(pREContact != null){
                                       ticketWithContactMap.put(ticket.Id, pREContact);
                                   }else{
                                       ticketWithContactMap.put(ticket.Id, primaryContact); 
                                   }
                               }
                           }
                           if(ticket.Returns__r.size() > 0){
                               for(Return__c ticketReturn : ticket.Returns__r){
                                   returnDateMap.put(ticketReturn.Ticket__c, ticketReturn.Date_Return_Received__c);
                               }
                           }
                       }           
            }
            for(CMPL123CME__EMDR__c emdr : newEMDRs){
                if(returnDateMap.get(emdr.CMPL123CME__Complaint__c) != null){
                    emdr.CMPL123CME__D9_Date_returned_to_Mfg__c = returnDateMap.get(emdr.CMPL123CME__Complaint__c);
                }
                //Defect #182 fix (Added emdr.RecordTypeId == Label.EMDR_Initial_Record_Type_Id to if statement to copy E1 fields only for Initial EMDRs)
                if(ticketWithContactMap.get(emdr.CMPL123CME__Complaint__c) != null && emdr.RecordTypeId == Label.EMDR_Initial_Record_Type_Id){
                    Contact__c contactRecord = ticketWithContactMap.get(emdr.CMPL123CME__Complaint__c);
                    CMPL123CME__Complaint__c customerRecord = ticketWithCustomerMap.get(emdr.CMPL123CME__Complaint__c);
                    if(customerRecord != null){
                        emdr.Division__c = customerRecord != null &&
                            customerRecord.Division__c != null ?
                            customerRecord.Division__c :
                        emdr.Division__c;
                        // Worflow: ADD Update Customer based information fields in EMDR
                        emdr.E1_Country_New__c = customerRecord != null && customerRecord.CMPL123CME__Customer__r.Country__c != null ?
                            customerRecord.CMPL123CME__Customer__r.Country__c : emdr.E1_Country_New__c;
                        
                        emdr.E1_Region_State_New__c = (customerRecord.CMPL123CME__Customer__r.Customer_State__c != null ? 
                                                       customerRecord.CMPL123CME__Customer__r.Customer_State__c
                                                       : (customerRecord.CMPL123CME__Customer__r.State__c != null ? 
                                                          customerRecord.CMPL123CME__Customer__r.State__c : emdr.E1_Region_State_New__c));
                        
                        
                        emdr.CMPL123CME__E1_Address_1__c = (customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c != null ? 
                                                            (customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c.length() > 30 ? customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c.substring(0,30) : customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c)
                                                            :(customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_1__c != null ? 
                                                              (customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_1__c.length() > 30 ? String.valueOf(customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_1__c).substring(0,30) : String.valueOf(customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_1__c))
                                                              : emdr.CMPL123CME__E1_Address_1__c));
                        
                        emdr.CMPL123CME__E1_Address2__c = (customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c != null ? 
                                                           (customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c.length() > 30 ? customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c.substring(0,30) : customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c)
                                                           :(customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_2__c != null ? 
                                                             (customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_2__c.length() > 30 ? String.valueOf(customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_2__c).substring(0,30) : String.valueOf(customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_2__c))
                                                             : emdr.CMPL123CME__E1_Address2__c));
                        
                        emdr.CMPL123CME__E1_City__c = (customerRecord.CMPL123CME__Customer__r.Customer_City_Translated__c != null ? 
                                                       (customerRecord.CMPL123CME__Customer__r.Customer_City_Translated__c.length() > 30 ? customerRecord.CMPL123CME__Customer__r.Customer_City_Translated__c.substring(0,30) : customerRecord.CMPL123CME__Customer__r.Customer_City_Translated__c)
                                                       :(customerRecord.CMPL123CME__Customer__r.City__c != null ? 
                                                         (customerRecord.CMPL123CME__Customer__r.City__c.length() > 30 ? String.valueOf(customerRecord.CMPL123CME__Customer__r.City__c).substring(0,30) : String.valueOf(customerRecord.CMPL123CME__Customer__r.City__c))
                                                         : emdr.CMPL123CME__E1_City__c));

                        //Added on 10 APR 2019
                       if(String.isNotBlank(customerRecord.CMPL123CME__Customer__c) ){
                            String zipPostalCode = customerRecord.CMPL123CME__Customer__c != null ? customerRecord.CMPL123CME__Customer__r.Zip_Postal_Code__c : null;
                           //Replaced previous logic in scope of #882 
                           emdr.CMPL123CME__E1_Postal_Code__c = zipPostalCode;
                        }
                        //Added on 10 APR 2019
                        
                        for(CMPL123CME__Complaint_Code__c state : statesAndCountryList){
                            emdr.CMPL123CME__E1_Region_State__c = state.CMPL123CME__Type__c == 'STATE CODE' && 
                                customerRecord.CMPL123CME__Customer__r.State__c == state.CMPL123CME__Name__c ?
                                state.Id : emdr.CMPL123CME__E1_Region_State__c;
                        }
                        
                    }
                    if(contactRecord != null){

                        emdr.CMPL123CME__E1_Facility_Name__c =  (contactRecord.Customer_Name_Translated__c != null ? 
                                                                 (contactRecord.Customer_Name_Translated__c.length() > 50 ? contactRecord.Customer_Name_Translated__c.substring(0,50) : contactRecord.Customer_Name_Translated__c)
                                                                 :(contactRecord.Customer_Name__c != null ? 
                                                                   (contactRecord.Customer_Name__r.Name.length() > 50 ? String.valueOf(contactRecord.Customer_Name__r.Name).substring(0,50) : String.valueOf(contactRecord.Customer_Name__r.Name))
                                                                   : emdr.CMPL123CME__E1_Facility_Name__c));

                        emdr.CMPL123CME__E1_Last_Name__c = (contactRecord.Contact_Name_Translated__c != null ? 
                                                            (contactRecord.Contact_Name_Translated__c.length() > 25 ? contactRecord.Contact_Name_Translated__c.substring(0,25) : contactRecord.Contact_Name_Translated__c)
                                                            :(contactRecord.Name__c != null ? 
                                                              (contactRecord.Name__c.length() > 25 ? String.valueOf(contactRecord.Name__c).substring(0,25) : String.valueOf(contactRecord.Name__c))
                                                              : emdr.CMPL123CME__E1_Last_Name__c));
                                emdr.CMPL123CME__E1_Email__c = contactRecord.Contact_Email__c != null ?
                            contactRecord.Contact_Email__c : emdr.CMPL123CME__E1_Email__c;
                        
                        emdr.CMPL123CME__E1_Fax__c = contactRecord.Contact_Fax__c != null ?
                            contactRecord.Contact_Fax__c : emdr.CMPL123CME__E1_Fax__c;
                        
                        emdr.CMPL123CME__E1_Phone__c = contactRecord.Contact_Phone_Number__c != null ?
                            contactRecord.Contact_Phone_Number__c : emdr.CMPL123CME__E1_Phone__c;
                    }
                    
                    for(Country__c country : countriesList){
                        emdr.E1_Country1__c = contactRecord.Country__c == country.Name || 
                            contactRecord.Country__c == country.Country_Code__c ? country.Id : emdr.E1_Country1__c;
                    }
                }              
            }

            // Moved because of "related to" fields logic assigment should be executed firstly
            for(CMPL123CME__EMDR__c emdr : newEMDRs) {
                setDefaultsAndNullFlavors(emdr);

                // Set E3 - Occupation to Health Professional
                if(emdr.Ticket_Review__c != null) {
                    emdr.CMPL123CME__E3_Occupation__c = emdr.CMPL123CME__E3_Occupation__c == null ?
                        'Non-Healthcare Professional' : emdr.CMPL123CME__E3_Occupation__c;
                }else if(emdr.Medical_Evaluation__c != null) {
                    emdr.CMPL123CME__E3_Occupation__c = emdr.CMPL123CME__E3_Occupation__c == null ?
                        'Other Health Care Professional' : emdr.CMPL123CME__E3_Occupation__c;
                }
            }
        }
        isExecuted=true;
    }

    /**
     * Assigns default values on eMDR various fields such as null flavor fields
     * @param emdr The record to have its fields changed. Must be non-null.
     * @revision 21-MAR-2023 Larry Resnik for R3.0: Moved all this logic out of
     * autoPopulateFieldValue. Commented logic for "G1 - Email Null" and
     * uncommented logic for "E1 - Email Null".
     */
    @testVisible
    private static void setDefaultsAndNullFlavors(CMPL123CME__EMDR__c emdr) {
        // Set A2 Date of birth null field to NI if Be date of birth is blank upon save.
        emdr.CMPL123CME__A2_DOB_Null__c = emdr.CMPL123CME__A2_DOB__c == null ?
                'NI' : null;

        //Set  A2 - Age Units (Patient) field to NI if A2 - Age at Time of Event is empty upon save
        emdr.CMPL123CME__A2_Age_Units_Patient__c = emdr.CMPL123CME__A2_Age_at_Time_of_Event__c == null ?
                'NI' : emdr.CMPL123CME__A2_Age_Units_Patient__c;
        //CHaRM-R4: Start
        //Set  A3a-Sex field to NI if blank upon save
        emdr.CMPL123CME__A3a_Sex__c = emdr.CMPL123CME__A3a_Sex__c == null ?
                'NI' : emdr.CMPL123CME__A3a_Sex__c;
        //Set  A3b-Gender field to NI if blank upon save
        emdr.CMPL123CME__A3b_Gender__c = emdr.CMPL123CME__A3b_Gender__c == null ?
                'NI' : emdr.CMPL123CME__A3b_Gender__c;
        //CHaRM-R4: End
        
        //Set A4 - Weight Units (Patient) field to NI if A4 - Weight is empty upon save
        emdr.CMPL123CME__A4_Weight_Units_Patient__c = emdr.CMPL123CME__A4_Weight__c == null ?
                'NI' : emdr.CMPL123CME__A4_Weight_Units_Patient__c;

        // 22-FEB-2022 Larry: "A5a - Ethnicity" replaced with "A5 - Ethnicity"
        // Set A5 - Ethnicity field to NI if blank upon save
        emdr.CMPL123CME__A5_Ethnicity__c =
                emdr.CMPL123CME__A5_Ethnicity__c == null ? 'NI' : emdr.CMPL123CME__A5_Ethnicity__c;

        // 22-FEB-2022 Larry: "A5b - Race" replaced with "A6 - Race"
        // Set A6 - Race field to NI if blank upon save
        emdr.CMPL123CME__A6_Race__c =
                emdr.CMPL123CME__A6_Race__c == null ? 'NI' : emdr.CMPL123CME__A6_Race__c;

        // Set B2 Date of Death null field to NI if Be date of death is blank upon save.
        emdr.CMPL123CME__B2_Death_Date_Null__c = emdr.CMPL123CME__B2_Date_of_Death__c == null ?
                'NI' : null;

        // Set B2 - Outcomes attributed to AE Null to NI if B2 - Outcomes attributed to AE is null upon save.
        emdr.CMPL123CME__B2_Outcomes_attributed_to_AE_Null__c =
                emdr.CMPL123CME__B2_Outcomes_attributed_to_AE__c == null ? 'NI' : null;

        // Set B3 - Date of Event Null to NI if B3 - Date of Event is null upon save.
        emdr.B3_Date_of_Event_v1__c =
                emdr.CMPL123CME__B3_Date_of_Event__c == null ? 'NI' : null;

        // Set D10 - Date Returned to Mfg Null ti NI if D10 - Date Returned to Mfg is blank upon save.
        emdr.CMPL123CME__D9_Date_Returned_to_Mfg_Null__c =
                emdr.CMPL123CME__D9_Date_returned_to_Mfg__c == null ? 'NI' : null;

        // Set D3 - Email Null to NI if D3 - Email is blank upon save.
        emdr.CMPL123CME__D3_Email_Null__c = emdr.CMPL123CME__D3_Email__c == null ?
                'NI' : null;

        // Set D3 - Fax Number Null to NI if D3 - Fax Number is blank upon save.
        emdr.CMPL123CME__D3_Fax_Number_Null__c = emdr.CMPL123CME__D3_Fax_Number__c == null ?
                'NI' : null;

        // 15-FEB-2023 Larry: Commented this assignment because "D3 - Phone Number" is not on the UI anymore
        // Set D3 - Phone Number Null to NI if D3 - Phone Number is blank upon save.
        // emdr.CMPL123CME__D3_Phone_Number_Null__c = emdr.CMPL123CME__D3_Phone_Number__c == null ?
        //         'NI' : null;

        // Set D4 - Expiration Date Null to NI if D4 - Expiration Date is blank upon save
        emdr.CMPL123CME__D4_Expiration_Date_Null__c = emdr.CMPL123CME__D4_Expiration_Date__c == null ?
                'NI' : null;

        // Set D6 - Implant Date Null to NI if D6 - Implant Date is blank upon save.
        emdr.CMPL123CME__D6a_Implant_Date_Null__c = emdr.CMPL123CME__D6a_Implant_Date__c == null ?
                'NI' : null;

        // Set D7 - Explant Date Null to NI if D7 - Explant Date is blank upon save.
        emdr.CMPL123CME__D6b_Explant_Date_Null__c = emdr.CMPL123CME__D6b_Explant_Date__c == null ?
                'NI' : null;

        // Set D9 - E-mail Nullto NI if D9 - E-mail is blank upon save.
        emdr.CMPL123CME__D7b_E_mail_Null__c = emdr.CMPL123CME__D7b_E_mail__c == null ?
                'NI' : null;

        // Set D9 - Fax Number Null to NI if D9 - Fax Number is blank upon save.
        emdr.CMPL123CME__D7b_Fax_Number_Null__c = emdr.CMPL123CME__D7b_Fax_Number__c == null ?
                'NI' : null;

        // Set E1 - E-Mail Null to NI if E1 - E-Mail is blank upon save.
        // 09-FEB-2023 Larry: Commented out the assignment to "E1 - Email Null" due to requirement updates
        // 21-MAR-2023 Larry: Re-enabled. "G1 - Email Null" was supposed to be commented instead
        emdr.CMPL123CME__E1_E_Mail_Null__c = emdr.CMPL123CME__E1_Email__c == null ?
                'NI' : null;

        // Set E1 - Fax Number Null to NI if E1 - Fax Number upon save.
        emdr.CMPL123CME__E1_Fax_Number_Null__c = emdr.CMPL123CME__E1_Fax__c == null ?
                'NI' : null;

        //Set E1 - Phone Null to NI if E1 - Phone is blank upon save.
        emdr.CMPL123CME__E1_Phone_Null__c = emdr.CMPL123CME__E1_Phone__c == null ?
                'NI' : null;

        // Set F11 - Date Sent to FDA Null to NI if F11 - Date Report Sent to FDA is blank upon save.
        emdr.CMPL123CME__F11_Date_Sent_to_FDA_Null__c = emdr.CMPL123CME__F11_Date_Report_Sent_to_FDA__c == null ?
                'NI' : null;

        // Set F13 - Date Report Sent to MFG Null to NI if F13 - Date Report Sent to MFG is blank upon save.
        emdr.CMPL123CME__F13_Date_Report_Sent_to_MFG_Null__c =
                emdr.CMPL123CME__F13_Date_Report_Sent_to_MFG__c == null ?
                        'NI' : null;

        // Set F14 - Email Null to NI if F14 - Email is blank upon save.
        emdr.CMPL123CME__F14_Email_Null__c = emdr.CMPL123CME__F14_Email__c == null ?
                'NI' : null;

        //Set F14 - Fax Null to NI if F14 - Fax is blank upon save.
        emdr.CMPL123CME__F14_Fax_Null__c = emdr.CMPL123CME__F14_Fax__c == null ?
                'NI' : null;

        // Set F3 - Contact Email Null to NI if F3 - Contact Email is blank upon save.
        emdr.CMPL123CME__F3_Contact_Email_Null__c = emdr.CMPL123CME__F3_Contact_Email__c == null ?
                'NI' : null;

        // Set F2 - User Fac / Imp Report No Null if F2 - UF/Importer Report# is blank upon save.
        emdr.CMPL123CME__F2_USER_FACILITY_IMPORTER_RPT_NO_NULL__c = emdr.CMPL123CME__F2_UF_Importer_Report_Number__c == null ?
                'NI' : null;

        // Set C4 - #1 Therapy Dates - Start Date Null to NI if C4 - #1 Therapy Dates - Start Date is blank upon //save.
        emdr.CMPL123CME__C4_Therapy_Dates_Start_Date1_Null__c = emdr.CMPL123CME__C4_Therapy_Dates_Start_Date1__c == null ?
                'NI' : null;

        // Set C4 - #2 Therapy Dates - Start Date Null to NI if C4 - #2 Therapy Dates - Start Date is blank upon //save.
        emdr.CMPL123CME__C4_Therapy_Dates_Start_Date2_Null__c = emdr.CMPL123CME__C4_Therapy_Dates_Start_Date2__c == null ?
                'NI' : null;

        // Set C4 - #1 Therapy Dates - Stop Date Null to NI if C4 - #1 Therapy Dates - Stop Date is blank upon //save.
        emdr.CMPL123CME__C4_1_Therapy_Dates_Stop_Date1_Null__c = emdr.CMPL123CME__C4_Therapy_Date_Stop_Date1__c == null ?
                'NI' : null;

        // Set C4 - #2 Therapy Dates - Stop Date Null to NI if C4 - #2 Therapy Dates - Stop Date is blank upon //save.
        emdr.CMPL123CME__C4_Therapy_Date_Stop_Date2_Null__c = emdr.CMPL123CME__C4_Therapy_Date_Stop_Date2__c == null ?
                'NI' : null;

        // Set C8 - #1 Exp. Date Null to NI if C8 - #1 Exp. Date upon //save.
        emdr.CMPL123CME__C8_Exp_Date1_Null__c = emdr.CMPL123CME__C8_Exp_Date1__c == null ?
                'NI' : null;

        // Set C8 - #2 Exp. Date Null to NI if C8 - #2 Exp. Date upon //save.
        emdr.CMPL123CME__C8_Exp_Date2_Null__c = emdr.CMPL123CME__C8_Exp_Date2__c == null ?
                'NI' : null;

        // Set G8 - Adverse Event Term(s) NA as a default value
        //(SA)emdr.CMPL123CME__G8_Adverse_Event_Term__c = emdr.CMPL123CME__G8_Adverse_Event_Term__c == null
                //? 'NA' : emdr.CMPL123CME__G8_Adverse_Event_Term__c;
        emdr.CMPL123CME__G7_Adverse_Event_Term_s__c = emdr.CMPL123CME__G7_Adverse_Event_Term_s__c == null
                ? 'NA' : emdr.CMPL123CME__G7_Adverse_Event_Term_s__c;

        // Set F5 - Contact Email Null to NI if F5 - Contact Email is blank upon save.
        emdr.CMPL123CME__F5_Contact_Email_Null__c = emdr.CMPL123CME__F5_Contact_Email__c == null ?
                'NI' : null;

        // Set F5 - Phone Number Null to NI if F5 - Phone is blank upon save.
        emdr.CMPL123CME__F5_Phone_Number_Null__c = emdr.CMPL123CME__F5_Phone__c == null ?
                'NI' : null;

        // Set F6 - Aware Date Null to NI if F6 - Date facility/dist was aware is blank upon save.
        emdr.CMPL123CME__F6_Aware_Date_Null__c = emdr.CMPL123CME__F6_Date_facility_dist_was_aware__c == null ?
                'NI' : null;

        // Set F8 - Date of This Report Null to NI if F8 - Date of This Report is blank upon save.
        emdr.CMPL123CME__F8_Date_of_This_Report_Null__c = emdr.CMPL123CME__F8_Date_of_This_Report__c == null ?
                'NI' : null;

        // Set G1 - Contact Office E-mail Null to NI if G1 - Contact Office E-mail is blank upon save.
        // 21-MAR-2023 Larry: Disabled. "G1 - Email Null" is hidden from the layout since 
        // "G1 - Email" is now always required.
        // emdr.CMPL123CME__G1_Contact_Office_E_mail_Null__c = emdr.CMPL123CME__G1_Contact_Office_E_mail__c == null ?
        //         'NI' : null;

        //Set G1 - Contact Office Fax Number Null to NI if G1 - Contact Office Fax Number is blank upon save.
        emdr.CMPL123CME__G1_Contact_Office_Fax_Number_Null__c =
                emdr.CMPL123CME__G1_Contact_Office_Fax_Number__c == null ?
                        'NI' : null;

        // Set G1 - Mfg Site E-mail Null to NI if G1 - Mfg Site E-mail is blank upon save.
        emdr.CMPL123CME__G1_Mfg_E_mail_Null__c = emdr.CMPL123CME__G1_Mfg_Email__c == null ?
                'NI' : null;

        // Set G1 - Mfg Site Fax Number Null to NI if G1 - Mfg Site Fax Number is blank upon save.
        emdr.CMPL123CME__G1_Mfg_Fax_Number_Null__c = emdr.CMPL123CME__G1_Mfg_Fax_Number__c == null ?
                'NI' : null;

        //Set G2 - Contact Office Phone Number Null to NI if G2 - Contact Office Phone Number is blank upon save.
        //(SA)emdr.CMPL123CME__G2_Contact_Office_Phone_Null__c = emdr.CMPL123CME__G2_Contact_Office_Phone__c == null ?
        emdr.CMPL123CME__G1_Contact_Office_Phone_Number_Null__c = emdr.CMPL123CME__G1_Contact_Office_Phone_Number__c == null ?
                'NI' : null;

        //Set H4 - Device Manufacture Date Null to NI if H4 - Device Mfg date is blank upon save.
        emdr.CMPL123CME__H4_DEVICE_MANUFACTURE_DATE_NULL__c =
                emdr.CMPL123CME__H4_Device_mfg_date__c == null ?
                        'NI' : null;

        //Set H7 - If Remedial Action Init Null to NI if H7 - If Remedial Action Initiated is blank upon save.
        emdr.CMPL123CME__H7_If_Remedial_Action_Init_Check_Null__c =
                emdr.CMPL123CME__H7_If_Remedical_Action_Init__c == null ?
                        'NI' : null;

        //Set EMDR H5 - Labeled for Single Use is Null while insert then set to No if blank upon save.
        emdr.CMPL123CME__H5_Labeled_for_Single_Use__c = emdr.CMPL123CME__H5_Labeled_for_Single_Use__c == null ?
                'NI' : emdr.CMPL123CME__H5_Labeled_for_Single_Use__c;

        // Set D8 - Single Use Device to default value No
        emdr.CMPL123CME__D7a_Single_Use_Device__c = emdr.CMPL123CME__D7a_Single_Use_Device__c == null ?
                AspenConstants.STR_No : emdr.CMPL123CME__D7a_Single_Use_Device__c;
    }

    /*
    * @Method       : fieldUpdatesFromWfRules.
    * @Description  : To execute WF Rules Field Updates logic.
    * @Invoke       : From EMDRTriggerHandler.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void fieldUpdatesFromWfRules() {
        List<CMPL123CME__EMDR__c> newEMDRs = (List<CMPL123CME__EMDR__c>)Trigger.New;
        Map<Id,CMPL123CME__EMDR__c> oldEMDRMap = (Map<Id,CMPL123CME__EMDR__c>)Trigger.oldMap;
        Map<Id,CMPL123CME__EMDR__c> newEMDRMap = (Map<Id,CMPL123CME__EMDR__c>)Trigger.newMap;

        Set<Id> medEvalIds = new Set<Id>();

        for(CMPL123CME__EMDR__c emdr : newEMDRs) {
            if(emdr.Medical_Evaluation__c != null) {
                medEvalIds.add(emdr.Medical_Evaluation__c);
            }
        }

        Map<Id, CMPL123CME__Questionnaire__c> medEvals = new Map<Id, CMPL123CME__Questionnaire__c>([
            SELECT Id, CMPL123CME__Complaint__c, CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c FROM CMPL123CME__Questionnaire__c WHERE Id IN : medEvalIds
        ]);
        
        for(CMPL123CME__EMDR__c emdr : newEMDRs) {
            DateTime actionPerformedOn = DateTime.now();
            String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
            
            Boolean wfActionIsChanged = Trigger.isInsert || (Trigger.isUpdate && emdr.CMPL123CME__CMPL123_WF_Action__c != oldEMDRMap.get(emdr.Id).CMPL123CME__CMPL123_WF_Action__c);
            Boolean wfStatusIsChanged = Trigger.isInsert || (Trigger.isUpdate && emdr.CMPL123CME__CMPL123_WF_Status__c != oldEMDRMap.get(emdr.Id).CMPL123CME__CMPL123_WF_Status__c);

            //Ack Failed WF Rule
            if(wfActionIsChanged && emdr.CMPL123CME__CMPL123_WF_Action__c != null
                && (emdr.CMPL123CME__CMPL123_WF_Action__c.containsIgnoreCase('Failed') 
                    || emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_REJECT)) {
                //Clear Report Submitter Field Update
                emdr.Report_Submitter__c = '';
                //Clear Submitted Date/Time Field Update
                emdr.CMPL123CME__Submitted_Date_Time__c = null;
            }

            //Autoset Registration Number WF Rule
            if(Trigger.isInsert && emdr.Medical_Evaluation__c != null && medEvals.get(emdr.Medical_Evaluation__c).CMPL123CME__Complaint__c != null
            && medEvals.get(emdr.Medical_Evaluation__c).CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c !=null) { 
                    emdr.Registration_Number__c = emdr.Registration_Ticket_Number__c;
            }

            //Clear Follow Up Required? WF Rule
            if(wfStatusIsChanged && emdr.CMPL123CME__CMPL123_WF_Status__c == AspenConstants.STR_Pending_Follow_Up_Creation) {
                //Clear Follow Up Required? Field Update
                emdr.Follow_Up_Required__c = null;

                //Clear Action on Follow Up Awareness Date Field Update
                emdr.Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank';
            }

            //Update MDR Submission WF Rule
            if (wfActionIsChanged && emdr.CMPL123CME__MDR_Submission__c != 'Ready to submit' &&
                (emdr.CMPL123CME__CMPL123_WF_Action__c == 'Generate MFR Report #' ||
                emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT)
            ) {
                emdr.CMPL123CME__MDR_Submission__c = 'Ready to submit';
            }

            //Update workflow action based fields in eMDR && Update workflow action based fields in eMDR2 WF Rules
            if(wfActionIsChanged) {
                //Ack 1 Received By Field Update
                emdr.Ack_1_Received_By__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 1 Received' ?  actionPerformedBy : emdr.Ack_1_Received_By__c;

                //Ack 1 Received On Field Update
                emdr.Ack_1_Received_On__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 1 Received' ?  actionPerformedOn : emdr.Ack_1_Received_On__c;

                //Ack 2 Received By Field Update
                emdr.Ack_2_Received_By__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 2 Received' ?  actionPerformedBy : emdr.Ack_2_Received_By__c;

                //Ack 2 Received On Field Update
                emdr.Ack_2_Received_On__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 2 Received' ?  actionPerformedOn : emdr.Ack_2_Received_On__c;

                //Ack 3 Received By Field Update
                emdr.Ack_3_Received_By__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 3 Received' ?  actionPerformedBy : emdr.Ack_3_Received_By__c;

                //Ack 3 Received On Field Update
                emdr.Ack_3_Received_On__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 3 Received' ?  actionPerformedOn : emdr.Ack_3_Received_On__c;

                //Report Submitter Field Update
                emdr.Report_Submitter__c  = emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT ?  actionPerformedBy : emdr.Report_Submitter__c;

                //Sent to FDA By Field Update
                emdr.Sent_to_FDA_By__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Sent to FDA' ?  actionPerformedBy : emdr.Sent_to_FDA_By__c;

                //Sent to FDA On Field Update
                emdr.Sent_to_FDA_On__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Sent to FDA' ?  actionPerformedOn : emdr.Sent_to_FDA_On__c;

                //Update B4 - Report Date Field Update
                emdr.CMPL123CME__B4_Report_Date__c = emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT ?  Date.today() : emdr.CMPL123CME__B4_Report_Date__c;

                //Clear Report Submitter Field Update
                emdr.Report_Submitter__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 1 Failed' ? '' : emdr.Report_Submitter__c;
                emdr.Report_Submitter__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 2 Failed' ? '' : emdr.Report_Submitter__c;
                emdr.Report_Submitter__c = emdr.CMPL123CME__CMPL123_WF_Action__c == 'Ack 3 Failed' ? '' : emdr.Report_Submitter__c;
                emdr.Report_Submitter__c = emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_REJECT ? '' : emdr.Report_Submitter__c;

                //Closed By Field Update
                emdr.Closed_By__c = emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Close ?  actionPerformedBy : emdr.Closed_By__c;

                //Closed On Field Update
                emdr.Closed_On__c = emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Close ?  actionPerformedOn : emdr.Closed_On__c;

                //Voided By Field Update
                emdr.Voided_By__c = emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void ?  actionPerformedBy : emdr.Voided_By__c;

                //Voided On Field Update
                emdr.Voided_On__c = emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void ?  actionPerformedOn : emdr.Voided_On__c;
            }

            //Update workflow panel WF Rule
            if(Trigger.isInsert && emdr.RecordTypeId == Label.EMDR_Initial_Record_Type_Id && emdr.RecordTypeId != null) {
                emdr.CMPL123CME__CMPL123Rule_Key_Value__c = 'EMDR_WORKFLOW';
            }
        }
    }
    
    // TODO: not calling from anywhere!
    // W-001331
    public static void beforeUpdateTriggerEvent(){
        List<CMPL123CME__EMDR__c> newEMDRs = (List<CMPL123CME__EMDR__c>)Trigger.New;
        Map<Id,CMPL123CME__EMDR__c> oldEMDRMap = (Map<Id,CMPL123CME__EMDR__c>)Trigger.oldMap;
        Set<String> ticketRefSet = new Set<String>();
        Set<String> ticketIdSet = new Set<String>();
        
        for(CMPL123CME__EMDR__c emdr : newEMDRs){
            if(emdr.Registration_Ticket_Number__c != null &&
                emdr.CMPL123CME__CMPL123_WF_Action__c != oldEMDRMap.get(emdr.Id).CMPL123CME__CMPL123_WF_Action__c &&
                emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT)
            {
                ticketRefSet.add(emdr.CMPL123CME__Complaint__c);
            }
        }
        
        if(ticketRefSet.size() > 0){
            for(CMPL123CME__Complaint__c ticket 
                : [SELECT Id, Name
                   FROM CMPL123CME__Complaint__c WHERE Id IN: ticketRefSet AND Med_Evaluator_Pending_MDCs__c = true]){
                       ticketIdSet.add(ticket.Id);
                   }
            
            if(ticketIdSet.size() > 0){
                for(CMPL123CME__EMDR__c emdr : newEMDRs){
                    if(emdr.CMPL123CME__CMPL123_WF_Action__c != oldEMDRMap.get(emdr.Id).CMPL123CME__CMPL123_WF_Action__c && 
                       emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT &&  
                       ticketIdSet.contains(emdr.CMPL123CME__Complaint__c)){
                           emdr.adderror(System.Label.EMDR_MDC_Not_Closed);
                       }
                }
            }
        }
    }
}