/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDProductTriggerhandler.
* @Why   : Handles all the customization involved on Product object.
* @When  : 06-APR-2017.
* @Where : From UpdateProductTicketAsync class, CMPL123_Product_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                 Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                06-APR-2017          Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                12-MAY-2020          #96/CHARM-2507             Audit trail code added on beforeUpdate() method.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                15-JUN-2020          Code Audit                 Updated Jira reference with reference from Defect Tracker.
*                                                                      Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020          Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDProductTriggerhandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From CMPL123_Product_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From CMPL123_Product_AuditTrigger trigger.
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
    * @Invoke       : From CMPL123_Product_AuditTrigger trigger.
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
    * @Invoke       : From CMPL123_Product_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();

        updateProductTicket();
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From CMPL123_Product_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeDelete() {
        //Prevent deletion on product object, defect #1362
        for(Sobject obj : Trigger.old){
            obj.addError(System.Label.Custom_Attachment_Error_Message);
        }
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterDelete.
    * @Description  : To handle all the logic in after delete event.
    * @Invoke       : From CMPL123_Product_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterDelete() {
    }

    /*
    * @Method       : updateProductTicket.
    * @Description  : W-000488 - To fix DML and CPU Time Limit Error.
    * @Invoke       : From ADDProductTriggerhandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void updateProductTicket(){
        Set<Id> setProductIds = New Set<Id>();
        Map<Id, CMPL123__Product__c> objProductOldMap = (Map<Id, CMPL123__Product__c>)Trigger.oldMap;
        for(CMPL123__Product__c objProduct : (List<CMPL123__Product__c>)Trigger.new) {
            if(objProductOldMap == null || objProduct.Reportable_Confirmed_Malfunction_Descrip__c != objProductOldMap.get(objProduct.Id).Reportable_Confirmed_Malfunction_Descrip__c){
                setProductIds.add(objProduct.Id);
            }
        }

        if(setProductIds.size() > 0)
            Database.executeBatch(New UpdateProductTicketAsync(setProductIds),200);
    }

}