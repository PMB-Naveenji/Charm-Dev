/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : QuestionnaireTriggerHandler.
* @Why   : Public class to manage all the custom coding invoked on the Questionnaire object.
* @When  : 23-MAR-2017.
* @Where : From QuestionnaireTriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID              Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                   23-MAR-2017            N/A                          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   22-MAY-2020            #123/CHARM-2729              Added return of updated ticket ids
*                                                                             into afterEventHandler and closeTicketBasedOnQuestionnaires
*                                                                             methods, created updateTicketLastModifiedDate method.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   27-MAY-2020            #123/CHARM-2729              Prevented multiple updates of the ticket
*                                                                             in the same transaction.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   04-JUN-2020            Code Audit                   Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   11-JUN-2020            Defect #104/CHARM-2615       Added verification for reportability of Medical Evaluation
*                                                                             record into the IF statement, in beforEventHandler() method.
*                                                                             Added IF statement in beforEventHandler() method, to throw
*                                                                             an error when reportable Medical Evaluation record is moving
*                                                                             to "Close-Done" status with only one type of voided submission.
*                                                                             Added IF statement in beforEventHandler() method, to throw
*                                                                             an error when non-reportable Medical Evaluation record is moving
*                                                                             to "Close-Done" status with MDI in 'Closed-Wavied' status.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020           Code Audit                    Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   24-NOV-2020           HC #82 CHARM-3441,#132        Added missed parentheses into validation condition.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                   30-DEC-2020           TWD Upgrade issue             Added method to cover disabled WF logic.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   26-JAN-2020           TWD Upgrade issue             Updated logic from WF Rules.
* --------------------------------------------------------------------------------------------------------------------------------------
* OBriceno                21-MAY-2021           HyperCare IPDR 194            Added setDateOfIncidence method invoked before insert to get
*                                                                             Date_of_Incidence__c from Complaint just on creation 
*/

public class QuestionnaireTriggerHandler {
    public static boolean reportabilityHistoryRunOnce = false;
    public static boolean systemMedEvalTaskFlag = false;
    private static Set<Id> setQuestionAdverseEventIds = new Set<Id>();

    /*
    * @Method       : beforeInsertEventHandler
    * @Invoke       : Events from before Insert Event Handler
    * @Description  : To handle all the logic in before Insert Event Handler
    * @Return       : N/A
    * @Params       : N/A
    */
    public static void beforeInsertEventHandler(){
        List<CMPL123CME__Questionnaire__c> newMedEvals = (List<CMPL123CME__Questionnaire__c>)Trigger.new;
        setInitialAwarenessDate(newMedEvals);
        setDateOfIncidence(newMedEvals);
        //addCurrentTimeToDateFields();
    }

    /*
    * @Method       : beforEventHandler
    * @Invoke       : Events from befor Event Handler
    * @Description  : To handle all the logic in before Event Handler
    * @Return       : N/A
    * @Params       : N/A
    */
    public static void beforEventHandler(){
        TicketUtil.addTrace('QuestionnaireTriggerHandler.beforEventHandler - ' + Trigger.isUpdate);
        Map<Id, CMPL123CME__Questionnaire__c> newQuestionnaireMap
                = (Map<Id, CMPL123CME__Questionnaire__c>)Trigger.newMap;
        Map<Id, CMPL123CME__Questionnaire__c> oldQuestionnaireMap
                = (Map<Id, CMPL123CME__Questionnaire__c>)Trigger.oldMap;

        //Added - W-000103 - Added inner query - (SELECT Id, Name,RecordType.Name FROM Medical_Evaluation_Tasks__r WHERE CMPL123_WF_Status__c != 'Closed-done' AND
        //CMPL123_WF_Status__c != 'Closed-Voided' AND
        //RecordType.Name != 'RCML Review Task')
        // 07JAN19 - SOQL Limit Fix
        // Not need to do any processing on insert
        if(oldQuestionnaireMap == null) { return; }
        // Query the child only when the Status of the record Changes
        Set<Id> statusChangedIds = new Set<Id>();
        for(CMPL123CME__Questionnaire__c ques: newQuestionnaireMap.values()) {
            if(ques.CMPL123_WF_Status__c != oldQuestionnaireMap.get(ques.Id).CMPL123_WF_Status__c) {
                statusChangedIds.add(ques.id);
            }
        }

        if(statusChangedIds.isEmpty()) { return; }

        if(System.Limits.getQueries() < System.Limits.getLimitQueries()){
            for(CMPL123CME__Questionnaire__c questionnaire : [SELECT Id, Name,
            (SELECT Id, Name, CMPL123_WF_Status__c FROM MDI__r),
            (SELECT Id, Name, CMPL123CME__CMPL123_WF_Status__c FROM EMDR__r),
            // Sprint 10 code changes start : Rahamtulla
            (select id,name,CMPL123_WF_Status__c from EU_MIR__r),
            //sprint 10 code changes end  :Rahamtulla  
            (SELECT Id, Name, RecordType.Name FROM Medical_Evaluation_Tasks__r
            WHERE CMPL123_WF_Status__c != 'Closed-Done' AND
            CMPL123_WF_Status__c != 'Closed-Voided' AND RecordType.Name != 'RCML Review Task')
            FROM CMPL123CME__Questionnaire__c
            WHERE Id IN :statusChangedIds]) {
                CMPL123CME__Questionnaire__c oldQuestionnaire = oldQuestionnaireMap.get(questionnaire.Id);

                if(Trigger.isUpdate) {
                    // Flags to verify the child records
                    Set<String> allSubmissionStatusSet = new Set<String>();
                    Set<String> openSubmissionStatusSet = new Set<String>();
                    Set<String> closedStatusSet = new Set<String>{'Closed-Done', 'Closed-Voided','Closed - Voided', 'Closed - Waived', 'Closed-Waived'};
                    Set<Id> closedVoidedeMDRSet = new Set<Id>();
                    Set<Id> closedVoidedMDISet = new Set<Id>();
                    // Sprint 10 code changes start : Rahamtulla
                    Set<Id> closedVoidedeMIRSet = new Set<Id>();
                    //sprint 10 code changes end  :Rahamtulla
                    if(questionnaire.MDI__r.size() > 0 || questionnaire.EMDR__r.size() > 0 || questionnaire.EU_MIR__r.size()>0) {
                        for(CMPL123CME__MEDDEV__c mdi: questionnaire.MDI__r) {
                            if(mdi.CMPL123_WF_Status__c != null){
                                allSubmissionStatusSet.add(mdi.CMPL123_WF_Status__c);
                                if(mdi.CMPL123_WF_Status__c == 'Closed-Voided' || mdi.CMPL123_WF_Status__c == 'Closed - Voided'){
                                    closedVoidedMDISet.add(mdi.Id);
                                }
                            }
                        }

                        for(CMPL123CME__EMDR__c emdr: questionnaire.EMDR__r) {
                            if(emdr.CMPL123CME__CMPL123_WF_Status__c != null){
                                allSubmissionStatusSet.add(emdr.CMPL123CME__CMPL123_WF_Status__c);
                                if(emdr.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Voided'){
                                    closedVoidedeMDRSet.add(emdr.Id);
                                }
                            }
                        }
                        //sprint 10 code changes start :Rahamtulla 
                        for(CMPL123CME__EU_MIR__c mir: questionnaire.EU_MIR__r) {
                            if(mir.CMPL123_WF_Status__c != null){
                                allSubmissionStatusSet.add(mir.CMPL123_WF_Status__c);
                                if(mir.CMPL123_WF_Status__c == 'Closed-Voided' || mir.CMPL123_WF_Status__c == 'Closed - Voided'){
                                    closedVoidedeMIRSet.add(mir.Id);    
                                }
                            }                                                                                  
                        }       
                        //sprint 10 code changes end :Rahamtulla    

                        openSubmissionStatusSet.addAll(allSubmissionStatusSet);
                        openSubmissionStatusSet.removeAll(closedStatusSet);
                    }
                    if((questionnaire.MDI__r.size() > 0 && questionnaire.MDI__r.size() == closedVoidedMDISet.size())
                            && (questionnaire.EMDR__r.size() > 0 && questionnaire.EMDR__r.size() == closedVoidedeMDRSet.size())
                            && newQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c == 'Closed-Done'
                            && newQuestionnaireMap.get(questionnaire.Id).Reportability__c == 'Reportable' // Added in scope of the Defect #104/CHARM-2615
                            //sprint 10 code changes start :Rahamtulla 
                            && (questionnaire.EU_MIR__r.size() > 0 && questionnaire.EU_MIR__r.size() == closedVoidedeMIRSet.size())
                            //sprint 10 code changes end :Rahamtulla 
                            ){  
                        newQuestionnaireMap.get(questionnaire.Id).addError(
                                System.label.Medical_Evaluation_Voided_Submissions
                        );
                    }
                    // Fix defect #104/CHARM-2615 start
                    // HC #82 CHARM-3441, #132: Added missed parentheses into validation condition.
                    if (((questionnaire.MDI__r.isEmpty() && (!questionnaire.EMDR__r.isEmpty() && questionnaire.EMDR__r.size() == closedVoidedeMDRSet.size()))
                        || (questionnaire.EMDR__r.isEmpty() && (!questionnaire.MDI__r.isEmpty() && questionnaire.MDI__r.size() == closedVoidedMDISet.size())))
                        && newQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c == 'Closed-Done'
                        && newQuestionnaireMap.get(questionnaire.Id).Reportability__c == 'Reportable') {
                            newQuestionnaireMap.get(questionnaire.Id).addError(
                                System.Label.Medical_Evaluation_Voided_Submissions);
                    }

                    if ((allSubmissionStatusSet.contains('Closed - Waived') || allSubmissionStatusSet.contains('Closed-Done'))
                        && newQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c == 'Closed-Done'
                        && newQuestionnaireMap.get(questionnaire.Id).Reportability__c != 'Reportable') {
                                newQuestionnaireMap.get(questionnaire.Id).addError(
                                    System.Label.Medical_Evaluation_Closed_Or_Waived_Submissions);
                    }
                    // Fix defect #104/CHARM-2615 end

                    if(newQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c == 'Closed-Done' &&
                            newQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c !=
                                    oldQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c) {
                        if(openSubmissionStatusSet.size() > 0) {
                            newQuestionnaireMap.get(questionnaire.Id).addError(
                                    System.label.Medical_Evaluation_Open_submissions);
                        } else if(questionnaire.Medical_Evaluation_Tasks__r.size() > 0) {  //Added for W-000103
                            newQuestionnaireMap.get(questionnaire.Id).addError(
                                    System.Label.Medical_Evaluation_Open_Task_s);
                        }
                    }

                    //Added for W-000328
                    if(newQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c == 'Closed-Voided' &&
                            newQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c !=
                                    oldQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c) {
                        if((allSubmissionStatusSet.size() == 1 && !allSubmissionStatusSet.contains('Closed-Voided'))
                                || (openSubmissionStatusSet.size() == 1 && openSubmissionStatusSet.contains('Opened'))) {
                            newQuestionnaireMap.get(questionnaire.Id).addError(
                                    System.Label.Medical_Evaluation_Submission_Closed_Voided);
                        } else if(openSubmissionStatusSet.size() > 1 && openSubmissionStatusSet.contains('Opened')) {
                            newQuestionnaireMap.get(questionnaire.Id).addError(
                                    System.label.Medical_Evaluation_Submission_Pending);
                        }
                    }
                }
            }

        }else{
            newQuestionnaireMap.values()[0].addError(
                    System.Label.SOQL_Limit_Message + ',' + System.Label.Contact_Admin_Message);
        }
    }

    /*
    * @Method       : beforeUpdateEventHandler
    * @Invoke       : Events from before Update Event Handler
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public static void beforeUpdateEventHandler(){
        TicketUtil.addTrace('QuestionnaireTriggerHandler.beforeUpdateEventHandler');
        Set<String> medEvalVoidIdSet = new Set<String>();
        systemMedEvalTaskFlag = false;
        List<CMPL123CME__Questionnaire__c> newQuestionaireList =  (List<CMPL123CME__Questionnaire__c>) Trigger.new;
        Map<Id,CMPL123CME__Questionnaire__c> newQuestionnaireMap = (Map<Id,CMPL123CME__Questionnaire__c>)Trigger.newMap;
        Set<String> questionaireSet=  new Set<String>();
        Map<Id,CMPL123CME__Questionnaire__c> oldQuestionnaireMap = (Map<Id,CMPL123CME__Questionnaire__c>)Trigger.oldMap;
        List<CMPL123CME__EU_MIR_Code_Choices__c> cdList= new List<CMPL123CME__EU_MIR_Code_Choices__c>();
        Id initialRecordTypeId 
            = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        //addCurrentTimeToDateFields();
        for(CMPL123CME__Questionnaire__c questionaire : newQuestionaireList){
            questionaire.RecordtypeId = initialRecordTypeId;
            if(questionaire.CMPL123_WF_Action__c == 'Reportable - Go to Regulatory' ){
                questionaireSet.add(questionaire.id);
            }
            //Clear Quality Notes on Closed - Done
            if(questionaire.CMPL123_WF_Status__c == 'Closed-Done' && questionaire.CMPL123_WF_Status__c != oldQuestionnaireMap.get(questionaire.Id).CMPL123_WF_Status__c){
                questionaire.Quality_Notes__c = '';
            }
            // AQC#287 Fix //Changed criteria #917 - 13MAY2019
            if(!systemMedEvalTaskFlag &&
                    !questionaire.Is_Auto_Medical_Evaluation_Task_Created__c &&
                    questionaire.Deficiency_to_an_adverse_event__c &&
                    questionaire.Adverse_Event__c &&
                    ((questionaire.Deficiency_to_an_adverse_event__c != oldQuestionnaireMap.get(questionaire.Id).Deficiency_to_an_adverse_event__c ) ||
                            (questionaire.Adverse_Event__c != oldQuestionnaireMap.get(questionaire.Id).Adverse_Event__c ))
                    ){
                setQuestionAdverseEventIds.add(questionaire.Id);
                questionaire.Is_Auto_Medical_Evaluation_Task_Created__c = true;
                systemMedEvalTaskFlag = true;
            }


            if(Trigger.isUpdate
                    && questionaire.CMPL123_WF_Status__c == 'Closed-Voided' && oldQuestionnaireMap != null
                    && questionaire.CMPL123_WF_Status__c != oldQuestionnaireMap.get(questionaire.Id).CMPL123_WF_Status__c){
                medEvalVoidIdSet.add(questionaire.id);
            }
        }

        if(medEvalVoidIdSet.size() > 0){
            //Display error if Med eval has any open med eval tasks
            for(CMPL123CME__Questionnaire__c objQuestionaire : [SELECT Id,(SELECT Id FROM Medical_Evaluation_Tasks__r WHERE CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided' LIMIT 1) FROM CMPL123CME__Questionnaire__c WHERE Id IN :medEvalVoidIdSet]){
                if(objQuestionaire.Medical_Evaluation_Tasks__r.size() > 0 && newQuestionnaireMap.containsKey(objQuestionaire.Id)){
                    newQuestionnaireMap.get(objQuestionaire.Id).addError(System.label.Cannot_perform_Void_action_on_a_Medical_Evaluation);
                }
            }
        }
        //Not required it is not given in FRS
        // W-000329 Changes
        // 07JAN19 - SOQL LIMIT FIX
        /*if(medEvalVoidIdSet.size() > 0) {
        updateOpenTasks(medEvalVoidIdSet);
        }*/
        if(questionaireSet!= null && questionaireSet.size()>0){
            List<CMPL123CME__Questionnaire_Items__c> QuestionaireItemList =  [SELECT Id, CMPL123CME__Question__c,CMPL123CME__Questionnaire__r.CMPL123_WF_Action__c,CMPL123CME__Answer__c,CMPL123CME__Questionnaire__c  FROM CMPL123CME__Questionnaire_Items__c WHERE CMPL123CME__Questionnaire__c =:questionaireSet];
            Map<Id, Boolean> QItemsNullAnswerMap = new Map<Id,Boolean>();

            if(QuestionaireItemList!= null && QuestionaireItemList.size()>0){
                for(CMPL123CME__Questionnaire_Items__c questionaireItem :QuestionaireItemList){
                    if(questionaireItem.CMPL123CME__Question__c != Null && questionaireItem.CMPL123CME__Answer__c == Null ){
                        QItemsNullAnswerMap.put(questionaireItem.CMPL123CME__Questionnaire__c,true);
                    }
                }
                if(QItemsNullAnswerMap != Null && QItemsNullAnswerMap.size()>0){
                    for(CMPL123CME__Questionnaire__c questionaire :(List<CMPL123CME__Questionnaire__c>) Trigger.new ){
                        if(QItemsNullAnswerMap.get(questionaire.Id) != null && QItemsNullAnswerMap.get(questionaire.Id)){
                            questionaire.addError(System.Label.Medical_Evaluation_All_question_answered);

                        }
                    }
                }
            }
        }
        setReopenRationale(newQuestionnaireMap, oldQuestionnaireMap);
    }

    /*
    * @Method       : afterEventHandler
    * @Invoke       : Events from after Event Handler
    * @Description  : To handle after Event Handler
    * @Return       : Set<Id> updatedTicketIds
    * @Params       : N/A
    */
    // Defect #123/CHARM-2729: changed void return result to Set<Id>
    public static Set<Id> afterEventHandler(){
        system.debug('inside afterEventHandler---->');
        Set<Id> lstMdEvlInitialDateChangeId = new  Set<Id>();
        Set<Id> lstMdEvlFollowUpDateChangeId = new  Set<Id>();

        TicketUtil.addTrace('QuestionnaireTriggerHandler.afterEventHandler');
        List<CMPL123CME__Questionnaire__c> newQuestionnaires = (List<CMPL123CME__Questionnaire__c>)Trigger.New;
        Map<Id,CMPL123CME__Questionnaire__c> oldQuestionnaireMap = (Map<Id,CMPL123CME__Questionnaire__c>)Trigger.oldMap;
        Map<Id,CMPL123CME__Questionnaire__c> newQuestionnaireMap = (Map<Id,CMPL123CME__Questionnaire__c>)Trigger.newMap;

        Set<String> complaintIds = new Set<String>();
        Set<Id> parentCompaintIds = new Set<Id>();  // Def #1587 fix
        Set<Id> updatedTicketIds = new Set<Id>();  // Defect #123/CHARM-2729: used to store updated ticket ids
        Map<Id,CMPL123CME__Complaint__c> updatableComplaintMap = new Map<Id,CMPL123CME__Complaint__c>();
        List<CMPL123CME__EU_MIR_Code_Choices__c> cdList= new List<CMPL123CME__EU_MIR_Code_Choices__c>();
        List<Id> euMirIdList = new List<Id>();
        for(CMPL123CME__Questionnaire__c questionnaire : newQuestionnaires){
            system.debug('questionnaire---->'+questionnaire);
            if(oldQuestionnaireMap != null && questionnaire.Initial_Awareness_Date__c  != oldQuestionnaireMap.get(questionnaire.Id).Initial_Awareness_Date__c){
                lstMdEvlInitialDateChangeId.add(questionnaire.Id);
            }
            if(oldQuestionnaireMap != null && questionnaire.Follow_Up_Awareness_Date__c  != oldQuestionnaireMap.get(questionnaire.Id).Follow_Up_Awareness_Date__c){
                lstMdEvlFollowUpDateChangeId.add(questionnaire.Id);
            }
            system.debug('questionnaire.CMPL123CME__Complaint__c---->'+questionnaire.CMPL123CME__Complaint__c);

            if(questionnaire.CMPL123CME__Complaint__c != null) {
                parentCompaintIds.add(questionnaire.CMPL123CME__Complaint__c);
            }
            /* used to auto-promote event to complete status when all child are closed. W-1208 */
            if(Trigger.isUpdate && questionnaire.CMPL123CME__Complaint__c != null
                    && (questionnaire.CMPL123_WF_Status__c == 'Closed-Done'
                    || questionnaire.CMPL123_WF_Status__c == 'Closed-Voided') && oldQuestionnaireMap != null
                    && questionnaire.CMPL123_WF_Status__c != oldQuestionnaireMap.get(questionnaire.Id).CMPL123_WF_Status__c){
                complaintIds.add(questionnaire.CMPL123CME__Complaint__c);
            }
        }

        if(lstMdEvlInitialDateChangeId.size() > 0 || lstMdEvlFollowUpDateChangeId.size() > 0){
            updateEmdrMdiDueDateFields(lstMdEvlInitialDateChangeId, lstMdEvlFollowUpDateChangeId);
        }

        // 07JAN19 - SOQL Limit Fix
        // Added if condition before the query this is for validating the Ticket Overall Reportable status
        // DEF 1625 fix, FRS-1450-07 implementation start
        if(parentCompaintIds.size() > 0) {
            Map<Id, CMPL123CME__Complaint__c> parentComplaints = new Map<Id, CMPL123CME__Complaint__c>();
            Map<Id, CMPL123CME__Complaint__c> complaintsToUpdate = new Map<Id, CMPL123CME__Complaint__c>();
            Map<Id, List<CMPL123CME__Questionnaire__c>> reportableMedEvalsByTicket = new Map<Id, List<CMPL123CME__Questionnaire__c>>();
            Map<Id, List<CMPL123CME__Questionnaire__c>> nonReportMedEvalsByTicket = new Map<Id, List<CMPL123CME__Questionnaire__c>>();
            Map<Id, List<CMPL123CME__Questionnaire__c>> tpmRespMedEvalsByTicket = new Map<Id, List<CMPL123CME__Questionnaire__c>>();
            Map<Id, Boolean> ticketAdverseEventTrue = new Map<Id, Boolean>();

            for (CMPL123CME__Complaint__c complaint : [SELECT Id, Overall_Reportable_Status__c, Was_an_Adverse_Event_Identified__c,
            (SELECT Id, Reportability__c, Adverse_Event__c FROM CMPL123CME__Questionnaires__r)
            FROM CMPL123CME__Complaint__c WHERE Id IN :parentCompaintIds]) {
                parentComplaints.put(complaint.Id, complaint);
                for (CMPL123CME__Questionnaire__c questionnaire : complaint.CMPL123CME__Questionnaires__r) {
                    if (questionnaire.Reportability__c == 'Reportable') {
                        fillInMedEvalsByTicketMap(complaint.Id, reportableMedEvalsByTicket, questionnaire);
                    } else if (questionnaire.Reportability__c == 'Non-Reportable') {
                        fillInMedEvalsByTicketMap(complaint.Id, nonReportMedEvalsByTicket, questionnaire);
                    } else if (questionnaire.Reportability__c == 'TPM Responsible') {
                        fillInMedEvalsByTicketMap(complaint.Id, tpmRespMedEvalsByTicket, questionnaire);
                    }
                    if (null != questionnaire.Adverse_Event__c && questionnaire.Adverse_Event__c) {
                        ticketAdverseEventTrue.put(complaint.Id, questionnaire.Adverse_Event__c);
                    }
                }
            }

            for (CMPL123CME__Complaint__c complaint : parentComplaints.values()) {
                system.debug('complaint---->'+complaint);
                List<CMPL123CME__Questionnaire__c> reportableMedEvals = reportableMedEvalsByTicket.get(complaint.Id);
                List<CMPL123CME__Questionnaire__c> nonReportableMedEvals = nonReportMedEvalsByTicket.get(complaint.Id);
                List<CMPL123CME__Questionnaire__c> tpmRespMedEvals = tpmRespMedEvalsByTicket.get(complaint.Id);

                if (null != reportableMedEvals  && reportableMedEvals.size() > 0
                        && complaint.Overall_Reportable_Status__c != 'Reportable') {
                    fillInComplaintToUpdate(complaintsToUpdate, 'Reportable', complaint);
                } else if (null == reportableMedEvals && null == tpmRespMedEvals && null != nonReportableMedEvals
                        && nonReportableMedEvals.size() > 0
                        && complaint.Overall_Reportable_Status__c != 'Not Reportable') {
                    fillInComplaintToUpdate(complaintsToUpdate, 'Not Reportable', complaint);
                } else if (null == reportableMedEvals && null == nonReportableMedEvals && null != tpmRespMedEvals
                        && tpmRespMedEvals.size() > 0 && complaint.Overall_Reportable_Status__c != 'TPM Responsible') {
                    fillInComplaintToUpdate(complaintsToUpdate, 'TPM Responsible', complaint);
                } else if (null == reportableMedEvals && null != nonReportableMedEvals && null != tpmRespMedEvals
                        && tpmRespMedEvals.size() > 0 && nonReportableMedEvals.size() > 0) {
                    fillInComplaintToUpdate(complaintsToUpdate, 'Not Reportable', complaint);
                }
                system.debug('ticketAdverseEventTrue.get(complaint.Id)---->'+ticketAdverseEventTrue.get(complaint.Id));
                system.debug('complaint.Was_an_Adverse_Event_Identified__c---->'+complaint.Was_an_Adverse_Event_Identified__c);

                if (null != ticketAdverseEventTrue.get(complaint.Id)
                        && ticketAdverseEventTrue.get(complaint.Id) && complaint.Was_an_Adverse_Event_Identified__c != 'Yes') {
                    if (null == complaintsToUpdate.get(complaint.Id)) {
                        complaint.Was_an_Adverse_Event_Identified__c = 'Yes';
                        complaintsToUpdate.put(complaint.Id, complaint);
                    } else {
                        CMPL123CME__Complaint__c complaintToUpdate = complaintsToUpdate.get(complaint.Id);
                        complaintToUpdate.Was_an_Adverse_Event_Identified__c = 'Yes';
                        complaintsToUpdate.put(complaint.Id, complaint);
                    }
                } else if (null == ticketAdverseEventTrue.get(complaint.Id)
                         && complaint.Was_an_Adverse_Event_Identified__c != 'No') {
                    if (null == complaintsToUpdate.get(complaint.Id)) {
                        complaint.Was_an_Adverse_Event_Identified__c = 'No';
                        system.debug('Was_an_Adverse_Event_Identified__c Updated spot 1>>> '+complaint.Was_an_Adverse_Event_Identified__c);
                        complaintsToUpdate.put(complaint.Id, complaint);
                    } else {
                        CMPL123CME__Complaint__c complaintToUpdate = complaintsToUpdate.get(complaint.Id);
                        complaintToUpdate.Was_an_Adverse_Event_Identified__c = 'No';
                        system.debug('Was_an_Adverse_Event_Identified__c Updated spot 2>>> '+complaint.Was_an_Adverse_Event_Identified__c);
                        complaintsToUpdate.put(complaint.Id, complaint);
                    }
                }
            }

            if(complaintsToUpdate.keyset().size() > 0){
                update complaintsToUpdate.values();
            }
            updatedTicketIds.addAll(complaintsToUpdate.keySet()); //Defect #123/CHARM-2729: add all ids of updated tickets
        }
        // DEF 1625 fix, FRS-1450-07 implementation end

        if(complaintIds.size() > 0){
            Set<Id> updTicketIds = CustomerResponseTriggerHandler.processEligibleComplaintsToComplete(complaintIds); // Defect #123/CHARM-2729: assign ids of processed tickets
            updatedTicketIds.addAll(updTicketIds);  // Defect #123/CHARM-2729: add all ids of updated tickets
        }
        //Added - W-000108 - 07/08/2018
        Set<Id> updatedTickets =  closeTicketBasedOnQuestionnaires(newQuestionnaires);  // Defect #123/CHARM-2729: assign ids of processed tickets
        updatedTicketIds.addAll(updatedTickets);  // Defect #123/CHARM-2729: add all ids of updated tickets
        //Added - W-000098 - 09/20/2018
        if(Trigger.isUpdate) {
            Set<Id> setQuestionnaireIds = new Set<Id>();
            for(CMPL123CME__Questionnaire__c objQuestionnaire : newQuestionnaires) {
                //Added - W-000098 for issue 160 - 02/08/2019
                if(objQuestionnaire.Reportability_Rationale__c != oldQuestionnaireMap.get(objQuestionnaire.Id).Reportability_Rationale__c
                        || objQuestionnaire.Reportability_Category__c  != oldQuestionnaireMap.get(objQuestionnaire.Id).Reportability_Category__c
                        || (objQuestionnaire.CMPL123_WF_Status__c != oldQuestionnaireMap.get(objQuestionnaire.Id).CMPL123_WF_Status__c
                        && objQuestionnaire.CMPL123_WF_Status__c == 'Regulatory')) {
                    setQuestionnaireIds.add(objQuestionnaire.Id);
                }
            }
            if(setQuestionnaireIds.size() > 0 && reportabilityHistoryRunOnce == false) {
                reportabilityHistoryRunOnce = true;
                QuestionnaireItemsTriggerHandler.createReportabilityHistoryRecord(setQuestionnaireIds, QuestionnaireItemsTriggerHandler.deleteTriggerFlag);
            }
        }

        // AQC#287 Fix
        if(systemMedEvalTaskFlag) {
            createMedEvalTaskRecord(setQuestionAdverseEventIds);
        }
        return updatedTicketIds;
    }

    /*
    * @Method       : closeTicketBasedOnQuestionnaires
    * @Description  : W-000108 - When all Questionnaires related to ticket closed, based on ticket "MDC All ACKs Received?"
    *                 And "CMSNext Status" field values close ticket.
    * @Return       : Set<Id> setTicketIds
    * @Params       : List<CMPL123CME__Questionnaire__c> lstTranslationTasksNew
    */
    // Defect #123/CHARM-2729: changed void return result to Set<Id>
    private static Set<Id> closeTicketBasedOnQuestionnaires(List<CMPL123CME__Questionnaire__c> lstQuestionnaireNew){
        TicketUtil.addTrace('QuestionnaireTriggerHandler.closeTicketBasedOnQuestionnaires');
        //Store Related Ticket Ids
        Set<Id> setTicketIds = New Set<Id>();

        for(CMPL123CME__Questionnaire__c objQuestionnaire : lstQuestionnaireNew){
            // 07JAN19 - SOQL Limit Fix
            // Added only Closed-Voided/Closed-Done questionnaires related complaints
            // TODO - Check filter Is It Correct??
            if(objQuestionnaire.CMPL123CME__Complaint__c != null &&
                    (objQuestionnaire.CMPL123_WF_Status__c == 'Closed-Voided' ||
                            objQuestionnaire.CMPL123_WF_Status__c == 'Closed-Done')) {
                setTicketIds.add(objQuestionnaire.CMPL123CME__Complaint__c);
            }
        }

        if(setTicketIds.size() > 0){
            // W-000108
            TicketUtil.closeTicketBasedOnConditions(setTicketIds);
            // 13MAR19 - Added for DEF#285
            TicketUpdateUtility.updateParentOnChildUpdate(setTicketIds);
        }
        return setTicketIds;
    }
    @TestVisible
    private static void updateOpenTasks(Set<String> medEvalVoidIdSet) {
        TicketUtil.addTrace('QuestionnaireTriggerHandler.updateOpenTasks');
        // Added for W-000329 - This is required to avoid the exception on updating child record when the parent is closed-voided
        if(medEvalVoidIdSet.size() > 0) {
            // Get the Workflow Steps
            Map<String, CMPL123__WF_Step__c> wfStepMap = new Map<String, CMPL123__WF_Step__c>();
            for(CMPL123__WF_Step__c wfStep : [SELECT Id, CMPL123__WF_Rule__r.CMPL123__Record_Type__c,
                    CMPL123__Action__r.Name, CMPL123__End_Status__r.Name, CMPL123__Start_Status__r.Name
            FROM CMPL123__WF_Step__c
            WHERE CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_TASK_WORKFLOW' AND
            CMPL123__Action__r.Name = 'Void']) {
                wfStepMap.put(wfStep.CMPL123__Start_Status__r.Name, wfStep);
            }

            // Read all the Open MedEval Tasks to Void
            List<Medical_Evaluation_Task__c> voidTasksList = new List<Medical_Evaluation_Task__c>();
            List<CMPL123__WF_History__c> wfHistoryRecords = new List<CMPL123__WF_History__c>();

            for(Medical_Evaluation_Task__c openTask: [SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action_Performed_On__c,
                    CMPL123_WF_Action_Performed_By__c, CMPL123_WF_Action__c
            FROM Medical_Evaluation_Task__c
            WHERE CMPL123_WF_Status__c != 'Closed-Done' AND
            CMPL123_WF_Status__c != 'Closed-Voided' AND
            Medical_Evaluation__c IN :medEvalVoidIdSet]) {
                CMPL123__WF_Step__c wfStep = wfStepMap.get(openTask.CMPL123_WF_Status__c);
                wfHistoryRecords.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(openTask.id, wfStep));

                openTask.CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name;
                openTask.CMPL123_WF_Action_Performed_On__c = DateTime.now();
                openTask.CMPL123_WF_Action_Performed_By__c = userinfo.getuserid();
                openTask.CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name;
                openTask.Voided_Rationale__c ='Parent voided';
                voidTasksList.add(openTask);
            }
            if(voidTasksList.size() > 0){
                update voidTasksList;
                insert wfHistoryRecords;
            }
        }
    }

    /*
    * @Method       : updateTicketFromMedEval
    * @Description  : Method to convert Process builders to Apex
    * @Return       : N/A
    * @Params       : N/A
    */
    public static void updateTicketFromMedEval(List<CMPL123CME__Questionnaire__c> lstQuestionnairesNew, Map<Id,CMPL123CME__Questionnaire__c> mapQuestionnairesOld){
        TicketUtil.addTrace('QuestionnaireTriggerHandler.updateTicketFromMedEval');
        //Holds complaints which needs to be updated
        Map<Id,CMPL123CME__Complaint__c> mapComplaintToBeUpdated = new Map<Id,CMPL123CME__Complaint__c>();
        //Holds complaints which are parent of Medevals
        Map<Id,CMPL123CME__Complaint__c> mapComplaints;
        //Holds compaint id's
        Set<Id> setComplaints = new Set<Id>();
        //Holds list of current med evals
        Map<Id,CMPL123CME__Questionnaire__c> lstQuestionnairesNewWithInfos = new Map<Id,CMPL123CME__Questionnaire__c>([SELECT Id,Evaluator__c,Evaluator__r.FirstName,Evaluator__r.LastName FROM CMPL123CME__Questionnaire__c WHERE Id IN :lstQuestionnairesNew]);
        //Collect all the complaint ids
        for(CMPL123CME__Questionnaire__c objQuestionnaire : lstQuestionnairesNew){
            if(String.isNotBlank(objQuestionnaire.CMPL123CME__Complaint__c)){
                setComplaints.add(objQuestionnaire.CMPL123CME__Complaint__c);
            }
        }

        if(!setComplaints.isEmpty()){
            mapComplaints = new Map<Id,CMPL123CME__Complaint__c>([SELECT Id,Was_an_Adverse_Event_Identified__c,First_Medical_Evaluator__c FROM CMPL123CME__Complaint__c WHERE Id IN :setComplaints]);
        }

        for(CMPL123CME__Questionnaire__c objQuestionnaire : lstQuestionnairesNew){
            if(String.isNotBlank(objQuestionnaire.CMPL123CME__Complaint__c)){
                //Boolean variable to check, Complaint needs to be updated or not
                Boolean updateComplaint = false;
                //Complaint instance
                CMPL123CME__Complaint__c objComplaint = new CMPL123CME__Complaint__c(Id = objQuestionnaire.CMPL123CME__Complaint__c);

                //Update Complaint if Adverse_Event__c is changed and is true
                if(Trigger.isUpdate &&
                        objQuestionnaire.Adverse_Event__c != mapQuestionnairesOld.get(objQuestionnaire.Id).Adverse_Event__c  &&
                        !mapComplaints.isEmpty() &&
                        mapComplaints.containsKey(objQuestionnaire.CMPL123CME__Complaint__c)) {
                    updateComplaint = true;
                }

                //Update complaint's Medical Eval Close Date to null
                if((Trigger.isInsert || objQuestionnaire.CMPL123_WF_Action__c != mapQuestionnairesOld.get(objQuestionnaire.Id).CMPL123_WF_Action__c) &&
                        (objQuestionnaire.CMPL123_WF_Action__c == 'Reopen' || objQuestionnaire.CMPL123_WF_Action__c == 'Reopen-Go to Evaluation')) {
                    updateComplaint = true;
                    objComplaint.Medical_Eval_Close_Date__c = null;
                }

                //Update Medical Eval Close Date on Ticket when Med Eval gets closed
                if((Trigger.isInsert || objQuestionnaire.CMPL123_WF_Status__c != mapQuestionnairesOld.get(objQuestionnaire.Id).CMPL123_WF_Status__c) &&
                        (objQuestionnaire.CMPL123_WF_Status__c == 'Closed-Voided' || objQuestionnaire.CMPL123_WF_Status__c == 'Closed-Done')) {
                    updateComplaint = true;
                    objComplaint.Medical_Eval_Close_Date__c = System.now();
                }

                //Update first medical evaluation evaluator in ticket - TBD
                if((Trigger.isInsert && String.isNotBlank(objQuestionnaire.Evaluator__c) || objQuestionnaire.Evaluator__c != mapQuestionnairesOld.get(objQuestionnaire.Id).Evaluator__c) && String.isNotBlank(objQuestionnaire.Evaluator__c)){
                    if(!mapComplaints.isEmpty() && mapComplaints.containsKey(objQuestionnaire.CMPL123CME__Complaint__c) && String.isBlank(mapComplaints.get(objQuestionnaire.CMPL123CME__Complaint__c).First_Medical_Evaluator__c)){
                        updateComplaint = true;
                        objComplaint.First_Medical_Evaluator__c = lstQuestionnairesNewWithInfos.get(objQuestionnaire.Id).Evaluator__r.FirstName + ' '+lstQuestionnairesNewWithInfos.get(objQuestionnaire.Id).Evaluator__r.LastName + '-' + objQuestionnaire.Id;
                    }

                    if(!mapComplaints.isEmpty() && mapComplaints.containsKey(objQuestionnaire.CMPL123CME__Complaint__c) && (mapComplaints.get(objQuestionnaire.CMPL123CME__Complaint__c).First_Medical_Evaluator__c).contains(objQuestionnaire.Id)){
                        updateComplaint = true;
                        objComplaint.First_Medical_Evaluator__c = lstQuestionnairesNewWithInfos.get(objQuestionnaire.Id).Evaluator__r.FirstName + ' '+lstQuestionnairesNewWithInfos.get(objQuestionnaire.Id).Evaluator__r.LastName + '-' + objQuestionnaire.Id;
                    }
                }

                //Validate updateComplaint boolean variable.
                if(updateComplaint){
                    mapComplaintToBeUpdated.put(objComplaint.Id, objComplaint);
                }
            }
        }

        if(!mapComplaintToBeUpdated.isEmpty()){
            Update mapComplaintToBeUpdated.values();
        }
    }

    /*
    * @Method       : updateKILOGFields
    * @Description  : Method to convert Process builders to Apex
    * @Return       : N/A
    * @Params       : N/A
    */
    public static void updateKILOGFields(List<CMPL123CME__Questionnaire__c> lstQuestionnaires,Map<Id,CMPL123CME__Questionnaire__c> mapQuestionnairesOld) {
        TicketUtil.addTrace('QuestionnaireTriggerHandler.updateKILOGFields');
        Set<Id> idKILogs = new Set<Id>();
        for(CMPL123CME__Questionnaire__c objQuestionnaire : lstQuestionnaires) {
            if((String.isNotBlank(objQuestionnaire.KI_Log__c)) && (mapQuestionnairesOld == null ||
                    (objQuestionnaire.KI_Log__c != mapQuestionnairesOld.get(objQuestionnaire.Id).KI_Log__c))) {
                idKILogs.add(objQuestionnaire.KI_Log__c);
            }
        }

        if(idKILogs.size() > 0) {
            Map<Id, KI_Log__c> mapKILogs = New Map<Id, KI_Log__c>([SELECT Id,Describe_Event_or_Problem__c,Final_Mfg_Analysis_New__c,H9_Correction_Removal_report_No__c,Initial_Follow_Up_Mfg_Analysis_New__c,
                    Reportability_Category__c,Reportability_Rationale__c,Reportability__c,Targeted_Assessment_Number_of_Days__c FROM KI_Log__c WHERE Id IN : idKILogs]);
            for(CMPL123CME__Questionnaire__c objQuestionnaire : lstQuestionnaires) {
                if((String.isNotBlank(objQuestionnaire.KI_Log__c)) && (mapQuestionnairesOld == null ||
                        (objQuestionnaire.KI_Log__c != mapQuestionnairesOld.get(objQuestionnaire.Id).KI_Log__c))) {
                    objQuestionnaire.Describe_Event_or_Problem__c = mapKILogs.get(objQuestionnaire.KI_Log__c).Describe_Event_or_Problem__c;
                    objQuestionnaire.Final_Mfg_Analysis_New__c = mapKILogs.get(objQuestionnaire.KI_Log__c).Final_Mfg_Analysis_New__c;
                    objQuestionnaire.H9_Correction_Removal_report_No__c = mapKILogs.get(objQuestionnaire.KI_Log__c).H9_Correction_Removal_report_No__c;
                    objQuestionnaire.Initial_Follow_Up_Mfg_Analysis_New__c = mapKILogs.get(objQuestionnaire.KI_Log__c).Initial_Follow_Up_Mfg_Analysis_New__c;
                    objQuestionnaire.KI_Log_Flag__c = true;
                    objQuestionnaire.Reportability_Category__c =  mapKILogs.get(objQuestionnaire.KI_Log__c).Reportability_Category__c;
                    objQuestionnaire.Reportability_Rationale__c = mapKILogs.get(objQuestionnaire.KI_Log__c).Reportability_Rationale__c;
                    objQuestionnaire.Reportability__c = mapKILogs.get(objQuestionnaire.KI_Log__c).Reportability__c;
                    objQuestionnaire.Targeted_Assessment_No_of_Days__c = mapKILogs.get(objQuestionnaire.KI_Log__c).Targeted_Assessment_Number_of_Days__c;

                }
            }
        }
    }

    /*
    * @Method       : updateEmdrMdiDueDateFields
    * @Description  : Method to Update Date Due fields in MDI and EMDR on parent MedEval Initial awareness date field change.
    * @Return       : N/A
    * @Params       : Set of medical evaluation record Id's
    */
    public static void updateEmdrMdiDueDateFields(Set<Id> lstMdEvlInitialDateChangeId, Set<Id> lstMdEvlFollowUpDateChangeId){
        List<CMPL123CME__EMDR__c> lstEmdrDueDateToBeUpdated = new List<CMPL123CME__EMDR__c>();
        List<CMPL123CME__MEDDEV__c> lstMdiDueDateToBeUpdated = new List<CMPL123CME__MEDDEV__c>();
        Integer emdrCalenderDays, mdiCalenderDays;
        if(lstMdEvlInitialDateChangeId.size() > 0 || lstMdEvlFollowUpDateChangeId.size() > 0){
            Set<Id> combinedMedEvalIds = new Set<Id>();
            combinedMedEvalIds.addAll(lstMdEvlInitialDateChangeId);
            combinedMedEvalIds.addAll(lstMdEvlFollowUpDateChangeId);
            for(CMPL123CME__EMDR__c emdr : [SELECT Id, RecordType.Name, CMPL123CME__MDR_Due_Date__c,Medical_Evaluation__c,
                    Medical_Evaluation__r.Initial_Awareness_Date__c, Submission_Type__r.Calendar_Days__c, Medical_Evaluation__r.Follow_Up_Awareness_Date__c FROM
                    CMPL123CME__EMDR__c WHERE Medical_Evaluation__c  IN :combinedMedEvalIds AND (CMPL123CME__CMPL123_WF_Status__c = 'Opened' OR CMPL123CME__CMPL123_WF_Status__c = 'MFR Report # Generated')]){
                emdrCalenderDays = emdr.Submission_Type__r.Calendar_Days__c != null ? Integer.valueOf(emdr.Submission_Type__r.Calendar_Days__c) : 0;
                if(emdr.RecordType.Name == 'Initial'){
                    if(emdr.CMPL123CME__MDR_Due_Date__c == null &&lstMdEvlInitialDateChangeId.contains(emdr.Medical_Evaluation__c) &&
                            emdr.Medical_Evaluation__r.Initial_Awareness_Date__c != null &&  emdrCalenderDays != null && (emdr.CMPL123CME__MDR_Due_Date__c != (emdr.Medical_Evaluation__r.Initial_Awareness_Date__c + emdrCalenderDays))){
                        emdr.CMPL123CME__MDR_Due_Date__c = emdr.Medical_Evaluation__r.Initial_Awareness_Date__c + emdrCalenderDays;
                        lstEmdrDueDateToBeUpdated.add(emdr);
                    }
                }else{
                    if(emdr.CMPL123CME__MDR_Due_Date__c == null && lstMdEvlFollowUpDateChangeId.contains(emdr.Medical_Evaluation__c)
                            && emdr.Medical_Evaluation__r.Follow_Up_Awareness_Date__c != null){
                        emdr.CMPL123CME__MDR_Due_Date__c = emdr.Medical_Evaluation__r.Follow_Up_Awareness_Date__c + 30;
                        lstEmdrDueDateToBeUpdated.add(emdr);
                    }
                }

            }
            for(CMPL123CME__MEDDEV__c medDev : [SELECT Id, Submission_Due_Date__c, Medical_Evaluation__r.Initial_Awareness_Date__c,
                    CMPL123CME__Type_of_Report__c, Medical_Evaluation__r.Follow_Up_Awareness_Date__c, Submission_Type__r.Calendar_Days__c  FROM
                    CMPL123CME__MEDDEV__c WHERE Medical_Evaluation__c IN :lstMdEvlInitialDateChangeId]){
                mdiCalenderDays = medDev.Submission_Type__r.Calendar_Days__c != null ? Integer.valueOf(medDev.Submission_Type__r.Calendar_Days__c) : 0;
                if(medDev.CMPL123CME__Type_of_Report__c == 'Initial report' || medDev.CMPL123CME__Type_of_Report__c == 'Combined initial and final report'){
                    if(medDev.Submission_Due_Date__c == null && lstMdEvlInitialDateChangeId.contains(medDev.Medical_Evaluation__c)
                            && medDev.Medical_Evaluation__r.Initial_Awareness_Date__c != null &&  mdiCalenderDays != null && (medDev.Submission_Due_Date__c != (medDev.Medical_Evaluation__r.Initial_Awareness_Date__c + mdiCalenderDays))){
                        medDev.Submission_Due_Date__c = medDev.Medical_Evaluation__r.Initial_Awareness_Date__c + mdiCalenderDays;
                        lstMdiDueDateToBeUpdated.add(medDev);
                    }
                }else{
                    if(medDev.Submission_Due_Date__c == null && lstMdEvlFollowUpDateChangeId.contains(medDev.Medical_Evaluation__c)
                            && medDev.Medical_Evaluation__r.Follow_Up_Awareness_Date__c != null){
                        medDev.Submission_Due_Date__c = medDev.Medical_Evaluation__r.Follow_Up_Awareness_Date__c + 30;
                        lstMdiDueDateToBeUpdated.add(medDev);
                    }
                }
            }
        }

        if(lstMdiDueDateToBeUpdated.size() > 0){
            update lstMdiDueDateToBeUpdated;
        }
        if(lstEmdrDueDateToBeUpdated.size() > 0){
            update lstEmdrDueDateToBeUpdated;
        }
    }

    /*
    * @Method       : Auto create Medical Evaluation Task with RCML Record Type
    * @Description  : W-000098 - Upon Adverse event 'Yes' and Did this confirmed malfunction (deficiency) cause/contribute to an adverse event?” field is set to “Yes”. the system will auto create a 'New' Medical Evaluation Task with RCML Record Type child record: .
    * @Return       : N/A
    * @Params       : Set<Id> setMedEvals
    */
    public static void createMedEvalTaskRecord(Set<Id> setMedEvals){
        TicketUtil.addTrace('QuestionnaireItemsTriggerHandler.createMedEvalTaskRecord');
        List<Medical_Evaluation_Task__c> lstMedEvalTask = New List<Medical_Evaluation_Task__c>();
        Boolean createMedEvalTask = false;
        String deficiencyQuestion = SYSTEM.Label.ADDS3_Deficiency_DT_Q1;
        for(CMPL123CME__Questionnaire__c objQuestionnaire : [SELECT Id,Is_Auto_Medical_Evaluation_Task_Created__c, (SELECT Id, CMPL123CME__Answer__c, CMPL123CME__Question__c FROM CMPL123CME__Questionnaire_Items__r WHERE CMPL123CME__Answer__c != NULL)
        FROM CMPL123CME__Questionnaire__c WHERE Id IN: setMedEvals ]) {
            for(CMPL123CME__Questionnaire_Items__c qItem : objQuestionnaire.CMPL123CME__Questionnaire_Items__r) {
                if(deficiencyQuestion.contains(qItem.CMPL123CME__Question__c) && qItem.CMPL123CME__Answer__c == 'Yes'){
                    createMedEvalTask = true;
                }
            }

            if(createMedEvalTask){
                Id recTypeId = Schema.SObjectType.Medical_Evaluation_Task__c.getRecordTypeInfosByName().get('RCML Review Task').getRecordTypeId();

                Medical_Evaluation_Task__c objMedEvalTask = new Medical_Evaluation_Task__c(
                        Medical_Evaluation__c = objQuestionnaire.Id,
                        RecordTypeId = recTypeId);
                lstMedEvalTask.add(objMedEvalTask);
            }
        }
        if(lstMedEvalTask.size() > 0){
            insert lstMedEvalTask;
        }
    }
    
    /*
    * @Method       : getComplaintByIdMap
    * @Description  : Helper method to get Complaint Ticket map based on associated Med Evals
    * @Invoke       : setDateOfIncidence
    * @Return       : Map <Id, CMPL123CME__Complaint__c>
    * @Params       : List<CMPL123CME__Questionnaire__c> newMedEvals
    */
    private static Map <Id, CMPL123CME__Complaint__c> getComplaintByIdMap(List<CMPL123CME__Questionnaire__c> newMedEvals) {
        Set <Id> complaintIds = new Set <Id>();

        for (CMPL123CME__Questionnaire__c medEval: newMedEvals) {
            complaintIds.add(medEval.CMPL123CME__Complaint__c);
        }

        Map <Id, CMPL123CME__Complaint__c> complaintById = new Map <Id, CMPL123CME__Complaint__c>([
            SELECT Date_of_Incidence__c, CMSNext_Ticket_Number__c, RecordType.DeveloperName, Service_Type__c, pRE_Status__c
            FROM CMPL123CME__Complaint__c
            WHERE Id in: complaintIds
        ]);
        
        return complaintById;

    }
    
    /*
    * @Method       : setDateOfIncidence
    * @Description  : IPDR #194, Used to set initial Date of Incidence field on creation from Complaints coming from CMSNext
    * @Invoke       : beforeInsertEventHandler
    * @Return       : N/A
    * @Params       : List<CMPL123CME__Questionnaire__c> newMedEvals
    */
    public static void setDateOfIncidence(List<CMPL123CME__Questionnaire__c> newMedEvals) {
         Map <Id, CMPL123CME__Complaint__c> complaintById = getComplaintByIdMap(newMedEvals);
        
         for (CMPL123CME__Questionnaire__c medEval: newMedEvals) {
            //WF: ADDS3 Update ticket based fields in medical evaluation.
            if (medEval.CMPL123CME__Complaint__c != null) {
                // HyperCare IPDR 194 
                if (medEval.Date_of_Incidence__c == null) {
                    if (complaintById.containsKey(medEval.CMPL123CME__Complaint__c)) {
                        medEval.Date_of_Incidence__c = Date.valueOf(complaintById.get(medEval.CMPL123CME__Complaint__c).Date_of_Incidence__c);
                    }
                }
            }
         }
    }

    /*
    * @Method       : setInitialAwarenessDate
    * @Description  : Defect #476, Used to set initial awareness date field on creation for manually created Med Evals
    * @Return       : N/A
    * @Params       : List<CMPL123CME__Questionnaire__c> newMedEvals
    */
    public static void setInitialAwarenessDate(List<CMPL123CME__Questionnaire__c> newMedEvals){
        Set<Id> ticketIdSet = new Set<Id>();
        for(CMPL123CME__Questionnaire__c medEval : newMedEvals){
            if(!medEval.System_Generated_Flag__c && medEval.Initial_Awareness_Date__c == null){
                ticketIdSet.add(medEval.CMPL123CME__Complaint__c);
            }
        }
        //query all tickets which match the criteria
        if(ticketIdSet.size() > 0){
            Map<Id, CMPL123CME__Complaint__c> queriedTicketMap = new Map<Id, CMPL123CME__Complaint__c>([
                    SELECT Id, Receipt_Date__c FROM CMPL123CME__Complaint__c WHERE Id IN:ticketIdSet
            ]);
            for(CMPL123CME__Questionnaire__c medEval : newMedEvals){
                if(!medEval.System_Generated_Flag__c && medEval.Initial_Awareness_Date__c == null
                        && queriedTicketMap.get(medEval.CMPL123CME__Complaint__c) != null
                        && queriedTicketMap.get(medEval.CMPL123CME__Complaint__c).Receipt_Date__c != null){
                    medEval.Initial_Awareness_Date__c = queriedTicketMap.get(medEval.CMPL123CME__Complaint__c).Receipt_Date__c.dateGMT();
                }
            }
        }
    }

    /*
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history
    * @Return       : N/A
    * @Params       : Map<Id,CMPL123CME__Questionnaire__c> newRecordMap,
    *                 Map<Id,CMPL123CME__Questionnaire__c> oldRecordMap
    */
    public static void setReopenRationale(Map<Id,CMPL123CME__Questionnaire__c> newRecordMap,
            Map<Id,CMPL123CME__Questionnaire__c> oldRecordMap){
        CMPL123CME__Questionnaire__c oldRecord;
        CMPL123CME__Questionnaire__c newRecord;
        if(newRecordMap.keyset().size() == 1 && oldRecordMap != null){
            for(CMPL123CME__Questionnaire__c sobj : newRecordMap.values()){
                newRecord = sobj;
                oldRecord = oldRecordMap.get(sobj.Id);
            }
            if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase('Reopen')
                    && newRecord.CMPL123_WF_Action__c != 'Reopen' && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                newRecord.Reopen_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
            }
        }
    }

    static void fillInMedEvalsByTicketMap (Id ticketId,
            Map<Id, List<CMPL123CME__Questionnaire__c>> medEvalsByTicketMap, CMPL123CME__Questionnaire__c medEval) {
        if (null == medEvalsByTicketMap.get(ticketId)) {
            medEvalsByTicketMap.put(ticketId, new List<CMPL123CME__Questionnaire__c>{medEval});
        } else {
            medEvalsByTicketMap.get(ticketId).add(medEval);
        }
    }

    static void fillInComplaintToUpdate (Map <Id, CMPL123CME__Complaint__c> complaintsToUpdate,
            String overallReportableString, CMPL123CME__Complaint__c complaint) {
        if (null == complaintsToUpdate.get(complaint.Id)) {
            complaint.Overall_Reportable_Status__c = overallReportableString;
            complaintsToUpdate.put(complaint.Id, complaint);
        } else {
            CMPL123CME__Complaint__c complaintToUpdate = complaintsToUpdate.get(complaint.Id);
            complaintToUpdate.Overall_Reportable_Status__c = overallReportableString;
            complaintsToUpdate.put(complaint.Id, complaint);
        }
    }

    /*
    * @Method       : updateTicketLastModifiedDate
    * @Invoke       : Events from Trigger after insert/update
    * @Description  : To update parent record "LastModifiedDate" field based on child records
    * @Return       : N/A
    * @Params       : Set<Id> updatedTicketIds
    */
    // Defect #123/CHARM-2729: added method to update parent tickets if they weren't updated in current transaction
    public static void updateTicketLastModifiedDate(Set<Id> updatedTicketIds){
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if(!UpdateParentUtility.isTicketUpdated || !ComplaintTriggerHandler.isTicketInserting){
            Set<Id> setComplaintIdToUpdate = new Set<Id>();
            for (CMPL123CME__Questionnaire__c objRecord : (List<CMPL123CME__Questionnaire__c>)Trigger.new) {
                Id ticketId = objRecord.CMPL123CME__Complaint__c;
                if (ticketId != null && !updatedTicketIds.contains(ticketId)) {
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

    /*
    * @Method       : wfLogic.
    * @Invoke       : From CMPL123CME_Questionnaire_AuditTrigger.
    * @Description  : To handle all the logic from disabled WF rules (TWD Upgrade issue).
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__Questionnaire__c> newMedEvals.
    */
    public static void wfLogic(){
        if (ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c) { return; }

        List<CMPL123CME__Questionnaire__c> newMedEvals = (List<CMPL123CME__Questionnaire__c>)Trigger.new;
        Map<Id, CMPL123CME__Questionnaire__c> oldMedEvalById = (Map<Id, CMPL123CME__Questionnaire__c>)Trigger.oldMap;

        Set <Id> actionPerformedByIds = new Set <Id>();
        Set <Id> complaintIds = new Set <Id>();

        for (CMPL123CME__Questionnaire__c medEval: newMedEvals) {
            actionPerformedByIds.add(medEval.CMPL123_WF_Action_Performed_By__c);
            complaintIds.add(medEval.CMPL123CME__Complaint__c);
        }

        Map <Id, CMPL123CME__Complaint__c> complaintById = new Map <Id, CMPL123CME__Complaint__c>([
            SELECT Date_of_Incidence__c, CMSNext_Ticket_Number__c, RecordType.DeveloperName, Service_Type__c, pRE_Status__c
            FROM CMPL123CME__Complaint__c
            WHERE Id in: complaintIds
        ]);

        Map <Id, User> userById = new Map <Id, User>([SELECT FirstName, LastName FROM User WHERE id IN: actionPerformedByIds]);

        for (CMPL123CME__Questionnaire__c medEval: newMedEvals) {
            //WF: ADDS3 update Assigned date based on evaluator in medical evaluation.
            if (medEval.Evaluator__c != null && (oldMedEvalById == null || (oldMedEvalById != null
                    && (oldMedEvalById.get(medEval.Id).Evaluator__c != medEval.Evaluator__c)))) {
                medEval.Assigned_Date__c = Date.today();
            }

            //WF: ADDS3 Update ticket based fields in medical evaluation.
            if (medEval.CMPL123CME__Complaint__c != null) {
                /* HyperCare IPDR 194 assign from Complaint only on creation moved to setDateOfIncidence method */

                String CMSNextTicketNumber = complaintById.get(medEval.CMPL123CME__Complaint__c).CMSNext_Ticket_Number__c;

                //WF: Autoset Registration Number
                if (CMSNextTicketNumber != null) {
                    String recordTypeName = complaintById.get(medEval.CMPL123CME__Complaint__c).RecordType.DeveloperName;

                    medEval.Registration_Number__c = CMSNextTicketNumber
                        + '('
                        + (recordTypeName == 'Service' ? complaintById.get(medEval.CMPL123CME__Complaint__c).Service_Type__c + ' ' : '')
                        + recordTypeName
                        + ')';
                }

                //WF: Initiate pRE decision tree
                if ((medEval.CMPL123CME__Key_value__c == '' || medEval.CMPL123CME__Key_value__c == null)
                        && complaintById.get(medEval.CMPL123CME__Complaint__c).pRE_Status__c == 'Yes'
                        && (oldMedEvalById == null || (oldMedEvalById  != null
                            && oldMedEvalById.get(medEval.Id).CMPL123CME__Key_value__c != medEval.CMPL123CME__Key_value__c))) {
                    medEval.CMPL123CME__Key_value__c = 'pRE';
                }
            }

            //WF: ADDS3_Initiate Deficiency Decision Tree
            if (medEval.CMPL123CME__Key_value__c != 'Deficiency' && medEval.Conclusion_Disposition_Flag__c == 'Deficiency'
                    && (oldMedEvalById == null || (oldMedEvalById != null
                        && oldMedEvalById.get(medEval.Id).Conclusion_Disposition_Flag__c != medEval.Conclusion_Disposition_Flag__c))) {
                medEval.CMPL123CME__Key_value__c = 'Deficiency';
            }

            //WF: ADDS3_Initiate_Field_Action
            if (medEval.Field_Action_Flag__c && medEval.CMPL123CME__Key_value__c != 'FieldAction'
                    && (oldMedEvalById == null || (oldMedEvalById  != null
                        && oldMedEvalById.get(medEval.Id).Field_Action_Flag__c != medEval.Field_Action_Flag__c ))) {
                medEval.CMPL123CME__Key_value__c = 'FieldAction';
            }

            //WF: Update Assessment Due date
            if (medEval.Initial_Awareness_Date__c != null && medEval.Targeted_Assessment_No_of_Days__c != null && (oldMedEvalById == null
                    || (oldMedEvalById != null && (oldMedEvalById.get(medEval.Id).Initial_Awareness_Date__c != medEval.Initial_Awareness_Date__c
                        || oldMedEvalById.get(medEval.Id).Targeted_Assessment_No_of_Days__c != medEval.Targeted_Assessment_No_of_Days__c )))) {
                medEval.Assessment_Due_date__c = medEval.Initial_Awareness_Date__c.addDays(Integer.valueOf(medEval.Targeted_Assessment_No_of_Days__c));
            }

            //WF: Update Reportability Date Field
            if (medEval.Reportability__c != null && (oldMedEvalById == null || (oldMedEvalById != null
                    && (oldMedEvalById.get(medEval.Id).Reportability__c != medEval.Reportability__c)))) {
                medEval.Reportability_Date__c = Datetime.now();
            }

            Boolean wfStatusIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && medEval.CMPL123_WF_Status__c != oldMedEvalById.get(medEval.Id).CMPL123_WF_Status__c);
            Boolean wfActionIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && medEval.CMPL123_WF_Action__c != oldMedEvalById.get(medEval.Id).CMPL123_WF_Action__c);

            String actionPerformedBy = userById.get(medEval.CMPL123_WF_Action_Performed_By__c)?.FirstName
                + ' '
                + userById.get(medEval.CMPL123_WF_Action_Performed_By__c)?.LastName;

            if (wfStatusIsChanged) {
                //WF: Clear action by and on fields
                if (medEval.CMPL123_WF_Status__c == 'In Process-Evaluation') {
                    medEval.Closed_By__c = null;
                    medEval.Closed_On__c = null;
                    medEval.Not_Reportable_On__c = null;
                    medEval.Not_Reportable_By__c = null;
                    medEval.Reportable_By__c = null;
                    medEval.Reportable_On__c = null;
                    medEval.TPM_Responsible_By__c = null;
                    medEval.TPM_Responsible_On__c = null;
                }
            }

            if (!wfActionIsChanged) {
                continue;
            }

            //WF: Workflow - Close
            if (medEval.CMPL123_WF_Action__c == 'Close' || medEval.CMPL123_WF_Action__c == 'Not Reportable - Close'
                    || medEval.CMPL123_WF_Action__c == 'TPM Responsible - Close' ) {
                medEval.Reopened_By__c = null;
                medEval.Reopened_On__c = null;
                medEval.Closed_By__c = actionPerformedBy;
                medEval.Closed_On__c = Datetime.now();
            }

            //WF: ADDS3 update assessment start,prompted date and reopen performed date and performed by in medical evaluation.
            //and WF: ADDS3 update workflow action performed date and performed by in medical evaluation.
            if (medEval.CMPL123_WF_Action__c == 'Reopen' || medEval.CMPL123_WF_Action__c == 'Reopen-Go to Evaluation') {
                medEval.Reopened_By__c = actionPerformedBy;
                medEval.Reopened_On__c = medEval.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: ADDS3 update assessment start,prompted date and reopen performed date and performed by in medical evaluation.
            //and WF: ADDS3 update workflow action performed date and performed by in medical evaluation.
            if (medEval.CMPL123_WF_Action__c == 'TPM Responsible - Close') {
                medEval.TPM_Responsible_By__c = actionPerformedBy;
                medEval.TPM_Responsible_On__c = medEval.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: ADDS3 update assessment start,prompted date and reopen performed date and performed by in medical evaluation.
            //and WF: ADDS3 update workflow action performed date and performed by in medical evaluation.
            if (medEval.CMPL123_WF_Action__c == 'Promote') {
                medEval.Submitted_Date__c = Date.valueOf(medEval.CMPL123_WF_Action_Performed_On__c);
                medEval.Assessment_Start_Date__c = Date.valueOf(medEval.CMPL123_WF_Action_Performed_On__c);
                //WF: Update Not Reportable By
                medEval.Promoted_By__c = actionPerformedBy;
                medEval.Promoted_On__c = medEval.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: ADDS3 update workflow action performed date and performed by in medical evaluation.
            if (medEval.CMPL123_WF_Action__c == 'Close') {
                medEval.Closed_By__c = actionPerformedBy;
                medEval.Closed_On__c = medEval.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: Update Not Reportable By
            if (medEval.CMPL123_WF_Action__c == 'Not Reportable - Close') {
                medEval.Not_Reportable_By__c= actionPerformedBy;
                medEval.Not_Reportable_On__c = medEval.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: Update Not Reportable By
            if (medEval.CMPL123_WF_Action__c == 'Reportable - Go to Regulatory') {
                medEval.Reportable_By__c = actionPerformedBy;
                medEval.Reportable_On__c = medEval.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: Update Not Reportable By
            if (medEval.CMPL123_WF_Action__c == 'Void') {
                medEval.Voided_By__c = actionPerformedBy;
                medEval.Voided_On__c = medEval.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: Workflow - Close
            if (medEval.CMPL123_WF_Action__c == 'Reopen') {
                medEval.Closed_By__c = null;
                medEval.Closed_On__c = null;
            }
        }
    }
}