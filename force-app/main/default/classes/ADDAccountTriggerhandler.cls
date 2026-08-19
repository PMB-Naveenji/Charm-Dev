/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDAccountTriggerhandler
* @Why   : Handles all the customization involved on Account object.
* @When  : 4-JUN-2017
* @Where : From Account_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID           Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin	    			 4-JUN-2017				Work ID / Case ID         Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*	oivan                    12-MAY-2020            Defect #96 (CHARM-2507)   Modified (Audit trail code added on beforeUpdate)
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit                Updated Jira reference with reference from Defect Tracker. 
*                                                                             Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDAccountTriggerhandler extends TriggerHandler {

    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/    
    public override void beforeInsert() {
    }

    /**
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

	/**
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : This code handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void beforeUpdate() {
		//Defect #96 (CHARM-2507) start. Fields should be tracked in before Update
        CMPL123.AuditHandler.handleAudit();
        //Defect #96 (CHARM-2507) end
    }

    /**
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : This code handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /**
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : This code handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }   

    /**
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after delete
    * @Description  : This code handle all the logic in after delete event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterDelete() {
    }
}