/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
 * @What  : ADDInvestigationTaskTriggerHandler.
 * @Why   : Handles all the customization involved on Investigation Task object.
 * @When  : 06-APR-2017.
 * @Where : From Task_AuditTrigger Trigger.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID               Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    06-APR-2017            Work ID / Case ID             Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    09-JUN-2020            #123/CHARM-2729               Added updateInvestigationLastModifiedDate method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                    29-DEC-2020            TWD Upgrade issue             Related to WF Step issue. Added setFieldValues
 *                                                                                   and setRegNumber methods.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    26-JAN-2021            TWD Upgrade issue             Updated logic from WF Rules.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Yadram                   07-FEB-2022            CHaRM R2.1                    Defect 325: Related to Lot Search Functionality.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             07-FEB-2023            CHaRM R3.0                    Commented out code for the Salesforce Workflow called
 * "Skip Pre Approval if Is Protocol Pre-Approval is yes" because no business process can activate it. This was discovered when looking for
 * potential problem areas called out by the config guide for the TWD upgrade. Also replaced magic words with constants and set class to "with sharing".
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

public with sharing class ADDInvestigationTaskTriggerHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        InvestigationTaskTriggerHandler.beforeEventHandler();

        //TWD Upgrade issue start. Move WF rules into code.
        Map <String, Schema.RecordTypeInfo> recordTypeByName = Schema.SObjectType.Task__c.getRecordTypeInfosByName();
        List <Task__c> newInvTasks = (List <Task__c>)Trigger.New;
        Set <Id> productTicketIds = new Set <Id> ();
        Set <Id> ticketIds = new Set <Id> ();
        Set <Id> tpmIds = new Set <Id> ();
        Set <Id> actionPerformedByIds = new Set <Id> ();
        Set <Id> relatedInvestigationEvaluationIds = new Set <Id>();

        for(Task__c objInvTask : newInvTasks){
            if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c){
                //WF: Auto set Assigned Date
                if(objInvTask.CMPL123_WF_Status__c == AspenConstants.STR_In_Process) {
                    objInvTask.Assigned_Date__c = objInvTask.CMPL123_WF_Action_Performed_On__c;
                }

                //WF: Update Task Instructions based on record type
                if (objInvTask.RecordTypeId == recordTypeByName.get('Customer Return Analysis').getRecordTypeId()
                    || objInvTask.RecordTypeId == recordTypeByName.get('Retained Product & Customer Return Analysis').getRecordTypeId()
                    || objInvTask.RecordTypeId == recordTypeByName.get('Retained Product Analysis').getRecordTypeId()) {
                         objInvTask.CMPL123Rule_Key_Value__c = 'Task_Analysis';
                } else if (objInvTask.RecordTypeId == recordTypeByName.get('Ticket History Review By Product List Number').getRecordTypeId()
                    || objInvTask.RecordTypeId == recordTypeByName.get('Ticket History Review By Lot Number').getRecordTypeId()) {
                         objInvTask.CMPL123Rule_Key_Value__c = 'Tickets_Task';
                } else {
                    objInvTask.CMPL123Rule_Key_Value__c = 'Prod_Eval_Task';
                }
            }

            productTicketIds.add(objInvTask.Product_Ticket__c);
            tpmIds.add(objInvTask.TPM__c);
            actionPerformedByIds.add(objInvTask.CMPL123_WF_Action_Performed_By__c);
            relatedInvestigationEvaluationIds.add(objInvTask.Related_Investigation_Evaluation__c);
            ticketIds.add(objInvTask.Parent_Ticket__c);
        }

        //WF: Autoset Product Registration Number & Legal Manufacturer
        setFieldValues(newInvTasks, null, productTicketIds, tpmIds, actionPerformedByIds, ticketIds, relatedInvestigationEvaluationIds);

        //WF: Autoset Registration Number. Only for Insert event
        setRegNumber(newInvTasks, relatedInvestigationEvaluationIds);
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
        InvestigationTaskTriggerHandler.createTaskJunction();
    }

    /*
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeUpdate() {
        //TWD Upgrade issue start. Move WF rules into code.
        Set <Id> productTicketIds = new Set <Id> ();
        Set <Id> tpmIds = new Set <Id> ();
        Set <Id> ticketIds = new Set <Id> ();
        Set<Id> relatedInvestigationEvaluationIds = new Set <Id>();
        Set <Id> actionPerformedByIds = new Set <Id> ();
        //TWD Upgrade issue end.
        //code which invokes 123Compliance platform audit and workflow code
        List< Task__c > newInvTasks = (List< Task__c >)Trigger.New;
        Map< Id, Task__c > newInvTaskMap = (Map<Id, Task__c >)Trigger.newMap;
        Map< Id, Task__c > oldInvTaskMap = (Map<Id, Task__c >)Trigger.oldMap;
        for(Task__c objInvTask : newInvTasks){
            if(objInvTask.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done || objInvTask.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided){
                objInvTask.Task_Item_Completion_Date__c = system.now();
                objInvTask.Task_Item_Completed_By__c = UserInfo.getFirstName()+' '+ UserInfo.getLastName();
            }
            if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c){
                //WF: Auto set Assigned Date
                if (objInvTask.CMPL123_WF_Status__c == AspenConstants.STR_In_Process && objInvTask.CMPL123_WF_Status__c != oldInvTaskMap.get(objInvTask.Id).CMPL123_WF_Status__c) {
                    objInvTask.Assigned_Date__c = objInvTask.CMPL123_WF_Action_Performed_On__c;
                }
                //WF: Autoset Product Registration Number & Legal Manufacturer
                productTicketIds.add(objInvTask.Product_Ticket__c);
                //WF: Autoset TPM fields
                tpmIds.add(objInvTask.TPM__c);
                actionPerformedByIds.add(objInvTask.CMPL123_WF_Action_Performed_By__c);
                ticketIds.add(objInvTask.Parent_Ticket__c);
                relatedInvestigationEvaluationIds.add(objInvTask.Related_Investigation_Evaluation__c);
            }
        }

        setReopenRationale(newInvTaskMap, oldInvTaskMap);

        User user = [Select Id, Profile.Name from User where Id =: UserInfo.getUserId()];

        if (user.Profile.Name != 'System Administrator') {
            CustomRecordLockingUtil.validateRecordEdit(
                newInvTaskMap,
                oldInvTaskMap,
                new List<String>{ 'Pre Approval In Progress' },
                new List<String>{
                    'Evaluation_Investigation_Task_Assignee',
                    'Evaluation_Investigation_Task_Approver',
                    'Complaint_Evaluator_Investigator'
                },
                new List<String>{
                    'Approver__c',
                    'Rejection_Rationale__c',
                    'Task_Item_Submit_for_Pre_Approval_By__c',
                    'Approver_Assigned__c'
                }
            );
        }

        //TWD Upgrade issue. Call setFieldValues()
        setFieldValues(newInvTasks, oldInvTaskMap, productTicketIds, tpmIds, actionPerformedByIds, ticketIds, relatedInvestigationEvaluationIds);

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
        InvestigationTaskTriggerHandler.afterEventHandler();


        if(TicketUpdateUtility.executeFlag){
            TicketUpdateUtility.executeFlag = false;
            Set<Id> parentIds = new Set<Id>();
            List< Task__c > newInvTasks = (List< Task__c >)Trigger.New;
            for(Task__c objInvTask : newInvTasks){
                if(objInvTask.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done || objInvTask.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided){
                    parentIds.add(objInvTask.Parent_Ticket__c);
                }
            }
            if(parentIds != null && parentIds.size() > 0){
                // Call the utility method to update the parent
                TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
            }

        }
    }

    /*
    * @Method       : beforeDelete
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : To handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeDelete() {
        InvestigationTaskTriggerHandler.beforeDeleteEventHandler();
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
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history
    * @Return       : N/A
    * @Params       : Map<Id,Task__c> newRecordMap, Map<Id,Task__c> oldRecordMap.
    */
    public static void setReopenRationale(Map<Id,Task__c> newRecordMap, Map<Id,Task__c> oldRecordMap) {
        Task__c oldRecord;
        Task__c newRecord;

        if(newRecordMap.keyset().size() == 1){
            for(Task__c sobj : newRecordMap.values()){
                newRecord = sobj;
                oldRecord = oldRecordMap.get(sobj.Id);
            }
            if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase(AspenConstants.STR_Reopen)
                && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                newRecord.Reopen_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
            }
        }
    }

    /*
    * @Method       : updateInvestigationLastModifiedDate
    * @Invoke       : Events from Trigger after insert/update
    * @Description  : To update parent record "LastModifiedDate" field based on child records
    * @Return       : N/A
    * @Params       : N/A
    */
    // Defect #123/CHARM-2729: added method to update parent Investigations if they weren't updated in current transaction
    public static void updateInvestigationLastModifiedDate() {
        Set<Id> investigationRecordIdSet = new Set<Id>();
        if (!UpdateParentUtility.isInvestigationUpdated) {
            UpdateParentUtility.isInvestigationUpdated = true;
                for (Task__c taskCode : (List<Task__c>)Trigger.new){
                    if (taskCode.Related_Investigation_Evaluation__c != null) {
                        investigationRecordIdSet.add(taskCode.Related_Investigation_Evaluation__c);
                    }
                }
                if (investigationRecordIdSet.size() > 0) {
                    UpdateParentUtility.isInvestigationLastModifDateUpdating = true;
                    UpdateParentUtility.updateparent_trend(investigationRecordIdSet);
                    UpdateParentUtility.isInvestigationLastModifDateUpdating = false;
                }
        }
    }

    /*
    * @Method       : setFieldValues.
    * @Description  : TWD Upgrade issue. Added logic from WF rule: Autoset Product Registration Number & Legal Manufacturer, Autoset TPM fields,
    *                 Clear Reject fields, Skip Pre Approval if Is Protocol Pre-Approval is yes, Update Task performed by and time for custom fields,
    *                 Update Time Frame, Update threshold URL, Workflow - Complete, Workflow - Reopen, Workflow - Request More Information
    * @Invoke       : From Task_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : List<Task__c> tasks, Map<Id, Task__c> oldTaskById, Set<Id> productTicketsIds, Set <Id> tpmIds, Set<Id> actionPerformedByIds, Set <Id> ticketIds, Set<Id> relatedInvestigationEvaluationIds.
    */
    public static void setFieldValues (List<Task__c> tasks, Map<Id, Task__c> oldTaskById, Set<Id> productTicketsIds, Set <Id> tpmIds, Set<Id> actionPerformedByIds, Set <Id> ticketIds, Set<Id> relatedInvestigationEvaluationIds) {
        if (ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c) { return; }

        Id chinaRecordTypeId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('China GSP Regulation').getRecordTypeId();
        //07-FEB-2022 Yadram : Fetch Record type Id to fix the Defect no 325.
        Id ticketHistoryReviewListNumberRecordTypeId = 
            Schema.SObjectType.Task__c.getRecordTypeInfosByName().get(
                AspenConstants.STR_Ticket_History_Review_By_Prod_Lst_Number).getRecordTypeId();


        Map<Id, Product_Ticket__c> productTicketsById = new Map <Id, Product_Ticket__c>([
            SELECT Product__r.Product_Registration_Number__c, Product__r.Legal_Manufacturer__c
            FROM Product_Ticket__c
            WHERE Id IN: productTicketsIds
        ]);

        Map<Id, TPM__c> tpmById = new Map <Id, TPM__c>([
            SELECT TPM_Contact_Email__c, TPM_Contact_Name__c
            FROM TPM__c
            WHERE Id IN: tpmIds
        ]);

        Map<Id, User> userById = new Map <Id, User>([
            SELECT LastName, FirstName
            FROM User
            WHERE Id IN: actionPerformedByIds
        ]);

        Map<Id, CMPL123CME__Complaint__c> ticketById = new Map <Id, CMPL123CME__Complaint__c>([
            SELECT Division__c
            FROM CMPL123CME__Complaint__c
            WHERE Id IN: ticketIds
        ]);

        Map<Id, CMPL123CME__Investigation__c> invEvalById = new Map <Id, CMPL123CME__Investigation__c>([
            SELECT CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c
            FROM CMPL123CME__Investigation__c
            WHERE Id IN: relatedInvestigationEvaluationIds
        ]);

        for (Task__c task :tasks) {
            Boolean wfActionIsChanged = Trigger.isInsert || (Trigger.isUpdate && task.CMPL123_WF_Action__c != oldTaskById.get(task.Id).CMPL123_WF_Action__c);

            String actionPerformedBy = userById.get(task.CMPL123_WF_Action_Performed_By__c)?.FirstName
                + ' '
                + userById.get(task.CMPL123_WF_Action_Performed_By__c)?.LastName;

            //WF: Autoset Product Registration Number & Legal Manufacturer
            if (task.RecordTypeId == chinaRecordTypeId && task.List_Number_to_Review__c != null
                    && (oldTaskById == null || (oldTaskById != null
                        && (task.RecordTypeId != oldTaskById.get(task.Id).RecordTypeId || null == oldTaskById.get(task.Id).List_Number_to_Review__c )))) {
                task.Legal_Manufacturer__c = productTicketsById.get(task.Product_Ticket__c)?.Product__r.Legal_Manufacturer__c;
                task.Product_Registration_Number__c = productTicketsById.get(task.Product_Ticket__c)?.Product__r.Product_Registration_Number__c;
            }

            //WF: Autoset TPM fields
            if ((oldTaskById == null && task.TPM__c != null) || (oldTaskById != null && task.TPM__c != oldTaskById.get(task.Id).TPM__c)) {
                task.TPM_Contact_Email__c = tpmById.get(task.TPM__c)?.TPM_Contact_Email__c;
                task.TPM_Contact_Name__c = tpmById.get(task.TPM__c)?.TPM_Contact_Name__c;
            }

            //WF: Skip Pre Approval if Is Protocol Pre-Approval is yes
            // 07-FEB-2023 Larry: Commenting out this code as part of CHaRM R3.0 because
            // it is not physically possible to hit this. No automation changes this field, and
            // the field is not revealed to users on the frontend. As a result, the
            // 123Task called "PostInProgessTask" is not accessible either.
            // if (task.Is_Protocol_Pre_approved__c == 'Yes') {
            //     task.CMPL123Task_Key_Value__c = 'PostInProgessTask';
            // }
            //07-FEB-2022 Yadram : Defect 325 : Add ticketHistoryReviewListNumberRecordTypeId for fix the issue.
            //WF: Update Time Frame
            if (task.Timeframe_in_Months__c == null && (oldTaskById == null || (oldTaskById!=null && oldTaskById.get(task.Id).Timeframe_in_Months__c != null)) &&
               task.RecordTypeId == ticketHistoryReviewListNumberRecordTypeId) {
                if (ticketById.get(task.Parent_Ticket__c)?.Division__c == 'AMD') {
                    task.Timeframe_in_Months__c = 24;
                } else {
                    task.Timeframe_in_Months__c = 12;
                }
            }

            //WF: Update threshold URL
            if (invEvalById.get(task.Related_Investigation_Evaluation__c)?.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c != null) {
                task.Threshold_Report_URL_Part_1__c = 'https://globalbi.abbott.com/cognos/cgi-bin/cognosisapi.dll?b_action=xts.run&m=portal/launch.xts&ui.tool=CognosViewer&ui.object=/content/folder%5B@name=%22Metrics_Library%22%5D/folder%5B@name=%22Complaint%20Threshold%20Metrics%22%5D/report%5B@name=%22Complaint%20Threshold%20Metrics%20CPD%20by%20Ticket%22%5D&ui.action=run&p_p_TicketNum='
                    + invEvalById.get(task.Related_Investigation_Evaluation__c)?.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c
                    + '&run.prompt=false&ui=h1h2h3';
            }

            if (!wfActionIsChanged) {
                continue;
            }

            //WF: Clear Reject fields
            if (task.CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT || task.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Approve) {
                task.Rejected_By__c = null;
                task.Rejected_On__c = null;
                task.Rejection_Rationale__c = null;
            }

            //WF: Update Task performed by and time for custom fields
            if (task.CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_REJECT) {
                task.Rejected_By__c = actionPerformedBy;
                task.Rejected_On__c = task.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: Update Task performed by and time for custom fields
            if (task.CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT) {
                task.Task_Item_Submitted_By__c = actionPerformedBy;
                task.Task_Item_Submitted_On__c = task.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: Update Task performed by and time for custom fields
            if (task.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Approve) {
                task.Task_Item_Approved_By__c = actionPerformedBy;
                task.Task_Item_Approved_On__c = task.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: Update Task performed by and time for custom fields
            if (task.CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_COMPLETE_TASK) {
                task.Task_Item_Completed_By__c = task.CMPL123_WF_Action_Performed_By__c;
                task.Task_Item_Completion_Date__c = task.CMPL123_WF_Action_Performed_On__c;

                //WF: Workflow - Complete
                task.Reopened_By__c = null;
                task.Reopened_On__c = null;
                task.Request_More_Information__c = null;
            }

            //WF: Update Task performed by and time for custom fields
            if (task.CMPL123_WF_Action__c == AspenConstants.STR_WF_ACTION_SUBMIT_PRE_APPROVAL) {
                task.Task_Item_Submit_for_Pre_Approval_By__c = actionPerformedBy;
                task.Task_Item_Submit_for_Pre_Approval_On__c = task.CMPL123_WF_Action_Performed_On__c;
            }

            //WF: Workflow - Request More Information
            if (task.CMPL123_WF_Action__c == AspenConstants.STR_Request_More_Information) {
                task.Task_Item_Approved_On__c = null;
                task.Task_Item_Approved_By__c = null;
                task.Task_Item_Submit_for_Pre_Approval_By__c = null;
                task.Task_Item_Submit_for_Pre_Approval_On__c = null;
                task.Task_Item_Submitted_By__c = null;
                task.Task_Item_Submitted_On__c = null;
            }

            //WF: Workflow - Reopen
            if (task.CMPL123_WF_Action__c == AspenConstants.STR_Reopen) {
                task.Task_Item_Completed_By__c = null;
                task.Task_Item_Completion_Date__c = null;
                task.Reopened_On__c = task.CMPL123_WF_Action_Performed_On__c;
                task.Reopened_By__c = actionPerformedBy;
            }
        }
    }

    /*
    * @Method       : setRegNumber.
    * @Description  : TWD Upgrade issue. Added logic from WF rule: Autoset Registration Number.
    * @Invoke       : From Task_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : List<Task__c> tasks, Set<Id> relatedInvestigationEvaluationIds.
    */
    public static void setRegNumber(List<Task__c> tasks, Set<Id> relatedInvestigationEvaluationIds) {
        if (ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c) { return; }

        Map<Id, CMPL123CME__Investigation__c> invEvalById = new Map <Id, CMPL123CME__Investigation__c>([
            SELECT CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c, CMPL123CME__Complaint__r.RecordType.DeveloperName,
            CMPL123CME__Complaint__r.Service_Type__c
            FROM CMPL123CME__Investigation__c
            WHERE Id in: relatedInvestigationEvaluationIds
        ]);

        for (Task__c task: tasks) {
            if (invEvalById.get(task.Related_Investigation_Evaluation__c)?.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c == null) {
                continue;
            }

            String recordTypeName = invEvalById.get(task.Related_Investigation_Evaluation__c).CMPL123CME__Complaint__r.RecordType.DeveloperName;
            String cmsNextTicketNumber = invEvalById.get(task.Related_Investigation_Evaluation__c).CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c;

            task.Registration_Number__c = cmsNextTicketNumber
                + '('
                + (recordTypeName == AspenConstants.STR_Service ? invEvalById.get(task.Related_Investigation_Evaluation__c).CMPL123CME__Complaint__r.Service_Type__c + ' ' : '')
                + recordTypeName
                + ')';
        }
    }
}