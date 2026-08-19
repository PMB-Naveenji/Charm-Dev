/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDCustomerResponseMasterHandler.
* @Why   : Handles all the customization involved on Customer Response Master object.
* @When  : 23-MAR-2017.
* @Where : From Customer_Response_Master_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    06-APR-2017            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    12-MAY-2020            Defect #96 (CHARM-2507)           Modified (Audit trail code added on beforeUpdate)
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                        Updated Jira reference with reference from
*                                                                                       Defect Tracker. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue                 Added 'executeLogicFromWFRules()' method to move *                                                                                      logic from Workflow Rules with Field Updates
*                                                                                      on Customer Response Master to Apex.
*                                                                                      Commented logic in 'beforeInsert()' method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDCustomerResponseMasterHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        //  The logic below ic commented because it has never been executed, because 'Customer_Response_Master_AuditTrigger' trigger
        //      did not have 'before insert' event.
        // List<Customer_Response_Master__c> newCRMasterList = (List<Customer_Response_Master__c>)Trigger.new;
        // for(Customer_Response_Master__c CRMaster : newCRMasterList){
        //     CRMaster.Category_Text_Hidden__c = CRMaster.Category__c;
        // }

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
        List<Customer_Response_Master__c> newCRMasterList = (List<Customer_Response_Master__c>) Trigger.new;

        Map<Id, Customer_Response_Master__c> queriedCRMasterList = new Map<Id, Customer_Response_Master__c>([
            SELECT Id, Name, CMPL123_WF_Status__c, (SELECT Id FROM Attachments)
            FROM Customer_Response_Master__c
            WHERE Id IN :newCRMasterList
        ]);

        for (Customer_Response_Master__c CRMaster :newCRMasterList) {
            Customer_Response_Master__c oldCRM = (Customer_Response_Master__c) Trigger.oldMap.get(CRMaster.Id);

            CRMaster.Category_Text_Hidden__c = CRMaster.Category__c;

            if (oldCRM.CMPL123_WF_Status__c != CRMaster.CMPL123_WF_Status__c
                    && CRMaster.CMPL123_WF_Status__c == 'Closed-Done'
                    && queriedCRMasterList.get(CRMaster.Id).Attachments.size() == 0) {
                CRMaster.addError(System.Label.Customer_Response_Master_Attachment_Required);
            }
        }

        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END

        //code which invokes 123Compliance platform audit and workflow code
        //Defect #96 (CHARM-2507) start. Fields should be tracked in before Update
        CMPL123.AuditHandler.handleAudit();
        //Defect #96 (CHARM-2507) end
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
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on CRM.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<Customer_Response_Master__c> newList = (List<Customer_Response_Master__c>) Trigger.new;
        Map<Id, Customer_Response_Master__c> oldMap = (Map<Id, Customer_Response_Master__c>) Trigger.oldMap;

        for (Customer_Response_Master__c newCRM :newList) {
            Boolean wfActionIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && newCRM.CMPL123_WF_Action__c != oldMap.get(newCRM.Id).CMPL123_WF_Action__c);

            if (!wfActionIsChanged) {
                continue;
            }

            String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

            //  Update Customer Letter Approval fields
            if (newCRM.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Approve) {
                newCRM.Customer_Letter_Approved_By__c = actionPerformedBy;
                newCRM.Customer_Letter_Approval_Date__c = Date.today();
            }

            //  Workflow - Retire
            if (newCRM.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Retire) {
                newCRM.Retired_By__c = actionPerformedBy;
                newCRM.Retired_On__c = DateTime.now();
            }
        }
    }
}