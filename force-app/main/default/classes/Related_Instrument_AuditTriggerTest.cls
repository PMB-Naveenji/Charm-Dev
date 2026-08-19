/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Related_Instrument_AuditTriggerTest.
* @Why   : Related_Instrument_AuditTriggerTest test class for the Related_Instrument_AuditTrigger trigger.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 21-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class Related_Instrument_AuditTriggerTest {

    /*
    * @Method       : test.
    * @Description  : Test method to cover Related_Instrument_AuditTrigger trigger functionality.
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