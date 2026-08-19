/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ChildToParentsUpdateTest.
* @Why   : ChildToParentsUpdateTest test class for test parents update upon their childs insert/update.
* @When  : 16-JUN-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 16-JUN-2020         #123/CHARM-2729                   Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                 18-AUG-2020         Code Audit                        Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ChildToParentsUpdateTest {

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setupData() {
        insertData();
    }

    /*
    * @Method       : insertData.
    * @Description  : To insert test data.
    * @Invoke       : From setupData from ChildToParentsUpdateTest.
    * @Return       : N/A.
    * @Params       : N/A.
    */  
    @future
    static void insertData(){
        Id aspenIntegrationId = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User integrstionUser = (User) TestUtil.insertTestUser(aspenIntegrationId, 'aspenUserInteg@test.com', 'aspenUserInteg@test.com.test');
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
            new Country_Submission_Type__c(
                Name = '30 Days',
                Calendar_Days__c = 30,
                Country__c = objCountry.Id
            ), true);
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId,
                CMPL123CME__CMPL123_WF_Status__c = 'Opened'
            ), true);
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(
                RecordTypeId = questionnaireRTId,
                CMPL123_WF_Status__c = 'Regulatory',
                CMPL123CME__Complaint__c = complaint.Id,
                Reportability_Rationale__c = 'Test',
                Evaluator__c = UserInfo.getUserId(),
                Reportability__c = 'Non-Reportable',
                Reportability_Category__c = 'Adverse Event',
                Initial_Awareness_Date__c = Date.newInstance(2018, 05, 07),
                Submitted_Date__c = Date.newInstance(2018, 05, 07)
            ), true);

        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c EMDRInitialRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = EMDRInitial,
                        Medical_Evaluation__c = questionnaire.Id,
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                        CMPL123CME__CMPL123_WF_Action__c = 'Open'
                ), true);

        CMPL123CME__MDR_Code__c  mdrCode =  (CMPL123CME__MDR_Code__c ) TestDataFactory.createSObject(
            new CMPL123CME__MDR_Code__c (
                CMPL123CME__EMDR__c = EMDRInitialRecord.Id
            ), true);

        Customer_Response__c customerResponse = (Customer_Response__c) TestDataFactory.createSObject(
            new Customer_Response__c(Event__c = complaint.Id, CMPL123_WF_Status__c = 'Opened'),true);

        insert new Contact__c(Ticket__c = complaint.Id, Primary__c = true);

        Meaningful_Data_Request__c mdr = (Meaningful_Data_Request__c) TestDataFactory.createSObject(
            new Meaningful_Data_Request__c(
                Request_Type__c = 'CSS Request',
                Question_Action__c = 'test?',
                Request_Status__c = 'Opened',
                Ticket__c = complaint.Id
            ), true);

        Translation_Task__c objTranslation = (Translation_Task__c)TestDataFactory.createSObject(
            new Translation_Task__c(
                Parent_Ticket__c =  complaint.Id,
                CMPL123_WF_Status__c = 'Opened'
            ),true);

        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(new pRE_Information__c(
                External_ID__c = 'CHaRM 24102018 - 01',
                Complaint__c = complaint.Id
        ), true);

        Return__c returnC = (Return__c) TestDataFactory.createSObject(
                new Return__c(
                        Ticket__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened'),
                true
        );

        Id taskRecordTypeId = Schema.SObjectType.Medical_Evaluation_Task__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('RCML_Review_Task')
                    .getRecordTypeId();

        Medical_Evaluation_Task__c medTask = new Medical_Evaluation_Task__c(
            RecordTypeId = taskRecordTypeId,
            Medical_Evaluation__c = questionnaire.Id,
            Priority__c = 'Urgent',
            Add_Confirmed_Malfunction_to_RCML_List__c = 'Yes',
            Reportable_Confirmed_Malfunction_Descrip__c = 'Test',
            Assignee_Name__c = UserInfo.getUserId());
        insert medTask;

        Trend_Item__c trendItemRecord = (Trend_Item__c) TestDataFactory.createSObject(
            new Trend_Item__c(
                    Trend_Item_Name__c = 'Test',
                    Process__c = 'Thresholds',
                    Trend_Item_Type__c = 'Process'
            ),true);
        
        Trend_Item_Product__c trendItemProd = (Trend_Item_Product__c) TestDataFactory.createSObject(
            new Trend_Item_Product__c(Trend_Item__c = trendItemRecord.Id), true);
        
        Trend_Item_Issue_Code__c trendItemIssueCode = (Trend_Item_Issue_Code__c)TestDataFactory.createSObject(
            new Trend_Item_Issue_Code__c(
                Trend_Item__c = trendItemRecord.Id,
                Division__c = 'ADD'
            ),true);
        
        CMPL123CME__Complaint_Code__c complCode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint_Code__c(), true);

    }

    /*
    * @Method       : testParentTicketUpdate.
    * @Description  : Testing transaction load and ticket update when all its children and grandchildren are updated.  
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */  
    @isTest 
    public static void testParentTicketUpdate() {

        User integrationUser = [SELECT Id FROM User WHERE Email = 'aspenUserInteg@test.com'];
        CMPL123CME__Complaint__c complaint = [SELECT Id, LastModifiedDate FROM CMPL123CME__Complaint__c LIMIT 1];
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id, LastModifiedDate FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c = :complaint.Id LIMIT 1];
        Country__c objCountry = [SELECT Id, LastModifiedDate FROM Country__c LIMIT 1];
        Country_Submission_Type__c objCountrySubmissionType = [SELECT Id, LastModifiedDate FROM Country_Submission_Type__c WHERE Country__c = :objCountry.Id LIMIT 1];
        CMPL123CME__Investigation__c investigation = [SELECT Id, LastModifiedDate FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id LIMIT 1];
        Customer_Response__c customerResponse = [SELECT Id, LastModifiedDate FROM Customer_Response__c WHERE Event__c = :complaint.Id LIMIT 1];
        Contact__c contact = [SELECT Id, LastModifiedDate FROM Contact__c LIMIT 1];
        Meaningful_Data_Request__c mdr = [SELECT Id, LastModifiedDate FROM Meaningful_Data_Request__c WHERE Ticket__c = :complaint.Id LIMIT 1];
        Translation_Task__c objTranslation = [SELECT Id, LastModifiedDate FROM Translation_Task__c WHERE Parent_Ticket__c = :complaint.Id LIMIT 1];
        pRE_Information__c preInfo = [SELECT Id, LastModifiedDate FROM pRE_Information__c WHERE Complaint__c = :complaint.Id LIMIT 1];
        Return__c returnC = [SELECT Id, LastModifiedDate FROM Return__c WHERE Ticket__c = :complaint.Id LIMIT 1];
        CMPL123CME__EMDR__c EMDRInitialRecord = [SELECT Id, LastModifiedDate FROM CMPL123CME__EMDR__c WHERE Medical_Evaluation__c = :questionnaire.Id LIMIT 1];
        Medical_Evaluation_Task__c medTask = [SELECT Id, LastModifiedDate FROM Medical_Evaluation_Task__c WHERE Medical_Evaluation__c = :questionnaire.Id LIMIT 1];
        CMPL123CME__MDR_Code__c  mdrCode = [SELECT Id, LastModifiedDate FROM CMPL123CME__MDR_Code__c WHERE CMPL123CME__EMDR__c = :EMDRInitialRecord.Id LIMIT 1];
        CMPL123__Product__c product;
        Product_Ticket__c prodTckt;
        Product_Lot__c productLot;
        Task__c task;
        CMPL123CME__MEDDEV__c meddevRecord;
        Regulatory_Task__c regulatoryTaskRecord;

        System.runAs(integrationUser) {
            product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            productLot = (Product_Lot__c) TestDataFactory.createSObject(
                new Product_Lot__c(
                    Product_Evaluation_Investigation__c = investigation.Id,
                    Related_Ticket__c = complaint.Id,
                    Product_Name__c = prodTckt.Id
                ), true);

            task = (Task__c) TestDataFactory.createSObject(
                new Task__c(
                        Related_Investigation_Evaluation__c = investigation.Id,
                        CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
                        Source_Leveraged__c = 'Leveraged',
                        CMPL123_WF_Status__c = 'Opened'
                ),true);

            meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                    Medical_Evaluation__c = questionnaire.Id,
                    Product__c = prodTckt.id,
                    Country__c = objCountry.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Regulatory_Evaluator__c = UserInfo.getUserId(),
                    Submission_Type__c = objCountrySubmissionType.Id,
                    Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
                    CMPL123_WF_Status__c = 'Opened'
                ), true);
                
            Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Competent Authority Regulatory Response').getRecordTypeId();
            regulatoryTaskRecord = (Regulatory_Task__c) TestDataFactory.createSObject(
                new Regulatory_Task__c(
                        RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                        MDI__c = meddevRecord.Id
                ), true);
        }

        Test.startTest();
        UpdateParentUtility.isMedDevUpdated = false;
        String errorMessage = '';
        customerResponse.Customer_Reply__c = 'test';
        contact.pRE__c = true;
        mdr.Question_Action__c = 'test2';
        objTranslation.Task_Comments__c = 'Comments';
        preInfo.pRE_Comments__c = 'Test';
        returnC.Tracking_Number__c = 'Old';
        questionnaire.Reportability_Rationale__c = 'Test2';
        EMDRInitialRecord.CMPL123CME__MDR_Due_Date__c = Date.newInstance(2019, 12, 8);
        meddevRecord.CMPL123CME__Type_of_Report__c = 'Combined initial and final report';
        investigation.Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem';
        productLot.Device_Expiration_Date__c = Date.newInstance(2019, 01, 12);
        productLot.Device_Expiration_Date_NA__c = false;
        productLot.Device_Expiration_Date_Unknown__c = false;
        task.Result__c = 'Test';
        task.Conclusion__c ='Test';
        regulatoryTaskRecord.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        regulatoryTaskRecord.Regulatory_Agency_Notification_Required__c = 'No';
        medTask.Reportable_Confirmed_Malfunction_Descrip__c = 'Test';
        mdrCode.CMPL123CME__Category__c = 'Evaluation Code';
                
        try {
            update customerResponse;
            update contact;
            update mdr;
            update objTranslation;
            update preInfo;
            update returnC;
            update questionnaire;
            update EMDRInitialRecord;
            update meddevRecord;
            update investigation;
            update productLot; 
            update task;
            update regulatoryTaskRecord;
            update medTask;
            update mdrCode;
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        CMPL123CME__Complaint__c updatedComplaint = [SELECT LastModifiedDate FROM CMPL123CME__Complaint__c WHERE Id = :complaint.Id];
        System.debug(errorMessage);
        System.assert(errorMessage == '');
        System.assert(updatedComplaint.LastModifiedDate > complaint.LastModifiedDate);
    }

    /*
    * @Method       : testMultipleParentsUpdate.
    * @Description  : Testing transaction load and parents update when children are updated.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */  
    @isTest 
    public static void testMultipleParentsUpdate() {

        User integrationUser = [SELECT Id FROM User WHERE Email = 'aspenUserInteg@test.com'];
        Country__c objCountry = [SELECT Id, LastModifiedDate FROM Country__c LIMIT 1];
        Country_Submission_Type__c objCountrySubmissionType = [SELECT Id, LastModifiedDate FROM Country_Submission_Type__c WHERE Country__c = :objCountry.Id LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id, LastModifiedDate FROM CMPL123CME__Complaint__c LIMIT 1];
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id, LastModifiedDate FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c = :complaint.Id LIMIT 1];
        CMPL123CME__Investigation__c investigation = [SELECT Id, LastModifiedDate FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id LIMIT 1];
        CMPL123CME__EMDR__c EMDRInitialRecord = [SELECT Id, LastModifiedDate FROM CMPL123CME__EMDR__c WHERE Medical_Evaluation__c = :questionnaire.Id LIMIT 1];
        Medical_Evaluation_Task__c medTask = [SELECT Id, LastModifiedDate FROM Medical_Evaluation_Task__c WHERE Medical_Evaluation__c = :questionnaire.Id LIMIT 1];
        CMPL123CME__MDR_Code__c  mdrCode = [SELECT Id, LastModifiedDate FROM CMPL123CME__MDR_Code__c WHERE CMPL123CME__EMDR__c = :EMDRInitialRecord.Id LIMIT 1];
        Trend_Item__c trendItem = [SELECT Id, LastModifiedDate FROM Trend_Item__c LIMIT 1];
        Trend_Item_Product__c trendItemProd = [SELECT Id, LastModifiedDate FROM Trend_Item_Product__c WHERE Trend_Item__c = :trendItem.Id LIMIT 1];
        Trend_Item_Issue_Code__c trendItemIssueCode = [SELECT Id, LastModifiedDate FROM Trend_Item_Issue_Code__c WHERE Trend_Item__c = :trendItem.Id LIMIT 1];
        CMPL123__Product__c product;
        Product_Ticket__c prodTckt;
        Product_Lot__c productLot;
        Task__c task;
        CMPL123CME__MEDDEV__c meddevRecord;
        Regulatory_Task__c regulatoryTaskRecord;

        System.runAs(integrationUser) {
            product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            productLot = (Product_Lot__c) TestDataFactory.createSObject(
                new Product_Lot__c(
                    Product_Evaluation_Investigation__c = investigation.Id,
                    Related_Ticket__c = complaint.Id,
                    Product_Name__c = prodTckt.Id
                ), true);

            task = (Task__c) TestDataFactory.createSObject(
                new Task__c(
                        Related_Investigation_Evaluation__c = investigation.Id,
                        CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
                        Source_Leveraged__c = 'Leveraged',
                        CMPL123_WF_Status__c = 'Opened'
                ),true);

            meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(
                new CMPL123CME__MEDDEV__c(
                    Medical_Evaluation__c = questionnaire.Id,
                    Product__c = prodTckt.id,
                    Country__c = objCountry.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    Regulatory_Evaluator__c = UserInfo.getUserId(),
                    Submission_Type__c = objCountrySubmissionType.Id,
                    Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
                    CMPL123_WF_Status__c = 'Opened'
                ), true);
                
            Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Competent Authority Regulatory Response').getRecordTypeId();
            regulatoryTaskRecord = (Regulatory_Task__c) TestDataFactory.createSObject(
                new Regulatory_Task__c(
                        RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                        MDI__c = meddevRecord.Id
                ), true);
        }

        CMPL123CME__MedDev__c meddevRecordBefore = [SELECT LastModifiedDate FROM CMPL123CME__MedDev__c WHERE Id = :meddevRecord.Id];

        Test.startTest();
        String errorMessage = '';
        EMDRInitialRecord.CMPL123CME__MDR_Due_Date__c = Date.newInstance(2019, 12, 8);
        meddevRecord.CMPL123CME__Type_of_Report__c = 'Combined initial and final report';
        investigation.Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem';
        productLot.Device_Expiration_Date__c = Date.newInstance(2019, 01, 12);
        productLot.Device_Expiration_Date_NA__c = false;
        productLot.Device_Expiration_Date_Unknown__c = false;
        task.Result__c = 'Test';
        task.Conclusion__c ='Test';
        regulatoryTaskRecord.Justification_for_not_Reporting__c = 'This issue does not need to be reported per local regulatory requirements';
        regulatoryTaskRecord.Regulatory_Agency_Notification_Required__c = 'No';
        medTask.Reportable_Confirmed_Malfunction_Descrip__c = 'Test';
        mdrCode.CMPL123CME__Category__c = 'Evaluation Code';
        UpdateParentUtility.isMedDevUpdated = false;
        try {
            update productLot; 
            update task;
            update regulatoryTaskRecord;
            update medTask;
            update mdrCode;
            update trendItemProd;
            update trendItemIssueCode;
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        CMPL123CME__Complaint__c updatedComplaint = [SELECT LastModifiedDate FROM CMPL123CME__Complaint__c WHERE Id = :complaint.Id];
        CMPL123CME__Questionnaire__c updatedQuestionnaire = [SELECT LastModifiedDate FROM CMPL123CME__Questionnaire__c WHERE Id = :questionnaire.Id];
        CMPL123CME__Investigation__c updatedInvestigation = [SELECT LastModifiedDate FROM CMPL123CME__Investigation__c WHERE Id = :investigation.Id];
        CMPL123CME__MedDev__c updatedMeddevRecord = [SELECT LastModifiedDate FROM CMPL123CME__MedDev__c WHERE Id = :meddevRecord.Id];
        CMPL123CME__EMDR__c updatedEMDR = [SELECT LastModifiedDate FROM CMPL123CME__EMDR__c WHERE Id = :EMDRInitialRecord.Id];

        System.assert(errorMessage == '');
        System.assert(updatedComplaint.LastModifiedDate > complaint.LastModifiedDate);
        System.assert(updatedQuestionnaire.LastModifiedDate > questionnaire.LastModifiedDate);
        System.assert(updatedInvestigation.LastModifiedDate > investigation.LastModifiedDate);
        System.assert(updatedMeddevRecord.LastModifiedDate > meddevRecordBefore.LastModifiedDate);
        System.assert(updatedEMDR.LastModifiedDate > EMDRInitialRecord.LastModifiedDate);
    }
}