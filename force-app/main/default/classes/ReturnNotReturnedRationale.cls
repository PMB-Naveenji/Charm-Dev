/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : ReturnNotReturnedRationale
* @Why   : Global class to check if "Return not Returned Rationale" is changed in Return object
*          and has prodEval record in ticket to check the MDC trigger record creation
* @When  : 05-JAN-2021
* @Where : From ReturnNotReturnedRationale class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    23-MAR-2017            Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit            Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit            Removed commented code. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues    Modified entry condition to execute MDC logic at beforeUpdate
*                                                                         event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class ReturnNotReturnedRationale implements CMPL123.IMDCCustomValidation {
    public static Boolean hasProdEval;
    public static Boolean recursionHandler = false;
    /**
    * @Method       : customValidation
    * @Invoke       : Events from CustomValidation
    * @Description  : To handle Custom Validation
    * @Return       : N/A
    * @Params       : N/A
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate && !recursionHandler)) {
            //TWD Upgrade fix END
            recursionHandler = true;
           //Modified the above two lines because of a security issue. "AvoidDirectAccessTriggerMap"
           //FYI : https://pmd.github.io/pmd/pmd_rules_apex_errorprone.html#avoiddirectaccesstriggermap
            Return__c newReturn, oldReturn;
            newReturn = (Return__c)newRecord;
            oldReturn = (Return__c)oldRecord;

            if (newReturn.Return_not_Returned_Rationale__c != oldReturn.Return_not_Returned_Rationale__c) {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newReturn.Ticket__c);
                }
                return TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}