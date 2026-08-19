/* 
* @why  : To Test all scenarios on the class TicketDescMDCCustom
* @when : CreatedDate : 25-OCT-2018  ModifiedDate : 25-OCT-2018
* @what : TicketDescMDCCustomTest Test Class
*/
@isTest
private class TicketDescMDCCustomTest {
    
    /**
* @Method       : setupData
* @Description  : Create Test Data
**/
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                        Complaint_Quality_Closure_Date__c = system.now(),
                        Overall_Reportable_Status__c = 'Reportable'), true);

        TestUtil.setupMDC(
                TicketDescMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Ticket_Description__c
        );
    }

    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        complaint.Ticket_Description__c = 'Test';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);

        TicketQDNumMDCCustom.hasProdEval = true;
        complaint.Ticket_Description__c = 'Test Update';
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