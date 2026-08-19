/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDTicketVersionTriggerhandlerTest.
* @Why   : ADDTicketVersionTriggerhandlerTest class for the ADDTicketVersionTriggerhandler class.
* @When  : 26-DEC-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                26-DEC-2018            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                26-DEC-2018            N/A                           Modified.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                14-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                07-SEP-2020           PMD report fixes          Added System.assert's.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class ADDTicketVersionTriggerhandlerTest {
    /*
    * @Method       : setupData.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {

        //Create Complaint
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(Ticket_Type__c = 'Complaint',Customer_Reply_Required__c = true), true);

        //Create Ticket Version
        Ticket_Version__c objTicketVersion = (Ticket_Version__c) TestDataFactory.createSObject(new Ticket_Version__c(
        									Ticket__c = objComplaint.Id
        									),true);
    }

    /*
    * @Method       : actionDML.
    * @Description  : To test the ADDTicketVersionTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void actionDML() {

        Ticket_Version__c objTicketVersion = [SELECT Id FROM Ticket_Version__c LIMIT 1];
        update objTicketVersion;
        //PMD report fix for System assert start. This method should be refactored.
        System.assertEquals(2, [SELECT count() FROM Ticket_Version__c], '2 Record should exist');
        //PMD report fix for System assert end.
        delete objTicketVersion;
        //PMD report fix for System assert start. This method should be refactored.
        System.assertEquals(1, [SELECT count() FROM Ticket_Version__c], 'Record should be deleted');
        //PMD report fix for System assert end.
    }
}