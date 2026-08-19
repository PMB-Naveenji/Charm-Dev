/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketpREStatusMDCCustom
* @Why   : Global class to check if ticket pRE flag field is changed to check the
           MDC trigger record creation
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    09-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

global class TicketpREStatusMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : customValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            CMPL123CME__Complaint__c newTicket = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldTicket = (CMPL123CME__Complaint__c) oldRecord;

            if (oldTicket.pRE_Status__c != null && ((newTicket.pRE_Status__c == 'Yes' && oldTicket.pRE_Status__c == 'No') 
                || (newTicket.pRE_Status__c == 'No' && oldTicket.pRE_Status__c == 'Yes'))) {
                if(TicketQDNumMDCCustom.hasMedEval == null){
                    TicketQDNumMDCCustom.setDefaults(newTicket.Id);
                }
                return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
            }
        }
        return false;
    }
}