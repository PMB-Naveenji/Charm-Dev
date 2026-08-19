/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDpREInformationTriggerHandlerTest.
* @Why   : ADDpREInformationTriggerHandlerTest class for the ADDpREInformationTriggerHandler class.
* @When  : 18-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                18-OCT-2018           Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                10-JUN-2020           N/A                         Updated code part, which is related to Users' insertion. This
*                                                                        change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                        deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                08-SEP-2020           PMD                         Added assertion into 'deletePREInformation' method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDpREInformationTriggerHandlerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){

        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

        //Create User
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        User aspenUser = TestUtil.insertTestUser(
            profileId,
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
            CMPL123__Is_Start_Step__c = true),
        true);

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
            Primary_Vigilance_Contact__c = aspenUser.id,
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

        //Creating pRE_Information__c
        pRE_Information__c objPreInformation = (pRE_Information__c) TestDataFactory.createSObject(new pRE_Information__c(
            pRE_Comments__c = 'Test',
        	Cause_of_fire_smoke__c = 'Test Fire Smoke',
        	Extent_of_fire_smoke_damage__c = 'Test Damage',
        	Sample_Type_Storage_Condition__c = 'Test Condition',
        	Device_Storage_Condition__c = 'Test Storage',
        	Cause_of_exposure_potential_exposure__c = 'Test Exposure',
        	Cause_of_Death_Injury_Potential_Injury__c = 'Test Injuiry',
        	Complaint__c = complaintTicket.Id),
        	true);

    }

    /*
    * @Method       : updatePREInformation.
    * @Description  : To test updating of pRE Information.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void updatePREInformation(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c WHERE Customer_Reply_Required__c = false AND pRE_Status__c  = 'No' LIMIT 1];

        System.assertEquals(1, [SELECT count() FROM Translation_Task__c WHERE Parent_Ticket__c =: complaintTicket.id]);
        pRE_Information__c objPreInformation = [SELECT Id FROM pRE_Information__c WHERE pRE_Comments__c = 'test'];

        update objPreInformation;
    }

    /*
    * @Method       : updatePREInformation.
    * @Description  : To test deletion of pRE Information.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void deletePREInformation(){
        pRE_Information__c objPreInformation = [SELECT Id FROM pRE_Information__c WHERE pRE_Comments__c = 'test'];
        delete objPreInformation;
        System.assertEquals(0, [SELECT COUNT() FROM pRE_Information__c]);
    }
}