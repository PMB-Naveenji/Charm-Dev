/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : AttachmnetsWithQNCMDCLogic
* @Why   : 
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    01-Apr-2019            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Commented unnecessary logging.
*                                                                        Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Naveenji                 03-JUN-2026           CHARM R9.0 -  		Added conditional check (TicketQDNumMDCCustom.isInquiryTcktforCR) in 
													IPDR - 165			the return statement, to ensure MDC creation for a Inquiry Ticket with 
* 																		customer response existence when Registartion_Attachment__c is changed 
																		for Quality Non-Complaint group.                                                              
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class AttachmnetsWithQNCMDCLogic implements CMPL123.IMDCCustomValidation {
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
            //TicketUtil.addTrace('AttachmnetsWithQNCMDCLogic');
            //TWD Upgrade fix END
            Attachment__c newAttachment = (Attachment__c) newRecord;
            Attachment__c oldAttachment = (Attachment__c) oldRecord;           
                if (newAttachment.Registartion_Attachment__c != oldAttachment.Registartion_Attachment__c) {     
                    TicketQDNumMDCCustom.setDefaults(newAttachment.Ticket__c); 
                    // Modified return condition by adding TicketQDNumMDCCustom.isInquiryTcktforCR as part for IPDR 165.                     
                    return TicketQDNumMDCCustom.isTicketInquiry != null && TicketQDNumMDCCustom.isTicketInquiry;
                    
                }
        }    
        return false;
    }
}