/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDCountryBackupVigilanceContactHandler.
* @Why   : Handles all the customization involved on Country Backup Vigilance Contact object.
* @When  : 06-APR-2017.
* @Where : From Country_Backup_Vigilance_Contact_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                    Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin 				  06-APR-2017		      Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                   12-MAY-2020             #96/CHARM-2507             Audit trail code added on beforeUpdate() method.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020             Code Audit                 Updated Jira reference with reference from Defect Tracker.
*                                                                            Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   28-JUL-2020             Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDCountryBackupVigilanceContactHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From Country_Backup_Vigilance_Contact_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From Country_Backup_Vigilance_Contact_AuditTrigger trigger.
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
    * @Invoke       : From Country_Backup_Vigilance_Contact_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
	    //Defect #96 (CHARM-2507). Fields should be tracked in before Update
        CMPL123.AuditHandler.handleAudit();
        //Defect #96 (CHARM-2507)
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From Country_Backup_Vigilance_Contact_AuditTrigger trigger.
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
    * @Invoke       : From Country_Backup_Vigilance_Contact_AuditTrigger trigger.
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
    * @Invoke       : From Country_Backup_Vigilance_Contact_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterDelete() {
    }
}