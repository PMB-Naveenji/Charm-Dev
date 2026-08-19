/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDReopenJustificationTriggerHandler
* @Why   : Handles all the customization involved on Re-open Justification object.
* @When  : 06-APR-2017
* @Where : From Re_Open_Justification_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin  				    06-APR-2017			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   05-JAN-2021             TWD Upgrade issue     Added beforeInsert() logic to handle WF rule logic
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDReopenJustificationTriggerHandler extends TriggerHandler {
    
/**
* @Method       : beforeInsert
* @Invoke       : Events from TriggerHandler before insert
* @Description  : To handle all the logic in before insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeInsert() {
		//TWD Upgrade issue start
		//WF: Upon creation of Re-Open Justification, auto populate Re-Open Justification Added with Ticket Re-Open Rationale(Native)
		for (Re_Open_Justification__c record : (List<Re_Open_Justification__c>)Trigger.new) {
			if (record.Ticket_Re_Open_Rationale_Native__c != null) {
				record.Re_Open_Justification_Added__c = record.Ticket_Re_Open_Rationale_Native__c;
			}
		}
		//TWD Upgrade issue end
        //code which invokes 123Compliance platform audit and workflow code
        //CMPL123.AuditHandler.handleAudit();
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
        
        ADDTranslations.ChildObjectTranslations();
    }

/**
* @Method       : beforeUpdate
* @Invoke       : Events from TriggerHandler before update
* @Description  : To handle all the logic in before update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }
    
/**
* @Method       : afterUpdate
* @Invoke       : Events from TriggerHandler after update
* @Description  : To handle all the logic in after update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        
        ADDTranslations.ChildObjectTranslations();
    }

/**
* @Method       : beforeDelete
* @Invoke       : Events from TriggerHandler before delete
* @Description  : To handle all the logic in before delete event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }   
     
/**
* @Method       : afterDelete
* @Invoke       : Events from TriggerHandler after delete
* @Description  : To handle all the logic in after delete event
* @Return       : N/A
* @Params       : N/A
**/  
    public override void afterDelete() {
    }   
}