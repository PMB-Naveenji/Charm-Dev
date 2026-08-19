/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDCountrySubmissionTypeHandlerTest.
* @Why   : ADDCountrySubmissionTypeHandlerTest test class for the ADDCountrySubmissionTypeHandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 N/A                 Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 28-JUL-2020         Code Audit                        Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class ADDCountrySubmissionTypeHandlerTest {
    /*
    * @Method       : testHandler.
    * @Description  : To test the ADDCountrySubmissionTypeHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void testHandler() {
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        objCountrySubmissionType.Name = '20 days';
        update objCountrySubmissionType;
        Country_Submission_Type__c objCountrySubmissionTypeUpdated = [
                SELECT Name
                FROM Country_Submission_Type__c
                WHERE Id = :objCountrySubmissionType.Id
        ];
        System.assertEquals('20 days', objCountrySubmissionTypeUpdated.name);
        delete objCountrySubmissionType;
        System.assert(0 == [SELECT COUNT() FROM Country_Submission_Type__c WHERE Id = : objCountrySubmissionType.Id]);
    }

}