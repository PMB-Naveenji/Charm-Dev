/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : ADDTTReviewTaskTriggerhandler.
* @Why   : Handles all the customization involved on Tracking Trending Review Task object.
* @When  : 06-APR-2017.
* @Where : From Tracking_Trending_Review_Task_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                06-APR-2017            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                29-DEC-2020            TWD Upgrade issue                 Related to WF Step issue, rules with field update
*                                                                                   moved to this handler.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                26-JAN-2021            TWD Upgrade issue                 Updated logic from WF Rules.
* --------------------------------------------------------------------------------------------------------------------------------------
* Anshika              23-AUG-2022            CHaRM R2.2                        BTSIT10071 Feature. Added functionality For Updating 
* Reopen Fields(Workflow History Fields) On Tracking_Trending_Review_Task__c
*--------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDTTReviewTaskTriggerhandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        //TWD Upgrade issue start. Logic moved from WF
        List<Tracking_Trending_Review_Task__c> tasks = (List<Tracking_Trending_Review_Task__c>) Trigger.New;
        clearAndSetFields(tasks, null);
        //TWD Upgrade issue end.
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
    * @Revision     : 23-AUG-2022 Anshika: Defined newTasksById. Now calls setReopenRationale().
    */
    public override void beforeUpdate() {
        //Defect #1600 fix BEGIN
        CustomRecordLockingUtil.validateRecordEdit(Trigger.NewMap,
                                                    Trigger.OldMap,
                                                    new List <String> {'Pending Approval'},
                                                    new List <String> {'T_T_Task_Approver', 'T_T_Task_Reviewer', 'Business_Admin', 'System_Administrator'},
                                                    new List <String> {'Approver__c', 'Reject_Rationale__c', 'Is_Assigned_As_Current_User__c', 'Is_Current_User_Approver__c'});
        //Defect #1600 fix END
        //TWD Upgrade issue start. Logic moved from WF
        List<Tracking_Trending_Review_Task__c> tasks = (List<Tracking_Trending_Review_Task__c>) Trigger.New;
        Map<Id, Tracking_Trending_Review_Task__c> oldTasksById = (Map<Id, Tracking_Trending_Review_Task__c> ) Trigger.OldMap;
        Map<Id, Tracking_Trending_Review_Task__c> newTasksById = (Map<Id, Tracking_Trending_Review_Task__c> ) Trigger.NewMap;
        clearAndSetFields(tasks, oldTasksById);
        setReopenRationale(newTasksById,oldTasksById);
        
        //TWD Upgrade issue end.
        //code which invokes 123Compliance platform audit and workflow code
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
    * @Method       : afterDelete
    * @Invoke       : Events from TriggerHandler after delete
    * @Description  : To handle all the logic in after delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterDelete() {
    }

    /*
    * @Method       : clearAndSetFields.
    * @Description  : To handle logic removed from WF: Autoset Approved Date, Update reject related fields, Workflow - Send Back to In Process,
    *                 Workflow - Submit, Workflow - Submit for Approval, Workflow - Void.
    * @Invoke       : From Tracking_Trending_Review_Task_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : List<Tracking_Trending_Review_Task__c> tasks, Map<Id, Tracking_Trending_Review_Task__c> oldTasksById
    */
    public static void clearAndSetFields(List<Tracking_Trending_Review_Task__c> tasks, Map<Id, Tracking_Trending_Review_Task__c> oldTasksById) {
        if (ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c) { return; }

        Set<Id> actionPerformedByIds = new Set<Id>();

        for (Tracking_Trending_Review_Task__c task: tasks) {
            actionPerformedByIds.add(task.CMPL123_WF_Action_Performed_By__c);
        }

        Map<Id, User> actionPerformedByById = new Map <Id, User>([SELECT Id, FirstName, LastName FROM User WHERE Id IN :actionPerformedByIds]);

        for (Tracking_Trending_Review_Task__c task :tasks) {
            Boolean wfStatusIsChanged = Trigger.isInsert || (Trigger.isUpdate && task.CMPL123_WF_Status__c != oldTasksById.get(task.Id).CMPL123_WF_Status__c);
            Boolean wfActionIsChanged = Trigger.isInsert || (Trigger.isUpdate && task.CMPL123_WF_Action__c != oldTasksById.get(task.Id).CMPL123_WF_Action__c);

            String actionPerformedBy = actionPerformedByById.get(task.CMPL123_WF_Action_Performed_By__c)?.FirstName
                + ' '
                + actionPerformedByById.get(task.CMPL123_WF_Action_Performed_By__c)?.LastName;

            if (wfStatusIsChanged) {
                //WF: Autoset Approved Date.
                if (task.CMPL123_WF_Status__c == 'Closed-Done') {
                    task.Reject_By__c = null;
                    task.Reject_On__c = null;
                    task.Reject_Rationale__c = null;
                    task.Approved_Date__c = Date.today();
                }
            }

            if (wfActionIsChanged) {
                //WF: Update reject related fields
                if (task.CMPL123_WF_Action__c  == 'Reject') {
                    task.Reject_By__c = actionPerformedBy;
                    task.Reject_On__c = date.valueOf(task.CMPL123_WF_Action_Performed_On__c);
                }

                //WF: Workflow - Send Back to In Process
                if (task.CMPL123_WF_Action__c == 'Send Back to In Process') {
                    task.Submitted_for_Approval_By__c = null;
                    task.Submitted_for_Approval_On__c = null;
                }

                //WF: Workflow - Submit
                if (task.CMPL123_WF_Action__c == 'Submit') {
                    task.Submitted_By__c = actionPerformedBy;
                    task.Submitted_On__c = task.CMPL123_WF_Action_Performed_On__c;
                }

                //WF: Workflow - Submit for Approval
                if (task.CMPL123_WF_Action__c == 'Submit For Approval') {
                    task.Submitted_for_Approval_By__c = actionPerformedBy;
                    task.Submitted_for_Approval_On__c = task.CMPL123_WF_Action_Performed_On__c;
                }

                //WF: Workflow - Void
                if (task.CMPL123_WF_Action__c == 'Void') {
                    task.Voided_By__c = actionPerformedBy;
                    task.Voided_On__c = task.CMPL123_WF_Action_Performed_On__c;
                }
                //23-AUG-2022 Anshika:For feature BTSIT10071,now supports Reopen action.
                if (task.CMPL123_WF_Action__c == AspenConstants.STR_Reopen) {
                    task.Reopened_On__c = task.CMPL123_WF_Action_Performed_On__c;
                    task.Reopened_By__c = actionPerformedBy;
                    task.Submitted_for_Approval_By__c = null;
                    task.Submitted_for_Approval_On__c = null;
                    task.Approved_Date__c = null;
                }
                if (task.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done && (oldTasksById == null || (oldTasksById != null 
                    && oldTasksById.get(task.Id).CMPL123_WF_Status__c != task.CMPL123_WF_Status__c)) ) {
                        task.Reopened_By__c = null;
                        task.Reopened_On__c = null;
                }
            }
        }
    }
    //For BTSIT10071 Feature.
    /*
    * @Method       : setReopenRationale.
    * @Description  : To Populate Reopen Rationale Field with the Comment field when moving from Closed-Done Status to In-Process Status upon 'Reopen' Action.
    * @Return       : N/A.
    * @Params       : Map<Id,Tracking_Trending_Review_Task__c> newRecordMap,Map<Id,Tracking_Trending_Review_Task__c> oldRecordMap
    * @Author       : 23-AUG-2022 Anshika
    */
    public static void setReopenRationale(
        Map<Id,Tracking_Trending_Review_Task__c> newRecordMap, 
        Map<Id,Tracking_Trending_Review_Task__c> oldRecordMap){
            Tracking_Trending_Review_Task__c oldRecord;
            Tracking_Trending_Review_Task__c newRecord;
            if(newRecordMap.size() == 1){
                for(Tracking_Trending_Review_Task__c sobj : newRecordMap.values()){
                    newRecord = sobj;
                    oldRecord = oldRecordMap.get(sobj.Id);
                }   
                if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase('Reopen') 
                    && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                       newRecord.Reopen_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
                   }
            }
        }
}