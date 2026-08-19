/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketService.
* @Why   : This SOAP web service class. this class process the data received from the CMSNext.
* @When  : 23-MAR-2017.
* @Where : From TicketService.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit           Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit           Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class TicketService {
    /*
    * @Method       : createOrUpdateTicket.
    * @Description  : To create Or UpdateTicket.
    * @Invoke       : Events from TriggerHandler before insert.
    * @Return       : N/A.
    * @Params       : TicketServiceWrapper.Ticket Ticket.
    */
    webservice static void createOrUpdateTicket(TicketServiceWrapper.Ticket Ticket) {
        if(Ticket.division != 'AMD' || Ticket.division != 'amd'){
            //Added - W-000268 - Ticket version check
            if(TicketService.validateVersion(Ticket)){
                TicketServiceHandler tcktservchdl = new TicketServiceHandler();
                tcktservchdl.handle(Ticket);

                //W-000195 - Added for creating Product-Lot for System generated Prod Eval - start
                if(String.isNotBlank(Ticket.cmsnextTicketNumber)){
                    ADDInvestigationHandler.createProductLot(Ticket.cmsnextTicketNumber);
                }
                //W-000195 - Added for creating Product-Lot for System generated Prod Eval - End
            }
        }
    }

    /*
    * @Method       : validateVersion.
    * @Description  : W-000268 - Ticket Version is not getting update correctly.
    * @Invoke       : From 'createOrUpdateTicket()' method.
    * @Return       : Boolean.
    * @Params       : TicketServiceWrapper.Ticket Ticket.
    */
    public static Boolean validateVersion(TicketServiceWrapper.Ticket Ticket){
        if([SELECT COUNT() FROM CMPL123CME__Complaint__c WHERE CMSNext_Ticket_Id__c =: Ticket.cmsnextTicketId] > 0){
            CMPL123CME__Complaint__c complaint = [SELECT Id, Ticket_Version__c FROM CMPL123CME__Complaint__c
                                                  WHERE CMSNext_Ticket_Id__c =: Ticket.cmsnextTicketId LIMIT 1];
            if(String.isNotBlank(complaint.Ticket_Version__c)
               && String.isNotBlank(Ticket.ticketVersion)
               && complaint.Ticket_Version__c.replace('.','').isNumeric()
               && Ticket.ticketVersion.replace('.','').isNumeric()
               && Decimal.valueOf(complaint.Ticket_Version__c) > Decimal.valueOf(Ticket.ticketVersion)){
                   return false;
               }
        }else{
            return true;
        }
        return true;
    }

    /*
    * @Method       : validateVersion.
    * @Description  : W-000268 - Ticket Version is not getting update correctly.
    * @Invoke       : From 'createOrUpdateTicket()' method.
    * @Return       : Boolean.
    * @Params       : TicketServiceWrapper.Ticket Ticket.
    */
    public static Boolean validateVersionOptimized(TicketServiceWrapper.Ticket ticket){
        // Extract ticket.ticketVersion
        Decimal ticketVersionFromCMSNext = 0.0;
        if (ticket != null &&
            String.isNotBlank(ticket.ticketVersion) &&
            ticket.ticketVersion.isNumeric()
        ) {
            ticketVersionFromCMSNext = Decimal.valueOf(ticket.ticketVersion);
        } else {
            // Abort early to avoid SOQL
            // Ticket version is valid because there is no "ticketVersion" to compare
            return true;
        }

        // Compare against the unique, existing record
        List<CMPL123CME__Complaint__c> complaintList = [
            SELECT Id, Ticket_Version__c
            FROM CMPL123CME__Complaint__c
            WHERE CMSNext_Ticket_Id__c = :ticket.cmsnextTicketId
            WITH SECURITY_ENFORCED
            LIMIT 1];
        Decimal ticketVersionFromSalesforce = 0.0;
        if (!complaintList.isEmpty()) {
            ticketVersionFromSalesforce = Decimal.valueOf(complaintList[0].Ticket_Version__c);
        }

        return ticketVersionFromSalesforce <= ticketVersionFromCMSNext;
    }
}