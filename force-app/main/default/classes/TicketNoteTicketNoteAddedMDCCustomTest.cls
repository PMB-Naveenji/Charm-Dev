/* 
* @why  : To Test all scenarios on the class TicketNoteTicketNoteAddedMDCCustom
* @when : CreatedDate : 30-OCT-2018  ModifiedDate : 30-OCT-2018
* @what : TicketNoteTicketNoteAddedMDCCustomTest Test Class
*/
@isTest
private class TicketNoteTicketNoteAddedMDCCustomTest {

    /**
* @Method       : setupData
* @Description  : Create Test Data
**/
    @testSetup
    static void setupData() {
        CMPL123CME__Complaint__c objInquiry = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Ticket_Type__c = 'Inquiry',
                        Customer_Reply_Required__c = true
                ), true);
        Ticket_Note__c objTicketNoteInquiry = (Ticket_Note__c) TestDataFactory.createSObject(
                new Ticket_Note__c(
                        Ticket__c = objInquiry.Id
                ), true);
        TestUtil.setupMDC(
                TicketNoteTicketNoteAddedMDCCustom.class,
                Ticket_Note__c.getSObjectType(),
                Ticket_Note__c.Ticket_Note_Added__c
        );
    }

    /**
* @Method       : customValidation
* @Description  : Test method to cover CustomValidation method in TicketNoteTicketNoteAddedMDCCustom Class
**/
    @isTest
    static void customValidation() {
        Test.startTest();
        Ticket_Note__c objTicketNoteInquiry = [
                SELECT Id, Ticket_Note_Added__c
                FROM Ticket_Note__c
                WHERE Ticket__r.Ticket_Type__c = 'Inquiry'
                LIMIT 1
        ];
        objTicketNoteInquiry.Ticket_Note_Added__c = 'Note Added';
        objTicketNoteInquiry = (Ticket_Note__c) TestDataFactory.updateSObject(objTicketNoteInquiry);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :objTicketNoteInquiry.Id
                AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);
        Test.stopTest();
    }
}