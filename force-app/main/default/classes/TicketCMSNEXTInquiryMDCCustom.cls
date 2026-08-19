/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TranslationTaskWithTckMedEvalMDCCustom
* @Why   :  Global class to check if "CMSNext" field is changed check MDC Ticket record creation.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    13-NOV-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketCMSNEXTInquiryMDCCustom implements CMPL123.IMDCCustomValidation{
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
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldComplaint = (CMPL123CME__Complaint__c) oldRecord;

            //Added : W-000150
            TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
            system.debug('TicketQDNumMDCCustom.inquiryTT>>'+TicketQDNumMDCCustom.inquiryTT+'\n'+' Follow_up_Status__c>> '+newComplaint.Follow_up_Status__c+'\n'+'newComplaint.CMSNext__c and  oldComplaint.CMSNext__c>>>>'+newComplaint.CMSNext__c == 'Open' && oldComplaint.CMSNext__c == 'Closed');
            return TicketQDNumMDCCustom.inquiryTT == true
                    && newComplaint.Follow_up_Status__c != null
                    && ((newComplaint.CMSNext__c == 'Open' && oldComplaint.CMSNext__c == 'Closed')
                    || (newComplaint.Reopen_Rationale__c != oldComplaint.Reopen_Rationale__c));
        }
        return false;
       
    }
}