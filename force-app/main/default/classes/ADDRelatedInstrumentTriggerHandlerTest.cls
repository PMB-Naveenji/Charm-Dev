/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDRelatedInstrumentTriggerHandlerTest.
* @Why   : ADDRelatedInstrumentTriggerHandlerTest class for the ADDRelatedInstrumentTriggerHandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ADDRelatedInstrumentTriggerHandlerTest {
    /*
    * @Method       : test.
    * @Description  : To test the ADDRelatedInstrumentTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        Related_Instrument__c relatedInstrumentObj = new Related_Instrument__c();
        insert relatedInstrumentObj;
        update relatedInstrumentObj;
        delete relatedInstrumentObj;

        System.assertEquals(0, [SELECT COUNT() FROM Related_Instrument__c]);
    }
}