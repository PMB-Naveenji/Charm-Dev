global class EUMIRCodeInsert_BatchSchedule implements Schedulable{
    global void execute(SchedulableContext sc){
        EUMIRCodeInsert_BatchClass euBatch = new EUMIRCodeInsert_BatchClass();
        Database.executeBatch(euBatch,200);
       
    }
}