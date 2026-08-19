/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3OverrideSourceTicketCtrlTest.
* @Why   : ADDS3OverrideSourceTicketCtrlTest class for the ADDS3OverrideSourceTicketController class.
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
* oivan                07-SEP-2020           PMD report fixes          Added System.assert's.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class ADDS3OverrideSourceTicketCtrlTest {
    /*
    * @Method       : ADDS3OverrideSourceTicketCtrlTestSetup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static public void ADDS3OverrideSourceTicketCtrlTestSetup () {
        CMPL123CME__Complaint__c ticket = new CMPL123CME__Complaint__c ();
        ticket.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'CMPL123CME__Complaint__c' AND Name = 'Complaint'][0].Id;
        insert ticket;
        CMPL123CME__Investigation__c investigation = new CMPL123CME__Investigation__c ();
        investigation.CMPL123CME__Complaint__c = ticket.Id;
        insert investigation;
        Task__c task = new Task__c ();
        task.Related_Investigation_Evaluation__c = investigation.Id;
        insert task;
        Task_Product_Evaluation_Investigation__c taskPEIJunction = new Task_Product_Evaluation_Investigation__c ();
        taskPEIJunction.Task__c = task.Id;
        taskPEIJunction.Investigation_Evaluation__c = investigation.Id;
        insert taskPEIJunction;
        Ticket_Product_Evaluation_Investigation__c ticketPEIJunction = new Ticket_Product_Evaluation_Investigation__c ();
        ticketPEIJunction.Ticket__c = ticket.Id;
        ticketPEIJunction.Investigation_Evaluation__c = investigation.Id;
        insert ticketPEIJunction;
    }

    /*
    * @Method       : testADDS3OverrideSourceTicketContoller.
    * @Description  : To test the ADDS3OverrideSourceTicketController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testADDS3OverrideSourceTicketContoller () {
        CMPL123CME__Complaint__c ticket = [SELECT Id, Name FROM CMPL123CME__Complaint__c LIMIT 1][0];
        Ticket_Product_Evaluation_Investigation__c junction = [SELECT Id, Name FROM Ticket_Product_Evaluation_Investigation__c][0];
        PageReference pageRef = Page.ADDS3OverrideSourceTicket;
        Test.setCurrentPage(pageRef);
        Map<String, String> pageRefParameters = pageRef.getParameters();
        pageRefParameters.put('ids', String.valueOf(junction.Id + ','));
        pageRefParameters.put('lksrch', '123Test');
        pageRefParameters.put('ticketId', String.valueOf(ticket.Id));
        ADDS3OverrideSourceTicketContoller ostCtrl = new ADDS3OverrideSourceTicketContoller();
        ostCtrl.search();
         //PMD report fix for System assert start.
        System.assertEquals(0, ostCtrl.results.size(), '123Test Ticket doesn\'t exist');
        //PMD report fix for System assert end.
        ostCtrl.overrideTicket();
    }

}