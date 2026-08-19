/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
 * @What  : ADDInvestigationHandler
 * @Why   : Class to Handle Different scenarios from Product Evaluation/Investigation Trigger
 * @When  : 23-MAR-2017
 * @Where : From CMPL123CME_Investigation_AuditTrigger Trigger, AspenConstants class,  TicketService class,
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID          Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *    Admin                 06-04-2017              Work ID / Case ID         Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *    RSlob                 03-18-2020              CR 1600-B                 Modified beforeUpdate() for CR 1600-B.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *    oivan                 02-MAR-2020             CHARM-1879 (CR 1600-B)    Modified
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 05-18-2020              Fix Def #102              Filtered out "Closed-Done" recodrs from validation scope.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *    DSkak                 04-06-2020              Code Audit                Removed 'System.debug()'.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 09-JUNE-2020            #123/CHARM-2729           Added parent ticket LastModifiedDate updating
 *   -------------------------------------------------------------------------------------------------------------------------------------
 *    RSlob                 15-06-2020              Code Audit                Removed commented code. Formatting.
 *   -------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 06-22-2020              #123.1/CHARM-2878         Added parent ticket custom Last Modified Date/Time field
 *                                                                            updating Changed updateTicketLastModifiedDate to generic.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 14-JUL-2020             #123.3/CHARM-3012         Adjusted custom Last Modified Date/Time field updating logic.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 05-JAN-2021             TWD Upgrade               Moved Prod Eval SF WF Rules into apex. Added
 *                                                                            beforeInsertEvent, beforeInsertOrUpdateEvent methods
 *                                                                            and their invocation.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 12-JAN-2021             UPGRD Def #92             Searchable Field Update PB logic upon insert/update
 *                                                                            of Prod Eval.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 19-JAN-2021             UPGRD Def #92             Adjusted updateTicketProductEvaluationInvestigation
 *                                                                            condition.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 22-JAN-2021            TWD Upgrade                Fixed mistakes in the beforeInsertOrUpdateEvent method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    rsitc                 28-JAN-2021            TWD Upgrade                Added Complaint_Description__c field into query of
 *                                                                            beforeInsertOrUpdateEvent method.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    Yadram                03-FEB-2022            CHaRM R2.1                 Defect 106. Removing task existence requirement.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    Larry Resnik          16-FEB-2022            CHaRM R2.1                 Defect 261. Product Evaluation/Investigation Tasks of type
 *                                                                            "Adverse Trend" will not be created anymore
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    Anshika               20-JUL-2022            CHaRM R2.2                 IPDR 400. Now Follow_Up_Awareness_Date__c populates correctly.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    Larry Resnik          21-NOV-2022            CHaRM R2.2.1               Defect 66. Fills in cumulative fields on insert.
 *                                                                            Existing debug statements now have LoggingLevel defined
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    Nicholas Sutanto      31-JAN-2023            CHaRM 3.0                  Defect 93. A parent ticket's investigation conclusion is 
 *                                                                            set to the highest priority conclusion disposition of its
 *                                                                            Closed-Done children investigation when the status of a
 *                                                                            child investigation is set to Closed-Done or Closed-Voided.
 * --------------------------------------------------------------------------------------------------------------------------------------
 *    Larry Resnik          05-JUN-2023            CHaRM 3.1                  Defect 299. updateMedEvals changed to make a new MedEval
 * if there are no MedEvals (existing functionality) or if all existing MedEvals are Closed-Voided.
 * --------------------------------------------------------------------------------------------------------------------------------------
     Charm COE               13-AUG-2025            IPDR-105                Updated the method "createProductLotFromProductTicket". Set the 
																			system-generated flag to true to indicate that this Product Lot 
																			was created programmatically.
* --------------------------------------------------------------------------------------------------------------------------------------
     Charm COE               16-JUN-2026            CHaRM R9.0/IPDR-539    Updated the method "afterUpdate".Removed invocation and 
																			commented the method Implementation of 
																			removeMDCMedicalEvaluator(complQualityClosedDateTicketMap.keySet()) 
																			from afterUpdate() method as it is no longer required.
 * --------------------------------------------------------------------------------------------------------------------------------------
 **/
public without sharing class ADDInvestigationHandler extends TriggerHandler {
    // MedEval WorkFlow Statuses which you can start in, and then progress to "In Process Evaluation".
    // This constant lets us tightly couple the logic between WorkFlow Step queries and MedEval processing.
    @testVisible private static final Set<String> MEDEVAL_WFSTATUS_TO_IN_PROCESS = new Set<String>{
        AspenConstants.STR_Regulatory, AspenConstants.STR_Closed_Done
    };
    // MedEval WorkFlow Actions which progress the record to the "In Process Evaluation" WorkFlow Status.
    @testVisible private static final Set<String> MEDEVAL_WFACTION_TO_IN_PROCESS = new Set<String>{
        AspenConstants.WF_ACTION_TO_PROC_EVAL, AspenConstants.STR_Reopen
    };
    public static final Double MS_IN_DAY = 86400000;
    Map<Id, CMPL123CME__Investigation__c> newInvMap;
    Map<Id, CMPL123CME__Investigation__c> oldInvMap;
    List<CMPL123CME__Investigation__c> newInvList;
    Map<Id, CMPL123CME__Complaint__c> updatableComplaintMap;
    Map<String, String> recordTypeMap;
    String thresholdRecordTypeId;
    String adverseRecordTypeId;

    //Recursion Handler
    public static Boolean executeOnce = false;
    @TestVisible
    public static Boolean executeOnceBeforeUpdate = false;

    // 28FEB19 - DEF#509 - Fix for TriggerOldMap
    public static Set<String> updatedFieldsSet = new Set<String>();

    /**
    * @Method       : constructor
    * @Invoke       : From CMPL123CME_Investigation_AuditTrigger Trigger
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
    // Constructor
    public ADDInvestigationHandler() {
        TicketUtil.addTrace('ADDInvestigationHandler.ADDInvestigationHandler');
        this.newInvMap = (Map<Id, CMPL123CME__Investigation__c>) Trigger.newMap;
        this.oldInvMap = (Map<Id, CMPL123CME__Investigation__c>) Trigger.oldMap;
        this.newInvList = (List<CMPL123CME__Investigation__c>) Trigger.new;
        Map<Id, CMPL123CME__Complaint__c> updatableComplaintMap = new Map<Id, CMPL123CME__Complaint__c>();
        if(recordTypeMap == null){
            recordTypeMap = ADDUtil.getRecordTypeMap(AspenConstants.STR_Object_Name);
            thresholdRecordTypeId = recordTypeMap.get(AspenConstants.STR_Record_Type_Threshold_Review);
            adverseRecordTypeId = recordTypeMap.get(AspenConstants.STR_Record_Type_Trend_Review_By_Prod_Number);
        }
    }

    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : Before Insert Trigger Event Handling Common Method
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void beforeInsert() {
        // #123.1/CHARM-2878: Last Modified Date/Time updating
        updateLastModifiedDateTime();
        beforeInsertEvent((List<CMPL123CME__Investigation__c>) Trigger.new);
        beforeInsertOrUpdateEvent();
        //addCurrentTimeToDateFields();
    }

    /**
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : After Insert Trigger Event Handling Common Method
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterInsert() {
        TicketUtil.addTrace('ADDInvestigationHandler.afterInsert');
        // 123 audit/workflow code
        system.debug(LoggingLevel.FINER, 'Limits - Before - afterInsertHnadler'+Limits.getCpuTime());
        CMPL123.AuditHandler.handleAudit();
        system.debug(LoggingLevel.FINER, 'Limits - After - afterInsertHnadler'+Limits.getCpuTime());

        createProductLotFromProductTicket(newInvList, true);
        // #123/CHARM-2729: added updatedTicketIds set
        Set<Id> updatedTicketIds = new Set<Id>();

        // 28FEB19 - 120 Removed Batch System record creation
        if(ComplaintTriggerHandler.systemProdEval) { return; }

        if(TicketUpdateUtility.executeFlag){
            TicketUpdateUtility.executeFlag = false;
            //Update parent ticket
            Set<Id> parentIds = new Set<Id>();
            List< CMPL123CME__Investigation__c > newInvestigations = (List< CMPL123CME__Investigation__c >)Trigger.New;
            for(CMPL123CME__Investigation__c objInvestigation : newInvestigations){
                parentIds.add(objInvestigation.CMPL123CME__Complaint__c);
            }
            if(parentIds != null && parentIds.size() > 0){
                // Call the utility method to update the parent
                // #123/CHARM-2729: added assignment of updated tickets to updatedTicketIds
                updatedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
            }
        }

        // #123/CHARM-2729: update ticket LastModifiedDate except updatedTicketIds
        UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, updatedTicketIds, 'CMPL123CME__Complaint__c', true);
    }

    /**
     * @Method       : beforeUpdate
     * @Invoke       : Events from TriggerHandler before update
     * @Description  : Before Insert Trigger Event Handling Common Method
     * @Return       : N/A
     * @Params       : N/A
     * @Revision     : 31-JAN-2023 Danny: Workflow Status is now also added to updatedFieldsSet when status is changed to Closed-Voided instead of only Closed-Done
     **/
    public override void beforeUpdate() {

        Integer intBeforeCustomLimits = 0;
        Integer intBeforeProductLimits = 0;
        intBeforeCustomLimits = Limits.getCpuTime();
        // 28FEB19 - 120 Removed Batch System record creation
        // #123.1/CHARM-2878: Last Modified Date/Time updating
        updateLastModifiedDateTime();

        if(ComplaintTriggerHandler.systemProdEval) { return; }

        TicketUtil.addTrace('ADDInvestigationHandler.beforeUpdate');

        /* #123/CHARM-2729: added !UpdateParentUtility.isInvestigationLastModifDateUpdating condition to skip logic if only
        LastModifiedDate is updated through UpdateParentUtility*/
        if(!executeOnceBeforeUpdate && !UpdateParentUtility.isInvestigationLastModifDateUpdating){
            executeOnceBeforeUpdate = true;
            Set<String> ticketIds = new Set<String>();
            //Added - W-000344 - Start
            Set<String> setClosedVoidedticketIds = new Set<String>();
            //Added - W-000344 - End

            //Added - W-000094 - Start
            Set<Id> setDemotedToServiceEvaluations = new Set<Id>();
            //Added - W-000094 - End

            Set<String> investigationsWithNoTasks = new Set<String> ();
            Set<String> investigationsWithPendingTasks = new Set<String> ();
            Set<String> investigationsWithThresholdReveiewConclusion = new Set<String> ();
            Set<String> investigationsWithThresholdExceededActiveTasks = new Set<String> ();
            Set<Id> invPendingTickets = new Set<Id>();
            Set<Id> investigationWithNonClosedTasks = new Set<Id>();
            //Added - W-000089 - proper message to identify which mandatory tasks does not exists - Start
            Map<Id, String> mapRequiredTaskNamesForInvestigation = New Map<Id, String>();
            //Added - W-000089 - proper message to identify which mandatory tasks does not exists - End

            // Added - W-000078 -  Added inner query ((SELECT Id FROM Product_Lots__r WHERE Product_Evaluation_Investigation__r.CMPL123CME__Complaint__r.Overall_Reportable_Status__c ='Reportable'
            // AND ((Device_Manufacturing_Date__c != Null OR Device_Manufacturing_Date_NA__c != True OR Device_Manufacturing_Date_Unknown__c != True) )
            //Added - W-000089 query filter - WHERE Task__r.CMPL123_WF_Status__c !=: AspenConstants.STR_Closed_Voided
            //This for loop iterates over the Product Evalutaion/ Investigation  Id's Which are in newInvMap Id's.
            //addCurrentTimeToDateFields();
            for(CMPL123CME__Investigation__c inv : [
                SELECT Id, Prod_eval_KI_Log__c,CMPL123CME__Complaint__r.Complaint_Demotion_rationale__c,CMPL123_WF_Action__c,CMPL123CME__Complaint__c,
                CMPL123CME__Complaint__r.CMPL123CME__CMPL123_WF_Status__c,CMPL123CME__Complaint__r.Ticket_Type__c,
                (SELECT Id, Task__r.CMPL123_WF_Status__c, Task__r.Threshold_Review_Conclusion__c,
                Task__r.RecordTypeId FROM Related_Product_Evaluation_Investigation__r WHERE Task__r.CMPL123_WF_Status__c !=: AspenConstants.STR_Closed_Voided ),
                (SELECT Id FROM Product_Lots__r WHERE
                ((Device_Manufacturing_Date__c = Null AND Device_Manufacturing_Date_NA__c != true AND Device_Manufacturing_Date_Unknown__c != true)
                OR (Device_Expiration_Date__c = Null AND Device_Expiration_Date_NA__c != true AND Device_Expiration_Date_Unknown__c != true)))
                FROM CMPL123CME__Investigation__c WHERE Id IN :newInvMap.keyset()])
            {
                Boolean hasComplaintSummaryTask = false;
                Boolean hasLableReviewTask = false;
                Boolean hasLotOrListTask = false;
                // This following if loop is to get all the Product Evalutaion/ Investigation with no tasks.
                if(inv.Related_Product_Evaluation_Investigation__r.size() == 0 && !inv.Prod_eval_KI_Log__c) {
                    investigationsWithNoTasks.add(inv.Id);
                }

                //Autoset Approval Date,Quality Notes on Prod eval closed-done (Addded on 22-03-2019)
                if((newInvMap.get(inv.Id).CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done || newInvMap.get(inv.Id).CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided) 
                        && oldInvMap.get(inv.Id).CMPL123_WF_Status__c != newInvMap.get(inv.Id).CMPL123_WF_Status__c){
                    // MR - 02APR19 - Added for DEF#509
                    updatedFieldsSet.add('CMPL123_WF_Status__c');

                    if (newInvMap.get(inv.Id).CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done) {
                        newInvMap.get(inv.Id).Approval_Date__c = System.today();
                        newInvMap.get(inv.Id).Quality_Notes__c = null;
                    }
                }

                // MR - 02APR19 - Added for DEF#509
                if(oldInvMap.get(inv.Id).CMPL123_WF_Action__c != newInvMap.get(inv.Id).CMPL123_WF_Action__c){
                    updatedFieldsSet.add('CMPL123_WF_Action__c');
                }
                if(oldInvMap.get(inv.Id).Prod_Eval_Returns_to_be_Requested__c != newInvMap.get(inv.Id).Prod_Eval_Returns_to_be_Requested__c){
                    updatedFieldsSet.add('Prod_Eval_Returns_to_be_Requested__c');
                }

                // Added - W-000051 - Start
                if(inv.CMPL123CME__Complaint__c != null){
                    // Added - W-000051 - Start
                    ticketIds.add(inv.CMPL123CME__Complaint__c);
                    //Added - W-000344 - Start
                    if(inv.CMPL123CME__Complaint__r.CMPL123CME__CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided){
                        setClosedVoidedticketIds.add(inv.CMPL123CME__Complaint__c);
                    }
                    //Added - W-000344 - End

                    //Added - W-000094 - Start
                    //If loop to collect all the DemoteToServiceEvaluations Id's
                    if(inv.CMPL123CME__Complaint__r.Complaint_Demotion_rationale__c != null && inv.CMPL123CME__Complaint__r.Complaint_Demotion_rationale__c != '' &&  inv.CMPL123CME__Complaint__r.Ticket_Type__c == AspenConstants.STR_Service){
                        setDemotedToServiceEvaluations.add(inv.Id);
                    }
                    //Added - W-000094 - End
                }

                // Added - W-000078 - Start
                // The following if is to throw a error message for required fields when the Workflow action is performed on the particular Product evaluation/i nvestigation record.
                if((inv.Product_Lots__r.size() > 0
                    && (newInvMap.get(inv.id).CMPL123_WF_Action__c == AspenConstants.STR_Invest_Req || newInvMap.get(inv.id).CMPL123_WF_Action__c== AspenConstants.STR_No_Invest_Req)
                    && newInvMap.get(inv.id).CMPL123_WF_Action__c != oldInvMap.get(inv.id).CMPL123_WF_Action__c)){
                        //TBD : custom label
                        newInvMap.get(inv.id).addError(System.Label.Product_evaluation_Investigation_Required_Fields);
                    }
                // Added - W-000078 - End

                //follwing for loop iterates over the related Task - Product Evaluation/Investigation
                for(Task_Product_Evaluation_Investigation__c task : inv.Related_Product_Evaluation_Investigation__r) {

                    //TODO whether applicable only for selected record types or for all.


                    if(task.Task__r.RecordTypeId != thresholdRecordTypeId &&
                        task.Task__r.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Done
                        && task.Task__r.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Voided
                        && !inv.Prod_eval_KI_Log__c) {
                            investigationsWithPendingTasks.add(inv.Id);
                        }
                    //Added - W-000058 - added filter - Start
                    if(task.Task__r.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Done
                        && task.Task__r.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Voided
                        && inv.Prod_eval_KI_Log__c == true){
                            investigationsWithPendingTasks.add(inv.Id);
                        }
                    //Added - W-000058 - added filter - End
                    if(task.Task__r.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Done
                        && task.Task__r.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Voided ){
                            investigationsWithPendingTasks.add(inv.Id);
                        }

                    // Condition c
                    if(!inv.Prod_eval_KI_Log__c){
                        // Condition B
                        // Following if Collects all the product Evaluation records with the field "Threshold_Review_Conclusion__c != null"
                        if(task.Task__r.RecordTypeId == thresholdRecordTypeId
                            && task.Task__r.Threshold_Review_Conclusion__c != AspenConstants.STR_Complaint_does_not_exceed_the_threshold
                            && task.Task__r.Threshold_Review_Conclusion__c != null) {
                                investigationsWithThresholdReveiewConclusion.add(inv.Id);
                                if (!task.Task__r.CMPL123_WF_Status__c.startsWith('Closed')) { // exclude closed tasks
                                investigationsWithThresholdExceededActiveTasks.add(inv.Id);
                                }
                            }
                        //sets flag in the else section.
                        else if(task.Task__r.RecordTypeId == thresholdRecordTypeId
                                && task.Task__r.Threshold_Review_Conclusion__c == AspenConstants.STR_Complaint_does_not_exceed_the_threshold) {
                                    hasComplaintSummaryTask = true; hasLableReviewTask = true; hasLotOrListTask = true;
                                }

                        // Doesn't have to check Condition A if Condition B is already executed
                        // Added - W-000089 - If Condition check based on the code review feedback
                        if((hasComplaintSummaryTask == false || hasLableReviewTask == false || hasLotOrListTask == false) || !investigationsWithThresholdReveiewConclusion.contains(inv.Id)){
                            // Condition A - This was not changed because it was already existing
                            if(recordTypeMap.get(task.Task__r.RecordTypeId) == AspenConstants.STR_Complaint_Desc_Or_Attachment_Review) {
                                hasComplaintSummaryTask = true;
                            } else if(recordTypeMap.get(task.Task__r.RecordTypeId) == AspenConstants.STR_Labeling_Review) {
                                hasLableReviewTask = true;
                            } else if(recordTypeMap.get(task.Task__r.RecordTypeId) == AspenConstants.STR_Ticket_History_Review_By_Lot_Number
                                        || recordTypeMap.get(task.Task__r.RecordTypeId) == AspenConstants.STR_Ticket_History_Review_By_Prod_Lst_Number) {
                                            hasLotOrListTask = true;
                                        }
                        }
                    }
                }
                //Following if is to check hasComplaintSummaryTask,hasLableReviewTask,hasLotOrListTask flags and collects all the requiredTasks For Investigation.
                if(!inv.Prod_eval_KI_Log__c){
                    //Added - W-000089 - proper message to identify which mandatory tasks does not exists - Start
                    String strRequiredTasks = '(';
                    if(!hasComplaintSummaryTask){
                        strRequiredTasks += AspenConstants.STR_Complaint_Desc_Or_Attachment_Review+' ';
                    }
                    if(!hasLableReviewTask){
                        strRequiredTasks += (strRequiredTasks != '(' ? ',' : '')+AspenConstants.STR_Labeling_Review+' ';
                    }
                    if(!hasLotOrListTask){
                        strRequiredTasks += (strRequiredTasks != '(' ? ',' : '')+AspenConstants.STR_Ticket_History_Review_By_Lot_Number_Or_Prod_List_Number;
                    }
                    strRequiredTasks += ')';
                    //Added - W-000089 - proper message to identify which mandatory tasks does not exists - End

                    if(!hasComplaintSummaryTask || !hasLableReviewTask || !hasLotOrListTask) {
                        //Added - W-000089 - proper message to identify which mandatory tasks does not exists - Start
                        mapRequiredTaskNamesForInvestigation.put(inv.Id, strRequiredTasks);
                        //Added - W-000089 - proper message to identify which mandatory tasks does not exists - End
                    }
                }
            }

            //Updated - W-000051 - donot consider voided complaint -
            for(CMPL123CME__Complaint__c objComplaint : [
                SELECT Id, (SELECT Id FROM Ticket_Product_Evaluation_Investigation__r
                            WHERE Investigation_Evaluation__c NOT IN: newInvMap.keyset() AND
                            Investigation_Evaluation__r.CMPL123_WF_Status__c != : AspenConstants.STR_Closed_Voided) FROM
                CMPL123CME__Complaint__c WHERE Id IN :ticketIds AND Ticket_Type__c = :AspenConstants.STR_Complaint
                AND CMPL123CME__CMPL123_WF_Status__c != :AspenConstants.STR_Closed_Voided])
            {
                if(objComplaint.Ticket_Product_Evaluation_Investigation__r.size() == 0){
                    invPendingTickets.add(objComplaint.Id);
                }
            }
            // for loop to iterate over the Product Evaluation / Investiagtion Records in Trigger.new
            for(CMPL123CME__Investigation__c investigation : newInvList){
                CMPL123CME__Investigation__c oldInv = oldInvMap.get(investigation.Id);

                //Added - W-000270 - Is Investigation Required? to Yes, then No Investigation Rationale = Blank - Start
                if(investigation.Is_Investigation_Required__c == AspenConstants.STR_Yes){
                    investigation.No_Investigation_Rationale__c = '';
                }
                //Added - W-000270  Is Investigation Required? to Yes, then No Investigation Rationale = Blank - End

                //Added - W-000124 - Update closed date - Start
                if((investigation.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done
                    || investigation.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided)
                   && oldInv.CMPL123_WF_Status__c != investigation.CMPL123_WF_Status__c ){
                       investigation.Closed_Date__c = system.today();
                   }
                // following if is to update reopen date.
                if(investigation.CMPL123_WF_Action__c == AspenConstants.STR_Reopen_Go_To_Conclude
                   && oldInv.CMPL123_WF_Action__c != investigation.CMPL123_WF_Action__c ){
                       investigation.Reopened_Date__c = system.today();
                   }
                //Added - W-000124 - Update closed date - End

                //setting product ticket name as prod eval name.
                //The folowing if performs the validations and throws the warning message when you try to perform "Submit for Review" Action.
                //03-FEB-2022 Yadram : Defect 106. Removing task existence requirement.
                /*if(investigation.CMPL123_WF_Action__c == AspenConstants.STR_Submit_for_Review
                   && oldInv.CMPL123_WF_Action__c != investigation.CMPL123_WF_Action__c) {

                       if (investigationsWithNoTasks.contains(investigation.Id)) {
                           investigation.addError(System.label.Product_evaluation_Investigation_No_Task_Exist);
                       }
                       else if (investigationsWithPendingTasks.contains(investigation.Id)) {
                           investigation.addError(System.label.Product_evaluation_Investigation_No_Task_Closed);
                       }
                       else if (investigationsWithThresholdExceededActiveTasks.contains(investigation.Id)) {
                           investigation.addError(System.Label.Product_evaluation_Investigation_Threshold_exceeded);
                       }
                       else if (!mapRequiredTaskNamesForInvestigation.isEmpty() && mapRequiredTaskNamesForInvestigation.containsKey(investigation.Id)) {
                           //Added - W-000089 - proper message to identify which mandatory tasks does not exists -Start
                           String strErrorMessage = System.Label.Product_evaluation_Investigation_Minimum_Required_Tasks;
                           strErrorMessage += mapRequiredTaskNamesForInvestigation.get(investigation.Id);
                           investigation.addError(
                               strErrorMessage , false
                           );
                           //Added - W-000089 - proper message to identify which mandatory tasks does not exists -End
                       }
                       //foo=llowing if is to check if there are any pending tasks and throws a warning message.
                   }
                else*/
                if(!Test.isRunningTest() && investigation.CMPL123_WF_Status__c == AspenConstants.STR_Conclude
                            && oldInv.CMPL123_WF_Status__c != investigation.CMPL123_WF_Status__c
                            && investigationsWithPendingTasks.contains(investigation.Id)){
                                investigation.addError(System.Label.Product_evaluation_Investigation_All_Existing_Task_Not_Closed);

                                //Added - W-000344 -
                                //following if is to check  if the void action is performed on Product Evaluation / invetsigation record.
                            }
                else if(!Test.isRunningTest() && investigation.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided
                                     && oldInv.CMPL123_WF_Status__c != investigation.CMPL123_WF_Status__c
                                     && investigation.System_Integration_Generated_Flag__c
                                     //&& investigation.Source_Leveraged__c == AspenConstants.STR_Source
                                     && !setClosedVoidedticketIds.contains(investigation.CMPL123CME__Complaint__c)
                                     //Added - W-000094 - prevent error for demote to service complaint
                                     && !setDemotedToServiceEvaluations.contains(investigation.Id)){
                                         investigation.addError(
                                             System.Label.Product_evaluation_Investigation_Voiding_System_Generated);

                                         //Added - W-000344
                                     }
                else if(!Test.isRunningTest() && investigation.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided
                                               && oldInv.CMPL123_WF_Status__c != investigation.CMPL123_WF_Status__c
                                               && invPendingTickets.contains(investigation.CMPL123CME__Complaint__c)
                                               //Added - W-000094 - prevent error for demote to service complaint
                                               && !setDemotedToServiceEvaluations.contains(investigation.Id)){
                                                   investigation.addError(
                                                       System.Label.Product_evaluation_Investigation_Voiding_Not_Allowed );
                                                   //W-1424, updated - W-000051 - proper message
                                               }

            }

            // 1600-B CR start. Complaint_Evaluator_Investigator and Quality_Complaint_Approver should be able to edit only few fields in this status.
            // Other users should not be able to edit any fields - is from disabled Validation rule PordEval_Not_Editable_PEREview_Status
            List <PermissionSetAssignment> currentUserPermissionSetAssignments = [
                        SELECT Id, PermissionSet.Name
                        FROM PermissionSetAssignment
                        WHERE AssigneeId = :UserInfo.getUserId()
            ];
            List <String> currentUserPermissionSetNames = new List <String> ();
            for (PermissionSetAssignment psa : currentUserPermissionSetAssignments) {
                currentUserPermissionSetNames.add(psa.PermissionSet.Name);
            }

            // Validate record edit scenarios such that an authorized user can perform “Submit for Review” action to
            // move a Product Evaluation record from “Conclude” status to “PE Review” status and lock the record except
            // the Reject Rationale and Approver fields.  This is required to allow the ADD Business to update the
            // Rejection Rationale and Approver fields on respective Object records in the event a Business Assignee/Approver
            // is out of the office or has left their role in the company.

            if(!currentUserPermissionSetNames.contains('Quality_Complaint_Approver')){
                CustomRecordLockingUtil.validateRecordEdit(Trigger.NewMap,
                    Trigger.OldMap,
                    new List <String>{'PE Review'},
                    new List <String>{'Complaint_Evaluator_Investigator'},
                    new List <String>{'Approver__c', 'Assigned_Approver__c', 'Approver_Name__c', 'No_Investigation_Rationale__c'});
            }
            if(!currentUserPermissionSetNames.contains('Complaint_Evaluator_Investigator')){
                CustomRecordLockingUtil.validateRecordEdit(Trigger.NewMap,
                    Trigger.OldMap,
                    new List <String>{'PE Review'},
                    new List <String>{'Quality_Complaint_Approver'},
                    new List <String>{'Rejection_Rationale__c', 'No_Investigation_Rationale__c', 'Rejection_Reason__c'});
            }
            //1600-B CR end

            // 21-NOV-2022 Larry: Added this fn call
            setCumulsOnEachProdEval((Map<Id, CMPL123CME__Investigation__c>) Trigger.oldMap,
                (List<CMPL123CME__Investigation__c>) Trigger.new);
        }
        intBeforeCustomLimits = Limits.getCpuTime() - intBeforeCustomLimits;

        system.debug(LoggingLevel.FINER, 'intBeforeCustomLimits -->'+ intBeforeCustomLimits);
        setReopenRationale(newInvMap, oldInvMap);
        beforeInsertOrUpdateEvent();
        intBeforeProductLimits = Limits.getCpuTime();
        CMPL123.AuditHandler.handleAudit();
        intBeforeProductLimits = Limits.getCpuTime() - intBeforeProductLimits;
        system.debug(LoggingLevel.FINER, 'intBeforeProductLimits -->'+ intBeforeProductLimits);
        //123 audit/workflow code
    }

    /**
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event
    * @Return       : N/A
    * @Params       : N/A
    * @Revision     : 23-JAN-2023 Danny: Run chooseHighestPriority for all investigations under a ticket isntead of just the one most recent investigation.
    **/
    public override void afterUpdate() {
        Integer intAfterCustomLimits = 0;
        Integer intAfterProductLimits = 0;
        updateTicketProductEvaluationInvestigation();
        // 28FEB19 - 120 Removed Batch System record creation
        if(ComplaintTriggerHandler.systemProdEval) { return; }

        TicketUtil.addTrace('ADDInvestigationHandler.afterUpdate');

        //123 audit/workflow code
        intAfterProductLimits = Limits.getCpuTime();
        CMPL123.AuditHandler.handleAudit();
        intAfterProductLimits = Limits.getCpuTime() - intAfterProductLimits;
        system.debug(LoggingLevel.FINER, 'intAfterProductLimits -->'+ intAfterProductLimits);

        Set<String> complaintIds = new Set<String>();
        Set<String> updatableComplaintIds = new Set<String>();
        Map<String, DateTime> ticketIdWithDateMap = new Map<String, DateTime>();
        Set<String> closedIds = new Set<String>();
        Set<Id> parentIds = new Set<Id>();
        //Added - W-000162 -Start
        Map<String, Date> ticketIdForClosedDate = new Map<String, Date>();
        //Added - W-000162 -End
        //Added on 08 FEB 2019
        List<Activity__c> lstActivities = new List<Activity__c>();
        // #123/CHARM-2729: added updatedTicketIds set
        Set<Id> updatedTicketIds = new Set<Id>();

        intAfterCustomLimits = Limits.getCpuTime();

        //Added W-000346
        /* #123/CHARM-2729: added !UpdateParentUtility.isInvestigationLastModifDateUpdating condition to skip logic if only
        LastModifiedDate is updated through UpdateParentUtility*/
        if (Trigger.isUpdate && !executeOnce && !UpdateParentUtility.isInvestigationLastModifDateUpdating) {
            //Added : W-000346 - Recursion handler
            executeOnce = true;
            //Added : W-000346 - Recursion handler

            List<sobject> updatableComplaints = new List<sobject>();
            Map<Id, Id> invWithTicketMap = new Map<Id, Id>();
            //Added : W-000332
            Map<Id, CMPL123CME__Complaint__c> complQualityClosedDateTicketMap = new Map<Id, CMPL123CME__Complaint__c>();
            for(CMPL123CME__Investigation__c investigation : newInvList) {
                parentIds.add(investigation.CMPL123CME__Complaint__c);
                // following Collects all the related Complaint Id with action Performed and Investigation Closed Date.
                if (investigation.CMPL123CME__Complaint__c != null && (investigation.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done
                                                                       || investigation.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided) && oldInvMap != null
                    // MR - 02APR19 - DEF#509 Fix
                      && updatedFieldsSet.contains('CMPL123_WF_Status__c')) {
                    complaintIds.add(investigation.Id);

                    if(investigation.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done && investigation.CMPL123_WF_Action_Performed_On__c != null) {
                        ticketIdWithDateMap.put(investigation.CMPL123CME__Complaint__c, investigation.CMPL123_WF_Action_Performed_On__c);
                        // closedIds only contains the one Investigation Id that was most recently changed because newInvList only contains the updated investigation.
                        closedIds.add(investigation.Id);
                    }

                    //Added - W-000162 -Start
                    if(investigation.Closed_Date__c != null){
                        ticketIdForClosedDate.put(investigation.CMPL123CME__Complaint__c,investigation.Closed_Date__c);
                    }
                    //Added - W-000162 -End
                }

                //US-1210, AC-8
                //following if collects all the updatable complaint Id's
                if((investigation.Prod_Eval_Returns_to_be_Requested__c == AspenConstants.STR_No
                   // MR - 02APR19 - DEF#509 Fix
                    && updatedFieldsSet.contains('Prod_Eval_Returns_to_be_Requested__c'))
                    || updatedFieldsSet.contains('CMPL123_WF_Status__c')) {
                       updatableComplaintIds.add(investigation.CMPL123CME__Complaint__c);
                   }

                //Added -  W-000199 - Filter updated
                if (updatedFieldsSet.contains('CMPL123_WF_Status__c') && investigation.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done
                    && (investigation.Conclusion_Disposition__c == AspenConstants.STR_80067_Deficiency_Malfunction ||
                        investigation.Conclusion_Disposition__c == AspenConstants.STR_80064_NO_Deficiency_Malfunction)) {
                            invWithTicketMap.put(investigation.Id, investigation.CMPL123CME__Complaint__c);
                        }
                //Added : W-000332, W-000422
                if(investigation.CMPL123CME__Complaint__c != null && (investigation.CMPL123_WF_Action__c == AspenConstants.STR_Reopen || investigation.CMPL123_WF_Action__c == AspenConstants.STR_Reopen_Go_To_Conclude ) && oldInvMap.get(investigation.Id).CMPL123_WF_Action__c != investigation.CMPL123_WF_Action__c ){
                    complQualityClosedDateTicketMap.put(investigation.CMPL123CME__Complaint__c, new CMPL123CME__Complaint__c(Id = investigation.CMPL123CME__Complaint__c, Complaint_Quality_Closure_Date__c = null, Investigation_Status__c = investigation.CMPL123_WF_Status__c));
                }

            }
            if(!complQualityClosedDateTicketMap.isEmpty()){
                // Not multiple Tickets - TBD
                CMPL123CME__Complaint__c objComplaint = complQualityClosedDateTicketMap.values()[0];
                objComplaint.Investigation_Status__c = reOrderTicketInvestigationStatus(objComplaint.Id);
                complQualityClosedDateTicketMap.put(objComplaint.Id, objComplaint);

                Update complQualityClosedDateTicketMap.values();
                //Charm R9.0/IPDR-539 - Removed call to removeMDCMedicalEvaluator(complQualityClosedDateTicketMap.keySet()), as this logic is no longer required per updated requirements.
            }

            if(complaintIds.size() > 0) {
                Set<String> possibleTicketIds = new Set<String>();
                for (Ticket_Product_Evaluation_Investigation__c tp : [
                    SELECT Ticket__c, Investigation_Evaluation__c
                    FROM Ticket_Product_Evaluation_Investigation__c
                    WHERE Investigation_Evaluation__c IN :complaintIds
                ]) {
                    possibleTicketIds.add(tp.Ticket__c);
                }
                // gets the Compalint Id's and calls the CustomerResponseTriggerHandler method to complete the Tickets.
                if (possibleTicketIds.size() > 0) {
                    CustomerResponseTriggerHandler.processEligibleComplaintsToComplete(possibleTicketIds);
                }
            }

            //US-1210, AC-8 , line 35-43
            if(updatableComplaintIds.size() > 0 || ticketIdWithDateMap.keyset().size() > 0) {

                Set<String> allTicketIds = new Set<String>();
                allTicketIds.addAll(updatableComplaintIds);
                allTicketIds.addAll(ticketIdWithDateMap.keyset());
                //Added -  W-000162 - Query updated - Follow_Up_Awareness_Date__c = null
                //20-JUL-2022 Anshika IPDR 400: Follow_Up_Awareness_Date__c was added to the subquery for MedEvals.
                for(CMPL123CME__Complaint__c ticket : [
                    Select Id, Investigation_Conclusion__c, Returns_to_be_Requested__c,
                   (Select Id, Name, Prod_Eval_Returns_to_be_Requested__c,CMPL123_WF_Status__c, Conclusion_Summary__c,
                    Conclusion_Disposition__c,Source_Leveraged__c,Product_Evaluation_Type__c,Evaluation_Start_date__c,Investigation_Completed_On__c From CMPL123CME__Investigations__r),
                   (SELECT Id, Follow_Up_Awareness_Date__c FROM CMPL123CME__Questionnaires__r WHERE (CMPL123_WF_Status__c !=: AspenConstants.STR_Closed_Done AND CMPL123_WF_Status__c !=: AspenConstants.STR_Closed_Voided AND Follow_Up_Awareness_Date__c = null  ))
                   From CMPL123CME__Complaint__c Where Id IN :allTicketIds
                ]){
                    //Added W-000057
                    CMPL123CME__Complaint__c updatableTicket = new CMPL123CME__Complaint__c(Id = ticket.Id, Investigation_Conclusion__c = ticket.Investigation_Conclusion__c);
                    Activity__c objActivity = new Activity__c(Complaint__c = ticket.Id, Activity_Type__c = 'QA',Work_Done_Likely_Cause__c =  'Yes');
                    Boolean returnsNotRequested = true;
                    Boolean allClosed = true;
                    String conclusionSummary = '';
                    String investigationConclusion;

                    //following for iterates over the Invistogations related to the compalint. Updates all the complaint tickets with the assigned values.
                    for(CMPL123CME__Investigation__c inv : ticket.CMPL123CME__Investigations__r){
                        if(inv.Conclusion_Summary__c != null){
                            conclusionSummary += inv.Conclusion_Summary__c + AspenConstants.STR_New_Line;
                        }
                        if(inv.Prod_Eval_Returns_to_be_Requested__c == AspenConstants.STR_Yes){
                            returnsNotRequested = false;
                        }
                        if(inv.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Done && inv.CMPL123_WF_Status__c != AspenConstants.STR_Closed_Voided){
                            allClosed = false;
                        }

                        if(inv.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done){
                            // Added Defect 93: Select the highest priority investigation conclusion from a parent ticket's Closed-Done child investigations.
                            investigationConclusion = chooseHighestPriority(investigationConclusion, inv.Conclusion_Disposition__c);
                        }

                        //Added W-000057
                        if(closedIds.contains(inv.Id)){
                            if(inv.Conclusion_Disposition__c == AspenConstants.STR_80067_Deficiency_Malfunction){
                                // As above criteria reopen/create new med eval, clear Medical_Eval_Close_Date__c on complaint
                                if(!ticketIdWithDateMap.isEmpty()){
                                    updatableTicket.Medical_Eval_Close_Date__c = null;
                                }
                                objActivity.Work_Done_Description__c = inv.Product_Evaluation_Type__c;
                                objActivity.Work_Done_Code__c = AspenConstants.STR_80067_CODE;   // 13MAR19 - Added for DEF#552
                                objActivity.Start_Date_Time__c = inv.Evaluation_Start_date__c;
                                objActivity.End_Date_Time__c = inv.Investigation_Completed_On__c;
                                lstActivities.add(objActivity);
                                //Added W-000417
                            }else if(inv.Conclusion_Disposition__c == AspenConstants.STR_80064_NO_Deficiency_Malfunction && updatableTicket.Investigation_Conclusion__c != AspenConstants.STR_80067_Deficiency_Malfunction ){
                                objActivity.Work_Done_Description__c = inv.Product_Evaluation_Type__c;
                                objActivity.Work_Done_Code__c = AspenConstants.STR_80064_CODE;   // 13MAR19 - Added for DEF#552
                                objActivity.Start_Date_Time__c = inv.Evaluation_Start_date__c;
                                objActivity.End_Date_Time__c = inv.Investigation_Completed_On__c;
                                lstActivities.add(objActivity);
                            }else if(inv.Conclusion_Disposition__c == AspenConstants.STR_80065_NO_Deficiency_Malfunction_Defect_Distribution_Issue && updatableTicket.Investigation_Conclusion__c != AspenConstants.STR_80064_NO_Deficiency_Malfunction && updatableTicket.Investigation_Conclusion__c != AspenConstants.STR_80067_Deficiency_Malfunction ){
                                objActivity.Work_Done_Description__c = inv.Product_Evaluation_Type__c;
                                objActivity.Work_Done_Code__c = AspenConstants.STR_80065_CODE;   // 13MAR19 - Added for DEF#552
                                objActivity.Start_Date_Time__c = inv.Evaluation_Start_date__c;
                                objActivity.End_Date_Time__c = inv.Investigation_Completed_On__c;
                                lstActivities.add(objActivity);
                            }else if(inv.Conclusion_Disposition__c == AspenConstants.STR_80066_NO_Deficiency_NO_Malfunction && updatableTicket.Investigation_Conclusion__c == null ){
                                objActivity.Work_Done_Description__c = inv.Product_Evaluation_Type__c;
                                objActivity.Work_Done_Code__c = AspenConstants.STR_80066_CODE;   // 13MAR19 - Added for DEF#552
                                objActivity.Start_Date_Time__c = inv.Evaluation_Start_date__c;
                                objActivity.End_Date_Time__c = inv.Investigation_Completed_On__c;
                                lstActivities.add(objActivity);
                            }else if(inv.Conclusion_Disposition__c == AspenConstants.STR_80069_Non_Medical_Device_Product_Problem){
                                objActivity.Work_Done_Description__c = inv.Product_Evaluation_Type__c;
                                objActivity.Work_Done_Code__c = AspenConstants.STR_80069_CODE;   // 13MAR19 - Added for DEF#552
                                objActivity.Start_Date_Time__c = inv.Evaluation_Start_date__c;
                                objActivity.End_Date_Time__c = inv.Investigation_Completed_On__c;
                                lstActivities.add(objActivity);
                            }else if(inv.Conclusion_Disposition__c == AspenConstants.STR_80068_Non_Medical_Device_NO_Product_Problem && updatableTicket.Investigation_Conclusion__c == null){
                                objActivity.Work_Done_Description__c = inv.Product_Evaluation_Type__c;
                                objActivity.Work_Done_Code__c = AspenConstants.STR_80068_CODE;   // 13MAR19 - Added for DEF#552
                                objActivity.Start_Date_Time__c = inv.Evaluation_Start_date__c;
                                objActivity.End_Date_Time__c = inv.Investigation_Completed_On__c;
                                lstActivities.add(objActivity);
                            }
                        }
                    }
                    updatableTicket.Investigation_Conclusion__c = investigationConclusion;

                    if(returnsNotRequested && updatableComplaintIds.contains(ticket.Id)){
                        updatableTicket.Returns_to_be_Requested__c = AspenConstants.STR_No;
                    }

                    if(allClosed){
                        updatableTicket.Investigation_Status__c = AspenConstants.STR_Closed_Done;
                        updatableTicket.Conclusion_Summary__c = conclusionSummary;
                    }
                    if(ticketIdWithDateMap.keyset().contains(ticket.Id) && ticketIdWithDateMap.get(ticket.Id) != null){
                        updatableTicket.Complaint_Quality_Closure_Date__c = ticketIdWithDateMap.get(ticket.Id);
                    }
                    //Added - W-000162
                    if(!ticketIdForClosedDate.isEmpty() && ticketIdForClosedDate.containsKey(ticket.Id) && ticketIdForClosedDate.get(ticket.Id) != null){
                        for(CMPL123CME__Questionnaire__c questionnaire : ticket.CMPL123CME__Questionnaires__r){
                            updatableComplaints.add(new CMPL123CME__Questionnaire__c(
                                Id = questionnaire.Id,
                                Follow_Up_Awareness_Date__c = ticketIdForClosedDate.get(ticket.Id)
                            ));
                        }
                    }
                    updatableComplaints.add(updatableTicket);
                    // #123/CHARM-2729: add id of updated ticket to updatedTicketIds
                    updatedTicketIds.add(updatableTicket.Id);
                }
            }
            if(updatableComplaints.size() > 0) {
                update updatableComplaints;
            }
            if(lstActivities.size() > 0){
                Insert lstActivities;
            }
            createTasks();
            updateMedEvals(invWithTicketMap);
            if(TicketUpdateUtility.executeFlag && parentIds != null && parentIds.size() > 0){
                TicketUpdateUtility.executeFlag = false;
                // Call the utility method to update the parent
                // #123/CHARM-2729: assign processed ticket ids
                Set<Id> updatedTickets = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
                // #123/CHARM-2729: add ids of updated tickets to updatedTicketIds
                updatedTicketIds.addAll(updatedTickets);
            }
        }

        // #123.3/CHARM-3012: update ticket LastModifiedDate except updatedTicketIds, added logic for custom Last Modified Date/Time
        UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, updatedTicketIds, 'CMPL123CME__Complaint__c',
            !UpdateParentUtility.isInvestigationLastModifDateUpdating);

        intAfterCustomLimits = Limits.getCpuTime() - intAfterCustomLimits;
        system.debug(LoggingLevel.FINER, 'intAfterCustomLimits -->'+intAfterCustomLimits);
    }

    /**
    * @Method       : beforeDelete
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : To handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void beforeDelete() {
        TicketUtil.addTrace('ADDInvestigationHandler.beforeDelete');
        //Added - W-000344 - Start
        Set<Id> setInvestigationIdsWithSourceSystemGenerated = New Set<Id>();
        Set<Id> setInvestigationIds = oldInvMap.keySet();
        // collects all the system generated Investigation Id's
        for (Ticket_Product_Evaluation_Investigation__c objTicketProductEvaluationInvestigation
             : [SELECT Id, Name,
                Investigation_Evaluation__c, Type__c FROM Ticket_Product_Evaluation_Investigation__c
                WHERE Investigation_Evaluation__c IN: setInvestigationIds AND Type__c = :AspenConstants.STR_Source
                AND Investigation_Evaluation__r.System_Integration_Generated_Flag__c = true
               ]) {
                   setInvestigationIdsWithSourceSystemGenerated.add(objTicketProductEvaluationInvestigation.Investigation_Evaluation__c);
               }
        // Throws a warning message when you try to delete system generated Investigation record.
        for (CMPL123CME__Investigation__c objInvestigation : (List<CMPL123CME__Investigation__c>)Trigger.Old) {
            if (setInvestigationIdsWithSourceSystemGenerated.contains(objInvestigation.Id)) {
                objInvestigation.addError(
                    System.label.Product_evaluation_Investigation_Cannot_Be_Deleted);
            }
        }
        //Added - W-000344 - End

        //123 audit/workflow code
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
    * @Method       : afterUnDelete
    * @Invoke       : Events from TriggerHandler after Undelete
    * @Description  : To handle all the logic in after Undelete event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterUndelete() {

    }

    /**
    * @Method       : returnProducts
    * @Description  : get related product tickets
    * @Return       : Map<String,Product_Ticket__c>
    * @Params       : Set<String> relatedIds
    **/
    public static Map<String,Product_Ticket__c> returnProducts(Set<String> relatedIds) {
        TicketUtil.addTrace('ADDInvestigationHandler.returnProducts');
        Map<String,Product_Ticket__c> ticketIdWithProductTicketMap = new Map<String,Product_Ticket__c>();

        if(relatedIds.size() > 0){
            // coolects all the productTicket id's based on the input relatedIds
            // and if likely cause = true and ticketIdWithProductTicketMap
            // doesn't contain Product ticket Id it adds it to the
            // existing ticketIdWithProductTicketMap map.
            for (Product_Ticket__c productTicket : [
                SELECT Id, Batch_Lot_Serial__c, Likely_Cause__c, Event_Ticket__c,
                Product__r.CMPL123__Lot_No__c,Product__r.List_Number__c
                FROM Product_Ticket__c WHERE Id IN :relatedIds OR 
                Event_Ticket__c IN :relatedIds ORDER BY Name ASC])
            {
                ticketIdWithProductTicketMap.put(productTicket.Id, productTicket);
                //Added - W-000195 - && !ticketIdWithProductTicketMap.containsKey(productTicket.Event_Ticket__c)
                if (productTicket.Likely_Cause__c == AspenConstants.STR_Yes && 
                    !ticketIdWithProductTicketMap.containsKey(productTicket.Event_Ticket__c))
                {
                    ticketIdWithProductTicketMap.put(productTicket.Event_Ticket__c, productTicket);
                }
            }
        }

        return ticketIdWithProductTicketMap;
    }

    /**
     * @Method       : createTasks
     * @Invoke       : from ADDInvestigationHandler class
     * @Description  : Creates a Tasks.
     * @Return       : Void.
     * @Params       : none
     * @Revision     : 16-FEB-2022, Larry Resnik: Defect 261. Adverse Trend Tasks
     * will not be created anymore. Added comments explaining what each major
     * logical block does. Adjusted indentation.
     **/
    //1437 and 1570
    public void createTasks() {
        TicketUtil.addTrace('ADDInvestigationHandler.createTasks');
        // inserting junction records when new prod eval is created
        Map<String, SObject> newRecords = new Map<String, SObject>();
        Map<Id, Task__c> adverseTasks = new Map<Id, Task__c>();
        //Added - W-000364
        Set<Id> setAdverseTasksExists = New Set<Id>();
        //Added - W-000364
        //Added - W-000153
        Set<Id> setThresholdTasksExists = New Set<Id>();
        Map<Id, Task__c> mapThresholdTasks = new Map<Id, Task__c>();
        //Added - W-000153
        Map<String, String> listNumberWithTicket = new Map<String, String>();
        Map<Id, List<Tracking_Trending_Review_Task__c>> invWithTTMap = new Map<Id,List<Tracking_Trending_Review_Task__c>>();
        for(CMPL123CME__Investigation__c investigation : newInvList){
            if(investigation.CMPL123_WF_Action__c != null
               // MR - 02APR19 - DEF#509 Fix && investigation.CMPL123_WF_Action__c!= oldInvMap.get(investigation.Id).CMPL123_WF_Action__c
               && updatedFieldsSet.contains('CMPL123_WF_Action__c')
               && investigation.CMPL123_WF_Action__c == 'Submit for Evaluation'
            ) {
                // Product_List_Numbers has a value like "08P88-10,08P66-14,05P23-56".
                // This would refer to three different Product__c records.
                if(investigation.Product_List_Numbers__c != null) {
                    for(String listNo : investigation.Product_List_Numbers__c.split(',')) {
                        listNumberWithTicket.put(listNo, investigation.Id);
                    }
                }
            }
        }
        if(listNumberWithTicket.keyset().size() > 0) {
            // For each indirectly referenced Product__c, find the existing
            // TrendItems-Products junctions.
            // We want the Trend Items that were referenced in
            // investigation.Product_List_Numbers
            Map<Id, String> trendItemMap = new Map<Id, String> ();
            for(Trend_Item_Product__c tiproduct : [
                SELECT Id, Trend_Item__c, Product_Name__r.List_Number__c FROM Trend_Item_Product__c
                WHERE Product_Name__r.List_Number__c IN : listNumberWithTicket.keyset()
            ]) {
                trendItemMap.put(tiproduct.Trend_Item__c,
                    tiproduct.Product_Name__r.List_Number__c);
            }

            if(trendItemMap.keyset().size() > 0) {
                // There are Trend Items related to our triggered
                // Product Evaluation/Investigations (Investigation__c),
                // so we must make a Threshold Task for the Prod Eval/Inv.
                // Loop over them and determine which
                // Product Evaluation/Investigation Tasks (Task__c) ALREADY exist
                Map<String,CMPL123CME__Investigation__c> listNumMap = new Map<String,CMPL123CME__Investigation__c>();
                for(CMPL123CME__Investigation__c inv : [
                    SELECT Id, CMPL123CME__Complaint__r.Issue_code__c,
                    CMPL123CME__Complaint__r.Trending_issue_Bucket__c, Product_List_Numbers__c,
                    (SELECT Id,RecordTypeId FROM Related_Evaluation_Investigation_Tasks__r WHERE (RecordTypeId =: thresholdRecordTypeId OR RecordTypeId =: adverseRecordTypeId))
                    FROM CMPL123CME__Investigation__c WHERE Id IN :listNumberWithTicket.values()
                ]){
                    if(inv.Product_List_Numbers__c != null) {
                        for(String listNo : inv.Product_List_Numbers__c.split(',')) {
                            listNumMap.put(listNo, inv);
                        }
                    }
                    //Added - W-000153
                    for(Task__c objTask : inv.Related_Evaluation_Investigation_Tasks__r){
                        if(objTask.RecordTypeId == thresholdRecordTypeId){
                            setThresholdTasksExists.add(inv.Id);
                        }
                        //Added - W-000364
                        if(objTask.RecordTypeId == adverseRecordTypeId){
                            setAdverseTasksExists.add(inv.Id);
                        }
                        //Added - W-000364
                    }
                    //Added - W-000153
                }

                Integer timeFrame =
                    System.Label.Timeframe_in_months != null ? Integer.valueOf(System.Label.Timeframe_in_months) : 12;
                Datetime startDate = Datetime.now().addMonths(-timeFrame);
                Datetime endDate = Datetime.now();

                // Find the Trend Items that were referenced by the Products
                // within each Prod Eval/Inv's "Product List Numbers".
                // For each Trend Item, determine which Task__c records to make
                // 16-FEB-2022 Larry: Removed the inner-query for Tracking_Trending_Review_Tasks__r
                // since it is no longer needed for this function and
                // would count against governor limits
                for(Trend_Item__c trendItem : [
                    SELECT Id, Threshold__c, Suspended__c,
                    (SELECT Id, Trend_Bucket_Code__r.Name FROM Trend_Item_Trend_Buckets__r),
                    (SELECT Id, Issue_Code__r.Name FROM Trend_Item_Issue_Codes__r)
                    // (SELECT Id, Name, CreatedDate, Trend_Item_Type__c, Process__c, Adverse_Trend__c,
                    // Action_Taken__c, Created_Date__c FROM Tracking_Trending_Review_Tasks__r WHERE
                    // Adverse_Trend__c =: AspenConstants.STR_Yes AND (CreatedDate >= :startDate OR CreatedDate <= :endDate))
                    FROM Trend_Item__c WHERE Id IN :trendItemMap.keyset()
                ]) {
                    CMPL123CME__Investigation__c investigationRecord =
                        trendItemMap.get(trendItem.Id) != null && listNumMap.get(trendItemMap.get(trendItem.Id)) != null
                        ? listNumMap.get(trendItemMap.get(trendItem.Id))
                        : null;
                    if(investigationRecord != null) {
                        // 16-FEB-2022 Larry: Adverse Trend Tasks will not be created anymore
                        //Added - W-000364 - Handle Duplicate adverse trend task - && !setAdverseTasksExists.contains(investigationRecord.Id)
                        // if(trendItem.Tracking_Trending_Review_Tasks__r.size() > 0 && !setAdverseTasksExists.contains(investigationRecord.Id)) {
                        //     //Create adverse trend task
                        //     invWithTTMap.put(investigationRecord.Id, trendItem.Tracking_Trending_Review_Tasks__r);
                        //     adverseTasks.put(investigationRecord.ID,
                        //                         new Task__c(
                        //                             RecordTypeId = adverseRecordTypeId,
                        //                             Related_Investigation_Evaluation__c = investigationRecord.ID
                        //                         )
                        //                     );
                        // }

                        Boolean validTrendBucket = false; Boolean validIssueCode = false;

                        for(Trend_Item_Trend_Bucket__c trendBucket : trendItem.Trend_Item_Trend_Buckets__r) {
                            if(trendBucket.Trend_Bucket_Code__r.Name
                                == investigationRecord.CMPL123CME__Complaint__r.Trending_issue_Bucket__c) {
                                    validTrendBucket = true;
                                }
                        }

                        for(Trend_Item_Issue_Code__c trendIssue : trendItem.Trend_Item_Issue_Codes__r) {
                            if(trendIssue.Issue_Code__r.Name == investigationRecord.CMPL123CME__Complaint__r.Issue_code__c) {
                                validIssueCode = true;
                            }
                        }
                        //Added filter - W-000153 -  Handle Duplicate Threshold Task - && !setThresholdTasksExists.contains(investigationRecord.Id)
                        if((validTrendBucket || validIssueCode) && !setThresholdTasksExists.contains(investigationRecord.Id)) {
                            mapThresholdTasks.put(
                                investigationRecord.ID,
                                new Task__c(
                                    RecordTypeId = thresholdRecordTypeId,
                                    Related_Investigation_Evaluation__c = investigationRecord.ID
                                )
                            );
                        }
                    }
                }
            }
        }

        //Commented : W-000346 - Recursion handled on afterUpdate Method, so Commented this below line
        //if (!executeOnce) {
        if(adverseTasks.keyset().size() > 0) {
            //Added - W-000153
            List<Task__c> lstToInsertTasks = New List<Task__c>();
            if(mapThresholdTasks.keyset().size() > 0){
                lstToInsertTasks.addAll(mapThresholdTasks.values());
            }
            lstToInsertTasks.add(adverseTasks.values());
            //Added - W-000153
            insert lstToInsertTasks;

            // 16-FEB-2022 Larry: Commented the loop because can no longer
            // get code coverage.
            // for(Task__c taskRecord : adverseTasks.values()) {
            //     if(invWithTTMap.get(taskRecord.Related_Investigation_Evaluation__c) != null) {
            //         Integer counter = 1;
            //         for(Tracking_Trending_Review_Task__c ttTask : invWithTTMap.get(taskRecord.Related_Investigation_Evaluation__c)){
            //             newRecords.put (String.valueOf(counter),
            //                             new T_T_Review_Task_Adverse_Trend__c (
            //                                 Task_Name__c = ttTask.Name,
            //                                 Task_ID__c = ttTask.Id,
            //                                 Action_Taken__c = ttTask.Action_Taken__c,
            //                                 Adverse_Trend__c = ttTask.Adverse_Trend__c,
            //                                 Adverse_Trend_Task__c = taskRecord.Id,
            //                                 Created_Date__c = ttTask.Created_Date__c,
            //                                 Process__c = ttTask.Process__c,
            //                                 Trend_Item_Type__c = ttTask.Trend_Item_Type__c
            //                             )
            //                            );
            //             counter++;
            //         }
            //     }
            // }
        }else{
            //Added - W-000153
            if(mapThresholdTasks.keyset().size() > 0){
                insert mapThresholdTasks.values();
            }
            //Added - W-000153
        }
        if(newRecords.keyset().size() > 0) {
            insert newRecords.values();
        }
        //}
    }

    /**
     * @Method       : updateMedEvals
     * @Description  : Updates Related medEvals.
     * @Return       : Void.
     * @Params       : Map of Investigation Id as Key and Ticket Id as values.
     * @Revision     : R3.1, Larry: Now makes a new MedEval if all MedEvals are Closed-Voided.
     **/
    public static void updateMedEvals(Map<Id, Id> invWithTicketMap) {
        TicketUtil.addTrace('ADDInvestigationHandler.updateMedEvals');
        // R3.1, Larry: Inverted if-statement to reduce scope.
        // Removed null check since this function is always called with it initialized.
        if (invWithTicketMap.isEmpty()) {
            return;
        }

        Map<String, CMPL123__WF_Step__c> workflowStepMap = updateMedEvalsGetWfStepsForProcessEval();
        List<CMPL123CME__Questionnaire__c> upsertList = new List<CMPL123CME__Questionnaire__c>();
        List<CMPL123__WF_History__c> wfHistoryRecords = new List<CMPL123__WF_History__c>();

        //20-JUL-2022 Anshika IPDR 400:Follow_Up_Awareness_Date__c was added to the subquery for MedEvals.
        for (CMPL123CME__Complaint__c ticket : [
            SELECT Id, Complaint_Quality_Closure_Date__c,
            (
                SELECT Id, Conclusion_Disposition__c
                FROM CMPL123CME__Investigations__r
                WHERE Id IN :invWithTicketMap.keyset()
            ),
            (
                SELECT Id, Follow_Up_Awareness_Date__c,
                Conclusion_Disposition_Flag__c, CMPL123_WF_Status__c,
                Reportability__c
                FROM CMPL123CME__Questionnaires__r
                WHERE CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided
            )
            FROM CMPL123CME__Complaint__c
            WHERE Id IN :invWithTicketMap.values()
        ]) {
            // R3.1, Larry: Note that following a discussion between the developers and Abbott representatives,
            // we determined that loop-within-loop was not potentially optimizable. Tickets can have multiple ProdEvals
            // and multiple MedEvals. There is no unique identifier between the ProdEvals and MedEvals.
            // If they were one-to-one, we could have built a [UniqueIdentifier]-to-MedEval Map for looping.
            // The potential crash mentioned at the bottom of this function is the result of there not
            // being a unique link between the objects, but this crash is not witnessed in Production because CMSNext
            // sends Ticket updates to Salesforce one-at-a-time.
            for (CMPL123CME__Investigation__c inv : ticket.CMPL123CME__Investigations__r) {
                Boolean isPeConcDispo80067 = inv.Conclusion_Disposition__c ==
                    AspenConstants.STR_80067_Deficiency_Malfunction;

                // R3.1, Larry: Hoisted logic to determine keyVal and concDispoFlag 
                // since the logic is shared.
                //
                // Assume ProdEval.ConclusionDisposition is NOT code 80067 by default.
                // Specifically, we expect code 80064.
                String keyVal = AspenConstants.POTENTIAL_REPORTABLE_EVENT;
                String concDispoFlag = AspenConstants.STR_Malfunction_Requiring_Med_Eval;
                if (isPeConcDispo80067) {
                    keyVal = AspenConstants.STR_Deficiency;
                    concDispoFlag = AspenConstants.STR_Deficiency;
                }

                for (CMPL123CME__Questionnaire__c questionnaire : ticket.CMPL123CME__Questionnaires__r) {
                    String wfStatus = questionnaire.CMPL123_WF_Status__c;
                    CMPL123__WF_Step__c applicableStep = workflowStepMap.get(wfStatus);
                    Boolean isJustUpdateConcoDispoFlag =
                        wfStatus == AspenConstants.STR_Opened ||
                        wfStatus == AspenConstants.STR_In_Process_Evaluation;
                    //Added - W-000199: applicableStep != null into the logic now-called isGoingToInProcess
                    Boolean isGoingToInProcess = applicableStep != null && 
                        isPeConcDispo80067 &&
                        MEDEVAL_WFSTATUS_TO_IN_PROCESS.contains(wfStatus);
                    if (isJustUpdateConcoDispoFlag) {
                        upsertList.add (
                            new CMPL123CME__Questionnaire__c (
                                Id = questionnaire.Id,
                                //15APR19 - 688
                                CMPL123CME__Key_value__c = keyVal,
                                Conclusion_Disposition_Flag__c = concDispoFlag
                            )
                        );
                    } else if (isGoingToInProcess) {
                        //20-JUL-2022 Anshika -Defined a new variable for IPDR 400
                        //The logic was moved outside of the MedEval's constructor into this new variable
                        //Now prefers the Medical Evaluation's Follow Up Awareness Date before the Ticket's Complaint Quality Closure Date.
                        Date followUpDate = questionnaire.Follow_Up_Awareness_Date__c;
                        if(followUpDate == null && ticket.Complaint_Quality_Closure_Date__c != null){
                            followUpDate = ticket.Complaint_Quality_Closure_Date__c.date();
                        }
                        // R3.1, Larry: Removed logic from Conclusion Disposition Flag since
                        // we know that the ProdEval's Conclusion Disposition is 80067.
                        upsertList.add (
                            new CMPL123CME__Questionnaire__c (
                                Id = questionnaire.Id,
                                CMPL123_WF_Status__c = applicableStep.CMPL123__End_Status__r.Name,
                                CMPL123_WF_Action_Performed_On__c = System.now(),
                                CMPL123_WF_Action_Performed_By__c = userinfo.getuserid(),
                                CMPL123_WF_Action__c = applicableStep.CMPL123__Action__r.Name,
                                // Def 1638 fix
                                Follow_Up_Awareness_Date__c = followUpDate,
                                Conclusion_Disposition_Flag__c = AspenConstants.STR_Deficiency
                            )
                        );

                        wfHistoryRecords.add (
                            ComplaintTriggerHandler.processAutomatedHistoryRecord (
                                questionnaire.Id, applicableStep
                            )
                        );
                    }
                }

                // R3.1, Larry: Now checks that all MedEvals are Voided OR
                // that there are NO MedEvals.
                //
                // Note: This may cause the function to crash if we
                // update-and-insert MedEvals at the same time.
                // Hopefully users do not update multiple ProdEvals at once?
                if (ticket.CMPL123CME__Questionnaires__r.isEmpty()) {
                    upsertList.add (
                        new CMPL123CME__Questionnaire__c (
                            CMPL123CME__Complaint__c = ticket.Id,
                            //Added W-000367
                            //15APR19 - 688
                            CMPL123CME__Key_value__c = keyVal,
                            Conclusion_Disposition_Flag__c = concDispoFlag
                        )
                    );
                }
            } // end of for (CMPL123CME__Investigation__c inv : ticket.CMPL123CME__Investigations__r) {
        } // end of CMPL123CME__Complaint__c ticket : [

        // R3.1, Larry: Now only inserts WorkFlow History records if the list is populated.
        // The list could be empty if there were no MedEvals or they were all Closed-Voided.
        if (!wfHistoryRecords.isEmpty()) {
            insert wfHistoryRecords;
        }

        if (!upsertList.isEmpty()) {
            upsert upsertList;
        }
    }

    /**
     * Queries for all WorkFlow Steps which move a MedEval to the "In Process Evaluation" Status
     * 
     * Helper for updateMedEvals
     * @author Larry Resnik
     * @date 07-JUN-2023
     */
    @testVisible
    private static Map<String, CMPL123__WF_Step__c> updateMedEvalsGetWfStepsForProcessEval() {
        Map<String, CMPL123__WF_Step__c> workflowStepMap = new Map<String, CMPL123__WF_Step__c>();
        for (CMPL123__WF_Step__c step : [
            SELECT Id, CMPL123__WF_Rule__c,
            CMPL123__WF_Rule__r.CMPL123__Record_Type__c, CMPL123__Action__r.CMPL123__Is_ESign_Required__c,
            CMPL123__Action__r.Name, CMPL123__End_Status__r.Name, CMPL123__Start_Status__r.Name
            FROM CMPL123__WF_Step__c
            WHERE CMPL123__WF_Rule__r.CMPL123__Record_Type__c = :AspenConstants.STR_MEDICAL_EVALUATION_WORKFLOW
            AND CMPL123__Start_Status__r.Name IN :MEDEVAL_WFSTATUS_TO_IN_PROCESS
            AND CMPL123__End_Status__r.Name = :AspenConstants.STR_In_Process_Evaluation
            AND CMPL123__Action__r.Name IN :MEDEVAL_WFACTION_TO_IN_PROCESS
        ]) {
            workflowStepMap.put(step.CMPL123__Start_Status__r.Name, step);
        }
        return workflowStepMap;
    }

    /**
    * @Method       : createProductLot
    * @Invoke       : from TicketService class
    * @Description  : W-000195 - Creating Product/Lot from Product-Ticket
    * @Return       : N/A
    * @Params       : String registrationTicketNumber
    **/
    public static void createProductLot(String strRegistrationTicketNumber) {
        TicketUtil.addTrace('ADDInvestigationHandler.createProductLot');
        List<CMPL123CME__Investigation__c> lstInvestigations = new List<CMPL123CME__Investigation__c>();
        for(CMPL123CME__Investigation__c objInvestigation
            : [SELECT Id,CMPL123CME__Complaint__c,System_Integration_Generated_Flag__c, (SELECT Id FROM Product_Lots__r) FROM CMPL123CME__Investigation__c
               WHERE CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c = :strRegistrationTicketNumber AND System_Integration_Generated_Flag__c = true]
           ) {
               if(objInvestigation.Product_Lots__r.size() == 0) {
                   lstInvestigations.add(objInvestigation);
               }
           }
        if(lstInvestigations.size() > 0) {
            createProductLotFromProductTicket(lstInvestigations, false);
        }
    }

    /**
    * @Method       : createProductLotFromProductTicket
    * @Invoke       : from ADDInvestigationHandler class
    * @Description  : W-000195 - Creating Product/Lot from Product-Ticket
    * @Return       : N/A
    * @Params       : List<CMPL123CME__Investigation__c> lstIvestigations,Boolean isTriggerEvent
    **/
    public static void createProductLotFromProductTicket(List<CMPL123CME__Investigation__c> lstIvestigations,Boolean isTriggerEvent) {
        TicketUtil.addTrace('ADDInvestigationHandler.createProductLotFromProductTicket');
        // inserting junction records when new prod eval is created
        List<SObject> newRecords = new List<SObject> ();
        Set<String> relatedIds = new Set<String>();

        for(CMPL123CME__Investigation__c objInvestigation : lstIvestigations) {
            if (objInvestigation.CMPL123CME__Complaint__c != null) {
                relatedIds.add(objInvestigation.CMPL123CME__Complaint__c);
            }
        }

        Map <String, CMPL123CME__Complaint__c> relatedTickets = new Map <String, CMPL123CME__Complaint__c>();
        if (isTriggerEvent && relatedIds.size() > 0) {
            relatedTickets = new Map <String, CMPL123CME__Complaint__c> (
                [SELECT Name, Receipt_Date__c FROM CMPL123CME__Complaint__c WHERE Id IN :relatedIds]
            );
        }

        // UPGRD Def #92: Searchable Field Update PB logic upon insertion of Prod Eval
        for (CMPL123CME__Investigation__c objInvestigation : lstIvestigations) {
            CMPL123CME__Complaint__c relatedTicket = relatedTickets.get(objInvestigation.CMPL123CME__Complaint__c);
            if (isTriggerEvent && relatedTicket != null) {
                String searchable = formatSearchable(objInvestigation, relatedTicket);
                newRecords.add(
                    new Ticket_Product_Evaluation_Investigation__c(
                        Type__c = AspenConstants.STR_Source,
                        Investigation_Evaluation__c = objInvestigation.id,
                        Ticket__c = objInvestigation.CMPL123CME__Complaint__c,
                        Searchable__c = searchable
                    )
                );
            }
        }

        // Create new Product/Lot records
        Map<String, Product_Ticket__c> ticketIdWithProductTicketMap = returnProducts(relatedIds);
        for (CMPL123CME__Investigation__c objInvestigation : lstIvestigations) {
            //setting product ticket value based on likely cause and prod eval name.
            //Added investigation.System_Integration_Generated_Flag__c and removed investigation.Name.contains('-01')
            //Added - W-000195 - System generated flag check
            if(objInvestigation.System_Integration_Generated_Flag__c
                && objInvestigation.CMPL123CME__Complaint__c != null
                && ticketIdWithProductTicketMap.get(objInvestigation.CMPL123CME__Complaint__c) != null)
            {
                newRecords.add(new Product_Lot__c (
                    Product_Evaluation_Investigation__c = objInvestigation.Id,
                    Product_Name__c = ticketIdWithProductTicketMap.get(objInvestigation.CMPL123CME__Complaint__c).Id,
                    Related_Ticket__c = objInvestigation.CMPL123CME__Complaint__c,
                    //IPDR-105 Set the system-generated flag to true to indicate that this Product Lot was system generated.
                	System_Generated_Flag__c = true));
            }
        }

        if (newRecords.size() > 0) {
            insert newRecords;
        }
    }

    //Added : W-000332
    /**
    * @Method       : removeMDCMedicalEvaluator
    * @Invoke       : from ADDInvestigationHandler class
    * @Description  : W-000332 - Remove MDC assignment to Medical Evaluator 
    * 		 		  Commented out the method as part of Charm R9.0/IPDR-539 since no longer required.
    * @Return       : N/A
    * @Params       : Set prodEvalsTicketSet
    **/    
    /*public static void removeMDCMedicalEvaluator(Set<Id> prodEvalsTicketSet){
        TicketUtil.addTrace('ADDInvestigationHandler.removeMDCMedicalEvaluator');
        Map<Id, CMPL123__MDC_Ticket__c> ticketMDCMap = new Map<Id, CMPL123__MDC_Ticket__c>();
        for(CMPL123__MDC_Ticket__c objMDCTicket : [SELECT Id FROM CMPL123__MDC_Ticket__c WHERE CMPL123__Related_Record_ID__c IN : prodEvalsTicketSet AND CMPL123__All_Acks_Received__c = False AND Is_Medical_Evaluator__c = true AND CMPL123__Record_Type__c = 'CMPL123CME__Complaint__c' AND CMPL123__MDC_Trigger_Name__c = 'Ticket Change for medical evaluator' AND CMPL123__Field_Name__c  = 'Complaint Quality Closure Date']){
            ticketMDCMap.put(objMDCTicket.Id, objMDCTicket);
        }
        if(!ticketMDCMap.isEmpty()){
            Delete ticketMDCMap.values();
        }
    }*/

    /**
    * @Method       : reOrderTicketInvestigationStatus
    * @Invoke       : from ADDInvestigationHandler class
    * @Description  : to populate Investigation Status in Ticket
    * @Return       : String strStatus
    * @Params       : Id idTicket
    **/
    private static String reOrderTicketInvestigationStatus(Id idTicket){
        String strStatus;

        List<Integer> lstStatus = New List<Integer>();
        //Fixed - W-000063 - Re-Order the priority STR_In_Process_Investigation 2 to 3 and STR_In_Process_Evaluation 3 to 2
        Map<String, Integer> mapStatus = New Map<String, Integer> {
            AspenConstants.STR_Assess => 1,
            AspenConstants.STR_In_Process_Evaluation => 2,
            AspenConstants.STR_In_Process_Investigation => 3,
            AspenConstants.STR_Conclude => 4,
            AspenConstants.STR_PE_Review => 5,
            AspenConstants.STR_Closed_Done => 6
        };
        lstStatus.clear();

        if(!ADDUpdateTicketStatus.boolIsExcuted && idTicket != null) {
            ADDUpdateTicketStatus.boolIsExcuted = true;

            for(Ticket_Product_Evaluation_Investigation__c objInvestigationTicket
                : [SELECT Id, Investigation_Evaluation__r.CMPL123CME__Complaint__c,Ticket__r.Investigation_Status__c,
                   Investigation_Evaluation__r.CMPL123_WF_Status__c FROM Ticket_Product_Evaluation_Investigation__c
                   WHERE Ticket__c =: idTicket AND Type__c =: AspenConstants.STR_Source]) {
                       if(mapStatus.get(objInvestigationTicket.Investigation_Evaluation__r.CMPL123_WF_Status__c) != null) {
                           lstStatus.add(mapStatus.get(objInvestigationTicket.Investigation_Evaluation__r.CMPL123_WF_Status__c));
                       }
                   }
            lstStatus.sort();

            if(lstStatus.size() > 0) {
                if(lstStatus[0] == 1) {
                    strStatus = AspenConstants.STR_Assess;
                } else if(lstStatus[0] == 2) {
                    strStatus = AspenConstants.STR_In_Process_Evaluation;
                } else if(lstStatus[0] == 3) {
                    strStatus = AspenConstants.STR_In_Process_Investigation;
                } else if(lstStatus[0] == 4) {
                    strStatus = AspenConstants.STR_Conclude;
                } else if(lstStatus[0] == 5) {
                    strStatus = AspenConstants.STR_PE_Review;
                } else if(lstStatus[0] == 6) {
                    strStatus = AspenConstants.STR_Closed_Done;
                }

            }
        }
        return strStatus;
    }

    /**
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history
    * @Return       : N/A
    * @Params       : Map<Id,CMPL123CME__Investigation__c> newRecordMap,
    *                 Map<Id,CMPL123CME__Investigation__c> oldRecordMap
    **/
    public static void setReopenRationale(Map<Id,CMPL123CME__Investigation__c> newRecordMap,
                                          Map<Id,CMPL123CME__Investigation__c> oldRecordMap){
        CMPL123CME__Investigation__c oldRecord;
        CMPL123CME__Investigation__c newRecord;
        if(newRecordMap.keyset().size() == 1){
            for(CMPL123CME__Investigation__c sobj : newRecordMap.values()){
                newRecord = sobj;
                oldRecord = oldRecordMap.get(sobj.Id);
            }
            if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase(AspenConstants.STR_Reopen)
                && newRecord.CMPL123_WF_Action__c != AspenConstants.STR_Reopen && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                newRecord.Reopening_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
            }
        }
    }

    /**
    * @Method       : updateLastModifiedDateTime
    * @Description  : used to update custom Last Modified Date/Time field
    * @Return       : N/A
    * @Params       : N/A
    **/
    static void updateLastModifiedDateTime() {
        if (Trigger.isBefore && UserInfo.getProfileId() != System.Label.Integration_Profile_ID) {
            for (CMPL123CME__Investigation__c investigation: (List<CMPL123CME__Investigation__c>)Trigger.new) {
                investigation.Last_Modified_Date_Time__c = System.now();
            }
        }
    }

    /*
    * @Method       : beforeInsertOrUpdateEvent.
    * @Description  : Contains logic from disabled SF WF Rules.
    * @Invoke       : From ADDInvestigationHandler class on before insert or update events.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void beforeInsertOrUpdateEvent() {
        Set <String> kiLogIds = new Set <String>();
        Set <String> userIds = new Set <String>();
        Map <Id, KI_Log__c> kiLogs = new Map <Id, KI_Log__c>();
        Map<Id, User> userById = new Map <Id, User>();
        Set <String> statusesToCheck = new Set <String> {
            'Approve', 'Go to Conclude', 'Investigation Completed', 'Investigation Required', 'No Investigation Required',
            'Reject', AspenConstants.STR_Reopen_Go_To_Conclude, 'Send Back to Evaluation', 'Send Back to Investigation',
            'Submit for Evaluation', 'Submit for Investigation', 'Submit for Review', 'Void'
        };

        for (CMPL123CME__Investigation__c newInv : newInvList) {
            CMPL123CME__Investigation__c oldInv = Trigger.isUpdate ? oldInvMap.get(newInv.Id) : null;
            if (newInv.KI_Log__c != null && (Trigger.isInsert || (Trigger.isUpdate && (newInv.KI_Log__c != oldInv.KI_Log__c)))) {
                kiLogIds.add(newInv.KI_Log__c);
            }
            if (newInv.CMPL123_WF_Action_Performed_By__c != null && statusesToCheck.contains(newInv.CMPL123_WF_Action__c)
                    && (Trigger.isInsert || Trigger.isUpdate && newInv.CMPL123_WF_Action__c != oldInv.CMPL123_WF_Action__c)) {
                userIds.add(newInv.CMPL123_WF_Action_Performed_By__c);
            }
        }

        if (kiLogIds.size() > 0) {
            kiLogs = new Map <Id, KI_Log__c> (
                [SELECT Id, CAPA_Reference__c, Complaint_Summary__c, Conclusion_Summary__c,
                    Describe_Additional_Action_Taken__c, No_Investigation_Rationale__c, Complaint_Description__c
                    FROM KI_Log__c
                        WHERE Id IN :kiLogIds]);
        }

        if (userIds.size() > 0) {
            userById = new Map <Id, User>(
                [SELECT LastName, FirstName
                    FROM User
                        WHERE Id IN :userIds]);
        }

        for (CMPL123CME__Investigation__c newInv : newInvList) {
            CMPL123CME__Investigation__c oldInv = Trigger.isUpdate ? oldInvMap.get(newInv.Id) : null;
            // ADDS2 Update Cycle Time WF Rule start
            if (newInv.Closed_Date__c != null && newInv.Reopened_Date__c != null) {
                if (Trigger.isInsert || (Trigger.isUpdate && (newInv.Closed_Date__c != oldInv.Closed_Date__c)
                    || (newInv.Reopened_Date__c != oldInv.Reopened_Date__c))) {
                        if (newInv.Reopened_On__c > newInv.Approved_On__c) {
                            Double cycleTimeDays = (newInv.Reopened_On__c.getTime() - newInv.Approved_On__c.getTime())/MS_IN_DAY;
                            newInv.Cycle_Time__c = newInv.Cycle_Time__c != null ? newInv.Cycle_Time__c + cycleTimeDays : cycleTimeDays;
                        }
                }
            }
            // ADDS2 Update Cycle Time WF Rule end

            // Update KI Log fields values WF Rule start
            if (newInv.KI_Log__c != null && kiLogs.get(newInv.KI_Log__c) != null
                    && (Trigger.isInsert || (Trigger.isUpdate && (newInv.KI_Log__c != oldInv.KI_Log__c)))) {
                KI_Log__c relatedKILog = kiLogs.get(newInv.KI_Log__c);
                newInv.Prod_eval_KI_Log__c = true;
                newInv.CAPA_Reference__c = relatedKILog.CAPA_Reference__c;
                newInv.Complaint_Summary__c = String.isBlank(newInv.Complaint_Summary__c) ? relatedKILog.Complaint_Description__c
                                                 : newInv.Complaint_Summary__c;
                newInv.Conclusion_Summary__c = relatedKILog.Conclusion_Summary__c;
                newInv.Describe_Additional_Action_Taken__c = relatedKILog.Describe_Additional_Action_Taken__c;
                newInv.No_Investigation_Rationale__c = relatedKILog.No_Investigation_Rationale__c;
            }
            // Update KI Log fields values WF Rule end

            // Update KI Log flag start
            if (Trigger.isUpdate
                && (newInv.KI_Log__c == null && (newInv.KI_Log__c != oldInv.KI_Log__c)
                    || newInv.Leveraged_Investigation_Evaluation__c == null
                    && newInv.Leveraged_Investigation_Evaluation__c != oldInv.Leveraged_Investigation_Evaluation__c)) {
                newInv.Prod_eval_KI_Log__c = false;
            }
            // Update KI Log flag end

            if (newInv.CMPL123_WF_Action_Performed_By__c != null && (Trigger.isInsert
                    || Trigger.isUpdate && newInv.CMPL123_WF_Action__c != oldInv.CMPL123_WF_Action__c)) {
                User performedBy = userById.get(newInv.CMPL123_WF_Action_Performed_By__c);
                switch on newInv.CMPL123_WF_Action__c {
                    when 'Approve' {   // Workflow - Approve WF Rule start
                        newInv.Approved_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Approved_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                        newInv.Rejected_By__c = null;
                        newInv.Rejected_On__c = null;
                        newInv.Rejection_Rationale__c = null;
                        newInv.Rejection_Reason__c = null;
                        newInv.Reopening_Reason__c = null;
                        newInv.Reopened_By__c = null;
                        newInv.Reopened_On__c = null;
                    }   // Workflow - Approve WF Rule end
                    when 'Go to Conclude' {    // Workflow - Go to Conclude WF Rule start
                        newInv.Returned_to_Conclude_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Returned_to_Conclude_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Go to Conclude WF Rule end
                    when 'Investigation Completed' {  // Workflow - Investigation Completed WF Rule start
                        newInv.Investigation_Completed_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Investigation_Completed_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Investigation Completed WF Rule end
                    when 'Investigation Required' {    // Workflow - Investigation Required WF Rule start
                        newInv.Investigation_Required_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Investigation_Required_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                        newInv.Is_Investigation_Required__c = 'Yes';
                    }   // Workflow - Investigation Required WF Rule end
                    when 'No Investigation Required' {  // Workflow - No Investigation Required WF Rule start
                    newInv.No_Investigation_Required_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                    newInv.No_Investigation_Required_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                    newInv.Is_Investigation_Required__c = 'No';
                    }   // Workflow - No Investigation Required WF Rule end
                    when 'Reject' {    // Workflow - Reject WF Rule start
                        newInv.Rejected_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Rejected_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Reject WF Rule end
                    when ('Reopen – Go To Conclude') {    // Workflow - Reopen WF Rule start
                        newInv.Reopened_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Reopened_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                        newInv.Approved_By__c = null;
                        newInv.Approved_On__c = null;
                        newInv.Submitted_for_Review_By__c = null;
                        newInv.Submitted_for_Review_On__c = null;
                        newInv.Closed_Date__c = null;
                    }   //  Workflow - Reopen WF Rule end
                    when 'Send Back to Evaluation' {   // Workflow - Send to Evaluation WF Rule start
                        newInv.Sent_to_Evaluation_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Sent_to_Evaluation_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Send to Evaluation WF Rule end
                    when 'Send Back to Investigation' {   // Workflow - Send to Investigation WF Rule start
                        newInv.Sent_to_Investigation_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Sent_to_Investigation_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Send to Investigation WF Rule end
                    when 'Submit for Evaluation' {   // Workflow - Submit for Evaluation WF Rule start
                        newInv.Submitted_for_Evaluation_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Submitted_for_Evaluation_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Submit for Evaluation WF Rule end
                    when 'Submit for Investigation' {   // Workflow - Submit for Investigation WF Rule start
                        newInv.Submitted_for_Investigation_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Submitted_for_Investigation_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                        newInv.Is_Investigation_Required__c = 'Yes';
                    }   // Workflow - Submit for Investigation WF Rule end
                    when 'Submit for Review' {   // Workflow - Submit for Review WF Rule start
                        newInv.Submitted_for_Review_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Submitted_for_Review_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                        newInv.Rejection_Rationale__c = null;
                    }   // Workflow - Submit for Review WF Rule end
                    when 'Void' {   // Workflow - Void WF Rule start
                        newInv.Voided_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newInv.Voided_On__c = newInv.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Void WF Rule end
                }
            }
        }
    }

    /**
     * @Method       : beforeInsertEvent.
     * @Description  : Contains logic from disabled SF WF Rules.
     * @Invoke       : From ADDInvestigationHandler class on before insert events.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : 21-NOV-2022 Larry: Now updates cumulative fields.
     * Changed the static variable to a passed parameter. Decoupled this
     * function from Trigger contexts to allow for testing.
     */
    public void beforeInsertEvent(List<CMPL123CME__Investigation__c> newInvList) {
        Set <String> complaintIds = new Set<String>();
        for (CMPL123CME__Investigation__c newInv : newInvList) {
            if (newInv.CMPL123CME__Complaint__c != null) {
                complaintIds.add(newInv.CMPL123CME__Complaint__c);
            }
        }
        Map <Id, CMPL123CME__Complaint__c> complaints = new Map <Id, CMPL123CME__Complaint__c>();
        if (complaintIds.size() > 0) {
            complaints = new Map <Id, CMPL123CME__Complaint__c>(
                [SELECT CMSNext_Ticket_Number__c, RecordType.DeveloperName, Service_Type__c, Division__c
                FROM CMPL123CME__Complaint__c
                WHERE Id IN :complaintIds]);
        }
        Group productQualityQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Product_Quality_Queue' AND Type = 'Queue'];
        for (CMPL123CME__Investigation__c newInv : newInvList) {
            // Product Evaluation/Investigation Division value updated Process Builder logic
            newInv.Division__c = AspenConstants.DIVISION_DIAGNOSTICS;
            // Assign_Owner WF Rule start
            newInv.OwnerId = productQualityQueue.Id;
            // Assign_Owner WF Rule end

            // Autoset_Registration_Number WF Rule start
            CMPL123CME__Complaint__c relatedComplaint = complaints.get(newInv.CMPL123CME__Complaint__c);
            if (relatedComplaint != null && (relatedComplaint.RecordType.DeveloperName == AspenConstants.STR_Complaint
                    || relatedComplaint.RecordType.DeveloperName == AspenConstants.STR_Inquiry)) {
                newInv.Registration_Number__c = relatedComplaint.CMSNext_Ticket_Number__c + '(' + relatedComplaint.RecordType.DeveloperName + ')';
            } else if (relatedComplaint != null && relatedComplaint.RecordType.DeveloperName == AspenConstants.STR_Service) {
                newInv.Registration_Number__c = relatedComplaint.CMSNext_Ticket_Number__c + '(' + relatedComplaint.Service_Type__c + ' '
                    + relatedComplaint.RecordType.DeveloperName + ')';
            }
            // Autoset_Registration_Number WF Rule end

            // Update Rule Field Update Key Value WF Rule start
            if (relatedComplaint != null && relatedComplaint.Division__c == AspenConstants.DIVISION_DIAGNOSTICS) {
                newInv.CMPL123Rule_Key_Value__c = 'PRODEVAL_WORKFLOW';
            }
            // Update Rule Field Update Key Value WF Rule end
        }
        // 21-NOV-2022 Larry: Added this fn call
        setCumulsOnEachProdEval(null, newInvList);
    }

    /*
    * @Method       : updateTicketProductEvaluationInvestigation.
    * @Description  : Contains logic from 'Searchable Field Update' Process.
    * @Invoke       : From ADDInvestigationHandler class on after update events.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void updateTicketProductEvaluationInvestigation() {
        Set <String> relatedIds = new Set<String>();
        List <Ticket_Product_Evaluation_Investigation__c> ticketProdEvalInvList = new List <Ticket_Product_Evaluation_Investigation__c>();
        for(CMPL123CME__Investigation__c objInvestigation : newInvList) {
            if (objInvestigation.CMPL123CME__Complaint__c != null) {
                relatedIds.add(objInvestigation.CMPL123CME__Complaint__c);
            }
        }

        Map <String, CMPL123CME__Complaint__c> relatedTickets = new Map <String, CMPL123CME__Complaint__c>();
        Map <String, List<Ticket_Product_Evaluation_Investigation__c>> relatedTicketProdEvals
                = new Map <String, List <Ticket_Product_Evaluation_Investigation__c>>();
        if (relatedIds.size() > 0) {
            relatedTickets = new Map <String, CMPL123CME__Complaint__c> (
                [SELECT Name, Receipt_Date__c FROM CMPL123CME__Complaint__c WHERE Id IN :relatedIds]
            );
        }

        for (Ticket_Product_Evaluation_Investigation__c ticketProdEvalInv : [SELECT Investigation_Evaluation__c, Searchable__c
                    FROM Ticket_Product_Evaluation_Investigation__c
                        WHERE Investigation_Evaluation__c IN :Trigger.newMap.values()]) {

            if (relatedTicketProdEvals.get(ticketProdEvalInv.Investigation_Evaluation__c) == null) {
                relatedTicketProdEvals.put(ticketProdEvalInv.Investigation_Evaluation__c,
                        new List <Ticket_Product_Evaluation_Investigation__c> {ticketProdEvalInv});
            } else {
                relatedTicketProdEvals.get(ticketProdEvalInv.Investigation_Evaluation__c).add(ticketProdEvalInv);
            }
        }


        // UPGRD Def #92: Searchable Field Update PB logic upon insertion of Prod Eval
        for (CMPL123CME__Investigation__c objInvestigation : newInvList) {
            CMPL123CME__Complaint__c relatedTicket = relatedTickets.get(objInvestigation.CMPL123CME__Complaint__c);
            String searchable;
            CMPL123CME__Investigation__c oldInv = oldInvMap.get(objInvestigation.Id);
            if (relatedTicket != null && relatedTicketProdEvals.get(objInvestigation.Id) != null
                    && (objInvestigation.Name != oldInv.Name || objInvestigation.CMPL123_WF_Status__c != oldInv.CMPL123_WF_Status__c
                    || objInvestigation.Product_List_Numbers__c != oldInv.Product_List_Numbers__c
                    || objInvestigation.CMPL123CME__Product_Name__c != oldInv.CMPL123CME__Product_Name__c
                    || objInvestigation.Product_Lot_Numbers__c != oldInv.Product_Lot_Numbers__c
                    || objInvestigation.Issue_Code_Issue_Code_Description__c != oldInv.Issue_Code_Issue_Code_Description__c)) {
                searchable = searchable == null ? formatSearchable(objInvestigation, relatedTicket) : searchable;
                for (Ticket_Product_Evaluation_Investigation__c ticketProdEvalInv : relatedTicketProdEvals.get(objInvestigation.Id)) {
                    ticketProdEvalInvList.add(
                            new Ticket_Product_Evaluation_Investigation__c(
                                Id = ticketProdEvalInv.Id,
                                Searchable__c = searchable
                            )
                    );
                }
            } else if (relatedTicket != null && relatedTicket.Receipt_Date__c != null && relatedTicketProdEvals.get(objInvestigation.Id) != null) {
                for (Ticket_Product_Evaluation_Investigation__c ticketProdEvalInv : relatedTicketProdEvals.get(objInvestigation.Id)) {
                    if (ticketProdEvalInv.Searchable__c.substringAfterLast(' - ') != relatedTicket.Receipt_Date__c.formatGMT('y-MM-dd H:mm:ssZ')) {
                        searchable = searchable == null ? formatSearchable(objInvestigation, relatedTicket) : searchable;
                        ticketProdEvalInvList.add(
                            new Ticket_Product_Evaluation_Investigation__c(
                                Id = ticketProdEvalInv.Id,
                                Searchable__c = searchable
                            )
                        );
                    }
                }
            }
        }

        if (ticketProdEvalInvList.size() > 0) {
            update ticketProdEvalInvList;
        }
    }

    /**
     * Composes cumulative ProdEval fields to be assigned onto a ProdEval record
     * 
     * Cumulative fields are explained in the ProdEvalFieldsWrap docstring.
     * 
     * Code based on ADDProductTicketTriggerHandler.getCumulativeProdEvalFields
     * @param queriedPtList All Product-Tickets related to ONE Ticket
     * @return An inner class that stores the fully composed cumulative fields
     * @author Larry Resnik, 18-NOV-2022
     */
    private static ADDProductTicketTriggerHandler.ProdEvalFieldsWrap
        getCumulsForTicket(List<Product_Ticket__c> queriedPtList)
    {
        ADDProductTicketTriggerHandler.ProdEvalFieldsWrap fields =
            new ADDProductTicketTriggerHandler.ProdEvalFieldsWrap();
        for (Product_Ticket__c queriedPt : queriedPtList) {
            fields.addFields(queriedPt);
        }
        return fields;
    }

    /**
     * Sets the cumulative fields for all passed ProdEvals.
     * 
     * Code based on ADDProductTicketTriggerHandler.fixProdEvalFields,
     * but the entry conditions and outcomes are very different.
     * In that method, we CHECK if the cumulative fields need updated, 
     * then do DML to update the queried ProdEvals.
     * In this method, we ALWAYS update the cumulative fields.
     * No DML needed because the records to change are in the Trigger context.
     * @param oldMap Same as Trigger.oldMap. Can be null
     * @param newList Same as Trigger.new. Can be null
     * @return See setCumulsOnEachProdEvalAssign
     * @author 18-NOV-2022 Larry Resnik
     */
    @testVisible
    private static List<Id> setCumulsOnEachProdEval(
        Map<Id, CMPL123CME__Investigation__c> oldMap,
        List<CMPL123CME__Investigation__c> newList)
    {
        // Prepare passed parameters
        newList = newList != null ? newList : new List<CMPL123CME__Investigation__c>();

        Set<Id> ticketIdSet = new Set<Id>();
        Map<Id, List<CMPL123CME__Investigation__c>> ticketIdToChildProdEvalList =
            new Map<Id, List<CMPL123CME__Investigation__c>>();
        // Gather and organize data for the upcoming query
        for (CMPL123CME__Investigation__c prodEvalNew : newList) {
            // If prodEvalNew.Id is null, the map returns null.
            // It implies we are in an insert trigger context
            CMPL123CME__Investigation__c prodEvalOld = oldMap?.get(prodEvalNew.Id);
            if (!getMustRecalcCumuls(prodEvalOld, prodEvalNew)) {
                continue;
            }

            // Gather Ticket Ids to query for child Product-Tickets.
            // Note that we do not need prodEvalOld.CMPL123CME__Complaint__c
            // because it is either not needed in setCumulsOnEachProdEvalAssign
            // or it is referenced by a different triggered ProdEval. The
            // latter scenario implies two ProdEvals swapped their Tickets.
            Id ticketIdNew = prodEvalNew.CMPL123CME__Complaint__c;
            ticketIdSet.add(ticketIdNew);

            // Relate the passed ProdEvals to their parent Ticket
            {
                List<CMPL123CME__Investigation__c> childProdEvalList =
                    ticketIdToChildProdEvalList.get(ticketIdNew);
                if (childProdEvalList == null) {
                    childProdEvalList = new List<CMPL123CME__Investigation__c>();
                }
                childProdEvalList.add(prodEvalNew);
                // Put the list into the map in case it was newly created
                ticketIdToChildProdEvalList.put(ticketIdNew, childProdEvalList);
            }
        }

        // Set ProdEval fields using the gathered data
        return setCumulsOnEachProdEvalAssign(ticketIdSet, ticketIdToChildProdEvalList);
    }

    /**
     * States if a ProdEval must update its cumulative fields
     * 
     * Code based on ADDProductTicketTriggerHandler.getIsProdEvalNeedsUpdated
     * @param prodEvalNew One record from Trigger.new
     * @param prodEvalOld The record from Trigger.old or oldMap with the same Id as prodEvalNew
     * @return True if the ProdEval needs updated. False otherwise
     * @author Larry Resnik, 21-NOV-2022
     */
    @testVisible
    private static Boolean getMustRecalcCumuls(
        CMPL123CME__Investigation__c prodEvalOld,
        CMPL123CME__Investigation__c prodEvalNew)
    {
        if (prodEvalOld == null) {
            // Implies Trigger.isInsert is true, the ProdEval needs initialized
            // with its cumulative fields calculated
            return true;
        }

        // If a different trigger context (such as Product-Trigger's)
        // updates ProdEval cumulative fields, keep those fields as-is in
        // Trigger.new and do not try to re-populate them from this trigger.
        // This could also imply that the user directly edited these fields.
        // We should keep those edits. Note that these fields are NOT shown
        // in page layouts and inline editing is disabled from list views,
        // so only devs and testers would edit them.
        // Boolean isCumulsAllSame =
        //     prodEvalNew.Product_Lot_Numbers__c == prodEvalOld.Product_Lot_Numbers__c &&
        //     prodEvalNew.Product_List_Numbers__c == prodEvalOld.Product_List_Numbers__c &&
        //     prodEvalNew.Products__c == prodEvalOld.Products__c &&
        //     prodEvalNew.Has_Product_Lot_Child__c == prodEvalOld.Has_Product_Lot_Child__c;

        // If the parent Ticket changes, the Product-Tickets affiliated with
        // this ProdEval are different, so the cumulative fields must change.
        // This can imply the Ticket changed OR the Ticket was removed.
        Boolean isParentTicketSame = prodEvalNew.CMPL123CME__Complaint__c ==
            prodEvalOld.CMPL123CME__Complaint__c;

        return !isParentTicketSame;
    }

    /**
     * Helper fn for setCumulsOnEachProdEval that does the field assignments.
     * 
     * Code based on ADDProductTicketTriggerHandler.fixProdEvalFieldsDoUpdate
     * @return Ids of ProdEvals that had their cumulative fields updated
     * @author 18-NOV-2022 Larry Resnik
     */
    private static List<Id> setCumulsOnEachProdEvalAssign(
        Set<Id> ticketIdSet,
        Map<Id, List<CMPL123CME__Investigation__c>> ticketIdToChildProdEvalList)
    {
        List<Id> changedProdEvalIds = new List<Id>();
        if (ticketIdSet.isEmpty()) {
            // Abort early to avoid a pointless query
            return changedProdEvalIds;
        }

        // Get Product-Tickets under Tickets referenced by the passed ProdEvals.
        // ProdEvals fill their cumulative fields only from Product-Tickets
        // with the same parent Ticket
        for (CMPL123CME__Complaint__c ticket : [
            SELECT Id,
            (
                SELECT Id,
                // See ProdEvalFieldsWrap for the purpose of these fields
                Batch_Lot_Serial__c,
                Product_List_Number__c,
                Product_Name__c
                // Products_Events__r is the related list of PRODUCT-TICKETS
                FROM Products_Events__r
                WHERE Likely_Cause__c = :AspenConstants.STR_Yes
                AND Delete_Flag__c = false
                AND Product__c != null
            )
            FROM CMPL123CME__Complaint__c
            WHERE Id IN :ticketIdSet
            WITH SECURITY_ENFORCED
        ])
        {
            // Determine the cumulative fields for this Ticket.
            // They are identical across sibling ProdEvals
            ADDProductTicketTriggerHandler.ProdEvalFieldsWrap fields =
                getCumulsForTicket(ticket.Products_Events__r);
            // Fix the cumulative fields on each ProdEval under this Ticket
            for (CMPL123CME__Investigation__c prodEval :
                ticketIdToChildProdEvalList.get(ticket.Id))
            {
                prodEval.Product_Lot_Numbers__c = fields.getCumulativeLotNums();
                prodEval.Product_List_Numbers__c = fields.getCumulativeListNums();
                prodEval.Products__c = fields.getCumulativeProductNames();
                prodEval.Has_Product_Lot_Child__c = !ticket.Products_Events__r.isEmpty();
                changedProdEvalIds.add(prodEval.Id);
            }
        }
        return changedProdEvalIds;
    }

    /*
    * @Method       : formatSearchable.
    * @Description  : Create searchable string basing on input parameters.
    * @Invoke       : From updateTicketProductEvaluationInvestigation method.
    * @Return       : String.
    * @Params       : CMPL123CME__Investigation__c objInvestigation, CMPL123CME__Complaint__c relatedTicket.
    */
    private static String formatSearchable(CMPL123CME__Investigation__c objInvestigation, CMPL123CME__Complaint__c relatedTicket) {
        String invName = objInvestigation.Name != null ? objInvestigation.Name : '';
        String invStatus = objInvestigation.CMPL123_WF_Status__c != null ? objInvestigation.CMPL123_WF_Status__c : '';
        String ticketName = relatedTicket.Name != null ? relatedTicket.Name : '';
        String invProdList = objInvestigation.Product_List_Numbers__c != null ? objInvestigation.Product_List_Numbers__c : '';
        String invProdName = objInvestigation.CMPL123CME__Product_Name__c  != null ? objInvestigation.CMPL123CME__Product_Name__c  : '';
        String invProdLot = objInvestigation.Product_Lot_Numbers__c  != null ? objInvestigation.Product_Lot_Numbers__c  : '';
        String invDescript = objInvestigation.Issue_Code_Issue_Code_Description__c != null
                                    ? objInvestigation.Issue_Code_Issue_Code_Description__c : '';
        String ticketReceiptDate = relatedTicket.Receipt_Date__c != null ? relatedTicket.Receipt_Date__c.formatGMT('y-MM-dd H:mm:ssZ') : '';

        String searchable = invName + ' - ' + invStatus + ' - ' + ticketName + ' - ' + invProdList + ' - ' + invProdName
                + ' - ' + invProdLot + ' - ' + invDescript + ' - ' + ticketReceiptDate;
        return searchable;
    }
    
    /**
     * Helper function for afterUpdate() to set a parent ticket's Investigation Conclusion field to the highest priority Conclusion Disposition of its child investigations.
     * 
     * @return The highest priority investigation conclusion of a parent ticket's child investigations.
     * @author 12-JAN-2023 Nicholas Danny Sutanto
     */
    @testVisible
    private static String chooseHighestPriority(String currentInvestigationConclusion, String newInvestigationConclusion) {
        if (currentInvestigationConclusion == null) {
            return newInvestigationConclusion;
        }

        Map<String, Integer> conclusionPriorities = new Map<String, Integer>{
            AspenConstants.STR_80067_Deficiency_Malfunction => 1,
            AspenConstants.STR_80064_NO_Deficiency_Malfunction => 2,
            AspenConstants.STR_80065_NO_Deficiency_Malfunction_Defect_Distribution_Issue => 3,
            AspenConstants.STR_80066_NO_Deficiency_NO_Malfunction => 4,
            AspenConstants.STR_80069_Non_Medical_Device_Product_Problem => 5,
            AspenConstants.STR_80068_Non_Medical_Device_NO_Product_Problem => 6
        };

        Integer currentConclusionPriority = conclusionPriorities.get(currentInvestigationConclusion);
        Integer newConclusionPriority = conclusionPriorities.get(newInvestigationConclusion);

        if (newConclusionPriority < currentConclusionPriority) {
            return newInvestigationConclusion;
        } else {
            return currentInvestigationConclusion;
        }
    }
}