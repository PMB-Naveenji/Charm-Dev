/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDpREInformationTriggerHandler.
* @Why   : Handles all the customization involved on pRE Information object.
* @When  : 06-APR-2017.
* @Where : From pRE_Information_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer           Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin               06-APR-2017            Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc               27-MAY-2020            #123/CHARM-2729             Prevented multiple updates of the ticket
*                                                                        in the same transaction.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan               12-MAY-2020            #96/CHARM-2507              Audit trail code added on beforeUpdate() method.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih               11-AUG-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDpREInformationTriggerHandler extends TriggerHandler {
    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From pRE_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterInsert() {

        updateTicketLastModifiedDate();
        ADDTranslations.ChildObjectTranslations();
        //Defect #96 (CHARM-2507) start. Audit Trail should be the last line of method
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        //Defect #96 (CHARM-2507)  end.
    }

    /*
    * @Method       : beforeUpdate.
    * @Description  : To handle all the logic in before update event.
    * @Invoke       : From pRE_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
        //Defect #96 (CHARM-2507) start. Fields should be tracked in before Update
        CMPL123.AuditHandler.handleAudit();
        //Defect #96 (CHARM-2507) end
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From pRE_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterUpdate() {

        updateTicketLastModifiedDate();
        ADDTranslations.ChildObjectTranslations();
        //Defect #96 (CHARM-2507) start. Audit Trail should be the last line of method
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        //Defect #96 (CHARM-2507) end.
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From pRE_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : updateTicketLastModifiedDate.
    * @Description  : To update parent record "Last Modified Date/Time" field based on child record's parent Id collection.
    * @Invoke       : From ADDpREInformationTriggerHandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void updateTicketLastModifiedDate() {
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if(!UpdateParentUtility.isTicketUpdated || !ComplaintTriggerHandler.isTicketInserting){
            Set<Id> setComplaintIdToUpdate = new Set<Id>();
            for(pRE_Information__c objRecord : (List<pRE_Information__c>)Trigger.new){
                if(objRecord.Complaint__c != null)
                    setComplaintIdToUpdate.add(objRecord.Complaint__c);
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