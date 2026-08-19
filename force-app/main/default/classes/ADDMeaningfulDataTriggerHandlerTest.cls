/**
 * @why  : ADDMeaningfulDataTriggerHandlerTest class for the ADDMeaningfulDataTriggerHandler,
 * @when : CreatedDate : 18-OCTOBER-2018         
 * @what : Class to Handle Different scenarios from ADDMeaningfulDataTriggerHandler.
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID         Description 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      rsitc                10-June-2020            N/A                     Updated code part, which is related to Users' insertion. 
                                                                             This change designed to prevent a 'DUPLICATE_USERNAME'
                                                                             error during deployment to Production environment
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      oivan                06-JAN-2021             TWD Upgrade Issue       Added method testWFlogic 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik            07-SEP-2022             CHaRM R2.2 IPDR 164     Fix missing coverage for MDCTicketUtil due to not having
 *                                                                           MDC Trigger records
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  CHaRM COE               20-JUL-2026             CHaRM R9.0/IPDR-409     Created "createMeaningfulData_test1" & "createMeaningfulData_test2" methods
 * 																		    to cover the MDC creation fucntionality when PatientInformation record creates.
 * 																			Update the "setup" method to insert the "ADD_App_Settings__c" custom setting.
 * -------------------------------------------------------------------------------------------------------------------------------------- 
*/

@isTest
public class ADDMeaningfulDataTriggerHandlerTest {
    
    /**
* @Method       : setup
* @Description  : Creating Meaningful Data  
* @Return       : N/A
* @Params       : N/A
**/ 
    @testSetup static void setup(){
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true); 
        appConfig.MDC_Generation_Prevention_Minutes__c=10.0;
        update appConfig;
        Profile aspenUserProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];
        //Create User
        User u = TestUtil.insertTestUser(
            aspenUserProfile.Id,
            'test@test.com',
            'test@test.com',
            'Tran10'
        );
        
        //Create Workflow Status
        CMPL123__WF_Status__c  statusOpened = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Opened'),true);
        
        CMPL123__WF_Status__c  statusInProcess = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'In Process'),true);
        
        CMPL123__WF_Status__c  statusTaskSentToVendor = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Task sent to vendor'),true);
        
        CMPL123__WF_Status__c  statusClosedDone = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Closed-Done'),true);
        
        //Create Workflow Action
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Promote'),true);
        
        CMPL123__WF_Action__c actionPopulateTranslation = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Populate Translations'),true);
        
        CMPL123__WF_Action__c actionSendToVendor = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Send to Vendor'),true);
        
        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c  assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            Name = 'Translation task workflow',
            CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
            CMPL123__Record_Type__c  = 'Translation_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for Prod Eval Assess
        CMPL123__WF_Step__c assessProdStep = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusOpened.Id,
            CMPL123__End_Status__c  = statusInProcess.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = assessProdRule.Id,
            CMPL123__Is_Start_Step__c = true),true);
        
        //Create Translation Vendor
        Translation_Vendor__c objTranslationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new Translation_Vendor__c(
            Name = 'Do Not Use',
            Division__c = 'ADD',
            Status__c = 'Active',
            Vendor_Email__c = 'test@test.com'), 
        true);
        
        //Create Country
        Country__c objCountryIndia = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'INDIA',
            Division__c = 'ADD',
            Country_Code__c = 'IND',
            Primary_Vigilance_Contact__c = u.id, 
            Preferred_Translation_Vendor__c = objTranslationVendor.id,
            Translations_Required_flag__c = true ), 
        true);
        
        
        // Create Complaint of Ticket RecordType
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
        
        //Create Meaningful_Data__c 
        Meaningful_Data__c objMeaningfulData = (Meaningful_Data__c) TestDataFactory.createSObject(new Meaningful_Data__c(
            Meaningful_Data_Category__c = 'Test Category',
            Meaningful_Data_Answers__c = 'Test Answer',
            Compliant__c = complaintTicket.Id),
        true);
        insertMdcTriggersForMeaningfulData();
        // 07-SEP-2022 Larry: Now inserts all MDC Trigger records currently in the org
        //insert ADDTicketNoteTriggerHandlerTest.getMdcTriggers();
    }
    /**
     * @Method       : insertMdcTriggersForMeaningfulData
     * @Description  : Setup MDC trigger
     * @Return       : N/A
     * @Params       : N/A
     **/
    private static List<CMPL123__MDC_Trigger__c> insertMdcTriggersForMeaningfulData() {
        // Insert MDC Triggers so that the audit trail knows which SObjects to act on.
        // Notice that these four MDC Triggers are commented from the MDC_TRIGGER constants
        CMPL123__MDC_Trigger__c mdcTriggerEvalInvest =
            (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(new CMPL123__MDC_Trigger__c(
                CMPL123__Active__c = true,
                CMPL123__Criteria__c = 'Created or Changed',
                CMPL123__Logic__c = '1',
                CMPL123__Number_of_Acks__c = 1,
                CMPL123__Record_Detail_Field__c = 'Registration_Ticket__c',
                CMPL123__Select_Target_Object__c = 'Meaningful_Data__c',
                Name = 'Meaningful Data Change for Evaluator/Investigator',
                Selected_Group_Name__c = 'Evaluator/Investigator'
            ), false);
        CMPL123__MDC_Trigger__c mdcTriggerMedEval = mdcTriggerEvalInvest.clone();
        mdcTriggerMedEval.Name = 'Meaningful Data Change for med evaluator';
        mdcTriggerMedEval.Selected_Group_Name__c = 'Medical Evaluator';
        insert new CMPL123__MDC_Trigger__c[]{mdcTriggerEvalInvest, mdcTriggerMedEval};
                    
            // Insert Audit Trail Config so that MDCs know which fields to track.
            // This happens in MDCTicketUtil.createMDC
            CMPL123__AuditTrail_Config__c auditTrailConfig = 
            (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
                CMPL123__Fields__c = 'Meaningful_Data_Answers__c',
                CMPL123__Is_Active__c = true,
                Name = 'Meaningful_Data__c'
            ), true);
        
        // Insert MDC Field Maps so that field API names can be affiliated with labels
        CMPL123__MDC_Field_Mapping__c fieldMapEvalInvest = 
            (CMPL123__MDC_Field_Mapping__c) TestDataFactory.createSObject(new CMPL123__MDC_Field_Mapping__c(
                CMPL123__Condition__c = 'Custom',
                CMPL123__Field_API__c = 'Meaningful_Data_Answers__c',
                CMPL123__Field_Name__c = 'Meaningful Data Answers',
                CMPL123__Index__c = 1,
                CMPL123__Parameters__c = 'MeanigfulDataAnswerMDC',
                CMPL123__Parent_object__c = mdcTriggerEvalInvest.Id,
                CMPL123__Selected_object__c = 'Ticket_Note__c'
            ), false);
        CMPL123__MDC_Field_Mapping__c fieldMapMedEval = fieldMapEvalInvest.clone();
        fieldMapMedEval.CMPL123__Parameters__c = 'MeanigfulDataAnswerMDC';
        fieldMapMedEval.CMPL123__Parent_object__c = mdcTriggerMedEval.Id;
        insert new CMPL123__MDC_Field_Mapping__c[]{ fieldMapEvalInvest, fieldMapMedEval };
         return new List<CMPL123__MDC_Trigger__c>{ mdcTriggerEvalInvest, mdcTriggerMedEval };
       }
    /**
* @Method       : updateMeaningfulData
* @Description  : Updating Meaningful Data
* @Return       : N/A
* @Params       : N/A
**/    
    static testmethod void updateMeaningfulData(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c WHERE Customer_Reply_Required__c = false AND pRE_Status__c  = 'No' LIMIT 1];
        
        System.assertEquals(1, [SELECT count() FROM Translation_Task__c WHERE Parent_Ticket__c =: complaintTicket.id]);
        Meaningful_Data__c objMeaningfulData = [SELECT Id FROM Meaningful_Data__c WHERE Meaningful_Data_Category__c = 'Test Category'];
        
        update objMeaningfulData;
    }
    
    /**
* @Method       : deleteMeaningfulData
* @Description  : deleting Meaningful Data
* @Return       : N/A
* @Params       : N/A
**/    
    static testmethod void deleteMeaningfulData(){
        Meaningful_Data__c objMeaningfulData = [SELECT Id FROM Meaningful_Data__c WHERE Meaningful_Data_Category__c = 'Test Category'];
        delete objMeaningfulData;
        System.assertEquals(new List<Meaningful_Data__c>(), [SELECT Id FROM Meaningful_Data__c WHERE Meaningful_Data_Category__c = 'Test Category']);
    } 
/**
* @Method       : testWfFogic
* @Description  : TWD Upgrade issue. WF: Auto populate Meaningful Data Added field with a concatenation of fields was moved to apex
* @Return       : N/A
* @Params       : N/A
**/    
    static testmethod void testWfFogic(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c WHERE Customer_Reply_Required__c = false AND pRE_Status__c  = 'No' LIMIT 1];
        
        //Create Meaningful_Data__c 
        Meaningful_Data__c objMeaningfulData = (Meaningful_Data__c) TestDataFactory.createSObject(new Meaningful_Data__c(
            Meaningful_Data_Category__c = 'Test Category',
            Meaningful_Data_Answers__c = 'Test Answer',
            Compliant__c = complaintTicket.Id),
            true);
        System.assert([SELECT Meaningful_Data_Details__c FROM Meaningful_Data__c WHERE Id =: objMeaningfulData.Id].Meaningful_Data_Details__c.contains('Meaningful Data Category: - Test Category') );
        objMeaningfulData = (Meaningful_Data__c) TestDataFactory.createSObject(new Meaningful_Data__c(
            Meaningful_Data_Answers__c = 'Test Answer',
            Compliant__c = complaintTicket.Id),
            true);
        System.assert([SELECT Meaningful_Data_Details__c FROM Meaningful_Data__c WHERE Id =: objMeaningfulData.Id].Meaningful_Data_Details__c.contains('Meaningful Data Answer: - Test Answer') );
    
    } 
    /**
     * @Method       : createMeaningfulData_test1
     * @Description  : Verifies Ticket Note processing and MDC generation when MDC prevention validation is enabled 
     * 				   through application settings.
     * @Return       : N/A
     * @Params       : N/A
     **/
    @isTest
    static void createMeaningfulData_test1() { 
        ADD_App_Settings__c appConfig = [SELECT Id, Enable_MDC_Prevention_Logic__c FROM ADD_App_Settings__c LIMIT 1];
        appConfig.Enable_MDC_Prevention_Logic__c = true;
        update appConfig;
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        //CHaRM R9.0/IPDR-409 Create Medical Evaluation record
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaintTicket.Id
        ), true);
        Test.startTest();
        Meaningful_Data__c objMeaningfulData = (Meaningful_Data__c) TestDataFactory.createSObject(new Meaningful_Data__c(
            Meaningful_Data_Category__c = 'Test Category',
            Meaningful_Data_Answers__c = 'Test Answer',
            Compliant__c = complaintTicket.Id),true);
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(2, mdcCount);
        Test.stopTest();
    }
    /**
     * @Method       : createMeaningfulData_test2
     * @Description  : Verifies Ticket Note processing and MDC generation when MDC prevention validation is enabled 
     * 				   through application settings.
     * @Return       : N/A
     * @Params       : N/A
     **/
    @isTest
    static void createMeaningfulData_test2() { 
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        //CHaRM R9.0/IPDR-409 Create Medical Evaluation record
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaintTicket.Id
        ), true);
        Test.startTest();
        Meaningful_Data__c objMeaningfulData = (Meaningful_Data__c) TestDataFactory.createSObject(new Meaningful_Data__c(
            Meaningful_Data_Category__c = 'Test Category',
            Meaningful_Data_Answers__c = 'Test Answer',
            Compliant__c = complaintTicket.Id),true);
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(2, mdcCount);
        Test.stopTest();
    }
}