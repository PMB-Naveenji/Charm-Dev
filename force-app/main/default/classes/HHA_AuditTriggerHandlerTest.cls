/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : HHA_AuditTriggerHandlerTest.
* @Why   : HHA_AuditTriggerHandlerTest test class for the HHA_AuditTriggerHandler class.
* @When  : 13-AUG-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 13-AUG-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid                08-Feb-2021       	Error Fixes                		  ōUpdated the code.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class HHA_AuditTriggerHandlerTest {
    
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {
        
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
                        Health_Hazard_Risk_Level__c = 'Medium',
                    	Approach_for_Data_Analysis__c = '100% of all available data',
                    	Assignee__c = UserInfo.getUserId()
                ), true);
        
        Health_Hazard_Assessment__c healthHazardAssessment = (Health_Hazard_Assessment__c) TestDataFactory.createSObject(
                new Health_Hazard_Assessment__c(
                        Hazard_Assessment__c = hazardAssessment.Id,
                        Potential_Harm__c = 'test',
                        Current_Severity_Level__c = 'Major',
                        Probability_of_Occurrence_of_Harm__c = 'Probable',
                        Health_Hazard_Risk_Level__c = 'Medium'
                ), true);
    }
    
    /*
    * @Method       : beforeDeleteTest.
    * @Description  : To test the HHA_AuditTriggerHandler functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void beforeDeleteTest() {
        
        Hazard_Assessment__c hazardAssessment = [SELECT Id, CMPL123_WF_Status__c FROM Hazard_Assessment__c];
        system.debug('hazardAssessment--->'+hazardAssessment);
		hazardAssessment.CMPL123_WF_Action__c = 'HHA Complete';        
        hazardAssessment.CMPL123_WF_Status__c = 'HHA Complete';//@Juneid 08 Feb 2021, Updated WF Status 
        TestDataFactory.updateSObject(hazardAssessment);
        
        Health_Hazard_Assessment__c healthHazardAssessment = [SELECT Id FROM Health_Hazard_Assessment__c];
        
        Test.startTest();
        try{
            TestDataFactory.deleteSObject(healthHazardAssessment);
        }catch(DmlException e){
            System.assertEquals(System.label.RMF_cannot_be_deleted, e.getDmlMessage(0));
        }
        Test.stopTest();
    }
}