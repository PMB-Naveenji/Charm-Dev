/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDActionTaskTriggerhandler
* @Why   : Handles all the customization involved on Action Task object.
* @When  : 06-APR-2017
* @Where : From Action_Task_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*     Admin                 06-APR-2017             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*     oivan                 05-JAN-2020             TWD Upgrade issue    Added method wfLogic().
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDActionTaskTriggerhandler extends TriggerHandler {
/**
* @Method       : beforeInsert
* @Invoke       : Events from TriggerHandler before insert
* @Description  : To handle all the logic in before insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeInsert() {
        //TWD Upgrade issue start. 
        Set <Id> actionPerformedByIds = new Set <Id>();
        List<Action_Task__c> newItems = (List<Action_Task__c>)Trigger.New;
        for(Action_Task__c item : newItems){
            actionPerformedByIds.add(item.CMPL123_WF_Action_Performed_By__c);
        }
        wfLogic(newItems, actionPerformedByIds, null);
        //TWD Upgrade issue end. 
    }

/**
* @Method       : afterInsert
* @Invoke       : Events from TriggerHandler after insert
* @Description  : To handle all the logic in after insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }
/**
* @Method       : beforeUpdate
* @Invoke       : Events from TriggerHandler before update
* @Description  : To handle all the logic in before update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeUpdate() {
        //TWD Upgrade issue start. 
        Set <Id> actionPerformedByIds = new Set <Id>();
        //TWD Upgrade issue end. 
        Map<Id,Action_Task__c> mapActionTasks = (Map<Id,Action_Task__c>)Trigger.newMap;
        Map<Id,Action_Task__c> oldActionTasks = (Map<Id,Action_Task__c>)Trigger.oldMap;
        
        for(Action_Task__c actionTask : mapActionTasks.values()){
        
            
            //Clear Reopening_Rationale__c on Close Action  STR_Closed_Done
            //if(actionTask.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Complete && actionTask.CMPL123_WF_Action__c != oldActionTasks.get(actionTask.Id).CMPL123_WF_Action__c){
              //actionTask.Reopening_Rationale__c = '';
            //}
            
            
           if(actionTask.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done && 
               actionTask.CMPL123_WF_Status__c != oldActionTasks.get(actionTask.Id).CMPL123_WF_Status__c){
               
               actionTask.Quality_Notes__c = '';
            }
            //TWD Upgrade issue: add userIds to the list. 
            actionPerformedByIds.add(actionTask.CMPL123_WF_Action_Performed_By__c);
        }
        setReopenRationale(mapActionTasks, oldActionTasks);
        //TWD Upgrade issue start. Call wfLogic
        wfLogic(mapActionTasks.values(), actionPerformedByIds, oldActionTasks );
        //TWD Upgrade issue end. 
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }
/**
* @Method       : afterUpdate
* @Invoke       : Events from TriggerHandler after update
* @Description  : To handle all the logic in after update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }
/**
* @Method       : beforeDelete
* @Invoke       : Events from TriggerHandler before delete
* @Description  : To handle all the logic in before delete event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }   
/**
* @Method       : afterDelete
* @Invoke       : Events from TriggerHandler after delete
* @Description  : To handle all the logic in after delete event
* @Return       : N/A
* @Params       : N/A
**/  
    public override void afterDelete() {
    }  
    
    /**
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history 
    * @Return       : N/A
    * @Params       : Map<Id,Action_Task__c> newRecordMap, 
    *                 Map<Id,Action_Task__c> oldRecordMap 
    **/ 
    public static void setReopenRationale(Map<Id,Action_Task__c> newRecordMap, 
                                          Map<Id,Action_Task__c> oldRecordMap){
        Action_Task__c oldRecord;
        Action_Task__c newRecord;
        if(newRecordMap.keyset().size() == 1){
            for(Action_Task__c sobj : newRecordMap.values()){
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
    * @Method       : wfLogic.
    * @Description  : TWD Upgrade issue. Added logic from WF rules.
    * @Invoke       : From ADDTrendItemHandler class.
    * @Return       : N/A.
    * @Params       : List<Action_Task__c> items, Set<Id> userIds, Map <Id, Action_Task__c> oldItemById.
    */
    
    public static void wfLogic(List<Action_Task__c> items, Set<Id> userIds, Map <Id, Action_Task__c> oldItemById) {
        Map<Id, User> userById = new Map <Id, User>(
                        [SELECT LastName, FirstName
                        FROM User
                        WHERE Id in: userIds]);
        for (Action_Task__c item: items) {
            if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c){
                //WF: Regulatory Evaluation Due Date    
                //Sets the Date Due to 10 days after Date Created on Regulatory Evaluation, 21CR806 records
                if (item.Action_Type__c == 'Regulatory Evaluation, 21CR806' && (oldItemById == null || (oldItemById != null 
                    && oldItemById.get(item.Id).Action_Type__c != item.Action_Type__c))) {
                        item.Date_Due_Date__c = date.today().addDays(10);
                }
                //WF: Workflow - Complete
                if (item.CMPL123_WF_Action__c == 'Complete' && (oldItemById == null || (oldItemById != null 
                    && oldItemById.get(item.Id).CMPL123_WF_Action__c != item.CMPL123_WF_Action__c)) ) {
                        item.Completed_By__c = userById.get(item.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                              userById.get(item.CMPL123_WF_Action_Performed_By__c)?.LastName;
                        item.Completed_Date__c = item.CMPL123_WF_Action_Performed_On__c;
                }
                //WF: Workflow - Reopen 
                if (item.CMPL123_WF_Action__c == 'Reopen' && (oldItemById == null || (oldItemById != null 
                    && oldItemById.get(item.Id).CMPL123_WF_Action__c != item.CMPL123_WF_Action__c)) ) {
                        item.Reopen_Date__c = date.valueOf(item.CMPL123_WF_Action_Performed_On__c);
                }
                //WF: Workflow - Submit 
                if (item.CMPL123_WF_Action__c == 'Promote' && (oldItemById == null || (oldItemById != null 
                    && oldItemById.get(item.Id).CMPL123_WF_Action__c != item.CMPL123_WF_Action__c)) ) {
                        item.Assignee_Date__c = date.valueOf(item.CMPL123_WF_Action_Performed_On__c);
                }
            }
        }
    }
}