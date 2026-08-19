/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TranslationTaskWithTckMedEvalMDCCustom
* @Why   : Global class to check if "Customer Expectation"
*          field is changed in Customer Response .
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    9-OTC-2018             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Commented unnecessary logging.
*                                                                        Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class CustomerResponseCustExpectMDCCustom implements CMPL123.IMDCCustomValidation{
    /**
    * @Method       : CustomValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TicketUtil.addTrace('CustomerResponseCustExpectMDCCustom');
            //TWD Upgrade fix END
            Customer_Response__c oldCustResponse = (Customer_Response__c) oldRecord;
            Customer_Response__c newCustResponse = (Customer_Response__c) newRecord;

            if((newCustResponse.Customer_Expectation__c != oldCustResponse.Customer_Expectation__c)
                || (newCustResponse.Additional_Reply_Expectation__c != oldCustResponse.Additional_Reply_Expectation__c)) {
                TicketQDNumMDCCustom.setDefaults(newCustResponse.Event__c);
                return TicketQDNumMDCCustom.inquiryTT != null && TicketQDNumMDCCustom.inquiryTT;
            }
        }
        return false;
    }
}