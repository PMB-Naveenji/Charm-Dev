/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : ReturnTrackingNumber
* @Why   : Global class to check if "Tracking Number" is changed in Return object
           and has prodEval record in ticket to check the MDC trigger record creation.
* @When  : 05-JAN-2021
* @Where : From ReturnTrackingNumber
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    23-JAN-2017            Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues    Modified entry condition to execute MDC logic at beforeUpdate
*                                                                         event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class ReturnTrackingNumber implements CMPL123.IMDCCustomValidation {
    public static Boolean hasProdEval;
    public static Boolean recursionHandler = false;
    /**
    * @Method       : customValidation
    * @Invoke       : Events CustomValidation
    * @Description  : To handle Custom Validation
    * @Return       : N/A
    * @Params       : N/A
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord){
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate && !recursionHandler)) {
            //TWD Upgrade fix END
            recursionHandler = true;
            Return__c newReturn = (Return__c) newRecord;
            Return__c oldReturn = (Return__c) oldRecord;

            if (newReturn.Tracking_Number__c != oldReturn.Tracking_Number__c) {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newReturn.Ticket__c);
                }
                return TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}