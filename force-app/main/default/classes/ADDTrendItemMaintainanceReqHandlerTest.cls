/**
* @Who   : Copyright (c) 2018 - 2021  Sparta Systems, Inc.
* @why  : ADDTrendItemMaintainanceReqHandlerTest class for the Trend_Item_Maintenance_Request_AuditTrigger,
* @when : CreatedDate : 03-SEPTEMBER-2018         
* @what : Class to Handle Different scenarios from Trend_Item_Maintenance_Request_AuditTrigger.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID         Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                 03-SEPT-2018                                   Created
*      oivan				 26-FEB-2020		    CHARM-1859 (CR#1261)	Added testing for CR 1261
*      DSkak    	         10-JUN-2020	        N/A                     Updated code part, which is related to Users' insertion.
*                                                                           This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                           deployment to Production environment
*  --------------------------------------------------------------------------------------------------------------------------------------
*       oivan                31-DEC-2020            TWD Upgrade issue       Test logic of WF rules that were moved to code.
* --------------------------------------------------------------------------------------------------------------------------------------
*       RSlob                22-JAN-2020            Too many soql issue     Divided test logic of WF rules into two methods (one per record type).
* --------------------------------------------------------------------------------------------------------------------------------------
*       Dinesh Kumar         17-NOV-2023            CHaRM-R4/IPDR-571       Covered the code for new Workflow status "TIMR Pending Approval" And added Validations to
                                                                            check the users permission in "TIMR Approver Name" field.
* --------------------------------------------------------------------------------------------------------------------------------------
        
*       Dinesh Kumar         29-SEP-2024                                     updated the below methods:testWfLogicPrt1
                                                                                 tandTTaskApproverUserCannotApproveorReject
                                                                                 businessUserCannotApproveorReject
                                                                                 businessUserCanApproveorReject
                                                                                 tandTTaskApproverUserCanApproveorReject
                                                                                 validateDualPermissionUserTest2
                                                                                 validateDualPermissionUserTest1
                                                                                 businessAdminvalidateTIMRInsertUpdate
                                                                                 validateT_TCannotCreateThresholdTest
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ADDTrendItemMaintainanceReqHandlerTest {
/**
* @Method       :  
* @Description  :   To test the Trend_Item_Maintenance_Request_AuditTrigger functionality.
* @Return       : N/A
* @Params       : N/A
**/
    @TestSetup
    static void makeData(){
        User user = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'MainContact',
            Email = 'test2@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Username = 'test2@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);
        
        //Start - CHaRM-R4
        //Creating a test user 'BusinessAdmin'
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        User businessAdmin = TestUtil.insertTestUser(
                aspenUserProfileId,
                'BusinessAdmin@test.com',
                'BusinessAdmin@test.com'
        );
         //Creating a test user 'BusinessAdmin1'
        User businessAdmin1 = TestUtil.insertTestUser(
                aspenUserProfileId,
                'BusinessAdmin1@test.com',
                'BusinessAdmin1@test.com'
        );
        //Creating a test user 'T_TTaskApprover'
        User t_TTaskApprover = TestUtil.insertTestUser(
                aspenUserProfileId,
                'T_TTaskApprover@test.com',
                'T_TTaskApprover@test.com'
        );
         //Creating a test user 'T_TTaskApprover1'
        User t_TTaskApprover1 = TestUtil.insertTestUser(
                aspenUserProfileId,
                'T_TTaskApprover1@test.com',
                'T_TTaskApprover1@test.com'
        );
        //CHaRM R5: Start
        User dualPermissionUser = TestUtil.insertTestUser(
                aspenUserProfileId,
                'DualAdmin@test.com',
                'DualAdmin@test.com'
        );
        //CHaRM R5: End
        
        //Creating a system admin user 'systemAdmin'. This user will be used to assign permission sets to test user.
        Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User systemAdmin = TestUtil.insertTestUser(
                systemAdminProfileId,
                'systemAdminUsertest@test.com',
                'systemAdminUsertest@test.com'
        );
        
        //Fetch permission sets that are needed to be assigned to 'T_TTaskApprover' and 'businessAdmin'
        PermissionSet PS1 = [
            SELECT Id FROM PermissionSet
            WHERE Name= 'Business_Admin'
        ];
        
        PermissionSet PS2 = [
            SELECT Id FROM PermissionSet
            WHERE Name= 'T_T_Task_Approver'
        ];
        
        PermissionSet PS3 = [
            SELECT Id FROM PermissionSet
            WHERE Name= 'X123Compliance_Permission_Set_for_Platform_User'
        ];
        
        //Running as systemAdmin to assign PS to test user BusinessAdmin and T_TTaskApprover
        //This is to avoid Mixed DML excpetion as both setup and non-setup objects cannot be updated in same transaction.
        System.runAs(systemAdmin)
        {
            insert new permissionSetAssignment(
                AssigneeId = businessAdmin.Id,
                PermissionSetId = PS1.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = businessAdmin.Id,
                PermissionSetId = PS3.Id
            );
             insert new permissionSetAssignment(
                AssigneeId = businessAdmin1.Id,
                PermissionSetId = PS1.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = businessAdmin1.Id,
                PermissionSetId = PS3.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = t_TTaskApprover.Id,
                PermissionSetId = PS2.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = t_TTaskApprover.Id,
                PermissionSetId = PS3.Id
            );
            insert new permissionSetAssignment(
                AssigneeId = t_TTaskApprover1.Id,
                PermissionSetId = PS2.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = t_TTaskApprover1.Id,
                PermissionSetId = PS3.Id
            );
            //CHaRM R5- Start
           insert new permissionSetAssignment(
                AssigneeId = dualPermissionUser.Id,
                PermissionSetId = PS1.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = dualPermissionUser.Id,
                PermissionSetId = PS2.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = dualPermissionUser.Id,
                PermissionSetId = PS3.Id
            );
            //CHaRM R5 - End
        }
        //End - CHaRM-R4
    }

    @IsTest
    public static void testADDTrendItemMaintenanceReqHandler() {
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        User testUser = new User(
            Alias = 'standt',
            Email = 'raj@test.com',
            Belongs_to_Text__c = 'TIMRA9',
            Is_ooo__c = false,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing1234',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardUserProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'hiii@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        );

        insert testUser;

        RecordType testRecordTypes = [
                SELECT Id
                FROM RecordType
                WHERE SobjectType = 'Trend_Item_Maintenance_Request__c'
                        AND DeveloperName = 'Add_Trend_Item'
        ];
        Trend_Item__c trendItemRecord = (Trend_Item__c) TestDataFactory.createSObject(
                new Trend_Item__c(
                        Trend_Item_Name__c = 'Test',
                        Process__c = 'Thresholds',
                        Trend_Item_Type__c = 'Process'),
                true
        );
        User businessAdmin = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin@test.com'];//CHaRM-R4
        //CHaRM R5: Added the Dual permission user to Insert the TIMR record without Error
        User DualPermissionUser = [SELECT Id, Email FROM User WHERE Email =: 'DualAdmin@test.com'];
        System.runAs(DualPermissionUser) {
        Trend_Item_Maintenance_Request__c trendItemMaintenanceRequest = (Trend_Item_Maintenance_Request__c) TestDataFactory.createSObject(
                new Trend_Item_Maintenance_Request__c(
                        Trend_Item__c = trendItemRecord.Id,
                        Trend_Item_Name__c = 'Test',
                        Division__c = 'ADD',
                        CMPL123_WF_Action__c = 'Submit',
                        Assignee_Name__c = testUser.Id,
                    //CHaRM-R4: Added the TIMR Aprover name field since it is a required field
                        TIMR_Approver_Name__c = businessAdmin.Id,//CHaRM-R4
                        RecordTypeId = testRecordTypes.Id,
                        Process__c = 'Thresholds',
                        Trend_Item_Type__c = 'Assay',
                        Has_Trend_Bucket_Child__c = false),
                true
        );
        trendItemMaintenanceRequest.CMPL123_WF_Action__c = 'Submit a Request';

        try {
            update trendItemMaintenanceRequest;
        } catch (Exception E) {
            //Assert Error
        }


        Trend_Item_Maintenance_Trend_Bucket__c trendItemMaintenanceTrendBucketRequest = (Trend_Item_Maintenance_Trend_Bucket__c) TestDataFactory.createSObject(
                new Trend_Item_Maintenance_Trend_Bucket__c (
                        Division__c = 'ADD', Trend_Item_Maintenance_Request__c = trendItemMaintenanceRequest.Id),
                true
        );

        try {
            update trendItemMaintenanceRequest;
        } catch (Exception E) {
            //Assert Error
        }

        Trend_Item_Maintenance_Product__c trendItemMaintenanceProduct = (Trend_Item_Maintenance_Product__c) TestDataFactory.createSObject(
                new Trend_Item_Maintenance_Product__c (
                        Division__c = null,
                        Trend_Item_Maintenance_Request__c = trendItemMaintenanceRequest.Id),
                true
        );

        try {
            update trendItemMaintenanceRequest;
        } catch (Exception E) {
            //Assert Error
        }
        delete trendItemMaintenanceRequest;
        }
    }

    @IsTest
    static void validateUserForRejectFieldsTest() {
        Id aspenUser = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        User businessUser = TestUtil.insertTestUser(aspenUser, 'business@test.com', 'business@test.com');

        Id admin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User adminUser = TestUtil.insertTestUser(admin, 'admin@test.com', 'admin@test.com');

        CMPL123__WF_Action__c approveAction;
        Trend_Item__c trendItem;
        System.runAs(adminUser) {
            TestDataFactory.createSObject(new ADD_App_Settings__c(Restrict_Validation_Rules__c = false, SetupOwnerId = businessUser.Id), true);


            approveAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(new CMPL123__WF_Action__c(
                    Name = 'Approve',
                    CMPL123__Is_ESign_Required__c = false,
                    CMPL123__Is_Comment_Required__c = false
            ), true);

            String trendItemRTId = Schema.SObjectType.Trend_Item__c
                    .getRecordTypeInfosByName()
                    .get('Thresholds')
                    .getRecordTypeId();
            trendItem = (Trend_Item__c) TestDataFactory.createSObject(
                    new Trend_Item__c(
                            Process__c = 'Thresholds',
                            RecordTypeId = trendItemRTId,
                            Trend_Item_Type__c = 'Process'),
                    true
            );
        }

        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Business_Admin'];
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
                PermissionSetId = permissionSet.Id,
                AssigneeId = businessUser.Id
        );
        insert permissionSetAssignment;

        RecordType recordType = [SELECT Id
                                    FROM RecordType
                                    WHERE SobjectType = 'Trend_Item_Maintenance_Request__c'
                                    AND DeveloperName = 'Update_Trend_Item'];
        User businessAdmin = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin@test.com'];//CHaRM-R4

        Test.startTest();
        Trend_Item_Maintenance_Request__c timr;
        //CHaRM R5: Added the Dual permission user to Insert the TIMR record without Error
        User DualPermissionUser = [SELECT Id, Email FROM User WHERE Email =: 'DualAdmin@test.com'];
        System.runAs(DualPermissionUser) {
            timr = new Trend_Item_Maintenance_Request__c(
                    Assignee_Name__c = businessUser.Id,
                //CHaRM-R4: Added the TIMR Aprover name field since it is a required field
                    TIMR_Approver_Name__c = businessAdmin.Id,//CHaRM-R4
                    Trend_Item_Name__c = 'Test',
                    Process__c = 'Thresholds',
                    Trend_Item_Type__c = 'Process',
                    RecordType = recordType,
                    Division__c = 'ADD',
                    Has_Trend_Bucket_Child__c = false,
                    CMPL123_WF_Status__c = 'Pending Implementation'
            );
            insert timr;
        }

        System.runAs(businessUser) {
            try {
                timr.Reject_Reason__c = 'test';
                timr.Rejected_By__c = 'test';
                timr.Rejected_On__c = Date.today();
                timr.CMPL123_WF_Action__c = approveAction.Id;
                timr.CMPL123_WF_Status__c = 'Pending Approval';
                timr.CMPL123_WF_Action_Performed_On__c = Date.today();
                timr.CMPL123Rule_Key_Value__c = 'test';
                timr.Trend_Item__c = trendItem.Id;
                timr.Assignee_Name__c = adminUser.Id;
                update timr;
            } catch (DmlException e) {
                System.assertEquals('Record is locked for you.', e.getDmlMessage(0));
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION',e.getDmlStatusCode(0));
            }
        }
        Test.stopTest();
    }
    //CHaRM R5: (Start)
     /**
	* @Method       : validateT_TCannotCreateThresholdTest
	* @Description  : T/T Task Appover permission access cannot insert a Threshold process type but can insert a Ticket T/t process type 
	* @Return       : N/A
	* @Params       : N/A
	**/ 
    @IsTest
    static void validateT_TCannotCreateThresholdTest() {
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];
        RecordType recordType = [SELECT Id
                                    FROM RecordType
                                    WHERE SobjectType = 'Trend_Item_Maintenance_Request__c'
                                    AND DeveloperName = 'Update_Trend_Item'];

        Test.startTest();
        System.runAs(t_TTaskApprover) {
            try {
                Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Thresholds',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                               Assignee_Name__c = UserInfo.getUserId()
                                                                               
                                                                              ), true);
            }
            catch (Exception e) {
                //CHaRM R5:  To verify that T&T Task Appover permission access user cannot Insert a TIMR record with 'Thresholds'  process type TIMR record.
                 System.assert( e.getMessage().contains(System.Label.OnlyBusinessAdminCanCreateThreshold), 'Error should be shown because the business admin can approve a threshold process type');
            }
             insert new Trend_Item_Maintenance_Request__c(
                        Assignee_Name__c = t_TTaskApprover.Id,
                        Trend_Item_Name__c = 'TestApprover',
                        Process__c = 'Ticket T/T',
                        Trend_Item_Type__c = 'Assay',
                        RecordType = recordType,
                        Division__c = 'ADD',
                        Has_Trend_Bucket_Child__c = false,
                        CMPL123_WF_Status__c = 'Opened'
                );
            //CHaRM R5: To verify that T&T Task Appover permission access user can Insert a TIMR record with 'Ticket T/T'  process type TIMR record.
            System.assertEquals('TestApprover',[SELECT ID, Trend_Item_Name__c FROM Trend_Item_Maintenance_Request__c].Trend_Item_Name__c);
        }
        
        Test.stopTest();
    }
     /**
	* @Method       : businessAdminvalidateTIMRInsertUpdate
	* @Description  : Business Admin permission access can insert a Threshold process type but cannot insert a Ticket T/t process type
	* @Return       : N/A
	* @Params       : N/A
	**/ 
     @IsTest
    static void businessAdminvalidateTIMRInsertUpdate() {
       // User approverUser = TestUtil.insertTestUser(aspenUser, 'approver@test.com', 'approver@test.com');
        User businessAdmin = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin@test.com'];
        RecordType recordType = [SELECT Id
                                    FROM RecordType
                                    WHERE SobjectType = 'Trend_Item_Maintenance_Request__c'
                                    AND DeveloperName = 'Update_Trend_Item'];

        Test.startTest();
        System.runAs(businessAdmin) {
            try {
                insert new Trend_Item_Maintenance_Request__c(
                        Assignee_Name__c = businessAdmin.Id,
                        Trend_Item_Name__c = 'Test',
                        Process__c = 'Ticket T/T',
                        Trend_Item_Type__c = 'Process',
                        RecordType = recordType,
                        Division__c = 'ADD',
                        Has_Trend_Bucket_Child__c = false,
                        CMPL123_WF_Status__c = 'Opened'
                );
            }
            catch (Exception e) {
                //CHaRM R5: To verify that Business Admin permission access user cannot Insert a TIMR record with 'Ticket T/T' process type TIMR record.
               System.assert( e.getMessage().contains(System.Label.OnlyTTTaskApproverOrTTTaskReviewerCancreateTicketTTSubmissionTT), 'Error should be shown because the business admin cannot approve a TicketT/T process type');
            }
            insert new Trend_Item_Maintenance_Request__c(
                        Assignee_Name__c = businessAdmin.Id,
                        Trend_Item_Name__c = 'TestBusiness',
                        Process__c = 'Thresholds',
                        Trend_Item_Type__c = 'Process',
                        RecordType = recordType,
                        Division__c = 'ADD',
                        Has_Trend_Bucket_Child__c = false,
                        CMPL123_WF_Status__c = 'Opened'
                );
            //CHaRM R5:To verify that Business Admin permission access user can Insert a TIMR record with 'Thresholds'  process type TIMR record.
            System.assertEquals('TestBusiness',[SELECT ID, Trend_Item_Name__c FROM Trend_Item_Maintenance_Request__c].Trend_Item_Name__c);
        }                        
        Test.stopTest();
    }

    /**
	* @Method       : validateDualPermissionUserTest1
	* @Description  : Dual Permission user with T/T Task Appover and Business Admin permission access can approve or reject a TIMR record with 'Ticket T/T' process type 
	* @Return       : N/A
	* @Params       : N/A
	**/  
     @IsTest
     static void validateDualPermissionUserTest1() {
        User dualUser = [SELECT Id, Email FROM User WHERE Email =: 'DualAdmin@test.com' LIMIT 1];
        System.runAs(dualUser) {
        Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Ticket T/T',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                                Assignee_Name__c = UserInfo.getUserId()
                                                                              
                                         ), true);
        //Check the Assert for 'TIMR Approved On & TIMR Approved By' is auto-populated and 'TIMR Rjected On & TIMR Rejected By' as null when 'TIMR Approve' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Approve';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Approved_By__c, 'TIMR Approve by, should be autopopulated');
        System.assertEquals(date.today(), timr.TIMR_Approved_On__c );
        System.assertEquals(null, timr.TIMR_Rejected_By__c );
        System.assertEquals(null, timr.TIMR_Rejected_On__c ); 
        
        //Check the Assert for 'TIMR Rjected On & TIMR Rejected By' is auto-populated and TIMR Approved By and TIMR Approved On is Blanked out when 'TIMR Reject' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Reject';
        timr.TIMR_Rejection_Rationale__c = 'Test';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Rejected_By__c );
        System.assertEquals(date.today(), timr.TIMR_Rejected_On__c ); 
        System.assertEquals(null, timr.TIMR_Approved_By__c);
        System.assertEquals(null, timr.TIMR_Approved_On__c); 
        }             
    } 
     /**
	* @Method       : validateDualPermissionUserTest2
	* @Description  : Dual Permission user with T/T Task Appover and Business Admin permission access can approve or reject a TIMR record with 'Thresholds' process type
	* @Return       : N/A
	* @Params       : N/A
	**/  
     @IsTest
     static void validateDualPermissionUserTest2() {
        User dualUser = [SELECT Id, Email FROM User WHERE Email =: 'DualAdmin@test.com' LIMIT 1];
        System.runAs(dualUser) {
        Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Thresholds',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                                Assignee_Name__c = UserInfo.getUserId()
                                                                              
                                         ), true);
        //Check the Assert for 'TIMR Approved On & TIMR Approved By' is auto-populated and 'TIMR Rjected On & TIMR Rejected By' as null when 'TIMR Approve' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Approve';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Approved_By__c, 'TIMR Approve by, should be autopopulated');
        System.assertEquals(date.today(), timr.TIMR_Approved_On__c );
        System.assertEquals(null, timr.TIMR_Rejected_By__c );
        System.assertEquals(null, timr.TIMR_Rejected_On__c ); 
        
        //Check the Assert for 'TIMR Rjected On & TIMR Rejected By' is auto-populated and TIMR Approved By and TIMR Approved On is Blanked out when 'TIMR Reject' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Reject';
        timr.TIMR_Rejection_Rationale__c = 'Test';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Rejected_By__c );
        System.assertEquals(date.today(), timr.TIMR_Rejected_On__c ); 
        System.assertEquals(null, timr.TIMR_Approved_By__c);
        System.assertEquals(null, timr.TIMR_Approved_On__c); 
        }             
    }         
     /**
	* @Method       : tandTTaskApproverUserCanApproveorReject
	* @Description  : T/T Task Appover permission access can approve or reject a TIMR record with 'Ticket T/T' process type
	* @Return       : N/A
	* @Params       : N/A
	**/ 
     @IsTest
     static void tandTTaskApproverUserCanApproveorReject() {
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];
        System.runAs(t_TTaskApprover) {
        Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Ticket T/T',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                                Assignee_Name__c = UserInfo.getUserId()
                                                                              
                                         ), true);
        //Check the Assert for 'TIMR Approved On & TIMR Approved By' is auto-populated and 'TIMR Rjected On & TIMR Rejected By' as null when 'TIMR Approve' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Approve';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c, TIMR_Rejection_Rationale__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Approved_By__c, 'TIMR Approve by, should be autopopulated');
        System.assertEquals(date.today(), timr.TIMR_Approved_On__c );
        System.assertEquals(null, timr.TIMR_Rejected_By__c );
        System.assertEquals(null, timr.TIMR_Rejected_On__c ); 
        System.assertEquals(null,timr.TIMR_Rejection_Rationale__c );
        
        //Check the Assert for 'TIMR Rjected On & TIMR Rejected By' is auto-populated and TIMR Approved By and TIMR Approved On is Blanked out when 'TIMR Reject' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Reject';
        timr.TIMR_Rejection_Rationale__c = 'Test';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Rejected_By__c );
        System.assertEquals(date.today(), timr.TIMR_Rejected_On__c ); 
        System.assertEquals(null, timr.TIMR_Approved_By__c);
        System.assertEquals(null, timr.TIMR_Approved_On__c); 
        }            
    } 
   /**
	* @Method       : businessUserCanApproveorReject
	* @Description  : Business Admin permission access can approve or reject a TIMR record with 'Thresholds' process type
	* @Return       : N/A
	* @Params       : N/A
	**/  
     @IsTest
     static void businessUserCanApproveorReject() {
        User businessAdmin = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin@test.com'];
        System.runAs(businessAdmin) {
        Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Thresholds',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                                Assignee_Name__c = UserInfo.getUserId()
                                                                              
                                         ), true);
        //Check the Assert for 'TIMR Approved On & TIMR Approved By' is auto-populated and 'TIMR Rjected On & TIMR Rejected By' as null when 'TIMR Approve' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Approve';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c, TIMR_Rejection_Rationale__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Approved_By__c, 'TIMR Approve by, should be autopopulated');
        System.assertEquals(date.today(), timr.TIMR_Approved_On__c );
        System.assertEquals(null, timr.TIMR_Rejected_By__c );
        System.assertEquals(null, timr.TIMR_Rejected_On__c );
        System.assertEquals(null,timr.TIMR_Rejection_Rationale__c );
        //Check the Assert for 'TIMR Rjected On & TIMR Rejected By' is auto-populated and TIMR Approved By and TIMR Approved On is Blanked out when 'TIMR Reject' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Reject';
        timr.TIMR_Rejection_Rationale__c = 'Test';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Rejected_By__c );
        System.assertEquals(date.today(), timr.TIMR_Rejected_On__c ); 
        System.assertEquals(null, timr.TIMR_Approved_By__c);
        System.assertEquals(null, timr.TIMR_Approved_On__c); 
        }             
    }         
   /**
	* @Method       : businessUserCannotApproveorReject
	* @Description  : Business Admin permission access cannot approve or reject a TIMR record with 'Ticket T/T' process type
	* @Return       : N/A
	* @Params       : N/A
	**/   
     @IsTest
     static void businessUserCannotApproveorReject() {
         User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];
        User businessAdmin = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin@test.com'];
        System.runAs(t_TTaskApprover) {
        Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
      
            Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Ticket T/T',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test for TIMR',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                               CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                               CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                               Assignee_Name__c = UserInfo.getUserId()
                                                                               
                                                                              ), true);
       
            //Check the Assert that Business admin user cannot approve or reject a TIMR record with 'Ticket T/T' process type
            System.runAs(businessAdmin) {
                 Trend_Item_Maintenance_Request__c timr1 = [SELECT Id, Process__c, CMPL123_WF_Action__c,Trend_Item_Name__c FROM Trend_Item_Maintenance_Request__c WHERE Trend_Item_Name__c = 'Test for TIMR'];
                try{
                    timr1.CMPL123_WF_Action__c = 'TIMR Approve';
                    update timr1; 
                }            
                catch (Exception e) {
                    //Check the Assert if the Process type is Ticket T/T then the TIMR Approver Name should be T&T Task Approver or else throw Error
                    System.assert( e.getMessage().contains(System.Label.OnlyTTTaskApproverOrTTTaskReviewerCancreateTicketTTSubmissionTT), 'Error should be shown because the business admin cannot approve a TicketT/T process type');
                }   
                
                //Check the Assert that Business admin user cannot approve or reject a TIMR record with 'Ticket T/T' process type
                try{
                    timr1.CMPL123_WF_Action__c = 'TIMR Reject';
                    timr1.TIMR_Rejection_Rationale__c = 'Test';
                    update timr1;
                }          
                catch (Exception e) {
                    //Check the Assert if the Process type is Ticket T/T then the TIMR Approver Name should be T&T Task Approver or else throw Error
                    System.assert( e.getMessage().contains(System.Label.OnlyTTTaskApproverOrTTTaskReviewerCancreateTicketTTSubmissionTT), 'Error should be shown because the business admin cannot reject a TicketT/T process type');
                }
            } 
        }
     } 
    /**
	* @Method       : tandTTaskApproverUserCannotApproveorReject
	* @Description  : T&T Task Approver permission access user cannot approve or reject a TIMR record with 'Ticket T/T' process type
	* @Return       : N/A
	* @Params       : N/A
	**/    
     @IsTest
     static void tandTTaskApproverUserCannotApproveorReject() {
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];
         User businessAdmin = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin@test.com'];
        System.runAs(businessAdmin) {
        Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Thresholds',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                               Assignee_Name__c = UserInfo.getUserId()
                                                                               
                                                                              ), true);
            System.runAs(t_TTaskApprover) {
                //Check the Assert that Business admin user cannot approve or reject a TIMR record with 'Ticket T/T' process type
                try{
                    timr.CMPL123_WF_Action__c = 'TIMR Approve';
                    update timr; 
                }            
                catch (Exception e) {
                    //Check the Assert if the Process type is Ticket T/T then the TIMR Approver Name should be T&T Task Approver or else throw Error
                    System.assert( e.getMessage().contains(System.Label.OnlyBusinessAdminCanCreateThreshold), 'Error should be shown because the business admin cannot approve a TicketT/T process type');
                }        
                //Check the Assert that Business admin user cannot approve or reject a TIMR record with 'Ticket T/T' process type
                try{
                    timr.CMPL123_WF_Action__c = 'TIMR Reject';
                    timr.TIMR_Rejection_Rationale__c = 'Test';
                    update timr;
                }          
                catch (Exception e) {
                    //Check the Assert if the Process type is Ticket T/T then the TIMR Approver Name should be T&T Task Approver or else throw Error
                    System.assert( e.getMessage().contains(System.Label.OnlyBusinessAdminCanCreateThreshold), 'Error should be shown because the business admin cannot reject a TicketT/T process type');
                }
            }      
        }
     } 
    //CHaRM R5: END
    /**
	* @Method       : timrCreationWithoutProductsForUpdateTrendItemTest
	* @Description  : Test logic for Update Trend Item. Error message should not be shown even when there is no Products. 
	* @Return       : N/A
	* @Params       : N/A
	**/ 
    // CR 1261 start
    @isTest
    public static void timrCreationWithoutProductsForUpdateTrendItemTest (){
        User user = [SELECT Id FROM User WHERE Email = 'test2@test.com'];
        String timrRecordTypeId = Schema.SObjectType.Trend_Item_Maintenance_Request__c
                .getRecordTypeInfosByName()
                .get('Update Trend Item')
                .getRecordTypeId();
        //CHaRM-R4
        String timrRecordTypeId1 = Schema.SObjectType.Trend_Item_Maintenance_Request__c
                .getRecordTypeInfosByName()
                .get('Add Trend Item')
                .getRecordTypeId();//END
        sObject trendItemObj = Schema.getGlobalDescribe().get('Trend_Item__c').newSObject() ;
        trendItemObj.put('CMPL123_WF_Status__c', 'Opened');
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(trendItemObj, true);
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];//CHaRM-R4
        //CHaRM R5: Added the Dual permission user to Insert the TIMR record without Error
        User DualPermissionUser = [SELECT Id, Email FROM User WHERE Email =: 'DualAdmin@test.com'];
        System.runAs(DualPermissionUser) {
        sObject timrObj = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Request__c').newSObject() ;
        timrObj.put('CMPL123_WF_Status__c', 'Opened');
        timrObj.put('RecordTypeId', timrRecordTypeId);
        timrObj.put('Trend_Item__c', trendItem.Id);
        timrObj.put('Assignee_Name__c', user.Id);
        timrObj.put('TIMR_Approver_Name__c', t_TTaskApprover.Id);//CHaRM-R4 Added TIMR Approver Name.
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(timrObj, true);
        timr.CMPL123_WF_Status__c = 'In Progress';
        timr.CMPL123_WF_Action__c = 'Submit a Request';
        update timr;
        System.assertEquals('In Progress', [Select Id, CMPL123_WF_Status__c from Trend_Item_Maintenance_Request__c].CMPL123_WF_Status__c, 'Status should be changed without error');
         // CHaRM-R4 Start
        User businessAdmin = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin@test.com'];
        RecordType recordType = [SELECT Id
                                 FROM RecordType
                                 WHERE SobjectType = 'Trend_Item_Maintenance_Request__c'
                                 AND DeveloperName = 'Update_Trend_Item'];
        try {
            timr.TIMR_Approver_Name__c = businessAdmin.Id;
            timr.Trend_Item_Name__c = 'Test';
            timr.Process__c = 'Ticket T/T';
            timr.Trend_Item_Type__c = 'Process';
            timr.RecordType = recordType;
            timr.CMPL123_WF_Status__c = 'In Progress';
            timr.CMPL123_WF_Action__c = 'Submit a Request';
            
            update timr;
            
        } catch (Exception e) {
            //Check the Assert if the Process type is Ticket T/T then the TIMR Approver Name should be T&T Task Approver or else throw Error
            System.assert( e.getMessage().contains(System.Label.TIMR_Approver_Name_T_T_Approver), 'Error should be shown because the TIMR Approver name has wrong user');
        }
        try {
            timr.TIMR_Approver_Name__c = t_TTaskApprover.Id;
            timr.Trend_Item_Name__c = 'Test';
            timr.Process__c = 'Thresholds';
            timr.Trend_Item_Type__c = 'Process';
            timr.RecordType = recordType;
            
            update timr;
            
        } catch (Exception e) {
            //Check the Assert if the Process type is Thresholds then the TIMR Approver Name should be Business Admin or else throw Error
            System.assert( e.getMessage().contains(System.Label.TIMR_Approver_Name_Business_Admin), 'Error should be shown because the TIMR Approver name has wrong user');
        }
        try {
            timr.Trend_Item_Name__c = 'Test';
            timr.Process__c = 'Ticket T/T';
            timr.Trend_Item_Type__c = 'Process';
            timr.RecordType = recordType;
            timr.CMPL123_WF_Status__c = 'In Progress';
            timr.CMPL123_WF_Action__c = 'Submit a Request';                        
            timr.TIMR_Approver_Name__c = t_TTaskApprover.Id;
            
            update timr;
            
        } catch (Exception e) {
            //Check the Assert if the TIMR Approver Name is populated with wrong user then throw Error
            System.assert( e.getMessage().contains(System.Label.TIMR_Approver_Name_Is_Not_BussinessAdmin_Or_T_T_TaskApprover), 'Error should be shown because the TIMR Approver name has wrong user');
        }
        try {
            sObject timrObj1 = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Request__c').newSObject() ;
            timrObj1.put('CMPL123_WF_Status__c', 'Opened');
            timrObj1.put('RecordTypeId', timrRecordTypeId1);
            timrObj1.put('Trend_Item__c', trendItem.Id);
            timrObj1.put('Assignee_Name__c', user.Id);
            timrObj1.put('TIMR_Approver_Name__c', t_TTaskApprover.Id);
            timrObj1.put('Process__c', 'Thresholds');
            timrObj1.put('Trend_Item_Name__c', 'Test');
            timrObj1.put('Trend_Item_Type__c', 'Process');
            timrObj1.put('Trend_Item_Description__c', 'Process');
            timrObj1.put('Trend_Item_Evaluation_Location__c', 'Dallas, Texas');
            timrObj1.put('Request_Reason__c', 'test');
            timrObj1.put('Sector__c', 'CC-DA-TPM-Alinity C');
            timrObj1.put('Request_Justification__c', 'test');
            Trend_Item_Maintenance_Request__c timr1 = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(timrObj1, true);
            insert timr1;
        } catch (Exception e) {
            //Check the Assert if the Process type is Thresholds then the TIMR Approver Name should be Business Admin or else throw Error
            System.assert( e.getMessage().contains(System.Label.TIMR_Approver_Name_Business_Admin), 'Error should be shown because the TIMR Approver name has wrong user');
        }
        try {
            sObject timrObj2 = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Request__c').newSObject() ;
            timrObj2.put('CMPL123_WF_Status__c', 'Opened');
            timrObj2.put('RecordTypeId', timrRecordTypeId);
            timrObj2.put('Trend_Item__c', trendItem.Id);
            timrObj2.put('Assignee_Name__c', user.Id);
            timrObj2.put('TIMR_Approver_Name__c', businessAdmin.Id);
            timrObj2.put('Process__c', 'Ticket T/T');
            Trend_Item_Maintenance_Request__c timr2 = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(timrObj2, true);
            insert timr2;
        } catch (Exception e) {
            //Check the Assert if the Process type is Ticket T/T then the TIMR Approver Name should be T&T Task Approver or else throw Error
            System.assert( e.getMessage().contains(System.Label.TIMR_Approver_Name_T_T_Approver), 'Error should be shown because the TIMR Approver name has wrong user');
        }
            User adminUser = [SELECT Id, Email FROM User WHERE Email =: 'systemAdminUsertest@test.com'];
        try {
            sObject timrObj3 = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Request__c').newSObject() ;
            timrObj3.put('CMPL123_WF_Status__c', 'Opened');
            timrObj3.put('RecordTypeId', timrRecordTypeId);
            timrObj3.put('Trend_Item__c', trendItem.Id);
            timrObj3.put('Assignee_Name__c', user.Id);
            timrObj3.put('TIMR_Approver_Name__c', adminUser.Id);
            timrObj3.put('Process__c', 'Ticket T/T');
            Trend_Item_Maintenance_Request__c timr3 = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(timrObj3, true);
            insert timr3;
        } catch (Exception e) {
            //Check the Assert if the TIMR Approver Name is populated with wrong user then throw Error
            System.assert( e.getMessage().contains(System.Label.TIMR_Approver_Name_Is_Not_BussinessAdmin_Or_T_T_TaskApprover), 'Error should be shown because the TIMR Approver name has wrong user');
        }
        //CHaRM-R4-End
        }
    }

    /**
	* @Method       : timrCreationWithoutProductsForUpdateTrendItemTest
	* @Description  : Test logic for Update Trend Item. Error message should not be shown even when there is no Products. 
	* @Return       : N/A
	* @Params       : N/A
	**/ 
    @isTest
    public static void timrCreationWithoutProductsForAddTrendItemTest (){
        User user = [SELECT Id FROM User WHERE Email = 'test2@test.com'];
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];//CHaRM-R4
        String timrRecordTypeId = Schema.SObjectType.Trend_Item_Maintenance_Request__c
                .getRecordTypeInfosByName()
                .get('Add Trend Item')
                .getRecordTypeId();
        sObject trendItemObj = Schema.getGlobalDescribe().get('Trend_Item__c').newSObject() ;
        trendItemObj.put('CMPL123_WF_Status__c', 'Opened');
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(trendItemObj, true);
        //CHaRM R5: Added the T/T Task approver user to Insert the Ticket T/T process TIMR record without Error
        User t_TTaskApprover1 = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover1@test.com'];//CHaRM-R4
        System.runAs(t_TTaskApprover1) {
        sObject timrObj = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Request__c').newSObject() ;
        timrObj.put('CMPL123_WF_Status__c', 'Opened');
        timrObj.put('RecordTypeId', timrRecordTypeId);
        timrObj.put('Process__c', 'Ticket T/T');
        timrObj.put('Trend_Item__c', trendItem.Id);
        timrObj.put('Trend_Item_Name__c', 'Test');
        timrObj.put('Trend_Item_Type__c', 'Process');
        timrObj.put('Has_Product_Child__c', true);
        timrObj.put('Assignee_Name__c', user.Id);
        //CHaRM-R4: Added the TIMR Aprover name field since it is a required field
        timrObj.put('TIMR_Approver_Name__c', t_TTaskApprover.Id);//CHaRM-R4
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(timrObj, true);
        timr.CMPL123_WF_Status__c = 'In Progress';
        timr.CMPL123_WF_Action__c = 'Submit a Request';

        Boolean hasErrors = false;
        try {
            update timr;
        } catch (Exception e) {
            System.assert( e.getMessage().contains(System.Label.Trend_Item_Maintenance_Request_Product_Error), 'Error should be shown because no product was created');
            hasErrors = true;
        }
        
        System.assertEquals(true, hasErrors, 'Error should appear');
        System.assertEquals('Opened', [Select Id, CMPL123_WF_Status__c from Trend_Item_Maintenance_Request__c].CMPL123_WF_Status__c, 'Status should be changed without error');
        }
    }
    // CR 1261 end
    /*
    * @Method       : testWfLogicPrt1.
    * @Description  : TWD Upgrade issue. To test logic from disabled WF rules.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testWfLogicPrt1 () {
        Id inactiveTrendItemRecType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Inactivate Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];//CHaRM-R4
        User DualPermissionUser = [SELECT Id, Email FROM User WHERE Email =: 'DualAdmin@test.com'];
        System.runAs(DualPermissionUser) {
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = inactiveTrendItemRecType,
                                                                                Process__c = 'Ticket T/T',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'TestDual',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                Assignee_Name__c = UserInfo.getUserId(),
                                                                               //CHaRM-R4: Added the TIMR Aprover name field since it is a required field
                                                                                TIMR_Approver_Name__c = t_TTaskApprover.Id,//CHaRM-R4
                                                                                Suspended__c = true
                                         ), true);
        //WF: Update Rule Field for Trend Item Maint I/R Workflow    
        System.assertEquals('TREND_ITEM_MAINTENANCE_I_R_WORKFLOW', [SELECT CMPL123Rule_Key_Value__c FROM Trend_Item_Maintenance_Request__c  WHERE Id =: timr.Id].CMPL123Rule_Key_Value__c);
        //CHaRM R5: To verify that  Dual Permission User with 'Business Admin' and 'T&T task Approver' Permission set access can Insert a 'Thresholds' or 'Ticket T/T' process type TIMR record.
        System.assertEquals('TestDual',[SELECT ID, Trend_Item_Name__c FROM Trend_Item_Maintenance_Request__c].Trend_Item_Name__c);
        //WF: Last Un/Suspended Date update 
        System.assertNotEquals(null, [SELECT Last_Un_Suspended_Date__c FROM Trend_Item_Maintenance_Request__c  WHERE Id =: timr.Id].Last_Un_Suspended_Date__c);
        timr.Last_Un_Suspended_Date__c = date.today().addDays(-5);
        timr.Suspended__c = false;
        timr.Suspended_Rationale__c = 'TEST';
        update timr;
        System.assertNotEquals(date.today().addDays(-5), [SELECT Last_Un_Suspended_Date__c FROM Trend_Item_Maintenance_Request__c  WHERE Id =: timr.Id].Last_Un_Suspended_Date__c);
    }
    }

    /*
    * @Method       : testWfLogicPrt2.
    * @Description  : TWD Upgrade issue. To test logic from disabled WF rules.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testWfLogicPrt2 () {
        Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];//CHaRM-R4
        //CHaRM R5: Added the Dual permission user to Insert the TIMR record without Error
        User DualPermissionUser = [SELECT Id, Email FROM User WHERE Email =: 'DualAdmin@test.com'];
        System.runAs(DualPermissionUser) {
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Ticket T/T',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                                Assignee_Name__c = UserInfo.getUserId(),
                                                                               //CHaRM-R4: Added the TIMR Aprover name field since it is a required field
                                                                                TIMR_Approver_Name__c = t_TTaskApprover.Id
                                         ), true);
        //Charm-R4 : (Start)
        //Check the Assert for 'TIMR Approved On & TIMR Approved By' is auto-populated and 'TIMR Rjected On & TIMR Rejected By' as null when 'TIMR Approve' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Approve';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Approved_By__c, 'TIMR Approve by, should be autopopulated');
        System.assertEquals(date.today(), timr.TIMR_Approved_On__c );
        System.assertEquals(null, timr.TIMR_Rejected_By__c );
        System.assertEquals(null, timr.TIMR_Rejected_On__c ); 
        
        //Check the Assert for 'TIMR Rjected On & TIMR Rejected By' is auto-populated and TIMR Approved By and TIMR Approved On is Blanked out when 'TIMR Reject' action is Performed.
        timr.CMPL123_WF_Action__c = 'TIMR Reject';
        timr.TIMR_Rejection_Rationale__c = 'Test';
        update timr;
        timr = [SELECT TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timr.TIMR_Rejected_By__c );
        System.assertEquals(date.today(), timr.TIMR_Rejected_On__c ); 
        System.assertEquals(null, timr.TIMR_Approved_By__c);
        System.assertEquals(null, timr.TIMR_Approved_On__c); 
        //Charm-R4 : (end)
        }
   }
   /*
    * @Method       : testWfLogicPrt3.
    * @Description  : TWD Upgrade issue. To test logic from disabled WF rules.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */ 
   @isTest
    public static void testWfLogicPrt3 () {
        Id addTrendItemRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(
                                        new Trend_Item__c(CMPL123_WF_Status__c = 'Opened'), true);
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];//CHaRM-R4
        //CHaRM R5: Added the Dual permission user to Insert the TIMR record without Error
        User DualPermissionUser = [SELECT Id, Email FROM User WHERE Email =: 'DualAdmin@test.com'];
        System.runAs(DualPermissionUser) {
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(
                                        new Trend_Item_Maintenance_Request__c (CMPL123_WF_Status__c = 'Opened',
                                                                                RecordTypeId = addTrendItemRecordType,
                                                                                Process__c = 'Ticket T/T',
                                                                                Trend_Item__c = trendItem.Id,
                                                                                Trend_Item_Name__c = 'Test',
                                                                                Trend_Item_Type__c = 'Process',
                                                                                Has_Product_Child__c = true,
                                                                                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                                                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                                                Assignee_Name__c = UserInfo.getUserId(),
                                                                               //CHaRM-R4: Added the TIMR Aprover name field since it is a required field
                                                                                TIMR_Approver_Name__c = t_TTaskApprover.Id
                                         ), true);
   
        //WF: Workflow - Approve    
        timr.CMPL123_WF_Action__c = 'Approve';
        update timr;
        //WF: Workflow - Close
        timr.CMPL123_WF_Action__c = 'Close';
        update timr;
        //WF: Workflow - Implementation Complete
        timr.CMPL123_WF_Action__c = 'Implementation Complete';
        update timr;
        //WF: Workflow - Reject
        timr.CMPL123_WF_Action__c = 'Reject';
        timr.Reject_Reason__c = 'TSET';
        update timr;
       //WF: Workflow - Request More Info
        timr.CMPL123_WF_Action__c = 'Request More Info';
        timr.Request_Submitted_On__c = date.today();
        timr.Request_More_Information__c = 'TEST';
        update timr;
        timr = [SELECT Request_Submitted_On__c, TIMR_Approved_By__c, TIMR_Approved_On__c FROM Trend_Item_Maintenance_Request__c WHERE Id = :timr.Id];//CHaRM-R4
        System.assertEquals(null, timr.Request_Submitted_On__c );//CHaRM-R4
        //CHaRM-R4:Check the Assert for 'TIMR Approved On & TIMR Approved By' is null when Request More Info action is Performed.
        System.assertEquals(null, timr.TIMR_Approved_By__c);//CHarM-R4
        System.assertEquals(null, timr.TIMR_Approved_On__c);//CHarM-R4
        //WF: Workflow - Submit a Request
        Trend_Item_Maintenance_Product__c trendItemMaintenanceProduct = (Trend_Item_Maintenance_Product__c) TestDataFactory.createSObject(
                new Trend_Item_Maintenance_Product__c (
                        Division__c = null,
                        Trend_Item_Maintenance_Request__c = timr.Id),
                true
        );
        timr.CMPL123_WF_Action__c = 'Submit a Request';
        update timr;
        //WF: Workflow - Submit Re/Baseline for Review
        timr.CMPL123_WF_Action__c = 'Submit Re/Baseline for Review';
        update timr;
        //WF: Workflow - Submit for Implementation
        timr.CMPL123_WF_Action__c = 'Submit for Implementation';
        update timr;
        //WF: Workflow - Void
        timr.CMPL123_WF_Action__c = 'Void';
        update timr;
        
        //CHaRM R4: Start 
        Trend_Item_Maintenance_Request__c timrField = [SELECT CMPL123Rule_Key_Value__c,Approved_By__c,Closed_By__c,Implementation_Completed_By__c,Rejected_By__c
                                                       , Request_Submitted_By__c,Re_Baseline_Submitted_for_Review_By__c,Submitted_for_Implementation_By__c,
                                                       Voided_By__c,TIMR_Rejected_On__c, TIMR_Rejected_By__c, TIMR_Approved_By__c, TIMR_Approved_On__c
                                                        FROM Trend_Item_Maintenance_Request__c  WHERE Id =: timr.Id];
    
        System.assertEquals('TREND_ITEM_MAINTENANCE_WORKFLOW', timrField.CMPL123Rule_Key_Value__c);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timrField.Approved_By__c);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timrField.Closed_By__c);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timrField.Implementation_Completed_By__c);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timrField.Rejected_By__c);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timrField.Request_Submitted_By__c);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timrField.Re_Baseline_Submitted_for_Review_By__c);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timrField.Submitted_for_Implementation_By__c);
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), timrField.Voided_By__c);
        
     //CHaRM R4 : End 
   }
 }
   
    /**
	* @Method       : timrCreationWithThresholdProcess
	* @Description  : 
	* @Return       : N/A
	* @Params       : N/A
	**/ 
    @isTest
    public static void timrCreationWithThresholdProcess (){
        User user = [SELECT Id FROM User WHERE Email = 'test2@test.com'];
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];//CHaRM-R4
        User businessAdmin = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin@test.com'];
        RecordType recordType = [SELECT Id
                                 FROM RecordType
                                 WHERE SobjectType = 'Trend_Item_Maintenance_Request__c'
                                 AND DeveloperName = 'Add_Trend_Item'];
        String timrRecordTypeId = Schema.SObjectType.Trend_Item_Maintenance_Request__c
                .getRecordTypeInfosByName()
                .get('Add Trend Item')
                .getRecordTypeId();
        sObject trendItemObj = Schema.getGlobalDescribe().get('Trend_Item__c').newSObject() ;
        trendItemObj.put('CMPL123_WF_Status__c', 'Opened');
        //CHaRM R5: Added the Dual permission user to Insert the TIMR record without Error
        User businessAdmin1 = [SELECT Id, Email FROM User WHERE Email =: 'BusinessAdmin1@test.com'];
        System.runAs(businessAdmin1) {
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(trendItemObj, true);
        
        sObject timrObj = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Request__c').newSObject() ;
        timrObj.put('CMPL123_WF_Status__c', 'Opened');
        timrObj.put('RecordTypeId', timrRecordTypeId);
        timrObj.put('Process__c', 'Thresholds');
        timrObj.put('Trend_Item__c', trendItem.Id);
        timrObj.put('Trend_Item_Name__c', 'Test');
        timrObj.put('Trend_Item_Type__c', 'Process');
        timrObj.put('Has_Product_Child__c', true);
        timrObj.put('Assignee_Name__c', user.Id);
        timrObj.put('TIMR_Approver_Name__c', businessAdmin.Id);//CHaRM-R4
        Trend_Item_Maintenance_Request__c timr = (Trend_Item_Maintenance_Request__c)TestDataFactory.createSObject(timrObj, true);
        
       try {
            timr.TIMR_Approver_Name__c = t_TTaskApprover.Id;
            timr.Process__c = 'Thresholds';
            timr.RecordType = recordType;
            
            update timr;
            
        } catch (Exception e) {
            System.assert( e.getMessage().contains(System.Label.TIMR_Approver_Name_Business_Admin), 'Error should be shown because the TIMR Approver name has wrong user');
        }
    }
    }
    
}