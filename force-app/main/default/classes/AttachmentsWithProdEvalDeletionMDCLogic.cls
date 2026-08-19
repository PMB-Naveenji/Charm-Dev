/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : AttachmentsWithProdEvalDeletionMDCLogic
* @Why   : Global class to check if Attachment whose parent ticket has prod evaluation/investigation records
           record is changed, and if yes then create the MDC trigger for that change.
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
**/
global class AttachmentsWithProdEvalDeletionMDCLogic implements CMPL123.IMDCCustomValidation {
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
            //TicketUtil.addTrace('AttachmentsWithProdEvalDeletionMDCLogic');
            //TWD Upgrade fix END
            Attachment__c newAttachment = (Attachment__c) newRecord;
            Attachment__c oldAttachment = (Attachment__c) oldRecord;

            if (newAttachment != null) {
                if (newAttachment.Deletion_Justification__c != null && oldAttachment.Deletion_Justification__c != newAttachment.Deletion_Justification__c) {
                    if (TicketQDNumMDCCustom.hasProdEval == null) {
                        TicketQDNumMDCCustom.setDefaults(newAttachment.Ticket__c);
                    }
                    return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval && TicketQDNumMDCCustom.isTicketInquiry == false;
                }
            }
        }
        return false;
    }
}