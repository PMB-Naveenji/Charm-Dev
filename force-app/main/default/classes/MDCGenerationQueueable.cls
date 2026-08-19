public class MDCGenerationQueueable implements Queueable {
    
    private String objectName;
    private Map <Id, SObject> recordsMap;
    
    public MDCGenerationQueueable(String objectName, Map <Id, SObject> recordsMap) {
        
        this.objectName = objectName;
        this.recordsMap = recordsMap;
    }
    
    public void execute(QueueableContext qc) {
        Set<Id> ticketIds = new Set<Id>();
        if(objectName == 'Meaningful_Data__c') {
            for(Meaningful_Data__c md : (List<Meaningful_Data__c>)(recordsMap.values())){ 
                if(md.Compliant__c != null){ 
                    ticketIds.add(md.Compliant__c); 
                }
            }
            Map<Id, CMPL123CME__Complaint__c> ticketMap = new Map<Id, CMPL123CME__Complaint__c>( [SELECT Id, CreatedDate FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIds]);
            Integer minutesToAdd = Integer.valueOf(Label.MDC_Generation_Prevention_Minutes);
            List<Meaningful_Data__c> meaningfulDataRecords = new List<Meaningful_Data__c>();
            for(Meaningful_Data__c md : (List<Meaningful_Data__c>)(recordsMap.values())){
                CMPL123CME__Complaint__c ticket = ticketMap.get(md.Compliant__c);
                if(ticket == null){
                    continue;
                }
                Datetime windowEndTime = ticket.CreatedDate.addMinutes(minutesToAdd);
                //if(System.now() > windowEndTime){
                    meaningfulDataRecords.add(md);
               //}
            }
            if(meaningfulDataRecords.size() > 0){
                createMDCTicket(meaningfulDataRecords);
            }
        }
    }
    
    public void createMDCTicket(List<Meaningful_Data__c> meaningfulDataRecords) {
        
        Map <Id, Meaningful_Data__c> meaningfulDataMatchCondition = new Map <Id, Meaningful_Data__c>();
        Map <Id, Meaningful_Data__c> meaningfulDataMatchConditionMedEval = new Map <Id, Meaningful_Data__c>();
        Set <Id> ticketIds = new Set <Id>();
        for (Meaningful_Data__c meaningfulData: meaningfulDataRecords) {
            ticketIds.add(meaningfulData.Compliant__c);
        }
        
        // refactor
        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);
        for (Meaningful_Data__c meaningfulData: meaningfulDataRecords) {
            if (meaningfulData.Meaningful_Data_Answers__c  != null) {
                Map<String, Boolean> boolMap = ticketMap.get(meaningfulData.Compliant__c); 
                //@Juneid @12 FEB , 2021, Using MDCTicketUtil Static Variable
                if (boolMap.get('hasProdEval')) { 
                    meaningfulDataMatchCondition.put(meaningfulData.Id, meaningfulData);
                } //@Juneid @12 FEB , 2021, Using MDCTicketUtil Static Variable
                if (boolMap.get('hasMedEval')) {
                    meaningfulDataMatchConditionMedEval.put(meaningfulData.Id, meaningfulData);
                }                    
            }
        }
        
        if (meaningfulDataMatchCondition.size() > 0) {
            MDCTicketUtil.createMDC('Meaningful Data Change for Evaluator/Investigator', meaningfulDataMatchCondition, 'Compliant__c', 'Ticket_Number__c', 'meaningful_data_answers__c', TRUE);
        }
        if (meaningfulDataMatchConditionMedEval.size() > 0) {
            MDCTicketUtil.createMDC('Meaningful Data Change for med evaluator', meaningfulDataMatchConditionMedEval, 'Compliant__c', 'Ticket_Number__c', 'meaningful_data_answers__c', TRUE);
        }
    }
    
}