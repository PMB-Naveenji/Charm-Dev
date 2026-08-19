/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDAdditionalApprovalHandler.
* @Why   : Handles all the customization involved on Additional Approval object.
* @When  : 26-MAR-2018.
* @Where : From Additional_Approval_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    26-MAR-2018            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue                 Added 'executeLogicFromWFRules()' method to move *                                                                                      logic from Workflow Rules with Field Updates
*                                                                                      on Additional Approval to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDAdditionalApprovalHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END
    }

    /*
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeUpdate() {
        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END

        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : beforeDelete
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : To handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeDelete() {

        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterDelete
    * @Invoke       : Events from TriggerHandler after delete
    * @Description  : To handle all the logic in after delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterDelete() {
    }

    /*
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on Additional Approval.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<Additional_Approval__c> newList = (List<Additional_Approval__c>) Trigger.new;
        Map<Id, Additional_Approval__c> oldMap = (Map<Id, Additional_Approval__c>) Trigger.oldMap;

        for (Additional_Approval__c newAA :newList) {
            Boolean wfActionIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && newAA.CMPL123_WF_Action__c != oldMap.get(newAA.Id).CMPL123_WF_Action__c);

            if (!wfActionIsChanged) {
                continue;
            }

            String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
            DateTime actionPerformedOn = DateTime.now();

            //  Clear_Reject_Rationale
            if (newAA.CMPL123_WF_Action__c == AspenConstants.STR_Promote) {
                newAA.Submit_for_Approval_By__c = actionPerformedBy;
                newAA.Submit_for_Approval_On__c = actionPerformedOn;

                newAA.Approve_By__c = null;
                newAA.Approve_On__c = null;
                newAA.Reject_By__c = null;
                newAA.Reject_On__c = null;
                newAA.Reject_Rationale__c = null;
            }

            //  Update Reject field
            if (newAA.CMPL123_WF_Action__c == AspenConstants.STR_Reject) {
                newAA.Reject_By__c = actionPerformedBy;
                newAA.Reject_On__c = actionPerformedOn;
            }

            //  update_Approve_Field
            if (newAA.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Approve) {
                newAA.Approve_By__c = actionPerformedBy;
                newAA.Approve_On__c = actionPerformedOn;
            }

            //  update_Void
            if (newAA.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void) {
                newAA.Vioded_By__c = actionPerformedBy;
                newAA.Voided_On__c = actionPerformedOn;
            }
        }
    }
}