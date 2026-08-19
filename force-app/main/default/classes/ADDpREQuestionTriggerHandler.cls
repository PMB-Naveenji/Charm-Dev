/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDpREQuestionTriggerHandler.
* @Why   : Handles all the customization involved on pRE Question object.
* @When  : 06-APR-2017.
* @Where : From pRE_Question_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                 Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                06-APR-2017		    Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020          Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDpREQuestionTriggerHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From pRE_Question_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From pRE_Question_AuditTrigger trigger.
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
    * @Invoke       : From pRE_Question_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From pRE_Question_AuditTrigger trigger.
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
    * @Invoke       : From pRE_Question_AuditTrigger trigger.
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
    * @Invoke       : From pRE_Question_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterDelete() {
    }
}