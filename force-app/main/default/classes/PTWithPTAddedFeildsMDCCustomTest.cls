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
* Admin                    21-DEC-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Delete setup and add logic to customValidationTest methods. 
*                                                                      Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class PTWithPTAddedFeildsMDCCustomTest {
    /**
    * @Method       : customValidationTest
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    private static void customValidationTest() { 
        PTWithPTAddedFeildsMDCCustom mdcTrigger = new PTWithPTAddedFeildsMDCCustom();
        Product_Ticket__c newRecord = new Product_Ticket__c(Bactch_Likely_List__c = 'New');
        Product_Ticket__c oldRecord = new Product_Ticket__c(Bactch_Likely_List__c = 'Old');
        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}