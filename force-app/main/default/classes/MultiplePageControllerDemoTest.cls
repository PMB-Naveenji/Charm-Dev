/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : MultiplePageControllerDemoTest.
* @Why   : MultiplePageControllerDemoTest test class for the MultiplePageControllerDemo class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    30-MAY-2019	          Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    21-AUG-2020            Code Audit           Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class MultiplePageControllerDemoTest {

    /*
    * @Method       : test.
    * @Description  : To test MultiplePageControllerDemo class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        MultiplePageControllerDemo controller = new MultiplePageControllerDemo();

        Test.startTest();
        controller.count = 1;
        PageReference result1 = controller.incrementCounter();
        controller.count = 10000;
        PageReference result2 = controller.incrementCounter();
        Test.stopTest();

        System.assertEquals(null, result2);
        System.assertNotEquals(result1, result2);
    }
}