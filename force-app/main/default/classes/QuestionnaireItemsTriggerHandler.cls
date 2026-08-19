/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : QuestionnaireItemsTriggerHandler.
* @Why   : Public class to manage all the custom coding invoked from QuestionnaireItemsTrigger.
* @When  : 01-JAN-2017.
* @Where : From QuestionnaireTriggerHandler, TicketUtil, QuestionnaireItemsTrigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    01-JAN-2017            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                    Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                    Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                    20-AUG-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    07-SEP-2020            Code Audit                    Removed empty If condition.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                    06-JAN-2021            TWD Upgrade Issue             Created fieldUpdatesFromWfRules method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class QuestionnaireItemsTriggerHandler {
    public static boolean updateMedEvalFlag = false;
    public static boolean deleteMedEvalFlag = false;
    public static boolean updateMedDevFlag = false;
    public static boolean deleteMedDevFlag = false;

    // 01FEB19 - IssueID#172, 175 - Fix to call decisionTreeEvaluation during delete
    public static boolean deleteTriggerFlag = false;

    /*
    * @Method       : isAfterInsert.
    * @Description  : To handle After Insert events.
    * @Invoke       : From QuestionnaireItemsTrigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    // After Insert Trigger Event Handling Common Method
    public static void isAfterInsert(){
        TicketUtil.addTrace('QuestionnaireItemsTriggerHandler.isAfterInsert');
    }

    /*
    * @Method       : isAfterUpdate.
    * @Description  : To handle After Update events.
    * @Invoke       : From QuestionnaireItemsTrigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    // After Update Trigger Event Handling Common Method
    public static void isAfterUpdate(){
        TicketUtil.addTrace('QuestionnaireItemsTriggerHandler.isAfterUpdate');
        // Def#172 Fix for SOQL and Optimization - START
        Map<Id, CMPL123CME__Questionnaire_Items__c> newQuestionnaireMap
            = (Map<Id, CMPL123CME__Questionnaire_Items__c>)Trigger.newMap;
        Map<Id, CMPL123CME__Questionnaire_Items__c> oldQuestionnaireMap
            = (Map<Id, CMPL123CME__Questionnaire_Items__c>)Trigger.oldMap;
        // Collect all the modified ids
        Set<Id> oldQIKeys = oldQuestionnaireMap.keySet();
        // Remove the updated ids
        oldQIKeys.removeAll(newQuestionnaireMap.keySet());
        // If any id left that means items were deleted, if deleted records exist, no need to call the validateData twice
        if(oldQIKeys.size() == 0) {
            validateData(Trigger.New);
        }
        // Def#172 Fix for SOQL and Optimization - END
    }

    /*
    * @Method       : isAfterDelete.
    * @Description  : To handle After Delete events.
    * @Invoke       : From QuestionnaireItemsTrigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    // After Delete Trigger Event Handling Common Method
    public static void isAfterDelete(){
        TicketUtil.addTrace('QuestionnaireItemsTriggerHandler.isAfterDelete');
        validateData(Trigger.Old);
    }

    /*
    * @Method       : validateData.
    * @Description  : To validate Questionnaire Items.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__Questionnaire_Items__c> qItems.
    */
    private static void validateData(List<CMPL123CME__Questionnaire_Items__c> qItems){
        TicketUtil.addTrace('QuestionnaireItemsTriggerHandler.validateData. Input data = ' + qItems);
        Set<Id> mdeEvalIdSet = new Set<Id>();

        for(CMPL123CME__Questionnaire_Items__c qItem: qItems){
            mdeEvalIdSet.add(qItem.CMPL123CME__Questionnaire__c);
        }

        if(mdeEvalIdSet.size() > 0){
            reRunDecisionTree(mdeEvalIdSet);
        }
    }

    /*
    * @Method       : reRunDecisionTree.
    * @Description  : Re Run Decision Tree.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Set<Id> medvalIds.
    */
    private static void reRunDecisionTree(Set<Id> medvalIds){
        TicketUtil.addTrace('QuestionnaireItemsTriggerHandler.reRunDecisionTree');
        List<CMPL123CME__Questionnaire__c> updatableMedEvals = new List<CMPL123CME__Questionnaire__c>();
        List<CMPL123CME__MEDDEV__c> updatableMedDevs = new List<CMPL123CME__MEDDEV__c>();
        Set<String> reportabilityYesSet = new Set<String>{SYSTEM.Label.ADDS3_pRE_DT_Q4,
            SYSTEM.Label.ADDS3_pRE_DT_Q5,
            SYSTEM.Label.ADDS3_Deficiency_DT_Q2,
            SYSTEM.Label.ADDS3_Field_Action_DT_Q1};
        Set<String> deathIndicators = new Set<String>();

        for(CMPL123CME__Questionnaire__c medEval :[SELECT Id,CMPL123_WF_Status__c, Reportability__c, Adverse_Event__c,
                                                   B1_Adverse_Event_Product_Problem_New__c,
                                                   B2_Outcomes_attributed_to_AE__c,
                                                   (SELECT Id, CMPL123CME__Question__c, CMPL123CME__Answer__c, CMPL123CME__Parent_Key_Value__c
                                                    FROM CMPL123CME__Questionnaire_Items__r ORDER BY CMPL123CME__Decision_Level__c ASC, CMPL123CME__Question_No__c ASC),
                                                   (SELECT Id, CMPL123CME__Classification_of_Incident__c
                                                    FROM MDI__r WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND
                                                    CMPL123_WF_Status__c != 'Closed-Done' AND
                                                    CMPL123_WF_Status__c != 'Closed - Waived' AND CMPL123_WF_Status__c != 'Closed - Voided')
                                                   FROM CMPL123CME__Questionnaire__c
                                                   WHERE Id IN :medvalIds AND (NOT CMPL123_WF_Status__c LIKE 'Closed%')]){
                                                       // Go thru the questions
                                                       Boolean B1_AE_Flag = false;
                                                       Boolean B1_PP_Flag = false;
                                                       Boolean B1_AEO_Flag = false;
                                                       Boolean Blank_RP_Flag = false;
                                                       medEval.Reportability__c = '';
                                                       Set<String> setOfTotalTree = new Set<String>();
                                                       Set<String> setOfIncompleteTree = new Set<String>();

                                                       Boolean is2aYes = false;
                                                       Boolean is3aYes = false;
                                                       Boolean isDTQ1 = false;

                                                       TicketUtil.addTrace('Questionnaire Items Size = ' + medEval.CMPL123CME__Questionnaire_Items__r.size());
                                                       // Check whether the tree is complete or not
                                                       for(CMPL123CME__Questionnaire_Items__c qItem : medEval.CMPL123CME__Questionnaire_Items__r) {
                                                           if(!String.isBlank(qItem.CMPL123CME__Parent_Key_Value__c)){
                                                               setOfTotalTree.add(qItem.CMPL123CME__Parent_Key_Value__c);
                                                           }

                                                           if(String.isBlank(qItem.CMPL123CME__Answer__c)) {
                                                               setOfIncompleteTree.add(qItem.CMPL123CME__Parent_Key_Value__c);
                                                           }
                                                       }

                                                       Map<String, String> treeReportabilityMap = new Map<String, String>();

                                                       for(CMPL123CME__Questionnaire_Items__c qItem : medEval.CMPL123CME__Questionnaire_Items__r) {
                                                           medEval.B2_Outcomes_attributed_to_AE__c =  medEval.B2_Outcomes_attributed_to_AE__c == 'Death' ? '' : medEval.B2_Outcomes_attributed_to_AE__c;

                                                           if(qItem.CMPL123CME__Question__c.equalsIgnoreCase(SYSTEM.Label.ADDS3_pRE_DT_Q1)) {
                                                               if(qItem.CMPL123CME__Answer__c == 'No') {
                                                                   medEval.Reportability__c = 'TPM Responsible';
                                                                   medEval.Adverse_Event__c = false;
                                                                   medEval.B1_Adverse_Event_Product_Problem_New__c = '';
                                                                   medEval.B2_Outcomes_attributed_to_AE__c = '';
                                                                   //break;
                                                               } else if(qItem.CMPL123CME__Answer__c == 'Yes') {
                                                                   medEval.Reportability__c = 'Non-Reportable';
                                                               }
                                                           } else if(qItem.CMPL123CME__Question__c.equalsIgnoreCase(SYSTEM.Label.ADDS3_pRE_DT_Q2)) {
                                                                if (qItem.CMPL123CME__Answer__c != 'Yes') {
                                                                   medEval.Adverse_Event__c = false;
                                                                }
                                                           } else if(qItem.CMPL123CME__Question__c.equalsIgnoreCase(SYSTEM.Label.ADDS3_Deficiency_DT_Q1 )) {
                                                               if(qItem.CMPL123CME__Answer__c == 'Yes') {
                                                                   isDTQ1 = true;
                                                               }
                                                           } else if(qItem.CMPL123CME__Question__c.equalsIgnoreCase(SYSTEM.Label.ADDS3_pRE_DT_Q2a)) {
                                                               if(qItem.CMPL123CME__Answer__c == 'Yes') {
                                                                   deathIndicators.add(medEval.Id);
                                                                   medEval.Reportability__c = 'Reportable';
                                                                   medEval.Adverse_Event__c = true;
                                                                   B1_AE_Flag = true;
                                                                   is2aYes = true;
                                                               } else {
                                                                   medEval.Adverse_Event__c = false;
                                                               }
                                                           } else if (qItem.CMPL123CME__Question__c.equalsIgnoreCase(SYSTEM.Label.ADDS3_pRE_DT_Q3a)) {
                                                               if(qItem.CMPL123CME__Answer__c == 'Yes') {
                                                                   medEval.Reportability__c = 'Reportable';
                                                                   medEval.Adverse_Event__c = true;
                                                                   B1_AEO_Flag = true;
                                                                   is3aYes = true;
                                                               }
                                                           } else if(reportabilityYesSet.contains(qItem.CMPL123CME__Question__c)) {
                                                               if(qItem.CMPL123CME__Answer__c == 'Yes') {
                                                                   medEval.Reportability__c = 'Reportable';
                                                                   B1_PP_Flag = true; // 22FEB19 - DEF#293 Fix
                                                                   if(qItem.CMPL123CME__Question__c.equalsIgnoreCase(SYSTEM.Label.ADDS3_pRE_DT_Q4) ||
                                                                      qItem.CMPL123CME__Question__c.equalsIgnoreCase(SYSTEM.Label.ADDS3_pRE_DT_Q5)) {
                                                                          medEval.Reportability__c = 'Reportable';
                                                                          B1_PP_Flag = true;
                                                                      }
                                                               }
                                                           }

                                                           if(!setOfIncompleteTree.contains(qItem.CMPL123CME__Parent_Key_Value__c)) {
                                                               if(medEval.Reportability__c == '') {
                                                                   medEval.Reportability__c = 'Non-Reportable';
                                                               }
                                                               treeReportabilityMap.put(qItem.CMPL123CME__Parent_Key_Value__c, medEval.Reportability__c);
                                                           }
                                                       }

                                                       if(isDTQ1 && !is2aYes && !is3aYes){
                                                           List<sObject> sObjects = Trigger.isDelete ? Trigger.old : Trigger.new;
                                                           for(sObject obj : sObjects){
                                                               obj.addError(System.Label.pRE_Decision_Tree_Message);
                                                               break;
                                                           }
                                                       }

                                                       // Decide the reportability based on the Tree Completeness and Order
                                                       Set<String> reportabilitySet = new Set<String>();
                                                       reportabilitySet.addAll(treeReportabilityMap.values());

                                                       if(reportabilitySet.contains('Reportable')) {
                                                           medEval.Reportability__c = 'Reportable';
                                                       } else if(reportabilitySet.contains('TPM Responsible')) {
                                                           medEval.Reportability__c = 'TPM Responsible';
                                                       } else if(reportabilitySet.contains('Non-Reportable')) {
                                                           medEval.Reportability__c = 'Non-Reportable';
                                                       } else {
                                                           medEval.Reportability__c = '';
                                                           Blank_RP_Flag = true;
                                                           medEval.B1_Adverse_Event_Product_Problem_New__c = '';
                                                       }

                                                       if(B1_AE_Flag) {
                                                           medEval.B1_Adverse_Event_Product_Problem_New__c = 'Adverse Event;Product Problem';
                                                           medEval.B2_Outcomes_attributed_to_AE__c = 'Death';
                                                       }else if(B1_AEO_Flag && !B1_AE_Flag ) {
                                                           medEval.B1_Adverse_Event_Product_Problem_New__c = 'Adverse Event;Product Problem';
                                                           medEval.B2_Outcomes_attributed_to_AE__c = medEval.B2_Outcomes_attributed_to_AE__c != 'Death' ? '' : medEval.B2_Outcomes_attributed_to_AE__c ;
                                                       } else if(B1_PP_Flag && !(B1_AE_Flag || B1_AEO_Flag)) {
                                                           medEval.B1_Adverse_Event_Product_Problem_New__c = 'Product Problem';
                                                            medEval.B2_Outcomes_attributed_to_AE__c = '';
                                                       } else {
                                                           medEval.B1_Adverse_Event_Product_Problem_New__c = '';
                                                       }

                                                        if((B1_AE_Flag || B1_AEO_Flag) && Blank_RP_Flag){
                                                           medEval.B1_Adverse_Event_Product_Problem_New__c = 'Adverse Event';
                                                           medEval.B2_Outcomes_attributed_to_AE__c = 'Death';
                                                       }

                                                       if(medEval.MDI__r.size() > 0 && deathIndicators.contains(medEval.Id)) {
                                                           for(CMPL123CME__MEDDEV__c medDev : medEval.MDI__r) {
                                                               updatableMedDevs.add(new CMPL123CME__MEDDEV__c(Id = medDev.Id,
                                                                                                              CMPL123CME__Classification_of_Incident__c = 'Death'));
                                                           }
                                                       }

                                                       updatableMedEvals.add(medEval);
                                                   }

        if(updatableMedDevs.size() > 0){
            // 01FEB19 - IssueID#172, 175 - Fix to call decisionTreeEvaluation during delete
            if(!QuestionnaireItemsTriggerHandler.updateMedDevFlag ||
               (QuestionnaireItemsTriggerHandler.deleteTriggerFlag && !QuestionnaireItemsTriggerHandler.deleteMedDevFlag)) {
                   update updatableMedDevs;
               }
        }

        if(updatableMedEvals.size() > 0) {
            // 01FEB19 - IssueID#172, 175 - Fix to call decisionTreeEvaluation during delete
            if(!QuestionnaireItemsTriggerHandler.updateMedEvalFlag ||
               (QuestionnaireItemsTriggerHandler.deleteTriggerFlag && !QuestionnaireItemsTriggerHandler.deleteMedEvalFlag)) {
                   update updatableMedEvals;
               }
        }
    }

    /*
    * @Method       : createReportabilityHistoryRecord.
    * @Description  : W-000098 - Upon Reportability Rationale 'change', the system will auto create a 'New' Reportability History child record.
    * @Invoke       : From QuestionnaireTriggerHandler.
    * @Return       : N/A.
    * @Params       : Set<Id> setMedEvals, Boolean isDelete.
    */
    public static void createReportabilityHistoryRecord(Set<Id> setMedEvals, Boolean isDelete){
        TicketUtil.addTrace('QuestionnaireItemsTriggerHandler.createReportabilityHistoryRecord');
        List<Reportability_History__c> lstReportabilityHistory = New List<Reportability_History__c>();

        for(CMPL123CME__Questionnaire__c objQuestionnaire : [SELECT Id, Reportability__c, Reportability_Rationale__c,Reportability_Category__c ,(SELECT Id, CMPL123CME__Answer__c, CMPL123CME__Question__c,
                                                                                                                                                 CMPL123CME__Questionnaire__c,CMPL123CME__Questions_Template_Item__r.CMPL123CME__Questions_Template__r.Name
                                                                                                                                                 FROM CMPL123CME__Questionnaire_Items__r WHERE CMPL123CME__Answer__c != NULL
                                                                                                                                                 ORDER BY Sort_Order__c ASC, CMPL123CME__Decision_Level__c ASC, CMPL123CME__Question_No__c ASC),
                                                             (SELECT Id FROM Reportability_Historys__r ORDER BY CreatedDate DESC LIMIT 1)
                                                             FROM CMPL123CME__Questionnaire__c WHERE Id IN: setMedEvals AND CMPL123_WF_Status__c != 'Opened' AND CMPL123_WF_Status__c != 'In Process-Evaluation']) {
                                                                 Reportability_History__c objHistoryRecord = isDelete && objQuestionnaire.Reportability_Historys__r.size() > 0 ?
                                                                     new Reportability_History__c (Id = objQuestionnaire.Reportability_Historys__r[0].Id) :
                                                                 new Reportability_History__c();

                                                                 objHistoryRecord.Reportability_Rationale__c = objQuestionnaire.Reportability_Rationale__c;
                                                                 //Added - W-000098 for issue 160 - 02/08/2019
                                                                 objHistoryRecord.Reportability_Category__c = objQuestionnaire.Reportability_Category__c;


                                                                 String strDecisionTree = '';
                                                                 for(CMPL123CME__Questionnaire_Items__c objQuestionnaireItem : objQuestionnaire.CMPL123CME__Questionnaire_Items__r){
                                                                     strDecisionTree += objQuestionnaireItem.CMPL123CME__Questions_Template_Item__r.CMPL123CME__Questions_Template__r.Name +' : '+ objQuestionnaireItem.CMPL123CME__Question__c+' - '+objQuestionnaireItem.CMPL123CME__Answer__c +'\n';
                                                                 }
                                                                 objHistoryRecord.Decision_Tree__c = strDecisionTree;
                                                                 objHistoryRecord.Reportability_Rationale_Change_Date__c  = Date.today();
                                                                 objHistoryRecord.Reportability_Rationale_Change_By__c = UserInfo.getName();
                                                                 objHistoryRecord.Reportability__c = objQuestionnaire.Reportability__c;
                                                                 objHistoryRecord.Medical_Evaluation__c = objQuestionnaire.Id;
                                                                 lstReportabilityHistory.add(objHistoryRecord);
                                                             }
        if(lstReportabilityHistory.size() > 0){
            upsert lstReportabilityHistory;
        }
    }

    /*
    * @Method       : fieldUpdatesFromWfRules.
    * @Description  : To execute WF Rules Field Updates logic.
    * @Invoke       : From QuestionnaireItemsTrigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void fieldUpdatesFromWfRules() {
        List<CMPL123CME__Questionnaire_Items__c> newQi = (List<CMPL123CME__Questionnaire_Items__c>)Trigger.New;

        Set<Id> medEvalIds = new Set<Id>();

        for(CMPL123CME__Questionnaire_Items__c qi : newQi) {
            if(qi.CMPL123CME__Questionnaire__c != null) {
                medEvalIds.add(qi.CMPL123CME__Questionnaire__c);
            }
        }

        Map<Id, CMPL123CME__Questionnaire__c> medEvals = new Map<Id, CMPL123CME__Questionnaire__c>([
            SELECT Id, CMPL123CME__Key_value__c FROM CMPL123CME__Questionnaire__c WHERE Id IN : medEvalIds
        ]);

        //Set Key Value on Creation	WF Rule
        for(CMPL123CME__Questionnaire_Items__c qi : newQi) {
            if(qi.CMPL123CME__Parent_Key_Value__c == null) {
                qi.CMPL123CME__Parent_Key_Value__c = medEvals.get(qi.CMPL123CME__Questionnaire__c).CMPL123CME__Key_value__c;
            }
        }
    }
}