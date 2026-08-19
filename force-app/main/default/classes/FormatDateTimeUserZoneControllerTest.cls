/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : FormatDateTimeUserZoneControllerTest test class.
* @Why   : ormatDateTimeUserZoneControllerTest class for the FormatDateTimeUserZoneController.
* @When  : 15-DEC-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                 10-JUN-2020         N/A                               Updated code part, which is related
*                                                                             to Users' insertion. This change designed
*                                                                             to prevent a 'DUPLICATE_USERNAME' error during
*                                                                             deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                  17-AUG-2020        Code Audit                        Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class FormatDateTimeUserZoneControllerTest {

    /*
    * @Method       : testFormatDateTimeUserZoneController.
    * @Description  : To test the FormatDateTimeUserZoneController functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void testFormatDateTimeUserZoneController(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        //Create User
        User objUser = TestUtil.insertTestUser(profileId, 'aspeUserFDTZ@test.com', 'aspeUserFDTZ@test.com');
        objUser.Belongs_to_Text__c = 'Tran10';
        update objUser;

        system.runAs(objUser){
            FormatDateTimeUserZoneController objFormatDateTimeUserZoneController = New FormatDateTimeUserZoneController();
            // Test Case 1 : When there is no date passed
            system.assertEquals('', objFormatDateTimeUserZoneController.getFormattedDatetime());

            // Test Case 2 : When there is a date , but without format
            objFormatDateTimeUserZoneController.objDateTime = dateTime.valueOf('2018-12-15 00:00:00');
            system.assertEquals('12/15/2018 12:00 AM', objFormatDateTimeUserZoneController.getFormattedDatetime());

            // Test Case 3 : When there is a date and with format
            objFormatDateTimeUserZoneController.objDateTime = dateTime.valueOf('2018-12-15 00:00:00');
            objFormatDateTimeUserZoneController.strDefinedFormat = 'yyyy-dd-MM';
            system.assertEquals('2018-15-12', objFormatDateTimeUserZoneController.getFormattedDatetime());

        }
    }

}