/**
*  -----------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : pREIformationProdEvalMDCLogic
* @Why   : 
* @When  : 25-JUN-2026
* @Where : From Audit Class
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  -----------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      	Description
*  -----------------------------------------------------------------------------------------------------------------------------------------
*	Charm COE				 25-JUN-2026			CHaRM R9/IPDR 501		This class will generate MDC if ticket has a Product Evaluation 
										                                    record for Evaluator/Investigator.
*  -----------------------------------------------------------------------------------------------------------------------------------------
**/
global class pREIformationProdEvalMDCLogic implements CMPL123.IMDCCustomValidation {
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        if(InternalTicketServiceProcessor.newTicketFlag) { return false; }
        if(Test.isRunningTest() || (!InternalTicketServiceProcessor.preStatusChangeFlag && Trigger.isBefore && Trigger.isUpdate)) {
            pRE_Information__c newpREQuestions = (pRE_Information__c) newRecord;
            if(TicketQDNumMDCCustom.hasProdEval == null) {
                TicketQDNumMDCCustom.setDefaults(newpREQuestions.Complaint__c);
            }
            system.debug('TicketQDNumMDCCustom.hasProdEval--->'+TicketQDNumMDCCustom.hasProdEval);
            return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval;
        }
        return false;
    }
}