/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Trend_Item_Trend_Bucket_AuditTriggerTest.
* @Why   : To test functionality of Trend_Item_Trend_Bucket_AuditTrigger trigger.
* @When  : 31-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  31-MAY-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class Trend_Item_Trend_Bucket_AuditTriggerTest {
    /*
    * @Method       : triggerEventsTest.
    * @Description  : To test Trend_Item_Trend_Bucket_AuditTrigger functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void triggerEventsTest() {
        CMPL123CME__Complaint_Code__c ccode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint_Code__c(), true);

        String trendItemRTId = Schema.SObjectType.Trend_Item__c.getRecordTypeInfosByName().get('Thresholds').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(
                new Trend_Item__c(
                        Process__c = 'Thresholds',
                        RecordTypeId = trendItemRTId
                ), true);

        Trend_Item_Trend_Bucket__c trndBucket = (Trend_Item_Trend_Bucket__c) TestDataFactory.createSObject(
                new Trend_Item_Trend_Bucket__c(
                        Trend_Item__c = trendItem.Id,
                        Trend_Bucket_Code__c = ccode.Id), true);
        UpdateParentUtility.flag = true;
        update trndBucket;
        delete trndBucket;
        System.assert(0 == [SELECT COUNT() FROM Trend_Item_Trend_Bucket__c WHERE Id = :trndBucket.Id]);
    }
}