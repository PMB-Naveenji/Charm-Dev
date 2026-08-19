/* 
* @why  : To Test all scenarios on the class TicketProductChangeMDCCustom
* @when : CreatedDate : 12-OCT-2018  ModifiedDate : 12-OCT-2018
* @what : TicketProductChangeMDCCustomTest Test Class
*/
@isTest
private class TicketProductChangeMDCCustomTest {

    /**
* @Method       : setupData
* @Description  : Create Test Data
**/
    @testSetup
    static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Ticket_Type__c = 'Inquiry',
                        Customer_Reply_Required__c = true,
                        Complaint_Quality_Closure_Date__c = system.now(),
                        Overall_Reportable_Status__c = 'Reportable'                        
                ), true);

        TestUtil.setupMDC(
                TicketProductChangeMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Product_Ticket_Added__c
        );
    }

    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id, Ticket_Type__c, Customer_Reply_Required__c, Product_Ticket_Added__c FROM CMPL123CME__Complaint__c LIMIT 1];
        Test.startTest();
        complaint.Product_Ticket_Added__c = 'Likely Cause';
        complaint = (CMPL123CME__Complaint__c)TestDataFactory.updateSObject(complaint);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);

        complaint.Product_Ticket_Added__c = 'Likely Cause Likely Cause';
        complaint = (CMPL123CME__Complaint__c)TestDataFactory.updateSObject(complaint);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ][1].CMPL123__Action__c);
        Test.stopTest();
    }
}