/*
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:  
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID            Description 
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    06-JAN-2021            TWD Upgrade issue          Added testWfLogic
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@IsTest
class ADDTicketSearchResultTriggerHandlerTest {

    @TestSetup
    static void testSetup() {
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

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(RecordTypeId = complaintRTId), true);

        TestDataFactory.createSObject(new Ticket_Search_Result__c(
            Ticket_Review__c = ticketReview.Id,
            Ticket_Review_Status__c = 'Related with Malfunction',
            Ticket__c = complaint.Id,
            Unique_Identifier__c = ticketReview.Id + '-' + complaint.Id
        ), true);
    }

    @IsTest
    static void handlerTest() {
        Ticket_Search_Result__c objTicketSearchResult = [SELECT Id FROM Ticket_Search_Result__c LIMIT 1];
        update objTicketSearchResult;
        delete objTicketSearchResult;
        System.assert(0 == [SELECT COUNT() FROM Ticket_Search_Result__c WHERE Id = :objTicketSearchResult.Id]);
    }
    /*
    * @Method       : testWFlogic
    * @Description  : Test logic from disabled WF rules
    * @Return       : N/A
    * @Params       : N/A
    */ 
    @isTest static void testWFlogic(){
        // WF: Autoset Registration Number
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        complaint.CMSNext_Ticket_Number__c = '123456';
        update complaint;
        Ticket_Review__c ticketReview = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        Ticket_Search_Result__c res = (Ticket_Search_Result__c )TestDataFactory.createSObject(new Ticket_Search_Result__c(
            Ticket_Review__c = ticketReview.Id,
            Ticket_Review_Status__c = 'Related with Malfunction',
            Ticket__c = complaint.Id,
            Unique_Identifier__c = ticketReview.Id + '-' + complaint.Id
        ), true);
        System.assertEquals('123456(Complaint)', [SELECT Registration_Number__c FROM Ticket_Search_Result__c WHERE Id =: res.Id].Registration_Number__c);

        String serviceRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        CMPL123CME__Complaint__c service = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Complaint_Demotion_rationale__c = '',
                Demotion_rationale__c = '',
                Complaint_Demoted_By__c = UserInfo.getName(),
                Complaint_Demotion_Date__c = System.Now(),
                Division__c  = 'ADD',
                pRE_Status__c  = 'Yes',
                Country_of_origin__c = 'INDIA',
                RecordTypeId = serviceRTId,
                Service_Type__c = 'Planned',
                Business_Unit__c  = 'IA-CC',
                Ticket_Type__c = 'Service',
                Is_Product_Evaluation_Investigation_chil__c = false,
                CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
                CMSNext_Ticket_Number__c = '12345678',
                CMPL123Rule_Key_Value__c = 'SERVICE_WORKFLOW',
                Trending_issue_Bucket__c = 'ProdEvel',
                Receipt_Date__c = System.today() - 5
        ), true);
        res = (Ticket_Search_Result__c )TestDataFactory.createSObject(new Ticket_Search_Result__c(
            Ticket_Review__c = ticketReview.Id,
            Ticket_Review_Status__c = 'Related with Malfunction',
            Ticket__c = service.Id,
            Unique_Identifier__c = ticketReview.Id + '-' + service.Id
        ), true);
        System.assertEquals('12345678(Planned Service)', [SELECT Registration_Number__c FROM Ticket_Search_Result__c WHERE Id =: res.Id].Registration_Number__c);
        //WF: Set Ticket Review Status Date
        System.assertNotEquals(null, [SELECT Ticket_Review_Status_Date__c FROM Ticket_Search_Result__c WHERE Id =: res.Id].Ticket_Review_Status_Date__c);
        res.Ticket_Review_Status__c = 'Not Related';
        res.Not_Related_Rationale__c = 'TEST';
        res.Ticket_Review_Status_Date__c = null;
        update res;
        System.assertNotEquals(null, [SELECT Ticket_Review_Status_Date__c FROM Ticket_Search_Result__c WHERE Id =: res.Id].Ticket_Review_Status_Date__c);
    }
}