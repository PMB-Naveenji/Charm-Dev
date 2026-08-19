/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : PatientInformationMDCLogic
* @Why   : Global class to check if Patient Information record Ticket Review Status is changed, and if yes then
           create the MDC trigger for that change.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    19-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    26-May-2020            #124 (CHARM-2724)    Condition for MDC ticket creation is changed.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class PatientInformationMDCLogic implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            Patient_Information__c newPatientInformation = (Patient_Information__c) newRecord;
            Patient_Information__c oldPatientInformation = (Patient_Information__c) oldRecord;

            // #124 (CHARM-2724) start. Condition is changed. All fields should be checked.
            if (newPatientInformation.Patient_Information__c != oldPatientInformation.Patient_Information__c
                || newPatientInformation.Patient_Information_Translated__c != oldPatientInformation.Patient_Information_Translated__c
                || newPatientInformation.External_Id__c != oldPatientInformation.External_Id__c) {
            // #124 (CHARM-2724) end.
                if (TicketQDNumMDCCustom.hasMedEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newPatientInformation.Parent_Ticket_Id__c);
                }
                return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
            }
        }
        return false;
    }
}