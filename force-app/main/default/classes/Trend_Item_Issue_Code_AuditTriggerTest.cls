/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Trend_Item_Issue_Code_AuditTriggerTest.
* @Why   : To test functionality of Trend_Item_Issue_Code_AuditTrigger trigger.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  30-MAY-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class Trend_Item_Issue_Code_AuditTriggerTest {
    /*
    * @Method       : test.
    * @Description  : To test Trend_Item_Issue_Code_AuditTrigger functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        String trendItemRTId = Schema.SObjectType.Trend_Item__c
                .getRecordTypeInfosByName()
                .get('Thresholds')
                .getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(
                new Trend_Item__c(
                        Process__c = 'Thresholds',
                        RecordTypeId = trendItemRTId,
                        Trend_Item_Type__c = 'Process'),
                true
        );
        Trend_Item_Issue_Code__c trendItemIssueCode = new Trend_Item_Issue_Code__c(Trend_Item__c = trendItem.Id);

        Test.startTest();
        insert trendItemIssueCode;
        update trendItemIssueCode;
        delete trendItemIssueCode;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Trend_Item_Issue_Code__c]);
    }
}