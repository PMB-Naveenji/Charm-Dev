/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : QuestionnaireItemsTrigger
* @Why   : To Handles all the customization involved on CMPL123CME__Questionnaire_Items__c object.
* @When  : 08-FEB-2019	
* @Where : From CMPL123CME__Questionnaire_Items__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			   08-FEB-2019			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oober    			   06-JAN-2021			    TWD Upgrade Issue    Added before insert event, addded fieldUpdatesFromWfRules method call.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger QuestionnaireItemsTrigger on CMPL123CME__Questionnaire_Items__c (before insert, after insert, after update, after delete) {

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        // 28FEB19 - DEF#120 - Removed the Batch processing
        if(ComplaintTriggerHandler.systemMedEval) { return; }

        //Move WF Rules to Apex
        if(Trigger.isBefore) {
            if(Trigger.isInsert) {
                QuestionnaireItemsTriggerHandler.fieldUpdatesFromWfRules();
            }
        }

        TicketUtil.addTrace('QuestionnaireItemsTrigger');
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                QuestionnaireItemsTriggerHandler.isAfterInsert();
            }
            if(Trigger.isUpdate){
                QuestionnaireItemsTriggerHandler.isAfterUpdate();
                QuestionnaireItemsTriggerHandler.updateMedEvalFlag = true;
                QuestionnaireItemsTriggerHandler.updateMedDevFlag = true;
            }
            if(Trigger.isDelete){
                // 01FEB19 - IssueID#172, 175 - Fix to call decisionTreeEvaluation during delete
                QuestionnaireItemsTriggerHandler.deleteTriggerFlag = true;
                QuestionnaireItemsTriggerHandler.isAfterDelete();
                QuestionnaireItemsTriggerHandler.deleteMedEvalFlag = true;
                QuestionnaireItemsTriggerHandler.deleteMedDevFlag = true;
            }
        }

        //TicketUtil.sendLimits('QuestionnaireItemsTrigger');
    }
}