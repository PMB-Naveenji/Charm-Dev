/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDCountryBckupVigilanceContHandlerTest.
* @Why   : ADDCountryBckupVigilanceContHandlerTest test class for the ADDCountryBckupVigilanceContHandler class.
* @When  : 30-AUG-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                 Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                30-AUG-2018          Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                28-JUL-2020          Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                16-SEP-2020          Defect #27                    Added new test method to test Business Admin delete permission.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDCountryBckupVigilanceContHandlerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){
        //Country_Backup_Vigilance_Contact__c
        Country__c country = (Country__c) TestDataFactory.createSObject(new Country__c(Country_Region__c='Test'), true);
        Country_Backup_Vigilance_Contact__c vigContact = (Country_Backup_Vigilance_Contact__c)  TestDataFactory.createSObject(
                                                         new Country_Backup_Vigilance_Contact__c(Country__c=country.Id), true);
    }

    /*
    * @Method       : testCountryBackupVigilanceContact.
    * @Description  : To test the ADDCountryBckupVigilanceContHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testCountryBackupVigilanceContact(){
        Country__c con = [SELECT id FROM Country__c WHERE Country_Region__c='Test'];
        Country_Backup_Vigilance_Contact__c vigContact = [SELECT Id FROM Country_Backup_Vigilance_Contact__c WHERE Country__c= :con.Id];
        vigContact.Division__c='ADD';
        upsert vigContact;
        System.assertEquals(1, [SELECT Id FROM Country_Backup_Vigilance_Contact__c WHERE Country__c= :con.Id AND Division__c = 'ADD'].size());
        delete vigContact;
        System.assertEquals(new List<Country_Backup_Vigilance_Contact__c>(), [SELECT Id FROM Country_Backup_Vigilance_Contact__c WHERE Country__c= :con.Id AND Division__c = 'ADD']);
    }
	 /*
    * @Method       : testBADeletePermission.
    * @Description  : Defect #27. To test Business Admin permission to delete Country_Backup_Vigilance_Contact__c.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testBADeletePermission(){
        
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Business_Admin'];
        Profile aspenIntegProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];
        User baUser = TestUtil.insertTestUser(
            aspenIntegProfile.Id,
            'aspenBAUserTest@test.com',
            'aspenBAUserTest@test.com'
        );

        insert new PermissionSetAssignment(
            PermissionSetId = permSet.Id,
            AssigneeId = baUser.Id
        );
        Test.startTest();
        System.assertEquals(1, [SELECT Id, SobjectType, PermissionsCreate, PermissionsDelete, LastModifiedDate, Parent.Name 
                                FROM ObjectPermissions 
                                WHERE SobjectType = 'Country_Backup_Vigilance_Contact__c' and Parent.Name='Business_Admin'].size());
        System.runAs(baUser){
            Country__c country = (Country__c) TestDataFactory.createSObject(
                                                    new Country__c (Country_Region__c = 'Test123'), 
                                                    true);
            Country_Backup_Vigilance_Contact__c vigContact = (Country_Backup_Vigilance_Contact__c) TestDataFactory.createSObject(
                                                         new Country_Backup_Vigilance_Contact__c (Country__c = country.Id), 
                                                         true);
            System.assertEquals(1, [SELECT Id FROM Country_Backup_Vigilance_Contact__c WHERE Country__c =: country.Id].size(), 'Record should be created by user with BA permission set');
            delete vigContact;
            System.assertEquals(0, [SELECT Id FROM Country_Backup_Vigilance_Contact__c  WHERE Country__c =: country.Id].size(), 'Record should be deleted by user with BA permission set');
        }
        Test.stopTest();
    }
}