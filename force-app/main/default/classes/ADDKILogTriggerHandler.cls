/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDKILogTriggerHandler
* @Why   : Handles all the customization involved on KI Log object.
* @When  : 06-APR-2017
* @Where : From KI_Log_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID            Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*    Admin 				   06-APR-2017			    Work ID / Case ID          Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   12-MAY-2020             Defect #96 (CHARM-2507)    Modified (Audit trail code added on beforeUpdate)
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                   15-06-2020              Code Audit                 Updated Jira reference with reference from Defect Tracker. 
*                                                                              Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   28-DEC-2020             TWD Upgrade issue          Related to WF Step issue. Added autosetInactivatedDate method
* --------------------------------------------------------------------------------------------------------------------------------------
**/

public class ADDKILogTriggerHandler extends TriggerHandler {
    
    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeInsert() {
        //TWD Upgrade issue start. WF rule logic: Autoset Inactived On Field Date/Time
        List <KI_Log__c> logs = (List<KI_Log__c>)Trigger.new;
        autosetInactivatedDate(logs, null);
        //TWD Upgrade issue end.
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
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeUpdate() {
        //TWD Upgrade issue start. WF rule logic: Autoset Inactived On Field Date/Time
        List <KI_Log__c> logs = (List<KI_Log__c>)Trigger.new;
        Map <Id, KI_Log__c> oldlogById = (Map <Id, KI_Log__c>)Trigger.oldMap;
        autosetInactivatedDate(logs, oldlogById );
        //TWD Upgrade issue end.
        //code which invokes 123Compliance platform audit and workflow code
        //Defect #96 (CHARM-2507) start. Fields should be tracked in before Update
        CMPL123.AuditHandler.handleAudit();
        //Defect #96 (CHARM-2507) end
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
    
    /*
    * @Method       : autosetInactivatedDate.
    * @Description  : Moving WF rule: Autoset Inactived On Field Date/Time to trigger handler.
    * @Invoke       : From KI_Log_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : List <KI_Log__c> logs, Map <Id, KI_Log__c> oldLogById
    */
    public static void autosetInactivatedDate(List <KI_Log__c> logs, Map <Id, KI_Log__c> oldLogById) {
        for (KI_Log__c log: logs) {
            if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c 
                && log.Status__c == 'Inactive' && (oldLogById == null || oldLogById.get(log.Id).Status__c != log.Status__c)){
                    log.Inactived_On__c = datetime.now();
            }
        }
    }
}