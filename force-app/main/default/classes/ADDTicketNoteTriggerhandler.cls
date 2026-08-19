/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
 * @What  : ADDTicketNoteTriggerhandler
 * @Why   : Handles all the customization involved on Ticket Note object.
 * @When  : 06-APR-2017
 * @Where : From Ticket_Note_AuditTrigger trigger
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID             Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      Admin                06-APR-2017            Work ID / Case ID            Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      rsitc                27-MAY-2020            #123/CHARM-2729              Prevented multiple updates of the ticket
 *                                                                               in the same transaction.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                   15-06-2020              Code Audit                  Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oivan                   05-JAN-2021             TWD Upgrade issue           Added beforeInsert() to handle WF rule logic
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  OBriceno                 15-FEB-2021             CHaRM Defect #141           MDC Creation Fix
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  OBriceno                 14-APR-2021             CHaRM IPDR #157             Fix Production issue where MDC was not generated for
 *                                                                               Inquiry Tickets for FA Quality Assignee
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  Larry Resnik             08-AUG-2022             CHaRM R2.2 #164             Now needs Customer_Reply_Required to be checked for an
 *                                                                               MDC to be created for Inquiry Tickets
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  Larry Resnik             31-JAN-2023             CHaRM R3.0 #411             Now needs at least one Ticket Search to be active for an
 *                                                                               MDC to be created
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  CHaRM COE                29-JUN-2026             CHaRM R9.0/IPDR 409        Added configurable MDC prevention validation to generate MDC 
 * 																				records only for eligible Ticket Notes based on the parent 
 * 																				Ticket creation time and configured prevention interval.
 * --------------------------------------------------------------------------------------------------------------------------------------
 **/
public class ADDTicketNoteTriggerhandler extends TriggerHandler {
    public static Boolean executeOnce = false;
    // 08-AUG-2022 Larry: Defined the following eight constants out of createMDCTicket
    @testVisible private static final String MDC_NAME_FOR_EVAL_INV8R = 'Ticket Notes Change for Evaluator/Investigator';
    @testVisible private static final String MDC_NAME_FOR_MED_EVAL8R = 'Ticket Notes Change for medical evaluator';
    @testVisible private static final String MDC_NAME_FOR_QUALTY_NON = 'Ticket Notes Change for Quality non Complaint';
    @testVisible private static final String MDC_NAME_FOR_FA_QUALTY = 'Ticket Notes Change for FA Quality Assignee';
    @testVisible private static final String RELATED_TICKET_ID_API = 'Ticket__c';
    @testVisible private static final String RELATED_TICKET_NUM_API = 'Registration_Ticket_Number__c';
    // 31-JAN-2023 Larry: Note that this field is referred to as "Ticket Note (Native)" in the
    // documentation because the value is just copied.
    @testVisible private static final String RELATED_TICKET_AUDIT_FIELD = 'ticket_note_added__c';
    @testVisible private static final Boolean IS_CREATE_JUNC = true;

    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event. TWD Upgrade issue.
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void beforeInsert() {
        //WF: Upon creation of Ticket Note record, auto populate Ticket Note Added with Ticket Notes (Native).
        for (Ticket_Note__c ticketNote : (List<Ticket_Note__c>)Trigger.new) {
            if (ticketNote.Ticket_Notes_Native__c != null && ticketNote.Ticket_Notes_Native__c != '') {
                ticketNote.Ticket_Note_Added__c = ticketNote.Ticket_Notes_Native__c;
            }
        }
    }

    /**
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterInsert() {
        // Code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        
        if (!executeOnce) {
            executeOnce = true;
            updateTicketLastModifiedDate();
            ADDTranslations.ChildObjectTranslations();
            // IPDR 409: MDC creation will remain synchronous.
            // Skip MDC generation if related Ticket is within configured prevention window.
            
            Map<Id, Ticket_Note__c> ticketNoteMap = new Map<Id, Ticket_Note__c>((List<Ticket_Note__c>)Trigger.new);
            ADD_App_Settings__c addApp = ADD_App_Settings__c.getInstance();
            /*CHaRM R9.0/IPDR-409 : Fallback switch to immediately use the existing MDC generation logic.
              This feature was introduced as a safeguard in case high-volume Ticket Note
              loads from CMSNext cause issues with the new MDC prevention logic.*/
            if (addApp != null && addApp.Enable_MDC_Prevention_Logic__c) {
                createMDCTicket(ticketNoteMap);
                return;
            }
            Set<Id> ticketIds = new Set<Id>();
            for (Ticket_Note__c ticketNote : (List<Ticket_Note__c>) Trigger.new) {
                if (ticketNote.Ticket__c != null) {
                    ticketIds.add(ticketNote.Ticket__c);
                }
            }
            if (!ticketIds.isEmpty()) {
                Map<Id, CMPL123CME__Complaint__c> ticketMap =
                    new Map<Id, CMPL123CME__Complaint__c>(
                        [SELECT Id, CreatedDate FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIds] );
                Map<Id,Ticket_Note__c> filteredTicketNoteMap = new Map<Id,Ticket_Note__c>();
                for (Ticket_Note__c ticketNote : (List<Ticket_Note__c>)Trigger.new) {
                    CMPL123CME__Complaint__c ticket = ticketMap.get(ticketNote.Ticket__c);
                    Integer minutesToAdd = Integer.valueOf(addApp.MDC_Generation_Prevention_Minutes__c);
                    /*CHaRM R9.0/IPDR-409 : Prevent MDC generation for Ticket Note added shortly after ticket creation.
                    MDC will only be generated once the configured prevention window has elapsed.
                    This avoids creating MDCs for newly created tickets. After the configured
                    time threshold is reached, MDC generation resumes as normal.*/
                    if (System.now() > ticket.CreatedDate.addMinutes(minutesToAdd)) {
                        filteredTicketNoteMap.put(ticketNote.Id, ticketNote);
                    }
                }
                if(!filteredTicketNoteMap.isEmpty()){
                    createMDCTicket(filteredTicketNoteMap);
                }
            }
        }
    }

    /**
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void beforeUpdate() {
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

        if(!executeOnce){
            executeOnce = true;
            updateTicketLastModifiedDate();
            ADDTranslations.ChildObjectTranslations();
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
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }


    /**
    * @Method       : updateTicketLastModifiedDate
    * @Invoke       : Events from TriggerHandler after insert / update
    * @Description  : To update parent record "Last Modified Date/Time" field based on child record's parent Id collection
    * @Return       : N/A
    * @Params       : Trigger
    **/
    private static void updateTicketLastModifiedDate(){
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if(!UpdateParentUtility.isTicketUpdated || !ComplaintTriggerHandler.isTicketInserting){
            Set<Id> setComplaintIdToUpdate = new Set<Id>();
            for(Ticket_Note__c objRecord : (List<Ticket_Note__c>)Trigger.new){
                if(objRecord.Ticket__c != null)
                    setComplaintIdToUpdate.add(objRecord.Ticket__c);
            }
            if(setComplaintIdToUpdate.size() > 0){
                UpdateParentUtility.ticketTriggerPreventFlag = true;
                UpdateParentUtility.updateparent(setComplaintIdToUpdate);
                // Defect #123/CHARM-2729: disable ticket trigger logic only for UpdateParentUtility.updateparent method execution
                UpdateParentUtility.ticketTriggerPreventFlag = false;
            }
        }
    }

    /**
     * @Description  : Used to create MDC record after TicketNote is inserted.
     * See TicketNoteWithTickteSearchesMDCCustom and its affiliated MDC Trigger record
     * to see how MDCs are created when Ticket Notes are updated rather than inserted.
     * For more info, see the docstring in ADDCustomAttachmentTriggerHandler.createMDCTicket
     * @Revision     : Larry 08-AUG-2022: Defect 164: MDC for "Quality non-Complaint"
     * now needs Inquiry Tickets to also need Ticket.Customer_Response_Required to be
     * flagged. Replaced all magic words with constants
     * @Revision     : Larry 31-JAN-2023: Defect 411: The MDC created due to having a Ticket
     * Search now requires at least one of the Ticket Searches to be active. Minor formatting
     * changes done to illustrate that this method is almost identical to
     * ADDCustomAttachmentTriggerHandler.createMDCTicket. Adjusted this docstring
     */
    public void createMDCTicket(Map<Id,Ticket_Note__c> ticketNoteNewMap) {
        Map <Id, Ticket_Note__c> ticketNoteMatchCon         = new Map <Id, Ticket_Note__c>();
        Map <Id, Ticket_Note__c> ticketNoteMatchCondMedEval = new Map <Id, Ticket_Note__c>();
        Map <Id, Ticket_Note__c> ticketNoteMatchCondInquiry = new Map <Id, Ticket_Note__c>();
        Map <Id, Ticket_Note__c> ticketNoteMatchCondSearch  = new Map <Id, Ticket_Note__c>();

        Set <Id> ticketIds = new Set <Id>();
        for (Ticket_Note__c ticketNote: ticketNoteNewMap.values()) {
            ticketIds.add(ticketNote.Ticket__c);
        }

        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);
        for (Ticket_Note__c ticketNoteObj: ticketNoteNewMap.values()) {
            if (ticketNoteObj.Ticket_Note_Added__c == null) {
                continue;
            }

            Map<String, Boolean> boolMap = ticketMap.get(ticketNoteObj.Ticket__c);
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_PRODEVAL)) {
                ticketNoteMatchCon.put(ticketNoteObj.Id, ticketNoteObj);
            }
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_MEDEVAL)) {
                ticketNoteMatchCondMedEval.put(ticketNoteObj.Id, ticketNoteObj);
            }
            //OBriceno  14-APR-2021   CHaRM IPDR #157
            //Larry     08-AUG-2022   CHaRM R2.2 IPDR #164: Now also needs IS_REPLY_REQUIRED
            if (boolMap.get(AspenConstants.TICKETFLAG_IS_INQUIRY) &&
                boolMap.get(AspenConstants.TICKETFLAG_IS_REPLY_REQUIRED)
            ) {
                ticketNoteMatchCondInquiry.put(ticketNoteObj.Id, ticketNoteObj);
            }
            //Larry     31-JAN-2023   CHaRM R3.0 IPDR #411: Now needs at least one *ACTIVE* Ticket Search
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH)) {
                ticketNoteMatchCondSearch.put(ticketNoteObj.Id, ticketNoteObj);
            }
        }

        if (ticketNoteMatchCon.size() > 0) {
            MDCTicketUtil.createMDC(MDC_NAME_FOR_EVAL_INV8R, ticketNoteMatchCon,
                RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API, RELATED_TICKET_AUDIT_FIELD,
                IS_CREATE_JUNC);
        }
        if (ticketNoteMatchCondMedEval.size() > 0) {
            MDCTicketUtil.createMDC(MDC_NAME_FOR_MED_EVAL8R, ticketNoteMatchCondMedEval,
                RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API, RELATED_TICKET_AUDIT_FIELD,
                IS_CREATE_JUNC);
        }
        if (ticketNoteMatchCondInquiry.size() > 0) {
            MDCTicketUtil.createMDC(MDC_NAME_FOR_QUALTY_NON, ticketNoteMatchCondInquiry,
                RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API, RELATED_TICKET_AUDIT_FIELD,
                IS_CREATE_JUNC);
        }
        if (ticketNoteMatchCondSearch.size() > 0) {
            MDCTicketUtil.createMDC(MDC_NAME_FOR_FA_QUALTY, ticketNoteMatchCondSearch,
                RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API, RELATED_TICKET_AUDIT_FIELD,
                IS_CREATE_JUNC);
        }
    }
    
}