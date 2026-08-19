@isTest
class TicketNoteWithTickteSearchesMDCCustTest {
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
                TicketNoteWithTickteSearchesMDCCustom.class,
                Ticket_Note__c.getSObjectType(),
                Ticket_Note__c.Ticket_Note_Added__c
        );
    }

    @IsTest
    private static void test() {
        Ticket_Note__c ticketNote = [SELECT Id FROM Ticket_Note__c LIMIT 1];

        Test.startTest();
        ticketNote.Ticket_Note_Added__c = 'Yes';
        TestDataFactory.updateSObject(ticketNote);

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :ticketNote.Id
                AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);

        Test.stopTest();
    }
}