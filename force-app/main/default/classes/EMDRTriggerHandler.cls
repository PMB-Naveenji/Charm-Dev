/**
 * @When  : 23-MAR-2017.
 * @Where : From EMDRTriggerHandler class.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                      Modification ID              Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    23-MAR-2017               Work ID / Case ID            Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    22-MAY-2020               Defect #123/CHARM-2729       Added isLastModifiedDateUpdatedFromChild flag.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    09-JUNE-2020              Defect #123/CHARM-2729       Added parent ticket LastModifiedDate updating.
 *                                                                                 Deleted commented method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    27-OCT-2020               HC #100/CHARM-3518           Added getEditableOnPendingFields method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    03-NOV-2020               HC #100/CHARM-3518           Adjusted getEditableOnPendingFields method to query
 *                                                                                 Custom Metadata records. Changed Follow Ups creation
 *                                                                                 to be done upon closing action.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman               03-Dec-2020             Charm Upgrade                  Changed the field value from CMPL123CME__G4_Date_received_by_MFG__c to CMPL123CME__G3_Date_received_by_Mfg__c.
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Lakshman               03-Dec-2020            Charm Upgrade                   Changed the field value from CMPL123CME__G7_Type_of_Report_MultiSelect__c -> CMPL123CME__G6_Type_of_Report__c
  --------------------------------------------------------------------------------------------------------------------------------------
 * Sameer                 03-Dec-2020           Charm Upgrade             Changed the field value from CMPL123CME__G7_Follow_Up_No__c -> CMPL123CME__G6_Follow_up_No__c
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Sameer                 12-Dec-2020           Charm Upgrade             Added the method and call to update the Submitted Date/Time based on relevant workflow actions.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oober                  31-DEC-2020           TWD Upgrade Issue         Added fieldUpdatesFromWfRules method call to
 *                                                                        beforeInsertHandler and beforeUpdateHandler methods.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                  11-MAR-2021           Def #175                  Adjusted CMPL123CME__G6_Follow_up_No__c populating logic.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           28-JUN-2023           CHaRM R3.1, IPDR 496      Adjusted logic for assigning E1-Country. Now intentionally crashes when invalid.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar           16-JAN-2025         CHaRM R6/IPDR 176/IPDR 552  updated beforeUpdateHandler method
 * --------------------------------------------------------------------------------------------------------------------------------------
 */
public class EMDRTriggerHandler {

    public static Boolean isafterUpdateExecuted = false;
    public static Boolean isBeforeUpdateExecuted = false;
    // Def HC #100/CHARM-3518 fix: added isEditAccessOnPendingChecked flag
    public static Boolean isEditAccessOnPendingChecked = false;
    public static Boolean isFollowUpsCreated = false;
    // Defect #123/CHARM-2729: avoid LastModifiedDate update if already done
    @TestVisible
    public static Boolean isLastModifiedDateUpdatedFromChild = false;
    public static Id recordTypeIdInitial {
        get {
            if (recordTypeIdInitial == null) {
                recordTypeIdInitial = Schema.SObjectType.CMPL123CME__EMDR__c
                    .getRecordTypeInfosByName().get(AspenConstants.RECTYPE_EMDR_INITIAL)
                    .getRecordTypeId();
            }
            return recordTypeIdInitial;
        }
        private set;
    }
    public static Id recordTypeIdSuppl {
        get {
            if (recordTypeIdSuppl == null) {
                recordTypeIdSuppl = Schema.SObjectType.CMPL123CME__EMDR__c
                    .getRecordTypeInfosByName().get(AspenConstants.RECTYPE_EMDR_SUPPLEMENTAL)
                    .getRecordTypeId();
            }
            return recordTypeIdSuppl;
        }
        private set;
    }

    /**
     * @Method       : beforeInsertHandler
     * @Invoke       : Events from EMDRTriggerHandler class  before insert
     * @Description  : To handle the logic in before insert event
     * @Return       : N/A
     * @Params       : N/A
     **/
    public static void beforeInsertHandler() {
        //Type Cast Trigger Records
        List<CMPL123CME__EMDR__c> lstEMDRsNew = (List<CMPL123CME__EMDR__c>) Trigger.new;
        //Add Custom Methods Below
        Set<Id> ticketReviewId = new Set<Id>();
        for (CMPL123CME__EMDR__c emdr :lstEMDRsNew) {
            if (emdr.Ticket_Review__c != null) {
                ticketReviewId.add(emdr.Ticket_Review__c);
            }
        }
        if (ticketReviewId.size() > 0) {
            EMDRFieldUpdateTicketReview.autoPopulateTicketReview();
        }
        initializeNullPreferenceFieldValues(lstEMDRsNew); // 1608 def fix: subtask Audit Trail - Duplicate Entries
        EMDRFieldUpdates.autoPopulateFieldValue();
        //addCurrentTimeToDateFields( lstEMDRsNew, emdrOldMap );

        //Move WF Rules to Apex
        EMDRFieldUpdates.fieldUpdatesFromWfRules();
    }

    /**
     * @Method       : afterInsertHandler
     * @Invoke       : Events from EMDRTriggerHandler class  after insert
     * @Description  : To handle the logic in after insert event
     * @Return       : N/A
     * @Params       : N/A
     **/
    public static void afterInsertHandler() {
        //Type Cast Trigger Records
        List<CMPL123CME__EMDR__c> lstEMDRsNew = (List<CMPL123CME__EMDR__c>) Trigger.new;
        updateMedicalEvaluationsEMDR(lstEMDRsNew);
        updateTicketReview(lstEMDRsNew);
    }

    /**
     * @Method       : beforeUpdateHandler
     * @Invoke       : Events from EMDRTriggerHandler class  beforeUpdate
     * @Description  : To handle the logic in before update event
     * @Return       : N/A
     * @Params       : N/A
     **/
    public static void beforeUpdateHandler() {
        Map<Id,CMPL123CME__EMDR__c> lstEMDRsNewMap = (Map<Id,CMPL123CME__EMDR__c>) Trigger.newMap;
        Map<Id,CMPL123CME__EMDR__c> emdrOldMap = (Map<Id,CMPL123CME__EMDR__c>) Trigger.oldMap;

        for (CMPL123CME__EMDR__c objEMDR : [SELECT Id, CMPL123CME__CMPL123_WF_Action__c,
                                            (SELECT Id
                                             FROM CMPL123CME__EMDR__r
                                             WHERE CMPL123CME__CMPL123_WF_Status__c != 'Closed-Done'
                                             AND CMPL123CME__CMPL123_WF_Status__c != 'Closed-Voided')
                                            FROM CMPL123CME__EMDR__c
                                            WHERE Id IN : lstEMDRsNewMap.keySet()]) {
                                                if (lstEMDRsNewMap.get(objEMDR.Id).CMPL123CME__CMPL123_WF_Action__c == 'Follow Up Required'
                                                    && objEMDR.CMPL123CME__EMDR__r.size() > 0) {
                                                            lstEMDRsNewMap.get(objEMDR.Id).addError(Label.Follow_Up_Action_Restrict, false);
                                                    }
                                            }
        //CHaRM R6 : Start - Update EMDR's Task Key value to blank due to defect IPDR 176 where it does not demote to opened status due to the task key value already has the same value.
        for (CMPL123CME__EMDR__c emdr : (List<CMPL123CME__EMDR__c>) Trigger.new) {
          If(emdrOldMap != null && emdrOldMap.get(emdr.Id).CMPL123CME__CMPL123_WF_Status__c != null                   
             && emdr.CMPL123CME__CMPL123_WF_Status__c == 'Submitted to TIBCO' && (emdrOldMap.get(emdr.Id).CMPL123CME__CMPL123_WF_Status__c == 'Opened' || 
             emdrOldMap.get(emdr.Id).CMPL123CME__CMPL123_WF_Status__c == 'MFR Report # Generated') &&
             (emdrOldMap.get(emdr.Id).CMPL123CME__CMPL123Task_Key_Value__c =='SUBMITTEDTOFDAFAIL' || 
              emdrOldMap.get(emdr.Id).CMPL123CME__CMPL123Task_Key_Value__c == 'SUBMITTEDTOFDAFAILSUPP')){
             emdr.CMPL123CME__CMPL123Task_Key_Value__c = '';          
           }
        }                                                  
        //CHaRM R6: End
        //Defect #CHARM-1314
        Set <Id> parentIds = new Set <Id>();
        for (CMPL123CME__EMDR__c  emdr: emdrOldMap.values()) {
            parentIds.add(emdr.CMPL123CME__Initial_MDR__c);
        }
        for (CMPL123CME__EMDR__c  emd :[SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c,
                                             (SELECT Id
                                              FROM CMPL123CME__EMDR__r
                                              WHERE CMPL123CME__CMPL123_WF_Status__c != 'Closed-Done'
                                              AND CMPL123CME__CMPL123_WF_Status__c != 'Closed-Voided')
                                             FROM CMPL123CME__EMDR__c
                                             WHERE Id IN :parentIds]) {


            Boolean toSkip = false;
            if (emd.CMPL123CME__EMDR__r.size() == 1 && lstEMDRsNewMap.containsKey(emd.CMPL123CME__EMDR__r.get(0).Id)) {
                toSkip = true;
            }
            if (emd.CMPL123CME__EMDR__r.size() > 0 && !toSkip) {
                //@Juneid 12 Feb 2021, Added a logic for Supplimental EMDR Follw up Error
                for(CMPL123CME__EMDR__c supliEmdr : lstEMDRsNewMap.Values()){
                     if((supliEmdr.CMPL123CME__Initial_MDR__c == emd.Id) &&
                      (emdrOldMap.get(supliEmdr.Id).CMPL123CME__CMPL123_WF_Action__c != 'Follow Up Required' &&
                     lstEMDRsNewMap.get(supliEmdr.Id).CMPL123CME__CMPL123_WF_Action__c == 'Follow Up Required')){
                             lstEMDRsNewMap.get(supliEmdr.Id).addError(Label.Follow_Up_Action_Restrict_On_Supplemental_EMDR, false);
                     }
                  }
                 //@Juneid 12 Feb 2021, Commented for resolve Follow up Error Issue Defect #154
                /*for (CMPL123CME__EMDR__c   child: emd.CMPL123CME__EMDR__r) {

                    if (lstEMDRsNewMap.containsKey(child.Id)
                        && emdrOldMap.get(child.Id).CMPL123CME__CMPL123_WF_Action__c != 'Follow Up Required'
                        && lstEMDRsNewMap.get(child.Id).CMPL123CME__CMPL123_WF_Action__c == 'Follow Up Required'){
                            lstEMDRsNewMap.get(child.Id).addError(Label.Follow_Up_Action_Restrict_On_Supplemental_EMDR, false);
                        }
                }*/
            }
        }


        //Defect #1112 and 1199
        Map<String, Country__c> countryNameOrCodeToRecord =
            makeCountryLookup((List<CMPL123CME__EMDR__c>) Trigger.new);
        Set<Id> ticketReviewId = new Set<Id>();
        for (CMPL123CME__EMDR__c emdr : (List<CMPL123CME__EMDR__c>) Trigger.new) {
            if (emdr.Ticket_Review__c != null) {
                ticketReviewId.add(emdr.Ticket_Review__c);
            }
            //Defect #1112 and 1199, set country and state fields which are used by TIBCO and not on layout
            if (emdrOldMap != null && emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT
                && emdr.CMPL123CME__CMPL123_WF_Action__c != emdrOldMap.get(emdr.Id).CMPL123CME__CMPL123_WF_Action__c
            ) {
                emdr.D3_Country_Code__c = emdr.D3_Country_New__c;
                emdr.D3_Region_State_Code__c = emdr.D3_Region_State_New__c;
                emdr.G1_Contact_Office_Country_Code__c = emdr.G1_Contact_Office_Country_New__c;
                emdr.G1_Contact_Office_Region_State_Code__c = emdr.G1_Contact_Office_Region_State_New__c;
                emdr.G1_Mfg_Site_Country_Code__c = emdr.G1_Mfg_Site_Country_New2__c;
                emdr.G1_Mfg_Site_Region_State_Code__c = emdr.G1_Mfg_Site_Region_State_New__c;
                setFieldsE1Country(countryNameOrCodeToRecord, emdr);

                if (emdr.E1_Region_State_New__c != null && emdr.E1_Region_State_New__c.length() == 2) {
                    emdr.E1_Region_State_Code__c = emdr.E1_Region_State_New__c;
                } else {
                    emdr.E1_Region_State_Code__c =null;
                    emdr.E1_Region_State_New__c = null;
                }
            }
        }
        if (ticketReviewId.size() > 0) {
            EMDRFieldUpdateTicketReview.autoPopulateTicketReview();
        }
        //Add Custom Methods Below
        EMDRFieldUpdates.autoPopulateFieldValue();
        //addCurrentTimeToDateFields( lstEMDRsNew, emdrOldMap );
        //(SA)Update the Submitted Date
        updateSubmittedDatetimeUponWorkflowActions(emdrOldMap,lstEMDRsNewMap);

        //Move WF Rules to Apex
        EMDRFieldUpdates.fieldUpdatesFromWfRules();
    }

    /**
     * Builds a lookup table of Country name-or-code to its affiliated record
     * 
     * Designed to work alongside setFieldsE1Country
     * An example of a generated table is as follows:
     * {
     *      "IND"   => recordForIndia,
     *      "INDIA" => recordForIndia,
     *      "CHN"   => recordForChina,
     *      "CHINA" => recordForChina
     * }
     * @author R3.1, Larry Resnik
     * @param triggerNew Same as Trigger.new; Can be null
     * @return Map of Country names/codes to records. Can be empty, but never null
     */
    public static Map<String, Country__c> makeCountryLookup(List<CMPL123CME__EMDR__c> triggerNew) {
        triggerNew = triggerNew != null ? triggerNew : new List<CMPL123CME__EMDR__c>();
        Set<String> countryE1Set = new Set<String>();
        for (CMPL123CME__EMDR__c emdr : triggerNew) {
            if (emdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT) {
                countryE1Set.add(emdr.E1_Country_New__c);
            }
        }
        // Remove invalid country names and codes
        countryE1Set.remove(null);
        countryE1Set.remove('');

        Map<String, Country__c> countryNameOrCodeToRecord = new Map<String, Country__c>();
        if (countryE1Set.isEmpty()) {
            // Abort early to avoid SOQL
            return countryNameOrCodeToRecord;
        }

        for (Country__c countryRecord : [
            SELECT Id, Name, Country_Code__c
            FROM Country__c
            WHERE Active__c = true AND (
                Name IN :countryE1Set OR
                Country_Code__c IN :countryE1Set
            )
        ]) {
            // Assume that Country names and codes are already uppercase in the database.
            // It would be expensive to uppercase tons of strings here.
            countryNameOrCodeToRecord.put(countryRecord.Name, countryRecord);
            countryNameOrCodeToRecord.put(countryRecord.Country_Code__c, countryRecord);
        }
        return countryNameOrCodeToRecord;
    }

    /**
     * Sets frontend and backend E1-Country fields for the passed EMDR
     * 
     * Helper for beforeUpdateHandler
     * This function might set an error on the record
     * No DML is applied to the passed EMDR
     * @author R3.1, Larry Resnik
     * @param countryNameOrCodeToRecord Map of Country names or codes to their records. Cannot be null
     * @param emdr The EMDR record to edit IN-PLACE. Cannot be null
     * @return The appropriate Country code for E1-Country. If invalid, returns an empty string
     */
    public static String setFieldsE1Country(
        Map<String, Country__c> countryNameOrCodeToRecord,
        CMPL123CME__EMDR__c emdr)
    {
        Country__c appropriateCountry;
        Boolean isCountryOriginallyBlank = false;
        String countryCodeOld = emdr.E1_Country_New__c;

        if (String.isBlank(countryCodeOld)) {
            // No need to do a map lookup or normalize text
            // However, we do not know whether or not to addError yet
            isCountryOriginallyBlank = true;
        } else {
            // Unlike Countries put in the database, E1-Country is a user-inputted field, so we normalize it
            countryCodeOld = emdr.E1_Country_New__c.toUpperCase();
            appropriateCountry = countryNameOrCodeToRecord.get(countryCodeOld);
        }

        Boolean isValidCountry = appropriateCountry != null;
        Boolean isE1CountryRequired = emdr.RecordTypeId == recordTypeIdInitial;
        Boolean isErrorScenarioOne = !isValidCountry && !isCountryOriginallyBlank;
        Boolean isErrorScenarioTwo = isE1CountryRequired && isCountryOriginallyBlank;

        String countryCodeNew = '';
        if (isValidCountry) {
            countryCodeNew = appropriateCountry.Country_Code__c;
            emdr.E1_Country_Code__c = countryCodeNew;
            emdr.E1_Country_New__c = countryCodeNew;
        } else if (isErrorScenarioOne || isErrorScenarioTwo) {
            // R3.1, Larry: Now puts an error on the EMDR if an invalid Country will be sent to the FDA
            emdr.addError(System.Label.E1_Country_can_t_be_null);
        }
        return countryCodeNew;
    }

    /**
     * @Method       : afterUpdateHandler
     * @Invoke       : Events from EMDRTriggerHandler class  afterUpdate
     * @Description  : To handle the logic in after update event
     * @Return       : N/A
     * @Params       : N/A
     **/
    public static void afterUpdateHandler() {
        List<CMPL123CME__EMDR__c> lstEMDRsNew =(List<CMPL123CME__EMDR__c>)Trigger.new;
        Map<Id, CMPL123CME__EMDR__c> mapEMDRsOld = (Map<Id, CMPL123CME__EMDR__c>)Trigger.oldMap;

        if (!isafterUpdateExecuted) {
            //Add Custom Methods Below
            CMPL123CME__EMDR__c newEmdr, oldEmdr;
            for (CMPL123CME__EMDR__c emdr : (List<CMPL123CME__EMDR__c>) Trigger.new) {
                newEmdr = emdr;
                break;
            }

            for (CMPL123CME__EMDR__c emdr : (List<CMPL123CME__EMDR__c>) Trigger.old) {
                oldEmdr = emdr;
                break;
            }
            //Added : W-000249  Description: To check Device code and Patient code on Submit action and recordtype is initial
            Id initialRTId = recordTypeIdInitial;
            /*
if(((CMPL123CME__EMDR__c)Trigger.New[0]).RecordTypeId == initialRTId  && ((CMPL123CME__EMDR__c)Trigger.New[0]).CMPL123CME__CMPL123_WF_Action__c != ((CMPL123CME__EMDR__c)Trigger.old[0]).CMPL123CME__CMPL123_WF_Action__c && ((CMPL123CME__EMDR__c)Trigger.New[0]).CMPL123CME__CMPL123_WF_Action__c == 'Submit'){
EMDRCustomException.patientDeviceCodeValidate();
}
*/
            if (newEmdr.RecordTypeId == initialRTId
                && newEmdr.CMPL123CME__CMPL123_WF_Action__c != oldEmdr.CMPL123CME__CMPL123_WF_Action__c
                && newEmdr.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT) {
                    EMDRCustomException.patientDeviceCodeValidate();
                }
            updateMedicalEvaluationsEMDR(lstEMDRsNew);
            updateTicketReview(lstEMDRsNew);
            createSupplementalEMDR(lstEMDRsNew, mapEMDRsOld);
        }
    }

    /**
     * @Method       : initializeNullPreferenceFieldValues
     * @Invoke       : Events from EMDRTriggerHandler class
     * @Description  : To handle the logic initialize Null Preference Field Values
     * @Return       : N/A
     * @Params       : N/A
     **/
    private static void initializeNullPreferenceFieldValues(List < CMPL123CME__EMDR__c > lstEMDRsNew){

        String initialRTId = recordTypeIdInitial;

        for (CMPL123CME__EMDR__c objEMDR : lstEMDRsNew) {

            if (objEMDR.RecordTypeId == initialRTId) {
                for (Schema.FieldSetMember objFieldSetMember : SObjectType.CMPL123CME__EMDR__c.fieldSets.Update_to_NI.getFields()) {
                    if (objEMDR.get(objFieldSetMember.getFieldPath()) == null) {
                        objEMDR.put(objFieldSetMember.getFieldPath(), 'NI');
                    }
                }
            }

        }
    }

    /**
     * @Method       : createSupplementalEMDR
     * @Invoke       : Events from EMDRTriggerHandler class
     * @Description  : To handle the logic in  create SupplementalEMDR
     * @Return       : N/A
     * @Params       : List<CMPL123CME__EMDR__c> lstEMDRsNew, Map<Id,CMPL123CME__EMDR__c> mapEMDRsOld
     **/
    private static void createSupplementalEMDR(List<CMPL123CME__EMDR__c> lstEMDRsNew, Map<Id,CMPL123CME__EMDR__c> mapEMDRsOld){
        Map<Id,String> mapSubmissionType = new Map<Id,String>();
        Set<Id> setCountries = new Set<Id>();

        String supplementRTId = recordTypeIdSuppl;
        //Added : W-000105
        Set<Id> emdrSet = new Set<Id>();
        Set<Id> setSupplementalIds = new Set<Id>();
        Set<Id> newEmdrSet = new Set<Id>();
        Set<Id> medEvalSet = new Set<Id>();
        Set<Id> ticketReviewSet = new Set<Id>();
        Set<Id> followUpToCreate = new Set<Id>();
        for (CMPL123CME__EMDR__c emdr: lstEMDRsNew) {
            CMPL123CME__EMDR__c oldEMDR = Trigger.isUpdate && mapEMDRsOld != null ?
                mapEMDRsOld.get(emdr.Id) : null;
            if(emdr.Medical_Evaluation__c != null){
                medEvalSet.add(emdr.Medical_Evaluation__c );
            }
            if(emdr.Ticket_Review__c != null){
                ticketReviewSet.add(emdr.Ticket_Review__c);
            }
            if ((emdr.Follow_Up_Required__c == 'Yes' && (emdr.CMPL123CME__CMPL123_WF_Status__c == 'Pending Closure' || emdr.CMPL123CME__CMPL123_WF_Status__c == 'Pending Follow Up Creation' ) && emdr.Follow_Up_Required__c != oldEMDR.Follow_Up_Required__c)) {
                emdrSet.add(emdr.Id);
                if (emdr.CMPL123CME__Initial_MDR__c != null) {
                    emdrSet.add(emdr.CMPL123CME__Initial_MDR__c);
                    setSupplementalIds.add(emdr.Id);
                }
            }

            if (!isFollowUpsCreated && emdr.Follow_Up_Required__c == 'Yes' && emdr.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done'
                    && (oldEMDR != null && emdr.CMPL123CME__CMPL123_WF_Status__c != oldEMDR.CMPL123CME__CMPL123_WF_Status__c)) {
                followUpToCreate.add(emdr.Id);
                emdrSet.add(emdr.Id);
                if (emdr.CMPL123CME__Initial_MDR__c != null) {
                    emdrSet.add(emdr.CMPL123CME__Initial_MDR__c);
                    setSupplementalIds.add(emdr.Id);
                }
            }

            if (emdr.D9_Country1__c != null) {
                setCountries.add(emdr.D9_Country1__c);
            }
        }
        Map<Id,CMPL123CME__Questionnaire__c>  medEvalMap = new Map<Id,CMPL123CME__Questionnaire__c>();
        Map<Id,Ticket_Review__c>  ticketReviewMap = new Map<Id,Ticket_Review__c>();
        if (medEvalSet.size() > 0) {
            for (CMPL123CME__Questionnaire__c medEval : [SELECT Id, Follow_Up_Awareness_Date__c
                                                         FROM CMPL123CME__Questionnaire__c WHERE Id IN: medEvalSet]) {
                                                             medEvalMap.put(medEval.Id, medEval);
                                                         }
        }
        //added for deefct #761, follow-up from ticket review
        if (ticketReviewSet.size() > 0) {
            for (Ticket_Review__c ticketReview : [SELECT Id, Follow_Up_Awareness_Date__c
                                                  FROM Ticket_Review__c WHERE Id IN: ticketReviewSet]) {
                                                      ticketReviewMap.put(ticketReview.Id, ticketReview);
                                                  }
        }
        Set<Id> nonEligibleEmdrSet = new Set<Id>();
        if (emdrSet.size() > 0) {
            for (CMPL123CME__EMDR__c objEMDR : [SELECT Id, (SELECT Id FROM CMPL123CME__EMDR__r WHERE CMPL123CME__CMPL123_WF_Status__c != 'Closed-Done'
                                                            AND CMPL123CME__CMPL123_WF_Status__c != 'Closed-Voided' AND Id NOT IN: setSupplementalIds LIMIT 1) FROM CMPL123CME__EMDR__c
                                                WHERE Id =: emdrSet]) {
                                                    if (objEMDR.CMPL123CME__EMDR__r.size() == 1) {
                                                        nonEligibleEmdrSet.add(objEMDR.Id);
                                                    }
                                                }
            if (nonEligibleEmdrSet.size() > 0) {
                lstEMDRsNew[0].addError(Label.EMDR_Prevent_creating_Supplemental_EMDR_with_another_having_not_closed_status, false);
            }
        }

        if (followUpToCreate.size() > 0) {
            List<CMPL123CME__EMDR__c> newEMDRList = new List<CMPL123CME__EMDR__c>();

            if (setCountries.size() > 0) {
                for (Country_Submission_Type__c objCountrySubmissionType : [SELECT Id, Name, Country__c FROM Country_Submission_Type__c
                                                                            WHERE Name = '30 Days' AND Calendar_Days__c = 30
                                                                            AND Country__c IN: setCountries]) {
                                                                                mapSubmissionType.put(objCountrySubmissionType.Country__c, objCountrySubmissionType.Id);
                                                                            }
            }
            //defect #597 added to set new follow-up number on supplementals so that voided eMDR's are not counted.
            Map<Id, String> eMDRIDWithFollowUpNoMap = new Map<Id, String>();
            for (CMPL123CME__EMDR__c queriedEMDR : [SELECT Id, (SELECT Id
                                                                FROM CMPL123CME__EMDR__r
                                                                WHERE CMPL123CME__CMPL123_WF_Status__c != 'Closed-Voided')
                                                    FROM CMPL123CME__EMDR__c WHERE Id =: emdrSet]) {
                                                        eMDRIDWithFollowUpNoMap.put(queriedEMDR.Id, String.valueOf(queriedEMDR.CMPL123CME__EMDR__r.size()+1));
                                                    }
            //defect #597 code ends here
            for (CMPL123CME__EMDR__c emdr : lstEMDRsNew) {
                if (followUpToCreate.contains(emdr.Id)) {
                    Id parenteMDRId = emdr.CMPL123CME__Initial_MDR__c == null ? emdr.Id : emdr.CMPL123CME__Initial_MDR__c;
                    newEmdrSet.add(parenteMDRId);
                    Date dateG4, dateDue;
                    if (emdr.Medical_Evaluation__c != null) {
                        dateG4 = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c) != null &&
                            medEvalMap.get(emdr.Medical_Evaluation__c).Follow_Up_Awareness_Date__c != null
                            ? medEvalMap.get(emdr.Medical_Evaluation__c).Follow_Up_Awareness_Date__c
                            : null;
                        dateDue = medEvalMap != null && medEvalMap.get(emdr.Medical_Evaluation__c)!= null &&
                            medEvalMap.get(emdr.Medical_Evaluation__c).Follow_Up_Awareness_Date__c != null
                            ? medEvalMap.get(emdr.Medical_Evaluation__c).Follow_Up_Awareness_Date__c + 30
                            : null;
                    }
                    //added for defect#761, 762, 765
                    if (emdr.Ticket_Review__c != null) {
                        dateG4 = ticketReviewMap != null && ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                            ticketReviewMap.get(emdr.Ticket_Review__c).Follow_Up_Awareness_Date__c != null
                            ? ticketReviewMap.get(emdr.Ticket_Review__c).Follow_Up_Awareness_Date__c
                            : null;
                        dateDue = ticketReviewMap != null && ticketReviewMap.get(emdr.Ticket_Review__c)!= null &&
                            ticketReviewMap.get(emdr.Ticket_Review__c).Follow_Up_Awareness_Date__c != null
                            ? ticketReviewMap.get(emdr.Ticket_Review__c).Follow_Up_Awareness_Date__c + 30
                            : null;
                    }
                    CMPL123CME__EMDR__c copiedEmdr = new CMPL123CME__EMDR__c(
                        CMPL123CME__Initial_MDR__c = parenteMDRId,
                        RecordTypeId = supplementRTId,
                        CMPL123CME__G6_Type_of_Report__c = 'Follow Up',
                        CMPL123CME__CMPL123Rule_Key_Value__c = 'EMDR_WORKFLOW_SUPPLEMENTAL',
                        CMPL123CME__G3_Date_received_by_Mfg__c = dateG4,
                        CMPL123CME__MDR_Due_Date__c = dateDue,
                        Submission_Type__c = (!mapSubmissionType.isEmpty() ? mapSubmissionType.get(emdr.D9_Country1__c) : null),
                        CMPL123CME__G6_Follow_up_No__c = eMDRIDWithFollowUpNoMap.get(parenteMDRId)
                    );
                    for (Schema.FieldSetMember f: SObjectType.CMPL123CME__EMDR__c.fieldSets.Follow_up_auto_populate.getFields()) {
                        copiedEmdr.put(f.getFieldPath(), emdr.get(f.getFieldPath()));
                    }
                    newEMDRList.add(copiedEmdr);
                }
            }
            if (newEMDRList.size() > 0) {
                insert newEMDRList;
                isafterUpdateExecuted = true;
                isFollowUpsCreated = true;
                List < CMPL123CME__Concomitant_Product__c > followupCP = new List < CMPL123CME__Concomitant_Product__c > ();
                // To copy concomitant product to follow up
                Map<Id, List<CMPL123CME__Concomitant_Product__c>> concomitantProductMap = new Map<Id, List<CMPL123CME__Concomitant_Product__c>>();

                for(CMPL123CME__EMDR__c objEMDR : [SELECT Id, (SELECT Id, Name, CMPL123CME__D11_End_Date_Null__c,
                                                               CMPL123CME__D11_End_Date__c, CMPL123CME__D11_Product__c, CMPL123CME__D11_Start_Date_Null__c,
                                                               CMPL123CME__D11_Start_Date__c, CMPL123CME__EMDR_IsEmpty_End_Date__c,
                                                               CMPL123CME__EMDR_IsEmpty_Start_Date__c, CMPL123CME__Related_EMDR__c, Product_Ticket__c,
                                                               Registration_Ticket_Number__c, Division__c FROM CMPL123CME__Concommitant_Products__r)
                                                   FROM CMPL123CME__EMDR__c WHERE (Id  IN: newEmdrSet OR Id IN: emdrSet)
                                                   AND Id NOT IN : nonEligibleEmdrSet]){
                                                       concomitantProductMap.put(objEMDR.Id, objEMDR.CMPL123CME__Concommitant_Products__r);
                                                   }


                if (!concomitantProductMap.isEmpty()) {
                    for (CMPL123CME__EMDR__c followUpEMDR: newEMDRList) {
                        for (CMPL123CME__Concomitant_Product__c CP
                             : concomitantProductMap.get(followUpEMDR.CMPL123CME__Initial_MDR__c)) {
                                 CMPL123CME__Concomitant_Product__c clonedCP = CP.clone(false);
                                 clonedCP.CMPL123CME__Related_EMDR__c = followUpEMDR.Id;
                                 followupCP.add(clonedCP);
                             }
                    }
                    if (followupCP.size() > 0) {
                        insert followupCP;
                    }
                }
            }
        }
    }

    // Process Builder - Set Submission Created Field when EMDR child record is created

    /**
     * @Method       : updateMedicalEvaluationsEMDR
     * @Invoke       : Events from EMDRTriggerHandler class
     * @Description  :  Process Builder - Set Submission Created Field when EMDR child record is created
     * @Params       : List<CMPL123CME__EMDR__c> lstEMDRsNew, Boolean isInsert
     * @Return       : N/A
     **/
    private static void updateMedicalEvaluationsEMDR(List<CMPL123CME__EMDR__c> lstEMDRsNew) {
        Map<Id,CMPL123CME__EMDR__c> oldEMDRMap = (Map<Id,CMPL123CME__EMDR__c>)Trigger.oldMap;
        Map<Id, CMPL123CME__Questionnaire__c> mapMedicalEvaluations = new Map<Id, CMPL123CME__Questionnaire__c>();
        Map<Id,CMPL123CME__Questionnaire__c> mapMedicalEvaluationsToUpdate = new Map<Id,CMPL123CME__Questionnaire__c>();

        Set<Id> setMedicalEvaluationIds = new Set<Id>();

        for (CMPL123CME__EMDR__c objEMDR : lstEMDRsNew) {
            if (objEMDR.Medical_Evaluation__c != null) {
                setMedicalEvaluationIds.add(objEMDR.Medical_Evaluation__c);
            }
        }

        if (setMedicalEvaluationIds.size() > 0) {
            mapMedicalEvaluations = new Map<Id, CMPL123CME__Questionnaire__c>([SELECT Id, Submission_Created__c, Follow_Up_Awareness_Date__c
                                                                               FROM CMPL123CME__Questionnaire__c WHERE Id IN: setMedicalEvaluationIds]);
            if(mapMedicalEvaluations != null && !mapMedicalEvaluations.isEmpty() ){
                for (CMPL123CME__EMDR__c objEMDR : lstEMDRsNew) {
                    CMPL123CME__EMDR__c oldEMDR = Trigger.isUpdate && oldEMDRMap != null ? oldEMDRMap.get(objEMDR.Id) : null;
                    if (objEMDR.Medical_Evaluation__c != null) {
                        CMPL123CME__Questionnaire__c objMedicalEvaluation = mapMedicalEvaluations.get(objEMDR.Medical_Evaluation__c);
                        /*
if(isInsert){
//Commented below code, set flag on Med eval is already done while submission creation, SOQL optimization
if(objMedicalEvaluation.Submission_Created__c == false){

objMedicalEvaluation.Submission_Created__c = true;
mapMedicalEvaluationsToUpdate.put(objMedicalEvaluation.Id,objMedicalEvaluation);

}

}*/
                        if(objEMDR.Follow_Up_Required__c == 'Yes'
                           && (objEMDR.Action_on_Follow_Up_Awareness_Date__c  == 'Set to Blank'
                               || objEMDR.Action_on_Follow_Up_Awareness_Date__c  == 'Set Date')
                           && (oldEMDR == null
                               || (objEMDR.Action_on_Follow_Up_Awareness_Date__c != oldEMDR.Action_on_Follow_Up_Awareness_Date__c
                                   || objEMDR.Follow_Up_Required__c != oldEMDR.Follow_Up_Required__c))
                           && objMedicalEvaluation.Follow_Up_Awareness_Date__c != null) {
                               if (objEMDR.Action_on_Follow_Up_Awareness_Date__c  == 'Set to Blank') {
                                   objMedicalEvaluation.Follow_Up_Awareness_Date__c = null;
                                   mapMedicalEvaluationsToUpdate.put(objMedicalEvaluation.Id,objMedicalEvaluation);
                               } else if (objEMDR.Action_on_Follow_Up_Awareness_Date__c  == 'Set Date') {
                                   objMedicalEvaluation.Follow_Up_Awareness_Date__c = objEMDR.New_Follow_Up_Awareness_Date__c;
                                   mapMedicalEvaluationsToUpdate.put(objMedicalEvaluation.Id,objMedicalEvaluation);
                               }
                           }
                    }
                }
                if (!mapMedicalEvaluationsToUpdate.isEmpty()) {
                    update mapMedicalEvaluationsToUpdate.values();
                }
            }
        }
    }


    /**
     * @Method       : updateTicketReview
     * @Invoke       : Events from EMDRTriggerHandler class
     * @Description  : Upate ticket review recrod when any changes on new follow-up date on supplement creation
     *                 Defect #761, 762, 765
     * @Params       : List<CMPL123CME__EMDR__c> lstEMDRsNew
     * @Return       : N/A
     **/
    private static void updateTicketReview(List<CMPL123CME__EMDR__c> lstEMDRsNew) {
        Map<Id,CMPL123CME__EMDR__c> oldEMDRMap = (Map<Id,CMPL123CME__EMDR__c>) Trigger.oldMap;
        Map<Id, Ticket_Review__c> ticketReviewMap = new Map<Id, Ticket_Review__c>();
        Map<Id,Ticket_Review__c> ticketReviewUpdateMap = new Map<Id, Ticket_Review__c>();
        Set<Id> ticketReviewIdSet = new Set<Id>();
        //collecting all the ticket review Ids
        for (CMPL123CME__EMDR__c objEMDR : lstEMDRsNew) {
            if (objEMDR.Ticket_Review__c != null) {
                ticketReviewIdSet.add(objEMDR.Ticket_Review__c);
            }
        }
        //Querying ticket review records
        if (ticketReviewIdSet.size() > 0) {
            ticketReviewMap = new Map<Id, Ticket_Review__c>([SELECT Id, Follow_Up_Awareness_Date__c FROM
                                                             Ticket_Review__c WHERE Id IN: ticketReviewIdSet]);
            if (ticketReviewMap != null && !ticketReviewMap.isEmpty()) {
                for (CMPL123CME__EMDR__c objEMDR :lstEMDRsNew) {
                    CMPL123CME__EMDR__c oldEMDR = Trigger.isUpdate && oldEMDRMap != null ? oldEMDRMap.get(objEMDR.Id) : null;
                    if (objEMDR.Ticket_Review__c != null) {
                        Ticket_Review__c ticketReviewRecord = ticketReviewMap.get(objEMDR.Ticket_Review__c);
                        if (objEMDR.Follow_Up_Required__c == 'Yes' && (objEMDR.Action_on_Follow_Up_Awareness_Date__c  == 'Set to Blank'
                                                                       || objEMDR.Action_on_Follow_Up_Awareness_Date__c  == 'Set Date') && (oldEMDR == null
                                                                                                                                            || (objEMDR.Action_on_Follow_Up_Awareness_Date__c != oldEMDR.Action_on_Follow_Up_Awareness_Date__c
                                                                                                                                                || objEMDR.Follow_Up_Required__c != oldEMDR.Follow_Up_Required__c))
                            && ticketReviewRecord.Follow_Up_Awareness_Date__c != null) {

                                if (objEMDR.Action_on_Follow_Up_Awareness_Date__c  == 'Set to Blank') {
                                    ticketReviewRecord.Follow_Up_Awareness_Date__c = null;
                                    ticketReviewUpdateMap.put(ticketReviewRecord.Id, ticketReviewRecord);
                                } else if (objEMDR.Action_on_Follow_Up_Awareness_Date__c  == 'Set Date') {
                                    ticketReviewRecord.Follow_Up_Awareness_Date__c = objEMDR.New_Follow_Up_Awareness_Date__c ;
                                    ticketReviewUpdateMap.put(ticketReviewRecord.Id, ticketReviewRecord);
                                }
                            }
                    }
                }
                //updating ticket review records to set follow-up awareness date
                if (!ticketReviewUpdateMap.isEmpty()) {
                    update ticketReviewUpdateMap.values();
                }
            }
        }
    }

    public static void checkEditability (List<CMPL123CME__EMDR__c> lstEMDRsNew, Map<Id, CMPL123CME__EMDR__c> emdrOldMap ) {
        String profileName=[Select Id,Name from Profile where Id = :UserInfo.getProfileId()].Name;
        for (CMPL123CME__EMDR__c newEmdr : lstEMDRsNew) {
            CMPL123CME__EMDR__c oldEMDR = emdrOldMap.get(newEmdr.Id);
            if (null != oldEMDR && (oldEMDR.CMPL123CME__CMPL123_WF_Status__c == 'Pending ACK 1'
                    || oldEMDR.CMPL123CME__CMPL123_WF_Status__c == 'Pending ACK 2'
                    || oldEMDR.CMPL123CME__CMPL123_WF_Status__c == 'Pending ACK 3')
                    && oldEMDR.CMPL123CME__MDR_Submission__c == 'Submitted'
                    && newEmdr.CMPL123CME__CMPL123Task_Key_Value__c == oldEMDR.CMPL123CME__CMPL123Task_Key_Value__c
                    && newEmdr.CMPL123CME__CMPL123_WF_Action__c != null
                    && !newEmdr.CMPL123CME__CMPL123_WF_Action__c.containsIgnoreCase('failed')
                    && !isBeforeUpdateExecuted && profileName != 'ASPEN Integration') {
                newEmdr.addError(Label.PendingEMDRLockMessage);
            }


        }
    }

    /**
     * @Method       : updateTicketLastModifiedDate
     * @Invoke       : Events from Trigger after insert/update
     * @Description  : To update parent record "LastModifiedDate" field based on child records
     * @Return       : N/A
     * @Params       : N/A
     **/
    // Defect #123/CHARM-2729: added method to update parent tickets
    public static void updateTicketLastModifiedDate(){
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if(!UpdateParentUtility.isTicketUpdated || !ComplaintTriggerHandler.isTicketInserting){
            Set<Id> setComplaintIdToUpdate = new Set<Id>();
            for (CMPL123CME__EMDR__c objRecord : (List<CMPL123CME__EMDR__c>)Trigger.new) {
                Id ticketId = objRecord.CMPL123CME__Complaint__c;
                if (ticketId != null) {
                    setComplaintIdToUpdate.add(ticketId);
                }
            }
            if(setComplaintIdToUpdate.size() > 0){
                UpdateParentUtility.ticketTriggerPreventFlag = true;
                UpdateParentUtility.updateparent(setComplaintIdToUpdate);
                // Defect #123/CHARM-2729: disable ticket trigger logic only for UpdateParentUtility.updateparent method execution
                UpdateParentUtility.ticketTriggerPreventFlag = false;
            }
        }
    }

    /**
     * @Method       : getEditableOnPendingFields.
     * @Description  : To retrieve to retrieve set of editable fields on Pending statuses.
     * @Invoke       : From CMPL123CME_EMDR_AuditTrigger on bebore update events.
     * @Return       : Set<String>.
     * @Params       : N/A.
     */
    // Defect HC #100/CHARM-3518: added method to retrieve set of editable fields on Pending statuses
    public static Set<String> getEditableOnPendingFields(Set<String> lockedStatuses){
        Map<Id, CMPL123CME__EMDR__c> mapEMDRsOld = (Map<Id, CMPL123CME__EMDR__c>)Trigger.oldMap;
        Set<String> editableFields = new Set<String>();
        Boolean isCheckNeeded = false;
        for (CMPL123CME__EMDR__c newEMDR : (List<CMPL123CME__EMDR__c>)Trigger.new) {
            if ((newEMDR.CMPL123CME__CMPL123_WF_Status__c == mapEMDRsOld.get(newEMDR.Id).CMPL123CME__CMPL123_WF_Status__c)
                    && lockedStatuses.contains(newEMDR.CMPL123CME__CMPL123_WF_Status__c)) {
                isCheckNeeded = true;
                break;
            }
        }
        if (isCheckNeeded) {
            for(Fields_editable_on_Pending_closure__mdt fld : [SELECT API_Name__c FROM Fields_editable_on_Pending_closure__mdt]) {
                editableFields.add(fld.API_Name__c);
            }
        }
        return editableFields;
    }
    /**
     * @Method       : updateSubmittedDatetimeUponWorkflowActions.
     * @Description  : Sets Submission Datetime upon specific workflow actions.
     * @Invoke       : Events from EMDRTriggerHandler class.
     * @Params       : List<CMPL123CME__EMDR__c> lstEMDRsNew.
     * @Return       : N/A.
     */
    private static void updateSubmittedDatetimeUponWorkflowActions(Map<Id,CMPL123CME__EMDR__c> emdrOldMap,
        Map<Id,CMPL123CME__EMDR__c> lstEMDRsNewMap)
    {
        if (!lstEMDRsNewMap.isEmpty())
        {
            for (Id emdr: lstEMDRsNewMap.keySet())
            {
                if (lstEMDRsNewMap.get(emdr).CMPL123CME__CMPL123_WF_Action__c != emdrOldMap.get(emdr).CMPL123CME__CMPL123_WF_Action__c)
                {
                    if (lstEMDRsNewMap.get(emdr).CMPL123CME__CMPL123_WF_Action__c == 'Ack 1 Failed' ||
                    lstEMDRsNewMap.get(emdr).CMPL123CME__CMPL123_WF_Action__c == 'Ack 2 Failed' ||
                    lstEMDRsNewMap.get(emdr).CMPL123CME__CMPL123_WF_Action__c == 'Ack 3 Failed')
                    {
                        lstEMDRsNewMap.get(emdr).FDA_Status__c='Fail';
                        lstEMDRsNewMap.get(emdr).CMPL123CME__Submitted_Date_Time__c=null; 
                    }
                    //CHaRM R6:IPDR 552: Commented below code for IPDR 552 as the logic to update Submitted Date time is autopopulated from Sybmission History
                   /* if (lstEMDRsNewMap.get(emdr).CMPL123CME__CMPL123_WF_Action__c == 'Ack 1 Received')
                    {
                        lstEMDRsNewMap.get(emdr).CMPL123CME__Submitted_Date_Time__c=System.now();
                    }*/
                }
            }
        }
    } 
 
}