/**
 * Class to Handle Different scenarios from Ticket Trigger.
 * @createdDate:    2018-07-11
 * @copyright (c): (2018 - 2019) Abbott CHaRM , Incorporated. All rights are reserved.
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID             Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   rsitc                    9-April-2020           Def #66 fix                 Removed Customer Response Wf Rule reassignment.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   DSkak                    04-06-2020             Code Audit                  Removed 'System.debug()'.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   rsitc                    27-May-2020            #123/CHARM-2729             Added isTicketInserting to avoid multiple ticket updates
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    15-06-2020             Code Audit                  Removed commented code. Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                      16-NOV-2020            Defect #62 / CHARM-3356     Fixed typo in 'createTranslationTaskWhenTicketConverts()' method name.
 *                                                                                   Added loop and condition from the method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                      22-DEC-2020            Upgrade issue #41           Adjusted moveChildrenOpenToClose method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oober                      28-DEC-2020            TWD Upgrade Issue           Added logic to beforeEventHandler method to move
 *                                                                               Complaint WF Rules to Apex code.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                      14-JAN-2021            Upgrade issue #84           Adjusted 123 assignment for Service.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Lakshman                   22-JAN-2021            Defect1 issue               Set Ready to close for ComplaintResponded
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik               02-FEB-2023            CHaRM R3.0 IPDR 482          Now sets the new "Previously Closed as Service Ticket" flag
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar(COE)          01-Jun-2023            CHARM R3.1 IPDR 506          Created a New method "beforeUpdateComplaintDateFields" To 
                                                                                  Update "Original Ticket Close Date" field in Complaint Ticket 
                                                                                  when a Ticket is "Closed-Done" for the first Time After the Release of
                                                                                  Charm 3.1 to Production. And update 
                                                                                  "Last Reopened date" field with current date in Complaint ticket 
                                                                                  when ever a Ticket is reopened.
                                                                                  Also updated method "isBeforeUpdate" to call new method 
                                                                                  "beforeUpdateComplaintDateFields"  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar               22-JUL-2024            CHARM R5/IPDR 580            Updated the afterEventHandler method
 * -------------------------------------------------------------------------------------------------------------------------------------- 
 * Dinesh Kumar               12-NOV-2024            CHARM R5/BTSIT09980/IPDR695  Updated the afterEventHandler method
 * -------------------------------------------------------------------------------------------------------------------------------------- 
 **/
public with sharing class ComplaintTriggerHandler {
    public static String inquiryCustomerResponseKeyValue = 'Inquiry_Customer_Response';
    public static String complaintCustomerResponseKeyValue = 'Complaint_Customer_Response';
    public static Boolean executingThroughInvokable = false;
    public static Boolean TTFlag = false;   // 30JAN19 - AQC#111 - Fix for CPU Time Limit error for non-english Country
    static String cmsnextTicketNumber = ''; // 14FEB19 - AQC#120 - Fix for CPU Time Limit error for non-english Country
    public static Boolean ticketVersionUpdated = false;
    public static Boolean systemProdEval = false;
    public static Boolean systemMedEval = false;
    public static Boolean customCustomerResponse = false;
    static Map<String,String> recordTypeNameWithIdMap;
    static String investigationRuleKeyValue = 'PRODEVAL_WORKFLOW';
    static String investigationAMDRuleKeyValue = 'PRODEVAL_WORKFLOW_AMD';
    static String assessmentRuleKeyValue = 'MEDICAL_EVALUATION_WORKFLOW';
    static final String customerResponseAPI = 'Customer_Response__c';
    static Map<String,String> recordTypesWithKeyValue = new Map<String,String>{'Service' => 'SERVICE_WORKFLOW', 'Inquiry' => 'INQUIRY_WORKFLOW', 'Complaint' => 'COMPLAINT_WORKFLOW'};
    static Map<String,String> queueWithIdMap;

    // 28FEB19 - DEF#280 and DEF#374 - Fix for TriggerOldMap
    public static Set<String> updatedFieldsSet = new Set<String>();

     //Recursion Handler
    public static Boolean executeOnceBeforeInsert = false;
    public static Boolean executeOnceBeforeUpdate = false;
    public static Boolean executeOnceAfterInsert = false;
    public static Boolean executeOnceAfterUpdate = false;
    // Defect #123/CHARM-2729: added isTicketInserting to avoid ticket update during its insert from UpdateParentUtility.updateparent()
    public static Boolean isTicketInserting = false;

    private static Boolean executeOnceBeforeUpdateOnceCheck = false; //18APR19 - void if all mdc Inquiry fix
    private static Boolean executeOnceClosedVoidComplaint = false; //06MAY19 - void if all mdc Inquiry fix

    public static Boolean updateTicketVersionCloseDateOnceCheck = false; //15May19 - #946 - Ticket Version Closed Date Fix

    //Static boolean variable to call record locked validation only once.
    public static Boolean excecuteRecodLockOnlyOnce = false;

    //Static boolean variable to stop update on ticket from translation task when ticket is also modified in same transaction
    //defect #1394, #1395
    public static Boolean isTicketUpdated = false;

    public static Boolean isCRReopened = false;
    public static Boolean isCRVoided = false;
    public static Boolean isTTReopened = false;

    //Before Insert Trigger Event Handling Common Method
    public static void isBeforeInsert(){
        TicketUtil.addTrace('ComplaintTriggerHandler.isBeforeInsert');
        if(!executeOnceBeforeInsert){
            executeOnceBeforeInsert = true;
            // Defect #123/CHARM-2729: avoid ticket update during its insert from UpdateParentUtility.updateparent()
            isTicketInserting = true; 
            beforeEventHandler();
        }
    }

    //After Insert Trigger Event Handling Common Method
    public static void isAfterInsert(){
        TicketUtil.addTrace('ComplaintTriggerHandler.isAfterInsert');
        if(!executeOnceAfterInsert){
            executeOnceAfterInsert = true;
            afterInsertEventHandler();
        }
    }

    //Before Update Trigger Event Handling Common Method
    public static void isBeforeUpdate(){
        // 30JAN19 - IssueID#170 - Fix for Child to Parent and Ready for Closure
        //if(TicketUpdateUtility.childToParentUpdateFlag) { return; } // 12APR19 - Commented for AutoPromotion DEF#285
        //Start - IPDR 506 - CHARM R3.1 - By Dinesh Kumar(COE)
        beforeUpdateComplaintDateFields((List<CMPL123CME__Complaint__c>)Trigger.new, (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap);
        //End - IPDR 506 - CHARM R3.1 - By Dinesh Kumar(COE)
        
        TicketUtil.addTrace('ComplaintTriggerHandler.isBeforeUpdate');
        if(!excecuteRecodLockOnlyOnce && UserInfo.getProfileId() != System.Label.Integration_Profile_ID){
            excecuteRecodLockOnlyOnce = true;
            TicketUtil.validateRecordLockOnClosedStatus((List<CMPL123CME__Complaint__c>)Trigger.new, (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap);
            setReopenRationale((List<CMPL123CME__Complaint__c>)Trigger.new, (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap);
        }

        if(!executeOnceBeforeUpdate){
            //executeOnceBeforeUpdate = true;   // 12APR19 - Commented for DEF#659
            beforeEventHandler();
        }

        //Defect #1541 fix BEGIN
        validateRCMLTasksStatusBeforeClosingTicket(
                (Map <Id, CMPL123CME__Complaint__c>) Trigger.newMap,
                (Map <Id, CMPL123CME__Complaint__c>) Trigger.oldMap
        );
        //Defect #1541 fix END

    }

    //After Update Trigger Event Handling Common Method
    public static void isAfterUpdate(){
        TicketUtil.addTrace('ComplaintTriggerHandler.isAfterUpdate' + updatedFieldsSet);

        // Added to avoid looping and unwanted processing
        // 30JAN19 - IssueID#170 - Fix for Child to Parent and Ready for Closure
        if(ADDProductTicketTriggerHandler.newPTFlag ||
          TicketUpdateUtility.childToParentUpdateFlag ||
          ADDMDCTicketTriggerHandler.MDCTriggerUpdateFlag ) {
            // MR 12APR19 - Added for AutoProtion Fix DEF#285
            if(updatedFieldsSet.contains('CMPL123CME__CMPL123_WF_Status__c') ||
               updatedFieldsSet.contains('MDC_All_ACKs_Received__c') ||
               updatedFieldsSet.contains('CMPL123Task_Key_Value__c')) {
                Set<Id> autoPromoteIds = new Set<Id>();
                for(CMPL123CME__Complaint__c obj: (List<CMPL123CME__Complaint__c>)Trigger.New) {
                    if(obj.Ticket_Type__c == 'Complaint' && obj.MDC_All_ACKs_Received__c) {
                        autoPromoteIds.add(obj.Id);
                    }
                }
                if(autoPromoteIds.size() > 0) {
                    updatedFieldsSet.clear();
                    TicketUpdateUtility.updateParentOnChildUpdate(autoPromoteIds);
                }
            }

            // 21APR19 - MR - Commented below need to confirm with Teertha
            // 23APR19 - Parent to child void fix since it was not working from recursion handler - This is required - Teertha
            if(ADDMDCTicketTriggerHandler.MDCTriggerUpdateFlag && !executeOnceClosedVoidComplaint){
                List<CMPL123CME__Complaint__c> newComplaints = (List<CMPL123CME__Complaint__c>)Trigger.New;
                Map<Id,CMPL123CME__Complaint__c> oldComplaintsMap = (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap;

                closedVoidAllRelatedChildren(newComplaints, oldComplaintsMap);
            }

            // 21APR19 after trigger must be executed atleast once
            if(executeOnceAfterUpdate) {
                TicketUtil.addTrace('ComplaintTriggerHandler.isAfterUpdate return due to executeOnceAfterUpdate');
                return;
            }
        }

        //23APR19 - #772 - Ticket Version Fix
        //When Ticket is reopened from CMSNext, version was not created, Issue from recursion handling
        if(!ticketVersionUpdated){
            createTicketVersionWhenReopen((List<CMPL123CME__Complaint__c>)Trigger.New);
        }

        //15May19 - #946 - Ticket Version Closed Date Fix - logic added in Code from Process Builder "Update Ticket Version"
        if(!updateTicketVersionCloseDateOnceCheck){
            updateTicketVersionClosedDate((List<CMPL123CME__Complaint__c>)Trigger.New, (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap);
        }

        if(!executeOnceAfterUpdate){
            executeOnceAfterUpdate = true;
            afterEventHandler();
        }
    }

    //Before Trigger Event Handling Common Method
    public static void beforeEventHandler() {
        TicketUtil.addTrace('ComplaintTriggerHandler.beforeEventHandler. Ticket Id - ' + Trigger.New[0].Id);
        //W-1307
        List<CMPL123CME__Complaint__c> newComplaints = (List<CMPL123CME__Complaint__c>)Trigger.New;
        Map<Id,CMPL123CME__Complaint__c> oldComplaintsMap = (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap;

        if(recordTypeNameWithIdMap == null){
            recordTypeNameWithIdMap = new Map<String,String>();
            for(RecordType rt : [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType Where SobjectType  = 'CMPL123CME__Complaint__c']){
                recordTypeNameWithIdMap.put(rt.Name, rt.Id);
                recordTypeNameWithIdMap.put(rt.Id,rt.Name);
            }
        }

        for(CMPL123CME__Complaint__c complaint : newComplaints){
            //To update ticket Reportable Date Added:30/01/2019
            if(Trigger.isUpdate &&
              String.isNotBlank(complaint.Overall_Reportable_Status__c) &&
              oldComplaintsMap.containsKey(complaint.Id) &&
              complaint.Overall_Reportable_Status__c != oldComplaintsMap.get(complaint.Id).Overall_Reportable_Status__c) {
                complaint.Reportable_Date__c = System.today();
                updatedFieldsSet.add('Overall_Reportable_Status__c');   //  28FEB19 - Trigger.oldMap Issue
            }

            if(complaint.Ticket_Type__c == null){
                complaint.Ticket_Type__c = recordTypeNameWithIdMap.get(complaint.RecordTypeId);
            }
            if(complaint.Ticket_Type__c != null &&
              recordTypeNameWithIdMap != null &&
              (Trigger.isInsert || (oldComplaintsMap != null  && complaint.Ticket_Type__c != oldComplaintsMap.get(complaint.Id).Ticket_Type__c)) &&
              recordTypeNameWithIdMap.get(complaint.Ticket_Type__c) != null) {
                complaint.RecordTypeId = recordTypeNameWithIdMap.get(complaint.Ticket_Type__c);
                complaint.CMPL123Rule_Key_Value__c = recordTypesWithKeyValue.get(complaint.Ticket_Type__c);
                if(Trigger.isUpdate){
                    updatedFieldsSet.add('Ticket_Type__c');   //  28FEB19 - Trigger.oldMap Issue
                }
            }

             if(Trigger.isUpdate && !executeOnceBeforeUpdateOnceCheck && (complaint.CMSNext__c != oldComplaintsMap.get(complaint.Id).CMSNext__c || complaint.MDC_All_ACKs_Received__c != oldComplaintsMap.get(complaint.Id).MDC_All_ACKs_Received__c || complaint.Med_Evaluator_Pending_MDCs__c != oldComplaintsMap.get(complaint.Id).Med_Evaluator_Pending_MDCs__c)) {
                if(complaint.CMSNext__c == 'Void' && complaint.Ticket_Type__c == 'Inquiry' && complaint.MDC_All_ACKs_Received__c) { //16APR19 - #690 Inquiry should close void only when all ACKs Recieved
                    complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided';
                    //complaint.CMPL123Task_Key_Value__c = 'voidInquiryCMSNext';
                } else if(complaint.CMSNext__c == 'Void' && complaint.Ticket_Type__c != 'Inquiry' && !complaint.Med_Evaluator_Pending_MDCs__c && complaint.CMPL123CME__CMPL123_WF_Status__c != 'Closed-Voided') {
                    complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided';
                }
            }

            //Added -by Amit W-000129 - 10/08/2018
            if(Trigger.isUpdate && complaint.CMSNext__c != oldComplaintsMap.get(complaint.Id).CMSNext__c) {
                updatedFieldsSet.add('CMSNext__c'); //  28FEB19 - Trigger.oldMap Issue
                // 06MAY2019 - #884, #885 - Reopen multiple times issue fix
                if(complaint.CMSNext__c == 'Closed'){
                    complaint.CMPL123CME__CMPL123_WF_Action__c = '';
                }
            }

            //Added on 16 APR 2019 (Defect - 693)
            if(Trigger.isUpdate && complaint.Ticket_Type__c == 'Inquiry' && complaint.CMPL123CME__CMPL123_WF_Action__c != oldComplaintsMap.get(complaint.Id).CMPL123CME__CMPL123_WF_Action__c && (complaint.CMPL123CME__CMPL123_WF_Action__c == 'Close' || complaint.CMPL123CME__CMPL123_WF_Action__c == 'Void')){

                if((!updatedFieldsSet.contains('CMSNext__c') && complaint.CMSNext__c == oldComplaintsMap.get(complaint.Id).CMSNext__c) && (complaint.Adhoc_Quality_Non_Complaint_Pending_MDCs__c == True || complaint.Quality_Non_Complaint_Pending_MDCs__c == True)){
                    complaint.addError(System.label.Cannot_close_Inquiry);
                }
            }

            //Added - W-000129 - 10/08/2018

            // AQC#354 Added below condition check for CPU time reduction
            if(Trigger.isUpdate &&
              complaint.Translation_Required_flag__c != oldComplaintsMap.get(complaint.Id).Translation_Required_flag__c &&
              complaint.Translation_Required_flag__c == true) {
                  updatedFieldsSet.add('Translation_Required_flag__c');
                List<Translation_Task__c> ttList = new List<Translation_Task__c>([SELECT Id, Name, Parent_Ticket__c
                                           FROM Translation_Task__c
                                           WHERE Parent_Ticket__c = :complaint.Id
                                           AND Recordtype.Name = 'Text Translation'
                                           AND (CMPL123_WF_Status__c = 'Opened' OR CMPL123_WF_Status__c= 'In Process')]);
                  if(ttList.size() > 0){
                      complaint.addError(System.label.Ticket_Translation_Task_Exists);
                  }
            }

            // 28FEB19 - DEF#280 and DEF#374 - Fix for TriggerOldMap
            if(Trigger.isUpdate) {
                CMPL123CME__Complaint__c oldComplaint = oldComplaintsMap.get(complaint.Id);
                if (complaint.RecordTypeId != oldComplaint.RecordTypeId) {
                    updatedFieldsSet.add('RecordTypeId');
                }
                if(complaint.Reply_Expectation__c != oldComplaint.Reply_Expectation__c) {
                    updatedFieldsSet.add('Reply_Expectation__c');
                }
                if(complaint.Customer_Reply_Required__c != oldComplaint.Customer_Reply_Required__c) {
                    updatedFieldsSet.add('Customer_Reply_Required__c');
                }
                if(complaint.Follow_up_Status__c != oldComplaint.Follow_up_Status__c) {
                    updatedFieldsSet.add('Follow_up_Status__c');
                }
                if(complaint.pRE_Status__c != oldComplaint.pRE_Status__c) {
                    updatedFieldsSet.add('pRE_Status__c');
                }
                if(complaint.CMPL123CME__CMPL123_WF_Action__c != oldComplaint.CMPL123CME__CMPL123_WF_Action__c) {
                    updatedFieldsSet.add('CMPL123CME__CMPL123_WF_Action__c');
                    // 17MAR19 - DEF#285 - Fix to perform FRA to Closed-Done
                    if(complaint.CMPL123CME__CMPL123_WF_Action__c == 'Submit for Final Review'
                      && complaint.Division__c == 'ADD'
                      && complaint.MDC_All_ACKs_Received__c) {
                        complaint.CMPL123Task_Key_Value__c = 'addautofra';
                    }
                }

                // DEF#1472 fix
                if (!executeOnceBeforeUpdateOnceCheck
                        && complaint.CMSNext__c == oldComplaint.CMSNext__c
                        && complaint.CMPL123CME__CMPL123_WF_Action__c  == 'Reopen'
                        && complaint.CMPL123CME__CMPL123_WF_Action__c  != oldComplaint.CMPL123CME__CMPL123_WF_Action__c) {
                    //W-000084 - Start (DevCycle 7 - when system Reopens the Ticket)
                    complaint.Reopen_Rationale__c = 'Automatically reopened by the CHaRM System.';
                }

                // 30APR2019 - 703,704 - Moved form After Update to Before Update to fix CPU Time limit error
                // Logic to reopen the Ticket
                if(complaint.CMSNext__c == 'Open' && complaint.CMSNext__c != oldComplaint.CMSNext__c
                        && (complaint.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done' || complaint.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Voided')){
                    // && (complaint.Ticket_Type__c == 'Complaint' || complaint.Ticket_Type__c == 'Inquiry') - Commented for Reopening Service Tickets
                    if(complaint.Ticket_Type__c == 'Complaint'){
                        //03MAY2019 - #873 ticket covert and reopen at same time fix
                        if(complaint.Ticket_Type__c == oldComplaint.Ticket_Type__c){
                            complaint.CMPL123Task_Key_Value__c = (complaint.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done' ? 'ReopenClosedComplaint' : 'ReopenVoidCompalint');
                        }

                    } else if(complaint.Ticket_Type__c == 'Inquiry'){
                        //03MAY2019 - #873 ticket covert and reopen at same time fix
                        if(complaint.Ticket_Type__c == oldComplaint.Ticket_Type__c){
                            complaint.CMPL123Task_Key_Value__c = (complaint.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done' ? 'openInquiryClose' : 'openInquiryVoided');
                        }
                    } else if (complaint.Ticket_Type__c == 'Service' // Upgrade issue #84: adjusted 123 assignment for Service
                                && complaint.Ticket_Type__c == oldComplaint.Ticket_Type__c) {
                        complaint.CMPL123Task_Key_Value__c = (complaint.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done' ? 'reopenServiceClosed' : 'reopenServiceVoided');
                    }
                    if(complaint.Reopen_Rationale__c == null && (complaint.Ticket_Type__c == 'Complaint' || complaint.Ticket_Type__c == 'Inquiry')){
                        complaint.Reopen_Rationale__c.addError(System.label.Ticket_Reopen_rationale_Required);
                    }
                }
                // 30APR2019 - 703,704 - Moved form After Update to Before Update to fix CPU Time limit error

                // Def 1635 fix start
                if (complaint.CMSNext__c == 'Open' && complaint.CMSNext__c != oldComplaint.CMSNext__c
                        && complaint.CMPL123CME__CMPL123_WF_Status__c == 'Registration Closed'
                        && complaint.Ticket_Type__c == 'Complaint'
                        && complaint.Ticket_Type__c == oldComplaint.Ticket_Type__c) { // Avoid ticket convert and reopen at same time recycling
                        complaint.CMPL123Task_Key_Value__c = 'REOPENRCTICKET';
                }
                // Def 1635 fix end

                if(complaint.CMPL123CME__CMPL123_WF_Status__c != oldComplaint.CMPL123CME__CMPL123_WF_Status__c) {
                    updatedFieldsSet.add('CMPL123CME__CMPL123_WF_Status__c');
                    // 17MAR19 - DEF#509 - Fix to reset the Ready_to_Close__c flag
                    if(complaint.CMPL123CME__CMPL123_WF_Status__c == 'Opened') {
                        complaint.Ready_to_Close__c = 'No';
                        complaint.CMPL123Task_Key_Value__c = '';    // 12APR19 Generic fix for Task Key Value
                    }
                }
                // 27MAR19 - Added the following flags for MDC All Acks - DEF#520 Fix
                if(complaint.Evaluator_Investigator_Pending_MDCs__c != oldComplaint.Evaluator_Investigator_Pending_MDCs__c) {
                    updatedFieldsSet.add('Evaluator_Investigator_Pending_MDCs__c');
                    updatedFieldsSet.add('MDC_All_ACKs_Received__c');   // 27MAR19 DEF#508/509
                }
                if(complaint.FA_Quality_Assignee_Pending_MDCs__c != oldComplaint.FA_Quality_Assignee_Pending_MDCs__c) {
                    updatedFieldsSet.add('FA_Quality_Assignee_Pending_MDCs__c');
                    updatedFieldsSet.add('MDC_All_ACKs_Received__c');   // 27MAR19 DEF#508/509
                }
                if(complaint.Med_Evaluator_Pending_MDCs__c != oldComplaint.Med_Evaluator_Pending_MDCs__c) {
                    updatedFieldsSet.add('Med_Evaluator_Pending_MDCs__c');
                    updatedFieldsSet.add('MDC_All_ACKs_Received__c');   // 27MAR19 DEF#508/509
                }
                if(complaint.Prod_Eval_Assessor_Pending_MDCs__c != oldComplaint.Prod_Eval_Assessor_Pending_MDCs__c) {
                    updatedFieldsSet.add('Prod_Eval_Assessor_Pending_MDCs__c');
                    updatedFieldsSet.add('MDC_All_ACKs_Received__c');   // 27MAR19 DEF#508/509
                }
                if(complaint.Quality_Non_Complaint_Pending_MDCs__c != oldComplaint.Quality_Non_Complaint_Pending_MDCs__c) {
                    updatedFieldsSet.add('Quality_Non_Complaint_Pending_MDCs__c');
                    updatedFieldsSet.add('MDC_All_ACKs_Received__c');   // 27MAR19 DEF#508/509
                }

                if(complaint.MDC_All_ACKs_Received__c != oldComplaint.MDC_All_ACKs_Received__c) {
                    updatedFieldsSet.add('MDC_All_ACKs_Received__c');
                }

                // 12APR19 - Added for Ticket Reopen VR Error Fix
                if(complaint.Reopen_Rationale__c != oldComplaint.Reopen_Rationale__c){
                    updatedFieldsSet.add('Reopen_Rationale__c');
                }

                if(complaint.CMPL123Task_Key_Value__c != oldComplaint.CMPL123Task_Key_Value__c) {
                    updatedFieldsSet.add('CMPL123Task_Key_Value__c');
                }

                executeOnceBeforeUpdateOnceCheck = true;

                // 03-FEB-2023 Larry: Moved this block of logic to a dedicated function
                doWorkflowRules(oldComplaint, complaint);
            } //end of if (Trigger.isUpdate)

            //Update pRE to Yes Date WF Rule (before insert)
            if(complaint.pRE_Status__c != null && Trigger.isInsert && complaint.pRE_Status__c == 'Yes') {
                complaint.pRE_to_Yes_Date__c = Date.today();
            }

            //Move SFDC WF Rules to Apex code END
        } //end of for(CMPL123CME__Complaint__c complaint : newComplaints)
    }

    public static void afterInsertEventHandler() {
        TicketUtil.addTrace('ComplaintTriggerHandler.afterInsertEventHandler. Ticket Id - ' + Trigger.New[0].Id);
        List<sObject> newRecords = new List<sObject>();
        List<sObject> updatableRecords = new List<sObject>();

        for(CMPL123CME__Complaint__c complaint : (List<CMPL123CME__Complaint__c>)Trigger.New) {
            CMPL123CME__Complaint__c updatableComplaint = new CMPL123CME__Complaint__c();
            // Create Customer Response
            if(complaint.Customer_Reply_Required__c && !complaint.Is_Custom_response_child_created__c && !customCustomerResponse) {
                if(complaint.Ticket_Type__c == 'Inquiry'){
                    newRecords.add(createCustomerResponse(complaint.id, inquiryCustomerResponseKeyValue, 'Inquiry', complaint.CMSNext_Ticket_Number__c, complaint.Reply_Expectation__c));
                }
                if(complaint.Ticket_Type__c == 'Complaint'){
                    newRecords.add(createCustomerResponse(complaint.id, complaintCustomerResponseKeyValue, 'Complaint', complaint.CMSNext_Ticket_Number__c, complaint.Reply_Expectation__c));
                }
                updatableComplaint.id = complaint.Id;
                updatableComplaint.Is_Custom_response_child_created__c = true;
                customCustomerResponse = true;
            }

            // Create System Prod Eval
            // Removed Process Builder and Added in apex to avoid looping
            if(!systemProdEval && complaint.Ticket_Type__c == 'Complaint' && !complaint.Is_Product_Evaluation_Investigation_chil__c) {
                CMPL123CME__Investigation__c investigation = createInvestigation(
                        complaint.Id, investigationRuleKeyValue, complaint.Division__c, complaint.Registration_Ticket__c
                );
                newRecords.add(investigation);
                updatableComplaint.Id = complaint.Id;
                updatableComplaint.Is_Product_Evaluation_Investigation_chil__c = true;
                // Def #1577 fix
                updatableComplaint.Product_Evaluation_Start_Date__c = investigation.Created_Date__c;
                systemProdEval = true;
            }

            //Create Med Eval
            if(complaint.pRE_Status__c == 'Yes' && (complaint.Ticket_Type__c == 'Service' || complaint.Ticket_Type__c == 'Complaint')){
                if(!complaint.Is_Medical_Evaluation_child_created__c) {
                    newRecords.add(createAssessment(complaint.Id, complaint.Ticket_Receipt_Date__c, assessmentRuleKeyValue));
                    updatableComplaint.Id = complaint.Id;
                    updatableComplaint.Is_Medical_Evaluation_child_created__c = true;
                    systemMedEval = true;
                }
            }

            // Ticket Version Code for newly created Ticket Record
            newRecords.add(new Ticket_Version__c(Ticket__c = complaint.Id, Version_number__c = 1,
                                                    Opened_By__c = userinfo.getName(),
                                                    Opened_Date__c = complaint.Ticket_origination_Date__c != null
                                                    ? complaint.Ticket_origination_Date__c.date()
                                                    : Date.today()
                                                ));

            // 14FEB19 - AQC#120 - Fix for CPU Time Limit error for non-english Country
            cmsnextTicketNumber = complaint.CMSNext_Ticket_Number__c;

            if(updatableComplaint.Id != null) {
                updatableRecords.add(updatableComplaint);
            }
        }

        // 14FEB19 - AQC#120 - Fix for CPU Time Limit error for non-english Country
        if(newRecords.size() > 0) {
            insert newRecords;      // 28FEB19 - DEF#280 and DEF#374 - Fix for TriggerOldMap
        }

        if(updatableRecords.size() > 0)
            update updatableRecords;
    }

    //After Trigger Event Handling Common Method
    public static void afterEventHandler() {
        TicketUtil.addTrace('ComplaintTriggerHandler.afterUpdateEventHandler');
        List<CMPL123CME__Complaint__c> newComplaints = (List<CMPL123CME__Complaint__c>)Trigger.New;
        Map<Id,CMPL123CME__Complaint__c> oldComplaintsMap = (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap;
        Map<Id,CMPL123CME__Complaint__c> newComplaintsMap = (Map<Id,CMPL123CME__Complaint__c>)Trigger.newMap;

        List<sObject> newRecords = new List<sObject>();
        List<sObject> updatableChildRecords = new List<sObject>();
        List<sObject> updatableComplaints = new List<sObject>();
        Set<String> eligibleTicketIds = new Set<String>();

        Map<String,List<Customer_Response__c>> complaintIdWithClosedCR = new Map<String,List<Customer_Response__c>>();
        try {
            if(queueWithIdMap == null){
                queueWithIdMap = new Map<String,String>();
                for(Group grp : [SELECT Id, Name, Type, DeveloperName FROM Group Where Type = 'Queue' AND (DeveloperName = 'Customer_Reply_Required' OR DeveloperName = 'Product_Quality_Queue' OR DeveloperName = 'Medical_eval_Assessment_Queue')]){
                    queueWithIdMap.put(grp.DeveloperName,grp.Id);
                }
            }

            for(CMPL123CME__Complaint__c queriedComplaint : [Select Id, Reply_Expectation__c, (Select Id,Ticket_Type__c,CMPL123_WF_Status__c,CMSNext_Ticket_Number__c,CMPL123Rule_Key_Value__c ,Customer_Expectation__c
                                                                            From Customer_Responses__r) From CMPL123CME__Complaint__c
                                                                Where Id IN : newComplaintsMap.keyset()]){
                                                                    complaintIdWithClosedCR.put(queriedComplaint.Id, queriedComplaint.Customer_Responses__r);
                //Added on 30/01/2019 - AQC#97 - Fix
                if(queriedComplaint.Reply_Expectation__c != oldComplaintsMap.get(queriedComplaint.Id).Reply_Expectation__c ||
                   updatedFieldsSet.contains('Reply_Expectation__c')) {  //  28FEB19 - Trigger.oldMap Issue

                    for(Customer_Response__c objCustResp : queriedComplaint.Customer_Responses__r){
                        if(objCustResp.CMPL123_WF_Status__c != 'Closed-Done' && objCustResp.CMPL123_WF_Status__c != 'Closed-Voided'){
                            objCustResp.Customer_Expectation__c = queriedComplaint.Reply_Expectation__c;
                            updatableChildRecords.add(objCustResp);
                        }
                    }
                }
            }

            //  Defect #62 fix START
            //Added - W-000313 - 28/09/2018 -Start
            // React to ticket conversions
            if (updatedFieldsSet.contains('Ticket_Type__c') || updatedFieldsSet.contains('Translation_Required_flag__c')
                    || updatedFieldsSet.contains('pRE_Status__c')
                    || updatedFieldsSet.contains('Customer_Reply_Required__c')) {
                Map<String, String> countryNameWithId = new Map<String, String>();

                for (Country__c country : [SELECT Id, Division__c, Name
                                            FROM Country__c
                                                WHERE Translations_Required_flag__c = TRUE]) {
                    countryNameWithId.put(country.Name + '-' + country.Division__c, country.Id);
                }

                Set<Id> setComplaintIds = new Set<Id>();

                for (CMPL123CME__Complaint__c ticket : newComplaints) {
                    Boolean ticketIsValid = ticket.CMPL123CME__CMPL123_WF_Status__c != AspenConstants.STR_Closed_Done
                            && ticket.CMPL123CME__CMPL123_WF_Status__c != AspenConstants.STR_Closed_Voided
                            && ticket.Country_of_origin__c != null
                            && (countryNameWithId.containsKey(ticket.Country_of_origin__c + '-' + ticket.Division__c)
                                || ticket.Translation_Required_flag__c == true)
                            && ((ticket.Translation_Required_flag__c == true
                                    && updatedFieldsSet.contains('Translation_Required_flag__c'))
                                || (ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Complaint)
                                    && updatedFieldsSet.contains('RecordTypeId'))
                                || (ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Service)
                                    && ticket.pRE_Status__c == AspenConstants.STR_Yes && updatedFieldsSet.contains('pRE_Status__c'))
                                || (ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Inquiry)
                                    && ticket.Customer_Reply_Required__c && updatedFieldsSet.contains('Customer_Reply_Required__c')));

                    if (ticketIsValid) {
                        setComplaintIds.add(ticket.Id);
                    }
                }

                if (!setComplaintIds.isEmpty()) {
                    ADDTranslations.createTranslationTaskWhenTicketConverts(setComplaintIds);
                }
            } // end of logic for react to ticket conversions
            //Added - W-000313 - 28/09/2018 -End
            //  Defect #62 fix END

            Set<Id> finalReviewIds = new Set<Id>();

            //Added - W-000108 - 07/08/2018
            Set<Id> setTicketIds = New Set<Id>();
            //Added - W-000108 - 07/08/2018

           // Added as Ready for closure
           Set<Id> readyForClosureTicketIdSet = new Set<Id>();
           // Added as Ready for closure

            //Added - W-000104 - 19/08/2018
            Set<Id> setTicketIdsToCloseCustomerResponses = New Set<Id>();
            //Added - W-000104 - 19/08/2018

            // DEF #1526 fix
            Set<Id> setTicketIdsToReopenVoidedCRs = New Set<Id>();

            for(CMPL123CME__Complaint__c complaint : newComplaints) {
                try{
                    CMPL123CME__Complaint__c updatableComplaint = new CMPL123CME__Complaint__c();
                    if(complaint.Ticket_Type__c != 'Service') {
                        if(Trigger.isUpdate && complaint.Ticket_Type__c != oldComplaintsMap.get(complaint.Id).Ticket_Type__c) {
                            // 31JAN19 - Avoid updating newly create Customer Response and avoid updating closed customer response
                            for(Customer_Response__c CR : complaintIdWithClosedCR.get(complaint.Id)) {
                                //CHaRM-R5: Added the Ticket Type field to update in Customer Response
                                if(CR.CMPL123_WF_Status__c != 'Closed-Done' && CR.CMPL123_WF_Status__c != 'Closed-Voided') {
                                    updatableChildRecords.add(new Customer_Response__c(Id = CR.Id, CMPL123Rule_Key_Value__c = complaint.Ticket_Type__c == 'Complaint' ? complaintCustomerResponseKeyValue : inquiryCustomerResponseKeyValue, Ticket_Type__c = complaint.Ticket_Type__c == 'Complaint' ? 'Complaint' : 'Inquiry'));
                                }
                            }
                        }//CHaRM-R5: Added below logic as part of IPDR 695 fix to update Ticket Type field in Customer Response when Complaint's Ticket type is not equal to Customer Response's Ticket Type and 
                        //Customer Response is not equal to 'Closed-Done' or 'Closed-Voided'
                        else if(Trigger.isUpdate){
                            for(Customer_Response__c CR : complaintIdWithClosedCR.get(complaint.Id)) {
                                if(complaint.Ticket_Type__c != CR.Ticket_Type__c)
                                {
                                    if(CR.CMPL123_WF_Status__c != 'Closed-Done' && CR.CMPL123_WF_Status__c != 'Closed-Voided') {
                                        updatableChildRecords.add(new Customer_Response__c(Id = CR.Id, CMPL123Rule_Key_Value__c = complaint.Ticket_Type__c == 'Complaint' ? complaintCustomerResponseKeyValue : inquiryCustomerResponseKeyValue, Ticket_Type__c = complaint.Ticket_Type__c == 'Complaint' ? 'Complaint' : 'Inquiry'));
                                    }
                                }
                            }
                        }

                        // DEF #1526 fix - Start
                        if(Trigger.isUpdate && complaint.Customer_Reply_Required__c == true
                                && updatedFieldsSet.contains('Customer_Reply_Required__c')) {
                            setTicketIdsToReopenVoidedCRs.add(complaint.Id);
                        }
                        // DEF #1526 fix - End

                        // DEF 1606 fix (Reopen voided CR when the Service Ticket is promoted back to a Complaint Ticket) - Start
                        if(Trigger.isUpdate && complaint.Ticket_Type__c == 'Complaint'
                                && updatedFieldsSet.contains('Ticket_Type__c') && complaint.Customer_Reply_Required__c
                                && !setTicketIdsToReopenVoidedCRs.contains(complaint.Id)) {
                            setTicketIdsToReopenVoidedCRs.add(complaint.Id);
                        }
                        // DEF 1606 fix - End
                        //W-1308
                        if(Trigger.isUpdate && complaint.Customer_Reply_Required__c && !complaint.Is_Custom_response_child_created__c
                                && !customCustomerResponse && updatedFieldsSet.contains('Customer_Reply_Required__c')
                                && complaintIdWithClosedCR.get(complaint.Id).isEmpty()) {        //  28FEB19 - Trigger.oldMap Issue
                            if(complaint.Ticket_Type__c == 'Inquiry'){
                                newRecords.add(createCustomerResponse(complaint.id, inquiryCustomerResponseKeyValue, 'Inquiry', complaint.CMSNext_Ticket_Number__c, complaint.Reply_Expectation__c));
                            }
                            if(complaint.Ticket_Type__c == 'Complaint'){
                                newRecords.add(createCustomerResponse(complaint.id, complaintCustomerResponseKeyValue, 'Complaint', complaint.CMSNext_Ticket_Number__c, complaint.Reply_Expectation__c));
                            }

                            updatableComplaint.Id = complaint.Id;
                            updatableComplaint.Is_Custom_response_child_created__c = true;
                            customCustomerResponse = true;
                        }

                        //W-1312
                        if(Trigger.isUpdate && complaint.Follow_up_Status__c == 'Further Review' &&
                          ((complaint.Ticket_Type__c == 'Inquiry') ||
                           (complaint.Ticket_Type__c == 'Complaint'))
                                && updatedFieldsSet.contains('Follow_up_Status__c')) {//  28FEB19 - Trigger.oldMap Issue
                            for(Customer_Response__c CR : complaintIdWithClosedCR.get(complaint.Id)){
                                // DEF #1408 fix
                                if(CR.CMPL123_WF_Status__c == 'Closed-Done') {
                                    updatableChildRecords.add(new Customer_Response__c(
                                            Id = CR.Id,
                                            CMPL123Task_Key_Value__c = (complaint.Ticket_Type__c == 'Inquiry' ? 'ReopenInqCustomerResponse' : (complaint.Ticket_Type__c == 'Complaint' ? 'ReopenComplaintCustomerResponse' : null)),
                                            Action_Required__c = false
                                    )
                                    );
                                }
                            }
                        }

                        if (Trigger.isUpdate && complaint.CMPL123CME__CMPL123_WF_Status__c == 'Complaint Complete'
                          && updatedFieldsSet.contains('Follow_up_Status__c')
                          && complaint.Follow_up_Status__c == 'Further Review') {
                            updatableComplaint.CMPL123Task_Key_Value__c = 'FurtherReview';
                            updatableComplaint.Ready_to_Close__c = 'No';
                            updatableComplaint.Last_Modified_Date_Time__c = System.now();
                            updatableComplaint.Id = complaint.Id;
                            updatableComplaint.Follow_up_Status__c = null;
                        }

                        if(Trigger.isUpdate && complaint.CMPL123CME__CMPL123_WF_Status__c == 'Complaint Further Review' &&
                         updatedFieldsSet.contains('Follow_up_Status__c')) {
                            Boolean isValid = true;

                            for(Customer_Response__c CR : complaintIdWithClosedCR.get(complaint.Id)) {
                                if(CR.CMPL123_WF_Status__c != 'Closed-Done') {
                                    isValid = false;
                                    break;
                                }
                            }

                            if(isValid) {
                                updatableComplaint.Id = complaint.Id;
                                updatableComplaint.CMPL123Task_Key_Value__c = 'ComplaintResponded';
                                //Lakshman: Start
                                updatableComplaint.Ready_to_Close__c = 'Yes';
                                //Lakshman: End
                            }
                        }
                    }

                    //Added - W-000108 - 07/08/2018
                    // 18MAR19 - Added for Def#285
                    if(complaint.MDC_All_ACKs_Received__c == true &&
                      ((complaint.CMSNext__c == 'Closed') ||
                       updatedFieldsSet.contains('MDC_All_ACKs_Received__c') ||
                       (updatedFieldsSet.contains('CMPL123CME__CMPL123_WF_Status__c') && complaint.CMPL123CME__CMPL123_WF_Status__c == 'Complaint Complete'))) {
                        setTicketIds.add(complaint.Id);
                    }

                    //Added - W-000108 - 07/08/2018

                    //Added - W-000104 - 19/08/2018 - Start
                    if(Trigger.isUpdate && complaint.Customer_Reply_Required__c == false && updatedFieldsSet.contains('Customer_Reply_Required__c')) {
                        setTicketIdsToCloseCustomerResponses.add(complaint.Id);
                    }
                    //Added - W-000104 - 19/08/2018 - End

                    //W-1313
                    if(Trigger.isUpdate && updatedFieldsSet.contains('CMSNext__c')){
                        if(complaint.CMSNext__c == 'Closed'){
                            if(complaint.Ticket_Type__c == 'Complaint' && complaint.CMPL123CME__CMPL123_WF_Status__c == 'Complaint Complete'){
                                updatableComplaint.Id = complaint.Id;
                                updatableComplaint.CMPL123Task_Key_Value__c = 'FurtherRequired';
                            }
                        }
                    }

                    // Generate System Prod Eval for Service Tickets
                    if(!systemProdEval && !complaint.Is_Product_Evaluation_Investigation_chil__c) {
                        if(complaint.Ticket_Type__c == 'Complaint' ||
                           (complaint.Ticket_Type__c == 'Service' && complaint.Overall_Reportable_Status__c == 'Reportable' &&
                            (updatedFieldsSet.contains('Overall_Reportable_Status__c') || updatedFieldsSet.contains('pRE_Status__c'))) ) {
                            CMPL123CME__Investigation__c investigation = createInvestigation(
                                    complaint.Id, investigationRuleKeyValue, complaint.Division__c, complaint.Registration_Ticket__c
                            );
                            newRecords.add(investigation);
                            updatableComplaint.Id = complaint.Id;
                            updatableComplaint.Is_Product_Evaluation_Investigation_chil__c = true;
                            // Def #1577 fix
                            updatableComplaint.Product_Evaluation_Start_Date__c = investigation.Created_Date__c;
                            systemProdEval = true;
                        }
                    }

                    // Create Med Eval for DEF#280
                    if(!systemMedEval && updatedFieldsSet.contains('pRE_Status__c') && complaint.pRE_Status__c == 'Yes' &&
                      !complaint.Is_Medical_Evaluation_child_created__c &&
                      (complaint.Ticket_Type__c == 'Service' || complaint.Ticket_Type__c == 'Complaint')) {
                        newRecords.add(createAssessment(complaint.Id, complaint.Ticket_Receipt_Date__c, assessmentRuleKeyValue));
                        updatableComplaint.Id = complaint.Id;
                        updatableComplaint.Is_Medical_Evaluation_child_created__c = true;
                        systemMedEval = true;
                    }

                    // 14FEB19 - AQC#120 - Fix for CPU Time Limit error for non-english Country
                    cmsnextTicketNumber = complaint.CMSNext_Ticket_Number__c;

                    if(updatableComplaint.Id != null){
                        updatableComplaints.add(updatableComplaint);
                    }
                } catch(Exception exp) {
                    complaint.addError(exp);
                }

                // Final Review
                if (Trigger.isUpdate && complaint.CMPL123CME__CMPL123_WF_Status__c == 'Final Review In Progress' &&
                  complaint.Division__c == 'ADD' &&
                  updatedFieldsSet.contains('CMPL123CME__CMPL123_WF_Status__c')) {
                    finalReviewIds.add(complaint.Id);
                }

                if (Trigger.isUpdate && complaint.MDC_All_ACKs_Received__c &&
                  updatedFieldsSet.contains('MDC_All_ACKs_Received__c')) {
                    eligibleTicketIds.add(complaint.Id);
                }
            }

            // Automatically promote histories
            if (finalReviewIds.size() > 0) {
                // 09-NOV-2022 Larry: TODO: Doesn't this crash if the record doesn't exist? Someone check.
                CMPL123__WF_Step__c workflowStep = [SELECT Id, CMPL123__WF_Rule__c,CMPL123__WF_Rule__r.CMPL123__Record_Type__c,
                                                    CMPL123__Action__r.CMPL123__Is_ESign_Required__c,CMPL123__Action__r.Name,
                                                    CMPL123__End_Status__r.Name, CMPL123__Start_Status__r.Name
                                                    FROM CMPL123__WF_Step__c
                                                    WHERE CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'COMPLAINT_WORKFLOW'
                                                    AND CMPL123__Start_Status__r.Name = 'Final Review In Progress'
                                                    AND CMPL123__End_Status__r.Name = 'Closed-Done' LIMIT 1];


                if(workflowStep != null) {
                    for(Id ticketId : finalReviewIds) {
                        updatableComplaints.add (
                            new CMPL123CME__Complaint__c (
                                Id = ticketId,
                                CMPL123CME__CMPL123_WF_Status__c = workflowStep.CMPL123__End_Status__r.Name,
                                CMPL123CME__CMPL123_WF_Action_Performed_On__c = System.now(),
                                CMPL123CME__CMPL123_WF_Action_Performed_By__c = userinfo.getuserid(),
                                CMPL123CME__CMPL123_WF_Action__c = workflowStep.CMPL123__Action__r.Name
                            )
                        );
                        newRecords.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(ticketId, workflowStep));
                    }
                }
            } // End of logic to automatically promote histories

            if (eligibleTicketIds.size() > 0) {
                CustomerResponseTriggerHandler.processEligibleComplaintsToComplete(eligibleTicketIds);

                // Added for ready for closure - 08FEB18
                for(Id strId: eligibleTicketIds) {
                    readyForClosureTicketIdSet.add((Id)strId);
                }
                TicketUpdateUtility.updateParentOnChildUpdate(readyForClosureTicketIdSet);
            }

            // 14FEB19 - AQC#120 - Fix for CPU Time Limit error for non-english Country
            if(newRecords.size() > 0) {
                insert newRecords;      // 28FEB19 - DEF#280 and DEF#374 - Fix for TriggerOldMap
            }

            if(updatableChildRecords.size() > 0){
                update updatableChildRecords;
            }

            if(updatableComplaints.size() > 0){
                update updatableComplaints;
            }

            //Added - W-000108 - 07/08/2018 - Start
            //CHaRM-R5: Add "restrictClosureFlag" in the condition to process the ticket closure if the flag is false.
                if(setTicketIds.size() > 0 && !TicketServiceHandler.ticketOpenFromCMSFlag && !TicketServiceHandler.restrictClosureFlag){
                    TicketUtil.closeTicketBasedOnConditions(setTicketIds);
                }
                //Added - W-000108 - 07/08/2018 - End

            // Def #1526 fix - Start
            if(setTicketIdsToReopenVoidedCRs.size() > 0 && !isCRReopened){
                reopenVoidCustomerResponses(setTicketIdsToReopenVoidedCRs);
                isCRReopened = true;
            }
            // Def #1526 fix - End

            //Added - W-000104 - 19/08/2018 -Start
            if(setTicketIdsToCloseCustomerResponses.size() > 0 &&!isCRVoided){
                closedVoidCustomerResponses(setTicketIdsToCloseCustomerResponses);
                isCRVoided = true;
            }
            //Added - W-000104 - 19/08/2018 -End

            //Added - - 07/08/2018
            if(TicketUtil.isFirstRun()){
                //Added - W-000129 - 08/08/2018 -Start
                if(!TicketServiceHandler.ticketOpenFromCMSFlag){
                   closedVoidAllRelatedChildren(newComplaints, oldComplaintsMap);

                }
                //Added - W-000129 - 08/08/2018 -End
            }
        }catch(Exception exp){
            throw exp;
        }
    }

    //23APR19 - #772 - To create Ticket Version when ticket reopens from CHaRM and also CMSNext
    private static void createTicketVersionWhenReopen(List<CMPL123CME__Complaint__c> lstComplaintsNew){
        List<sObject> newRecords = new List<sObject>();
        //Ticket version updation code
        //Added 'Reopen - Translation Required' and 'Reopen - Go to Opened' - W-000100, W-000213 - 02/08/2018
        // FRS-130-01
        for(CMPL123CME__Complaint__c complaint : lstComplaintsNew) {
            if(!ticketVersionUpdated && complaint.Ticket_Type__c == 'Complaint' && Trigger.isUpdate &&
               (complaint.CMPL123CME__CMPL123_WF_Action__c == 'Reopen' ||
                complaint.CMPL123CME__CMPL123_WF_Action__c == 'Reopen - Translation Required' ||
                complaint.CMPL123CME__CMPL123_WF_Action__c == 'Reopen - Go to Opened'
               ) &&
               updatedFieldsSet.contains('CMPL123CME__CMPL123_WF_Action__c')) {
                   newRecords.add(new Ticket_Version__c(Ticket__c = complaint.Id,
                                                        Version_number__c = complaint.Total_Ticket_Versions__c + 1,
                                                        Opened_By__c = userinfo.getName(),
                                                        Opened_Date__c = complaint.CMPL123CME__CMPL123_WF_Action_Performed_On__c.date(),
                                                        Reopen_Rationale__c = complaint.Reopen_Rationale__c
                                                       ));
                   ticketVersionUpdated = true;
               }
        }

        if(newRecords.size() > 0){
            insert newRecords;
        }
    }

    // public method used to construct auto customer response record, also set the owner
    public static Customer_Response__c createCustomerResponse(String ticketId, String ruleKeyValue, String ticketType, String strCMSNextTicketNumber, String strCustomerExpectation){
        TicketUtil.addTrace('ComplaintTriggerHandler.createCustomerResponse' + ticketId);
        Customer_Response__c CR = new Customer_Response__c(
            Event__c = ticketId,
            CMSNext_Ticket_Number__c = strCMSNextTicketNumber,
            CMPL123Rule_Key_Value__c = ruleKeyValue,
            Ticket_Type__c = ticketType,
            OwnerId = queueWithIdMap != null && queueWithIdMap.get('Customer_Reply_Required') != null ? queueWithIdMap.get('Customer_Reply_Required') : Userinfo.getUserId(),
            Customer_Expectation__c = strCustomerExpectation
        );
        return CR;
    }

    //15May19 - #946 - Ticket Version Closed Date Fix - logic added in Code from Process Builder "Update Ticket Version"
    private static void updateTicketVersionClosedDate(List<CMPL123CME__Complaint__c> lstComplaintsNew,
            Map<Id,CMPL123CME__Complaint__c> oldComplaints){
            Set<Id> setComplaintIds = New Set<Id>();
            for(CMPL123CME__Complaint__c objComplaint : lstComplaintsNew) {
            if(!updateTicketVersionCloseDateOnceCheck && objComplaint.Ticket_Type__c == 'Complaint' &&
            Trigger.isUpdate && objComplaint.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done' &&
            oldComplaints.get(objComplaint.Id).CMPL123CME__CMPL123_WF_Status__c == 'Final Review In Progress' ){
            setComplaintIds.add(objComplaint.Id);
        }
        }

        if(setComplaintIds.size() > 0){
            List<Ticket_Version__c> lstTicketVersions = New List<Ticket_Version__c>();
            for(CMPL123CME__Complaint__c objComplaint
                : [SELECT Id,
                   (SELECT Id, Closed_Date__c FROM Ticket_Versions__r WHERE Closed_Date__c = null) FROM CMPL123CME__Complaint__c WHERE Id IN: setComplaintIds]){
                       for(Ticket_Version__c objTicketVersion : objComplaint.Ticket_Versions__r){
                           objTicketVersion.Closed_Date__c = System.today();
                           lstTicketVersions.add(objTicketVersion);
                       }
                   }

            if(lstTicketVersions.size() > 0 ){
                updateTicketVersionCloseDateOnceCheck = true;
                update lstTicketVersions;
            }
        }
    }

    //public method used to construct auto investigation record, also set the owner
    public static CMPL123CME__Investigation__c createInvestigation(String ticketId, String ruleKeyValue, String division, String invName){
        TicketUtil.addTrace('ComplaintTriggerHandler.createInvestigation' + ticketId);
        //Added - W-000344 -  System_Integration_Generated_Flag__c = true
        CMPL123CME__Investigation__c investigation = new CMPL123CME__Investigation__c(
            CMPL123CME__Complaint__c = ticketId,
            CMPL123Rule_Key_Value__c = division != null && division == 'AMD' ? investigationAMDRuleKeyValue : ruleKeyValue,
            Name = invName + '-01',
            OwnerId = queueWithIdMap != null && queueWithIdMap.get('Product_Quality_Queue') != null ? queueWithIdMap.get('Product_Quality_Queue') : Userinfo.getUserId(),
            Division__c = division,
            System_Integration_Generated_Flag__c = true,
            // Moved field assigment from Autoset Date to Current process
            Created_Date__c = System.today()
        );
        return investigation;
    }

    //public method used to construct auto assessment record, also set the owner
    public static CMPL123CME__Questionnaire__c createAssessment(String ticketId, Date receiptDateTime, String ruleKeyValue){
        TicketUtil.addTrace('ComplaintTriggerHandler.createAssessment' + ticketId);
        CMPL123CME__Questionnaire__c assessment = new CMPL123CME__Questionnaire__c(
            CMPL123CME__Complaint__c = ticketId,
            CMPL123Rule_Key_Value__c = ruleKeyValue,
            CMPL123CME__Key_Value__c = 'pRE',
            // Added for DEF#476
            Initial_Awareness_Date__c = (receiptDateTime == null ? null : receiptDateTime),
            //Added for W-000498
            System_Generated_Flag__c = true,
            OwnerId = queueWithIdMap != null && queueWithIdMap.get('Medical_eval_Assessment_Queue') != null ? queueWithIdMap.get('Medical_eval_Assessment_Queue') : Userinfo.getUserId()

        );

        return assessment;
    }

    //public method used to construct a automated history record based on the step pass as parameter
    public static CMPL123__WF_History__c processAutomatedHistoryRecord(String parentId, CMPL123__WF_Step__c WFStep){
        TicketUtil.addTrace('ComplaintTriggerHandler.processAutomatedHistoryRecord' + parentId);
        CMPL123__WF_History__c autoPromotedHistory = new CMPL123__WF_History__c(
            CMPL123__Related_Id__c = parentId,
            CMPL123__Workflow_Step__c = WFStep.Id,
            CMPL123__Action__c = WFStep.CMPL123__Action__r.Name,
            CMPL123__ESign_Applied__c = false, //WFStep.CMPL123__Action__r.CMPL123__Is_ESign_Required__c,
            CMPL123__Comment__c = 'Applied through task update',
            CMPL123__Status__c = WFStep.CMPL123__End_Status__r.Name,
            CMPL123__Change_Summary__c= 'Updated Status From '+WFStep.CMPL123__Start_Status__r.Name+' to '+ WFStep.CMPL123__End_Status__r.Name
        );
        return autoPromotedHistory;
    }

    /*
    * @Method       : moveChildrenOpenToClose.
    * @Description  : Public method referenced in process builder invokable methods,
    *                 used to move all the children to closed void status (either
    *                 when demoted to service or CMSNext is set to void).
    * @Invoke       : ADDDemoteToServiceHandler, DemoteToServiceWorkflowProcess, ProcessCMSNextVoidWorkflow classes.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__Complaint__c> records, Boolean isDemoted.
    */
    public static void moveChildrenOpenToClose(List<CMPL123CME__Complaint__c> records, Boolean isDemoted){
        TicketUtil.addTrace('ComplaintTriggerHandler.moveChildrenOpenToClose');
        CMPL123CME__Complaint__c updatableComplaint;

        if(records.size() == 1){
            for(CMPL123CME__Complaint__c c : records){
                updatableComplaint = c;
            }
        }
        if(updatableComplaint.Id != null){
            String emailHeader = '<div style="font-family: verdana;font-size:13px;"><p>Hello '+UserInfo.getName()+',</p><br/> ';
            String emailFooter = '<p>Thanks<br/>CHaRM</p><br/>';
            String emailBody = '<p>Following product evaluation/investigation are also linked to other tickets, so cannot move to void status.\n';
            emailBody = emailBody + 'Please follow below link to view the product evaluation/investigation to reparent the ticket';
            Boolean notifyUser = false;
            //Updated - W-000094
            List< CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();
            List<sObject> childRecords = new List<sObject>();
            Map<string,CMPL123__WF_Step__c> objectNameCloseStepIdMap = new Map<string,CMPL123__WF_Step__c>();
            Map<String,CMPL123__WF_Step__c> ruleKeyToStep = new Map<String,CMPL123__WF_Step__c>();
            String wfKeyIdentifierWildcard = customerResponseAPI + '%';
            for(CMPL123__WF_Step__c WFStep : [SELECT Id, CMPL123__Action__r.Name, CMPL123__Start_Status__r.Name,
                                              CMPL123__End_Status__r.Name,CMPL123__WF_Rule__r.CMPL123__Target_Object__c FROM CMPL123__WF_Step__c
                                              WHERE CMPL123__End_Status__r.Name = 'Closed-Voided'
                                              AND (CMPL123__Action__r.Name = 'Close' OR CMPL123__Action__r.Name = 'Void')
                                              AND CMPL123__WF_Rule__r.CMPL123__Is_Active__c = true
                                              AND (CMPL123__WF_Rule__r.CMPL123__Target_Object__c LIKE :wfKeyIdentifierWildcard  // retrieve Close or Void actions for all Customer Response WF Rules
                                                    OR CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'PRODEVAL_WORKFLOW'    // Upgrade issue #41
                                                    OR CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'closevoid')]){
                String objectName = WFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c.substringBefore('(');
                objectNameCloseStepIdMap.put(objectName,WFStep);
                ruleKeyToStep.put(WFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c, WFStep);
            }
            //Updated - W-000094 (NOT CMPL123_WF_Status__c LIKE 'Closed%')
            CMPL123CME__Complaint__c Complaint = [SELECT Id,CMPL123CME__CMPL123_WF_Action__c,CMPL123CME__CMPL123_WF_Status__c,Complaint_Demotion_rationale__c,
                                                  CMPL123CME__CMPL123_WF_Action_Performed_By__c, CMPL123CME__CMPL123_WF_Action_Performed_On__c,
                                                  (SELECT Id, Investigation_Evaluation__c,Investigation_Evaluation__r.Name,Investigation_Evaluation__r.CMPL123_WF_Status__c,
                                                   Investigation_Evaluation__r.CMPL123_WF_Action_Performed_By__c,
                                                   Investigation_Evaluation__r.CMPL123_WF_Action_Performed_On__c,Investigation_Evaluation__r.CMPL123_WF_Action__c
                                                   FROM Ticket_Product_Evaluation_Investigation__r WHERE
                                                   (NOT Investigation_Evaluation__r.CMPL123_WF_Status__c LIKE 'Closed%')),
                                                   (SELECT Id,Name,CMPL123_WF_Status__c,CMPL123_WF_Action_Performed_By__c,CMPL123_WF_Action__c,
                                                    CMPL123_WF_Action_Performed_On__c, CMPL123Rule_Key_Value__c
                                                    FROM Customer_responses__r WHERE
                                                    (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
                                                   (SELECT Id,Name,CMPL123_WF_Status__c,CMPL123_WF_Action_Performed_By__c,CMPL123_WF_Action_Performed_On__c,
                                                    CMPL123_WF_Action__c FROM CMPL123CME__Questionnaires__r
                                                    WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%'))
                                                   FROM CMPL123CME__Complaint__c WHERE Id =: updatableComplaint.Id];

            executingThroughInvokable = true;

            if(!isDemoted){
                Complaint.CMPL123Rule_Key_Value__c= 'void_complaint';
                Complaint.CMPL123Task_Key_Value__c = 'voidcomplaint';
                update Complaint;
            }
            CMPL123__WF_Step__c wfStep;

            Set<String> investigationIdSet = new Set<String>();
            Set<String> leveragedIdSet = new Set<String>();
            for(Ticket_Product_Evaluation_Investigation__c investigation : Complaint.Ticket_Product_Evaluation_Investigation__r){
                investigationIdSet.add(investigation.Investigation_Evaluation__c);
            }

            for(Ticket_Product_Evaluation_Investigation__c leveragedInvestigation : [SELECT Id, Name, Investigation_Evaluation__c,
                                                                                     Ticket__c, Type__c FROM Ticket_Product_Evaluation_Investigation__c WHERE  Investigation_Evaluation__c
                                                                                     IN : investigationIdSet AND Ticket__c != :updatableComplaint.Id]){
                leveragedIdSet.add(leveragedInvestigation.Investigation_Evaluation__c);
            }

            for(Ticket_Product_Evaluation_Investigation__c investigation : Complaint.Ticket_Product_Evaluation_Investigation__r){
                wfStep = objectNameCloseStepIdMap.get('CMPL123CME__Investigation__c');
                if(wfStep != null){
                    if(!leveragedIdSet.contains(investigation.Investigation_Evaluation__c)){
                        childRecords.add(new CMPL123CME__Investigation__c(
                            Id = investigation.Investigation_Evaluation__c,
                            CMPL123_WF_Status__c = WFStep.CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action__c = WFStep.CMPL123__Action__r.Name,
                            CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                            CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId(),
                            //Voided_Rationale__c = isDemoted ? 'Ticket demoted to service' : 'Ticket voided in CMS Next'
                            Voided_Rationale__c = isDemoted ? Complaint.Complaint_Demotion_rationale__c : 'Ticket voided in CMS Next'
                        ));
                        // Updated - W-000094 -if condition added - Start
                        CMPL123__WF_History__c wfHistory = ComplaintTriggerHandler.processAutomatedHistoryRecord(investigation.Investigation_Evaluation__c,wfStep);
                        // Upgrade issue #41
                        wfHistory.CMPL123__Change_Summary__c = 'Updated Status From ' + investigation.Investigation_Evaluation__r.CMPL123_WF_Status__c
                                                                    + ' to ' + WFStep.CMPL123__End_Status__r.Name;

                        WFHistories.add(wfHistory);
                        // Updated - W-000094 -if condition added - End
                    } else {
                        notifyUser = true;
                        emailBody = emailBody + '\n<a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+investigation.Investigation_Evaluation__c+'">this link</a>';
                    }
                }
            }

            for(Customer_Response__c customerResponse : Complaint.Customer_responses__r){
                String strKey = customerResponseAPI + (String.valueOf(customerResponse.get('CMPL123Rule_Key_Value__c'))
                    != '' ? '('+String.valueOf(customerResponse.get('CMPL123Rule_Key_Value__c'))+')' : '');
                wfStep = ruleKeyToStep.get(strKey); // get step from assigned WF Rule
                if(wfStep != null){
                    childRecords.add(new Customer_Response__c(
                        Id = customerResponse.Id,
                        CMPL123_WF_Status__c = WFStep.CMPL123__End_Status__r.Name,
                        CMPL123_WF_Action__c = WFStep.CMPL123__Action__r.Name,
                        CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                        CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId()
                    ));
                    // Updated - W-000094 -if condition added - Start
                    CMPL123__WF_History__c wfHistory = ComplaintTriggerHandler.processAutomatedHistoryRecord(customerResponse.Id,wfStep);

                    wfHistory.CMPL123__Comment__c = Complaint.Complaint_Demotion_rationale__c;
                    WFHistories.add(wfHistory);
                    // Updated - W-000094 -if condition added- End
                }
            }
            if(!isDemoted) {
                for(CMPL123CME__Questionnaire__c assessment : Complaint.CMPL123CME__Questionnaires__r){
                    wfStep = objectNameCloseStepIdMap.get('CMPL123CME__Questionnaire__c');
                    if(wfStep != null){
                        childRecords.add(new CMPL123CME__Questionnaire__c(
                            Id = assessment.Id,
                            CMPL123_WF_Status__c = WFStep.CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action__c = WFStep.CMPL123__Action__r.Name,
                            CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                            CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId()
                        ));
                        WFHistories.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(assessment.Id,wfStep));
                    }
                }
            }
            if(childRecords.size() > 0) {
                insert WFHistories;
                update childRecords;
            }
            if(notifyUser) {
                if(!test.isRunningTest()) {
                    Messaging.sendEmail(new List<Messaging.Singleemailmessage>{ADDUtil.generateNotification(emailHeader+emailBody+emailFooter, Userinfo.getUserId(), 'Change Product Evaluation/Investigation source', new List<String>())});
                }
            }
        }
    }

    /**
    * @Method       : closedVoidAllRelatedChildren
    * @Description  : W-000129 - (Ticket) Void all child records that have a workflow and not in Closed status
    *                 should be automatically moved to Closed - Voided status
    * @Return       : N/A
    * @Params       : List<CMPL123CME__Complaint__c> lstComplaintsNew,  Map<Id,CMPL123CME__Complaint__c> mapComplaintsOld
    **/
    //W-000129 - (Ticket) Void all child records that have a workflow and not in Closed status should be automatically moved to Closed - Voided status
    private static void closedVoidAllRelatedChildren(List<CMPL123CME__Complaint__c> lstComplaintsNew,  Map<Id,CMPL123CME__Complaint__c> mapComplaintsOld){
        TicketUtil.addTrace('ComplaintTriggerHandler.closedVoidAllRelatedChildren');
        Set<Id> setTicketIds = New Set<Id>();
        if(trigger.isUpdate){
            for(CMPL123CME__Complaint__c objTicket : lstComplaintsNew){
                if(objTicket.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Voided' && objTicket.CMSNext__c == 'Void' && (mapComplaintsOld.get(objTicket.Id).CMPL123CME__CMPL123_WF_Status__c != objTicket.CMPL123CME__CMPL123_WF_Status__c || updatedFieldsSet.contains('CMPL123CME__CMPL123_WF_Status__c') || updatedFieldsSet.contains('CMSNext__c'))){
                    // recheck before close void
                    if(objTicket.Ticket_Type__c == 'Inquiry' && objTicket.MDC_All_ACKs_Received__c) { //16APR19 - #690 Inquiry should close void only when all ACKs Recieved
                        setTicketIds.add(objTicket.Id);
                    }else if(objTicket.Ticket_Type__c != 'Inquiry' && objTicket.Med_Evaluator_Pending_MDCs__c == false){
                        setTicketIds.add(objTicket.Id);
                    }
                }
            }
        }
        // 07JAN19 - SOQL Limit Fix
        if(setTicketIds.isEmpty()) {
            TicketUtil.addTrace('ComplaintTriggerHandler.closedVoidAllRelatedChildren - return');
            return;
        }else{
            //06MAY2019 - #878
            executeOnceClosedVoidComplaint = true;
        }

        //Query all the related child records without the workflow status ("Closed-Voided")
        Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey = New Map<String,CMPL123__WF_Step__c>();
        Set<String> setChildObjectAPINames = new Set<String>{'CMPL123CME__Complaint__c','Translation_Task__c','CMPL123CME__Questionnaire__c','Return__c','Customer_Response__c','Task__c','CMPL123CME__Investigation__c','Medical_Evaluation_Task__c'};
        for(CMPL123__WF_Step__c objWFStep :
            [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,CMPL123__WF_Rule__r.CMPL123__Target_Object__c,
                CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c WHERE
                CMPL123__End_Status__r.Name = 'Closed-Voided' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__WF_Rule__r.CMPL123__Is_Active__c = true] ){
            if(setChildObjectAPINames.contains(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c.substringBefore('('))){
                mapWFStepWithRuleKey.put(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c,objWFStep);
            }
        }

        List<CMPL123__WF_History__c> lstWFHistories = New list<CMPL123__WF_History__c>();
        List<sObject> lstsObjects = New List<sObject>();
        Set<Id> setQuestionnaires = new Set<Id>();
        Set<Id> setEvalInvestTasks = new Set<Id>();
        for(CMPL123CME__Complaint__c objTicket :
            [SELECT Id,CMPL123Rule_Key_Value__c,
             (SELECT Id,CMPL123Rule_Key_Value__c FROM Customer_Responses__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
             (SELECT Id,CMPL123Rule_Key_Value__c FROM Translation_Tasks__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
             (SELECT Id,CMPL123Rule_Key_Value__c FROM Returns__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
             (SELECT Id,CMPL123Rule_Key_Value__c FROM CMPL123CME__Questionnaires__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')),
             (SELECT Id, Request_Status__c, Answer_No_Answer_Rationale__c FROM Meaningful_Data_Requests__r WHERE Request_Status__c = 'Opened'),
             (SELECT Id,CMPL123Rule_Key_Value__c FROM CMPL123CME__Investigations__r  WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%') AND (Prod_eval_KI_Log__c  = false OR Prod_eval_KI_Log__c  = null))
             FROM CMPL123CME__Complaint__c WHERE Id IN: setTicketIds]){

            //Closing the Customer Responses
            for(sObject objCustomerResponse : objTicket.Customer_Responses__r){

                String strKey = 'Customer_Response__c' + (String.valueOf(objCustomerResponse.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objCustomerResponse.get('CMPL123Rule_Key_Value__c'))+')' : '');
                if(mapWFStepWithRuleKey.containsKey(strKey)){
                    lstsObjects.add(TicketUtil.populateWFFields(objCustomerResponse, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                    lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objCustomerResponse.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                }
            }

            // Closing the Translation Tasks
            for(sObject objTranslationTask : objTicket.Translation_Tasks__r){
                String strKey = 'Translation_Task__c' + (String.valueOf(objTranslationTask.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objTranslationTask.get('CMPL123Rule_Key_Value__c'))+')' : '');
                if(mapWFStepWithRuleKey.containsKey(strKey)){
                    objTranslationTask.put('Void_Rationale__c', 'Voided by Parent Ticket Void');
                    lstsObjects.add(TicketUtil.populateWFFields(objTranslationTask, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                    lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objTranslationTask.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                }
            }

            // Closing the Returns
            for(sObject objReturn : objTicket.Returns__r){
                String strKey = 'Return__c' + (String.valueOf(objReturn.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objReturn.get('CMPL123Rule_Key_Value__c'))+')' : '');
                if(mapWFStepWithRuleKey.containsKey(strKey)){
                    lstsObjects.add(TicketUtil.populateWFFields(objReturn, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                    lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objReturn.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                }
            }

                 for(sObject objQuestionnaire : objTicket.CMPL123CME__Questionnaires__r){
                     setQuestionnaires.add(String.valueOf(objQuestionnaire.get('Id')));
                 }

                //15APR19 - Added this code before voiding Med Eval Record to avoid the validation
                 for(sObject objMedEvalTask : [SELECT Id,CMPL123Rule_Key_Value__c FROM Medical_Evaluation_Task__c WHERE Medical_Evaluation__c IN :setQuestionnaires AND (NOT CMPL123_WF_Status__c LIKE 'Closed%')]){
                     String strKey = 'Medical_Evaluation_Task__c' + (String.valueOf(objMedEvalTask.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objMedEvalTask.get('CMPL123Rule_Key_Value__c'))+')' : '');
                     if(mapWFStepWithRuleKey.containsKey(strKey)){
                         objMedEvalTask.put('Voided_Rationale__c','Voided by Parent Ticket Void');
                         lstsObjects.add(TicketUtil.populateWFFields(objMedEvalTask, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                         lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objMedEvalTask.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                     }
                 }

                 for(sObject objInvestigation : objTicket.CMPL123CME__Investigations__r){
                     setEvalInvestTasks.add(String.valueOf(objInvestigation.get('Id')));
                 }

                 for(sObject objEvalInvestTask : [SELECT Id,CMPL123Rule_Key_Value__c FROM Task__c WHERE Related_Investigation_Evaluation__c IN :setEvalInvestTasks AND (NOT CMPL123_WF_Status__c LIKE 'Closed%') AND (Leveraged__c = false OR Leveraged__c = null)]){
                     String strKey = 'Task__c' + (String.valueOf(objEvalInvestTask.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objEvalInvestTask.get('CMPL123Rule_Key_Value__c'))+')' : '');
                     if(mapWFStepWithRuleKey.containsKey(strKey)){
                         lstsObjects.add(TicketUtil.populateWFFields(objEvalInvestTask, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                         lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objEvalInvestTask.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                     }
                 }

            // Closing the MedEvals
            for(sObject objQuestionnaire : objTicket.CMPL123CME__Questionnaires__r){
                String strKey = 'CMPL123CME__Questionnaire__c' + (String.valueOf(objQuestionnaire.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objQuestionnaire.get('CMPL123Rule_Key_Value__c'))+')' : '');
                if(mapWFStepWithRuleKey.containsKey(strKey)){
                    objQuestionnaire.put('Voided_Rationale__c','Voided by Parent Ticket Void');
                    lstsObjects.add(TicketUtil.populateWFFields(objQuestionnaire, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                    lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objQuestionnaire.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                }
            }

            // Closing the Prod Evals
            for(sObject objInvestigation : objTicket.CMPL123CME__Investigations__r){
                String strKey = 'CMPL123CME__Investigation__c' + (String.valueOf(objInvestigation.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objInvestigation.get('CMPL123Rule_Key_Value__c'))+')' : '');
                if(mapWFStepWithRuleKey.containsKey(strKey)){
                    objInvestigation.put('Voided_Rationale__c','Voided by Parent Ticket Void');
                    lstsObjects.add(TicketUtil.populateWFFields(objInvestigation, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                    lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objInvestigation.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                }
            }

            // Closing the Meaningful Data Requests - 15MAR19 - DEF#526
            for(sObject objMDR: objTicket.Meaningful_Data_Requests__r) {
                objMDR.put('Request_Status__c', 'Voided');
                objMDR.put('Answer_No_Answer_Rationale__c', 'Voided by Parent Ticket Void');
                lstsObjects.add(objMDR);
            }

                 //Creation of WorkFlow History record for current Ticket
                 String strStepKey = 'CMPL123CME__Complaint__c' + (objTicket.CMPL123Rule_Key_Value__c != null ? '('+objTicket.CMPL123Rule_Key_Value__c+')' : '');
                 if(mapWFStepWithRuleKey.containsKey(strStepKey)){
                     lstsObjects.add(TicketUtil.populateWFFields((sObject)objTicket, mapWFStepWithRuleKey.get(strStepKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strStepKey).CMPL123__Action__r.Name));
                     lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objTicket.Id), mapWFStepWithRuleKey.get(strStepKey)));
                 }

        }

        if(lstsObjects.size() > 0){
            update lstsObjects;
            insert lstWFHistories;
        }
    }

    //W-000104 - Customer Reply Required = No, Closed-Void Customer Response Child
    @TestVisible
    private static void closedVoidCustomerResponses(Set<Id> setTicketIds){
        TicketUtil.addTrace('ComplaintTriggerHandler.closedVoidCustomerResponses' + setTicketIds);
        if(trigger.isUpdate){
            //Query all the customer response related child records without the workflow status ("Closed-Voided")
            Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey = New Map<String,CMPL123__WF_Step__c>();
            Set<String> setChildObjectAPINames = New Set<String>{'Customer_Response__c'};
                for(CMPL123__WF_Step__c objWFStep :
                    [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,CMPL123__WF_Rule__r.CMPL123__Target_Object__c,
                     CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c WHERE
                     CMPL123__End_Status__r.Name = 'Closed-Voided' AND
                     CMPL123__Action__r.Name = 'Void' AND CMPL123__WF_Rule__r.CMPL123__Is_Active__c = true] ){
                         if(setChildObjectAPINames.contains(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c.substringBefore('('))){
                             mapWFStepWithRuleKey.put(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c,objWFStep);
                         }
                     }
            List<CMPL123__WF_History__c> lstWFHistories = New list<CMPL123__WF_History__c>();
            List<sObject> lstsObjects = New List<sObject>();

            for(CMPL123CME__Complaint__c objTicket :
                [SELECT Id,CMPL123Rule_Key_Value__c,
                 (SELECT Id,CMPL123Rule_Key_Value__c FROM Customer_Responses__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%'))
                 FROM CMPL123CME__Complaint__c WHERE Id IN: setTicketIds AND Customer_Reply_Required__c = false]){

                     for(sObject objCustomerResponse : objTicket.Customer_Responses__r){
                         String strKey = 'Customer_Response__c' + (String.valueOf(objCustomerResponse.get('CMPL123Rule_Key_Value__c')) != '' ? '('+String.valueOf(objCustomerResponse.get('CMPL123Rule_Key_Value__c'))+')' : '');
                         if(mapWFStepWithRuleKey.containsKey(strKey)){
                             lstsObjects.add(TicketUtil.populateWFFields(objCustomerResponse, mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name , mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                             lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(String.valueOf(objCustomerResponse.get('Id')), mapWFStepWithRuleKey.get(strKey)));
                         }

                     }
                 }

            if(lstsObjects.size() > 0){
                update lstsObjects;
                insert lstWFHistories;
            }
        }
    }

    @TestVisible
    private static void reopenVoidCustomerResponses(Set<Id> setTicketIds){
        TicketUtil.addTrace('ComplaintTriggerHandler.reopenVoidCustomerResponses' + setTicketIds);
        if(Trigger.isUpdate){
            Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey = new Map<String,CMPL123__WF_Step__c>();
            String objAPIName = Customer_Response__c.SObjectType.getDescribe().getName();
            for(CMPL123__WF_Step__c objWFStep : [
                    SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                            CMPL123__WF_Rule__r.CMPL123__Target_Object__c, CMPL123__Start_Status__r.Name
                    FROM CMPL123__WF_Step__c
                    WHERE CMPL123__Start_Status__r.Name = 'Closed-Voided'
                    AND CMPL123__End_Status__r.Name = 'Opened'
                    AND CMPL123__Action__r.Name = 'Reopen'
                    AND CMPL123__WF_Rule__r.CMPL123__Is_Active__c = true
            ]){
                if(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c.substringBefore('(') == objAPIName){
                    mapWFStepWithRuleKey.put(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c,objWFStep);
                }
            }
            List<CMPL123__WF_History__c> lstWFHistories = new list<CMPL123__WF_History__c>();
            List<sObject> lstsObjects = new List<sObject>();

            for(CMPL123CME__Complaint__c objTicket :
            [SELECT Id, CMPL123Rule_Key_Value__c,
            (SELECT Id, CMPL123Rule_Key_Value__c FROM Customer_Responses__r WHERE  CMPL123_WF_Status__c = 'Closed-Voided')
            FROM CMPL123CME__Complaint__c WHERE Id IN: setTicketIds]){

                for(sObject objCustomerResponse : objTicket.Customer_Responses__r){
                    String strKey = 'Customer_Response__c' +
                            (String.valueOf(objCustomerResponse.get('CMPL123Rule_Key_Value__c')) != ''
                                    ? '('+String.valueOf(objCustomerResponse.get('CMPL123Rule_Key_Value__c'))+')' : '');
                    if(mapWFStepWithRuleKey.containsKey(strKey)){
                        lstsObjects.add(TicketUtil.populateWFFields(objCustomerResponse,
                                mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name ,
                                mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                        lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(
                                String.valueOf(objCustomerResponse.get('Id')), mapWFStepWithRuleKey.get(strKey))
                        );
                    }

                }
            }

            if(lstsObjects.size() > 0){
                update lstsObjects;
                insert lstWFHistories;
            }
        }
    }

    /**
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history
    * @Return       : N/A
    * @Params       : Map<Id,CMPL123CME__Complaint__c> newRecordMap,
    *                 Map<Id,CMPL123CME__Complaint__c> oldRecordMap
    **/
    public static void setReopenRationale(List<CMPL123CME__Complaint__c> newRecordList,
                                          Map<Id,CMPL123CME__Complaint__c> oldRecordMap){
        CMPL123CME__Complaint__c oldRecord;
        CMPL123CME__Complaint__c newRecord;
        if(newRecordList.size() == 1){
            for(CMPL123CME__Complaint__c sobj : newRecordList){
                newRecord = sobj;
                oldRecord = oldRecordMap.get(sobj.Id);
            }
            if(newRecord.CMPL123CME__CMPL123_WF_Action__c  != null && newRecord.CMPL123CME__CMPL123_WF_Action__c .containsIgnorecase('Reopen')
                && newRecord.CMPL123CME__CMPL123_WF_Action__c  != oldRecord.CMPL123CME__CMPL123_WF_Action__c
                && newRecord.CMPL123CME__CMPL123_WF_Action__c != 'Reopen'){
                newRecord.Reopen_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
            }
        }
    }

    /**
    * @Method       : checkRCMLTasksStausBeforeClosingTicket
    * @Description  : used to throw an error when user attempted to close a Ticket with Open/In Process RCML Tasks
    * @Return       : N/A
    * @Params       : Map <Id, CMPL123CME__Complaint__c> newMap,
    *                 Map <Id, CMPL123CME__Complaint__c> oldMap
    **/
    public static void validateRCMLTasksStatusBeforeClosingTicket (Map <Id, CMPL123CME__Complaint__c> newMap, Map <Id, CMPL123CME__Complaint__c> oldMap) {
        //Declarations
        Id RCMLTaskRecordTypeId = null;
        List <Id> ticketsToBeClosed = new List <Id> ();
        List <Medical_Evaluation_Task__c> openedRCMLTasks = new List <Medical_Evaluation_Task__c> ();
        Map <Id, Integer> openedRCMLTasksCountPerTicket = new Map <Id, Integer> ();

        //Initialization
        RCMLTaskRecordTypeId = Schema.SObjectType.Medical_Evaluation_Task__c.getRecordTypeInfosByName().get('RCML Review Task').getRecordTypeId();
        for (Id ticketId : newMap.keySet()) {
            CMPL123CME__Complaint__c ticket = newMap.get(ticketId);
            if (String.isNotBlank(ticket.CMPL123CME__CMPL123_WF_Status__c)
                    && (ticket.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done' || ticket.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done')) {
                ticketsToBeClosed.add(ticketId);
            }
        }
        openedRCMLTasks = [
                SELECT Id, Medical_Evaluation__r.CMPL123CME__Complaint__c
                FROM Medical_Evaluation_Task__c
                WHERE Medical_Evaluation__r.CMPL123CME__Complaint__c IN :ticketsToBeClosed
                AND (CMPL123_WF_Status__c LIKE 'Opened' OR CMPL123_WF_Status__c LIKE 'In Process')
                AND RecordTypeId = :RCMLTaskRecordTypeId
        ];

        //Calculation
        for (Medical_Evaluation_Task__c medEvalRCMLTask : openedRCMLTasks) {
            Id parentTicketId = medEvalRCMLTask.Medical_Evaluation__r.CMPL123CME__Complaint__c;
            if (!openedRCMLTasksCountPerTicket.containsKey(parentTicketId)) {
                openedRCMLTasksCountPerTicket.put(parentTicketId, 1);
            } else {
                openedRCMLTasksCountPerTicket.put(parentTicketId, openedRCMLTasksCountPerTicket.get(parentTicketId) + 1);
            }
        }

        //Errors assignments
        for (Id parentTicketId : openedRCMLTasksCountPerTicket.keySet()) {
            if (openedRCMLTasksCountPerTicket.get(parentTicketId) > 0) {
                newMap.get(parentTicketId).addError(System.label.All_RCML_tasks_should_be_closed);
            }
        }
    }

    /**
    * @Method       : identifyPromotedTickets
    * @Description  : used to identify promoted tickets
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestVisible
    public static void identifyPromotedTickets() {
        List<CMPL123CME__Complaint__c> newMap = (List<CMPL123CME__Complaint__c>)Trigger.New;
        Map<Id,CMPL123CME__Complaint__c> oldMap = (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap;
        if (Trigger.isUpdate) {
            Set<Id> promotedTicketIds = new Set<Id>();
            for (CMPL123CME__Complaint__c ticket : newMap) {
                if (ticket.Ticket_Type__c == 'Complaint'
                        && (ticket.Ticket_Type__c != oldMap.get(ticket.Id).Ticket_Type__c)) {
                    promotedTicketIds.add(ticket.Id);
                }
            }
            reopenVoidedTranslationTasks(promotedTicketIds, oldMap);
        }
    }

    /**
    * @Method       : reopenVoidedTranslationTasks
    * @Description  : used to reopen Voided during demotion Translation Tasks
    * @Return       : N/A
    * @Params       : Set<Id> promotedTicketIds,
    *                 Map <Id, CMPL123CME__Complaint__c> oldMap
    **/
    @TestVisible
    public static void reopenVoidedTranslationTasks(Set<Id> promotedTicketIds, Map <Id, CMPL123CME__Complaint__c> oldMap) {
        if (Trigger.isUpdate && !isTTReopened) {
            TicketUtil.addTrace('ComplaintTriggerHandler.reopenVoidedTranslationTasks' + promotedTicketIds);
            Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey = new Map<String,CMPL123__WF_Step__c>();
            String objAPIName = Translation_Task__c.SObjectType.getDescribe().getName();
            for(CMPL123__WF_Step__c objWFStep : [
                    SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                            CMPL123__WF_Rule__r.CMPL123__Target_Object__c, CMPL123__Start_Status__r.Name
                    FROM CMPL123__WF_Step__c
                    WHERE CMPL123__Start_Status__r.Name = 'Closed-Voided'
                    AND CMPL123__End_Status__r.Name = 'In Process'
                    AND CMPL123__Action__r.Name = 'Reopen'
                    AND CMPL123__WF_Rule__r.CMPL123__Is_Active__c = true
            ]){
                if(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c.substringBefore('(') == objAPIName){
                    mapWFStepWithRuleKey.put(objWFStep.CMPL123__WF_Rule__r.CMPL123__Target_Object__c,objWFStep);
                }
            }
            List<CMPL123__WF_History__c> lstWFHistories = new list<CMPL123__WF_History__c>();
            List<sObject> lstsObjects = new List<sObject>();
            Map<Id, String> demotionRationales = new Map<Id, String>();
            for (CMPL123CME__Complaint__c oldComplaint : oldMap.values()) {
                if (null != oldComplaint.Complaint_Demotion_rationale__c) {
                    demotionRationales.put(oldComplaint.Id, oldComplaint.Complaint_Demotion_rationale__c);
                }
            }

            for (sObject translationTask : [
                    SELECT Id, CMPL123Rule_Key_Value__c, Void_Rationale__c, Parent_Ticket__c FROM Translation_Task__c
                    WHERE  CMPL123_WF_Status__c = 'Closed-Voided'
                    AND Parent_Ticket__c IN :promotedTicketIds]){
                Id parentTicketId = (Id)translationTask.get('Parent_Ticket__c');
                if (demotionRationales.get(parentTicketId) != null
                        && demotionRationales.get(parentTicketId) == (String)translationTask.get('Void_Rationale__c')) {
                    String strKey = objAPIName + (String.valueOf(translationTask.get('CMPL123Rule_Key_Value__c')) != '' ?
                            '('+String.valueOf(translationTask.get('CMPL123Rule_Key_Value__c'))+')' : '');
                    if (mapWFStepWithRuleKey.containsKey(strKey)) {
                        lstsObjects.add(TicketUtil.populateWFFields(translationTask,
                                mapWFStepWithRuleKey.get(strKey).CMPL123__End_Status__r.Name ,
                                mapWFStepWithRuleKey.get(strKey).CMPL123__Action__r.Name));
                        lstWFHistories.add(TicketUtil.processAutomatedHistoryRecord(
                                String.valueOf(translationTask.get('Id')), mapWFStepWithRuleKey.get(strKey))
                        );
                    }
                }

            }

            if (lstsObjects.size() > 0) {
                update lstsObjects;
                insert lstWFHistories;
            }
            isTTReopened = true;
        }
    }

    /**
     * Does Workflow Rule logic with Apex code.
     * The Workflows were translated into Apex code because of performance issues.
     * @revision: 03-FEB-2023 Larry: Moved this portion of logic out of beforeEventHandler().
     * Added the assignment to the new "Previously Closed as Service Ticket" field.
     * Replaced magic words with constants.
     */
    @testVisible
    private static void doWorkflowRules(CMPL123CME__Complaint__c oldComplaint, CMPL123CME__Complaint__c complaint) {
        //Move SFDC WF Rules to Apex code BEGIN
        String wfAction = complaint.CMPL123CME__CMPL123_WF_Action__c;
        String wfStatus = complaint.CMPL123CME__CMPL123_WF_Status__c;

        //Clear ready for closure flag when ticket is reopened WF Rule
        if (wfAction != null &&
            wfAction != oldComplaint.CMPL123CME__CMPL123_WF_Action__c &&
            oldComplaint.Ready_to_Close__c == AspenConstants.STR_Yes &&
            (
                wfAction == AspenConstants.STR_WF_Action_FURTHER_ACT_REQ ||
                wfAction == AspenConstants.STR_Reopen ||
                wfAction == AspenConstants.STR_WF_Action_GO_TO_OPENED
            ))
        {
            complaint.Ticket_Close_Date__c = null;
        }

        //Set Complaint Complete Date WF Rule & When Complete action is performed Ready For Closure should be set to yes WF Rule
        if (wfAction != null &&
            wfAction != oldComplaint.CMPL123CME__CMPL123_WF_Action__c &&
            wfAction == AspenConstants.STR_WF_Action_Complete)
        {
            complaint.Complaint_Complete_Date__c = complaint.CMPL123CME__CMPL123_WF_Action_Performed_On__c.date();
            complaint.Ready_to_Close__c = AspenConstants.STR_Yes;
        }

        //Set Ticket Close Date WF Rule
        if (wfStatus != null &&
            wfStatus != oldComplaint.CMPL123CME__CMPL123_WF_Status__c &&
            wfStatus == AspenConstants.STR_Closed_Done)
        {
            complaint.Ticket_Close_Date__c = complaint.CMPL123CME__CMPL123_WF_Action_Performed_On__c;
            // 03-FEB-2023 Larry: Added this inner branch and assignment for the new field
            if (complaint.Ticket_Type__c == AspenConstants.STR_Service) {
                complaint.Previously_Closed_as_Service_Ticket__c = AspenConstants.STR_Yes;
            }
        }

        //Update pRE to Yes Date WF Rule (before update)
        if (complaint.pRE_Status__c != null &&
            complaint.pRE_Status__c != oldComplaint.pRE_Status__c &&
            complaint.pRE_Status__c == AspenConstants.STR_Yes)
        {
            complaint.pRE_to_Yes_Date__c = Date.today();
        }
    }
     
    /**
     * @Method       : beforeUpdateComplaintDateFields
     * @Description  : To Update "Original Ticket Close Date" field in Complaint Ticket when a Ticket is "Closed-Done" for the first Time. And update "Last Reopened date" field with current date in Complaint ticket when ever a Ticket is reopened. By Dinesh Kumar(COE)
     * @Params       : List<CMPL123CME__Complaint__c> complaints - List of ticket records of any type(CMPL123CME__Complaint__c)
     *                Map<Id,CMPL123CME__Complaint__c> complaintOldMap - Old map of ticket records(Ticket Id as key and Ticket record as value) which holds prior data
     * @Release      : CHARM 3.1
     */
    //Start - IPDR 506
    private static void beforeUpdateComplaintDateFields(List<CMPL123CME__Complaint__c> complaints,  Map<Id,CMPL123CME__Complaint__c> complaintOldMap){
        String oldComplaintStatus = null;
        for(CMPL123CME__Complaint__c complaint : complaints){
            if(complaint.Ticket_Type__c != AspenConstants.STR_Complaint){
                continue;
            }
            oldComplaintStatus = complaintOldMap.get(complaint.Id).CMPL123CME__CMPL123_WF_Status__c;
            Datetime complaintCreatedDate = complaint.CreatedDate;
            Datetime originalTicketCloseDateEffectiveFrom = ADDUtil.getOriginalTicketCloseDateEffectiveFrom();
            if(oldComplaintStatus != complaint.CMPL123CME__CMPL123_WF_Status__c 
               && complaint.Original_Ticket_Close_Date__c == null
               && complaint.CMPL123CME__CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Done
               && complaintCreatedDate >= originalTicketCloseDateEffectiveFrom){
                   complaint.Original_Ticket_Close_Date__c = ADDUtil.getCurrentDateInGMT();
            }
            if( oldComplaintStatus != complaint.CMPL123CME__CMPL123_WF_Status__c
               && oldComplaintStatus == AspenConstants.STR_WF_Closed_Done
               && complaint.CMPL123CME__CMPL123_WF_Status__c != AspenConstants.STR_WF_Closed_Voided){
                   complaint.Last_Reopened_Date__c = ADDUtil.getCurrentDateInGMT();
            }
        }
    }
    //End - IPDR 506
}