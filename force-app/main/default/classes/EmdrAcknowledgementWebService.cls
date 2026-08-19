/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : EmdrAcknowledgementWebService.
* @Why   : Handles all the customization involved on Action Task object.
* @When  : 29-MAR-2017.
* @Where : From EmdrAcknowledgementWebService class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                 Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    29-MAR-2017          Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020          Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020          Code Audit           Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-JUL-2020          Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
global class EmdrAcknowledgementWebService{

   /*
    * @Method       : validateEMDRAcknowledgement.
    * @Description  : This method calls the "AVE_EmdrAcknowledgementWebServiceHandler" class and get the EMDR Id.
    * @Invoke       : Events from TriggerHandler before insert.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    webService static String validateEMDRAcknowledgement(String acknowledgementType,String uniqueIdentifier){
        Map<String,EMDR_Integration__c> emdrIntegrationMap = EMDR_Integration__c.getAll();
        return ADD_EmdrAcknowledgementWebServiceHandler.validateEMDR(acknowledgementType,uniqueIdentifier,emdrIntegrationMap);
    }
}