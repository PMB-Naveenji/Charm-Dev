trigger CodeChoiceTrigger on CMPL123CME__EU_MIR_Code_Choices__c (before Update,before insert) {
   
    //system.assert(false,'done');
 List<CMPL123CME__EU_MIR_Code_Choices__c> newchoices = (List<CMPL123CME__EU_MIR_Code_Choices__c>)Trigger.New;
    List<ID> mirs = new List<ID>();
    
    for(CMPL123CME__EU_MIR_Code_Choices__c c:newchoices){
      //c.adderror('done');
    }
    
    
  
}