/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : RiskAsstCustomReportControllerTest.
* @Why   : Test class to handle different scenarios from 'RiskAsstCustomReportController' class.
* @When  : 21-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  21-MAY-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class RiskAsstCustomReportControllerTest {
    private static final String IDS = 'ids';
    private static final String NAMES = 'names';
    private static final Integer DEFAULTRECSCOUNT = 50;

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setupData() {
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
                new Post_Market_Risk_Assessment_Risk_Contr__c(
                        Division__c = 'ADD'
                ), true);
        Hazard_Assessment__c hazardAssessment1 = (Hazard_Assessment__c) TestDataFactory.createSObject(
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
        Hazard_Assessment__c hazardAssessment2 = (Hazard_Assessment__c) TestDataFactory.createSObject(
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
        Regulatory_Assessment__c objRegAssessment = (Regulatory_Assessment__c) TestDataFactory.createSObject(
                new Regulatory_Assessment__c (
                        Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessRiskContrRecord.Id,
                        CMPL123Rule_Key_Value__c = 'REGULATORY_ASSESSMENT_WORKFLOW'
                ), true);
        Health_Hazard_Assessment__c healthHazardAssessment = (Health_Hazard_Assessment__c) TestDataFactory.createSObject(
                new Health_Hazard_Assessment__c(
                        Hazard_Assessment__c = hazardAssessment1.Id,
                        Potential_Harm__c = 'test',
                        Current_Severity_Level__c = 'Major',
                        Probability_of_Occurrence_of_Harm__c = 'Probable',
                        Health_Hazard_Risk_Level__c = 'Medium'
                ),
                true
        );
        Attachment__c attachment = (Attachment__c) TestDataFactory.createSObject(
                new Attachment__c(
                        Name = 'ManualAttachment.csv',
                        Hazard_Assessment__c = hazardAssessment1.Id,
                        Attachment_Type__c = 'Translation',
                        Attachment_Status__c = 'Active'
                ), true);
    }

    /*
    * @Method       : testForIdParam.
    * @Description  : To test 'RiskAsstCustomReportController' class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void testForIdParam() {
        Test.startTest();
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = [SELECT Name FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        List<Hazard_Assessment__c> hazardAssessments = [
                SELECT Id, Name FROM Hazard_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c =: postMarketRiskAssessRiskContrRecord.Id
        ];
        List<Regulatory_Assessment__c> regulatoryAssessments = [
                SELECT Id, Name FROM Regulatory_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c =: postMarketRiskAssessRiskContrRecord.Id
        ];

        ApexPages.currentPage().getParameters().put(IDS, postMarketRiskAssessRiskContrRecord.Id);
        RiskAsstCustomReportController controller = new RiskAsstCustomReportController();
        RiskAsstCustomReportController.PostMarketHAHHARMFWrapper result = controller.lstWrapPostMarketHAHHARMF.get(0);
        Map<Id, Hazard_Assessment__c> resultForNamesHazardAssessments = new Map<Id, Hazard_Assessment__c>(result.lstHAs);
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessmentRiskContr = result.objPostRisk;
        Test.stopTest();

        System.assert(postMarketRiskAssessmentRiskContr.Id == postMarketRiskAssessRiskContrRecord.Id);
        System.assert(resultForNamesHazardAssessments.containsKey(hazardAssessments.get(0).Id));
    }

    /*
    * @Method       : testForNameParam.
    * @Description  : To test 'RiskAsstCustomReportController' class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void testForNameParam() {
        Test.startTest();
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = [SELECT Name FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        List<Hazard_Assessment__c> hazardAssessments = [
                SELECT Id, Name FROM Hazard_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c =: postMarketRiskAssessRiskContrRecord.Id
        ];
        List<Regulatory_Assessment__c> regulatoryAssessments = [
                SELECT Id, Name FROM Regulatory_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c =: postMarketRiskAssessRiskContrRecord.Id
        ];
        ApexPages.currentPage().getParameters().put(NAMES, postMarketRiskAssessRiskContrRecord.Name);
        RiskAsstCustomReportController controller = new RiskAsstCustomReportController();
        RiskAsstCustomReportController.PostMarketHAHHARMFWrapper result = controller.lstWrapPostMarketHAHHARMF.get(0);
        Map<Id, Hazard_Assessment__c> resultForNamesHazardAssessments = new Map<Id, Hazard_Assessment__c>(result.lstHAs);
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessmentRiskContrForNames = result.objPostRisk;
        Test.stopTest();

        System.assert(postMarketRiskAssessmentRiskContrForNames.Id == postMarketRiskAssessRiskContrRecord.Id);
        System.assert(resultForNamesHazardAssessments.containsKey(hazardAssessments.get(0).Id));
    }

    /*
    * @Method       : testWithoutParams.
    * @Description  : To test 'RiskAsstCustomReportController' class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void testWithoutParams() {
        Test.startTest();
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = [SELECT Name FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        List<Hazard_Assessment__c> hazardAssessments = [
                SELECT Id, Name FROM Hazard_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c =: postMarketRiskAssessRiskContrRecord.Id
        ];
        List<Regulatory_Assessment__c> regulatoryAssessments = [
                SELECT Id, Name FROM Regulatory_Assessment__c
                WHERE Post_Market_Risk_Assessment_Risk_Contr__c =: postMarketRiskAssessRiskContrRecord.Id
        ];
        RiskAsstCustomReportController controller = new RiskAsstCustomReportController();
        RiskAsstCustomReportController.PostMarketHAHHARMFWrapper result = controller.lstWrapPostMarketHAHHARMF.get(0);
        Map<Id, Hazard_Assessment__c> resultForNamesHazardAssessments = new Map<Id, Hazard_Assessment__c>(result.lstHAs);
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessmentRiskContrForNames = result.objPostRisk;
        Test.stopTest();

        System.assert(postMarketRiskAssessmentRiskContrForNames.Id == postMarketRiskAssessRiskContrRecord.Id);
        System.assert(resultForNamesHazardAssessments.containsKey(hazardAssessments.get(0).Id));
    }
}