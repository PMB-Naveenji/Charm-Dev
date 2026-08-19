/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDCountryTriggerhandlerTest.
* @Why   : ADDCountryTriggerhandlerTest class for the ADDCountryTriggerhandler class.
* @When  : 15-DEC-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    15-DEC-2018            Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    30-APR-2020            Defects #81-87, 89         Modified.
*                                                 (CHARM-2474)
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    10-JUN-2020            N/A                        Updated code part, which is related to Users' insertion.
*                                                                            This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                            error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                 Updated Jira reference with reference from Defect Tracker.
*                                                                            Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    28-JUL-2020            Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDCountryTriggerhandlerTest {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup () {
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(
            new Country__c(Country_Region__c='Test',
            Primary_Vigilance_Contact__c = UserInfo.getUserId()
            ), true);
    }

    /*
    * @Method       : testADDCountryTriggerhandler.
    * @Description  : To test the ADDCountryTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDCountryTriggerhandler () {
        Country__c objCountry = [SELECT Id FROM Country__c WHERE Country_Region__c='Test'];
        objCountry.Country_Code__c = 'India';
        Update objCountry;
        System.assertEquals('India', [SELECT Id, Country_Code__c FROM Country__c WHERE Id =: objCountry.Id].Country_Code__c);
        delete objCountry;
    }

    /*
    * @Method       : beforeUpdateTest.
    * @Description  : To test the ADDCountryTriggerhandler auditing on before update functionality. Defects #81-87, 89 (CHARM-2478) test.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void beforeUpdateTest() {
        Test.startTest();
        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
               new CMPL123__AuditTrail_Config__c(
                       CMPL123__Fields__c = 'AE_Submission_Required__c,Country_Code__c,Country_Region_New__c,Country_Region__c,Death_Submission_Required__c,Language__c,NCA_Address__c,NCA_Name__c,Notified_Body_Task_Required__c,Submission_Required__c,Translations_Required_flag__c',
                       CMPL123__Is_Active__c = true,
                       Name = 'Country__c'),
               true);

        Country__c country = (Country__c) TestDataFactory.createSObject(
                new Country__c (
                        Name = 'test',
                        Primary_Vigilance_Contact__c = Userinfo.getUserId()
                ), true);
        country.Country_Region_New__c = 'ASIA-PAC';
        update country;
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c WHERE CMPL123__Action__c = 'Update'].size(), 'Audit trail entry record should be created');
    }
}