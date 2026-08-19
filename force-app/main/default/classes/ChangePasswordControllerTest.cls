/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ChangePasswordControllerTest.
* @Why   : ChangePasswordControllerTest test class for the ChangePasswordController class.
* @When  : 28-JAN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 28-JAN-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                 18-AUG-2020         Code Audit                        Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest public with sharing class ChangePasswordControllerTest {
    /*
    * @Method       : testChangePasswordController.
    * @Description  : To test the ChangePasswordController changePassword functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest(SeeAllData=true) public static void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        System.assertEquals(controller.changePassword(),null);                           
    }    
}