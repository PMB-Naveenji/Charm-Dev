/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : RelatedProductEvaluationListContTest.
* @Why   : RelatedProductEvaluationListContTest class is test class for RelatedProductEvaluationListController.
* @When  : 25-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 18-OCT-2018         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 21-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                 08-SEP-2020         PMD                               Added assertion into 'afterInsertTicketTest' method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class RelatedProductEvaluationListContTest {

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    //Method to create test data
    @testSetup static void setupData() {
        //Create CMPL123CME__Complaint__c
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(Ticket_Type__c = 'Complaint',Complaint_Quality_Closure_Date__c=system.now(), Overall_Reportable_Status__c='Reportable'), true);

        //Create CMPL123CME__Investigation__c
        CMPL123CME__Investigation__c cmpl123cmeInvestigationRecord = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(Name = 'Test',CMPL123_WF_Status__c = 'Assess',Product_List_Numbers__c = 'Test',Product_Lot_Numbers__c='Test', CMPL123CME__Complaint__c = objComplaint.Id), true);
        //Create Task__c
        Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(Comments__c = 'Test Task Comments', Related_Investigation_Evaluation__c = cmpl123cmeInvestigationRecord.Id) ,true);

        //Create Task_Product_Evaluation_Investigation__c
        Task_Product_Evaluation_Investigation__c objTskProdEvalInvi = (Task_Product_Evaluation_Investigation__c) TestDataFactory.createSObject(new Task_Product_Evaluation_Investigation__c(Task__c = objTask.Id, Investigation_Evaluation__c = cmpl123cmeInvestigationRecord.Id) ,true);

    }

    /*
    * @Method       : setupData.
    * @Description  : Method to cover RelatedProductEvaluationListController class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    //Method to cover RelatedProductEvaluationListController class
    @isTest static void afterInsertTicketTest() {
        ApexPages.CurrentPage().getparameters().put('id', [SELECT Id FROM Task_Product_Evaluation_Investigation__c LIMIT 1].Id);
        RelatedProductEvaluationListController objRelProdEvalLstControl = new RelatedProductEvaluationListController(new ApexPages.StandardController(new Task__c()));
        System.assertEquals(1, [SELECT COUNT() FROM Task__c]);
    }
}