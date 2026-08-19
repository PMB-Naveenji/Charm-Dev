/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CMPL123CME_MEDDEV_AuditTrigger.
* @Why   : Handles all the customization involved on CMPL123CME__MEDDEV__c object.
* @When  : 07-FEB-2019.
* @Where : From CMPL123CME__MEDDEV__c object events.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    07-FEB-2019            Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    13-APR-2020            Defect #70 fix              Add MEDDEVTriggerHandler.checkRequiredFieldsUponClosing
*                                                                               call upon before update event.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                  Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    05-JUN-2020            #123/CHARM-2729             Added parent ticket LastModifiedDate updating.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    09-JUN-2020            #123/CHARM-2729             Skipped capacitive logic if only LastModifiedDate is updating.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                  Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* dskak                    02-JUL-2020            #131 / CHARM-2734           Added if-conditions and populate six fields.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-OCT-2020            HC #100/CHARM-3518          Added locking functionality for Pending statuses.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue           Added 'MEDDEVTriggerHandler.executeLogicFromWFRules()' method calls.
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             10-Nov-2023            CHaRM-R4/IPDR-538           Added Audit Handler code in Before Insert And After Insert.
                                                                              Moved the Audit handler code to the end in Before Update and
                                                                              After Update.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

trigger CMPL123CME_MEDDEV_AuditTrigger on CMPL123CME__MEDDEV__c (before insert, before update, before delete, after insert, after update) {
    if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('CMPL123CME_MEDDEV_AuditTrigger');

        if (Trigger.isInsert && Trigger.isBefore) {
            MEDDEVTriggerHandler.beforeEventHandler();
            ADDS3MDITriggerHandler.fieldUpdates();

            //  TWD Upgrade issue - Fix START
            MEDDEVTriggerHandler.executeLogicFromWFRules();
            //  TWD Upgrade issue - Fix END
            //CHaRM-R4: Added the below code for Audit Trail
             CMPL123.AuditHandler.handleAudit();
            System.debug('cpu after med dev field updates:' + Limits.getCpuTime());
        }

        /* After Insert */
        else if(Trigger.isInsert && Trigger.isAfter){
            //CHaRM-R4 Commented the below code to move it to the end of the trigger connext
           /* CMPL123.AuditHandler.handleAudit();
            System.debug('cpu after handle audit - after insert medev:' + Limits.getCpuTime());*/

            MEDDEVTriggerHandler.afterEventHandler();
            // #123/CHARM-2729: parent ticket LastModifiedDate updating
            MEDDEVTriggerHandler.updateTicketLastModifiedDate();

            if (UpdateParentUtility.flag) {
                UpdateParentUtility.flag = false;

                Set<Id> productticketRecordIdSet = new Set<Id>();

                for (CMPL123CME__MEDDEV__c meddevCode : Trigger.new) {
                    if (meddevCode.Product__c != null) {
                        productticketRecordIdSet.add(meddevCode.Product__c);
                    }
                }

                UpdateParentUtility.updateparent_trend(productticketRecordIdSet);
            }
            //CHaRM-R4: Moved the below code for Audit Trail
            CMPL123.AuditHandler.handleAudit();
            System.debug('cpu after handle audit - after insert medev:' + Limits.getCpuTime());
        }

        /* Before Update */
        else if (Trigger.isUpdate && Trigger.isBefore) {
            // Def HC #100/CHARM-3518: checks edit access
            if (!MEDDEVTriggerHandler.isEditAccessOnPendingChecked) {
                MEDDEVTriggerHandler.checkEditableOnPendingStatus('CMPL123_WF_Status__c');
                MEDDEVTriggerHandler.isEditAccessOnPendingChecked = true;
            }

            // Def #70 fix: validate data upon closing
            MEDDEVTriggerHandler.checkRequiredFieldsUponClosing(
                (Map<Id, CMPL123CME__MEDDEV__c>)Trigger.newMap,
                (Map<Id, CMPL123CME__MEDDEV__c>) Trigger.oldMap);
            // Def #70 fix end

            Boolean isDueDateChanged = false;

            for (CMPL123CME__MEDDEV__c medDev :Trigger.New) {
                isDueDateChanged = medDev.Submission_Due_Date__c != Trigger.oldMap.get(medDev.Id).Submission_Due_Date__c;

                //  Defect 131 / CHARM-2734 fix start
                Boolean wfStatusWasChanged = medDev.CMPL123_WF_Status__c != ((Map<Id, CMPL123CME__MEDDEV__c>) Trigger.oldMap).get(medDev.Id).CMPL123_WF_Status__c;

                if (wfStatusWasChanged) {
                    //Added on 04 FEB 2019 - (FRS-1500-10)
                    if (medDev.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Waive && medDev.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Waived) {
                        medDev.Waived_By__c = UserInfo.getName();
                        medDev.Waived_On__c = System.now();
                    }

                    if (medDev.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void && medDev.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided) {
                        medDev.Voided_By__c = UserInfo.getName();
                        medDev.Voided_On__c = System.now();
                    }

                    if (medDev.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Submit_To_Regulatory && medDev.CMPL123_WF_Status__c == AspenConstants.STR_WF_Pending_Regulatory) {
                        medDev.Submit_to_Regulatory_By__c = UserInfo.getName();
                        medDev.Submit_to_Regulatory_Date__c = Date.today();
                    }

                    if (medDev.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Close && medDev.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Done) {
                        medDev.Closed_By__c = UserInfo.getName();
                        medDev.Closed_On__c = System.now();
                    }

                    if (medDev.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Complete_Regulatory_Response && medDev.CMPL123_WF_Status__c == AspenConstants.STR_WF_Action_Pending_Final_Review) {
                        medDev.Complete_Regulatory_Response_By__c = UserInfo.getName();
                        medDev.Complete_Regulatory_Response_Date__c = Date.today();
                    }
                }
                // Defect #131 / CHARM-2734 fix end
            }
            //CHaRM-R4: Commented the below 3 lines of code to move the Audit handler code to the end of method to capture all the field updates
            //          in the Audit trail. And also commented the "isDueDateChanged" condition.
           // if (!isDueDateChanged) {
               /* CMPL123.AuditHandler.handleAudit();
                System.debug('cpu after handle audit - before update medev:' + Limits.getCpuTime());*/

                // Def #123/CHARM-2729: skip capacitive logic if only lastmodifieddate updating
                if (!UpdateParentUtility.isMedDevLastModifDateUpdating) {
                    MEDDEVTriggerHandler.beforeEventHandler();
                    ADDS3MDITriggerHandler.fieldUpdates();
                }
           // }//CHaRM-R4: Commented the Code for the Above fix.

            //  TWD Upgrade issue - Fix START
            MEDDEVTriggerHandler.executeLogicFromWFRules();
            //  TWD Upgrade issue - Fix END
            //CHaRM-R4: Audit handler code moved to the end.
            CMPL123.AuditHandler.handleAudit(); 
            System.debug('cpu after handle audit - before update medev:' + Limits.getCpuTime());//CHaRM-R4
        }

        /* After Update */
        else if (Trigger.isUpdate && Trigger.isAfter) {
            Boolean isDueDateChanged = false;

            for (CMPL123CME__MEDDEV__c medDev : Trigger.New) {
                if (medDev.Submission_Due_Date__c    != Trigger.oldMap.get(medDev.Id).Submission_Due_Date__c) {
                    isDueDateChanged = true;
                }
            }
             //CHaRM-R4: Commented the below 3 lines of code to move the Audit handler code to the end of method to capture all the field updates
            //          in the Audit trail. And also commented the "isDueDateChanged" condition.
            //if (!isDueDateChanged) { 
               /* CMPL123.AuditHandler.handleAudit();
                System.debug('cpu after handle audit - after update medev:' + Limits.getCpuTime());*/

                // Def #123/CHARM-2729: skip capacitive logic if only lastmodifieddate updating
                if (!UpdateParentUtility.isMedDevLastModifDateUpdating) {
                    MEDDEVTriggerHandler.afterEventHandler();
                }
           // }//CHaRM-R4:Commented the Code for the Above fix.

            // #123/CHARM-2729: parent ticket LastModifiedDate updating
            MEDDEVTriggerHandler.updateTicketLastModifiedDate();

            if (UpdateParentUtility.flag) {
                UpdateParentUtility.flag = false;

                Set<Id> productticketRecordIdSet = new Set<Id>();

                for (CMPL123CME__MEDDEV__c meddevCode : Trigger.new) {
                    if (meddevCode.Product__c != null) {
                        productticketRecordIdSet.add(meddevCode.Product__c);
                    }
                }

                UpdateParentUtility.updateparent_trend(productticketRecordIdSet);
            }
            //CHaRM-R4: Audit handler code moved to the end.
            CMPL123.AuditHandler.handleAudit(); 
            System.debug('cpu after handle audit - before update medev:' + Limits.getCpuTime());// CHaRM-R4
        }

        /* Before Delete */
        else if (Trigger.isDelete && Trigger.isBefore) {
            CMPL123.AuditHandler.handleAudit();
        }

        /* After Delete */
        else if (Trigger.isDelete && Trigger.isAfter) {
             // Place your code.
        }
    }
}