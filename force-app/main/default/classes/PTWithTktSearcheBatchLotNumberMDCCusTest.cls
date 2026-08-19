/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : Test class.
* @Why   : To test PTWithTktSearcheBatchLotNumberMDCCustom class.
* @When  : 09-JUL-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                    09-JUL-2020            Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    14-JAN-2020            TWD Upgrade               Updated logic in class. TWD Upgrade issue related to MDCs generation.
* --------------------------------------------------------------------------------------------------------------------------------------
* Nicholas D Sutanto       7-FEB-2023             CHaRM R3.0                Fixed test by initializing static variables to false instead of null.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class PTWithTktSearcheBatchLotNumberMDCCusTest {
    /*
    * @Method       : test.
    * @Description  : Contains verification logic.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        PTWithTktSearcheBatchLotNumberMDCCustom mdcTrigger = new PTWithTktSearcheBatchLotNumberMDCCustom();

        // Added 7-FEB-2023: Initialized to false instead of leaving null
        TicketQDNumMDCCustom.hasActiveTicketSearch = false;
        TicketQDNumMDCCustom.isTicketInquiry = false;

        Product_Ticket__c newRecord = new Product_Ticket__c(Batch_Lot_Serial__c = null);
        Product_Ticket__c oldRecord = new Product_Ticket__c(Batch_Lot_Serial__c = 'test');

        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}