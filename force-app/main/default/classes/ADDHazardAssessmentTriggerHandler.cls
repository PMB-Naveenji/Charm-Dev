/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : ADDHazardAssessmentTriggerHandler.
* @Why   : Handles all the customization involved on Hazard Assessment object.
* @When  : 06-APR-2017.
* @Where : From Hazard_Assessment_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    06-APR-2017            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    28-DEC-2020            TWD Upgrade issue             Related to WF Step issue, rules with field update moved
*                                                                                   to this handler.
* ---------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    26-JAN-2021            TWD Upgrade issue             Removed reference to obsolete WF Status.
* ---------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDHazardAssessmentTriggerHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        //CMPL123.AuditHandler.handleAudit();
        //Upgrade issue start. WF: Autoset Completed By and Completed On Dates.
        List <Hazard_Assessment__c> haWithNewStatusOrAction = new List <Hazard_Assessment__c>();
        List <Id> actionPerformedByIds = new List <Id>();
        List <Hazard_Assessment__c> haToUpdateRuleKeyVal = new List <Hazard_Assessment__c>();
        List <Id> pmraIds = new List <Id>();

        //Upgrade issue end.
        for(Hazard_Assessment__c hAobj : (List<Hazard_Assessment__c>)Trigger.new){
            if(hAobj.Hazard_Type__c != 'Delay of Results' && !hAobj.Is_Cloned__c){
                hAobj.Rationale_Associated_to_Delay_of_Results__c = 'N/A';
            }else if(hAobj.Hazard_Type__c != 'Incorrect Results' && !hAobj.Is_Cloned__c){
                hAobj.For_Incorrect_Results_describe__c = 'N/A';
            }
            //Upgrade issue start. WF: Autoset Completed By and Completed On Dates.
            if (hAobj.CMPL123_WF_Action__c != null || hAobj.CMPL123_WF_Status__c != null) {
                haWithNewStatusOrAction.add(hAobj);
                actionPerformedByIds.add(hAobj.CMPL123_WF_Action_Performed_By__c);
            }
            //WF: Autoset RMF Frequency Type for ADD
            //WF: Update Delay associated with an ASR,LDA or RUO?
            if (hAobj.Division__c == 'ADD') {
                hAobj.RMF_Frequencey_Type__c = 'Harm';
                hAobj.Delay_of_results_associated_with_an_ASR__c = 'N/A';
            }
            //WF: Clear HHA Complete Field
            if (hAobj.CMPL123_WF_Action__c == 'Send back to Hazard Assessment In Process') {
                hAobj.Hazard_Assessment_Completed_By__c = null;
                hAobj.Hazard_Assessment_Completed_Date__c = null;
                hAobj.HHA_Completed_By__c = null;
                hAobj.HHA_Completed_Date__c = null;
            }
            //WF: Clear Risk Evaluation Background Field
            if (hAobj.CMPL123_WF_Action__c == 'Send Back to Risk Evaluation in Process') {
                hAobj.Risk_Evaluation_Background_Completed_By__c = null;
                hAobj.Risk_Eval_Background_Completed_Date__c = null;
            }
            //WF: Hazard Type <> Delay of Results
            if (hAobj.Hazard_Type__c != 'Delay of Results') {
                hAobj.Delay_of_results_associated_with_an_ASR__c = 'N/A';
                hAobj.For_delay_of_results_is_maximum_tolerab__c = 'N/A';
            }
            //WF: Known Hazard Src No - RMF Desc of Hazard
            if (hAobj.Known_hazard_src_pred_freq_IDd_in_RMF__c == 'No' && hAobj.RMF_Description_of_Hazard__c == null) {
                hAobj.RMF_Description_of_Hazard__c = 'None';
            }
            //WF: Known Hazard Src No - RMF Desc of Src
            if (hAobj.RMF_Descr_of_Source_Cause_of_Hazard__c == null && hAobj.Known_hazard_src_pred_freq_IDd_in_RMF__c == 'No') {
                hAobj.RMF_Descr_of_Source_Cause_of_Hazard__c = 'None';
            }
            //WF: Reopened Date update
            if (hAobj.CMPL123_WF_Action__c == 'Reopen' ) {
                hAobj.CMPL123Task_Key_Value__c = null;
                hAobj.Reopen_Date__c = hAobj.CMPL123_WF_Action_Performed_On__c;
            }
            //WF: Update Rule Field Update Key Value
            if (hAobj.CMPL123Rule_Key_Value__c == null  && !hAobj.Is_Cloned__c) {
                haToUpdateRuleKeyVal.add(hAobj);
                pmraIds.add(hAobj.Post_Market_Risk_Assessment_Risk_Contr__c);
            }
            //Upgrade issue end.
        }
        //Upgrade issue start. WF: Autoset Completed By and Completed On Dates.
        autoSetFields(actionPerformedByIds, haWithNewStatusOrAction);
        //WF: Update Rule Field Update Key Value
        setRuleKeyVal(pmraIds, haToUpdateRuleKeyVal);
        //Upgrade issue end.
    }

    /*
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        //W-000495 - The system shall not move Hazard Assessment from ‘Hazard Assessment in Process’ to ‘Pending Parent Hazard Assessment Approval’ status  without at least one RMF record
        Map<Id,Hazard_Assessment__c> mapHazardAssessments = (Map<Id,Hazard_Assessment__c>)Trigger.newMap;
        Map<Id,Hazard_Assessment__c> oldHazardAssessments = (Map<Id,Hazard_Assessment__c>)Trigger.oldMap;
        //Upgrade issue start. WF: Autoset Completed By and Completed On Dates.
        List <Hazard_Assessment__c> haWithNewStatusOrAction = new List <Hazard_Assessment__c>();
        List <Id> actionPerformedByIds = new List <Id>();
        //Upgrade issue end.
        ADDS4HazardsAssessmentTriggerHandler.checkRMFCount(mapHazardAssessments);

        for(Hazard_Assessment__c hAobj : mapHazardAssessments.values()){
            //Clear Reopening_Rationale__c on Close Action  STR_Closed_Done
            //if(hAobj.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Close && hAobj.CMPL123_WF_Action__c != oldHazardAssessments.get(hAobj.Id).CMPL123_WF_Action__c){
                //hAobj.Reopening_Rationale__c = '';
            //}

            if(hAobj.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done && hAobj.CMPL123_WF_Status__c != oldHazardAssessments.get(hAobj.Id).CMPL123_WF_Status__c){
                hAobj.Quality_Notes__c = '';
            }

            if(hAobj.Hazard_Type__c != 'Delay of Results' && !hAobj.Is_Cloned__c){
                hAobj.Rationale_Associated_to_Delay_of_Results__c = 'N/A';
            }else if(hAobj.Hazard_Type__c != 'Incorrect Results' && !hAobj.Is_Cloned__c){
                hAobj.For_Incorrect_Results_describe__c = 'N/A';
            }
            //Upgrade issue start. WF: Autoset Completed By and Completed On Dates.
            if (hAobj.CMPL123_WF_Action__c != oldHazardAssessments.get(hAobj.Id).CMPL123_WF_Action__c  || hAobj.CMPL123_WF_Status__c != oldHazardAssessments.get(hAobj.Id).CMPL123_WF_Status__c  ) {
                haWithNewStatusOrAction.add(hAobj);
                actionPerformedByIds.add(hAobj.CMPL123_WF_Action_Performed_By__c);
            }
            //WF: Clear HHA Complete Field
            if (hAobj.CMPL123_WF_Action__c == 'Send back to Hazard Assessment In Process' && oldHazardAssessments.get(hAobj.Id).CMPL123_WF_Action__c != hAobj.CMPL123_WF_Action__c) {
                hAobj.Hazard_Assessment_Completed_By__c = null;
                hAobj.Hazard_Assessment_Completed_Date__c = null;
                hAobj.HHA_Completed_By__c = null;
                hAobj.HHA_Completed_Date__c = null;
            }
            //WF: Clear Risk Evaluation Background Field
            if (hAobj.CMPL123_WF_Action__c == 'Send Back to Risk Evaluation in Process' && oldHazardAssessments.get(hAobj.Id).CMPL123_WF_Action__c != hAobj.CMPL123_WF_Action__c) {
                hAobj.Risk_Evaluation_Background_Completed_By__c = null;
                hAobj.Risk_Eval_Background_Completed_Date__c = null;
            }
            //WF: Hazard Type <> Delay of Results
            if (hAobj.Hazard_Type__c != 'Delay of Results' ) {
                hAobj.Delay_of_results_associated_with_an_ASR__c = 'N/A';
                hAobj.For_delay_of_results_is_maximum_tolerab__c = 'N/A';
            }
            //WF: Known Hazard Src No - RMF Desc of Hazard
            if (hAobj.Known_hazard_src_pred_freq_IDd_in_RMF__c == 'No' && hAobj.RMF_Description_of_Hazard__c == null
                && (oldHazardAssessments.get(hAobj.Id).Known_hazard_src_pred_freq_IDd_in_RMF__c != hAobj.Known_hazard_src_pred_freq_IDd_in_RMF__c
                || oldHazardAssessments.get(hAobj.Id).RMF_Description_of_Hazard__c != hAobj.RMF_Description_of_Hazard__c )) {
                    hAobj.RMF_Description_of_Hazard__c = 'None';
            }
            //WF: Known Hazard Src No - RMF Desc of Src
            if (hAobj.RMF_Descr_of_Source_Cause_of_Hazard__c == null && hAobj.Known_hazard_src_pred_freq_IDd_in_RMF__c == 'No'
                && (oldHazardAssessments.get(hAobj.Id).RMF_Descr_of_Source_Cause_of_Hazard__c != hAobj.RMF_Descr_of_Source_Cause_of_Hazard__c
                || oldHazardAssessments.get(hAobj.Id).Known_hazard_src_pred_freq_IDd_in_RMF__c != hAobj.Known_hazard_src_pred_freq_IDd_in_RMF__c )) {
                    hAobj.RMF_Descr_of_Source_Cause_of_Hazard__c = 'None';
            }
            //WF: Reopened Date update
            if (hAobj.CMPL123_WF_Action__c != oldHazardAssessments.get(hAobj.Id).CMPL123_WF_Action__c && hAobj.CMPL123_WF_Action__c == 'Reopen' ) {
                hAobj.CMPL123Task_Key_Value__c = null;
                hAobj.Reopen_Date__c = hAobj.CMPL123_WF_Action_Performed_On__c;
            }
            //Upgrade issue end.
        }

        setReopenRationale(mapHazardAssessments, oldHazardAssessments);
        //Upgrade issue start. WF: Autoset Completed By and Completed On Dates.
        autoSetFields(actionPerformedByIds, haWithNewStatusOrAction);
        //Upgrade issue end.

        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterUpdate() {
        CMPL123.AuditHandler.handleAudit();

        ADDS4HazardsAssessmentTriggerHandler.autoPostWorkflowActionsinRiskManagements();
    }

    /*
    * @Method       : beforeDelete
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : To handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : setRuleKeyVal.
    * @Description  : Autoset field values. Logic moved from WF rule: Update Rule Field Update Key Value
    * @Invoke       : From ADDHazardsAssessmentTriggerHandler class.
    * @Return       : N/A.
    * @Params       : List<Id> pmraIds, List <Hazard_Assessment__c> hazzardAssessment.
    */
    public static void setRuleKeyVal (List<Id> pmraIds, List <Hazard_Assessment__c> hazzardAssessments ) {
        Map <Id, Post_Market_Risk_Assessment_Risk_Contr__c> pmraById = new Map <Id, Post_Market_Risk_Assessment_Risk_Contr__c>(
                                                        [SELECT Division__c
                                                        FROM Post_Market_Risk_Assessment_Risk_Contr__c
                                                        WHERE Id in : pmraIds]);
        for (Hazard_Assessment__c hazzardAssessment : hazzardAssessments) {
            if (pmraById.containsKey(hazzardAssessment.Post_Market_Risk_Assessment_Risk_Contr__c)) {
                if(pmraById.get(hazzardAssessment.Post_Market_Risk_Assessment_Risk_Contr__c).Division__c == '') {
                    hazzardAssessment.CMPL123Rule_Key_Value__c = '';
                } else if (pmraById.get(hazzardAssessment.Post_Market_Risk_Assessment_Risk_Contr__c).Division__c == 'AMD') {
                    hazzardAssessment.CMPL123Rule_Key_Value__c = 'HAZARD_ASSESSMENT_AMD_WORKFLOW';
                } else {
                    hazzardAssessment.CMPL123Rule_Key_Value__c = 'HAZARD_ASSESSMENT_ADD_WORKFLOW';
                }
            }
        }
    }

    /*
    * @Method       : autoSetFields.
    * @Description  : Autoset field values. Logic moved from WF rule: Autoset Completed By and Completed On Dates
    * @Invoke       : From ADDHazardsAssessmentTriggerHandler class.
    * @Return       : N/A.
    * @Params       : List<Id> actionPerformedByIds, List<Hazard_Assessment__c> recordsToUpdateIds.
    */
    public static void autoSetFields (List<Id> actionPerformedByIds, List<Hazard_Assessment__c> recordsToUpdate) {
        Map<Id, User> userById = new Map<Id, User>([SELECT Id, FirstName, LastName FROM User WHERE Id in: actionPerformedByIds]);

        for (Hazard_Assessment__c recordToUpdate: recordsToUpdate) {
            if (recordToUpdate.CMPL123_WF_Action__c == 'Hazard Assessment Completed') {
                recordToUpdate.Hazard_Assessment_Completed_Date__c = recordToUpdate.CMPL123_WF_Action_Performed_On__c;
                recordToUpdate.Hazard_Assessment_Completed_By__c = userById.get(recordToUpdate.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' +
                                                                   userById.get(recordToUpdate.CMPL123_WF_Action_Performed_By__c)?.LastName;
            }
            if (recordToUpdate.CMPL123_WF_Action__c == 'Promote') {
                recordToUpdate.Assignee_Date__c = recordToUpdate.CMPL123_WF_Action_Performed_On__c;
            }
            if (recordToUpdate.CMPL123_WF_Action__c == 'HHA Complete') {
                recordToUpdate.HHA_Completed_Date__c = recordToUpdate.CMPL123_WF_Action_Performed_On__c;
                recordToUpdate.HHA_Completed_By__c = userById.get(recordToUpdate.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' +
                                                     userById.get(recordToUpdate.CMPL123_WF_Action_Performed_By__c)?.LastName;
            }
            if (recordToUpdate.CMPL123_WF_Action__c == 'Submit for HHA') {
                recordToUpdate.Risk_Eval_Background_Completed_Date__c = recordToUpdate.CMPL123_WF_Action_Performed_On__c;
                recordToUpdate.Risk_Evaluation_Background_Completed_By__c = userById.get(recordToUpdate.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' +
                                                                            userById.get(recordToUpdate.CMPL123_WF_Action_Performed_By__c)?.LastName;
            }
        }
    }

    /*
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history
    * @Return       : N/A
    * @Params       : Map<Id,Hazard_Assessment__c> newRecordMap,
    *                 Map<Id,Hazard_Assessment__c> oldRecordMap
    */
    public static void setReopenRationale(Map<Id,Hazard_Assessment__c> newRecordMap, Map<Id,Hazard_Assessment__c> oldRecordMap) {
        Hazard_Assessment__c oldRecord;
        Hazard_Assessment__c newRecord;

        if(newRecordMap.keyset().size() == 1){
            for(Hazard_Assessment__c ha : newRecordMap.values()){
                newRecord = ha;
                oldRecord = oldRecordMap.get(ha.Id);
            }
            if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase('Reopen')
                && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                newRecord.Reopening_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
            }
        }
    }
}