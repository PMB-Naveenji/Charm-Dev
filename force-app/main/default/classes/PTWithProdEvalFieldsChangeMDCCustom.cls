/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : PTWithProdEvalFieldsChangeMDCCustom
* @Why   : Global class to check if List Number field is changed and if yes create the MDC trigger record.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    14-NOV-2018            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    20-May-2020            #115 / CHARM-2665    Removed condition to check if Likely_Cause__c
*                                                                        has different values in new/old records.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class PTWithProdEvalFieldsChangeMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) 
    {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) 
        {
            //TWD Upgrade fix END
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldComplaint = (CMPL123CME__Complaint__c) oldRecord;

            //Defect #115 / CHARM-2665 fix start
            if (oldComplaint.Product_Ticket_Added__c != null && newComplaint.Product_Ticket_Added__c != null && newComplaint.Product_Ticket_Added__c != oldComplaint.Product_Ticket_Added__c) 
            {
                 Boolean isDefaultsAssigned = TicketQDNumMDCCustom.hasProdEval != null;
                if (!isDefaultsAssigned) 
                {
                    TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
                    isDefaultsAssigned = true;
                }
                
                //Defect #115 / CHARM-2665 fix end
             /*   if (TicketQDNumMDCCustom.hasProdEval == null) 
                {
                    TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
                }
                return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval; */
              return isDefaultsAssigned && TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}