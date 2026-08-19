/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDCustomAttachmentTriggerHandlerTest.
 * @Why   : ADDCustomAttachmentTriggerHandlerTest class for the ADDCustomAttachmentTriggerHandler class.
 * @When  : 25-FEB-2017.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer            Date                   Modification ID                 Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                25-FEB-2017            Work ID / Case ID               Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                18-FEB-2020            CR973                           Added new test methods. Add/Delete attachment behaviour.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                22-MAY-2020            #100/CHARM-2610                 Added new test method to test edit attachment behavoiur for Tibco user.
 *                                                                             Tibco user wasn't able to edit attachment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                26-MAY-2020            #100/CHARM-2610                 Added a filter to query only active test user.
 *                                                                             Tibco user wasn't able to edit attachment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rslob                03-JUN-2020            N/A                             Test class optimization.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
 *                                                                             This change designed to prevent a 'DUPLICATE_USERNAME'
 *                                                                             error during deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                15-JUN-2020            Code Audit                      Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                29-OCT-2020            HC #100/CHARM-3518              Adjusted test data insertion.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                28-DEC-2020            TWD Upgrade issue               Added 'executeLogicFromWFRulesTest()' method to test moved
 *                                                                               logic from Workflow Rules with Field Updates on
 *                                                                               Attachment to Apex.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         07-SEP-2022            CHaRM R2.2 IPDR 164             Fix missing coverage for MDCTicketUtil due to not having
 *                                                                               MDC Trigger records
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Dinesh Kumar        29-NOV-2023            CHaRM-R4/IPDR-571              Added the TIMR Approver name Field in the method "testAttachmentAllowedDMLOperationsTIMR"
 *                                                                            Created the T&T approver user since there is a validation on TIMR Approver Name field. 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Charm COE           29-JUN-2026			   CHaRM R9.0/IPDR-165            Added a new Method 'testInquiryAttachmentWithCR' to test MDC Creation
 *																			  for Inquiry Ticket when Customer Response Child Record Exists.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  CHaRM COE           20-JUL-2026            CHaRM R9.0/IPDR-409          Created "createAttachment_test1" & "createAttachment_test2" methods
 * 																		    to cover the MDC creation fucntionality when PatientInformation record creates.
 * 																			Update the "makeData" method to insert the "ADD_App_Settings__c" custom setting.
 * -------------------------------------------------------------------------------------------------------------------------------------- 
*/ 

@IsTest
private class ADDCustomAttachmentTriggerHandlerTest {
    /**
    * @Method       : makeData
    * @Description  : Create data fov
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    static void makeData(){
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        appConfig.MDC_Generation_Prevention_Minutes__c=10.0;
        update appConfig;
        User user = TestUtil.insertTestUser(
            [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            'test2@test.com',
            'test2@test.com'
        );
        //CHARM-2610 (#100) start. Creating tibco user to test edit behavior.
        User user2 = TestUtil.insertTestUser(
            [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration' LIMIT 1].Id,
            'test3@test.com',
            'test3@test.com'
        );
        //Start - CHaRM-R4 - IPDR-571
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        //Creating a test user 'T_TTaskApprover'
        User t_TTaskApprover = TestUtil.insertTestUser(
                aspenUserProfileId,
                'T_TTaskApprover@test.com',
                'T_TTaskApprover@test.com'
        );
        
        //Creating a system admin user 'systemAdmin'. This user will be used to assign permission sets to test user.
        Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User systemAdmin = TestUtil.insertTestUser(
                systemAdminProfileId,
                'systemAdminUsertest@test.com',
                'systemAdminUsertest@test.com'
        );
        
        //Fetch permission sets that are needed to be assigned to 'T_TTaskApprover'        
        PermissionSet PS1 = [
            SELECT Id FROM PermissionSet
            WHERE Name= 'T_T_Task_Approver'
        ];
        
        PermissionSet PS2 = [
            SELECT Id FROM PermissionSet
            WHERE Name= 'X123Compliance_Permission_Set_for_Platform_User'
        ];
        
        //Running as systemAdmin to assign PS to test user T_TTaskApprover
        //This is to avoid Mixed DML excpetion as both setup and non-setup objects cannot be updated in same transaction.
        System.runAs(systemAdmin)
        {
            insert new permissionSetAssignment(
                AssigneeId = t_TTaskApprover.Id,
                PermissionSetId = PS1.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = t_TTaskApprover.Id,
                PermissionSetId = PS2.Id
            );
        }
        //End - CHaRM-R4
        //CHARM-2610 (#100) end.
        // 07-SEP-2022 Larry: Now inserts all MDC Trigger records currently in the org
        //insert ADDTicketNoteTriggerHandlerTest.getMdcTriggers();
        insertMdcTriggersForAttachment();
    }
    /**
     * @Method       : insertMdcTriggersForAttachment
     * @Description  : Setup MDC trigger
     * @Return       : N/A
     * @Params       : N/A
     **/
    private static List<CMPL123__MDC_Trigger__c> insertMdcTriggersForAttachment() {
        // Insert MDC Triggers so that the audit trail knows which SObjects to act on.
        // Notice that these four MDC Triggers are commented from the MDC_TRIGGER constants
        CMPL123__MDC_Trigger__c mdcTriggerEvalInvest =
            (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(new CMPL123__MDC_Trigger__c(
                CMPL123__Active__c = true,
                CMPL123__Criteria__c = 'Created or Changed',
                CMPL123__Logic__c = '1',
                CMPL123__Number_of_Acks__c = 1,
                CMPL123__Record_Detail_Field__c = 'Registration_Ticket__c',
                CMPL123__Select_Target_Object__c = 'Attachment__c',
                Name = 'Attachment Change for Evaluator/Investigator',
                Selected_Group_Name__c = 'Evaluator/Investigator'
            ), false);
        CMPL123__MDC_Trigger__c mdcTriggerMedEval = mdcTriggerEvalInvest.clone();
        mdcTriggerMedEval.Name = 'Attachment Change for Medical Evaluator';
        mdcTriggerMedEval.Selected_Group_Name__c = 'Medical Evaluator';
        insert new CMPL123__MDC_Trigger__c[]{mdcTriggerEvalInvest, mdcTriggerMedEval};
                    
            // Insert Audit Trail Config so that MDCs know which fields to track.
            // This happens in MDCTicketUtil.createMDC
            CMPL123__AuditTrail_Config__c auditTrailConfig = 
            (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
                CMPL123__Fields__c = 'Registartion_Attachment__c',
                CMPL123__Is_Active__c = true,
                Name = 'Attachment__c'
            ), true);
        
        // Insert MDC Field Maps so that field API names can be affiliated with labels
        CMPL123__MDC_Field_Mapping__c fieldMapEvalInvest = 
            (CMPL123__MDC_Field_Mapping__c) TestDataFactory.createSObject(new CMPL123__MDC_Field_Mapping__c(
                CMPL123__Condition__c = 'Custom',
                CMPL123__Field_API__c = 'Registartion_Attachment__c',
                CMPL123__Field_Name__c = 'Registration Attachment Added',
                CMPL123__Index__c = 1,
                CMPL123__Parameters__c = 'AttachmnetsWithMedEvalMDCLogic',
                CMPL123__Parent_object__c = mdcTriggerEvalInvest.Id,
                CMPL123__Selected_object__c = 'Ticket_Note__c'
            ), false);
        CMPL123__MDC_Field_Mapping__c fieldMapMedEval = fieldMapEvalInvest.clone();
        fieldMapMedEval.CMPL123__Parameters__c = 'AttachmnetsWithMedEvalMDCLogic';
        fieldMapMedEval.CMPL123__Parent_object__c = mdcTriggerMedEval.Id;
        insert new CMPL123__MDC_Field_Mapping__c[]{ fieldMapEvalInvest, fieldMapMedEval };
         return new List<CMPL123__MDC_Trigger__c>{ mdcTriggerEvalInvest, mdcTriggerMedEval };
       }
    /**
* @Method       : testInquiryAttachmentWithCR
* @Description  : Verifies that MDC is created only for Inquiry tickets with a Customer Response child record upon attachment insertion.
* @Return       : N/A
* @Params       : N/A
**/
    @IsTest
    public static void testInquiryAttachmentWithCR() {
        String rtId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        
        CMPL123CME__Complaint__c complaint = new CMPL123CME__Complaint__c(
            RecordTypeId = rtId,
            Division__c = 'ADD',
            pRE_Status__c = 'Yes',
            Country_of_origin__c = 'USA',
            Business_Unit__c = 'IA-CC',
            Customer_Reply_Required__c=true,
            Is_Custom_response_child_created__c = true,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened'
        );
        insert complaint;
        Customer_Response__c customerResponse = (Customer_Response__c) TestDataFactory.createSObject(
            new Customer_Response__c(
                Event__c = complaint.Id,                        
                Customer_Reply__c = 'test',
                CMPL123_WF_Status__c = 'Opened'),
            true
        );
        Attachment__c att = new Attachment__c(
            Attachment_Type__c = 'Registration',
            Registartion_Attachment__c = 'VERIFICATION FOR CR EXISTENCE',
            Ticket__c = complaint.Id
        );
        
        Test.startTest();
        insert att;          
        Test.stopTest();
        
        Boolean ticketwithCR = [SELECT Ticket__r.Customer_Reply_Required__c FROM Attachment__c  WHERE Ticket__c = :complaint.Id ].Ticket__r.Customer_Reply_Required__c;       
        System.assertEquals(true, ticketwithCR, 'MDC should be created for Inquiry Ticket Only with Customer Response');
        
    }
    
    /**
    * @Method       : test
    * @Description  : Test edit functionality for attachment for Customer Response for Tibco User. CHARM-2610 (#100)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testCustResponseAttachmForTibco() {
        User tibcoUser = [SELECT Id FROM User WHERE Profile.Name = 'ASPEN Integration' and Email = 'test3@test.com' and isActive = true limit 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and Email = 'test2@test.com' and isActive = true limit 1];
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Inquiry')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'USA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMSNext_Ticket_Number__c = '12345'),
                true
        );

        Id aspenUser = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        User approverUser = TestUtil.insertTestUser(aspenUser, 'test@test.com', 'test@test.com');
        System.runAs(adminUser) {
            List<Group> groups = [SELECT Id FROM Group WHERE DeveloperName = 'Quality_Complaint' OR DeveloperName = 'Quality_non_Complaint'];
            List<GroupMember> newGroupMembers = new List<GroupMember> ();
            for (Group gr : groups) {
                newGroupMembers.add(new GroupMember(
                        GroupId = gr.Id,
                        UserOrGroupId = approverUser.Id
                ));
            }
            insert newGroupMembers;
        }
        Customer_Response__c customerResponse = (Customer_Response__c) TestDataFactory.createSObject(
                new Customer_Response__c(
                        Event__c = complaint.Id,
                        Assign_To__c = approverUser.Id,
                        Customer_Reply__c = 'test',
                        CMPL123_WF_Status__c = 'Opened'),
                true
        );
        Attachment__c attachment = (Attachment__c ) TestDataFactory.createSObject(new Attachment__c(Customer_Response__c = customerResponse.Id, Attachment_Type__c = 'Medical Evaluation'), true);
        Attachment stAttachment = (Attachment) TestDataFactory.createSObject(new Attachment(Name = 'test', ParentId = attachment.Id, Body = Blob.valueOf('text')), true);
        System.runAs(approverUser) {
            attachment.Send_to_CMSNext__c = true;
            update attachment;
            customerResponse.CMPL123_WF_Status__c = 'Closed-Done';
            update customerResponse;
        }
        System.runAs(tibcoUser) {
            attachment.UNC_Path__c = 'test';
            update attachment;
        }
        System.assertEquals('test', [SELECT UNC_Path__c FROM Attachment__c].UNC_Path__c , 'Attachment should be successfully updated');
    }

    /**
    * @Method       : test
    * @Description  : Test add/edit/delete functionality for attachment
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();

        Profile aspenIntegrationProfile = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'];
        Profile aspenUserProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];

        User aspenInteg = TestUtil.insertTestUser(
                aspenIntegrationProfile.Id,
                'test@test.com',
                'aspenIntegrationTest@test.com'
        );
        User aspenUser = TestUtil.insertTestUser(
                aspenUserProfile.Id,
                'test2@test.com',
                'aspenUserTest@test.com'
        );

        System.runAs(aspenInteg) {
            TestDataFactory.createSObject(new CMPL123__Product__c(Name = 'Test'), true);
        }

        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'USA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened:Appending Regulatory Correspondence',
                CMSNext_Ticket_Number__c = '12345'),
                true
        );

        Customer_Response__c customerResponse = (Customer_Response__c) TestDataFactory.createSObject(
                new Customer_Response__c(
                        Event__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened'),
                true
        );

        Test.startTest();
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        Name = 'Test',
                        CMPL123_WF_Status__c = 'Assess:In Process-Evaluation:In Process-Investigation:Conclude',
                        Product_Evaluation_Type__c = 'FUF',
                        Additional_Action_Taken__c = 'No',
                        Approver__c = aspenUser.Id,
                        Assessor__c = aspenUser.Id,
                        Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                        Conclusion_Summary__c = 'Test',
                        Evaluator_Investigator__c = aspenInteg.Id,
                        CMPL123CME__Complaint__c = complaint.Id),
                true
        );

        Task__c task = (Task__c) TestDataFactory.createSObject(
                new Task__c(
                        Related_Investigation_Evaluation__c = investigation.Id,
                        CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
                        Source_Leveraged__c = 'Leveraged',
                        CMPL123_WF_Status__c = 'Opened:In Process'),
                true
        );

        Return__c returnC = (Return__c) TestDataFactory.createSObject(
                new Return__c(
                        Ticket__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened'),
                true
        );

        List<Attachment__c> attachments = new List<Attachment__c>{
                new Attachment__c(
                        Customer_Response__c = customerResponse.Id,
                        Attachment_Type__c = 'Medical Evaluation',
                        Evaluation_Investigation_Task__c = task.Id,
                        Investigation_Evaluation__c = investigation.Id,
                        Return__c = returnC.Id,
                        Ticket__c = complaint.Id
                )
        };

        ADDCustomAttachmentTriggerHandler handler = new ADDCustomAttachmentTriggerHandler();
        TicketUpdateUtility.executeFlag = true;
        insert attachments;
        insert new Attachment(
                ParentId = attachments.get(0).Id,
                Body = Blob.valueOf('Test'),
                Name = 'Test.txt'
        );
        TicketUpdateUtility.executeFlag = true;
        update attachments;
        try {
            delete attachments;
        }
        catch (DmlException ex) {
            System.debug(ex.getMessage());
        }
        handler.afterDelete();
        Test.stopTest();

        System.assertEquals(attachments.size(), [SELECT COUNT() FROM Attachment__c ALL ROWS], 'Should be the same');
    }

    /**
    * @Method       : preventCreatingDeletingIfParentIsSpecificTest
    * @Description  : Test add/delete functionality for attachment for PMRA in status Pending Closure of Related Child Records and Tasks
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    static void preventCreatingDeletingIfParentIsSpecificTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c pmra = (Post_Market_Risk_Assessment_Risk_Contr__c)
                TestDataFactory.createSObject(new Post_Market_Risk_Assessment_Risk_Contr__c(
                        Division__c = 'ADD',
                        CMPL123_WF_Status__c = 'Opened',
                        Rationale_if_No_Hazards_Are_Identified__c = 'Test',
                        Potential_Hazard_Types_Associated_with_I__c = 'Chemical',
                        Business_Unit__c = 'Transfusion',
                        Event_which_could_lead_to_a_hazard__c = 'Test',
                        Notification_Date__c = System.today(),
                        Site_Owner_New__c = 'Dallas'
                ), true);

        Attachment__c attachment = (Attachment__c) TestDataFactory.createSObject(new Attachment__c(
                Attachment_Type__c = 'Medical Evaluation',
                Post_Market_Risk_Asst_Risk_Ctrl__c = pmra.Id
        ), true);

        pmra.CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks';
        update pmra;

        Test.startTest();
            try {
                delete attachment;
            } catch (DmlException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0), 'Error should appear');
                //CR 973. Check should be done on different error message.
                System.assertEquals(System.Label.Custom_Attachment_Error_Message, e.getDmlMessage(0), 'Error should appear');
            }
        Test.stopTest();

        Attachment__c result = [SELECT IsDeleted FROM Attachment__c WHERE Id =: attachment.Id ALL ROWS];

        System.assertEquals(false, result.IsDeleted, 'Should not be deleted');
    }

    //CR:973 start. Tests are for checking create and delete behaviour for attachment for specific objects in specific Statuses.
    //Each method relates to different parent object.
    /**
    * @Method       : testAttachmentAllowedDMLOperationsCompl
    * @Description  : Test create and delete behaviour for attachment for complaint. CR:973
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testAttachmentAllowedDMLOperationsCompl(){
        List <String> allowedStatuses = new List <String>{'Opened', 'Closed-Done', 'Closed-Voided',
                                                            'Complaint Complete', 'Complaint Further Review',
                                                            'Registration Closed', 'Final Review in Progress',
                                                            'Appending Regulatory Correspondence'};
        List <String> notAllowedStatuses = new List <String>{'Closed-Done', 'Closed-Voided'};
        List <sObject> sObjects = new List <sObject>();
        for (String status: allowedStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('CMPL123CME__Complaint__c').newSObject() ;
            sObj.put('CMPL123CME__CMPL123_WF_Status__c', status);
            sObjects.add(TestDataFactory.createSObject(sObj, false));
        }
        List <sObject> sObjectsToModify = new List <sObject>();
        for (String status: notAllowedStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('CMPL123CME__Complaint__c').newSObject() ;
            sObj.put('CMPL123CME__CMPL123_WF_Status__c', allowedStatuses.get(0));
            sObjectsToModify.add(TestDataFactory.createSObject(sObj, false));
        }
        testSobjectAttachment(sObjects, sObjectsToModify, 'CMPL123CME__CMPL123_WF_Status__c', allowedStatuses, notAllowedStatuses, notAllowedStatuses, 'Ticket__c');
        System.assertEquals(notAllowedStatuses.size(), [Select Id from Attachment__c].size());
    }
    /**
    * @Method       : testAttachmentAllowedDMLOperationsMDI
    * @Description  : Test create and delete behaviour for attachment for MDI. CR:973
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testAttachmentAllowedDMLOperationsMDI () {
        List <String> allowedStatusesForInsert = new List <String>{'Opened', 'Pending Regulatory Decision'};
        List <String> notAllowedStatusesForInsert = new List <String>{'Pending Follow Up Creation', 'Pending Final Review'};
        List <String> allowedStatuses = new List <String>{'Opened', 'Pending Follow Up Creation','Pending Regulatory Decision', 'Pending Final Review'};
        List <String> notAllowedStatuses = new List <String>{'Closed-Done', 'Closed-Voided'};
        List <sObject> sObjects = new List <sObject>();
        List <sObject> sObjectsWithAllowedStatusesToUpdate = new List <sObject>();
        List <sObject> sObjectsToModify = new List <sObject>();
        Country__c country = (Country__c) TestDataFactory.createSObject(new Country__c(), true);
        Country_Submission_Type__c countrySubmissionType = (Country_Submission_Type__c)TestDataFactory.createSObject(new Country_Submission_Type__c(
                                                                        Name = '30 Days',
                                                                        Calendar_Days__c = 30,
                                                                        Country__c = country.Id
                                                            ), true);
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId), true);
        Product_Ticket__c productTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(), true);
        User user = [select Id from User limit 1];
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c parentMedEval = (CMPL123CME__Questionnaire__c)TestDataFactory.createSObject(
                                                        new CMPL123CME__Questionnaire__c(
                                                            CMPL123_WF_Status__c = 'Regulatory',
                                                            Reportability_Category__c = 'RCML',
                                                            Reportability__c = 'Non-Reportable',
                                                            Reportability_Rationale__c = 'Test',
                                                            RecordTypeId = questionnaireRTId,
                                                            Evaluator__c = user.Id,
                                                            CMPL123CME__Complaint__c = complaint.Id
                                                        ), true
                                                    );
        List <String> allStatusesForInsert = new List <String>();
        allStatusesForInsert.addAll(allowedStatusesForInsert);
        allStatusesForInsert.addAll(notAllowedStatuses);
        for (String status: allStatusesForInsert) {
            sObject sObj = Schema.getGlobalDescribe().get('CMPL123CME__MEDDEV__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', status);
            sObj.put('CMPL123CME__Complaint__c', complaint.Id);
            sObj.put('Medical_Evaluation__c', parentMedEval.Id);
            sObj.put('Product__c', productTicket.Id);
            sObj.put('Regulatory_Evaluator__c', user.Id);
            sObj.put('Country__c', country.Id);
            sObj.put('Submission_Type__c', countrySubmissionType.Id);
            sObjects.add(TestDataFactory.createSObject(sObj, false));
        }

        for (String status: notAllowedStatusesForInsert) {
            sObject sObj = Schema.getGlobalDescribe().get('CMPL123CME__MEDDEV__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', allowedStatusesForInsert.get(0));
            sObj.put('CMPL123CME__Complaint__c', complaint.Id);
            sObj.put('Medical_Evaluation__c', parentMedEval.Id);
            sObj.put('Product__c', productTicket.Id);
            sObj.put('Regulatory_Evaluator__c', user.Id);
            sObj.put('Country__c', country.Id);
            sObj.put('Submission_Type__c', countrySubmissionType.Id);
            sObjectsWithAllowedStatusesToUpdate.add(TestDataFactory.createSObject(sObj, false));
        }
        insert sObjectsWithAllowedStatusesToUpdate;
        Integer i = 0;
        for (String status: notAllowedStatusesForInsert) {
            sObject sObj = sObjectsWithAllowedStatusesToUpdate.get(i);
            sObj.put('CMPL123_WF_Status__c', status);
            sObjects.add(sObj);
            i++;
        }

        for (String status: notAllowedStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('CMPL123CME__MEDDEV__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', allowedStatusesForInsert.get(0));
            sObj.put('CMPL123CME__Complaint__c', complaint.Id);
            sObj.put('Medical_Evaluation__c', parentMedEval.Id);
            sObj.put('Product__c', productTicket.Id);
            sObj.put('Regulatory_Evaluator__c', user.Id);
            sObj.put('Country__c', country.Id);
            sObj.put('Submission_Type__c', countrySubmissionType.Id);
            sObjectsToModify.add(TestDataFactory.createSObject(sObj, false));
        }
        testSObjectAttachment(sObjects, sObjectsToModify, 'CMPL123_WF_Status__c', allowedStatuses,
                            new List <String>{'Pending Follow Up Creation', 'Closed-Done', 'Closed-Voided'},
                            notAllowedStatuses, 'MEDDEV__c');
        System.assertEquals(notAllowedStatuses.size(), [Select Id from Attachment__c].size());
    }
    /**
    * @Method       : testAttachmentAllowedDMLOperationsTrendItem
    * @Description  : Test create and delete behaviour for attachment for TrendItem. CR:973
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testAttachmentAllowedDMLOperationsTrendItem(){
        List <String> allowedStatuses = new List <String>{'Opened', 'Active'};
        List <String> notAllowedStatuses = new List <String>{'Inactive'};
        List <sObject> sObjects = new List <sObject>();
        List <String> allStatuses = new List <String>();
        allStatuses.addAll(allowedStatuses);
        allStatuses.addAll(notAllowedStatuses);
        for (String status: allStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Trend_Item__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', status);
            sObjects.add(TestDataFactory.createSObject(sObj, false));
        }
        List <sObject> sObjectsToModify = new List <sObject>();
        for (String status: notAllowedStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Trend_Item__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', allowedStatuses.get(0));
            sObjectsToModify.add(TestDataFactory.createSObject(sObj, false));
        }
        testSobjectAttachment(sObjects, sObjectsToModify, 'CMPL123_WF_Status__c', allowedStatuses, notAllowedStatuses, notAllowedStatuses, 'Trend_Item__c');
        System.assertEquals(notAllowedStatuses.size(), [Select Id from Attachment__c].size());
    }

    /**
    * @Method       : testAttachmentAllowedDMLOperationsTIMR
    * @Description  : Test create and delete behaviour for attachment for TIMR. CR:973
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testAttachmentAllowedDMLOperationsTIMR(){
        User user = [Select Id from User where Email = 'test2@test.com' LIMIT 1];
        String timrRecordTypeId = Schema.SObjectType.Trend_Item_Maintenance_Request__c
                .getRecordTypeInfosByName()
                .get('Add Trend Item')
                .getRecordTypeId();
        sObject trendItemObj = Schema.getGlobalDescribe().get('Trend_Item__c').newSObject() ;
        trendItemObj.put('CMPL123_WF_Status__c', 'Opened');
        Trend_Item__c trendItem = (Trend_Item__c)TestDataFactory.createSObject(trendItemObj, true);
        List <String> allowedStatuses = new List <String>{'Opened', 'In Progress', 'Pending Approval', 'Pending Implementation'};
        List <String> notAllowedStatuses = new List <String>{'Closed-Done', 'Closed-Voided'};
        List <sObject> sObjects = new List <sObject>();
        List <String> allStatuses = new List <String>();
        allStatuses.addAll(allowedStatuses);
        allStatuses.addAll(notAllowedStatuses);
        User t_TTaskApprover = [SELECT Id, Email FROM User WHERE Email =: 'T_TTaskApprover@test.com'];//CHaRM-R4
        for (String status: allStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Request__c').newSObject() ;
            if (status == 'Pending Approval') {
                sObj.put('CMPL123_WF_Status__c', 'Opened');
            } else {
                sObj.put('CMPL123_WF_Status__c', status);
            }
            sObj.put('RecordTypeId', timrRecordTypeId);
            sObj.put('Process__c', 'Ticket T/T');
            sObj.put('Trend_Item__c', trendItem.Id);
            sObj.put('Trend_Item_Name__c', 'Test');
            sObj.put('Trend_Item_Type__c', 'Process');
            sObj.put('Has_Product_Child__c', true);
            sObj.put('Assignee_Name__c', user.Id);
            sObj.put('TIMR_Approver_Name__c', t_TTaskApprover.Id);//CHaRM-R4 Added TIMR Approver Name.
            sObjects.add(TestDataFactory.createSObject(sObj, false));
        }
        List <sObject> sObjectsToModify = new List <sObject>();
        for (String status: notAllowedStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Request__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', allowedStatuses.get(0));
            sObj.put('RecordTypeId', timrRecordTypeId);
            sObj.put('Process__c', 'Ticket T/T');
            sObj.put('Trend_Item__c', trendItem.Id);
            sObj.put('Trend_Item_Name__c', 'Test');
            sObj.put('Trend_Item_Type__c', 'Process');
            sObj.put('Has_Product_Child__c', true);
            sObj.put('Assignee_Name__c', user.Id);
            sObj.put('TIMR_Approver_Name__c', t_TTaskApprover.Id);//CHaRM-R4 Added TIMR Approver Name.
            sObjectsToModify.add(TestDataFactory.createSObject(sObj, false));
        }

        testSobjectAttachment(sObjects, sObjectsToModify, 'CMPL123_WF_Status__c', allowedStatuses, notAllowedStatuses, notAllowedStatuses, 'Trend_Item_Maintenance_Request__c');
        System.assertEquals(notAllowedStatuses.size(), [Select Id from Attachment__c].size());
    }
    /**
    * @Method       : testAttachmentAllowedDMLOperationsPMRA
    * @Description  : Test create and delete behaviour for attachment for PMRA.CR:973
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testAttachmentAllowedDMLOperationsPMRA(){
        User user = [select Id from User limit 1];
        List <String> allowedStatuses = new List <String>{'Opened', 'Hazard Assessment In Process',
                                                            'Pending Risk Control Measure Recommendation',
                                                            'Risk Evaluation in Process',
                                                            'Risk Control Measure in Process',
                                                            'Typographical Changes',
                                                            'Pending Typographical Changes Approval',
                                                            'Pending Management Approval',
                                                            'Pending RCM Management Approval'};
        List <String> notAllowedStatuses = new List <String>{'Pending Senior Management Approval',
                                                            'Pending TSB Senior Management Approval',
                                                            'Pending Pass-Through Approval',
                                                            'Pending Closure of Related Child Records and Tasks',
                                                            'Pending Hazard Assessment Approval',
                                                            'Pending Risk Evaluation Approval',
                                                            'Closed-Done',
                                                            'Closed-Voided'};
        List <sObject> sObjects = new List <sObject>();
        List <String> allStatuses = new List <String>();
        allStatuses.addAll(allowedStatuses);
        allStatuses.addAll(notAllowedStatuses);
        for (String status: allStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Post_Market_Risk_Assessment_Risk_Contr__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', status);
            sObj.put('Division__c', 'ADD');
            sObj.put('Rationale_if_No_Hazards_Are_Identified__c', 'Test');
            sObj.put('Potential_Hazard_Types_Associated_with_I__c', 'Chemical');
            sObj.put('Business_Unit__c', 'Transfusion');
            sObj.put('Event_which_could_lead_to_a_hazard__c', 'Test');
            sObj.put('Notification_Date__c', System.today());
            sObj.put('Site_Owner_New__c', 'Dallas');
            sObj.put('DVP_Marketing_Approver__c', user.Id);
            sObj.put('DVP_Medical_Affairs_Approver__c', user.Id);
            sObj.put('DVP_Quality_Assurance_Approver__c', user.Id);
            sObj.put('DVP_Regulatory_Affairs_Approver__c', user.Id);
            sObj.put('Overall_Health_Hazard_Risk_Level__c', 'None');
            if (status == 'Pending Pass-Through Approval') {
                sObj.put('Source__c', 'Pass-Through');
            }
            if (status == 'Pending Hazard Assessment Approval') {
                sObj.put('Hazard_Assessment_Quality_Approver__c', user.Id);
            }
            if (status == 'Pending Risk Evaluation Approval') {
                sObj.put('Risk_Evaluation_Exec_Quality_Approver__c', user.Id);
                sObj.put('Risk_Evaluation_Quality_Approver__c', user.Id);
            }
            if (status == 'Closed-Done' || status == 'Closed-Voided') {
                sObj.put('CMPL123_WF_Status__c', allowedStatuses.get(0));
            }
            if (status == 'Hazard Assessment In Process') {
                sObj.put('Initial_Hazard_Assessment_By__c', user.Id);
            }
            if (status == 'Pending Management Approval' || status == 'Pending RCM Management Approval') {
                sObj.put('QA_Manager_Approver__c', user.Id);
                sObj.put('Medical_Affairs_Approver__c', user.Id);
                sObj.put('Regulatory_Affairs_Approver__c', user.Id);
                sObj.put('Technical_Manager_Approver__c', user.Id);
                sObj.put('Head_of_Quality_Approver__c', user.Id);
                sObj.put('Head_of_Medical_Affairs_Approver__c', user.Id);
                sObj.put('Head_of_Regulatory_Affairs_Approver__c', user.Id);
                sObj.put('Head_of_Technical_Approver__c', user.Id);

            }
            sObjects.add(TestDataFactory.createSObject(sObj, false));
        }
        List <sObject> sObjectsToModify = new List <sObject>();
        for (String status: notAllowedStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Post_Market_Risk_Assessment_Risk_Contr__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', allowedStatuses.get(0));
            sObj.put('Division__c', 'ADD');
            sObj.put('Rationale_if_No_Hazards_Are_Identified__c', 'Test');
            sObj.put('Potential_Hazard_Types_Associated_with_I__c', 'Chemical');
            sObj.put('Business_Unit__c', 'Transfusion');
            sObj.put('Event_which_could_lead_to_a_hazard__c', 'Test');
            sObj.put('Notification_Date__c', System.today());
            sObj.put('Site_Owner_New__c', 'Dallas');
            sObj.put('DVP_Marketing_Approver__c', user.Id);
            sObj.put('DVP_Medical_Affairs_Approver__c', user.Id);
            sObj.put('DVP_Quality_Assurance_Approver__c', user.Id);
            sObj.put('DVP_Regulatory_Affairs_Approver__c', user.Id);
            sObj.put('Overall_Health_Hazard_Risk_Level__c', 'None');
            if (status == 'Pending Pass-Through Approval') {
                sObj.put('Source__c', 'Pass-Through');
            }
            if (status == 'Pending Hazard Assessment Approval') {
                sObj.put('Hazard_Assessment_Quality_Approver__c', user.Id);
            }
            if (status == 'Pending Risk Evaluation Approval') {
                sObj.put('Risk_Evaluation_Exec_Quality_Approver__c', user.Id);
                sObj.put('Risk_Evaluation_Quality_Approver__c', user.Id);
            }
            if (status == 'Hazard Assessment In Process') {
                sObj.put('Initial_Hazard_Assessment_By__c', user.Id);
            }
            if (status == 'Pending Management Approval'  || status == 'Pending RCM Management Approval') {
                sObj.put('QA_Manager_Approver__c', user.Id);
                sObj.put('Medical_Affairs_Approver__c', user.Id);
                sObj.put('Regulatory_Affairs_Approver__c', user.Id);
                sObj.put('Technical_Manager_Approver__c', user.Id);
                sObj.put('Head_of_Quality_Approver__c', user.Id);
                sObj.put('Head_of_Medical_Affairs_Approver__c', user.Id);
                sObj.put('Head_of_Regulatory_Affairs_Approver__c', user.Id);
                sObj.put('Head_of_Technical_Approver__c', user.Id);
            }
            sObjectsToModify.add(TestDataFactory.createSObject(sObj, false));
        }
        testSobjectAttachment(sObjects, sObjectsToModify, 'CMPL123_WF_Status__c', allowedStatuses, notAllowedStatuses, notAllowedStatuses, 'Post_Market_Risk_Asst_Risk_Ctrl__c');
        System.assertEquals(notAllowedStatuses.size(), [Select Id from Attachment__c].size());
    }

    /**
    * @Method       : testAttachmentAllowedDMLOperationsHA
    * @Description  : Test create and delete behaviour for attachment for Hazard Assessment. CR:973
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testAttachmentAllowedDMLOperationsHA(){
        List <String> allowedStatuses = new List <String>{'Opened', 'Hazard Assessment In Process', 'Risk Evaluation in Process',
                                                            'HHA in Process', 'Typographical Changes'};
        List <String> notAllowedStatuses = new List <String>{'Pending Parent Hazard Assessment Approval',
                                                            'Pending Parent Risk Evaluation Approval',
                                                            'Closed-Done',
                                                            'Closed-Voided'};
        List <sObject> sObjects = new List <sObject>();
        List <String> allStatuses = new List <String>();
        allStatuses.addAll(allowedStatuses);
        allStatuses.addAll(notAllowedStatuses);
        for (String status: allStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Hazard_Assessment__c').newSObject() ;
            if (notAllowedStatuses.contains(status)) {
                sObj.put('CMPL123_WF_Status__c', 'Opened');
            } else {
                sObj.put('CMPL123_WF_Status__c', status);
            }
            sObj.put('Description_of_the_Hazard__c', 'Test');
            sObj.put('Hazard_Type__c', 'Delay of Results');
            sObj.put('Approach_for_Data_Analysis__c', 'Experimentally derived');
            sObj.put('Current_Frequency_of_Hazard_Category__c', 'Rare');
            sObj.put('Descr_Data_Used_Data_Anlys_Rationale__c', 'test');
            sObj.put('Does_the_Curt_Est_Freq_trigger_risk_eval__c', 'N/A');
            sObj.put('Estimated_Current_Frequency_of_Hazard__c', 'Test');
            sObj.put('Is_the_hazard_identified_in_the_RMF__c', 'No');
            sObj.put('For_delay_of_results_is_maximum_tolerab__c', 'N/A');
            sObjects.add(TestDataFactory.createSObject(sObj, false));
        }
        List <sObject> sObjectsToModify = new List <sObject>();
        for (String status: notAllowedStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Hazard_Assessment__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', allowedStatuses.get(0));
            sObj.put('Description_of_the_Hazard__c', 'Test');
            sObj.put('Hazard_Type__c', 'Delay of Results');
            sObj.put('Approach_for_Data_Analysis__c', 'Experimentally derived');
            sObj.put('Current_Frequency_of_Hazard_Category__c', 'Rare');
            sObj.put('Descr_Data_Used_Data_Anlys_Rationale__c', 'test');
            sObj.put('Does_the_Curt_Est_Freq_trigger_risk_eval__c', 'N/A');
            sObj.put('Estimated_Current_Frequency_of_Hazard__c', 'Test');
            sObj.put('Is_the_hazard_identified_in_the_RMF__c', 'No');
            sObj.put('For_delay_of_results_is_maximum_tolerab__c', 'N/A');
            sObjectsToModify.add(TestDataFactory.createSObject(sObj, false));
        }
        testSobjectAttachment(sObjects, sObjectsToModify, 'CMPL123_WF_Status__c', allowedStatuses, notAllowedStatuses, notAllowedStatuses, 'Hazard_Assessment__c');
        System.assertEquals(notAllowedStatuses.size(), [Select Id from Attachment__c].size());
    }

    /**
    * @Method       : testAttachmentAllowedDMLOperationsHHA
    * @Description  : Test create and delete behaviour for attachment for Health Hazard Assessment. CR:973
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testAttachmentAllowedDMLOperationsHHA(){
        List <String> notAllowedParentStatuses = new List <String>{'Pending Parent Hazard Assessment Approval',
                                                                    'Pending Parent Risk Evaluation Approval',
                                                                    'Closed-Done', 'Closed-Voided'};
        List <sObject> haSObjects = new List <sObject>();
        List <sObject> hhaSObjects = new List <sObject>();
        List <sObject> attSObjects = new List <sObject>();
        for (String statuses: notAllowedParentStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Hazard_Assessment__c').newSObject() ;
            sObj.put('Hazard_Type__c', 'Delay of Results');
            sObj.put('For_delay_of_results_is_maximum_tolerab__c', 'N/A');
            sObj.put('CMPL123_WF_Status__c', 'HHA in Process');
            haSObjects.add(sObj);
        }
        insert haSObjects;
        for (sObject haSObj: haSObjects) {
            sObject sObjHHA = Schema.getGlobalDescribe().get('Health_Hazard_Assessment__c').newSObject() ;
            sObjHHA.put('Hazard_Assessment__c', haSObj.Id);
            sObjHHA.put('Current_Severity_Level__c', 'Minimal');
            sObjHHA.put('Probability_of_Occurrence_of_Harm__c', 'Rare');
            sObjHHA.put('Health_Hazard_Risk_Level__c', 'Low');
            hhaSObjects.add(sObjHHA);
        }
        insert hhaSObjects;
        for (sObject hhaSObj: hhaSObjects) {
            sObject attachment = Schema.getGlobalDescribe().get('Attachment').newSObject() ;
            attachment.put('Name', 'Test ' + hhaSObj.Id);
            attachment.put('ParentId', hhaSObj.Id);
            attachment.put('Body', Blob.valueOf('Test'));
            attSObjects.add(attachment);
        }
        insert attSObjects;
        System.assertEquals(notAllowedParentStatuses.size(), [Select Id from Attachment].size(), 'Attachment should be created');
        Integer statusIndex = 0;
        for (sObject sObj: haSObjects) {
            sObj.put('CMPL123_WF_Status__c', notAllowedParentStatuses.get(statusIndex));
            statusIndex++;
        }
        update haSObjects;
        Boolean hasErrors = false;

        Database.DeleteResult[] drList = Database.delete(attSObjects, false);
        for (Database.DeleteResult dr : drList) {
            if (!dr.isSuccess()) {
                hasErrors = true;
            }
        }
        System.assertEquals(true, hasErrors, 'Errors should be thrown');
        System.assertEquals(notAllowedParentStatuses.size(), [Select Id from Attachment].size(), 'Error should be thrown for '+notAllowedParentStatuses.size() +' record');
    }

    /**
    * @Method       : testAttachmentAllowedDMLOperationsRegAssessment
    * @Description  : Test create and delete behaviour for attachment for Regulatory Assessment. CR:973
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testAttachmentAllowedDMLOperationsRegAssessment(){
        User user = [Select Id from User where Email = 'test2@test.com' LIMIT 1];
        List <String> allowedStatuses = new List <String>{'Opened', 'In Process'};
        List <String> notAllowedStatuses = new List <String>{'Pending Approval',
                                                            'Closed-Done',
                                                            'Closed-Voided'};
        List <sObject> sObjects = new List <sObject>();
        List <String> allStatuses = new List <String>();
        allStatuses.addAll(allowedStatuses);
        allStatuses.addAll(notAllowedStatuses);
        for (String status: allStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Regulatory_Assessment__c').newSObject() ;
            if (notAllowedStatuses.contains(status)) {
                sObj.put('CMPL123_WF_Status__c', 'Opened');
            } else {
                sObj.put('CMPL123_WF_Status__c', status);
            }
            sObj.put('Approver__c', user.Id);
            sObjects.add(TestDataFactory.createSObject(sObj, false));
        }
        List <sObject> sObjectsToModify = new List <sObject>();
        for (String status: notAllowedStatuses) {
            sObject sObj = Schema.getGlobalDescribe().get('Regulatory_Assessment__c').newSObject() ;
            sObj.put('CMPL123_WF_Status__c', allowedStatuses.get(0));
            sObj.put('Approver__c', user.Id);
            sObjectsToModify.add(TestDataFactory.createSObject(sObj, false));
        }
        testSobjectAttachment(sObjects, sObjectsToModify, 'CMPL123_WF_Status__c', allowedStatuses, notAllowedStatuses, notAllowedStatuses, 'Regulatory_Assessment__c');
        System.assertEquals(notAllowedStatuses.size(), [Select Id from Attachment__c].size());
    }

    /**
    * @Method       : testSObjectAttachment
    * @Description  : General method to test create and delete behaviour for attachment.
    * @Return       : N/A
    * @Params       : List <sObject> sObjects, List <sObject> sObjectsToModify,
    *                  String statusFieldAPI, List <String> allowedStatuses, List <String> notAllowedStatuses,
    *                  List <String> notAllowedStatusesForDelete,
    *                  String parentFieldAPI
    **/
    private static void testSObjectAttachment(List <sObject> sObjects, List <sObject> sObjectsToModify,
                                                String statusFieldAPI, List <String> allowedStatuses, List <String> notAllowedStatuses,
                                                List <String> notAllowedStatusesForDelete,
                                                String parentFieldAPI) {
        List <String> allStatuses = new List <String>();
        allStatuses.addAll(allowedStatuses);
        allStatuses.addAll(notAllowedStatuses);
        upsert sObjects;
        if (parentFieldAPI == 'Trend_Item_Maintenance_Request__c') {
            sObject sObj = sObjects.get(2);
            sObj.put(statusFieldAPI, 'Pending Approval');
            update sObj;
        }

        //impossible to create records with this status. Needs to be modified.
        if (parentFieldAPI == 'Regulatory_Assessment__c') {
            List <sObject> sObjsToChange = new List <sObject>();
            for (String status : notAllowedStatuses) {
                sObject sObj = sObjects.get(allowedStatuses.size() + notAllowedStatuses.indexOf(status));
                sObj.put(statusFieldAPI, status);
                sObjsToChange.add(sObj);
            }
            update sObjsToChange;
        }
        if (parentFieldAPI == 'Hazard_Assessment__c') {
            List <sObject> childrensObjects = new List <sObject> ();
            for (sObject ha: sObjects) {
                sObject sObj = Schema.getGlobalDescribe().get('RMF__c').newSObject();
                sObj.put('Hazard_Assessment__c', ha.Id);
                childrensObjects.add(sObj);
            }
            insert childrensObjects;
            List <sObject> sObjsToChange = new List <sObject>();
            for (String status : notAllowedStatuses) {
                sObject sObj = sObjects.get(allowedStatuses.size() + notAllowedStatuses.indexOf(status));
                sObj.put(statusFieldAPI, status);
                sObjsToChange.add(sObj);
            }
            update sObjsToChange;
        }
        if (parentFieldAPI == 'Post_Market_Risk_Asst_Risk_Ctrl__c') {
            List <sObject> sObjsToChange = new List <sObject>();
            for (String status : notAllowedStatuses) {
                sObject sObj = sObjects.get(allowedStatuses.size() + notAllowedStatuses.indexOf(status));
                sObj.put(statusFieldAPI, status);
                sObjsToChange.add(sObj);
            }
            update sObjsToChange;
        }
        Test.startTest();
        testAttachmentInsert(allStatuses, notAllowedStatuses, sObjects, parentFieldAPI);
        //all created attachment should be deleted
        testAttachmentDelete(new List <String>());
        insert sObjectsToModify;
        if (parentFieldAPI == 'Hazard_Assessment__c') {
            List <sObject> childrensObjects = new List <sObject> ();
            for (sObject ha: sObjectsToModify) {
                sObject sObj = Schema.getGlobalDescribe().get('RMF__c').newSObject();
                sObj.put('Hazard_Assessment__c', ha.Id);
                childrensObjects.add(sObj);
            }
            insert childrensObjects;

        }
        //impossible to create records with this status. Needs to be modified.
        if (parentFieldAPI == 'Trend_Item_Maintenance_Request__c') {
            List <sObject> allParentsObjects = new List <sObject>();
            allParentsObjects.addAll(sObjects);
            allParentsObjects.addAll(sObjectsToModify);
            List <sObject> childrensObjects = new List <sObject>();
            for (sObject parentSobj: allParentsObjects) {
                sObject sObj = Schema.getGlobalDescribe().get('Trend_Item_Maintenance_Product__c').newSObject() ;
                sObj.put('Trend_Item_Maintenance_Request__c', parentSobj.Id);
                childrensObjects.add(sObj);
            }
            insert childrensObjects;

        }
        // create sobject with allowed status and change the status to not allowed to be able to test deletion
        testAttachmentInsert(allStatuses, new List <String>(), sObjectsToModify, parentFieldAPI);
        Integer sObjIndex = 0;
        for (String status: notAllowedStatusesForDelete) {
            sObject sObj = sObjectsToModify.get(sObjIndex);
            sObj.put(statusFieldAPI, status);
            sObjIndex++;
        }
        update sObjectsToModify;

        testAttachmentDelete(notAllowedStatusesForDelete);
        System.assertEquals(notAllowedStatusesForDelete.size(), [Select Id from Attachment__c].size(),
                            notAllowedStatusesForDelete.size() + ' attachments should be in the system');
        Test.stopTest();
    }
    /**
    * @Method       : testAttachmentInsert
    * @Description  : Test create behaviour for attachment. CR:973
    * @Return       : N/A
    * @Params       : List <String> allStatuses, List <String> notAllowedStatuses, List<sObject> sObjects, String parentFieldAPI
    **/
    private static void testAttachmentInsert(List <String> allStatuses, List <String> notAllowedStatuses, List<sObject> sObjects, String parentFieldAPI){
        List <Attachment__c> attachments = new List <Attachment__c>();
        for (sObject sObj: sObjects) {
            sObject attachment = Schema.getGlobalDescribe().get('Attachment__c').newSObject() ;
            attachment.put('Attachment_Type__c', 'Regulatory Correspondence');
            attachment.put('Name', 'Test ' + sObj.Id);
            attachment.put(parentFieldAPI, sObj.Id);
            attachments.add((Attachment__c)TestDataFactory.createSObject(attachment, false));

        }
        Database.SaveResult[] srList = Database.insert(attachments, false);
        Integer dmlErrorMessagesSize = 0;
        Set <Id> savedAttachmentIds = new Set <Id>();

        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                for(Database.Error objErr : sr.getErrors()) {
                    dmlErrorMessagesSize++;
                    System.assert(objErr.getMessage().contains('Insufficient access'), 'Insufficient access error should be thrown, but it is '+ objErr.getMessage());
                }
            } else {
                savedAttachmentIds.add(sr.getId());
            }
        }
        System.assertEquals(notAllowedStatuses.size(), dmlErrorMessagesSize, 'Error should be thrown for ' + notAllowedStatuses.size() + ' records.');

    }

    /**
    * @Method       : testAttachmentDelete
    * @Description  : Test delete behaviour for attachment. CR:973
    * @Return       : N/A
    * @Params       : List <String> notAllowedStatuses
    **/
    private static void testAttachmentDelete(List <String> notAllowedStatuses){
        List <Attachment__c> savedRecords = [Select Id from Attachment__c];
        Database.DeleteResult[] drList = Database.delete(savedRecords, false);
        Integer dmlErrorMessagesSize = 0;
        for (Database.DeleteResult dr : drList) {
            if (!dr.isSuccess()) {
                for(Database.Error objErr : dr.getErrors()) {
                    dmlErrorMessagesSize++;
                    System.assert(objErr.getMessage().contains('Insufficient access'), 'Insufficient access error should be thrown, but it is '+ objErr.getMessage());
                }
            }
        }
        System.assertEquals(notAllowedStatuses.size(), dmlErrorMessagesSize, 'Error should be thrown for ' + notAllowedStatuses.size() + 'records');
    }

    /*
    * @Method       : executeLogicFromWFRulesTest
    * @Description  : To test 'executeLogicFromWFRules()' method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void executeLogicFromWFRulesTest() {
        insert new Attachment__c(
            Attachment_Type__c = 'Registration',
            Name = 'test 123'
        );

        Attachment__c newAtt = [SELECT Name, Registartion_Attachment__c, Last_Modified__c FROM Attachment__c];

        System.assertEquals(newAtt.Name, newAtt.Registartion_Attachment__c);
        System.assertEquals(newAtt.Last_Modified__c.day(), newAtt.Last_Modified__c.day());
    }
    /**
     * @Method       : createAttachment_test1
     * @Description  : Verifies Ticket Note processing and MDC generation when MDC prevention validation is enabled 
     * 				   through application settings.
     * @Return       : N/A
     * @Params       : N/A
     **/
    @isTest
    static void createAttachment_test1() { 
        
        // Create Complaint Ticket record
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'No',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Complaint',
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), true);
        ADD_App_Settings__c appConfig = [SELECT Id, Enable_MDC_Prevention_Logic__c FROM ADD_App_Settings__c LIMIT 1];
        appConfig.Enable_MDC_Prevention_Logic__c = true;
        update appConfig;
		
        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        //CHaRM R9.0/IPDR-409 Create Medical Evaluation record
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaintTicket.Id
        ), true);
        Test.startTest();
        Attachment__c attachmentRec = (Attachment__c)TestDataFactory.createSObject(new Attachment__c(
                Name = 'Test',
                Attachment_Type__c = 'Customer Letter',
                Registration_Number__c = 'registration',
            	Registartion_Attachment__c= 'Test Attachment',
                Ticket__c = complaintTicket.Id
        ), true);
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(2, mdcCount);
        Test.stopTest();
    }
    /**
     * @Method       : createAttachment_test2
     * @Description  : Verifies Ticket Note processing and MDC generation when MDC prevention validation is enabled 
     * 				   through application settings.
     * @Return       : N/A
     * @Params       : N/A
     **/
    @isTest
    static void createAttachment_test2() { 
        // Create Complaint Ticket record
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'No',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Complaint',
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), true);

        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        //CHaRM R9.0/IPDR-409 Create Medical Evaluation record
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaintTicket.Id
        ), true);
        Test.startTest();
        Attachment__c attachmentRec = (Attachment__c)TestDataFactory.createSObject(new Attachment__c(
                Name = 'Test',
                Attachment_Type__c = 'Customer Letter',
                Registration_Number__c = 'registration',
            	Registartion_Attachment__c= 'Test Attachment',
                Ticket__c = complaintTicket.Id
        ), true);
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(2, mdcCount);

        Test.stopTest();
    }
}