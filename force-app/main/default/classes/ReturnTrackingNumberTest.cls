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
* Admin                    04-JUN-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Add new test method. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class ReturnTrackingNumberTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    private static void setup() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get('Complaint')
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'USA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened:Appending Regulatory Correspondence',
                CMSNext_Ticket_Number__c = '12345'),
            true
        );
        insert new Return__c(
            Ticket__c = complaint.Id,
            CMPL123_WF_Status__c = 'Opened',
            Tracking_Number__c = 'Old'
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
        Return__c returnC = [SELECT Id FROM Return__c LIMIT 1];
        //TWD Upgrade BEGIN
        TicketQDNumMDCCustom.hasProdEval = null;
        //TWD Upgrade END
        returnC.Tracking_Number__c = 'New';
        Test.startTest();
        update returnC;
        delete returnC;
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Return__c]);
    }

    /**
    * @Method       : test2
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test2 () {
        ReturnTrackingNumber mdcTrigger = new ReturnTrackingNumber();
        Return__c newRecord = new Return__c(Tracking_Number__c = 'New');
        Return__c oldRecord = new Return__c(Tracking_Number__c = 'Old');
        System.assertEquals(null, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}