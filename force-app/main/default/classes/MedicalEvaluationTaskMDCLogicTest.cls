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
* Admin                    26-OCT-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class MedicalEvaluationTaskMDCLogicTest {
    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test () {
        MedicalEvaluationTaskMDCLogic mdcTrigger = new MedicalEvaluationTaskMDCLogic();
        Medical_Evaluation_Task__c newRecord = new Medical_Evaluation_Task__c(CMPL123_WF_Status__c = 'Closed-Done');
        Medical_Evaluation_Task__c oldRecord = new Medical_Evaluation_Task__c(CMPL123_WF_Status__c = 'Opened');
        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}