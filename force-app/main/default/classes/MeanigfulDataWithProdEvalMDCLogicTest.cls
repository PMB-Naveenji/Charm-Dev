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
* Admin                    30-MAY-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Delete setup and modify test methods. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class MeanigfulDataWithProdEvalMDCLogicTest {
    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test () {
        MeanigfulDataWithProdEvalMDCLogic mdcTrigger = new MeanigfulDataWithProdEvalMDCLogic();
        Meaningful_Data__c newRecord = new Meaningful_Data__c(Meaningful_Data_Details__c = 'New');
        Meaningful_Data__c oldRecord = new Meaningful_Data__c(Meaningful_Data_Details__c = 'Old');
        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}