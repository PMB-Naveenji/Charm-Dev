/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketProductChangeMDCCustom
* @Why   :  Global class to check if "CMSNext" field is changed check MDC
Ticket record creation.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    13-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Kishor Kumar             02-June-2023            CHaRM R3.1, Defect IPDR# 187 Replace some hasTicketSearch references with the new hasActiveTicketSearch
*	-------------------------------------------------------------------------------------------------------------------------------------
*	Charm COE				 19-JUN-2026			 CHaRM R9/IPDR 841	 Updated "CustomValidation" method to generate MDC for 
*													 					 Quality Non Complaint group for Inquiry ticket type when Customer Reply Required is true.			
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketProductChangeMDCCustom implements CMPL123.IMDCCustomValidation{
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
            Integer likelyCauseNewCount = newComplaint.Product_Ticket_Added__c != null ? newComplaint.Product_Ticket_Added__c.countMatches('Likely Cause') : 0;
            Integer likelyCauseOldCount = oldComplaint.Product_Ticket_Added__c != null ? oldComplaint.Product_Ticket_Added__c.countMatches('Likely Cause') : 0;
            //Added : W-000150
            //CHaRM R9.0/IPDR-841 - Updated if condition by adding Product Ticket Added not equal to null check for oldComplaint.
            if (newComplaint.Product_Ticket_Added__c != oldComplaint.Product_Ticket_Added__c && oldComplaint.Product_Ticket_Added__c != null) { 
                //CHaRM R9.0/IPDR-841 - Added inquiryTT which checks if ticket type equals Inquiry and Customer Reply Required equals true.
                Boolean isDefaultsAssigned = TicketQDNumMDCCustom.inquiryTT != null; // TicketQDNumMDCCustom.hasTicketSearch != null; 
                if (!isDefaultsAssigned) {
                    TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
                    isDefaultsAssigned = true;
                }
                //CHaRM R9.0/IPDR-841 - Updated AND condition with inquiryTT check.
                return isDefaultsAssigned && TicketQDNumMDCCustom.inquiryTT;
            }
        }
        return false;
    }
}