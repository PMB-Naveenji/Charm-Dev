/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Trend_Item_Product_AuditTriggerTest.
* @Why   : To test functionality of Trend_Item_Product_AuditTrigger trigger.
* @When  : 05-JUN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    05-JUN-2019            Work ID / Case ID                               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    07-MAY-2020            Defect #96 (CHARM-2507 - Audit trail)           Updated.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    10-JUN-2020            N/A                                             Updated code part, which is related to Users' insertion.
*                                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                                                   deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid                   02-FEB-2021           Fixed Erorr                                    Updated Assertion Failed Error Fix 
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class Trend_Item_Product_AuditTriggerTest {
    private static final String THRESHOLDS = 'Thresholds';

    /*
    * @Method       : setup.
    * @Description  : Inserts test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;

        User ssTestUser = TestUtil.insertTestUser(aspenInteg, 'ssTestUser@test.com', 'ssTestUser@test.com');

        System.runAs(ssTestUser) {
            insert new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            );
        }
        String trendItemRTId = Schema.SObjectType.Trend_Item__c
                .getRecordTypeInfosByName()
                .get(THRESHOLDS)
                .getRecordTypeId();
        insert new Trend_Item__c(
                Trend_Item_Name__c = 'Test',
                Trend_Item_Type__c = 'Instruments',
                Process__c = THRESHOLDS,
                RecordTypeId = trendItemRTId
        );
        //CHARM-2507  start. Create audit trail config for object to track changes
        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
                new CMPL123__AuditTrail_Config__c(
                        CMPL123__Fields__c = 'Kit_Size__c,Sales_Flag__c',
                        CMPL123__Is_Active__c = true,
                        Name = 'Trend_Item_Product__c'),
                true);
        //CHARM-2507  end
    }

    /*
    * @Method       : testAuditTrail.
    * @Description  : To test the Trend_Item_Product_AuditTrigger for Defect #96 (CHARM-2507). Test if on create  and update audit trail entry is created.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testAuditTrail() {
        Trend_Item_Product__c trendItemProduct =  (Trend_Item_Product__c) TestDataFactory.createSObject(
                new Trend_Item_Product__c(Trend_Item__c = [SELECT Id FROM Trend_Item__c LIMIT 1].Id,
                        Kit_Size__c = '12',
                        Sales_Flag__c = true), true);
         // @Juneid, 02-feb-2021, Assert Updated
        System.assertEquals(2, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit trail entry record should be created');
        trendItemProduct.Sales_Flag__c = false;
        update trendItemProduct;
        System.assertEquals(1, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c where CMPL123__Action__c = 'Update'].size(), 'Audit trail entry record should be created');
    }

    /*
    * @Method       : test.
    * @Description  : Tests CUD operations of Trend_Item_Product__c.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        Trend_Item_Product__c trendItemProduct = new Trend_Item_Product__c(
                Product_Name__c  = [SELECT Id FROM CMPL123__Product__c LIMIT 1].Id,
                Trend_Item__c = [SELECT Id FROM Trend_Item__c LIMIT 1].Id
        );

        Test.startTest();
        insert trendItemProduct;
        UpdateParentUtility.flag = true;
        update trendItemProduct;
        delete trendItemProduct;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Trend_Item_Product__c]);
    }
}