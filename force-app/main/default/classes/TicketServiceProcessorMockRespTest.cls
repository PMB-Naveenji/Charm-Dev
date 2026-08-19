/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketServiceProcessorMockRespTest.
* @Why   : To mock request from CMSNext.
* @When  : 25-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  25-OCT-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  04-JUN-2020            Code Audit                      Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
global class TicketServiceProcessorMockRespTest implements HttpCalloutMock {
    /*
    * @Method       : respond.
    * @Description  : Implement this interface method.
    * @Invoke       : From TicketServiceTest class.
    * @Return       : HTTPResponse.
    * @Params       : HTTPRequest req.
    */
    global HTTPResponse respond(HTTPRequest req) {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            CMSNext_Ticket_Id__c = '159159C20181024'
        ), true);

        // Create pRE Information
        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(new pRE_Information__c(
            External_ID__c = 'CHaRM 24102018 - 01'
        ), true);

		//Sample response provide by service processor
        Account acc = new Account(
            Customer_External_ID__c = 'CHaRM 24101802',
            Name = 'Test'
        );

        upsert complaint;
        upsert preInfo;
        upsert acc;

        HttpResponse res = new HttpResponse();
        InternalTicketServiceProcessor.ResponseWrapper response = new InternalTicketServiceProcessor.ResponseWrapper();

        response.isSuccess = TRUE;
        response.successMap = new Map<String,String>();
        response.successMap.put('accId',acc.Id);
        response.successMap.put('ticketId',complaint.Id);
        response.successMap.put('preInfoId',preInfo.Id);

        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(response));
        res.setStatusCode(200);

        return res;
    }
}