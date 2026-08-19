/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : MDCAckMappingTriggerHandler.
* @Why   : Public class to manage all the custom coding invoked on the CMPL123__AcknowledgementMapping__c object.
* @When  : 28-DEC-2020.
* @Where : From MDCAckMappingTriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue           Created. Added 'executeLogicFromWFRules()' method to move
*                                                                               logic from Workflow Rules with Field Updates on
*                                                                               MDCAcknowledgementMapping to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class MDCAckMappingTriggerHandler extends TriggerHandler {
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
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on AcknowledgementMapping.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<CMPL123__AcknowledgementMapping__c> newList = (List<CMPL123__AcknowledgementMapping__c>) Trigger.new;

        List<CMPL123__MDC_Trigger__c> mdcTriggersToUpdate = new List<CMPL123__MDC_Trigger__c>();

        //  Update Group Name
        for (CMPL123__AcknowledgementMapping__c newAM :newList) {
            if (null == newAM.CMPL123__PublicGroupAcknowledgment__c) {
                continue;
            }

            mdcTriggersToUpdate.add(new CMPL123__MDC_Trigger__c(
                Id = newAM.CMPL123__MDC_Trigger_Acknowledgment__c,
                Selected_Group_Name__c = newAM.CMPL123__PublicGroupAcknowledgment__c
            ));
        }

        update mdcTriggersToUpdate;
    }
}