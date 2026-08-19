/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TranslationTaskWithTckMedEvalMDCCustom
* @Why   : Global class to check if "Meaningful Data Answer" is changed in Meanigful Data object
           and has medEval record in ticket to check the MDC trigger record creation.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    11-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    25-JUN-2020            #143 (CHARM-2801)    Modified. Added new condition for MDC ticket creation.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class MeanigfulDataAnswerMedEvalMDC implements CMPL123.IMDCCustomValidation {

    /**
    * @Method       : CustomValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    public static Boolean hasMedEval;

    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        // 18MAR19 - DEF#354 - Change Request
        if(InternalTicketServiceProcessor.newTicketFlag) { return false; }

        // 13MAR19 - DEF#354 fix - Optimized
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //Modified the above line because of a security issue. "AvoidDirectAccessTriggerMap"
            //FYI : https://pmd.github.io/pmd/pmd_rules_apex_errorprone.html#avoiddirectaccesstriggermap
            Meaningful_Data__c newMeaningfulData = (Meaningful_Data__c) newRecord;
            //#143 (CHARM-2801) start: added new valiable and condition to test if field was changed
            Meaningful_Data__c oldMeaningfulData = (Meaningful_Data__c) oldRecord;
            if (newMeaningfulData.Meaningful_Data_Answers__c  != oldMeaningfulData.Meaningful_Data_Answers__c ) {
            //#143 (CHARM-2801) end.
                if (TicketQDNumMDCCustom.hasMedEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newMeaningfulData.Compliant__c);
                }
                return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
            }
        }
        return false;
    }
}