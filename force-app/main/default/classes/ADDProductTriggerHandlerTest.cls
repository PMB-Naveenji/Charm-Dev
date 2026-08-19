/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDProductTriggerHandlerTest.
* @Why   : ADDProductTriggerHandlerTest class for the ADDProductTriggerHandler class.
* @When  : 11-DEC-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                11-DEC-2018           Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                10-JUN-2020           N/A                       Updated code part, which is related to Users' insertion.
*                                                                      This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                      error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020           Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDProductTriggerHandlerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup() {
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

        User u = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
                LastName = 'last',
                Email = 'test@test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10',
                Username = 'test@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        //Create Product
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User ssTestUser = TestUtil.insertTestUser(aspenInteg, 'ssTestUser@test.com', 'ssTestUser@test.com');
        System.runAs(ssTestUser) {
            CMPL123__Product__c statusOpened = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c (
                    Name = 'TestProduct',
                    Reportable_Confirmed_Malfunction_Descrip__c = 'test'), true);
        }

    }

    /*
    * @Method       : updatingProduct.
    * @Description  : To test Product updating.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void updatingProduct() {
        User ssTestUser = [SELECT Id, Username, Profile_Name__c FROM User WHERE Username LIKE '%ssTestUser@test.com%'][0];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Business_Admin'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = ssTestUser.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;

        System.runAs(ssTestUser) {
            CMPL123__Product__c objProduct = [SELECT Id, Reportable_Confirmed_Malfunction_Descrip__c FROM CMPL123__Product__c LIMIT 1];
            objProduct.Reportable_Confirmed_Malfunction_Descrip__c = 'test123';
            TestDataFactory.updateSObject(objProduct);
            System.assertEquals('test123', [SELECT Id, Reportable_Confirmed_Malfunction_Descrip__c FROM CMPL123__Product__c LIMIT 1].Reportable_Confirmed_Malfunction_Descrip__c);
        }
    }
}