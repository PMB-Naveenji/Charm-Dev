/*
Description : Global class to check if "Likely Cause" field is changed in Product Ticket
Created On  : 9th OCT 2018
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit            Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class ProductTicketLikelyCauseMDCCustom implements CMPL123.IMDCCustomValidation{
    /**
    * @Method       : customValidation
    * @Invoke       : Events from CustomValidation
    * @Description  : To Custom Validation
    * @Return       : N/A
    * @Params       : N/A
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord){
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TicketUtil.addTrace('PTWithMedEvalLikelyCauseMDCCustom');
            //TWD Upgrade fix END
            Product_Ticket__c newProductTicket = (Product_Ticket__c) newRecord;
            Product_Ticket__c oldProductTicket = (Product_Ticket__c) oldRecord;

            if(newProductTicket.Likely_Cause__c != null && oldProductTicket.Likely_Cause__c != null
               && newProductTicket.Likely_Cause__c != oldProductTicket.Likely_Cause__c) {
                TicketQDNumMDCCustom.setDefaults(newProductTicket.Event_Ticket__c);
                return TicketQDNumMDCCustom.inquiryTT != null && TicketQDNumMDCCustom.inquiryTT;
            }
        }
        return false;
    }
}