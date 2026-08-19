/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : MyProfilePageController.
* @Why   : An apex class that updates portal user details. Guest users are never able to access this page.
* @When  : 28-JAN-2019.
* @Where : From MyProfilePageController.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                Modification ID         Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    28-JAN-2019         Work ID / Case ID       Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    21-AUG-2020         Code Audit              Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class MyProfilePageController {

    private User user;
    private boolean isEdit = false;

    public User getUser() {
        return user;
    }

    /*
    * @Constructor  : MyProfilePageController.
    * @Invoke       : Upon class initialization.
    * @Description  : To run logic upon classin itialization.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public MyProfilePageController() {
        user = [SELECT id, email, username, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email
                FROM User
                WHERE id = :UserInfo.getUserId()];
        // guest users should never be able to access this page
        if (user.usertype == 'GUEST') {
            throw new NoAccessException();
        }
    }

    /*
    * @Method       : getIsEdit.
    * @Invoke       : N/A.
    * @Description  : Getter for isEdit field.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public Boolean getIsEdit() {
        return isEdit;
    }

    /*
    * @Method       : edit.
    * @Invoke       : From MyProfilePage page.
    * @Description  : Setter for isEdit field.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void edit() {
        isEdit=true;
    }

    /*
    * @Method       : save.
    * @Invoke       : From MyProfilePage page.
    * @Description  : Updates user.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void save() {
        try {
            update user;
            isEdit=false;
        } catch(DmlException e) {
            ApexPages.addMessages(e);
        }
    }

    /*
    * @Method       : changePassword.
    * @Invoke       : From MyProfilePage page.
    * @Description  : Navigates to ChangePassword page.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference changePassword() {
        return Page.ChangePassword;
    }

    /*
    * @Method       : cancel.
    * @Invoke       : From MyProfilePage page.
    * @Description  : Sets isEdit to false and reinitializes user.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void cancel() {
        isEdit=false;
        user = [SELECT id, email, username, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email
                FROM User
                WHERE id = :UserInfo.getUserId()];
    }
}