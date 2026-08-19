/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : ADDUpdateRMHazardLevelTest.
* @Why   : Test class for ADDUpdateRMHazardLevel,ADDS4HazardsAssessmentTriggerHandler and ADDHazardAssessmentTriggerHandler.
* @When  : 29-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                28-OCT-2018            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                28-DEC-2020            TWD Upgrade issue             Added new methods to test WFs logic
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                26-JAN-2021            TWD Upgrade issue             Removed obsolete test method.
* ---------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDUpdateRMHazardLevelTest {
    @TestSetup
    static void setupData() {
        TestDataFactory.createSObject(new ADD_App_Settings__c(Restrict_Validation_Rules__c = true), true);

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

        TestDataFactory.createSObject(new Hazard_Assessment__c(
            Health_Hazard_Risk_Level__c = 'Low',
            Hazard_Type__c = 'Physical',
            Description_of_the_Hazard__c ='test',
            Post_Market_Risk_Assessment_Risk_Contr__c = pmra.Id,
            Approach_for_Data_Analysis__c = 'Experimentally derived',
            Current_Frequency_of_Hazard_Category__c = 'Probable',
            Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
            For_delay_of_results_is_maximum_tolerab__c = 'Yes',
            Does_the_Curt_Est_Freq_trigger_risk_eval__c ='Yes',
            Estimated_Current_Frequency_of_Hazard__c ='Test',
            Is_the_hazard_identified_in_the_RMF__c = 'Yes',
            Rationale_Associated_to_Delay_of_Results__c = 'N/A',
            For_Incorrect_Results_describe__c = 'N/A',
            CMPL123_WF_Status__c = 'Closed-Done'
        ), true);

        TestDataFactory.createSObject(new Hazard_Assessment__c(
            Health_Hazard_Risk_Level__c = 'Low',
            Describe_Existing_Control_Measures_RMF__c = 'Test',
            Hazard_Type__c = 'Physical',
            Hazard_easily_identifiable_If_so_how__c = 'Test',
            Description_of_the_Hazard__c = 'test',
            Post_Market_Risk_Assessment_Risk_Contr__c = pmra.Id,
            Approach_for_Data_Analysis__c = 'Experimentally derived',
            Current_Frequency_of_Hazard_Category__c = 'Probable',
            Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
            For_delay_of_results_is_maximum_tolerab__c = 'Yes',
            Does_the_Curt_Est_Freq_trigger_risk_eval__c = 'Yes',
            Estimated_Current_Frequency_of_Hazard__c = 'Test',
            Is_the_hazard_identified_in_the_RMF__c = 'Yes',
            RMF_Create_Status__c = true,
            Rationale_Associated_to_Delay_of_Results__c = 'N/A',
            For_Incorrect_Results_describe__c = 'N/A',
            CMPL123_WF_Status__c = 'Opened'
        ), true);
    }


    //To test the ADDUpdateRMHazardLevel class functionality.
    @IsTest
    public static void testupdateRMHazardLevel(){
        Test.startTest();

        //Query Hazard Assessment
        List<Hazard_Assessment__c> hazardAssessmentList = new List<Hazard_Assessment__c>([SELECT Id,CMPL123_WF_Status__c,Post_Market_Risk_Assessment_Risk_Contr__c FROM Hazard_Assessment__c WHERE CMPL123_WF_Status__c = 'Closed-Done' LIMIT 1]);
        ADDUpdateRMHazardLevel.updateRMHazardLevel(hazardAssessmentList);
        //Assert
        System.assertEquals([SELECT Health_Hazard_Risk_Level__c FROM Hazard_Assessment__c LIMIT 1].Health_Hazard_Risk_Level__c,[SELECT Overall_Final_Risk_Level__c FROM Post_Market_Risk_Assessment_Risk_Contr__c].Overall_Final_Risk_Level__c);

        //Query Hazard Assessment
        Hazard_Assessment__c hazardAssessment = [SELECT Id,CMPL123_WF_Status__c,Post_Market_Risk_Assessment_Risk_Contr__c FROM Hazard_Assessment__c WHERE CMPL123_WF_Status__c = 'Closed-Done' LIMIT 1];
        //Update Hazard Assessment
        hazardAssessment.Health_Hazard_Risk_Level__c  = 'High';
        TestDataFactory.updateSObject(hazardAssessment) ;
        //Query Updated Hazard Assessment for 'Health Hazard Risk Level' high.
        List<Hazard_Assessment__c> hazardAssHighList = new List<Hazard_Assessment__c>([SELECT Id,CMPL123_WF_Status__c,Post_Market_Risk_Assessment_Risk_Contr__c FROM Hazard_Assessment__c WHERE CMPL123_WF_Status__c = 'Closed-Done' LIMIT 1]);
        ADDUpdateRMHazardLevel.updateRMHazardLevel(hazardAssHighList);
        //Assert
        System.assertEquals([SELECT Health_Hazard_Risk_Level__c FROM Hazard_Assessment__c LIMIT 1].Health_Hazard_Risk_Level__c,[SELECT Overall_Final_Risk_Level__c FROM Post_Market_Risk_Assessment_Risk_Contr__c].Overall_Final_Risk_Level__c);


        //Query Hazard Assessment
        Hazard_Assessment__c hazardAssessmentMedium = [SELECT Id,CMPL123_WF_Status__c,Post_Market_Risk_Assessment_Risk_Contr__c FROM Hazard_Assessment__c WHERE CMPL123_WF_Status__c = 'Closed-Done' LIMIT 1];
        //Update Hazard Assessment
        hazardAssessmentMedium.Health_Hazard_Risk_Level__c  = 'Medium';
        TestDataFactory.updateSObject(hazardAssessmentMedium) ;
        //Query Updated Hazard Assessment for 'Health Hazard Risk Level' Medium.
        List<Hazard_Assessment__c> hazardAssMediumList = new List<Hazard_Assessment__c>([SELECT Id,CMPL123_WF_Status__c,Post_Market_Risk_Assessment_Risk_Contr__c FROM Hazard_Assessment__c WHERE CMPL123_WF_Status__c = 'Closed-Done' LIMIT 1]);
        ADDUpdateRMHazardLevel.updateRMHazardLevel(hazardAssMediumList);
        //Assert
        System.assertEquals([SELECT Health_Hazard_Risk_Level__c FROM Hazard_Assessment__c LIMIT 1].Health_Hazard_Risk_Level__c,[SELECT Overall_Final_Risk_Level__c FROM Post_Market_Risk_Assessment_Risk_Contr__c].Overall_Final_Risk_Level__c);

        Test.stopTest();
    }

    //To test the ADDHazardAssessmentTriggerHandler and ADDS4HazardsAssessmentTriggerHandler class functionality.
    @IsTest
    public static void testautoPostWorkflowActionsinRiskManagements(){
        Test.startTest();

        // Code Coverage for ADDS4HazardsAssessmentTriggerHandler for different status
        //Query post Market Risk Assessment Risk Contr
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketAss = [SELECT Id,CMPL123_WF_Status__c FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        //Update post Market Risk Assessment Risk Contr
        postMarketAss.CMPL123_WF_Status__c = 'Risk Evaluation In Process';
        TestDataFactory.updateSObject(postMarketAss) ;
        //  Query Hazard Assessment
        Hazard_Assessment__c hazardRisk = [SELECT Id,CMPL123_WF_Status__c,Post_Market_Risk_Assessment_Risk_Contr__c,For_Incorrect_Results_describe__c FROM Hazard_Assessment__c WHERE CMPL123_WF_Status__c = 'Opened' AND Post_Market_Risk_Assessment_Risk_Contr__c =: postMarketAss.Id LIMIT 1];
        hazardRisk.CMPL123_WF_Status__c = 'Pending Parent Risk Evaluation Approval';
        TestDataFactory.updateSObject(hazardRisk);
        System.assertEquals('RiskEval',[SELECT CMPL123Task_Key_Value__c FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1].CMPL123Task_Key_Value__c);

        // Code Coverage for ADDS4HazardsAssessmentTriggerHandler
        //Query post Market Risk Assessment Risk Contr
        Post_Market_Risk_Assessment_Risk_Contr__c riskAss = [SELECT Id,CMPL123_WF_Status__c FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        //riskAss.CMPL123_WF_Status__c = 'Risk Control Measure in Process';
        //TestDataFactory.updateSObject(riskAss);
        // Query Hazard Assessment
        Hazard_Assessment__c hazardRiskAsses = [SELECT Id,CMPL123_WF_Status__c,Post_Market_Risk_Assessment_Risk_Contr__c,For_Incorrect_Results_describe__c FROM Hazard_Assessment__c WHERE CMPL123_WF_Status__c != 'Closed-Done' AND Post_Market_Risk_Assessment_Risk_Contr__c =: riskAss.Id LIMIT 1];
        hazardRiskAsses.CMPL123_WF_Status__c = 'Risk Evaluation Background';
        hazardRiskAsses.For_Incorrect_Results_describe__c = 'N/A';
        TestDataFactory.updateSObject(hazardRiskAsses) ;
        System.assertEquals('RiskEval',[SELECT CMPL123Task_Key_Value__c FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1].CMPL123Task_Key_Value__c);

        //Delete Hazard Assessment
        Hazard_Assessment__c hazardDel = [SELECT Id,CMPL123_WF_Status__c,Post_Market_Risk_Assessment_Risk_Contr__c,For_Incorrect_Results_describe__c FROM Hazard_Assessment__c WHERE CMPL123_WF_Status__c != 'Closed-Done' AND Post_Market_Risk_Assessment_Risk_Contr__c =: riskAss.Id LIMIT 1];
        TestDataFactory.deleteSObject(hazardDel);
        Test.stopTest();
    }

    /*
    * @Method       : testAutoCompleteWF.
    * @Description  : To test the ADDHazardAssessmentTriggerHandler functionality from removed WF rules:
    *                 Autoset Completed By and Completed On Dates, Autoset RMF Frequency Type for ADD
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
   @IsTest
    public static void testAutoCompleteWF(){
        // Create Post Market Risk Assessment Risk Contr
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = [SELECT Id,CMPL123_WF_Status__c FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        //Create Hazard Assessment
        Hazard_Assessment__c hazardAssessmentRecord = (Hazard_Assessment__c) TestDataFactory.createSObject(
                        new Hazard_Assessment__c(Health_Hazard_Risk_Level__c = 'Low',Hazard_Type__c = 'Physical',
                                                Description_of_the_Hazard__c ='test',
                                                Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessRiskContrRecord.id,
                                                Approach_for_Data_Analysis__c = 'Experimentally derived',
                                                Current_Frequency_of_Hazard_Category__c = 'Probable',
                                                Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
                                                For_delay_of_results_is_maximum_tolerab__c= 'Yes',
                                                Does_the_Curt_Est_Freq_trigger_risk_eval__c ='Yes',
                                                Estimated_Current_Frequency_of_Hazard__c='Test',
                                                Is_the_hazard_identified_in_the_RMF__c = 'Yes',
                                                Rationale_Associated_to_Delay_of_Results__c = 'N/A',
                                                For_Incorrect_Results_describe__c = 'N/A',
                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                CMPL123_WF_Action__c = 'Hazard Assessment Completed'), true);
        System.assertEquals(date.today(), [SELECT Hazard_Assessment_Completed_Date__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].Hazard_Assessment_Completed_Date__c );
        System.assertEquals('Harm', [SELECT RMF_Frequencey_Type__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].RMF_Frequencey_Type__c);
        hazardAssessmentRecord = (Hazard_Assessment__c) TestDataFactory.createSObject(
                        new Hazard_Assessment__c(Health_Hazard_Risk_Level__c = 'Low',Hazard_Type__c = 'Physical',
                                                Description_of_the_Hazard__c ='test',
                                                Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessRiskContrRecord.id,
                                                Approach_for_Data_Analysis__c = 'Experimentally derived',
                                                Current_Frequency_of_Hazard_Category__c = 'Probable',
                                                Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
                                                For_delay_of_results_is_maximum_tolerab__c= 'Yes',
                                                Does_the_Curt_Est_Freq_trigger_risk_eval__c ='Yes',
                                                Estimated_Current_Frequency_of_Hazard__c='Test',
                                                Is_the_hazard_identified_in_the_RMF__c = 'Yes',
                                                Rationale_Associated_to_Delay_of_Results__c = 'N/A',
                                                For_Incorrect_Results_describe__c = 'N/A',
                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                CMPL123_WF_Action__c = 'HHA Complete'), true);
        System.assertEquals(null, [SELECT Hazard_Assessment_Completed_Date__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].Hazard_Assessment_Completed_Date__c );
        System.assertEquals(date.today(), [SELECT HHA_Completed_Date__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].HHA_Completed_Date__c );
        hazardAssessmentRecord.CMPL123_WF_Action__c  = 'Submit for HHA';
        update hazardAssessmentRecord;
        System.assertEquals(date.today(), [SELECT Risk_Eval_Background_Completed_Date__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].Risk_Eval_Background_Completed_Date__c );
        System.assertEquals(null, [SELECT CMPL123_WF_Action_Performed_By__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].CMPL123_WF_Action_Performed_By__c);
    }

    /*
    * @Method       : testClearWF.
    * @Description  : To test the ADDHazardAssessmentTriggerHandler functionality from removed WF rules:
    *                 Clear HHA Complete Field, Clear Hazard Assessment Field, Clear Risk Evaluation Background Field, Hazard Type <> Delay of Results,
    *                 Update Delay associated with an ASR,LDA or RUO?
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testClearWF(){
        // Create Post Market Risk Assessment Risk Contr
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = [SELECT Id,CMPL123_WF_Status__c FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        //Create Hazard Assessment
        Hazard_Assessment__c hazardAssessmentRecord = (Hazard_Assessment__c) TestDataFactory.createSObject(
                        new Hazard_Assessment__c(Health_Hazard_Risk_Level__c = 'Low',Hazard_Type__c = 'Physical',
                                                Description_of_the_Hazard__c ='test',
                                                Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessRiskContrRecord.id,
                                                Approach_for_Data_Analysis__c = 'Experimentally derived',
                                                Current_Frequency_of_Hazard_Category__c = 'Probable',
                                                Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
                                                For_delay_of_results_is_maximum_tolerab__c= 'Yes',
                                                Does_the_Curt_Est_Freq_trigger_risk_eval__c ='Yes',
                                                Estimated_Current_Frequency_of_Hazard__c='Test',
                                                Is_the_hazard_identified_in_the_RMF__c = 'Yes',
                                                Rationale_Associated_to_Delay_of_Results__c = 'N/A',
                                                For_Incorrect_Results_describe__c = 'N/A',
                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                Hazard_Assessment_Completed_By__c = 'TEST',
                                                CMPL123_WF_Action__c = 'Send back to Hazard Assessment In Process'), true);
        System.assertEquals(null, [SELECT Hazard_Assessment_Completed_By__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].Hazard_Assessment_Completed_By__c );

        System.assertEquals(null, [SELECT HHA_Completed_Date__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].HHA_Completed_Date__c );
        hazardAssessmentRecord.CMPL123_WF_Action__c  = 'Send Back to Risk Evaluation in Process';
        hazardAssessmentRecord.Hazard_Assessment_Completed_By__c = 'TEST';
        hazardAssessmentRecord.HHA_Completed_Date__c = date.today().addDays(-2);
        hazardAssessmentRecord.CMPL123_WF_Action_Performed_On__c = date.today();
        hazardAssessmentRecord.HHA_Completed_By__c = UserInfo.getUserId();
        hazardAssessmentRecord.Risk_Evaluation_Background_Completed_By__c = 'TEST2';
        update hazardAssessmentRecord;
        System.assertEquals(null, [SELECT Risk_Evaluation_Background_Completed_By__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].Risk_Evaluation_Background_Completed_By__c );
        System.assertEquals('TEST', [SELECT Hazard_Assessment_Completed_By__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ].Hazard_Assessment_Completed_By__c );
        hazardAssessmentRecord.CMPL123_WF_Action__c  = 'Send back to Hazard Assessment In Process';
        update hazardAssessmentRecord;
        hazardAssessmentRecord  = [SELECT Hazard_Assessment_Completed_By__c , Delay_of_results_associated_with_an_ASR__c, For_delay_of_results_is_maximum_tolerab__c
                                            FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ];
        System.assertEquals(null, hazardAssessmentRecord.Hazard_Assessment_Completed_By__c );
        System.assertEquals('N/A', hazardAssessmentRecord.Delay_of_results_associated_with_an_ASR__c);
        System.assertEquals('N/A', hazardAssessmentRecord.For_delay_of_results_is_maximum_tolerab__c);
    }

    /*
    * @Method       : testWF.
    * @Description  : To test the ADDHazardAssessmentTriggerHandler functionality from removed WF rules:
    *                 Known Hazard Src No - RMF Desc of Hazard, Known Hazard Src No - RMF Desc of Src, Reopened Date update
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testWF(){
        // Create Post Market Risk Assessment Risk Contr
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = [SELECT Id,CMPL123_WF_Status__c FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        //Create Hazard Assessment
        Hazard_Assessment__c hazardAssessmentRecord = (Hazard_Assessment__c) TestDataFactory.createSObject(
                        new Hazard_Assessment__c(Health_Hazard_Risk_Level__c = 'Low',
                                                Hazard_Type__c = 'Physical',
                                                Description_of_the_Hazard__c ='test',
                                                Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessRiskContrRecord.id,
                                                Approach_for_Data_Analysis__c = 'Experimentally derived',
                                                Current_Frequency_of_Hazard_Category__c = 'Probable',
                                                Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
                                                For_delay_of_results_is_maximum_tolerab__c= 'Yes',
                                                Does_the_Curt_Est_Freq_trigger_risk_eval__c ='Yes',
                                                Estimated_Current_Frequency_of_Hazard__c='Test',
                                                Is_the_hazard_identified_in_the_RMF__c = 'Yes',
                                                Rationale_Associated_to_Delay_of_Results__c = 'N/A',
                                                For_Incorrect_Results_describe__c = 'N/A',
                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                Known_hazard_src_pred_freq_IDd_in_RMF__c = 'No',
                                                CMPL123_WF_Action__c = 'Send back to Hazard Assessment In Process'), true);
        hazardAssessmentRecord  = [SELECT RMF_Description_of_Hazard__c, RMF_Descr_of_Source_Cause_of_Hazard__c  FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ];
        System.assertEquals('None', hazardAssessmentRecord.RMF_Description_of_Hazard__c );
        System.assertEquals('None', hazardAssessmentRecord.RMF_Descr_of_Source_Cause_of_Hazard__c );
        hazardAssessmentRecord.CMPL123_WF_Action__c = 'Reopen';
        update hazardAssessmentRecord;
        hazardAssessmentRecord  = [SELECT Reopen_Date__c FROM Hazard_Assessment__c
                                            WHERE Id =: hazardAssessmentRecord.Id ];
        System.assertEquals(date.today(), hazardAssessmentRecord.Reopen_Date__c);
    }

    /*
    * @Method       : testRuleKeyUpdate.
    * @Description  : To test the ADDHazardAssessmentTriggerHandler functionality from removed WF rules:
    *                 Update Rule Field Update Key Value
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testRuleKeyUpdate() {
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessRiskContrRecord = [SELECT Id,CMPL123_WF_Status__c FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];
        //Create Hazard Assessment
        Hazard_Assessment__c hazardAssessmentRecord = (Hazard_Assessment__c) TestDataFactory.createSObject(
                        new Hazard_Assessment__c(Health_Hazard_Risk_Level__c = 'Low',
                                                Hazard_Type__c = 'Physical',
                                                Description_of_the_Hazard__c ='test',
                                                Post_Market_Risk_Assessment_Risk_Contr__c = postMarketRiskAssessRiskContrRecord.id,
                                                Approach_for_Data_Analysis__c = 'Experimentally derived',
                                                Current_Frequency_of_Hazard_Category__c = 'Probable',
                                                Descr_Data_Used_Data_Anlys_Rationale__c = 'Test',
                                                For_delay_of_results_is_maximum_tolerab__c= 'Yes',
                                                Does_the_Curt_Est_Freq_trigger_risk_eval__c ='Yes',
                                                Estimated_Current_Frequency_of_Hazard__c='Test',
                                                Is_the_hazard_identified_in_the_RMF__c = 'Yes',
                                                Rationale_Associated_to_Delay_of_Results__c = 'N/A',
                                                For_Incorrect_Results_describe__c = 'N/A',
                                                CMPL123_WF_Action_Performed_On__c = date.today(),
                                                Known_hazard_src_pred_freq_IDd_in_RMF__c = 'No',
                                                CMPL123_WF_Action__c = 'Send back to Hazard Assessment In Process'), true);
        hazardAssessmentRecord  = [SELECT CMPL123Rule_Key_Value__c FROM Hazard_Assessment__c WHERE Id =: hazardAssessmentRecord.Id ];
        System.assertEquals('HAZARD_ASSESSMENT_ADD_WORKFLOW', hazardAssessmentRecord.CMPL123Rule_Key_Value__c);
    }
}