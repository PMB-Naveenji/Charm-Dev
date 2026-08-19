/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3_InvestigationCustomRLControllerTest.
* @Why   : ADDS3_InvestigationCustomRLControllerTest class for the ADDS3_InvestigationCustomRLController class.
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
public class ADDS3_InvestigationCustomRLCtrlTest {
    /*
    * @Method       : ADDS3_InvestigationCustomRLControllerTest.
    * @Description  : To test the ADDS3_InvestigationCustomRLController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void ADDS3_InvestigationCustomRLControllerTest () {

        CMPL123CME__Complaint__c ticket = new CMPL123CME__Complaint__c ();
        ticket.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'CMPL123CME__Complaint__c' AND Name = 'Complaint'][0].Id;
        insert ticket;

        PageReference pageRef = Page.ADDS3_InvestigationCustomRelatedList;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(ticket.Id));

        ApexPages.StandardController ticketStandardController = new ApexPages.StandardController(ticket);
        ADDS3_InvestigationCustomRLController investigationCustomRLCtrl = new ADDS3_InvestigationCustomRLController(ticketStandardController);

        Ticket_Product_Evaluation_Investigation__c tpei = new Ticket_Product_Evaluation_Investigation__c ();
        CMPL123CME__Investigation__c investigation = new CMPL123CME__Investigation__c ();
        investigation.CMPL123CME__Complaint__c = ticket.Id;
        insert investigation;
        //investigation.Name = 'Test Investigation';
        //insert investigation;

        tpei.Ticket__c = ticket.Id;
        tpei.Investigation_Evaluation__c = investigation.Id;
        insert tpei;

        investigationCustomRLCtrl.disconnectedId = String.valueOf(tpei.Id);
        investigationCustomRLCtrl.disconnectInvestigations();
        System.assertEquals(0, [SELECT COUNT() FROM Ticket_Product_Evaluation_Investigation__c WHERE Id = :tpei.Id]);

    }

}