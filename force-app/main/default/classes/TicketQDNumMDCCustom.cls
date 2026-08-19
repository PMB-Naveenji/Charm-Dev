/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : TicketQDNumMDCCustom
 * @Why   : Global class to check if ticket QD Number field is changed to check the
            MDC trigger record creation.
 * @When  : 05-JAN-2021
 * @Where : From Audit Class
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Admin                    09-Jan-2017            Work ID / Case ID    Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    15-06-2020             Code Audit           Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oivan                    23-Jun-2020            #136 (CHARM-2759)    Modified. Added logic to check Complaint Ticket.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
 *                                                                        event instead of after update. Commented unnecessary logging.
 *                                                                        Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             24-JAN-2023            CHaRM R3.0, IPDR 411 Added hasActiveTicketSearch for other IMDCCustomValidation subclasses.
 * Replaced all magic words with constants.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
global class TicketQDNumMDCCustom implements CMPL123.IMDCCustomValidation 
{
    /**
    * @Method       : customValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    public static Boolean hasMedEval;
    public static Boolean hasTicketSearch;
    // 12-JAN-2023 Larry: Added this flag
    public static Boolean hasActiveTicketSearch;
    public static Boolean hasProdEval;
    public static Boolean isInquiryTcktforCR;
    public static Boolean isNewTranslationTask;
    public static Boolean isInprocessTranslationTask;
    public static Boolean inquiryTT;
    //Added :  W-000326
    public static Boolean isTicketServiceType;
    //Added : W-000189
    public static Boolean isTicketOverallReportable;
    public static Boolean isTicketInquiry;
    public static Id prevTicketId = null;
    //Added: #136 (CHARM-2759) to check if ticket recordType is Complaint
    public static Boolean isComplaintTicket;

    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            CMPL123CME__Complaint__c newTicket = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldTicket = (CMPL123CME__Complaint__c) oldRecord;

            if (newTicket.Quality_Directive_Number__c != oldTicket.Quality_Directive_Number__c) {
                if (hasMedEval == null) {
                    setDefaults(newTicket.Id);
                }
                return hasMedEval != null && hasMedEval;
            }
        }
        return false;
    }

    /**
     * Initializes static variables in this class with data related to the passed Ticket.
     * @param recordId Any Ticket (aka Complaint) Id.
     * @revision 12-JAN-2023 Larry: Added this docstring. Moved some logic to MDCTicketUtil.
     * Made hasActiveTicketSearch.
     */
    public static void setDefaults (Id recordId) 
    {      system.debug('startinginquiryTT>>'+inquiryTT); 
        if(recordId != null && (prevTicketId == null || prevTicketId != recordId)) {
            // 31-JAN-2023 Larry: Moved shared logic to MDCTicketUtil
            CMPL123CME__Complaint__c ticketWithChilds =
                MDCTicketUtil.queryTicketsAndNonVoidChildren(new Set<Id>{recordId})[0]; 
            system.debug('ticketWithChilds>>'+ticketWithChilds.Customer_Reply_Required__c);
            Map<String, Boolean> flagNameToVal =
                MDCTicketUtil.getFlagMapForTicket(ticketWithChilds);
             system.debug('flagNameToVal==>'+flagNameToVal);//Kishor
            //#136 (CHARM-2759) start. Check if ticket is complaint.
            isComplaintTicket = ticketWithChilds.Ticket_Type__c == AspenConstants.STR_Complaint;
            //#136 (CHARM-2759) end
            // 30-JAN-2023 Larry: The five flags below are now calculated from MDCTicketUtil
            isTicketInquiry =       flagNameToVal.get(AspenConstants.TICKETFLAG_IS_INQUIRY);
            hasProdEval =           flagNameToVal.get(AspenConstants.TICKETFLAG_HAS_PRODEVAL); //hasProdEval
            hasMedEval =            flagNameToVal.get(AspenConstants.TICKETFLAG_HAS_MEDEVAL);
            hasTicketSearch =       flagNameToVal.get(AspenConstants.TICKETFLAG_HAS_TICKET_SEARCH); //hasTicketSearch
            hasActiveTicketSearch = flagNameToVal.get(AspenConstants.TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH);
            inquiryTT = ticketWithChilds.Ticket_Type__c == AspenConstants.STR_Inquiry &&
                ticketWithChilds.Customer_Reply_Required__c; 
            system.debug('inquiryTT>>'+inquiryTT);
            List<CMPL123CME__Investigation__c> childProdEvalsList = ticketWithChilds.CMPL123CME__Investigations__r;
            if(childProdEvalsList.size() > 0){
                for(CMPL123CME__Investigation__c prodEval : childProdEvalsList){
                    isNewTranslationTask = ticketWithChilds.Ticket_Type__c == AspenConstants.STR_Complaint &&
                        prodEval.CMPL123_WF_Status__c == AspenConstants.STR_Assess;
                    isInprocessTranslationTask = (ticketWithChilds.Ticket_Type__c == AspenConstants.STR_Complaint &&
                                                    prodEval.CMPL123_WF_Status__c != AspenConstants.STR_Assess);
                }
            }
            isInquiryTcktforCR = ticketWithChilds.Ticket_Type__c  == AspenConstants.STR_Inquiry &&
                ticketWithChilds.Is_Custom_response_child_created__c;            
            //Added :  W-000326
            isTicketServiceType = ticketWithChilds.Ticket_Type__c == AspenConstants.STR_Service;
            //Added : W-000189
            isTicketOverallReportable = ticketWithChilds.Overall_Reportable_Status__c == AspenConstants.STR_Reportable;
            prevTicketId = recordId;
            
        }
    }
}