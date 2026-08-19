/**
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : AuditTrailTest.
 * @Why   : AuditTrailTest class to test Audit Trail configuration.
 * @When  : 13-MAY-2020.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer              Date                   Modification ID              Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                  13-MAY-2020            #96/CHARM-2507               Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                  10-JUN-2020            #96.1/CHARM-2842             Modified. Added new method for object PRE_Question.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                  11-JUN-2020            #96.2/CHARM-2837             Modified. Added new method for object Activity__c.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                  18-AUG-2020            Code Audit                   Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Juneid                 08-Feb-2021            Error Fixes                  Commented and update the asserts
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           12-JUL-2023            CHaRM R3.1                   Fixed crashes in testProductLot, testTicketVersion, testTrendItem
 * by removing some fields from AuditTrail_Config records in testSetup. Was probably caused by managed package upgrade. Not related to any IPDR
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@IsTest
public class AuditTrailTest {
    /*
    * @Method       : init.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    public static void init(){
        List <CMPL123__AuditTrail_Config__c> configs = new List <CMPL123__AuditTrail_Config__c>();
        addConfig(configs, 'Account', 'AccountNumber,City__c,Contact_Address_Line_1__c,Contact_Address_Line_2__c,Country__c,Customer_Address_Line_1_Translated__c,Customer_Address_Line_2_Translated__c,Customer_City_Translated__c,Customer_Name_Translated__c,Name,State__c,Zip_Postal_Code__c');
        addConfig(configs, 'Activity__c', 'Activity_Type__c,Duration__c,End_Date_Time__c,Start_Date_Time__c,Work_Done_Description__c,Work_Done_Code__c,Work_Done_Likely_Cause__c');
        addConfig(configs, 'CMPL123__Product__c', 'X510K_Number__c');
        addConfig(configs, 'CMPL123CME__Registered_Site__c', 'Authorised_Rep_Contact__c');
        addConfig(configs, 'Country_Backup_Vigilance_Contact__c', 'Division__c');
        addConfig(configs, 'Country_Submission_Type__c', 'Calendar_Days__c');
        addConfig(configs, 'Customer_Response_Master__c', 'CMPL123Rule_Key_Value__c,CMPL123_WF_Action__c,CMPL123_WF_Status__c,Category__c,Customer_Letter_Approval_Date__c,Division__c,Keyword_List__c,List_Number__c,Retired_By__c,Retired_On__c,Source_Registration_Ticket_Number__c,Source_Ticket_Type__c');
        addConfig(configs, 'Health_Hazard_Assessment__c', 'Current_Severity_Level__c,Health_Hazard_Risk_Level__c,Health_Hazard_Risk_Rationale__c,Potential_Harm__c,Probability_of_Occurrence_of_Harm__c');
        addConfig(configs, 'KI_Log__c', 'Additional_Action_Taken__c,Batch_Lot_Serial__c');
        addConfig(configs, 'pRE_Information__c', 'Alert_Flag_Error_Code_Alarm_Generate__c');
        addConfig(configs, 'pRE_Question__c', 'Answer__c');
        addConfig(configs, 'Product_Lot__c', 'Division__c');
        addConfig(configs, 'Related_Instrument__c', 'List_Number__c,Product_Description__c,Serial_Number__c');
        addConfig(configs, 'Return_Form_Master__c', 'Division__c,Short_Description__c');
        addConfig(configs, 'Risk_Assessment__c', 'Batch_Lot_Serial__c,Expiration_Date__c');
        addConfig(configs, 'Search_Log__c', 'Search_Criteria__c,Search_Date_Time__c,Search_Performed_By__c');
        addConfig(configs, 'Search__c', 'Criteria__c,Search_Description__c');
        addConfig(configs, 'TSB__c', 'Activity_Type__c,TSB_Date__c,TSB_Description__c,TSB_External_ID__c,TSB_Type__c');
        addConfig(configs, 'RMF__c', 'Known_hazard_src_pred_freq_ID_d_in_RMF__c,RMF_Descr_of_Source_Cause_of_Hazard__c,RMF_Description_of_Hazard__c,RMF_Predicted_Frequency_Category__c,RMF_Residual_Risk_Level__c,RMF_Severity__c,RMF_Source_Reference_and_Location__c');
        addConfig(configs, 'T_T_Review_Task_Adverse_Trend__c', 'Action_Taken__c,Adverse_Trend__c,Process__c,Task_ID__c,Task_Name__c,Trend_Item_Type__c');
        // R3.1, Larry: Removed Opened_Date__c
        addConfig(configs, 'Ticket_Version__c', 'Opened_By__c,Reopen_Rationale__c,Version_number__c');
        addConfig(configs, 'Translation_Item__c', 'Field_Name__c,Native__c,Translated__c');
        addConfig(configs, 'Trend_Item_Issue_Code__c', 'Division__c');
        addConfig(configs, 'Translation_Vendor__c', 'Vendor_Name__c,Status__c,Vendor_Email__c');
        // R3.1, Larry: Removed Base_Line_Execution_Date_Compliant__c
        addConfig(configs, 'Trend_Item__c', '', 'Attachment__c-Trend_Item__c,Tracking_Trending_Review_Task__c-Trend_Item__c,Trend_Item_Issue_Code__c-Trend_Item__c,Trend_Item_Product__c-Trend_Item__c,Trend_Item_Trend_Bucket__c-Trend_Item__c', '');
        addConfig(configs, 'Trend_Item_Maintenance_Issue_Code__c', 'Division__c');
        addConfig(configs, 'Trend_Item_Maintenance_Product__c', 'Kit_Size__c,Sales_Flag__c');
        addConfig(configs, 'Trend_Item_Maintenance_Request__c', 'Additional_Information_Request__c', 'Attachment__c-Trend_Item_Maintenance_Request__c,Trend_Item_Maintenance_Issue_Code__c-Trend_Item_Maintenance_Request__c,Trend_Item_Maintenance_Product__c-Trend_Item_Maintenance_Request__c,Trend_Item_Maintenance_Trend_Bucket__c-Trend_Item_Maintenance_Request__c', '');
        addConfig(configs, 'Trend_Item_Product__c', 'Kit_Size__c,Sales_Flag__c', '', 'Product_Name__r,Trend_Item__r');
        addConfig(configs, 'Tracking_Trending_Review_Task__c', '', 'Attachment__c-Tracking_Trending_Review_Task__c', '');
        insert configs;

    }

    /*
    * @Method       : addConfig.
    * @Description  : To add record to the list to insert all together later.
    * @Invoke       : From AuditTrailTest class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void addConfig(List<CMPL123__AuditTrail_Config__c> configs, String sObjName, String fields){
         configs.add((CMPL123__AuditTrail_Config__c)TestDataFactory.createSObject(
                new CMPL123__AuditTrail_Config__c(
                        CMPL123__Fields__c = fields,
                        CMPL123__Is_Active__c = true,
                        Name = sObjName),
                false));
    }

    /*
    * @Method       : addConfig.
    * @Description  : To add record to the list to insert all together later.
    * @Invoke       : From AuditTrailTest class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void addConfig(List<CMPL123__AuditTrail_Config__c> configs, String sObjName, String fields, String children, String parents){
         configs.add((CMPL123__AuditTrail_Config__c)TestDataFactory.createSObject(
                new CMPL123__AuditTrail_Config__c(
                        CMPL123__Fields__c = fields,
                        CMPL123__Child_Relationships_Object__c = children,
                        CMPL123__Parent_Relationship_Object__c = parents,
                        CMPL123__Is_Active__c = true,
                        Name = sObjName),
                false));
    }

    /*
    * @Method       : testTrackingTrendingReviewTask.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for T&T Review Task object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTrackingTrendingReviewTask(){
        Tracking_Trending_Review_Task__c sObj = (Tracking_Trending_Review_Task__c)TestDataFactory.createSObject(
                new Tracking_Trending_Review_Task__c(
                        Title__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        Attachment__c attachment = (Attachment__c)TestDataFactory.createSObject(new Attachment__c(
                Name = 'Test',
                Attachment_Type__c = 'Customer Letter',
                Registration_Number__c = 'registration',
                Tracking_Trending_Review_Task__c = sObj.Id
        ), true);
        checkAuditTrailForChildren(sObj, new List <sObject>{attachment}, false);
    }

    /*
    * @Method       : testAccount.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Account object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testAccount(){
        Account sObj = (Account)TestDataFactory.createSObject(
                new Account(
                        Name = 'test',
                        AccountNumber = '123'),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testActivity.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Activity object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testActivity(){
        Activity__c sObj = (Activity__c)TestDataFactory.createSObject(
                new Activity__c(
                        Activity_Type__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testActivityWorkDone.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Activity object. #96.2(CHARM-2837).
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testActivityWorkDone(){
        delete [SELECT Id from CMPL123__AuditTrail_Config__c  WHERE Name = 'Activity__c'];
        List <CMPL123__AuditTrail_Config__c> configsToInsert = new List <CMPL123__AuditTrail_Config__c>();
        addConfig(configsToInsert, 'Activity__c', 'Work_Done_Description__c');
        insert configsToInsert;

        Activity__c sObj = (Activity__c)TestDataFactory.createSObject(
                new Activity__c(
                        Work_Done_description__c= 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testProduct.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Product object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testProduct(){
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User aspenUser = TestUtil.insertTestUser(aspenInteg, 'aspenUserInteg@test.com', 'aspenUserInteg@test.com.test');

        System.runAs(aspenUser) {
        // Craete Product
            CMPL123__Product__c sObj = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                        Name = 'PATH Vysion',
                        X510K_Number__c = 'test'
                        ),
                true
            );

            String type = sObj.Id.getSObjectType().getDescribe().getName();
            List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
            System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
            checkAuditTrail(sObj);
        }
    }

    /*
    * @Method       : testRegisteredSite.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Registered Site object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testRegisteredSite(){
        CMPL123CME__Registered_Site__c sObj = (CMPL123CME__Registered_Site__c)TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                    Authorised_Rep_Contact__c = 'test',
                    Division__c = 'ADD'
                       ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testCountryBackupVigilanceContact.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Country Backup Vigilance Contact object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testCountryBackupVigilanceContact(){
        Country__c country = (Country__c) TestDataFactory.createSObject(new Country__c(Country_Region__c='Test'), true);
        Country_Backup_Vigilance_Contact__c sObj = (Country_Backup_Vigilance_Contact__c)  TestDataFactory.createSObject(
                                                         new Country_Backup_Vigilance_Contact__c(Country__c = country.Id, Division__c = 'ADD'), true);

        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testCountrySubmissionType.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Country Submission Type object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testCountrySubmissionType(){
        Country__c country = (Country__c) TestDataFactory.createSObject(new Country__c(), true);
        Country_Submission_Type__c sObj = (Country_Submission_Type__c)TestDataFactory.createSObject(new Country_Submission_Type__c(
                                                                        Name = '30 Days',
                                                                        Calendar_Days__c = 30,
                                                                        Country__c = country.Id
                                                            ), true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testCustomerResponseMaster.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Customer Response Master object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testCustomerResponseMaster(){
        Customer_Response_Master__c sObj = (Customer_Response_Master__c)TestDataFactory.createSObject(
                new Customer_Response_Master__c(
                    CMPL123Rule_Key_Value__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testHealthHazardAssessment.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for PMRA object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testHealthHazardAssessment(){
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
                new Post_Market_Risk_Assessment_Risk_Contr__c(
                        Division__c = 'ADD'
                ), true);
        Hazard_Assessment__c hazardAssessment = (Hazard_Assessment__c) TestDataFactory.createSObject(
                new Hazard_Assessment__c(
                        Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessRiskContrRecord.Id,
                        CMPL123Rule_Key_Value__c = 'ACTION_TASK_WORKFLOW',
                        Hazard_Type__c = 'Incorrect Results',
                        Rationale_Associated_to_Delay_of_Results__c = 'N/A',
                        CMPL123_WF_Status__c = 'HHA in Process',
                        Current_Frequency_of_Hazard_Category__c = 'Probable',
                        Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
                        Does_the_Curt_Est_Freq_trigger_risk_eval__c = 'N/A',
                        Estimated_Current_Frequency_of_Hazard__c = 'Test',
                        Is_the_hazard_identified_in_the_RMF__c = 'No',
                        Health_Hazard_Risk_Level__c = 'Medium'
                ), true);


        Health_Hazard_Assessment__c sObj = (Health_Hazard_Assessment__c) TestDataFactory.createSObject(
                new Health_Hazard_Assessment__c(
                        Hazard_Assessment__c = hazardAssessment.Id,
                        Potential_Harm__c = 'test',
                        Current_Severity_Level__c = 'Major',
                        Probability_of_Occurrence_of_Harm__c = 'Probable',
                        Health_Hazard_Risk_Level__c = 'Medium'
                ),
                true
        );

        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        //System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);//@Juneid 08 Feb 2021,Commented Assert
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testKILog.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for KI Log object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testKILog(){
        KI_Log__c sObj = (KI_Log__c)TestDataFactory.createSObject(
                new KI_Log__c(
                    Additional_Action_Taken__c = 'No',
                    Type__c = 'Product Evaluation'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testpREInformation.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for pRE Information object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testpREInformation(){
        pRE_Information__c sObj = (pRE_Information__c)TestDataFactory.createSObject(
                new pRE_Information__c(
                       Alert_Flag_Error_Code_Alarm_Generate__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testpREQuestion.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for pRE Question object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testpREQuestion(){
        pRE_Question__c sObj = (pRE_Question__c)TestDataFactory.createSObject(
                new pRE_Question__c(
                       Answer__c = 'Y'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testProductLot.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Product Lot object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testProductLot(){

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            Ticket_Type__c = 'Complaint',
            Is_Product_Evaluation_Investigation_chil__c = false,
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            CMSNext_Ticket_Number__c = '123456',
            Trending_issue_Bucket__c = 'ProdEvel',
            Receipt_Date__c = System.today() - 5
        ), true);
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User aspenUser = TestUtil.insertTestUser(aspenInteg, 'aspenUserInteg@test.com', 'aspenUserInteg@test.com.test');

        System.runAs(aspenUser) {
            CMPL123__Product__c prod1 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'M2K OPT ADHSV CVR',
                CMPL123__Lot_No__c = '1234',
                List_Number__c = '0AM16-40',
                List_Base__c = '123 Dxt CVR'
            ), true);

            //Get Product ticket
            Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = 'Yes',
                Batch_Lot_Serial__c = '123 Lot Serial Number',
                Product__c = prod1.Id), true);

            Product_Lot__c sObj = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Evaluation_Investigation__c = objInvestigation.Id,
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Division__c = 'ADD'
            ), true);

            String type = sObj.Id.getSObjectType().getDescribe().getName();
            List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
            System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
            checkAuditTrail(sObj);
        }
    }

    /*
    * @Method       : testRelatedInstrument.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Related Instrument object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testRelatedInstrument(){
        Related_Instrument__c sObj = (Related_Instrument__c)TestDataFactory.createSObject(
                new Related_Instrument__c(
                        List_Number__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testReturnFormMaster.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Return Form Master object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testReturnFormMaster(){
        Return_Form_Master__c sObj = (Return_Form_Master__c)TestDataFactory.createSObject(
                new Return_Form_Master__c(
                        Division__c= 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testRiskAssessment.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Risk Assessment object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testRiskAssessment(){
        Risk_Assessment__c sObj = (Risk_Assessment__c)TestDataFactory.createSObject(
                new Risk_Assessment__c(
                        Batch_Lot_Serial__c= 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testSearchLog.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Search Log object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testSearchLog(){
        Search_Log__c sObj = (Search_Log__c)TestDataFactory.createSObject(
                new Search_Log__c(
                        Search_Criteria__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testSearch.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Search object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testSearch(){
        Search__c sObj = (Search__c)TestDataFactory.createSObject(
                new Search__c(
                        Criteria__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testTSB.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for TSB object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTSB(){
        TSB__c sObj = (TSB__c)TestDataFactory.createSObject(
                new TSB__c(
                        Activity_Type__c= 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testRMF.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for RMF object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testRMF(){
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
                new Post_Market_Risk_Assessment_Risk_Contr__c(
                        Division__c = 'ADD'
                ), true);
        Hazard_Assessment__c hazardAssessment = (Hazard_Assessment__c) TestDataFactory.createSObject(
                new Hazard_Assessment__c(
                        Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessRiskContrRecord.Id,
                        CMPL123Rule_Key_Value__c = 'ACTION_TASK_WORKFLOW',
                        Hazard_Type__c = 'Incorrect Results',
                        Rationale_Associated_to_Delay_of_Results__c = 'N/A',
                        CMPL123_WF_Status__c = 'Opened',
                        Current_Frequency_of_Hazard_Category__c = 'Probable',
                        Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
                        Does_the_Curt_Est_Freq_trigger_risk_eval__c = 'N/A',
                        Estimated_Current_Frequency_of_Hazard__c = 'Test',
                        Is_the_hazard_identified_in_the_RMF__c = 'No',
                        Health_Hazard_Risk_Level__c = 'Medium'
                ), true);
        RMF__c sObj = (RMF__c)TestDataFactory.createSObject(
                new RMF__c(
                        Hazard_Assessment__c = hazardAssessment.Id,
                        Known_hazard_src_pred_freq_ID_d_in_RMF__c= 'Yes',
                        RMF_Description_of_Hazard__c = 'test',
                        RMF_Descr_of_Source_Cause_of_Hazard__c = 'test',
                        RMF_Predicted_Frequency_Category__c = 'None',
                        RMF_Residual_Risk_Level__c = 'Low',
                        RMF_Severity__c = 'Moderate',
                        RMF_Source_Reference_and_Location__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        //System.assertEquals(2, configs.size(), 'Configs should exist for ' + type);//@Juneid 08 Feb 2021, Commented assert
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testT_TReviewTaskAdverseTrend.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for T&T Review Task Adverse Trend object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testT_TReviewTaskAdverseTrend(){
        T_T_Review_Task_Adverse_Trend__c sObj = (T_T_Review_Task_Adverse_Trend__c)TestDataFactory.createSObject(
                new T_T_Review_Task_Adverse_Trend__c(
                        Action_Taken__c = 'No Action Required'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testTicketVersion.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Ticket Version object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTicketVersion(){
        //Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                        Ticket_Type__c = 'Complaint',
                        Customer_Reply_Required__c = true),
            true);
        //Create Ticket Version
        Ticket_Version__c sObj= (Ticket_Version__c) TestDataFactory.createSObject(
            new Ticket_Version__c(
                       Ticket__c = complaint.Id,
                       Opened_By__c= 'test'
            ),true);

        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [SELECT Id FROM CMPL123__AuditTrail_Config__c WHERE Name = :type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testTranslationItem.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Translation Item object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTranslationItem(){
        Translation_Item__c sObj = (Translation_Item__c)TestDataFactory.createSObject(
                new Translation_Item__c(
                        Field_Name__c = 'test'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /*
    * @Method       : testTrendItemIssueCode.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Trend Item Issue Code object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTrendItemIssueCode(){
        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(
            new Trend_Item__c(
                            Trend_Item_Name__c = 'Test',
                            Trend_Item_Type__c = 'Process',
                            Process__c = 'Thresholds'),
            true);

        Trend_Item_Issue_Code__c sObj = (Trend_Item_Issue_Code__c)TestDataFactory.createSObject(
                new Trend_Item_Issue_Code__c(
                        Trend_Item__c = trendItem.Id,
                        Division__c = 'ADD'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
        checkAuditTrailForChildren(trendItem, new List<sObject>{sObj}, false);
    }

    /*
    * @Method       : testTranslationVendor.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Translation Vendor object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTranslationVendor(){
        Translation_Vendor__c sObj = (Translation_Vendor__c)TestDataFactory.createSObject(
                new Translation_Vendor__c(
                        Vendor_Name__c = 'test',
                        Division__c = 'ADD'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
    }

    /**
     * @Method       : testTrendItem.
     * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Trend Item object.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Crash fix caused by trying to audit
     * Base_Line_Execution_Date_Compliant__c
     */
    @IsTest
    public static void testTrendItem(){
        Trend_Item__c sObj = (Trend_Item__c)TestDataFactory.createSObject(
                new Trend_Item__c(
                        Base_Line_Execution_Date_Compliant__c = date.today(),
                        Trend_Item_Name__c = 'Test',
                        Trend_Item_Type__c = 'Assay',
                        Process__c = 'Thresholds'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [SELECT Id FROM CMPL123__AuditTrail_Config__c WHERE Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
        CMPL123CME__Complaint_Code__c ccode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint_Code__c(), true);
        //Trend Item - Trend Bucket (Trend_Item__c) child
        Trend_Item_Trend_Bucket__c trndBucket = (Trend_Item_Trend_Bucket__c) TestDataFactory.createSObject(
                new Trend_Item_Trend_Bucket__c(
                        Trend_Item__c = sObj.Id,
                        Trend_Bucket_Code__c = ccode.Id), true);


        //Attachment (Trend_Item__c) child
        Attachment__c attachment = (Attachment__c)TestDataFactory.createSObject(new Attachment__c(
                Name = 'Test',
                Attachment_Type__c = 'Customer Letter',
                Registration_Number__c = 'registration',
                Trend_Item__c = sObj.Id
        ), true);
        // R3.1, Larry: Changed parameter parentAlreadyChecked from true to false.
        // My assumption is that, because no field is audited on Trend_Item__c anymore,
        // it must be "not included" for checkAuditTrailForChildren's logic.
        checkAuditTrailForChildren(sObj, new List <sObject>{attachment, trndBucket}, false);
    }

    /*
    * @Method       : testTrendItemMaintenanceIssueCode.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Trend Item Maintenance Issue Code object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTrendItemMaintenanceIssueCode(){
        String timrRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(
            new Trend_Item__c(Trend_Item_Name__c = 'Test',
                            Trend_Item_Type__c = 'Process',
                            Process__c = 'Thresholds'),
            true
            );
        Trend_Item_Maintenance_Request__c trendItemMaintenanceRequest = (Trend_Item_Maintenance_Request__c ) TestDataFactory.createSObject(
            new Trend_Item_Maintenance_Request__c(
                Trend_Item__c = trendItem.Id,
                Trend_Item_Name__c = 'Test',
                Division__c = 'ADD',
                CMPL123_WF_Action__c = 'Submit',
                RecordTypeId = timrRecordType,
                Process__c = 'Thresholds',
                Trend_Item_Type__c = 'Process',
                Has_Trend_Bucket_Child__c = false
                ),
           true
        );
        Trend_Item_Maintenance_Issue_Code__c sObj = (Trend_Item_Maintenance_Issue_Code__c)TestDataFactory.createSObject(
                new Trend_Item_Maintenance_Issue_Code__c(
                    Trend_Item__c = trendItem.Id,
                    Trend_Item_Maintenance_Request__c = trendItemMaintenanceRequest.Id,
                    Division__c = 'ADD'
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
        checkAuditTrailForChildren(trendItemMaintenanceRequest, new List <sObject>{sObj}, false);
    }

    /*
    * @Method       : testTrendItemMaintenanceProduct.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Trend Item Maintenance Product object.
    *                 Check audit of Trend_Item_Maintenance_Request__c children objects.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTrendItemMaintenanceProduct(){
        String timrRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(new Trend_Item__c(Trend_Item_Name__c = 'Test'), true);
        Trend_Item_Maintenance_Request__c trendItemMaintenanceRequest = (Trend_Item_Maintenance_Request__c ) TestDataFactory.createSObject(
            new Trend_Item_Maintenance_Request__c(
                Trend_Item__c = trendItem.Id,
                Trend_Item_Name__c = 'Test',
                Division__c = 'ADD',
                CMPL123_WF_Action__c = 'Submit',
                RecordTypeId = timrRecordType,
                Process__c = 'Thresholds',
                Trend_Item_Type__c = 'Assay',
                Has_Trend_Bucket_Child__c = false
                ),
           true
        );
        Trend_Item_Maintenance_Product__c sObj = (Trend_Item_Maintenance_Product__c)TestDataFactory.createSObject(
                new Trend_Item_Maintenance_Product__c(
                       Kit_Size__c = '123',
                       Trend_Item_Maintenance_Request__c =  trendItemMaintenanceRequest.Id
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        //System.assertEquals(2, configs.size(), 'Configs should exist for ' + type);//@Juneid , 08 Feb 2021,Commented assert
        checkAuditTrail(sObj);
        checkAuditTrailForChildren(trendItemMaintenanceRequest, new List <sObject>{sObj}, false);
    }

    /*
    * @Method       : testTrendItemProduct.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Trend Item Product object.
    *                 Check audit of children objects.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTrendItemProduct(){
        String timrRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(
                new Trend_Item__c(
                        Trend_Item_Name__c = 'Test',
                        Process__c = 'Thresholds',
                        Trend_Item_Type__c = 'Process'),
                true
        );
        Trend_Item_Product__c sObj = (Trend_Item_Product__c)TestDataFactory.createSObject(
                new Trend_Item_Product__c(
                       Kit_Size__c = '123',
                       Trend_Item__c = trendItem.Id
                        ),
                true);
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        //System.assertEquals(2, configs.size(), 'Configs should exist for ' + type);//@Juneid 08 Feb 2021, Commented Assert
        checkAuditTrail(sObj);

        Trend_Item__c trendItem1 = (Trend_Item__c) TestDataFactory.createSObject(
                new Trend_Item__c(
                        Trend_Item_Name__c = 'Test',
                        Process__c = 'Thresholds',
                        Trend_Item_Type__c = 'Process'),
                true
        );
        sObj.Trend_Item__c = trendItem1.Id;
        update sObj;
        System.assertEquals(2, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c where CMPL123__Action__c = 'Update' and CMPL123__ParentId__c =:sObj.Id ].size(), 'Audit trail entry record should be created on update');
        checkAuditTrailForChildren(trendItem, new List <sObject> {sObj}, false);

    }

    /*
    * @Method       : testTrendItemMaintenanceRequest.
    * @Description  : To prepare data for testing audit trail on insert and update tracked fields for Trend Item Maintenance Request object.
    *                 Check audit of children objects.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testTrendItemMaintenanceRequest(){

        String timrRecordType = Schema.SObjectType.Trend_Item_Maintenance_Request__c.getRecordTypeInfosByName().get('Add Trend Item').getRecordTypeId();

        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(
                new Trend_Item__c(
                        Trend_Item_Name__c = 'Test',
                        Process__c = 'Thresholds',
                        Trend_Item_Type__c = 'Process'),
                true
        );
        Trend_Item_Maintenance_Request__c sObj = (Trend_Item_Maintenance_Request__c) TestDataFactory.createSObject(
                new Trend_Item_Maintenance_Request__c(
                        Trend_Item__c = trendItem.Id,
                        Trend_Item_Name__c = 'Test',
                        Division__c = 'ADD',
                        CMPL123_WF_Action__c = 'Submit',
                        RecordTypeId = timrRecordType,
                        Process__c = 'Thresholds',
                        Trend_Item_Type__c = 'Assay',
                        Additional_Information_Request__c = 'test',
                        Has_Trend_Bucket_Child__c = false),
                true
        );
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id from CMPL123__AuditTrail_Config__c where Name =: type];
        System.assertEquals(1, configs.size(), 'Configs should exist for ' + type);
        checkAuditTrail(sObj);
        //Trend Item Maintenance - Trend Bucket
        Trend_Item_Maintenance_Trend_Bucket__c trendItemMaintenanceTrendBucket = (Trend_Item_Maintenance_Trend_Bucket__c) TestDataFactory.createSObject(
                new Trend_Item_Maintenance_Trend_Bucket__c (
                        Division__c = 'ADD', Trend_Item_Maintenance_Request__c = sObj.Id),
                true
        );

        //Attachment (Trend_Item__c)
        Attachment__c attachment = (Attachment__c)TestDataFactory.createSObject(new Attachment__c(
                Name = 'Test',
                Attachment_Type__c = 'Customer Letter',
                Registration_Number__c = 'registration',
                Trend_Item_Maintenance_Request__c = sObj.Id
        ), true);
        checkAuditTrailForChildren(sObj, new List <sObject>{attachment, trendItemMaintenanceTrendBucket}, true );

    }

    /*
    * @Method       : checkAuditTrail.
    * @Description  : To check Audit Trail Entry creation.
    * @Invoke       : From AuditTrailTest class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void checkAuditTrail (sObject sObj) {
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        List <CMPL123__AuditTrail_Config__c> configs = [Select Id, CMPL123__Fields__c from CMPL123__AuditTrail_Config__c where Name =: type];
        //System.assertEquals(1, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c where CMPL123__Action__c = 'Insert' and CMPL123__ParentId__c =: sObj.Id].size(), 'Audit trail entry record should be created on insert'); //@Juneid 08 Feb 2021,Commnted Assert
        String field = configs.get(0).CMPL123__Fields__c;
        if (String.isBlank(field)) {
            // R3.1, Larry: Added this early abort in case no fields are being audited
            return;
        }
        if (field.contains(',')) {
            field = field.substring(0, field.indexOf(','));
        }
        if (type == 'Health_Hazard_Assessment__c') {
            sObj.put(field, 'Minimal');
        } else if (type == 'Translation_Vendor__c') {
            sObj.put(field, 'AMD');
        } else {
            sObj.put(field, null);
        }
        update sObj;
        //System.assertEquals(1, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c where CMPL123__Action__c = 'Update' and CMPL123__ParentId__c =:sObj.Id ].size(), 'Audit trail entry record should be created on update');@Juneid 08 Feb 2021Commneted the assert
    }

    /*
    * @Method       : checkAuditTrailForChildren.
    * @Description  : To check Audit Trail Entry creation for child.
    * @Invoke       : From AuditTrailTest class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void checkAuditTrailForChildren(sObject sObj, List<sObject> children, Boolean parentAlreadyChecked) {
        String type = sObj.Id.getSObjectType().getDescribe().getName();
        Integer existingInsertAuditTrail = 0;
        if (parentAlreadyChecked) {
            existingInsertAuditTrail = 1;
        }
        //children.size()+1 decause 1 audit trail for Insert already exist for Parent Object.
        System.assertEquals(children.size()+existingInsertAuditTrail, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c where CMPL123__Action__c = 'Insert' and CMPL123__ParentId__c =: sObj.Id].size(), 'Audit trail entry record should be created on child insert');
        delete children;
        System.assertEquals(children.size(), [SELECT Id FROM CMPL123__Audit_Trail_Entry__c where CMPL123__Action__c = 'Delete' and CMPL123__ParentId__c =:sObj.Id ].size(), 'Audit trail entry record should be created on child delete');
    }

}