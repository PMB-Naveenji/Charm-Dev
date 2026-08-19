/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ObjectlevelPermissionsControllerDemoTest.
* @Why   : ObjectlevelPermissionsControllerDemoTest test class for the ObjectlevelPermissionsControllerDemo class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 21-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ObjectlevelPermissionsControllerDemoTest {

    /*
    * @Method       : test.
    * @Description  : To test ObjectlevelPermissionsControllerDemo class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        Test.startTest();
        ObjectlevelPermissionsControllerDemo controller = new ObjectlevelPermissionsControllerDemo();
        Test.stopTest();

        System.assertEquals(false, controller.lstwrapObjectPermissions.isEmpty());
    }
}