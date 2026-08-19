/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketProductChangeFAQMDCCustom
* @Why   : 
* @When  : 24-JUN-2026
* @Where : 
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      	Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*	Complaint COE			 24-JUN-2026			CHaRM R9.0/IPDR-841		This class handles MDC creation for the FA Quality Assignee group. 
*																			It generates MDCs for all ticket types when associated active 
*																			ticket review child records are present.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketProductChangeFAQMDCCustom implements CMPL123.IMDCCustomValidation{
    
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldComplaint = (CMPL123CME__Complaint__c) oldRecord;
            if (newComplaint.Product_Ticket_Added__c != oldComplaint.Product_Ticket_Added__c && oldComplaint.Product_Ticket_Added__c != null) { 
                system.debug('TicketQDNumMDCCustom.hasTicketSearch---->'+TicketQDNumMDCCustom.hasTicketSearch);
                
                Boolean isDefaultsAssigned = TicketQDNumMDCCustom.hasTicketSearch != null;
                system.debug('isDefaultsAssigned---->'+isDefaultsAssigned);
                if (!isDefaultsAssigned){
                    TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
                    isDefaultsAssigned = true;
                }
                system.debug('TicketQDNumMDCCustom.hasActiveTicketSearch---->'+TicketQDNumMDCCustom.hasActiveTicketSearch);
                return isDefaultsAssigned && TicketQDNumMDCCustom.hasActiveTicketSearch;
            }
        }
        return false;
    }
}