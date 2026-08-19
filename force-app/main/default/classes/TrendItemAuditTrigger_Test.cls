/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TrendItemAuditTrigger_Test.
* @Why   : TrendItemAuditTrigger_Test class is for Trend_Item_AuditTrigger.
* @When  : 18-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  18-OCT-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class TrendItemAuditTrigger_Test {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    public static void testTrendItemTrigger(){
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        // create Trend Item
        String trendItemRTId = Schema.SObjectType.Trend_Item__c.getRecordTypeInfosByName().get('Thresholds').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(new Trend_Item__c(
            Process__c = 'Thresholds',
            RecordTypeId = trendItemRTId
        ),true);
    }

    /*
    * @Method       : testDeleteTrendItem.
    * @Description  : To test delete audit trigger.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static testMethod void testDeleteTrendItem(){
        test.startTest();
        Trend_Item__c trendItem = [SELECT Id,Name,Process__c FROM Trend_Item__c WHERE Process__c = 'Thresholds' LIMIT 1];
        DELETE trendItem;

        System.assertEquals(0, [SELECT COUNT() FROM Trend_Item__c WHERE Process__c = 'Thresholds']);
        test.stopTest();
    }
}