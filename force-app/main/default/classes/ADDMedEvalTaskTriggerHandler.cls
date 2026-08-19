/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDMedEvalTaskTriggerHandler
* @Why   : Handles all the customization involved on Medical Evaluation Task object.
* @When  : 06-APR-2017
* @Where : From UpdateProductReportableFields class, Medical_Evaluation_Task_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID                   Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*    Admin                 06-APR-2017              Work ID / Case ID                 Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*    DSkak                 04-06-2020               Code Audit                        Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*    rsitc                 09-June-2020             #123/CHARM-2729                   Added method updateMedEvalLastModifiedDate()
*  --------------------------------------------------------------------------------------------------------------------------------------
*    RSlob                 15-06-2020               Code Audit                        Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*    oivan                 05-JAN-2020              TWD Upgrade issue                 Added method wfLogic() and setRegNumber().
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDMedEvalTaskTriggerHandler extends TriggerHandler {
    
    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeInsert() {
        TicketUtil.addTrace('ADDMedEvalTaskTriggerHandler.beforeInsert');
        //TWD Upgrade issue start. 
        Set <Id> actionPerformedByIds = new Set <Id>();
        Set <Id> medEvalIds = new Set <Id>();
        //TWD Upgrade issue end. 
        List<Medical_Evaluation_Task__c> newMedEvalTaskList = (List<Medical_Evaluation_Task__c>)Trigger.New;
        for(Medical_Evaluation_Task__c newMedEvalTask : newMedEvalTaskList){
            if(newMedEvalTask.Requestor_Name__c == null){
                newMedEvalTask.Requestor_Name__c = userinfo.getUserId();
            }
            //TWD Upgrade issue start: Add ids to lists 
            actionPerformedByIds.add(newMedEvalTask.CMPL123_WF_Action_Performed_By__c);
            medEvalIds.add(newMedEvalTask.Medical_Evaluation__c);
            //TWD Upgrade issue end.
        }
        //TWD Upgrade issue: call wfLogic method 
        wfLogic(newMedEvalTaskList, actionPerformedByIds, medEvalIds, null);
    }
    
    /**
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterInsert() {
        TicketUtil.addTrace('ADDMedEvalTaskTriggerHandler.afterInsert');
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
        TicketUtil.addTrace('ADDMedEvalTaskTriggerHandler.beforeUpdate');
        //TWD Upgrade issue start. 
        Set <Id> actionPerformedByIds = new Set <Id>();
        Set <Id> medEvalIds = new Set <Id>();
        //TWD Upgrade issue end. 
        List<Medical_Evaluation_Task__c> newMedEvalTaskList = (List<Medical_Evaluation_Task__c>)Trigger.New;
        Map < Id, Medical_Evaluation_Task__c > newMedEvalTaskMap = (Map < Id, Medical_Evaluation_Task__c > ) Trigger.newMap;
        Map < Id, Medical_Evaluation_Task__c > oldMedEvalTaskMap = (Map < Id, Medical_Evaluation_Task__c > ) Trigger.oldMap;
        for(Medical_Evaluation_Task__c newMedEval : newMedEvalTaskList){
            if(newMedEval.CMPL123_WF_Action__c != null 
               && oldMedEvalTaskMap.get(newMedEval.Id).CMPL123_WF_Action__c != newMedEval.CMPL123_WF_Action__c
               && newMedEval.CMPL123_WF_Action__c == 'Complete'){
               
               newMedEval.Task_Item_Completed_By__c = newMedEval.CMPL123_WF_Action_Performed_By__c;
           }
            
            if(newMedEval.CMPL123_WF_Action__c == 'Void' && oldMedEvalTaskMap.get(newMedEval.Id).CMPL123_WF_Action__c != newMedEval.CMPL123_WF_Action__c){
                newMedEval.Voided_By__c = UserInfo.getName();
                newMedEval.Voided_On__c = System.now();
            }
            //TWD Upgrade issue start: Add ids to lists 
            actionPerformedByIds.add(newMedEval.CMPL123_WF_Action_Performed_By__c);
            medEvalIds.add(newMedEval.Medical_Evaluation__c);
            //TWD Upgrade issue end.
        }
        setReopenRationale(newMedEvalTaskMap, oldMedEvalTaskMap);
        //TWD Upgrade issue: call wfLogic method 
        wfLogic(newMedEvalTaskList, actionPerformedByIds, medEvalIds, oldMedEvalTaskMap);
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
        TicketUtil.addTrace('ADDMedEvalTaskTriggerHandler.afterUpdate');
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        
        List<Medical_Evaluation_Task__c> newMedTask = (List<Medical_Evaluation_Task__c>)Trigger.New;
        Map<Id, Medical_Evaluation_Task__c> oldMedTask = (Map<Id, Medical_Evaluation_Task__c>)Trigger.oldMap;
        List<Medical_Evaluation_Task__c> newMedTaskCompleted = new List<Medical_Evaluation_Task__c> ();
        
        Id medTaskRecTypeId = Schema.SObjectType.Medical_Evaluation_Task__c.getRecordTypeInfosByName().get('RCML Review Task').getRecordTypeId();
        for (Medical_Evaluation_Task__c medTask :newMedTask) {
           if(medTask.CMPL123_WF_Action__c == 'Complete' && medTask.RecordTypeId ==medTaskRecTypeId 
              && medTask.CMPL123_WF_Action__c != oldMedTask.get(medTask.Id).CMPL123_WF_Action__c) {
              newMedTaskCompleted.add(medTask);
           }
        } 
        if (newMedTaskCompleted != null && newMedTaskCompleted.size()>0) {
            UpdateProductReportableFields prodUpdate = new updateProductReportableFields();
            prodUpdate.updateFields(newMedTaskCompleted);
            prodUpdate.validationRuleCheck(newMedTaskCompleted);        
        }
    }

    /**
    * @Method       : beforeDelete
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : To handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeDelete() {
        TicketUtil.addTrace('ADDMedEvalTaskTriggerHandler.beforeDelete');
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
    * @Params       : Map<Id,Medical_Evaluation_Task__c> newRecordMap, 
    * 				  Map<Id,Medical_Evaluation_Task__c> oldRecordMap 
    **/ 
    public static void setReopenRationale(Map<Id,Medical_Evaluation_Task__c> newRecordMap, 
                                          Map<Id,Medical_Evaluation_Task__c> oldRecordMap){
        Medical_Evaluation_Task__c oldRecord;
        Medical_Evaluation_Task__c newRecord;
        if(newRecordMap.keyset().size() == 1){
            for(Medical_Evaluation_Task__c sobj : newRecordMap.values()){
                newRecord = sobj;
                oldRecord = oldRecordMap.get(sobj.Id);
            }   
        	if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase('Reopen') 
                && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                newRecord.Reopen_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
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
    // Defect #123/CHARM-2729: added method to update parent med evals 
    public static void updateMedEvalLastModifiedDate(){
        // Defect #123/CHARM-2729: prevent multiple updates of the med eval in the same transaction
        if(!UpdateParentUtility.isMedEvalUpdated){
            Set<Id> setMedEvalsToUpdate = new Set<Id>();
            for (Medical_Evaluation_Task__c objRecord : (List<Medical_Evaluation_Task__c>)Trigger.new) {
                Id medEvalId = objRecord.Medical_Evaluation__c;
                if (medEvalId != null) {
                    setMedEvalsToUpdate.add(medEvalId);              
                }
            }
            if(setMedEvalsToUpdate.size() > 0){
                UpdateParentUtility.isMedEvalUpdated = true;
                UpdateParentUtility.isMedEvalLastModifDateUpdating = true;
                UpdateParentUtility.updateparent_trend(setMedEvalsToUpdate);
                UpdateParentUtility.isMedEvalLastModifDateUpdating = false;
            }
        }       
    }
    
    /*
    * @Method       : wfLogic.
    * @Description  : TWD Upgrade issue. Added logic from WF rules.
    * @Invoke       : From ADDMedEvalTaskTriggerHandler class.
    * @Return       : N/A.
    * @Params       : List<Medical_Evaluation_Task__c> tasks, Set<Id> userIds, Set<Id> medEvalIds, Map <Id, Medical_Evaluation_Task__c> oldTasksById.
    */
    
    public static void wfLogic(List<Medical_Evaluation_Task__c> tasks, Set<Id> userIds, Set<Id> medEvalIds, Map <Id, Medical_Evaluation_Task__c> oldTasksById) {
        Map<Id, User> userById = new Map <Id, User>(
                        [SELECT LastName, FirstName
                        FROM User
                        WHERE Id in: userIds]);
        for (Medical_Evaluation_Task__c task: tasks) {
            if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c){
                //WF: Autoset Assigned Date field
                if (task.CMPL123_WF_Status__c == 'In Process' && (oldTasksById == null || (oldTasksById != null 
                    && oldTasksById.get(task.Id).CMPL123_WF_Status__c != task.CMPL123_WF_Status__c)) ) {
                        task.Assigned_Date__c = date.valueOf(task.CMPL123_WF_Action_Performed_On__c);
                }
                //WF: Autoset Task Item Completion Date 
                if (task.CMPL123_WF_Status__c == 'Closed-Done' && (oldTasksById == null || (oldTasksById != null 
                    && oldTasksById.get(task.Id).CMPL123_WF_Status__c != task.CMPL123_WF_Status__c)) ) {
                        task.Reopened_By__c = null;
                        task.Reopened_On__c = null;
                        task.Task_Item_Completion_Date__c = datetime.now();
                }
                //WF: Workflow - Reopen 
                if (task.CMPL123_WF_Action__c == 'Reopen' && (oldTasksById == null || (oldTasksById != null 
                    && oldTasksById.get(task.Id).CMPL123_WF_Action__c != task.CMPL123_WF_Action__c)) ) {
                        task.Task_Item_Completed_By__c = null;
                        task.Submitted_By__c = null;
                        task.Submitted_On__c = null;
                        task.Reopened_By__c = userById.get(task.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                              userById.get(task.CMPL123_WF_Action_Performed_By__c)?.LastName;
                        task.Reopened_On__c = task.CMPL123_WF_Action_Performed_On__c;
                        task.Task_Item_Completion_Date__c = null;
                }
                //WF: Workflow - Submit 
                if (task.CMPL123_WF_Action__c == 'Submit' && (oldTasksById == null || (oldTasksById != null 
                    && oldTasksById.get(task.Id).CMPL123_WF_Action__c != task.CMPL123_WF_Action__c)) ) {
                        task.Request_More_Information__c = null;
                        task.Submitted_By__c = userById.get(task.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                              userById.get(task.CMPL123_WF_Action_Performed_By__c)?.LastName;
                        task.Submitted_On__c = task.CMPL123_WF_Action_Performed_On__c;
                }
            }
            
        }
        //WF: Autoset Registration Number   
        setRegNumber(tasks, medEvalIds);
    }
    
    /*
    * @Method       : setRegNumber.
    * @Description  : TWD Upgrade issue. Added logic from WF rule: Autoset Registration Number.
    * @Invoke       : From ADDMedEvalTaskTriggerHandler class.
    * @Return       : N/A.
    * @Params       : List<Medical_Evaluation_Task__c> tasks, Set<Id> medEvalIds.
    */
    public static void setRegNumber(List<Medical_Evaluation_Task__c> tasks, Set<Id> medEvalIds) {
        Map<Id, CMPL123CME__Questionnaire__c> medEvalById = new Map <Id, CMPL123CME__Questionnaire__c>(
                        [SELECT CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c, CMPL123CME__Complaint__r.RecordType.DeveloperName,
                        CMPL123CME__Complaint__r.Service_Type__c
                        FROM CMPL123CME__Questionnaire__c
                        WHERE Id in: medEvalIds]);
        for (Medical_Evaluation_Task__c task: tasks) {
            if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c 
                && medEvalById.get(task.Medical_Evaluation__c)?.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c != null) {
                    if (medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.RecordType.DeveloperName == 'Complaint') {
                        task.Registration_Number__c = medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c +
                                                 '(' + medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.RecordType.DeveloperName + ')';
                    } else if (medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.RecordType.DeveloperName == 'Inquiry') {
                        task.Registration_Number__c = medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c +
                                                 '(' + medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.RecordType.DeveloperName + ')';
                    } else if (medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.RecordType.DeveloperName == 'Service') {
                        task.Registration_Number__c = medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c +
                                                 '(' + medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.Service_Type__c + ' ' + 
                                                  medEvalById.get(task.Medical_Evaluation__c).CMPL123CME__Complaint__r.RecordType.DeveloperName + ')';
                    }
            }
        }
    }
}