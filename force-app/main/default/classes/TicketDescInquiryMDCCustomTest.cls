/* 
* @why  : To Test all scenarios on the class TicketDescInquiryMDCCustom
* @when : CreatedDate : 13-DEC-2018  ModifiedDate : 13-DEC-2018
* @what : TicketDescInquiryMDCCustomTest Test Class
*/
@isTest
private class TicketDescInquiryMDCCustomTest {
    /**
* @Method       : setupData
* @Description  : Create Test Data
**/
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                        Complaint_Quality_Closure_Date__c = system.now(),
                        Overall_Reportable_Status__c = 'Reportable',
                        Customer_Reply_Required__c = true,
                        Follow_up_Status__c = 'Test'
                ), true);
        TestUtil.setupMDC(
                TicketDescInquiryMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Ticket_Description__c
        );
    }

    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        complaint.Ticket_Description__c = 'Test';
        complaint = (CMPL123CME__Complaint__c)TestDataFactory.updateSObject(complaint);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);
        Test.stopTest();
    }
}