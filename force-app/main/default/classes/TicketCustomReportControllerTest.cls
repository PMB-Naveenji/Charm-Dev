/**
 * Created by rsitc on 29.05.2019.
 */
@isTest
class TicketCustomReportControllerTest {
    @testSetup
    static void setupData() {
        //Create Complaint
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Ticket_Type__c = 'Complaint',
                        Follow_up_Status__c = 'Responded',
                        Customer_Reply_Required__c = true,
                        CMSNext__c = 'Closed'), true);

        //Create Audit_Trail_Entry
        CMPL123__Audit_Trail_Entry__c ate = (CMPL123__Audit_Trail_Entry__c) TestDataFactory.createSObject(new CMPL123__Audit_Trail_Entry__c(
                CMPL123__Audit_Trail_JSON__c = '[{\"ov\":\"\",\"Open\":\"\",\"nv\":\"Closed\",\"fn\":\"CMSNext Status\",\"fieldAPI\":\"CMSNext__c\"}]',
                CMPL123__ParentId__c = objComplaint.Id,
                CMPL123__Action__c = 'Update'), true);

        CMPL123__AuditTrail_Config__c objAuditTrialConfig = new CMPL123__AuditTrail_Config__c(
                CMPL123__Fields__c = 'CMSNext__c',
                CMPL123__Is_Active__c = true,
                CMPL123__AuditTrail_External_Id__c = ate.Id);
        insert objAuditTrialConfig;
        //Create MDC_Trigger
        CMPL123__MDC_Trigger__c mdcTrigger = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(new CMPL123__MDC_Trigger__c (
                CMPL123__Select_Target_Object__c = 'CMPL123CME__Complaint__c',
                CMPL123__Criteria__c = 'Created or Changed',
                CMPL123__Logic__c = '1',
                CMPL123__Active__c = true
        ), true);


        //Create MDC_Field_Mapping
        CMPL123__MDC_Field_Mapping__c fieldMapping = (CMPL123__MDC_Field_Mapping__c) TestDataFactory.createSObject(new CMPL123__MDC_Field_Mapping__c(
                CMPL123__Field_Name__c = 'CMSNext Status',
                CMPL123__Index__c = 1,
                CMPL123__Field_API__c = 'CMSNext__c',
                CMPL123__Condition__c = 'Custom',
                CMPL123__Selected_object__c = 'CMPL123CME__Complaint__c',
                CMPL123__Parent_object__c = mdcTrigger.Id), true);


        //Create AcknowledgementMapping
        CMPL123__AcknowledgementMapping__c ackMapping = (CMPL123__AcknowledgementMapping__c) TestDataFactory.createSObject(new CMPL123__AcknowledgementMapping__c(
                CMPL123__SelectObject__c = 'CMPL123CME__Complaint__c',
                CMPL123__AckNumber__c = 1,
                CMPL123__UsersFieldAcknowledgment__c = '123Admin',
                CMPL123__PublicGroupAcknowledgment__c = '123Admin',
                CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id), true);

        CMPL123__MDC_Ticket__c mdcTicket = new CMPL123__MDC_Ticket__c(
                CMPL123__Record_Type__c = 'CMPL123CME__Complaint__c',
                CMPL123__MDC_Trigger__c = mdcTrigger.Id, CMPL123__Field_Name__c = 'CMSNext Status',
                CMPL123__Field_Condition__c = 'Custom',
                CMPL123__Audit_Trail_Entry__c = ate.Id,
                CMPL123__Related_Record_ID__c = objComplaint.Id); //@Lakshman - Assigned the value to CMPL123__Related_Record_ID__c
        Insert mdcTicket;

    }

    @isTest
    static void customReportTest() {
        Test.startTest();
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        PageReference pageReference = Page.Ticket_Custom_Report;
        Test.setCurrentPage(pageReference);
        ApexPages.currentPage().getParameters().put('id', complaint.Id);
        TicketCustomReportController controller = new TicketCustomReportController(new ApexPages.StandardController(complaint));
        Test.stopTest();
        System.assertEquals(1, controller.ticketWithChildsAndGrandChildsList.size());
    }

}