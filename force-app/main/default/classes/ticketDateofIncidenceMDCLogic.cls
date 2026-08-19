/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : ticketDateofIncidenceMDCLogic
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
global class ticketDateofIncidenceMDCLogic implements CMPL123.IMDCCustomValidation {
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
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            if(TicketQDNumMDCCustom.hasMedEval == null) {
                TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
            }
            return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
        }
        return false;
    }
}