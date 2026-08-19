/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDTranslationVendorTriggerhandler.
* @Why   : Handles all the customization involved on Translation Vendor object.
* @When  : 06-APR-2017.
* @Where : From Translation_Vendor_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				  06-APR-2017			 Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                   12-MAY-2020            #96/CHARM-2507             Audit trail code added on beforeUpdate() method.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020            Code Audit                 Updated Jira reference with reference from Defect Tracker.
*                                                                           Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   17-AUG-2020            Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDTranslationVendorTriggerhandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From Translation_Vendor_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From Translation_Vendor_AuditTrigger trigger.
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
    * @Invoke       : From Translation_Vendor_AuditTrigger trigger.
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
    * @Invoke       : From Translation_Vendor_AuditTrigger trigger.
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
    * @Invoke       : From Translation_Vendor_AuditTrigger trigger.
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
    * @Invoke       : From Translation_Vendor_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterDelete() {
    }
}