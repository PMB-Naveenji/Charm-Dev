/*
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : PTWithTktSearcheBatchLotNumberMDCCustom
* @Why   : Global class to check if Re-Open justification record is created and check if
*          parent ticket is inquiry type and customer replay is required,
*          if yes trigger the MDC and create a MDC ticket.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    24-JAN-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*/
global class ReopenjustWithInquiryTicketsMDCCustom implements CMPL123.IMDCCustomValidation {
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
            Re_Open_Justification__c newReOpenJust = (Re_Open_Justification__c) newRecord;
            Re_Open_Justification__c oldReOpenJust = (Re_Open_Justification__c) oldRecord;

            if (newReOpenJust.Re_Open_Justification_Added__c != oldReOpenJust.Re_Open_Justification_Added__c) {
                if (TicketQDNumMDCCustom.isInquiryTcktforCR == null) {
                    TicketQDNumMDCCustom.setDefaults(newReOpenJust.Complaint__c);
                }
                return TicketQDNumMDCCustom.isInquiryTcktforCR != null && TicketQDNumMDCCustom.isInquiryTcktforCR;
            }
        }
        return null;
    }
}