/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : SiteLoginController.
* @Why   : To test 'SiteLoginController' class.
* @When  : 28-JAN-2019.
* @Where : From SiteLoginController.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    28-JAN-2019            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oober                    10-JUN-2020            N/A                           Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                                   error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
global with sharing class SiteLoginControllerTest {
    /*
    * @Method       : testSiteLoginController.
    * @Description  : To test 'login()' method.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest(SeeAllData=true)
    global static void testSiteLoginController () {
        // Instantiate a new controller with all parameters in the page
        SiteLoginController controller = new SiteLoginController ();
        controller.username = 'test@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10);
        controller.password = '123456';

        System.assertEquals(controller.login(),null);
    }
}