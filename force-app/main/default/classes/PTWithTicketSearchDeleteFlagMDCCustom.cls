/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : PTDeleteFlagMDCCustom
 * @Why   : Global class to check if Delete Flag field is changed and if parent ticket has prod eval chils records and if yes create the MDC trigger record.
 * @When  : 05-JAN-2021
 * @Where : From Audit Class
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    2-Dec-2019             Defect #1439         Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    15-06-2020             Code Audit           Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
 *                                                                        event instead of after update. Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             27-JAN-2023            CHaRM R3.0, IPDR 411 Replace some hasTicketSearch references with the new hasActiveTicketSearch
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Kishor Kumar             17-May-2023            CHaRM R3.1, Defect IPDR# 189 Removed a Check "isTicketInquiry" for an Inquiry ticket in their ticket reviewreturn 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
global class PTWithTicketSearchDeleteFlagMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
     * @Method       : CustomValidation
     * @Invoke       : From Product-Ticket Change for FA Quality Assignee MDC Trigger
     * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
     * @Return       : Boolean
     * @Params       : Trigger Context
     * @Revision     : 27-JAN-2023 Larry: Replaced hasTicketSearch with 
     * hasActiveTicketSearch for the validation. Defined isDefaultsAssigned to
     * clarify what why hasTicketSearch is being checked against null.
     **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) 
    {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) 
        {
            //TWD Upgrade fix END
            Product_Ticket__c newProductTicket = (Product_Ticket__c) newRecord;
            Product_Ticket__c oldProductTicket = (Product_Ticket__c) oldRecord;

            if (newProductTicket.Delete_Flag__c != oldProductTicket.Delete_Flag__c) 
            {
                Boolean isDefaultsAssigned = TicketQDNumMDCCustom.hasTicketSearch != null;
                if (!isDefaultsAssigned) 
                {
                    TicketQDNumMDCCustom.setDefaults(newProductTicket.Event_Ticket__c);
                    isDefaultsAssigned = true;
                }
                // 27-JAN-2023 Larry: Validation now uses hasActiveTicketSearch and isDefaultsAssigned
                // instead of hasTicketSearch for both
                //return isDefaultsAssigned && TicketQDNumMDCCustom.hasActiveTicketSearch && !TicketQDNumMDCCustom.isTicketInquiry;
                //17-MAY-2023 Kishor:CHarm R3.1, Defect IPDR# 189 "isTicketInquiry" check is removed for an Inquiry ticket in their ticket reviewreturn.
                return isDefaultsAssigned && TicketQDNumMDCCustom.hasActiveTicketSearch;
            }
        }
        return false;
    }
}