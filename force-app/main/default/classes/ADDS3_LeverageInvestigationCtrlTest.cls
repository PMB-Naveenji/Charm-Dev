/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3_LeverageInvestigationCtrlTest.
* @Why   : ADDS3_LeverageInvestigationCtrlTest class for the ADDS3_LeverageInvestigationController class.
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
public with sharing class ADDS3_LeverageInvestigationCtrlTest {
    /*
    * @Method       : ADDS3_LeverageInvestigationCtrlTestSetup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    public static void ADDS3_LeverageInvestigationCtrlTestSetup () {
        CMPL123CME__Complaint__c ticket = new CMPL123CME__Complaint__c ();
        ticket.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'CMPL123CME__Complaint__c' AND Name = 'Complaint'][0].Id;
        insert ticket;
        CMPL123CME__Investigation__c investigation = new CMPL123CME__Investigation__c ();
        investigation.CMPL123CME__Complaint__c = ticket.Id;
        insert investigation;
    }

    /*
    * @Method       : testADDS3_LeverageInvestigationController.
    * @Description  : To test the ADDS3_LeverageInvestigationController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testADDS3_LeverageInvestigationController () {
        List<CMPL123CME__Investigation__c> investigations = [SELECT Id, Name FROM CMPL123CME__Investigation__c LIMIT 1];
        PageReference pageRef = Page.ADDS3_LeverageInvestigation;
        Test.setCurrentPage(pageRef);
        Map<String, String> pageRefParameters = pageRef.getParameters();
        pageRefParameters.put('Id', String.valueOf(investigations[0].Id));
        pageRefParameters.put('lksrch', '123Test');
        ADDS3_LeverageInvestigationController liCtrl = new ADDS3_LeverageInvestigationController();
        liCtrl.selectedInvestigationId = investigations[0].Id + '-1';
        liCtrl.search();
        liCtrl.leverageSelectedInvesigation();
        System.assertEquals(0, liCtrl.results.size());
    }

}