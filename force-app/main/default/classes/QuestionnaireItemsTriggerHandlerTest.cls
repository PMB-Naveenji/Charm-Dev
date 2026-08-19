/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : QuestionnaireItemsTriggerHandlerTest.
* @Why   : QuestionnaireItemsTriggerHandlerTest test class for the QuestionnaireItemsTriggerHandler class.
* @When  : 03-JUN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 03-JUN-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 20-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 11-JAN-2021         TWD Upgrade Issue                 Created fieldUpdatesFromWfRulesTest method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class QuestionnaireItemsTriggerHandlerTest {

    /*
    * @Method       : test.
    * @Description  : To insert test data and test QuestionnaireItemsTriggerHandler functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
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
        List<CMPL123CME__Questionnaire_Items__c> questionnaireItems = new List<CMPL123CME__Questionnaire_Items__c>{
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q1,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q1,
                        CMPL123CME__Answer__c = 'Yes'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q2,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q2,
                        CMPL123CME__Answer__c = 'Yes'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_Deficiency_DT_Q1,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_Deficiency_DT_Q1,
                        CMPL123CME__Answer__c = 'Yes'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q2a,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q2a,
                        CMPL123CME__Answer__c = 'Yes'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q3,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q3,
                        CMPL123CME__Answer__c = 'Yes'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q3a,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q3a,
                        CMPL123CME__Answer__c = 'Yes'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q5,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q5,
                        CMPL123CME__Answer__c = 'Yes'
                )
        };

        Test.startTest();
        ComplaintTriggerHandler.systemMedEval = false;
        insert questionnaireItems;
        update questionnaireItems;
        delete questionnaireItems;
        Test.stopTest();

        System.assertEquals(questionnaireItems.size(), [SELECT COUNT() FROM CMPL123CME__Questionnaire_Items__c ALL ROWS]);
    }

    /*
    * @Method       : fieldUpdatesFromWfRulesTest.
    * @Description  : To test moved to Apex WF Rules functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void fieldUpdatesFromWfRulesTest() {
        //Create Complaint 
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
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
                        CMSNext_Ticket_Number__c = '123456'),
                true
        );
        //Create Med Eval
        CMPL123CME__Questionnaire__c medeval = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                    CMPL123CME__Complaint__c = complaint.Id,
                    CMPL123CME__Key_value__c = 'pRE'
                    ),true
        );

        Test.startTest();
        ComplaintTriggerHandler.systemMedEval = false;
        CMPL123CME__Questionnaire_Items__c qi = (CMPL123CME__Questionnaire_Items__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire_Items__c(
                CMPL123CME__Questionnaire__c = medeval.Id
                ), true
        );

        System.assertEquals('pRE', 
                            [SELECT Id, CMPL123CME__Parent_Key_Value__c FROM CMPL123CME__Questionnaire_Items__c WHERE Id =: qi.Id].CMPL123CME__Parent_Key_Value__c, 
                            'Parent Key Value should be copied from parent Med Eval');
        Test.stopTest();
    }
}