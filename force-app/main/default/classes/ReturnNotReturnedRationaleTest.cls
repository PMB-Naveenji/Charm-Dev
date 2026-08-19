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
* Admin                    06-SEP-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class ReturnNotReturnedRationaleTest {
    /**
    * @Method       : testCustomValidation
    * @Description  : To test the Return_AuditTrigger functionality.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    public static void testCustomValidation() {
        //TWD Upgrade BEGIN
        ReturnNotReturnedRationale mdcTrigger = new ReturnNotReturnedRationale();
        Return__c newRecord = new Return__c(Return_not_Returned_Rationale__c = 'New');
        Return__c oldRecord = new Return__c(Return_not_Returned_Rationale__c = 'Old');
        System.assertEquals(null, mdcTrigger.CustomValidation(oldRecord, newRecord));
        //TWD Upgrade END
    }
}