/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : ProductLotMDCCustom
* @Why   : Global class to check if Expiration/Manufacturing Date change and Parent Ticket is Reportable
           and Med Eval is not closed-voided then create the MDC ticket records.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    08-OCT-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class ProductLotMDCCustom implements CMPL123.IMDCCustomValidation {
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
            /*Product_Lot__c  newProductLot = (Product_Lot__c )Trigger.new[0];
            Product_Lot__c  oldProductLot = (Product_Lot__c )Trigger.old[0];
            */
            //Modified the above two lines because of a security issue. "AvoidDirectAccessTriggerMap"
            //FYI : https://pmd.github.io/pmd/pmd_rules_apex_errorprone.html#avoiddirectaccesstriggermap
            Product_Lot__c newProductLot,oldProductLot;
            for(Product_Lot__c prodLot : (List<Product_Lot__c>)Trigger.new){
                newProductLot = prodLot;
                break;
            }
            for(Product_Lot__c prodLot : (List<Product_Lot__c>)Trigger.old){
                oldProductLot = prodLot;
                break;
            }

            if (TicketQDNumMDCCustom.hasMedEval == null && newProductLot.Related_Ticket__c != null) {
                TicketQDNumMDCCustom.setDefaults(newProductLot.Related_Ticket__c);
            }
            return ((newProductLot.Device_Manufacturing_Date__c != oldProductLot.Device_Manufacturing_Date__c) 
                    || (newProductLot.Device_Manufacturing_Date_Unknown__c != oldProductLot.Device_Manufacturing_Date_Unknown__c)
                    || (newProductLot.Device_Manufacturing_Date_NA__c != oldProductLot.Device_Manufacturing_Date_NA__c) 
                    || (newProductLot.Device_Expiration_Date__c != oldProductLot.Device_Expiration_Date__c)
                    || (newProductLot.Device_Expiration_Date_NA__c != oldProductLot.Device_Expiration_Date_NA__c) 
                    || (newProductLot.Device_Expiration_Date_Unknown__c != oldProductLot.Device_Expiration_Date_Unknown__c))
                    && TicketQDNumMDCCustom.hasMedEval == true 
                    && TicketQDNumMDCCustom.isTicketOverallReportable == true;
        }
        return false;
    }
}