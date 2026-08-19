/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDCustomContactTriggerhandler.
* @Why   : Handles all the customization involved on Custom Contact object.
* @When  : 06-APR-2017.
* @Where : From Contact_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  06-APR-2017            Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                  27-MAY-2020            #123/CHARM-2729             Prevented multiple updates of the ticket
*                                                                           in the same transaction.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                  28-JUL-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDCustomContactTriggerhandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From Contact_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {

        Set<Id> ticketIds = new Set<Id>();
        for (Contact__c contactRecord : (List<Contact__c>)Trigger.new) {
            if (contactRecord.Ticket__c != null) {
                ticketIds.add(contactRecord.Ticket__c);
            }
        }
        Map<Id, CMPL123CME__Complaint__c> ticketMap = new Map<Id, CMPL123CME__Complaint__c>(
            [SELECT Id, Division__c FROM CMPL123CME__Complaint__c WHERE Id IN : ticketIds]);
        for (Contact__c contactRecord : (List<Contact__c>)Trigger.new) {
            if (contactRecord.Ticket__c != null && ticketMap.get(contactRecord.Ticket__c) != null) {
                contactRecord.Division__c = ticketMap.get(contactRecord.Ticket__c).Division__c;
            }
        }
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From Contact_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterInsert() {
        updateTicketLastModifiedDate();
        //code which invokes 123Compliance platform audit and workflow code
        //CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From Contact_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterUpdate() {
        updateTicketLastModifiedDate();
        //code which invokes 123Compliance platform audit and workflow code
        //CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From Contact_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        //CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : updateTicketLastModifiedDate.
    * @Description  : To update parent record "Last Modified Date/Time" field based on child record's parent Id collection.
    * @Invoke       : From ADDCustomContactTriggerhandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void updateTicketLastModifiedDate(){
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if(!UpdateParentUtility.isTicketUpdated || !ComplaintTriggerHandler.isTicketInserting){
            Set<Id> setComplaintIdToUpdate = new Set<Id>();
            for(Contact__c objRecord : (List<Contact__c>)Trigger.new){
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

}