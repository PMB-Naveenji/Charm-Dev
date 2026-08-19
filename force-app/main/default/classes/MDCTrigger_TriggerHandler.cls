/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : MDCTrigger_TriggerHandler.
* @Why   : Public class to manage all the custom coding invoked on the CMPL123__MDC_Trigger__c object.
* @When  : 28-DEC-2020.
* @Where : From MDCTrigger_TriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue           Created. Added 'executeLogicFromWFRules()' method to move
*                                                                               logic from Workflow Rules with Field Updates on
*                                                                               MDC Trigger to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class MDCTrigger_TriggerHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Invoke       : Events from TriggerHandler before insert.
    * @Description  : To handle all the logic in before insert event.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END
    }

    /*
    * @Method       : beforeUpdate.
    * @Invoke       : Events from TriggerHandler before update.
    * @Description  : To handle all the logic in before update event.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END
    }

    /*
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on MDC Trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<CMPL123__MDC_Trigger__c> newList = (List<CMPL123__MDC_Trigger__c>) Trigger.new;

        for (CMPL123__MDC_Trigger__c newMDCTrigger :newList) {
            //  MDC Field Criteria
            if (null != newMDCTrigger.CMPL123__Field__c) {
                newMDCTrigger.CMPL123__Field__c = null;
            }
        }
    }
}