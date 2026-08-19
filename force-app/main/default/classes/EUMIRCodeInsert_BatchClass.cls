global class EUMIRCodeInsert_BatchClass implements Database.Batchable <sObject>{
    Id medIdList;
    List<Id> choiceList = new List<Id>();
    public EUMIRCodeInsert_BatchClass(){
        
    }
    public EUMIRCodeInsert_BatchClass( Id medIdList,List<Id> choiceList){
        this.medIdList=medIdList;
        this.choiceList=choiceList;
    }
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query='SELECT Id,MedicalEvaluation__c,MedicalEvaluation__r.Choice1__c FROM CMPL123CME__EU_MIR__c WHERE MedicalEvaluation__c =:medIdList';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<CMPL123CME__EU_MIR__c> records){
        List<CMPL123CME__EU_MIR_Code_Choices__c> cdList= new List<CMPL123CME__EU_MIR_Code_Choices__c>();
        
         for(CMPL123CME__EU_MIR__c euMir : records){
             for(Id eachChoice:choiceList){
                 CMPL123CME__EU_MIR_Code_Choices__c euMircode = new CMPL123CME__EU_MIR_Code_Choices__c();
                euMircode.CMPL123CME__Related_EU_MIR_Code__c=eachChoice;
                euMircode.Name='test';
                euMircode.CMPL123CME__Related_EU_MIR__c=euMir.Id;
                 cdList.add(euMircode);
             //System.assert(false,'cdList=='+cdList.size());
            }
         }
         if(cdList.size()>0){
           insert cdList;
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }

}