/*
 * @why  : To Test all scenarios on the class TicketWithSearchesICMDCCustom
 * @when : CreatedDate : 12-DEC-2018  ModifiedDate : 12-DEC-2018
 * @what : TicketWithSearchesICMDCCustomTest Test Class
 */
@IsTest
private class TicketWithSearchesICMDCCustomTest {
    /**
     * @Method       : setupData
     * @Description  : Create Test Data
     **/
    @TestSetup
    static void setupData() {
        insert new CMPL123CME__Complaint__c(
                Ticket_Type__c = 'Inquiry',
                Quality_Directive_Number__c='122',
                Customer_Reply_Required__c = true,
                Issue_code__c = 'Old'
        );

        TestUtil.setupMDC(
                TicketWithSearchesICMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Issue_code__c
        );

    }

    @IsTest
    private static void customValidationTest() {
        CMPL123CME__Complaint__c complaint = [SELECT Issue_code__c FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        complaint.Issue_code__c = 'New';
        TestDataFactory.updateSObject(complaint);
        Test.stopTest();

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c =: complaint.Id
                AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);
    }
}