/**
*  -----------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketDateofIncidenceProdEvalMDCLogic
* @Why   : 
* @When  : 20-JUL-2026
* @Where : From Audit Class
*  -----------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  -----------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      	Description
*  -----------------------------------------------------------------------------------------------------------------------------------------
*	Charm COE				 20-JUL-2026			CHaRM R9.0/IPDR 501		This class will generate MDC if ticket has a Product Evaluation 
										                                    record for Evaluator/Investigator.
*  -----------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketDateofIncidenceProdEvalMDCLogic implements CMPL123.IMDCCustomValidation{
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        if(InternalTicketServiceProcessor.newTicketFlag) { return false; }

        if(Test.isRunningTest() || (!InternalTicketServiceProcessor.preStatusChangeFlag && Trigger.isBefore && Trigger.isUpdate)) {
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            if(TicketQDNumMDCCustom.hasProdEval == null) {
                TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
            }
            return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval;
        }
        return false;
    }
}