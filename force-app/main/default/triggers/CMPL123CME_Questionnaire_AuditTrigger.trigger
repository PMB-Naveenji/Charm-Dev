/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : CMPL123CME_Questionnaire_AuditTrigger
* @Why   : To Handles all the customization involved on CMPL123CME__Questionnaire__c object.
* @When  : 13-FEB-2019  
* @Where : From     CMPL123CME__Questionnaire__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID             Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    13-FEB-2019            Work ID / Case ID           Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    22-May-2020            Defect #123/CHARM-2729      Added parent ticket LastModifiedDate updating upon insert
*                                                                               and update.
*   rsitc                    09-June-2020           Defect #123/CHARM-2729      Prevented custom logic execution if only Last Modified
*                                                                               is updated.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  oivan                    30-DEC-2020             TWD Upgrade issue           Added method to cover disabled WF logic.
* ---------------------------------------------------------------------------------------------------------------------------------------
*  rsitc                    11-JAN-2021             TWD Upgrade #92             Added logic to skip parent ticket LastModifiedDate update
*                                                                               if ComplaintTriggerHandler.isTicketUpdated set to true.
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
trigger CMPL123CME_Questionnaire_AuditTrigger on CMPL123CME__Questionnaire__c (before insert, before update,before delete,after insert,after update, after delete){
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        Set<Id> updatedTicketIds = new Set<Id>();   // Defect #123/CHARM-2729 
        if(Trigger.isInsert && Trigger.isBefore){
             // Place your code.
             QuestionnaireTriggerHandler.beforeInsertEventHandler();  
             //TWD Upgrade issue. added wfLogic() call
             QuestionnaireTriggerHandler.wfLogic();
        }
    
        /* After Insert */
    
        else if(Trigger.isInsert && Trigger.isAfter){
            system.debug('Medical Evaluation Inserted----->');
            CMPL123.AuditHandler.handleAudit();
            CMPL123CME.Questionnaire_TriggerHandler questionareTrigHandler = new CMPL123CME.Questionnaire_TriggerHandler ();
            questionareTrigHandler.createQuestionareItems();
            system.debug('ComplaintTriggerHandler.systemMedEval----->'+ComplaintTriggerHandler.systemMedEval);

            // Added to avoid Record Lock 22FEB19
            if(!ComplaintTriggerHandler.systemMedEval) {
                // Defect #123/CHARM-2729: added assignment of returned resuld to updatedTicketIds 
                updatedTicketIds = QuestionnaireTriggerHandler.afterEventHandler();
                system.debug('Medical Evaluation Insertion>>>>');
            }
            // Defect #123/CHARM-2729: update tickets LastModifiedDate except updatedTicketIds
            if (!ComplaintTriggerHandler.isTicketUpdated) {
                QuestionnaireTriggerHandler.updateTicketLastModifiedDate(updatedTicketIds);
            }
        }
    
        /* Before Update */
    
        else if(Trigger.isUpdate && Trigger.isBefore){
            Boolean isWeightOrScoreChanged = false;
            
            for(CMPL123CME__Questionnaire__c qst : Trigger.New){
                if(qst.CMPL123CME__Total_Weight__c != Trigger.oldMap.get(qst.Id).CMPL123CME__Total_Weight__c  || qst.CMPL123CME__Total_Score__c != Trigger.oldMap.get(qst.Id).CMPL123CME__Total_Score__c){
                    isWeightOrScoreChanged = true;
                    break;
                }
            }
            // #123/CHARM-2729: Prevent custom logic execution if only Last Modified is updated
            if(!isWeightOrScoreChanged && !UpdateParentUtility.isMedEvalLastModifDateUpdating){
                QuestionnaireTriggerHandler.beforEventHandler();
                QuestionnaireTriggerHandler.beforeUpdateEventHandler();    
            } 
            //TWD Upgrade issue. added wfLogic() call
            QuestionnaireTriggerHandler.wfLogic();
            CMPL123.AuditHandler.handleAudit();
        }
    
        /* After Update */
    
        else if(Trigger.isUpdate && Trigger.isAfter){
            Boolean isWeightOrScoreChanged = false;
            for(CMPL123CME__Questionnaire__c qst : Trigger.New){
                if(qst.CMPL123CME__Total_Weight__c != Trigger.oldMap.get(qst.Id).CMPL123CME__Total_Weight__c  || qst.CMPL123CME__Total_Score__c != Trigger.oldMap.get(qst.Id).CMPL123CME__Total_Score__c){
                    isWeightOrScoreChanged = true;
                    break;
                }
            }
            if(!isWeightOrScoreChanged){
                CMPL123.AuditHandler.handleAudit();
                
                // #123/CHARM-2729: Prevent custom logic execution if only Last Modified is updated
                if (!UpdateParentUtility.isMedEvalLastModifDateUpdating) {
                    CMPL123CME.Questionnaire_TriggerHandler questionareTrigHandler = new CMPL123CME.Questionnaire_TriggerHandler ();
                    questionareTrigHandler.createQuestionareItems();
    
                    // Added to avoid Record Lock 22FEB19
                    if(!ComplaintTriggerHandler.systemMedEval) {
                         system.debug('Medical Evaluation Updation>>>>'+Trigger.old);
                         system.debug('Medical Evaluation Updation>>>>'+Trigger.New);
                        updatedTicketIds = QuestionnaireTriggerHandler.afterEventHandler(); // Defect #123/CHARM-2729: assign updated ticket ids
                       
                    }
                } 
            }
            // Defect #123/CHARM-2729: update tickets LastModifiedDate except updatedTicketIds
            if (!ComplaintTriggerHandler.isTicketUpdated) {
                QuestionnaireTriggerHandler.updateTicketLastModifiedDate(updatedTicketIds);
            }
        }
    
        /* Before Delete */
    
        else if(Trigger.isDelete && Trigger.isBefore){
            CMPL123.AuditHandler.handleAudit();
        }
    
        /* After Delete */
    
        else if(Trigger.isDelete && Trigger.isAfter){
             // Place your code. 
        }
        if (Trigger.isAfter) {
            ReportsRelatedDataUtil.updateComplaintWithQuestionairesData(Trigger.old, Trigger.new);
        }
    }
}