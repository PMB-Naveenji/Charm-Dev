/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 14-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    19-MAY-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
class TicketNoteWithMedEvalsMDCCustomTest {
    /**
    * @Method       : setupData
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                Complaint_Quality_Closure_Date__c = system.now(),
                Overall_Reportable_Status__c = 'Reportable'), true);

        Ticket_Note__c ticketNote = (Ticket_Note__c) TestDataFactory.createSObject(
            new Ticket_Note__c(Ticket__c = objComplaint.Id),
            true
        );

        TestUtil.setupMDC(
            //TWD Update BEGIN
            TicketNoteWithMedEvalsMDCCustom.class,
            //TWD Update END
            Ticket_Note__c.getSObjectType(),
            Ticket_Note__c.Ticket_Note_Added__c
        );
    }

    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test() {
        Ticket_Note__c ticketNote = [SELECT Id FROM Ticket_Note__c LIMIT 1];

        Test.startTest();
        ticketNote.Ticket_Note_Added__c = 'Yes';
        TestDataFactory.updateSObject(ticketNote);

        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c =: ticketNote.Id
            AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);

        Test.stopTest();
    }
}