public class SkipMDCGeneration {
    
    public static void skipMDC(List<Ticket_Note__c> ticNoteLst){
        Map<Id, Ticket_Note__c> ticketNoteMap = new Map<Id, Ticket_Note__c>();
        for(Ticket_Note__c tic : ticNoteLst){
            ticketNoteMap.put(tic.Id, tic);
        }        
        ADD_App_Settings__c addApp = ADD_App_Settings__c.getInstance();
        if (addApp != null && addApp.Enable_MDC_Prevention_Logic__c) {
            ADDTicketNoteTriggerhandler.createMDCTicket_TicketNote(ticketNoteMap);
            return;
        }
        Set<Id> ticketIds = new Set<Id>();
        for (Ticket_Note__c ticketNote : ticNoteLst) {
            if (ticketNote.Ticket__c != null) {
                ticketIds.add(ticketNote.Ticket__c);
            }
        }
        if (!ticketIds.isEmpty()) {
            Map<Id, CMPL123CME__Complaint__c> ticketMap =
                new Map<Id, CMPL123CME__Complaint__c>(
                    [SELECT Id, CreatedDate FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIds] );
            Map<Id,Ticket_Note__c> filteredTicketNoteMap = new Map<Id,Ticket_Note__c>();
            for (Ticket_Note__c ticketNote : ticNoteLst) {
                CMPL123CME__Complaint__c ticket = ticketMap.get(ticketNote.Ticket__c);
                Integer minutesToAdd = Integer.valueOf(addApp.MDC_Generation_Prevention_Minutes__c);//Integer.valueOf(Label.MDC_Generation_Prevention_Minutes);
                if (System.now() > ticket.CreatedDate.addMinutes(minutesToAdd)) {
                    filteredTicketNoteMap.put(ticketNote.Id, ticketNote);
                }
            }
            if(!filteredTicketNoteMap.isEmpty()){
                ADDTicketNoteTriggerhandler.createMDCTicket_TicketNote(filteredTicketNoteMap);
            }
        }
    }
    
}