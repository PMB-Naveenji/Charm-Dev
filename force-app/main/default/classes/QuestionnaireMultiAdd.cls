public class QuestionnaireMultiAdd {
    public List<CMPL123CME__Questionnaire__c> questionnaireList  = new List<CMPL123CME__Questionnaire__c>();
      public List<ID> choiceList  = new List<ID>();
      
    //list of the inner class
    public List<innerClass> lstInner 
    {  get;set;  }
      public Boolean showInputContent {get;set;}
      public Boolean showOutputContent {get;set;}
      
      
    //will indicate the row to be deleted
    public String selectedRowIndex
    {get;set;}  
    
    //no. of rows added/records in the inner class list
    public Integer count = 1;
    //{get;set;}
      public String currentRecordId {get;set;}
      /*Constructor*/
    public QuestionnaireMultiAdd(ApexPages.StandardController ctlr)
    {
       currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
          lstInner = new List<innerClass>();
          innerClass objInnerClass = new innerClass(count);
          lstInner.add(objInnerClass);    
          addMore();
          selectedRowIndex = '0';
          showInputContent=true;
          showOutputContent=false;
  
    }/*End Constructor*/
    
    ////save the records by adding the elements in the inner class list to questionnaireList,return to the same page
    public PageReference Save()
    {
      PageReference pr = new PageReference('/apex/QuestionnaireMultiAdd');
      
      for(Integer j = 0;j<lstInner.size();j++)
      {
        questionnaireList.add(lstInner[j].ques);
      }
        // System.assert(false,'questionnaireList===='+questionnaireList);
          for(CMPL123CME__Questionnaire__c cc :questionnaireList){
              choiceList.add(cc.Choice1__c);
          }
           //System.assert(false,'choiceList===='+choiceList);
           /*CMPL123CME__EU_MIR_Code_Choices__c euMircode = new CMPL123CME__EU_MIR_Code_Choices__c();
                  euMircode.CMPL123CME__Related_EU_MIR_Code__c=questionnaireList[0].Id;
                  euMircode.Medical_Evaluation__c=euMir.MedicalEvaluation__c;
                  euMircode.Name='test';
                  euMircode.CMPL123CME__Related_EU_MIR__c=euMir.Id;*/
        
         //   System.assert(false,'choiceList==='+choiceList);
            
          if(currentRecordId!=null && choiceList.size()>0){
              EUMIRCodeInsert_BatchClass euMirBatch = new EUMIRCodeInsert_BatchClass(currentRecordId,choiceList);
             /* List<CMPL123CME__EU_MIR__c> euMList=[SELECT Id,MedicalEvaluation__c FROM CMPL123CME__EU_MIR__c WHERE MedicalEvaluation__c =:currentRecordId];
             List<CMPL123CME__EU_MIR_Code_Choices__c> cdList= new List<CMPL123CME__EU_MIR_Code_Choices__c>();
          
           for(CMPL123CME__EU_MIR__c euMir : euMList){
               for(Id i:choiceList){
                   CMPL123CME__EU_MIR_Code_Choices__c euMircode = new CMPL123CME__EU_MIR_Code_Choices__c();
                  euMircode.CMPL123CME__Related_EU_MIR_Code__c=i;
                  euMircode.Medical_Evaluation__c=euMir.MedicalEvaluation__c;
                  euMircode.Name='test';
                  euMircode.CMPL123CME__Related_EU_MIR__c=euMir.Id;
                   cdList.add(euMircode);
               //System.assert(false,'cdList=='+cdList.size());
              }
           }
           if(cdList.size()>0){
             insert cdList;
          }
  */
          }
      pr.setRedirect(false);
          showInputContent=false;
          showOutputContent=true;
      return pr;
    }
      
    //add one more row
    public void Add()
    {  
          if(count <= 4){
      count = count+1;
          addMore();  
          }
    }
    
    /*Begin addMore*/
    public void addMore()
    {
      //call to the iner class constructor
      innerClass objInnerClass = new innerClass(count);
      
      //add the record to the inner class list
          lstInner.add(objInnerClass);    
          system.debug('lstInner---->'+lstInner);            
      }/* end addMore*/
    
    /* begin delete */
    public void Del()
    {
      system.debug('selected row index---->'+selectedRowIndex);
      
          if(count != 1){
      count = count - 1;
              //System.assert(false,'selectedRowIndex==='+selectedRowIndex+'lstInner==='+lstInner+'[[[[['+lstInner.size());
              
              System.debug('selectedRowIndex==='+selectedRowIndex+'lstInner==='+lstInner+'[[[[['+lstInner.size());
          lstInner.remove(Integer.valueOf(selectedRowIndex)-1);
              
          }
    }/*End del*/
    
    
    
    
      
  
  
    /*Inner Class*/
    public class innerClass
    {    
      /*recCount acts as a index for a row. This will be helpful to identify the row to be deleted */
      public String recCount
      {get;set;}
      
      
      public CMPL123CME__Questionnaire__c ques 
      {get;set;}
      
      /*Inner Class Constructor*/
      public innerClass(Integer intCount)
      {
        recCount = String.valueOf(intCount);    
        
        /*create a new Questionnaire*/
        ques = new CMPL123CME__Questionnaire__c();
        
      }/*End Inner class Constructor*/  
    }/*End inner Class*/
  }