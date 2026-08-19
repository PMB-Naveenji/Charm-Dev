/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TrendItemMaintenTrendBucketAuditTest.
* @Why   : To test functionality of Trend_Item_Maintenance_Trend_Bucket_AuditTrigger trigger.
* @When  : 05-JUN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  05-JUN-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
*                                                                                 This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                                 deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class TrendItemMaintenTrendBucketAuditTest {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        Profile standartUserProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
                Alias = 'standt',
                Email='raj@test.com',
                Belongs_to_Text__c = 'TIMRA9',
                Is_ooo__c = false,
                EmailEncodingKey='UTF-8',
                LastName='Testing1234',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = standartUserProfile.Id,
                TimeZoneSidKey='America/Los_Angeles',
                Username='hiii@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        );

        insert testUser;

        RecordType trendItemRecordType = [
                SELECT Id
                FROM RecordType
                WHERE SobjectType = 'Trend_Item_Maintenance_Request__c'
                        AND DeveloperName = 'Add_Trend_Item'
        ];
        Trend_Item__c trendItemRecord = (Trend_Item__c) TestDataFactory.createSObject(new Trend_Item__c(Trend_Item_Name__c = 'Test'), true);
        insert new Trend_Item_Maintenance_Request__c(
                Trend_Item__c =trendItemRecord.Id,
                Trend_Item_Name__c = 'Test',
                Division__c = 'ADD',
                CMPL123_WF_Action__c = 'Submit',
                Assignee_Name__c = testUser.Id,
                RecordTypeId =trendItemRecordType.Id,
                Process__c = 'Thresholds',
                Trend_Item_Type__c = 'Assay',
                Has_Trend_Bucket_Child__c =false
        );
    }

    /*
    * @Method       : test.
    * @Description  : To test Trend_Item_Maintenance_Trend_Bucket_AuditTrigger functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        Trend_Item_Maintenance_Request__c trendItemMaintenanceRequestRecord = [
                SELECT Id
                FROM Trend_Item_Maintenance_Request__c
                LIMIT 1
        ];
        Trend_Item_Maintenance_Trend_Bucket__c trendItemMaintenanceTrendBucketRequest = new Trend_Item_Maintenance_Trend_Bucket__c (
                Division__c = 'ADD',
                Trend_Item_Maintenance_Request__c = trendItemMaintenanceRequestRecord.Id
        );

        Test.startTest();
        insert trendItemMaintenanceTrendBucketRequest;
        update trendItemMaintenanceTrendBucketRequest;
        delete trendItemMaintenanceTrendBucketRequest;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Trend_Item_Maintenance_Trend_Bucket__c]);
    }
}