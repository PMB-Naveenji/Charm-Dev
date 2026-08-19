/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 14-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    13-DEC-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TicketFollowUpStatusInquiryMDCCustomTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                Complaint_Quality_Closure_Date__c = system.now(),
                Overall_Reportable_Status__c = 'Reportable',
                Customer_Reply_Required__c = true,
                //TWD Update BEGIN
                Follow_up_Status__c = 'Complete'
                //TWD Update END
            ), true);
        TestUtil.setupMDC(
            TicketFollowUpStatusInquiryMDCCustom.class,
            CMPL123CME__Complaint__c.getSObjectType(),
            CMPL123CME__Complaint__c.Follow_up_Status__c
        );
    }

    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        //TWD Update BEGIN
        complaint.Follow_up_Status__c = 'Further Review';
        //TWD Update END
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