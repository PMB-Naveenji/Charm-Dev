/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDRegulatoryAssessmentTriggerHandler.
* @Why   : Handles all the customization involved on Regulatory Assessment object.
* @When  : 06-APR-2017.
* @Where : From Regulatory_Assessment_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                06-APR-2017            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                28-DEC-2020            TWD Upgrade issue                 Added 'executeLogicFromWFRules()' method to move logic from
*                                                                                   Workflow Rules with Field Updates on Regulatory Assessment to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDRegulatoryAssessmentTriggerHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END
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
        Map<Id,Regulatory_Assessment__c> mapRegulatoryAssessments = (Map<Id,Regulatory_Assessment__c>)Trigger.newMap;
        Map<Id,Regulatory_Assessment__c> oldRegulatoryAssessments = (Map<Id,Regulatory_Assessment__c>)Trigger.oldMap;

        for(Regulatory_Assessment__c regassessment : mapRegulatoryAssessments.values()){
           if(regassessment.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done &&
               regassessment.CMPL123_WF_Status__c != oldRegulatoryAssessments.get(regassessment.Id).CMPL123_WF_Status__c){

               regassessment.Quality_Notes__c = '';
               //regassessment.Reopening_Rationale__c = '';
            }

           if(regassessment.CMPL123_WF_Action__c == 'Reopen'){
                regassessment.Reopened_By__c = UserInfo.getName();
                regassessment.Reopen_Date__c  = System.now();
            }
            if(regassessment.CMPL123_WF_Action__c == 'Void'){
                regassessment.Voided_By__c  = UserInfo.getName();
                regassessment.Voided_On__c  = System.now();
            }
        }
        setReopenRationale(mapRegulatoryAssessments, oldRegulatoryAssessments);

        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END

        CMPL123.AuditHandler.handleAudit();

        //Defect #1600 fix BEGIN
        List <PermissionSetAssignment> currentUserPermissionSetAssignments = [
                SELECT Id, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
        ];
        Set <String> permSets = new Set <String>();
        for (PermissionSetAssignment permSet: currentUserPermissionSetAssignments) {
            permSets.add(permSet.PermissionSet.Name);
        }
        if (permSets.contains('Risk_Assessment_Regulatory_Assessor')) {
            CustomRecordLockingUtil.validateRecordEdit(Trigger.NewMap,
                    Trigger.OldMap,
                    new List <String>{'Pending Approval'},
                    new List <String>{'Risk_Assessment_Regulatory_Assessor'},
                    new List <String>{'Approver__c', 'Reopened_By__c', 'Reopen_Date__c', 'Assigned_Assignee__c', 'Completed_Date__c', 'Completed_By__c', 'Completed_Date_GMT__c'});
        }
        if (permSets.contains('Risk_Assessment_Risk_Evaluation_Approver_ADD')) {
            CustomRecordLockingUtil.validateRecordEdit(Trigger.NewMap,
                    Trigger.OldMap,
                    new List <String>{'Pending Approval'},
                    new List <String>{'Risk_Assessment_Risk_Evaluation_Approver_ADD'},
                    new List <String>{'Reject_Rationale__c', 'Reopened_By__c', 'Reopen_Date__c', 'Assigned_Assignee__c', 'Completed_Date__c', 'Completed_By__c', 'Completed_Date_GMT__c'});
        }
        //Defect #1600 fix END
    }

    /*
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
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
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history
    * @Return       : N/A
    * @Params       : Map<Id,Regulatory_Assessment__c> newRecordMap, Map<Id,Regulatory_Assessment__c> oldRecordMap.
    */
    public static void setReopenRationale(Map<Id,Regulatory_Assessment__c> newRecordMap,
                                          Map<Id,Regulatory_Assessment__c> oldRecordMap){
        Regulatory_Assessment__c oldRecord;
        Regulatory_Assessment__c newRecord;
        if(newRecordMap.keyset().size() == 1){
            for(Regulatory_Assessment__c sobj : newRecordMap.values()){
                newRecord = sobj;
                oldRecord = oldRecordMap.get(sobj.Id);
            }
        	if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase('Reopen')
                && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                newRecord.Reopening_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
            }
        }
    }

    /*
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates
    *                   on Regulatory Assessment.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<Regulatory_Assessment__c> newList = (List<Regulatory_Assessment__c>) Trigger.new;
        Map<Id, Regulatory_Assessment__c> oldMap = (Map<Id, Regulatory_Assessment__c>) Trigger.oldMap;

        for (Regulatory_Assessment__c newRA :newList) {
            Boolean wfActionIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && newRA.CMPL123_WF_Action__c != oldMap.get(newRA.Id).CMPL123_WF_Action__c);

            //  Update rule key value when AMD Regulatory Assessment is created
            //  Update rule key value when ADD Regulatory Assessment is created
            if (null == newRA.CMPL123Rule_Key_Value__c) {
                newRA.CMPL123Rule_Key_Value__c = newRA.Division__c == 'ADD' ? 'REGULATORY_ASSESSMENT_WORKFLOW' : 'AMD_REGULATORY_ASSESSMENT_WORKFLOW';
            }

            if (!wfActionIsChanged) {
                continue;
            }

            DateTime actionPerformedOn = DateTime.now();
            String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

            //  Autoset By and Date Fields
            newRA.Completed_By__c = null;
            newRA.Completed_Date__c = null;

            //  Clear Approve field
            if (newRA.CMPL123_WF_Action__c == AspenConstants.STR_Reopen) {
                newRA.Approved_By__c = null;
                newRA.Approved_On__c = null;
                newRA.Submitted_By__c = null;
                newRA.Submitted_On__c = null;
            }

            //  Autoset By and Date Fields
            if (newRA.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Approve) {
                newRA.Approved_By__c = actionPerformedBy;
                newRA.Approved_On__c = actionPerformedOn;
            }

            //  Autoset By and Date Fields
            if (newRA.CMPL123_WF_Action__c == AspenConstants.STR_Complete_Regulatory_Impact) {
                newRA.Submitted_By__c = actionPerformedBy;
                newRA.Submitted_On__c = actionPerformedOn;
            }

            //  Autoset By and Date Fields
            if (newRA.CMPL123_WF_Action__c == AspenConstants.STR_Complete_No_Regulatory_Impact) {
                newRA.Completed_By__c = actionPerformedBy;
                newRA.Completed_Date__c = actionPerformedOn;
            }

            //  Autoset By and Date Fields
            if (newRA.CMPL123_WF_Action__c == AspenConstants.STR_Promote) {
                newRA.Assigned_Date__c = actionPerformedOn;
            }

            //  Autoset By and Date Fields
            if (newRA.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Complete
                    || newRA.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Approve
                    || newRA.CMPL123_WF_Action__c == AspenConstants.STR_Complete_Regulatory_Impact) {
                newRA.Reject_Rationale__c = '';
            }
        }
    }
}