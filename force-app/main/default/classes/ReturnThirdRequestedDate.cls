/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : ReturnThirdRequestedDate
* @Why   : Global class to check if "Third Return Requested Date" is changed in Return object and has prodEval record in ticket to
*          check the MDC trigger record creation
* @When  : 05-JAN-2021
* @Where : From ReturnThirdRequestedDate Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    11-JAN-2017            Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues    Modified entry condition to execute MDC logic at beforeUpdate
*                                                                         event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class ReturnThirdRequestedDate implements CMPL123.IMDCCustomValidation {

    public static Boolean hasProdEval;
    /**
    * @Method       : customValidation
    * @Invoke       : Events from CustomValidation
    * @Description  : To Custom Validation
    * @Return       : N/A
    * @Params       : N/A
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            Return__c newReturn = (Return__c) newRecord;
            Return__c oldReturn = (Return__c) oldRecord;

            if (newReturn.Third_Return_Requested_Date__c != oldReturn.Third_Return_Requested_Date__c) {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newReturn.Ticket__c);
                }
                return TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}