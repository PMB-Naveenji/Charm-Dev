/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : MDIWorkflowActionMDCTest.
* @Why   : MDIWorkflowActionMDCTest test class for the MDIWorkflowActionMDC class.
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
private class MDIWorkflowActionMDCTest {

    /*
    * @Method       : test.
    * @Description  : To test the MDIWorkflowActionMDC class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        MDIWorkflowActionMDC controller = new MDIWorkflowActionMDC();

        Test.startTest();
        Boolean result = controller.customValidation(null, null);
        Test.stopTest();

        System.assertEquals(null, result);
    }
}