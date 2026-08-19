/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : FeedItem_AuditTriggerTest.
* @Why   : FeedItem_AuditTriggerTest test class for the FeedItem_AuditTrigger trigger.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 17-AUG-2020         Code Audit                        Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@IsTest
private class FeedItem_AuditTriggerTest {

    /*
    * @Method       : test.
    * @Description  : To test the FeedItem_AuditTrigger logic on insert, update and delete events .
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        FeedItem item = new FeedItem(
                Body = 'Test',
                ParentId = UserInfo.getUserId()
        );

        Test.startTest();
        insert item;
        update item;
        delete item;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM FeedItem]);
    }
}