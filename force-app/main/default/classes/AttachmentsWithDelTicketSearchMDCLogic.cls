/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : AttachmentsWithDelTicketSearchMDCLogic
 * @Why   : Global class to check if Attachment whose parent ticket has TicketSearch records
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
 *                                                   event instead of after update. Commented unnecessary logging. Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             30-JAN-2023            CHaRM R3.0, IPDR 411 Replace some hasTicketSearch references with the new hasActiveTicketSearch
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
global class AttachmentsWithDelTicketSearchMDCLogic implements CMPL123.IMDCCustomValidation {
    /**
     * @Method       : CustomValidation
     * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
     * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
     * @Return       : Boolean
     * @Params       : Trigger Context
     * @Revision     : 30-JAN-2023 Larry: Replaced hasTicketSearch with 
     * hasActiveTicketSearch for the validation. Defined isDefaultsAssigned to
     * clarify what why hasTicketSearch is being checked against null.
     **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TicketUtil.addTrace('AttachmentsWithDelTicketSearchMDCLogic');
            //TWD Upgrade fix END
            Attachment__c newAttachment = (Attachment__c) newRecord;
            Attachment__c oldAttachment = (Attachment__c) oldRecord;
            if (newAttachment != null &&
                newAttachment.Deletion_Justification__c != null &&
                oldAttachment.Deletion_Justification__c != newAttachment.Deletion_Justification__c)
            {
                Boolean isDefaultsAssigned = TicketQDNumMDCCustom.hasTicketSearch != null;
                if (!isDefaultsAssigned) {
                    TicketQDNumMDCCustom.setDefaults(newAttachment.Ticket__c);
                    isDefaultsAssigned = true;
                }
                // 30-JAN-2023 Larry: Validation now uses hasActiveTicketSearch and isDefaultsAssigned
                // instead of hasTicketSearch for both
                Boolean hasActiveTicketSearch = TicketQDNumMDCCustom.hasActiveTicketSearch;
                Boolean isTicketInquiry = TicketQDNumMDCCustom.isTicketInquiry;
                return isDefaultsAssigned && hasActiveTicketSearch && !isTicketInquiry;
            }
        }
        return false;
    }
}