/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateProductReportableFieldsTest.
* @Why   : UpdateProductReportableFieldsTest test class for the UpdateProductReportableFields class.
* @When  : 09-JUL-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 28-APR-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 28-SEP-2020         Code Audit                        Added filter "IsActive = true" to query in 'testUpdateFields()' method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class UpdateProductReportableFieldsTest {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setup(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        System.runAs(TestUtil.insertTestUser(profileId, 'test@test.com', 'testinteguser@test.com')){
            
            Id complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Complaint')
                    .getRecordTypeId();

            CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                    new CMPL123CME__Complaint__c(
                            Division__c = 'ADD',
                            pRE_Status__c = 'Yes',
                            Country_of_origin__c = 'INDIA',
                            RecordTypeId = complaintRTId,
                            Business_Unit__c = 'IA-CC',
                            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                            CMSNext_Ticket_Number__c = '12345'),
                    true
            );

            CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                    new CMPL123CME__Questionnaire__c(CMPL123CME__Complaint__c = complaint.Id),
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
                    Assignee_Name__c = UserInfo.getUserId()
            );
            insert medTask;

            CMPL123__Product__c product = new CMPL123__Product__c(
                    Name = 'Test Product',
                    Division__c = 'ADD',
                    Reportable_Confirmed_Malfunction_List__c = 'Yes',
                    Reportable_Confirmed_Malfunction_Descrip__c = 'Test Description',
                    Reportable_Confirmed_MalfunctionInitDate__c = System.now()
            );
            insert product;

            RCML_Task_Product__c RCMLTask = (RCML_Task_Product__c) TestDataFactory.createSObject(
                    new RCML_Task_Product__c(
                            RCML_Task_ID__c = medTask.Id,
                            Product_ID__c = product.Id),
                    true
            );
        }
    }

    /*
    * @Method       : testUpdateFields.
    * @Description  : To test the updateFields functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void testUpdateFields() {
        List<Medical_Evaluation_Task__c> medicalEvalTaskList = [SELECT Add_Confirmed_Malfunction_to_RCML_List__c, Reportable_Confirmed_Malfunction_Descrip__c
                                                                FROM Medical_Evaluation_Task__c];

        User integrationUser = [SELECT Id FROM User WHERE Profile.Name = 'ASPEN Integration' AND IsActive = true LIMIT 1];

        Test.startTest();

        System.runAs(integrationUser) {
            UpdateProductReportableFields updateProductReportableFields = new UpdateProductReportableFields();
            updateProductReportableFields.updateFields(medicalEvalTaskList);
        }

        Test.stopTest();

        CMPL123__Product__c prod = [SELECT Reportable_Confirmed_Malfunction_List__c, Reportable_Confirmed_Malfunction_Descrip__c FROM CMPL123__Product__c];

        System.assertEquals(prod.Reportable_Confirmed_Malfunction_List__c, 'Yes');
        System.assertEquals(prod.Reportable_Confirmed_Malfunction_Descrip__c, 'Test');
    }
    
    /*
    * @Method       : testUpdateFieldsWithNoValue.
    * @Description  : To test the updateFields with no value functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    // if medTask.Add_Confirmed_Malfunction_to_RCML_List__c == 'No'
    @IsTest
    static void testUpdateFieldsWithNoValue() {

        List<Medical_Evaluation_Task__c> medicalEvalTaskList = new List<Medical_Evaluation_Task__c>();

        Medical_Evaluation_Task__c medTask = [SELECT Add_Confirmed_Malfunction_to_RCML_List__c,
                                                      Reportable_Confirmed_Malfunction_Descrip__c
                                              FROM Medical_Evaluation_Task__c];
        medTask.Add_Confirmed_Malfunction_to_RCML_List__c = 'No';
        medicalEvalTaskList.add(medTask);

        Test.startTest();
        UpdateProductReportableFields updateProductReportableFields = new UpdateProductReportableFields();
        updateProductReportableFields.updateFields(medicalEvalTaskList);
        Test.stopTest();

        CMPL123__Product__c prod = [SELECT Reportable_Confirmed_Malfunction_List__c,
                                            Reportable_Confirmed_Malfunction_Descrip__c
                                    FROM CMPL123__Product__c];

        System.assertEquals(prod.Reportable_Confirmed_Malfunction_List__c, null);
        System.assertEquals(prod.Reportable_Confirmed_Malfunction_Descrip__c, null);
    }
    
    /*
    * @Method       : testValidationRuleCheck.
    * @Description  : To test the ValidationRuleCheck functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void testValidationRuleCheck() {
        RCML_Task_Product__c RCMLTask = [SELECT Product_ID__c FROM RCML_Task_Product__c];
        RCMLTask.Product_ID__c = null;
        update RCMLTask;

        List<Medical_Evaluation_Task__c> medTasks = [SELECT Add_Confirmed_Malfunction_to_RCML_List__c,
                                                            Reportable_Confirmed_Malfunction_Descrip__c
                                                     FROM Medical_Evaluation_Task__c];
        Test.startTest();
        UpdateProductReportableFields updateProductReportableFields = new UpdateProductReportableFields();
        try{
            updateProductReportableFields.validationRuleCheck(medTasks);
        } catch (Exception e){
            System.assertEquals(e.getMessage(), System.label.Medical_Evaluation_Task_Product_Required);
        }
        Test.stopTest();
    }
}