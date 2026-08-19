/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : HHAReportControllerTest.
* @Why   : HHAReportControllerTest test class for the HealthHazardAssessmentReportController class.
* @When  : 17-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 17-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 18-AUG-2020         Code Audit                        Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@IsTest
private class HHAReportControllerTest {
    private static final String IDS = 'ids';
    private static final String NAMES = 'names';

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessmentRiskContr = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
                new Post_Market_Risk_Assessment_Risk_Contr__c(Division__c = 'ADD'),
                true
        );
        Hazard_Assessment__c hazardAssessment = (Hazard_Assessment__c) TestDataFactory.createSObject(
                new Hazard_Assessment__c (
                        Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessmentRiskContr.Id,
                        CMPL123Rule_Key_Value__c = 'ACTION_TASK_WORKFLOW',
                        Hazard_Type__c = 'Incorrect Results',
                        Rationale_Associated_to_Delay_of_Results__c = 'N/A',
                        CMPL123_WF_Status__c = 'HHA in Process',
                        Current_Frequency_of_Hazard_Category__c = 'Probable',
                        Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
                        Does_the_Curt_Est_Freq_trigger_risk_eval__c = 'N/A',
                        Estimated_Current_Frequency_of_Hazard__c = 'Test',
                        Is_the_hazard_identified_in_the_RMF__c = 'No',
                        Health_Hazard_Risk_Level__c = 'Medium'),
                true
        );
        insert new Health_Hazard_Assessment__c(
                Hazard_Assessment__c = hazardAssessment.Id,
                Potential_Harm__c = 'test',
                Current_Severity_Level__c = 'Major',
                Probability_of_Occurrence_of_Harm__c = 'Probable',
                Health_Hazard_Risk_Level__c = 'Medium'
        );
    }

    /*
    * @Method       : testController.
    * @Description  : To test HealthHazardAssessmentReportController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testController() {
        Health_Hazard_Assessment__c healthHazardAssessment = [SELECT Name FROM Health_Hazard_Assessment__c LIMIT 1];
        HealthHazardAssessmentReportController controller = new HealthHazardAssessmentReportController();

        Test.startTest();
        Map<Id, Health_Hazard_Assessment__c> controllerResultsWithoutParams = new Map<Id, Health_Hazard_Assessment__c>(
                controller.healthHazardAssessments
        );
        System.assert(controller.isDataAvailable);
        System.assert(controller.getRecordsIdentifiers(IDS).isEmpty());
        controller.healthHazardAssessments = null;
        ApexPages.currentPage().getParameters().put(IDS, healthHazardAssessment.Id);
        Map<Id, Health_Hazard_Assessment__c> controllerResults = new Map<Id, Health_Hazard_Assessment__c>(
                controller.healthHazardAssessments
        );
        ApexPages.currentPage().getParameters().put(NAMES, healthHazardAssessment.Name);
        Test.stopTest();

        System.assertEquals(' WHERE Name IN :names', controller.getWhereClauseOrLimit(
                controller.getRecordsIdentifiers(IDS),
                controller.getRecordsIdentifiers(NAMES)
        ));
        System.assert(controller.getRecordsIdentifiers(IDS).contains(healthHazardAssessment.Id));
        System.assert(controllerResults.containsKey(healthHazardAssessment.Id));
        System.assert(controllerResultsWithoutParams.containsKey(healthHazardAssessment.Id));
    }
}