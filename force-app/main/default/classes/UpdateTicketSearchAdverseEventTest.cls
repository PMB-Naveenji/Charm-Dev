/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateTicketSearchAdverseEventTest.
* @Why   : To test functionality of 'UpdateTicketSearchAdverseEvent' class.
* @When  : 06-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  06-MAY-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class UpdateTicketSearchAdverseEventTest {
    /*
    * @Method       : updateSearchAdverseEventTest.
    * @Description  : To test functionality of UpdateTicketSearchAdverseEvent class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void updateSearchAdverseEventTest() {
        Test.startTest();
        Ticket_Review__c objTicketReview = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        Status__c = 'Active'
                ), true);
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Ticket_Type__c = 'Inquiry',
                        Customer_Reply_Required__c = true,
                        Was_an_Adverse_Event_Identified__c = 'Yes'
                ), true);

        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                new Ticket_Search_Result__c(
                        Ticket_Review__c = objTicketReview.Id,
                        Unique_Identifier__c = objTicketReview.Id + '-' + objComplaint.Id,
                        Ticket_Review_Status__c = 'Related with Malfunction',
                        Ticket__c = objComplaint.Id
                ), true);
        UpdateTicketSearchAdverseEvent updateSearchResRecs = new UpdateTicketSearchAdverseEvent(new List<Id>{
                objComplaint.Id
        });
        Database.executeBatch(updateSearchResRecs);
        Test.stopTest();
        Ticket_Search_Result__c objTicketSearchResultUpdated = [
                SELECT Is_Ticket_Adverse_Event__c
                FROM Ticket_Search_Result__c
                WHERE Id = :objTicketSearchResult.Id
        ];
        System.assertEquals(objComplaint.Was_an_Adverse_Event_Identified__c, objTicketSearchResultUpdated.Is_Ticket_Adverse_Event__c);
    }
}