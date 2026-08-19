/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketAdhocMedicalEvaluatorMDCCustom
* @Why   : Global class to check if "Was an adverse event identified?" field is changed in ticket and
*          has prodEval record to check MDC Ticket record creation
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
*   Charm COE                02-JUN-2026            CHaRM R9.0/IPDR-96   Added condition to prevent MDC Creation when  
*                                                                        Was_an_Adverse_Event_Identified__c field Change from Null to No.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketAdvEventIdentifyMDCCustom implements CMPL123.IMDCCustomValidation {
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
            CMPL123CME__Complaint__c newTicket = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldTicket = (CMPL123CME__Complaint__c) oldRecord;
            
            
            // CHaRM R9.0/IPDR-96 --> Prevent MDC creation when Was_an_Adverse_Event_Identified__c changes from null to 'No'.
            if (newTicket.Was_an_Adverse_Event_Identified__c != oldTicket.Was_an_Adverse_Event_Identified__c && !(oldTicket.Was_an_Adverse_Event_Identified__c == null  && newTicket.Was_an_Adverse_Event_Identified__c == 'No')) {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newTicket.Id);
                }
                system.debug('TicketQDNumMDCCustom.hasProdEvaltestv2>>>'+TicketQDNumMDCCustom.hasProdEval);
                return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}