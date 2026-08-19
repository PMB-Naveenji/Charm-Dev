/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : EmailsDeletionPageCtrlTest.
* @Why   : Test class for the EmailsDeletionPageCtrl class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                    Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                    02-JAN-2020             Storage Limit        Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020             Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-JUL-2020             Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class EmailsDeletionPageCtrlTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setup () {
        insert new EmailMessage(FromAddress = UserInfo.getUserEmail(), FromName = UserInfo.getName());
    }

    /*
    * @Method       : testBehavior.
    * @Description  : To test the EmailsDeletionPageCtrl.DeleteEmails functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void testBehavior () {
        EmailsDeletionPageCtrl edpCtrl = new EmailsDeletionPageCtrl ();
        Test.startTest();
        edpCtrl.DeleteEmails();
        Test.stopTest();
        System.assertEquals(0, database.countquery('SELECT COUNT() FROM EmailMessage WHERE CreatedById = \'' + UserInfo.getUserId() + '\''));
    }
}