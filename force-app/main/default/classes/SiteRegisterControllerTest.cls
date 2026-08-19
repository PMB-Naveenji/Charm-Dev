/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : SiteRegisterControllerTest.
* @Why   : To test functionality of 'SiteRegisterController' class.
* @When  : 28-JAN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  28-JAN-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oober                  10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                                   error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class SiteRegisterControllerTest {
    /*
    * @Method       : testRegistration.
    * @Description  : To test 'registerUser()' method.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest(SeeAllData=true)
    static void testRegistration() {
        SiteRegisterController controller = new SiteRegisterController();
        controller.username = 'test@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10);
        controller.email = 'test@test.com';
        controller.communityNickname = 'test';
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);

        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null);
    }
}