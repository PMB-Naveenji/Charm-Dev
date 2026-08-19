@isTest
class TicketChangeAOACMDCCustomTest {
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                        Complaint_Quality_Closure_Date__c = system.now(),
                        Overall_Reportable_Status__c = 'Reportable'), true);

        TestUtil.setupMDC(
                TicketChangeAOACMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Additional_Ticket_Observations_Comments__c
        );
    }

    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        complaint.Additional_Ticket_Observations_Comments__c = 'Test';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c =: complaint.Id
                AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);

        TicketQDNumMDCCustom.isTicketInquiry = false;
        complaint.Additional_Ticket_Observations_Comments__c = 'Test Updated';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c =: complaint.Id
                AND CMPL123__Action__c = 'Update'][1].CMPL123__Action__c);

        Test.stopTest();
    }

}