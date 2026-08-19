/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3LeverageTaskControllerTest.
* @Why   : ADDS3LeverageTaskControllerTest class for the ADDS3LeverageTaskController class.
* @When  : 28-MAY-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                28-MAY-2020           Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                12-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class ADDS3LeverageTaskControllerTest {
    /*
    * @Method       : ADDS3LeverageTaskControllerTestSetup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    public static void ADDS3LeverageTaskControllerTestSetup () {
        CMPL123CME__Complaint__c ticket = new CMPL123CME__Complaint__c ();
        ticket.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'CMPL123CME__Complaint__c' AND Name = 'Complaint'][0].Id;
        insert ticket;
        CMPL123CME__Investigation__c investigation = new CMPL123CME__Investigation__c ();
        investigation.CMPL123CME__Complaint__c = ticket.Id;
        insert investigation;
        Task__c task = new Task__c ();
        task.Related_Investigation_Evaluation__c = investigation.Id;
        insert task;
    }

    /*
    * @Method       : testADDS3LeverageTaskController.
    * @Description  : To test the ADDS3LeverageTaskController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testADDS3LeverageTaskController () {
        Task__c task = [SELECT Id, Name FROM Task__c LIMIT 1][0];
        PageReference pageRef = Page.ADDS3LeverageTask;
        Test.setCurrentPage(pageRef);
        Map<String, String> pageRefParameters = pageRef.getParameters();
        pageRefParameters.put('Id', String.valueOf(task.Id));
        pageRefParameters.put('lksrch', '123Test');
        ADDS3LeverageTaskController ltCtrl = new ADDS3LeverageTaskController();
        ltCtrl.selectedTaskId = task.Id + '-1';
        ltCtrl.search();
        ltCtrl.leverageSelectedTask();
        System.assertEquals(0, ltCtrl.results.size());
    }

}