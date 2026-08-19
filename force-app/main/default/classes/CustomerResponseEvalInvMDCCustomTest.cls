/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who  : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @what : CustomerResponseEvalInvMDCCustomTest Test Class
* @why  : To Test all scenarios on the class CustomerResponseEvalInvMDCCustom
* @when : 27-MAY-2020
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    27-MAY-2020            #136 (CHARM-2759)    Created. Added logic to test "Customer Response change for
*                                                                      Evaluator/Investigator" MDC Trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* dskak                    08-JUL-2020            Code Audit           Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    13-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class CustomerResponseEvalInvMDCCustomTest {
    /**
    * @Method       : setupData
    * @Description  : Create Test Data
    * @Return       : N/A
    * @Params       : N/A
    **/
    @testSetup static void setupData() {
         CMPL123CME__Complaint__c objInquiry = (CMPL123CME__Complaint__c) TestDataFactory.createSObject (
            new CMPL123CME__Complaint__c (
                Ticket_Type__c = 'Inquiry',
                Customer_Reply_Required__c = true,
                //TWD Issue fix BEGIN
                RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId(),
                CMSNext_Ticket_ID__c = '12345',
                CMSNext_Ticket_Number__c = '12345'
                //TWD Issue fix END
            ),
            true
        );
        Customer_Response__c objCustomerResponseInquiry = (Customer_Response__c) TestDataFactory.createSObject (
            new Customer_Response__c (
                Customer_Expectation__c = 'CustomerExpectation',
                Event__c = objInquiry.Id,
                //TWD Issue fix BEGIN
                CMPL123_WF_Status__c = 'Opened',
                CMPL123Rule_Key_Value__c = 'Inquiry_Customer_Response',
                CMSNext_Ticket_Number__c = '12345',
                Ticket_Type__c = 'Inquiry',
                Division_New__c = 'ADD',
                Action_Required__c = false
                //TWD Issue fix END
            ),
            true
        );
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject (
            new CMPL123CME__Complaint__c (
                Ticket_Type__c = 'Complaint',
                Customer_Reply_Required__c = true,
                //TWD Issue fix BEGIN
                RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(),
                CMSNext_Ticket_ID__c = '12346',
                CMSNext_Ticket_Number__c = '12346'
                //TWD Issue fix END
            ),
            true
        );
        Customer_Response__c objCustomerResponseComplaint = (Customer_Response__c) TestDataFactory.createSObject (
            new Customer_Response__c (
                Customer_Expectation__c = 'CustomerExpectation',
                Event__c = objComplaint.Id,
                //TWD Issue fix BEGIN
                CMPL123_WF_Status__c = 'Opened',
                CMPL123Rule_Key_Value__c = 'Complaint_Customer_Response',
                CMSNext_Ticket_Number__c = '12346',
                Ticket_Type__c = 'Complaint',
                Division_New__c = 'ADD',
                Action_Required__c = false
                //TWD Issue fix END
            ),
            true
        );
        TestUtil.setupMDC(
            CustomerResponseEvalInvMDCCustom.class,
            Customer_Response__c.getSObjectType(),
            Customer_Response__c.Customer_Expectation__c
        );
        delete [SELECT Id FROM CMPL123__AcknowledgementMapping__c];
        CMPL123__MDC_Trigger__c mdcTrigger = [
            SELECT Id
            FROM CMPL123__MDC_Trigger__c
            LIMIT 1
        ];
        CMPL123__AcknowledgementMapping__c ackMapping = (CMPL123__AcknowledgementMapping__c) TestDataFactory.createSObject (
            new CMPL123__AcknowledgementMapping__c (
                CMPL123__SelectObject__c = 'Customer_Response__c',
                CMPL123__AckNumber__c = 1,
                CMPL123__PublicGroupAcknowledgment__c = 'Evaluator/Investigator',
                CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
                CMPL123__Index__c = 1
            ),
            true
        );
    }

    /**
    * @Method       : testMDCForCustomerComplaintCR
    * @Description  : To test CustomerResponseEvalInvMDCCustom.CustomValidation method
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testMDCForCustomerComplaintCR () {
        Customer_Response__c customerResponseComplaint = [
            SELECT Id, Event__c, Registration_Ticket__c, Registration_Ticket_Number__c
            FROM Customer_Response__c
            WHERE Event__r.Ticket_Type__c = 'Complaint'
            LIMIT 1
        ];
        System.debug('customerResponseComplaint: ' + customerResponseComplaint);
        Test.startTest();
        customerResponseComplaint.Customer_Expectation__c = 'test updated';
        customerResponseComplaint = (Customer_Response__c) TestDataFactory.updateSObject(customerResponseComplaint);
        Test.stopTest();
        System.assertEquals(
            1,
            [
                SELECT Id
                FROM CMPL123__MDC_Ticket__c
            ].size(),
            'MDC ticket should be created');
        System.assertEquals(
            1,
            [
                SELECT Id, Evaluator_Investigator__c
                FROM CMPL123__MDC_Ticket__c
            ].Evaluator_Investigator__c,
            'MDC ticket should be created for Evaluator/Investigator'
        );
    }

    /**
    * @Method       : testMDCForCustomerComplaintCR
    * @Description  : To test CustomerResponseEvalInvMDCCustom.CustomValidation method with negative scenario
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testMDCForCustomerComplaintCRNegative () {
        Customer_Response__c customerResponseComplaint = [
            SELECT Id, Event__c, Registration_Ticket__c, Registration_Ticket_Number__c
            FROM Customer_Response__c
            WHERE Event__r.Ticket_Type__c = 'Inquiry'
            LIMIT 1
        ];
        System.debug('customerResponseComplaint: ' + customerResponseComplaint);
        Test.startTest();
        customerResponseComplaint.Customer_Expectation__c = 'test updated';
        customerResponseComplaint = (Customer_Response__c) TestDataFactory.updateSObject(customerResponseComplaint);
        Test.stopTest();
        System.assertEquals(
            0,
            [
                SELECT Id
                FROM CMPL123__MDC_Ticket__c
            ].size(),
            'MDC ticket should not be created'
        );
    }
}