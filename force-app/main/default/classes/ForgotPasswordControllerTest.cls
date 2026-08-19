/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ForgotPasswordControllerTest.
* @Why   : ForgotPasswordControllerTest test class for the ForgotPasswordController class.
* @When  : 07-FEB-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 07-FEB-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 17-AUG-2020         Code Audit                        Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest public with sharing class ForgotPasswordControllerTest {

  /*
    * @Method       : testForgotPasswordController.
    * @Description  : To test the ForgotPasswordController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
  @IsTest(SeeAllData=true) public static void testForgotPasswordController() {
    // Instantiate a new controller with all parameters in the page
    ForgotPasswordController controller = new ForgotPasswordController();
    controller.username = 'test@salesforce.com';

    System.assertEquals(controller.forgotPassword(),null);
  }
}