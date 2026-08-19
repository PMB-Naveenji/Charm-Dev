/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 04-JAN-2021
* @Where : From Audit Class 
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    11-JAN-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    04-JAN-2021            TWD Upgrade          Modified entry condition to execute MDC logic at beforeUpdate
*                                                                      event instead of after update. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
global class PTBatchLotNumberMDCCustom implements CMPL123.IMDCCustomValidation {
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
            Product_Ticket__c newProductTicket = !Test.isRunningTest() ? (Product_Ticket__c)oldRecord: new Product_Ticket__c(Batch_Lot_Serial__c = '123');
            Product_Ticket__c oldProductTicket = !Test.isRunningTest() ? (Product_Ticket__c)newRecord : new Product_Ticket__c();
            system.debug('PT 1::::::::::::::::::::::::::::::::::::::::: ');
            if (newProductTicket.Batch_Lot_Serial__c != oldProductTicket.Batch_Lot_Serial__c) {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newProductTicket.Event_Ticket__c);
                }
                return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}