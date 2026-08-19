/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketSearchesMDCLogic
* @Why   : Global class to check if Ticket Search record Ticket Review Status is changed, and if yes then 
create the MDC trigger for that change
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    19-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketSearchesMDCLogic implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : customValidation
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @PARAM oldRecord prior version of the record
    * @PARAM newRecord new version of the record
    **/ 
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            Ticket_Search_Result__c newTicketSearch, oldTicketSearch;
            newTicketSearch = (Ticket_Search_Result__c) newRecord;
            oldTicketSearch = (Ticket_Search_Result__c) oldRecord;

            Ticket_Review__c parentTicketReviews = [
                SELECT Id, Search_Frequency__c
                FROM Ticket_Review__c
                WHERE Id = :newTicketSearch.Ticket_Review__c
            ];
            Boolean isRelatedwithMalfunctionChanged = false;
            if (newTicketSearch.Ticket_Review_Status__c != oldTicketSearch.Ticket_Review_Status__c 
                && (newTicketSearch.Ticket_Review_Status__c == 'Related with Malfunction'
                || oldTicketSearch.Ticket_Review_Status__c == 'Related with Malfunction') 
                && parentTicketReviews.Search_Frequency__c == 'Two Weeks (14 days)') {
                isRelatedwithMalfunctionChanged = true;
            }
            if (TicketQDNumMDCCustom.hasMedEval == null) {
                TicketQDNumMDCCustom.setDefaults(newTicketSearch.Ticket__c);
            }
            if (isRelatedwithMalfunctionChanged) {
                return TicketSearchResultsReviewController.isRelatedwithMalfunction 
                        || (TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval);
            }
        }
        return false;
    }
}