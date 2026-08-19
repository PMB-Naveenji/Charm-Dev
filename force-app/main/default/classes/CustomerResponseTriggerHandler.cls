/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : CustomerResponseTriggerHandler.
 * @Why   : Public class to manage all the custom coding invoked on the Customer_Response__c object.
 * @When  : 23-03-2017.
 * @Where : From Customer_Response_AuditTrigger Trigger.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID             Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    23-03-2017             Work ID / Case ID           Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    03-12-2019             Defect #1400                Modified.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    06-12-2019             Defect #1633                Modified.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    22-05-2020             #123/CHARM-2729             Added processedTickectIds set returning updated ticket ids
 *                                                                                 into processEligibleComplaintsToComplete method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    04-06-2020             Code Audit                  Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-06-2020             Code Audit                  Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    23-06-2020             #123.1/CHARM-2878           Added flags to prevent logic execution if only
 *                                                                                 Last Modified Date is updated.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    28-DEC-2020            TWD Upgrade issue           Added 'executeLogicFromWFRules()' method to move logic from
 *                                                                                 Workflow Rules with Field Updates on Customer Response to Apex.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    11-JAN-2021            TWD Upgrade #92             Added logic for division assignment upon creation.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             23-MAY-2023            CHaRM R3.1, IPDR 116        Made prepTranslationItemsForVoiding and added it to afterUpdateHandler
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Charm COE                17-Jul-2025             IPDR-746                   Updated method "beforeEventHandler" add validation check before change the status.
 * Charm COE				07-Aug-2025             IPDR-749				   Updated method "checkCustomerResponseClosureEctionExecutorRole" added check to identify QCA
 * 																			   based on assigned permission set.
 * --------------------------------------------------------------------------------------------------------------------------------------  
*/

public class CustomerResponseTriggerHandler {
    // R3.1, Larry: Converted a switch-case statement into this map because
    // Salesforce switch statements cannot work with variables even if they are constant (final).
    public static final Map<String, String> TICKET_TYPE_TO_GROUP_NAME = new Map<String, String>{
        AspenConstants.STR_Complaint => AspenConstants.GROUP_QC,
        AspenConstants.STR_Inquiry => AspenConstants.GROUP_QNC,
        AspenConstants.STR_Service => AspenConstants.GROUP_QNC
    };
    public static final Set<String> TRANS_TASK_LOCKED_WF_STATUSES = new Set<String>{
        AspenConstants.STR_WF_Closed_Done,
        AspenConstants.STR_WF_Closed_Voided
    };
    public static Boolean executingCRCreate = false;
    public static Boolean executingCRCreateAfterEvent = false;
    public static Boolean isBeforeUpdateExecuted = false;
    public static Boolean TTFlag = false;   // 07FEB19 - AQC#120 - CPU TIME LIMIT
    // Def #123.1/CHARM-2878: added isUpdated, isLastModifiedDateUpdating
    public static Boolean isUpdated = false;
    public static Boolean isLastModifiedDateUpdating = false;
    public static List<PermissionSetAssignment> permSetList = new List<PermissionSetAssignment>();

    public static void beforeEventHandler() {
        TicketUtil.addTrace('CustomerResponseTriggerHandler.beforeEventHandler');
        List<Customer_Response__c> newCustomerResponses = (List<Customer_Response__c>) Trigger.New;

        //Defects 1400 & 1633 fixes BEGIN
        //Only before update because needed status are not start statuses
        List<Customer_Response__c> oldCustomerResponses = (List<Customer_Response__c>) Trigger.Old;
        Map <Id, Customer_Response__c> oldMap =  (Map <Id, Customer_Response__c>) Trigger.oldMap;
        if (Trigger.isUpdate) {

            //For defect #1633
            checkCustomerResponseClosureEctionExecutorRole(new Map<Id, Customer_Response__c>(newCustomerResponses), new Map<Id, Customer_Response__c>(oldCustomerResponses));
            // IPDR-746: Validates status change on Customer Response records based on metadata-defined statuses.
			// If status changes to a restricted value and related Translation Items exist (not closed), block the update.

            Set<String> statusList = new Set<String>();
            Map<String, Customer_Response_Status_for_Validation__mdt> mapCRStatus = Customer_Response_Status_for_Validation__mdt.getAll();
            for(String status : mapCRStatus.keySet()){
                statusList.add(mapCRStatus.get(status).Label);
            }
            List<Id> crIds = new List<Id>();
            for(Customer_Response__c cr : newCustomerResponses){
                crIds.add(cr.Id);
            }
            List<Translation_Item__c> translationItemList= [Select Id, Name, Translation_Task__r.Name, Field_Name__c,Related_Record_Id__c 
                                                            from Translation_Item__c where Related_Record_Id__c =: crIds[0]
                                                            and Translation_Task__r.CMPL123_WF_Status__c NOT IN ('Closed-Done', 'Closed-Voided')];
            
            // Loop through new records and compare old values
            for(Customer_Response__c cr : newCustomerResponses){
                Customer_Response__c oldCustomerResponseRec = oldMap.get(cr.Id);
                if((oldCustomerResponseRec != null && oldCustomerResponseRec.CMPL123_WF_Status__c != 'Pending Quality Approval') && statusList.contains(cr.CMPL123_WF_Status__c) && (cr.CMPL123_WF_Status__c != oldCustomerResponseRec.CMPL123_WF_Status__c) && translationItemList.size() > 0){
                    cr.addError(Label.CR_Validation_Message);
                }
            }
            //IPDR-746
        }
        //Defects 1400 & 1633 fixes END

        if (Trigger.isInsert && !executingCRCreate) {
            executingCRCreate = true;

            Set<String> complaintIdSet = new Set<String>();
            for (Customer_Response__c newCR : newCustomerResponses) {
                newCR.Division_New__c = AspenConstants.DIVISION_DIAGNOSTICS;
                if (newCR.Event__c != null && newCR.CMPL123Rule_Key_Value__c == null) {
                    complaintIdSet.add(newCR.Event__c);
                }
            }
            Map<String, String> complaintIdWithTicketType = new Map<String, String>();


            if (complaintIdSet.size() > 0) {
                for (CMPL123CME__Complaint__c complaint : [
                        SELECT Id,Ticket_Type__c
                        FROM CMPL123CME__Complaint__c
                        WHERE Id IN :complaintIdSet AND
                        (Ticket_Type__c = :AspenConstants.STR_Complaint OR Ticket_Type__c = :AspenConstants.STR_Inquiry)
                        AND (CMPL123CME__CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Done
                        OR CMPL123CME__CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided)
                ]) {
                    complaintIdWithTicketType.put(complaint.Id, complaint.Ticket_Type__c);
                }
            }

            for (Customer_Response__c newCR : newCustomerResponses) {
                if (newCR.Event__c != null && newCR.CMPL123Rule_Key_Value__c == null && complaintIdWithTicketType.get(newCR.Event__c) != null) {
                    newCR.CMPL123Rule_Key_Value__c = complaintIdWithTicketType.get(newCR.Event__c) == AspenConstants.STR_Complaint
                            ? ComplaintTriggerHandler.complaintCustomerResponseKeyValue
                            : ComplaintTriggerHandler.inquiryCustomerResponseKeyValue;
                }
            }
        } else if (Trigger.isUpdate) {
            Map<Id, Customer_Response__c> oldCustomerResponsesMap = (Map<Id, Customer_Response__c>) Trigger.oldMap;

            if (newCustomerResponses != null) {
                for (Customer_Response__c newCR : newCustomerResponses) {
                    Customer_Response__c oldCR = oldCustomerResponsesMap != null ? oldCustomerResponsesMap.get(newCR.Id) : new Customer_Response__c();

                    /* Record locking in Closed-Done or Closed-Voided statuses (isBeforeUpdateExecuted flag is used in
                    order to avoid locking when record is updated through automatical task) */
                    if ((oldCR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Done || oldCR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided)
                            && oldCR.CMPL123Task_Key_Value__c == newCR.CMPL123Task_Key_Value__c
                            && oldCR.CMPL123_WF_Status__c == newCR.CMPL123_WF_Status__c && !isBeforeUpdateExecuted) {
                        newCR.addError(Label.Record_Locked);
                    }
                    if (newCustomerResponses.size() == 1 && (newCR.CMPL123_WF_Status__c != AspenConstants.STR_WF_Closed_Done || newCR.CMPL123_WF_Status__c != AspenConstants.STR_WF_Closed_Voided)) {
                        if (newCR.CMPL123_WF_Status__c == AspenConstants.WF_STATUS_PENDING_QUALITY_APPROVAL && oldCR.CMPL123_WF_Status__c != newCR.CMPL123_WF_Status__c) {
                            if (newCR.Additional_Approvals__c == null) {
                                newCR.CMPL123Task_Key_Value__c = 'QGR';
                            } else if (newCR.Additional_Approvals__c == 'Tech Approval') {
                                newCR.CMPL123Task_Key_Value__c = 'QTGR';
                            } else if (newCR.Additional_Approvals__c == 'Regulatory Approval') {
                                newCR.CMPL123Task_Key_Value__c = 'QLGR';
                            } else if (newCR.Additional_Approvals__c != null && newCR.Additional_Approvals__c.containsIgnoreCase('Tech Approval') && newCR.Additional_Approvals__c.containsIgnoreCase('Regulatory Approval')) {
                                newCR.CMPL123Task_Key_Value__c = 'QTLGR';
                            }
                        } else if (newCR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Opened && newCR.CMPL123_WF_Status__c != oldCR.CMPL123_WF_Status__c) {
                            newCR.CMPL123Task_Key_Value__c = null;
                        }

                        else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Process_Team_Approval && oldCR.CMPL123_WF_Action__c != newCR.CMPL123_WF_Action__c) {
                            newCR.Rejection_Reason__c = '';
                        }
                        // W-000588 - Auto post Pending Promotion to Responded to Responded
                        else if (newCR.CMPL123_WF_Status__c == AspenConstants.WF_STATUS_PENDING_PROMOTE_TO_RESPOND && oldCR.CMPL123_WF_Status__c != newCR.CMPL123_WF_Status__c) {
                            newCR.CMPL123Task_Key_Value__c = 'Pending_Promotion_to_Responded';
                        }
                    }
                }
            }
            isBeforeUpdateExecuted = true;
        }
    }

    /**
    * @Method       : afterEventHandler
    * @Invoke       : Events from afterEventHandler
    * @Description  : Description : public method referenced in the customer response audit trigger, which executes in after events,
    related to user story W-1309
    1. Updates customer response when closed done action is performed.
    2. Update ticket status to responded when "Responded & Action Required" action performed.
    * @Return       : N/A
    * @Params       : N/A
    **/
    public static void afterEventHandler() {
        TicketUtil.addTrace('CustomerResponseTriggerHandler.afterEventHandler');
        if (executingCRCreateAfterEvent) {
            return;
        }
        executingCRCreateAfterEvent = true;
        List<Customer_Response__c> newCustomerResponses = (List<Customer_Response__c>) Trigger.New;
        Map<Id, Customer_Response__c> oldCustomerResponsesMap = (Map<Id, Customer_Response__c>) Trigger.oldMap;

        List<Customer_Response__c> updatableCustomerResponses = new List<Customer_Response__c>();
        List<CMPL123CME__Complaint__c> updatableComplaints = new List<CMPL123CME__Complaint__c>();
        Set<String> complaintIds = new Set<String>();

        for (Customer_Response__c CR : newCustomerResponses) {
            if ((CR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Done || CR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided) && oldCustomerResponsesMap != null
                    && CR.CMPL123_WF_Status__c != oldCustomerResponsesMap.get(CR.Id).CMPL123_WF_Status__c) {
                if (CR.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Done) {
                    updatableComplaints.add(
                            new CMPL123CME__Complaint__c(
                                    Id = CR.Event__c,
                                    Follow_up_Status__c = CR.CMPL123_WF_Action__c == AspenConstants.STR_Responded_Info_On_Labeling
                                            ? 'Responded_Info_in_Labeling'
                                            : 'Responded'
                            )
                    );

                    if (CR.CMPL123_WF_Action__c == AspenConstants.STR_Responded_Info_On_Labeling) {
                        updatableCustomerResponses.add(new Customer_Response__c(Action_Required__c = true, Id = CR.Id));
                    }
                }
                complaintIds.add(CR.Event__c);
            }
        }

        if (updatableCustomerResponses.size() > 0) {
            update updatableCustomerResponses;
        }

        // R3.1, Larry: TODO: With this update operation and the two functions following it,
        // there are about five potential update operations just on Tickets.
        // It's slow and there's room for optimization, but who knows what
        // functionality could break if the updates were consolidated.
        if (updatableComplaints.size() > 0) {
            update updatableComplaints;
        }

        if (complaintIds.size() > 0) {
            processEligibleComplaintsToComplete(complaintIds);
        }

        //Added - W-000108 - 07/08/2018
        closeTicketBasedOnCustomerResponses(newCustomerResponses);

        // R3.1, Larry: Added this function call and subsequent update operation
        Map<Id, Translation_Item__c> transItemIdToRec = prepTranslationItemsForVoiding(
            newCustomerResponses, oldCustomerResponsesMap);
        if (!transItemIdToRec.isEmpty()) {
            update transItemIdToRec.values();
        }
    }

    /**
    * @Method       : processEligibleComplaintsToComplete
    * @Invoke       : Events from addTrace
    * @Description  : Description : public method used to auto-promote ticket to complete status when all child records are closed.
    W-1208   Applicable to only if ticket type is complaint
    * @Return       : Set<Id> processedTickectIds
    * @Params       : Set<String> complaintIdSet
    **/
    // Defect #123/CHARM-2729: changed void return result to Set<Id>
    public static Set<Id> processEligibleComplaintsToComplete(Set<String> complaintIdSet) {
        TicketUtil.addTrace('CustomerResponseTriggerHandler.processEligibleComplaintsToComplete');
        List<CMPL123CME__Complaint__c> eligibleComplaints = new List<CMPL123CME__Complaint__c>();
        List<CMPL123CME__Complaint__c> eligibleTickets = new List<CMPL123CME__Complaint__c>();
        Set<Id> processedTickectIds = new Set<Id>();    // Defect #123/CHARM-2729: added set of processed ticket ids

        if (complaintIdSet != null && complaintIdSet.size() > 0) {
            for (CMPL123CME__Complaint__c complaint : [
                SELECT Id,CMPL123CME__CMPL123_WF_Action__c,
                CMPL123CME__CMPL123_WF_Status__c, MDC_All_ACKs_Received__c,
                CMPL123CME__CMPL123_WF_Action_Performed_By__c, CMPL123CME__CMPL123_WF_Action_Performed_On__c,
                Follow_up_Status__c, (
                    SELECT Id
                    FROM Ticket_Product_Evaluation_Investigation__r
                    WHERE Investigation_Evaluation__r.CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided
                    AND Investigation_Evaluation__r.CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Done
                    LIMIT 1
                ), (
                    SELECT Id
                    FROM Customer_responses__r
                    WHERE CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided AND
                    CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Done
                    LIMIT 1
                ), (
                    SELECT Id
                    FROM CMPL123CME__Questionnaires__r
                    WHERE CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided AND
                    CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Done
                    LIMIT 1
                ), (
                    SELECT Id
                    FROM Returns__r
                    WHERE CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided AND
                    CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Done
                    LIMIT 1
                ), (
                    SELECT Id
                    FROM Meaningful_Data_Requests__r
                    WHERE Request_Status__c != 'Completed' AND Request_Status__c != 'Voided'
                    LIMIT 1
                ), (
                    SELECT Id
                    FROM Translation_Tasks__r
                    WHERE CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Done AND CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided
                    LIMIT 1
                )
                FROM CMPL123CME__Complaint__c
                WHERE Id IN :complaintIdSet AND (
                    CMPL123CME__CMPL123_WF_Status__c = :AspenConstants.STR_WF_Opened OR
                    CMPL123CME__CMPL123_WF_Status__c = :AspenConstants.STR_WF_Reg_Closed
                )
                AND Ticket_Type__c = :AspenConstants.STR_Complaint
            ]) {
                // Written for W-001268
                if (complaint.CMPL123CME__CMPL123_WF_Status__c == AspenConstants.STR_WF_Opened && complaint.MDC_All_ACKs_Received__c &&
                        complaint.Ticket_Product_Evaluation_Investigation__r.size() == 0 &&
                        complaint.Customer_responses__r.size() == 0 && complaint.returns__r.size() == 0 &&
                        complaint.Meaningful_Data_Requests__r.size() == 0 && complaint.Translation_Tasks__r.size() == 0) {
                    eligibleComplaints.add(new CMPL123CME__Complaint__c
                            (Id = complaint.Id, CMPL123Task_Key_Value__c = 'ComplaintComplete', Ready_to_Close__c = AspenConstants.STR_Yes,
                                    Follow_up_Status__c = complaint.Follow_up_Status__c, Last_Modified_Date_Time__c = System.now()));
                    processedTickectIds.add(complaint.Id);  // Defect #123/CHARM-2729: add id of processed ticket
                }

                if (complaint.CMPL123CME__CMPL123_WF_Status__c == AspenConstants.STR_WF_Reg_Closed &&
                        complaint.Ticket_Product_Evaluation_Investigation__r.size() == 0 && complaint.MDC_All_ACKs_Received__c &&
                        complaint.Customer_responses__r.size() == 0 && complaint.returns__r.size() == 0 &&
                        complaint.Meaningful_Data_Requests__r.size() == 0 && complaint.Translation_Tasks__r.size() == 0 &&
                        complaint.CMPL123CME__Questionnaires__r.size() == 0) {
                    eligibleTickets.add(
                            new CMPL123CME__Complaint__c(
                                    Id = complaint.Id,
                                    CMPL123Task_Key_Value__c = 'ReopentoClose',
                                    Last_Modified_Date_Time__c = System.now(),
                                    Reopen_Rationale__c = 'Automatically reopened by the CHaRM System.'
                            )
                    );
                    processedTickectIds.add(complaint.Id);  // Defect #123/CHARM-2729: add id of processed ticket
                }
            }

            if (eligibleComplaints.size() > 0) {
                ComplaintTriggerHandler.executingThroughInvokable = true;
                update eligibleComplaints;

                List<CMPL123CME__Complaint__c> modifiedEligibleComplaints = new List<CMPL123CME__Complaint__c>();
                for (CMPL123CME__Complaint__c completedComplaint : eligibleComplaints) {
                    if (completedComplaint.Follow_up_Status__c == 'Further Review') {
                        modifiedEligibleComplaints.add(
                                new CMPL123CME__Complaint__c(
                                        Id = completedComplaint.Id,
                                        CMPL123Task_Key_Value__c = 'FurtherReview',
                                        Ready_to_Close__c = AspenConstants.STR_No,
                                        Last_Modified_Date_Time__c = System.now()
                                )
                        );
                    }
                }
                if (modifiedEligibleComplaints.size() > 0) {
                    update modifiedEligibleComplaints;
                }
            }
            if (eligibleTickets.size() > 0) {
                update eligibleTickets;
            }
        }
        return processedTickectIds; // Defect #123/CHARM-2729
    }

    /**
    * @Method       : closeTicketBasedOnCustomerResponses
    * @Description  : W-000108 - When all Customer Responses related to ticket closed, based on ticket "MDC All ACKs Received?"
    *                 And "CMSNext Status" field values close ticket.
    * @Return       : N/A
    * @Params       : List<Translation_Task__c> lstTranslationTasksNew
    **/
    private static void closeTicketBasedOnCustomerResponses(List<Customer_Response__c> lstCustomerResponsesNew) {
        TicketUtil.addTrace('CustomerResponseTriggerHandler.closeTicketBasedOnCustomerResponses');
        //Store Related Ticket Ids
        Set<Id> setTicketIds = New Set<Id>();

        for (Customer_Response__c objCustomerResponse : lstCustomerResponsesNew) {
            if (objCustomerResponse.Event__c != null) {
                setTicketIds.add(objCustomerResponse.Event__c);
            }
        }

        if (setTicketIds.size() > 0) {
            // W-000108
            TicketUtil.closeTicketBasedOnConditions(setTicketIds);
        }
    }

    /**
    * @Method       : checkCustomerResponseClosureEctionExecutorRole
    * @Description  : Complaint Customer Response should be completed using Complaint Investigator (Quality_Complaint)
    *                 Inquiry Customer Response should be completed using Quality non Complaint (Quality_non_Complaint)
    * @Return       : N/A, but adds errors for CR records. Message stored in "Customer_Response_Insufficient_Access_message"
    * @Params       : Map<Id, Customer_Response__c> customerResponsesNewMap
    *               : Map<Id, Customer_Response__c> customerResponsesOldMap
    **/
    private static void checkCustomerResponseClosureEctionExecutorRole(Map <Id, Customer_Response__c> customerResponsesNewMap, Map <Id, Customer_Response__c> customerResponsesOldMap) {
        ADD_App_Settings__c addAppSettings = ADD_App_Settings__c.getValues(UserInfo.getUserId());
        if (addAppSettings == null || (null != addAppSettings && !addAppSettings.Restrict_Validation_Rules__c)) {
            List <Id> userGroupsIds = new List <Id> ();
            List <GroupMember> userGroupMemberships = [
                    SELECT GroupId
                    FROM GroupMember
                    WHERE UserOrGroupId = :UserInfo.getUserId()
            ];
            for (GroupMember userGroupMembership : userGroupMemberships) {
                userGroupsIds.add(userGroupMembership.GroupId);
            }
            List <Group> userGroups = [
                    SELECT DeveloperName
                    FROM Group
                    WHERE Id IN :userGroupsIds
            ];
            List <String> userGroupsNames = new List <String> ();
            for (Group userGroup : userGroups) {
                userGroupsNames.add(userGroup.DeveloperName);
            }
            //IPDR-749
            Id currentUserId = UserInfo.getUserId();
            Set<String> currentUserPermissionSetNames = new Set<String>();
            String QCA_PermissionSet = Label.Quality_Complaint_Approver;
            //This check ensures that the permission set query runs only once per transaction, avoiding repeated SOQL 
            //calls during test execution where the method may be invoked multiple times.
            if(permSetList == null || permSetList.isEmpty()){
                permSetList = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :currentUserId];
            }
            for (PermissionSetAssignment psa : permSetList) {
                currentUserPermissionSetNames.add(psa.PermissionSet.Name);
            }
            Boolean isQualityApproverUser = currentUserPermissionSetNames.contains(QCA_PermissionSet);
            //IPDR-749
            for (Id crId : customerResponsesNewMap.keySet()) {
                String newWFStatus = customerResponsesNewMap.get(crId).CMPL123_WF_Status__c;
                String oldWFStatus = customerResponsesOldMap.get(crId).CMPL123_WF_Status__c;
                if (String.isNotBlank(newWFStatus)
                    && (newWFStatus != oldWFStatus)
                    && (newWFStatus.contains('Closed') && !newWFStatus.contains('Voided'))
                ) {
                    // R3.1, Larry: Replaced switch-statement with a Map
                    String ticketType = customerResponsesNewMap.get(crId).Parent_Record_Type__c;
                    String groupToCheck = TICKET_TYPE_TO_GROUP_NAME.get(ticketType);
                    if (String.isNotBlank(groupToCheck) && !userGroupsNames.contains(groupToCheck)) {
                        if(!isQualityApproverUser){
                            customerResponsesNewMap.get(crId).addError(System.label.Customer_Response_Insufficient_Access_message);
                        }
                    }
                }
            }
        }
        if(permSetList != null && permSetList.size()>0){
            //permSetList.clear();
        }
    }

    /*
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on Customer Response.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void executeLogicFromWFRules() {
        List<Customer_Response__c> newList = (List<Customer_Response__c>) Trigger.new;
        Map<Id, Customer_Response__c> oldMap = (Map<Id, Customer_Response__c>) Trigger.oldMap;

        for (Customer_Response__c newCR :newList) {
            Boolean wfStatusIsChanged = Trigger.isInsert || (Trigger.isUpdate && newCR.CMPL123_WF_Status__c != oldMap.get(newCR.Id).CMPL123_WF_Status__c);
            Boolean wfActionIsChanged = Trigger.isInsert || (Trigger.isUpdate && newCR.CMPL123_WF_Action__c != oldMap.get(newCR.Id).CMPL123_WF_Action__c);

            if (wfStatusIsChanged) {
                //  Clear approve by and on fields when back to Opened status
                //  Clear responded by and on fields when back to Opened status
                if (newCR.CMPL123_WF_Status__c == AspenConstants.STR_Opened) {
                    newCR.Follow_up_Status__c = '';
                    newCR.Responded_By_New__c = null;
                    newCR.Responded_On__c = null;
                    newCR.Responded_Info_on_Labeling_By__c = null;
                    newCR.Responded_Info_on_Labeling_On__c = null;
                    newCR.Quality_Approve_By__c = null;
                    newCR.Quality_Approve_Response_On__c = null;
                    newCR.Regulatory_Approve_By__c = null;
                    newCR.Regulatory_Approve_On__c = null;
                    newCR.Routed_for_Approval_By_New__c = null;
                    newCR.Routed_for_Approval_On__c = null;
                    newCR.Technical_Approve_By__c = null;
                    newCR.Technical_Approve_On__c = null;
                }

                //  Clear reject and reopened by and on fields when in Closed - Done status
                else if (newCR.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done) {
                    newCR.Reject_By__c = null;
                    newCR.Reject_Response_On__c = null;
                    newCR.Rejection_Reason__c = null;
                    newCR.Reopened_By_New__c = null;
                    newCR.Reopened_On__c = null;
                }
            }

            if (wfActionIsChanged) {
                DateTime actionPerformedOn = DateTime.now();
                String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

                //  Autoset Follow Up Status to Responded Info on Labeling
                //  Autoset By and On Fields 2
                if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Responded_Info_On_Labeling) {
                    newCR.Follow_up_Status__c = 'Responded Info in Labeling';
                    newCR.Responded_Info_on_Labeling_By__c = actionPerformedBy;
                    newCR.Responded_Info_on_Labeling_On__c = actionPerformedOn;
                }

                //  Autoset Follow Up Status to Responded
                //  Autoset By and On Fields 2
                else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Responded) {
                    newCR.Follow_up_Status__c = 'Responded';
                    newCR.Responded_By_New__c = actionPerformedBy;
                    newCR.Responded_On__c = actionPerformedOn;
                }

                //  Autoset By and On Fields 2
                else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Process_Team_Approval) {
                    newCR.Routed_for_Approval_By_New__c = actionPerformedBy;
                    newCR.Routed_for_Approval_On__c = actionPerformedOn;
                }

                //  Autoset By and On Fields 2
                else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void) {
                    newCR.Voided_By_New__c = actionPerformedBy;
                    newCR.Voided_On__c = actionPerformedOn;
                }

                //  Autoset By and On Fields
                else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Reopen) {
                    newCR.Reopened_By_New__c = actionPerformedBy;
                    newCR.Reopened_On__c = actionPerformedOn;
                }

                //  Autoset By and On Fields
                else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Quality_Approve_Response
                        || (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Responded
                            && newCR.Quality_Approve_By__c == null)) {
                    newCR.Quality_Approve_By__c = actionPerformedBy;
                    newCR.Quality_Approve_Response_On__c = actionPerformedOn;
                }

                //  Autoset By and On Fields
                else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Regulatory_Approve
                        || (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Responded
                            && null != newCR.Additional_Approvals__c
                            && newCR.Additional_Approvals__c.contains('Regulatory Approval')
                            && newCR.Regulatory_Approve_By__c == null)) {
                    newCR.Regulatory_Approve_By__c = actionPerformedBy;
                    newCR.Regulatory_Approve_On__c = actionPerformedOn;
                }

                //  Autoset By and On Fields
                else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Quality_Reject
                        || newCR.CMPL123_WF_Action__c == AspenConstants.STR_Tech_Reject
                        || newCR.CMPL123_WF_Action__c == AspenConstants.STR_Regulatory_Reject) {
                    newCR.Reject_By__c = actionPerformedBy;
                    newCR.Reject_Response_On__c = actionPerformedOn;
                }

                //  Autoset By and On Fields
                else if (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Tech_Approve
                        || (newCR.CMPL123_WF_Action__c == AspenConstants.STR_Responded
                            && null != newCR.Additional_Approvals__c
                            && newCR.Additional_Approvals__c.contains('Tech Approval'))
                            && newCR.Technical_Approve_By__c == null) {
                    newCR.Technical_Approve_By__c = actionPerformedBy;
                    newCR.Technical_Approve_On__c = actionPerformedOn;
                }
            }
        }
    }

    /**
     * Prepares Translation Items to be voided due to Customer Responses getting voided.
     * 
     * This method is meant for an After-Update trigger context.
     * This method expects executeLogicFromWFRules to run first (which is in Before-Update).
     * @param triggerNewList Same as Trigger.new. Can be empty, but never null
     * @param triggerOldMap Same as Trigger.oldMap. Can be empty or null
     * @return All Translation Items that need updated. Can be empty, but never null
     * @author Larry Resnik
     * @date 23-MAY-2023
     */
    @testVisible
    private static Map<Id, Translation_Item__c> prepTranslationItemsForVoiding(
        List<Customer_Response__c> triggerNewList,
        Map<Id, Customer_Response__c> triggerOldMap
    ) {
        // Determine which Customer Responses have just been voided
        List<Id> newlyVoidedResponseIdList = new List<Id>();
        for (Customer_Response__c respNew : triggerNewList) {
            Customer_Response__c respOld = triggerOldMap?.get(respNew.Id);
            Boolean isInsertContext = triggerOldMap == null;
            Boolean isStatusChangedToVoid =
                respNew.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void && (
                    isInsertContext ||
                    respNew.CMPL123_WF_Action__c != respOld.CMPL123_WF_Action__c
                );
            if (isStatusChangedToVoid) {
                newlyVoidedResponseIdList.add(respNew.Id);
            }
        }

        Map<Id, Translation_Item__c> updatableTransItemToRecord =
            new Map<Id, Translation_Item__c>();
        if (newlyVoidedResponseIdList.isEmpty()) {
            // Abort early to avoid SOQL
            return updatableTransItemToRecord;
        }

        // Find all applicable Translation Items, then prepare them to be voided.
        // R3.1, dry run defect #30, Larry: Now excludes Translation Items whose
        // parent Translation Tasks are locked
        for (Translation_Item__c transItem : [
            SELECT Id, Translated__c, Related_Record_Id__c, Is_Voided__c
            FROM Translation_Item__c
            WHERE Related_Record_Id__c IN :newlyVoidedResponseIdList AND
            Translation_Task__r.CMPL123_WF_Status__c NOT IN :TRANS_TASK_LOCKED_WF_STATUSES
            WITH SECURITY_ENFORCED
        ]) {
            transItem.Is_Voided__c = true;

            // Put default text into the translation only if the translation is empty.
            //
            // The translation will be blank if the following actions happen in order:
            // 1. The CSV of Translation Items is emailed to the translator.
            // 2. This Customer Response is voided. Implies the upcoming if-statement condition PASSES.
            // 3. The CSV is returned by the translator. Translation Items are unchanged since we set Is_Voided__c here.
            //
            // The translation to be pre-filled if the following actions happen in order:
            // 1. The CSV of Translation Items is emailed to the translator.
            // 2. The CSV is returned by the translator. Translation Items get Translated__c filled.
            // 3. This Customer Response is voided. Implies the upcoming if-statement condition FAILS.
            if (String.isBlank(transItem.Translated__c)) {
                String runningUser = 'via Automation';
                // Note that this string template should match logic from TicketTranslation.page
                transItem.Translated__c = String.format('{0}, {1}, {2}',
                    new Object[]{
                        ADDUtil.formatDateTicketTranslation(System.today()),
                        runningUser,
                        AspenConstants.TRANSLATION_NOT_NEEDED
                    }
                );
            }
            updatableTransItemToRecord.put(transItem.Id, transItem);
        } // end of for (Translation_Item__c transItem : [

        return updatableTransItemToRecord;
    }
}