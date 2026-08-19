/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CMPL123CME_Complaint_AuditTrigger.
* @Why   : Handles all the customization involved on CMPL123CME__Complaint__c object.
* @When  : 13-FEB-2019.
* @Where : From CMPL123CME__Complaint__c object Events.
* ----------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    13-FEB-2019            Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    22-JUN-2020            #123.1/CHARM-2878         Adjusted ticketTriggerPreventFlag use.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

trigger CMPL123CME_Complaint_AuditTrigger on CMPL123CME__Complaint__c (
    before insert, before update, before delete, after insert, after update) {

    // Def #123.1/CHARM-2878: removed UpdateParentUtility.ticketTriggerPreventFlag from condition in order to allow audit handling
    if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('CMPL123CME_Complaint_AuditTrigger');

        ComplaintTriggerHandler.isTicketUpdated = true;
        // 15APR19 - Added for Fixing TIBCO Query Redesign
        /* Def #123.1/CHARM-2878: avoid Last_Modified_Date_Time__c updating when update was trigered from child
        and updateTicketCustomLastModifDate == false*/
        if (Trigger.isBefore && UserInfo.getProfileId() != System.Label.Integration_Profile_ID && (Trigger.isInsert || Trigger.isUpdate)
            && (UpdateParentUtility.updateTicketCustomLastModifDate || !UpdateParentUtility.isTriggeredFromChild)) {
            for (CMPL123CME__Complaint__c ticket: Trigger.new) {
                ticket.Last_Modified_Date_Time__c = System.now();
                // Def #123.1/CHARM-2878: avoid multiple updated in the same transaction
                UpdateParentUtility.isCustomLastModifDateUpdated = true;
            }
        }

        // Def #123.1/CHARM-2878: skip custom logic if only Last Modified Date is updating
        if (!UpdateParentUtility.ticketTriggerPreventFlag) {
            // 27FEB19 - DEF#374 - Setting the TicketUpdateUtility Execution to False when the execution started from Ticket.
            TicketUpdateUtility.executeFlag = false;

            // 05MAR19 - DEF#354 - Avoiding MDC Trigger Looping
            if (ADDMDCTicketTriggerHandler.MDCTriggerInsertFlag) {
                return;
            }

            //18JUN19 - Avoid Ticket Version Rollup looping
            if (ComplaintTriggerHandler.updateTicketVersionCloseDateOnceCheck) {
                return;
            }
        }

        if (Trigger.isInsert && Trigger.isBefore) {                    /* Before Insert */
            // 18MAR19 - DEF#354 - Change Request
            InternalTicketServiceProcessor.newTicketFlag = true;
		    //ComplaintTriggerHandler.preventMDCGenerationFlag= true; // Added for IPDR # 409 ON MAY 15,2026.
            ComplaintTriggerHandler.isBeforeInsert();
        } else if (Trigger.isInsert && Trigger.isAfter) {              /* After Insert */
            CMPL123.AuditHandler.handleAudit();

            ADDTranslations.createTranslationTask();
            ComplaintTriggerHandler.isAfterInsert();
        } else if (Trigger.isUpdate && Trigger.isBefore) {             /* Before Update */
            // Def #123.1/CHARM-2878: skip custom logic except audit handling if only Last Modified Date is updating
            if (!UpdateParentUtility.ticketTriggerPreventFlag) {
                ComplaintTriggerHandler.isBeforeUpdate();
                ComplaintTriggerHandler.identifyPromotedTickets();
                // 30JAN19 - AQC#111 - Fix for CPU Time Limit error for non-english Country
                // 05MAR19 - DEF#101, 311 Fix - Moved from after update to before update
                if (!ComplaintTriggerHandler.TTFlag) {
                    ComplaintTriggerHandler.TTFlag = true;
                    ADDTranslations.ChildObjectTranslations();
                }
                //Added for W-001396
                ADDS4TicketTriggerHandler.beforeUpdateEventHandler();

            }
            CMPL123.AuditHandler.handleAudit();
        } else if (Trigger.isUpdate && Trigger.isAfter) {              /* After Update */
            CMPL123.AuditHandler.handleAudit();
            //Below Commented as per #715
            //ADDTranslations.processReopenJustification();

            // Def #123.1/CHARM-2878: skip custom logic except audit handling if only Last Modified Date is updating
            if (!UpdateParentUtility.ticketTriggerPreventFlag) {
                if (!ComplaintTriggerHandler.executingThroughInvokable) {
                    ComplaintTriggerHandler.isAfterUpdate();
                }
            }
        } else if (Trigger.isDelete && Trigger.isBefore) {             /* Before Delete */
           CMPL123.AuditHandler.handleAudit();
        } else if (Trigger.isDelete && Trigger.isAfter) {              /* After Delete */
             // Place your code.
        }
    }
}