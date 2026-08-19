/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDTranslationTaskTriggerhandler.
* @Why   : Handles all the customization involved on Translation Task object.
* @When  : 06-APR-2017.
* @Where : From Translation_Task_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				  06-APR-2017			 Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   27-MAY-2020            #123/CHARM-2729            Prevented multiple updates of the ticket
*                                                                           in the same transaction.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   17-AUG-2020            Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDTranslationTaskTriggerhandler extends TriggerHandler {
    private static boolean isBeforeInsertFirstRun = false;
    private static boolean isAfterInsertFirstRun = false;
    private static boolean isBeforeUpdateFirstRun = false;
    private static boolean isAfterUpdateFirstRun = false;
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From Translation_Task_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
        if(isBeforeInsertFirstRun == false) {
            //isBeforeInsertFirstRun = true;
            ADDS4TranslationTaskTiggerHandler.beforeEventHandler();
        }
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From Translation_Task_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();

        if(!ComplaintTriggerHandler.isTicketUpdated){
            updateTicketLastModifiedDate();
        }

        if(isAfterInsertFirstRun == false) {
            //isAfterInsertFirstRun = true;
            ADDS4TranslationTaskTiggerHandler.afterEventHandler();
        }


    }

    /*
    * @Method       : beforeUpdate.
    * @Description  : To handle all the logic in before update event.
    * @Invoke       : From Translation_Task_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
        List<Translation_Task__c> newTranslationTasks = (List<Translation_Task__c>) Trigger.new;
        Map<Id, Translation_Task__c> oldTranslationTasks = (Map<Id, Translation_Task__c>) Trigger.oldMap;
        ADDS4TranslationTaskTiggerHandler.beforeEventHandler();
        if(!isBeforeUpdateFirstRun) {
            for (Translation_Task__c translationTask : newTranslationTasks){
                String previousStatus = oldTranslationTasks.get(translationTask.Id).CMPL123_WF_Status__c;
                if (previousStatus == 'Closed-Voided' && translationTask.CMPL123_WF_Status__c == previousStatus) {
                   translationTask.addError(Label.Record_Locked);
                }
            }
            isBeforeUpdateFirstRun = true;
        }

        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From Translation_Task_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterUpdate() {

        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();

        if(isAfterUpdateFirstRun == false) {
            //isAfterUpdateFirstRun = true;
            ADDS4TranslationTaskTiggerHandler.afterEventHandler();
        }
        if(TicketUpdateUtility.executeFlag){
            TicketUpdateUtility.executeFlag = false;
            Set<Id> parentIds = new Set<Id>();
            List< Translation_Task__c > newTranslationTasks = (List< Translation_Task__c >)Trigger.New;
            for(Translation_Task__c objTransTask : newTranslationTasks){
                if(objTransTask.CMPL123_WF_Status__c == 'Closed-Done' || objTransTask.CMPL123_WF_Status__c == 'Closed-Voided'){
                    parentIds.add(objTransTask.Parent_Ticket__c);
                }
            }
            if(parentIds != null && parentIds.size() > 0){
                // Call the utility method to update the parent
                TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
            }else if(!ComplaintTriggerHandler.isTicketUpdated){
                updateTicketLastModifiedDate();
            }
        }
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From Translation_Task_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : updateTicketLastModifiedDate.
    * @Invoke       : From ADDTranslationTaskTriggerhandler class.
    * @Description  : To update parent record "Last Modified Date/Time" field based on child record's parent Id collection.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void updateTicketLastModifiedDate(){
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if(!UpdateParentUtility.isTicketUpdated || !ComplaintTriggerHandler.isTicketInserting){
            Set<Id> setComplaintIdToUpdate = new Set<Id>();
            for(Translation_Task__c objRecord : (List<Translation_Task__c>)Trigger.new){
                if(objRecord.Parent_Ticket__c != null)
                    setComplaintIdToUpdate.add(objRecord.Parent_Ticket__c);
            }
            if(setComplaintIdToUpdate.size() > 0){
                UpdateParentUtility.ticketTriggerPreventFlag = true;
                UpdateParentUtility.updateparent(setComplaintIdToUpdate);
                // Defect #123/CHARM-2729: disable ticket trigger logic only for UpdateParentUtility.updateparent method execution
                UpdateParentUtility.ticketTriggerPreventFlag = false;
            }
        }
    }


}