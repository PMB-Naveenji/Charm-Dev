@isTest
class TicketQDNWithTicketSearchesMDCCustomTest {

    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                        Complaint_Quality_Closure_Date__c = system.now(),
                        Overall_Reportable_Status__c = 'Reportable'), true);

        TestUtil.setupMDC(
                TicketQDNWithTicketSearchesMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Quality_Directive_Number__c
        );
    }

    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        complaint.Quality_Directive_Number__c = '10';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);

        TicketQDNumMDCCustom.isTicketInquiry = false;
        TicketQDNumMDCCustom.hasTicketSearch = true;
        complaint.Quality_Directive_Number__c = '12';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ][1].CMPL123__Action__c);

        Test.stopTest();
    }
}