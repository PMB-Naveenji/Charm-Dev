/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : ForgotPasswordController.
* @Why   : Exposes the site forgot password functionality.
* @When  : 28-JAN-2019.
* @Where : From ForgotPassword page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    28-JAN-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    17-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ForgotPasswordController {
    public String username {get; set;}

    public ForgotPasswordController() {}

    /*
    * @Method       : forgotPassword.
    * @Description  : Navigates user to ForgotPasswordConfirm page.
    * @Invoke       : From ForgotPassword page.
    * @Return       : PageReference Page.ForgotPasswordConfirm.
    * @Params       : N/A.
    */
    public PageReference forgotPassword() {
        boolean success = Site.forgotPassword(username);
        PageReference pr = Page.ForgotPasswordConfirm;
        pr.setRedirect(true);

        if (success) {
            return pr;
        }
        return null;
    }
}