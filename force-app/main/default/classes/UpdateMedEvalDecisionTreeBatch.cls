/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateMedEvalDecisionTreeBatch.
* @Why   : Global class, used for updating the value of workflow status of Regulatory or Closed-Done
*           to In-Process Evaluation Status and create Field action decision tree.
* @When  : 15-NOV-2018.
* @Where : From ADDS5TicketSearchResultController class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    15-NOV-2018            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class UpdateMedEvalDecisionTreeBatch implements Database.Batchable<CMPL123CME__Questionnaire__c>,Database.Stateful{
    //To store the List of MedEval Ids
    private List< CMPL123CME__Questionnaire__c > assessmentToUpdate = new List< CMPL123CME__Questionnaire__c >();

    /*
    * @Method       : UpdateMedEvalDecisionTreeBatch.
    * @Description  : Constructor.
    * @Invoke       : From ADDS5TicketSearchResultController Class.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__Questionnaire__c> setMedIds.
    */
    public UpdateMedEvalDecisionTreeBatch(List<CMPL123CME__Questionnaire__c> setMedIds) {
        this.assessmentToUpdate = !Test.isRunningTest() ?  setMedIds : new List< CMPL123CME__Questionnaire__c >{setMedIds[0]} ;
    }

    /*
    * @Method       : start.
    * @Description  : Get MedEval records.
    * @Invoke       : From UpdateMedEvalDecisionTreeBatch class.
    * @Return       : Iterable<CMPL123CME__Questionnaire__c>.
    * @Params       : Database.BatchableContext BC.
    */
    global Iterable<CMPL123CME__Questionnaire__c> start(Database.BatchableContext BC){
        return assessmentToUpdate;
    }

    /*
    * @Method       : execute.
    * @Description  : Get MedEval records.
    * @Invoke       : From UpdateMedEvalDecisionTreeBatch class.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<CMPL123CME__Questionnaire__c> lstScope.
    */
    global void execute(Database.BatchableContext BC, List<CMPL123CME__Questionnaire__c > lstScope){
        UPDATE lstScope;
    }

    /*
    * @Method       : finish.
    * @Description  : finish process.
    * @Invoke       : From UpdateMedEvalDecisionTreeBatch Class.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext BC) {
    }
}