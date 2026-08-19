/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 13-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    12-OCT-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    13-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class CustomerResponseCustExpectMDCCustomTest {
    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test () {
        CustomerResponseCustExpectMDCCustom mdcTrigger = new CustomerResponseCustExpectMDCCustom();
        Customer_Response__c newAttachment = new Customer_Response__c(Customer_Expectation__c = 'asdf');
        Customer_Response__c oldAttachment = new Customer_Response__c(Customer_Expectation__c = 'hjkl');
        System.assertEquals(false, mdcTrigger.CustomValidation(oldAttachment, newAttachment));
        newAttachment = new Customer_Response__c(Additional_Reply_Expectation__c = 'asdf');
        oldAttachment = new Customer_Response__c(Additional_Reply_Expectation__c = 'hjkl');
        System.assertEquals(false, mdcTrigger.CustomValidation(oldAttachment, newAttachment));
    }
}