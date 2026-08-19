/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : Test class.
* @Why   : To test PTWithMedEvalLikelyCauseMDCCustom class.
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
private class PTWithMedEvalLikelyCauseMDCCustomTest {
    /*
    * @Method       : test.
    * @Description  : Contains verification logic.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        PTWithMedEvalLikelyCauseMDCCustom mdcTrigger = new PTWithMedEvalLikelyCauseMDCCustom();

        Product_Ticket__c newRecord = new Product_Ticket__c(Likely_Cause__c = 'No');
        Product_Ticket__c oldRecord = new Product_Ticket__c(Likely_Cause__c = 'Yes');

        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}