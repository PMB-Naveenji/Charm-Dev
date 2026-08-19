/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : SiteLoginController.
* @Why   : An apex page controller that exposes the site login functionality.
* @When  : 28-JAN-2019.
* @Where : From SiteLoginController.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    28-JAN-2019            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global with sharing class SiteLoginController {
    global String username {get; set;}
    global String password {get; set;}

    /*
    * @Method       : login.
    * @Description  : To handle a Page Reference.
    * @Invoke       : Events PageReference.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    global PageReference login() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        return Site.login(username, password, startUrl);
    }

    global SiteLoginController () {}
}