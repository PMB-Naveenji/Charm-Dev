/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : FieldLevelPermissionsControllerDemoTest.
* @Why   : FieldLevelPermissionsControllerDemoTest test class for the FieldLevelPermissionsControllerDemo class.
* @When  : 27-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 27-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 17-AUG-2020         Code Audit                        Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class FieldLevelPermissionsControllerDemoTest {

    /*
    * @Method       : test.
    * @Description  : To test the FieldLevelPermissionsControllerDemo class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        String objectName = Attachment__c.class.getName();
        ApexPages.currentPage().getParameters().put('strObjectName', objectName);

        Test.startTest();
        FieldLevelPermissionsControllerDemo controller = new FieldLevelPermissionsControllerDemo();
        Test.stopTest();

        System.assertEquals(objectName, controller.strObjectName);
        System.assertNotEquals(null, controller.lstwrapFieldPermissions);
    }
}