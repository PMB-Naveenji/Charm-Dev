/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : pREIformationMDCLogic
* @Why   : 
* @When  : 
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Dinesh Kumar            25-Sep-2024            CHaRM R5/IPDR663      Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class pREIformationMDCLogic implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : 
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record for PRE Information object field update
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        if(InternalTicketServiceProcessor.newTicketFlag) { return false; }

        if(Test.isRunningTest() || (!InternalTicketServiceProcessor.preStatusChangeFlag && Trigger.isBefore && Trigger.isUpdate)) {
            pRE_Information__c newpREQuestions = (pRE_Information__c) newRecord;
            if(TicketQDNumMDCCustom.hasMedEval == null) {
                TicketQDNumMDCCustom.setDefaults(newpREQuestions.Complaint__c);
            }
            return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
        }
        return false;
    }
}