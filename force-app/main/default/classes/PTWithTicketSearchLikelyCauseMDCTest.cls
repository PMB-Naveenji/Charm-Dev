@IsTest
private class PTWithTicketSearchLikelyCauseMDCTest {
    @TestSetup
    private static void setup() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'INDIA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                        CMSNext_Ticket_Number__c = '12345'),
                true
        );
        insert new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = 'true'
        );

        TestUtil.setupMDC(
                PTWithTicketSearchLikelyCauseMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Likely_Cause__c
        );
    }

    @IsTest
    private static void test() {
        Product_Ticket__c productTickets = [SELECT Id FROM Product_Ticket__c LIMIT 1];

        Test.startTest();
        productTickets.Likely_Cause__c = 'false';
        TestDataFactory.updateSObject(productTickets);
        Test.stopTest();

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :productTickets.Id
                        AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);

    }
}