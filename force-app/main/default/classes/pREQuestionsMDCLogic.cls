/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : pREQuestionsMDCLogic
* @Why   : Global class to check if Ticket Search record Ticket Review Status is changed, and if yes then
           create the MDC trigger for that change.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    19-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  CHaRM COE                30-JUL-2026             CHaRM R9.0/IPDR 83   Use a dedicated Product Evaluation query for MDC generation to 
* 																		 include Closed-Voided records, while preserving existing status 
* 																		 exclusions in the shared hasMedEval logic used by other processes. 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
global class pREQuestionsMDCLogic implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        // 18MAR19 - DEF#354 - Change Request
        if(InternalTicketServiceProcessor.newTicketFlag) { return false; }

        // 08MAR19 - DEF#354 fix
        //TWD Upgrade fix BEGIN
        if(Test.isRunningTest() || (!InternalTicketServiceProcessor.preStatusChangeFlag && Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            pRE_Question__c newpREQuestions = (pRE_Question__c) newRecord;
            // CHaRM R9.0/IPDR-83 : Direct query used here to include all Product Evaluation records (including Closed-Voided)
            // for MDC generation, as the shared hasMedEval logic excludes certain statuses required elsewhere.
            return [SELECT COUNT() FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c = :newpREQuestions.Parent_Ticket_Id__c] > 0;
        }
        return false;
    }
}