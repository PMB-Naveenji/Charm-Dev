/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDComplaintCodesTriggerhandler.
* @Why   : Handles all the customization involved on Complaint Codes object.
* @When  : 06-APR-2018.
* @Where : From CMPL123CME_Complaint_Code_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin    				06-APR-2018		       Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 27-JUL-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDComplaintCodesTriggerhandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From CMPL123CME_Complaint_Code_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From CMPL123CME_Complaint_Code_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : beforeUpdate.
    * @Description  : To handle all the logic in before update event.
    * @Invoke       : From CMPL123CME_Complaint_Code_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From CMPL123CME_Complaint_Code_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From CMPL123CME_Complaint_Code_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterDelete.
    * @Description  : To handle all the logic in after delete event.
    * @Invoke       : From CMPL123CME_Complaint_Code_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterDelete() {
    }
}