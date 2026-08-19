/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : RecordsWithoutWFHistoryTest.
* @Why   : RecordsWithoutWFHistoryTest test class for the RecordsWithoutWFHistory class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 20-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*  Juneid               08 Feb 2021         Error Fix                         Updated the user
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class RecordsWithoutWFHistoryTest {
    static final String APINAME = Schema.Ticket_Search_Result__c.SObjectType.getDescribe().getName();

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {

    }

    /*
    * @Method       : processRecordsTest.
    * @Description  : To test processRecords method functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void processRecordsTest() {
        String userName = Label.Migration_User_Name;
        User curUser = [SELECT id,Name,Email FROM User WHERE Username = :userName];
        //@Juneid 08 Feb 2021, Updat the user 
        curUser.isActive = true;
        update curUser;
        System.runAs(curUser){

            //Create Complaint
            CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                    new CMPL123CME__Complaint__c(
                            Ticket_Type__c = 'Inquiry',
                            Customer_Reply_Required__c = true
                    ), true);

            //Create Customer Response
            Ticket_Review__c objTicketReview = (Ticket_Review__c) TestDataFactory.createSObject(
                    new Ticket_Review__c(
                            Status__c = 'Active'
                    ), true);

            Ticket_Review__c objTicketReview1 = (Ticket_Review__c) TestDataFactory.createSObject(new Ticket_Review__c(
                    Status__c = 'Active'), true);

            // Create Ticket Search Result
            Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                    new Ticket_Search_Result__c(
                            Ticket_Review__c = objTicketReview.Id,
                            Unique_Identifier__c = objTicketReview.Id + '-' + objComplaint.Id,
                            Ticket_Review_Status__c = 'Related with Malfunction',
                            Ticket__c = objComplaint.Id), true);
        }
        RecordsWithoutWFHistory controller = new RecordsWithoutWFHistory(APINAME);
        System.assert(controller.lstRec.size() > 0);
    }

}