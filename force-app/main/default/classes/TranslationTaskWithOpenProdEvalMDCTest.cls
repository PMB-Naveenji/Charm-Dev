/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : Test class.
* @Why   : To test TranslationTaskWithOpenProdEvalMDCCustom class.
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
private class TranslationTaskWithOpenProdEvalMDCTest {
    /*
    * @Method       : test.
    * @Description  : Contains verification logic.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        TranslationTaskWithOpenProdEvalMDCCustom mdcTrigger = new TranslationTaskWithOpenProdEvalMDCCustom();

        Translation_Task__c newRecord = new Translation_Task__c(CMPL123_WF_Status__c = 'Closed-Done');
        Translation_Task__c oldRecord = new Translation_Task__c(CMPL123_WF_Status__c = 'Opened');

        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}