@isTest
class TicketSearchesMDCLogicTest {
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Ticket_Type__c = 'Inquiry',
                        Customer_Reply_Required__c = true,
                        Ticket_Description__c = 'Test'
                ), true);

        Ticket_Review__c ticketReview = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        FA_CAPA_Short_Description__c = 'test',
                        CAPA_Number__c = 'test',
                        Search_Frequency__c = 'Two Weeks (14 days)',
                        Division__c = 'ADD',
                        Pending_Batch_Jobs__c = '7070j00000OO6fAAAT',
                        Status__c = 'Active',
                        Medical_Assignee_Name__c = Userinfo.getUserId()
                ), true);

        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                new Ticket_Search_Result__c(
                        Ticket_Review__c = ticketReview.Id,
                        Ticket__c = objComplaint.Id,
                        Unique_Identifier__c = ticketReview.Id + '-' + objComplaint.Id
                ), true);

        TestUtil.setupMDC(
                TicketSearchesMDCLogic.class,
                Ticket_Search_Result__c.getSObjectType(),
                Ticket_Search_Result__c.Ticket_Review_Status__c
        );
    }

    @isTest
    static void customValidationTest() {
        Ticket_Search_Result__c ticketSearchResult = [SELECT Id, Ticket_Review_Status__c FROM Ticket_Search_Result__c LIMIT 1];
        Test.startTest();

        ticketSearchResult.Ticket_Review_Status__c = 'Related with Malfunction';
        TestDataFactory.updateSObject(ticketSearchResult);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :ticketSearchResult.Id
                AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);

        Test.stopTest();
    }
}