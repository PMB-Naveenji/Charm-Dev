/*
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : PTWithTktSearcheBatchLotNumberMDCCustom
* @Why   : Global class to check if Regulatory task is completed then create the MDC ticket records.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID              Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    08-OCT-2018            Work ID / Case ID            Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues           Modified entry condition to execute MDC logic at beforeUpdate
*                                                                                   event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Juneid                   16 Sep 2021            Defect #158 MIR Release      Modified entry condition to execute MDC logic at beforeUpdate
*                                                                                event only for Regulatory Opininon Task 
*  --------------------------------------------------------------------------------------------------------------------------------------
*/
global class RegulatoryTaskWithMedEvalMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : customValidation
    * @Invoke       : Events from CustomValidation
    * @Description  : To Custom Validation
    * @Return       : N/A
    * @Params       : N/A
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            Regulatory_Task__c newRegulatoryTask = (Regulatory_Task__c) newRecord;
            Regulatory_Task__c oldRegulatoryTask = (Regulatory_Task__c) oldRecord;

            //W-000160
            //@Juneid Added condition only for Regulatry opinion Task For Defect #158
            return newRegulatoryTask.CMPL123_WF_Action__c  != oldRegulatoryTask.CMPL123_WF_Action__c && newRegulatoryTask.CMPL123_WF_Action__c == 'Complete' && newRegulatoryTask.RecordTypeId == AspenConstants.Regulatory_Opinion_Task_RecordType_Id;
        }
        return false;
    }
}