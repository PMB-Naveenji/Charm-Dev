/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : MDIWorkflowActionMDC.
* @Why   : Global class to check if Ticket description field is changed and has prodEval record to check MDC Ticket record creation.
* @When  : 09-JAN-2017.
* @Where : From Audit Class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    09-JAN-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    19-AUG-2020            Code Audit           Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class MDIWorkflowActionMDC implements CMPL123.IMDCCustomValidation{

    /*
    * @Method       : CustomValidation.
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record.
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom class.
    * @Return       : Boolean.
    * @Params       : Trigger Context.
    */
    global Boolean CustomValidation(SObject oldRecord, SObject newRecord){
       /* if( (Test.isRunningTest()) || (Trigger.isAfter && Trigger.isUpdate)){
            CMPL123CME__MEDDEV__c newMDI = !Test.isRunningTest() ? (CMPL123CME__MEDDEV__c) Trigger.new[0] : new CMPL123CME__MEDDEV__c(CMPL123_WF_Action__c = '123');
            CMPL123CME__MEDDEV__c oldMDI = !Test.isRunningTest() ? (CMPL123CME__MEDDEV__c) Trigger.old[0] : new CMPL123CME__MEDDEV__c();

            if(newMDI.CMPL123_WF_Action__c!=oldMDI.CMPL123_WF_Action__c){
                if(TicketQDNumMDCCustom.hasMedEval == null){
                 //TicketQDNumMDCCustom.setMedEval(newMDI.CMPL123CME__Complaint__c,newMDI.Id);
                }
                if(TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval){
                    return true;
                }else{
                return false;
                }
            }
        }*/
    return null;
    }

}