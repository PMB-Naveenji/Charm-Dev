global class TicketReviewRecodErrorBatchSchedular implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        TicketReviewRecodErrorBatch obj = new TicketReviewRecodErrorBatch();
        Database.executeBatch(obj);
    }
 }