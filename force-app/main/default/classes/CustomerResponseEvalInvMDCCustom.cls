/**
*  --------------------------------------------------------------------------------------------------------------------------------------
*  @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
*  @What  : CustomerResponseEvalInvMDCCustom
*  @Why   : Global class to check if Customer Expectation or Additional_Reply_Expectation field is changed in Customer Response .
*  @When  : 04-JAN-2021
*  @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    27-MAY-2020            #136 (CHARM-2759)     Created. Added logic to check change on needed condition.
*                                                   MDC not created for
*                                                   Evaluator/Investigator
*                                                   group
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    08-JUL-2020            Code Audit           Added 'Copyright' to header comment.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Commented unnecessary logging.
*                                                                        Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class CustomerResponseEvalInvMDCCustom implements CMPL123.IMDCCustomValidation{
    /**
    * @Method       : CustomValidation
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            //TicketUtil.addTrace('CustomerResponseEvalInvMDCCustom');
            Customer_Response__c oldCustResponse = (Customer_Response__c) oldRecord;
            Customer_Response__c newCustResponse = (Customer_Response__c) newRecord;

            if (newCustResponse.Customer_Expectation__c != oldCustResponse.Customer_Expectation__c) {
                TicketQDNumMDCCustom.setDefaults(newCustResponse.Event__c);
                return TicketQDNumMDCCustom.isComplaintTicket != null && TicketQDNumMDCCustom.isComplaintTicket;
            }
        }
        return false;
    }
}