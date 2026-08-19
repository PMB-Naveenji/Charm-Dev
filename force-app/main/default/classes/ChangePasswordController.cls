/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ChangePasswordController.
* @Why   : An apex page controller that exposes the change password functionality.
* @When  : 28-JAN-2019.
* @Where : From ChangePassword page
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 28-JAN-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                 18-AUG-2020            Code Audit                      Update comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        
    /*
    * @Method       : changePassword.
    * @Description  : To change password.
    * @Invoke       : From MyProfilePageController class, ChangePassword page, MyProfilePage page 
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public PageReference changePassword() {
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);    
    }
    /*
    * @Method       : Constructor.
    * @Description  : To set class Variables
    * @Invoke       : From MyProfilePageController class, ChangePassword page, MyProfilePage page 
    * @Return       : N/A.
    * @Params       : N/A.
    */     
    public ChangePasswordController() {}
}