/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : Test class.
* @Why   : To test ReturnThirdRequestedDate class.
* @When  : 14-JAN-2021.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    14-JAN-2020            TWD Upgrade               Created. TWD Upgrade issue related to MDCs generation.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ReturnThirdRequestedDateTest {
    /*
    * @Method       : test.
    * @Description  : Contains verification logic.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        ReturnThirdRequestedDate mdcTrigger = new ReturnThirdRequestedDate();

        Return__c newRecord = new Return__c(Third_Return_Requested_Date__c = DateTime.now().addHours(5));
        Return__c oldRecord = new Return__c(Third_Return_Requested_Date__c = DateTime.now());

        System.assertEquals(null, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}