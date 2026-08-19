/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : AttachmnetsDeletionWithQNCMDCLogic
* @Why   : 
* @When  : 04-JAN-2021
* @Where : From Audit Class 
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    26-Mar-2019            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Commented unnecessary logging.
*                                                                        Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Charm COE                03-JUN-2026            CHaRM R9.0/IPDR-165  Updated CustomValidation() to generate an MDC ticket for the Quality Non-Complaint group
* 												   					 	 only when a Customer Response child record exists for the Inquiry ticket.				
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class AttachmnetsDeletionWithQNCMDCLogic implements CMPL123.IMDCCustomValidation {
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
            //TicketUtil.addTrace('AttachmnetsDeletionWithQNCMDCLogic');
            //TWD Upgrade fix END
            Attachment__c newAttachment = (Attachment__c) newRecord;
            Attachment__c oldAttachment = (Attachment__c) oldRecord;
            
            if (newAttachment != null) {                                
                if (newAttachment.Deletion_Justification__c != null && oldAttachment.Deletion_Justification__c != newAttachment.Deletion_Justification__c) { 
                    TicketQDNumMDCCustom.setDefaults(newAttachment.Ticket__c);  
                    // CHARM R9.0/IPDR-165 - MDC creation is allowed only for Inquiry tickets with a Customer Response.
                    return TicketQDNumMDCCustom.isInquiryTcktforCR;
                }
            }
        }    
        return false;
    }
}