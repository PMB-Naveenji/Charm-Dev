/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : ADDTrendItemMaintainanceReqHandler
* @Why   : Handles all the customization involved on ADDTrend item maintainance request handler object.
* @When  : 06-MAR-2017
* @Where : From Trend_Item_AuditTrigger trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                06-MAR-2017            Work ID / Case ID     Created.
*      oivan                26-FEB-2020            CHARM-1859 (CR#1261)  beforeUpdate(): Do not check Update Trend Item in validation
*  --------------------------------------------------------------------------------------------------------------------------------------
*      oivan                31-DEC-2020            TWD Upgrade issue     Related to WF Step issue, WF rules with field update moved to this handler.
* --------------------------------------------------------------------------------------------------------------------------------------
*      Dinesh Kumar         10-NOV-2023            CHaRM-R4/ IPDR- 571   Added two new methods "validateTIMRApproverNameFieldInsert" and 
                                                   IPDR-598              "validateTIMRApproverNameFieldUpdate" invoking from beforeInsert and
                                                                         beforeUpdate and Modified "wfLogic" method. Added Audit trail Handler code
                                                                         in beforeInsert.                                                                         
* --------------------------------------------------------------------------------------------------------------------------------------
*      Dinesh Kumar              13-Jul-2024        CHaRM-R5/ IPDR- 90    Updated the method validateT_TCannotCreateThreshold
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDTrendItemMaintainanceReqHandler extends TriggerHandler {

    //Variable declaration
    static Map<String, String> recordTypeMap;
    static String ADDRecordTypeId;
    static String UpdateRecordTypeId;
    
/**
* @Method       : getRecordTypes
* @Invoke       : From ADDTrendItemMaintainanceReqHandler class
* @Description  : Method to fetch the record type
* @Return       : N/A
* @Params       : N/A
**/
    public static void getRecordTypes() {
        if (recordTypeMap == null) {
            recordTypeMap = ADDUtil.getRecordTypeMap('Trend_Item_Maintenance_Request__c');
            ADDRecordTypeId = recordTypeMap.get('Add Trend Item');
            UpdateRecordTypeId = recordTypeMap.get('Update Trend Item');
        }
    }

/**
* @Method       : beforeInsert
* @Invoke       : Events from TriggerHandler before insert
* @Description  : To handle all the logic in before insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeInsert() {
        validateTIMRApproverNameFieldInsert();//CHaRM-R4: Invoking the method "validateTIMRApproverNameField" from Before Insert event.
        validateT_TCannotCreateThreshold();
        getRecordTypes();
        //TWD Upgrade Issue start.
        Set <Id> actionPerformedByIds = new Set <Id>();
        //TWD Upgrade Issue end.
        List<Trend_Item_Maintenance_Request__c> newRecord = (List<Trend_Item_Maintenance_Request__c>) Trigger.new;
        for (Trend_Item_Maintenance_Request__c queriedRecord : newRecord) {
            if (queriedRecord.RecordTypeId == UpdateRecordTypeId) {
                queriedRecord.Process__c = queriedRecord.Process_Lookup__c;
            }
            //TWD Upgrade Issue start.
            actionPerformedByIds.add(queriedRecord.CMPL123_WF_Action_Performed_By__c);
            //TWD Upgrade Issue end.
        }
        //TWD Upgrade Issue start.
        wfLogic(newRecord, null, actionPerformedByIds);
        //TWD Upgrade Issue end.
        CMPL123.AuditHandler.handleAudit(); //CHaRM-R4: Added the Audit Handler method in Before Insert.
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
        
        //TWD Upgrade Issue start.
        Set <Id> actionPerformedByIds = new Set <Id>();
        //TWD Upgrade Issue end.
        //Defect #1600 fix BEGIN
        CustomRecordLockingUtil.validateRecordEdit(Trigger.NewMap,
                                                    Trigger.OldMap,
                                                    new List <String> {'Pending Approval'},
                                                    new List <String> {'T_T_Task_Approver', 'T_T_Task_Reviewer', 'Business_Admin', 'System_Administrator'},
                                                    //CHaRM-R4 : Added 'TIMR_Rejection_Rationale__c' in the below Line
                                                    new List <String> {'Reject_Reason__c', 'TIMR_Rejection_Rationale__c', 'Requestor_Name__c', 'Requestor_Name_New__c', 'Current_User_Requestor__c'});
        //Defect #1600 fix END
        validateTIMRApproverNameFieldUpdate();//CHaRM-R4: Invoking the method "validateTIMRApproverNameField" from Before update event.
        validateT_TCannotCreateThreshold();
        
        validateUserForRejectFields();
        //CMPL123.AuditHandler.handleAudit(); //CHaRM-R4: Commented the Audit Handler Method to move it to the end.
        getRecordTypes();
        Map<Id, Trend_Item_Maintenance_Request__c> newRecordMap = (Map<Id, Trend_Item_Maintenance_Request__c>) Trigger.newMap;
        
        for (Trend_Item_Maintenance_Request__c queriedRecord: [SELECT Id, Request_Type__c,
                                                               CMPL123_WF_Action__c, RecordTypeId, RecordType.Name, Process__c, Trend_Item_Type__c,
                                                               Trend_Item_Type_Lookup_del__c, Process_Lookup__c,
                                                               (SELECT Id FROM Trend_Item_Maintenance_Trend_Buckets__r),
                                                               (SELECT Id FROM Trend_Item_Maintenance_Issue_Codes__r),
                                                               (SELECT Id FROM Trend_Item_Maintenance_Products__r) FROM Trend_Item_Maintenance_Request__c
                                                               WHERE Id IN: newRecordMap.keySet()
                                                               AND(RecordTypeId =: ADDRecordTypeId OR RecordTypeId =: UpdateRecordTypeId)]) {
                                                                   
                                                                   Trend_Item_Maintenance_Request__c currentRecord = newRecordMap.get(queriedRecord.Id);
                                                                   Trend_Item_Maintenance_Request__c oldRecord
                                                                       = (Trend_Item_Maintenance_Request__c) Trigger.oldMap.get(currentRecord.Id);
                                                                   
                                                                   if (currentRecord.CMPL123_WF_Action__c == 'Submit a Request' &&
                                                                       oldRecord.CMPL123_WF_Action__c != currentRecord.CMPL123_WF_Action__c) {
                                                                           if (queriedRecord.Trend_Item_Maintenance_Trend_Buckets__r.size() == 0 &&
                                                                               currentRecord.Process__c == 'Thresholds' &&
                                                                               (currentRecord.Trend_Item_Type__c == 'Assay' ||
                                                                                currentRecord.Trend_Item_Type__c == 'Consumables') &&
                                                                               currentRecord.RecordTypeId == ADDRecordTypeId) {
                                                                                   newRecordMap.get(currentRecord.Id).addError(
                                                                                       System.Label.Trend_Item_Maintenance_Trend_Buckets_Error
                                                                                   );
                                                                               } else if (queriedRecord.Trend_Item_Maintenance_Issue_Codes__r.size() == 0 &&
                                                                                          currentRecord.Process__c == 'Thresholds' &&
                                                                                          currentRecord.Trend_Item_Type__c == 'Process' &&
                                                                                          currentRecord.RecordTypeId == ADDRecordTypeId) {
                                                                                              currentRecord.addError(
                                                                                                  System.Label.Trend_Item_Maintenance_Request_Issue_Code_Error
                                                                                              );
                                                                                          } else if (queriedRecord.Trend_Item_Maintenance_Products__r.size() == 0 && 
                                                                                                  // CR 1261: Do not check Update Trend Item record type records
                                                                                                  currentRecord.RecordTypeId != UpdateRecordTypeId) {
                                                                                                  // End CR 1261
                                                                                                  currentRecord.addError(
                                                                                                      System.Label.Trend_Item_Maintenance_Request_Product_Error
                                                                                                  );
                                                                                          } else if (queriedRecord.Trend_Item_Maintenance_Trend_Buckets__r.size() == 0 &&
                                                                                                     currentRecord.Process_Lookup__c == 'Thresholds' &&
                                                                                                     (currentRecord.Trend_Item_Type_Lookup_del__c == 'Assay' ||
                                                                                                      currentRecord.Trend_Item_Type_Lookup_del__c == 'Consumables') &&
                                                                                                     currentRecord.RecordTypeId == UpdateRecordTypeId) {
                                                                                                         newRecordMap.get(currentRecord.Id).addError(
                                                                                                             System.Label.Trend_Item_Maintenance_Trend_Buckets_Error
                                                                                                         );
                                                                                                     } else if (queriedRecord.Trend_Item_Maintenance_Issue_Codes__r.size() == 0 &&
                                                                                                                currentRecord.Process_Lookup__c == 'Thresholds' &&
                                                                                                                currentRecord.Trend_Item_Type_Lookup_del__c == 'Process' &&
                                                                                                                currentRecord.RecordTypeId == UpdateRecordTypeId) {
                                                                                                                    currentRecord.addError(
                                                                                                                        System.Label.Trend_Item_Maintenance_Request_Issue_Code_Error
                                                                                                                    );
                                                                                                                }
                                                                       }
                                                               }
         //TWD Upgrade Issue start.                                                      
         Map<Id, Trend_Item_Maintenance_Request__c> oldRecordsById = (Map<Id, Trend_Item_Maintenance_Request__c>) Trigger.oldMap;
         for (Trend_Item_Maintenance_Request__c queriedRecord: newRecordMap.values()) { 
            actionPerformedByIds.add(queriedRecord.CMPL123_WF_Action_Performed_By__c); 
         }
         wfLogic(newRecordMap.values(), oldRecordsById, actionPerformedByIds);
         //TWD Upgrade Issue end.
         CMPL123.AuditHandler.handleAudit(); //CHaRM-R4:Moved the Audit Handler method to the End to Capture the Audit of the fields getting updated.
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
* @Method       : validateUserForRejectFields
* @Description  : created to check user's permission set to allow edit Rationale fields
* @Return       : N/A
* @Params       : N/A
**/
    public static void validateUserForRejectFields() {
        ADD_App_Settings__c addAppSettings = ADD_App_Settings__c.getValues(UserInfo.getUserId());
        if (null != addAppSettings && !addAppSettings.Restrict_Validation_Rules__c) {
            List<Trend_Item_Maintenance_Request__c> newList = (List<Trend_Item_Maintenance_Request__c>) Trigger.new;
            Map<Id, Trend_Item_Maintenance_Request__c> oldMap = (Map<Id, Trend_Item_Maintenance_Request__c>) Trigger.oldMap;
            List<AggregateResult> permissionSetAssignments = [SELECT COUNT(Id)
                                                                    FROM PermissionSetAssignment
                                                                    WHERE AssigneeId =: UserInfo.getUserId()
                                                                        AND (PermissionSet.Name = 'T_T_Task_Approver'
                                                                            OR PermissionSet.Name = 'T_T_Task_Reviewer'
                                                                            OR PermissionSet.Name = 'Business_Admin')];

            for (Trend_Item_Maintenance_Request__c timr :newList) {
                if ((timr.Reject_Reason__c == oldMap.get(timr.Id).Reject_Reason__c
                        //CHaRM-R4: added TIMR_Rejection_Rationale__c
                        || timr.TIMR_Rejection_Rationale__c == oldMap.get(timr.Id).TIMR_Rejection_Rationale__c
                        || timr.Rejected_By__c == oldMap.get(timr.Id).Rejected_By__c
                        || timr.Rejected_On__c == oldMap.get(timr.Id).Rejected_On__c
                        || timr.CMPL123_WF_Action__c == oldMap.get(timr.Id).CMPL123_WF_Action__c
                        || timr.CMPL123_WF_Status__c == oldMap.get(timr.Id).CMPL123_WF_Status__c
                        || timr.CMPL123_WF_Action_Performed_On__c == oldMap.get(timr.Id).CMPL123_WF_Action_Performed_On__c
                        || timr.CMPL123Rule_Key_Value__c == oldMap.get(timr.Id).CMPL123Rule_Key_Value__c
                        || timr.Trend_Item__c == oldMap.get(timr.Id).Trend_Item__c
                        || timr.CMPL123_WF_Action_Performed_By__c == oldMap.get(timr.Id).CMPL123_WF_Action_Performed_By__c)
                        && (timr.CMPL123_WF_Status__c == 'Pending Implementation' || timr.CMPL123_WF_Status__c == 'Pending Approval' || timr.CMPL123_WF_Status__c == 'TIMR Pending Approval') && (Integer) permissionSetAssignments[0].get('expr0') == 0) {
                    timr.addError(System.Label.Locked_TIMR_Record);
                }
            }
        }
    }

    /**
* @Method       : validateT_TCannotCreateThreshold
* @Description  : created to check user's permission set to allow\restrict inserting a record with "Thresholds" Process value
* @Return       : N/A
* @Params       : N/A
**/
    public static void validateT_TCannotCreateThreshold() {
        ADD_App_Settings__c addAppSettings = ADD_App_Settings__c.getValues(UserInfo.getUserId());
        system.debug('addAppSettings>>'+addAppSettings);
        system.debug('UserInfo.getUserId()>>'+UserInfo.getUserId());
        user u = [select id,name from user where id=:UserInfo.getUserId()];
        system.debug('YOU>> '+u);
        if (addAppSettings == null || (null != addAppSettings && !addAppSettings.Restrict_Validation_Rules__c)) {
            
            //CHaRM R5: Added the IT_Admin_T_T permission in the below query to allow access for TIMR record
           Integer usersNumber = [SELECT COUNT()
                                    FROM PermissionSetAssignment
                                    WHERE AssigneeId =: UserInfo.getUserId()
                                    AND (PermissionSet.Name = 'T_T_Task_Approver'
                                        OR PermissionSet.Name = 'T_T_Task_Reviewer'
                                        OR PermissionSet.Name = 'IT_Admin_T_T')];
            //CHaRM R5: Added Check for Business_Admin Permission set for IPDR- 90 to allow Dual Permission user
            //CHaRM R5: Added the IT_Admin_T_T permission in the below query to allow access for TIMR record
            Integer usersNumberBussiness = [SELECT COUNT()
                                    FROM PermissionSetAssignment
                                    WHERE AssigneeId =: UserInfo.getUserId()
                                    AND (PermissionSet.Name = 'Business_Admin'
                                        OR PermissionSet.Name = 'IT_Admin_T_T')];
            
            for (Trend_Item_Maintenance_Request__c timr :(List<Trend_Item_Maintenance_Request__c>) Trigger.new) {
                //CHaRM -R5: Added Check for Business_Admin Permission set to allow Dual Permission user and also added Process_Actual__c field in the condition.
                if (usersNumberBussiness == 0 && timr.Process_Actual__c == System.label.Thresholds) {
                    timr.addError(System.Label.OnlyBusinessAdminCanCreateThreshold);
                }
                //CHaRM -R5: Added Check for T&T task approver or T&T Task Reviewer or It Admin Permission set to allow Dual Permission user and also added Process_Actual__c field in the condition.
                 if (usersNumber == 0 && (timr.Process_Actual__c == System.label.Ticket_T_T || timr.Process_Actual__c == System.label.Submission_T_T)) {
                   timr.addError(System.Label.OnlyTTTaskApproverOrTTTaskReviewerCancreateTicketTTSubmissionTT);
                }                                
            }
        }
    }

    /*
    * @Method       : wfLogic,
    * @Description  : To handle WF logic.
    * @Invoke       : From ADDTrendItemMaintainanceReqHandler class.
    * @Return       : N/A.
    * @Params       : List <Trend_Item_Maintenance_Request__c> newTIMRs, Map <Id, Trend_Item_Maintenance_Request__c> oldRecordById, Set <Id> actionPerformedByIds.
    */
    public static void wfLogic(List <Trend_Item_Maintenance_Request__c> newTIMRs, Map <Id, Trend_Item_Maintenance_Request__c> oldRecordById, Set <Id> actionPerformedByIds) {
        Id inactiveTrendItemRecType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Inactivate Trend Item').getRecordTypeId();
        Id reactiveTrendItemRecType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Reactivate Trend Item').getRecordTypeId();
        Map<Id, User> userById = new Map <Id, User>([SELECT LastName, FirstName FROM User WHERE Id in: actionPerformedByIds]);
        for (Trend_Item_Maintenance_Request__c timr: newTIMRs) {
            //WF: Last Un/Suspended Date update 
            if ((oldRecordById == null && timr.Suspended__c != null) || (oldRecordById != null && timr.Suspended__c != oldRecordById.get(timr.Id).Suspended__c)) {
                timr.Last_Un_Suspended_Date__c = date.today();
            }
            //WF: Update Rule Field for Trend Item Maint I/R Workflow  
            if (oldRecordById == null && (timr.RecordTypeId == inactiveTrendItemRecType || timr.RecordTypeId == reactiveTrendItemRecType)) {
                timr.CMPL123Rule_Key_Value__c = 'TREND_ITEM_MAINTENANCE_I_R_WORKFLOW';
            }
            //WF: Update Rule Field for Trend Item Maint Workflow
            if (oldRecordById == null && (timr.RecordTypeId == ADDRecordTypeId || timr.RecordTypeId == UpdateRecordTypeId)) {
                timr.CMPL123Rule_Key_Value__c = 'TREND_ITEM_MAINTENANCE_WORKFLOW';
            }
            //CHaRM-R4: (Start) Workflow - TIMR Fields getting populated when "TIMR Approve" action is selected.    
            if (timr.CMPL123_WF_Action__c == 'TIMR Approve' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
    
                timr.TIMR_Rejected_By__c = null;
                timr.TIMR_Rejected_On__c = null;
                timr.TIMR_Rejection_Rationale__c = null;
                timr.TIMR_Approved_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.TIMR_Approved_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                           userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            } 
            //CHaRM-R4: (End)
           // Workflow - Approve    
            if (timr.CMPL123_WF_Action__c == 'Approve' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Rejected_By__c = null;
                timr.Rejected_On__c = null;
                timr.Reject_Reason__c = null;
                timr.Approved_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.Approved_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                      userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            }
            //WF: Workflow - Close  
            if (timr.CMPL123_WF_Action__c == 'Close' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Closed_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.Closed_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                      userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            }
            //WF:  Workflow - Implementation Complete
            if (timr.CMPL123_WF_Action__c == 'Implementation Complete' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Implementation_Completed_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.Implementation_Completed_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                      userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            }
            //CHaRM-R4 (Start) Workflow - TIMR Fields getting populated when "TIMR Reject" action is selected
            if (timr.CMPL123_WF_Action__c == 'TIMR Reject' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.TIMR_Rejected_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.TIMR_Rejected_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                      userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
                //CHaRM-R4: added TIMR Approved on & TIMR Approved by
                timr.TIMR_Approved_On__c = null;
                timr.TIMR_Approved_By__c = null;
            }
            //CHaRM-R4(End)
            //Workflow - Reject
            if (timr.CMPL123_WF_Action__c == 'Reject' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Rejected_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.Rejected_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                      userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            }           
            //WF: Workflow - Request More Info
            if (timr.CMPL123_WF_Action__c == 'Request More Info' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Request_Submitted_On__c = null;
                timr.Request_Submitted_By__c = null;
            //CHaRM-R4 Workflow - TIMR Approved On and TIMR Approved By Fields getting populated with Null when "Request More Info" action is selected
                timr.TIMR_Approved_On__c = null;
                timr.TIMR_Approved_By__c = null;
            }   
            //WF: Workflow - Submit a Request
            if (timr.CMPL123_WF_Action__c == 'Submit a Request' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Request_More_Information__c = null;
                timr.Request_Submitted_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.Request_Submitted_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                               userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            } 
            //WF: Workflow - Submit for Implementation
            if (timr.CMPL123_WF_Action__c == 'Submit for Implementation' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Submitted_for_Implementation_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.Submitted_for_Implementation_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                               userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            } 
            //WF: Workflow - Submit Re/Baseline for Review  
            if (timr.CMPL123_WF_Action__c == 'Submit Re/Baseline for Review' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Re_Baseline_Submitted_for_Review_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.Re_Baseline_Submitted_for_Review_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                               userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            }
            //WF: Workflow - Void
            if (timr.CMPL123_WF_Action__c == 'Void' && (oldRecordById == null || (oldRecordById != null && timr.CMPL123_WF_Action__c != oldRecordById.get(timr.Id).CMPL123_WF_Action__c))) {
                timr.Voided_On__c = timr.CMPL123_WF_Action_Performed_On__c;
                timr.Voided_By__c = userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                               userById.get(timr.CMPL123_WF_Action_Performed_By__c)?.LastName;
            } 
        }
    }
    //Start CHaRM-R4
    /*
* @Method       : validateTIMRApproverNameFieldUpdate,
* @Description  : To handle Valiadtion on TIMR Approver Name Field to have the correct user by validating the the Process Field Type and 
the users permission from the TIMR Approver Name Field. Invoked from Before update
* @Invoke       : From ADDTrendItemMaintainanceReqHandler class.
* @Return       : N/A.
* @Params       : 
*/
    public static void validateTIMRApproverNameFieldUpdate(){
        Set<Id> userIDList = new Set<Id>();
        Set<String> PermissionSetName = new Set<String>{'T_T_Task_Approver','Business_Admin'};
            List<Trend_Item_Maintenance_Request__c> newRecord = (List<Trend_Item_Maintenance_Request__c>) Trigger.new;
        for (Trend_Item_Maintenance_Request__c queriedRecord : newRecord){
            userIDList.add(queriedRecord.TIMR_Approver_Name__c);
        }
                
        Map<Id,String> timrApproverNamePermission = new map<id, String>();
        //check permission set
        for(PermissionSetAssignment checkPermissionSet :  [Select AssigneeId, PermissionSet.Name from PermissionSetAssignment where AssigneeId In :userIDList and PermissionSet.Name IN :PermissionSetName]){
            timrApproverNamePermission.put(checkPermissionSet.AssigneeId, checkPermissionSet.PermissionSet.Name);
        }
        
        for (Trend_Item_Maintenance_Request__c queriedRecord : newRecord){
            Trend_Item_Maintenance_Request__c oldRecord = (Trend_Item_Maintenance_Request__c) Trigger.oldMap.get(queriedRecord.Id);
            if(oldRecord.TIMR_Approver_Name__c != queriedRecord.TIMR_Approver_Name__c){
                If(!timrApproverNamePermission.containsKey(queriedRecord.TIMR_Approver_Name__c) && (queriedRecord.Process_Actual__c == System.label.Thresholds || queriedRecord.Process_Actual__c == System.label.Ticket_T_T || queriedRecord.Process_Actual__c == System.label.Submission_T_T)){
                    queriedRecord.addError(System.label.TIMR_Approver_Name_Is_Not_BussinessAdmin_Or_T_T_TaskApprover);
                }
                If(timrApproverNamePermission.containsKey(queriedRecord.TIMR_Approver_Name__c) && !(timrApproverNamePermission.get(queriedRecord.TIMR_Approver_Name__c) == 'Business_Admin')
                   && (queriedRecord.Process_Actual__c == System.label.Thresholds)){
                       queriedRecord.addError(System.label.TIMR_Approver_Name_Business_Admin);
                }
                If(timrApproverNamePermission.containsKey(queriedRecord.TIMR_Approver_Name__c) && !(timrApproverNamePermission.get(queriedRecord.TIMR_Approver_Name__c) == 'T_T_Task_Approver')
                   && (queriedRecord.Process_Actual__c == System.label.Ticket_T_T || queriedRecord.Process_Actual__c == System.label.Submission_T_T)){
                       queriedRecord.addError(System.label.TIMR_Approver_Name_T_T_Approver);
                }
               
            }
        }
        
    }//CHaRM-R4 End
    
    //Start CHaRM-R4
    /*
* @Method       : validateTIMRApproverNameFieldInsert,
* @Description  : To handle Valiadtion on TIMR Approver Name Field to have the correct user by validating the the Process Field Type and 
the users permission from the TIMR Approver Name Field. Invoked from Before Insert.
* @Invoke       : From ADDTrendItemMaintainanceReqHandler class.
* @Return       : N/A.
* @Params       : 
*/
    public static void validateTIMRApproverNameFieldInsert(){
        Set<Id> userIDList = new Set<Id>();
        Set<String> PermissionSetName = new Set<String>{'T_T_Task_Approver','Business_Admin'};
            List<Trend_Item_Maintenance_Request__c> newRecord = (List<Trend_Item_Maintenance_Request__c>) Trigger.new;
        for (Trend_Item_Maintenance_Request__c queriedRecord : newRecord){
            userIDList.add(queriedRecord.TIMR_Approver_Name__c);
        }
        
        Map<Id,String> timrApproverNamePermission = new map<id, String>();
        //check permission set
        for(PermissionSetAssignment checkPermissionSet :  [Select AssigneeId, PermissionSet.Name from PermissionSetAssignment where AssigneeId In :userIDList and PermissionSet.Name IN :PermissionSetName]){
            timrApproverNamePermission.put(checkPermissionSet.AssigneeId, checkPermissionSet.PermissionSet.Name);
        }
        
        for (Trend_Item_Maintenance_Request__c queriedRecord : newRecord){
           If(!timrApproverNamePermission.containsKey(queriedRecord.TIMR_Approver_Name__c) && queriedRecord.TIMR_Approver_Name__c != null && (queriedRecord.Process_Actual__c == System.label.Thresholds || queriedRecord.Process_Actual__c == System.label.Ticket_T_T || queriedRecord.Process_Actual__c == System.label.Submission_T_T)){
                queriedRecord.addError(System.label.TIMR_Approver_Name_Is_Not_BussinessAdmin_Or_T_T_TaskApprover);
            }
            If(timrApproverNamePermission.containsKey(queriedRecord.TIMR_Approver_Name__c) && 
               !(timrApproverNamePermission.get(queriedRecord.TIMR_Approver_Name__c) == 'Business_Admin') && (queriedRecord.Process_Actual__c == System.label.Thresholds)){
                   queriedRecord.addError(System.label.TIMR_Approver_Name_Business_Admin); 
               } 
            If(timrApproverNamePermission.containsKey(queriedRecord.TIMR_Approver_Name__c) && !(timrApproverNamePermission.get(queriedRecord.TIMR_Approver_Name__c) == 'T_T_Task_Approver')
               && (queriedRecord.Process_Actual__c == System.label.Ticket_T_T || queriedRecord.Process_Actual__c == System.label.Submission_T_T)){
                   queriedRecord.addError(System.label.TIMR_Approver_Name_T_T_Approver);
               } 
            
        } 
           
    } //CHaRM-R4 End 
           
    
}