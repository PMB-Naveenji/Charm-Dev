/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS4RiskManagementTriggerHandler.
* @Why   : To perform all a Auto post workflow action.
* @When  : 23-MAR-2018.
* @Where : From Post_Market_Risk_Assessment_Risk_Contr_cloneWhenReopenAuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2018            Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    02-JUL-2020            Code Audit                Added method comment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue         Added 'executeLogicFromWFRules()' method to move logic from
*                                                                               Workflow Rules with Field Updates on PMRA to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDS4RiskManagementTriggerHandler {
    public static Boolean isFirst = false;
    public static Boolean isFirstHazzard = false;
    public static Boolean stopRecursionForClonedRecord = false;

    /**
    * @Method       : cloneWhenReopen
    * @Invoke       : From Post_Market_Risk_Assessment_Risk_Contr_AuditTrigger trigger
    * @Description  : W-000228 - Reopen Post Market Risk Record Cloning and New Versioning.
    * @Return       : N/A
    * @Params       : N/A
    **/
    public static void cloneWhenReopen(){
        if (StopRecursion.runonce()) {
            // Variable declaration
            List < Post_Market_Risk_Assessment_Risk_Contr__c > newRiskManagements = (List < Post_Market_Risk_Assessment_Risk_Contr__c > ) Trigger.New;
            Map < Id, Post_Market_Risk_Assessment_Risk_Contr__c > oldRiskMangementsMap = (Map < Id, Post_Market_Risk_Assessment_Risk_Contr__c > ) Trigger.OldMap;

            List <Post_Market_Risk_Assessment_Risk_Contr__c> updatedRiskManagementList = new List <Post_Market_Risk_Assessment_Risk_Contr__c>();
            List <Post_Market_Risk_Assessment_Risk_Contr__c> clonesRiskManagementList = new List <Post_Market_Risk_Assessment_Risk_Contr__c>();
            List <Post_Market_Risk_Assessment_Risk_Contr__c> UpdateclonedRiskManagementList = new List <Post_Market_Risk_Assessment_Risk_Contr__c>();
            List<CMPL123__WF_History__c> clonedWFHistory = new List<CMPL123__WF_History__c>();
            Id pmraId = newRiskManagements[0].Id;
            List<CMPL123__WF_History__c> listWFHistory = [SELECT CMPL123__Related_Id__c, CMPL123__Status__c, CMPL123__Workflow_Step__c, CMPL123__ESign_Applied__c, CMPL123__Comment__c, CMPL123__Action__c, CMPL123__Change_Summary__c, CMPL123__Change_Summary_Long__c, CMPL123__Date_Updated__c, CMPL123__Last_Modified_DateTime__c, CMPL123__Sequence_No__c FROM CMPL123__WF_History__c WHERE CMPL123__Related_Id__c =: pmraId ORDER BY CreatedDate DESC LIMIT 2];
            Map<ID,String> pmraChildIdAndStatusMap = new Map<ID,String>();
            for (Post_Market_Risk_Assessment_Risk_Contr__c riskAssessment: newRiskManagements) {
                //Cloning records.
                if (riskAssessment.CMPL123_WF_Action__c !=
                    oldRiskMangementsMap.get(riskAssessment.Id).CMPL123_WF_Action__c &&
                    (riskAssessment.CMPL123_WF_Action__c == 'Reopen' || riskAssessment.CMPL123_WF_Action__c == 'Reopen – go to Risk Control Measure Recommendation' )) {
                        updatedRiskManagementList.add(new Post_Market_Risk_Assessment_Risk_Contr__c(
                            Id = riskAssessment.Id,
                            Version_Number__c = (riskAssessment.Version_Number__c != null ? (riskAssessment.Version_Number__c + 1) : 2),
                            Closure_Date__c = null
                        ));

                        Post_Market_Risk_Assessment_Risk_Contr__c clonedRecord =
                            new Post_Market_Risk_Assessment_Risk_Contr__c();
                        clonedRecord = riskAssessment.clone(false, false, false, false);
                        clonedRecord.Post_Market_Risk_Asst_Risk_Ctrl__c = riskAssessment.Id;
                        clonedRecord.Is_Cloned__c = true;
                        clonedRecord.CMPL123Task_Key_Value__c = '';
                        clonedRecord.CMPL123_WF_Action__c = '';
                        clonedRecord.CMPL123_WF_Action_Performed_By__c = null;
                        clonedRecord.CMPL123_WF_Action_Performed_On__c = null;
                        clonedRecord.CMPL123_WF_Status__c = '';
                        clonesRiskManagementList.add(clonedRecord);
                    }

            }
            if (!updatedRiskManagementList.isEmpty() && updatedRiskManagementList.size() > 0) {
                update updatedRiskManagementList;
            }
            if (clonesRiskManagementList.size() > 0) {
                stopRecursionForClonedRecord = true;
                insert clonesRiskManagementList;
                List < sObject > childRecords = new List < sObject > ();
                Map<Id, sObject> mapclonedChildrenWithParent = new Map<Id, sObject>();
                Map<Id, sObject> mapclonedGrandChildrenWithParent = new Map<Id, sObject>();
                //added on 24 June for attachment clone
                Map<Id, Id> customAttachmentParentMap = new Map<Id, Id>(); //added today

                for (Post_Market_Risk_Assessment_Risk_Contr__c cloneRMRecord: clonesRiskManagementList) {
                    cloneRMRecord.CMPL123_WF_Status__c = 'Closed-Done';
                    UpdateclonedRiskManagementList.add(cloneRMRecord);
                    if(listWFHistory != null && listWFHistory.size() == 2){
                        CMPL123__WF_History__c wfHistory = new CMPL123__WF_History__c();
                        wfHistory = listWFHistory[1].clone(false, false, false, false);
                        wfHistory.CMPL123__Related_Id__c = cloneRMRecord.Id;
                        clonedWFHistory.add(wfHistory);
                        //added on 24 June for attachment clone
                        customAttachmentParentMap.put(cloneRMRecord.Post_Market_Risk_Asst_Risk_Ctrl__c, cloneRMRecord.Id);
                    }
                    for (Action_Task__c toBeClonedActionTask: [SELECT Id, Name,
                                                               Post_Market_Risk_Assessment_Risk_Contr__c,
                                                               Action_Type__c, Assignee__c,CMPL123_WF_Status__c ,
                                                               Date_Due__c, Action_Description__c, Other_Action_Type__c, Division__c, Assignee_Date__c,
                                                               Action_Activity_Completed__c, Reopen_Date__c, Reopening_Rationale__c,
                                                               Assigned_Assignee__c, Completed_By__c, Date_Due_Date__c, Completed_On__c, Closure_Date__c
                                                               FROM Action_Task__c WHERE Post_Market_Risk_Assessment_Risk_Contr__c IN: newRiskManagements
                                                              ]) {
                                                                  Action_Task__c clonedActionTask = toBeClonedActionTask.clone(false, false, false, false);
                                                                  pmraChildIdAndStatusMap.put(toBeClonedActionTask.Id,clonedActionTask.CMPL123_WF_Status__c);
                                                                  clonedActionTask.Post_Market_Risk_Assessment_Risk_Contr__c = cloneRMRecord.Id;
                                                                  clonedActionTask.Is_Cloned__c = true;
                                                                  clonedActionTask.CMPL123_WF_Status__c = '';
                                                                  childRecords.add(clonedActionTask);
                                                                  mapclonedChildrenWithParent.put(toBeClonedActionTask.Id, clonedActionTask);
                                                              }
                    for (Hazard_Assessment__c toBeClonedHA: [SELECT Id, Name,
                                                             Post_Market_Risk_Assessment_Risk_Contr__c,
                                                             Assignee__c, Description_of_the_Hazard__c,CMPL123_WF_Status__c ,
                                                             For_Incorrect_Results_describe__c, Current_Residual_Risk_Level__c,
                                                             Health_Hazard_Risk_Level__c,
                                                             For_delay_of_results_is_maximum_tolerab__c, Delay_of_results_associated_with_an_ASR__c,
                                                             Rationale_Associated_to_Delay_of_Results__c, Post_Market_Risk_Asst_Risk_Ctrl_ID__c,
                                                             Assignee_Date__c, Is_the_hazard_identified_in_the_RMF__c,
                                                             Known_hazard_src_pred_freq_IDd_in_RMF__c, RMF_Source_Reference_and_Location__c,
                                                             RMF_Description_of_Hazard__c, RMF_Descr_of_Source_Cause_of_Hazard__c,
                                                             Update_to_RMF_required__c,
                                                             RMF_Severity__c, RMF_Predicted_Frequency_Category__c, RMF_Frequencey_Type__c,
                                                             Opt_Risk_Evaluation_Will_be_Performed__c, RMF_Residual_Risk_Level__c,
                                                             Approach_for_Data_Analysis__c, Descr_Data_Used_Data_Anlys_Rationale__c,
                                                             Estimated_Current_Frequency_of_Hazard__c, Current_Frequency_of_Hazard_Category__c,
                                                             Does_the_Curt_Est_Freq_trigger_risk_eval__c, Optional_Risk_Evaluation_Rationale__c,
                                                             Hazard_Assessment_Completed_Date__c, Describe_Existing_Control_Measures_RMF__c,
                                                             Complaint_Search_Criteria_and_Results__c, Hazard_easily_identifiable_If_so_how__c,
                                                             Risk_Eval_Background_Completed_Date__c, Medical_Affairs_Assessor__c,
                                                             Medical_Review_Start_Date__c, Potential_Harm__c, Current_Severity_Level__c,
                                                             Probability_of_Occurrence_of_Harm__c, Health_Hazard_Risk_Rationale__c,
                                                             Update_to_RMF_required_per_HHA__c, Secondary_Medical_Affairs_Assessor__c,
                                                             HHA_Completed_Date__c, Division__c, Hazard_Type__c, Assigned_Assignee__c,
                                                             Assigned_Medical_Affairs_Assessor__c, Hazard_Assessment_Completed_By__c,
                                                             Risk_Evaluation_Background_Completed_By__c, HHA_Completed_By__c,CMPL123Rule_Key_Value__c,
                                                             Closure_Date__c,(SELECT Id, Known_hazard_src_pred_freq_ID_d_in_RMF__c, RMF_Residual_Risk_Level__c, RMF_Predicted_Frequency_Category__c, RMF_Severity__c, RMF_Descr_of_Source_Cause_of_Hazard__c, RMF_Description_of_Hazard__c, RMF_Source_Reference_and_Location__c FROM RMFs__r), (SELECT Id, Potential_Harm__c, Current_Severity_Level__c, Probability_of_Occurrence_of_Harm__c, Health_Hazard_Risk_Level__c, Health_Hazard_Risk_Rationale__c FROM Health_Hazard_Assessments__r) FROM Hazard_Assessment__c
                                                             WHERE Post_Market_Risk_Assessment_Risk_Contr__c IN: newRiskManagements
                                                            ]) {
                                                                Hazard_Assessment__c clonedHazardAssessment = toBeClonedHA.clone(false, false, false, false);
                                                                pmraChildIdAndStatusMap.put(toBeClonedHA.Id,clonedHazardAssessment.CMPL123_WF_Status__c);
                                                                clonedHazardAssessment.Post_Market_Risk_Assessment_Risk_Contr__c = cloneRMRecord.Id;
                                                                clonedHazardAssessment.Is_Cloned__c = true;
                                                                clonedHazardAssessment.CMPL123_WF_Status__c = 'Opened';
                                                                childRecords.add(clonedHazardAssessment);
                                                                mapclonedChildrenWithParent.put(toBeClonedHA.Id, clonedHazardAssessment);
                                                                //Clonning RMF's
                                                                for(RMF__c rmfObj : toBeClonedHA.RMFs__r){
                                                                    mapclonedGrandChildrenWithParent.put(rmfObj.Id, rmfObj.clone(false, false, false, false));
                                                                }
                                                                //Conning Health_Hazard_Assessment's
                                                                for(Health_Hazard_Assessment__c healthHAObj : toBeClonedHA.Health_Hazard_Assessments__r ){
                                                                    mapclonedGrandChildrenWithParent.put(healthHAObj.Id, healthHAObj.clone(false, false, false, false));
                                                                }
                                                            }
                    for (Regulatory_Assessment__c toBeClonedRA: [SELECT Id, Name,
                                                                 Post_Market_Risk_Assessment_Risk_Contr__c,CMPL123_WF_Status__c ,
                                                                 Site_Owner__c, Short_Description_of_Issue__c, Recognition_Date__c, Division__c,
                                                                 Assignee__c, Impact_to_Labeling__c, Impact_to_Product_Performance__c,
                                                                 Impact_to_a_US_Submission__c,
                                                                 Impact_to_an_International_Submission__c, Is_there_a_Regulatory_Impact__c,
                                                                 No_Regulatory_Impact_Rationale__c, Extent_of_Regulatory_Impact__c,
                                                                 Additional_Descr_of_Regulatory_Impact__c, Existing_Mitigating_Factors__c,
                                                                 Completed_Date__c,
                                                                 Reopen_Date__c, Reopening_Rationale__c, Assigned_Date__c, Impact_to_Claims__c,
                                                                 Impact_to_Product_s_Intended_Use__c, Impact_to_Design_Reqs_Specs__c, Assigned_Assignee__c,
                                                                 Closure_Date__c, Completed_By__c FROM Regulatory_Assessment__c
                                                                 WHERE Post_Market_Risk_Assessment_Risk_Contr__c IN: newRiskManagements
                                                                ]) {
                                                                    Regulatory_Assessment__c clonedRA = toBeClonedRA.clone(false, false, false, false);
                                                                    pmraChildIdAndStatusMap.put(toBeClonedRA.Id,clonedRA.CMPL123_WF_Status__c);
                                                                    clonedRA.Post_Market_Risk_Assessment_Risk_Contr__c = cloneRMRecord.Id;
                                                                    clonedRA.Is_Cloned__c = true;
                                                                    clonedRA.CMPL123_WF_Status__c = '';
                                                                    childRecords.add(clonedRA);
                                                                    mapclonedChildrenWithParent.put(toBeClonedRA.Id, clonedRA);

                                                                }
                    //Added - W-000310 - 05/12/2018 -Start
                    for (Additional_Approval__c toBeClonedAdditionalApproval : [SELECT Id, Name,Approval_Type__c, CMPL123_WF_Status__c ,
                                                                                Approve_By__c, Approve_On__c, Approver__c, Is_Cloned__c,
                                                                                Post_Market_ID__c, Reject_By__c, Reject_On__c,
                                                                                Reject_Rationale__c, Submit_for_Approval_By__c,
                                                                                Submit_for_Approval_On__c, Vioded_By__c, Voided_On__c
                                                                                FROM Additional_Approval__c WHERE Post_Market_ID__c IN: newRiskManagements
                                                                               ]) {
                                                                                   Additional_Approval__c clonedAdditionalApproval = toBeClonedAdditionalApproval.clone(false, false, false, false);
                                                                                   pmraChildIdAndStatusMap.put(toBeClonedAdditionalApproval.Id,clonedAdditionalApproval.CMPL123_WF_Status__c);
                                                                                   clonedAdditionalApproval.Post_Market_ID__c = cloneRMRecord.Id;
                                                                                   clonedAdditionalApproval.Is_Cloned__c = true;
                                                                                   clonedAdditionalApproval.CMPL123_WF_Status__c = '';
                                                                                   childRecords.add(clonedAdditionalApproval);
                                                                                   mapclonedChildrenWithParent.put(toBeClonedAdditionalApproval.Id, clonedAdditionalApproval);
                                                                               }

                    for(Risk_Assessment__c toBeClonedRiskAssessment : [SELECT Id, Batch_Lot_Serial__c, Expiration_Date__c, Product__c,
                                                                       Post_Market_Risk_Asst_Risk_Ctrl__c FROM Risk_Assessment__c WHERE Post_Market_Risk_Asst_Risk_Ctrl__c In : newRiskManagements]){

                                                                           Risk_Assessment__c clonedRiskAssessment = toBeClonedRiskAssessment.clone(false, false, false, false);
                                                                           clonedRiskAssessment.Post_Market_Risk_Asst_Risk_Ctrl__c = cloneRMRecord.Id;
                                                                           mapclonedChildrenWithParent.put(toBeClonedRiskAssessment.Id, clonedRiskAssessment);
                                                                       }
                    //Added - W-000310 - 05/12/2018 -End
                }
                if(!mapclonedChildrenWithParent.isEmpty() && mapclonedChildrenWithParent.size() > 0){
                    insert mapclonedChildrenWithParent.values();

                    //added on 24 June for attachment clone
                    for(Id originalParentId : mapclonedChildrenWithParent.keySet()){
                        customAttachmentParentMap.put(originalParentId, mapclonedChildrenWithParent.get(originalParentId).Id);
                    }
                    //added on 26 June to add attachment clone on RMF and HHA
                    Map<Id, SObject> cloneGrandChildMap = new Map<Id, SObject>();
                    if(!mapclonedGrandChildrenWithParent.isEmpty()){
                        for(Id oldRecordId : mapclonedGrandChildrenWithParent.keyset()){
                            Sobject clonedRecord = mapclonedGrandChildrenWithParent.get(oldRecordId);
                            if(clonedRecord.get('Hazard_Assessment__c') != null){
                                String oldRecordParentId = String.valueOf(clonedRecord.get('Hazard_Assessment__c'));
                                clonedRecord.put('Hazard_Assessment__c', customAttachmentParentMap.get(oldRecordParentId));
                                cloneGrandChildMap.put(oldRecordId, clonedRecord);
                            }
                        }
                    }
                    if(!cloneGrandChildMap.isEmpty()){
                        insert cloneGrandChildMap.values();
                    }
                    Map<Id, Id> standardAttachmentParentMap = new Map<Id, Id>();
                    for(Id originalParentId : cloneGrandChildMap.keySet()){
                        standardAttachmentParentMap.put(originalParentId, cloneGrandChildMap.get(originalParentId).Id);
                    }
                    cloneAttachments(customAttachmentParentMap, standardAttachmentParentMap);
                    List<SObject> updatePmraChildClonedList = new List<SObject>();
                    String raKeyprefix = Risk_Assessment__c.sObjectType.getDescribe().getKeyPrefix();
                    List<sObject> lstObjectToBeCloned = new List<sObject>();
                    for(Id originalHAId : mapclonedChildrenWithParent.keySet()){
                        String raIdPrefix = String.valueOf(originalHAId).substring(0,3);
                        if(raKeyprefix != raIdPrefix){
                            sObject pmraChildObject = mapclonedChildrenWithParent.get(originalHAId);
                            pmraChildObject.put('CMPL123_WF_Status__c', pmraChildIdAndStatusMap.get(originalHAId));
                            updatePmraChildClonedList.add(pmraChildObject);
                        }
                    }
                    if(updatePmraChildClonedList.size() > 0){
                        update updatePmraChildClonedList;
                    }
                    List<CMPL123__WF_History__c> clonedListWFHistory = new List<CMPL123__WF_History__c>();
                    for(CMPL123__WF_History__c wfHistoryObj :  [SELECT CMPL123__Related_Id__c, CMPL123__Status__c, CMPL123__Workflow_Step__c, CMPL123__ESign_Applied__c, CMPL123__Comment__c, CMPL123__Action__c, CMPL123__Change_Summary__c, CMPL123__Change_Summary_Long__c, CMPL123__Date_Updated__c, CMPL123__Last_Modified_DateTime__c, CMPL123__Sequence_No__c FROM CMPL123__WF_History__c WHERE CMPL123__Related_Id__c =: mapclonedChildrenWithParent.keySet() ORDER BY CMPL123__Related_Id__c, CMPL123__Sequence_No__c ]){

                        CMPL123__WF_History__c wfHistory = new CMPL123__WF_History__c();
                        wfHistory = wfHistoryObj.clone(false, false, false, false);
                        wfHistory.CMPL123__Related_Id__c = mapclonedChildrenWithParent.get(wfHistoryObj.CMPL123__Related_Id__c).Id;
                        clonedListWFHistory.add(wfHistory);

                    }
                    if(clonedListWFHistory.size() > 0){
                        Insert clonedListWFHistory;
                    }
                }
                if(UpdateclonedRiskManagementList.size() > 0){
                    Update UpdateclonedRiskManagementList;
                }
                if(clonedWFHistory.size() > 0){
                    Insert clonedWFHistory;
                }
            }
        }
    }

    /**
    * @Method       : autoCreateRiskAsstChildRecord
    * @Invoke       : From Post_Market_Risk_Assessment_Risk_Contr_AuditTrigger trigger
    * @Description  : Auto creation of Hazard assessment and action task object
    * @Return       : N/A
    * @Params       : N/A
    **/
    public static void autoCreateRiskAsstChildRecord() {
        List < Post_Market_Risk_Assessment_Risk_Contr__c > newPostMarketAsst =
            (List < Post_Market_Risk_Assessment_Risk_Contr__c > ) Trigger.new;
        Set < String > multiPicklistValues = new Set < String > ();
        Set < String > parentIdSet = new Set < String > ();
        Set < String > postAssRecIdsSet = new Set < String > ();
        Set < String > closedPostAssRecIdSet = new Set < String > ();
        List < Hazard_Assessment__c > hazardRecToInsert = new List < Hazard_Assessment__c > ();
        List < Post_Market_Risk_Assessment_Risk_Contr__c > updateFlagList =
            new List < Post_Market_Risk_Assessment_Risk_Contr__c > ();
        List < Post_Market_Risk_Assessment_Risk_Contr__c > actionTaskUpdateFlagList =
            new List < Post_Market_Risk_Assessment_Risk_Contr__c > ();
        Id parentId;

        //looping the trigger.new variable of risk assesment object to check specified condition.
        for (Post_Market_Risk_Assessment_Risk_Contr__c postAssRec: newPostMarketAsst) {
            // Auto creation of hazard record for ADD and AMD in specified condition.
            if (postAssRec.CMPL123Rule_Key_Value__c == 'ADDRiskManagement' ||
                postAssRec.CMPL123Rule_Key_Value__c == 'AMDRiskManagment') {
                    if (postAssRec.CMPL123_WF_Status__c != null &&
                        postAssRec.CMPL123_WF_Status__c == 'Hazard Assessment In Process' &&
                        postAssRec.Is_Auto_Hazard_Assessment_Created__c == False &&
                        postAssRec.Potential_Hazard_Types_Associated_with_I__c != null) {
                            // create the hazard record depeding on the value selected in hazard type.
                            String[] tmpString = postAssRec.Potential_Hazard_Types_Associated_with_I__c.split(';');
                            for (String str: tmpString) {
                                multiPicklistValues.add(str);
                            }
                            parentId = postAssRec.id;
                            if (multiPicklistValues != null && multiPicklistValues.size() > 0) {
                                if (multiPicklistValues.contains('None Apply')) {
                                    multiPicklistValues.remove('None Apply');
                                }
                                if (multiPicklistValues != null && multiPicklistValues.size() > 0) {
                                    parentIdSet.add(postAssRec.id);
                                    for (String picklistVal: multiPicklistValues) {
                                        Hazard_Assessment__c hazardRecord;
                                        hazardRecord = new Hazard_Assessment__c(
                                            Post_Market_Risk_Assessment_Risk_Contr__c = parentId,
                                            Hazard_Type__c = picklistVal
                                        );
                                        hazardRecToInsert.add(hazardRecord);
                                    }
                                }
                            }
                        }
                }
            // Auto creation of Action task for AMD
            if (postAssRec.CMPL123Rule_Key_Value__c != null &&
                postAssRec.CMPL123Rule_Key_Value__c == 'AMDRiskManagment' &&
                postAssRec.CMPL123_WF_Status__c != null &&
                postAssRec.CMPL123_WF_Status__c == 'Risk Evaluation in Process' &&
                postAssRec.Division__c != null && postAssRec.Division__c == 'AMD' &&
                postAssRec.Is_Auto_Action_Task_Created__c == False) {
                    postAssRecIdsSet.add(postAssRec.id);
                }
        }
        if (hazardRecToInsert != null && hazardRecToInsert.size() > 0) {
            if (!isFirstHazzard) {
                insert hazardRecToInsert;
                isFirstHazzard = true;
            }
            // Make the flag to false to avoide autocreation twice.
            if (parentIdSet != null && parentIdSet.size() > 0) {
                for (Post_Market_Risk_Assessment_Risk_Contr__c postAssRec: [SELECT Is_Auto_Hazard_Assessment_Created__c
                                                                            FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN: parentIdSet
                                                                           ]) {
                                                                               if (postAssRec.Is_Auto_Hazard_Assessment_Created__c == False) {
                                                                                   postAssRec.Is_Auto_Hazard_Assessment_Created__c = True;
                                                                                   updateFlagList.add(postAssRec);
                                                                               }
                                                                           }
                if (updateFlagList != null && updateFlagList.size() > 0) {
                    update updateFlagList;
                }
            }
        }

        List<Post_Market_Risk_Assessment_Risk_Contr__c> newMarketRisk = (List<Post_Market_Risk_Assessment_Risk_Contr__c>)Trigger.New;
        Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldMarketRiskMap = (Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c>)Trigger.oldMap;
        //Added - W-000303 - 23/10/2018 -Start
        System.debug('ADDS4RiskManagementTriggerHandler.autoCreateRiskAsstChildRecord - Before calling closedVoidAllRelatedChildren method'+isFirst);
        if(!isFirst){
            System.debug('ADDS4RiskManagementTriggerHandler.autoCreateRiskAsstChildRecord - inside if closedVoidAllRelatedChildren method'+isFirst);
            closedVoidAllRelatedChildren(newMarketRisk, oldMarketRiskMap);
        }
        //Added - W-000303 - 23/10/2018 -End

    }

    /**
    * @Method       : closedVoidAllRelatedChildren
    * @Invoke       : From Post_Market_Risk_Assessment_Risk_Contr_AuditTrigger trigger
    * @Description  : W-000303 - (Ticket) Void all child records that have a workflow and not in Closed status
    *            should be automatically moved to Closed - Voided status
    * @Return       : N/A
    * @Params       : List<Post_Market_Risk_Assessment_Risk_Contr__c> lstRisksNew,  Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> mapRisksOld
    **/
    //W-000303 - (Post_Market_Risk_Assessment_Risk_Contr__c) Void all child records that have a workflow and not in Closed status should be automatically moved to Closed - Voided status
    private static void closedVoidAllRelatedChildren(List<Post_Market_Risk_Assessment_Risk_Contr__c> lstRisksNew,  Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> mapRisksOld){
        isFirst = true;
        Set<Id> setRisksIds = New Set<Id>();
        System.debug('ADDS4RiskManagementTriggerHandler.closedVoidAllRelatedChildren - inside closedVoidAllRelatedChildren method'+isFirst);
        if(trigger.isUpdate){
            for(Post_Market_Risk_Assessment_Risk_Contr__c objTicket : lstRisksNew){
                if(Trigger.isUpdate && objTicket.CMPL123_WF_Status__c == 'Closed-Voided' && mapRisksOld.get(objTicket.Id).CMPL123_WF_Status__c != objTicket.CMPL123_WF_Status__c){
                    setRisksIds.add(objTicket.Id);
                }
            }
        }

        //Query all the related child records without the workflow status ("Closed-Voided")
        Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey = New Map<String,CMPL123__WF_Step__c>();
        Set<String> setChildObjectAPINames = New Set<String>{'Post_Market_Risk_Assessment_Risk_Contr__c','Regulatory_Assessment__c','Hazard_Assessment__c','Action_Task__c','Additional_Approval__c'};
            for(CMPL123__WF_Step__c objWFStep :
                [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,CMPL123__WF_Rule__r.CMPL123__Target_Object__c,
                 CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c WHERE
                 CMPL123__End_Status__r.Name = 'Closed-Voided' AND
                 CMPL123__Action__r.Name = 'Void' AND CMPL123__WF_Rule__r.CMPL123__Is_Active__c = true] ){
                     if(setChildObjectAPINames.contains(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c.substringBefore('('))){
                         mapWFStepWithRuleKey.put(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c,objWFStep);
                     }
                 }
        List<CMPL123__WF_History__c> lstWFHistories = New list<CMPL123__WF_History__c>();
        List<sObject> lstsObjects = New List<sObject>();
        Set<Id> setQuestionnaires = new Set<Id>();
        Set<Id> setEvalInvestTasks = new Set<Id>();
        for(Post_Market_Risk_Assessment_Risk_Contr__c objTicket :
            [SELECT Id,CMPL123Rule_Key_Value__c,
             (SELECT Id,CMPL123Rule_Key_Value__c FROM Regulatory_Assessments__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
             (SELECT Id,CMPL123Rule_Key_Value__c FROM Hazard_Assessments__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
             (SELECT Id,CMPL123Rule_Key_Value__c FROM Action_Tasks__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
             (SELECT Id,CMPL123Rule_Key_Value__c FROM Additional_Approval__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%'))
             FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN: setRisksIds]){


                 for(sObject objRegulatoryAssessment : objTicket.Regulatory_Assessments__r){
                     String strKey = 'Regulatory_Assessment__c' + (String.valueOf(objRegulatoryAssessment.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objRegulatoryAssessment.get('CMPL123Rule_Key_Value__c'))+')' : '');
                     if(mapWFStepWithRuleKey.containsKey(strKey)){
                         //lstsObjects.add(TicketUtil.populateWFFields(objRegulatoryAssessment, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                         //lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objRegulatoryAssessment.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                         objRegulatoryAssessment.put('CMPL123Task_Key_Value__c', 'MoveToClosed');
                         lstsObjects.add(objRegulatoryAssessment);
                     }

                 }

                 for(sObject objHazardAssessment : objTicket.Hazard_Assessments__r){
                     String strKey = 'Hazard_Assessment__c' + (String.valueOf(objHazardAssessment.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objHazardAssessment.get('CMPL123Rule_Key_Value__c'))+')' : '');
                     if(mapWFStepWithRuleKey.containsKey(strKey)){
                         lstsObjects.add(TicketUtil.populateWFFields(objHazardAssessment, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                         lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objHazardAssessment.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                     }
                 }

                 for(sObject objActionTask : objTicket.Action_Tasks__r){
                     setQuestionnaires.add(String.valueOf(objActionTask.get('Id')));
                     String strKey = 'Action_Task__c' + (String.valueOf(objActionTask.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objActionTask.get('CMPL123Rule_Key_Value__c'))+')' : '');
                     if(mapWFStepWithRuleKey.containsKey(strKey)){
                         lstsObjects.add(TicketUtil.populateWFFields(objActionTask, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                         lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objActionTask.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                     }
                 }

                 for(sObject objAdditionalApprover : objTicket.Additional_Approval__r){
                     setQuestionnaires.add(String.valueOf(objAdditionalApprover.get('Id')));
                     String strKey = 'Additional_Approval__c' + (String.valueOf(objAdditionalApprover.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objAdditionalApprover.get('CMPL123Rule_Key_Value__c'))+')' : '');
                     if(mapWFStepWithRuleKey.containsKey(strKey)){
                         lstsObjects.add(TicketUtil.populateWFFields(objAdditionalApprover, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                         lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objAdditionalApprover.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                     }
                 }
             }

        if(lstsObjects.size() > 0){
            update lstsObjects;
            insert lstWFHistories;
        }
        System.debug('ADDS4RiskManagementTriggerHandler.closedVoidAllRelatedChildren - before completing closedVoidAllRelatedChildren method'+isFirst);
    }

    /**
    * @Method       : preventCloseIfActionTaskNotClosed
    * @Description  : W-000301 - check all action task are closed before posting Related Child Records & Tasks Closed
    * @Return       : N/A
    * @Params       : N/A
    **/
    //W-000301 - check all action task are closed before posting Related Child Records & Tasks Closed
    public static void preventCloseIfActionTaskNotClosed(){

        Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c> newRiskAssessMap = (Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c>) Trigger.newMap;
        if (newRiskAssessMap != null) {
            for(Post_Market_Risk_Assessment_Risk_Contr__c objPmrisk : [SELECT CMPL123_WF_Action__c,
                                                                       (SELECT Id,CMPL123_WF_Status__c FROM Action_Tasks__r WHERE CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided') FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN :newRiskAssessMap.keyset()]) {

                                                                           if((objPmrisk.Action_Tasks__r.size() > 0
                                                                               && (newRiskAssessMap.get(objPmrisk.id).CMPL123_WF_Action__c == 'Related Child Records and Tasks Closed'))){
                                                                                   newRiskAssessMap.get(objPmrisk.id).addError(System.Label.Post_Market_Risk_Assessment_Risk_Contr_Action_Task_Not_Closed);
                                                                               }

                                                                       }
        }

        List<Post_Market_Risk_Assessment_Risk_Contr__c> pmraList = (List<Post_Market_Risk_Assessment_Risk_Contr__c>)Trigger.New;
        Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> pmraOldMap =(Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c>)Trigger.oldMap;
    }

    /**
    * @Method       : preventSubmitHazardAssessmentForApproval
    * @Description  : W-000298 - check all Additional Approval  records are Closed-Done or Closed-Voided before allowing to perform Submit Hazard Assessment for Approval or No Hazards action
    * @Return       : N/A
    * @Params       : N/A
    **/
    public static void preventSubmitHazardAssessmentForApproval(){
        Map < Id, Post_Market_Risk_Assessment_Risk_Contr__c > newRiskMangementsMap = (Map < Id, Post_Market_Risk_Assessment_Risk_Contr__c > ) Trigger.NewMap;
        // Variable declaration
        List < Post_Market_Risk_Assessment_Risk_Contr__c > riskControlList = [SELECT ID, (SELECT Id, CMPL123_WF_Action__c FROM Additional_Approval__r WHERE (CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided') ) FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE  Id IN: newRiskMangementsMap.keyset()];
        for(Post_Market_Risk_Assessment_Risk_Contr__c riskControl : riskControlList){
            if((newRiskMangementsMap.get(riskControl.Id).CMPL123_WF_Action__c == 'Submit Hazard Assessment for Approval' || newRiskMangementsMap.get(riskControl.Id).CMPL123_WF_Action__c == 'No Hazards' || newRiskMangementsMap.get(riskControl.Id).CMPL123_WF_Action__c == 'Pass-Through DVP Quality Assurance Approval')&& riskControl.Additional_Approval__r.size() > 0){
                newRiskMangementsMap.get(riskControl.Id).addError(System.Label.Post_Market_Risk_Assessment_Risk_Contr_Additional_Approval_Records);

            }
        }
    }

    /**
    * @Method       : checkRiskAssessmentProduct
    * @Description  : W-000305 - Check if product is present before performing Submit Hazard Assessment for Approval / No Hazards for ADD
    * @Return       : N/A
    * @Params       : N/A
    **/
    // W-000305 -  Check if product is present before performing Submit Hazard Assessment for Approval / No Hazards for ADD
    public static void checkRiskAssessmentProduct(){
        Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c> newPostMarketAsst = (Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c>) Trigger.newMap;

        for(Post_Market_Risk_Assessment_Risk_Contr__c objPmrisk : [SELECT CMPL123_WF_Action__c,
                                                                   CMPL123Rule_Key_Value__c,
                                                                   (SELECT Id FROM Risk_Assessment_Products__r) FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN :newPostMarketAsst.keyset()]) {

                                                                       if((newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c == 'Submit Hazard Assessment for Approval'
                                                                           || newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c == 'No Hazards') &&
                                                                          newPostMarketAsst.get(objPmrisk.id).CMPL123Rule_Key_Value__c == 'ADDRiskManagement' &&
                                                                          objPmrisk.Risk_Assessment_Products__r.size() < 1){
                                                                              newPostMarketAsst.get(objPmrisk.id).addError(System.Label.Post_Market_Risk_Assessment_Risk_Contr_Risk_Assessment_Product);
                                                                          }
                                                                   }
    }

    /**
    * @Method       : checkHazardAssessment
    * @Description  : W-000551 - Post Market Risk Asst & Risk Ctrl record from ‘Hazard Assessment in Process’ to ‘Pending Hazard Assessment Approval’ status can be moved when all Hazard Assessment child records are in the ‘Pending Parent Hazard Assessment Approval’ or ‘Closed-Voided’ status (for ADD only).
    * @Return       : N/A
    * @Params       : N/A
    **/
    // W-000551 - Post Market Risk Asst & Risk Ctrl record from ‘Hazard Assessment in Process’ to ‘Pending Hazard Assessment Approval’ status can be moved when all Hazard Assessment child records are in the ‘Pending Parent Hazard Assessment Approval’ or ‘Closed-Voided’ status (for ADD only).
    public static void checkHazardAssessment(){
        Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c> newPostMarketAsst = (Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c>) Trigger.newMap;
        Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c> oldPostMarketAsst = (Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c>) Trigger.oldMap;

        for(Post_Market_Risk_Assessment_Risk_Contr__c objPmrisk : [SELECT CMPL123_WF_Action__c,
                                                                   CMPL123Rule_Key_Value__c,
                                                                   (SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c FROM Hazard_Assessments__r) FROM
                                                                   Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN :newPostMarketAsst.keyset()]) {
                                                                       Integer pendingParentHAAppClosedVoidedCount = 0;
                                                                       Integer closedDoneCount = 0;

                                                                       for(Hazard_Assessment__c objhazardAsst : objPmrisk.Hazard_Assessments__r) {

                                                                           if(((newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c == AspenConstants.STR_Submit_Hazard_Assessment_for_Approval
                                                                                && newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c != oldPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c) ||
                                                                               (newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c == AspenConstants.STR_No_Hazards
                                                                                && newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c != oldPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c))
                                                                              && (objhazardAsst.CMPL123_WF_Status__c != AspenConstants.STR_Pending_Parent_Hazard_Assessment_Approval &&
                                                                                  objhazardAsst.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Voided )
                                                                              && newPostMarketAsst.get(objPmrisk.id).CMPL123Rule_Key_Value__c == AspenConstants.STR_ADDRiskManagement){
                                                                                  newPostMarketAsst.get(objPmrisk.id).addError(System.Label.Post_Market_Risk_Asst_Risk_Contr_Hazard_Asst_Pending_Approval_Closed_Void);
                                                                              }

                                                                           // W-000552 Post Market Risk Asst & Risk Ctrl record from ‘Risk Evaluation in Process’ to ‘Pending Risk Evaluation Approval’ status can be moved when all Hazard Assessment records are
                                                                           // in ‘Pending Parent Risk Evaluation Approval’, ‘Closed-Done’ or ‘Closed-Voided status
                                                                           if((newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c == AspenConstants.STR_Submit_Risk_Evaluation_for_Approval
                                                                               && newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c != oldPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c)
                                                                              && (objhazardAsst.CMPL123_WF_Status__c != AspenConstants.STR_Pending_Parent_Risk_Evaluation_Approval &&
                                                                                  objhazardAsst.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Voided &&
                                                                                  objhazardAsst.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Done )&&
                                                                              newPostMarketAsst.get(objPmrisk.id).CMPL123Rule_Key_Value__c == AspenConstants.STR_ADDRiskManagement){
                                                                                  newPostMarketAsst.get(objPmrisk.id).addError(System.Label.Post_Market_Risk_Asst_Risk_Contr_Hazard_Asst_Pending_Risk_Approval_Closed_Void);
                                                                              }

                                                                           // W-000553 Post Market Risk Asst & Risk Ctrl record from Pending Risk Evaluation Approva’ to ‘Risk Control Measure Recommended’ or 'Risk Control Measure Not Recommended' status can be
                                                                           // moved when all Hazard Assessment records are in ‘Closed-Done’ or ‘Closed-Voided status.
                                                                           if(((newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c == AspenConstants.STR_Risk_Control_Measure_Recommended
                                                                                || newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c == AspenConstants.STR_Risk_Control_Measure_Not_Recommended )
                                                                               && newPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c != oldPostMarketAsst.get(objPmrisk.id).CMPL123_WF_Action__c)
                                                                              && (objhazardAsst.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Voided &&
                                                                                  objhazardAsst.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Done )&&
                                                                              newPostMarketAsst.get(objPmrisk.id).CMPL123Rule_Key_Value__c == AspenConstants.STR_ADDRiskManagement){
                                                                                  newPostMarketAsst.get(objPmrisk.id).addError(System.Label.Post_Market_Risk_Asst_Risk_Contr_Hazard_Assessment_Closed);
                                                                              }
                                                                       }

                                                                   }

    }

    /**
    * @Method       : checkRegulatoryAssessmentCount
    * @Description  : Takes Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> as a parameter and makes sure that RMF child can be created only when the Hazard Assessment parent record is in Opened status or Hazard Assessment In Process status
    * @Return       : N/A
    * @Params       : Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> newMapPostMarketRiskAsses, Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldMapPostMarketRiskAsses
    // W-000496 RMF child can be created only when the Hazard Assessment parent record is in Opened status or Hazard Assessment In Process status
    // W-000574  - Added Source__c != 'Pass-Through'
    **/
    public static void checkRegulatoryAssessmentCount(Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> newMapPostMarketRiskAsses, Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldMapPostMarketRiskAsses){

        Set<Id> setPmraInRiskControlMeasureInProcess = new Set<Id>();

        for(Post_Market_Risk_Assessment_Risk_Contr__c objPostRiskAsses : newMapPostMarketRiskAsses.values()){
            if(objPostRiskAsses.CMPL123_WF_Status__c == 'Risk Control Measure in Process' && objPostRiskAsses.CMPL123_WF_Status__c != oldMapPostMarketRiskAsses.get(objPostRiskAsses.Id).CMPL123_WF_Status__c ){
                setPmraInRiskControlMeasureInProcess.add(objPostRiskAsses.Id);
            }
        }
        for(Post_Market_Risk_Assessment_Risk_Contr__c objPostRiskAsses: [SELECT Id, Source__c, (SELECT Id, CMPL123_WF_Status__c FROM Regulatory_Assessments__r WHERE (CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided') LIMIT 1), CMPL123_WF_Status__c, CMPL123_WF_Action__c FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN: setPmraInRiskControlMeasureInProcess] ){
            if(objPostRiskAsses.Regulatory_Assessments__r.size() > 0 && newMapPostMarketRiskAsses.get(objPostRiskAsses.Id).CMPL123_WF_Status__c == 'Risk Control Measure in Process' && newMapPostMarketRiskAsses.get(objPostRiskAsses.Id).Source__c != 'Pass-Through'){
                newMapPostMarketRiskAsses.get(objPostRiskAsses.Id).addError('All Regulatory Assessment records in "Closed" status are required.');
            }
        }
    }

    /**
    * @Method       : checkAdditionalApprovalCount
    * @Description  : Validate checkAdditionalApprovalCount when 'Submit for Pass-Through Approval' action is performed on PMRA.
    * @Return       : N/A
    * @Params       : Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> newMapPostMarketRiskAsses, Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldMapPostMarketRiskAsses
    **/
    public static void checkAdditionalApprovalCount(Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> newMapPostMarketRiskAsses, Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldMapPostMarketRiskAsses){
        for(Post_Market_Risk_Assessment_Risk_Contr__c objPostRiskAsses: [SELECT Id, (SELECT Id, CMPL123_WF_Status__c FROM Additional_Approval__r WHERE (CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided') LIMIT 1) FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN: newMapPostMarketRiskAsses.keyset()] ){
            if(objPostRiskAsses.Additional_Approval__r.size() > 0 && newMapPostMarketRiskAsses.get(objPostRiskAsses.Id).CMPL123_WF_Action__c != oldMapPostMarketRiskAsses.get(objPostRiskAsses.Id).CMPL123_WF_Action__c && newMapPostMarketRiskAsses.get(objPostRiskAsses.Id).CMPL123_WF_Action__c == 'Submit for Pass-Through Approval'){
                newMapPostMarketRiskAsses.get(objPostRiskAsses.Id).addError('All Additional Approval records in "Closed" status are required.');
            }
        }
    }

    /**
    * @Method       : validateHazardAssessments
    * @Description  : Validate HazardAssessments when 'Hazard Assessment Approve – No Risk Evaluation' action is performed on PMRA.
    * @Return       : N/A
    * @Params       : N/A
    **/
    public static void validateHazardAssessments(Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> newMapPostMarketRiskAsses, Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldMapPostMarketRiskAsses){

        //Set to hold PMRA record ids on which 'Hazard Assessment Approve – No Risk Evaluation' action is performed.
        Set<Id> pmraSet = new Set<Id>();
        for(Post_Market_Risk_Assessment_Risk_Contr__c pmraObj : newMapPostMarketRiskAsses.values()){
            if(pmraObj.CMPL123_WF_Action__c == 'Hazard Assessment Approve – No Risk Evaluation' && pmraObj.CMPL123_WF_Action__c != oldMapPostMarketRiskAsses.get(pmraObj.Id).CMPL123_WF_Action__c){
                pmraSet.add(pmraObj.Id);
            }
        }

        if(!pmraSet.isEmpty()){
            for(Post_Market_Risk_Assessment_Risk_Contr__c pmraObj : [SELECT Id,(SELECT Id FROM Hazard_Assessments__r WHERE CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided' AND (Does_the_Curt_Est_Freq_trigger_risk_eval__c = 'Yes' OR Opt_Risk_Evaluation_Will_be_Performed__c = 'Yes') LIMIT 1) FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN :pmraSet]){
                if(pmraObj.Hazard_Assessments__r.size() > 0){
                    Post_Market_Risk_Assessment_Risk_Contr__c pmraNewObj = newMapPostMarketRiskAsses.get(pmraObj.Id);
                    pmraNewObj.addError(System.label.PMRA_Hazard_Assessment_Approve_No_Risk_Evaluation_Action);
                }
            }

        }
    }

    /**
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history
    * @Return       : N/A
    * @Params       : Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> newRecordMap,
    *                 Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldRecordMap
    **/
    public static void setReopenRationale(Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> newRecordMap,
                                          Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldRecordMap){
                                              Post_Market_Risk_Assessment_Risk_Contr__c oldPMRA;
                                              Post_Market_Risk_Assessment_Risk_Contr__c newPMRA;
                                              if(newRecordMap.keyset().size() == 1){
                                                  for(Post_Market_Risk_Assessment_Risk_Contr__c pmra : newRecordMap.values()){
                                                      newPMRA = pmra;
                                                      oldPMRA = oldRecordMap.get(pmra.Id);
                                                  }
                                                  if(newPMRA.CMPL123_WF_Action__c != null && newPMRA.CMPL123_WF_Action__c.containsIgnorecase('Reopen')
                                                     && newPMRA.CMPL123_WF_Action__c != oldPMRA.CMPL123_WF_Action__c){
                                                         newPMRA.Reopening_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newPMRA.Id);
                                                     }
                                              }
                                          }

    /**
    * @Method       : checkEditAccess
    * @Description  : used to restrict to update fields on some statuses (1703/1704)
    * @Return       : N/A
    * @Params       : Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> newRecordMap,
    *                 Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldRecordMap
    **/
    public static void checkEditAccess (Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c> newRecordMap,
                                        Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c> oldRecordMap) {
        List <PermissionSetAssignment> currentUserPermissionSetAssignments = [
                                                SELECT Id, PermissionSet.Name
                                                FROM PermissionSetAssignment
                                                WHERE AssigneeId = :UserInfo.getUserId()
                                        ];
        Set <String> permSets = new Set <String>();
        for (PermissionSetAssignment permSet: currentUserPermissionSetAssignments) {
            permSets.add(permSet.PermissionSet.Name);
        }
        List <String> allowedStatuses = new List <String>{'Pending Pass-Through Approval',
                                                            'Pending Risk Evaluation Approval',
                                                            'Pending Senior Management Approval',
                                                            'Pending TSB - Senior Management Approval'};

        if (permSets.contains('Risk_Assessment_Hazard_Assessment_Approver_ADD') && !permSets.contains('Risk_Assessment_Risk_Evaluation_Approver_ADD')) {
            for (Post_Market_Risk_Assessment_Risk_Contr__c pmra: newRecordMap.values()) {
                if (pmra.CMPL123_WF_Status__c == oldRecordMap.get(pmra.Id).CMPL123_WF_Status__c
                    && !allowedStatuses.contains(pmra.CMPL123_WF_Status__c)
                    && pmra.Typographical_Rejection_Reason__c != oldRecordMap.get(pmra.Id).Typographical_Rejection_Reason__c) {
                        pmra.addError(System.label.Not_editable_fields + ' Typographical Rejection Reason');
                }
            }
        }
        if (permSets.contains('Risk_Assessment_Hazard_Assessment_Approver_ADD') && permSets.contains('Risk_Assessment_Risk_Evaluation_Approver_ADD')) {
            allowedStatuses.add('Pending Typographical Changes Approval');
            allowedStatuses.add('Typographical Changes');
            for (Post_Market_Risk_Assessment_Risk_Contr__c pmra: newRecordMap.values()) {
                if (pmra.CMPL123_WF_Status__c == oldRecordMap.get(pmra.Id).CMPL123_WF_Status__c
                    && !allowedStatuses.contains(pmra.CMPL123_WF_Status__c)
                    && pmra.Typographical_Rejection_Reason__c != oldRecordMap.get(pmra.Id).Typographical_Rejection_Reason__c) {
                        pmra.addError(System.label.Not_editable_fields + ' Typographical Rejection Reason');
                }
            }
        }
    }

    /*
    * @Method       : executeLogicFromWFRules
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on PMRA.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void executeLogicFromWFRules() {
        List<Post_Market_Risk_Assessment_Risk_Contr__c> newList = (List<Post_Market_Risk_Assessment_Risk_Contr__c>) Trigger.new;
        Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c> oldMap = (Map<Id, Post_Market_Risk_Assessment_Risk_Contr__c>) Trigger.oldMap;

        for (Post_Market_Risk_Assessment_Risk_Contr__c newPMRA :newList) {
            Boolean wfActionIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && newPMRA.CMPL123_WF_Action__c != oldMap.get(newPMRA.Id).CMPL123_WF_Action__c);
            Boolean wfStatusIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && newPMRA.CMPL123_WF_Status__c != oldMap.get(newPMRA.Id).CMPL123_WF_Status__c);

            DateTime actionPerformedOn = DateTime.now();
            String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

            if (wfActionIsChanged) {
                //  Clear Hazard Assesment Approver
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_Send_Back_To_HA_In_Process) {
                    newPMRA.Hazard_Assessment_Approval_Date__c = null;
                    newPMRA.Hazard_Assessment_Approved_By__c = null;
                    newPMRA.Hazard_Assessment_Approved_On__c = null;
                }

                //  Clear Risk Evaluation Approver
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_Send_Back_To_RE_In_Process) {
                    newPMRA.Risk_Evaluation_Exec_Quality_Approved_By__c = null;
                    newPMRA.Risk_Evaluation_Exec_Quality_Approved_On__c = null;
                    newPMRA.Risk_Evaluation_Quality_Approved_By__c = null;
                    newPMRA.Risk_Evaluation_Quality_Approved_On__c = null;
                }

                //  Workflow - DVP Marketing
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_DVP_Marketing_Approval) {
                    newPMRA.DVP_Marketing_Approval_By__c = actionPerformedBy;
                    newPMRA.DVP_Marketing_Approval_On__c = actionPerformedOn;
                }

                //  Workflow - DVP Medical Affairs
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_DVP_Medical_Affairs_Approval) {
                    newPMRA.DVP_Medical_Affairs_Approval_By__c = actionPerformedBy;
                    newPMRA.DVP_Medical_Affairs_Approval_On__c = actionPerformedOn;
                }

                //  Workflow - DVP Quality Assurance
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_DVP_Quality_Assurance_Approval) {
                    newPMRA.DVP_Quality_Assurance_Approval_By__c = actionPerformedBy;
                    newPMRA.DVP_Quality_Assurance_Approval_On__c = actionPerformedOn;
                }

                //  Workflow - DVP Regulatory Affairs
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_DVP_Regulatory_Affairs_Approval) {
                    newPMRA.DVP_Regulatory_Affairs_Approval_By__c = actionPerformedBy;
                    newPMRA.DVP_Regulatory_Affairs_Approval_On__c = actionPerformedOn;
                }

                //  Workflow - Director Core Global Service Operations
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_Director_Core_Global_Service_Operations_Approval) {
                    newPMRA.Director_Core_Global_Service_Ops_By__c = actionPerformedBy;
                    newPMRA.Director_Core_Global_Service_Ops_On__c = actionPerformedOn;
                }

                //  Workflow - Hazard Assessment Approval
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_HA_Approve_No_Risk_Eval
                        || newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_HA_Approve_Risk_Eval
                        || newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_Approve_No_Hazards_No_Risk_Eval) {
                    newPMRA.Hazard_Assessment_Approved_By__c = actionPerformedBy;
                    newPMRA.Hazard_Assessment_Approval_Date__c = actionPerformedOn;
                    newPMRA.Hazard_Assessment_Approved_On__c = actionPerformedOn;
                }

                //  Workflow - QA Manager
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_QA_Manager_Approval) {
                    newPMRA.QA_Manager_Approval_By__c = actionPerformedBy;
                    newPMRA.QA_Manager_Approval_On__c = actionPerformedOn;
                    newPMRA.Risk_Evaluation_Quality_Approved_By__c = actionPerformedBy;
                    newPMRA.Risk_Evaluation_Quality_Approved_On__c = actionPerformedOn;
                }

                //  Risk Control Measure Recommended
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_Risk_Control_Measure_Recommended) {
                    newPMRA.RCM_Initiation_Date__c = actionPerformedOn;
                }

                //  Workflow - Risk Evaluation Exec Quality Approved
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_Site_Supply_Chain_QA_Head_Approval) {
                    newPMRA.Risk_Evaluation_Exec_Quality_Approved_By__c = actionPerformedBy;
                    newPMRA.Risk_Evaluation_Exec_Quality_Approved_On__c = actionPerformedOn;
                }

                //  Clear Approver fields after Reject
                if (newPMRA.CMPL123_WF_Action__c == AspenConstants.STR_Risk_Evaluation_Reject) {
                    newPMRA.Risk_Evaluation_Exec_Quality_Approved_By__c = null;
                    newPMRA.Risk_Evaluation_Quality_Approved_On__c = null;
                    newPMRA.Risk_Evaluation_Quality_Approved_By__c = null;
                    newPMRA.Risk_Evaluation_Exec_Quality_Approved_On__c = null;
                    newPMRA.Risk_Evaluation_Approval_Date__c = null;
                }
            }

            if (wfStatusIsChanged) {
                //  Closure Date should be auto populated when the record is moved to Closed – Done status
                if (newPMRA.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Done && !newPMRA.Is_Cloned__c) {
                    newPMRA.Closure_Date__c = Date.today();
                }

                //  Workflow - Hazard Assessment In Process State
                if (newPMRA.CMPL123_WF_Status__c == AspenConstants.STR_HA_In_Process
                        && newPMRA.Hazard_Assessment_Initiation_Date__c == null) {
                    newPMRA.Hazard_Assessment_Initiation_Date__c = actionPerformedOn;
                }

                //  Workflow - Risk Evaluation In Process State
                if (newPMRA.CMPL123_WF_Status__c == AspenConstants.STR_Risk_Evaluation_In_Process
                        && newPMRA.Risk_Evaluation_Initiation_Date__c == null) {
                    newPMRA.Risk_Evaluation_Initiation_Date__c = actionPerformedOn;
                }
            }

            //  Initiation
            if (Trigger.isInsert && !newPMRA.Is_Cloned__c) {
                newPMRA.Initiator__c = actionPerformedBy;
                newPMRA.Initiated_Date__c = actionPerformedOn;
                newPMRA.CMPL123Rule_Key_Value__c = newPMRA.Division__c == 'ADD' ? 'ADDRiskManagement' : 'AMDRiskManagment';
            }

            //  Workflow - Risk Evaluation Approval Date
            if (newPMRA.Risk_Evaluation_Quality_Approved_By__c != null
                    && newPMRA.Risk_Evaluation_Exec_Quality_Approved_By__c != null) {
                newPMRA.Risk_Evaluation_Approval_Date__c = actionPerformedOn;
            }
        }
    }

    /**
    * @Method       : cloneAttachments
    * @Description  : clone attachments of PMRA and related child
    * @Return       : N/A
    * @Params       : Map<Id, Id>
    **/
    public static void cloneAttachments(Map<Id, Id> customAttachmentParentMap, Map<Id, Id> standardAttachmentParentMap){
        Map<Id, Attachment__c> customAttMap = new Map<Id, Attachment__c>([SELECT Id, Name, Attachment_Description__c, Attachment_Id__c,
                                                                          Attachment_Status__c, Attachment_Title__c, Attachment_Type__c, Attachment_Type_And_Status__c, CMSNext_Ticket_Number__c, Delete_Flag__c,
                                                                          Deletion_Justification__c, File_Name__c, Is_Delete__c, Key_List__c, Last_Modified__c, Registartion_Attachment__c,
                                                                          Registration_Number__c, Registration_Ticket__c, Send_to_CMSNext__c, UNC_Path__c, Regulatory_Assessment__c,
                                                                          Post_Market_Risk_Asst_Risk_Ctrl__c, Hazard_Assessment__c, Action_Task__c, Additional_Approval__c FROM Attachment__c WHERE
                                                                          Regulatory_Assessment__c IN:customAttachmentParentMap.keyset() OR Post_Market_Risk_Asst_Risk_Ctrl__c IN:customAttachmentParentMap.keyset()
                                                                          OR Hazard_Assessment__c IN:customAttachmentParentMap.keyset() OR Action_Task__c IN:customAttachmentParentMap.keyset()
                                                                          OR Additional_Approval__c IN:customAttachmentParentMap.keyset()]);

        AggregateResult[] groupedResults = [SELECT SUM(BodyLength) attSize FROM Attachment WHERE ParentId IN: customAttMap.keyset()];

        if (Integer.valueOf(groupedResults[0].get('attSize')) > 55000000) {
            List<sObject> sObjects = Trigger.isDelete ? Trigger.old : Trigger.new;

            for (sObject obj :sObjects) {
                obj.addError('Operation failed, attachment cannot be cloned as size exceeds 60MB');
                break;
            }
        } else {
            Map<Id, Attachment__c> clonedAttachments = new Map<Id, Attachment__c>();
            for(Id recordId : customAttMap.keyset()){
                Attachment__c originalAttachment = customAttMap.get(recordId);
                Attachment__c clonedAttachment = originalAttachment.clone(false, false, false, false);
                if(originalAttachment.Post_Market_Risk_Asst_Risk_Ctrl__c != null){
                    clonedAttachment.Post_Market_Risk_Asst_Risk_Ctrl__c = customAttachmentParentMap.get(originalAttachment.Post_Market_Risk_Asst_Risk_Ctrl__c);
                }else if(originalAttachment.Regulatory_Assessment__c != null){
                    clonedAttachment.Regulatory_Assessment__c = customAttachmentParentMap.get(originalAttachment.Regulatory_Assessment__c);
                }else if(originalAttachment.Hazard_Assessment__c != null){
                    clonedAttachment.Hazard_Assessment__c = customAttachmentParentMap.get(originalAttachment.Hazard_Assessment__c);
                }else if(originalAttachment.Action_Task__c != null){
                    clonedAttachment.Action_Task__c = customAttachmentParentMap.get(originalAttachment.Action_Task__c);
                }else{
                    clonedAttachment.Additional_Approval__c = customAttachmentParentMap.get(originalAttachment.Additional_Approval__c);
                }
                clonedAttachments.put(recordId, clonedAttachment);
            }
            if(clonedAttachments.keyset().size() > 0){
                insert clonedAttachments.values();
                List<Attachment> clonedStandardAtts = new List<Attachment>();

                for(Attachment att : [SELECT Id, ParentId, Name, IsPrivate, ContentType, BodyLength, Body, OwnerId, Description,
                                      IsDeleted FROM Attachment WHERE ParentId IN :clonedAttachments.keyset() OR ParentId IN :standardAttachmentParentMap.keyset()]){
                                          Attachment clonedAtt = att.clone(false, false, false, false);
                                          if(clonedAttachments.get(att.ParentId) != null)
                                              clonedAtt.ParentId = clonedAttachments.get(att.ParentId).Id;
                                          else if(standardAttachmentParentMap.get(att.ParentId) != null)
                                              clonedAtt.ParentId = standardAttachmentParentMap.get(att.ParentId);

                                          clonedStandardAtts.add(clonedAtt);
                                      }
                if(clonedStandardAtts.size() > 0){
                    insert clonedStandardAtts;
                }
            }
        }
    }
}